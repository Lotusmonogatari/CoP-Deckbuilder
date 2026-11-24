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
	GameState.start_new_run("PC04")
	GameState.awaiting_new_game = false
	OS.set_environment("COP_NO_RANDOM_EVENTS", "1")
	for style: String in STYLES:
		UiStyle.trying = style
		UiStyle.sync()
		await _open_office()
		await _lv11(style)
		await _long_level(style)
		await _mixed_level(style)
		await _the_note(style)
		await _large_text(style)
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
	# A level starts only at its own office (two offices, 2026-11-20): stand where this one does.
	var here := Offices.normalize(DataDB.get_level(level_id).get("location"))
	GameState.office_location = Offices.CAPITOL if here == Offices.EITHER else here
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
	_expect(texts.has("+42,000円"), where + "the Funds total, in yen, signed (the rooms' 42,000円 since the P17 economy pass; the bonus is shown on its own)")
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


## A mixed level's trips are in its hours and the briefing says so (two offices, 2026-11-20): LV05 is a Capitol level with a
## town hall in it, so PC04 (seven hours by rail from Noheji) goes out and back: 14 hours on top of its rooms.
func _mixed_level(style: String) -> void:
	var panel := await _brief("LV05")
	var where := "LV05 in %s: " % style
	var level := DataDB.get_level("LV05")
	var texts := _labels(panel)
	_expect(texts.has("Includes 14 h of travel by rail pass"), where + "the travel line (%s)" % [texts])
	_expect(panel.find_child("TravelIncluded", true, false) != null, where + "named TravelIncluded")
	_expect(texts.has("Capitol"), where + "the badge says where it starts")
	var go := panel.find_child("Confirm", true, false) as Button
	_expect(go != null and go.text == "Go in · %d hours" % GameState.level_total_hours(level), where + "Go in counts the trips (%s)" % [go.text if go != null else "none"])
	_expect(GameState.level_total_hours(level) == GameState.level_hours(level) + 14, where + "rooms plus 14")
	panel.close()
	await get_tree().process_frame


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


## At Large text nothing may be wider than the phone: the scroll box, the bottom bar and every control stay inside the screen.
func _large_text(style: String) -> void:
	Layout.text_size_setting = "large"
	Layout.apply_text_scale()
	for id: String in ["LV11", "LV19"]:
		var panel := await _brief(id)
		var where := "%s at Large text in %s: " % [id, style]
		var width := get_viewport().get_visible_rect().size.x
		var scroll := panel.find_child("Scroll", true, false) as Control
		_expect(is_equal_approx(scroll.size.x, width), where + "the scroll box is as wide as the screen (%.0f of %.0f)" % [scroll.size.x, width])
		var bar := panel.find_child("BottomBar", true, false) as Control
		_expect(bar.get_global_rect().end.x <= width + 1.0, where + "the bottom bar stays on screen")
		var go := panel.find_child("Confirm", true, false) as Button
		_expect(go.get_global_rect().end.x <= width + 1.0, where + "Go in stays on screen")
		var worst := 0.0
		for node: Node in (panel.find_child("Middle", true, false) as Control).find_children("*", "Control", true, false):
			var control := node as Control
			if control.is_visible_in_tree() and control.size.x > 0.0:
				worst = maxf(worst, control.get_global_rect().end.x)
		_expect(worst <= width + 1.0, where + "nothing in the middle reaches past the right edge (%.0f)" % worst)
		var badge := panel.find_child("HoursBadge", true, false) as Control
		_expect(badge != null and badge.get_global_rect().end.x <= width, where + "the hours badge is on screen")
		panel.close()
		await get_tree().process_frame
	Layout.text_size_setting = "normal"
	Layout.apply_text_scale()


## LV11 pays a bonus and its note says so; LV85 pays none, so its note speaks only of the rooms.
func _the_note(_style: String) -> void:
	var with_bonus := await _brief("LV11")
	_expect(_labels(with_bonus.find_child("HowItPays", true, false)).has(Text.say("briefing.how_it_pays")), "LV11's note names the bonus")
	with_bonus.close()
	await get_tree().process_frame
	var without := await _brief("LV85")
	_expect(_labels(without.find_child("HowItPays", true, false)).has(Text.say("briefing.how_it_pays_rooms")), "LV85 pays no bonus, so its note names none")
	without.close()
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
		var hours := GameState.level_trip_hours(DataDB.get_level(hidden_id))   # a mixed level's trips are in its hours
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
		var one_view := LevelBriefing.build(BattleSetup.expand_level(DataDB.get_level(one_id)), GameState.difficulty, DataDB.balance_base, {})
		var note := _labels(panel.find_child("HowItPays", true, false))
		if LevelBonus.is_empty(one_view["bonus"]):
			_expect(note == PackedStringArray([Text.say("briefing.how_it_pays_rooms")]), "%s: no bonus, so the note speaks of the rooms only (%s)" % [one_id, note])
		else:
			_expect(note == PackedStringArray([Text.say("briefing.how_it_pays")]), "%s: a bonus, so the note names it (%s)" % [one_id, note])
		panel.close()
		await get_tree().process_frame
