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
	var opponents := [
		{"opp_id": "A", "party": "Frontier Party", "role": "Committee on War"},
		{"opp_id": "B", "party": "Frontier Party", "role": "Committee on Finance"},
		{"opp_id": "C", "party": "Butsutou", "role": "Committee on Finance"},
	]
	for trial in range(10):
		var rng := RandomNumberGenerator.new()
		rng.seed = trial
		assert_eq(MpVisit.pick_member(opponents, "Frontier Party", "Committee on Finance", {}, rng)["opp_id"], "B")
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
	for style: String in MpVisit.STYLES:
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
		if template["kind"] == "Flagship":
			flagship = template
	assert_eq(LevelTemplate.stages(flagship, "ST16", "National", true),
			["ST20", "ST16", "ST260", "ST261", "ST04", "ST03", "ST23"])
	assert_eq(LevelTemplate.stages(flagship, "ST16", "National", false),
			["ST20", "ST16", "ST04", "ST03", "ST23"])


func test_a_flagship_level_carries_a_visit_and_a_favor_does_not() -> void:
	var favor := PatronLevel.register("PB051", [])
	assert_false((favor["level"] as Dictionary).has("visit"))
	DataDB.clear_runtime()
	var built := PatronLevel.register("PB052", [])
	var level: Dictionary = built["level"]
	assert_true(level.has("visit"))
	var visit: Dictionary = level["visit"]
	assert_true(["PT04", "PT02"].has(visit["party_id"]))
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
