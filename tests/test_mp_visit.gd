extends GutTest
## The member visit (influence building step B, 2026-10-19): rapport rules,
## the researcher's briefing, the level it adds to a patron Flagship, and what
## winning or skipping it does to the vote.

var _saved: Dictionary = {}


func before_each() -> void:
	_saved = GameState.to_save()
	GameState.start_new_run("PC01")
	GameState.booster_standing["BO05"] = 75
	GameState.booster_standing["BO24"] = 40


func after_each() -> void:
	DataDB.clear_runtime()
	GameState.load_save(_saved)
	DataDB.clear_runtime()


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	return rng


func _member() -> Dictionary:
	return {"opp_id": "OPX", "name": "Test Member", "party": "Five Point Independents",
		"role": "Committee on Finance", "suit_1": "Data Driven", "suit_2": "Earnest", "suit_3": "Appeal"}


func test_the_first_party_with_seats_outside_the_pick_is_chosen() -> void:
	var positions := [
		{"party_id": "PT04", "votes_yes": 5, "votes_no": 0, "votes_abstain": 0},
		{"party_id": "PT02", "votes_yes": 4, "votes_no": 8, "votes_abstain": 2},
	]
	assert_eq(MpVisit.pick_party(["PT04", "PT02"], positions), "PT02", "PT04 is entirely Yes: nothing to win")
	positions[0]["votes_no"] = 1
	assert_eq(MpVisit.pick_party(["PT04", "PT02"], positions), "PT04")
	assert_eq(MpVisit.pick_party(["PT06"], positions), "", "a party not in the bill is skipped")
	assert_eq(MpVisit.pick_party(["PT02"], positions, "No"), "PT02")


func test_a_member_on_the_hearing_committee_is_preferred() -> void:
	# With a committee pool as small as one, the old rule (min_committee_pool 1) still holds;
	# the default draws from the whole party when fewer than three sit on the committee.
	var opponents := [
		{"opp_id": "A", "party": "Frontier Party", "role": "Committee on War"},
		{"opp_id": "B", "party": "Frontier Party", "role": "Committee on Finance"},
		{"opp_id": "C", "party": "Butsutou", "role": "Committee on Finance"},
	]
	for trial in range(10):
		var rng := RandomNumberGenerator.new()
		rng.seed = trial
		assert_eq(MpVisit.pick_member(opponents, "Frontier Party", "Committee on Finance", {}, rng, 1)["opp_id"], "B")
	assert_eq(MpVisit.pick_member(opponents, "Frontier Party", "Committee on Ethics", {}, _rng())["party"], "Frontier Party")
	assert_true(MpVisit.pick_member(opponents, "Keizaijiyuutou", "x", {}, _rng()).is_empty())


func test_styles_grade_against_the_members_own_three() -> void:
	var member := _member()
	assert_eq(MpVisit.grade(member, "Data Driven"), MpVisit.STRONG)
	assert_eq(MpVisit.grade(member, "Earnest"), MpVisit.STRONG)
	assert_eq(MpVisit.grade(member, "Appeal"), MpVisit.MEDIUM)
	assert_eq(MpVisit.grade(member, "Divisive"), MpVisit.WEAK)
	assert_eq(MpVisit.points(MpVisit.STRONG, 1, 0, -1), 1)
	assert_eq(MpVisit.points(MpVisit.WEAK, 1, 0, -1), -1)
	assert_eq(MpVisit.start_bonus(-3, 5), -15)


func test_every_question_offers_four_distinct_styles_with_a_good_answer() -> void:
	var member := _member()
	var rng := _rng()
	for trial in range(60):
		var styles := MpVisit.choose_styles(member, rng)
		assert_eq(styles.size(), 4)
		for style: String in styles:
			assert_eq(styles.count(style), 1)
		assert_true(styles.has("Data Driven") or styles.has("Earnest"), "at least one favored style")


