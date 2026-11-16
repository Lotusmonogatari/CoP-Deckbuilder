class_name StaffTasks
extends RefCounted
## The daily staff tasks (Cameron, 2026-11-16; design/proposals/
## STAFF_ASSIGNMENTS_2026-11-16.md). Each workday the Office offers a pool of
## small tasks (the Staff Assignments tab). The player gives them to hired
## people; how well a person does one depends on whether their ROLE is a
## strong, fair or poor fit for it, and on their Loyalty.
##
## Pure rules: no UI, no autoloads, no files. Projection (what the screen shows
## before Confirm) and resolution (what is applied at the day's end) call the
## same evaluate(), so the screen can never promise something else.

const STRONG := "strong"
const FAIR := "fair"
const POOR := "poor"

const KIND_PLAIN := "plain"
const KIND_ORGANIZATION := "organization"
const KIND_COMMITTEE := "committee"
const KIND_OFFICIAL := "official"
const KIND_TIME_OFF := "time_off"

## Why a task cannot be given to a person right now (codes the screen words).
const REFUSE_LOCKED := "locked"          # the day is already confirmed
const REFUSE_TAKEN := "taken"            # someone already has this task
const REFUSE_BLOCKS := "blocks"          # not enough of their day is left
const REFUSE_UNKNOWN := "unknown"
const REFUSE_ITEM_HAVE := "item_have"    # they already have this item
const REFUSE_ITEM_NONE := "item_none"    # none left to give
const REFUSE_ITEM_SLOT := "item_slot"    # a person item for the Office box, or the reverse

## Effect names the Staff Assignments tab may use.
const META_NAMES := ["Constituency support", "Reputation", "Funds", "Party support"]


