class_name FloorVoteEngine
extends RefCounted
## National Assembly Floor Voting (ST23): one Yes/No/Abstain choice.
##
## No cards, no turns, no gaffe meter — the simplest engine in scripts/rules/
## next to OfficeHoursEngine.gd, and built the same way: setup() is handed
## already-resolved data (DataDB.get_floor_vote(), fetched by whatever calls
## this — BattleSetup, in the real game), and this class never touches an
## autoload, a file, or the scene tree.
##
## Every party's own vote split is baked into the bill's data, ASSUMING the
## player voted with their own party's majority. choose() is where that
## assumption gets corrected: if the player picks something else, one seat
## moves out of whichever bucket the player's own party's majority sat in
## and into the bucket the player actually chose. Cameron's call (2026-09-26):
## the majority bucket, not an explicit authored field — a tie breaks toward
## Yes, then No, then Abstain, in that fixed order, since some deterministic
## answer has to win and this project's convention is to make [DEFAULT]
## choices like this explicit rather than silently random.
##
## Influence swing (2026-09-28): a strong enough player (whichever meta
## values and booster standings Cameron lists as "trigger variables" in the
## workbook's Vote Influence Triggers tab, ALL of them at or above their own
## threshold — a hard gate, not a weighted score) can additionally swing
## OTHER parties' seats toward the player's own pick, not just the player's
## own single seat. Reuses majority_bucket() for every party, not just the
## player's: any party whose own assumed majority isn't already the picked
## bucket has some of its seats (capped by that party's own "resistance",
## data/parties.json's own vote_resistance) moved over, deterministically —
## no roll, since the point is a hard-but-reliable payoff once the gate is
## cleared. See VoteInfluence.gd for the gate check itself.
##
## Per-party scope (2026-10-02): the gate is checked separately for EACH
## party being considered, not once for the whole vote — a trigger row can
## name specific parties it applies to (VoteInfluence.gd's own
## `applies_to_parties`), so the player might be able to swing one party but
## not another even in the same vote. A row with no scope at all still
## counts everywhere, so this changes nothing for a trigger set written
## before the scoping column existed.
##
## USE
##     var engine := FloorVoteEngine.new()
##     engine.setup({"bill": bill, "player_party": "Frontier Party",
##         "meta": GameState.meta, "booster_standing": GameState.booster_standing,
##         "triggers": DataDB.vote_influence_triggers,
##         "default_threshold": int(DataDB.balance.get("vote_influence_default_threshold", 85)),
##         "resistance_by_party": {...}, "default_resistance": 70})
##     var result := engine.choose("Yes")
##     ... show result.totals, result.positions, apply result.favorability_deltas ...
##     ... result.outcome_flipped_by_influence decides whether a cutscene fires ...

const BUCKETS := ["Yes", "No", "Abstain"]

## Set by setup() when the config could not be used. Empty means it worked.
var setup_problems: Array[String] = []

var _bill: Dictionary = {}
var _positions: Array = []
var _player_party: String = ""
const MAJORITY := "Majority"
const SUPERMAJORITY := "Supermajority"

var _resolved := false
var _config: Dictionary = {}

var _meta: Dictionary = {}
var _booster_standing: Dictionary = {}
var _triggers: Array = []
var _default_threshold := 85
var _resistance_by_party: Dictionary = {}
var _default_resistance := 70

## Set once, the first time choose() resolves — cached rather than
## recomputed on a repeat call, since by then _positions already reflects
## the swing and re-deriving "what would have happened without it" from the
## post-swing state would be wrong (choose() promises the same answer every
## time it's called, per its own doc comment below).
##
## True when the gate passed for AT LEAST ONE party being considered for the
## swing (per-party scope, 2026-10-02) — a single flag covering the whole
## vote, for a caller (the cutscene, the UI) that only needs to know
## "did anything swing," not which party.
var _influence_gate_passed := false
var _outcome_flipped_by_influence := false


