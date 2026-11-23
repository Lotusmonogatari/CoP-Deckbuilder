extends GutTest
## A level must not run over a Decision! (P15, 2026-11-23): a Mandatory scene refuses it, an Optional one warns.

var cfg := WeekCalendar.settings({})
## Week 2 begins on Monday 18.10.15.
var monday := {"week": 2, "phase": "work", "hours": 0}


func _day(text: String) -> int:
	return WeekCalendar.parse_date(text)


func _mandatory(day_text: String, id: String = "DS10") -> Dictionary:
	return {"scene_id": id, "kind": "Mandatory", "opens": day_text}


func test_hours_left_before_a_later_day_this_week() -> void:
	assert_eq(DecisionClash.hours_until_day(monday, cfg, _day("18.10.18")), 24, "Thursday: today's 8 and two whole days")
	assert_eq(DecisionClash.hours_until_day(monday, cfg, _day("18.10.16")), 8, "Tuesday: just today")
	var tuesday := {"week": 2, "phase": "work", "hours": 8}
	assert_eq(DecisionClash.hours_until_day(tuesday, cfg, _day("18.10.18")), 16)
	var midday := {"week": 2, "phase": "work", "hours": 12}
	assert_eq(DecisionClash.hours_until_day(midday, cfg, _day("18.10.18")), 12, "four hours into Tuesday leaves four of Tuesday")


func test_a_scene_today_or_past_has_no_room_and_one_in_another_week_is_not_protected() -> void:
	assert_eq(DecisionClash.hours_until_day(monday, cfg, _day("18.10.15")), 0)
	assert_eq(DecisionClash.hours_until_day(monday, cfg, _day("18.10.10")), 0)
	assert_eq(DecisionClash.hours_until_day(monday, cfg, _day("18.10.22")), -1, "next Monday: a level never crosses the week")
	var weekend := {"week": 2, "phase": "weekend", "hours": 0}
	assert_eq(DecisionClash.hours_until_day(weekend, cfg, _day("18.10.22")), -1)


func test_a_level_that_runs_over_a_mandatory_scene_is_refused() -> void:
	var scenes := [_mandatory("18.10.18")]
	assert_true(DecisionClash.mandatory_clash(scenes, {}, monday, cfg, 24).is_empty(), "24 hours end the evening before")
	var clash := DecisionClash.mandatory_clash(scenes, {}, monday, cfg, 25)
	assert_eq(str((clash["scene"] as Dictionary)["scene_id"]), "DS10")
	assert_eq(int(clash["hours"]), 24)


func test_an_answered_scene_and_a_scene_next_week_never_clash() -> void:
	var scenes := [_mandatory("18.10.18")]
	assert_true(DecisionClash.mandatory_clash(scenes, {"DS10": {"day": 1, "choice": "A"}}, monday, cfg, 40).is_empty())
	assert_true(DecisionClash.mandatory_clash([_mandatory("18.10.22")], {}, monday, cfg, 40).is_empty())


func test_a_follow_up_scene_is_protected_once_its_day_is_known() -> void:
	var scenes := [{"scene_id": "DS11", "kind": "Mandatory", "follows": "DS10", "delay": 3}]
	assert_true(DecisionClash.mandatory_clash(scenes, {}, monday, cfg, 40).is_empty(), "the earlier scene is not answered yet")
	var log := {"DS10": {"day": _day("18.10.15"), "choice": "A"}}
	assert_false(DecisionClash.mandatory_clash(scenes, log, monday, cfg, 30).is_empty(), "due Thursday: 24 hours of room")


func test_an_optional_scene_warns_when_the_level_outlasts_its_window() -> void:
	var scene := {"scene_id": "DS12", "kind": "Optional", "opens": "18.10.16", "closes": "18.10.17"}
	assert_true(DecisionClash.optional_clash([scene], {}, monday, cfg, 24).is_empty(), "24 hours end Wednesday evening, the last day")
	var warned := DecisionClash.optional_clash([scene], {}, monday, cfg, 25)
	assert_eq(int(warned["closes"]), _day("18.10.17"))
	assert_true(DecisionClash.optional_clash([scene], {"DS12": {"day": 1, "choice": "A"}}, monday, cfg, 40).is_empty(), "answered")


func test_the_after_hours_trip_costs_up_to_the_cap() -> void:
	assert_eq(DecisionClash.evening_xp_cost(500, 100), 100)
	assert_eq(DecisionClash.evening_xp_cost(100, 100), 100)
	assert_eq(DecisionClash.evening_xp_cost(60, 100), 60, "all the XP the player has")
	assert_eq(DecisionClash.evening_xp_cost(0, 100), 0)
	assert_eq(DecisionClash.evening_xp_cost(-5, 100), 0)


func test_a_chain_is_dated_from_its_first_scene_by_delays() -> void:
	var scenes := [{"scene_id": "A", "opens": "18.10.22"}, {"scene_id": "B", "follows": "A", "delay": 3},
		{"scene_id": "C", "follows": "B", "delay": 0}, {"scene_id": "D", "follows": "A", "delay": 7}]
	var days := DecisionScenes.chain_days(scenes, "A")
	assert_eq(days["A"], _day("18.10.22"))
	assert_eq(days["B"], _day("18.10.25"))
	assert_eq(days["C"], _day("18.10.25"), "a delay of 0 is the same day")
	assert_eq(days["D"], _day("18.10.29"))
