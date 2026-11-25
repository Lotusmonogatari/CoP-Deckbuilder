extends GutTest
## Area Characters (2026-11-25): who appears where (VEN by Site, CA/CB/DI by zone, narrowed by Site), the seeded pick, the speaker word
## `area` in a venue line, the speech coach as VEN01, and the art folder for each prefix.

var _people := [
	{"character_id": "VEN01", "name": "Coach", "site": "VN04"},
	{"character_id": "VEN02", "name": "Two-venue", "site": "VN04; VN06"},
	{"character_id": "CA01", "name": "Area", "site": null},
	{"character_id": "CB01", "name": "Capitol", "site": null},
	{"character_id": "CB02", "name": "Library regular", "site": "VN02"},
	{"character_id": "DI01", "name": "District", "site": null},
]
var _cafeteria := {"venue_id": "VN01", "zone": "Capitol Building"}
var _library := {"venue_id": "VN02", "zone": "Capitol Building"}
var _coach_room := {"venue_id": "VN04", "zone": "Capital Area"}
var _district := {"venue_id": "VN08", "zone": "District"}


func _ids(pool: Array) -> Array:
	return pool.map(func(c: Dictionary) -> String: return str(c["character_id"]))


func test_a_ven_person_appears_only_at_the_venues_in_their_site() -> void:
	assert_eq(_ids(AreaCharacters.pool_for(_people, _coach_room)), ["VEN01", "VEN02", "CA01"])
	assert_false(AreaCharacters.appears_at(_people[0], _cafeteria), "the coach is not in the Cafeteria")
	assert_eq(AreaCharacters.sites(_people[1]), ["VN04", "VN06"] as Array[String], "several venues, semicolon separated")


func test_a_zone_person_appears_across_their_zone_and_a_site_narrows_them() -> void:
	assert_eq(_ids(AreaCharacters.pool_for(_people, _cafeteria)), ["CB01"], "CB02 is narrowed to the Library")
	assert_eq(_ids(AreaCharacters.pool_for(_people, _library)), ["CB01", "CB02"])
	assert_eq(_ids(AreaCharacters.pool_for(_people, _district)), ["DI01"])
	assert_false(AreaCharacters.appears_at(_people[2], _district), "a Capital Area person is not in the District")


func test_a_ven_person_with_no_site_appears_nowhere() -> void:
	assert_false(AreaCharacters.appears_at({"character_id": "VEN09", "site": null}, _coach_room))


func test_the_pick_is_the_same_for_the_same_seed_and_empty_for_an_empty_pool() -> void:
	var pool := AreaCharacters.pool_for(_people, _library)
	assert_eq(AreaCharacters.pick(pool, 7), AreaCharacters.pick(pool, 7))
	assert_eq(AreaCharacters.pick([], 7), "")
	var seen := {}
	for seed_value in range(20):
		seen[AreaCharacters.pick(pool, seed_value)] = true
	assert_eq(seen.size(), 2, "both people come up over different seeds")


func test_ids_are_recognised_by_prefix() -> void:
	for id: String in ["VEN01", "CA01", "CB12", "DI03"]:
		assert_true(AreaCharacters.is_area_id(id), id)
	for id: String in ["CP01", "OP10", "VI05", "SF01", "PC01", "DIANA", "CAT", "VN04"]:
		assert_false(AreaCharacters.is_area_id(id), id)
	assert_eq(DecisionScenes.person_kind("VEN01"), "area")


func test_the_art_folder_follows_the_prefix() -> void:
	for id: String in ["VEN01", "CA01", "CB01", "DI01"]:
		assert_eq(ArtLoader.character_folder(id), "res://assets/characters/area/", id)
	assert_eq(ArtLoader.character_folder("CP09"), "res://assets/characters/opponents/", "a cosmetic package ID is not an area character")


func test_the_speech_coach_is_ven01_and_stands_at_the_speech_coach_only() -> void:
	var coach := DataDB.get_area_character("VEN01")
	assert_eq(str(coach["name"]), "Masayuki Katō")
	assert_eq(str(coach["site"]), "VN04")
	for venue: Dictionary in DataDB.venues:
		assert_eq(AreaCharacters.appears_at(coach, venue), str(venue["venue_id"]) == "VN04", str(venue["venue_id"]))


func test_a_line_that_names_area_takes_someone_from_the_venues_pool() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	var real_people := DataDB.area_characters
	var real_lines := DataDB.venue_lines
	DataDB.area_characters = [{"character_id": "CB01", "name": "Capitol regular", "site": null}]
	for row: Dictionary in DataDB.venue_lines:
		if str(row.get("line_id", "")) == "VL001":
			row["speaker"] = "area"
	var entry := GameState.venue_day("VN01")
	(entry["dealt"] as Array)[0] = {"line_id": "VL001", "hint": {}}
	GameState.venue_visit("VN01")
	var heard := GameState.venue_hear_next("VN01")
	assert_eq(str(heard["speaker"]), "CB01", "the Cafeteria's pool is the Capitol interior's people")
	DataDB.area_characters = []
	var again := GameState._venue_speaker("area", "VN01", "x")
	assert_eq(again, "", "an empty pool makes the line narration")
	DataDB.area_characters = real_people
	DataDB.venue_lines = real_lines
	for row: Dictionary in DataDB.venue_lines:
		if str(row.get("line_id", "")) == "VL001":
			row["speaker"] = null