## config = { "bill": DataDB.get_floor_vote(level_id)'s own shape,
## "player_party": the current protagonist's own party name,
## "meta"/"booster_standing"/"triggers"/"default_threshold"/
## "resistance_by_party"/"default_resistance": the influence-swing inputs,
## all optional — omitting them just means the gate never passes, the same
## "nothing configured yet, nothing happens" bargain as the rest of the
## feature }.
func setup(config: Dictionary) -> bool:
	_config = config
	setup_problems = []
	_bill = config.get("bill", {}) as Dictionary
	_positions = (_bill.get("positions", []) as Array).duplicate(true)
	_player_party = str(config.get("player_party", ""))
	_resolved = false

	_meta = config.get("meta", {}) as Dictionary
	_booster_standing = config.get("booster_standing", {}) as Dictionary
	_triggers = config.get("triggers", []) as Array
	_default_threshold = int(config.get("default_threshold", 85))
	_resistance_by_party = config.get("resistance_by_party", {}) as Dictionary
	_default_resistance = int(config.get("default_resistance", 70))

	if _bill.is_empty():
		setup_problems.append("no bill to vote on")
	if _positions.is_empty():
		setup_problems.append("bill has no party positions")
	if not _player_party.is_empty() and not _position_for(_player_party):
		setup_problems.append("player's own party '%s' has no position on this bill" % _player_party)

	return setup_problems.is_empty()


func bill() -> Dictionary:
	return _bill


## This vote's requirement ("Majority" or "Supermajority") and the Yes votes it
## takes to pass.
func requirement() -> String:
	return requirement_of(_bill)


func supermajority_percent() -> int:
	return int(_config.get("supermajority_percent", 67))


func yes_needed_now(totals: Dictionary = {}) -> int:
	return yes_needed(totals if not totals.is_empty() else _totals(), requirement(), supermajority_percent())


func passes(totals: Dictionary) -> bool:
	return bill_passes(totals, requirement(), supermajority_percent())


## The as-baked positions, before any player choice is applied.
func positions() -> Array:
	return _positions


## True once choose() has resolved a vote. Calling choose() again after this
## is a no-op that returns the same result.
func is_finished() -> bool:
	return _resolved


## Matches on "party_name" — attached by BattleSetup (which has DataDB and
## can resolve a position's own "party_id" to parties.json's own "name"),
## never on party_id itself: this file never sees DataDB, so it cannot do
## that resolution itself, only rely on it having already happened.
func _position_for(party_name: String) -> Dictionary:
	for position: Dictionary in _positions:
		if str(position.get("party_name", "")) == party_name:
			return position
	return {}


## The optional bonus a bill pays when the player's influence flips it:
## { "reputation": n, "party_support": n }. A blank workbook cell is JSON null
## (the key is present, the value is not), and int(null) is a script error that
## used to abort the vote screen the moment a flip happened (found by the
## 2026-10-12 rubric playtest), so blank reads as 0 here.
static func influence_bonus(bill: Dictionary) -> Dictionary:
	var reputation: Variant = bill.get("influence_bonus_reputation")
	var party_support: Variant = bill.get("influence_bonus_party_support")
	return {
		"reputation": 0 if reputation == null else int(reputation),
		"party_support": 0 if party_support == null else int(party_support),
	}


## Which bucket already holds the majority of `position`'s own votes — the
## bucket the player's own seat is assumed to sit in before they vote.
## Ties break Yes > No > Abstain (this file's own header comment).
static func majority_bucket(position: Dictionary) -> String:
	var best := "Yes"
	var best_count := int(position.get("votes_yes", 0))
	for bucket: String in ["No", "Abstain"]:
		var count := int(position.get("votes_%s" % bucket.to_lower(), 0))
		if count > best_count:
			best = bucket
			best_count = count
	return best


## Yes votes a bill needs: a majority of the whole house (everyone in the
## chamber, abstainers included). 101 seats gives 51, Yezo's floor majority
## (CLAUDE.md section 4); derived from the seats so it never goes stale.
##
## `requirement` is the bill's own Vote Requirement: "Majority" (the default,
## and what a blank cell means) or "Supermajority", which needs `percent` of
## the whole house (Balance: supermajority_percent), rounded up (2026-10-15).
static func yes_needed(totals: Dictionary, requirement: String = MAJORITY,
		percent: int = 67) -> int:
	var house := int(totals.get("Yes", 0)) + int(totals.get("No", 0)) + int(totals.get("Abstain", 0))
	if requirement == SUPERMAJORITY:
		return ceili(house * percent / 100.0)
	return house / 2 + 1


## True when Yes reaches what the bill needs (a majority of the whole house
## unless the bill is flagged Supermajority).
static func bill_passes(totals: Dictionary, requirement: String = MAJORITY,
		percent: int = 67) -> bool:
	return int(totals.get("Yes", 0)) >= yes_needed(totals, requirement, percent)


## A bill's own requirement from its Vote Requirement cell: blank or anything
## but "Supermajority" is an ordinary majority.
static func requirement_of(bill: Dictionary) -> String:
	var cell: Variant = bill.get("vote_requirement")
	if cell != null and str(cell).strip_edges().to_lower() == "supermajority":
		return SUPERMAJORITY
	return MAJORITY


