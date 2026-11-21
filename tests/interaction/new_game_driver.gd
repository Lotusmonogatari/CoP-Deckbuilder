class_name NewGameDriver
extends Node
## Choosing who to play, with real clicks.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/new_game_test.tscn
##
##   First launch (no save) → the Office opens on the New Game screen
##   Tap "Play as" for PC03 → the run is PC03's, the Office says their name
##   Office Management → New game → Start over → the picker again
##   Tap "Play as" for PC02 → a fresh run as PC02
##
## SaveManager is off in test runs, so this never touches a real save.

const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.awaiting_new_game = true
	get_tree().change_scene_to_file(OFFICE_SCENE)
	await get_tree().create_timer(0.8).timeout
	await _walk()

	print("")
	if _failures.is_empty():
		print("NEW GAME TEST: PASS")
		get_tree().quit(0)
	else:
		print("NEW GAME TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _walk() -> void:
	var office := get_tree().current_scene
	var panel := office.get_node("NewGamePanel") as Overlay
	if not panel.visible:
		_failures.append("the first launch did not open the New Game screen")
		return
	print("  the first launch opens the New Game screen")

	if not await _choose(panel, "PC03"):
		return
	var name := str(DataDB.get_protagonist("PC03").get("name_en"))
	if GameState.protagonist_id != "PC03" or not (office.get_node("%Title") as Label).text.contains(name):
		_failures.append("choosing PC03 did not make the run and the Office theirs")
		return
	print("  choosing a protagonist starts the run as them")

	GameState.xp = 77
	await _click(office.find_child("AdministrationButton", true, false) as Control)
	var administration := office.get_node("AdministrationMenuPanel") as Overlay
	# The Administration rows (P13, 2026-11-20) keep their node names; the text is a label inside the row.
	var new_game := administration.find_child("NewGameMenuButton", true, false) as Button
	if new_game != null and (new_game.find_child("RowLabel", true, false) as Label).text != Text.say("office.new_game"):
		new_game = null
	if new_game == null:
		_failures.append("the Administration menu has no New game button")
		return
	await _click(new_game)
	var confirm := panel.find_child("Confirm", true, false) as Button
	if not panel.visible or confirm == null or not confirm.visible:
		_failures.append("New game did not ask before starting over")
		return
	if GameState.xp != 77:
		_failures.append("New game threw the run away before it was confirmed")
		return
	await _click(confirm)
	await get_tree().create_timer(0.3).timeout
	# The two swipe strips: difficulty on one side, display theme on the other (2026-11-18).
	var spent := GameState.xp
	if panel.find_child("PressureStrip_harder", true, false) == null or panel.find_child("ThemeStrip_woodblock", true, false) == null:
		_failures.append("the New Game screen has no difficulty and theme strips")
		return
	await _click(panel.find_child("PressureStrip_harder", true, false) as Control)
	await get_tree().create_timer(0.3).timeout
	if not (panel.find_child("PressureStrip_harder", true, false) as Button).button_pressed:
		_failures.append("tapping Harder did not select it")
		return
	# A theme restyles the screen at once: the Office reloads and the New Game screen comes back.
	await _click(panel.find_child("ThemeStrip_woodblock", true, false) as Control)
	await get_tree().create_timer(1.0).timeout
	office = get_tree().current_scene
	panel = office.get_node("NewGamePanel") as Overlay
	if not panel.visible or UiStyle.current() != UiStyles.WOODBLOCK:
		_failures.append("choosing the Woodblock theme did not restyle the New Game screen and keep it open")
		return
	if not (panel.find_child("PressureStrip_harder", true, false) as Button).button_pressed:
		_failures.append("the difficulty choice was lost when the theme changed")
		return
	if not await _choose(panel, "PC02"):
		return
	if GameState.difficulty != Difficulty.HARDER:
		_failures.append("the run did not start on Harder")
		return
	var package_id := str(GameState.active_cosmetics.get(CosmeticPieces.UI_STYLE, ""))
	if UiStyle.current() != UiStyles.WOODBLOCK or package_id.is_empty() or not GameState.owned_cosmetic_packages.has(package_id):
		_failures.append("the chosen theme did not come with the new run")
		return
	if GameState.xp != BattleSetup.starting_xp_for(DataDB.get_protagonist("PC02")) or spent != 77:
		_failures.append("the chosen theme cost XP")
		return
	print("  difficulty and theme strips: both apply, the theme is free")

	# PC02's own starting_xp (the difficulty ladder, data/player.json,
	# 2026-09-25) rather than a bare 0 — "fresh run" means PC02's real
	# starting numbers, not that every protagonist starts at zero.
	if GameState.protagonist_id != "PC02" \
			or GameState.xp != BattleSetup.starting_xp_for(DataDB.get_protagonist("PC02")):
		_failures.append("starting over did not begin a fresh run as PC02")
		return
	print("  New game asks first, then starts a fresh run")


func _choose(panel: Overlay, player_id: String) -> bool:
	await get_tree().create_timer(0.2).timeout
	# The mock-up flow (P14b, 2026-11-21): tap the champion's portrait, then Play as in the foot.
	var pick := panel.find_child("Pick_" + player_id, true, false)
	if pick == null:
		_failures.append("the New Game screen does not list %s" % player_id)
		return false
	await _click(pick as Control)
	await get_tree().create_timer(0.3).timeout   # the screen is redrawn for the picked champion
	var play := panel.find_child("PlayAsButton", true, false)
	if play == null or not (panel.find_child("Protagonist_" + player_id, true, false) != null):
		_failures.append("tapping %s did not show their card and the Play as button" % player_id)
		return false
	await _click(play as Control)
	if panel.visible:
		_failures.append("choosing %s did not close the New Game screen" % player_id)
		return false
	return true


func _button_with_text(root: Node, text: String) -> Control:
	for node in root.find_children("", "Button", true, false):
		if (node as Button).text == text:
			return node as Control
	return null


func _click(control: Control) -> void:
	if control == null:
		_failures.append("a button this test needed does not exist")
		return
	await get_tree().process_frame
	var parent := control.get_parent()
	while parent != null and not (parent is ScrollContainer):
		parent = parent.get_parent()
	if parent is ScrollContainer:
		(parent as ScrollContainer).ensure_control_visible(control)
		await get_tree().process_frame
		await get_tree().process_frame
	var where: Vector2 = get_viewport().get_screen_transform() * control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = where
		event.global_position = where
		Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().create_timer(0.15).timeout


## The New Game panel now opens with the Campaign Pressure buttons above the
## protagonists, so a row can sit below the fold, as it does for a player.
func _scroll_into_view(panel: Node, row: Node) -> void:
	var node: Node = row
	while node != null and node != panel:
		node = node.get_parent()
		if node is ScrollContainer:
			(node as ScrollContainer).ensure_control_visible(row as Control)
			return
