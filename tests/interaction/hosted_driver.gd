class_name HostedDriver
extends Node
## Real clicks through a hosted dinner (2026-10-23): the Marketplace, the Booster
## Dinner, choosing the Chamber of Commerce, three picks for the menu, a
## topic, a promise, the guests' reactions after each, and the result.

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.inventory["SH19"] = 1
	get_tree().change_scene_to_file("res://scenes/office_hours/OfficeScreen.tscn")
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	await _dinner()
	print("")
	if _failures.is_empty():
		print("HOSTED TEST: PASS")
		get_tree().quit(0)
	else:
		print("HOSTED TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _screen() -> Node:
	return get_tree().current_scene


func _dinner() -> void:
	var screen := _screen()
	(screen.find_child("InventoryButton", true, false) as Button).pressed.emit()
	await _frames()
	var inventory := screen.get_node("InventoryPanel") as InventoryPanel
	var icon := inventory.find_child("Item_SH19", true, false) as Button
	_expect(icon != null, "the Marketplace holds the dinner")
	if icon == null:
		return
	icon.pressed.emit()
	await _frames()
	(inventory.find_child("Confirm", true, false) as Button).pressed.emit()
	await _frames()
	var chamber := inventory.find_child("Choice_BO05", true, false) as Button
	_expect(chamber != null, "the picker offers the Chamber of Commerce")
	if chamber == null:
		return
	chamber.pressed.emit()
	await get_tree().create_timer(0.5).timeout
	var panel := screen.get_node("HostedEventPanel") as HostedEventPanel
	_expect(panel.visible, "the dinner opens its own screens")
	_expect(panel.find_child("Picture", true, false) != null, "with the dining room picture")
	_expect(GameState.booster_standing["BO05"] == 30 or int(GameState.booster_standing["BO05"]) == int(DataDB.get_booster("BO05").get("starting_standing", 30)), "choosing alone moves nothing")
	_save_shot("hosted_menu")
	# Step 1: three menu picks (entree, drink, side), then reactions.
	for i in 3:
		_expect(await _pick_first(panel), "a menu choice %d is offered" % (i + 1))
	_save_shot("hosted_reactions")
	_expect(await _next(panel), "the reactions have a Next button")
	# Step 2 and 3: one pick each, each followed by reactions.
	_expect(await _pick_first(panel), "a topic is offered")
	_expect(await _next(panel), "reactions after the topic")
	_expect(await _pick_first(panel), "a promise is offered")
	_expect(await _next(panel), "reactions after the promise lead to the result")
	var done := panel.find_child("HostedDoneButton", true, false) as Button
	_expect(done != null, "the result has a Continue button")
	_save_shot("hosted_result")
	_expect(GameState.hosted_session.is_empty(), "the evening ended")
	_expect(int(GameState.calendar["hours"]) == 4, "it took 4 hours, got %d" % int(GameState.calendar["hours"]))
	if done != null:
		done.pressed.emit()
	await _frames()
	_expect(not panel.visible, "Continue closes it")


func _pick_first(panel: Node) -> bool:
	var button := _first_with_prefix(panel, "HostedOption_")
	if button == null:
		return false
	button.pressed.emit()
	await _frames()
	return true


func _next(panel: Node) -> bool:
	var button := panel.find_child("HostedNextButton", true, false) as Button
	if button == null:
		return false
	button.pressed.emit()
	await _frames()
	return true


func _first_with_prefix(root: Node, prefix: String) -> Button:
	if root is Button and root.name.begins_with(prefix) and (root as Button).visible:
		return root as Button
	for child in root.get_children():
		var found := _first_with_prefix(child, prefix)
		if found != null:
			return found
	return null


func _frames() -> void:
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout


func _save_shot(name: String) -> void:
	DirAccess.make_dir_recursive_absolute("user://shots")
	get_viewport().get_texture().get_image().save_png("user://shots/%s.png" % name)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)
