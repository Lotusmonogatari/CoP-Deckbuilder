class_name CodexViews
extends RefCounted
## The pieces of the Library's Codex and reference desk (P18, 2026-11-24): a closed scroll for the list, an unrolled scroll for the
## reader, the six-style reading and its meters, and the desk's tip box. They draw what they are given; nothing here reads a rule.
## The looks come from ScrollStyle (the UI Styles tab); every sentence is a Text row or a document's own text.

const NEW_NODE := "NewMark"
const SEALED_NODE := "SealedMark"


# --- Small helpers ----------------------------------------------------------------------------------------------------------------

## A label in the scroll's own ink: `mockup_px` size, never boxed, on one wrapping column.
static func ink_label(text: String, mockup_px: float, colour: Color, display: bool = false, node_name: String = "", one_line: bool = false) -> Label:
	var label := Label.new()
	if not node_name.is_empty():
		label.name = node_name
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 0.0
	label.add_theme_font_size_override("font_size", OfficeFrameStyles.px(mockup_px))
	label.add_theme_color_override("font_color", colour)
	label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if display:
		label.theme_type_variation = "HeaderLabel"
	if one_line:
		# A tag, a count or a word beside another: it keeps one line and its own width (UiKit.wrap_all leaves it alone).
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.set_meta(UiKit.ONE_LINE_META, true)
	return label


static func _margin(child: Control, left: float, top: float, right: float, bottom: float) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", int(ScrollStyle.len_px(left)))
	margin.add_theme_constant_override("margin_top", int(ScrollStyle.len_px(top)))
	margin.add_theme_constant_override("margin_right", int(ScrollStyle.len_px(right)))
	margin.add_theme_constant_override("margin_bottom", int(ScrollStyle.len_px(bottom)))
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(child)
	return margin


static func _ignore_mouse(root: Node) -> void:
	for node: Node in root.find_children("*", "Control", true, false):
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	if root is Control:
		(root as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


# --- The list ---------------------------------------------------------------------------------------------------------------------

## A category's heading: its name on the left, its count on the right.
static func category_heading(title: String, count_text: String) -> Control:
	var look := OfficeFrameStyles.look()
	var row := HBoxContainer.new()
	row.name = "CategoryHeading"
	var name_label := ink_label(title.to_upper() if not _has_kana(title) else title, 12.0, look["on_ground"], true)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var count := ink_label(count_text, 12.0, look["on_ground_muted"], false, "", true)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(count)
	return row


static func _has_kana(text: String) -> bool:
	for index in range(text.length()):
		if text.unicode_at(index) > 0x2E80:
			return true
	return false


## One closed scroll: a roller at each end, the paper between with its title and its one line, and NEW or Sealed on the right.
## `doc` = {"id", "title", "line", "state": "new" | "read" | "sealed", "node": the tap target's name}. `on_open` is called with the id;
## a sealed scroll cannot be tapped.
static func closed_scroll(doc: Dictionary, on_open: Callable) -> Control:
	var sealed := str(doc.get("state", "")) == "sealed"
	var holder := PanelContainer.new()
	holder.name = "Scroll_" + str(doc.get("id", ""))
	holder.add_theme_stylebox_override("panel", _row_shadow_box())
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var strip := HBoxContainer.new()
	strip.add_theme_constant_override("separation", 0)
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(strip)
	strip.add_child(_roller(true, sealed))
	var paper := ScrollPaper.new()
	paper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", int(ScrollStyle.len_px(8.0)))
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 0)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	texts.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ink := ScrollStyle.colour("ink")
	var muted := ScrollStyle.colour("muted")
	if sealed:
		holder.modulate = Color(1, 1, 1, 0.6)   # faded: a document not yet found
	texts.add_child(ink_label(str(doc.get("title", "")), 17.0, ink, true, "ScrollTitle"))
	texts.add_child(ink_label(str(doc.get("line", "")), 12.0, muted, false, "ScrollLine"))
	inner.add_child(texts)
	var state := str(doc.get("state", ""))
	if state == "new":
		inner.add_child(_mark(Text.say("codex.new"), true, NEW_NODE))
	elif sealed:
		var word := ink_label(Text.say("codex.sealed"), 12.0, muted, false, SEALED_NODE, true)
		word.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		inner.add_child(word)
	paper.add_child(_margin(inner, 14.0, 10.0, 14.0, 10.0))
	strip.add_child(paper)
	strip.add_child(_roller(true, sealed))
	# The whole row is one tap target, laid over the picture of the scroll.
	var tap := Button.new()
	tap.name = str(doc.get("node", "Doc_" + str(doc.get("id", ""))))
	tap.flat = true
	tap.focus_mode = Control.FOCUS_NONE
	tap.disabled = sealed
	for state_name: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		tap.add_theme_stylebox_override(state_name, StyleBoxEmpty.new())
	tap.custom_minimum_size = Vector2(0, ceilf(ScrollStyle.len_px(62.0)))
	if not sealed:
		tap.pressed.connect(Haptics.confirm)
		tap.pressed.connect(on_open.bind(str(doc.get("id", ""))))
	holder.add_child(tap)
	return holder


