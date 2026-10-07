class_name OfficeMenusDriver
extends Node
## The Office's two intermediary menus, with real clicks (2026-10-06):
## "Reputation and Results" holds Important Stakeholders, Boosters and Your Record;
## "Administration" holds Appearance and Music and How to Play. The Office's
## own button row no longer shows those four directly, each button opens the
## panel it always did ON TOP of its menu, and Back returns to the menu.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/office_menus_test.tscn

const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveManager.delete_save()
	GameState.start_new_run("PC02")
	get_tree().change_scene_to_file(OFFICE_SCENE)
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout

	await _walk()

	SaveManager.delete_save()
	print("")
	if _failures.is_empty():
		print("OFFICE MENUS TEST: PASS")
		get_tree().quit(0)
	else:
		print("OFFICE MENUS TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _walk() -> void:
	var office := get_tree().current_scene

	# The row itself: the two menu buttons are there, the four they replaced are not.
	for name in ["ReputationButton", "AdministrationButton", "ManagementButton", "InventoryButton"]:
		if office.find_child(name, true, false) == null:
			_failures.append("the Office has no %s" % name)
			return
	for name in ["OrganisationsButton", "BackingButton", "RecordButton", "CosmeticsButton", "HowToPlayButton"]:
		if office.find_child(name, true, false) != null:
			_failures.append("%s is still loose in the Office instead of inside a menu" % name)
	var reputation := office.find_child("ReputationButton", true, false) as Button
	var administration := office.find_child("AdministrationButton", true, false) as Button
	if reputation.text != Text.say("office.reputation_and_results"):
		_failures.append("the Reputation button reads '%s'" % reputation.text)
	if administration.text != Text.say("office.administration"):
		_failures.append("the Administration button reads '%s'" % administration.text)
	print("  the Office row has Reputation and Results and Administration")

	await _menu(office, "ReputationButton", "ReputationMenuPanel",
		[["OrganisationsButton", "OrganisationsPanel"], ["BackingButton", "BackingPanel"],
		["RecordButton", "RecordPanel"]])
	await _menu(office, "AdministrationButton", "AdministrationMenuPanel",
		[["CosmeticsButton", "CosmeticsPanel"], ["HowToPlayButton", "HowToPlayPanel"]])


## Opens a menu, checks it holds the right buttons, then opens each in turn:
## the panel must show ON TOP of the menu, and Back must land on the menu.
func _menu(office: Node, menu_button: String, menu_name: String, entries: Array) -> void:
	await _click(office.find_child(menu_button, true, false) as Control)
	await get_tree().create_timer(0.3).timeout
	var menu := office.get_node(menu_name) as Overlay
	if menu == null or not menu.visible:
		_failures.append("%s did not open %s" % [menu_button, menu_name])
		return
	print("  %s opened %s" % [menu_button, menu_name])

	for entry: Array in entries:
		var button := menu.find_child(entry[0], true, false) as Control
		if button == null:
			_failures.append("%s has no %s" % [menu_name, entry[0]])
			continue
		await _click(button)
		await get_tree().create_timer(0.3).timeout
		var panel := office.get_node(entry[1]) as Overlay
		if panel == null or not panel.visible:
			_failures.append("%s did not open %s" % [entry[0], entry[1]])
			continue
		if panel.get_index() < menu.get_index():
			_failures.append("%s opened UNDER its menu" % entry[1])
		print("  %s opened %s on top of the menu" % [entry[0], entry[1]])

		await _click_back(panel)
		if panel.visible:
			_failures.append("Back did not close %s" % entry[1])
		elif not menu.visible:
			_failures.append("closing %s also closed its menu" % entry[1])
		else:
			print("  Back from %s returned to the menu" % entry[1])

	await _click_back(menu)
	if menu.visible:
		_failures.append("Back did not close %s" % menu_name)


## Scroll Back into view the way a player would (a long panel keeps it below
## the fold), then click it.
func _click_back(panel: Overlay) -> void:
	var back := panel.find_child("Back", true, false) as Control
	var scroll := panel.find_child("Scroll", true, false) as ScrollContainer
	if back != null and scroll != null:
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
		await get_tree().process_frame
		await get_tree().process_frame
	await _click(back)
	await get_tree().create_timer(0.2).timeout


func _click(control: Control) -> void:
	if control == null:
		_failures.append("a button this test needed does not exist")
		return
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
