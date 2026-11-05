extends GutTest
## The extra member visit on a drafted bill (Cameron, 2026-11-05): the draft
## screen may add a second Member Visit and Win Over a Member pair just before
## the vote, to a different member, for hours and XP. Also the fight's title:
## "Convince <member>".

var _saved: Dictionary = {}


func before_each() -> void:
	_saved = GameState.to_save()
	GameState.start_new_run("PC01")
	GameState.xp = 2000
	GameState.meta["Funds"] = 400000
	GameState.funds_cap_bonus = 900000
	GameState.calendar = WeekCalendar.fresh()


func after_each() -> void:
	DataDB.clear_runtime()
	GameState.load_save(_saved)
	DataDB.clear_runtime()


## A three-part bill from three organizations that the rules accept (a
## Flagship: its template always carries a member visit).
func _triple() -> Array:
	var owners := {}
	for component: Dictionary in DataDB.bill_components:
		var owner := str(component["owner"])
		if not owners.has(owner):
			owners[owner] = []
		(owners[owner] as Array).append(str(component["component_id"]))
	var ids: Array = owners.keys()
	for i in ids.size():
		var triple := [(owners[ids[i]] as Array)[0], (owners[ids[(i + 3) % ids.size()]] as Array)[1],
			(owners[ids[(i + 7) % ids.size()]] as Array)[2]]
		if GameState.draft_refusal(triple, true).is_empty():
			return triple
	return []


## Forgets the draft in progress and refills Funds, so a test can draft again.
func _start_over() -> void:
	GameState.abandon_level()
	DataDB.clear_runtime()
	GameState.patron_drafts = {}
	GameState.patron_requests = {}
	GameState.draft_counter = 0
	GameState.last_draft_at = -1
	GameState.meta["Funds"] = 400000


func _stage_ids() -> Array:
	var out: Array = []
	for stage: Dictionary in GameState.level_runner.stages:
		out.append(str(stage.get("stage_id", "")))
	return out


func test_the_extra_visit_adds_a_second_pair_just_before_the_vote() -> void:
	var triple := _triple()
	assert_eq(triple.size(), 3, "a winnable three-part bill exists")
	assert_true(GameState.start_draft(triple, true))
	var stages := _stage_ids()
	var n := stages.size()
	assert_eq(stages.slice(n - 3), [MpVisit.VISIT_STAGE, MpVisit.FIGHT_STAGE, "ST23"],
		"the second pair sits right before the vote")
	assert_eq(stages.count(MpVisit.VISIT_STAGE), 2)
	assert_eq(stages.count(MpVisit.FIGHT_STAGE), 2)
	var level: Dictionary = GameState.patron_runtime["level"]
	assert_true(level.has("visit") and level.has("visit_2"))
	assert_ne(level["visit"]["opp_id"], level["visit_2"]["opp_id"], "never the same member twice")


func test_without_the_toggle_nothing_changes() -> void:
	var triple := _triple()
	assert_true(GameState.start_draft(triple, false))
	assert_eq(_stage_ids().count(MpVisit.VISIT_STAGE), 1)
	assert_false((GameState.patron_runtime["level"] as Dictionary).has("visit_2"))


func test_each_visit_stage_reads_its_own_visit_and_the_fight_is_titled_for_its_member() -> void:
	assert_true(GameState.start_draft(_triple(), true))
	var level: Dictionary = GameState.patron_runtime["level"]
	var fights: Array = []
	var visits: Array = []
	for stage: Dictionary in GameState.level_runner.stages:
		if str(stage.get("stage_id", "")) == MpVisit.FIGHT_STAGE:
			fights.append(stage)
		elif str(stage.get("stage_id", "")) == MpVisit.VISIT_STAGE:
			visits.append(stage)
	assert_eq(fights.size(), 2)
	for i in 2:
		var key := PatronLevel.visit_key(i + 1)
		assert_eq(int((fights[i] as Dictionary)["visit_index"]), i + 1)
		assert_eq(((fights[i] as Dictionary)["opponents"][0] as Dictionary)["opp_id"], level[key]["opp_id"])
		assert_eq(((visits[i] as Dictionary)["visit"] as Dictionary)["opp_id"], level[key]["opp_id"])
		assert_eq(str((fights[i] as Dictionary)["name_en"]),
			"Convince %s" % DataDB.get_opponent(str(level[key]["opp_id"]))["name"],
			"the fight is titled for the member it is against")


func test_a_fight_with_no_known_member_keeps_the_colleague_title() -> void:
	assert_eq(str(DataDB.get_stage(MpVisit.FIGHT_STAGE)["name_en"]), "Convince Your Colleague")


