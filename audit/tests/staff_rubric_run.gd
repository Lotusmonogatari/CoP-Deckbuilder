extends Node
## Staff Assignments rubric run (2026-11-16; design/STAFF_ASSIGNMENTS_RUBRIC.md).
## Plays the real mechanic (GameState, StaffTasks) day by day with four kinds of
## player, over 20 back-to-back days and 10 Office visits interrupted by levels,
## measures the rubric's numbers and prints a markdown report.
##
##   .tools/godot --headless --path . audit/tests/staff_rubric_run.tscn

const METAS := ["Constituency support", "Reputation", "Funds", "Party support"]
const STAFF := ["SF04", "SF08", "SF18"]    # a researcher, a media spokesperson, a district representative
const DAY_HOURS := 8


# ---------------------------------------------------------------------------
# Setup and helpers
# ---------------------------------------------------------------------------

var _staff_ids: Array = STAFF


func _new_run(week: int, staffed: bool) -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	GameState.staff_recruitment_tier = 2
	GameState.meta["Funds"] = 800000
	GameState.funds_cap_bonus = 800000   # so gains of Funds are not clipped by the starting cap
	GameState.calendar["week"] = week
	if staffed:
		for id: String in _staff_ids:
			GameState.hire_staff(id)
	_refresh_funds()


## Funds are kept high so wages and dues are never the story of a run.
func _refresh_funds() -> void:
	GameState.meta["Funds"] = 800000
	GameState.dues_balance = 0


func _today() -> int:
	return WeekCalendar.today_number(GameState.calendar, GameState.calendar_config())


func _meta_snapshot() -> Dictionary:
	var out := {}
	for name: String in METAS:
		out[name] = int(GameState.meta.get(name, 0))
	out["XP"] = GameState.xp
	return out


func _diff(after: Dictionary, before: Dictionary) -> Dictionary:
	var out := {}
	for key: String in after.keys():
		out[key] = int(after[key]) - int(before.get(key, 0))
	return out


func _points(diff: Dictionary) -> int:
	# Constituency support, Reputation, Party support and XP (Funds are reported on their own).
	var total := 0
	for key: String in diff.keys():
		if key != "Funds":
			total += int(diff[key])
	return total


func _members() -> Array:
	return GameState._staff_eval_members()


func _fit(task: Dictionary, member: Dictionary) -> String:
	return StaffTasks.effective_fit(task, str(member["role"]), int(member["loyalty"]))


func _task_of(entry: Dictionary) -> Dictionary:
	return StaffTasks.task_for(DataDB.staff_tasks, str(entry["task_id"]))


func _hours_of(entry: Dictionary) -> int:
	return int(_task_of(entry).get("blocks", 1))


func _is_due(entry: Dictionary) -> bool:
	return not StaffTasks.parse_effects(_task_of(entry).get("due_penalty")).is_empty()


func _is_time_off(entry: Dictionary) -> bool:
	return str(_task_of(entry).get("kind", "")) == StaffTasks.KIND_TIME_OFF


func _room(member: Dictionary) -> int:
	return GameState.staff_blocks_left(str(member["staff_id"]))


# ---------------------------------------------------------------------------
# The players
# ---------------------------------------------------------------------------

func _assign_best() -> void:
	var members := _members()
	var left: Array = []
	for entry: Dictionary in GameState.staff_day_pool:
		left.append(entry)
	# 1. Due tasks, to the best fit that is not poor.
	for entry: Dictionary in left.duplicate():
		if _is_due(entry) and not _is_time_off(entry):
			if _give_best(entry, members, ["strong", "fair"]):
				left.erase(entry)
	# 2. Strong fits.
	for entry: Dictionary in left.duplicate():
		if not _is_time_off(entry) and _give_best(entry, members, ["strong"]):
			left.erase(entry)
	# 3. Time off to the least loyal person with room.
	for entry: Dictionary in left.duplicate():
		if _is_time_off(entry):
			var order := members.duplicate()
			order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["loyalty"]) < int(b["loyalty"]))
			for member: Dictionary in order:
				if _room(member) >= _hours_of(entry) and GameState.staff_assign(str(entry["uid"]), str(member["staff_id"])).is_empty():
					left.erase(entry)
					break
	# 4. Fair fits to fill the day.
	for entry: Dictionary in left.duplicate():
		if not _is_time_off(entry) and _give_best(entry, members, ["fair"]):
			left.erase(entry)


