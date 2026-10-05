class_name LoopDriver
extends Node
## Walks the whole playtest loop with real clicks: the Office, every
## stage of the first level, and back to the Office.
##
## WHY THIS IS NOT THE SCENE ITSELF
## The game changes scenes as it moves from the Office into a stage, and
## changing a scene frees the old one. A driver that was the current scene
## would delete itself the moment it pressed Start. So loop_test.tscn adds
## this as a child of the tree root instead, where it outlives every scene
## change and can watch the whole journey.
##
## Every button press goes through the input system rather than emitting a
## signal, so a button that cannot actually be reached makes this fail.

const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"

## A stage that has not finished within this many turns is stuck.
##
## Generous on purpose: a committee is 15 turns against each of two members
## with a full reset between them, so 30 is the honest worst case and this
## has to sit clear of it. Too tight and a slow-but-working stage reads as a
## hang, which is exactly what happened when the committee went from 8 turns
## to 15.
const TURN_CEILING := 70

## The most stages the first level could hold. The driver plays whichever
## level it picks first, and whether it plays every stage depends on how the
## fights go: a lost combat stage ends the level early (stages.json's
## loss_ends_level), so the count is a ceiling, never an exact number.
## LV01 is Town Hall (ST05) then Office Hours (ST07); a little headroom
## keeps this from breaking when the workbook adds a stage.
const MAX_STAGES := 6

var _failures: PackedStringArray = []


func _ready() -> void:
	# Deferred so the tree is not busy adding children when the first scene
	# change happens.
	_run.call_deferred()