func test_questions_are_built_from_the_real_pools() -> void:
	var questions := MpVisit.build_questions(_member(), DataDB.visit_questions, DataDB.visit_answers, 3,
			"cut the corporate tax rate", _rng())
	assert_eq(questions.size(), 3)
	var seen := []
	for question: Dictionary in questions:
		assert_false(seen.has(question["text"]), "no stem twice")
		seen.append(question["text"])
		assert_true(str(question["text"]).contains("cut the corporate tax rate"))
		assert_false(str(question["text"]).contains("{"))
		assert_eq((question["choices"] as Array).size(), 4)
		for choice: Dictionary in question["choices"]:
			assert_false(str(choice["text"]).is_empty())
			assert_true(choice["grade"] in ["S", "M", "W"])


func test_the_real_pools_are_big_enough_for_the_three_times_rule() -> void:
	assert_gte(DataDB.visit_questions.size(), 3 * int(DataDB.balance["mp_visit_questions"]))
	for style: String in MpVisit.styles():
		var count := 0
		for row: Dictionary in DataDB.visit_answers:
			if row["style"] == style:
				count += 1
		assert_gte(count, 3, style)


func test_only_a_senior_enough_researcher_briefs() -> void:
	assert_false(MpVisit.briefing_available({}, 2), "nobody hired: no briefing")
	assert_false(MpVisit.briefing_available({"Policy Research Assistant": {"staff_id": "SF01", "tier": 1}}, 2))
	assert_true(MpVisit.briefing_available({"Policy Research Assistant": {"staff_id": "SF01", "tier": 2}}, 2))
	assert_false(MpVisit.briefing_available({"Media Spokesperson": {"staff_id": "SF08", "tier": 2}}, 2), "only the researcher counts")
	assert_eq(MpVisit.favored_styles({"suit_1": "Earnest", "suit_2": "Earnest", "suit_3": "Divisive"}), ["Earnest", "Divisive"])


func test_the_template_adds_the_visit_only_when_one_is_offered() -> void:
	var flagship: Dictionary = {}
	for template: Dictionary in DataDB.bill_level_templates:
		if template["template_id"] == "BT02":
			flagship = template
	assert_eq(LevelTemplate.stages(flagship, "ST16", "National", true),
			["ST263", "ST16", "ST260", "ST261", "ST04", "ST03", "ST23"])
	assert_eq(LevelTemplate.stages(flagship, "ST16", "National", false),
			["ST263", "ST16", "ST04", "ST03", "ST23"])


func test_a_favor_level_carries_a_visit_only_some_of_the_time() -> void:
	# Favor templates offer the visit half the time (Visit Chance 50, 2026-11-03).
	var row := PatronLevel.patron_bill("PB051")
	var bill: Dictionary = PatronLevel.compose("PB051", [])["bill"]
	var with_visit := 0
	var without := 0
	var rng := RandomNumberGenerator.new()
	for seed_value in 60:
		rng.seed = seed_value
		if PatronLevel.level_row(row, bill, rng).has("visit"):
			with_visit += 1
		else:
			without += 1
	assert_gt(with_visit, 10, "some Favor levels get a visit")
	assert_gt(without, 10, "and some do not")


