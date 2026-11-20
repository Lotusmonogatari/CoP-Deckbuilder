class_name LevelBonusDriver
extends Node
## The level bonus on the level briefing (2026-11-19, rewritten for the P12 redesign): opened through the level list as a
## player does it. A level that pays a bonus shows it as a small line in each meter's tile ("+1 to +2 bonus") and as a
## row for each organization in the "Organizations, if you win" card with its name and range; a level that pays none
## shows no such card and no bonus lines.

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	OS.set_environment("COP_NO_RANDOM_EVENTS", "1")
	await _open_office()
	await _level_with_a_bonus()
	await _level_without_one()
	print("")
	if _failures.is_empty():
		print("LEVEL BONUS TEST: PASS")
		get_tree().quit(0)
	else:
		print("LEVEL BONUS TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)


func _open_office() -> void:
	get_tree().change_scene_to_file("res://scenes/office_hours/OfficeScreen.tscn")
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout


func _screen() -> Node:
	return get_tree().current_scene


## The briefing for `level_id`, opened the way the level list opens it.
func _brief(level_id: String) -> Overlay:
	_screen().call("_on_level_chosen", DataDB.get_level(level_id))
	await get_tree().create_timer(0.5).timeout
	return _screen().get_node("BriefingPanel") as Overlay


func _texts(node: Node) -> PackedStringArray:
	var out := PackedStringArray()
	for label: Node in node.find_children("*", "Label", true, false):
		out.append((label as Label).text)
	return out


func _level_with_a_bonus() -> void:
	# LV11, Meeting with Student Organizers: Reputation 1 to 2, Constituency support 0 to 1, Party support
	# 1 to 4, XP 15 to 30, Funds 3,000 to 12,000, and standing with BO03, BO11 and BO29.
	var panel := await _brief("LV11")
	_expect(panel.visible, "the briefing opens")
	var texts := _texts(panel)
	_expect(texts.has("+1 to +2 bonus"), "Reputation's tile carries its bonus range")
	_expect(texts.has("0 to +1 bonus"), "a range from zero reads from 0")
	_expect(texts.has("+1 to +4 bonus"), "Party support's tile carries its range")
	_expect(texts.has("+15 to +30 bonus"), "XP Growth's tile carries its range")
	_expect(texts.has("+3,000円 to +12,000円 bonus"), "Funds read in yen with separators")
	var card := panel.find_child("OrgsCard", true, false)
	_expect(card != null, "an Organizations card is shown")
	var expected := {"BO03": "0 to +1", "BO11": "+2 to +4", "BO29": "0 to +1"}
	var found := panel.find_children("OrgRow_*", "HBoxContainer", true, false)
	_expect(found.size() == 3, "one row per organization, got %d" % found.size())
	for row: Node in found:
		var id := str(row.name).trim_prefix("OrgRow_")
		_expect(expected.has(id), "%s is one of the bonus organizations" % id)
		var range_label := row.find_child("Range", true, false) as Label
		_expect(range_label != null and range_label.text == str(expected.get(id, "")),
			"%s shows its range: %s" % [id, range_label.text if range_label != null else "none"])
		var chip := row.find_child("OrgChip_*", true, false)
		_expect(chip != null, "%s has its icon (an OrgChip)" % id)
		_expect(_texts(row).has(OrgChip.name_of(id)), "%s shows its name" % id)
	panel.close()
	await get_tree().process_frame


func _level_without_one() -> void:
	var none_id := ""
	for level: Dictionary in DataDB.levels:
		if LevelBonus.is_empty(LevelBonus.preview(level, GameState.difficulty, DataDB.balance_base)) \
				and not SpecialLevels.is_special(level):
			none_id = str(level.get("level_id", ""))
			break
	_expect(not none_id.is_empty(), "the data has a level that pays no bonus")
	if none_id.is_empty():
		return
	var panel := await _brief(none_id)
	_expect(panel.find_child("OrgsCard", true, false) == null, "%s pays no bonus and shows no organizations card" % none_id)
	for text: String in _texts(panel):
		_expect(not text.ends_with(" bonus"), "%s shows no bonus line: %s" % [none_id, text])
	panel.close()
	await get_tree().process_frame
