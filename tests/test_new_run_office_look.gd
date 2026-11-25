extends GutTest
## A tester's report (2026-11-25): a new run started while the last run stood at the PC01 District office drew that District office
## again, and so did a run as PC02. A new run starts at the Capitol, so the picture behind the Office must be the Capitol's.


func _office() -> Control:
	var office := (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate() as Control
	add_child_autofree(office)
	return office


func test_a_new_run_after_one_at_the_district_office_shows_the_capitol() -> void:
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.office_location = Offices.DISTRICT
	var office := _office()
	await get_tree().process_frame
	assert_eq(office._background.art_id, "DISTRICT_OFFICE_PC01", "the District office, as the run left it")
	office._on_protagonist_chosen("PC02")
	assert_eq(GameState.office_location, Offices.CAPITOL, "a new run starts at the Capitol")
	assert_eq(office._background.art_id, "OFFICE", "and the picture follows")
	assert_false(office._background.show_label)
