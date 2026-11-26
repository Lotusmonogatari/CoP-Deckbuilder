class_name LevelBriefingStyles
extends RefCounted
## What differs between the three UI styles on the level briefing (P12, 2026-11-19, Cameron).
##
## The layout is the same in every style (LevelBriefingView); this is the one place that knows how a card, a tile,
## a number square, the hours badge and the two buttons are drawn in Woodblock, Living Office and Broadcast, the way
## DuesBox and CalendarSquare ask UiStyle while they build. The colours are the briefing's own palette in the UI
## Styles tab (colour tokens brief_*); the shapes and measurements come from the P12 mockups (design/proposals/img/
## level_preview), drawn at 390 px wide there and scaled here to the 1080 px base (S).

## One mockup pixel in base pixels.
const S := 1080.0 / 390.0

## Font sizes in mockup pixels (scaled by S and by the text-size setting).
## Antaka Brush Display draws wider here than in the mockups' browser, so its title is a little smaller than the
## mockups' 28 (the UI Styles tab's own title size for Living Office is 24).
const SIZE_TITLE := 22.0
## Living Office's hours ring is the widest badge and its theme leaves the least width, so its title is smaller still.
const SIZE_TITLE_LIVING := 19.0
const SIZE_TITLE_BROADCAST := 26.0
const SIZE_HEADING := 14.0
const SIZE_BODY := 13.0
const SIZE_SMALL := 11.5
const SIZE_BIG := 18.0
const SIZE_BUTTON := 16.0


## The look of the active style: its palette and flags. Colours are read fresh, so a changed style shows on the next build.
static func look() -> Dictionary:
	var style := UiStyle.current()
	var look := {"style": style, "wood": style == UiStyles.WOODBLOCK, "living": style == UiStyles.LIVING_OFFICE,
		"broadcast": style == UiStyles.BROADCAST}
	for name: String in ["ground", "on_ground", "on_ground_muted", "card", "ink", "muted", "tile", "accent", "on_accent", "hot"]:
		look[name] = UiStyle.colour("brief_" + name, Color.MAGENTA)
	# A campaign skin (P22) also sets the display face, the capitals and tracking of its titles, the numerals and the other skin colours.
	look["skin"] = UiStyle.scope
	look["caps"] = UiStyle.scoped_token("type", "title_case") == "upper"
	look["numerals"] = UiStyle.scoped_token("type", "numerals", "arabic")
	look["display_font"] = CampaignLook.display_font(UiStyle.scope) if not UiStyle.scope.is_empty() else null
	if not UiStyle.scope.is_empty():
		for token: String in ["card_label", "card_label_ink", "phase_bar", "phase_bar_ink", "phase_rule", "emblem_fill", "emblem_ink", "stamp", "jp", "bar_fill", "bar_track",
				"button", "button_ink", "tab_on", "shadow"]:
			look["skin_" + token] = UiStyle.colour(token, Color.MAGENTA)
	return look


## A font size in base pixels, from a size in mockup pixels, with the text-size setting applied.
static func px(mockup_px: float) -> int:
	var factor := TextScale.factor(Layout.text_size_setting, DataDB.balance)
	return TextScale.scaled(int(roundf(mockup_px * S)), factor)


## A length in base pixels, from mockup pixels (not scaled by the text-size setting).
static func len_px(mockup_px: float) -> float:
	return mockup_px * S


## The style's title, in capitals in Broadcast.
static func title_text(look: Dictionary, text: String) -> String:
	return text.to_upper() if look["broadcast"] or bool(look.get("caps", false)) else text


## A card (the totals card, the organizations card, a room's block).
static func card_box(look: Dictionary) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = look["card"]
	box.set_content_margin_all(len_px(10.0))
	if look["wood"]:
		box.set_border_width_all(int(len_px(2.0)))
		box.border_color = look["ink"]
		box.shadow_color = look["hot"]
		box.shadow_size = 1
		box.shadow_offset = Vector2(len_px(4.0), len_px(4.0))
	elif look["living"]:
		box.set_corner_radius_all(int(len_px(18.0)))
		box.shadow_color = Color(0, 0, 0, 0.35)
		box.shadow_size = int(len_px(10.0))
		box.shadow_offset = Vector2(0, len_px(5.0))
		box.set_border_width_all(1)
		box.border_color = Color("#E2CFAF")
	else:
		box.border_width_top = int(len_px(2.0))
		box.border_width_bottom = int(len_px(2.0))
		box.border_color = look["accent"]
	return box


