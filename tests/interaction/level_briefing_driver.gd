class_name LevelBriefingDriver
extends Node
## The redesigned level briefing (P12, 2026-11-19), opened through the level list as a player does it, in each UI style:
## the back row and the bottom bar stay put while the middle scrolls, LV11 shows its tiles, organizations and a block for
## each room in order, a level that does not fit the week greys out Go in with the reason, hidden rooms leave no trace, and
## the buttons are big enough to press.

const STYLES := [UiStyles.WOODBLOCK, UiStyles.LIVING_OFFICE, UiStyles.BROADCAST]
## 44 pt at the phone's 390 pt width, in 1080 px base pixels.
const MIN_TARGET := 44.0 * 1080.0 / 390.0 - 1.0

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	OS.set_environment("COP_NO_RANDOM_EVENTS", "1")
	for style: String in STYLES:
		UiStyle.trying = style
		UiStyle.sync()
		await _open_office()
		await _lv11(style)
		await _long_level(style)
		await _does_not_fit(style)
	UiStyle.trying = ""
	UiStyle.sync()
	await _open_office()
	await _hidden_and_one_room()
	print("")
	if _failures.is_empty():
		print("LEVEL BRIEFING TEST: PASS")
		get_tree().quit(0)
	else:
		print("LEVEL BRIEFING TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)


func _open_office() -> void:
	GameState.calendar = WeekCalendar.fresh()
	get_tree().change_scene_to_file("res://scenes/office_hours/OfficeScreen.tscn")
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout


func _screen() -> Node:
	return get_tree().current_scene


func _brief(level_id: String) -> LevelBriefingPanel:
	_screen().call("_on_level_chosen", DataDB.get_level(level_id))
	await get_tree().create_timer(0.5).timeout
	return _screen().get_node("BriefingPanel") as LevelBriefingPanel


func _labels(node: Node) -> PackedStringArray:
	var out := PackedStringArray()
	for label: Node in node.find_children("*", "Label", true, false):
		out.append((label as Label).text)
	return out


func _lv11(style: String) -> void:
	var panel := await _brief("LV11")
	var where := "LV11 in %s: " % style
	_expect(panel.visible, where + "the briefing opens")
	var texts := _labels(panel)
	_expect(texts.has("Tier 1 · 3 rooms"), where + "the meta line says Tier 1 · 3 rooms")
	_expect(texts.has("This week: 40 hours left") and texts.has("34 left after this level"), where + "the week's hours around the level")
	var title := panel.find_child("Title", true, false) as Label
	_expect(title != null and title.text.to_lower() == "meeting with student organizers", where + "the title is the level's name")
	_expect(panel.find_child("HoursBadge", true, false) != null, where + "the hours badge")
	_expect(panel.find_child("WeekBar", true, false) != null, where + "the week bar")
	_expect(panel.find_children("Tile_*", "PanelContainer", true, false).size() == 5, where + "five totals tiles")
	_expect(panel.find_child("HowItPays", true, false) != null, where + "the note about when rooms and the bonus pay")
	_expect(texts.has("+55,000円"), where + "the Funds total, in yen, signed")
	_expect(panel.find_children("OrgRow_*", "HBoxContainer", true, false).size() == 3, where + "three organization rows")
	_expect(texts.has("Students United"), where + "organizations are named")

	# The timeline: a block for each room, in order, top to bottom, with the right words.
	var blocks := panel.find_children("TimelineBlock_*", "PanelContainer", true, false)
	_expect(blocks.size() == 3, where + "three room blocks, got %d" % blocks.size())
	var last_y := -1.0
	for block: Node in blocks:
		var y := (block as Control).global_position.y
		_expect(y > last_y, where + "the blocks run down the screen in order")
		last_y = y
	_expect(texts.has("Conversation · 2 h") and texts.has("Debate · 2 h"), where + "each block says its kind and length")
	_expect(panel.find_children("LossContinues", "Label", true, false).size() == 1, where + "one room says the level carries on after a loss")
	_expect(panel.find_child("FinishMarker", true, false) != null, where + "the bonus marker ends the timeline")
	_expect(panel.find_child("HourMark", true, false) != null, where + "the hour ruler")

	# The buttons: named, big enough, and Go in carries the hours.
	var go := panel.find_child("Confirm", true, false) as Button
	var back := panel.find_child("Back", true, false) as Button
	_expect(go != null and go.text == "Go in · 6 hours" and not go.disabled, where + "Go in · 6 hours")
	_expect(back != null and back.size.y >= MIN_TARGET and go.size.y >= MIN_TARGET, where + "Back and Go in are 44 pt or more tall")
	var link := panel.find_child("BackLink", true, false) as Button
	_expect(link != null and link.size.y >= MIN_TARGET, where + "the Levels link is 44 pt or more tall")

	# Only the middle scrolls: the back row and the bottom bar do not move.
	var scroll := panel.find_child("Scroll", true, false) as ScrollContainer
	var bar_y := (panel.find_child("BottomBar", true, false) as Control).global_position.y
	var top_y := (panel.find_child("TopBar", true, false) as Control).global_position.y
	_expect(scroll.get_v_scroll_bar().max_value > scroll.size.y, where + "this level is taller than the middle region")
	var before := scroll.scroll_vertical
	scroll.scroll_vertical = 100000
	await get_tree().create_timer(0.3).timeout
	_expect(scroll.scroll_vertical > before, where + "the middle scrolls")
	_expect(is_equal_approx((panel.find_child("BottomBar", true, false) as Control).global_position.y, bar_y), where + "the bottom bar stays")
	_expect(is_equal_approx((panel.find_child("TopBar", true, false) as Control).global_position.y, top_y), where + "the back row stays")

	# Back closes the panel and the Office goes back to the level list's own panel logic.
	back.pressed.emit()
	await get_tree().process_frame
	_expect(not panel.visible, where + "Back closes the briefing")


func _long_level(style: String) -> void:
	var panel := await _brief("LV19")
	var where := "LV19 in %s: " % style
	var blocks := panel.find_children("TimelineBlock_*", "PanelContainer", true, false)
	_expect(blocks.size() >= 8, where + "the longest level lists its rooms, got %d" % blocks.size())
	var go := panel.find_child("Confirm", true, false) as Button
	_expect(go != null and not go.disabled and go.text.begins_with("Go in"), where + "Go in is there")
	var bar := panel.find_child("BottomBar", true, false) as Control
	_expect(bar.global_position.y + bar.size.y <= get_viewport().get_visible_rect().size.y + 1.0, where + "the bottom bar is on screen")
	panel.close()
	await get_tree().process_frame


func _does_not_fit(style: String) -> void:
	GameState.calendar = {"week": 0, "phase": "work", "hours": 38}
	var panel := await _brief("LV11")
	var where := "a full week, LV11 in %s: " % style
	var go := panel.find_child("Confirm", true, false) as Button
	var reason := GameState.level_calendar_refusal(DataDB.get_level("LV11"))
	_expect(not reason.is_empty(), where + "the game says the level does not fit")
	_expect(go != null and go.disabled and go.text == reason, where + "Go in is greyed out and says why")
	var texts := _labels(panel)
	_expect(texts.has("This week: 2 hours left") and texts.has("0 left after this level"), where + "the week line shows what is left")
	panel.close()
	await get_tree().process_frame
	GameState.calendar = WeekCalendar.fresh()


func _hidden_and_one_room() -> void:
	var hidden_id := ""
	var one_id := ""
	for level: Dictionary in DataDB.levels:
		var view := LevelBriefing.build(BattleSetup.expand_level(level), Difficulty.STANDARD, DataDB.balance_base, {"hours_left": 40, "pool": 40})
		var all_rooms := (BattleSetup.expand_level(level)["stages"] as Array).size()
		if hidden_id.is_empty() and int(view["room_count"]) < all_rooms and bool(view["lists_rooms"]):
			hidden_id = str(level["level_id"])
		if one_id.is_empty() and int(view["room_count"]) == 1 and not SpecialLevels.is_special(level):
			one_id = str(level["level_id"])
	_expect(not hidden_id.is_empty() and not one_id.is_empty(), "the data has a level with a hidden room and a one-room level")
	if not hidden_id.is_empty():
		var panel := await _brief(hidden_id)
		var level := BattleSetup.expand_level(DataDB.get_level(hidden_id))
		var shown := 0
		var hours := 0
		for stage: Dictionary in level["stages"]:
			hours += TimeClock.units_for_stage(stage)
			if LevelBriefing.is_revealed(stage):
				shown += 1
		_expect(panel.find_children("TimelineBlock_*", "PanelContainer", true, false).size() == shown,
			"%s: only the shown rooms are listed" % hidden_id)
		for stage: Dictionary in level["stages"]:
			if not LevelBriefing.is_revealed(stage):
				_expect(not _labels(panel).has(str(stage.get("name_en", "?"))), "%s: the hidden room %s is not named" % [hidden_id, stage.get("name_en")])
		var go := panel.find_child("Confirm", true, false) as Button
		_expect(go.text == "Go in · %d hours" % hours, "%s: the hours count the hidden room too (%s)" % [hidden_id, go.text])
		panel.close()
		await get_tree().process_frame
	if not one_id.is_empty():
		var panel := await _brief(one_id)
		_expect(panel.find_child("Timeline", true, false) == null, "%s: a level with one room lists no rooms" % one_id)
		_expect(panel.find_child("TotalsCard", true, false) != null, "%s: but shows its totals" % one_id)
		panel.close()
		await get_tree().process_frame
