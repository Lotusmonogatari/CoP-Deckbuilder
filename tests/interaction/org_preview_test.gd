extends Node
## Real clicks on the listening strip (2026-10-18): in a Town Hall (LV01's
## first stage) the organisations the question concerns appear as icons; a
## first tap on a card that would move them shows ± marks and a Read button
## without opening the card; Read (or a second tap) opens it.

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
		print("ORG PREVIEW TEST: PASS")
		get_tree().quit(0)
	else:
		print("ORG PREVIEW TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _check() -> void:
	var strip: ListeningStrip = _screen._listening
	if strip == null or strip.listener_ids().is_empty():
		_failures.append("no organisations were shown as listening to the question")
		return
	print("  listening strip shows %d organisation(s)" % strip.listener_ids().size())

	var engine: BattleEngine = _screen.engine
	var hand: Node = _screen.get_node("%HandRow")
	var zoom: Control = _screen.get_node("%CardZoom")
	var target: CardView = null
	# The first matching card that is on screen: the hand row scrolls, and a
	# card past the right edge cannot be tapped without scrolling (this was a
	# rare flake when the only matching card was the fourth or fifth).
	var width := get_viewport().get_visible_rect().size.x
	for view: CardView in hand.get_children():
		if view.get_global_rect().get_center().x >= width:
			continue
		if not OrgPreview.changes(engine, DataDB.get_card(view.card_id)).is_empty():
			target = view
			break
	# A card that moves no organization shows that too: a 0 on every listening icon (Cameron, 2026-11-18).
	var zero_card: CardView = null
	for view: CardView in hand.get_children():
		if view.get_global_rect().get_center().x < width and OrgPreview.changes(engine, DataDB.get_card(view.card_id)).is_empty():
			zero_card = view
			break
	if zero_card != null:
		await _click(zero_card)
		var zeros := 0
		for booster_id: String in strip.listener_ids():
			var mark := strip._tiles[booster_id]["mark"] as Label
			if mark.visible and mark.text == "0":
				zeros += 1
		if zeros != strip.listener_ids().size():
			_failures.append("a card with no effect on organizations showed 0 on %d of %d icons" % [zeros, strip.listener_ids().size()])
		else:
			print("  a no-effect card shows 0 on every icon")
		# Put that card back down. A selected card is raised over its neighbour, and a tap on the part it
		# covers now reaches it (the card on top takes the tap, 2026-11-19), not the card beneath.
		_screen.call("_clear_preview")
		await get_tree().process_frame

	if target == null:
		# A random hand can hold no matching card in view (rare); nothing to click.
		print("  SKIPPED: no card in view would move any organisation")
		return

	await _click(target)
	if zoom.visible:
		_failures.append("the first tap opened the card instead of previewing it")
	if not target.selected:
		_failures.append("the card did not show Read after the first tap")
	else:
		print("  first tap previews and shows Read")

	var marked := 0
	for booster_id: String in strip._tiles:
		if (strip._tiles[booster_id]["mark"] as Label).visible:
			marked += 1
	if marked == 0:
		_failures.append("no organisation showed a +/- mark during the preview")
	else:
		print("  %d organisation(s) marked" % marked)

	await _click(target)
	if not zoom.visible:
		_failures.append("a second tap on the card did not open it")
	else:
		print("  a second tap opens the card")


func _click(control: Control) -> void:
	await get_tree().process_frame
	var where := HandPoint.center(control)
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
