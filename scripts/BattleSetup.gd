class_name BattleSetup
extends RefCounted
## Builds the configuration a battle needs, out of the game's data files.
##
## WHY THIS EXISTS
## The rules engine in scripts/rules/ is deliberately cut off from everything
## else: it never reads a file and never asks an autoload for anything. That
## separation is what lets the whole of it be tested without the game running.
##
## But something has to fetch the stage, the opponent and the deck and hand
## them over. That is this file's only job. It knows about DataDB, and it
## knows what shape BattleEngine.setup() wants, and nothing else.
##
## It sits at the top of scripts/ rather than in rules/ or ui/, because it is
## neither: putting it in rules/ would break the rule that rules code touches
## no autoloads, and it draws nothing on screen.
##
## USE
##     var config := BattleSetup.for_level_stage("LV06", "ST02")
##     var engine := BattleEngine.new()
##     engine.setup(config)


## Builds a battle straight from a level ID and a stage ID — the normal way
## to open one stage of a real level without going through a LevelRunner
## first (the battle screen's own editor-default fallback uses this; the
## in-level route is for_playtest_stage(), fed by LevelRunner.current_stage()
## on an already-expanded level).
##
## `meta` is the player's current standing; leave it out and the starting
## values from sanban.json are used.
static func for_level_stage(level_id: String, stage_id: String, meta: Dictionary = {}) -> Dictionary:
	var expanded := expand_level(DataDB.get_level(level_id))
	for stage: Dictionary in expanded.get("stages", []):
		if str(stage.get("stage_id", "")) == stage_id:
			return for_playtest_stage(stage, {}, meta)

	push_error("BattleSetup: %s has no stage '%s'." % [level_id, stage_id])
	return {}


## Expands one of levels.json's 30 flat rows (stage_1..stage_10, no opponent
## column) into the { level_id, stages: [...] } shape LevelRunner.gd already
## understands — the same shape the old hand-written levels.json used to
## produce, so LevelRunner needed no changes for this migration.
##
## Each entry in "stages" is a full row from DataDB.stages (so segment_mix,
## every win_delta_*/loss_delta_* field, everything LevelRunner already reads
## is present) plus:
##   seq                1, 2, 3... in stage_1..stage_10 order, skipping nulls
##   opponents          [the opponent], for a non-committee combat stage
##   committee_members  the roster, for a committee stage (see
##                      DataDB.COMMITTEE_STAGE_IDS)
##
## Who fights whom is not in the workbook — see _opponent_for()'s own
## comment for how that is decided, and how to pin one by hand.
static func expand_level(level: Dictionary) -> Dictionary:
	if level.is_empty():
		return {}

	var level_id := str(level.get("level_id", ""))
	var stages: Array = []

	for slot in range(1, 11):
		# An empty slot is JSON null, not "" — most levels use fewer than
		# ten. str(null) in GDScript is the literal text "<null>", not an
		# empty string, so the null check has to happen before the str()
		# cast or an unused slot is mistaken for a stage called "<null>".
		var raw_stage_id: Variant = level.get("stage_%d" % slot)
		if raw_stage_id == null:
			continue
		var stage_id := str(raw_stage_id).strip_edges()
		if stage_id.is_empty():
			continue

		var stage := DataDB.get_stage(stage_id)
		if stage.is_empty():
			push_warning("BattleSetup: %s names stage '%s', which does not exist." % [level_id, stage_id])
			continue
		stage = stage.duplicate(true)
		stage["seq"] = stages.size() + 1

		if DataDB.is_committee_stage(stage_id):
			var committee := _committee_for(level_id, stage_id, slot)
			stage["opponents"] = ([committee["chair"]] if not (committee["chair"] as Dictionary).is_empty()
				else [])
			stage["committee_members"] = committee["members"]
		else:
			stage["opponents"] = _opponents_for(level_id, stage_id, slot, _opponent_count(stage))
			stage["committee_members"] = []

		stages.append(stage)

	var expanded := level.duplicate(true)
	expanded["stages"] = stages
	return expanded


