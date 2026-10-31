class_name MarketTabsDriver
extends Node
## The Marketplace's two tabs (Cameron, 2026-10-31), with real clicks:
##
##   Office → Marketplace opens on Personal Inventory: a Personal item is for
##   sale, an Office item is not, and a held Office item is not in the strip.
##   Office Inventory tab → the Office item is for sale and in the strip, the
##   Personal item is not. Personal Inventory tab → back again.
##
## Which items are which comes from the Shop tab's Inventory column.

const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _first(tab: String) -> String:
	for item: Dictionary in DataDB.shop:
		if item.get("card_tier") == null and str(item.get("in_marketplace", "")).strip_edges().to_lower() != "no" \
				and Items.inventory_tab(item) == tab:
			return str(item["item_id"])
	return ""


func _run() -> void:
	GameState.xp = 10000
	GameState.meta["Funds"] = 900000
	var personal := _first(Items.PERSONAL)
	var office_item := _first(Items.OFFICE_INVENTORY)
	GameState.inventory = {personal: 1, office_item: 1}
	get_tree().change_scene_to_file(OFFICE_SCENE)
	await get_tree().process_frame
	await _wait(0.6)

	var office := get_tree().current_scene
	await _click(office.find_child("InventoryButton", true, false) as Control)
	var panel := office.get_node("InventoryPanel") as InventoryPanel
	_check(panel, personal, office_item, "Personal Inventory (opening tab)")
	await _click(panel.find_child("OfficeTab", true, false) as Control)
	_check(panel, office_item, personal, "Office Inventory")
	await _click(panel.find_child("PersonalTab", true, false) as Control)
	_check(panel, personal, office_item, "Personal Inventory (back)")

	print("")
	if _failures.is_empty():
		print("MARKET TABS TEST: PASS")
		get_tree().quit(0)
	else:
		print("MARKET TABS TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _check(panel: Node, shown: String, hidden: String, where: String) -> void:
	if panel.find_child("Supply_" + shown, true, false) == null:
		_failures.append("%s does not sell %s" % [where, shown])
	if panel.find_child("Supply_" + hidden, true, false) != null:
		_failures.append("%s sells %s, which belongs on the other tab" % [where, hidden])
	if panel.find_child("Item_" + shown, true, false) == null:
		_failures.append("%s does not show the held %s" % [where, shown])
	if panel.find_child("Item_" + hidden, true, false) != null:
		_failures.append("%s shows the held %s, which belongs on the other tab" % [where, hidden])
	print("  checked " + where)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _click(control: Control) -> void:
	if control == null:
		_failures.append("a button this test needed does not exist")
		return
	await get_tree().process_frame
	# Overlay content scrolls; bring the target into view the way a player
	# would by scrolling, or a click aimed at it lands somewhere else.
	# Every scroller on the way up (the item strip scrolls sideways inside
	# the panel, which scrolls down), not just the nearest.
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			(parent as ScrollContainer).ensure_control_visible(control)
			await get_tree().process_frame
			await get_tree().process_frame
		parent = parent.get_parent()

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
