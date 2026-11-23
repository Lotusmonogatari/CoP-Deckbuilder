extends Node
## P15 review screenshots (2026-11-23): the whip scene's card at each Party support band, the whip stage's first turn and the
## locked Floor Vote, in each UI style. Needs a real display:
##   P15_SHOTS_DIR=design/review/p15_cptpp_whip_2026-11-23 xvfb-run -a -s "-screen 0 1080x2340x24" .tools/godot --path . tools/p15_shots.tscn

const BANDS := [["assistant", 10], ["deputy", 50], ["chief", 80], ["minister", 93], ["leader", 99]]
var _dir := ""


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_dir = OS.get_environment("P15_SHOTS_DIR")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://") + _dir)
	OS.unset_environment("COP_NO_RANDOM_EVENTS")
	for style: String in UiStyles.ALL:
		UiStyle.trying = style
		for band: Array in BANDS:
			_fresh_state()
			var party := DataDB.get_party(str(DataDB.player.get("party", "")))
			var minister := DataDB.get_opponent("OP82")
			GameState.whip_picks = {"DS07": WhipPick.pick(int(band[1]), DataDB.rules.get("whip_bands", {}), party, minister)}
			await _open_office()
			await _shot("%s_whip_card_%s_support_%d" % [style, str(band[0]), int(band[1])])
		_fresh_state()
		GameState.whip_picks = {"DS07": "OP133"}
		GameState.apply_event_choice("EV116", "C")
		var next := GameState.next_activation()
		var runner := LevelRunner.new(BattleSetup.expand_level(next["level"] as Dictionary))
		GameState.finish_activation(str((next["level"] as Dictionary)["level_id"]))
		GameState.begin_level(runner)
		get_tree().change_scene_to_file(StageRouting.scene_for(runner.current_stage()))
		await get_tree().create_timer(1.2).timeout
		await _shot("%s_whip_stage_first_turn" % style)
		GameState.abandon_level()
		_fresh_state()
		GameState.whip_locks = {"BI52": [{"choice": "Yes", "by": "OP133", "scene_id": "DS07"}]}
		DataDB.register_runtime_level(DecisionScenes.ad_hoc_level("vote", "BI52", "Joining the CPTPP", "Capitol"))
		var vote_runner := LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("DSL_vote_BI52")))
		GameState.begin_level(vote_runner)
		get_tree().change_scene_to_file(StageRouting.scene_for(vote_runner.current_stage()))
		await get_tree().create_timer(1.0).timeout
		await _shot("%s_floor_vote_locked" % style)
		GameState.abandon_level()
	SaveManager.delete_save()
	get_tree().quit(0)


func _fresh_state() -> void:
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.office_location = Offices.CAPITOL
	GameState.calendar = {"week": 3, "phase": "work", "hours": 8 * 4}
	GameState.dated_events_done = ["EV47", "EV111"]
	var monday := WeekCalendar.parse_date("18.10.22")
	var thursday := WeekCalendar.parse_date("18.10.25")
	GameState.decision_log = {"DS01": {"day": 0, "choice": "A"}, "DS02": {"day": monday, "choice": "A"},
		"DS03": {"day": thursday, "choice": "A"}, "DS05": {"day": thursday, "choice": "A"}, "DS06": {"day": thursday, "choice": "A"}}
	GameState.pending_activations = []
	GameState.whip_locks = {}


func _open_office() -> void:
	get_tree().change_scene_to_file("res://scenes/office_hours/OfficeScreen.tscn")
	await get_tree().process_frame
	await get_tree().create_timer(0.9).timeout


func _shot(name: String) -> void:
	await get_tree().process_frame
	var image := get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path("res://") + _dir + "/" + name + ".png"
	image.save_png(path)
	print("saved " + path)