## Gives a task to the person with the most room whose fit is among `allowed`.
func _give_best(entry: Dictionary, members: Array, allowed: Array) -> bool:
	var best: Dictionary = {}
	var best_rank := 99
	for member: Dictionary in members:
		var fit := _fit(_task_of(entry), member)
		if not allowed.has(fit) or _room(member) < _hours_of(entry):
			continue
		var rank := ["strong", "fair", "poor"].find(fit) * 100 - _room(member)
		if rank < best_rank:
			best_rank = rank
			best = member
	if best.is_empty():
		return false
	return GameState.staff_assign(str(entry["uid"]), str(best["staff_id"])).is_empty()


func _assign_random(rng: RandomNumberGenerator) -> void:
	var members := _members()
	for entry: Dictionary in GameState.staff_day_pool:
		var order := members.duplicate()
		order.shuffle()
		for member: Dictionary in order:
			if _room(member) >= _hours_of(entry) and GameState.staff_assign(str(entry["uid"]), str(member["staff_id"])).is_empty():
				break


# ---------------------------------------------------------------------------
# One run
# ---------------------------------------------------------------------------

## policy: best, random, ignore, nostaff. `visits` is how many Office days to play;
## `level_hours` (empty for back-to-back) the hours that pass after each visit.
func _play(policy: String, week: int, visits: int, level_hours: Array = [], staff_ids: Array = STAFF) -> Dictionary:
	_staff_ids = staff_ids
	_new_run(week, policy != "nostaff")
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var stats := {"policy": policy, "visits": visits, "pool_sizes": [], "pool_ids": [], "families_seen": {}, "task_hours": [],
		"due": [], "due_visits": 0, "assigned": 0, "fits": {"strong": 0, "fair": 0, "poor": 0},
		"day_points": [], "day_funds": [], "wage_bill": 0, "meta_gain_max": 0, "meta_loss_max": 0, "projection_checks": 0, "projection_exact": 0,
		"skipped_days": 0, "skipped_exact": 0, "settled_exact_day": 0, "time_off_offered": 0, "time_off_taken": 0,
		"person_days": 0, "idle_days": 0, "full_days": 0, "empty_days": 0, "elapsed_days": 0,
		"loyalty_start": {}, "loyalty_end": {}, "weekly": [], "funds": 0, "xp": 0, "same_pool_twice": 0, "log": []}
	for id: String in _staff_ids:
		stats["loyalty_start"][id] = GameState.staff_loyalty_of(id) if policy != "nostaff" else 0
	var week_before := _meta_snapshot()
	stats["wage_bill"] = int(GameState.staff_wage_preview()["total"])
	var last_signature := ""
	for visit in visits:
		GameState.staff_ensure_day()
		var pool := GameState.staff_day_pool
		var signature := ",".join(PackedStringArray(pool.map(func(e: Dictionary) -> String: return str(e["task_id"]))))
		if signature == last_signature and not pool.is_empty():
			stats["same_pool_twice"] += 1
		last_signature = signature
		(stats["pool_sizes"] as Array).append(pool.size())
		var hours := 0
		var due_count := 0
		var off_in_pool := false
		for entry: Dictionary in pool:
			hours += _hours_of(entry)
			(stats["pool_ids"] as Array).append(str(entry["task_id"]))
			stats["families_seen"][str(_task_of(entry).get("family", ""))] = true
			if _is_due(entry):
				due_count += 1
			if _is_time_off(entry):
				off_in_pool = true
		(stats["task_hours"] as Array).append(hours)
		(stats["due"] as Array).append(due_count)
		if pool.is_empty():
			stats["empty_days"] += 1
		if off_in_pool:
			stats["time_off_offered"] += 1
		# The player acts.
		var confirmed := false
		match policy:
			"best":
				_assign_best()
			"random":
				_assign_random(rng)
		if policy in ["best", "random"] and GameState.staff_confirm_refusal().is_empty():
			var projection := GameState.staff_projection()
			for line: Dictionary in projection["lines"]:
				stats["assigned"] += 1
				stats["fits"][str(line["fit"])] += 1
				if str(_task_of(StaffTasks.entry_for(pool, str(line["uid"]))).get("kind", "")) == StaffTasks.KIND_TIME_OFF:
					stats["time_off_taken"] += 1
			for id: String in (projection["used"] as Dictionary).keys():
				stats["person_days"] += 1
				var used := int(projection["used"][id])
				if used <= 0:
					stats["idle_days"] += 1
				elif used >= GameState.staff_day_hours(id):
					stats["full_days"] += 1
			GameState.staff_confirm_day()
			confirmed = true
			stats["_projection"] = projection
		# Time passes: a level's hours, or the rest of the day.
		var hours_passing: int = DAY_HOURS if level_hours.is_empty() else int(level_hours[visit % level_hours.size()])
		var day_before := _today()
		var before := _meta_snapshot()
		var projected_meta := {}
		if confirmed:
			var p: Dictionary = stats["_projection"]
			projected_meta = (p["meta"] as Dictionary).duplicate()
			projected_meta["XP"] = int(p["xp"])
		var key_before: int = GameState.staff_day_key
		GameState.spend_hours(hours_passing)
		var friday_full := GameState.work_week_is_full()
		var gap := _today() - key_before
		GameState.staff_day_sync(friday_full)   # the week's end settles the day it leaves
		var after := _meta_snapshot()
		var delta := _diff(after, before)
		var resolved := not GameState.staff_report_pending.is_empty()
		GameState.staff_report_pending = {}
		stats["elapsed_days"] += maxi(1, _today() - day_before) if not friday_full else 1
		# Skipped by a long level: nothing may change.
		if gap > 1 and not friday_full:
			stats["skipped_days"] += 1
			if _points(delta) == 0 and not resolved:
				stats["skipped_exact"] += 1
		elif confirmed and resolved:
			stats["projection_checks"] += 1
			var exact := true
			for name: String in METAS + ["XP"]:
				if int(delta.get(name, 0)) != int(projected_meta.get(name, 0)):
					exact = false
			if exact:
				stats["projection_exact"] += 1
			else:
				(stats["log"] as Array).append("  projection mismatch: projected %s, applied %s" % [str(projected_meta), str(delta)])
		if gap == 1 and not friday_full and resolved:
			stats["settled_exact_day"] += 1
		var day_points := _points(delta)
		(stats["day_points"] as Array).append(day_points)
		(stats["day_funds"] as Array).append(int(delta.get("Funds", 0)))
		for name: String in METAS:
			if name == "Funds":
				continue
			stats["meta_gain_max"] = maxi(int(stats["meta_gain_max"]), int(delta.get(name, 0)))
			stats["meta_loss_max"] = mini(int(stats["meta_loss_max"]), int(delta.get(name, 0)))
		(stats["log"] as Array).append("%d tasks, %dh, %d due, %s, %+d pts" % [pool.size(), hours, due_count,
			("confirmed" if confirmed else policy), day_points])
		if friday_full:
			var week_after := _meta_snapshot()
			var week_report := GameState.go_home()
			var loyalty_now := {}
			for id: String in _staff_ids:
				loyalty_now[id] = GameState.staff_loyalty_of(id) if not GameState.hired_member(id).is_empty() else -1
			(stats["log"] as Array).append("  parts of the week's Loyalty change (%s): %s" % [_staff_ids[0], str(GameState.staff_last_week.get(_staff_ids[0], {}))])
			(stats["log"] as Array).append("  week end: Loyalty %s; wages paid %d; quit %s" % [str(loyalty_now),
				int((week_report.get("staff", {}) as Dictionary).get("paid_total", 0)), str((week_report.get("staff", {}) as Dictionary).get("quit", []))])
			stats["weekly"].append(_diff(_meta_snapshot(), week_before))
			_refresh_funds()
			week_before = _meta_snapshot()
	for id: String in _staff_ids:
		stats["loyalty_end"][id] = GameState.staff_loyalty_of(id) if policy != "nostaff" else 0
	stats["funds"] = 0
	return stats


