extends Node
## Plan step 2 of design/DYNAMIC_SCREEN_PLAN.md: every screen shape, drawn at
## several phone and tablet shapes, must keep all of its content inside the
## screen sideways. Each screen is instantiated inside a SubViewport of the
## given size (no stretching, so the layout sees the real shape).
##
##     xvfb-run .tools/godot --path . tests/interaction/aspect_matrix_test.tscn
##
## With ASPECT_SHOTS=dir set, also saves a PNG of each screen at each size.

const SIZES := [Vector2i(1080, 1920), Vector2i(1080, 2160), Vector2i(1080, 2340),
	Vector2i(1080, 2520), Vector2i(1600, 2000)]
const SCREENS := {
	"Intro": "res://scenes/menus/IntroScreen.tscn",
	"Office": "res://scenes/office_hours/OfficeScreen.tscn",
	"Battle": "res://scenes/battle/BattleScreen.tscn",
	"FloorVote": "res://scenes/office_hours/FloorVoteScreen.tscn",
	"Visitor": "res://scenes/office_hours/VisitorScreen.tscn",
	"LevelIntro": "res://scenes/office_hours/LevelIntroScreen.tscn",
}
## Nodes that scroll sideways on purpose (the hand of cards).
const SIDEWAYS_OK := ["HandScroll", "Hand", "Ticker"]

## Controls that must never be pushed off the bottom of a short screen.
const MUST_FIT := ["EndTurnButton", "ContinueButton", "StartButton"]

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var shots := OS.get_environment("ASPECT_SHOTS")
	for screen_name: String in SCREENS:
		for size: Vector2i in SIZES:
			await _check(screen_name, SCREENS[screen_name], size, shots)
	# Large text must fit too: the two most demanding shapes.
	Layout.text_size_setting = TextScale.LARGE
	Layout.apply_text_scale()
	for screen_name: String in SCREENS:
		for size: Vector2i in [Vector2i(1080, 1920), Vector2i(1080, 2340)]:
			await _check(screen_name + "(large text)", SCREENS[screen_name], size, shots)
	Layout.text_size_setting = TextScale.NORMAL
	Layout.apply_text_scale()
	print("")
	if _failures.is_empty():
		print("ASPECT MATRIX TEST: PASS (%d screens x %d sizes)" % [SCREENS.size(), SIZES.size()])
		get_tree().quit(0)
	else:
		print("ASPECT MATRIX TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _prepare(screen_name: String) -> void:
	GameState.start_new_run("PC01")
	match screen_name.trim_suffix("(large text)"):
		"Battle":
			GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV08"))))
		"FloorVote":
			var runner := LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV31")))
			GameState.begin_level(runner)
			runner.index = runner.stages.size() - 1
		"Visitor":
			var runner := LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV02")))
			GameState.begin_level(runner)
			for i in runner.stages.size():
				runner.index = i
				if str(runner.current_stage().get("mode", "")) == "Non-combat":
					return
		"LevelIntro":
			GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV31"))))


func _check(screen_name: String, path: String, size: Vector2i, shots: String) -> void:
	_prepare(screen_name)
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var scene: Control = (load(path) as PackedScene).instantiate()
	viewport.add_child(scene)
	await get_tree().create_timer(0.6).timeout

	var label := "%s at %dx%d" % [screen_name, size.x, size.y]
	var limit := float(size.x) + 1.0
	for control: Control in scene.find_children("*", "Control", true, false):
		if not control.is_visible_in_tree() or _scrolls_sideways(control, scene):
			continue
		var rect := control.get_global_rect()
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			continue
		if rect.position.x < -1.0 or rect.end.x > limit:
			_failures.append("%s: %s runs off the sides (x %d to %d)" % [
				label, scene.get_path_to(control), int(rect.position.x), int(rect.end.x)])
	for scroll: ScrollContainer in scene.find_children("*", "ScrollContainer", true, false):
		if scroll.is_visible_in_tree() and scroll.name not in SIDEWAYS_OK \
				and scroll.get_h_scroll_bar().visible and scroll.get_h_scroll_bar().max_value > scroll.get_h_scroll_bar().page + 1.0:
			_failures.append("%s: %s scrolls sideways" % [label, scene.get_path_to(scroll)])
	# The thing a player must always be able to reach stays on screen.
	for must_fit: String in MUST_FIT:
		var key := scene.find_child(must_fit, true, false) as Control
		if key != null and key.is_visible_in_tree() and key.get_global_rect().end.y > float(size.y) + 1.0:
			_failures.append("%s: %s is cut off the bottom (ends at %d)" % [
				label, must_fit, int(key.get_global_rect().end.y)])
	if not shots.is_empty():
		DirAccess.make_dir_recursive_absolute(shots)
		viewport.get_texture().get_image().save_png("%s/%s_%dx%d.png" % [shots, screen_name, size.x, size.y])
	print("  %s checked" % label)
	viewport.queue_free()
	await get_tree().process_frame


## True for a control that sits inside a scroll container meant to scroll sideways.
func _scrolls_sideways(control: Control, root: Node) -> bool:
	var node: Node = control
	while node != null and node != root:
		if node.name in SIDEWAYS_OK:
			return true
		node = node.get_parent()
	return false
