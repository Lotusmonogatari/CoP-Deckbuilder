extends GutTest
## Capitol venues, the pure rules (P16): when the player can step out, what a visit costs, which venues are built.

func test_the_player_may_step_out_at_either_office_outside_a_level_with_hours_left() -> void:
	assert_eq(VenueRules.step_out_state(false, 10), VenueRules.OPEN)
	assert_eq(VenueRules.step_out_state(true, 10), VenueRules.IN_LEVEL, "not during a level")
	assert_eq(VenueRules.step_out_state(false, 0), VenueRules.WEEK_FULL, "not once the work week is full")
	assert_eq(VenueRules.step_out_state(true, 0), VenueRules.IN_LEVEL, "the first reason wins")


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


func test_every_kind_but_the_show_is_built() -> void:
	for kind: String in ["chat", "watch", "train", "travel", "act", "read", "research"]:
		assert_true(VenueRules.is_built({"kind": kind}), kind)
	for kind: String in ["show"]:
		assert_false(VenueRules.is_built({"kind": kind}), kind + " is Coming soon")
	assert_true(VenueRules.deals_lines({"kind": "chat"}))
	assert_false(VenueRules.deals_lines({"kind": "train"}))


func test_a_venues_activity_is_found_by_venue_id() -> void:
	var activities := [{"venue_id": "VN01", "kind": "chat"}, {"venue_id": "VN03", "kind": "watch"}]
	assert_eq(VenueRules.activity_of(activities, "VN03")["kind"], "watch")
	assert_true(VenueRules.activity_of(activities, "VN09").is_empty())


func test_a_venue_shows_its_seasonal_picture_when_one_exists_and_the_plain_one_otherwise() -> void:
	var have := ["CAPITOL_GARDENS", "CAPITOL_GARDENS_AUTUMN", "CAPITOL_GARDENS_WINTER", "CAPITOL_CAFETERIA"]
	var exists := func(id: String) -> bool: return have.has(id)
	assert_eq(VenueRules.seasonal_background("CAPITOL_GARDENS", "Winter", exists), "CAPITOL_GARDENS_WINTER")
	assert_eq(VenueRules.seasonal_background("CAPITOL_GARDENS", "Autumn", exists), "CAPITOL_GARDENS_AUTUMN")
	assert_eq(VenueRules.seasonal_background("CAPITOL_GARDENS", "Spring", exists), "CAPITOL_GARDENS", "no spring picture: the plain one")
	assert_eq(VenueRules.seasonal_background("CAPITOL_CAFETERIA", "Winter", exists), "CAPITOL_CAFETERIA", "a venue with no seasons never changes")
	assert_eq(VenueRules.seasonal_background("CAPITOL_GARDENS", "", exists), "CAPITOL_GARDENS", "no season known: the plain one")
	assert_eq(VenueRules.seasonal_background("", "Winter", exists), "")


func test_the_real_gardens_pictures_follow_the_rules_tables_months() -> void:
	var gardens := {"background": "CAPITOL_GARDENS"}
	var table: Dictionary = DataDB.rules.get("seasons", {})
	assert_eq(VenuesController.venue_picture_id(gardens, 1, table), "CAPITOL_GARDENS_WINTER", "January is winter")
	assert_eq(VenuesController.venue_picture_id(gardens, 10, table), "CAPITOL_GARDENS_AUTUMN", "October is autumn")
	assert_eq(VenuesController.venue_picture_id(gardens, 6, table), "CAPITOL_GARDENS", "summer uses the plain picture")


func test_the_map_lists_the_offices_own_places() -> void:
	var venues := [{"venue_id": "VN07", "zone": "District", "order": 7}, {"venue_id": "VN02", "zone": "Capitol Building", "order": 2},
		{"venue_id": "VN06", "zone": "Capital Area", "order": 6}]
	var at_capitol := VenueRules.venues_at(venues, true).map(func(v: Dictionary) -> String: return str(v["venue_id"]))
	assert_eq(at_capitol, ["VN02", "VN06"], "the Capitol's places in Order, never the District's")
	var at_district := VenueRules.venues_at(venues, false).map(func(v: Dictionary) -> String: return str(v["venue_id"]))
	assert_eq(at_district, ["VN07"], "only the District's own place at the District office")


func test_a_district_places_name_and_picture_follow_the_office() -> void:
	assert_eq(VenueRules.fill_office("{office} Station", "Daikoku"), "Daikoku Station")
	assert_eq(VenueRules.fill_office("AREA_{OFFICE_ID}_STATION", "Akeno Shinmachi"), "AREA_AKENO_SHINMACHI_STATION")
	assert_eq(VenueRules.fill_office("AREA_{OFFICE_ID}_STATION", "Teine Ward"), "AREA_TEINE_WARD_STATION")
	assert_eq(VenueRules.fill_office("Cafeteria", "Daikoku"), "Cafeteria", "a venue with no token is unchanged")
	assert_eq(VenueRules.fill_office("{office} Station", ""), "{office} Station", "no office known: left as written")


func test_a_station_has_a_tracks_picture_only_when_one_exists() -> void:
	var have := ["AREA_SUPER_STATION", "AREA_SUPER_STATION_TRACKS"]
	var exists := func(id: String) -> bool: return have.has(id)
	assert_eq(VenueRules.tracks_background("AREA_SUPER_STATION", exists), "AREA_SUPER_STATION_TRACKS")
	assert_eq(VenueRules.tracks_background("AREA_DAIKOKU_STATION", exists), "", "a District station is one screen")
	assert_eq(VenueRules.tracks_background("", exists), "")


func test_the_travel_kind_is_built() -> void:
	assert_true(VenueRules.is_built({"kind": "travel"}))


func test_a_district_places_picture_follows_the_protagonist() -> void:
	assert_eq(VenueRules.fill_protagonist("AREA_SHRINE_{PC_ID}", "PC03"), "AREA_SHRINE_PC03")
	assert_eq(VenueRules.fill_protagonist("AREA_SHRINE_{PC_ID}", ""), "AREA_SHRINE_{PC_ID}", "no protagonist yet: left as written")
	assert_eq(VenueRules.fill_protagonist("Cafeteria", "PC01"), "Cafeteria")
