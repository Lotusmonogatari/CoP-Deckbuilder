extends GutTest
## The District versions of the shared rooms and the pictures on the travel-mode buttons (Cameron, 2026-11-20): at the District
## office the Lobbyist Meeting, Policy Study and Media Ambush rooms show picture 1 to 4 for PC01 to PC04; at the Capitol nothing
## changes; a stage that borrows a shared room follows it; and each travel mode has its picture.

const ROOMS := {"ST19": "DISTRICT_AMBUSH_STREET", "ST20": "DISTRICT_LOBBYIST_MEETING", "ST21": "DISTRICT_POLICY_STUDY"}


func after_each() -> void:
	GameState.office_location = Offices.CAPITOL


# --- the pure rule -------------------------------------------------------------------------------------------------

func test_the_nth_picture_belongs_to_the_nth_protagonist_at_the_district_only() -> void:
	var rooms := {"ST20": ["A", "B", "C", "D"]}
	assert_eq(DistrictRooms.picture(rooms, "ST20", "PC01", true), "A")
	assert_eq(DistrictRooms.picture(rooms, "ST20", "PC02", true), "B")
	assert_eq(DistrictRooms.picture(rooms, "ST20", "PC03", true), "C")
	assert_eq(DistrictRooms.picture(rooms, "ST20", "PC04", true), "D")
	assert_eq(DistrictRooms.picture(rooms, "ST20", "PC02", false), "", "at the Capitol nothing changes")


func test_an_unknown_room_or_protagonist_changes_nothing() -> void:
	var rooms := {"ST20": ["A", "B", "C", "D"]}
	assert_eq(DistrictRooms.picture(rooms, "ST05", "PC01", true), "")
	assert_eq(DistrictRooms.picture(rooms, "ST20", "PC09", true), "")
	assert_eq(DistrictRooms.picture(rooms, "ST20", "", true), "")
	assert_eq(DistrictRooms.picture(rooms, "ST20", "XX01", true), "")
	assert_eq(DistrictRooms.protagonist_number("PC03"), 3)
	assert_eq(DistrictRooms.protagonist_number("PCx"), 0)


# --- the data --------------------------------------------------------------------------------------------------------

func test_each_shared_room_has_four_pictures_and_every_file_exists() -> void:
	var rooms: Dictionary = DataDB.art.get("district_backgrounds", {})
	for room: String in ROOMS:
		var list: Array = rooms.get(room, [])
		assert_eq(list.size(), 4, room + " has one picture for each protagonist")
		for picture: Variant in list:
			assert_true(FileAccess.file_exists("res://assets/backgrounds/%s.png" % str(picture)), str(picture) + " exists")
		assert_true(str(list[0]).begins_with(str(ROOMS[room])), room + "'s pictures are the District ones")
	assert_true(rooms.get("ST21") is Array and str(rooms["ST21"][1]).ends_with("POLICY_STUDY_2"), "file number equals protagonist number")


# --- the loader, through real stages -------------------------------------------------------------------------------

func _path(stage_id: String) -> String:
	return ArtLoader.background_path(stage_id)


func test_at_the_district_the_shared_rooms_show_this_protagonists_picture() -> void:
	GameState.start_new_run("PC02")
	GameState.office_location = Offices.DISTRICT
	assert_true(_path("ST20").ends_with("DISTRICT_LOBBYIST_MEETING_2.png"))
	assert_true(_path("ST21").ends_with("DISTRICT_POLICY_STUDY_2.png"))
	assert_true(_path("ST19").ends_with("DISTRICT_AMBUSH_STREET_2.png"))
	GameState.start_new_run("PC04")
	GameState.office_location = Offices.DISTRICT
	assert_true(_path("ST20").ends_with("DISTRICT_LOBBYIST_MEETING_4.png"))


func test_at_the_capitol_the_shared_rooms_keep_their_usual_pictures() -> void:
	GameState.start_new_run("PC03")
	GameState.office_location = Offices.CAPITOL
	for room: String in ROOMS:
		assert_true(_path(room).ends_with(room + ".png"), room + " is unchanged at the Capitol")


func test_a_stage_that_borrows_a_shared_room_follows_it() -> void:
	GameState.start_new_run("PC01")
	var borrowers := {"ST28": "DISTRICT_LOBBYIST_MEETING", "ST25": "DISTRICT_POLICY_STUDY", "ST30": "DISTRICT_AMBUSH_STREET"}
	for stage_id: String in borrowers:
		GameState.office_location = Offices.DISTRICT
		assert_true(_path(stage_id).contains(str(borrowers[stage_id])), stage_id + " shows the District picture")
		GameState.office_location = Offices.CAPITOL
		assert_false(_path(stage_id).contains("DISTRICT_"), stage_id + " shows the usual picture at the Capitol")


func test_a_room_that_is_not_shared_never_changes_with_the_office() -> void:
	GameState.start_new_run("PC01")
	GameState.office_location = Offices.CAPITOL
	var at_capitol := _path("ST05")
	GameState.office_location = Offices.DISTRICT
	assert_eq(_path("ST05"), at_capitol)


# --- the trip row icons ----------------------------------------------------------------------------------------------

func test_every_travel_mode_has_its_picture() -> void:
	for mode: String in [Travel.PASS, Travel.TICKET, Travel.CAR, Travel.PLANE]:
		assert_not_null(ArtLoader.mode_icon(mode), mode + " has an icon")
	assert_null(ArtLoader.mode_icon("rocket"), "an unknown mode shows none")


func test_a_mode_button_gets_its_picture_and_keeps_its_words() -> void:
	var button := Button.new()
	autofree(button)
	button.text = "Plane ticket · 2 h · 4 held"
	TravelText.dress_mode_icon(button, Travel.PLANE, 90.0)
	assert_not_null(button.icon)
	assert_eq(button.text, "Plane ticket · 2 h · 4 held")
	var plain := Button.new()
	autofree(plain)
	TravelText.dress_mode_icon(plain, "rocket", 90.0)
	assert_null(plain.icon, "no picture, no icon")