static func _roller(vertical: bool, dim: bool) -> ScrollRoller:
	var roller := ScrollRoller.new()
	roller.vertical = vertical
	roller.dim = dim
	if vertical:
		roller.custom_minimum_size.x = ScrollStyle.len_px(10.0)
	else:
		roller.custom_minimum_size.y = ScrollStyle.len_px(16.0)
	return roller


## The NEW tag: the kicker's colour behind the seal's ink.
static func _mark(text: String, filled: bool, node_name: String) -> Control:
	var plate := PanelContainer.new()
	plate.name = node_name
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = ScrollStyle.colour("kicker") if filled else Color(0, 0, 0, 0)
	box.content_margin_left = ScrollStyle.len_px(7.0)
	box.content_margin_right = ScrollStyle.len_px(7.0)
	box.content_margin_top = ScrollStyle.len_px(2.0)
	box.content_margin_bottom = ScrollStyle.len_px(2.0)
	plate.add_theme_stylebox_override("panel", box)
	var label := ink_label(text, 11.0, ScrollStyle.colour("paper") if filled else ScrollStyle.colour("kicker"), true, "", true)
	plate.add_child(label)
	return plate


## The shadow behind a list row: a hard offset block, a soft shadow or none, by the style's row_shadow token.
static func _row_shadow_box() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0, 0, 0, 0)
	match ScrollStyle.text("row_shadow", "none"):
		"hard":
			box.shadow_color = ScrollStyle.colour("row_shadow")
			box.shadow_size = 1
			box.shadow_offset = Vector2(ScrollStyle.len_px(3.0), ScrollStyle.len_px(3.0))
		"soft":
			box.shadow_color = Color(ScrollStyle.colour("row_shadow"), 0.35)
			box.shadow_size = int(ScrollStyle.len_px(8.0))
			box.shadow_offset = Vector2(0.0, ScrollStyle.len_px(3.0))
	return box


# --- The reader -------------------------------------------------------------------------------------------------------------------

## An unrolled scroll: the top roller, the paper with the document, the seal in its lower corner, the bottom roller and (where the
## style has one) the cord. `doc` = {"kicker", "title", "title_jp", "subtitle", "paragraphs": Array[String], "extra": Control or null,
## "footer": String}.
static func reader(doc: Dictionary) -> Control:
	var column := VBoxContainer.new()
	column.name = "OpenScroll"
	column.add_theme_constant_override("separation", 0)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(_roller(false, false))
	var paper := ScrollPaper.new()
	paper.name = "ScrollPaper"
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", int(ScrollStyle.len_px(10.0)))
	var kicker := str(doc.get("kicker", ""))
	if not kicker.is_empty():
		body.add_child(ink_label(kicker.to_upper() if not _has_kana(kicker) else kicker, 12.0, ScrollStyle.colour("kicker"), true, "ScrollKicker"))
	body.add_child(ink_label(str(doc.get("title", "")), 26.0, ScrollStyle.colour("ink"), true, "ScrollHeading"))
	var jp := str(doc.get("title_jp", ""))
	if not jp.is_empty():
		body.add_child(ink_label(jp, 13.0, ScrollStyle.colour("muted"), false, "ScrollTitleJp"))
	var subtitle := str(doc.get("subtitle", ""))
	if not subtitle.is_empty():
		body.add_child(ink_label(subtitle, 12.0, ScrollStyle.colour("muted"), false, "ScrollSubtitle"))
	var rule := ColorRect.new()
	rule.color = ScrollStyle.colour("rule_line")
	rule.custom_minimum_size.y = maxf(1.0, ScrollStyle.len_px(ScrollStyle.number("rule_px", 1.0)))
	body.add_child(rule)
	for paragraph: Variant in doc.get("paragraphs", []):
		body.add_child(ink_label(str(paragraph), 14.0, ScrollStyle.colour("ink"), false, "ScrollParagraph"))
	var extra: Variant = doc.get("extra")
	if extra is Control:
		body.add_child(extra as Control)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", int(ScrollStyle.len_px(10.0)))
	var footer := ink_label(str(doc.get("footer", "")), 12.0, ScrollStyle.colour("muted"), false, "ScrollFooter")
	footer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.size_flags_vertical = Control.SIZE_SHRINK_END
	foot.add_child(footer)
	foot.add_child(seal())
	body.add_child(foot)
	paper.add_child(_margin(body, 22.0, 18.0, 22.0, 14.0))
	column.add_child(_margin_wrap(paper))
	column.add_child(_roller(false, false))
	if ScrollStyle.yes("cord"):
		column.add_child(_cord())
	return column