func _run() -> void:
	get_tree().change_scene_to_file(OFFICE_SCENE)
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout

	await _walk_the_loop()

	print("")
	if _failures.is_empty():
		print("LOOP TEST: PASS")
		get_tree().quit(0)
	else:
		print("LOOP TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _walk_the_loop() -> void:
	var office := get_tree().current_scene
	if office == null or office.name != "OfficeScreen":
		_failures.append("the game did not start in the Office")
		return
	print("  started in the Office")

	# Start opens the LEVELS screen now that there are six of them. Pick the
	# first, look it over, then go in: three clicks, and each screen must
	# actually appear or a later failure would be blamed on the wrong one.
	await _click(office.get_node("%StartButton"))
	await get_tree().create_timer(0.4).timeout

	var levels := office.get_node("%LevelsPanel") as Overlay
	if levels == null or not levels.visible:
		_failures.append("Start did not open the levels screen")
		return
	print("  Start opened the levels screen")

	var look := levels.find_child("Look it over", true, false)
	if look == null:
		for node in levels.find_children("", "Button", true, false):
			if (node as Button).text == "Look it over":
				look = node
				break
	if look == null:
		_failures.append("no level could be chosen")
		return

	await _click(look as Control)
	await get_tree().create_timer(0.4).timeout

	var briefing := office.get_node("%BriefingPanel") as Overlay
	if briefing == null or not briefing.visible:
		_failures.append("choosing a level did not open the briefing")
		return
	print("  chose a level and read the briefing")

	var go_in := briefing.find_child("Confirm", true, false) as Button
	if go_in == null or not go_in.visible:
		_failures.append("the briefing had no way into the level")
		return

	await _click(go_in)
	await get_tree().create_timer(0.6).timeout

	if get_tree().current_scene.name != "BattleScreen":
		_failures.append("the briefing did not open a stage")
		return
	print("  the briefing opened the first stage")

	# Play every stage the level hands over, whichever kind of screen it is:
	# a fight (BattleScreen) or a visitor room (VisitorScreen). The level is
	# over when the Office comes back.
	var played := 0
	while played < MAX_STAGES:
		var scene_name := str(get_tree().current_scene.name)
		if scene_name == "BattleScreen":
			if (await _play_current_stage()).is_empty():
				return
		elif scene_name == "VisitorScreen":
			if not await _play_visitor_stage():
				return
		else:
			break
		played += 1
		await get_tree().create_timer(0.5).timeout

	if get_tree().current_scene.name != "OfficeScreen":
		_failures.append("the loop did not return to the Office after %d stage(s)" % played)
		return

	if played < 1:
		_failures.append("the level returned to the Office without playing a stage")
		return
	print("  returned to the Office after %d stage(s)" % played)


## Answers every visitor in the Office Hours room on screen (always choice A)
## and presses Continue, until the room moves on. Returns false, noting a
## failure, if anything did not appear where it should.
func _play_visitor_stage() -> bool:
	print("  playing a visitor room")
	var visited := 0
	while get_tree().current_scene.name == "VisitorScreen" and visited < 12:
		var screen := get_tree().current_scene
		await _click(screen.get_node("%ChoiceA"))
		await get_tree().create_timer(0.2).timeout

		var continue_button: Button = screen.get_node("%ContinueButton")
		if continue_button.disabled:
			_failures.append("answering a visitor did not unlock Continue")
			return false
		await _click(continue_button)
		await get_tree().create_timer(0.3).timeout

		var outcome := screen.get_node_or_null("%OutcomePanel") as Control
		if outcome != null and outcome.visible:
			await _click(screen.get_node("%OutcomeClose"))
			await get_tree().create_timer(0.6).timeout
		visited += 1

	if get_tree().current_scene.name == "VisitorScreen":
		_failures.append("the visitor room never finished after %d visitors" % visited)
		return false
	print("  answered %d visitor(s)" % visited)
	return true


## Plays the stage on screen to a finish and presses on. Returns its name,
## or "" when something went wrong.
func _play_current_stage() -> String:
	var screen := get_tree().current_scene
	var stage_name := str(screen.get_node("%StageName").text)

	var guard := 0
	while not screen.engine.state.is_over() and guard < TURN_CEILING:
		guard += 1
		await _play_affordable_cards(screen)
		if screen.engine.state.is_over():
			break
		await _click(screen.get_node("%EndTurnButton"))

	if not screen.engine.state.is_over():
		var state = screen.engine.state
		_failures.append(("%s never finished within %d turns "
			+ "(reached turn %d against opponent %d of %d, gaffes %d of %d)")
			% [stage_name, TURN_CEILING, state.turn, state.opponent_index + 1,
				state.opponent_count, state.gaffe, state.gaffe_limit])
		return ""

	await get_tree().create_timer(0.3).timeout
	if not (screen.get_node("%OutcomePanel") as Control).visible:
		_failures.append("%s ended but showed no result" % stage_name)
		return ""

	# Reported rather than asserted. How hard a stage is, is Cameron's call;
	# the numbers just need to be visible so he can make it.
	var state = screen.engine.state
	var standing := ""
	if state.bar != null:
		standing = "  you %d, them %d" % [state.bar.player, state.bar.opponent]
	print("  played: %-24s %s in %d turns%s" % [
		stage_name, state.outcome.to_upper(), state.turn, standing])
	print("          %s" % state.outcome_reason)

	await _click(screen.get_node("%OutcomeClose"))
	await get_tree().create_timer(0.6).timeout
	return stage_name


## Plays whatever the player can afford this turn, the way a person would:
## tap the card, then confirm in the zoom view. Two clicks, both real.
##
## It deliberately plays rather than just ending turns. A driver that never
## plays a card loses every stage, which would make this a test of the first
## stage only.
func _play_affordable_cards(screen: Node) -> void:
	var hand: Node = screen.get_node("%HandRow")

	for _attempt in 8:
		if screen.engine.state.is_over():
			return

		var state = screen.engine.state

		var playable: Control = null
		for card: Control in hand.get_children():
			if not (card is Button) or (card as Button).disabled:
				continue
			# Skip anything that would fill the gaffe meter. Playing every
			# card you can afford loses on gaffes rather than on the bar,
			# which would make this a test of that mistake instead of the
			# loop. A person would not do it either.
			var gaffe := int((card as CardView).card.get("gaffe", 0))
			if state.gaffe + gaffe >= state.gaffe_limit:
				continue
			playable = card
			break
		if playable == null:
			return

		# THE HAND SCROLLS SIDEWAYS now that the cards are big enough to read,
		# and only about three of five are on screen at once. A player swipes
		# to reach the rest; this has to do the same, because a click aimed at
		# a card that is scrolled out of view lands outside the scroll area and
		# opens nothing. Without this the driver silently played only the first
		# few cards of every hand.
		# The hand row's own parent, rather than a %UniqueName: the scroll
		# container is not marked unique in the scene, so looking it up by
		# name returns null and the scrolling silently never happens.
		var scroller := hand.get_parent() as ScrollContainer
		if scroller != null:
			scroller.ensure_control_visible(playable)
			await get_tree().process_frame
			await get_tree().process_frame

		await _click(playable)
		await get_tree().create_timer(0.1).timeout

		# If the zoom did not open, the card was not reachable. Say so rather
		# than clicking a hidden Play button and pretending a turn happened.
		var zoom: Control = screen.get_node("%CardZoom")
		if not zoom.visible:
			_failures.append(("a card could not be opened from the hand: it sits at %s "
				+ "and the hand shows %s") % [
					playable.get_global_rect(),
					scroller.get_global_rect() if scroller else "nowhere"])
			return

		var play_button: Button = screen.get_node("%ZoomPlay")
		if play_button.disabled:
			# Cannot afford it after all; back out rather than getting stuck.
			await _click(screen.get_node("%ZoomClose"))
			return
		await _click(play_button)
		await get_tree().create_timer(0.1).timeout


func _click(control: Control) -> void:
	await get_tree().process_frame
	var rect := control.get_global_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_failures.append("%s has no size, so nothing could click it" % control.name)
		return

	# Injected clicks are read as window coordinates while control rectangles
	# are in viewport coordinates, and the two differ: the game is drawn at
	# 1080 wide inside a 440 wide window.
	var where: Vector2 = get_viewport().get_screen_transform() * rect.get_center()

	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = where
		event.global_position = where
		Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().process_frame
