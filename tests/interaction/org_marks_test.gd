extends Node
## While a card is held, each listening organization shows its icon with a +/-/0 mark on top (review of
## P9, finding 1). In Woodblock a paper plaque once filled the whole icon, leaving only "0  0". For
## every style this builds the battle, previews a card that moves organizations, and reads the pixels
## of each marked tile: they must not be one flat colour (the icon is there), and the mark carries no
## plaque.
##
##     xvfb-run .tools/godot --path . tests/interaction/org_marks_test.tscn

const BATTLE := "res://scenes/battle/BattleScreen.tscn"

var _failures: PackedStringArray = []
var _vp: SubViewport


func _ready() -> void:
	if name != "Runner":
		var runner := Node.new()
		runner.name = "Runner"
		runner.set_script(get_script())
		get_tree().root.add_child.call_deferred(runner)
		return
	_run.call_deferred()


func _run() -> void:
	var checked := 0
	for style: String in UiStyles.ALL:
		checked += await _one(style)
	if checked == 0:
		_failures.append("no marked organization tile was checked")
	if _failures.is_empty():
		print("ORG MARKS TEST: PASS (%d tiles)" % checked)
		get_tree().quit(0)
	else:
		print("ORG MARKS TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _one(style: String) -> int:
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
	_vp = SubViewport.new()
	_vp.size = Vector2i(1080, 2340)
	_vp.disable_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var screen: Control = (load(BATTLE) as PackedScene).instantiate()
	_vp.add_child(screen)
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	(screen.get("_banner") as CueBanner).set_suppressed(true)
	var engine: BattleEngine = screen.engine
	var strip: Control = screen.get("_listening")
	var changes: Array = []
	for card_id: String in engine.state.hand:
		changes = OrgPreview.changes(engine, DataDB.get_card(card_id))
		if not changes.is_empty():
			break
	if changes.is_empty():
		_vp.queue_free()
		return 0
	strip.show()
	strip.call("preview", changes)
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	var image := _vp.get_texture().get_image()
	var checked := 0
	for tile: Dictionary in (strip.get("_tiles") as Dictionary).values():
		var mark := tile["mark"] as Label
		if not mark.visible:
			continue
		if not mark.get_theme_stylebox("normal") is StyleBoxEmpty:
			_failures.append("%s: a mark carries a plaque" % style)
		var rect := (tile["root"] as Control).get_global_rect()
		var lums: Array[float] = []
		for y in range(int(rect.position.y), int(rect.end.y), 4):
			for x in range(int(rect.position.x), int(rect.end.x), 4):
				var c := image.get_pixel(x, y)
				lums.append(0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b)
		var mean := 0.0
		for l in lums:
			mean += l
		mean /= maxf(lums.size(), 1.0)
		var variance := 0.0
		for l in lums:
			variance += (l - mean) * (l - mean)
		variance /= maxf(lums.size(), 1.0)
		if variance < 0.004:
			_failures.append("%s: a marked tile is one flat colour (the icon is hidden), variance %.4f" % [style, variance])
		checked += 1
	_vp.queue_free()
	await get_tree().process_frame
	return checked