static func _margin_wrap(paper: Control) -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", int(ScrollStyle.len_px(6.0)))
	margin.add_theme_constant_override("margin_right", int(ScrollStyle.len_px(6.0)))
	margin.add_child(paper)
	return margin


## The cord and bead that hang from the bottom roller (Woodblock and Living Office).
static func _cord() -> Control:
	var holder := Control.new()
	holder.name = "ScrollCord"
	holder.custom_minimum_size.y = ScrollStyle.len_px(34.0)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var line := ColorRect.new()
	line.color = ScrollStyle.colour("cord")
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var width := maxf(2.0, ScrollStyle.len_px(1.5))
	line.set_anchors_preset(Control.PRESET_CENTER_TOP)
	line.offset_left = -width * 0.5
	line.offset_right = width * 0.5
	line.offset_bottom = ScrollStyle.len_px(24.0)
	holder.add_child(line)
	var bead := Panel.new()
	var box := StyleBoxFlat.new()
	box.bg_color = ScrollStyle.colour("cord")
	box.set_corner_radius_all(int(ScrollStyle.len_px(6.0)))
	bead.add_theme_stylebox_override("panel", box)
	bead.set_anchors_preset(Control.PRESET_CENTER_TOP)
	bead.offset_left = -ScrollStyle.len_px(5.0)
	bead.offset_right = ScrollStyle.len_px(5.0)
	bead.offset_top = ScrollStyle.len_px(22.0)
	bead.offset_bottom = ScrollStyle.len_px(32.0)
	bead.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(bead)
	return holder


