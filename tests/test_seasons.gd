extends GutTest
## Seasons: a seasonal level or event shows only in its seasons' months.

const TABLE := {"Spring": [3, 4, 5], "Summer": [6, 7, 8], "Autumn": [9, 10, 11], "Winter": [12, 1, 2]}


func test_each_month_falls_in_one_season() -> void:
	assert_eq(Seasons.season_of(1, TABLE), "Winter")
	assert_eq(Seasons.season_of(10, TABLE), "Autumn")
	assert_eq(Seasons.season_of(13, TABLE), "")


func test_a_row_with_no_seasons_shows_all_year() -> void:
	for month in range(1, 13):
		assert_true(Seasons.in_season({"seasons": null}, month, TABLE))
		assert_true(Seasons.in_season({}, month, TABLE))


func test_a_winter_row_shows_only_in_winter() -> void:
	var row := {"seasons": ["Winter"]}
	assert_true(Seasons.in_season(row, 12, TABLE))
	assert_true(Seasons.in_season(row, 2, TABLE))
	assert_false(Seasons.in_season(row, 3, TABLE))
	assert_false(Seasons.in_season(row, 8, TABLE))


func test_a_row_can_name_several_seasons() -> void:
	var row := {"seasons": ["Autumn", "Winter"]}
	assert_true(Seasons.in_season(row, 10, TABLE))
	assert_true(Seasons.in_season(row, 1, TABLE))
	assert_false(Seasons.in_season(row, 6, TABLE))


func test_the_real_seasonal_rows_name_real_seasons() -> void:
	var table: Dictionary = DataDB.rules.get("seasons", {})
	assert_false(table.is_empty(), "rules.json has a seasons table")
	for row: Dictionary in DataDB.levels + DataDB.events:
		for season: Variant in (row.get("seasons") if row.get("seasons") is Array else []):
			assert_true(table.has(str(season)), "%s names a real season" % str(season))


func test_a_random_event_out_of_season_never_arrives() -> void:
	var event := {"event_id": "EVX", "trigger": "Random", "weight": 1, "available": "Any",
		"seasons": ["Winter"]}
	var ctx := {"weekend": false, "now": 0, "last_at": {}, "default_cooldown": 0,
		"seasons": TABLE, "month": 7}
	assert_eq(EventEngine.eligible_random([event], ctx), [], "not in July")
	ctx["month"] = 1
	assert_eq(EventEngine.eligible_random([event], ctx).size(), 1, "but in January")
