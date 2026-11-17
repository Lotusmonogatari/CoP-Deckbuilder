extends Node
## A touched card in the overlapped hand rises over its neighbours so its whole face and name can be read
## (review of P9, finding 3), and settles back when the finger lifts. Checked in every style on a hand of
## six, built on the real battle screen.
##
##     xvfb-run .tools/godot --path . tests/interaction/hand_raise_test.tscn

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
	for style: String in UiStyles.ALL:
		await _one(style)
	if _failures.is_empty():
		print("HAND RAISE TEST: PASS")
		get_tree().quit(0)
	else:
		print("HAND RAISE TEST: FAIL")
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
	var vp := SubViewport.new()
	vp.size = Vector2i(1080, 2340)
	vp.disable_3d = true
	add_child(vp)
	var screen: Control = (load(BATTLE) as PackedScene).instantiate()
	vp.add_child(screen)
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	var ids: Array[String] = []
	for row: Dictionary in DataDB.cards:
		ids.append(str(row["card_id"]))
		if ids.size() == 6:
			break
	screen.engine.state.hand = ids
	screen._refresh()
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	var row := screen.find_child("HandRow", true, false) as HBoxContainer
	var views: Array[CardView] = []
	for child in row.get_children():
		if child is CardView:
			views.append(child)
	if views.size() < 4:
		_failures.append("%s: the hand has %d cards" % [style, views.size()])
		vp.queue_free()
		return
	var target := views[1]
	var resting := target.get_global_rect()
	var neighbour_top := views[2].get_global_rect().position.y
	target.button_down.emit()
	await get_tree().process_frame
	var raised := target.get_global_rect()
	if resting.position.y - raised.position.y < 30.0:
		_failures.append("%s: the touched card rose only %d px" % [style, int(resting.position.y - raised.position.y)])
	if raised.position.y >= neighbour_top - 30.0:
		_failures.append("%s: the touched card is not above its neighbour" % style)
	if target.z_index <= views[2].z_index:
		_failures.append("%s: the touched card is not drawn over its neighbour" % style)
	target.button_up.emit()
	await get_tree().process_frame
	if absf(target.get_global_rect().position.y - resting.position.y) > 1.0:
		_failures.append("%s: the card did not settle back" % style)
	vp.queue_free()
	await get_tree().process_frame
