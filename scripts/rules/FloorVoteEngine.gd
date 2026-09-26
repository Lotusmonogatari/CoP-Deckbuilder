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
## USE
##     var engine := FloorVoteEngine.new()
##     engine.setup({"bill": bill, "player_party": "Frontier Party"})
##     var result := engine.choose("Yes")
##     ... show result.totals, result.positions, apply result.favorability_deltas ...

const BUCKETS := ["Yes", "No", "Abstain"]

## Set by setup() when the config could not be used. Empty means it worked.
var setup_problems: Array[String] = []

var _bill: Dictionary = {}
var _positions: Array = []
var _player_party: String = ""
var _resolved := false


## config = { "bill": DataDB.get_floor_vote(level_id)'s own shape,
## "player_party": the current protagonist's own party name }.
func setup(config: Dictionary) -> bool:
	setup_problems = []
	_bill = config.get("bill", {}) as Dictionary
	_positions = (_bill.get("positions", []) as Array).duplicate(true)
	_player_party = str(config.get("player_party", ""))
	_resolved = false

	if _bill.is_empty():
		setup_problems.append("no bill to vote on")
	if _positions.is_empty():
		setup_problems.append("bill has no party positions")
	if not _player_party.is_empty() and not _position_for(_player_party):
		setup_problems.append("player's own party '%s' has no position on this bill" % _player_party)

	return setup_problems.is_empty()


func bill() -> Dictionary:
	return _bill


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


## Resolves the vote: `choice` is "Yes", "No", or "Abstain" (case-insensitive).
## Returns:
##   { "positions": Array (this bill's positions, the player's own party's
##       bucket totals adjusted if they voted against its assumed majority),
##     "totals": { "Yes": n, "No": n, "Abstain": n },
##     "passed": bool (Yes strictly outnumbers No — an Abstain counts toward
##       the house but not toward either side),
##     "favorability_deltas": { party_name: delta, ... } }
## Safe to call more than once — only the first call actually resolves
## anything; later calls return the same result again.
func choose(choice: String) -> Dictionary:
	var picked := _normalise(choice)
	if not _resolved:
		if not _player_party.is_empty():
			_reallocate_player_vote(picked)
		_resolved = true

	var totals := _totals()
	return {
		"positions": _positions,
		"totals": totals,
		"passed": totals["Yes"] > totals["No"],
		"favorability_deltas": _favorability_deltas(),
	}


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
			deltas[party_name] = by_disposition[disposition]
	return deltas
