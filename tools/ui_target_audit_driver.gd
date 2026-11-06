extends Node
## The walking half of ui_target_audit.gd (see there).

const OFFICE := "res://scenes/office_hours/OfficeScreen.tscn"
const OFFICE_PANELS := ["_show_levels", "_show_marketplace", "_show_staff", "_show_backing", "_show_deck",
	"_show_record", "_show_administration_menu", "_show_reputation_menu", "_show_organisations",
	"_show_parties", "_show_events_list", "_show_rhetoric_training"]

var _rows: Array = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.start_new_run("PC02")
	GameState.xp = 2000
	GameState.meta["Funds"] = 400000
	GameState.add_item("SH21")
	# The Office itself, then each panel on a fresh Office.
	await _go(OFFICE)
	_measure("Office")
	for panel: String in OFFICE_PANELS:
		await _go(OFFICE)
		var office := get_tree().current_scene
		if office.has_method(panel):
			office.call(panel)
			await get_tree().create_timer(0.5).timeout
			_measure("Office > " + panel.trim_prefix("_show_"))
	await _go(OFFICE)
	get_tree().current_scene.call("_open_draft", true)
	await get_tree().create_timer(0.5).timeout
	_measure("Office > draft a bill")
	# Battle (and its Details panel), a dilemma room, the Level Intro and its stance row.
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV01"))))
	await _go(StageRouting.BATTLE_SCENE)
	await get_tree().create_timer(0.8).timeout
	_measure("Battle")
	var battle := get_tree().current_scene
	if battle.get("_details_button") != null:
		(battle.get("_details_button") as Button).pressed.emit()
		await get_tree().create_timer(0.4).timeout
		_measure("Battle > details")
	GameState.level_runner.finish_stage(LevelRunner.WON)
	await _go(StageRouting.VISITOR_SCENE)
	_measure("Office Hours (a dilemma)")
	GameState.end_level()
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV66"))))
	await _go(StageRouting.LEVEL_INTRO_SCENE)
	_measure("Level Intro (first line)")
	var screen := get_tree().current_scene
	for _i in 12:
		if screen.get("_lean_shown"):
			break
		screen.get_node("CueBanner").call("clear")
		screen.set("_lines_accounted_for", screen.get("_total_lines"))
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout
	_measure("Level Intro (stance)")
	GameState.end_level()
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV66"))))
	while str(GameState.level_runner.current_stage().get("mode", "")) != "Vote":
		GameState.finish_stage(LevelRunner.WON)
	await _go(StageRouting.FLOOR_VOTE_SCENE)
	await get_tree().create_timer(0.8).timeout
	_measure("Floor Vote")
	var vote := get_tree().current_scene
	vote.call("_on_vote", "Yes")
	await get_tree().create_timer(0.8).timeout
	_measure("Floor Vote result")
	GameState.end_level()
	var out := OS.get_environment("AUDIT_OUT")
	if out.is_empty():
		out = "res://design/review/mc2t_targets.json"
	var file := FileAccess.open(out, FileAccess.WRITE)
	file.store_string(JSON.stringify(_rows, "  "))
	file.close()
	print("TARGET AUDIT: wrote %d targets to %s" % [_rows.size(), out])
	get_tree().quit(0)


func _go(path: String) -> void:
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().create_timer(0.8).timeout


## Every visible tappable control under the current scene, with its size.
func _measure(screen_name: String) -> void:
	# SHOT_DIR=/some/dir also saves a picture of each screen as it is measured.
	var shot_dir := OS.get_environment("SHOT_DIR")
	if shot_dir != "":
		var image := get_viewport().get_texture().get_image()
		image.save_png(shot_dir.path_join(screen_name.replace(" ", "_").replace(">", "").replace("(", "").replace(")", "") + ".png"))
	if get_tree().current_scene != null:
		_walk(get_tree().current_scene, screen_name)


func _walk(node: Node, screen_name: String) -> void:
	if node is Control:
		var control := node as Control
		var tappable := control is BaseButton or control is Range or str(control.get_script().get_global_name() if control.get_script() != null else "") in ["CardView"]
		if tappable and control.is_visible_in_tree() and control.size.x > 4.0 and control.size.y > 4.0 \
				and control.mouse_filter != Control.MOUSE_FILTER_IGNORE and control.modulate.a > 0.1:
			var text := ""
			if control is Button:
				text = (control as Button).text.substr(0, 40)
			var rect := control.get_global_rect()
			_rows.append({"screen": screen_name, "class": control.get_class(),
				"script": str(control.get_script().get_global_name() if control.get_script() != null else ""),
				"name": str(control.name), "text": text, "w": rect.size.x, "h": rect.size.y,
				"disabled": (control as BaseButton).disabled if control is BaseButton else false,
				"x": rect.position.x, "y": rect.position.y})
	for child in node.get_children():
		_walk(child, screen_name)