## Resolves the vote: `choice` is "Yes", "No", or "Abstain" (case-insensitive).
## Returns:
##   { "positions": Array (this bill's positions, seats moved if the player
##       voted against their own party's assumed majority and/or the
##       influence swing fired),
##     "totals": { "Yes": n, "No": n, "Abstain": n },
##     "passed": bool (Yes reaches a majority of the whole house — 51 of 101;
##       see bill_passes(). Abstentions count toward the house, so they make
##       the bar higher, never lower),
##     "favorability_deltas": { party_name: delta, ... },
##     "influence_gate_passed": bool,
##     "outcome_flipped_by_influence": bool (the bill's own pass/fail
##       differs from what it would have been without the swing — only
##       ever true when the gate passed, since nothing moves otherwise) }
## Safe to call more than once — only the first call actually resolves
## anything; later calls return the same result again.
func choose(choice: String) -> Dictionary:
	var picked := _normalise(choice)
	if not _resolved:
		if not _player_party.is_empty():
			_reallocate_player_vote(picked)
		var baseline_totals := _totals()
		var baseline_passed: bool = passes(baseline_totals)

		_apply_won_over(picked)
		_influence_gate_passed = _apply_influence_swing(picked)
		_apply_worked_against(picked)

		var final_totals := _totals()
		_outcome_flipped_by_influence = passes(final_totals) != baseline_passed
		_resolved = true

	var totals := _totals()
	return {
		"positions": _positions,
		"totals": totals,
		"passed": passes(totals),
		"requirement": requirement(),
		"yes_needed": yes_needed_now(totals),
		"favorability_deltas": _favorability_deltas(),
		"influence_gate_passed": _influence_gate_passed,
		"outcome_flipped_by_influence": _outcome_flipped_by_influence,
	}


## What voting `choice` would give, without voting: a throwaway engine is
## built from the same config and asked, so this engine is left untouched.
## { totals, passed, flipped_by_influence } (2026-10-15).
func preview(choice: String) -> Dictionary:
	var trial := FloorVoteEngine.new()
	if not trial.setup(_config):
		return {}
	var result := trial.choose(choice)
	return {
		"totals": result.get("totals", {}),
		"passed": result.get("passed", false),
		"yes_needed": result.get("yes_needed", 0),
		"flipped_by_influence": result.get("outcome_flipped_by_influence", false),
	}


## Where the player stands against the influence gate (see VoteInfluence.status()).
func influence_status() -> Dictionary:
	var ids: Array = []
	for position: Dictionary in _positions:
		ids.append(str(position.get("party_id", "")))
	return VoteInfluence.status(_triggers, _meta, _booster_standing, _default_threshold, ids)


## Members the player won over (BillAssist "won_over"): each is one seat that
## goes to `picked`, taken from the party's larger bucket of the two it is not
## already in, with no gate and no Vote Resistance. A party with nothing left
## outside `picked` gives nothing.
func _apply_won_over(picked: String) -> void:
	var won: Variant = (_config.get("assist", {}) as Dictionary).get("won_over", {})
	if not (won is Dictionary):
		return
	for index in _positions.size():
		var position: Dictionary = _positions[index]
		var seats := int((won as Dictionary).get(str(position.get("party_id", "")), 0))
		if seats <= 0:
			continue
		# One seat at a time, each from whichever bucket outside the pick is
		# larger at that moment, so a party's seats are all winnable.
		for _seat in range(seats):
			var best := ""
			var best_count := 0
			for bucket: String in ["Abstain", "No", "Yes"]:
				if bucket == picked:
					continue
				var count := int(position.get("votes_%s" % bucket.to_lower(), 0))
				if count > best_count:
					best = bucket
					best_count = count
			if best.is_empty():
				break
			position["votes_%s" % best.to_lower()] = best_count - 1
			position["votes_%s" % picked.to_lower()] = int(position.get("votes_%s" % picked.to_lower(), 0)) + 1
		_positions[index] = position


## Lobbyists working against the player (BillAssist "worked_against"): seats in
## the named party leave `picked` for its opposite (Yes and No swap; an
## Abstain pick loses them to No). Applied after the influence swing, so it
## cannot be won back.
func _apply_worked_against(picked: String) -> void:
	var against: Variant = (_config.get("assist", {}) as Dictionary).get("worked_against", {})
	if not (against is Dictionary):
		return
	var opposite := "No" if picked != "No" else "Yes"
	for index in _positions.size():
		var position: Dictionary = _positions[index]
		var seats := int((against as Dictionary).get(str(position.get("party_id", "")), 0))
		if seats <= 0:
			continue
		var from_key := "votes_%s" % picked.to_lower()
		var moved := mini(seats, int(position.get(from_key, 0)))
		position[from_key] = int(position.get(from_key, 0)) - moved
		position["votes_%s" % opposite.to_lower()] = int(position.get("votes_%s" % opposite.to_lower(), 0)) + moved
		_positions[index] = position


