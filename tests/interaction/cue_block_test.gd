extends Node
## A cue over a screen's buttons blocks them (Cameron, 2026-11-18): while a cue is up, and for a moment after it
## goes, a tap never presses a button behind it; the tap that dismisses a cue does not press one either.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/cue_block_test.tscn

var _failures: PackedStringArray = []
var _pressed := 0
var _button: Button = null
var _banner: CueBanner = null


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var holder := Control.new()
	holder.name = "Holder"
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(holder)
	_button = Button.new()
	_button.text = "Choice"
	# Where the cue band sits (0.42 of the way down), so the band lies over the button.
	_button.position = Vector2(100, 0.42 * 2340.0 - 40.0)
	_button.size = Vector2(800, 120)
	_button.pressed.connect(func() -> void: _pressed += 1)
	holder.add_child(_button)
	_banner = CueBanner.new()
	_banner.block_input = true
	holder.add_child(_banner)
	await get_tree().create_timer(0.3).timeout

	# A cue is up: the button behind it cannot be pressed, and the tap dismisses the cue.
	_banner.say(CueBanner.OPPONENT, "Visitor", "A question for you?")
	await get_tree().create_timer(0.6).timeout
	if not _banner.is_showing():
		_failures.append("the cue did not show")
	await _tap(_button.get_global_rect().get_center())
	if _pressed != 0:
		_failures.append("the tap that dismissed the cue pressed the button behind it")
	if _banner.is_showing():
		_failures.append("tapping the cue did not dismiss it")

	# Straight after the dismissal (inside the grace) the block still holds.
	await _tap(_button.get_global_rect().get_center())
	if _pressed != 0:
		_failures.append("a tap right after the cue went still pressed the button")

	# Once the grace is over the button works again.
	await get_tree().create_timer(Levers.num("cue_click_block_grace_seconds") + 0.3).timeout
	await _tap(_button.get_global_rect().get_center())
	if _pressed != 1:
		_failures.append("the button did not work once the cue and its grace were over (%d presses)" % _pressed)

	# A cue the code takes away needs no grace.
	_banner.say(CueBanner.OPPONENT, "Visitor", "Another one?")
	await get_tree().create_timer(0.6).timeout
	_banner.clear()
	await get_tree().process_frame
	await _tap(_button.get_global_rect().get_center())
	if _pressed != 2:
		_failures.append("the button stayed blocked after the code cleared the cue (%d presses)" % _pressed)

	print("")
	if _failures.is_empty():
		print("CUE BLOCK TEST: PASS")
		get_tree().quit(0)
	else:
		print("CUE BLOCK TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _tap(at: Vector2) -> void:
	var xf := get_viewport().get_screen_transform()
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = xf * at
		e.global_position = e.position
		Input.parse_input_event(e)
		await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
