class_name ConversationStyles
extends RefCounted
## The dress of the conversation screens (P14, 2026-11-20): Office Hours, the member visit, the lobbyist trade and the level
## intro. The layout is VisitLayout's (a big picture, a name plate over its corner, the question as a card under it, the choices
## full width); this gives every part the style's own look: the name on a plate, the choices as filled card-coloured buttons
## (they sit on the plain panel, which can be light or dark, so they carry their own fill), and Continue, the way on, in the
## accent colour. It changes colours, outlines and heights only: no node, text or signal changes, so every test that finds a
## button by name still does, and a disabled button reads as disabled from its own state.


## Dresses a screen. `name_label` is the person's name, `choices` the answer buttons (may be hidden now: they are dressed
## anyway), `way_on` the Continue button.
static func dress(name_label: Label, choices: Array, way_on: Button) -> void:
	var look := OfficeFrameStyles.look()
	_plate_the_name(name_label, look)
	for choice: Variant in choices:
		if choice is Button:
			dress_button(choice as Button, look, false)
	if way_on != null:
		dress_button(way_on, look, true)


## One button: filled, outlined, and drawn from its own state (so a button that becomes disabled later still looks it).
static func dress_button(button: Button, look: Dictionary, primary: bool) -> void:
	var fill: Color = look["accent"] if primary else look["card"]
	var ink: Color = look["on_accent"] if primary else look["ink"]
	var muted: Color = look["muted"]
	button.add_theme_font_size_override("font_size", OfficeFrameStyles.px(LevelBriefingStyles.SIZE_BUTTON))
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, ink)
	button.add_theme_color_override("font_disabled_color", muted)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, _box(look, fill, ink))
	# Disabled reads as disabled in every style: the card colour dimmed, a muted edge and muted words (never the accent).
	var card: Color = look["card"]
	button.add_theme_stylebox_override("disabled", _box(look, Color(card.r, card.g, card.b, 0.6), muted))
	# The height stays what the scene gave it: VisitLayout fits the picture to the room these buttons leave, and a taller
	# Continue pushed itself off a short screen at Large text (text sweep, 2026-11-20).


static func _box(look: Dictionary, fill: Color, edge: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_border_width_all(int(OfficeFrameStyles.len_px(2.0 if look["wood"] else 1.0)))
	box.border_color = edge
	if look["living"]:
		box.set_corner_radius_all(int(OfficeFrameStyles.len_px(24.0)))
	elif look["wood"]:
		box.shadow_color = look["hot"]
		box.shadow_size = 1
		box.shadow_offset = Vector2(OfficeFrameStyles.len_px(3.0), OfficeFrameStyles.len_px(3.0))
	box.content_margin_left = OfficeFrameStyles.len_px(12.0)
	box.content_margin_right = OfficeFrameStyles.len_px(12.0)
	return box


## The name on a plate in the style's card colour and ink, so it reads over any picture.
static func _plate_the_name(label: Label, look: Dictionary) -> void:
	if label == null:
		return
	label.add_theme_stylebox_override("normal", LevelBriefingStyles.card_box(look))
	label.add_theme_color_override("font_color", look["ink"])
