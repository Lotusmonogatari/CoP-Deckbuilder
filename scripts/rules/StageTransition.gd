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
		count: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var remaining := PoolPicker.eligible(cast_rows, "stage_id", stage_id)
	var dialogue_here := PoolPicker.eligible(dialogue_rows, "stage_id", stage_id)
	var speakers: Array[Dictionary] = []

	while speakers.size() < count and not remaining.is_empty():
		var candidate: Dictionary = remaining[rng.randi_range(0, remaining.size() - 1)]
		remaining.erase(candidate)
		var character_id := str(candidate.get("character_id", ""))
		if character_id.is_empty():
			continue
		var exchange := PoolPicker.pick(dialogue_here, "character_id", character_id, rng)
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
		dialogue_rows: Array, rng: RandomNumberGenerator) -> Dictionary:
	if not should_show(stage):
		return {}

	var stage_id := str(stage.get("stage_id", ""))
	var speakers := pick_speakers(cast_rows, dialogue_rows, stage_id, speaker_count(stage), rng)
	if speakers.is_empty():
		return {}

	var background := PoolPicker.pick(background_rows, "stage_id", stage_id, rng)
	return {
		"speakers": speakers,
		"background_id": str(background.get("background_id", "")),
	}
