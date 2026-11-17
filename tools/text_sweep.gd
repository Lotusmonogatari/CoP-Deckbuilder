extends Node
## Text sweep (design review panel P3, 2026-11-17). Opens every screen of the game at both
## phone shapes (1080 x 2340 and 1080 x 1920) and at every text size the game offers
## (Small, Normal, Large), and records what a person could not read:
##
##   letter_stacking  a Label or Button that wraps into more lines than it has words
##                    (a word split across lines, one letter a line)
##   off_screen       a visible text control, not inside a scrolling or clipping box,
##                    partly outside the screen
##   overlap          two visible text controls on the same layer whose rectangles overlap
##   small_target     a Button whose smaller side is under 122 px (the iOS 44 pt line);
##                    report only, one row per screen
##
##     xvfb-run -a -s "-screen 0 1080x2340x24" .tools/godot --path . tools/text_sweep.tscn
##
## Environment: SWEEP_OUT=path.csv (default res://audit/text_sweep.csv), SWEEP_TEXT=small,normal,large,
## SWEEP_SHAPES=2340,1920, SWEEP_SHOTS=dir (a picture of every screen that had a problem, plus the
## screens named in SWEEP_ALWAYS, comma separated).
## The exit code is 1 when there is any letter_stacking or off_screen row (overlap and
## small_target are report only). Each text size can run in its own process; tools/text_sweep.sh
## runs the three in parallel and joins the files. Read-only for the game.

const SHAPES := {"2340": Vector2i(1080, 2340), "1920": Vector2i(1080, 1920)}
const MIN_TARGET := 122.0
const OFFICE := "res://scenes/office_hours/OfficeScreen.tscn"

## Deliberate overlays, named. A control inside any of these is never reported for overlap
## or position: the banner slides in from off screen on purpose; a card face lays its text
## over its art; the hand and the ticker scroll sideways; the labelled stand-in for a picture that
## is not drawn yet (PlaceholderArt) is art, not interface text.
const DELIBERATE := ["CueBanner", "CardView", "CardBackView", "HandScroll", "Ticker", "ListeningStrip", "PlaceholderArt"]
## Boxes that scroll or clip: what hangs past them is reached by scrolling, not off screen.
const SCROLLS := ["ScrollContainer"]

var _rows: Array[Dictionary] = []
var _screens_checked := 0
var _vp: SubViewport
var _shape := ""
var _text := ""
var _shots := ""
var _targets_seen := {}


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_shots = OS.get_environment("SWEEP_SHOTS")
	var texts: PackedStringArray = (OS.get_environment("SWEEP_TEXT") if OS.has_environment("SWEEP_TEXT") and not OS.get_environment("SWEEP_TEXT").is_empty() else "small,normal,large").split(",")
	var shapes: PackedStringArray = (OS.get_environment("SWEEP_SHAPES") if not OS.get_environment("SWEEP_SHAPES").is_empty() else "2340,1920").split(",")
	var started := Time.get_ticks_msec()
	for text_size: String in texts:
		Layout.text_size_setting = text_size
		Layout.apply_text_scale()
		for shape: String in shapes:
			_text = text_size
			_shape = shape
			await _sweep_shape(SHAPES[shape])
	Layout.text_size_setting = TextScale.NORMAL
	Layout.apply_text_scale()
	var out := OS.get_environment("SWEEP_OUT")
	if out.is_empty():
		out = "res://audit/text_sweep.csv"
	_write(out)
	var hard := _rows.filter(func(r: Dictionary) -> bool: return r["problem"] in ["letter_stacking", "off_screen"])
	print("TEXT SWEEP: %d screens, %d rows (%d letter_stacking or off_screen), %.0f s -> %s" % [
		_screens_checked, _rows.size(), hard.size(), (Time.get_ticks_msec() - started) / 1000.0, out])
	get_tree().quit(1 if not hard.is_empty() else 0)