## A tile inside the totals card, or a chip on a room's block.
static func tile_box(look: Dictionary, margin: float = 7.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = look["tile"]
	box.set_content_margin_all(len_px(margin))
	if look["living"]:
		box.set_corner_radius_all(int(len_px(12.0)))
	return box


## A reward chip on a room's block: the tile fill, with the style's edge where it has one.
static func chip_box(look: Dictionary) -> StyleBoxFlat:
	var box := tile_box(look, 4.0)
	box.content_margin_left = len_px(8.0)
	box.content_margin_right = len_px(8.0)
	if look["broadcast"]:
		box.set_border_width_all(1)
		box.border_color = look["accent"]
	return box


## The number square on a room's block (a circle in Living Office).
static func number_box(look: Dictionary) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = look["accent"]
	if look["living"]:
		box.set_corner_radius_all(int(len_px(12.0)))
	return box


## A secondary button (Back): an outline in the style's edge colour.
static func secondary_box(look: Dictionary) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	box.set_border_width_all(int(len_px(2.0 if look["wood"] else 1.0)))
	box.border_color = look["on_ground"] if look["wood"] else (look["on_ground_muted"] if look["living"] else look["accent"])
	if look["living"]:
		box.set_corner_radius_all(int(len_px(24.0)))
	return box


## The primary button's fill (Go in): indigo plank, amber pill, gold bar. `enabled` false greys it.
static func primary_box(look: Dictionary, enabled: bool) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = look["accent"] if enabled else Color(look["on_ground_muted"].r, look["on_ground_muted"].g, look["on_ground_muted"].b, 0.35)
	if look["living"]:
		box.set_corner_radius_all(int(len_px(24.0)))
	return box


## The ink on the primary button.
static func primary_ink(look: Dictionary, enabled: bool) -> Color:
	return look["on_accent"] if enabled else look["on_ground"]


## The hours badge beside the title: a tilted vermilion seal (Woodblock), an amber ring (Living Office) or a gold
## slanted chip (Broadcast). Returns the badge with its labels already in it.
static func hours_badge(look: Dictionary, hours: int) -> Control:
	var number := str(hours)
	var word := Text.say("briefing.badge_hours.one" if hours == 1 else "briefing.badge_hours")
	# The badge grows with the text-size setting (never shrinks), so "hours" stays inside its seal or ring at Large.
	var grow := maxf(1.0, TextScale.factor(Layout.text_size_setting, DataDB.balance))
	var plate := BriefingPlate.new()
	plate.name = "HoursBadge"
	plate.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate.add_child(column)
	var ink: Color = look["on_accent"]
	var tilt := 0.0
	if look["wood"]:
		plate.custom_minimum_size = Vector2(len_px(56.0), len_px(56.0)) * grow
		plate.shape = BriefingPlate.Shape.RECT
		plate.fill = look["hot"]
		plate.edge = look["ink"]
		plate.edge_width = len_px(2.0)
		ink = look["card"]
		tilt = -3.0
		column.add_child(_badge_label(number, SIZE_TITLE * 0.86, ink, true))
		column.add_child(_badge_label(word, 11.0, ink, false))
	elif look["living"]:
		plate.custom_minimum_size = Vector2(len_px(58.0), len_px(58.0)) * grow
		plate.shape = BriefingPlate.Shape.RING
		plate.edge = look["accent"]
		plate.edge_width = len_px(4.0)
		ink = look["on_ground"]
		column.add_child(_badge_label(number, 20.0, ink, false))
		column.add_child(_badge_label(word, 11.0, ink, false))
	else:
		plate.custom_minimum_size = Vector2(len_px(86.0), len_px(34.0)) * grow
		plate.shape = BriefingPlate.Shape.SLANT
		plate.fill = look["accent"]
		plate.slant = len_px(10.0)
		column.add_child(_badge_label("%s %s" % [number, word.to_upper()], 15.0, ink, true))
	# A container resets a child's rotation, so the badge sits in a plain holder of its size and is tilted there.
	var holder := Control.new()
	holder.name = "HoursBadgeHolder"
	holder.custom_minimum_size = plate.custom_minimum_size
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.size = plate.custom_minimum_size
	plate.pivot_offset = plate.custom_minimum_size * 0.5
	plate.rotation_degrees = tilt
	holder.add_child(plate)
	return holder


static func _badge_label(text: String, mockup_px: float, colour: Color, display: bool) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", px(mockup_px))
	label.add_theme_color_override("font_color", colour)
	if display:
		label.theme_type_variation = "HeaderLabel"
	label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## Dresses a Button as the style's primary (Go in) or secondary (Back) button. Broadcast's primary is a slanted gold
## bar: a plate drawn behind a button with no box of its own.
static func dress_button(button: Button, look: Dictionary, primary: bool, enabled: bool = true) -> void:
	var ink: Color = primary_ink(look, enabled) if primary else look["on_ground"]
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
		button.add_theme_color_override(state, ink)
	button.add_theme_font_size_override("font_size", px(SIZE_BUTTON))
	var slanted: bool = look["broadcast"] and primary
	var box: StyleBox = StyleBoxEmpty.new() if slanted else (primary_box(look, enabled) if primary else secondary_box(look))
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, box)
	if slanted:
		var plate := BriefingPlate.new()
		plate.name = "SlantPlate"
		plate.shape = BriefingPlate.Shape.SLANT
		plate.fill = look["accent"] if enabled else Color(look["on_ground_muted"].r, look["on_ground_muted"].g, look["on_ground_muted"].b, 0.35)
		plate.slant = len_px(9.0)
		plate.show_behind_parent = true
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.add_child(plate)
