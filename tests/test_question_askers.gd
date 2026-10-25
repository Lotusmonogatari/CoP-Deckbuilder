extends GutTest
## Who asks a question (2026-10-12, Cameron): the asker must sit in the room
## and, when the question names parties in "Asked By Party", belong to one of
## them (OWN = the player's own party). The party caucus seats only the
## player's own party ("Own Party Only" on the Stages tab).

const PARTIES := {"PT01": "Butsutou", "PT03": "Frontier Party", "PT05": "Keizaijiyuutou"}
const ROOM := [
	{"opp_id": "OP1", "party": "Frontier Party"},
	{"opp_id": "OP2", "party": "Keizaijiyuutou"},
	{"opp_id": "OP3", "party": "Frontier Party"},
]


func _asker(questions: Array, own_party: String = "Frontier Party") -> Array:
	var ids: Array = []
	for q: Dictionary in QuestionAskers.resolve(questions, ROOM, own_party, PARTIES):
		ids.append(str(q.get("asked_by", "")))
	return ids


func test_an_asker_already_in_the_room_is_kept() -> void:
	assert_eq(_asker([{"id": "Q1", "asked_by": "OP2"}]), ["OP2"])


func test_an_asker_not_in_the_room_is_replaced_by_someone_who_is() -> void:
	var ids := _asker([{"id": "Q1", "asked_by": "OP99"}])
	assert_eq(ids.size(), 1)
	assert_has(["OP1", "OP2", "OP3"], ids[0])
	assert_eq(_asker([{"id": "Q1", "asked_by": "OP99"}]), ids, "the same question picks the same person")


func test_a_party_limited_question_is_asked_by_that_party() -> void:
	var ids := _asker([{"id": "Q1", "asked_by": "OP1", "asked_by_parties": ["PT05"]}])
	assert_eq(ids, ["OP2"], "only the Keizaijiyuutou member may ask it")


func test_own_means_the_players_party() -> void:
	var q := [{"id": "Q1", "asked_by": "OP2", "asked_by_parties": ["OWN"]}]
	assert_has(["OP1", "OP3"], _asker(q, "Frontier Party")[0])
	assert_eq(_asker(q, "Keizaijiyuutou"), ["OP2"])


func test_a_party_limited_question_nobody_here_may_ask_is_not_asked() -> void:
	assert_eq(_asker([{"id": "Q1", "asked_by": "OP1", "asked_by_parties": ["PT01"]}]), [],
		"no Butsutou member sits in this room")


func test_an_unlimited_question_in_a_room_with_no_askers_keeps_its_asker() -> void:
	var kept := QuestionAskers.resolve([{"id": "Q1", "asked_by": "OP9"}], [], "Frontier Party", PARTIES)
	assert_eq(str(kept[0]["asked_by"]), "OP9")


func test_the_caucus_seats_only_the_players_own_party() -> void:
	assert_eq(str(DataDB.get_stage("ST03").get("own_party_only", "")), "Yes", "real ST03 is Own Party Only")
	for player_id: String in ["PC01", "PC03", "PC04"]:
		GameState.start_new_run(player_id)
		var party := str(DataDB.player.get("party", ""))
		var seated := BattleSetup.eligible_opponents("ST03")
		assert_gte(seated.size(), 2, "%s's caucus has at least two members" % party)
		for opponent: Dictionary in seated:
			assert_eq(str(opponent.get("party", "")), party, "%s sits in %s's caucus" % [opponent.get("opp_id"), party])
	# A room without the flag still seats every party.
	var parties := {}
	for opponent: Dictionary in BattleSetup.eligible_opponents("ST02"):
		parties[str(opponent.get("party", ""))] = true
	assert_gt(parties.size(), 1, "the floor debate is not limited to one party")
	GameState.start_new_run("PC02")


func test_the_steering_committee_seats_only_the_players_own_party() -> void:
	assert_eq(str(DataDB.get_stage("ST08").get("own_party_only", "")), "Yes", "real ST08 is Own Party Only")
	for player_id: String in ["PC01", "PC02", "PC03", "PC04"]:
		GameState.start_new_run(player_id)
		var party := str(DataDB.player.get("party", ""))
		var seated := BattleSetup.eligible_opponents("ST08")
		assert_gte(seated.size(), 1, "%s has a Steering Committee member" % party)
		for opponent: Dictionary in seated:
			assert_eq(str(opponent.get("party", "")), party, "%s sits on %s's Steering Committee" % [opponent.get("opp_id"), party])
	GameState.start_new_run("PC02")


func test_real_questions_only_ever_name_someone_in_the_room() -> void:
	GameState.start_new_run("PC03")
	for stage_id: String in ["ST04", "ST05", "ST16", "ST20"]:
		var room := {}
		for opponent: Dictionary in BattleSetup.eligible_opponents(stage_id):
			room[str(opponent.get("opp_id", ""))] = true
		var stage := DataDB.get_stage(stage_id)
		var pool: Array = DataDB.questions.get(BattleSetup._question_pool_name(stage, stage_id), [])
		for question: Dictionary in BattleSetup.questions_for_room(pool + DataDB.get_stage_questions(stage_id), stage_id):
			var asker := str(question.get("asked_by", ""))
			if not room.is_empty() and not asker.is_empty():
				assert_true(room.has(asker), "%s %s is asked by %s, who sits in the room" % [stage_id, question.get("id"), asker])
	GameState.start_new_run("PC02")


## A question that names an organization (Asked By Organization, 2026-10-25) is
## asked by someone from it, wherever the room has such a person.
func test_a_question_that_names_an_organization_gets_someone_from_it() -> void:
	var affiliation := {}
	for opp in DataDB.opponents:
		affiliation[str(opp.get("opp_id"))] = str(opp.get("affiliation", ""))
	var checked := 0
	for pool in DataDB.questions.values():
		for q in pool:
			var orgs: Array = q.get("asked_by_orgs", [])
			if orgs.is_empty() or str(q.get("asked_by", "")) == "":
				continue
			checked += 1
			assert_true(orgs.has(affiliation.get(str(q["asked_by"]), "")),
				"%s should be asked by someone from %s" % [q["id"], orgs])
	assert_gt(checked, 20, "the column is used on real questions")
