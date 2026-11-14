class_name AuditTechProbe
extends Node
## The driver lives on the scene root so it survives scene changes.

const OFFICE := "res://scenes/office_hours/OfficeScreen.tscn"
var _out := {}


func _ready() -> void:
	_run.call_deferred()


func _settle(frames: int = 30) -> void:
	for i in frames:
		await get_tree().process_frame


func _frame_numbers() -> Dictionary:
	var draws: Array[int] = []
	for i in 20:
		await get_tree().process_frame
		draws.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	draws.sort()
	return {"draw_calls_median": draws[draws.size() / 2], "draw_calls_max": draws[draws.size() - 1],
		"objects_drawn": int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"processing": _processing(get_tree().root)}


## Scripted nodes that are still asked to run _process each frame.
func _processing(node: Node) -> Array:
	var found := []
	if node != self and node.is_processing() and node.get_script() != null and node.has_method("_process"):
		found.append("%s (%s)" % [node.name, str(node.get_script().resource_path).get_file()])
	for child in node.get_children():
		found.append_array(_processing(child))
	return found


func _memory() -> Dictionary:
	return {"static_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.01),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"texture_mb": snappedf(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, 0.01)}


func _open_battle() -> void:
	var runner := LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV08")))
	GameState.begin_level(runner)
	get_tree().change_scene_to_file(StageRouting.scene_for(runner.current_stage()))
	await _settle(40)


func _run() -> void:
	seed(7)
	DataDB.clear_runtime()
	GameState.start_new_run("PC02")
	get_tree().change_scene_to_file(OFFICE)
	await _settle(60)
	_out["office_idle"] = await _frame_numbers()
	await _open_battle()
	_out["battle_idle"] = await _frame_numbers()
	_out["battle_scene"] = str(get_tree().current_scene.name)

	# Memory across repeated stage loads: battle, back to the Office, 40 times.
	GameState.level_runner = null
	get_tree().change_scene_to_file(OFFICE)
	await _settle(30)
	var before := _memory()
	for i in 40:
		await _open_battle()
		GameState.level_runner = null
		GameState.mid_stage = false
		get_tree().change_scene_to_file(OFFICE)
		await _settle(12)
	await _settle(30)
	var after := _memory()
	_out["memory_before_40_loops"] = before
	_out["memory_after_40_loops"] = after

	# Save: time, size, and a round trip of every saved field.
	var times: Array[int] = []
	for i in 15:
		var started := Time.get_ticks_usec()
		SaveManager.save_game("user://audit_probe_save.json")
		times.append(Time.get_ticks_usec() - started)
	times.sort()
	var size := FileAccess.get_file_as_bytes("user://audit_probe_save.json").size()
	var snapshot := {}
	for field: String in GameState._SAVED_FIELDS:
		snapshot[field] = var_to_str(GameState.get(field))
	GameState.xp += 12345           # disturb the state, then load it back
	GameState.meta["Funds"] = 1
	var loaded := SaveManager.load_game("user://audit_probe_save.json")
	var changed := []
	for field: String in GameState._SAVED_FIELDS:
		if var_to_str(GameState.get(field)) != snapshot[field]:
			changed.append(field)
	_out["save"] = {"median_ms": snappedf(times[times.size() / 2] / 1000.0, 0.01), "max_ms": snappedf(times[times.size() - 1] / 1000.0, 0.01),
		"bytes": size, "loaded": loaded, "saved_fields": GameState._SAVED_FIELDS.size(), "fields_changed_by_round_trip": changed}
	SaveManager.delete_save("user://audit_probe_save.json")

	var path := OS.get_environment("AUDIT_OUT")
	if path.is_empty():
		path = "user://audit_tech_probe.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_out, "\t"))
	file.close()
	print("AUDIT TECH PROBE written to %s" % path)
	get_tree().quit(0)
