class_name LevelBriefingView
extends RefCounted
## Draws the level briefing from LevelBriefing's dictionary (P12, 2026-11-19, Cameron): Template A's top (the title and
## hours badge, the purpose, the week bar, the totals tiles and the organizations card) and Template B's timeline for
## "Rooms, in order" (an hour ruler and one block for each room), in the active UI style (LevelBriefingStyles).
##
## It reads nothing from the rules or the run: every number arrives in `view`, and every word is a Text row. The
## pieces are built separately so the panel can keep the back row and the bottom bar fixed and scroll the rest.
## Node names are stable (TotalsCard, OrgsCard, Timeline, TimelineBlock_1 ...) so tests can find them.

## The middle column's width: the 1080 base width less 40 px margins, as an Overlay's.
const COLUMN_WIDTH := 1000.0
## A timeline block's height follows its hours (mockup pixels per hour), between a floor and a ceiling.
const BLOCK_PER_HOUR := 49.0
const BLOCK_MIN := 64.0
const BLOCK_MAX := 150.0
## The ruler column's width, and the rail's, in mockup pixels.
const RULER_WIDTH := 40.0
const RAIL_WIDTH := 3.0
const TILE_COLUMNS := 3
const ORG_ICON := 26.0


# --- the fixed pieces ---------------------------------------------------------------------

## The back row: "Levels" (a left chevron and the word) and, once the two-offices plan has a Location, its badge.
static func top_bar(view: Dictionary, look: Dictionary, on_back: Callable) -> Control:
	var row := HBoxContainer.new()
	row.name = "TopBar"
	row.add_theme_constant_override("separation", int(LevelBriefingStyles.len_px(8.0)))
	var back := Button.new()
	back.name = "BackLink"
	back.flat = true
	back.text = Text.say("briefing.back_levels")
	back.alignment = HORIZONTAL_ALIGNMENT_LEFT
	back.custom_minimum_size = Vector2(LevelBriefingStyles.len_px(96.0), LevelBriefingStyles.len_px(46.0))
	back.focus_mode = Control.FOCUS_NONE
	LevelBriefingStyles.dress_button(back, look, false)
	back.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	back.add_theme_color_override("font_color", look["on_ground"])
	back.pressed.connect(on_back)
	# A left-pointing chevron: the shared chevron points right, so it is flipped inside a plain holder (a container
	# resets a child's scale and rotation).
	var chevron := StyleMarks.make(StyleMarks.Kind.CHEVRON, look["on_ground"], Vector2(LevelBriefingStyles.len_px(22.0), LevelBriefingStyles.len_px(40.0)))
	chevron.size = chevron.custom_minimum_size
	chevron.scale = Vector2(-1, 1)
	chevron.position = Vector2(chevron.custom_minimum_size.x, 0)
	var chevron_holder := Control.new()
	chevron_holder.custom_minimum_size = chevron.custom_minimum_size
	chevron_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chevron_holder.add_child(chevron)
	row.add_child(chevron_holder)
	row.add_child(back)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var where := str(view.get("location", ""))
	if not where.is_empty():
		row.add_child(_plate_label(where, look, LevelBriefingStyles.SIZE_SMALL))
	return row