func _write(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_line("screen,shape,text_size,control,problem,detail")
	for r: Dictionary in _rows:
		file.store_line("%s,%s,%s,\"%s\",%s,\"%s\"" % [r["screen"], r["shape"], r["text"], str(r["control"]).replace("\"", "'"), r["problem"], str(r["detail"]).replace("\"", "'")])
	file.close()


# ---------------------------------------------------------------- the screens
func _fresh_run(awaiting: bool = false) -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC02")
	GameState.awaiting_new_game = awaiting
	GameState.meta["Funds"] = 400000
	GameState.xp = 500
	GameState.staff_recruitment_tier = 2
	GameState.calendar["week"] = 4
	GameState.calendar["hours"] = 5
	GameState.time_units = 4 * 40 * 6
	for id: String in ["SF04", "SF08"]:
		GameState.hire_staff(id)
	GameState.staff_loyalty["SF04"] = 62
	GameState.booster_standing["BO03"] = 50
	GameState.inventory = {"SH04": 2, "SH37": 1, "SH38": 1}
	GameState.promises.append({"id": "P1", "kind": Promises.PROMISE_ITEM, "item_id": "SH04", "for_org": "BO10",
		"due_at": GameState.time_units + 96})
	seed(4242)
	BattleSetup.seed_people_draws(4242)


func _new_viewport(size: Vector2i) -> SubViewport:
	if _vp != null:
		_vp.queue_free()
		await get_tree().process_frame
	_vp = SubViewport.new()
	_vp.size = size
	_vp.disable_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	return _vp


func _load(path: String, size: Vector2i) -> Control:
	var vp := await _new_viewport(size)
	var scene: Control = (load(path) as PackedScene).instantiate()
	vp.add_child(scene)
	await _settle()
	return scene


func _settle(seconds: float = 0.45) -> void:
	await get_tree().process_frame
	await get_tree().create_timer(seconds).timeout


func _close_all(root: Node) -> void:
	for child in root.get_children():
		if child is Overlay and (child as Overlay).visible:
			(child as Overlay).close()


func _sweep_shape(size: Vector2i) -> void:
	# --- the title and the front door
	_fresh_run()
	var scene := await _load("res://scenes/menus/IntroScreen.tscn", size)
	await _check("A01_title", scene)
	_fresh_run(true)
	scene = await _load(OFFICE, size)
	await _check("A02_new_game_picker", scene)
	# --- the Office and its panels (one Office, many panels)
	_fresh_run()
	var office := await _load(OFFICE, size)
	_close_all(office)
	await _settle(0.2)
	await _check("B01_office_main", office)
	var panels: Array = [
		["B02_levels_list", func() -> void: office._show_levels()],
		["B03_level_briefing", func() -> void:
			office._chosen_level = DataDB.get_level("LV04")
			office._show_briefing()],
		["B04_rhetoric_training_list", func() -> void: office._show_rhetoric_training()],
		["B04b_rhetoric_training_offer", func() -> void:
			GameState.card_draw = {"item_id": "SH09", "card_id": "C23", "look": 1, "seen": ["C23"]}
			office._show_card_offer()],
		["B06_deck", func() -> void: office._show_deck()],
		["B07_card_view", func() -> void: office._show_card_look("C09")],
		["B09_marketplace", func() -> void: office._show_marketplace()],
		["B10_item_popup", func() -> void: office.get("_inventory_panel").show_item("SH37")],
		["B11_backings", func() -> void: office._show_backing()],
		["B12_staff_list", func() -> void: office._show_staff()],
		["B13_staff_profile", func() -> void: office._show_staff_profile("SF04")],
		["B14_staff_assignments", func() -> void:
			GameState.staff_ensure_day()
			office._show_staff_assignments()],
		["B15_task_popup", func() -> void:
			GameState.staff_ensure_day()
			office._show_staff_assignments()
			if not GameState.staff_day_pool.is_empty():
				office._on_task_tapped(str(GameState.staff_day_pool[0]["uid"]))],
		["B17_events_list", func() -> void: office._show_events_list()],
		["B18_event", func() -> void: office._present_event("EV02", true)],
		["B19_who_goes", func() -> void: office._on_event_delegate("EV02", "B")],
		["B20_promises", func() -> void: office._show_promises()],
		["B21_organisations", func() -> void: office._show_organisations()],
		["B22_parties", func() -> void: office._show_parties()],
		["B23_election_strength", func() -> void: office._show_election()],
		["B24_your_record", func() -> void: office._show_record()],
		["B25_request", func() -> void:
			GameState.arm_patron_requests()
			for id: String in GameState.patron_armed.keys():
				GameState.patron_armed[id] = -100000
			var shown := GameState.patron_requests_shown()
			if not shown.is_empty():
				office._open_request(str(shown[0]), "", "")],
		["B26_draft_a_bill", func() -> void: office._open_draft(true)],
		["B27_administration", func() -> void: office._show_administration_menu()],
		["B27b_management_menu", func() -> void: office._show_management()],
		["B27c_reputation_menu", func() -> void: office._show_reputation_menu()],
		["B27d_appearance", func() -> void: office._show_cosmetics()],
		["B28_how_to_play", func() -> void: HowToPlayPanel.open(HowToPlayPanel.attach(office))],
	]
	for entry: Array in panels:
		_close_all(office)
		(entry[1] as Callable).call()
		await _settle(0.3)
		await _check(str(entry[0]), office)
	# --- the week: dues owed, week over, urgent matters
	_fresh_run()
	GameState.dues_balance = 120000
	scene = await _load(OFFICE, size)
	_close_all(scene)
	await _settle(0.2)
	await _check("F02_dues_owed", scene)
	_fresh_run()
	GameState.calendar["hours"] = 40
	scene = await _load(OFFICE, size)
	await _check("F01_week_end_popup", scene)
	_fresh_run()
	GameState.meta["Constituency support"] = 15
	GameState.check_crisis_triggers()
	for id: String in GameState.special_levels.keys():
		GameState.special_levels[id] = {"armed_at": -100000}
	GameState.special_forced = true
	scene = await _load(OFFICE, size)
	await _check("F03_urgent_matters", scene)
	# --- entering a level
	_fresh_run()
	_begin("LV04")
	scene = await _load(StageRouting.LEVEL_INTRO_SCENE, size)
	await _settle(0.8)
	await _check("C01_level_intro_purpose", scene)
	GameState.finish_stage(LevelRunner.WON)
	scene = await _load(StageRouting.TRANSITION_SCENE, size)
	await _settle(1.0)
	await _check("C05_stage_transition", scene)
	GameState.end_level()
	_fresh_run()
	_begin("LV66")
	scene = await _load(StageRouting.LEVEL_INTRO_SCENE, size)
	await _intro_to_lean(scene)
	await _check("C02_level_intro_bill_card", scene)
	var read := scene.find_child("ReadBill", true, false) as Button
	if read != null:
		read.pressed.emit()
		await _settle(0.3)
		await _check("C03_read_the_bill", scene)
	GameState.end_level()
	# --- rooms
	_fresh_run()
	_begin("LV04")
	var battle := await _load(StageRouting.BATTLE_SCENE, size)
	await _settle(0.6)
	await _check("D01_combat_turn1", battle)
	var card := str(battle.engine.state.hand[0])
	battle._on_card_chosen(card)
	battle._on_card_chosen(card)
	await _settle(0.3)
	await _check("D02_card_zoom", battle)
	battle.get_node("%CardZoom").hide()
	battle._toggle_details()
	await _settle(0.3)
	await _check("D07_details_panel", battle)
	battle._toggle_details()
	battle.get("_inventory").show_inventory()
	await _settle(0.3)
	await _check("D08_inventory", battle)
	battle.get("_inventory").close()
	battle.engine.state.gaffe = battle.engine.state.gaffe_limit
	battle._play_card_now(str(battle.engine.state.hand[0]), [])
	await _settle(1.2)
	await _check("D10_loss_result", battle)
	GameState.end_level()
	for pair: Array in [["E01_press_conference", "LV05"], ["E03_tv_debate", "LV91"], ["E05_office_hours", "LV86"]]:
		_fresh_run()
		_begin(str(pair[1]))
		var scene_path := StageRouting.VISITOR_SCENE if pair[1] == "LV86" else StageRouting.BATTLE_SCENE
		scene = await _load(scene_path, size)
		await _settle(0.6)
		await _check(str(pair[0]), scene)
		GameState.end_level()
	_fresh_run()
	GameState.booster_standing["BO03"] = 70
	GameState.arm_patron_requests()
	for id: String in GameState.patron_armed.keys():
		GameState.patron_armed[id] = -100000
	if GameState.start_patron_level("PB032"):
		var got_visit := false
		var got_trade := false
		var guard := 0
		while GameState.is_in_level() and guard < 14 and not (got_visit and got_trade):
			guard += 1
			var scene_path2 := StageRouting.scene_for(GameState.level_runner.current_stage())
			if scene_path2 == StageRouting.VISIT_SCENE and not got_visit:
				scene = await _load(scene_path2, size)
				await _check("E07_member_visit", scene)
				got_visit = true
			elif scene_path2 == StageRouting.TRADE_SCENE and not got_trade:
				scene = await _load(scene_path2, size)
				await _check("E08_lobbyist_trade", scene)
				got_trade = true
			GameState.finish_stage(LevelRunner.WON)
		GameState.end_level()
	_fresh_run()
	_begin("LV66")
	while str(GameState.level_runner.current_stage().get("mode", "")) != "Vote":
		GameState.finish_stage(LevelRunner.WON)
	var vote := await _load(StageRouting.FLOOR_VOTE_SCENE, size)
	await _settle(0.6)
	await _check("E09_floor_vote_before", vote)
	vote._on_vote("Yes")
	await _settle(1.0)
	await _check("E10_floor_vote_result", vote)
	GameState.end_level()


func _begin(level_id: String) -> void:
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level(level_id))))


