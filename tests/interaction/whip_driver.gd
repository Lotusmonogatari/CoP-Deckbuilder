class_name WhipDriver
extends Node
## Real clicks on the vote whip (2026-10-22): LV31's bill with PC02 (Frontier
## Party, Opposed on it). Whip two extra votes, see the Nay button carry the
## price (base 10 each, because Nay is with the party), vote, and check Party
## support fell by exactly 20 and the result says so.

const LEVEL_ID := "LV31"
var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.start_new_run("PC02")
	GameState.meta["Party support"] = 80
	var runner := LevelRunner.new(BattleSetup.expand_level(DataDB.get_level(LEVEL_ID)))
	for i in runner.stage_count():
		if str(runner.stage_by_seq(i + 1).get("mode", "")) == "Vote":
			runner.index = i
	GameState.begin_level(runner)
	get_tree().change_scene_to_file(StageRouting.scene_for(runner.current_stage()))
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	await _walk()
	print("")
	if _failures.is_empty():
		print("WHIP TEST: PASS")
		get_tree().quit(0)
	else:
		print("WHIP TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _walk() -> void:
	var screen := get_tree().current_scene
	var more := screen.find_child("WhipMore", true, false) as Button
	if more == null:
		_failures.append("no 'Whip more' button with 80 Party support")
		return
	print("  the whip row is showing")
	await _click(more)
	await get_tree().create_timer(0.3).timeout   # the row is rebuilt and laid out
	await _click(screen.find_child("WhipMore", true, false))
	await get_tree().create_timer(0.3).timeout
	var count := screen.find_child("WhipCount", true, false) as Label
	if count == null or not count.text.contains("2"):
		_failures.append("the count did not reach 2: %s" % (count.text if count != null else "missing"))
		return
	var vote_no: Button = screen.get_node("%VoteNo")
	if not vote_no.text.contains("20"):
		_failures.append("the Nay button does not show the price of 20: '%s'" % vote_no.text)
	var vote_yes: Button = screen.get_node("%VoteYes")
	# Aye is against Frontier's position (Opposed): 30 each, 60 for two, and
	# 80 - 60 = 20 is under the floor of 30, so it must be greyed.
	if not vote_yes.disabled:
		_failures.append("Aye (against the party, 60 for two whips) should be greyed: 80 - 60 is under the floor")
	print("  Nay shows its price (%s); Aye is greyed" % vote_no.text)
	await _click(vote_no)
	await get_tree().create_timer(0.3).timeout
	var body: Label = screen.get_node("%OutcomeBody")
	if not body.text.contains("2 extra votes"):
		_failures.append("the result does not say two votes were whipped: '%s'" % body.text)
	# 80 - 20 for the whips, plus whatever the vote's own favorability moved.
	var now := int(GameState.meta.get("Party support", -1))
	if now > 62 or now < 55 or not body.text.contains("spending 20 Party support"):
		_failures.append("Party support is %d after whipping two votes at 10 each, and the result says '%s'" % [now, body.text])
	else:
		print("  Party support fell from 80 to %d and the result says so" % now)


func _click(control: Control) -> void:
	await get_tree().process_frame
	var in_window: Vector2 = get_viewport().get_screen_transform() * control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = in_window
		event.global_position = in_window
		Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().process_frame
