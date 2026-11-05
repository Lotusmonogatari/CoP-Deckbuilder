extends GutTest
## The hand's gold scroll bar (2026-11-05, Cameron): above the cards, and in step
## with the hand both ways.


func _hand() -> Array:
	var column := VBoxContainer.new()
	column.size = Vector2(500, 600)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 300)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	for _i in 6:
		var card := Control.new()
		card.custom_minimum_size = Vector2(200, 250)
		row.add_child(card)
	scroll.add_child(row)
	column.add_child(scroll)
	add_child_autofree(column)
	return [column, scroll]


func test_the_bar_sits_directly_above_the_cards_in_gold() -> void:
	var parts := _hand()
	var bar := HandScrollBar.attach(parts[1])
	assert_not_null(bar)
	assert_eq(bar.get_index() + 1, (parts[1] as Control).get_index(), "directly above the scroll area")
	var grabber := bar.get_theme_stylebox("grabber") as StyleBoxFlat
	assert_eq(Color(grabber.bg_color.r, grabber.bg_color.g, grabber.bg_color.b), CueBanner.EDGE_COLOUR)
	assert_eq((parts[1] as ScrollContainer).horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_SHOW_NEVER,
		"the container's own bar, underneath, is off")


func test_the_bar_and_the_hand_move_together() -> void:
	var parts := _hand()
	var scroll: ScrollContainer = parts[1]
	var bar := HandScrollBar.attach(scroll)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_gt(bar.max_value, bar.page, "the hand is wider than the screen")
	assert_eq(bar.modulate.a, 1.0, "so the bar shows")
	bar.value = 300
	assert_eq(scroll.scroll_horizontal, 300, "dragging the bar scrolls the hand")
	scroll.scroll_horizontal = 100
	await get_tree().process_frame
	assert_eq(int(bar.value), 100, "a drag on the cards moves the bar")


func test_a_hand_that_fits_fades_the_bar_but_keeps_its_space() -> void:
	var parts := _hand()
	var scroll: ScrollContainer = parts[1]
	var bar := HandScrollBar.attach(scroll)
	for card in scroll.get_child(0).get_children():
		(card as Control).custom_minimum_size = Vector2(40, 250)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(bar.modulate.a, 0.0)
	assert_eq(bar.custom_minimum_size.y, HandScrollBar.HEIGHT, "its space stays, so the cards do not jump")
