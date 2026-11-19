extends Node
## Touching an overlapped hand (2026-11-19, Cameron's playtest), with real mouse input on the real battle
## screen in two styles:
##  1. pressing a card makes the organization icons answer at once, not only once the card moves;
##  2. a raised card, and the popups, draw in the right order: a popup is above any raised card;
##  3. the cards overlap, and the one drawn on top is the one a tap reaches: with a card raised, pressing its
##     Read button (which its neighbour overlaps) opens that card, not the neighbour;
##  4. a hand wider than the screen (the last third of each card overlapped, Cameron 2026-11-19) scrolls sideways:
##     a card only partly in view scrolls into view when tapped, and a sideways drag scrolls without playing one.
##
##     xvfb-run .tools/godot --path . tests/interaction/hand_stack_test.tscn

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
	for style: String in ["woodblock", "living_office"]:
		await _one(style)
	if _failures.is_empty():
		print("HAND STACK TEST: PASS")
		get_tree().quit(0)
	else:
		print("HAND STACK TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


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
	await _press_shows_the_icons(screen, style)
	await _raised_card_takes_its_own_tap(screen, style)
	await _popup_is_above_a_raised_card(screen, style)
	await _hand_scrolls(screen, style)


func _cards(screen: Node) -> Array[CardView]:
	var out: Array[CardView] = []
	for child in screen.get_node("%HandRow").get_children():
		if child is CardView and (child as CardView).visible:
			out.append(child)
	return out


func _marks_showing(screen: Node) -> int:
	var strip: ListeningStrip = screen.get("_listening")
	var count := 0
	for booster_id: String in strip._tiles:
		if (strip._tiles[booster_id]["mark"] as Label).visible:
			count += 1
	return count


# ----------------------------------------------------------------- 1. the icons answer a press

func _press_shows_the_icons(screen: Node, style: String) -> void:
	var strip: ListeningStrip = screen.get("_listening")
	if strip.listener_ids().is_empty():
		print("  %s: SKIPPED, no organization is listening in this room" % style)
		return
	var card: CardView = null
	for view in _cards(screen):
		if not view.disabled and view.get_global_rect().get_center().x < 1000:
			card = view
			break
	if card == null:
		_failures.append("%s: no card to press" % style)
		return
	var at := HandPoint.center(card)
	Input.parse_input_event(_event(true, at))
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(_marks_showing(screen) > 0, "%s: pressing a card shows what it would do on the organization icons, before it moves" % style)
	# Slid off the card and let go: nothing was chosen, so the icons go back to blank.
	var away := at + Vector2(0, 260)
	var motion := InputEventMouseMotion.new()
	motion.position = get_viewport().get_screen_transform() * away
	motion.global_position = motion.position
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	await get_tree().process_frame
	Input.parse_input_event(_event(false, away))
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(not card.selected, "%s: a press slid off the card chooses nothing" % style)
	_expect(_marks_showing(screen) == 0, "%s: and the icons go back to blank (%d still marked)" % [style, _marks_showing(screen)])


# ----------------------------------------------------------------- 3. the card on top takes the tap

func _raised_card_takes_its_own_tap(screen: Node, style: String) -> void:
	var zoom: Control = screen.get_node("%CardZoom")
	var cards := _cards(screen)
	var chosen: CardView = null
	var neighbour: CardView = null
	for index in cards.size() - 1:
		var first := cards[index]
		var next := cards[index + 1]
		if first.disabled or first.get_global_rect().end.x <= next.get_global_rect().position.x + 60.0:
			continue
		chosen = first
		neighbour = next
		break
	if chosen == null:
		_failures.append("%s: no two cards overlap in this hand" % style)
		return
	# Select the first card (it rises over its neighbour), then press where the neighbour overlaps it.
	await _tap(HandPoint.center(chosen))
	_expect(screen.get("_previewed_card_id") == chosen.card_id, "%s: the first tap selects the card" % style)
	var inside_both := Vector2(neighbour.get_global_rect().position.x + 30.0, chosen.get_global_rect().get_center().y)
	_expect(chosen.get_global_rect().has_point(inside_both) and neighbour.get_global_rect().has_point(inside_both),
		"%s: the test point lies where the two cards overlap" % style)
	await _tap(inside_both)
	_expect(zoom.visible and screen.get("_selected_card_id") == chosen.card_id,
		"%s: pressing the raised card where its neighbour overlaps opens the raised card, not the neighbour" % style)
	zoom.hide()
	screen.call("_clear_preview")
	await get_tree().process_frame


# ----------------------------------------------------------------- 2. popups above raised cards

func _popup_is_above_a_raised_card(screen: Node, style: String) -> void:
	var card: CardView = null
	for view in _cards(screen):
		if not view.disabled and view.get_global_rect().get_center().x < 1000:
			card = view
			break
	if card == null:
		return
	await _tap(HandPoint.center(card))
	_expect(card.selected, "%s: the card is selected before the popup opens" % style)
	var details := screen.get_node("%DetailsPanel") as Control
	await _tap((screen.get_node("%DetailsButton") as Control).get_global_rect().get_center())
	_expect(details.visible, "%s: the Details panel opens" % style)
	_expect(details.z_index > card.z_index, "%s: the Details panel (z %d) is drawn above the selected card (z %d)" % [style, details.z_index, card.z_index])
	var zoom := screen.get_node("%CardZoom") as Control
	_expect(zoom.z_index > card.z_index, "%s: the card zoom (z %d) is drawn above a selected card (z %d)" % [style, zoom.z_index, card.z_index])
	var outcome := screen.get_node("%OutcomePanel") as Control
	_expect(outcome.z_index > card.z_index, "%s: the outcome panel (z %d) is drawn above a selected card (z %d)" % [style, outcome.z_index, card.z_index])
	await _tap((screen.get_node("%DetailsClose") as Control).get_global_rect().get_center())
	screen.call("_clear_preview")
	await get_tree().process_frame


# ----------------------------------------------------------------- 4. the hand scrolls sideways

func _hand_scrolls(screen: Node, style: String) -> void:
	var scroll := screen.get_node("Safe/Column/HandScroll") as ScrollContainer
	var bar := scroll.get_h_scroll_bar()
	if bar.max_value - bar.page < 1.0:
		print("  %s: SKIPPED, this hand fits the screen" % style)
		return
	var width := get_viewport().get_visible_rect().size.x
	var cards := _cards(screen)
	var last := cards[cards.size() - 1]
	_expect(last.get_global_rect().end.x > width, "%s: the last card starts partly off the screen" % style)
	var held: int = screen.engine.state.hand.size()
	# A sideways drag on a card scrolls the hand; it neither plays a card nor opens one. The hand scrolls with
	# the finger (drag right to bring the cards on the right into view, Cameron 2026-09-24).
	var from := HandPoint.center(cards[1])
	await _drag(from, from + Vector2(200, 0), 8)
	await get_tree().create_timer(0.2).timeout
	_expect(scroll.scroll_horizontal > 0, "%s: a sideways drag scrolls the hand (scrolled %d)" % [style, scroll.scroll_horizontal])
	_expect(screen.engine.state.hand.size() == held and not (screen.get_node("%CardZoom") as Control).visible,
		"%s: and plays or opens no card" % style)
	scroll.scroll_horizontal = 0
	await get_tree().create_timer(0.2).timeout
	# Tapping the partly hidden last card selects it and scrolls it fully into view.
	var rect := last.get_global_rect()
	await _tap(Vector2(minf(rect.position.x + 60.0, width - 40.0), rect.get_center().y))
	_expect(last.selected, "%s: tapping the partly hidden last card selects it" % style)
	await get_tree().create_timer(0.4).timeout
	_expect(last.get_global_rect().end.x <= width + 1.0, "%s: and it scrolls fully into view (ends at %.0f of %.0f)" % [style, last.get_global_rect().end.x, width])
	screen.call("_clear_preview")
	scroll.scroll_horizontal = 0
	await get_tree().process_frame


# ----------------------------------------------------------------- input helpers

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
	await get_tree().create_timer(0.2).timeout


func _drag(from: Vector2, to: Vector2, steps: int = 8) -> void:
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
	Input.parse_input_event(_event(false, to))
	await get_tree().process_frame
	await get_tree().process_frame


func _expect(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "  X   ") + what)
	if not ok:
		_failures.append(what)
