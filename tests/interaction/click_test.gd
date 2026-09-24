extends Node
## Proves every overlay can be opened and closed WITH A REAL MOUSE CLICK.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/click_test.tscn
##
## WHY THIS EXISTS
## A bug reached Cameron that no test here could have caught: the details
## panel had no close button, so opening it trapped the player on a screen
## with no way out. The screenshot driver that "tested" the UI pressed
## buttons by emitting their `pressed` signal directly, which bypasses
## hit-testing entirely and proves nothing about whether a finger can reach
## the button.
##
## Everything here goes through Input.parse_input_event instead, so a button
## that is covered by another control, sized to zero, or pushed off the
## bottom of the screen makes this fail.
##
## It needs a display, which is why it is not part of the GUT suite.

const BATTLE_SCENE := "res://scenes/battle/BattleScreen.tscn"

var _failures: PackedStringArray = []
var _screen: Node


func _ready() -> void:
	_screen = load(BATTLE_SCENE).instantiate()
	add_child(_screen)

	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	await _check_details_panel()
	await _check_card_zoom()
	await _check_escape_key()
	await _check_click_outside()
	await _check_hand_drags_sideways()
	await _check_drag_card_to_play()
	_check_background_and_player_portrait()

	print("")
	if _failures.is_empty():
		print("CLICK TEST: PASS")
		get_tree().quit(0)
	else:
		print("CLICK TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _check_details_panel() -> void:
	var panel: Control = _screen.get_node("%DetailsPanel")

	await _click(_screen.get_node("%DetailsButton"))
	if not panel.visible:
		_failures.append("clicking Details did not open the details panel")
		return
	print("  details panel opens on a click")

	await _click(_screen.get_node("%DetailsClose"))
	if panel.visible:
		_failures.append("the details panel could not be closed by clicking its Back button")
	else:
		print("  details panel closes on a click")


func _check_card_zoom() -> void:
	var zoom: Control = _screen.get_node("%CardZoom")
	var hand: Node = _screen.get_node("%HandRow")
	if hand.get_child_count() == 0:
		_failures.append("there were no cards in hand to click")
		return

	await _click(hand.get_child(0))
	if not zoom.visible:
		_failures.append("clicking a card did not open the zoom view")
		return
	print("  card zoom opens on a click")

	await _click(_screen.get_node("%ZoomClose"))
	if zoom.visible:
		_failures.append("the card zoom could not be closed by clicking Back")
	else:
		print("  card zoom closes on a click")


func _check_escape_key() -> void:
	var panel: Control = _screen.get_node("%DetailsPanel")
	await _click(_screen.get_node("%DetailsButton"))

	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await get_tree().process_frame
	await get_tree().process_frame

	if panel.visible:
		_failures.append("escape did not close the details panel")
		panel.hide()
	else:
		print("  escape closes an overlay")


func _check_click_outside() -> void:
	var panel: Control = _screen.get_node("%DetailsPanel")
	await _click(_screen.get_node("%DetailsButton"))
	if not panel.visible:
		_failures.append("could not reopen the details panel for the outside-click check")
		return

	# The very top-left corner is inside the panel but outside its content.
	await _click_at(Vector2(12, 12))
	if panel.visible:
		_failures.append("clicking outside the panel content did not close it")
		panel.hide()
	else:
		print("  clicking outside an overlay closes it")


## The stage background is named for the real stage, and the player's and
## opponent's full-body portraits sit as two separate cutouts in the art
## box's bottom corners (2026-09-24: was a small chip nested inside the
## opponent's own portrait; the two are now siblings, so there is nothing
## for either to be silently painted over by).
func _check_background_and_player_portrait() -> void:
	var background := _screen.get_node("%Background") as PlaceholderArt
	if background.art_id.is_empty():
		_failures.append("the battle background was never told which stage it is")
		return
	print("  the stage background is set (%s)" % background.art_id)

	var portrait := _screen.get_node("%Portrait") as Control
	var player_portrait := _screen.get_node("%PlayerPortrait") as Control
	if not player_portrait.visible:
		_failures.append("the player's own portrait is not visible")
		return
	if player_portrait.get_parent() != portrait.get_parent():
		_failures.append("the player's portrait is not sharing the opponent's art box")
		return
	print("  the player's and opponent's portraits share the art box as separate cutouts")


## A sideways drag across the hand scrolls it, and does not open the card
## the finger started on.
func _check_hand_drags_sideways() -> void:
	var hand: Control = _screen.get_node("%HandRow")
	var scroll := hand.get_parent() as ScrollContainer
	if hand.get_child_count() == 0 or scroll == null:
		_failures.append("no hand to drag")
		return
	scroll.scroll_horizontal = 0
	var start := (hand.get_child(0) as Control).get_global_rect().get_center()
	await _drag(start, start + Vector2(-400, 0))
	await get_tree().create_timer(0.6).timeout
	if scroll.scroll_horizontal <= 0:
		_failures.append("dragging sideways across the hand did not scroll it")
	elif _screen.get_node("%CardZoom").visible:
		_failures.append("dragging the hand also opened a card")
		_screen.get_node("%CardZoom").hide()
	else:
		print("  dragging the hand sideways scrolls it")
	scroll.scroll_horizontal = 0
	await get_tree().process_frame


## Pulling a playable card up out of the hand and letting go plays it.
func _check_drag_card_to_play() -> void:
	var engine: BattleEngine = _screen.engine
	var hand: Control = _screen.get_node("%HandRow")
	var card: CardView = null
	for child in hand.get_children():
		if child is CardView and not (child as CardView).disabled \
				and (child as Control).get_global_rect().get_center().x < 1000:
			card = child
			break
	if card == null:
		_failures.append("no playable card on screen to drag")
		return
	var held := engine.state.hand.size()
	var start := card.get_global_rect().get_center()

	# A short lift drops back and plays nothing.
	await _drag(start, start + Vector2(0, -80))
	if engine.state.hand.size() != held:
		_failures.append("a short lift played the card anyway")
		return

	await _drag(start, start + Vector2(0, -(CardView.PLAY_LIFT + 120)))
	if _screen.get_node("%CardZoom").visible:
		_failures.append("dragging a card up opened the zoom instead of playing it")
	elif engine.state.hand.size() >= held and engine.state.discard.is_empty():
		_failures.append("dragging a card up and letting go did not play it")
	else:
		print("  dragging a card up plays it")


## A real press, a movement in steps, and a release.
func _drag(from: Vector2, to: Vector2, steps: int = 12) -> void:
	var transform := get_viewport().get_screen_transform()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = transform * from
	press.global_position = press.position
	Input.parse_input_event(press)
	await get_tree().process_frame
	for step in range(1, steps + 1):
		var motion := InputEventMouseMotion.new()
		motion.position = transform * from.lerp(to, float(step) / steps)
		motion.global_position = motion.position
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion)
		await get_tree().process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = transform * to
	release.global_position = release.position
	Input.parse_input_event(release)
	await get_tree().process_frame
	await get_tree().process_frame


## A real press and release at the control's own screen position.
func _click(control: Control) -> void:
	await get_tree().process_frame
	var rect := control.get_global_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_failures.append("%s has no size, so nothing could click it" % control.name)
		return
	await _click_at(rect.get_center())


func _click_at(where: Vector2) -> void:
	# Injected events are read as WINDOW coordinates, but control rectangles
	# are in viewport coordinates, and the two differ: the game is designed
	# at 1080x2340 and shown in a 440-wide window. Without this conversion
	# every click lands in the wrong place and nothing is ever hit.
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
