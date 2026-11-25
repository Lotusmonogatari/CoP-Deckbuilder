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


func test_the_player_may_step_out_from_either_office_with_hours_left_and_no_level() -> void:
	assert_eq(GameState.step_out_state(), VenueRules.OPEN)
	GameState.office_location = Offices.DISTRICT
	assert_eq(GameState.step_out_state(), VenueRules.OPEN, "the District office can step out too")
	assert_eq(GameState.venue_visit_refusal("VN01"), Text.say("venue.refuse_elsewhere"), "the Cafeteria is not reachable from the District")
	GameState.office_location = Offices.CAPITOL
	GameState.calendar = {"week": 2, "phase": "work", "hours": 40}
	assert_eq(GameState.step_out_state(), VenueRules.WEEK_FULL, "a full work week")


func test_the_stage_the_stations_library_shrine_and_shotengai_are_all_built() -> void:
	GameState.office_location = Offices.CAPITOL
	assert_eq(GameState.venue_visit_refusal("VN05"), "", "the Stage is built (2026-11-25: Sit and Listen, Watch the Performance)")
	assert_eq(GameState.activity_refusal("VA02"), "", "Browse the Shelves is built (the Codex)")
	assert_eq(GameState.activity_refusal("VA05"), "", "Sit and Listen at the Stage")
	# The shrine, the shotengai and the Library's Nap and reading have activities now (test_venue_activity_state.gd).
	for venue_id: String in ["VN02", "VN08", "VN09"]:
		assert_true(VenueRules.venue_built(DataDB.venue_activities, venue_id), venue_id + " is built")
	assert_true(VenueRules.is_built(VenueRules.activity_of(DataDB.venue_activities, "VN06")), "Sapporo Super Station is built")
	assert_true(VenueRules.is_built(VenueRules.activity_of(DataDB.venue_activities, "VN07")), "the District station is built")
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


const SUIT_PHRASES := {"Earnest": "earnest rhetoric", "Emotional": "emotive rhetoric", "Appeal": "appealing rhetoric",
	"Data Driven": "logical rhetoric and data", "Divisive": "divisive rhetoric", "Duplicitous": "double-speak"}


func test_each_suit_has_its_own_phrase_with_the_agreed_wording() -> void:
	assert_eq(DataDB.suits.size(), SUIT_PHRASES.size())
	var seen := {}
	for suit: Dictionary in DataDB.suits:
		var phrase := VenueViews.rhetoric_phrase(str(suit["element"]))
		assert_eq(phrase, SUIT_PHRASES[str(suit["element"])], "%s" % suit["element"])
		seen[phrase] = true
	assert_eq(seen.size(), DataDB.suits.size(), "each suit has its own phrase")


func test_no_text_row_builds_rhetoric_of_a_suit_or_prints_a_bare_suit_name_in_a_tip_sentence() -> void:
	for key: Variant in DataDB.strings.keys():
		var row: Variant = DataDB.strings[key]
		var english := str((row as Dictionary).get("english", "")) if row is Dictionary else str(row)
		assert_false(english.to_lower().contains("rhetoric of"), "%s says 'rhetoric of ...': %s" % [key, english])
	for key: String in ["venue.tip_responds", "venue.tip_responds_stage", "tips.briefing_responds", "tips.briefing_if_seated"]:
		var sentence := Text.say(key, {"target": "X", "name": "X", "rhetoric": "PHRASE"})
		assert_true(sentence.contains("PHRASE"), "%s takes the suit phrase" % key)
		for suit: String in SUIT_PHRASES:
			assert_false(sentence.contains(suit), "%s does not print the bare suit name %s" % [key, suit])