func _intro_to_lean(screen: Node) -> void:
	for _i in 14:
		if screen.get("_lean_shown"):
			break
		screen.get_node("CueBanner").call("clear")
		screen.set("_lines_accounted_for", screen.get("_total_lines"))
		await get_tree().process_frame
	await _settle(0.5)


# ---------------------------------------------------------------- the checks
func _check(screen_id: String, root: Node) -> void:
	_screens_checked += 1
	var size := Vector2(_vp.size)
	var layer_root := _top_layer(root)
	var controls := _text_controls(layer_root)
	var found := 0
	# letter stacking
	for c: Control in controls:
		var words := _words(c)
		var lines := _line_count(c)
		if lines > 1 and lines > words:
			found += _add(screen_id, c, "letter_stacking", "%d lines for %d word(s): '%s'" % [lines, words, _text_of(c).substr(0, 40)])
	# off screen
	for c: Control in controls:
		if _in_scroll(c, layer_root):
			var r := _rect(c)
			if r.position.x < -1.0 or r.end.x > size.x + 1.0:
				found += _add(screen_id, c, "off_screen", "sideways inside a scroll box: x %d to %d of %d" % [r.position.x, r.end.x, size.x])
			continue
		var rect := _rect(c)
		if rect.position.x < -1.0 or rect.end.x > size.x + 1.0 or rect.position.y < -1.0 or rect.end.y > size.y + 1.0:
			found += _add(screen_id, c, "off_screen", "x %d to %d, y %d to %d of %dx%d" % [rect.position.x, rect.end.x, rect.position.y, rect.end.y, size.x, size.y])
	# overlap
	var texted := controls.filter(func(c: Control) -> bool: return not _text_of(c).strip_edges().is_empty() and not _in_scroll_clipped_out(c, layer_root))
	for i in texted.size():
		var a: Control = texted[i]
		var ra := _shown_rect(a, layer_root)
		for j in range(i + 1, texted.size()):
			var b: Control = texted[j]
			if a.is_ancestor_of(b) or b.is_ancestor_of(a):
				continue
			var rb := _shown_rect(b, layer_root)
			var inter := ra.intersection(rb)
			if inter.size.x > 6.0 and inter.size.y > 6.0:
				found += _add(screen_id, a, "overlap", "with %s (%d x %d px)" % [layer_root.get_path_to(b) if layer_root.is_ancestor_of(b) else b.name, inter.size.x, inter.size.y])
	# small targets: one row a screen
	var small := 0
	var smallest := 99999.0
	for c: Control in _all_visible(layer_root):
		if c is Button and c.is_visible_in_tree() and not _is_deliberate(c) and not _clipped_out(c, layer_root):
			var m := minf(c.size.x * c.get_global_transform().get_scale().x, c.size.y * c.get_global_transform().get_scale().y)
			if m < MIN_TARGET and c.size.x > 4.0 and c.size.y > 4.0:
				small += 1
				smallest = minf(smallest, m)
	if small > 0:
		_rows.append({"screen": screen_id, "shape": _shape, "text": _text, "control": "(%d buttons)" % small, "problem": "small_target", "detail": "smallest side %d px" % int(smallest)})
	var always := OS.get_environment("SWEEP_ALWAYS").split(",", false)
	if (found > 0 or screen_id in always) and not _shots.is_empty():
		DirAccess.make_dir_recursive_absolute(_shots)
		_vp.get_texture().get_image().save_png("%s/%s_%s_%s.png" % [_shots, screen_id, _shape, _text])


