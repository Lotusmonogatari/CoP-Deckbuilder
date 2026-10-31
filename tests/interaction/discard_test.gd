extends Node
## Real clicks on a card that costs a discard (2026-10-21). The card is the first
## real "discard to play" card in the workbook and its number is read from the
## card's own row (never typed here, 2026-10-31). Opening it and pressing Play
## asks which cards to discard; Cancel changes nothing; choosing that many and
## pressing "Discard and play" plays the card and throws them away.

var _failures: PackedStringArray = []
var _screen: Node
## The discard-to-play card under test and how many others it asks for.
var _card_id := ""
var _need := 0
## Plain cards (no discard of their own) that fill the hand.
var _others: Array[String] = []


func _pick_cards() -> void:
	for card: Dictionary in DataDB.cards:
		var to_play := int(card.get("discard_to_play") if card.get("discard_to_play") != null else 0)
		var for_draw := int(card.get("discard_for_draw") if card.get("discard_for_draw") != null else 0)
		if to_play > 0 and _card_id.is_empty() and int(card.get("cost", 0)) <= 3:
			_card_id = str(card["card_id"])
			_need = to_play
		elif to_play == 0 and for_draw == 0 and _others.size() < 4 and int(card.get("cost", 9)) <= 2:
			_others.append(str(card["card_id"]))


func _ready() -> void:
	_pick_cards()
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
	if _card_id.is_empty() or _others.size() < _need:
		_failures.append("the workbook has no discard-to-play card to test")
		return
	var chosen: Array[String] = []
	for i in _need:
		chosen.append(_others[i])
	var hand: Array[String] = [_card_id]
	hand.append_array(chosen)
	engine.state.hand.assign(hand)
	engine.state.discard.clear()
	_screen._refresh()
	await get_tree().process_frame

	var zoom: Control = _screen.get_node("%CardZoom")
	var bar: Control = _screen.get_node("%HandRow").get_parent().get_parent().get_node("PickBar")

	# Open the card (a first tap may preview organisations, a second opens it).
	var card := _view(_card_id)
	await _click(card)
	if not zoom.visible:
		await _click(card)
	if not zoom.visible:
		_failures.append("the card did not open")
		return
	var play: Button = _screen.get_node("%ZoomPlay")
	if play.disabled:
		_failures.append("Play is disabled with %d other cards in hand" % _need)
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
	if bar.visible or engine.state.hand.size() != hand.size():
		_failures.append("Cancel did not leave the hand untouched")
		return
	print("  Cancel leaves the hand as it was")

	# Again, choosing every other card.
	await _click(_view(_card_id))
	if not zoom.visible:
		await _click(_view(_card_id))
	await _click(_screen.get_node("%ZoomPlay"))
	for other: String in chosen:
		await _click(_view(other))
	if confirm.disabled:
		_failures.append("Discard and play stayed disabled after choosing %d cards" % _need)
		return
	print("  %d cards chosen, Discard and play enabled" % _need)
	await _click(confirm)
	for id: String in hand:
		if engine.state.hand.has(id):
			_failures.append("the played or discarded cards are still in hand: %s" % [engine.state.hand])
			break
	if engine.state.discard.size() < hand.size():
		_failures.append("the discard pile holds %d cards, expected %d" % [engine.state.discard.size(), hand.size()])
	else:
		print("  the card was played and the %d discards are in the discard pile" % _need)


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