## The bottom bar: Back and the primary button, which is Go in with the level's hours, or greyed out saying why the
## level cannot start (Information Standard 2). The buttons are named Back and Confirm, as the Overlay's were.
static func bottom_bar(view: Dictionary, look: Dictionary, on_back: Callable, on_go: Callable) -> Control:
	var bar := PanelContainer.new()
	bar.name = "BottomBar"
	var box := StyleBoxFlat.new()
	box.bg_color = look["ground"]
	box.content_margin_left = 40.0
	box.content_margin_right = 40.0
	box.content_margin_top = LevelBriefingStyles.len_px(10.0)
	box.content_margin_bottom = LevelBriefingStyles.len_px(14.0)
	box.border_width_top = int(LevelBriefingStyles.len_px(2.0 if look["wood"] or look["broadcast"] else 1.0))
	box.border_color = look["on_ground"] if look["wood"] else (look["accent"] if look["broadcast"] else Color(1, 1, 1, 0.15))
	bar.add_theme_stylebox_override("panel", box)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(LevelBriefingStyles.len_px(10.0)))
	bar.add_child(row)

	var back := Button.new()
	back.name = "Back"
	back.text = Text.say("ui.back")
	back.custom_minimum_size = Vector2(LevelBriefingStyles.len_px(86.0), LevelBriefingStyles.len_px(48.0))
	back.focus_mode = Control.FOCUS_NONE
	LevelBriefingStyles.dress_button(back, look, false)
	back.pressed.connect(Haptics.confirm)
	back.pressed.connect(on_back)
	row.add_child(back)

	var refusal := str(view.get("refusal", ""))
	var can_go := refusal.is_empty()
	var go := Button.new()
	go.name = "Confirm"
	var hours := int(view.get("hours", 0))
	go.text = Text.say("briefing.go_in_hours", {"count": hours}) if can_go else refusal
	go.disabled = not can_go
	go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go.custom_minimum_size = Vector2(0, LevelBriefingStyles.len_px(48.0))
	go.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	go.focus_mode = Control.FOCUS_NONE
	LevelBriefingStyles.dress_button(go, look, true, can_go)
	go.pressed.connect(Haptics.confirm)
	go.pressed.connect(on_go)
	row.add_child(go)
	return bar


# --- the scrolling middle ----------------------------------------------------------------

## Everything between the back row and the bottom bar: the title, purpose, week, totals, organizations and timeline.
static func middle(view: Dictionary, look: Dictionary, on_mode: Callable = Callable()) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.name = "Middle"
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", int(LevelBriefingStyles.len_px(8.0)))
	column.add_child(_title_row(view, look))
	var purpose := _purpose(view, look)
	if purpose != null:
		column.add_child(purpose)
	column.add_child(_week(view, look))
	var modes := _travel_row(view, look, on_mode)
	if modes != null:
		column.add_child(modes)
	column.add_child(_totals_card(view, look))
	var orgs := _orgs_card(view, look)
	if orgs != null:
		column.add_child(orgs)
	if bool(view.get("lists_rooms", false)):
		column.add_child(_timeline(view, look))
	return column


static func _title_row(view: Dictionary, look: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.name = "TitleRow"
	row.add_theme_constant_override("separation", int(LevelBriefingStyles.len_px(12.0)))
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", int(LevelBriefingStyles.len_px(4.0)))
	row.add_child(text)
	var title_text := str(view.get("title", ""))
	if title_text.is_empty():
		title_text = Text.say("office.briefing_fallback_title")
	var size := LevelBriefingStyles.SIZE_TITLE
	if look["broadcast"]:
		size = LevelBriefingStyles.SIZE_TITLE_BROADCAST
	elif look["living"]:
		size = LevelBriefingStyles.SIZE_TITLE_LIVING
	var title := _label(LevelBriefingStyles.title_text(look, title_text), size, look["on_ground"], true)
	title.name = "Title"
	if look["broadcast"]:
		# Barlow Condensed's line is tall for a title that wraps.
		title.add_theme_constant_override("line_spacing", -int(LevelBriefingStyles.len_px(5.0)))
	text.add_child(title)
	var rooms := int(view.get("room_count", 0))
	var meta := _label(Text.say("briefing.meta", {"tier": int(view.get("tier", 0)), "count": rooms}),
		LevelBriefingStyles.SIZE_SMALL + 1.0, look["on_ground_muted"], false)
	meta.name = "Meta"
	text.add_child(meta)
	# A mixed level says its trips are in the hours (Information Standard 1; two offices, 2026-11-20).
	var travel_hours := int(view.get("travel_hours", 0))
	if travel_hours > 0:
		var travel := _label(Text.say("briefing.travel_included", {"count": travel_hours,
			"mode": TravelText.mode_name(str(view.get("travel_mode", ""))).to_lower()}),
			LevelBriefingStyles.SIZE_SMALL + 1.0, look["on_ground_muted"], false)
		travel.name = "TravelIncluded"
		text.add_child(travel)
	var badge := LevelBriefingStyles.hours_badge(look, int(view.get("hours", 0)))
	badge.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(badge)
	return row


## "Travel by": one button for each way to pay for a mixed level's trips (the rail pass, a paid ticket, this
## protagonist's fast mode), with the hours each takes; the chosen one is filled. Only when there is a choice.
static func _travel_row(view: Dictionary, look: Dictionary, on_mode: Callable) -> Control:
	var options: Array = view.get("travel_options", [])
	if options.size() < 2 or int(view.get("travel_trips", 0)) == 0:
		return null
	var box := VBoxContainer.new()
	box.name = "TravelModes"
	box.add_theme_constant_override("separation", int(LevelBriefingStyles.len_px(5.0)))
	box.add_child(_label(Text.say("briefing.travel_by"), LevelBriefingStyles.SIZE_SMALL + 1.0, look["on_ground_muted"], false))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(LevelBriefingStyles.len_px(6.0)))
	box.add_child(row)
	for option: Dictionary in options:
		var mode := str(option["mode"])
		var chosen := mode == str(view.get("travel_mode", ""))
		var button := Button.new()
		button.name = "TravelMode_" + mode
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, LevelBriefingStyles.len_px(46.0))
		button.text = Text.say("travel.mode_button", {"mode": TravelText.mode_name(mode), "count": int(option["hours"])})
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = not bool(option.get("enough", true))
		button.focus_mode = Control.FOCUS_NONE
		LevelBriefingStyles.dress_button(button, look, chosen, not button.disabled)
		TravelText.dress_mode_icon(button, mode, LevelBriefingStyles.len_px(34.0))
		if on_mode.is_valid():
			button.pressed.connect(on_mode.bind(mode))
		row.add_child(button)
	return box