func test_a_flagship_level_always_carries_a_visit() -> void:
	DataDB.clear_runtime()
	var built := PatronLevel.register("PB052", [])
	var level: Dictionary = built["level"]
	assert_true(level.has("visit"))
	var visit: Dictionary = level["visit"]
	var template: Dictionary = {}
	for candidate: Dictionary in DataDB.bill_level_templates:
		if str(candidate["template_id"]) == "BT02":
			template = candidate
	assert_true((template["visit_parties"] as Array).has(visit["party_id"]), "a party the template lists")
	var member := DataDB.get_opponent(str(visit["opp_id"]))
	assert_eq(member["party"], visit["party_name"])
	assert_eq((visit["questions"] as Array).size(), 3)
	var runner := LevelRunner.new(BattleSetup.expand_level(level))
	assert_eq(runner.problems().size(), 0, str(runner.problems()))
	assert_true(runner.stages.size() in [7, 8], "with the visit, and a lobbyist trade when one is offered")
	var visit_stage: Dictionary = runner.stages[2]
	var fight_stage: Dictionary = runner.stages[3]
	assert_eq(str(visit_stage["stage_id"]), MpVisit.VISIT_STAGE)
	assert_eq(str(visit_stage["mode"]), "Visit")
	assert_false((visit_stage["visit"] as Dictionary).is_empty())
	assert_eq(str(fight_stage["stage_id"]), MpVisit.FIGHT_STAGE)
	assert_eq((fight_stage["opponents"] as Array).size(), 1)
	assert_eq(fight_stage["opponents"][0]["opp_id"], visit["opp_id"], "the fight is against the visiting member")
	assert_eq(StageRouting.scene_for(visit_stage), StageRouting.VISIT_SCENE)


func _flagship_in_progress() -> void:
	GameState.patron_requests["PB051"] = {"status": PatronRequests.PASSED, "components": ["CB051", "CB052"], "amended": false, "tries": 0}
	assert_true(GameState.start_patron_level("PB052"))


func _play_to(stage_id: String) -> void:
	while str(GameState.level_runner.current_stage().get("stage_id", "")) != stage_id:
		GameState.finish_stage(LevelRunner.WON)


func test_skipping_passes_both_stages_with_nothing_earned() -> void:
	_flagship_in_progress()
	_play_to(MpVisit.VISIT_STAGE)
	var xp := GameState.xp
	var units := GameState.time_units
	GameState.skip_member_visit()
	assert_eq(str(GameState.level_runner.current_stage()["stage_id"]), "ST04")
	assert_eq(GameState.xp, xp)
	assert_eq(GameState.time_units, units)
	assert_true(BillAssist.is_empty(GameState.bill_assist))


func test_rapport_sets_how_the_fight_opens() -> void:
	_flagship_in_progress()
	GameState.current_visit()["rapport"] = 2
	assert_eq(PatronLevel.visit_start_bonus(), 10)
	GameState.current_visit()["rapport"] = -3
	assert_eq(PatronLevel.visit_start_bonus(), -15)
	var stage := BattleSetup.build_stage_for_slot("PL_PB052", MpVisit.FIGHT_STAGE, 4)
	var config := BattleSetup.for_playtest_stage(stage)
	assert_eq(config["start_adjustment"], -15 + int(BattleSetup.backing_bonus(stage).get("start_support", 0)))


func test_winning_the_fight_wins_the_member_over_and_losing_does_not() -> void:
	_flagship_in_progress()
	_play_to(MpVisit.FIGHT_STAGE)
	var party_id := str(GameState.current_visit()["party_id"])
	GameState.finish_stage(LevelRunner.LOST)
	assert_true(BillAssist.is_empty(GameState.bill_assist), "a lost fight costs only the stage")
	assert_true(GameState.is_in_level(), "and does not end the level")
	DataDB.clear_runtime()
	GameState.abandon_level()
	_flagship_in_progress()
	_play_to(MpVisit.FIGHT_STAGE)
	party_id = str(GameState.current_visit()["party_id"])
	GameState.finish_stage(LevelRunner.WON)
	assert_eq(int(GameState.bill_assist["won_over"][party_id]), 1)
	assert_true(bool(GameState.current_visit()["won"]))


func test_a_won_member_is_a_seat_in_the_vote_and_a_story_afterwards() -> void:
	_flagship_in_progress()
	_play_to(MpVisit.FIGHT_STAGE)
	GameState.finish_stage(LevelRunner.WON)
	_play_to("ST23")
	var level_id := str(GameState.patron_runtime["level"]["level_id"])
	var bill := DataDB.get_floor_vote(level_id)
	var plain := FloorVoteEngine.new()
	plain.setup({"bill": bill.duplicate(true), "player_party": str(DataDB.player.get("party", ""))})
	var helped := FloorVoteEngine.new()
	helped.setup({"bill": bill.duplicate(true), "player_party": str(DataDB.player.get("party", "")), "assist": GameState.bill_assist})
	assert_eq(helped.choose("Yes")["totals"]["Yes"], int(plain.choose("Yes")["totals"]["Yes"]) + 1)
	GameState.record_floor_vote(bill, helped.choose("Yes"), "Yes")
	assert_true(GameState.active_news().has("visit_success"))