func test_the_current_visit_follows_the_stage_in_progress() -> void:
	assert_true(GameState.start_draft(_triple(), true))
	var level: Dictionary = GameState.patron_runtime["level"]
	var seen: Array = []
	while GameState.level_runner != null and not GameState.level_runner.is_finished():
		var stage := GameState.level_runner.current_stage()
		if str(stage.get("stage_id", "")) == MpVisit.VISIT_STAGE:
			seen.append(str(GameState.current_visit().get("opp_id", "")))
		if str(stage.get("mode", "")) == "Vote":
			break
		GameState.finish_stage(LevelRunner.WON)
	assert_eq(seen, [level["visit"]["opp_id"], level["visit_2"]["opp_id"]])


func test_winning_both_fights_wins_two_seats_and_declining_the_second_keeps_the_first() -> void:
	assert_true(GameState.start_draft(_triple(), true))
	# First fight won, second visit declined.
	while str(GameState.level_runner.current_stage().get("stage_id", "")) != MpVisit.FIGHT_STAGE:
		GameState.finish_stage(LevelRunner.WON)
	GameState.finish_stage(LevelRunner.WON)
	assert_eq(BillAssist.total(GameState.bill_assist, "won_over"), 1)
	while str(GameState.level_runner.current_stage().get("stage_id", "")) != MpVisit.VISIT_STAGE:
		GameState.finish_stage(LevelRunner.WON)
	GameState.skip_member_visit()
	assert_eq(str(GameState.level_runner.current_stage().get("mode", "")), "Vote")
	assert_eq(BillAssist.total(GameState.bill_assist, "won_over"), 1, "the declined visit earned nothing")


func test_both_fights_won_give_two_seats() -> void:
	assert_true(GameState.start_draft(_triple(), true))
	for _round in 2:
		while str(GameState.level_runner.current_stage().get("stage_id", "")) != MpVisit.FIGHT_STAGE:
			GameState.finish_stage(LevelRunner.WON)
		GameState.finish_stage(LevelRunner.WON)
	assert_eq(BillAssist.total(GameState.bill_assist, "won_over"), 2)


func test_it_costs_fifty_more_xp_and_two_hours_more() -> void:
	var triple := _triple()
	var xp := GameState.xp
	assert_true(GameState.start_draft(triple, true))
	assert_eq(GameState.xp, xp - 350 - 50)
	var with_extra := GameState.level_hours(GameState.patron_runtime["level"])
	_start_over()
	xp = GameState.xp
	assert_true(GameState.start_draft(triple, false))
	assert_eq(GameState.xp, xp - 350)
	assert_eq(with_extra - GameState.level_hours(GameState.patron_runtime["level"]), 2,
		"a visit and a fight, an hour each")


func test_the_stage_hours_are_an_hour_each() -> void:
	assert_eq(TimeClock.units_for_stage(DataDB.get_stage(MpVisit.VISIT_STAGE)), 1)
	assert_eq(TimeClock.units_for_stage(DataDB.get_stage(MpVisit.FIGHT_STAGE)), 1)


func test_not_enough_xp_for_the_extra_visit_is_refused_with_the_cost() -> void:
	var triple := _triple()
	GameState.xp = 380   # enough for 350, not for 350 + 50
	assert_eq(GameState.draft_refusal(triple, false), "")
	assert_string_contains(GameState.draft_refusal(triple, true), "400")
	assert_false(GameState.start_draft(triple, true))
	assert_eq(GameState.xp, 380, "nothing was paid")


func test_a_level_too_long_for_the_week_is_refused_with_the_extra_visit() -> void:
	var triple := _triple()
	# How long the plain level is.
	assert_true(GameState.start_draft(triple, false))
	var plain := GameState.level_hours(GameState.patron_runtime["level"])
	_start_over()
	# Leave exactly that many hours: the plain level fits, the extra pair cannot.
	GameState.calendar = WeekCalendar.advance(WeekCalendar.fresh(), 40 - plain, GameState.calendar_config())
	var xp := GameState.xp
	assert_false(GameState.start_draft(triple, true), "plain fits, plain + 2 hours does not")
	assert_ne(GameState.last_level_start_refusal, "")
	assert_eq(GameState.xp, xp, "nothing was paid")
	assert_false(GameState.patron_drafts.has("PD01"), "and no draft was left behind")


func test_the_extra_visit_survives_a_save() -> void:
	assert_true(GameState.start_draft(_triple(), true))
	var level: Dictionary = GameState.patron_runtime["level"]
	var saved := JSON.parse_string(JSON.stringify(GameState.to_save())) as Dictionary
	GameState.load_save(saved)
	var back: Dictionary = GameState.patron_runtime["level"]
	assert_eq(back["visit_2"]["opp_id"], level["visit_2"]["opp_id"])
	assert_eq((back["visit_2"]["questions"] as Array).size(), (level["visit_2"]["questions"] as Array).size())
