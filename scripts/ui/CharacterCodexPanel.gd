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
	var rows: Array[Control] = [UiKit.line(Text.say("characters.blurb"))]
	rows.append(UiKit.heading(Text.say("characters.opponents_heading")))
	rows.append_array(_buttons("opponent", DataDB.opponents))
	rows.append(UiKit.heading(Text.say("characters.visitors_heading")))
	rows.append_array(_buttons("visitor", DataDB.visitors))
	_list.open(Text.say("office.characters"), rows)


func _buttons(kind: String, people: Array) -> Array[Control]:
	var made: Array[Control] = []
	var player_party := str(DataDB.player.get("party", ""))
	for entry: Dictionary in CharacterCodex.entries(kind, people, DataDB.boosters, DataDB.parties,
			player_party, GameState.met_characters, DataDB.balance):
		var met := bool(entry["met"])
		var button := UiKit.action_button(
			str(entry["name"]) if met else Text.say("characters.unmet_name"), "", _show.bind(entry), 110.0)
		button.name = "Character_" + str(entry["id"])
		button.custom_minimum_size.x = UiKit.LINE_WIDTH
		_paint(button, entry["color"] as Color)
		made.append(button)
	return made


## The button takes the character's colour in every state, with readable text.
static func _paint(button: Button, color: Color) -> void:
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = color.lightened(0.12) if state == "hover" else (
			color.darkened(0.15) if state == "pressed" else color)
		box.set_corner_radius_all(10)
		box.set_content_margin_all(12)
		button.add_theme_stylebox_override(state, box)
	var text := CharacterCodex.text_color_for(color)
	for slot: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(slot, text)


func _show(entry: Dictionary) -> void:
	var rows: Array[Control] = []
	if not bool(entry["met"]):
		rows.append(UiKit.line(Text.say("characters.unmet_detail")))
	else:
		var portrait := PlaceholderArt.new()
		portrait.kind = PlaceholderArt.Kind.CHARACTER
		portrait.art_id = str(entry["id"])
		portrait.expression = "neutral"
		portrait.custom_minimum_size = Vector2(520, 520)
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
	_detail.open(Text.say("characters.unmet_name") if not bool(entry["met"]) else str(entry["name"]), rows)
	var parent := _detail.get_parent()
	if parent != null:
		parent.move_child(_detail, parent.get_child_count() - 1)