## Every opponent eligible for a stage — every opponents.json row whose own
## "stages" list names this STxx — in a stable, deterministic order (lowest
## opp_id first) so the same data always resolves the same way.
##
## Fetched through DataDB.get_opponent() rather than read straight off
## DataDB.opponents, so each one already carries its built intent_pattern —
## an opponent handed to a battle without it plays as the generic default,
## which is exactly the bug this would otherwise reintroduce for every level.
static func eligible_opponents(stage_id: String) -> Array:
	var found: Array = []
	for opponent: Dictionary in DataDB.get_opponents_for_stage(stage_id):
		found.append(DataDB.get_opponent(str(opponent.get("opp_id", ""))))
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("opp_id", "")) < str(b.get("opp_id", "")))
	return found


## The hand-written pin for one level+slot from
## data/level_opponent_overrides.json, or null when there isn't one.
static func _override_for(level_id: String, slot: int) -> Variant:
	for row: Dictionary in DataDB.level_opponent_overrides:
		if str(row.get("level_id", "")) == level_id and int(row.get("slot", -1)) == slot:
			return row
	return null


## Which single opponent a level's non-committee stage fights.
##
## [DEFAULT] Cameron settled this 2026-09-22: read it DYNAMICALLY off the
## Opponents tab's own "stages" list rather than storing a chosen opponent per
## level, so adding or editing an opponent's eligible stages is the whole job
## — no level data to touch. Where more than one opponent is eligible, the
## lowest opp_id is the tie-breaker: arbitrary, but stable, so a level opens
## the same way until it is pinned.
##
## data/level_opponent_overrides.json can PIN a specific opponent to a
## specific level+stage slot; a pin always wins when it names someone who
## really is eligible for that stage, and falls back to the dynamic pick
## (with a warning) otherwise, rather than seating someone in a room the
## workbook does not say they belong in.
static func _opponent_for(level_id: String, stage_id: String, slot: int) -> Dictionary:
	var eligible := eligible_opponents(stage_id)
	var pinned := _resolve_pin(level_id, stage_id, slot)
	if not pinned.is_empty():
		return pinned
	return eligible[0] if not eligible.is_empty() else {}


## How many opponents a non-committee stage fights, from its own
## "opponent_count" range column (a proposed stages.json addition, the same
## "min-max" range-string convention as Levels' bonus-win columns — exported
## as {"min","max"} or null). No column, or a range that only ever rolls 1,
## is the same single-opponent stage every canon row plays today; the roll
## itself is unseeded, matching how every other range in the game (a level's
## bonus_win_range_*, GameState._roll_range()) is already rolled.
static func _opponent_count(stage: Dictionary) -> int:
	var declared: Variant = stage.get("opponent_count")
	if not (declared is Dictionary) or not (declared as Dictionary).has("min"):
		return 1
	var low := int((declared as Dictionary)["min"])
	var high := int((declared as Dictionary)["max"])
	if high <= low:
		return maxi(low, 1)
	return randi_range(low, high)


## `count` opponents for a non-committee stage whose "opponent_count" calls
## for more than one, in sequence — what CARRIES OVER between them (energy,
## hand, gaffe, or a fresh start each time) is a separate question, answered
## entirely by the stage's own "sequence_mode" (BattleEngine._sequence_mode);
## this function only decides WHO is in the sequence. Same dynamic-by-default
## rule as _opponent_for(): a pin fills the first slot, lowest opp_id among
## the rest of the eligible pool fills however many more are needed. A stage
## whose eligible pool is smaller than its own opponent_count plays with
## whoever exists rather than failing setup outright — BattleEngine already
## reports "a committee stage needs its members" style problems for an empty
## list, and an empty one here does the same through has_more_opponents().
static func _opponents_for(level_id: String, stage_id: String, slot: int, count: int) -> Array:
	if count <= 1:
		var opponent := _opponent_for(level_id, stage_id, slot)
		return [opponent] if not opponent.is_empty() else []

	var eligible := eligible_opponents(stage_id)
	var chosen: Array = []

	var pinned := _resolve_pin(level_id, stage_id, slot)
	if not pinned.is_empty():
		chosen.append(pinned)

	for candidate: Dictionary in eligible:
		if chosen.size() >= count:
			break
		if not pinned.is_empty() and str(candidate.get("opp_id", "")) == str(pinned.get("opp_id", "")):
			continue
		chosen.append(candidate)

	return chosen


