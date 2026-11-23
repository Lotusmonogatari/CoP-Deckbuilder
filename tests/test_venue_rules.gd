extends GutTest
## Capitol venues, the pure rules (P16): when the player can step out, what a visit costs, which venues are built.

func test_the_player_may_step_out_only_at_the_capitol_outside_a_level_with_hours_left() -> void:
	assert_eq(VenueRules.step_out_state(true, false, 10), VenueRules.OPEN)
	assert_eq(VenueRules.step_out_state(false, false, 10), VenueRules.ELSEWHERE, "not from the District office")
	assert_eq(VenueRules.step_out_state(true, true, 10), VenueRules.IN_LEVEL, "not during a level")
	assert_eq(VenueRules.step_out_state(true, false, 0), VenueRules.WEEK_FULL, "not once the work week is full")
	assert_eq(VenueRules.step_out_state(false, true, 0), VenueRules.ELSEWHERE, "the first reason wins")


func test_walking_costs_the_rules_rows_and_the_area_adds_its_own() -> void:
	assert_eq(VenueRules.walk_hours("Capitol Building", 0, 0), 0)
	assert_eq(VenueRules.walk_hours("Capital Area", 0, 0), 0)
	assert_eq(VenueRules.walk_hours("Capitol Building", 1, 2), 1)
	assert_eq(VenueRules.walk_hours("Capital Area", 1, 2), 3, "the building, then the area")
	assert_eq(VenueRules.walk_hours("Capital Area", -4, -1), 0, "never negative")


func test_every_venue_is_open_every_day_unless_it_lists_weekdays() -> void:
	for weekday in 7:
		assert_true(VenueRules.open_on({"open_days": "Any"}, weekday), "weekday %d" % weekday)
		assert_true(VenueRules.open_on({"open_days": null}, weekday))
	assert_true(VenueRules.open_on({"open_days": "Mon; Wed"}, 1))
	assert_false(VenueRules.open_on({"open_days": "Mon; Wed"}, 2))


func test_a_visit_costs_its_hours_funds_and_xp_and_says_what_is_short() -> void:
	var eat := {"hours": 1, "funds": 0, "xp": 0}
	assert_eq(VenueRules.visit_cost(eat), {"hours": 1, "funds": 0, "xp": 0})
	assert_eq(VenueRules.visit_cost({"hours": null}), {"hours": 0, "funds": 0, "xp": 0}, "blank cells are 0")
	assert_eq(VenueRules.visit_refusal(eat, 1, 0, 0), "")
	assert_eq(VenueRules.visit_refusal(eat, 0, 0, 0), "hours")
	assert_eq(VenueRules.visit_refusal({"hours": 0, "funds": 500}, 5, 100, 0), "funds")
	assert_eq(VenueRules.visit_refusal({"hours": 0, "xp": 20}, 5, 100, 10), "xp")


func test_only_the_chat_watch_and_train_venues_are_built_in_phase_one() -> void:
	for kind: String in ["chat", "watch", "train"]:
		assert_true(VenueRules.is_built({"kind": kind}), kind)
	for kind: String in ["read", "show", "travel"]:
		assert_false(VenueRules.is_built({"kind": kind}), kind + " is Coming soon")
	assert_true(VenueRules.deals_lines({"kind": "chat"}))
	assert_false(VenueRules.deals_lines({"kind": "train"}))


func test_a_venues_activity_is_found_by_venue_id() -> void:
	var activities := [{"venue_id": "VN01", "kind": "chat"}, {"venue_id": "VN03", "kind": "watch"}]
	assert_eq(VenueRules.activity_of(activities, "VN03")["kind"], "watch")
	assert_true(VenueRules.activity_of(activities, "VN09").is_empty())
