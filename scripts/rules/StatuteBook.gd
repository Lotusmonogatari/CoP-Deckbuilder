class_name StatuteBook
extends RefCounted
## The statute book (2026-10-12, Cameron, Phase 2 of the legislation plan):
## a permanent record of every bill that came to a Floor Vote, and which
## Law Effects rows apply because of how it went.
##
## Pure and UI-free (CLAUDE.md §12): GameState keeps the book and applies
## the effects; everything here takes plain data and returns plain data.

const PASSED := "passed"
const FAILED := "failed"

## A Law Effects row's Timing. Blank reads as ONCE.
const ONCE := "once"
const EACH_LEVEL := "each level"

## The four meta-variables a Law Effects row can move, by their own column
## key in data/law_effects.json. The names are the Sanban lookup keys (§6).
const META_COLUMNS := {
	"constituency_support": "Constituency support",
	"reputation": "Reputation",
	"funds": "Funds",
	"party_support": "Party support",
}


## One entry for the book, from a bill and FloorVoteEngine.choose()'s own
## result. `enacted_at` is how many levels had been completed when the vote
## happened (GameState.levels_completed_count), so an "each level" effect
## can start counting from the NEXT level rather than the one that passed it.
static func entry(bill: Dictionary, result: Dictionary, choice: String,
		level_id: String, enacted_at: int) -> Dictionary:
	var totals: Dictionary = result.get("totals", {})
	return {
		"bill_id": str(bill.get("bill_id", "")),
		"passed": bool(result.get("passed", false)),
		"yes": int(totals.get("Yes", 0)),
		"no": int(totals.get("No", 0)),
		"abstain": int(totals.get("Abstain", 0)),
		"player_vote": choice.strip_edges().capitalize(),
		"flipped_by_influence": bool(result.get("outcome_flipped_by_influence", false)),
		"requirement": str(result.get("requirement", "Majority")),
		"yes_needed": int(result.get("yes_needed", 0)),
		"level_id": level_id,
		"enacted_at": enacted_at,
	}


## bill_id -> PASSED / FAILED, for every bill in the book. What Office
## Notices and the Ticker's "law" condition reads.
static func status_map(book: Array) -> Dictionary:
	var statuses := {}
	for law: Dictionary in book:
		statuses[str(law.get("bill_id", ""))] = PASSED if bool(law.get("passed", false)) else FAILED
	return statuses


## Whether a bill is already in the book (a bill is only ever voted once).
static func has_bill(book: Array, bill_id: String) -> bool:
	for law: Dictionary in book:
		if str(law.get("bill_id", "")) == bill_id:
			return true
	return false


## The Law Effects rows for this bill and outcome, with this timing.
static func effects_for(law_effects: Array, bill_id: String, passed: bool,
		timing: String) -> Array:
	var wanted_outcome := PASSED if passed else FAILED
	var found: Array = []
	for row: Dictionary in law_effects:
		if str(row.get("bill_id", "")) != bill_id:
			continue
		if _word(row.get("outcome")) != wanted_outcome:
			continue
		if timing_of(row) != timing:
			continue
		found.append(row)
	return found


## The Law Effects rows that apply at the end of a level, for every law in
## the book enacted before that level began (`completed_now` is the level
## count after this one has been counted).
static func ongoing_effects(book: Array, law_effects: Array, completed_now: int) -> Array:
	var found: Array = []
	for law: Dictionary in book:
		if completed_now <= int(law.get("enacted_at", 0)) + 1:
			continue   # the level that passed it does not also pay it out
		found.append_array(effects_for(law_effects, str(law.get("bill_id", "")),
			bool(law.get("passed", false)), EACH_LEVEL))
	return found


## A row's Timing, normalised: "Each level" or blank (= once).
static func timing_of(row: Dictionary) -> String:
	return EACH_LEVEL if _word(row.get("timing")) == EACH_LEVEL else ONCE


## The meta changes one row carries: {Sanban name: delta}, zeros left out.
static func meta_deltas(row: Dictionary) -> Dictionary:
	var deltas := {}
	for column: String in META_COLUMNS:
		var raw: Variant = row.get(column)
		if raw == null:
			continue
		var amount := int(raw)
		if amount != 0:
			deltas[META_COLUMNS[column]] = amount
	return deltas


## A row's XP change (blank = 0).
static func xp_delta(row: Dictionary) -> int:
	var raw: Variant = row.get("xp")
	return 0 if raw == null else int(raw)


## How a party-tier organisation (Party Headquarters, Party Faction: the
## Boosters tab's tier "Party") reacts to a law, from where the PLAYER'S OWN
## party stood on the bill (2026-10-13, Cameron): it follows the party's lean,
## so the same bill pleases one protagonist's headquarters and annoys
## another's. `disposition` is the bill's Party Positions disposition for the
## player's party (Supportive / Opposed / Neutral). A Neutral party has no
## stance, so nothing moves. Passing a bill the party backs (or failing one
## it opposed) pleases; the reverse annoys. A failed bill moves it by the
## smaller `fail_delta`, the same 3-to-1 shape Law Effects rows use.
static func party_tier_delta(disposition: String, passed: bool,
		pass_delta: int, fail_delta: int) -> int:
	var word := _word(disposition)
	if word != "supportive" and word != "opposed":
		return 0
	var backed := word == "supportive"
	var size := pass_delta if passed else fail_delta
	return size if backed == passed else -size


## A cell read past the <null> trap, lower-cased and trimmed.
static func _word(value: Variant) -> String:
	return "" if value == null else str(value).strip_edges().to_lower()