## The committee roster and chair for a committee stage: { chair, members }.
##
## Same dynamic-by-default rule as _opponent_for(). [DEFAULT] the chair —
## who runs the meeting and is not a voting tile, CLAUDE.md §7.5 — is the
## lowest opp_id among those eligible, since nothing in the new data says who
## chairs which committee; ask Cameron before this is treated as final. A pin
## for a committee slot means "make sure this opponent is on the roster, as
## its chair", not "replace the roster" — a committee needs its full eligible
## pool to have anyone left to persuade.
static func _committee_for(level_id: String, stage_id: String, slot: int) -> Dictionary:
	var eligible := eligible_opponents(stage_id)
	var chair: Dictionary = eligible[0] if not eligible.is_empty() else {}

	var pinned := _resolve_pin(level_id, stage_id, slot)
	if not pinned.is_empty():
		chair = pinned
		var already := false
		for member: Dictionary in eligible:
			if str(member.get("opp_id", "")) == str(pinned.get("opp_id", "")):
				already = true
				break
		if not already:
			eligible.append(pinned)

	var members := eligible.duplicate()
	if not chair.is_empty():
		for index in members.size():
			if str(members[index].get("opp_id", "")) == str(chair.get("opp_id", "")):
				members.remove_at(index)
				break

	return {"chair": chair, "members": members}


## Looks up and validates one level+slot's override row, if any. Returns an
## empty dictionary where there is none, the pin names someone who does not
## exist, or the pin names someone not eligible for that stage — in the last
## two cases with a warning, since a pin that cannot be honoured should be
## noticed rather than silently ignored.
static func _resolve_pin(level_id: String, stage_id: String, slot: int) -> Dictionary:
	var override_row: Variant = _override_for(level_id, slot)
	if override_row == null:
		return {}

	var opp_id := str((override_row as Dictionary).get("opp_id", ""))
	var pinned := DataDB.get_opponent(opp_id)
	if pinned.is_empty():
		push_warning("BattleSetup: %s slot %d pins unknown opponent '%s'." % [level_id, slot, opp_id])
		return {}
	if not (pinned.get("stages", []) as Array).has(stage_id):
		push_warning(("BattleSetup: %s slot %d pins %s, who is not eligible for %s. "
			+ "Falling back to the dynamic pick.") % [level_id, slot, opp_id, stage_id])
		return {}
	return pinned


## Which stage IDs draw from which of data/questions.json's five pools.
##
## [DEFAULT], 2026-09-22: nothing in the new stages.json says which STxx asks
## from which pool — the old link ran through stage_types.json's
## affinity_stage_id, which is the hand-written PLAYTEST vocabulary and does
## not line up with the real committee stages this migration adds (it points
## policy_study at ST01 and lobbyist_meeting at ST07, which are not their
## real workbook counterparts). Mapped directly here instead, by the plainest
## reading of each pool's name against the 21 canon stages. ST05 Town Hall is
## deliberately left out: CLAUDE.md already documents that its 20 questions
## are written but the stage does not ask them yet, and this migration is not
## the place to decide that it should. ST06 TV Debate is not one of the five
## pools either, same as before.
const QUESTION_POOL_BY_STAGE := {
	"ST04": "press_conference",
	"ST19": "media_ambush",
	"ST20": "lobbyist_meeting",
	"ST21": "policy_study",
}

