class_name HowToPlay
extends RefCounted
## The How to Play guide's content, put in reading order.
##
## data/how_to_play.json (the workbook's "How To Play" tab) is flat rows. This
## sorts them, gathers them under their Group headings, and fills the live
## {tokens} in their text from the game's own numbers, so a guide that says
## "the Floor Debate needs {majority} of {seats} seats" is still right after
## the Stages tab is retuned.
##
## Pure and UI-free (CLAUDE.md §12): HowToPlayPanel.gd draws it. Nothing here
## reads DataDB — every input is passed in, so tests can hand it fixtures.

## The numbers a guide entry may quote. Anything else in braces is left as
## written, on purpose: a typo in the workbook shows up on screen where the
## designer will see it, rather than silently vanishing.
##
##   {majority}      Floor Debate (ST02) win mark
##   {seats}         Floor Debate (ST02) seats in the chamber
##   {guard_cap}     rules.json: most Guard either side can hold
##   {pass_penalty}  rules.json: energy lost next turn for passing
##   {gaffe_min}     lowest gaffe limit of any Combat room
##   {gaffe_max}     highest gaffe limit of any Combat room
const TOKEN_NAMES := ["majority", "seats", "guard_cap", "pass_penalty", "gaffe_min", "gaffe_max"]

## The room the {majority} and {seats} tokens describe.
const FLOOR_DEBATE_ID := "ST02"


## Entries in reading order: by Order, then by Entry ID. A row with neither a
## heading nor a body has nothing to show and is dropped.
static func ordered(rows: Array) -> Array[Dictionary]:
	var kept: Array[Dictionary] = []
	for row in rows:
		if not (row is Dictionary):
			continue
		var entry: Dictionary = row
		if _text(entry, "heading_en").is_empty() and _text(entry, "body_en").is_empty():
			continue
		kept.append(entry)
	kept.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var order_a := _order(a)
		var order_b := _order(b)
		if order_a != order_b:
			return order_a < order_b
		return _text(a, "entry_id") < _text(b, "entry_id"))
	return kept


## The ordered entries gathered under their Group, each group sitting where
## its first entry does: [{"group": "The Goal", "entries": [...]}, ...]. An
## entry with no Group goes under a group named "" (no heading is drawn).
static func grouped(rows: Array) -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	for entry: Dictionary in ordered(rows):
		var name := _text(entry, "group")
		var home: Dictionary = {}
		for group: Dictionary in groups:
			if group["group"] == name:
				home = group
				break
		if home.is_empty():
			home = {"group": name, "entries": []}
			groups.append(home)
		(home["entries"] as Array).append(entry)
	return groups


## Replaces each known {token} in `text` with its value from `tokens`.
## Unknown tokens, and known ones with no value supplied, are left as written.
static func fill_tokens(text: String, tokens: Dictionary) -> String:
	var result := text
	for name: String in tokens:
		result = result.replace("{%s}" % name, str(tokens[name]))
	return result


## The {tokens} the guide can quote, read from the stage rows and the rules.
## A number that cannot be found is simply left out (so its token stays
## visible in the text) rather than guessed.
static func live_tokens(stages: Array, rules: Dictionary) -> Dictionary:
	var tokens := {}

	var gaffe_limits: Array[int] = []
	for stage in stages:
		if not (stage is Dictionary):
			continue
		var row: Dictionary = stage
		if str(row.get("stage_id", "")) == FLOOR_DEBATE_ID:
			if row.get("win_threshold") != null:
				tokens["majority"] = int(row["win_threshold"])
			if row.get("bar_max") != null:
				tokens["seats"] = int(row["bar_max"])
		if str(row.get("mode", "")) == "Combat" and row.get("gaffe_limit") != null:
			gaffe_limits.append(int(row["gaffe_limit"]))
	if not gaffe_limits.is_empty():
		tokens["gaffe_min"] = gaffe_limits.min()
		tokens["gaffe_max"] = gaffe_limits.max()

	tokens_from_rule(tokens, "guard_cap", rules, "guard_cap")
	tokens_from_rule(tokens, "pass_penalty", rules, "pass_energy_penalty")
	return tokens


## Copies a rule's number across under `token`. A rule may arrive as the bare
## value (what DataDB.rules holds) or as rules.json's own {"value": N, ...}.
static func tokens_from_rule(tokens: Dictionary, token: String, rules: Dictionary,
		rule: String) -> void:
	var lever = rules.get(rule)
	if lever is Dictionary:
		lever = (lever as Dictionary).get("value")
	if lever != null and (lever is int or lever is float):
		tokens[token] = int(lever)


## Every {word} in `text` that is not in `tokens` — what a test uses to prove
## the real guide has no typos.
static func unresolved_tokens(text: String, tokens: Dictionary) -> Array[String]:
	var missing: Array[String] = []
	var regex := RegEx.new()
	regex.compile("\\{([a-z_]+)\\}")
	for found in regex.search_all(text):
		var name := found.get_string(1)
		if not tokens.has(name) and not missing.has(name):
			missing.append(name)
	return missing


## A cell, with a blank (JSON null) read as "" rather than the text "<null>".
static func _text(entry: Dictionary, key: String) -> String:
	var value = entry.get(key)
	return "" if value == null else str(value).strip_edges()


static func _order(entry: Dictionary) -> float:
	var value = entry.get("order")
	return 1.0e9 if value == null else float(value)   # unnumbered rows go last