func test_the_visit_survives_save_and_load() -> void:
	_flagship_in_progress()
	_play_to(MpVisit.VISIT_STAGE)
	var before := GameState.current_visit().duplicate(true)
	var saved := GameState.to_save()
	DataDB.clear_runtime()
	GameState.load_save(saved)
	assert_eq(GameState.current_visit()["opp_id"], before["opp_id"])
	assert_eq((GameState.current_visit()["questions"] as Array).size(), 3)
	assert_eq(str(GameState.level_runner.current_stage()["stage_id"]), MpVisit.VISIT_STAGE)


func test_a_small_committee_pool_draws_from_the_whole_party() -> void:
	var opponents := [
		{"opp_id": "A", "party": "Frontier Party", "role": "Committee on War"},
		{"opp_id": "B", "party": "Frontier Party", "role": "Committee on Finance"},
		{"opp_id": "C", "party": "Frontier Party", "role": "Committee on Agriculture"},
	]
	var seen := {}
	for trial in range(60):
		var rng := RandomNumberGenerator.new()
		rng.seed = trial
		seen[str(MpVisit.pick_member(opponents, "Frontier Party", "Committee on Finance", {}, rng)["opp_id"])] = true
	assert_eq(seen.size(), 3, "one committee member is not enough to always send the same person")


func test_a_party_is_drawn_at_random_when_a_generator_is_given() -> void:
	var positions := [
		{"party_id": "PT01", "votes_yes": 2, "votes_no": 5, "votes_abstain": 0},
		{"party_id": "PT02", "votes_yes": 1, "votes_no": 0, "votes_abstain": 3},
		{"party_id": "PT03", "votes_yes": 9, "votes_no": 0, "votes_abstain": 0},
	]
	var seen := {}
	for trial in range(60):
		var rng := RandomNumberGenerator.new()
		rng.seed = trial
		seen[MpVisit.pick_party(["PT01", "PT02", "PT03"], positions, "Yes", rng)] = true
	assert_true(seen.has("PT01") and seen.has("PT02"), "both parties with seats outside Yes are visited")
	assert_false(seen.has("PT03"), "a party entirely on the player's side is never chosen")
	assert_eq(MpVisit.pick_party(["PT01", "PT02", "PT03"], positions), "PT01", "no generator: the first, as before")


func test_an_answer_of_the_questions_kind_is_preferred_then_the_generic_lines() -> void:
	var answers := [
		{"style": "Earnest", "line_en": "generic", "reply_kind": null},
		{"style": "Earnest", "line_en": "cost line", "reply_kind": "Cost"},
		{"style": "Earnest", "line_en": "voter line", "reply_kind": "Voters"},
	]
	assert_eq(str(MpVisit.answer_lines(answers, "Earnest", "Cost")[0]["line_en"]), "cost line")
	assert_eq(str(MpVisit.answer_lines(answers, "Earnest", "Risk")[0]["line_en"]), "generic", "no Risk line: the generic one")
	assert_eq(str(MpVisit.answer_lines(answers, "Earnest", "")[0]["line_en"]), "generic")


func test_the_questions_take_the_parts_of_the_bill_in_turn() -> void:
	var stems := [{"text_en": "A {component}?"}, {"text_en": "B {component}?"}, {"text_en": "C {component}?"}]
	var questions := MpVisit.build_questions(_member(), stems, DataDB.visit_answers, 3,
			["cut taxes", "fund roads", "open schools"], _rng())
	var texts: Array = questions.map(func(q: Dictionary) -> String: return str(q["text"]))
	for phrase in ["cut taxes", "fund roads", "open schools"]:
		assert_true(texts.any(func(t: String) -> bool: return t.contains(phrase)), phrase)