func test_the_tip_box_and_the_briefing_marks_use_the_suit_phrase() -> void:
	var phrase := VenueViews.rhetoric_phrase("Data Driven")
	assert_eq(Text.say("venue.tip_responds_stage", {"target": "Committee on Finance", "rhetoric": phrase}),
		"The audience in the Committee on Finance responds to logical rhetoric and data")
	assert_eq(Text.say("venue.tip_responds", {"target": "Imekanu Resu", "rhetoric": VenueViews.rhetoric_phrase("Appeal")}),
		"Imekanu Resu responds to appealing rhetoric")
	var box := VenueViews.tip_box({"kind": "stage_suit", "target": "ST16", "suit": "Duplicitous"}, "cafeteria")
	add_child_autofree(box)
	assert_true((box.find_child("TipSentence", true, false) as Label).text.ends_with("double-speak"), "the tip box ends in the phrase")
	var look := OfficeFrameStyles.look()
	for kind: String in ["stage_suit", "opponent_suit"]:
		var target := "ST16" if kind == "stage_suit" else "OP29"
		var mark := LevelBriefingView._tip_mark({"kind": kind, "target": target, "suit": "Data Driven", "where": "cafeteria", "day": 0}, look)
		add_child_autofree(mark)
		var words := ""
		for label: Node in mark.find_children("*", "Label", true, false):
			words += (label as Label).text + " "
		assert_true(words.contains("logical rhetoric and data"), "%s mark: %s" % [kind, words])
		assert_true(words.contains("heard in the Cafeteria"))
		if kind == "opponent_suit":
			assert_true(words.contains("is seated here, they respond to"), "the opponent mark reads as a condition")


# --- Hours on weekdays and weekends (P16b, 2026-11-23) --------------------------------------------------------------------------

const WEEK_FULL := {"week": 2, "phase": "work", "hours": 40}
const WEEKEND_FULL := {"week": 2, "phase": "weekend", "hours": 8}
const WEEKEND_OPEN := {"week": 2, "phase": "weekend", "hours": 0}


func test_step_out_is_greyed_with_its_reason_when_the_work_week_is_full() -> void:
	GameState.calendar = WEEK_FULL.duplicate()
	assert_eq(GameState.step_out_state(), VenueRules.WEEK_FULL)
	assert_eq(GameState.step_out_refusal(), Text.say("venue.refuse_week_full"))


func test_step_out_is_greyed_with_its_reason_when_no_weekend_hours_are_left() -> void:
	GameState.calendar = WEEKEND_FULL.duplicate()
	assert_eq(GameState.step_out_state(), VenueRules.WEEK_FULL)
	assert_eq(GameState.step_out_refusal(), Text.say("venue.no_hours_weekend"), "the weekend's own words")
	assert_ne(Text.say("venue.no_hours_weekend"), Text.say("venue.refuse_week_full"))


func test_step_out_is_available_on_a_weekend_while_weekend_hours_are_left() -> void:
	GameState.calendar = WEEKEND_OPEN.duplicate()
	assert_eq(GameState.step_out_state(), VenueRules.OPEN)
	assert_eq(GameState.step_out_refusal(), "")
	assert_eq(GameState.venue_visit_refusal("VN01"), "")


func test_a_weekend_visit_spends_weekend_hours_and_leaves_the_work_week_alone() -> void:
	GameState.calendar = WEEKEND_OPEN.duplicate()
	assert_true(GameState.venue_visit("VN01")["ok"])
	assert_eq(GameState.calendar["phase"], "weekend")
	assert_eq(int(GameState.calendar["hours"]), 1, "one weekend hour spent")
	assert_eq(GameState.work_hours_left(), 7, "of the weekend's eight")
	GameState.calendar = {"week": 2, "phase": "work", "hours": 0}
	assert_eq(GameState.work_hours_left(), 40, "the work week is untouched by a weekend visit")


func test_an_activity_needing_more_hours_than_are_left_is_refused_with_no_hour_taken_and_no_line_dealt() -> void:
	var activity := VenueRules.activity_of(DataDB.venue_activities, "VN01")
	var saved: Variant = activity["hours"]
	activity["hours"] = 2
	for case: Array in [[{"week": 2, "phase": "work", "hours": 39}, "venue.refuse_hours"], [{"week": 2, "phase": "weekend", "hours": 7}, "venue.refuse_hours_weekend"]]:
		GameState.venue_days = {}
		GameState.calendar = (case[0] as Dictionary).duplicate()
		assert_eq(GameState.venue_visit_refusal("VN01"), Text.say(str(case[1])), str(case[1]))
		var before := GameState.work_hours_left()
		var result := GameState.venue_visit("VN01")
		assert_false(result["ok"])
		assert_eq(GameState.work_hours_left(), before, "no hour taken")
		assert_false(GameState.venue_days.has("VN01"), "no set dealt for a refused visit")
	activity["hours"] = saved


