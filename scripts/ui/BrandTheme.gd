class_name BrandTheme
extends RefCounted
## The look of Brand B, "The Assembly Seal" (P10, 2026-11-18), for the start screen: the colours, the font and the
## three button styles. It is the brand, so it does not follow the UI style (the style is saved with the run, and
## the start screen comes before any run). Nothing else in the game reads this. Spec: design/proposals/BRAND_B_SPEC_2026-11-18.md.

const INDIGO := Color("#1F3561")
const INDIGO_DARK := Color("#142443")
const WAVE_BLUE := Color("#3E5C8A")
const WASHI := Color("#F1E6CF")
const PAPER := Color("#F8F1E3")
## The seal's and the plate borders' colour: shapes only, never text (it is 4.3 to 1 on washi, under the 4.5 text rule).
const VERMILION := Color("#C23B22")
const SUMI := Color("#1C1A17")
const QUIET_INK := Color("#5A5146")
const RULE_GREY := Color("#8C7F6B")

const CORNER := 14

static var _fonts := {}


## Antaka Brush Display (Cameron, 2026-11-18, after seeing every custom font on the start screen), with Noto Sans JP
## behind it so the Japanese in the footer (蓮物語) and any glyph Antaka lacks (it is Latin only: no "·", "ō", "−",
## "×", "•" or "→") are drawn per glyph by the Japanese font. Antaka has one weight, so `bold` makes no difference.
static func font(_bold: bool = true) -> Font:
	if not _fonts.has("display"):
		var base := (load("res://assets/fonts/AntakaBrushDisplay-Regular.ttf") as FontFile).duplicate() as FontFile
		var japanese: Font = load("res://assets/fonts/NotoSansJP[wght].ttf")
		base.fallbacks = [japanese]
		_fonts["display"] = base
	return _fonts["display"]


## The text-size setting's multiplier (Small, Normal or Large), so the start screen grows and shrinks with the rest.
static func scale() -> float:
	return TextScale.factor(Layout.text_size_setting, DataDB.balance)


## A label in the brand: font, size (before the text-size setting) and colour, with no plate behind it.
static func style_label(label: Label, size: int, colour: Color, bold: bool, spacing: float = 0.0) -> void:
	label.add_theme_font_override("font", font(bold))
	label.add_theme_font_size_override("font_size", TextScale.scaled(size, scale()))
	label.add_theme_color_override("font_color", colour)
	label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	if spacing != 0.0:
		var variation := FontVariation.new()
		variation.base_font = font(bold)
		variation.spacing_glyph = int(round(spacing * size))
		label.add_theme_font_override("font", variation)


enum Kind { PRIMARY, SECONDARY, TERTIARY }


## One of the three buttons: PRIMARY is the indigo plank with its darker underside, SECONDARY the paper button with
## an indigo outline, TERTIARY the thin grey-ruled one. A disabled button is the same colours at 45% (never red).
static func style_button(button: Button, kind: Kind, size: int) -> void:
	var fill := Color(0, 0, 0, 0)
	var ink := SUMI
	var border := Color(0, 0, 0, 0)
	var border_width := 0
	var underside := 0
	var bold := true
	match kind:
		Kind.PRIMARY:
			fill = INDIGO
			ink = PAPER
			border = INDIGO_DARK
			underside = 11
		Kind.SECONDARY:
			fill = PAPER
			ink = INDIGO
			border = INDIGO
			border_width = 6
		Kind.TERTIARY:
			ink = SUMI
			border = RULE_GREY
			border_width = 3
			bold = false
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(CORNER)
	box.set_border_width_all(border_width)
	box.border_width_bottom = maxi(border_width, underside)
	box.border_color = border
	box.set_content_margin_all(12)
	var pressed := box.duplicate() as StyleBoxFlat
	pressed.bg_color = fill.darkened(0.12) if fill.a > 0.0 else Color(SUMI.r, SUMI.g, SUMI.b, 0.06)
	var disabled := box.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(fill.r, fill.g, fill.b, fill.a * 0.45)
	disabled.border_color = Color(border.r, border.g, border.b, border.a * 0.45)
	for state: String in ["normal", "hover", "focus"]:
		button.add_theme_stylebox_override(state, box)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_font_override("font", font(bold))
	button.add_theme_font_size_override("font_size", TextScale.scaled(size, scale()))
	for colour_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(colour_name, ink)
	button.add_theme_color_override("font_disabled_color", Color(ink.r, ink.g, ink.b, 0.45))
	button.add_theme_constant_override("outline_size", 0)
