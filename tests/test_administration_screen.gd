extends GutTest
## The Administration screen on the shared frame (P13, 2026-11-20). It shows the same controls the old menu had, as grouped
## rows with their current value beside them: every value equals what the old button's own text said, every control keeps
## its old node name, a tap still runs the action, and Resign is not here (Cameron, 2026-11-20: it stays in Reputation and
## Results).

var _calls: Array[String] = []


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	UiStyle.trying = ""
	_calls.clear()


func after_each() -> void:
	UiStyle.trying = ""
	GameState.active_cosmetics.clear()
	GameState.difficulty = Difficulty.STANDARD


func _note(what: String) -> void:
	_calls.append(what)


func _actions() -> Dictionary:
	var button := Button.new()
	button.name = "RaisePressureButton"
	# Not parented: the Political Pressure card takes it, as it takes the Office's own fresh button.
	autofree(button)
	return {
		"redraw": _note.bind("redraw"), "open_cosmetics": _note.bind("cosmetics"),
		"open_how_to_play": _note.bind("how_to"), "open_characters": _note.bind("characters"),
		"backup_now": _note.bind("backup"), "backup_restore": _note.bind("restore"), "backup_undo": _note.bind("undo"),
		"new_game": _note.bind("new_game"),
		"pressure": {"title": "Political Pressure", "now": "Now: Standard", "blurb": "Blurb", "button": button},
	}


func _rows(model: Dictionary) -> Dictionary:
	var out := {}
	for group: Dictionary in model["groups"]:
		for row: Dictionary in group["rows"]:
			out[row["node"]] = row
	return out


func test_there_are_four_groups_in_the_order_the_spec_gives() -> void:
	var ids: Array[String] = []
	for group: Dictionary in AdministrationModel.build(_actions())["groups"]:
		ids.append(str(group["id"]))
	assert_eq(ids, ["display", "appearance", "save", "help"] as Array[String])


func test_the_display_values_equal_what_the_old_buttons_said() -> void:
	var rows := _rows(AdministrationModel.build(_actions()))
	assert_eq(Text.say("office.text_size", {"size": rows["TextSizeButton"]["value"]}), SettingsRows.text_size_label())
	assert_eq(Text.say("office.image_scroll", {"state": rows["ImageScrollButton"]["value"]}),
		SettingsRows.image_scroll_button(Callable()).text)
	assert_eq(Text.say("office.image_pan", {"state": rows["ImagePanButton"]["value"]}),
		SettingsRows.image_pan_button(Callable()).text)
	assert_eq(Text.say("office.scroll_speed", {"level": rows["ScrollSpeedButton"]["value"]}),
		SettingsRows.scroll_speed_button(Callable()).text)


func test_values_follow_the_settings_when_they_change() -> void:
	Layout.image_pan_enabled = false
	var rows := _rows(AdministrationModel.build(_actions()))
	assert_eq(rows["ImagePanButton"]["value"], Text.say("settings.off"))
	Layout.image_pan_enabled = true
	rows = _rows(AdministrationModel.build(_actions()))
	assert_eq(rows["ImagePanButton"]["value"], Text.say("settings.on"))


func test_every_control_the_old_menu_had_is_still_there_under_its_old_name() -> void:
	var rows := _rows(AdministrationModel.build(_actions()))
	for node: String in ["TextSizeButton", "ImageScrollButton", "ImagePanButton", "CosmeticsButton", "BackupNowButton",
			"NewGameMenuButton", "HowToPlayButton", "CharactersButton"]:
		assert_true(rows.has(node), node + " is on the screen")


func test_load_and_undo_follow_the_save_exactly_as_before() -> void:
	var rows := _rows(AdministrationModel.build(_actions()))
	assert_eq(rows.has("BackupRestoreButton"), SaveManager.has_backup())
	assert_eq(rows.has("BackupUndoButton"), SaveManager.has_undo())


