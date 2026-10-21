extends Node
## Real clicks on a card that costs a discard (2026-10-21): C63 "Compile the
## Dossier" (Tier 1, discard 2 other cards to play). Opening it and pressing Play
## asks which cards to discard; Cancel changes nothing; choosing two and pressing
## "Discard and play" plays the card and throws the two away.

var _failures: PackedStringArray = []
var _screen: Node


func _ready() -> void:
	GameState.start_new_run("PC01")
	var runner := LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV01")))
	GameState.begin_level(runner)
	_screen = load("res://scenes/battle/BattleScreen.tscn").instantiate()
	add_child(_screen)
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	await _check()

	print("")
	if _failures.is_empty():
		print("DISCARD TEST: PASS")
		get_tree().quit(0)
	else:
		print("DISCARD TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _view(card_id: String, nth: int = 0) -> CardView:
	var seen := 0
	for view: CardView in _screen.get_node("%HandRow").get_children():
		if view.card_id == card_id:
			if seen == nth:
				return view
			seen += 1
	return null


func _check() -> void:
	var engine: BattleEngine = _screen.engine
	engine.state.hand.assign(["C63", "C01", "C03"])
	engine.state.discard.clear()
	_screen._refresh()
	await get_tree().process_frame

	var zoom: Control = _screen.get_node("%CardZoom")
	var bar: Control = _screen.get_node("%HandRow").get_parent().get_parent().get_node("PickBar")

	# Open the card (a first tap may preview organisations, a second opens it).
	var card := _view("C63")
	await _click(card)
	if not zoom.visible:
		await _click(card)
	if not zoom.visible:
		_failures.append("the card did not open")
		return
	var play: Button = _screen.get_node("%ZoomPlay")
	if play.disabled:
		_failures.append("Play is disabled with two other cards in hand")
		return
	await _click(play)
	if not bar.visible:
		_failures.append("pressing Play did not ask for the discards")
		return
	print("  Play asks which cards to discard")
	var confirm: Button = bar.get_node("PickConfirm")
	if not confirm.disabled:
		_failures.append("Discard and play was enabled with nothing chosen")

	# Cancel changes nothing.
	await _click(bar.get_node("PickCancel"))
	if bar.visible or engine.state.hand.size() != 3:
		_failures.append("Cancel did not leave the hand untouched")
		return
	print("  Cancel leaves the hand as it was")

	# Again, choosing both others.
	await _click(_view("C63"))
	if not zoom.visible:
		await _click(_view("C63"))
	await _click(_screen.get_node("%ZoomPlay"))
	await _click(_view("C01"))
	await _click(_view("C03"))
	if confirm.disabled:
		_failures.append("Discard and play stayed disabled after choosing two cards")
		return
	print("  two cards chosen, Discard and play enabled")
	await _click(confirm)
	if engine.state.hand.has("C63") or engine.state.hand.has("C01") or engine.state.hand.has("C03"):
		_failures.append("the played or discarded cards are still in hand: %s" % [engine.state.hand])
	if engine.state.discard.size() < 3:
		_failures.append("the discard pile holds %d cards, expected 3" % engine.state.discard.size())
	else:
		print("  the card was played and the two discards are in the discard pile")


func _click(control: Control) -> void:
	await get_tree().process_frame
	var where := control.get_global_rect().get_center()
	var in_window: Vector2 = get_viewport().get_screen_transform() * where
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = in_window
		event.global_position = in_window
		Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().process_frame
