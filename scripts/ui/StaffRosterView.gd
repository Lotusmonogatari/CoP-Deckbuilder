class_name StaffRosterView
extends RefCounted
## Draws the Staff tab of Office Management (P13, 2026-11-20) from StaffRosterModel's data: a summary card, then one section
## for each role with a card for every hired person (portrait, name and rank, a tag, Loyalty and wage) and one dashed
## "+ Hire a ..." row for every open place. Every hired person has a card, so the staff count equals the cards shown.
## Draws only: it reads no game state.
##
## `handlers`: "profile" (Callable taking a staff id) and "hire" (Callable taking a role).


static func cards(model: Dictionary, handlers: Dictionary) -> Array[Control]:
	var look := OfficeFrameStyles.look()
	var out: Array[Control] = []
	out.append(_summary_card(look, model))
	for role: Dictionary in model["roles"]:
		out.append(_role_section(look, role, handlers))
	return out


## Wages this week, staff hired of all places, places per role: three small tiles.
static func _summary_card(look: Dictionary, model: Dictionary) -> Control:
	var card := OfficeFrameStyles.card(look)
	card.name = "StaffSummary"
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", int(OfficeFrameStyles.len_px(8.0)))
	row.add_theme_constant_override("v_separation", int(OfficeFrameStyles.len_px(8.0)))
	card.get_node("Column").add_child(row)
	for tile: Array in [[Text.say("office.wages_week"), str(model["wages"]), "SummaryWages"],
			[Text.say("office.staff"), str(model["staff_count"]), "SummaryCount"],
			[Text.say("office.places_per_role"), str(model["places"]), "SummaryPlaces"]]:
		row.add_child(_tile(look, str(tile[0]), str(tile[1]), str(tile[2])))
	return card


static func _tile(look: Dictionary, label: String, value: String, node: String) -> Control:
	var box := PanelContainer.new()
	box.name = node
	box.add_theme_stylebox_override("panel", LevelBriefingStyles.tile_box(look, 8.0))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	box.add_child(column)
	var name := Label.new()
	name.text = label
	name.add_theme_font_size_override("font_size", OfficeFrameStyles.px(LevelBriefingStyles.SIZE_SMALL))
	name.set_meta(UiKit.ONE_LINE_META, true)
	column.add_child(name)
	var number := Label.new()
	number.name = "Value"
	number.text = value
	number.theme_type_variation = "HeaderLabel"
	number.add_theme_font_size_override("font_size", OfficeFrameStyles.px(LevelBriefingStyles.SIZE_BIG))
	number.set_meta(UiKit.ONE_LINE_META, true)
	column.add_child(number)
	return box


## One role: its heading with "{filled} of {places} places filled", a card for each person, a dashed row for each open place.
static func _role_section(look: Dictionary, role: Dictionary, handlers: Dictionary) -> Control:
	var section := VBoxContainer.new()
	section.name = "Role_" + str(role["role"]).replace(" ", "_")
	section.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(6.0)))
	var heading := Label.new()
	heading.text = LevelBriefingStyles.title_text(look, str(role["role"]))
	heading.theme_type_variation = "HeaderLabel"
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size", OfficeFrameStyles.px(LevelBriefingStyles.SIZE_HEADING + 1.0))
	heading.add_theme_color_override("font_color", look["on_ground"])
	section.add_child(heading)
	var places := Label.new()
	places.text = str(role["filled_text"])
	places.theme_type_variation = "SmallLabel"
	places.add_theme_color_override("font_color", look["on_ground_muted"])
	section.add_child(places)
	for person: Dictionary in role["people"]:
		section.add_child(_person_card(look, person, handlers))
	for i in int(role["open"]):
		section.add_child(_hire_row(look, str(role["role"]), i, handlers))
	return section


