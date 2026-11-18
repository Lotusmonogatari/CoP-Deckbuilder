extends Node
## The Promises button stays where its style puts it (2026-11-18 playtest). In Broadcast and Woodblock it
## is a tile in the grid of destinations; in Living Office it is a pin in the room. The Office re-fits
## its page whenever the content above changes height (a longer report line after buying the Funds cap
## increase, a larger text size), and that re-fit used to write a bottom offset meant for the old corner
## spot: the tile jumped up over the End of Week Payments box.
##
## For each style the Office is built with one open promise, then re-fitted in the ways that happen in
## play, and the button must not move from where it was first placed.
##
##     xvfb-run .tools/godot --path . tests/interaction/promises_placement_test.tscn

const OFFICE := "res://scenes/office_hours/OfficeScreen.tscn"
const TOLERANCE := 1.0

var _failures: PackedStringArray = []


func _ready() -> void:
	# The scene changes below replace the current scene, so the test lives on the root.
	if name != "Runner":
		var runner := Node.new()
		runner.name = "Runner"
		runner.set_script(get_script())
		get_tree().root.add_child.call_deferred(runner)
		return
	_run.call_deferred()


func _run() -> void:
	for style: String in UiStyles.ALL:
		await _check_style(style)
	if _failures.is_empty():
		print("PROMISES PLACEMENT TEST: PASS")
		get_tree().quit(0)
	else:
		print("PROMISES PLACEMENT TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _check_style(style: String) -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.calendar = WeekCalendar.fresh()
	GameState.promises.append({"id": "P1", "kind": Promises.PROMISE_ITEM, "item_id": "SH01", "hours": 0,
		"funds": 0, "due_at": 100000, "made_at": 0, "for_org": "", "source": "test"})
	var package := UiStyles.package_for(style, DataDB.cosmetic_packages)
	if not package.is_empty():
		GameState.owned_cosmetic_packages.append(str(package["package_id"]))
		GameState.equip_cosmetic(CosmeticPieces.UI_STYLE, str(package["package_id"]))
	UiStyle.forget()
	Layout.apply_ui_style()
	get_tree().change_scene_to_file(OFFICE)
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	var office := get_tree().current_scene
	var button := office.find_child("PromisesButton", true, false) as Button
	if button == null or not button.visible:
		_failures.append("%s: the Office shows no Promises button" % style)
		return
	await get_tree().create_timer(0.3).timeout
	var home := button.get_global_rect()
	# The grid styles: the button is a tile in the grid of destinations, level with its row.
	var grid := office.find_child("StyleTiles", true, false) as Control
	if grid != null:
		_expect(grid.get_global_rect().grow(TOLERANCE).encloses(home), "%s: the Promises button is inside the grid of destinations" % style)

	# Living Office: the pin keeps the place the room layout gave it (centred on its anchor).
	if style == UiStyles.LIVING_OFFICE:
		_expect(is_equal_approx(button.offset_bottom, RoomObjects.PIN_SIZE.y * 0.5),
			"%s: the Promises pin sits on its place in the room (bottom offset %s)" % [style, button.offset_bottom])

	# What the return from the Marketplace does: the report gains a line, so the page re-fits.
	var report := office.find_child("Report", true, false) as Label
	report.text = "A line more.\n" + report.text
	await get_tree().create_timer(0.6).timeout
	_expect_unmoved(button, home, "%s: after the report grows a line" % style)

	# The compact layout (a short screen or a large text size) and the plain re-fit.
	office._set_compact(true)
	await get_tree().create_timer(0.4).timeout
	_expect_unmoved(button, home, "%s: in the compact layout" % style)
	office._set_compact(false)
	office._fit_portrait()
	await get_tree().create_timer(0.4).timeout
	_expect_unmoved(button, home, "%s: after a plain re-fit" % style)


## Compact mode may change the box sizes around the button; what must hold is that the button did not
## leave its own column. Its horizontal place is fixed and its top stays with its row.
func _expect_unmoved(button: Button, home: Rect2, what: String) -> void:
	var now := button.get_global_rect()
	_expect(absf(now.position.x - home.position.x) <= TOLERANCE and absf(now.position.y - home.position.y) <= TOLERANCE,
		"%s, the Promises button stayed put (was %s, is %s)" % [what, home.position, now.position])


func _expect(ok: bool, what: String) -> void:
	print(("  ok  " if ok else "  X   ") + what)
	if not ok:
		_failures.append(what)
