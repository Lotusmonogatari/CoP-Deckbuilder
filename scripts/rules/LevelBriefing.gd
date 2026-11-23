class_name LevelBriefing
extends RefCounted
## Everything the level briefing needs, as one plain dictionary (P12, 2026-11-19, Cameron).
##
## The briefing used to build its rows straight from the rules; the redesign draws it in three styles from a
## template, so the numbers are gathered here first and the screen only draws them. This file does the same
## reading OfficeScreen._show_briefing() always did (BriefingSummary for the rooms' rewards and totals,
## LevelBonus for the level bonus, TimeClock for hours, LevelRunner for the unset-reward and loss rules) and
## adds the week's numbers, the room kinds and the timeline's start hours. It holds no wording and no nodes.
## Pure and UI-free (CLAUDE.md section 12): callers hand in everything that lives in an autoload.
##
## A room whose Stages-tab "Reveal In Briefing" cell is No stays out of the rooms, the room count and the
## timeline, so nothing hints it exists; its hours still count in the total, as they always have.
##
## The dictionary (all keys always present):
##   level_id, title, tier (int), hours (total, hidden rooms and built-in travel included), room_count (shown rooms),
##   travel_hours (the built-in trips' hours, 0 for most levels), travel_trips, travel_mode (the mode id they are priced at),
##   travel_options ([ { mode, hours, owned, enough } ]: the ways to pay for the trips, for the briefing's row),
##   lists_rooms (false for a level with one shown room: totals only),
##   anything_set (false when no shown room and no bonus has a reward),
##   purpose { text, speaker } ({} when the level has none; speaker "" is narration),
##   week { phase, pool, used, left, this_level, after, overflow },
##   totals { name: amount } (BriefingSummary.total_rewards), bonus (LevelBonus.preview),
##   rooms [ { n, name, start, hours, kind, rewards, rewards_unset, loss_continues, loss, stage_id, tips } ],
##   refusal (why the level cannot start, "" when it can), location ("" until the two-offices plan has one).
## `loss` is each room's loss cost, carried so a later change can show it; the screen does not show it yet.

const KIND_CONVERSATION := "conversation"
const KIND_DEBATE := "debate"
const KIND_VOTE := "vote"
const KIND_VISIT := "visit"
const KIND_TRADE := "trade"


## The briefing's data for `level` (the expanded level, with its "stages"). `tier` is the Campaign Pressure.
## `context` carries what comes from the run: "hours_left" and "pool" (the work week's or the weekend's),
## "phase" ("work" or "weekend"), "purpose" (LevelPurpose.resolve()'s answer, or {}), "refusal" and
## "location" (both optional).
static func build(level: Dictionary, tier: String, base_balance: Dictionary, context: Dictionary) -> Dictionary:
	var stages: Array = level.get("stages", [])
	var shown: Array = []
	var total_hours := 0
	for stage: Dictionary in stages:
		total_hours += TimeClock.units_for_stage(stage)
		if is_revealed(stage):
			shown.append(stage)

	var rooms: Array = []
	var start := 0
	var any_reward := false
	for stage: Dictionary in shown:
		var hours := TimeClock.units_for_stage(stage)
		var unset := LevelRunner.rewards_are_unset(stage)
		if not unset:
			any_reward = true
		rooms.append({
			"n": rooms.size() + 1,
			"name": str(stage.get("name_en", "")),
			"start": start,
			"hours": hours,
			"kind": kind_of(stage),
			"rewards": BriefingSummary.stage_rewards(stage),
			"rewards_unset": unset,
			"loss_continues": loses_continue(stage),
			"loss": LevelRunner.loss_penalties(stage),
			# The rhetoric tips the player holds about this room, or a person who may sit in it (P16, 2026-11-23): "room_tips" in
			# the context is {stage_id: [tip rows]}.
			"stage_id": str(stage.get("stage_id", "")),
			"tips": (context.get("room_tips", {}) as Dictionary).get(str(stage.get("stage_id", "")), []),
		})
		start += hours

	var bonus := LevelBonus.preview(level, tier, base_balance)
	if not LevelBonus.is_empty(bonus):
		any_reward = true
	# A mixed level's trips between the offices (two offices, 2026-11-20) add their hours to the level's.
	var travel_hours := maxi(0, int(context.get("travel_hours", 0)))

	return {
		"level_id": str(level.get("level_id", "")),
		"title": str(level.get("description", "")).strip_edges(),
		"tier": int(level.get("tier", 0)),
		"hours": total_hours + travel_hours,
		"travel_hours": travel_hours,
		"travel_trips": int(context.get("travel_trips", 0)),
		"travel_mode": str(context.get("travel_mode", "")),
		"travel_options": context.get("travel_options", []),
		"room_count": shown.size(),
		"lists_rooms": BriefingSummary.lists_stages(shown),
		"anything_set": any_reward,
		"purpose": purpose_of(context.get("purpose", {})),
		"week": week_of(total_hours + travel_hours, int(context.get("hours_left", 0)), int(context.get("pool", 0)),
			str(context.get("phase", "work"))),
		"totals": BriefingSummary.total_rewards(shown),
		"bonus": bonus,
		"rooms": rooms,
		"refusal": str(context.get("refusal", "")),
		"location": str(context.get("location", "")),
	}


## True unless the Stages tab's "Reveal In Briefing" cell is explicitly No. Blank (null) keeps every room
## named before the player goes in.
static func is_revealed(stage: Dictionary) -> bool:
	var value: Variant = stage.get("reveal_in_briefing")
	if value == null:
		return true
	return str(value).strip_edges().to_lower() != "no"


## What sort of room a stage is, for the label on its block: a card battle is a debate, an Office Hours style
## room a conversation, and the Floor Vote, a member visit and a lobbyist trade have their own.
static func kind_of(stage: Dictionary) -> String:
	match str(stage.get("mode", "")):
		"Non-combat":
			return KIND_CONVERSATION
		"Vote":
			return KIND_VOTE
		"Visit":
			return KIND_VISIT
		"Trade":
			return KIND_TRADE
	return KIND_DEBATE


## True for a card battle whose loss costs but does not end the level (the press conference, the media
## ambush and the rest of the Stages tab's "Loss Ends Level: No" rooms), as StageBrief says in the battle.
static func loses_continue(stage: Dictionary) -> bool:
	return str(stage.get("mode", "")) == "Combat" and not LevelRunner.loss_ends_level(stage)


## { text, speaker } from LevelPurpose.resolve()'s answer; {} when there is no purpose line. A speaker of ""
## is narration (no staff hired), shown with no name.
static func purpose_of(resolved: Variant) -> Dictionary:
	if not (resolved is Dictionary) or (resolved as Dictionary).is_empty():
		return {}
	return {"text": str((resolved as Dictionary).get("text", "")),
		"speaker": str((resolved as Dictionary).get("staff_name", ""))}


## The week's numbers around this level: `pool` is the hours in the work week (or the weekend), `left` what is
## unspent, so `used` is the rest. `after` is what is left once the level is played (0 when it does not fit,
## with `overflow` true so the bar can show it).
static func week_of(level_hours: int, hours_left: int, pool: int, phase: String) -> Dictionary:
	var left := maxi(0, hours_left)
	var used := maxi(0, pool - left)
	return {
		"phase": phase,
		"pool": pool,
		"used": used,
		"left": left,
		"this_level": mini(level_hours, left),
		"after": maxi(0, left - level_hours),
		"overflow": level_hours > left,
	}