func _normalise(choice: String) -> String:
	var upper := choice.strip_edges().capitalize()
	return upper if BUCKETS.has(upper) else "Abstain"


func _reallocate_player_vote(picked: String) -> void:
	var position := _position_for(_player_party)
	if position.is_empty():
		return
	var assumed := majority_bucket(position)
	if assumed == picked:
		return   # the player voted with their own party's assumed majority

	var index := _positions.find(position)
	var moved: Dictionary = _positions[index]
	var from_key := "votes_%s" % assumed.to_lower()
	var to_key := "votes_%s" % picked.to_lower()
	moved[from_key] = maxi(int(moved.get(from_key, 0)) - 1, 0)
	moved[to_key] = int(moved.get(to_key, 0)) + 1
	_positions[index] = moved


## The influence swing: every party (the player's own included, evaluated
## fresh after its own single-seat move above) whose own assumed majority
## isn't already `picked` gives up some of its seats, deterministically —
## no roll. How many is capped by that party's own "resistance" (data/
## parties.json's own vote_resistance, or the flat default): resistance is
## the % of a party's seats that are swing-proof, so a 70% resistance party
## only ever gives up 30% of its seats, at most, and only from whichever
## bucket its own majority already sat in.
##
## The gate itself (2026-10-02) is checked PER PARTY, passing that party's
## own party_id to VoteInfluence.gate_passed() — a trigger row scoped to
## specific parties only ever counts toward those parties' own checks, so
## the same vote can swing one party and not another. Returns true if the
## gate passed for at least one party (whether or not that party actually
## had any seats to give — the flag is "could this have swung someone,"
## not "did seats move").
func _apply_influence_swing(picked: String) -> bool:
	var any_gate_passed := false
	for index in _positions.size():
		var position: Dictionary = _positions[index]
		var assumed := majority_bucket(position)
		if assumed == picked:
			continue

		var party_id := str(position.get("party_id", ""))
		if not VoteInfluence.gate_passed(
				_triggers, _meta, _booster_standing, _default_threshold, party_id):
			continue
		any_gate_passed = true

		var party_name := str(position.get("party_name", ""))
		var total_seats := (int(position.get("votes_yes", 0))
			+ int(position.get("votes_no", 0)) + int(position.get("votes_abstain", 0)))
		var resistance := int(_resistance_by_party.get(party_name, _default_resistance))
		var swingable := floori(total_seats * (1.0 - resistance / 100.0))

		var from_key := "votes_%s" % assumed.to_lower()
		var to_key := "votes_%s" % picked.to_lower()
		var moved := mini(swingable, int(position.get(from_key, 0)))
		if moved <= 0:
			continue
		position[from_key] = int(position[from_key]) - moved
		position[to_key] = int(position.get(to_key, 0)) + moved
		_positions[index] = position
	return any_gate_passed


func _totals() -> Dictionary:
	var totals := {"Yes": 0, "No": 0, "Abstain": 0}
	for position: Dictionary in _positions:
		totals["Yes"] += int(position.get("votes_yes", 0))
		totals["No"] += int(position.get("votes_no", 0))
		totals["Abstain"] += int(position.get("votes_abstain", 0))
	return totals


## Each party earns its own disposition's delta off the bill — Supportive/
## Opposed/Neutral, whichever this party was, unconditionally: a party's
## own stance is baked in at setup, not decided by whether the vote passed.
func _favorability_deltas() -> Dictionary:
	var deltas := {}
	var by_disposition := {
		"Supportive": int(_bill.get("favorability_delta_supportive", 0)),
		"Opposed": int(_bill.get("favorability_delta_opposed", 0)),
		"Neutral": int(_bill.get("favorability_delta_neutral", 0)),
	}
	for position: Dictionary in _positions:
		var party_name := str(position.get("party_name", ""))
		var disposition := str(position.get("disposition", ""))
		if by_disposition.has(disposition) and not party_name.is_empty():
			# A party moves more on a bill that sits on its own priorities
			# (PartySalience); BattleSetup stamps the factor on the position.
			deltas[party_name] = PartySalience.scaled(by_disposition[disposition],
				float(position.get("favorability_factor", 1.0)))
	return deltas
