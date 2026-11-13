extends GutTest
## The move flash (2026-11-13): settings from the Move Flashes tab, colours
## from the Characters list, and a layer that never takes a touch.

func test_every_side_and_move_has_a_row_in_the_workbook() -> void:
	for side: String in MoveFlash.SIDES:
		for move: String in MoveFlash.MOVES:
			assert_false(MoveFlash.row_for(DataDB.move_flashes, side, move).is_empty(),
				"%s %s has a row" % [side, move])


func test_a_neutral_face_flashes_nothing() -> void:
	assert_eq(MoveFlash.plan(DataDB.move_flashes, "player", "neutral", Color.RED), {})


func test_a_blank_colour_uses_the_characters_own_colour() -> void:
	var plan := MoveFlash.plan(DataDB.move_flashes, "opponent", "attacking", Color(0.2, 0.4, 0.6))
	assert_eq(plan["color"], Color(0.2, 0.4, 0.6))
	assert_eq(plan["width"], float(MoveFlash.row_for(DataDB.move_flashes, "opponent", "attack")["width_px"]))


func test_a_row_colour_overrides_the_character() -> void:
	var rows := [{"side": "player", "move": "hit", "colour": "255, 0, 128",
		"width_px": 5, "strength": 0.5, "hold_seconds": 0.1, "fade_seconds": 0.4}]
	var plan := MoveFlash.plan(rows, "player", "damaged", Color.BLUE)
	assert_eq(plan["color"], Color(1.0, 0.0, 128.0 / 255.0))
	assert_eq(MoveFlash.plan(rows, "player", "attacking", Color.BLUE), {}, "no row, no flash")


func test_a_zero_width_or_strength_row_means_no_flash() -> void:
	var rows := [{"side": "player", "move": "gain", "colour": null,
		"width_px": 0, "strength": 0.5, "hold_seconds": 0.1, "fade_seconds": 0.4}]
	assert_eq(MoveFlash.plan(rows, "player", "gaining", Color.BLUE), {})


func test_unreadable_colours_are_ignored() -> void:
	assert_null(MoveFlash.parse_colour(null))
	assert_null(MoveFlash.parse_colour("red"))
	assert_null(MoveFlash.parse_colour("1, 2"))


func test_an_opponents_flash_colour_is_their_list_colour() -> void:
	var person: Dictionary = DataDB.opponents[0]
	var player_party := str(DataDB.player.get("party", ""))
	var entries := CharacterCodex.entries("opponent", [person], DataDB.boosters, DataDB.parties,
		player_party, {}, DataDB.balance)
	assert_eq(CharacterCodex.opponent_color(person, DataDB.boosters, DataDB.parties,
		player_party, DataDB.balance), entries[0]["color"])


func test_the_layer_sits_behind_the_picture_and_ignores_touches() -> void:
	var art := PlaceholderArt.new()
	art.size = Vector2(300, 400)
	add_child_autofree(art)
	var layer := MoveFlashLayer.attach(art, "player")
	assert_not_null(layer)
	assert_eq(art.get_child(0), layer, "lowest child")
	assert_eq(layer.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(MoveFlashLayer.attach(art, "player"), layer, "attached once")
	layer.play("attacking", Color.RED)
	assert_true((layer.get_node("Glow") as ColorRect).visible, "the glow is up")
