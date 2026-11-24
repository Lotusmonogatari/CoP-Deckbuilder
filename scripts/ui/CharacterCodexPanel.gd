class_name CharacterCodexPanel
extends RefCounted
## The Characters list in Administration (2026-11-13, Cameron): a scrolling list of
## every opponent and visitor, one coloured button each, and a detail panel for
## the one tapped. Two Overlays, both owned by the Office; this class only fills
## them. The rules (order, colours, who has been met) are in CharacterCodex.

var _list: Overlay
var _detail: Overlay


func _init(list_panel: Overlay, detail_panel: Overlay) -> void:
	_list = list_panel
	_detail = detail_panel


## Opens the list: Opponents, then Visitors; met people A to Z, unmet last.
func open() -> void:
	# On the shared frame (P14b, 2026-11-20): one card each for Opponents and Visitors, the names in two columns, each with its
	# colour as a left edge; people not met yet are dimmed.
	var look := OfficeFrameStyles.look()
	var rows: Array[Control] = []
	var blurb := UiKit.line(Text.say("characters.blurb"), "SmallLabel")
	blurb.custom_minimum_size.x = 0.0
	blurb.add_theme_color_override("font_color", look["on_ground_muted"])
	rows.append(blurb)
	for group: Array in [["opponent", DataDB.opponents, "characters.opponents_heading"], ["visitor", DataDB.visitors, "characters.visitors_heading"]]:
		var card := OfficeFrameStyles.card(look, Text.say(str(group[2])))
		card.name = "CharactersCard_" + str(group[0])
		var grid := GridContainer.new()
		grid.name = "CharactersGrid_" + str(group[0])
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", int(OfficeFrameStyles.len_px(8.0)))
		grid.add_theme_constant_override("v_separation", int(OfficeFrameStyles.len_px(8.0)))
		for button: Control in _buttons(str(group[0]), group[1] as Array, look):
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			grid.add_child(button)
		card.get_node("Column").add_child(grid)
		rows.append(card)
	var frame := OfficeScreenFrame.new()
	frame.setup({"title": Text.say("office.characters"), "subtitle": "", "chips": [], "rows": rows})
	_list.open_frame(frame, Text.say("ui.back"))


func _buttons(kind: String, people: Array, look: Dictionary) -> Array[Control]:
	var made: Array[Control] = []
	var player_party := str(DataDB.player.get("party", ""))
	for entry: Dictionary in CharacterCodex.entries(kind, people, DataDB.boosters, DataDB.parties,
			player_party, GameState.met_characters, DataDB.balance):
		var met := bool(entry["met"])
		var button := UiKit.action_button(
			str(entry["name"]) if met else Text.say("characters.unmet_name"), "", _show.bind(entry), 110.0)
		button.name = "Character_" + str(entry["id"])
		button.custom_minimum_size.x = 0.0
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_paint(button, entry["color"] as Color, look)
		if not met:
			button.modulate = Color(1, 1, 1, 0.6)
		made.append(button)
	return made


## The button takes the character's colour in every state, with readable text.
static func _paint(button: Button, color: Color, look: Dictionary) -> void:
	# The card's own fill and ink, with the character's colour as a thick left edge: the words always read on the card.
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = (look["tile"] as Color).lightened(0.06) if state == "hover" else look["tile"]
		box.border_width_left = int(OfficeFrameStyles.len_px(12.0))
		box.border_color = color
		box.set_corner_radius_all(int(OfficeFrameStyles.len_px(8.0)) if look["living"] else 0)
		box.set_content_margin_all(12)
		button.add_theme_stylebox_override(state, box)
	for slot: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(slot, look["ink"])
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT


func _show(entry: Dictionary) -> void:
	var rows: Array[Control] = []
	if not bool(entry["met"]):
		rows.append(UiKit.line(Text.say("characters.unmet_detail")))
	else:
		var portrait := PlaceholderArt.new()
		portrait.kind = PlaceholderArt.Kind.CHARACTER
		portrait.art_id = str(entry["id"])
		portrait.expression = "neutral"
		# The name sits at the top, the picture takes all the room between, and the facts sit low (Cameron, 2026-11-24).
		portrait.trim_margins = true
		portrait.custom_minimum_size = Vector2(0, 700)
		portrait.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rows.append(portrait)
		rows.append(UiKit.line(Text.say("characters.detail_name", {"name": entry["name"]})))
		if not str(entry["name_jp"]).is_empty():
			rows.append(UiKit.line(Text.say("characters.detail_name_jp", {"name": entry["name_jp"]}), "SmallLabel"))
		if not str(entry["title"]).is_empty():
			rows.append(UiKit.line(Text.say("characters.detail_title", {"title": entry["title"]})))
		if not str(entry["party"]).is_empty():
			rows.append(UiKit.line(Text.say("characters.detail_party", {"party": entry["party"]})))
		var organizations := ", ".join(PackedStringArray(entry["organizations"] as Array))
		if not organizations.is_empty():
			rows.append(UiKit.line(Text.say("characters.detail_organization", {"organization": organizations})))
	_detail.top_aligned = bool(entry["met"])   # pins the name to the top and lets the picture fill the middle
	_detail.open(Text.say("characters.unmet_name") if not bool(entry["met"]) else str(entry["name"]), rows)
	var parent := _detail.get_parent()
	if parent != null:
		parent.move_child(_detail, parent.get_child_count() - 1)
