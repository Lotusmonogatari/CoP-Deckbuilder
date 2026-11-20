class_name ReputationView
extends RefCounted
## Draws the Overview tab of Reputation and Results (P13, 2026-11-20) from ReputationModel's data: the four meta numbers
## as tiles, the three biggest moves, the parties, the latest law, and the levels cleared. Every non-zero change is a
## button that shows only the signed number; the reasons ("because of ...") never show here, only in the pop-up the
## button opens. Draws only: it reads no game state.
##
## `handlers` carries the taps: "meta_factors" (Callable taking the meta name), "standing_factors" (taking the
## organization), "open_law" (taking the law), "tab" (taking a tab id).


## The Overview's cards, top to bottom.
static func overview_cards(model: Dictionary, handlers: Dictionary) -> Array[Control]:
	var look := OfficeFrameStyles.look()
	var out: Array[Control] = []
	out.append(_stand_card(look, model, handlers))
	if not (model["moves"] as Array).is_empty():
		out.append(_moves_card(look, model, handlers))
	out.append(_parties_card(look, model, handlers))
	out.append(_law_card(look, model, handlers))
	out.append(_tiers_card(look, model))
	out.append(_levels_card(look, model))
	return out


## "Where you stand": a 2 x 2 grid of tiles (name, number, what moved it), then XP and the Political Pressure line.
static func _stand_card(look: Dictionary, model: Dictionary, handlers: Dictionary) -> Control:
	var card := OfficeFrameStyles.card(look, Text.say("office.record_sanban_heading"))
	card.name = "OverviewStand"
	var column := card.get_node("Column") as VBoxContainer
	var grid := GridContainer.new()
	grid.name = "OverviewTiles"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", int(OfficeFrameStyles.len_px(8.0)))
	grid.add_theme_constant_override("v_separation", int(OfficeFrameStyles.len_px(8.0)))
	column.add_child(grid)
	for tile: Dictionary in model["tiles"]:
		grid.add_child(_tile(look, tile, handlers))
	var footer := HBoxContainer.new()
	footer.name = "OverviewFooter"
	var xp := Label.new()
	xp.text = str(model["footer"]["xp"])
	xp.theme_type_variation = "SmallLabel"
	xp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(xp)
	var pressure := Label.new()
	pressure.text = str(model["footer"]["pressure"])
	pressure.theme_type_variation = "SmallLabel"
	pressure.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pressure.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(pressure)
	column.add_child(footer)
	return card


static func _tile(look: Dictionary, tile: Dictionary, handlers: Dictionary) -> Control:
	var box := PanelContainer.new()
	box.name = "Tile_" + str(tile["name"]).replace(" ", "_")
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_stylebox_override("panel", LevelBriefingStyles.tile_box(look, 9.0))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	box.add_child(column)
	var name := Label.new()
	name.text = str(tile["name"])
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.add_theme_font_size_override("font_size", OfficeFrameStyles.px(LevelBriefingStyles.SIZE_SMALL + 0.5))
	column.add_child(name)
	var value := Label.new()
	value.text = str(tile["value"])
	value.theme_type_variation = "HeaderLabel"
	value.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value.add_theme_font_size_override("font_size", OfficeFrameStyles.px(LevelBriefingStyles.SIZE_BIG))
	column.add_child(value)
	if int(tile["change"]) != 0:
		var button := OfficeFrameStyles.signed_button(look, str(tile["node"]), str(tile["change_text"]), int(tile["change"]))
		button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		button.pressed.connect(Haptics.confirm)
		button.pressed.connect((handlers["meta_factors"] as Callable).bind(str(tile["name"])))
		column.add_child(button)
	return box


## "Biggest moves last level": the three organizations that moved most, each with icon, name, bar, standing and a
## change button; a hint under them says what the buttons do.
static func _moves_card(look: Dictionary, model: Dictionary, handlers: Dictionary) -> Control:
	var card := OfficeFrameStyles.card(look, Text.say("record.biggest_moves"))
	card.name = "OverviewMoves"
	var column := card.get_node("Column") as VBoxContainer
	for move: Dictionary in model["moves"]:
		column.add_child(_move_row(look, move, handlers))
	var hint := UiKit.line(Text.say("record.tap_change_hint"), "SmallLabel")
	hint.custom_minimum_size.x = 0.0
	column.add_child(hint)
	column.add_child(_link(look, "LinkStakeholders", Text.say("record.all_stakeholders", {"count": DataDB.boosters.size()}),
		(handlers["tab"] as Callable).bind("stakeholders")))
	return card


