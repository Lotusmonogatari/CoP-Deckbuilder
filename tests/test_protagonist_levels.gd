extends GutTest
## Two offices, slice 6 (2026-11-20): the eight protagonist levels, each offered to one protagonist and to one office.

const LEVELS := {
	"LV115": ["PC01", "District"], "LV116": ["PC01", "Capitol"],   # Wakkanai: the Soya Line, the Sakhalin Ferry
	"LV117": ["PC02", "District"], "LV118": ["PC02", "Capitol"],   # Tomakomai: carbon under the harbor, the casino
	"LV119": ["PC03", "District"], "LV120": ["PC03", "Capitol"],   # Teine and Ishikari: wind, the tunnel
	"LV121": ["PC04", "District"], "LV122": ["PC04", "Capitol"],   # Aomori: Rokkasho, the bluefin quota
}


func after_each() -> void:
	DataDB.use_protagonist("PC04")
	GameState.protagonist_id = "PC04"
	GameState.office_location = Offices.CAPITOL


func test_each_level_belongs_to_one_protagonist_and_one_office() -> void:
	for id: String in LEVELS:
		var level := DataDB.get_level(id)
		assert_false(level.is_empty(), "%s exists" % id)
		assert_eq(level.get("protagonist"), [LEVELS[id][0]], "%s is for %s" % [id, LEVELS[id][0]])
		assert_eq(Offices.normalize(level.get("location")), LEVELS[id][1], "%s starts at the %s" % [id, LEVELS[id][1]])
		assert_eq(Travel.level_trips(level), 0, "%s has no built-in trips" % id)
	assert_eq(DataDB.levels.size(), 122)


func test_a_level_is_offered_only_to_its_protagonist() -> void:
	for id: String in LEVELS:
		for pid: String in ["PC04", "PC02", "PC03", "PC01"]:
			GameState.protagonist_id = pid
			assert_eq(GameState.level_is_for_player(DataDB.get_level(id)), pid == LEVELS[id][0], "%s for %s" % [id, pid])
	GameState.protagonist_id = "PC04"
	assert_true(GameState.level_is_for_player(DataDB.get_level("LV01")), "an ordinary level is for everyone")


func test_a_district_level_reads_in_its_own_places() -> void:
	DataDB.use_protagonist("PC03")
	assert_string_contains(str(DataDB.get_level("LV119").get("purpose")), "Ishikari", "the beach is PC03's own")
	DataDB.use_protagonist("PC01")
	assert_string_contains(str(DataDB.get_level("LV116").get("purpose")), "Cape Sōya")
	DataDB.use_protagonist("PC02")
	assert_string_contains(str(DataDB.get_level("LV118").get("purpose")), "Lake Utonai")
	for pid: String in ["PC04", "PC02", "PC03", "PC01"]:
		DataDB.use_protagonist(pid)
		for id: String in LEVELS:
			assert_false(str(DataDB.get_level(id).get("purpose")).contains("{"), "%s for %s has no token left" % [id, pid])


func test_the_levels_fit_the_week_and_use_existing_rooms() -> void:
	for id: String in LEVELS:
		var level := DataDB.get_level(id)
		var hours := GameState.level_hours(level)
		assert_between(hours, 8, 16, "%s is %d hours" % [id, hours])
		assert_true(LevelRunner.new(BattleSetup.expand_level(level)).is_valid(), "%s builds" % id)


func test_the_casino_costs_standing_with_two_organizations() -> void:
	var range_cell: Variant = DataDB.get_level("LV118").get("win_delta_bo26")
	assert_eq(LevelBonus.range_of(range_cell), {"min": -2, "max": -1})
	assert_eq(LevelBonus.range_of(DataDB.get_level("LV118").get("win_delta_bo19")), {"min": -2, "max": -1})


func test_the_wind_level_is_for_the_autumn() -> void:
	# The spec also asked for weekend play, but a weekend level must fit a 4-hour day and these are 11 hours.
	var level := DataDB.get_level("LV119")
	assert_eq(level.get("seasons"), ["Autumn"])
	assert_ne(str(level.get("weekend_ok")), "Yes")
	assert_eq(DataDB.get_level("LV122").get("seasons"), ["Autumn", "Winter"], "tuna season")
