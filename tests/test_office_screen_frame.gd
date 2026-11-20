extends GutTest
## The shared frame of the Office screens (P13, 2026-11-20). It sits INSIDE an Overlay, so the way out is never lost:
## the Overlay's own Back button becomes the "‹ Office" control, the escape key still closes, and opening an ordinary
## panel afterwards puts the plain column back. It draws in all three styles, and every colour it uses reads at 4.5:1
## (text) or 3:1 (the rise and fall colours are text on a card).

const STYLES := [UiStyles.WOODBLOCK, UiStyles.LIVING_OFFICE, UiStyles.BROADCAST]
const TEXT_MIN := 4.5

var _closed := 0


func before_each() -> void:
	_closed = 0
	UiStyle.trying = ""


func after_each() -> void:
	UiStyle.trying = ""


func _rows() -> Array[Control]:
	var rows: Array[Control] = []
	for i in 3:
		var card := OfficeFrameStyles.card(OfficeFrameStyles.look(), "Card %d" % i)
		rows.append(card)
	return rows


func _frame(tabs: Array = [], footer: Button = null) -> OfficeScreenFrame:
	var frame := OfficeScreenFrame.new()
	frame.setup({"title": "Marketplace", "subtitle": "市場", "chips": ["Funds 182,000円", "XP 1,240"],
		"tabs": tabs, "active_tab": "a", "rows": _rows(), "footer": footer})
	return frame


func _overlay() -> Overlay:
	var overlay := Overlay.new()
	add_child_autofree(overlay)
	overlay.closed.connect(func() -> void: _closed += 1)
	return overlay


func test_the_frame_has_its_parts_in_every_style() -> void:
	for style: String in STYLES:
		UiStyle.trying = style
		var overlay := _overlay()
		var footer := Button.new()
		footer.text = "Staff Assignments"
		overlay.open_frame(_frame([{"id": "a", "text": "First"}, {"id": "b", "text": "Second"}], footer), "‹ Office")
		var frame := overlay.find_child("OfficeScreenFrame", true, false) as OfficeScreenFrame
		assert_not_null(frame, style + ": frame is there")
		var title := frame.find_child("FrameTitle", true, false) as Label
		assert_eq(title.text, "MARKETPLACE" if style == UiStyles.BROADCAST else "Marketplace", style + ": title")
		assert_eq((frame.find_child("FrameSubtitle", true, false) as Label).text, "市場")
		assert_eq(frame.find_child("FrameChips", true, false).get_child_count(), 2, style + ": two chips")
		assert_not_null(frame.find_child("FrameTab_a", true, false))
		assert_not_null(frame.find_child("FrameTab_b", true, false))
		assert_eq(frame.body().get_child_count(), 3, style + ": three cards")
		assert_eq(footer.get_parent(), frame.find_child("FrameFooter", true, false), style + ": footer is fixed")


func test_a_frame_without_tabs_or_footer_shows_neither() -> void:
	var overlay := _overlay()
	overlay.open_frame(_frame(), "‹ Office")
	assert_null(overlay.find_child("FrameTabs", true, false))
	assert_eq(overlay.find_child("FrameFooter", true, false).get_child_count(), 0)


func test_back_is_the_overlays_own_button_in_the_top_bar_and_closes() -> void:
	var overlay := _overlay()
	overlay.open_frame(_frame(), "‹ Office")
	var back := overlay.find_child("Back", true, false) as Button
	assert_not_null(back)
	assert_eq(back.text, "‹ Office")
	assert_eq(back.get_parent().name, "FrameBackSlot")
	assert_gte(back.custom_minimum_size.y, OfficeFrameStyles.touch_height() - 0.5, "as tall as a touch target")
	back.pressed.emit()
	assert_false(overlay.visible, "Back closes the panel")
	assert_eq(_closed, 1)


func test_escape_still_closes_a_frame() -> void:
	var overlay := _overlay()
	overlay.open_frame(_frame(), "‹ Office")
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	overlay._input(event)
	assert_false(overlay.visible)
	assert_eq(_closed, 1)


func test_a_tap_on_a_tab_says_which_one() -> void:
	var overlay := _overlay()
	var frame := _frame([{"id": "a", "text": "First"}, {"id": "b", "text": "Second"}])
	overlay.open_frame(frame, "‹ Office")
	watch_signals(frame)
	(frame.find_child("FrameTab_b", true, false) as Button).pressed.emit()
	assert_signal_emitted_with_parameters(frame, "tab_chosen", ["b"])


func test_opening_an_ordinary_panel_after_a_frame_restores_the_plain_column() -> void:
	var overlay := _overlay()
	overlay.open_frame(_frame(), "‹ Office")
	assert_true(overlay.has_frame())
	var rows: Array[Control] = [UiKit.line("Plain")]
	overlay.open("Plain heading", rows)
	assert_false(overlay.has_frame())
	await get_tree().process_frame
	assert_null(overlay.find_child("OfficeScreenFrame", true, false), "the frame is gone")
	var back := overlay.find_child("Back", true, false) as Button
	assert_eq(back.get_parent().name, "Column", "Back is back at the foot of the column")
	assert_eq(back.text, Text.say("ui.back"))
	assert_eq(back.custom_minimum_size.y, 110.0)
	assert_true((overlay.get_node("Margin") as Control).visible)
	back.pressed.emit()
	assert_false(overlay.visible)


func test_a_second_frame_replaces_the_first_and_keeps_one_back_button() -> void:
	var overlay := _overlay()
	overlay.open_frame(_frame(), "‹ Office")
	overlay.open_frame(_frame(), "‹ Office")
	await get_tree().process_frame
	assert_eq(overlay.find_children("Back", "Button", true, false).size(), 1, "one Back button, never two")
	assert_eq(overlay.find_children("OfficeScreenFrame", "", true, false).size(), 1, "one frame")


func test_every_colour_the_frame_uses_reads_in_every_style() -> void:
	var pairs: Array = [["on_ground", "ground"], ["on_ground_muted", "ground"], ["ink", "card"], ["muted", "card"],
		["on_accent", "accent"], ["up", "card"], ["down", "card"]]
	for style: String in STYLES:
		UiStyle.trying = style
		var look := OfficeFrameStyles.look()
		for pair: Array in pairs:
			var ratio := IntentPill.contrast(look[pair[0]], look[pair[1]])
			assert_gte(ratio, TEXT_MIN, "%s: %s on %s is %.2f:1" % [style, pair[0], pair[1], ratio])
		assert_ne(look["up"], Color.MAGENTA, style + " has frame_up")
		assert_ne(look["down"], Color.MAGENTA, style + " has frame_down")


func test_a_card_takes_its_own_ink_not_the_rooms() -> void:
	for style: String in STYLES:
		UiStyle.trying = style
		var look := OfficeFrameStyles.look()
		var card := OfficeFrameStyles.card(look, "Heading")
		add_child_autofree(card)
		assert_eq(card.theme.get_color("font_color", "Label"), look["ink"], style + ": a card's labels use the card ink")
		assert_not_null(card.find_child("CardTitle", true, false))
