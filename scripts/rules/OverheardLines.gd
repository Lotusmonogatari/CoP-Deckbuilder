class_name OverheardLines
extends RefCounted
## Overheard lines (2026-11-25, Cameron): going to a place counts one move, and on the N-th the place opens with a line heard in passing. N
## and its wobble are Balance rows (a Venues row may set its own pace); the places a line can come up at are its Where cell, so a new venue
## or season in the workbook needs no code. A line that names the place itself beats a zone-wide one by a weight boost. Pure: no screens, no
## autoloads, no files (the tests prove it); GameState holds the counter and the recent lines.

## The Pool value of these lines in Venue Lines.
const POOL := "overheard"
## How well a line's Where fits a place.
const NONE := 0
const ZONE := 1
const SPECIFIC := 2


## The tokens of a Where cell, split on semicolons or commas.
static func tokens(where_cell: Variant) -> Array[String]:
	var out: Array[String] = []
	if where_cell == null:
		return out
	for part: String in str(where_cell).replace(",", ";").split(";"):
		var token := part.strip_edges()
		if not token.is_empty():
			out.append(token)
	return out


## How a line fits the place being gone to (a Venues row; `screen` is "" or "tracks"): SPECIFIC when it names the venue (or its tracks, on
## the tracks screen), ZONE when it names the venue's zone, NONE otherwise. The best match wins.
static func fit(line: Dictionary, venue: Dictionary, screen: String = "") -> int:
	var best := NONE
	var venue_id := str(venue.get("venue_id", ""))
	var wanted := venue_id if screen.is_empty() else "%s/%s" % [venue_id, screen]
	for token: String in tokens(line.get("where")):
		if token.to_lower() == wanted.to_lower():
			best = SPECIFIC
		elif token == str(venue.get("zone", "")) and best < ZONE:
			best = ZONE
	return best


## How many moves between lines at a place: its own Overheard Every (0 = never), else the default.
static func pace(venue: Dictionary, default_every: int) -> int:
	var own: Variant = venue.get("overheard_every")
	return default_every if own == null else int(own)


## The moves needed before the next line: `every` moved by up to `wobble` either way, from the seed, never below 1.
static func threshold(every: int, wobble: int, seed_value: int) -> int:
	if every <= 0:
		return 0
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(seed_value)
	return maxi(1, every + rng.randi_range(-maxi(wobble, 0), maxi(wobble, 0)))


## Whether a line is due: `moves` (counted since the last line, this one included) has reached the threshold; false when the place never
## has lines.
static func due(moves: int, every: int, wobble: int, seed_value: int) -> bool:
	return every > 0 and moves >= threshold(every, wobble, seed_value)


## The line to hear at a place, or {}: the eligible overheard lines that fit the place (conditions, dates, seasons, After Law, Once), those
## heard in the last few skipped while another can be drawn, drawn by Weight with a line that names the place itself weighing `boost` times.
static func pick(lines: Array, venue: Dictionary, screen: String, ctx: Dictionary, recent: Array, boost: int, seed_value: int) -> Dictionary:
	var fresh: Array = []
	var all: Array = []
	for line: Variant in lines:
		var row := line as Dictionary
		if str(row.get("pool", "")) != POOL or fit(row, venue, screen) == NONE or not VenueLines.line_ok(row, ctx):
			continue
		all.append(row)
		if not recent.has(str(row.get("line_id", ""))):
			fresh.append(row)
	var from: Array = fresh if not fresh.is_empty() else all
	if from.is_empty():
		return {}
	var total := 0
	for row: Dictionary in from:
		total += weight_of(row, venue, screen, boost)
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(seed_value)
	var roll := rng.randi_range(0, total - 1)
	for row: Dictionary in from:
		roll -= weight_of(row, venue, screen, boost)
		if roll < 0:
			return row
	return from[from.size() - 1]


## A line's draw weight at a place: its Weight (blank counts 1), times the boost when it names the place itself.
static func weight_of(line: Dictionary, venue: Dictionary, screen: String, boost: int) -> int:
	var raw: Variant = line.get("weight")
	var weight := maxi(1 if raw == null else int(raw), 1)
	return weight * maxi(boost, 1) if fit(line, venue, screen) == SPECIFIC else weight


## The recent list with one more line ID, keeping the last `keep`.
static func with_recent(recent: Array, line_id: String, keep: int) -> Array:
	var out := recent.duplicate()
	out.append(line_id)
	while out.size() > maxi(keep, 0):
		out.pop_front()
	return out
