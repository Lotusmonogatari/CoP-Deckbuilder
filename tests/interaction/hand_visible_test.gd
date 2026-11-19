extends Node
## The hand's cards overlap only by their last third and keep their size (Cameron, 2026-11-19; it was every
## card squeezed on screen after P9, a sideways scroll before). For each style and hand size the real battle
## screen is built and each CardView is checked: visible in the tree, showing at least MIN_STRIP where the
## next card covers it, and (hands of 5 or more, which no longer fit) showing about two thirds of itself, with
## a sideways scroll that reaches every card. Hands that fit (3 or 4) are checked to sit inside the screen.
##
##     xvfb-run .tools/godot --path . tests/interaction/hand_visible_test.tscn

const BATTLE := "res://scenes/battle/BattleScreen.tscn"
const MIN_STRIP := 100.0

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


func _run() -> void:
	var checked := 0
	for style: String in UiStyles.ALL:
		for count in [3, 4, 5, 6]:
			checked += await _one(style, count)
	if checked != UiStyles.ALL.size() * 4:
		_failures.append("only %d hands were checked" % checked)
	if _failures.is_empty():
		print("HAND VISIBLE TEST: PASS (%d hands)" % checked)
		get_tree().quit(0)
	else:
		print("HAND VISIBLE TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _one(style: String, count: int) -> int:
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
	get_tree().change_scene_to_file(BATTLE)
	await get_tree().process_frame
	await get_tree().create_timer(0.8).timeout
	var screen := get_tree().current_scene
	var ids: Array[String] = []
	for row: Dictionary in DataDB.cards:
		ids.append(str(row["card_id"]))
		if ids.size() == count:
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
	var tag := "%s, %d cards: " % [style, count]
	if views.size() != count:
		_failures.append(tag + "%d card views on screen" % views.size())
		return 1
	var screen_rect := get_viewport().get_visible_rect()
	var scroll := screen.find_child("HandScroll", true, false) as ScrollContainer
	var share := float(Levers.whole("hand_card_overlap_percent")) / 100.0
	var fits := views[views.size() - 1].get_global_rect().end.x <= screen_rect.end.x + 1.0
	for i in views.size():
		var rect := views[i].get_global_rect()
		if not views[i].is_visible_in_tree():
			_failures.append(tag + "card %d is hidden" % i)
		if fits and (rect.position.x < -1.0 or rect.end.x > screen_rect.end.x + 1.0):
			_failures.append(tag + "card %d runs off the screen (%s)" % [i, rect])
		# Spacing is read from the cards' layout positions: Living Office tilts each card about its bottom
		# centre, which moves the corner a global rectangle starts from.
		var strip := rect.size.x if i == views.size() - 1 else views[i + 1].position.x - views[i].position.x
		if strip < MIN_STRIP:
			_failures.append(tag + "card %d shows only %d px" % [i, int(strip)])
		# A hand that no longer fits keeps the chosen overlap: each card but the last shows about two thirds.
		if not fits and i < views.size() - 1 and absf(strip - rect.size.x * (1.0 - share)) > 3.0:
			_failures.append(tag + "card %d shows %d px, not about %d" % [i, int(strip), int(rect.size.x * (1.0 - share))])
	if views[0].get_global_rect().position.x < -1.0:
		_failures.append(tag + "the first card starts off the screen")
	var range_px := scroll.get_h_scroll_bar().max_value - scroll.get_h_scroll_bar().page
	if fits and range_px > 1.0:
		_failures.append(tag + "the hand fits but it scrolls")
	if not fits:
		if range_px < 1.0:
			_failures.append(tag + "the hand does not fit but it cannot scroll")
		# Every card can be scrolled fully onto the screen.
		for i in views.size():
			scroll.ensure_control_visible(views[i])
			await get_tree().process_frame
			var seen := views[i].get_global_rect()
			if seen.position.x < -1.0 or seen.end.x > screen_rect.end.x + 1.0:
				_failures.append(tag + "card %d cannot be scrolled into view (%s)" % [i, seen])
	return 1