## The fallback for _reputation_affects_start() below, for a stage row with
## no "reputation_affects_start" column of its own — every canon row today.
const REPUTATION_START_STAGE_IDS := ["ST04", "ST06"]


## Whether Reputation nudges this stage's opening bar. Checks the stage's own
## "reputation_affects_start" (Yes/No, from a proposed stages.json column)
## first; REPUTATION_START_STAGE_IDS is the fallback.
## Which of data/questions.json's five pools a stage draws from: its own
## "type" (the hand-written playtest vocabulary) if set, else its own
## "question_pool" column (a proposed stages.json addition) if set, else
## QUESTION_POOL_BY_STAGE's fallback for a canon row with neither.
static func _question_pool_name(stage: Dictionary, stage_id: String) -> String:
	var type_value: Variant = stage.get("type")
	if type_value != null and not str(type_value).is_empty():
		return str(type_value)
	var pool_value: Variant = stage.get("question_pool")
	if pool_value != null and not str(pool_value).is_empty():
		return str(pool_value).to_lower()
	return str(QUESTION_POOL_BY_STAGE.get(stage_id, ""))


static func _reputation_affects_start(stage: Dictionary, stage_id: String) -> bool:
	var raw: Variant = stage.get("reputation_affects_start")
	if raw != null:
		var declared := str(raw).strip_edges()
		if not declared.is_empty():
			return declared.to_lower() == "yes"
	return REPUTATION_START_STAGE_IDS.has(stage_id)


## Builds a battle from one stage — a canon stages.json row, whether it
## arrived via a level's expand_level() (with "opponents"/"committee_members"
## already attached) or the old hand-written playtest stage shape. The two
## produce the same kind of dictionary, so BattleEngine cannot tell them
## apart.
##
## `buffs` is whatever earlier stages of the level left behind, from
## LevelRunner.carried_buffs().
static func for_playtest_stage(stage: Dictionary, buffs: Dictionary = {},
		meta: Dictionary = {}) -> Dictionary:
	if stage.is_empty():
		return {}

	stage = resolve_type(stage)

	if meta.is_empty():
		meta = starting_meta()

	var opponents: Array = stage.get("opponents", [])
	var stage_id := str(stage.get("stage_id", ""))
	var bonus := backing_bonus(stage)

	var start_adjustment := int(buffs.get("support_bonus", 0)) + int(bonus.get("start_support", 0))
	# Reputation opens a press stage for or against the player — the same
	# effect from_row() used to apply for the workbook's module route, now
	# folded in here since a level's expanded stages are real ST04/ST06 rows.
	if _reputation_affects_start(stage, stage_id):
		start_adjustment += MetaRules.press_start_adjustment(
			int(meta.get("Reputation", 50)), DataDB.sanban)

	var config := {
		"stage": with_audience(stage),
		# The first opponent; the rest arrive as the stage's sequencing is
		# built in phase 3. Until then a stage plays its opening opponent.
		"opponent": opponents[0] if not opponents.is_empty() else {},
		"opponents": opponents,
		"committee_members": stage.get("committee_members", []),
		"cards": card_table(),
		"affinity": affinity_table(),
		"rules": DataDB.rules,
		"strings": DataDB.strings,
		"meta": meta,
		# The questions this kind of room can ask. The engine deals from it
		# with the battle's own seed, and only where the stage has not
		# written its own questions out longhand. A stage's own type or
		# "question_pool" column (a proposed stages.json addition) wins;
		# QUESTION_POOL_BY_STAGE is the fallback for a canon row with neither.
		"question_pool": DataDB.questions.get(_question_pool_name(stage, stage_id), []),
		"deck": player_deck(),
		# A good caucus earlier in the level starts this stage ahead, and so
		# does an organisation whose backing you have bought (STAGE_START_BONUS).
		"start_adjustment": start_adjustment,
		"hand_size_bonus": int(bonus.get("hand_size_bonus", 0)),
		"gaffe_limit_bonus": int(bonus.get("gaffe_limit_bonus", 0)),
	}

	return config