static func _move_row(look: Dictionary, move: Dictionary, handlers: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.name = "Move_" + str(move["id"])
	row.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(8.0)))
	var icon := TextureRect.new()
	icon.texture = ArtLoader.icon(str(move["id"]))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(84, 84)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var middle := VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 2)
	var name := Label.new()
	name.text = str(move["name"])
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	middle.add_child(name)
	middle.add_child(bar(look, float(move["standing"])))
	var standing := Label.new()
	standing.text = str(move["standing"])
	standing.theme_type_variation = "SmallLabel"
	middle.add_child(standing)
	row.add_child(middle)
	var holder := MarginContainer.new()
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var button := OfficeFrameStyles.signed_button(look, str(move["node"]), str(move["change_text"]), int(move["change"]))
	button.pressed.connect(Haptics.confirm)
	button.pressed.connect((handlers["standing_factors"] as Callable).bind(move["booster"]))
	holder.add_child(button)
	row.add_child(holder)
	return row


## A 0 to 100 bar in the style's accent over a faint track.
static func bar(look: Dictionary, value: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, OfficeFrameStyles.len_px(6.0))
	var fill := StyleBoxFlat.new()
	fill.bg_color = look["hot"] if look["wood"] else look["accent"]
	var track := StyleBoxFlat.new()
	track.bg_color = look["tile"]
	if look["living"]:
		fill.set_corner_radius_all(8)
		track.set_corner_radius_all(8)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", track)
	return bar


## The parties' opinion of the player: a colour swatch, the name, the score, two to a row.
static func _parties_card(look: Dictionary, model: Dictionary, handlers: Dictionary) -> Control:
	var card := OfficeFrameStyles.card(look, Text.say("office.parties"))
	card.name = "OverviewParties"
	var column := card.get_node("Column") as VBoxContainer
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", int(OfficeFrameStyles.len_px(10.0)))
	grid.add_theme_constant_override("v_separation", int(OfficeFrameStyles.len_px(4.0)))
	column.add_child(grid)
	for party: Dictionary in model["parties"]:
		grid.add_child(_party_cell(party))
	column.add_child(_link(look, "LinkParties", Text.say("record.all_parties"), (handlers["tab"] as Callable).bind("parties")))
	return card


static func _party_cell(party: Dictionary) -> Control:
	var cell := HBoxContainer.new()
	cell.name = "Party_" + str(party["id"])
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(6.0)))
	var swatch := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = party["colour"]
	box.set_corner_radius_all(20)
	swatch.add_theme_stylebox_override("panel", box)
	swatch.custom_minimum_size = Vector2(OfficeFrameStyles.len_px(11.0), OfficeFrameStyles.len_px(11.0))
	swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cell.add_child(swatch)
	var name := Label.new()
	name.text = str(party["name"])
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name.add_theme_font_size_override("font_size", OfficeFrameStyles.px(LevelBriefingStyles.SIZE_SMALL + 1.0))
	cell.add_child(name)
	var score_holder := MarginContainer.new()
	var score := Label.new()
	score.text = str(party["score"])
	score.autowrap_mode = TextServer.AUTOWRAP_OFF
	score.set_meta(UiKit.ONE_LINE_META, true)
	score_holder.add_child(score)
	cell.add_child(score_holder)
	return cell


