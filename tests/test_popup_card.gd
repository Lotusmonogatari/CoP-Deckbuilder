extends GutTest
## The pop-up card (P14, 2026-11-20): one card with a kind tag, a meta line, a title, a body and a foot, inside an Overlay, so the way
## out is the Overlay's. It draws in all three styles, every colour of every kind of tag reads at 4.5:1, and an Overlay that
## shows an ordinary panel afterwards gets its plain column, Back button and backdrop back.

const STYLES := [UiStyles.WOODBLOCK, UiStyles.LIVING_OFFICE, UiStyles.BROADCAST]
const KINDS := [PopupCardStyles.ACCENT, PopupCardStyles.ALARM, PopupCardStyles.GOOD]

var _closed := 0
var _confirmed := 0


func before_each() -> void:
	_closed = 0
	_confirmed = 0
	UiStyle.trying = ""


func after_each() -> void:
	UiStyle.trying = ""


func _config(extra: Dictionary = {}) -> Dictionary:
	var body: Array[Control] = [UiKit.line("The body line.")]
	var foot: Array[Control] = []
	for letter: String in ["A", "B"]:
		var button := Button.new()
		button.name = "Choice_" + letter
		button.text = "Choice " + letter
		foot.append(button)
	var config := {"tag": "DECISION!", "tag_kind": PopupCardStyles.ALARM, "meta": "Monday · Capitol · 2 h", "title": "The title",
		"body": body, "buttons": foot}
	config.merge(extra, true)
	return config


func _overlay() -> Overlay:
	var overlay := Overlay.new()
	add_child_autofree(overlay)
	overlay.closed.connect(func() -> void: _closed += 1)
	overlay.confirmed.connect(func() -> void: _confirmed += 1)
	return overlay


func test_the_card_has_its_parts_in_every_style() -> void:
	for style: String in STYLES:
		UiStyle.trying = style
		var overlay := _overlay()
		overlay.open_card(_config())
		var card := overlay.find_child("PopupCard", true, false) as PopupCard
		assert_not_null(card, style + ": the card")
		assert_eq((card.find_child("TagText", true, false) as Label).text, "DECISION!")
		assert_eq((card.find_child("CardMeta", true, false) as Label).text, "Monday · Capitol · 2 h")
		assert_eq((card.find_child("CardTitle", true, false) as Label).text.to_lower(), "the title")
		assert_not_null(card.find_child("Choice_A", true, false))
		assert_not_null(card.find_child("Choice_B", true, false))
		assert_true(overlay.has_card())


func test_a_card_without_a_tag_or_meta_shows_neither() -> void:
	var overlay := _overlay()
	overlay.open_card(_config({"tag": "", "meta": ""}))
	assert_null(overlay.find_child("PopupTag", true, false))
	assert_false((overlay.find_child("CardMeta", true, false) as Label).visible)


func test_back_is_the_overlays_own_button_in_the_foot_and_closes() -> void:
	var overlay := _overlay()
	overlay.open_card(_config())
	var back := overlay.find_child("Back", true, false) as Button
	assert_not_null(back)
	assert_eq(back.get_parent().name, "CardFoot")
	back.pressed.emit()
	assert_false(overlay.visible)
	assert_eq(_closed, 1)


func test_escape_closes_a_dismissable_card_and_not_one_that_must_be_answered() -> void:
	var overlay := _overlay()
	overlay.open_card(_config())
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	overlay._input(event)
	assert_false(overlay.visible, "a dismissable card closes")
	var must := _overlay()
	must.dismissable = false
	must.show_back = false
	must.open_card(_config())
	must._input(event)
	assert_true(must.visible, "a card that must be answered stays")
	assert_null(must.find_child("Back", true, false) if must.find_child("Back", true, false) != null and must.find_child("Back", true, false).visible else null, "and shows no Back")


func test_the_confirm_button_is_the_cards_primary_button_and_emits_confirmed() -> void:
	var overlay := _overlay()
	overlay.open_card(_config(), "Go on")
	var confirm := overlay.find_child("Confirm", true, false) as Button
	assert_true(confirm.visible)
	assert_eq(confirm.text, "Go on")
	assert_eq(confirm.get_parent().name, "CardFoot")
	confirm.pressed.emit()
	assert_eq(_confirmed, 1)
	assert_false(overlay.visible, "confirming closes, as before")


func test_a_greyed_confirm_stays_greyed() -> void:
	var overlay := _overlay()
	overlay.open_card(_config(), "Not now", "", false)
	assert_true((overlay.find_child("Confirm", true, false) as Button).disabled)


func test_an_ordinary_panel_after_a_card_gets_its_plain_column_back() -> void:
	var overlay := _overlay()
	overlay.open_card(_config(), "Go on")
	var rows: Array[Control] = [UiKit.line("Plain")]
	overlay.open("Plain", rows)
	await get_tree().process_frame
	assert_false(overlay.has_card())
	assert_null(overlay.find_child("PopupCard", true, false), "the card is gone")
	var back := overlay.find_child("Back", true, false) as Button
	assert_eq(back.get_parent().name, "Column")
	assert_eq(back.custom_minimum_size.y, 110.0)
	assert_true((overlay.get_node("Margin") as Control).visible)
	assert_eq(overlay.find_children("SlantPlate", "", true, false).size(), 0, "no leftover plate on a lent button")


func test_every_kind_of_tag_reads_in_every_style() -> void:
	for style: String in STYLES:
		UiStyle.trying = style
		var look := OfficeFrameStyles.look()
		for kind: String in KINDS:
			var colours := PopupCardStyles.tag_colours(look, kind)
			var ratio := IntentPill.contrast(colours[1], colours[0])
			assert_gte(ratio, 4.5, "%s: a %s tag reads (%.2f:1)" % [style, kind, ratio])


func test_the_scrim_is_translucent_and_dims_the_room() -> void:
	for style: String in STYLES:
		UiStyle.trying = style
		var scrim := PopupCardStyles.scrim()
		assert_gt(scrim.a, 0.4, style + ": dims enough")
		assert_lt(scrim.a, 0.9, style + ": the room still shows")


func test_the_card_body_takes_the_height_its_content_needs() -> void:
	var overlay := _overlay()
	var rows: Array[Control] = []
	for i in 6:
		rows.append(UiKit.line("A line of the body, number %d." % i))
	overlay.open_card(_config({"body": rows}))
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var scroll := overlay.find_child("CardScroll", true, false) as ScrollContainer
	assert_gt(scroll.custom_minimum_size.y, 100.0, "the body is not collapsed")