static func _purpose(view: Dictionary, look: Dictionary) -> Control:
	var purpose: Dictionary = view.get("purpose", {})
	if purpose.is_empty():
		return null
	var speaker := str(purpose.get("speaker", ""))
	var line := str(purpose.get("text", ""))
	var words := Text.say("briefing.purpose", {"speaker": speaker, "line": line}) if not speaker.is_empty() \
		else Text.say("briefing.purpose_plain", {"line": line})
	var label := _label(words, LevelBriefingStyles.SIZE_SMALL + 1.0, look["on_ground_muted"], false)
	label.name = "Purpose"
	return label


## "This week: 28 hours left", "22 left after this level" and a bar of the whole week: what is used, this level, what is left.
static func _week(view: Dictionary, look: Dictionary) -> Control:
	var week: Dictionary = view.get("week", {})
	var box := VBoxContainer.new()
	box.name = "Week"
	box.add_theme_constant_override("separation", int(LevelBriefingStyles.len_px(5.0)))
	var left := int(week.get("left", 0))
	var weekend := str(week.get("phase", "work")) == "weekend"
	var key := ("briefing.weekend_left" if weekend else "briefing.week_left") + (".one" if left == 1 else "")
	var line := HBoxContainer.new()
	var now := _label(Text.say(key, {"count": left}), LevelBriefingStyles.SIZE_SMALL, look["on_ground_muted"], false)
	now.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(now)
	var after := _label(Text.say("briefing.week_after", {"count": int(week.get("after", 0))}), LevelBriefingStyles.SIZE_SMALL,
		look["on_ground"], false, false)
	after.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	after.name = "WeekAfter"
	line.add_child(after)
	box.add_child(line)

	var frame := PanelContainer.new()
	frame.name = "WeekBar"
	var edge := StyleBoxFlat.new()
	edge.bg_color = Color(0, 0, 0, 0)
	edge.set_border_width_all(int(LevelBriefingStyles.len_px(2.0 if look["wood"] else 1.0)))
	edge.border_color = look["on_ground"] if look["wood"] else (look["on_ground_muted"] if look["living"] else look["accent"])
	if look["living"]:
		edge.set_corner_radius_all(int(LevelBriefingStyles.len_px(6.0)))
	frame.add_theme_stylebox_override("panel", edge)
	frame.custom_minimum_size = Vector2(0, LevelBriefingStyles.len_px(11.0))
	var segments := HBoxContainer.new()
	segments.add_theme_constant_override("separation", 0)
	frame.add_child(segments)
	var used_colour: Color = look["on_ground_muted"]
	used_colour.a = 0.45
	for part: Array in [[int(week.get("used", 0)), used_colour], [int(week.get("this_level", 0)), look["hot"]],
			[int(week.get("after", 0)), Color(0, 0, 0, 0)]]:
		if int(part[0]) <= 0:
			continue
		var piece := ColorRect.new()
		piece.color = part[1]
		piece.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		piece.size_flags_stretch_ratio = float(part[0])
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		segments.add_child(piece)
	box.add_child(frame)
	return box


