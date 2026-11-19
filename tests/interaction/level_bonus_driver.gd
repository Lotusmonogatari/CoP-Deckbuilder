class_name LevelBonusDriver
extends Node
## The level briefing's "Level Bonus" block (2026-11-19, Cameron): opened through the level list as a player
## does it. A level that pays a bonus shows the heading, the ranges and one chip per organization, between
## the total rewards and the first room; a level that pays none shows nothing of the kind.

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


func _texts(panel: Node) -> PackedStringArray:
	var out := PackedStringArray()
	for node: Node in panel.find_children("*", "Label", true, false):
		out.append((node as Label).text)
	return out


func _index_of(texts: PackedStringArray, start: String) -> int:
	for i in texts.size():
		if texts[i].begins_with(start):
			return i
	return -1


func _level_with_a_bonus() -> void:
	# LV11, Meeting with Student Organizers: Reputation 1 to 2, Constituency support 0 to 1, Party support
	# 1 to 4, XP 15 to 30, Funds 3,000 to 12,000, and standing with BO03, BO11 and BO29.
	var panel := await _brief("LV11")
	_expect(panel.visible, "the briefing opens")
	var texts := _texts(panel)
	var total := _index_of(texts, "Total Rewards")
	var heading := _index_of(texts, "Level Bonus")
	var first_room := _index_of(texts, "Duration")
	_expect(total >= 0 and heading > total, "the Level Bonus heading comes after Total Rewards")
	_expect(first_room > heading, "and before the first room")
	_expect(texts.has("Level Bonus (paid if you win the whole level):"), "the heading says it is paid on a win")
	_expect(texts.has("● Reputation +1 to +2"), "a range reads as a range")
	_expect(texts.has("● Funds +3,000円 to +12,000円"), "Funds read in yen with separators")
	_expect(texts.has("● XP Growth +15 to +30"), "XP reads as a range")
	_expect(texts.has("● Constituency support 0 to +1"), "a range from zero reads from 0")
	_expect(texts.has("Standing with organizations:"), "the organizations are introduced")
	var chips := panel.find_children("OrgChip_*", "Button", true, false)
	var ids: Array = []
	for chip: Node in chips:
		ids.append(str(chip.get_meta("target_id")))
	ids.sort()
	_expect(ids == ["BO03", "BO11", "BO29"], "one chip per organization, got %s" % str(ids))
	var labels := {}
	for chip: Node in chips:
		labels[str(chip.get_meta("target_id"))] = (chip.get_node("Mark") as Label).text
	_expect(labels.get("BO11") == "+2–4", "a range shows both ends on its chip: %s" % str(labels.get("BO11")))
	_expect(labels.get("BO03") == "0–1", "and a range from zero shows 0: %s" % str(labels.get("BO03")))
	_expect(bool((chips[0] as Button).get_meta("preview")), "the chips are previews, with the white outline")
	DirAccess.make_dir_recursive_absolute("user://shots")
	get_viewport().get_texture().get_image().save_png("user://shots/level_bonus.png")
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
	var texts := _texts(panel)
	_expect(_index_of(texts, "Level Bonus") < 0, "%s pays no bonus and shows no block" % none_id)
	_expect(panel.find_children("OrgChip_*", "Button", true, false).is_empty(), "and no organization chips")
	panel.close()
	await get_tree().process_frame
