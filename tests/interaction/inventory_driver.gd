class_name InventoryDriver
extends Node
## Walks the inventory with real clicks (design/proposals/inventory.md):
##
##   Office → Office Management → Supplies → buy two Coffees
##   Office → Inventory → Coffee → Use     (queued for the next stage)
##   Office → Inventory → Host National Booster Dinner → Use → pick a booster
##                                                     (lands on that one only)
##   Start a level → the first stage starts with +1 energy per turn
##   Battle → Inventory → Coffee → Use     (lands now, +1 energy)
##
## Every press goes through the input system, the same as loop_driver.gd, so
## a button that is hidden, off-screen or under another panel fails here the
## way it would fail a player. Lives outside the current scene for the same
## reason loop_driver.gd does: it has to survive the scene change into battle.

const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"
const COFFEE := "SH04"
const DINNER := "SH25"   # Player Choice, "TIER:National +2"

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.xp = 10000
	GameState.meta["Funds"] = 900000
	GameState.inventory = {}
	GameState.pending_stage_bonuses = {}

	get_tree().change_scene_to_file(OFFICE_SCENE)
	await get_tree().process_frame
	await _wait(0.6)

	await _walk()

	print("")
	if _failures.is_empty():
		print("INVENTORY TEST: PASS")
		get_tree().quit(0)
	else:
		print("INVENTORY TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _walk() -> void:
	var office := get_tree().current_scene

	# --- Supplies: buy two Coffees -------------------------------------------
	await _click(office.get_node("%ManagementButton"))
	var management := office.get_node("%ManagementPanel") as Overlay
	var supplies_door := _button_with_text(management, Text.say("shop.supplies"))
	if supplies_door == null:
		_failures.append("Office Management has no Supplies button")
		return
	await _click(supplies_door)

	var supplies := office.get_node("SuppliesPanel") as Overlay
	if not supplies.visible:
		_failures.append("the Supplies button did not open the Supplies shop")
		return
	for _i in 2:
		var buy := supplies.find_child("Supply_" + COFFEE, true, false)
		if buy == null:
			_failures.append("the Supplies shop does not list Coffee")
			return
		var buy_button := buy.find_child("Buy", true, false) as Button
		await _click(buy_button)
	if GameState.item_count(COFFEE) != 2:
		_failures.append("two Buy presses left %d Coffees, not 2" % GameState.item_count(COFFEE))
		return
	print("  bought two Coffees in Supplies")

	# A long list is dragged, not hunted through: a drag that starts on a Buy
	# button scrolls the shop and buys nothing.
	var scroll := supplies.get_node("Margin/Scroll") as ScrollContainer
	var funds_before := int(GameState.meta.get("Funds", 0))
	scroll.scroll_vertical = 0
	await get_tree().process_frame
	var start := (supplies.find_child("Supply_" + COFFEE, true, false)
		.find_child("Buy", true, false) as Control).get_global_rect().get_center()
	await _drag(start, start + Vector2(0, -700))
	await _wait(0.5)
	if scroll.scroll_vertical <= 0:
		_failures.append("dragging the Supplies list did not scroll it")
		return
	if GameState.item_count(COFFEE) != 2 or int(GameState.meta.get("Funds", 0)) != funds_before:
		_failures.append("dragging the Supplies list also bought something")
		return
	print("  dragging the Supplies list scrolls it and buys nothing")
	supplies.close()
	await _wait(0.2)

	# --- Inventory in the Office: use one, for the next stage ----------------
	await _click(office.find_child("InventoryButton", true, false) as Control)
	var inventory := office.get_node("InventoryPanel") as InventoryPanel
	if not await _use_from(inventory, "the Office"):
		return
	if int(GameState.pending_stage_bonuses.get("ENERGY", 0)) != 1:
		_failures.append("using Coffee in the Office did not queue +1 energy for the next stage")
		return
	print("  used a Coffee in the Office; it waits for the next stage")
	inventory.close()
	await _wait(0.2)

	# --- Player Choice item: pick a booster from the picker -------------------
	if not await _walk_choice_picker(office):
		return

	# --- Into the first level ------------------------------------------------
	await _click(office.get_node("%StartButton"))
	var levels := office.get_node("%LevelsPanel") as Overlay
	var look := _button_with_text(levels, Text.say("office.look_it_over"))
	if look == null:
		_failures.append("no level could be chosen")
		return
	await _click(look)
	await _click(office.get_node("%BriefingPanel").find_child("Confirm", true, false) as Control)
	await _wait(0.6)

	var battle := get_tree().current_scene
	if battle.name != "BattleScreen":
		_failures.append("the briefing did not open a stage")
		return
	var stage_energy := int(GameState.level_runner.current_stage().get("energy_per_turn", 3))
	if battle.engine.state.energy_per_turn != stage_energy + 1:
		_failures.append("the first stage has %d energy per turn, not the stage's %d plus the Coffee"
			% [battle.engine.state.energy_per_turn, stage_energy])
		return
	print("  the first stage opened with +1 energy per turn from the Coffee")

	# --- Inventory mid-stage: use the second one now -------------------------
	var energy_before: int = battle.engine.state.energy
	await _click(battle.find_child("InventoryButton", true, false) as Control)
	var battle_inventory := battle.get_node("InventoryPanel") as InventoryPanel
	if not await _use_from(battle_inventory, "the stage"):
		return
	if battle.engine.state.energy != energy_before + 1:
		_failures.append("using Coffee mid-stage did not add 1 energy now")
		return
	if GameState.item_count(COFFEE) != 0:
		_failures.append("both Coffees used, but %d still held" % GameState.item_count(COFFEE))
		return
	print("  used the second Coffee mid-stage; +1 energy now")
	battle_inventory.close()
	GameState.end_level()


## Gives the player a Host National Booster Dinner, opens it from the Office
## inventory, presses Use (which — Items.is_player_choice() — opens the
## picker instead of using it right away), picks one specific National
## booster, and confirms only that booster moved.
func _walk_choice_picker(office: Node) -> bool:
	GameState.inventory[DINNER] = 1
	var national := DataDB.boosters_for_tier("National")
	if national.size() < 2:
		_failures.append("National needs at least 2 boosters for this test to mean anything")
		return false
	var chosen_id := str(national[0].get("booster_id"))
	var other_id := str(national[1].get("booster_id"))
	GameState.booster_standing[chosen_id] = 50
	GameState.booster_standing[other_id] = 50

	await _click(office.find_child("InventoryButton", true, false) as Control)
	var inventory := office.get_node("InventoryPanel") as InventoryPanel
	if not inventory.visible:
		_failures.append("the Inventory button did not reopen the inventory")
		return false
	var icon := inventory.find_child("Item_" + DINNER, true, false) as Control
	if icon == null:
		_failures.append("the inventory does not show the Booster Dinner")
		return false
	await _click(icon)
	var use := inventory.find_child("Confirm", true, false) as Button
	if use == null or not use.visible:
		_failures.append("the Booster Dinner pop-up has no Use button")
		return false
	await _click(use)

	var choice := inventory.find_child("Choice_" + chosen_id, true, false) as Button
	if choice == null:
		_failures.append("pressing Use did not open a picker with the chosen booster in it")
		return false
	if GameState.item_count(DINNER) != 1:
		_failures.append("opening the picker already consumed the item, before a choice was made")
		return false
	await _click(choice)

	if GameState.item_count(DINNER) != 0:
		_failures.append("choosing a booster did not use the Booster Dinner")
		return false
	if int(GameState.booster_standing[chosen_id]) != 52:
		_failures.append("the chosen booster did not gain the Dinner's +2")
		return false
	if int(GameState.booster_standing[other_id]) != 50:
		_failures.append("a booster nobody picked moved anyway")
		return false
	print("  used the Booster Dinner; the chosen booster (only) gained +2")
	inventory.close()
	await _wait(0.2)
	return true


## Opens Coffee's pop-up from an open inventory and presses Use.
func _use_from(inventory: InventoryPanel, where: String) -> bool:
	await _wait(0.2)
	if not inventory.visible:
		_failures.append("the Inventory button in %s did not open the inventory" % where)
		return false
	var icon := inventory.find_child("Item_" + COFFEE, true, false) as Control
	if icon == null:
		_failures.append("the inventory in %s does not show the Coffee" % where)
		return false
	var held := GameState.item_count(COFFEE)
	await _click(icon)
	var use := inventory.find_child("Confirm", true, false) as Button
	if use == null or not use.visible:
		_failures.append("the Coffee pop-up in %s has no Use button" % where)
		return false
	await _click(use)
	if GameState.item_count(COFFEE) != held - 1:
		_failures.append("pressing Use in %s did not take a Coffee" % where)
		return false
	return true


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


func _button_with_text(root: Node, text: String) -> Control:
	for node in root.find_children("", "Button", true, false):
		if (node as Button).text == text:
			return node as Control
	return null


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _click(control: Control) -> void:
	if control == null:
		_failures.append("a button this test needed does not exist")
		return
	await get_tree().process_frame
	# Overlay content scrolls; bring the target into view the way a player
	# would by scrolling, or a click aimed at it lands somewhere else.
	var parent := control.get_parent()
	while parent != null and not (parent is ScrollContainer):
		parent = parent.get_parent()
	if parent is ScrollContainer:
		(parent as ScrollContainer).ensure_control_visible(control)
		await get_tree().process_frame
		await get_tree().process_frame

	var rect := control.get_global_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_failures.append("%s has no size, so nothing could click it" % control.name)
		return
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
	await _wait(0.1)