## Legislative Work: the latest law (PASSED or FAILED, its tally and how you voted), which opens its pop-up, and a link
## to every law.
static func _law_card(look: Dictionary, model: Dictionary, handlers: Dictionary) -> Control:
	var card := OfficeFrameStyles.card(look, Text.say("office.record_statute_heading"))
	card.name = "OverviewLaw"
	var column := card.get_node("Column") as VBoxContainer
	var law: Dictionary = model["law"]
	if law.is_empty():
		var empty := UiKit.line(Text.say("office.record_statute_empty"))
		empty.custom_minimum_size.x = 0.0
		column.add_child(empty)
		return card
	var button := Button.new()
	button.name = str(law["node"])
	button.custom_minimum_size.y = OfficeFrameStyles.touch_height()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var quiet := StyleBoxEmpty.new()
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(look["tile"].r, look["tile"].g, look["tile"].b, 0.6)
	for state: String in ["normal", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, quiet)
	for state: String in ["hover", "pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(state, pressed)
	button.pressed.connect(Haptics.confirm)
	button.pressed.connect((handlers["open_law"] as Callable).bind(law["law"]))
	var inside := VBoxContainer.new()
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inside.add_theme_constant_override("separation", 2)
	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name := Label.new()
	name.text = str(law["name"])
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name)
	var marker := Label.new()
	marker.text = Text.say("record.law_marker_passed" if bool(law["passed"]) else "record.law_marker_failed")
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	marker.set_meta(UiKit.ONE_LINE_META, true)
	marker.add_theme_color_override("font_color", look["up"] if bool(law["passed"]) else look["down"])
	var holder := MarginContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(marker)
	top.add_child(holder)
	inside.add_child(top)
	for text: String in [str(law["tally"]), str(law["vote"])]:
		if not text.is_empty():
			var line := Label.new()
			line.text = text
			line.theme_type_variation = "SmallLabel"
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			inside.add_child(line)
	button.add_child(inside)
	# The button is as tall as its lines (a Button does not size itself to children).
	button.custom_minimum_size.y = maxf(OfficeFrameStyles.touch_height(), OfficeFrameStyles.len_px(76.0))
	column.add_child(button)
	column.add_child(_link(look, "LinkLaws", Text.say("record.all_laws"), (handlers["tab"] as Callable).bind("laws")))
	return card


## Tiers cleared: how many clears in each tier of level.
static func _tiers_card(look: Dictionary, model: Dictionary) -> Control:
	var card := OfficeFrameStyles.card(look, Text.say("office.record_tiers_heading"))
	card.name = "OverviewTiers"
	var column := card.get_node("Column") as VBoxContainer
	for text: String in model["tiers"]:
		var line := UiKit.line(text)
		line.custom_minimum_size.x = 0.0
		column.add_child(line)
	return card


## Levels cleared: each level cleared and how many times (the empty line when none).
static func _levels_card(look: Dictionary, model: Dictionary) -> Control:
	var card := OfficeFrameStyles.card(look, Text.say("office.record_levels_heading"))
	card.name = "OverviewLevels"
	var column := card.get_node("Column") as VBoxContainer
	for text: String in model["levels"]:
		var line := UiKit.line(text)
		line.custom_minimum_size.x = 0.0
		column.add_child(line)
	return card


## A small flat link in the card's ink ("All 32 ›"): at least a touch target tall.
static func _link(look: Dictionary, node: String, text: String, on_press: Callable) -> Button:
	var button := Button.new()
	button.name = node
	button.text = text
	button.flat = true
	button.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	button.autowrap_mode = TextServer.AUTOWRAP_OFF
	button.set_meta(UiKit.ONE_LINE_META, true)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, look["ink"])
	button.add_theme_font_size_override("font_size", OfficeFrameStyles.px(LevelBriefingStyles.SIZE_SMALL + 1.0))
	button.custom_minimum_size.y = OfficeFrameStyles.touch_height()
	button.size_flags_horizontal = Control.SIZE_SHRINK_END
	button.pressed.connect(Haptics.confirm)
	button.pressed.connect(on_press)
	return button


## The Resign box: its title, the button (the Office's own hold button) and how the hold works.
static func resign_card(look: Dictionary, button: Button, hint: String) -> Control:
	var card := OfficeFrameStyles.danger_card(look, Text.say("record.resign_title"))
	card.name = "ResignBox"
	var column := card.get_node("Column") as VBoxContainer
	column.add_child(button)
	var line := UiKit.line(hint, "SmallLabel")
	line.custom_minimum_size.x = 0.0
	column.add_child(line)
	return card
