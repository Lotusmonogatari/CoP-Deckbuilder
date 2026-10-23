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
	for name in ["OrganisationsButton", "BackingButton", "PartiesButton", "RecordButton", "CosmeticsButton", "HowToPlayButton"]:
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
		["PartiesButton", "PartiesPanel"], ["ElectionButton", "ElectionPanel"],
		["RecordButton", "RecordPanel"]])
	await _menu(office, "AdministrationButton", "AdministrationMenuPanel",
		[["CosmeticsButton", "CosmeticsPanel"], ["HowToPlayButton", "HowToPlayPanel"]])
	await _check_election_page(office)
	await _check_allies_popup(office)
	await _check_text_size(office)
	_check_backing_prices(office)


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


## The Parties page's "See allies and rivals" popup: opens on top, shows bars
## and favorability tags, allies in the party's colour and rivals in white.
func _check_allies_popup(office: Node) -> void:
	await _click(office.find_child("ReputationButton", true, false) as Control)
	await get_tree().create_timer(0.3).timeout
	var menu := office.get_node("ReputationMenuPanel") as Overlay
	await _click(menu.find_child("PartiesButton", true, false) as Control)
	await get_tree().create_timer(0.3).timeout
	var parties := office.get_node("PartiesPanel") as Overlay
	var party: Dictionary = DataDB.parties[0]
	var button := parties.find_child("AlliesButton_" + str(party["party_id"]), true, false) as Control
	if button == null:
		_failures.append("the Parties page has no allies button")
		return
	(parties.find_child("Scroll", true, false) as ScrollContainer).ensure_control_visible(button)
	await _click(button)
	await get_tree().create_timer(0.3).timeout
	var popup := office.get_node("PartyDetailPanel") as Overlay
	if not popup.visible or popup.get_index() < parties.get_index():
		_failures.append("the allies popup did not open on top of the Parties page")
		return
	var tags := [Text.say("party_opinion.tag_improving"), Text.say("party_opinion.tag_neutral"),
		Text.say("party_opinion.tag_reducing")]
	var tag_count := 0
	for label: Label in popup.find_children("*", "Label", true, false):
		if label.text in tags:
			tag_count += 1
	var bars := popup.find_children("*", "ProgressBar", true, false)
	if bars.is_empty() or tag_count != bars.size():
		_failures.append("the popup has %d bars and %d tags (should match, and not be zero)" % [bars.size(), tag_count])
	var want := PartyDisplay.color_for(party)
	var ally_colours := 0
	for bar: ProgressBar in bars:
		var fill := (bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color
		if fill == want:
			ally_colours += 1
		elif fill != Color.WHITE:
			_failures.append("a bar is neither the party colour nor white")
	if ally_colours == 0:
		_failures.append("no ally bar is in the party's colour")
	print("  allies popup: %d bars, %d in the party colour" % [bars.size(), ally_colours])
	await _click_back(popup)
	await _click_back(parties)
	await _click_back(menu)


## The Administration menu's text-size button: one tap cycles Small, Normal,
## Large, the label follows, and the theme's real font size changes.
func _check_text_size(office: Node) -> void:
	await _click(office.find_child("AdministrationButton", true, false) as Control)
	await get_tree().create_timer(0.3).timeout
	var menu := office.get_node("AdministrationMenuPanel") as Overlay
	var normal_size := ThemeDB.get_project_theme().default_font_size
	var seen: Array[int] = []
	for tap in 3:
		var button := menu.find_child("TextSizeButton", true, false) as Control
		if button == null:
			_failures.append("the Administration menu has no TextSizeButton")
			return
		await _click(button)
		await get_tree().create_timer(0.3).timeout
		seen.append(ThemeDB.get_project_theme().default_font_size)
	# normal -> large -> small -> normal
	if seen[0] <= normal_size or seen[1] >= normal_size or seen[2] != normal_size:
		_failures.append("text size did not go Large, Small, Normal (sizes %s from %d)" % [str(seen), normal_size])
	else:
		print("  text size button: Large %d, Small %d, back to %d" % [seen[0], seen[1], seen[2]])
	await _click_back(menu)


## Prices of four digits or more read with a comma ("25,000 Funds"), never as a
## bare run of digits, and no backing shows the typed-in word "free".
func _check_backing_prices(office: Node) -> void:
	office._show_backing()
	var panel := office.get_node("BackingPanel") as Overlay
	var bare := RegEx.new()
	bare.compile("(?<![0-9,])[0-9]{4,}(?![0-9,])")
	var seen_comma := false
	var stack: Array[Node] = [panel]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		var text := ""
		if node is Label:
			text = (node as Label).text
		elif node is Button:
			text = (node as Button).text
		if text.is_empty():
			continue
		if bare.search(text) != null:
			_failures.append("a backing line has an unseparated number: '%s'" % text)
		if text.contains(",") and text.contains("Funds"):
			seen_comma = true
	if not seen_comma:
		_failures.append("no backing price shows a comma (expected e.g. 25,000 Funds)")
	else:
		print("  backing prices are written with thousands separators")
	panel.hide()


## The Election Strength page (2026-10-23): three bars (strength and the two
## awareness meters) in the player's party colour, and no bar left on the Office.
func _check_election_page(office: Node) -> void:
	if office.find_child("ElectionBar", true, false) != null:
		_failures.append("the Office still carries an election bar")
	await _click(office.find_child("ReputationButton", true, false) as Control)
	await get_tree().create_timer(0.3).timeout
	await _click(office.find_child("ElectionButton", true, false) as Control)
	await get_tree().create_timer(0.3).timeout
	var panel := office.find_child("ElectionPanel", true, false) as Control
	var bars: Array[Node] = panel.find_children("*", "ProgressBar", true, false)
	if bars.size() != 3:
		_failures.append("the Election Strength page has %d bars, not 3" % bars.size())
	var party := DataDB.get_party(str(DataDB.player.get("party", "")))
	var want := PartyDisplay.color_for(party)
	for bar: Node in bars:
		var fill := (bar as ProgressBar).get_theme_stylebox("fill") as StyleBoxFlat
		if fill == null or not fill.bg_color.is_equal_approx(want):
			_failures.append("an election bar is not in the party colour")
	DirAccess.make_dir_recursive_absolute("user://shots")
	get_viewport().get_texture().get_image().save_png("user://shots/election_page.png")
	print("  the Election Strength page shows three party-coloured bars")
	await _click_back(panel as Overlay)
	await _click_back(office.find_child("ReputationMenuPanel", true, false) as Overlay)
