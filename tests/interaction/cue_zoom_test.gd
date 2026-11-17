extends Node
## The cue band steps aside while the card zoom is open and comes back exactly as it was
## (design review P2, round 2). In a real battle: a line is up, the zoom opens half a second
## in, stays open for ten seconds (longer than the line's whole hold), and closes. The same
## line must then be showing with its remaining hold, the queue must be intact and
## `lines_shown` must not have moved while the zoom was open. A band that was not showing
## must stay hidden, and one cleared while the zoom was open must not come back.
##
##     xvfb-run .tools/godot --path . tests/interaction/cue_zoom_test.tscn

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.start_new_run("PC02")
	GameState.awaiting_new_game = false
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV04"))))
	var vp := SubViewport.new()
	vp.size = Vector2i(1080, 2340)
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var battle: Control = (load("res://scenes/battle/BattleScreen.tscn") as PackedScene).instantiate()
	vp.add_child(battle)
	await get_tree().create_timer(1.0).timeout
	var banner: CueBanner = battle.get_node("CueBanner")
	var card_id: String = str(battle.get("engine").state.hand[0])

	# 1. A line up, the zoom opens at 0.5 s, stays open for ten seconds.
	banner.clear()
	banner.say(CueBanner.PLAYER, "Test", "The line that was showing.", "what it did")
	banner.say(CueBanner.OPPONENT, "Other", "The line that was waiting.")
	await get_tree().create_timer(0.5).timeout
	_expect(banner.is_showing(), "the line is up before the zoom opens")
	var shown_before := banner.lines_shown
	var timer: Timer = banner.get("_step_timer")
	battle.call("_open_card", card_id)
	await get_tree().process_frame
	var left_open := timer.time_left
	var queue_open: int = (banner.get("_queue") as Array).size()
	_expect(banner.is_suppressed(), "the banner is stepped aside while the zoom is open")
	_expect(not banner.is_showing(), "the band is hidden while the zoom is open")
	await get_tree().create_timer(10.0).timeout
	_expect(banner.lines_shown == shown_before, "lines_shown moved while the zoom was open (%d to %d)" % [shown_before, banner.lines_shown])
	_expect((banner.get("_queue") as Array).size() == queue_open, "the queue changed while the zoom was open")
	_expect(not banner.is_showing(), "the band stayed hidden for the ten seconds")
	battle.get_node("%CardZoom").hide()
	await get_tree().process_frame
	_expect(not banner.is_suppressed(), "the banner is released when the zoom closes")
	_expect(banner.is_showing(), "the line is showing again")
	_expect(banner.current_line() == "The line that was showing.", "the same line is showing, not '%s'" % banner.current_line())
	_expect(banner.lines_shown == shown_before, "lines_shown moved on release")
	_expect((banner.get("_queue") as Array).size() == queue_open, "the queue is not intact after release")
	_expect(timer.time_left >= left_open - 0.15, "the remaining hold shrank while paused (%.2f s before, %.2f s after)" % [left_open, timer.time_left])
	_expect(timer.time_left > 0.3, "the line has almost no hold left (%.2f s)" % timer.time_left)
	# and it carries on: the waiting line follows
	await get_tree().create_timer(timer.time_left + 0.6).timeout
	_expect(banner.lines_shown >= shown_before + 1, "the line never finished after release")

	# 2. Nothing showing: opening and closing the zoom shows nothing.
	banner.clear()
	await get_tree().process_frame
	battle.call("_open_card", card_id)
	await get_tree().process_frame
	battle.get_node("%CardZoom").hide()
	await get_tree().process_frame
	_expect(not banner.is_showing(), "a banner that was hidden came back with the zoom closing")

	# 3. Cleared while the zoom is open: stays gone.
	banner.say(CueBanner.PLAYER, "Test", "Another line.")
	await get_tree().create_timer(0.3).timeout
	battle.call("_open_card", card_id)
	await get_tree().process_frame
	banner.clear()
	battle.get_node("%CardZoom").hide()
	await get_tree().process_frame
	_expect(not banner.is_showing(), "a cleared band came back")

	# 4. A line said while the zoom is open waits, then shows on release.
	battle.call("_open_card", card_id)
	await get_tree().process_frame
	banner.say(CueBanner.OPPONENT, "Late", "Said during the zoom.")
	await get_tree().process_frame
	_expect(not banner.is_showing(), "a line started while the zoom was open")
	battle.get_node("%CardZoom").hide()
	await get_tree().process_frame
	_expect(banner.is_showing() and banner.current_line() == "Said during the zoom.", "the late line did not show on release")

	GameState.end_level()
	print("")
	if _failures.is_empty():
		print("CUE ZOOM TEST: PASS")
		get_tree().quit(0)
	else:
		print("CUE ZOOM TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _expect(ok: bool, message: String) -> void:
	if not ok:
		_failures.append(message)