func _add(screen_id: String, c: Control, problem: String, detail: String) -> int:
	var key := "%s|%s|%s|%s|%s|%s" % [screen_id, _shape, _text, problem, c.name, detail]
	if _targets_seen.has(key):
		return 0
	_targets_seen[key] = true
	_rows.append({"screen": screen_id, "shape": _shape, "text": _text, "control": _path(c), "problem": problem, "detail": detail})
	return 1


func _path(c: Control) -> String:
	var parts: PackedStringArray = []
	var n: Node = c
	while n != null and parts.size() < 4 and n != _vp:
		parts.append(str(n.name))
		n = n.get_parent()
	parts.reverse()
	return "/".join(parts)


## What the player sees on top: the last visible Overlay (or the zoom / outcome / inventory
## panels), else the whole scene. Everything under an opaque panel is hidden by it.
func _top_layer(root: Node) -> Node:
	var top: Node = root
	for child in root.get_children():
		if child is Overlay and (child as Overlay).visible:
			top = child
	if top == root:
		for name_ in ["OutcomePanel", "CardZoom", "DetailsPanel"]:
			var n := root.find_child(name_, true, false)
			if n is Control and (n as Control).visible:
				top = n
		var inv := root.get_node_or_null("InventoryPanel")
		if inv is Overlay and (inv as Overlay).visible:
			top = inv
	return top


