class_name OfficeFrameStyles
extends RefCounted
## What differs between the three UI styles on the Office screens' shared frame (P13, 2026-11-20).
##
## The arrangement is the same in every style (OfficeScreenFrame); this is the one place that knows how a card, a chip,
## a tab and the "‹ Office" control are drawn in Woodblock, Living Office and Broadcast. It reuses the P12 palette
## (colour tokens brief_*: the mockups of both panels use the same paper, ink and accent) and its shapes
## (LevelBriefingStyles), and adds the rise and fall colours (frame_up, frame_down) from the UI Styles tab.
## Draws only: no rule and no sentence lives here.

## The names of the theme overrides put on the "‹ Office" control, so they can be taken off again.
const _BACK_COLOURS: Array[String] = ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color",
	"font_hover_pressed_color", "font_disabled_color"]
const _STATES: Array[String] = ["normal", "hover", "pressed", "disabled", "focus"]


## The look of the active style: the briefing palette and flags, plus `up` and `down`.
static func look() -> Dictionary:
	var out := LevelBriefingStyles.look()
	out["up"] = UiStyle.colour("frame_up", Color("#2E6B34"))
	out["down"] = UiStyle.colour("frame_down", Color("#A3261A"))
	return out


## A font size in base pixels from a size in mockup pixels, with the text-size setting applied.
static func px(mockup_px: float) -> int:
	return LevelBriefingStyles.px(mockup_px)


## A length in base pixels from mockup pixels (not scaled by the text-size setting).
static func len_px(mockup_px: float) -> float:
	return LevelBriefingStyles.len_px(mockup_px)


## The smallest height of anything the player taps: 44 px in the 390 px mockup, 122 px at the 1080 px base.
static func touch_height() -> float:
	return ceilf(len_px(44.0))


## The screen title's size in mockup pixels: Broadcast's condensed face is narrower, so it can be larger.
static func title_size(look: Dictionary) -> float:
	return LevelBriefingStyles.SIZE_TITLE_BROADCAST if look["broadcast"] else LevelBriefingStyles.SIZE_TITLE


## A Theme that sets the ink for the labels inside a card. A card is paper in Woodblock and Living Office but navy in
## Broadcast, so its text takes the card's own ink instead of the room's.
static func card_theme(look: Dictionary) -> Theme:
	var theme := frame_theme()
	if look.get("display_font") != null:
		theme.set_font("font", "HeaderLabel", look["display_font"])   # a campaign skin's display face (P22)
	theme.set_color("font_color", "Label", look["ink"])
	theme.set_color("font_color", "HeaderLabel", look["ink"])
	theme.set_color("font_color", "SmallLabel", look["muted"])
	return theme


## A Theme for everything on the frame: labels carry no plate box of their own. The styles' themes put a pale plaque
## behind every label (Woodblock), which shows as a lighter block on a tile; the frame's cards and tiles are the
## surfaces here, so the text sits straight on them.
static func frame_theme() -> Theme:
	var theme := Theme.new()
	theme.set_type_variation("HeaderLabel", "Label")
	theme.set_type_variation("SmallLabel", "Label")
	for type_name: String in ["Label", "HeaderLabel", "SmallLabel"]:
		theme.set_stylebox("normal", type_name, StyleBoxEmpty.new())
	# A campaign skin replaces every look (P22): its text takes Woodblock's faces even when the player's look is another.
	if not UiStyle.scope.is_empty():
		var wood := UiStyle.overlay(UiStyles.WOODBLOCK)
		for type_name: String in ["Label", "HeaderLabel", "SmallLabel", "Button"]:
			if wood.has_font("font", type_name):
				theme.set_font("font", type_name, wood.get_font("font", type_name))
	return theme

## A card: the style's box, a theme for its ink, and a column inside it named "Column". `title` is the card's heading
## (empty for none). Returns the card; add rows to `card.get_node("Column")`.
static func card(look: Dictionary, title: String = "") -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "FrameCard"
	card.add_theme_stylebox_override("panel", LevelBriefingStyles.card_box(look))
	card.theme = card_theme(look)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.name = "Column"
	column.add_theme_constant_override("separation", int(len_px(8.0)))
	card.add_child(column)
	if not title.is_empty():
		var heading := Label.new()
		heading.name = "CardTitle"
		heading.text = LevelBriefingStyles.title_text(look, title)
		heading.theme_type_variation = "HeaderLabel"
		heading.add_theme_font_size_override("font_size", px(LevelBriefingStyles.SIZE_HEADING + 2.0))
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(heading)
	return card


## A danger box (the Resign box): a card with a red edge and a faint red wash, its title in the style's fall colour.
static func danger_card(look: Dictionary, title: String) -> PanelContainer:
	var box := card(look, title)
	var base := LevelBriefingStyles.card_box(look)
	var down: Color = look["down"]
	base.bg_color = (look["card"] as Color).lerp(down, 0.12)
	base.set_border_width_all(int(len_px(2.0)))
	base.border_color = down
	box.add_theme_stylebox_override("panel", base)
	var heading := box.find_child("CardTitle", true, false) as Label
	if heading != null:
		heading.add_theme_color_override("font_color", down)
	return box


