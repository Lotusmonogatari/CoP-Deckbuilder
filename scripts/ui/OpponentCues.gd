class_name OpponentCues
extends RefCounted
## What an opponent says on their own turn, from the workbook's Opponent
## Cues tab.
##
## Two kinds of row: a bespoke one names one or more Opponent IDs and is
## checked FIRST — never blended with the general pool. A general row names
## no opponent at all, and is the pool every opponent with that Suit draws
## from for that Verb, when no bespoke line exists for them.
##
## WHICH SUIT'S POOL an opponent draws from IS random, unlike the line
## picked within it: mostly their own suit_1 (55%), sometimes suit_2 (30%)
## or suit_3 (10%), and occasionally (5%) a suit that isn't tagged to them
## at all — a debater going off their usual script. Cameron asked for this
## mix; it is presentation, not a rules decision, so it lives here rather
## than behind a rules.json switch. WHICH LINE within that suit's pool is a
## line not yet said this level (pick_unused(), 2026-11-04), chosen among the
## unused ones from the opponent, the verb, the stage and the turn; once a
## pool is used up, the line said longest ago comes back.
##
## This is presentation. The rules never see a cue, and an opponent or suit
## with nothing written yet simply says nothing — BattleScreen falls back to
## today's narration-only banner.

## Cumulative thresholds for _suit_bucket(): a roll below PRIMARY lands on
## suit_1, below SECONDARY on suit_2, below TERTIARY on suit_3, and anything
## at or above TERTIARY is the "some other suit" 5% left over.
const PRIMARY_THRESHOLD := 0.55
const SECONDARY_THRESHOLD := 0.85
const TERTIARY_THRESHOLD := 0.95


## One of the opponent's lines for this moment: what is said, and the key a
## recording of it would live under in data/sounds.json.
##
## Comes back empty where nothing is written for the suit this moment
## landed on, which is what the screen checks before it says anything —
## even an opponent with plenty written can still go quiet on the rolls
## that pick a suit nothing is written for yet.
##
## suit_roll and other_suit_roll are 0..1 and default to a real die roll;
## tests pass them in directly to pin which suit gets picked, the same way
## IntentRunner's tests pin its own rolls without touching randf() itself.
static func for_move(opponent: Dictionary, verb: String, stage_id: String, turn: int,
		suit_roll: float = -1.0, other_suit_roll: float = -1.0, bill_id: String = "",
		general_roll: float = -1.0) -> Dictionary:
	var opp_id := str(opponent.get("opp_id", ""))
	if opp_id.is_empty() or verb.is_empty():
		return {"text": "", "line_id": ""}
	if general_roll < 0.0:
		general_roll = randf()

	# Lines written about this level's bill come before every other tier
	# (2026-10-18): this opponent's own, then the suit's.
	if not bill_id.is_empty():
		if suit_roll < 0.0:
			suit_roll = randf()
		if other_suit_roll < 0.0:
			other_suit_roll = randf()
		var bill_suit := _suit_for_move(opponent, suit_roll, other_suit_roll)
		# Only lines on this person's side of the bill, or neutral ones, and a
		# party leader may also say their party's own Floor Vote line
		# (2026-11-04, Cameron; MemberStance.gd).
		var bill: Dictionary = DataDB.floor_votes.get(bill_id, {})
		var allowed := MemberStance.sides(opponent, bill, DataDB.parties,
			BillStance.sides(bill, DataDB.law_effects, GameState._party_tier_booster_ids()),
			int(DataDB.balance.get("member_stance_split_party_abstain_percent", 30)),
			_player_side(bill_id))
		var about_bill: Array[String] = DataDB.get_bill_opponent_cue_lines(bill_id, opp_id, bill_suit, verb, allowed)
		var leader_line := MemberStance.leader_line(opponent, bill, DataDB.parties)
		if not leader_line.is_empty():
			about_bill.append(leader_line)
		if not about_bill.is_empty():
			var picked := pick_unused(about_bill, GameState.opponent_lines_said,
				_index_for(opp_id, verb, stage_id, turn))
			return {"text": about_bill[picked], "line_id": "%s_%s_%d" % [opp_id, verb, picked + 1]}

	# Stage-specific rows first, inside each lookup (2026-10-12): this
	# opponent in this stage, this opponent in this style, this opponent
	# anywhere, then the suit's pool in this stage, then the suit's pool
	# anywhere.
	if suit_roll < 0.0:
		suit_roll = randf()
	if other_suit_roll < 0.0:
		other_suit_roll = randf()
	var suit := _suit_for_move(opponent, suit_roll, other_suit_roll)
	var lines: Array[String] = DataDB.get_bespoke_opponent_cue_lines(opp_id, verb, stage_id, suit)
	var general: Array[String] = DataDB.get_general_opponent_cue_lines(suit, verb, stage_id)
	# Now and then the style's shared pool speaks instead of the personal
	# lines (2026-10-18), so a person is not only ever their own few lines.
	if lines.is_empty() or (not general.is_empty() and general_roll < _general_chance()):
		lines = general
	if lines.is_empty():
		return {"text": "", "line_id": ""}

	var which := pick_unused(lines, GameState.opponent_lines_said,
		_index_for(opp_id, verb, stage_id, turn))
	return {
		"text": lines[which],
		"line_id": "%s_%s_%d" % [opp_id, verb, which + 1],
	}