## The Library's seal: a square or round stamp, tilted, with its text set vertically (kanji) or across (FILED), ringed when the style
## says so. Sits in a plain holder because a container would reset a child's rotation.
static func seal() -> Control:
	var side := ScrollStyle.len_px(52.0)
	var holder := Control.new()
	holder.name = "ScrollSeal"
	holder.custom_minimum_size = Vector2(side, side) * 1.15
	holder.size_flags_vertical = Control.SIZE_SHRINK_END
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var stamp := PanelContainer.new()
	stamp.size = Vector2(side, side)
	stamp.custom_minimum_size = Vector2(side, side)
	stamp.position = Vector2(side, side) * 0.075
	stamp.pivot_offset = Vector2(side, side) * 0.5
	stamp.rotation_degrees = ScrollStyle.number("seal_tilt", 0.0)
	stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = ScrollStyle.colour("seal")
	if ScrollStyle.text("seal_shape", "square") == "round":
		box.set_corner_radius_all(int(side * 0.5))
	else:
		box.set_corner_radius_all(int(ScrollStyle.len_px(3.0)))
	if ScrollStyle.yes("seal_ring"):
		box.set_border_width_all(int(maxf(2.0, ScrollStyle.len_px(2.0))))
		box.border_color = ScrollStyle.colour("paper")
	stamp.add_theme_stylebox_override("panel", box)
	var words := ScrollStyle.text("seal_text", "")
	var ink := ScrollStyle.colour("seal_ink")
	var face := HBoxContainer.new()
	face.alignment = BoxContainer.ALIGNMENT_CENTER
	face.add_theme_constant_override("separation", 0)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ScrollStyle.yes("seal_vertical"):
		# Columns of up to three characters, the first column on the right (as vertical Japanese is read).
		var columns: Array[String] = []
		var index := 0
		var per_column := 3 if words.length() > 3 else words.length()
		while index < words.length():
			columns.append(words.substr(index, per_column))
			index += per_column
		columns.reverse()   # added left to right, so the first column (read first) ends up on the right
		for column_text: String in columns:
			face.add_child(ink_label("\n".join(column_text.split("")), 11.0, ink, false, "", true))
		for label: Node in face.get_children():
			(label as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			(label as Label).autowrap_mode = TextServer.AUTOWRAP_OFF
			(label as Label).add_theme_constant_override("line_spacing", 0)
	else:
		var label := ink_label(words, 11.0, ink, true, "", true)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		face.add_child(label)
	stamp.add_child(face)
	holder.add_child(stamp)
	return holder


# --- The reading (the reference desk and a Room file) --------------------------------------------------------------------------------

## The six styles' reading as rows: the suit's chip, its phrase and the band word with a five-step meter. `ink`, `muted` and `rule` are
## the colours of the surface it sits on (a card in the desk, the paper in a Room file).
static func reading_rows(reading: Array, ink: Color, rule: Color) -> Control:
	var column := VBoxContainer.new()
	column.name = "ReadingRows"
	column.add_theme_constant_override("separation", 0)
	for entry: Variant in reading:
		var row := entry as Dictionary
		var band := str(row.get("band", "neutral"))
		var holder := VBoxContainer.new()
		holder.name = "Reading_" + str(row.get("suit", "")).replace(" ", "")
		holder.add_theme_constant_override("separation", 0)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", int(ScrollStyle.len_px(10.0)))
		var chip := VenueViews.suit_chip(str(row.get("suit", "")))
		chip.custom_minimum_size.x = ScrollStyle.len_px(96.0)
		line.add_child(chip)
		var phrase := ink_label(VenueViews.rhetoric_phrase(str(row.get("suit", ""))), 13.0, ink)
		phrase.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		phrase.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_child(phrase)
		line.add_child(_band(band, int(row.get("meter", 3)), ink))
		holder.add_child(_margin(line, 0.0, 7.0, 0.0, 7.0))
		var divider := ColorRect.new()
		divider.color = Color(rule, 0.45)
		divider.custom_minimum_size.y = maxf(1.0, ScrollStyle.len_px(0.7))
		divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(divider)
		column.add_child(holder)
	return column


## The band word over its five-step meter: green for the top two bands, red for the bottom two, the ink between.
static func _band(band: String, meter: int, ink: Color) -> Control:
	var look := OfficeFrameStyles.look()
	var tone := ink
	if band in ["strongest", "strong"]:
		tone = look["up"]
	elif band in ["weak", "weakest"]:
		tone = look["down"]
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", int(ScrollStyle.len_px(3.0)))
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var word := ink_label(band_word(band), 12.0, tone, true, "Band", true)
	word.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(word)
	var steps := HBoxContainer.new()
	steps.name = "Meter"
	steps.alignment = BoxContainer.ALIGNMENT_END
	steps.add_theme_constant_override("separation", int(ScrollStyle.len_px(2.0)))
	steps.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for step in range(1, 6):
		var cell := ColorRect.new()
		cell.custom_minimum_size = Vector2(ScrollStyle.len_px(9.0), ScrollStyle.len_px(5.0))
		cell.color = tone if step <= meter else Color(tone, 0.22)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		steps.add_child(cell)
	column.add_child(steps)
	return column


## A band's word, by its id from Codex.band_for.
static func band_word(band: String) -> String:
	match band:
		"strongest": return Text.say("desk.band_strongest")
		"strong": return Text.say("desk.band_strong")
		"neutral": return Text.say("desk.band_neutral")
		"weak": return Text.say("desk.band_weak")
		"weakest": return Text.say("desk.band_weakest")
	return band


## The desk's tip box under a reading: its heading, the sentence with the stage and the phrase in bold-ish display type, and the note.
static func desk_tip_box(stage_name: String, suit: String, days: int, look: Dictionary) -> Control:
	var box := PanelContainer.new()
	box.name = "DeskTipBox"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(look["up"], 0.08)
	style.border_color = look["up"]
	style.set_border_width_all(int(maxf(2.0, ScrollStyle.len_px(1.5))))
	for side: String in ["left", "right"]:
		style.set("content_margin_" + side, ScrollStyle.len_px(12.0))
	style.content_margin_top = ScrollStyle.len_px(10.0)
	style.content_margin_bottom = ScrollStyle.len_px(10.0)
	box.add_theme_stylebox_override("panel", style)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", int(ScrollStyle.len_px(6.0)))
	box.add_child(column)
	var heading := ink_label(Text.say("desk.tip_heading").to_upper(), 11.0, look["on_ground_muted"], true, "DeskTipHeading")
	column.add_child(heading)
	var sentence := ink_label(Text.say("desk.tip_line", {"stage": stage_name, "phrase": VenueViews.rhetoric_phrase(suit)}), 14.0, look["on_ground"], false, "DeskTipSentence")
	column.add_child(sentence)
	column.add_child(ink_label(Text.say("desk.tip_foot", {"days": days}), 11.5, look["on_ground_muted"], false, "DeskTipFoot"))
	return box
