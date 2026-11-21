extends GutTest
## Group 7 of P14b (2026-11-20): Appearance and Music, How to Play, Characters and New Game on the shared frame. Every entry,
## character and champion is still there under its old name; the equipped option is filled; the Characters list is two columns.


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	UiStyle.trying = ""


func _office() -> Control:
	var office := (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate() as Control
	add_child_autofree(office)
	return office


func test_how_to_play_has_one_card_for_every_entry() -> void:
	var overlay := Overlay.new()
	add_child_autofree(overlay)
	HowToPlayPanel.open(overlay)
	assert_true(overlay.has_frame())
	var entries := 0
	for group: Dictionary in HowToPlay.grouped(DataDB.how_to_play):
		for entry: Dictionary in group["entries"]:
			entries += 1
			assert_not_null(overlay.find_child("HowToCard_%s" % str(entry.get("entry_id", "")), true, false), "a card for each entry")
	assert_gt(entries, 0)


func test_the_characters_list_is_two_columns_with_a_button_for_everyone() -> void:
	var office := _office()
	await get_tree().process_frame
	office._characters.open()
	var panel := office.get_node("CharactersPanel") as Overlay
	assert_true(panel.has_frame())
	for kind: String in ["opponent", "visitor"]:
		var grid := panel.find_child("CharactersGrid_" + kind, true, false) as GridContainer
		assert_not_null(grid)
		assert_eq(grid.columns, 2)
	var people := DataDB.opponents.size() + DataDB.visitors.size()
	assert_eq(panel.find_children("Character_*", "Button", true, false).size(), people, "everyone has a button")


func test_new_game_shows_the_portraits_the_picked_card_and_play_as_in_the_foot() -> void:
	var office := _office()
	await get_tree().process_frame
	office._new_game_pick = ""
	office._show_new_game(false)
	var panel := office.get_node("NewGamePanel") as Overlay
	assert_true(panel.has_frame())
	for protagonist: Dictionary in DataDB.protagonists:
		assert_not_null(panel.find_child("Pick_" + str(protagonist.get("player_id", "")), true, false), "a portrait for each champion")
	var first := str(DataDB.protagonists[0].get("player_id", ""))
	assert_not_null(panel.find_child("Protagonist_" + first, true, false), "the first champion's card shows by default")
	var play := panel.find_child("PlayAsButton", true, false) as Button
	assert_not_null(play)
	assert_eq(play.get_parent().name, "FrameFooter", "Play as is fixed in the foot")
	assert_true(play.text.contains(str(DataDB.protagonists[0].get("name_en", ""))))
	# Tapping another portrait shows that champion's card and renames the button.
	var other := str(DataDB.protagonists[1].get("player_id", ""))
	(panel.find_child("Pick_" + other, true, false) as Button).pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_not_null(panel.find_child("Protagonist_" + other, true, false), "the picked champion's card")
	assert_true((panel.find_child("PlayAsButton", true, false) as Button).text.contains(str(DataDB.protagonists[1].get("name_en", ""))))
	for tier: String in Difficulty.TIERS:
		assert_not_null(panel.find_child("PressureStrip_" + tier, true, false), "a switch for " + tier)
	assert_not_null(panel.find_child("ThemeStrip_" + UiStyles.LIVING_OFFICE, true, false))


func test_the_equipped_option_is_filled() -> void:
	var package := str(DataDB.cosmetic_packages[0].get("package_id", ""))
	GameState.owned_cosmetic_packages.append(package)
	var office := _office()
	await get_tree().process_frame
	office._show_cosmetics()
	var panel := office.get_node("CosmeticsPanel") as Overlay
	assert_true(panel.has_frame())
	var equipped: Button = null
	for button: Node in panel.find_children("*", "Button", true, false):
		if (button as Button).disabled and (button as Button).text.contains(Text.say("office.cosmetics_active")):
			equipped = button as Button
			break
	assert_not_null(equipped, "the Default option is equipped to begin with")
	var fill := (equipped.get_theme_stylebox("disabled") as StyleBoxFlat).bg_color
	assert_eq(fill, OfficeFrameStyles.look()["accent"], "the equipped option is filled in the accent colour")