## The player's own side on this bill (MemberStance.player_side_for()), or ""
## when they took no lean on it.
static func _player_side(bill_id: String) -> String:
	if str(GameState.bill_stance.get("bill_id", "")) != bill_id:
		return ""
	return MemberStance.player_side_for(GameState.stance_lean())


## Which of `lines` to say, and records it in `said` ({text: order said}).
## A line not yet said this level comes first, chosen by `seed` among the
## unused ones; when every line has been said, the one said longest ago is
## reused (2026-11-04, Cameron: no repeats within a level while lines last).
static func pick_unused(lines: Array, said: Dictionary, seed: int) -> int:
	var unused: Array[int] = []
	for i in lines.size():
		if not said.has(lines[i]):
			unused.append(i)
	var picked := 0
	if not unused.is_empty():
		picked = unused[absi(seed) % unused.size()]
	else:
		for i in lines.size():
			if int(said[lines[i]]) < int(said[lines[picked]]):
				picked = i
	var next_order := 0
	for order: Variant in said.values():
		next_order = maxi(next_order, int(order) + 1)
	said[lines[picked]] = next_order
	return picked


## Chance (0..1) that the style's shared pool speaks instead of an
## opponent's personal lines; Balance lever "Opponent Cues: General Pool
## Chance" (percent), 0 when absent.
static func _general_chance() -> float:
	return float(DataDB.balance.get("opponent_cues_general_pool_chance", 0)) / 100.0


## Which of the opponent's suits (or an outside one) this roll picked — the
## pure half of the weighting, with the die roll itself passed in rather
## than called here, so it can be pinned in a test.
static func _suit_for_move(opponent: Dictionary, suit_roll: float, other_suit_roll: float) -> String:
	match _suit_bucket(suit_roll):
		"suit_1":
			return str(opponent.get("suit_1", ""))
		"suit_2":
			return str(opponent.get("suit_2", ""))
		"suit_3":
			return str(opponent.get("suit_3", ""))
		_:
			return _other_suit(opponent, other_suit_roll)


## Which bucket a 0..1 roll lands in, against the cumulative thresholds
## above: suit_1 (55%), suit_2 (30%), suit_3 (10%), or "other" (5%).
static func _suit_bucket(roll: float) -> String:
	if roll < PRIMARY_THRESHOLD:
		return "suit_1"
	if roll < SECONDARY_THRESHOLD:
		return "suit_2"
	if roll < TERTIARY_THRESHOLD:
		return "suit_3"
	return "other"


## A suit that isn't tagged to this opponent at all, picked uniformly by a
## second roll. Empty if every suit in the game somehow belongs to them.
static func _other_suit(opponent: Dictionary, roll: float) -> String:
	var own := [
		str(opponent.get("suit_1", "")),
		str(opponent.get("suit_2", "")),
		str(opponent.get("suit_3", "")),
	]
	var others: Array[String] = []
	for suit: Dictionary in DataDB.suits:
		var name := str(suit.get("element", ""))
		if not own.has(name):
			others.append(name)
	if others.is_empty():
		return ""
	var index := clampi(int(roll * others.size()), 0, others.size() - 1)
	return others[index]


## Which line, as a number that is stable for a given moment. See
## CardCues._index_for() — same idea, one more field (the verb) since one
## opponent has a line for each of the three verbs.
static func _index_for(opp_id: String, verb: String, stage_id: String, turn: int) -> int:
	return absi(hash("%s|%s|%s|%d" % [opp_id, verb, stage_id, turn]))
