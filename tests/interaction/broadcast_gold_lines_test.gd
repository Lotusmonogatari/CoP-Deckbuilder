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
var _vp: SubViewport


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
	# Drawn in a viewport of the full design size, so pixels are base pixels whatever the window is.
	_vp = SubViewport.new()
	_vp.size = Vector2i(1080, 2340)
	_vp.disable_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var screen: Control = (load(BATTLE) as PackedScene).instantiate()
	_vp.add_child(screen)
	await get_tree().process_frame
	await get_tree().create_timer(1.2).timeout
	# The cue band lies over the bar while a line is showing: step it aside for the pixel check.
	(screen.get("_banner") as CueBanner).set_suppressed(true)
	await get_tree().create_timer(0.4).timeout
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
	# Since 2026-11-18 Broadcast draws the semicircle too, in its own look: faceted, with gold along the outer
	# and inner rims (the bar's gold top and bottom), none on the ends.
	if not bar._living or bar._look != UiStyles.BROADCAST:
		_failures.append("the support bar is not the Broadcast semicircle")
		return
	var image := _vp.get_texture().get_image()
	var rect := bar.get_global_rect()
	var h := bar._living_height
	var radius := minf(rect.size.x * 0.5 - SeatsMeter.ARC_WIDTH, h - SeatsMeter.ARC_WIDTH * 0.5 - 8.0)
	var centre := Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + h - 8.0)
	var inner := radius - SeatsMeter.ARC_WIDTH
	var outer_hits := 0
	var inner_hits := 0
	var samples := 0
	for k in range(1, 12):
		var a := PI + float(k) * PI / 12.0
		var dir := Vector2(cos(a), sin(a))
		samples += 1
		if _gold_near(image, centre + dir * radius, dir):
			outer_hits += 1
		if _gold_near(image, centre + dir * inner, dir):
			inner_hits += 1
	if outer_hits < samples * 0.7:
		_failures.append("the arc's outer gold rim shows at only %d of %d points" % [outer_hits, samples])
	if inner_hits < samples * 0.7:
		_failures.append("the arc's inner gold rim shows at only %d of %d points" % [inner_hits, samples])
	if not bar.has_threshold:
		_failures.append("this stage has no threshold to draw")


## Gold within a few pixels of `at`, searching along the radius (a facet's chord sits a little inside the circle).
func _gold_near(image: Image, at: Vector2, dir: Vector2) -> bool:
	for step in range(-8, 4):
		var p := at + dir * float(step)
		if p.x >= 0 and p.y >= 0 and p.x < image.get_width() and p.y < image.get_height() and _near_gold(image.get_pixel(int(p.x), int(p.y))):
			return true
	return false


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
