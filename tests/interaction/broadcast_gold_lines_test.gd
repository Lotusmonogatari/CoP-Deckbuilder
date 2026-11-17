extends Node
## Broadcast keeps today's gold lines (P9 decision D2, 2026-11-17): the support bar has its thin
## gold border along the top and bottom and a threshold mark, and the cue band has gold top and
## bottom lines. Rendered for real in the Broadcast style, then read from the pixels of the bar and
## from the band's own style box.
##
##     xvfb-run .tools/godot --path . tests/interaction/broadcast_gold_lines_test.tscn

const BATTLE := "res://scenes/battle/BattleScreen.tscn"
const GOLD := Color(0.95, 0.82, 0.38)

var _failures: PackedStringArray = []


func _ready() -> void:
	# A scene change frees this node, so the run lives on the root, as the other click drivers do.
	if name != "Runner":
		var runner := Node.new()
		runner.name = "Runner"
		runner.set_script(get_script())
		get_tree().root.add_child.call_deferred(runner)
		return
	_run.call_deferred()


func _near_gold(c: Color) -> bool:
	return absf(c.r - GOLD.r) < 0.12 and absf(c.g - GOLD.g) < 0.12 and absf(c.b - GOLD.b) < 0.14


func _run() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC02")
	GameState.awaiting_new_game = false
	var package := UiStyles.package_for(UiStyles.BROADCAST, DataDB.cosmetic_packages)
	GameState.owned_cosmetic_packages.append(str(package["package_id"]))
	GameState.equip_cosmetic(CosmeticPieces.UI_STYLE, str(package["package_id"]))
	UiStyle.forget()
	Layout.apply_ui_style()
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV04"))))
	get_tree().change_scene_to_file(BATTLE)
	await get_tree().process_frame
	await get_tree().create_timer(1.2).timeout
	var screen := get_tree().current_scene
	var bar := screen.find_child("SupportBar", true, false) as SupportBar
	if bar == null:
		_failures.append("no support bar")
	else:
		_check_bar(bar)
	var cues := screen.find_children("*", "CueBanner", true, false)
	if cues.is_empty():
		_failures.append("no cue banner")
	else:
		_check_band(cues[0])
	if _failures.is_empty():
		print("BROADCAST GOLD LINES TEST: PASS")
		get_tree().quit(0)
	else:
		print("BROADCAST GOLD LINES TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _check_bar(bar: SupportBar) -> void:
	if bar._living:
		_failures.append("the support bar drew seats in Broadcast")
		return
	var image := get_viewport().get_texture().get_image()
	var rect := bar.get_global_rect()
	var top := rect.position.y + 44.0   # SupportBar draws its bar 44 px under its caption
	var bottom := top + SupportBar.HEIGHT
	# Scan across the bar's width for gold on the first and last rows of the bar.
	var gold_top := 0
	var gold_bottom := 0
	var x := int(rect.position.x) + 40
	while x < int(rect.end.x) - 40:
		for dy in range(1, 4):
			if _near_gold(image.get_pixel(x, int(top) + dy)):
				gold_top += 1
				break
		for dy in range(1, 4):
			if _near_gold(image.get_pixel(x, int(bottom) - dy)):
				gold_bottom += 1
				break
		x += 8
	var columns := (int(rect.size.x) - 80) / 8
	if gold_top < columns * 0.7:
		_failures.append("the bar's top gold line shows on only %d of %d columns" % [gold_top, columns])
	if gold_bottom < columns * 0.7:
		_failures.append("the bar's bottom gold line shows on only %d of %d columns" % [gold_bottom, columns])
	if not bar.has_threshold:
		_failures.append("this stage has no threshold to draw")


func _check_band(banner: Node) -> void:
	var box: StyleBoxFlat = banner._band_box
	if box == null:
		_failures.append("the cue band has no style box")
		return
	if box.border_width_top <= 0 or box.border_width_bottom <= 0:
		_failures.append("the cue band lacks its top or bottom line (%d, %d)" % [box.border_width_top, box.border_width_bottom])
	if box.border_width_left != 0 or box.border_width_right != 0:
		_failures.append("the cue band has side borders")
	if not _near_gold(box.border_color):
		_failures.append("the cue band's lines are not gold: %s" % str(box.border_color))
