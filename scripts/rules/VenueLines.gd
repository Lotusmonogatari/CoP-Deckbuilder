class_name VenueLines
extends RefCounted
## The day's lines at a Capitol venue (P16, 2026-11-23, Cameron). Each line-giving venue deals a set of lines each day from the lines
## eligible that day (conditions, dates, seasons, After Law), seeded by run, day and venue so a reload does not reshuffle. About one
## dealt line in N is a rhetoric-tip slot; the player may hear a limited number a day, then one `dry` line. Pure: no screens, no
## autoloads, no files (the tests prove it).
##
## A line is a Venue Lines row (venue_lines.json). `ctx` is what the rules need to read the day: {"today": a WeekCalendar day number,
## "month": 1-12, "seasons": rules.json's seasons table, "meta": the run's meta numbers, "laws": {bill_id: "passed"/"failed"},
## "staff_hired": {}, "heard": {line_id: true} for lines marked Once}.

const DRY_POOL := "dry"


## True when a line may be dealt today: its condition holds, it is inside its dates and season, its law has been decided that way,
## and a Once line has not been heard before.
static func line_ok(line: Dictionary, ctx: Dictionary) -> bool:
	var condition: Variant = line.get("condition_type")
	if condition != null and not str(condition).strip_edges().is_empty():
		if not OfficeNotices.condition_met(line, ctx.get("staff_hired", {}), ctx.get("meta", {}), ctx.get("laws", {})):
			return false
	var today := int(ctx.get("today", 0))
	var on_date := _date(line.get("on_date"))
	if on_date >= 0 and today != on_date:
		return false
	var from_day := _date(line.get("date_from"))
	if from_day >= 0 and today < from_day:
		return false
	var to_day := _date(line.get("date_to"))
	if to_day >= 0 and today > to_day:
		return false
	if not Seasons.in_season(line, int(ctx.get("month", 1)), ctx.get("seasons", {})):
		return false
	var law: Variant = line.get("after_law")
	if law != null and not str(law).strip_edges().is_empty():
		var parts := str(law).strip_edges().split(" ", false)
		if parts.size() != 2 or str((ctx.get("laws", {}) as Dictionary).get(parts[0], "")) != parts[1]:
			return false
	if str(line.get("once", "")).strip_edges().to_upper() == "Y" and (ctx.get("heard", {}) as Dictionary).has(str(line.get("line_id", ""))):
		return false
	return true


## The eligible lines of one pool, in workbook order.
static func eligible(lines: Array, pool: String, ctx: Dictionary) -> Array:
	var out: Array = []
	for line: Variant in lines:
		if line is Dictionary and str((line as Dictionary).get("pool", "")) == pool and line_ok(line as Dictionary, ctx):
			out.append(line)
	return out


static func is_hint(line: Dictionary) -> bool:
	var kind: Variant = line.get("hint_kind")
	return kind != null and not str(kind).strip_edges().is_empty()


## The deterministic seed for one venue's day.
static func seed_for(run_seed: int, day: int, venue_id: String) -> int:
	return absi(("%d|%d|%s" % [run_seed, day, venue_id]).hash())


