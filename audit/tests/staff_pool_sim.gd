extends Node
## Audit/tuning (2026-11-16, expansion phase 6): how big are the days' task pools
## against what 1, 3 and 6 staff can do? Draws thousands of days with the real
## draw (StaffTasks.draw_pool) under a calm and a stressed game state, at each
## stage of the ramp, and prints a table.
##
##   .tools/godot --headless --path . audit/tests/staff_pool_sim.tscn

const DAYS := 3000
const CALM := {"dues_owed": 0, "open_promises": 0, "district_awareness": 40, "national_awareness": 40, "reputation": 45,
	"constituency_support": 40, "party_support": 40, "level_in_progress": 0, "avg_staff_loyalty": 50, "weekday": 3}
const STRESSED := {"dues_owed": 50000, "open_promises": 6, "district_awareness": 20, "national_awareness": 70, "reputation": 25,
	"constituency_support": 12, "party_support": 20, "level_in_progress": 1, "avg_staff_loyalty": 20, "weekday": 5}


func _ready() -> void:
	_run.call_deferred()


func _hours(pool: Array) -> int:
	var total := 0
	for entry: Dictionary in pool:
		total += int(StaffTasks.task_for(DataDB.staff_tasks, str(entry["task_id"])).get("blocks", 0))
	return total


func _due(pool: Array) -> int:
	var count := 0
	for entry: Dictionary in pool:
		if not StaffTasks.parse_effects(StaffTasks.task_for(DataDB.staff_tasks, str(entry["task_id"])).get("due_penalty")).is_empty():
			count += 1
	return count


func _row(label: String, week: int, state: Dictionary) -> String:
	GameState.start_new_run("PC01")
	var targets := GameState._staff_task_targets()
	var sizes := 0
	var hours := 0
	var due := 0
	var over := {1: 0, 3: 0, 6: 0}
	var empty := 0
	var maximum := StaffTasks.day_maximum(DataDB.staff_task_ramp, week, false, 0)
	for day in DAYS:
		var rng := RandomNumberGenerator.new()
		rng.seed = day * 7919 + week
		var changes := StaffPoolModifiers.from_drivers(DataDB.staff_task_drivers, state, rng)
		var pool := StaffTasks.draw_pool(DataDB.staff_tasks, DataDB.staff_task_families, targets,
			StaffTasks.day_maximum(DataDB.staff_task_ramp, week, false, int(changes["max_delta"])), false, changes["adds"], rng)
		sizes += pool.size()
		var h := _hours(pool)
		hours += h
		due += _due(pool)
		if pool.is_empty():
			empty += 1
		for staff_count: int in over.keys():
			if h > staff_count * 8:
				over[staff_count] += 1
	return "| %s | week %d (max %d) | %.1f | %.1f | %.1f | %d%% | %d%% | %d%% | %d%% |" % [label, week + 1, maximum,
		float(sizes) / DAYS, float(hours) / DAYS, float(due) / DAYS,
		100 * over[1] / DAYS, 100 * over[3] / DAYS, 100 * over[6] / DAYS, 100 * empty / DAYS]


func _run() -> void:
	print("")
	print("| State | Week | Tasks a day | Task hours a day | Due tasks a day | Hours beyond 1 staff | beyond 3 | beyond 6 | Empty days |")
	print("|---|---|---|---|---|---|---|---|---|")
	for week in [1, 2, 3, 4, 8]:
		print(_row("calm", week, CALM))
		print(_row("stressed", week, STRESSED))
	get_tree().quit(0)