func test_a_one_hour_activity_is_refused_at_zero_hours_and_deals_nothing() -> void:
	for calendar: Dictionary in [WEEK_FULL, WEEKEND_FULL]:
		GameState.venue_days = {}
		GameState.calendar = calendar.duplicate()
		assert_false(GameState.venue_visit("VN01")["ok"])
		assert_false(GameState.venue_visit("VN03")["ok"])
		assert_true(GameState.venue_days.is_empty(), "nothing dealt")


func test_looking_at_a_venue_deals_nothing() -> void:
	assert_true(GameState.venue_day_peek("VN01").is_empty())
	assert_false(GameState.venue_days.has("VN01"))
	GameState.venue_visit("VN01")
	assert_false(GameState.venue_day_peek("VN01").is_empty(), "a real visit deals the set")


func test_keep_listening_stays_free_even_when_the_visit_took_the_last_hour() -> void:
	GameState.calendar = {"week": 2, "phase": "work", "hours": 39}
	assert_true(GameState.venue_visit("VN01")["ok"])
	assert_eq(GameState.work_hours_left(), 0, "the last hour is gone")
	for i in 3:
		assert_true(GameState.venue_hear_next("VN01")["ok"], "line %d is still heard" % (i + 1))
	assert_eq(GameState.work_hours_left(), 0)


func test_the_map_lists_the_capitols_places_at_the_capitol_and_the_station_at_the_district() -> void:
	var ids := func() -> Array: return GameState.venues_here().map(func(v: Dictionary) -> String: return str(v["venue_id"]))
	assert_eq(ids.call(), ["VN01", "VN02", "VN03", "VN04", "VN05", "VN06"])
	GameState.office_location = Offices.DISTRICT
	assert_eq(ids.call(), ["VN07", "VN08", "VN09"], "the District office has its station, shrine and shotengai only")


func test_the_district_station_is_named_for_the_district_office() -> void:
	var town := GameState.district_office_name()
	assert_ne(town, "", "the test protagonist has a District office")
	var station := GameState.venue_row("VN07")
	assert_eq(str(station["name"]), "%s Station" % town)
	assert_eq(str(station["background"]), "AREA_%s_STATION" % town.to_upper().replace(" ", "_"))
	assert_true(ResourceLoader.exists("res://assets/backgrounds/%s.png" % station["background"]), "the picture is in the project")


func test_every_district_office_has_its_station_picture() -> void:
	for protagonist: Dictionary in DataDB.protagonists:
		var picture := VenueRules.fill_office("AREA_{OFFICE_ID}_STATION", str(protagonist.get("district_office", "")))
		assert_true(ResourceLoader.exists("res://assets/backgrounds/%s.png" % picture), picture)


func test_the_district_shrine_and_shotengai_use_the_protagonists_own_pictures() -> void:
	for protagonist: Dictionary in DataDB.protagonists:
		var pc := str(protagonist.get("player_id", ""))
		for stem: String in ["AREA_SHRINE_", "AREA_SHOTENGAI_"]:
			assert_true(ResourceLoader.exists("res://assets/backgrounds/%s%s.png" % [stem, pc]), stem + pc)
	assert_eq(str(GameState.venue_row("VN08")["background"]), "AREA_SHRINE_%s" % GameState.protagonist_id)
	assert_eq(str(GameState.venue_row("VN09")["background"]), "AREA_SHOTENGAI_%s" % GameState.protagonist_id)
	assert_true(ResourceLoader.exists("res://assets/icons/ACT_SHRINE.png") and ResourceLoader.exists("res://assets/icons/ACT_SHOTENGAI.png"))
