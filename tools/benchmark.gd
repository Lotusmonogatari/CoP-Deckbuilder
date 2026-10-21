extends Node
## Performance benchmark (2026-10-11, Cameron: "measure results before
## implementing optimization").
##
## Measures what a player feels: how long the game takes to load its data,
## how long each screen takes to appear, how long a battle screen takes to
## redraw after a card or a turn, how long each Office panel takes to open,
## and how much memory the game holds. Not part of tools/verify.sh: timings
## vary between machines, so this is a before/after tool, not a pass/fail
## gate. Run it through tools/bench.sh, which runs it twice (headless and
## with a virtual display) and compares results.
##
##     .tools/godot --headless --path . tools/benchmark.tscn
##     BENCH_OUT=/path/result.json  (where the JSON goes; default user://)
##     BENCH_RUNS=9                 (repeats per measurement; the median wins)
##
## Every number is in milliseconds unless its name says otherwise. A screen's
## "cold" time is its very first load in this process (files read from disk);
## "warm" is the median of later loads, when Godot already has it cached.
##
## How far to trust it: timings on a shared machine wander by 20-70% between
## identical runs (measured 2026-10-11), so a single run only shows large
## changes. Memory figures are steady run to run and are the reliable ones.
## bench.sh --compare flags a timing only when it is more than 30% worse.

const OFFICE := "res://scenes/office_hours/OfficeScreen.tscn"
const BATTLE := "res://scenes/battle/BattleScreen.tscn"
const SCENES := [
	"res://scenes/office_hours/OfficeScreen.tscn",
	"res://scenes/battle/BattleScreen.tscn",
	"res://scenes/office_hours/VisitorScreen.tscn",
	"res://scenes/office_hours/FloorVoteScreen.tscn",
	"res://scenes/office_hours/LevelIntroScreen.tscn",
]
## A real level and stage with a full shared-pool battle (Floor Debate).
const BATTLE_LEVEL := "LV08"
const BATTLE_STAGE := "ST02"
## Fixed so two runs play the same battle.
const SEED := 20261011
const PROTAGONIST := "PC02"
## Office panels opened one after another, the way a player browses them.
const OFFICE_PANELS := ["_show_levels", "_show_management", "_show_marketplace",
	"_show_reputation_menu", "_show_organisations", "_show_backing",
	"_show_parties", "_show_record", "_show_staff", "_show_deck",
	"_show_administration_menu", "_show_cosmetics"]

var _runs := 5
var _results := {}


func _ready() -> void:
	_runs = maxi(1, int(OS.get_environment("BENCH_RUNS")) if OS.get_environment("BENCH_RUNS") != "" else 9)
	_run.call_deferred()


func _run() -> void:
	await get_tree().process_frame
	_results["meta"] = {
		"date": Time.get_datetime_string_from_system(),
		"headless": DisplayServer.get_name() == "headless",
		"renderer": RenderingServer.get_video_adapter_name(),
		"runs": _runs,
	}
	_results["memory_start_mb"] = _memory()

	await _bench_data_load()
	seed(SEED)
	GameState.start_new_run(PROTAGONIST)
	await _bench_scenes()
	await _bench_office_panels()
	await _bench_battle()
	_results["memory_end_mb"] = _memory()

	_write()
	get_tree().quit(0)


# ---------------------------------------------------------------------------
# What is measured
# ---------------------------------------------------------------------------

func _bench_data_load() -> void:
	var times: Array[float] = []
	for i in _runs:
		var started := Time.get_ticks_usec()
		DataDB.load_all()
		times.append(_ms_since(started))
	_results["data_load_ms"] = _median(times)


## Cold load, then warm loads, of every screen: load the scene file, build
## it, add it to the tree and let it draw two frames.
func _bench_scenes() -> void:
	var scenes := {}
	for path: String in SCENES:
		var cold := await _open_scene(path)
		var warm: Array[float] = []
		for i in _runs:
			warm.append(await _open_scene(path))
		scenes[path.get_file().get_basename()] = {"cold_ms": cold, "warm_ms": _median(warm)}
	_results["scenes"] = scenes
	_results["memory_after_scenes_mb"] = _memory()


func _open_scene(path: String) -> float:
	var started := Time.get_ticks_usec()
	var node := (load(path) as PackedScene).instantiate()
	if node.get("level_id") != null:
		node.set("level_id", BATTLE_LEVEL)
		node.set("stage_id", BATTLE_STAGE)
	get_tree().root.add_child(node)
	await get_tree().process_frame
	await get_tree().process_frame
	var took := _ms_since(started)
	node.queue_free()
	await get_tree().process_frame
	return took


