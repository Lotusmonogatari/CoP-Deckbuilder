extends Node
## The opponent's intent line is a floating pill coloured for the opponent's party (Cameron, 2026-11-17):
## the party's colour when the opponent has a party that is not the player's, otherwise the default red.
## Built on the real battle screen in every style; the opponent's party is set, the screen refreshed, and
## the pill's fill is read from its style box AND from the rendered pixels. The pill must be narrower than
## the screen and a single line (no stacked letters).
##
##     xvfb-run .tools/godot --path . tests/interaction/intent_pill_test.tscn

const BATTLE := "res://scenes/battle/BattleScreen.tscn"

var _failures: PackedStringArray = []
var _checked := 0


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
	if _checked < 12:
		_failures.append("only %d pill checks ran" % _checked)
	if _failures.is_empty():
		print("INTENT PILL TEST: PASS (%d checks)" % _checked)
		get_tree().quit(0)
	else:
		print("INTENT PILL TEST: FAIL")
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
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var screen: Control = (load(BATTLE) as PackedScene).instantiate()
	vp.add_child(screen)
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	(screen.get("_banner") as CueBanner).set_suppressed(true)
	var own := PartyDisplay.party_name(DataDB.player)
	var default_red := UiStyle.colour("intent_default", Color.MAGENTA, UiStyles.SHARED)
	var cases := [
		["Keizaijiyuutou", PartyDisplay.color_for(DataDB.get_party("Keizaijiyuutou"))],
		["Butsutou", PartyDisplay.color_for(DataDB.get_party("Butsutou"))],
		["", default_red],
		[own, default_red],
	]
	for case: Array in cases:
		var row: Dictionary = screen.engine.current_opponent()
		row["party"] = case[0]
		screen._refresh()
		await get_tree().process_frame
		await get_tree().create_timer(0.3).timeout
		var label := screen.get("_intent_label_node") as Label
		var box := screen.get("_intent_box") as StyleBoxFlat
		var want: Color = case[1]
		var tag := "%s, party '%s': " % [style, case[0]]
		if box.bg_color.to_html(false) != want.to_html(false):
			_failures.append(tag + "the pill is %s, wanted %s" % [box.bg_color.to_html(false), want.to_html(false)])
		var rect := label.get_global_rect()
		if rect.size.x > 880.0 or rect.size.x < 200.0:
			_failures.append(tag + "the pill is %d px wide (a pill is as wide as its words)" % int(rect.size.x))
		if rect.size.y > 140.0:
			_failures.append(tag + "the pill is %d px tall (letters stacked?)" % int(rect.size.y))
		# The pixels: the pill's right end (clear of Woodblock's seal) is its fill.
		var image := vp.get_texture().get_image()
		var sample := image.get_pixel(int(rect.end.x - 14.0), int(rect.position.y + rect.size.y * 0.5))
		if absf(sample.r - want.r) + absf(sample.g - want.g) + absf(sample.b - want.b) > 0.12:
			_failures.append(tag + "the rendered pill is %s, wanted %s" % [sample.to_html(false), want.to_html(false)])
		_checked += 1
	vp.queue_free()
	await get_tree().process_frame