## A hired person: one card, tappable (it opens their profile).
static func _person_card(look: Dictionary, person: Dictionary, handlers: Dictionary) -> Control:
	var card := OfficeFrameStyles.card(look)
	card.name = "StaffCard_" + str(person["staff_id"])
	var button := Button.new()
	button.name = str(person["node"])
	button.custom_minimum_size.y = OfficeFrameStyles.len_px(66.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var quiet := StyleBoxEmpty.new()
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(look["tile"].r, look["tile"].g, look["tile"].b, 0.6)
	for state: String in ["normal", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, quiet)
	for state: String in ["hover", "pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(state, pressed)
	button.pressed.connect(Haptics.confirm)
	button.pressed.connect((handlers["profile"] as Callable).bind(str(person["staff_id"])))
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(8.0)))
	var portrait := PlaceholderArt.new()
	portrait.name = "StaffPortrait"
	portrait.kind = PlaceholderArt.Kind.CHARACTER
	portrait.art_id = str(person["staff_id"])
	portrait.custom_minimum_size = Vector2(OfficeFrameStyles.len_px(40.0), OfficeFrameStyles.len_px(58.0))
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(portrait)
	var text := VBoxContainer.new()
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.add_theme_constant_override("separation", 2)
	var name := Label.new()
	name.name = "StaffLine"
	name.text = str(person["line"])
	name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(name)
	var tag := Label.new()
	tag.name = "StaffTag"
	tag.text = str(person["tag"])
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.set_meta(UiKit.ONE_LINE_META, true)
	tag.theme_type_variation = "SmallLabel"
	tag.add_theme_font_size_override("font_size", OfficeFrameStyles.px(LevelBriefingStyles.SIZE_SMALL))
	if bool(person["primary"]):
		tag.add_theme_color_override("font_color", look["ink"])
	text.add_child(tag)
	var summary := Label.new()
	summary.name = "StaffSummaryLine"
	summary.text = str(person["summary"])
	summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	summary.theme_type_variation = "SmallLabel"
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_child(summary)
	line.add_child(text)
	button.add_child(line)
	# A Button does not size itself to its children: it is as tall as the portrait and the three lines need.
	button.custom_minimum_size.y = maxf(OfficeFrameStyles.len_px(66.0), OfficeFrameStyles.touch_height() * 1.5)
	card.get_node("Column").add_child(button)
	return card


## An open place: a dashed row that opens the candidates for the role.
static func _hire_row(look: Dictionary, role: String, index: int, handlers: Dictionary) -> Control:
	var button := Button.new()
	button.name = "HireSlot_%s_%d" % [role.replace(" ", "_"), index]
	button.custom_minimum_size.y = OfficeFrameStyles.touch_height()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var quiet := StyleBoxEmpty.new()
	for state: String in ["normal", "hover", "pressed", "disabled", "focus", "hover_pressed"]:
		button.add_theme_stylebox_override(state, quiet)
	button.pressed.connect(Haptics.confirm)
	button.pressed.connect((handlers["hire"] as Callable).bind(role))
	# Padded, so the "+" and "Open place" do not touch the dashed edge.
	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pad.add_theme_constant_override("margin_left", int(OfficeFrameStyles.len_px(10.0)))
	pad.add_theme_constant_override("margin_right", int(OfficeFrameStyles.len_px(10.0)))
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(8.0)))
	pad.add_child(line)
	var title := Label.new()
	title.name = "HireText"
	title.text = Text.say("office.hire_slot", {"role": role})
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title.add_theme_color_override("font_color", look["on_ground"])
	line.add_child(title)
	var open := Label.new()
	open.text = Text.say("office.open_place")
	open.mouse_filter = Control.MOUSE_FILTER_IGNORE
	open.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	open.set_meta(UiKit.ONE_LINE_META, true)
	open.add_theme_color_override("font_color", look["on_ground_muted"])
	var holder := MarginContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.add_child(open)
	line.add_child(holder)
	button.add_child(pad)
	var dashes := DashedFrame.new()
	dashes.colour = look["on_ground_muted"]
	dashes.width = OfficeFrameStyles.len_px(1.0)
	button.add_child(dashes)
	return button
