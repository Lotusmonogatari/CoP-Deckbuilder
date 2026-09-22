class_name CommitteeModel
extends RefCounted
## A committee stage, where you persuade people one at a time.
##
## Instead of one support bar there is a tile per member, each with a lean
## from 0 to 100. Push a member to 66 and their vote locks For; let them
## slide to 33 and it locks Against. Locked votes don't move again.
##
## You win by locking a majority For. You lose if a majority stops being
## possible — once enough members have locked Against, the arithmetic is over
## and there's no point playing out the remaining turns.
##
## The committee chair is the module's opponent. They are not a voting tile:
## they run the meeting, and their intent pushes a member away from you.

## A member reaching this locks their vote For.
const LOCK_FOR := 66
## A member falling to this locks their vote Against.
const LOCK_AGAINST := 33
## Where an undecided member starts.
const UNDECIDED_LEAN := 50

## Member records: { name, party, lean, locked }
## `locked` is "", "For" or "Against".
var members: Array[Dictionary] = []


## Builds the committee from a roster of opponents.json rows.
##
## 2026-09-22 workbook: the old Committee tab is gone, and with it the
## "starting_stance" column that told a member's opening lean. A committee's
## roster is now built by BattleSetup from opponents.json — every opponent
## whose own "stages" list names the committee's STxx — and those rows carry
## no stance of any kind, so `row.get("starting_stance", "Undecided")` below
## always falls through to "Undecided" today. That is CLAUDE.md §7.5's own
## [DEFAULT] for a member with no data ("Undecided members start at 50"), so
## nothing is being invented here — every member opens undecided until
## Cameron's workbook has something to say about who starts where. The
## "For"/"Against" branches are left in place rather than deleted: they cost
## nothing to keep, and the day starting stances come back into the data
## (whatever shape that takes) this function does not need touching again.
static func create(member_rows: Array) -> CommitteeModel:
	var committee := CommitteeModel.new()
	for row: Dictionary in member_rows:
		var stance := str(row.get("starting_stance", "Undecided"))
		var member := {
			# opponents.json rows use "name"; "member" is kept as a fallback
			# only so a stray hand-written fixture in the old shape still
			# reads sensibly rather than showing every member as "Visitor A".
			"name": str(row.get("name", row.get("member", "Visitor A"))),
			"party": str(row.get("party", "")),
			"lean": UNDECIDED_LEAN,
			"locked": "",
		}
		match stance:
			"Against":
				member["lean"] = 0
				member["locked"] = "Against"
			"For":
				member["lean"] = 100
				member["locked"] = "For"
			_:
				member["lean"] = UNDECIDED_LEAN
		committee.members.append(member)
	return committee


func size() -> int:
	return members.size()


## How many For votes it takes to carry the committee.
func majority_needed() -> int:
	return int(floor(float(members.size()) / 2.0)) + 1


func count_locked(stance: String) -> int:
	var total := 0
	for member: Dictionary in members:
		if member["locked"] == stance:
			total += 1
	return total


func locked_for() -> int:
	return count_locked("For")


func locked_against() -> int:
	return count_locked("Against")


func undecided_count() -> int:
	var total := 0
	for member: Dictionary in members:
		if str(member["locked"]).is_empty():
			total += 1
	return total


# ---------------------------------------------------------------------------
# Persuading
# ---------------------------------------------------------------------------

## Moves one member's lean. Positive persuades them towards For, negative
## pushes them away. A locked member doesn't move.
##
## Returns what happened, so the UI can animate it:
##   { moved, lean, locked, newly_locked }
func persuade(index: int, amount: int) -> Dictionary:
	if index < 0 or index >= members.size():
		push_warning("CommitteeModel: there is no member at position %d." % index)
		return {"moved": 0, "lean": 0, "locked": "", "newly_locked": false}

	var member: Dictionary = members[index]
	if not str(member["locked"]).is_empty():
		return {"moved": 0, "lean": member["lean"], "locked": member["locked"], "newly_locked": false}

	var before := int(member["lean"])
	member["lean"] = clampi(before + amount, 0, 100)

	var newly_locked := false
	if int(member["lean"]) >= LOCK_FOR:
		member["locked"] = "For"
		newly_locked = true
	elif int(member["lean"]) <= LOCK_AGAINST:
		member["locked"] = "Against"
		newly_locked = true

	return {
		"moved": int(member["lean"]) - before,
		"lean": int(member["lean"]),
		"locked": member["locked"],
		"newly_locked": newly_locked,
	}


## The chair leaning on a member: the same thing, pushing the other way.
func chair_pressure(index: int, amount: int) -> Dictionary:
	return persuade(index, -absi(amount))


## Which member the chair goes after: the one closest to locking For, since
## that is the vote most worth stopping. Returns -1 if everyone is locked.
func most_persuaded_unlocked() -> int:
	var best := -1
	var best_lean := -1
	for index in members.size():
		var member: Dictionary = members[index]
		if not str(member["locked"]).is_empty():
			continue
		if int(member["lean"]) > best_lean:
			best_lean = int(member["lean"])
			best = index
	return best


# ---------------------------------------------------------------------------
# Winning and losing
# ---------------------------------------------------------------------------

func player_has_won() -> bool:
	return locked_for() >= majority_needed()


## True while enough votes are still gettable to reach a majority.
##
## Every member who is either already For or not yet locked is a vote the
## player could still have. When that total drops below the majority, the
## stage is lost however many turns are left.
func majority_still_reachable() -> bool:
	return locked_for() + undecided_count() >= majority_needed()


func to_dictionary() -> Dictionary:
	return {
		"members": members.duplicate(true),
		"majority_needed": majority_needed(),
		"locked_for": locked_for(),
		"locked_against": locked_against(),
	}
