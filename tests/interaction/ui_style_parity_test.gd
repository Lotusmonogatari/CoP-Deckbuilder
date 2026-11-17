extends Node
## A style changes look and arrangement only (P9, 2026-11-17): the Office, the End of Week Payments
## breakdown and a battle show exactly the same visible text and numbers in every style. Each screen
## is built for real in each style (same run, same seed) and every visible label and button's text is
## collected; the sets must match. A difference names the style and the text.
##
##     xvfb-run .tools/godot --path . tests/interaction/ui_style_parity_test.tscn

const OFFICE := "res://scenes/office_hours/OfficeScreen.tscn"
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
	for screen_name: String in ["office", "payments", "battle"]:
		var reference: Array = []
		for style: String in UiStyles.ALL:
			var texts := await _texts(screen_name, style)
			if style == UiStyles.ALL[0]:
				reference = texts
			elif texts != reference:
				_report(screen_name, style, reference, texts)
	if _failures.is_empty():
		print("UI STYLE PARITY TEST: PASS")
		get_tree().quit(0)
	else:
		print("UI STYLE PARITY TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _report(screen_name: String, style: String, reference: Array, texts: Array) -> void:
	for text: String in texts:
		if not reference.has(text):
			_failures.append("%s: %s shows '%s', which %s does not" % [screen_name, style, text, UiStyles.ALL[0]])
	for text: String in reference:
		if not texts.has(text):
			_failures.append("%s: %s lacks '%s'" % [screen_name, style, text])


func _texts(screen_name: String, style: String) -> Array:
	DataDB.clear_runtime()
	GameState.start_new_run("PC02")
	GameState.awaiting_new_game = false
	GameState.meta["Funds"] = 12000
	GameState.xp = 500
	GameState.week_funds_earned = 80000
	for id: String in ["SF04", "SF08"]:
		GameState.hire_staff(id)
	var package := UiStyles.package_for(style, DataDB.cosmetic_packages)
	if not package.is_empty():
		GameState.owned_cosmetic_packages.append(str(package["package_id"]))
		GameState.equip_cosmetic(CosmeticPieces.UI_STYLE, str(package["package_id"]))
	UiStyle.forget()
	Layout.apply_ui_style()
	seed(77)
	BattleSetup.seed_people_draws(77)
	if screen_name == "battle":
		GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV04"))))
		get_tree().change_scene_to_file(BATTLE)
	else:
		get_tree().change_scene_to_file(OFFICE)
	await get_tree().process_frame
	await get_tree().create_timer(1.2).timeout
	var scene := get_tree().current_scene
	if screen_name == "payments":
		for child in scene.get_children():
			if child is Overlay and (child as Overlay).visible:
				(child as Overlay).close()
		scene._show_week_payments()
		await get_tree().create_timer(0.5).timeout
	var out: Array = []
	for node in scene.find_children("*", "Control", true, false):
		if not (node is Label or node is Button) or not (node as Control).is_visible_in_tree():
			continue
		# The news ticker rotates its lines at random and the hand is a shuffled draw: neither
		# is a style's doing, so both are left out. (The hand's own look is hand_visible_test.)
		# The small room-object word on a Living Office pin ("Phone", "Bookshelf") is part of that style's
		# room metaphor, a label of its own beside the destination's text; it is the one allowed difference.
		if node.name == "TickerLabel" or node.name == "ObjectWord" or _inside(node, scene, "CardView"):
			continue
		var text := str(node.get("text")).strip_edges()
		# Elapsed-time wording changes between builds; it is the same line in every style.
		if not text.is_empty() and not out.has(text):
			out.append(text)
	out.sort()
	return out


func _inside(node: Node, root: Node, class_label: String) -> bool:
	var parent := node.get_parent()
	while parent != null and parent != root:
		if parent.get_class() == class_label or (parent.get_script() != null and str(parent.get_script().get_global_name()) == class_label):
			return true
		parent = parent.get_parent()
	return false
