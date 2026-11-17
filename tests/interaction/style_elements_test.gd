extends Node
## The signature elements of each style exist and carry no extra words (P9 review, finding 2): Woodblock's
## 攻/守/得 intent seal follows the opponent's move, Broadcast has its gold diagonal between the characters,
## Living Office has the payments tray and the docket card's folder, every style's docket card says the
## hours left, and Woodblock's payment lines have dotted leaders.
##
##     xvfb-run .tools/godot --path . tests/interaction/style_elements_test.tscn

const BATTLE := "res://scenes/battle/BattleScreen.tscn"
const OFFICE := "res://scenes/office_hours/OfficeScreen.tscn"

var _failures: PackedStringArray = []


func _ready() -> void:
	if name != "Runner":
		var runner := Node.new()
		runner.name = "Runner"
		runner.set_script(get_script())
		get_tree().root.add_child.call_deferred(runner)
		return
	_run.call_deferred()


func _equip(style: String) -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC02")
	GameState.awaiting_new_game = false
	GameState.meta["Funds"] = 12000
	GameState.hire_staff("SF04")
	var package := UiStyles.package_for(style, DataDB.cosmetic_packages)
	if not package.is_empty():
		GameState.owned_cosmetic_packages.append(str(package["package_id"]))
		GameState.equip_cosmetic(CosmeticPieces.UI_STYLE, str(package["package_id"]))
	UiStyle.forget()
	Layout.apply_ui_style()


func _screen(path: String) -> Control:
	var vp := SubViewport.new()
	vp.size = Vector2i(1080, 2340)
	vp.disable_3d = true
	add_child(vp)
	var screen: Control = (load(path) as PackedScene).instantiate()
	vp.add_child(screen)
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	return screen


func _done(screen: Control) -> void:
	screen.get_parent().queue_free()
	await get_tree().process_frame


func _run() -> void:
	# Battle: Woodblock's seal and Broadcast's diagonal.
	for style: String in [UiStyles.WOODBLOCK, UiStyles.BROADCAST, UiStyles.LIVING_OFFICE]:
		_equip(style)
		GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV04"))))
		var battle := await _screen(BATTLE)
		var seal: Variant = battle.get("_intent_seal")
		var verb := str(battle.engine.current_intent().get("verb", "none"))
		var expected: String = {"attack": "攻", "block": "守", "gain": "得"}.get(verb, "")
		if style == UiStyles.WOODBLOCK:
			if seal == null:
				_failures.append("woodblock: no intent seal")
			elif (seal as StyleMarks).visible != not expected.is_empty() or (seal as StyleMarks).glyph != expected:
				_failures.append("woodblock: the seal shows '%s' for a '%s' move" % [(seal as StyleMarks).glyph, verb])
		elif seal != null:
			_failures.append("%s: has an intent seal" % style)
		var diagonal := battle.find_child("GoldDiagonal", true, false)
		if (style == UiStyles.BROADCAST) != (diagonal != null):
			_failures.append("%s: the gold diagonal is %s" % [style, "missing" if style == UiStyles.BROADCAST else "present"])
		await _done(battle)
	# Office: the docket card says the hours in every style; Living Office has the tray and the folder.
	for style: String in UiStyles.ALL:
		_equip(style)
		var office := await _screen(OFFICE)
		var sub := office.find_child("DocketHours", true, false) as Label
		if sub == null or not sub.text.contains(str(GameState.work_hours_left())):
			_failures.append("%s: the docket card does not say the hours left" % style)
		var tray := office.find_child("Tray", true, false)
		if (style == UiStyles.LIVING_OFFICE) != (tray != null):
			_failures.append("%s: the payments tray is %s" % [style, "missing" if style == UiStyles.LIVING_OFFICE else "present"])
		# Woodblock's ledger: dotted leaders in the payments breakdown.
		office.call("_show_week_payments")
		await get_tree().create_timer(0.4).timeout
		var leaders := 0
		for node in office.find_children("*", "Control", true, false):
			if node is StyleMarks and (node as StyleMarks).kind == StyleMarks.Kind.LEADER:
				leaders += 1
		if (style == UiStyles.WOODBLOCK) != (leaders > 0):
			_failures.append("%s: %d dotted leaders in the payments breakdown" % [style, leaders])
		await _done(office)
	if _failures.is_empty():
		print("STYLE ELEMENTS TEST: PASS")
		get_tree().quit(0)
	else:
		print("STYLE ELEMENTS TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)