## Each Office panel opened and closed: the time to build its rows and draw.
func _bench_office_panels() -> void:
	var office := (load(OFFICE) as PackedScene).instantiate()
	get_tree().root.add_child(office)
	await get_tree().process_frame
	var panels := {}
	for method: String in OFFICE_PANELS:
		if not office.has_method(method):
			continue
		var times: Array[float] = []
		for i in _runs:
			var started := Time.get_ticks_usec()
			office.call(method)
			await get_tree().process_frame
			times.append(_ms_since(started))
			_close_all_overlays(office)
			await get_tree().process_frame
		panels[method.trim_prefix("_show_")] = _median(times)
	_results["office_panels_ms"] = panels
	office.queue_free()
	await get_tree().process_frame


## A real battle on the real screen: how long the screen takes to redraw
## after each card and each turn (the moment a player waits on), plus the
## same moves on the rules engine alone, so screen cost and rules cost can
## be told apart.
func _bench_battle() -> void:
	var screen := (load(BATTLE) as PackedScene).instantiate()
	screen.set("level_id", BATTLE_LEVEL)
	screen.set("stage_id", BATTLE_STAGE)
	get_tree().root.add_child(screen)
	await get_tree().process_frame

	var card_refresh: Array[float] = []
	var turn_refresh: Array[float] = []
	var engine_card: Array[float] = []
	var engine_turn: Array[float] = []
	var cards_played := 0
	var turns := 0
	var battles := 1
	while turns < 40:
		var engine: BattleEngine = screen.get("engine")
		if engine == null:
			break
		if engine.state.outcome != "ongoing":
			screen.call("start_battle")
			battles += 1
			await get_tree().process_frame
			continue
		var card := _affordable_card(engine)
		if card != "":
			var started := Time.get_ticks_usec()
			engine.play_card(card)
			engine_card.append(_ms_since(started))
			started = Time.get_ticks_usec()
			screen.call("_refresh")
			await get_tree().process_frame
			card_refresh.append(_ms_since(started))
			cards_played += 1
			continue
		var turn_started := Time.get_ticks_usec()
		engine.end_turn()
		engine_turn.append(_ms_since(turn_started))
		turn_started = Time.get_ticks_usec()
		screen.call("_refresh")
		await get_tree().process_frame
		turn_refresh.append(_ms_since(turn_started))
		turns += 1

	_results["battle"] = {
		"stage": "%s/%s" % [BATTLE_LEVEL, BATTLE_STAGE],
		"cards_played": cards_played,
		"turns": turns,
		"battles": battles,
		"refresh_after_card_ms": _median(card_refresh),
		"refresh_after_card_max_ms": _max(card_refresh),
		"refresh_after_turn_ms": _median(turn_refresh),
		"engine_play_card_ms": _median(engine_card),
		"engine_end_turn_ms": _median(engine_turn),
		"nodes_in_battle_screen": _count_nodes(screen),
	}
	screen.queue_free()
	await get_tree().process_frame


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _affordable_card(engine: BattleEngine) -> String:
	for card_id: String in engine.state.hand:
		var card := DataDB.get_card(card_id)
		if int(card.get("cost", 99)) <= engine.state.energy and engine.discard_required(card) == 0:
			return card_id
	return ""


func _close_all_overlays(root: Node) -> void:
	for child in root.get_children():
		if child is Overlay and (child as Overlay).visible:
			(child as Overlay).close()


func _count_nodes(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _count_nodes(child)
	return total


func _memory() -> Dictionary:
	return {
		"static_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
		"texture_mb": snappedf(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0, 0.1),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
	}


func _ms_since(started_usec: int) -> float:
	return snappedf((Time.get_ticks_usec() - started_usec) / 1000.0, 0.01)


func _median(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[sorted.size() / 2]


func _max(values: Array[float]) -> float:
	return values.max() if not values.is_empty() else 0.0


func _write() -> void:
	var out := OS.get_environment("BENCH_OUT")
	if out.is_empty():
		out = "user://benchmark.json"
	var file := FileAccess.open(out, FileAccess.WRITE)
	if file == null:
		push_error("benchmark: cannot write %s" % out)
		return
	file.store_string(JSON.stringify(_results, "  "))
	print("BENCHMARK written to ", out)
	print(JSON.stringify(_results, "  "))