func test_every_visit_and_trade_question_has_a_reply_kind_with_answers_in_every_style() -> void:
	var kinds := {}
	for row: Dictionary in DataDB.visit_questions + DataDB.trade_questions:
		assert_not_null(row.get("reply_kind"), "%s needs a Reply Kind" % row.get("question_id"))
		kinds[str(row.get("reply_kind"))] = true
	for kind: String in kinds:
		for style in MpVisit.styles():
			var count := 0
			for answer: Dictionary in DataDB.visit_answers:
				if str(answer.get("reply_kind")) == kind and str(answer.get("style")) == style:
					count += 1
			assert_gte(count, 2, "%s needs two %s answers" % [kind, style])


func test_a_member_question_reads_with_a_verb_phrase_where_the_part_goes() -> void:
	# The part is a verb phrase ("fund street lighting"), so what comes before it must be one
	# of the words that takes a verb: "to", "would", "we" or "you", never "Is {part}".
	for row: Dictionary in DataDB.visit_questions:
		var text := str(row["text_en"])
		var at := text.find("{component}")
		var before := text.substr(0, at).strip_edges().split(" ")
		var last := str(before[before.size() - 1]).to_lower()
		assert_true(["to", "would", "we", "you"].has(last), "%s: '%s' ends before the part with '%s'" % [row["question_id"], text, last])


func test_the_part_a_lobbyist_asks_for_is_one_the_player_can_trade() -> void:
	var by_id := ComposedBill.index(DataDB.bill_components)
	var checked := 0
	for row: Dictionary in DataDB.patron_bills:
		var composed := PatronLevel.compose(str(row["patron_bill_id"]), [])
		var level := PatronLevel.level_row(row, composed["bill"], _rng())
		if not level.has("trade"):
			continue
		var trade: Dictionary = level["trade"]
		checked += 1
		var asked := str(trade["asked"])
		assert_true(asked.is_empty() or (trade["drops"] as Array).has(asked), "%s: asked %s is not tradeable" % [row["patron_bill_id"], asked])
		assert_true(by_id.has(asked) or asked.is_empty())
	assert_gt(checked, 5)


## Component plan 4.6 (2026-11-03): the committee share follows the lever.
func test_committee_share_follows_lever() -> void:
	var opponents: Array = []
	for i in range(4):
		opponents.append({"opp_id": "C%d" % i, "party": "Frontier Party", "role": "Committee on Finance"})
	for i in range(4):
		opponents.append({"opp_id": "O%d" % i, "party": "Frontier Party", "role": "Committee on War"})
	var shares := {}
	for percent in [0, 50, 100]:
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		var hits := 0
		for trial in range(400):
			var member := MpVisit.pick_member(opponents, "Frontier Party", "Committee on Finance", {}, rng, 3, percent)
			if str(member["role"]) == "Committee on Finance":
				hits += 1
		shares[percent] = hits
	assert_eq(shares[100], 400, "at 100 every visit is a committee member")
	assert_between(shares[50], 260, 340, "at 50: half certain, half from the whole party (half of which sit there)")
	assert_between(shares[0], 160, 240, "at 0 the whole party, of which half sit there")


## Component plan 4.7 (2026-11-03): parties are drawn by their seats outside Yes.
func test_pick_party_weights_by_open_seats() -> void:
	var positions := [
		{"party_id": "PT01", "votes_yes": 0, "votes_no": 20, "votes_abstain": 0},
		{"party_id": "PT02", "votes_yes": 10, "votes_no": 3, "votes_abstain": 2},
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var big := 0
	for trial in range(500):
		if MpVisit.pick_party(["PT01", "PT02"], positions, "Yes", rng) == "PT01":
			big += 1
	assert_between(big, 360, 440, "20 open seats against 5: about four in five")
