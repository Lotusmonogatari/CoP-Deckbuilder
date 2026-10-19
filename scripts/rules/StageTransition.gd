class_name StageTransition
extends RefCounted
## The Stage Transition screen's own logic (2026-10-01, §7.9): a short beat
## between two stages of the same level, where one or more characters from
## data/transition_cast.json speak in front of a transition_backgrounds.json
## pick, each paired with the player's own reply from
## transition_dialogue.json. Every pool is read through PoolPicker.gd.
##
## Entirely opt-in per stage (stages.json's own `show_transition`, blank =
## off) and silent when there is nothing eligible to show — the same
## "nothing written, nothing shown" bargain the Level Intro screen already
## keeps. Pure and UI-free (CLAUDE.md §12): StageTransitionScreen.gd is the
## one place this touches DataDB or the scene tree.


## Whether `stage`'s own `show_transition` column turns this on. Blank (the
## default for every existing stage) means No — nothing changes until
## Cameron writes "Yes" on a stage.
static func should_show(stage: Dictionary) -> bool:
	var declared: Variant = stage.get("show_transition")
	if declared == null:
		return false
	return str(declared).strip_edges().to_lower() == "yes"


## How many distinct characters speak, from `stage`'s own
## `transition_speaker_count` column. Blank or non-positive means 1.
static func speaker_count(stage: Dictionary) -> int:
	var declared: Variant = stage.get("transition_speaker_count")
	if declared == null:
		return 1
	return maxi(1, int(declared))


## "opponent" for an OPxx Character ID, "staff" for an SFxx one, "" for
## anything else — the same prefix-tells-you-the-kind trick
## BattleSetup._is_bill_id() already uses for a BIxx vs. an STxx.
static func character_kind(character_id: String) -> String:
	if character_id.begins_with("OP"):
		return "opponent"
	if character_id.begins_with("SF"):
		return "staff"
	return ""


## Up to `count` distinct characters for `stage_id`'s transition, each only
## counted once it actually has an eligible dialogue exchange — a cast
## candidate with nothing written for them here simply doesn't speak,
## rather than appearing silent. Sampled without replacement from the
## eligible cast pool, so the same transition never repeats a speaker.
static func pick_speakers(cast_rows: Array, dialogue_rows: Array, stage_id: String,
		count: int, rng: RandomNumberGenerator, hired_staff_ids: Variant = null,
		bill_id: String = "", lean: String = "", component_ids: Array = []) -> Array[Dictionary]:
	var remaining := PoolPicker.eligible(cast_rows, "stage_id", stage_id)
	# Staff are the player's own team: an SFxx cast member only speaks once
	# hired. `hired_staff_ids` null means "no filter" (older callers, tests).
	if hired_staff_ids is Array:
		remaining = remaining.filter(func(row: Dictionary) -> bool:
			var cid := str(row.get("character_id", ""))
			return character_kind(cid) != "staff" or cid in hired_staff_ids)
	var dialogue_here := PoolPicker.eligible(scope_dialogue(dialogue_rows, bill_id, lean, component_ids), "stage_id", stage_id)
	# Lines about this level's bill are preferred to the general ones.
	var about_bill := dialogue_here.filter(func(row: Dictionary) -> bool:
		return is_about_a_bill(row))
	var speakers: Array[Dictionary] = []

	while speakers.size() < count and not remaining.is_empty():
		var candidate: Dictionary = remaining[rng.randi_range(0, remaining.size() - 1)]
		remaining.erase(candidate)
		var character_id := str(candidate.get("character_id", ""))
		if character_id.is_empty():
			continue
		var exchange := PoolPicker.pick(about_bill, "character_id", character_id, rng)
		if exchange.is_empty():
			exchange = PoolPicker.pick(dialogue_here, "character_id", character_id, rng)
		if exchange.is_empty():
			continue
		speakers.append({
			"character_id": character_id,
			"character_line": str(exchange.get("character_line_en", "")),
			"player_reply": str(exchange.get("player_reply_en", "")),
		})

	return speakers


## Everything the screen needs for `stage`'s transition — `{"speakers":
## [...], "background_id": "..."}` — or `{}` when the stage doesn't show
## one, or shows one but nobody eligible has anything written.
static func resolve(stage: Dictionary, cast_rows: Array, background_rows: Array,
		dialogue_rows: Array, rng: RandomNumberGenerator, hired_staff_ids: Variant = null,
		thought_chance: int = 0, bill_id: String = "", lean: String = "",
		component_ids: Array = []) -> Dictionary:
	if not should_show(stage):
		return {}

	var stage_id := str(stage.get("stage_id", ""))
	var speakers := pick_speakers(cast_rows, dialogue_rows, stage_id, speaker_count(stage), rng,
		hired_staff_ids, bill_id, lean, component_ids)
	var thought := ""
	if speakers.is_empty():
		# Nobody is available to speak (no staff hired, no opponent cast):
		# the player alone has a private thought, if one is written.
		thought = player_thought(scope_dialogue(dialogue_rows, bill_id, lean, component_ids), stage_id, rng)
		if thought.is_empty():
			return {}
	elif thought_chance > 0 and rng.randi_range(1, 100) <= thought_chance:
		# Speakers are available, but the player sometimes opens with a
		# private thought first (2026-10-15).
		thought = player_thought(scope_dialogue(dialogue_rows, bill_id, lean, component_ids), stage_id, rng)

	var background := PoolPicker.pick(background_rows, "stage_id", stage_id, rng)
	return {
		"thought": thought,
		"speakers": speakers,
		"background_id": str(background.get("background_id", "")),
	}


## One internal-thought line for the player (Character ID "PLAYER" rows in
## Transition Dialogue), scoped by Stage ID like any other row. "" if none.
static func player_thought(dialogue_rows: Array, stage_id: String, rng: RandomNumberGenerator) -> String:
	var mine := dialogue_rows.filter(func(row: Dictionary) -> bool:
		return str(row.get("character_id", "")) == "PLAYER")
	# A thought about this level's bill (already scoped by the caller) is
	# preferred to a general one.
	var about_bill := mine.filter(func(row: Dictionary) -> bool: return is_about_a_bill(row))
	var row := PoolPicker.pick(about_bill if not about_bill.is_empty() else mine, "stage_id", stage_id, rng)
	return str(row.get("character_line_en", ""))


## Rows that suit this level: the general ones (no Bill ID), plus rows about
## `bill_id` whose Stance is blank or matches the player's `lean`. A level
## without a bill (or a row about another bill) never sees bill rows.
static func scope_dialogue(rows: Array, bill_id: String, lean: String,
		component_ids: Array = []) -> Array:
	return rows.filter(func(row: Dictionary) -> bool:
		var row_components: Variant = row.get("component_ids")
		if row_components is Array and not (row_components as Array).is_empty():
			# A row about bill components: only a level whose bill uses one.
			var uses_one := false
			for id: Variant in row_components:
				if component_ids.has(id):
					uses_one = true
			if not uses_one:
				return false
			return _blank(row.get("stance")) or str(row.get("stance")) == lean
		if _blank(row.get("bill_id")):
			return true
		if str(row.get("bill_id")) != bill_id:
			return false
		return _blank(row.get("stance")) or str(row.get("stance")) == lean)


## True for a row written about a bill or about bill components.
static func is_about_a_bill(row: Dictionary) -> bool:
	var row_components: Variant = row.get("component_ids")
	return not _blank(row.get("bill_id")) or (row_components is Array and not (row_components as Array).is_empty())


static func _blank(value: Variant) -> bool:
	return value == null or str(value).strip_edges().is_empty()