func _all_visible(root: Node) -> Array[Control]:
	var out: Array[Control] = []
	for n in root.find_children("*", "Control", true, false):
		var c := n as Control
		if c.is_visible_in_tree() and c.size.x > 0.0 and c.size.y > 0.0 and c.modulate.a > 0.1 and not _is_deliberate(c):
			out.append(c)
	if root is Control and (root as Control).is_visible_in_tree():
		out.append(root as Control)
	return out


func _text_controls(root: Node) -> Array[Control]:
	var out: Array[Control] = []
	for c: Control in _all_visible(root):
		if c is Label or c is Button or c is RichTextLabel:
			if not _text_of(c).strip_edges().is_empty() and not _clipped_out(c, root):
				out.append(c)
	return out


func _text_of(c: Control) -> String:
	if c is Label:
		return (c as Label).text
	if c is Button:
		return (c as Button).text
	if c is RichTextLabel:
		return (c as RichTextLabel).get_parsed_text()
	return ""


func _words(c: Control) -> int:
	var count := 0
	for w in _text_of(c).strip_edges().split(" ", false):
		if not w.strip_edges().is_empty():
			count += 1
	return maxi(count, 1)


func _line_count(c: Control) -> int:
	if c is Label:
		var l := c as Label
		return l.get_line_count() if l.autowrap_mode != TextServer.AUTOWRAP_OFF else 1
	if c is Button:
		var b := c as Button
		if b.autowrap_mode == TextServer.AUTOWRAP_OFF:
			return 1
		var para := TextParagraph.new()
		para.width = maxf(b.size.x - b.get_theme_stylebox("normal").get_minimum_size().x, 1.0)
		para.break_flags = TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE | TextServer.BREAK_MANDATORY
		para.add_string(b.text, b.get_theme_font("font"), b.get_theme_font_size("font_size"))
		return para.get_line_count()
	return 1


func _rect(c: Control) -> Rect2:
	return c.get_global_transform() * Rect2(Vector2.ZERO, c.size)


## The part of a control that can actually be seen: its rectangle cut down to every
## clipping or scrolling box it sits in (text scrolled half out of view is not on screen).
func _shown_rect(c: Control, root: Node) -> Rect2:
	var r := _rect(c)
	var n: Node = c.get_parent()
	while n != null and n != root and n != _vp:
		if n is Control and ((n as Control).clip_contents or n is ScrollContainer):
			r = r.intersection(_rect(n as Control))
		n = n.get_parent()
	return r


func _is_deliberate(c: Node) -> bool:
	var n: Node = c
	while n != null and n != _vp:
		if str(n.name) in DELIBERATE or (n.get_script() != null and str(n.get_script().get_global_name()) in DELIBERATE):
			return true
		n = n.get_parent()
	return false


func _in_scroll(c: Control, root: Node) -> bool:
	var n: Node = c.get_parent()
	while n != null and n != root and n != _vp:
		if n is ScrollContainer:
			return true
		n = n.get_parent()
	return false


## True for a control that sits inside a clipping or scrolling box and lies wholly outside its
## visible area (scrolled away): never on screen, so never reported.
func _clipped_out(c: Control, root: Node) -> bool:
	var n: Node = c.get_parent()
	var r := _rect(c)
	while n != null and n != root and n != _vp:
		if n is Control and ((n as Control).clip_contents or n is ScrollContainer):
			if not _rect(n as Control).intersects(r):
				return true
		n = n.get_parent()
	return false


func _in_scroll_clipped_out(c: Control, root: Node) -> bool:
	return _clipped_out(c, root)
