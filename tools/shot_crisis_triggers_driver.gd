extends Node
## The work for shot_crisis_triggers.tscn, kept outside the scene it changes
## away from.

const SHOTS := "user://shots/"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(SHOTS)

	GameState.start_new_run("PC04")
	print("Very Hard start — Jiban=%s Party support=%s" % [
		GameState.meta.get("Constituency support"), GameState.meta.get("Party support")])

	# A multi-stage level (LV03: ST05, ST20, ST21) rather than LV01 (a
	# single ST05) — the crisis triggers only ever insert into a level that
	# is still going, so a one-stage level proves the "nowhere to put it,
	# defer to next time" half of the design but not the insertion itself.
	var level := BattleSetup.expand_level(DataDB.levels[2])
	GameState.begin_level(LevelRunner.new(level))

	# Finishing the very first stage re-checks every crisis trigger against
	# Very Hard's starting numbers (Jiban 5, Party support 0) — all three
	# should fire on this one call.
	GameState.finish_stage(LevelRunner.WON, 0, [])

	print("town_hall_active=", GameState.town_hall_active)
	print("steering_committee_active=", GameState.steering_committee_active)
	print("funding_frozen_active=", GameState.funding_frozen_active)
	print("pending_trigger_alerts=", GameState.pending_trigger_alerts)

	var stage_ids: Array = []
	if GameState.level_runner != null:
		for s: Dictionary in GameState.level_runner.stages:
			stage_ids.append(s.get("stage_id"))
	print("stage queue now: ", stage_ids)

	get_tree().change_scene_to_file("res://scenes/office_hours/OfficeScreen.tscn")
	await get_tree().create_timer(1.0).timeout
	await _shot("50-office-crisis-alert")

	print("SHOTS DONE")
	get_tree().quit()


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(SHOTS + shot_name + ".png")
	print("  wrote ", shot_name)