## A signed change as a button that shows only the number: outlined in the style's rise or fall colour, as tall as a
## touch target. `change` decides the colour. Pressing it opens the reasons behind the number.
static func signed_button(look: Dictionary, node: String, text: String, change: int) -> Button:
	var button := Button.new()
	button.name = node
	button.text = text
	button.autowrap_mode = TextServer.AUTOWRAP_OFF
	button.set_meta(UiKit.ONE_LINE_META, true)
	var ink: Color = look["up"] if change > 0 else look["down"]
	for state: String in _BACK_COLOURS:
		button.add_theme_color_override(state, ink)
	button.add_theme_font_size_override("font_size", px(LevelBriefingStyles.SIZE_BODY + 1.0))
	var box := StyleBoxFlat.new()
	box.bg_color = Color(ink.r, ink.g, ink.b, 0.10)
	box.set_border_width_all(int(len_px(1.5)))
	box.border_color = ink
	if look["living"]:
		box.set_corner_radius_all(int(len_px(22.0)))
	box.content_margin_left = len_px(14.0)
	box.content_margin_right = len_px(14.0)
	for state: String in _STATES:
		button.add_theme_stylebox_override(state, box)
	button.custom_minimum_size = Vector2(len_px(52.0), touch_height())
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return button


## A status chip on the top bar (Funds, XP, week, office, hours left, Saved): the accent fill with the ink on it; a pill
## in Living Office, a slanted plate in Broadcast, a square plaque in Woodblock.
static func chip(look: Dictionary, text: String) -> Control:
	var holder := PanelContainer.new()
	holder.name = "FrameChip"
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.name = "ChipText"
	label.text = text
	label.add_theme_font_size_override("font_size", px(LevelBriefingStyles.SIZE_SMALL + 1.0))
	label.add_theme_color_override("font_color", look["on_accent"])
	label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	if look["broadcast"]:
		# A slanted plate cannot be a StyleBox: it is drawn behind the label, and a padding box (not the panel's own
		# margins, which would shrink the plate too) leaves room for the slant.
		holder.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var plate := BriefingPlate.new()
		plate.name = "ChipPlate"
		plate.shape = BriefingPlate.Shape.SLANT
		plate.fill = look["accent"]
		plate.slant = len_px(8.0)
		holder.add_child(plate)
		var pad := MarginContainer.new()
		pad.name = "ChipPad"
		pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pad.add_theme_constant_override("margin_left", int(len_px(16.0)))
		pad.add_theme_constant_override("margin_right", int(len_px(16.0)))
		pad.add_theme_constant_override("margin_top", int(len_px(4.0)))
		pad.add_theme_constant_override("margin_bottom", int(len_px(4.0)))
		pad.add_child(label)
		holder.add_child(pad)
		return holder
	var box := StyleBoxFlat.new()
	box.content_margin_left = len_px(10.0)
	box.content_margin_right = len_px(10.0)
	box.content_margin_top = len_px(4.0)
	box.content_margin_bottom = len_px(4.0)
	box.bg_color = look["accent"]
	if look["living"]:
		box.set_corner_radius_all(int(len_px(14.0)))
	holder.add_theme_stylebox_override("panel", box)
	holder.add_child(label)
	return holder

## Dresses a tab. The chosen tab is the style's primary button (filled); the others are outlines.
static func dress_tab(button: Button, look: Dictionary, chosen: bool) -> void:
	LevelBriefingStyles.dress_button(button, look, chosen, true)
	button.custom_minimum_size.y = touch_height()
	# The briefing's buttons are wide; a tab needs room round its word.
	for state: String in _STATES:
		var box := button.get_theme_stylebox(state)
		if box != null:
			box.content_margin_left = len_px(14.0)
			box.content_margin_right = len_px(14.0)


## Dresses a button that sits INSIDE a card: an outline in the card's own ink (the briefing's secondary button is inked
## for the room, which is cream on cream in Living Office).
static func dress_card_button(button: Button, look: Dictionary, enabled: bool = true) -> void:
	var ink: Color = look["ink"] if enabled else look["muted"]
	for state: String in _BACK_COLOURS:
		button.add_theme_color_override(state, ink)
	button.add_theme_font_size_override("font_size", px(LevelBriefingStyles.SIZE_BUTTON))
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	box.set_border_width_all(int(len_px(2.0 if look["wood"] else 1.0)))
	box.border_color = ink
	if look["living"]:
		box.set_corner_radius_all(int(len_px(24.0)))
	box.content_margin_left = len_px(12.0)
	box.content_margin_right = len_px(12.0)
	for state: String in _STATES:
		button.add_theme_stylebox_override(state, box)


## Dresses the "‹ Office" control: no box, the room's ink, as tall as a touch target.
static func dress_back(button: Button, look: Dictionary) -> void:
	for state: String in _BACK_COLOURS:
		button.add_theme_color_override(state, look["on_ground"])
	button.add_theme_font_size_override("font_size", px(LevelBriefingStyles.SIZE_BUTTON))
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = len_px(4.0)
	empty.content_margin_right = len_px(12.0)
	for state: String in _STATES:
		button.add_theme_stylebox_override(state, empty)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(0.0, touch_height())
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	# One line, whatever the Back button did before: a pop-up card wraps the buttons it borrows, and a wrapping Back shrinks to one letter
	# wide and tall (a tester's report, 2026-11-24: the Marketplace's "‹ Office" disappeared after an event result over it).
	button.autowrap_mode = TextServer.AUTOWRAP_OFF
	button.set_meta(UiKit.ONE_LINE_META, true)


## Takes the frame's dress off the Back control again, so an ordinary panel gets the plain button back.
static func undress_back(button: Button) -> void:
	for state: String in _BACK_COLOURS:
		button.remove_theme_color_override(state)
	button.remove_theme_font_size_override("font_size")
	for state: String in _STATES:
		button.remove_theme_stylebox_override(state)
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.size_flags_horizontal = Control.SIZE_FILL
	button.custom_minimum_size = Vector2(0.0, 110.0)