## Deals the day's set for a pool. Returns [{"line_id", "hint": {} or {"kind", "target", "suit", "text_key"}}], at most `set_size`.
## Lines tied to today's date come first (a moment fills its date); then, slot by slot, either a hint (one chance in `hint_share`)
## or the next plain line drawn by weight. `targets` is {"stage_suit": [{"id", "suit"}...], "opponent_suit": [...]} and `phrasings`
## {"stage_suit.earnest": 3, ...} (how many Text rows each kind and suit has); a hint slot with no target or no phrasing becomes a plain line.
static func deal(lines: Array, pool: String, ctx: Dictionary, seed_value: int, set_size: int, hint_share: int,
		targets: Dictionary, phrasings: Dictionary) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pool_lines := eligible(lines, pool, ctx)
	var plain: Array = []
	var hints: Array = []
	for line: Dictionary in pool_lines:
		(hints if is_hint(line) else plain).append(line)
	var today := int(ctx.get("today", 0))
	var dealt: Array = []
	# A line written for today comes first.
	for line: Dictionary in plain.duplicate():
		if _date(line.get("on_date")) == today:
			dealt.append({"line_id": str(line["line_id"]), "hint": {}})
			plain.erase(line)
	while dealt.size() < set_size:
		var want_hint := not hints.is_empty() and hint_share > 0 and rng.randi_range(1, hint_share) == 1
		var made := {}
		if want_hint:
			made = _hint_slot(hints, targets, phrasings, rng)
		if made.is_empty():
			if plain.is_empty():
				if hints.is_empty():
					break
				made = _hint_slot(hints, targets, phrasings, rng)
				if made.is_empty():
					break
			else:
				var line := _draw(plain, rng)
				plain.erase(line)
				made = {"line_id": str(line["line_id"]), "hint": {}}
		dealt.append(made)
	return dealt


static func _hint_slot(hints: Array, targets: Dictionary, phrasings: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var order := hints.duplicate()
	# Try the hint rows in a random order until one has a target and a phrasing.
	while not order.is_empty():
		var row: Dictionary = _draw(order, rng)
		order.erase(row)
		var kind := str(row.get("hint_kind", ""))
		var pool: Array = targets.get(kind, [])
		var raw_target: Variant = row.get("hint_target")
		var named := "" if raw_target == null else str(raw_target).strip_edges()
		if not named.is_empty():
			pool = pool.filter(func(t: Dictionary) -> bool: return str(t.get("id", "")) == named)
		if pool.is_empty():
			continue
		var target: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
		var suit_key := suit_key_of(str(target.get("suit", "")))
		var count := int(phrasings.get("%s.%s" % [kind, suit_key], 0))
		if count <= 0:
			continue
		var text_key := "hint.%s.%s_%d" % [kind, suit_key, rng.randi_range(1, count)]
		return {"line_id": str(row["line_id"]), "hint": {"kind": kind, "target": str(target["id"]), "suit": str(target["suit"]),
			"text_key": text_key}}
	return {}


## The suit's lower-case Text key part: "Data Driven" is "data_driven".
static func suit_key_of(suit: String) -> String:
	return suit.strip_edges().to_lower().replace(" ", "_")


## A weighted draw (the Weight column; blank counts 1).
static func _draw(rows: Array, rng: RandomNumberGenerator) -> Dictionary:
	var total := 0
	for row: Dictionary in rows:
		total += maxi(_weight(row), 1)
	var pick := rng.randi_range(0, total - 1)
	for row: Dictionary in rows:
		pick -= maxi(_weight(row), 1)
		if pick < 0:
			return row
	return rows[rows.size() - 1]


static func _weight(row: Dictionary) -> int:
	var raw: Variant = row.get("weight")
	return 1 if raw == null else int(raw)


## The line that follows the ones already heard from a dealt set, or {} when the set (or the daily limit) is used up.
static func next_dealt(dealt: Array, heard: int, limit: int) -> Dictionary:
	if heard >= mini(dealt.size(), limit):
		return {}
	return dealt[heard] as Dictionary


## One `dry` line for after the limit: a draw from the eligible dry pool, deterministic in the seed; {} when there is none.
static func dry_line(lines: Array, ctx: Dictionary, seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pool := eligible(lines, DRY_POOL, ctx)
	return {} if pool.is_empty() else _draw(pool, rng)


## The line row with this ID, or {}.
static func find(lines: Array, line_id: String) -> Dictionary:
	for line: Variant in lines:
		if line is Dictionary and str((line as Dictionary).get("line_id", "")) == line_id:
			return line as Dictionary
	return {}


## YY.MM.DD as a day number; -1 for a blank cell.
static func _date(raw: Variant) -> int:
	if raw == null or str(raw).strip_edges().is_empty():
		return -1
	return WeekCalendar.parse_date(str(raw))
