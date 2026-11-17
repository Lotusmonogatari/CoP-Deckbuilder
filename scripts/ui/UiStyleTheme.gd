class_name UiStyleTheme
extends RefCounted
## Builds one style's THEME OVERLAY from its tokens (P9, 2026-11-17).
##
## An overlay carries only what a style changes: the fonts, the ink colours and
## the button boxes. Sizes are left to the base theme (cop_theme.tres) until the
## text-size decision (T1) lands, so every style lays out at today's sizes.
## UiStyle merges the active overlay into the project theme; every overlay sets
## the SAME items, so merging one over another leaves nothing of the first behind.
##
## tools/build_theme.gd saves the three overlays as theme/cop_theme_<style>.tres.

const ANTAKA_DISPLAY := "res://assets/fonts/AntakaBrushDisplay-Regular.ttf"
const NOTO := "res://assets/fonts/NotoSansJP[wght].ttf"
const BARLOW := "res://assets/fonts/BarlowCondensed-BoldItalic.woff2"
const SHIPPORI := "res://assets/fonts/ShipporiMinchoB1-Regular.woff2"
const ZEN := "res://assets/fonts/ZenKakuGothicNew-Regular.woff2"

## Label types that take the display face, and the ones that take the body face.
const DISPLAY_TYPES := ["TitleLabel", "HeaderLabel", "CueBanner", "CueSpeaker"]
const BODY_TYPES := ["Label", "Button", "SmallLabel", "JapaneseAccent", "GaffeWarning"]
const BUTTON_STATES := ["normal", "hover", "pressed", "disabled", "hover_pressed"]
const JP_ACCENT_ALPHA := 0.55
## Antaka Brush Text's line height at size 34: the height every body face is trimmed to.
const ANTAKA_LINE_AT_34 := 40.0


## The display and body font files each style names.
static func font_paths(style: String) -> Dictionary:
	match style:
		UiStyles.BROADCAST:
			return {"display": BARLOW, "body": NOTO}
		UiStyles.WOODBLOCK:
			return {"display": ANTAKA_DISPLAY, "body": SHIPPORI}
	return {"display": ANTAKA_DISPLAY, "body": ZEN}


## A face with Noto Sans JP behind it, so anything it lacks (Japanese, −, ×, →)
## is drawn per glyph from Noto, as Antaka's text already is.
static func face(path: String) -> Font:
	var base: Font = load(path)
	var noto: Font = load(NOTO)
	var japanese := FontVariation.new()
	japanese.base_font = noto
	japanese.variation_opentype = {_tag("wght"): 400}
	var variation := FontVariation.new()
	variation.base_font = base
	variation.fallbacks = [japanese]
	# Zen Kaku, Shippori and Noto set their lines about a quarter taller than Antaka (50 px against
	# 40 at size 34). Trimmed to Antaka's line height so no screen grows when a style's body font is
	# swapped in (the text sweep caught it at Large text on the 9:16 shape).
	var excess := base.get_height(34) - ANTAKA_LINE_AT_34
	if excess > 0.0:
		variation.spacing_top = -int(floor(excess / 2.0))
		variation.spacing_bottom = -int(ceil(excess / 2.0))
	return variation


## The fill, border and radius of an ordinary button in this style, per state.
static func button_box(style: String, state: String, idx: Dictionary) -> StyleBoxFlat:
	var fill := UiStyles.plate_colour(idx, style)
	match state:
		"hover", "hover_pressed":
			fill = fill.lightened(0.08) if style != UiStyles.WOODBLOCK else fill.darkened(0.05)
		"pressed":
			fill = fill.lightened(0.14) if style != UiStyles.WOODBLOCK else fill.darkened(0.10)
		"disabled":
			fill = fill.lerp(UiStyles.ground_colour(idx, style), 0.45)
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	var radius := UiStyles.number(idx, style, "radius_px", "button", 10.0)
	if style == UiStyles.WOODBLOCK:
		radius = 2.0
	elif style == UiStyles.BROADCAST:
		radius = 4.0
	box.set_corner_radius_all(int(minf(radius, 26.0)))
	box.content_margin_left = 16.0
	box.content_margin_right = 16.0
	box.content_margin_top = 10.0
	box.content_margin_bottom = 10.0
	return box


static func build(style: String, idx: Dictionary) -> Theme:
	var theme := Theme.new()
	var paths := font_paths(style)
	var display := face(paths["display"])
	var body := face(paths["body"])
	theme.default_font = body
	var ink := UiStyles.plate_ink(idx, style)
	for type_name: String in BODY_TYPES:
		theme.set_font("font", type_name, body)
	theme.set_font("normal_font", "RichTextLabel", body)
	for type_name: String in DISPLAY_TYPES:
		theme.set_type_variation(type_name, "Label")
		theme.set_font("font", type_name, display)
	for type_name: String in ["Label", "SmallLabel", "TitleLabel", "HeaderLabel"]:
		theme.set_color("font_color", type_name, ink)
	theme.set_color("font_color", "JapaneseAccent", Color(ink.r, ink.g, ink.b, JP_ACCENT_ALPHA))
	theme.set_color("default_color", "RichTextLabel", ink)
	for key: String in ["font_color", "font_hover_color", "font_pressed_color",
			"font_focus_color", "font_hover_pressed_color"]:
		theme.set_color(key, "Button", ink)
	theme.set_color("font_disabled_color", "Button", Color(ink.r, ink.g, ink.b, 0.6))
	# Woodblock's ink is dark, for paper. Text that sits straight on a room picture (the battle, the
	# visits) would be dark on dark, so in Woodblock every label carries its own light paper plaque
	# (measured from pixels: 1.2 to 1 on the battle without one). The other styles' ink is light and
	# their labels carry none; every style sets the same items so a switch leaves nothing behind.
	var plaque: StyleBox = StyleBoxEmpty.new()
	if style == UiStyles.WOODBLOCK:
		var paper_box := StyleBoxFlat.new()
		var base := UiStyles.plate_colour(idx, style)
		paper_box.bg_color = Color(base.r, base.g, base.b, 0.94)
		paper_box.set_corner_radius_all(4)
		paper_box.content_margin_left = 5.0
		paper_box.content_margin_right = 5.0
		paper_box.content_margin_top = 3.0
		paper_box.content_margin_bottom = 3.0
		plaque = paper_box
	for type_name: String in ["Label", "SmallLabel", "TitleLabel", "HeaderLabel", "JapaneseAccent", "GaffeWarning"]:
		theme.set_stylebox("normal", type_name, plaque)
	# The cue's own labels sit on a band or a coloured tag: no plaque of their own.
	for type_name: String in ["CueBanner", "CueSpeaker"]:
		theme.set_stylebox("normal", type_name, StyleBoxEmpty.new())
	for type_name: String in ["Label", "SmallLabel", "TitleLabel", "HeaderLabel", "JapaneseAccent", "GaffeWarning", "CueBanner", "CueSpeaker"]:
		theme.set_color("font_outline_color", type_name, Color(0, 0, 0, 0))
		theme.set_constant("outline_size", type_name, 0)
	# The speaker's tag is a coloured chip: its name is light in every style.
	theme.set_color("font_color", "CueSpeaker", Color(1, 0.97, 0.92))
	for state: String in BUTTON_STATES:
		theme.set_stylebox(state, "Button", button_box(style, state, idx))
	return theme


static func _tag(text: String) -> int:
	var value := 0
	for index in 4:
		value = (value << 8) | text.unicode_at(index)
	return value