## What the organisations backing you are worth in this room.
##
## Backing only counts where the audience it cares about is actually here:
## a friendly beat reporter does nothing in a caucus with no press in it.
## MetaRules.active_modifiers decides that, off the stage's own mix. Which of
## the three stage-scoped effect types actually apply is then narrowed again
## by stage ID, inside ModifierEffects.battle_start_bonus().
static func backing_bonus(stage: Dictionary) -> Dictionary:
	var owned: Array = []
	for mod_id: String in GameState.owned_modifiers:
		var modifier := DataDB.get_modifier(mod_id)
		if not modifier.is_empty():
			owned.append(modifier)

	var empty := {"start_support": 0, "hand_size_bonus": 0, "gaffe_limit_bonus": 0}
	if owned.is_empty():
		return empty

	var active := MetaRules.active_modifiers(owned, with_audience(stage), "Player")
	if active.is_empty():
		return empty
	return ModifierEffects.battle_start_bonus(active, str(stage.get("stage_id", "")))


## Expands a level's stage row into a full stage.
##
## A row in levels.json names a TYPE and overrides only what it wants to
## differ. Everything else comes from stage_types.json, so "the default
## committee is 60 votes" is one number in one place rather than one per
## level that happens to contain a committee.
##
## A stage with no type is returned untouched: the old hand-written
## playtest level still works, and so does a module row from the workbook.
static func resolve_type(stage: Dictionary) -> Dictionary:
	var type_id := str(stage.get("type", ""))
	if type_id.is_empty():
		return stage

	var template: Dictionary = DataDB.stage_types.get(type_id, {})
	if template.is_empty():
		push_warning("BattleSetup: no stage type called '%s'." % type_id)
		return stage

	var resolved := template.duplicate(true)
	resolved.merge(stage, true)   # the level's own values win

	# A stage needs an ID: the type plus its place in the level, so two
	# study sessions in one level are still told apart in a report.
	if not resolved.has("stage_id"):
		resolved["stage_id"] = "%s_%d" % [type_id.to_upper(), int(stage.get("seq", 0))]

	resolved["name_en"] = fill_tokens(str(resolved.get("name_en", "")))
	return resolved


## Fills the tokens a stage name may carry.
##
## Only {party} so far: a caucus is the player's own party's caucus, and
## naming it in the data would fix a party CLAUDE.md still lists as open.
static func fill_tokens(text: String) -> String:
	if not text.contains("{party}"):
		return text
	var party := str(DataDB.player.get("party", "")).strip_edges()
	if party.is_empty():
		return text.replace("{party} ", "").replace("{party}", "").strip_edges()
	return text.replace("{party}", party)


## Fills in who is in the room, where a stage does not say.
##
## Every stage in the workbook carries a segment_mix — how much of the
## audience is Press, Loyalists, Constituents, Donors, Bureaucrats — and the
## hand-written playtest stages carry none, so every card aimed at a
## particular audience currently reads that audience as zero per cent of the
## room.
##
## Rather than invent percentages, a playtest stage borrows the mix of the
## canon stage it already names in affinity_stage_id: the playtest press
## conference is modelled on ST04, so it gets ST04's room. A stage that
## declares its own mix keeps it.
static func with_audience(stage: Dictionary) -> Dictionary:
	if stage.has("segment_mix"):
		return stage

	var modelled_on := str(stage.get("affinity_stage_id", ""))
	if modelled_on.is_empty():
		return stage

	var canon := DataDB.get_stage(modelled_on)
	if not canon.has("segment_mix"):
		return stage

	var filled := stage.duplicate(true)
	filled["segment_mix"] = canon["segment_mix"]
	# 2026-09-22 workbook: a room's audience can include a "% Other" share
	# (pct_other) that isn't one of segment_mix's rows but is still part of
	# the 100%, the same as DataDB.gd's own audience-shares check now reads
	# it. Borrowed alongside segment_mix so a playtest stage modelled on a
	# canon room gets the same total, not 100% minus whatever Other was.
	if canon.has("pct_other"):
		filled["pct_other"] = canon["pct_other"]
	return filled