## "Constituency support:1; Reputation:-1" as [{name, amount}].
static func parse_effects(text: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if text == null:
		return out
	for part: String in str(text).split(";"):
		var pair := part.strip_edges()
		if pair.is_empty():
			continue
		var cut := pair.rfind(":")
		if cut <= 0:
			continue
		out.append({"name": pair.substr(0, cut).strip_edges(), "amount": int(pair.substr(cut + 1).strip_edges())})
	return out


## The role a task names for a fit ("strong", "fair" or "poor"), "" for time off.
static func role_for(task: Dictionary, fit: String) -> String:
	var value: Variant = task.get("%s_role" % fit)
	return "" if value == null else str(value)


## How a role does a task: strong, fair or poor. Time off suits everyone.
static func fit_of(task: Dictionary, role: String) -> String:
	if str(task.get("kind", "")) == KIND_TIME_OFF:
		return STRONG
	for fit: String in [STRONG, FAIR, POOR]:
		if role_for(task, fit) == role:
			return fit
	return FAIR


## The fit a person actually delivers: Loyalty can weaken it (StaffLoyalty).
static func effective_fit(task: Dictionary, role: String, loyalty: int) -> String:
	var fit := fit_of(task, role)
	if str(task.get("kind", "")) == KIND_TIME_OFF:
		return fit
	return StaffLoyalty.weakened_fit(fit, loyalty)


## A strong-fit reward grows with the person's rank (a share of it per rank,
## rounded down). Only positive amounts grow, and never Loyalty.
static func rank_scaled(amount: int, name: String, tier: int) -> int:
	if amount <= 0 or name.begins_with("Loyalty"):
		return amount
	return amount + int(floor(amount * Levers.num("staff_tasks_rank_bonus_percent") * maxi(0, tier) / 100.0))


# ---------------------------------------------------------------------------
# The day's pool
# ---------------------------------------------------------------------------

## The most tasks a day may deliver (the ramp tab): the row for the calendar
## week (`week_index` 0 is the first week; the last row covers every later
## week), a weekend day keeping that row's Weekend Factor of it, plus `delta`
## from an item or event, never below 0.
static func day_maximum(ramp: Array, week_index: int, weekend: bool, delta: int = 0) -> int:
	if ramp.is_empty():
		return maxi(0, delta)
	var row: Dictionary = ramp[0]
	for candidate: Dictionary in ramp:
		if int(candidate.get("week", 1)) <= week_index + 1:
			row = candidate
	var most := int(row.get("max_tasks", 0))
	if weekend:
		most = int(floor(most * int(row.get("weekend_factor", 100)) / 100.0))
	return maxi(0, most + delta)


## How many tasks each family rolls today: a flat random number from its Min
## to its Max (a weekend day keeps its Weekend Factor of that), plus any
## driver or item change in `adds` ({ family: n }), held between 0 and its Cap.
## Returns { family: count } in the tab's order.
static func roll_quotas(families: Array, weekend: bool, adds: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var counts := {}
	for row: Dictionary in families:
		var family := str(row.get("family", ""))
		var count := rng.randi_range(int(row.get("min", 0)), maxi(int(row.get("min", 0)), int(row.get("max", 0))))
		if weekend:
			count = int(round(count * int(row.get("weekend_factor", 100)) / 100.0))
		count += int(adds.get(family, 0))
		counts[family] = clampi(count, 0, int(row.get("cap", count)))
	return counts


## Draws a day's pool (Cameron, 2026-11-16). Each family rolls its own count
## (roll_quotas); that many of its tasks are picked by weight without repeating
## (a family with fewer tasks than its count supplies what it has, and a task
## whose kind has nobody to name is skipped); then the whole list is trimmed to
## `maximum`, keeping tasks at random with a family's chance proportional to
## the count it rolled. `targets` holds the named things the tasks need, from
## the data: { "organization": [{id, name}], "committee": [...], "official": [...] }.
## Each entry is { uid, task_id, target_id, target_name, title, context }.
static func draw_pool(tasks: Array, families: Array, targets: Dictionary, maximum: int, weekend: bool,
		adds: Dictionary, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	if maximum <= 0:
		return pool
	var quotas := roll_quotas(families, weekend, adds, rng)
	var generated: Array[Dictionary] = []   # { task, target, family }
	for family: String in quotas.keys():
		var candidates: Array[Dictionary] = []
		for task: Dictionary in tasks:
			var kind := str(task.get("kind", KIND_PLAIN))
			if str(task.get("family", "")) != family:
				continue
			if kind == KIND_TIME_OFF or (int(task.get("weight", 0)) > 0 and (kind == KIND_PLAIN or not (targets.get(kind, []) as Array).is_empty())):
				candidates.append(task)
		for _n in int(quotas[family]):
			if candidates.is_empty():
				break
			var picked := _weighted_index(candidates, rng)
			var task: Dictionary = candidates[picked]
			candidates.remove_at(picked)
			var kind := str(task.get("kind", KIND_PLAIN))
			var target: Dictionary = {}
			if kind != KIND_PLAIN and kind != KIND_TIME_OFF:
				var named: Array = targets.get(kind, [])
				target = named[rng.randi_range(0, named.size() - 1)]
			generated.append({"task": task, "target": target, "family": family})
	# Trim to the day's maximum, a family's chance following the count it rolled.
	var kept: Array[int] = []
	var left: Array[int] = []
	for i in generated.size():
		left.append(i)
	while kept.size() < maximum and not left.is_empty():
		var total := 0
		for i: int in left:
			total += maxi(1, int(quotas.get(str(generated[i]["family"]), 1)))
		var roll := rng.randi_range(1, maxi(1, total))
		var chosen := 0
		for k in left.size():
			roll -= maxi(1, int(quotas.get(str(generated[left[k]]["family"]), 1)))
			if roll <= 0:
				chosen = k
				break
		kept.append(left[chosen])
		left.remove_at(chosen)
	kept.sort()
	for i: int in kept:
		pool.append(_entry(generated[i]["task"], pool.size(), generated[i]["target"]))
	return pool


static func _weighted_index(candidates: Array, rng: RandomNumberGenerator) -> int:
	var total := 0
	for task: Dictionary in candidates:
		total += maxi(1, int(task.get("weight", 1)))
	var roll := rng.randi_range(1, maxi(1, total))
	for i in candidates.size():
		roll -= maxi(1, int((candidates[i] as Dictionary).get("weight", 1)))
		if roll <= 0:
			return i
	return 0


static func _entry(task: Dictionary, index: int, target: Dictionary) -> Dictionary:
	var name := str(target.get("name", ""))
	return {
		"uid": "T%d" % index,
		"task_id": str(task.get("task_id", "")),
		"target_id": str(target.get("id", "")),
		"target_name": name,
		"title": str(task.get("title", "")).replace("{target}", name),
		"context": str(task.get("context", "")).replace("{target}", name),
	}


## The posts of ministers and presiding officers in an opponent's Title column
## ("Minister of Finance; Chair of the Committee on Finance" gives
## ["Minister of Finance"]): every part of the title that begins with one of
## `prefixes` (the Rules tab's `staff_task_official_prefixes`, so Cameron can
## add a post). Empty when the title has none.
static func official_posts(title: Variant, prefixes: Array) -> Array[String]:
	var posts: Array[String] = []
	if title == null:
		return posts
	for part: String in str(title).split(";"):
		var post := part.strip_edges()
		for prefix: Variant in prefixes:
			if not str(prefix).is_empty() and post.begins_with(str(prefix)):
				posts.append(post)
				break
	return posts


## "Committee on Finance" from a title such as "Minister of Finance; Chair of
## the Committee on Finance": from the first `marker` (the Rules tab's
## `staff_task_committee_marker`, "Committee on") to the end of that part.
## "" when the title names no committee.
static func committee_in(title: Variant, marker: String) -> String:
	if title == null or marker.is_empty():
		return ""
	for part: String in str(title).split(";"):
		var at := part.strip_edges().find(marker)
		if at >= 0:
			return part.strip_edges().substr(at)
	return ""


# ---------------------------------------------------------------------------
# Giving tasks to people
# ---------------------------------------------------------------------------

## The entry with this uid, {} when it is not in the pool.
static func entry_for(pool: Array, uid: String) -> Dictionary:
	for entry: Dictionary in pool:
		if str(entry.get("uid", "")) == uid:
			return entry
	return {}


static func task_for(tasks: Array, task_id: String) -> Dictionary:
	for task: Dictionary in tasks:
		if str(task.get("task_id", "")) == task_id:
			return task
	return {}


## Blocks of a person's day already taken: their tasks plus anything an event
## delegated to them.
static func blocks_used(staff_id: String, pool: Array, tasks: Array, plan: Dictionary, delegated: Dictionary) -> int:
	var used := int(delegated.get(staff_id, 0))
	for uid: Variant in plan.get(staff_id, []):
		used += int(task_for(tasks, str(entry_for(pool, str(uid)).get("task_id", ""))).get("blocks", 0))
	return used


## Why this task cannot go to this person, or "" when it can.
static func assign_refusal(uid: String, staff_id: String, pool: Array, tasks: Array, plan: Dictionary,
		delegated: Dictionary, day_blocks: int, locked: bool) -> String:
	if locked:
		return REFUSE_LOCKED
	var entry := entry_for(pool, uid)
	var task := task_for(tasks, str(entry.get("task_id", "")))
	if entry.is_empty() or task.is_empty():
		return REFUSE_UNKNOWN
	for list: Variant in plan.values():
		if (list as Array).has(uid):
			return REFUSE_TAKEN
	if blocks_used(staff_id, pool, tasks, plan, delegated) + int(task.get("blocks", 0)) > day_blocks:
		return REFUSE_BLOCKS
	return ""


# ---------------------------------------------------------------------------
# What a plan does
# ---------------------------------------------------------------------------

## Everything the plan does, as numbers. `members` are { staff_id, role, tier,
## loyalty }; `plan` is { staff_id: [uid, ...] }; `day` is { blocks, delegated,
## full_days, bonus, strong_family, reward_percent, quiet } (each a { staff_id: ... }
## dictionary set by the items given to that person). Returns:
##   lines     one per given task { uid, staff_id, fit, effects [{name, amount}] }
##   meta      { "Reputation": +/-n, ... } after the daily caps
##   xp, awareness { District, National }, standing { organization: n }
##   loyalty   { staff_id: n } this day's change, caps not applied
##   undone    due tasks left alone { uid, effects }
##   used      { staff_id: blocks }, full_days { staff_id: n } for tomorrow
##   time_off_unused  true when time off was offered and nobody took it
static func evaluate(pool: Array, tasks: Array, plan: Dictionary, members: Array, day: Dictionary) -> Dictionary:
	var result := {"lines": [], "meta": {}, "xp": 0, "awareness": {"District": 0, "National": 0},
		"standing": {}, "loyalty": {}, "undone": [], "used": {}, "full_days": {}, "time_off_unused": false}
	var blocks := int(day.get("blocks", 8))
	var delegated: Dictionary = day.get("delegated", {})
	var loyalty_all := 0
	var totals := {}   # raw sums before the caps, keyed "meta:Reputation", "xp", "aware:District", "stand:BO01"
	var given := {}    # uid -> true
	var time_off_in_pool := false
	for entry: Dictionary in pool:
		if str(task_for(tasks, str(entry.get("task_id", ""))).get("kind", "")) == KIND_TIME_OFF:
			time_off_in_pool = true
	var time_off_taken := false

	for member: Dictionary in members:
		var id := str(member["staff_id"])
		var change := 0
		for uid: Variant in plan.get(id, []):
			var entry := entry_for(pool, str(uid))
			var task := task_for(tasks, str(entry.get("task_id", "")))
			if task.is_empty():
				continue
			given[str(uid)] = true
			var fit := effective_fit(task, str(member["role"]), int(member["loyalty"]))
			# A Reference Set makes the person a strong fit for its family today
			# (unrest still weakens it, as it does for any strong fit).
			if str((day.get("strong_family", {}) as Dictionary).get(id, "")) == str(task.get("family", "")) \
					and str(task.get("kind", "")) != KIND_TIME_OFF:
				fit = StaffLoyalty.weakened_fit(STRONG, int(member["loyalty"]))
			var effects: Array[Dictionary] = []
			var kind := str(task.get("kind", ""))
			if kind == KIND_TIME_OFF:
				time_off_taken = true
				change += Levers.whole("staff_tasks_time_off_loyalty")
				effects.append({"name": "Loyalty", "amount": Levers.whole("staff_tasks_time_off_loyalty")})
			elif fit == STRONG:
				change += Levers.whole("staff_tasks_fit_loyalty")
				for effect: Dictionary in parse_effects(task.get("strong_reward")):
					var amount := rank_scaled(int(effect["amount"]), str(effect["name"]), int(member["tier"]))
					# A Training Voucher makes today's strong-fit gains bigger (a percent, rounded down).
					var percent := int((day.get("reward_percent", {}) as Dictionary).get(id, 0))
					if percent > 0 and amount > 0 and not str(effect["name"]).begins_with("Loyalty"):
						amount = int(floor(amount * percent / 100.0))
					effects.append({"name": effect["name"], "amount": amount})
			elif fit == POOR:
				change -= Levers.whole("staff_tasks_fit_loyalty")
				effects = parse_effects(task.get("poor_penalty"))
			for effect: Dictionary in effects:
				var name := str(effect["name"])
				var amount := int(effect["amount"])
				if name == "Loyalty all":
					loyalty_all += amount
				elif name == "Loyalty":
					pass   # already counted in `change`
				else:
					_add(totals, name, amount, str(entry.get("target_id", "")))
			(result["lines"] as Array).append({"uid": str(uid), "staff_id": id, "fit": fit,
				"base_fit": fit_of(task, str(member["role"])), "kind": kind, "effects": effects})
		# The day's shape for this person.
		var used := blocks_used(id, pool, tasks, plan, delegated)
		(result["used"] as Dictionary)[id] = used
		# Coffee and tea add hours to this person's day (the bonus).
		var day_hours := blocks + int((day.get("bonus", {}) as Dictionary).get(id, 0))
		var streak := int(((day.get("full_days", {}) as Dictionary).get(id, 0)))
		if bool((day.get("quiet", {}) as Dictionary).get(id, false)):
			# A Quiet Desk Pass: no Loyalty change from an idle or overworked day.
			streak = 0
		elif used <= 0:
			change -= Levers.whole("staff_tasks_idle_loyalty")
			streak = 0
		elif used >= day_hours:
			streak += 1
			if streak >= Levers.whole("staff_tasks_full_streak_days"):
				change -= Levers.whole("staff_tasks_full_streak_loyalty")
		else:
			streak = 0
			if used >= int(ceil(day_hours * Levers.num("staff_tasks_healthy_minimum_percent") / 100.0)):
				change += Levers.whole("staff_tasks_healthy_loyalty")
		(result["full_days"] as Dictionary)[id] = streak
		(result["loyalty"] as Dictionary)[id] = change

	# Time off offered but nobody took it: everyone is a little put out.
	if time_off_in_pool and not time_off_taken and not members.is_empty():
		result["time_off_unused"] = true
		loyalty_all -= Levers.whole("staff_tasks_time_off_unused_loyalty")
	if loyalty_all != 0:
		for id: String in result["loyalty"].keys():
			result["loyalty"][id] = int(result["loyalty"][id]) + loyalty_all

	# Due tasks nobody took.
	for entry: Dictionary in pool:
		var task := task_for(tasks, str(entry.get("task_id", "")))
		var due := parse_effects(task.get("due_penalty"))
		if not due.is_empty() and not given.has(str(entry.get("uid", ""))):
			(result["undone"] as Array).append({"uid": str(entry["uid"]), "effects": due})
			for effect: Dictionary in due:
				_add(totals, str(effect["name"]), int(effect["amount"]), str(entry.get("target_id", "")))

	_apply_caps(totals, result)
	return result


static func _add(totals: Dictionary, name: String, amount: int, target_id: String) -> void:
	var key := ""
	if META_NAMES.has(name):
		key = "meta:" + name
	elif name == "XP":
		key = "xp"
	elif name == "District awareness":
		key = "aware:District"
	elif name == "National awareness":
		key = "aware:National"
	elif name == "Standing" and not target_id.is_empty():
		key = "stand:" + target_id
	if not key.is_empty():
		totals[key] = int(totals.get(key, 0)) + amount


## Holds each kind of change inside its daily cap (a Balance lever), gains and
## losses separately, and files it under the result.
static func _apply_caps(totals: Dictionary, result: Dictionary) -> void:
	for key: String in totals.keys():
		var amount := int(totals[key])
		if key.begins_with("meta:"):
			var name := key.substr(5)
			var cap := Levers.whole("staff_tasks_cap_funds") if name == "Funds" else Levers.whole("staff_tasks_cap_meta")
			amount = clampi(amount, -cap, cap)
			if amount != 0:
				result["meta"][name] = amount
		elif key == "xp":
			result["xp"] = mini(amount, Levers.whole("staff_tasks_cap_xp"))
		elif key.begins_with("aware:"):
			result["awareness"][key.substr(6)] = mini(amount, Levers.whole("staff_tasks_cap_awareness"))
		elif key.begins_with("stand:"):
			var cap_standing := Levers.whole("staff_tasks_cap_standing")
			amount = clampi(amount, -cap_standing, cap_standing)
			if amount != 0:
				result["standing"][key.substr(6)] = amount


# ---------------------------------------------------------------------------
# Event delegation (Cameron, 2026-11-16)
# ---------------------------------------------------------------------------

## How well a person handles an event choice handed to staff: someone in the
## role the choice names is a strong fit, anyone else a fair one; unrest weakens
## it (StaffLoyalty.weakened_fit).
static func delegate_fit(needed_role: String, member_role: String, loyalty: int) -> String:
	return StaffLoyalty.weakened_fit(STRONG if member_role == needed_role else FAIR, loyalty)


## A gain scaled by how the delegate did: all of it, a share of it (rounded
## down), or none. A loss is never softened.
static func delegate_gain(amount: int, fit: String) -> int:
	if amount <= 0:
		return amount
	match fit:
		STRONG:
			return amount
		FAIR:
			return int(floor(amount * Levers.num("staff_delegate_fair_gain_percent") / 100.0))
	return 0


## The hours a delegated event still takes from the player.
static func delegate_hours(hours: int) -> int:
	return int(floor(hours * Levers.num("staff_delegate_hours_percent") / 100.0))
