extends GutTest
## Button outlines (2026-10-15): party colour on ordinary buttons, white on
## the ones that back out of a screen.


func test_back_and_close_buttons_count_as_cancel() -> void:
	for button_name in ["Back", "DetailsClose", "ZoomClose", "LeaveButton",
			"EndTurnButton", "InventoryButton", "DetailsButton"]:
		var b := Button.new()
		b.name = button_name
		assert_true(Layout.is_cancel_button(b), button_name)
		b.free()


func test_an_ordinary_button_is_not_cancel() -> void:
	var b := Button.new()
	b.name = "EndTurn"
	assert_false(Layout.is_cancel_button(b))
	b.free()


func test_the_theme_outlines_buttons_five_pixels_and_cancel_in_white() -> void:
	var theme := ThemeDB.get_project_theme()
	var normal := theme.get_stylebox("normal", "Button") as StyleBoxFlat
	assert_eq(normal.border_width_left, Layout.OUTLINE_WIDTH)
	assert_eq(Layout.OUTLINE_WIDTH, 2)
	var cancel := theme.get_stylebox("normal", Layout.CANCEL_VARIATION) as StyleBoxFlat
	assert_eq(cancel.border_width_top, Layout.OUTLINE_WIDTH)
	assert_eq(cancel.border_color, Color.WHITE)


func test_a_back_button_added_to_the_tree_takes_the_white_variation() -> void:
	var b := Button.new()
	b.name = "Back"
	add_child_autofree(b)
	assert_eq(b.theme_type_variation, Layout.CANCEL_VARIATION)


func test_the_offices_marketplace_button_keeps_the_party_colour() -> void:
	var b := Button.new()
	b.name = "InventoryButton"
	b.set_meta("party_outline", true)
	assert_false(Layout.is_cancel_button(b))
	b.free()
