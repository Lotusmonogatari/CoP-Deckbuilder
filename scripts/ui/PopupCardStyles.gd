class_name PopupCardStyles
extends RefCounted
## What differs between the three UI styles on the pop-up card (P14, 2026-11-20): the scrim over the room, the colour of each
## kind of tag, and how the card's buttons are drawn. The card's own colours are the Office frame's (OfficeFrameStyles), which
## are the P12 palette; the scrim, the alarm tag and the scrim strength are UI Styles rows (`scrim`, `alarm`, `scrim_alpha`).
## Draws only.

## The kinds of tag: a plain one (the style's accent), an alarm (red, white text) and a good one (the style's rise colour).
const ACCENT := "accent"
const ALARM := "alarm"
const GOOD := "good"

const _OVERRIDES: Array[String] = ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
	"font_hover_pressed_color", "font_disabled_color"]
const _STATES: Array[String] = ["normal", "hover", "pressed", "disabled", "focus"]


## The dimming laid over the room behind a pop-up.
static func scrim() -> Color:
	var base := UiStyle.colour("scrim", Color(0.08, 0.06, 0.04))
	return Color(base.r, base.g, base.b, UiStyle.number("shared", "scrim_alpha", 0.6))


## The fill and the ink of a tag of `kind`.
static func tag_colours(look: Dictionary, kind: String) -> Array[Color]:
	match kind:
		ALARM:
			return [UiStyle.colour("alarm", Color("#A3261A")), Color.WHITE]
		GOOD:
			# Broadcast's rise colour is a light green for dark rooms: white would not read on it, the dark accent ink does.
			var fill: Color = look["up"]
			var dark: Color = look["on_accent"]
			var ink: Color = Color.WHITE if IntentPill.contrast(Color.WHITE, fill) >= IntentPill.contrast(dark, fill) else dark
			return [fill, ink]
	return [look["accent"], look["on_accent"]]


## The tag itself: a small chip (a slanted plate in Broadcast) holding the words.
static func tag(look: Dictionary, text: String, kind: String) -> Control:
	var colours := tag_colours(look, kind)
	var holder := PanelContainer.new()
	holder.name = "PopupTag"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.name = "TagText"
	label.text = text
	label.set_meta(UiKit.ONE_LINE_META, true)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", OfficeFrameStyles.px(LevelBriefingStyles.SIZE_SMALL))
	label.add_theme_color_override("font_color", colours[1])
	label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	if look["broadcast"]:
		holder.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var plate := BriefingPlate.new()
		plate.shape = BriefingPlate.Shape.SLANT
		plate.fill = colours[0]
		plate.slant = OfficeFrameStyles.len_px(7.0)
		holder.add_child(plate)
		var pad := MarginContainer.new()
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for side: String in ["left", "right", "top", "bottom"]:
			pad.add_theme_constant_override("margin_" + side, int(OfficeFrameStyles.len_px(12.0 if side in ["left", "right"] else 4.0)))
		pad.add_child(label)
		holder.add_child(pad)
		return holder
	var box := StyleBoxFlat.new()
	box.bg_color = colours[0]
	box.content_margin_left = OfficeFrameStyles.len_px(10.0)
	box.content_margin_right = OfficeFrameStyles.len_px(10.0)
	box.content_margin_top = OfficeFrameStyles.len_px(4.0)
	box.content_margin_bottom = OfficeFrameStyles.len_px(4.0)
	if look["living"]:
		box.set_corner_radius_all(int(OfficeFrameStyles.len_px(14.0)))
	holder.add_theme_stylebox_override("panel", box)
	holder.add_child(label)
	return holder


## Dresses a button of the card's foot: the primary one filled, the others outlined in the card's own ink.
static func dress_foot_button(button: Button, look: Dictionary, primary: bool) -> void:
	if primary:
		LevelBriefingStyles.dress_button(button, look, true, not button.disabled)
	else:
		OfficeFrameStyles.dress_card_button(button, look, not button.disabled)
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, OfficeFrameStyles.touch_height())


## Takes the dress off a button an Overlay lent to the card (its Back or Confirm), so a plain panel gets the plain button back.
static func undress(button: Button) -> void:
	for name: String in _OVERRIDES:
		button.remove_theme_color_override(name)
	button.remove_theme_font_size_override("font_size")
	for state: String in _STATES:
		button.remove_theme_stylebox_override(state)
	for child: Node in button.get_children():
		if child.name == "SlantPlate":
			button.remove_child(child)
			child.queue_free()
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.size_flags_horizontal = Control.SIZE_FILL
	button.custom_minimum_size = Vector2(0.0, 110.0)
