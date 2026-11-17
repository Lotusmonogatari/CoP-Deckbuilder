extends Node
## A card that rises when touched still does its job (review of P9, finding 4): with real mouse input on
## the real battle screen in every style, a TAP on a card in the overlapped hand still opens the zoom, and
## a DRAG up still plays the card (the hand shrinks and the card's energy is spent). The card also rises
## while held and settles after the finger lifts.
##
##     xvfb-run .tools/godot --path . tests/interaction/hand_input_test.tscn

const BATTLE := "res://scenes/battle/BattleScreen.tscn"

var _failures: PackedStringArray = []


func _ready() -> void:
	if name != "Runner":
		var runner := Node.new()
		runner.name = "Runner"
		runner.set_script(get_script())
		get_tree().root.add_child.call_deferred(runner)
		return
	_run.call_deferred()


func _run() -> void:
	for style: String in UiStyles.ALL:
		await _one(style)
	if _failures.is_empty():
		print("HAND INPUT TEST: PASS")
		get_tree().quit(0)
	else:
		print("HAND INPUT TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _playable(screen: Control) -> CardView:
	var hand: Control = screen.get_node("%HandRow")
	for child in hand.get_children():
		if child is CardView and not (child as CardView).disabled \
				and screen.engine.discard_required((child as CardView).card) == 0 \
				and (child as Control).get_global_rect().get_center().x < 1000:
			return child
	return null


func _one(style: String) -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC02")
	GameState.awaiting_new_game = false
	var package := UiStyles.package_for(style, DataDB.cosmetic_packages)
	if not package.is_empty():
		GameState.owned_cosmetic_packages.append(str(package["package_id"]))
		GameState.equip_cosmetic(CosmeticPieces.UI_STYLE, str(package["package_id"]))
	UiStyle.forget()
	Layout.apply_ui_style()
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV04"))))
	get_tree().change_scene_to_file(BATTLE)
	await get_tree().process_frame
	await get_tree().create_timer(1.2).timeout
	var screen := get_tree().current_scene
	(screen.get("_banner") as CueBanner).set_suppressed(true)
	var zoom: Control = screen.get_node("%CardZoom")

	# A tap opens the zoom (in a question room the first tap previews, the second opens).
	var card := _playable(screen)
	if card == null:
		_failures.append("%s: no playable card on screen" % style)
		return
	var resting_y := card.get_global_rect().position.y
	await _tap(HandPoint.center(card))
	if not zoom.visible and card.selected:
		await _tap(HandPoint.center(card))
	if not zoom.visible:
		_failures.append("%s: a tap on a raised card did not open the zoom" % style)
	else:
		zoom.hide()
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	card = _playable(screen)
	if card != null and absf(card.get_global_rect().position.y - resting_y) > 2.0:
		_failures.append("%s: the card did not settle after the tap" % style)

	# A drag up plays it.
	card = _playable(screen)
	if card == null:
		return
	var held: int = screen.engine.state.hand.size()
	var energy: int = screen.engine.state.energy
	var start := HandPoint.center(card)
	var guard := screen.get_node("%GuardLabel") as Control
	var gaffes := screen.get_node("%GaffeLabel") as Control
	await _drag(start, start + Vector2(0, -(CardView.PLAY_LIFT + 120)), 12, func() -> void:
		# Mid-drag, the lifted card must not cover the Guard or Gaffes counters (P9 tidy).
		var rect := card.get_global_rect()
		if rect.intersects(guard.get_global_rect()):
			_failures.append("%s: the lifted card covers the Guard counter (card %s, counter %s)" % [style, rect, guard.get_global_rect()])
		if rect.intersects(gaffes.get_global_rect()):
			_failures.append("%s: the lifted card covers the Gaffes counter (card %s, counter %s)" % [style, rect, gaffes.get_global_rect()]))
	await get_tree().create_timer(0.4).timeout
	if screen.engine.state.hand.size() >= held and screen.engine.state.energy >= energy:
		_failures.append("%s: a drag up did not play the card" % style)


func _event(pressed: bool, at: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = pressed
	e.position = get_viewport().get_screen_transform() * at
	e.global_position = e.position
	return e


func _tap(at: Vector2) -> void:
	Input.parse_input_event(_event(true, at))
	await get_tree().process_frame
	Input.parse_input_event(_event(false, at))
	await get_tree().process_frame
	await get_tree().create_timer(0.15).timeout


func _drag(from: Vector2, to: Vector2, steps: int = 12, before_release: Callable = Callable()) -> void:
	var transform := get_viewport().get_screen_transform()
	Input.parse_input_event(_event(true, from))
	await get_tree().process_frame
	for step in range(1, steps + 1):
		var motion := InputEventMouseMotion.new()
		motion.position = transform * from.lerp(to, float(step) / steps)
		motion.global_position = motion.position
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion)
		await get_tree().process_frame
	await get_tree().process_frame
	if before_release.is_valid():
		before_release.call()
	Input.parse_input_event(_event(false, to))
	await get_tree().process_frame
	await get_tree().process_frame