func test_the_appearance_rows_name_what_is_equipped() -> void:
	var rows := _rows(AdministrationModel.build(_actions()))
	assert_eq(rows["CosmeticsButton"]["value"], Text.say("office.cosmetics_default"))
	# The slots that have a package in the data today are the Office Background and the Calendar.
	for pair: Array in [[CosmeticPieces.BACKGROUND, "CosmeticsButton"], [CosmeticPieces.CALENDAR, "CosmeticsCalendarButton"]]:
		var package: Dictionary = {}
		for candidate: Dictionary in DataDB.cosmetic_packages:
			if CosmeticPieces.has_piece(candidate, str(pair[0])):
				package = candidate
				break
		assert_false(package.is_empty(), "the data has a package for " + str(pair[0]))
		GameState.active_cosmetics[str(pair[0])] = str(package["package_id"])
		rows = _rows(AdministrationModel.build(_actions()))
		assert_eq(rows[pair[1]]["value"], CosmeticPieces.field(package, "name_en"), str(pair[0]) + " shows the package's name")


func test_reporting_a_problem_shows_the_reporters_own_lines() -> void:
	var rows := _rows(AdministrationModel.build(_actions()))
	var hints := Reporter.hint_lines()
	assert_eq(rows.has("ReportRow"), not hints.is_empty())
	if not hints.is_empty():
		assert_eq(rows["ReportRow"]["hints"], hints)


func test_resign_is_not_on_the_administration_screen() -> void:
	var overlay := Overlay.new()
	add_child_autofree(overlay)
	var frame := OfficeScreenFrame.new()
	frame.setup({"title": "Administration", "rows": AdministrationView.cards(AdministrationModel.build(_actions()))})
	overlay.open_frame(frame, "‹ Office")
	for node: Node in overlay.find_children("*", "", true, false):
		assert_false(str(node.name).to_lower().contains("resign"), str(node.name) + " is not a Resign control")


func test_a_tap_on_a_row_runs_its_action_and_the_chip_shows_the_value() -> void:
	var overlay := Overlay.new()
	add_child_autofree(overlay)
	var frame := OfficeScreenFrame.new()
	frame.setup({"title": "Administration", "rows": AdministrationView.cards(AdministrationModel.build(_actions()))})
	overlay.open_frame(frame, "‹ Office")
	var button := overlay.find_child("HowToPlayButton", true, false) as Button
	assert_not_null(button)
	assert_eq((button.find_child("RowValue", true, false) as Label).text, Text.say("admin.chip_open"))
	button.pressed.emit()
	assert_eq(_calls, ["how_to"] as Array[String])
	var about := overlay.find_child("CosmeticsMusicButton", true, false) as Button
	about.pressed.emit()
	assert_eq(_calls, ["how_to", "cosmetics"] as Array[String])


func test_a_value_chip_never_wraps() -> void:
	var overlay := Overlay.new()
	add_child_autofree(overlay)
	var frame := OfficeScreenFrame.new()
	frame.setup({"title": "Administration", "rows": AdministrationView.cards(AdministrationModel.build(_actions()))})
	overlay.open_frame(frame, "‹ Office")
	for chip: Node in overlay.find_children("RowValue", "Label", true, false):
		assert_eq((chip as Label).autowrap_mode, TextServer.AUTOWRAP_OFF, "a value chip stays on one line")


func test_the_pressure_box_has_one_button_and_the_tier_in_force() -> void:
	var model := AdministrationModel.build(_actions())
	assert_eq(model["pressure"]["now"], "Now: Standard")
	var overlay := Overlay.new()
	add_child_autofree(overlay)
	var frame := OfficeScreenFrame.new()
	frame.setup({"title": "Administration", "rows": AdministrationView.cards(model)})
	overlay.open_frame(frame, "‹ Office")
	var box := overlay.find_child("AdminPressure", true, false)
	assert_not_null(box)
	assert_eq(box.find_children("*", "Button", true, false).size(), 1, "one button in the Political Pressure box")
