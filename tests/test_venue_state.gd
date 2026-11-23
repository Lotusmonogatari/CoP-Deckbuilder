extends GutTest
## Capitol venues in the run (P16): stepping out, the daily set that survives a reload, hearing up to 8 then the dry line, tips held
## and expired, and old saves.

func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.office_location = Offices.CAPITOL
	GameState.calendar = {"week": 2, "phase": "work", "hours": 0}


func after_each() -> void:
	GameState.office_location = Offices.CAPITOL


func test_the_player_may_step_out_only_from_the_capitol_with_hours_left_and_no_level() -> void:
	assert_eq(GameState.step_out_state(), VenueRules.OPEN)
	GameState.office_location = Offices.DISTRICT
	assert_eq(GameState.step_out_state(), VenueRules.ELSEWHERE)
	assert_ne(GameState.venue_visit_refusal("VN01"), "", "the Cafeteria is not reachable from the District")
	GameState.office_location = Offices.CAPITOL
	GameState.calendar = {"week": 2, "phase": "work", "hours": 40}
	assert_eq(GameState.step_out_state(), VenueRules.WEEK_FULL, "a full work week")


func test_the_library_stage_and_station_are_coming_soon() -> void:
	for venue_id: String in ["VN02", "VN05", "VN06"]:
		assert_eq(GameState.venue_visit_refusal(venue_id), Text.say("venue.coming_soon"), venue_id)
	for venue_id: String in ["VN01", "VN03", "VN04"]:
		assert_ne(GameState.venue_visit_refusal(venue_id), Text.say("venue.coming_soon"), venue_id)


func test_walking_to_the_capital_area_is_free() -> void:
	assert_eq(GameState.venue_walk_hours("VN04"), 0)
	assert_eq(GameState.venue_walk_hours("VN01"), 0)


func test_a_visit_costs_its_hour_once_and_keep_listening_costs_nothing() -> void:
	assert_eq(GameState.work_hours_left(), 40)
	var visit := GameState.venue_visit("VN01")
	assert_true(visit["ok"])
	assert_eq(GameState.work_hours_left(), 39, "Eat with Colleagues takes an hour")
	for i in 8:
		assert_true(GameState.venue_hear_next("VN01")["ok"])
	assert_eq(GameState.work_hours_left(), 39, "no hours inside the visit")


func test_eight_lines_then_one_dry_line_then_come_back_tomorrow() -> void:
	GameState.venue_visit("VN01")
	var kinds: Array = []
	for i in 8:
		var heard := GameState.venue_hear_next("VN01")
		assert_eq(int(heard["number"]), i + 1)
		assert_eq(int(heard["limit"]), 8)
		kinds.append(heard["kind"])
	assert_false(kinds.has("dry"), "eight real lines first")
	var dry := GameState.venue_hear_next("VN01")
	assert_true(dry["ok"])
	assert_eq(dry["kind"], "dry")
	assert_true(dry["last"], "the dry line is the last")
	assert_false(GameState.venue_hear_next("VN01")["ok"], "nothing more today")
	assert_eq(GameState.venue_visit_refusal("VN01"), Text.say("venue.come_back"), "a new visit is refused and costs no hour")
	var hours := GameState.work_hours_left()
	assert_false(GameState.venue_visit("VN01")["ok"])
	assert_eq(GameState.work_hours_left(), hours)


func test_the_next_day_deals_a_fresh_set() -> void:
	var today_set := (GameState.venue_day("VN01")["dealt"] as Array).duplicate(true)
	GameState.calendar = {"week": 2, "phase": "work", "hours": 8}
	var tomorrow := GameState.venue_day("VN01")
	assert_eq(int(tomorrow["heard"]), 0)
	assert_ne(tomorrow["dealt"], today_set)


func test_the_days_set_is_the_same_after_a_save_and_a_reload() -> void:
	var before := (GameState.venue_day("VN03")["dealt"] as Array).duplicate(true)
	GameState.venue_visit("VN03")
	GameState.venue_hear_next("VN03")
	var saved := GameState.to_save()
	GameState.start_new_run("PC01")   # a different run number
	GameState.load_save(saved)
	var after := GameState.venue_day("VN03")
	assert_eq(after["dealt"], before, "a reload does not reshuffle")
	assert_eq(int(after["heard"]), 1, "and remembers what was heard")