# ---------------------------------------------------------------------------
# Numbers and verdicts
# ---------------------------------------------------------------------------

func _mean(values: Array) -> float:
	var total := 0.0
	for value: Variant in values:
		total += float(value)
	return total / maxf(1.0, float(values.size()))


func _verdict(value: float, pass_low: float, pass_high: float, warn_low: float, warn_high: float) -> String:
	if value >= pass_low and value <= pass_high:
		return "PASS"
	if value >= warn_low and value <= warn_high:
		return "WARN"
	return "FAIL"


var _results: Array = []


func _row(id: String, label: String, value: String, verdict: String, note: String = "") -> void:
	_results.append("| %s | %s | %s | **%s** | %s |" % [id, label, value, verdict, note])


func _run() -> void:
	# A1: the ramp from a new game; A2: full volume; the other players at full volume; B: interrupted.
	var a1 := _play("best", 0, 20)
	var a2 := _play("best", 4, 20)
	var rnd := _play("random", 4, 20)
	var ign := _play("ignore", 4, 20)
	var nos := _play("nostaff", 4, 20)
	# Real level lengths, in hours, from the data (a spread of short and long levels).
	var lengths: Array = []
	for level: Dictionary in DataDB.levels:
		var h := GameState.level_hours(level)
		if h > 0:
			lengths.append(h)
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var picked: Array = []
	for _i in 10:
		picked.append(lengths[rng.randi_range(0, lengths.size() - 1)])
	var one := _play("best", 4, 20, [], ["SF04"])
	var two := _play("best", 4, 20, [], ["SF04", "SF08"])
	var b := _play("best", 4, 10, picked)
	var b_ign := _play("ignore", 4, 10, picked)

	print("")
	print("# Staff Assignments rubric run")
	print("")
	print("Level lengths used for the interrupted run (hours): %s" % str(picked))
	print("")
	print("## Day logs")
	for run: Dictionary in [a1, a2, b]:
		print("")
		print("**%s, %d visits**" % [run["policy"], run["visits"]])
		var day := 0
		for line: String in run["log"]:
			day += 1
			print("- visit %d: %s" % [day, line])

	# ---- D1
	var ramp_sizes: Array = []
	for week in 4:
		var slice := (a1["pool_sizes"] as Array).slice(week * 5, week * 5 + 5)
		ramp_sizes.append(slice)
	var ramp_ok := true
	for week in 4:
		for size: Variant in ramp_sizes[week]:
			if int(size) != week:
				ramp_ok = false
	_row("R1.1", "Tasks a day, weeks 1 to 4", str(ramp_sizes), "PASS" if ramp_ok else "FAIL")
	var mean_pool := _mean(a2["pool_sizes"])
	_row("R1.2", "Mean tasks a day, full volume", "%.1f" % mean_pool, _verdict(mean_pool, 7, 11, 5, 13))
	_row("R1.3", "Days with no tasks", "%d%%" % (100 * int(a2["empty_days"]) / 20), "PASS" if int(a2["empty_days"]) == 0 else "FAIL")
	var distinct := {}
	for id: Variant in a2["pool_ids"]:
		distinct[id] = true
	_row("R1.4", "Distinct tasks seen in 20 days", "%d of 64" % distinct.size(), _verdict(distinct.size(), 30, 64, 20, 29))
	_row("R1.5", "Same pool two days running", str(a2["same_pool_twice"]), "PASS" if int(a2["same_pool_twice"]) == 0 else ("WARN" if int(a2["same_pool_twice"]) == 1 else "FAIL"))
	_row("R1.6", "Families seen in 20 days", "%d of 8" % (a2["families_seen"] as Dictionary).size(),
		"PASS" if (a2["families_seen"] as Dictionary).size() == 8 else ("WARN" if (a2["families_seen"] as Dictionary).size() == 7 else "FAIL"))

	var ramp_points := _mean((a1["day_points"] as Array).slice(5, 20))
	_row("R1.7", "Best: reward a day during weeks 2 to 4 (points)", "%.1f" % ramp_points, _verdict(ramp_points, 0.5, 99, 0.2, 0.5), "the ramp should still feel worth doing")

	# ---- D2
	var demand := _mean(a2["task_hours"]) / 24.0
	_row("R2.1", "Task hours offered / 3 staff's 24 hours", "%.2f" % demand, _verdict(demand, 0.8, 1.6, 0.5, 2.2))
	var assigned := maxi(1, int(a2["assigned"]))
	var strong_share := 100.0 * int(a2["fits"]["strong"]) / assigned
	_row("R2.2", "Best: share of assignments that are strong fits", "%.0f%%" % strong_share, _verdict(strong_share, 60, 100, 40, 60))
	var gap_points := _mean(a2["day_points"]) - _mean(rnd["day_points"])
	_row("R2.3", "Reward gap, Best over Random (points a day)", "%.1f (Best %.1f, Random %.1f)" % [gap_points, _mean(a2["day_points"]), _mean(rnd["day_points"])], _verdict(gap_points, 1.5, 99, 0.5, 1.5))
	var per_role := {}
	for task: Dictionary in DataDB.staff_tasks:
		if str(task.get("kind", "")) != "time_off":
			per_role[str(task["strong_role"])] = int(per_role.get(str(task["strong_role"]), 0)) + 1
	var min_role := 99
	for role: String in per_role.keys():
		min_role = mini(min_role, int(per_role[role]))
	_row("R2.4", "Fewest tasks any role is strong at", "%d (%s)" % [min_role, str(per_role)], _verdict(min_role, 15, 99, 10, 14))

	var done_three := 100.0 * int(a2["assigned"]) / maxf(1.0, float((a2["pool_sizes"] as Array).reduce(func(x, y): return x + y)))
	var done_one := 100.0 * int(one["assigned"]) / maxf(1.0, float((one["pool_sizes"] as Array).reduce(func(x, y): return x + y)))
	var done_two := 100.0 * int(two["assigned"]) / maxf(1.0, float((two["pool_sizes"] as Array).reduce(func(x, y): return x + y)))
	_row("R2.6", "Best: share of delivered tasks that get done, 1 / 2 / 3 staff", "%.0f%% / %.0f%% / %.0f%%" % [done_one, done_two, done_three],
		"PASS" if (done_one <= 60 and done_one >= 20 and done_three <= 95 and done_three > done_one) else "WARN", "one person should not clear a day; three nearly can")

	# ---- D3
	var due_mean := _mean(a2["due"])
	_row("R3.1", "Due tasks delivered a day", "%.1f" % due_mean, _verdict(due_mean, 1, 3, 0.5, 4))
	var ignore_cost := _mean(a2["day_points"]) - _mean(ign["day_points"])
	_row("R3.2", "Cost of ignoring, Best minus Ignore (points a day)", "%.1f (Ignore %.1f)" % [ignore_cost, _mean(ign["day_points"])], _verdict(ignore_cost, 1.5, 99, 0.5, 1.5))
	var nostaff_days := 0
	for p: Variant in nos["day_points"]:
		if int(p) < 0:
			nostaff_days += 1
	_row("R3.3", "No-staff days with a Due penalty", "%d%%" % (100 * nostaff_days / 20), _verdict(100.0 * nostaff_days / 20, 60, 100, 30, 60))
	var cap := Levers.whole("staff_tasks_cap_meta")
	var worst_loss := int(ign["meta_loss_max"])
	_row("R3.4", "Worst one-day loss on a meta number (Ignore)", "%d (cap %d)" % [worst_loss, cap], "PASS" if worst_loss >= -cap else "FAIL")
	var worst_week := 0
	for week_diff: Dictionary in ign["weekly"]:
		for name: String in ["Constituency support", "Reputation", "Party support"]:
			worst_week = mini(worst_week, int(week_diff.get(name, 0)))
	_row("R3.5", "Worst weekly loss, ignoring everything", "%d" % worst_week, "PASS" if worst_week >= -8 else ("WARN" if worst_week >= -14 else "FAIL"))

	# ---- D4
	var best_gain := int(a2["meta_gain_max"])
	_row("R4.1", "Best: biggest one-day gain on a meta number", "%d (cap %d)" % [best_gain, cap], "PASS" if best_gain <= cap else "FAIL")
	var week_points: Array = []
	var week_xp: Array = []
	var week_funds: Array = []
	for week_diff: Dictionary in a2["weekly"]:
		week_points.append(_points(week_diff))
		week_xp.append(int(week_diff.get("XP", 0)))
		week_funds.append(int(week_diff.get("Funds", 0)))
	_row("R4.2", "Best: net points a week (after decay)", str(week_points), _verdict(_mean(week_points), 3, 14, 1, 22))
	var xp_days := 0.0
	for day_points: Variant in a2["day_points"]:
		xp_days += 0.0
	_row("R4.3", "Best: XP a week", str(week_xp), _verdict(_mean(week_xp), -999, 20, -999, 35))
	var task_funds := _mean(a2["day_funds"]) * 5.0
	_row("R4.4", "Best: Funds from tasks a week", "%+.0f円 (weekly wage bill for the three staff: %d円)" % [task_funds, int(a2["wage_bill"])],
		_verdict(absf(task_funds), 0, 15000, 0, 30000), "tasks vs the wage they cost")

	# ---- D5
	var loyalty_changes: Array = []
	var low_loyalty := 0
	for id: String in STAFF:
		loyalty_changes.append(float(int(a2["loyalty_end"][id]) - int(a2["loyalty_start"][id])) / 4.0)
		if int(a2["loyalty_end"][id]) < 15:
			low_loyalty += 1
	_row("R5.1", "Best: mean Loyalty change a week", "%.1f (start %s, end %s)" % [_mean(loyalty_changes), str(a2["loyalty_start"]), str(a2["loyalty_end"])], _verdict(_mean(loyalty_changes), 0, 6, -2, 9), "includes wages (+2), affinity, tasks")
	_row("R5.2", "Best: staff below 15 Loyalty", str(low_loyalty), "PASS" if low_loyalty == 0 else ("WARN" if low_loyalty == 1 else "FAIL"))
	var pd := maxi(1, int(a2["person_days"]))
	var idle_share := 100.0 * int(a2["idle_days"]) / pd
	_row("R5.3", "Best: idle person-days", "%.0f%%" % idle_share, _verdict(idle_share, 0, 15, 0, 30))
	var full_share := 100.0 * int(a2["full_days"]) / pd
	_row("R5.4", "Best: full person-days", "%.0f%%" % full_share, _verdict(full_share, 0, 40, 0, 60))
	var off_share := 100.0 * int(a2["time_off_taken"]) / maxi(1, int(a2["time_off_offered"]))
	var ramp_low := 100
	for id: String in STAFF:
		ramp_low = mini(ramp_low, int(a1["loyalty_end"][id]))
	_row("R5.6", "Best: lowest Loyalty after the 4 ramp weeks", "%d (%s)" % [ramp_low, str(a1["loyalty_end"])], _verdict(ramp_low, 25, 100, 15, 24), "the ramp must not drive staff out")
	_row("R5.5", "Best: time off taken when offered", "%.0f%% (%d of %d)" % [off_share, int(a2["time_off_taken"]), int(a2["time_off_offered"])], _verdict(off_share, 30, 100, 10, 30))

	# ---- D6
	_row("R6.1", "Skipped days that changed nothing (interrupted run)", "%d of %d" % [int(b["skipped_exact"]), int(b["skipped_days"])],
		"PASS" if int(b["skipped_exact"]) == int(b["skipped_days"]) else "FAIL")
	var checks := int(a2["projection_checks"]) + int(b["projection_checks"])
	var exact := int(a2["projection_exact"]) + int(b["projection_exact"])
	_row("R6.2", "Projection equals what was applied", "%d of %d" % [exact, checks], "PASS" if exact == checks else ("WARN" if 100 * exact >= 95 * checks else "FAIL"))
	_row("R6.3", "A level that ends at the day's end settles it", "%d settled one-day crossings" % int(b["settled_exact_day"]), "PASS" if int(b["settled_exact_day"]) > 0 else "WARN", "informational if no level of that length was drawn")
	var b_rate := _mean(b["day_points"]) * int(b["visits"]) / maxf(1.0, float(b["elapsed_days"]))
	var a_rate := _mean(a2["day_points"])
	var retained := 100.0 * b_rate / maxf(0.01, a_rate)
	_row("R6.4", "Interrupted reward per elapsed day, share of back-to-back", "%.0f%% (%.1f vs %.1f pts a day over %d elapsed days)" % [retained, b_rate, a_rate, int(b["elapsed_days"])], _verdict(retained, 35, 999, 15, 35), "informational")

	print("")
	print("## Results")
	print("")
	print("| ID | Criterion | Value | Verdict | Note |")
	print("|---|---|---|---|---|")
	for line: String in _results:
		print(line)
	print("")
	print("## Run summaries")
	print("")
	print("| Run | Visits | Elapsed days | Mean tasks | Mean points a day | Skipped days | Assigned | Strong / fair / poor |")
	print("|---|---|---|---|---|---|---|---|")
	for run: Dictionary in [a1, a2, one, two, rnd, ign, nos, b, b_ign]:
		print("| %s (%d staff) | %d | %d | %.1f | %.1f | %d | %d | %d / %d / %d |" % [run["policy"], (run["loyalty_start"] as Dictionary).size() if run["policy"] != "nostaff" else 0, run["visits"], run["elapsed_days"],
			_mean(run["pool_sizes"]), _mean(run["day_points"]), run["skipped_days"], run["assigned"],
			run["fits"]["strong"], run["fits"]["fair"], run["fits"]["poor"]])
	print("")
	print("Weekly meta change (after decay), Best at full volume: %s" % str(a2["weekly"]))
	print("Weekly meta change, Ignore: %s" % str(ign["weekly"]))
	print("Weekly meta change, No staff: %s" % str(nos["weekly"]))
	get_tree().quit(0)


func _ready() -> void:
	_run.call_deferred()