## How much harder a bill is because of where public opinion sits.
##
## Kept even though nothing calls it any more: the Bills and Yoron tabs are
## not in the 2026-09-22 workbook pull (bills.json/yoron.json on disk are
## stale leftovers from the previous one), so there is currently no route
## that has a bill to look up. The maths is still right and still tested —
## MetaRules.bill_difficulty_from_data does the real work — so this is one
## line to delete rather than a system to rebuild the day bills come back.
static func bill_difficulty(bill: Dictionary) -> int:
	if bill.is_empty():
		return 0
	var topic := DataDB.get_topic(str(bill.get("topic_id", "")))
	if topic.is_empty():
		return 0
	return MetaRules.bill_difficulty_from_data(bill, topic, DataDB.balance)


## The player's opening deck: every Starter-tier card in the workbook.
##
## There are 12 of them, and balance.json's "starter deck size" is also 12,
## so the two agree today. They are not the same thing though, so if the
## counts ever diverge this says so rather than quietly dealing a wrong deck.
## The deck the player is taking in.
##
## The run's chosen deck where there is one, and the Starter twelve
## otherwise — a battle started outside a run, or before anything has been
## chosen, still deals a playable hand rather than nothing.
static func player_deck() -> Array[String]:
	if GameState.deck.is_empty():
		return starter_deck()
	return GameState.deck.duplicate()


static func starter_deck() -> Array[String]:
	var deck: Array[String] = []
	for card: Dictionary in DataDB.get_cards_by_tier(Ledger.OPENING_TIER):
		deck.append(str(card.get("card_id")))

	# Cards written by hand for the playtest are not the workbook's to count,
	# so they are taken off before comparing. Otherwise adding one to
	# playtest_cards.json would make the workbook look wrong.
	var from_workbook := deck.size()
	for card_id: String in deck:
		if DataDB.playtest_card_ids.has(card_id):
			from_workbook -= 1

	var expected := int(DataDB.get_balance("starter_deck_size", float(from_workbook)))
	if from_workbook != expected:
		push_warning(
			("BattleSetup: the workbook has %d Starter cards but says the starter deck "
			+ "should be %d. Using the %d that exist.") % [from_workbook, expected, deck.size()])

	return deck


## Every card, keyed by ID, for the engine to look up as they are played.
static func card_table() -> Dictionary:
	var table := {}
	for card: Dictionary in DataDB.cards:
		table[str(card.get("card_id"))] = card
	return table


## What each organisation is called, keyed by ID. The rules engine deals in
## IDs; anything shown to the player needs the name.
## Every organisation's ID, so the Ledger can tell a real backer from a
## modifier that names a meta-variable in the same column.
static func booster_ids() -> Array:
	var ids: Array = []
	for booster: Dictionary in DataDB.boosters:
		ids.append(str(booster.get("booster_id")))
	return ids


static func booster_names() -> Dictionary:
	var names := {}
	for booster: Dictionary in DataDB.boosters:
		names[str(booster.get("booster_id"))] = str(booster.get("name_en", ""))
	return names


## The suit-by-stage multipliers, in the shape the engine reads.
static func affinity_table() -> Dictionary:
	var table := {}
	for row: Dictionary in DataDB.affinity:
		table[str(row.get("element"))] = row.get("multipliers", {})
	return table


## The player's standing at the very start of a run, from sanban.json.
static func starting_meta() -> Dictionary:
	var meta := {}
	for variable: Dictionary in DataDB.sanban:
		meta[str(variable.get("name_en"))] = int(variable.get("start", 0))
	return meta