func test_a_save_from_before_venues_loads_with_none_and_a_stable_run_number() -> void:
	var saved := GameState.to_save()
	for field: String in ["run_seed", "venue_days", "venue_heard_once", "held_tips"]:
		saved.erase(field)
	GameState.load_save(saved)
	assert_eq(GameState.held_tips, [])
	assert_eq(GameState.venue_days, {})
	var first := GameState.run_seed
	GameState.load_save(saved)
	assert_eq(GameState.run_seed, first, "the same number on every load of the same save")


func _force_hint(venue_id: String, hint: Dictionary) -> void:
	var entry := GameState.venue_day(venue_id)
	entry["dealt"] = [{"line_id": "VL081", "hint": hint}]
	entry["heard"] = 0


func test_hearing_a_tip_holds_it_and_the_text_names_the_stage() -> void:
	var stage_id := ""
	for stage: Dictionary in DataDB.stages:
		if stage.get("favored_suit") != null and str(stage["favored_suit"]) != "—":
			stage_id = str(stage["stage_id"])
			break
	_force_hint("VN01", {"kind": "stage_suit", "target": stage_id, "suit": "Earnest", "text_key": "hint.stage_suit.earnest_1"})
	GameState.venue_visit("VN01")
	var heard := GameState.venue_hear_next("VN01")
	assert_eq(heard["kind"], "hint")
	assert_true(str(heard["text"]).contains(str(DataDB.get_stage(stage_id)["name_en"])), "the stage's own name")
	assert_eq(GameState.tips_held().size(), 1)
	assert_eq(GameState.tips_held()[0]["where"], "cafeteria")


func test_held_tips_cap_at_ten_and_expire_on_the_fifteenth_day() -> void:
	for i in 12:
		GameState.held_tips = RhetoricTips.add(GameState.held_tips, {"kind": "stage_suit", "target": "ST%02d" % (i + 1), "suit": "Earnest",
			"where": "cafeteria", "day": GameState.venue_today() + i}, 10)
	assert_eq(GameState.tips_held().size(), 10)
	GameState.held_tips = [{"kind": "stage_suit", "target": "ST01", "suit": "Earnest", "where": "gardens", "day": GameState.venue_today()}]
	GameState.calendar = {"week": 4, "phase": "work", "hours": 0}   # 14 days on
	assert_eq(GameState.tips_held().size(), 0, "day 15 it is gone")
	GameState.held_tips = [{"kind": "stage_suit", "target": "ST01", "suit": "Earnest", "where": "gardens", "day": GameState.venue_today() - 13}]
	assert_eq(GameState.tips_held().size(), 1, "the 14th day it is still held")
	assert_eq(GameState.tip_days_left(GameState.held_tips[0]), 1)


func test_the_hint_targets_are_only_rooms_and_people_in_levels_on_offer() -> void:
	var offered: Array = []
	for level: Dictionary in GameState.levels_on_offer():
		for slot in range(1, 11):
			var raw: Variant = level.get("stage_%d" % slot)
			if raw != null:
				offered.append(str(raw))
	# The next Decision! scene's own stage (DS05's whip fight) may also be a target.
	for scene: Dictionary in DataDB.decision_scenes:
		if not GameState.decision_log.has(str(scene.get("scene_id", ""))):
			for entry: Dictionary in DecisionScenes.parse_activates(scene.get("activates")):
				offered.append(str(entry["id"]))
			break
	var targets := GameState.tip_targets()
	for target: Dictionary in targets["stage_suit"]:
		var stage := DataDB.get_stage(str(target["id"]))
		assert_true(offered.has(str(target["id"])), "%s is on offer" % target["id"])
		assert_true(stage.get("favored_suit") != null and str(stage["favored_suit"]) != "—", "%s has a Favored Suit" % target["id"])


func test_every_suit_chip_reads_at_4_5_to_1_against_its_white_name() -> void:
	for suit: String in VenueViews.SUIT_COLORS:
		var color: Color = VenueViews.SUIT_COLORS[suit]
		assert_gte(PartyDisplay.contrast(Color.WHITE, color), 4.5, "%s chip contrast" % suit)