# --- the totals card ------------------------------------------------------------------------

## "If you win every room": one tile for each of the meters the rooms or the bonus pay, a big total with the bonus in small
## type, and the note about when rooms and the bonus pay. A level with no rewards set says so instead.
static func _totals_card(view: Dictionary, look: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.name = "TotalsCard"
	card.add_theme_stylebox_override("panel", LevelBriefingStyles.card_box(look))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", int(LevelBriefingStyles.len_px(6.0)))
	card.add_child(column)
	column.add_child(_label(LevelBriefingStyles.title_text(look, Text.say("briefing.win_every_room")), LevelBriefingStyles.SIZE_HEADING, look["ink"], true))
	if not bool(view.get("anything_set", false)):
		column.add_child(_label(Text.say("reward.nothing_set"), LevelBriefingStyles.SIZE_SMALL, look["muted"], false))
		return card

	var totals: Dictionary = view.get("totals", {})
	var bonus: Dictionary = (view.get("bonus", {}) as Dictionary).get("meta", {})
	var names := {}
	for name: String in totals.keys():
		names[name] = true
	for name: String in bonus.keys():
		names[name] = true
	var grid := GridContainer.new()
	grid.name = "Tiles"
	grid.columns = TILE_COLUMNS
	grid.add_theme_constant_override("h_separation", int(LevelBriefingStyles.len_px(6.0)))
	grid.add_theme_constant_override("v_separation", int(LevelBriefingStyles.len_px(6.0)))
	for name: String in BriefingSummary.ordered(names):
		grid.add_child(_tile(name, int(totals.get(name, 0)), bonus.get(name, {}), look))
	grid.add_child(_note_cell(look, not LevelBonus.is_empty(view.get("bonus", {}))))
	column.add_child(grid)
	return card


static func _tile(name: String, total: int, bonus: Dictionary, look: Dictionary) -> Control:
	var tile := PanelContainer.new()
	tile.name = "Tile_" + name.replace(" ", "_")
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.custom_minimum_size = Vector2(0, LevelBriefingStyles.len_px(54.0))
	tile.add_theme_stylebox_override("panel", LevelBriefingStyles.tile_box(look))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	tile.add_child(column)
	var is_xp := name == BriefingSummary.XP
	var amount := Phrase.meta_amount(name, total, true)
	column.add_child(_label(amount, LevelBriefingStyles.SIZE_BIG, look["ink"], false))
	column.add_child(_label(Text.say("briefing.tile_xp") if is_xp else name, LevelBriefingStyles.SIZE_SMALL, look["ink"], false))
	var small := bonus_text(name, bonus)
	if not small.is_empty():
		column.add_child(_label(small, LevelBriefingStyles.SIZE_SMALL - 0.5, look["muted"], false))
	return tile


## "+1 to +2 bonus", "+3 bonus", or "" when the meter has no level bonus.
static func bonus_text(name: String, bounds: Dictionary) -> String:
	if bounds.is_empty():
		return ""
	var low := int(bounds["min"])
	var high := int(bounds["max"])
	if low == high:
		return Text.say("briefing.bonus_fixed", {"amount": Phrase.meta_amount(name, high, true)})
	return Text.say("briefing.bonus_range", {"low": Phrase.meta_amount(name, low, true), "high": Phrase.meta_amount(name, high, true)})


## The note says when the rooms pay, and when the bonus does only if the level has one.
static func _note_cell(look: Dictionary, has_bonus: bool) -> Control:
	# A panel gives every child the whole cell, so the dashed frame fills it and the words sit in a margin of their own.
	var cell := PanelContainer.new()
	cell.name = "HowItPays"
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	cell.add_child(StyleMarks.make(StyleMarks.Kind.DASHED_FRAME, look["muted"], Vector2.ZERO))
	var inset := MarginContainer.new()
	inset.add_theme_constant_override("margin_left", int(LevelBriefingStyles.len_px(9.0)))
	inset.add_theme_constant_override("margin_right", int(LevelBriefingStyles.len_px(9.0)))
	inset.add_theme_constant_override("margin_top", int(LevelBriefingStyles.len_px(7.0)))
	inset.add_theme_constant_override("margin_bottom", int(LevelBriefingStyles.len_px(7.0)))
	var words := Text.say("briefing.how_it_pays") if has_bonus else Text.say("briefing.how_it_pays_rooms")
	inset.add_child(_label(words, LevelBriefingStyles.SIZE_SMALL - 0.5, look["muted"], false))
	cell.add_child(inset)
	return cell


# --- the organizations card -----------------------------------------------------------------

## "Organizations, if you win": each organization's icon (an OrgChip, so a tap names it), its name and its range.
static func _orgs_card(view: Dictionary, look: Dictionary) -> Control:
	var orgs: Array = (view.get("bonus", {}) as Dictionary).get("orgs", [])
	if orgs.is_empty():
		return null
	var card := PanelContainer.new()
	card.name = "OrgsCard"
	card.add_theme_stylebox_override("panel", LevelBriefingStyles.card_box(look))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", int(LevelBriefingStyles.len_px(4.0)))
	card.add_child(column)
	column.add_child(_label(LevelBriefingStyles.title_text(look, Text.say("briefing.orgs_if_win")), LevelBriefingStyles.SIZE_HEADING, look["ink"], true))
	for org: Dictionary in orgs:
		column.add_child(_org_row(org, look))
	return card


static func _org_row(org: Dictionary, look: Dictionary) -> Control:
	var id := str(org["id"])
	var row := HBoxContainer.new()
	row.name = "OrgRow_" + id
	row.add_theme_constant_override("separation", int(LevelBriefingStyles.len_px(10.0)))
	row.custom_minimum_size = Vector2(0, LevelBriefingStyles.len_px(30.0))
	var icon := OrgChip.make(id, int(org["max"]), false, LevelBriefingStyles.len_px(ORG_ICON), false)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var name := _label(OrgChip.name_of(id), LevelBriefingStyles.SIZE_BODY - 0.5, look["ink"], false)
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(name)
	var range := _label(org_range(int(org["min"]), int(org["max"])), LevelBriefingStyles.SIZE_BODY - 0.5, look["ink"], false, false)
	range.name = "Range"
	range.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	range.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(range)
	return row


## "+2 to +4", "0 to +1" or, for one amount, "+3".
static func org_range(low: int, high: int) -> String:
	var shown_high := Phrase.meta_amount("org", high, true)
	if low == high:
		return shown_high
	return Text.say("briefing.range", {"low": Phrase.meta_amount("org", low, true), "high": shown_high})


# --- the timeline ---------------------------------------------------------------------------

## "Rooms, in order": an hour ruler down the left and one block for each room, as tall as its hours, with its rewards as
## chips and, where a loss costs but the level carries on, a small line saying so. Ends with a slim marker for the bonus.
static func _timeline(view: Dictionary, look: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.name = "Timeline"
	box.add_theme_constant_override("separation", 0)
	var heading := _label(LevelBriefingStyles.title_text(look, Text.say("briefing.rooms_in_order")), LevelBriefingStyles.SIZE_HEADING, look["on_ground"], true)
	heading.add_theme_constant_override("line_spacing", 0)
	box.add_child(heading)
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(0, LevelBriefingStyles.len_px(6.0))
	box.add_child(pad)
	var rooms: Array = view.get("rooms", [])
	var end_hour := 0
	for room: Dictionary in rooms:
		box.add_child(_room_row(room, look))
		end_hour = int(room["start"]) + int(room["hours"])
	var end_row := HBoxContainer.new()
	end_row.name = "TimelineEnd"
	end_row.add_theme_constant_override("separation", int(LevelBriefingStyles.len_px(8.0)))
	end_row.add_child(_ruler_cell(end_hour, look, false))
	var bonus := (view.get("bonus", {}) as Dictionary)
	if not LevelBonus.is_empty(bonus):
		end_row.add_child(_finish_marker(look))
	box.add_child(end_row)
	return box


static func _ruler_cell(hour: int, look: Dictionary, with_rail: bool) -> Control:
	var cell := VBoxContainer.new()
	cell.custom_minimum_size = Vector2(LevelBriefingStyles.len_px(RULER_WIDTH), 0)
	cell.add_theme_constant_override("separation", 0)
	var mark := _label(Text.say("briefing.hour_mark", {"count": hour}), LevelBriefingStyles.SIZE_SMALL, look["on_ground_muted"], false)
	mark.name = "HourMark"
	mark.autowrap_mode = TextServer.AUTOWRAP_OFF
	cell.add_child(mark)
	if with_rail:
		var rail_row := HBoxContainer.new()
		rail_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var rail := ColorRect.new()
		rail.name = "Rail"
		rail.color = look["hot"]
		rail.custom_minimum_size = Vector2(LevelBriefingStyles.len_px(RAIL_WIDTH), 0)
		rail.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(LevelBriefingStyles.len_px(12.0), 0)
		rail_row.add_child(gap)
		rail_row.add_child(rail)
		cell.add_child(rail_row)
	return cell


static func _room_row(room: Dictionary, look: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.name = "TimelineRow_%d" % int(room["n"])
	row.add_theme_constant_override("separation", int(LevelBriefingStyles.len_px(8.0)))
	row.add_child(_ruler_cell(int(room["start"]), look, true))
	var holder := MarginContainer.new()
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	holder.add_theme_constant_override("margin_bottom", int(LevelBriefingStyles.len_px(8.0)))
	holder.add_child(_block(room, look))
	row.add_child(holder)
	return row


static func _block(room: Dictionary, look: Dictionary) -> Control:
	var block := PanelContainer.new()
	block.name = "TimelineBlock_%d" % int(room["n"])
	block.add_theme_stylebox_override("panel", LevelBriefingStyles.card_box(look))
	var hours := int(room["hours"])
	block.custom_minimum_size = Vector2(0, LevelBriefingStyles.len_px(clampf(hours * BLOCK_PER_HOUR, BLOCK_MIN, BLOCK_MAX)))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", int(LevelBriefingStyles.len_px(5.0)))
	block.add_child(column)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", int(LevelBriefingStyles.len_px(8.0)))
	head.add_child(_number_square(int(room["n"]), look))
	var name := _label(str(room["name"]), LevelBriefingStyles.SIZE_BODY + 1.5, look["ink"], true)
	name.name = "RoomName"
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(name)
	var line := _label(Text.say("briefing.room_line", {"kind": kind_text(str(room["kind"])),
		"hours": Text.say("briefing.hour_mark", {"count": hours})}), LevelBriefingStyles.SIZE_SMALL, look["muted"], false, false)
	line.name = "RoomLine"
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(line)
	column.add_child(head)

	if bool(room["rewards_unset"]):
		column.add_child(_label(Text.say("reward.stage_not_set"), LevelBriefingStyles.SIZE_SMALL, look["muted"], false))
	else:
		var chips := HFlowContainer.new()
		chips.name = "Chips"
		chips.add_theme_constant_override("h_separation", int(LevelBriefingStyles.len_px(5.0)))
		chips.add_theme_constant_override("v_separation", int(LevelBriefingStyles.len_px(5.0)))
		var rewards: Dictionary = room["rewards"]
		for reward_name: String in BriefingSummary.ordered(rewards):
			chips.add_child(_chip(reward_line(reward_name, int(rewards[reward_name])), look))
		column.add_child(chips)
	if bool(room["loss_continues"]):
		var carries := _label(Text.say("briefing.loss_continues"), LevelBriefingStyles.SIZE_SMALL - 0.5, look["muted"], false)
		carries.name = "LossContinues"
		column.add_child(carries)
	return block


## The label for a kind of room (LevelBriefing's KIND_ names), by literal Text keys.
static func kind_text(kind: String) -> String:
	match kind:
		LevelBriefing.KIND_CONVERSATION:
			return Text.say("briefing.kind_conversation")
		LevelBriefing.KIND_VOTE:
			return Text.say("briefing.kind_vote")
		LevelBriefing.KIND_VISIT:
			return Text.say("briefing.kind_visit")
		LevelBriefing.KIND_TRADE:
			return Text.say("briefing.kind_trade")
	return Text.say("briefing.kind_debate")


## "Constituency support +5", "XP Growth +50", "Funds +10,000円": one reward as a chip's words.
static func reward_line(name: String, amount: int) -> String:
	var shown := Phrase.meta_amount(name, amount, true)
	if name == BriefingSummary.XP:
		return Text.say("briefing.xp_growth", {"amount": shown})
	return Text.say("reward.delta", {"name": name, "amount": shown})


static func _chip(words: String, look: Dictionary) -> Control:
	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", LevelBriefingStyles.chip_box(look))
	chip.add_child(_label(words, LevelBriefingStyles.SIZE_SMALL, look["ink"], false, false))
	return chip


static func _number_square(n: int, look: Dictionary) -> Control:
	var square := PanelContainer.new()
	square.name = "Number"
	square.custom_minimum_size = Vector2(LevelBriefingStyles.len_px(24.0), LevelBriefingStyles.len_px(24.0))
	square.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	square.add_theme_stylebox_override("panel", LevelBriefingStyles.number_box(look))
	var label := _label(str(n), LevelBriefingStyles.SIZE_SMALL + 0.5, look["on_accent"], false, false)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	square.add_child(label)
	return square


static func _finish_marker(look: Dictionary) -> Control:
	var marker := PanelContainer.new()
	marker.name = "FinishMarker"
	marker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := StyleBoxFlat.new()
	box.bg_color = look["accent"]
	box.set_content_margin_all(LevelBriefingStyles.len_px(8.0))
	if look["living"]:
		box.set_corner_radius_all(int(LevelBriefingStyles.len_px(12.0)))
	marker.add_theme_stylebox_override("panel", box)
	# It wraps, so at Large text it takes two lines instead of pushing the whole screen wider than the phone.
	marker.add_child(_label(Text.say("briefing.finish_bonus"), LevelBriefingStyles.SIZE_BODY - 0.5, look["on_accent"], false))
	return marker


# --- small helpers --------------------------------------------------------------------------

## A wrapped label in the style's colours and a size from the mockups; `display` uses the style's display font.
static func _label(text: String, mockup_px: float, colour: Color, display: bool, wrap: bool = true) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", LevelBriefingStyles.px(mockup_px))
	label.add_theme_color_override("font_color", colour)
	if display:
		label.theme_type_variation = "HeaderLabel"
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# A style's theme draws a paper plate behind every Label; the briefing sits its words on its own cards.
	label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


## A small accent plate with a word on it (the Location badge).
static func _plate_label(text: String, look: Dictionary, mockup_px: float) -> Control:
	var plate := PanelContainer.new()
	plate.name = "LocationBadge"
	var box := StyleBoxFlat.new()
	box.bg_color = look["accent"]
	box.content_margin_left = LevelBriefingStyles.len_px(12.0)
	box.content_margin_right = LevelBriefingStyles.len_px(12.0)
	box.content_margin_top = LevelBriefingStyles.len_px(6.0)
	box.content_margin_bottom = LevelBriefingStyles.len_px(6.0)
	if look["living"]:
		box.set_corner_radius_all(int(LevelBriefingStyles.len_px(20.0)))
	plate.add_theme_stylebox_override("panel", box)
	plate.add_child(_label(text, mockup_px, look["on_accent"], false, false))
	return plate
