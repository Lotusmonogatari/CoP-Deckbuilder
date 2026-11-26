class_name PartyAlignment
extends RefCounted
## Party alignment (P20, 2026-11-26, Cameron): a score from 0 to 100 for how closely the player's votes match their own party. It is one of the
## three parts of the Candidate Selection Committee's score.
##
## For each bill in the statute book where the player took a side (StatuteBook.player_took_a_side: an Aye or a Nay, not an absence or an
## abstention) the rule finds the player's own party's position on the bill (its `positions` row: Supportive, Opposed or Neutral, with a
## salience). A Neutral party says nothing and the bill is skipped. The weight of a bill is the size of the salience (a bill the party feels
## strongly about counts more). The player AGREES when they voted Aye on a Supportive bill or Nay on an Opposed one.
##
##   alignment = 50 + 50 x (agreed weight - disagreed weight) / total weight, rounded to a whole number; 50 when there is no such bill.
##
## Composed (custom) bills carry the same `positions` list (ComposedBill builds it with BillPositions.positions), so floor-vote bills and
## composed bills are read the same way. Pure and UI-free (CLAUDE.md section 12).

const NEUTRAL := "Neutral"
const SUPPORTIVE := "Supportive"
const OPPOSED := "Opposed"


## `book` is the statute book, `bills` {bill_id: the bill's Dictionary with its `positions`}, `own_party` the player's party ID.
static func score(book: Array, bills: Dictionary, own_party: String) -> int:
	var agreed := 0.0
	var disagreed := 0.0
	for law: Variant in book:
		var entry := law as Dictionary
		var bill_id := str(entry.get("bill_id", ""))
		if not StatuteBook.player_took_a_side(book, bill_id):
			continue
		var position := _position_of(bills.get(bill_id, {}) as Dictionary, own_party)
		var disposition := str(position.get("disposition", NEUTRAL))
		if position.is_empty() or disposition == NEUTRAL:
			continue
		var weight := absf(float(position.get("salience", 0)))
		var vote := str(entry.get("player_vote", ""))
		var with_party := (disposition == SUPPORTIVE and vote == "Yes") or (disposition == OPPOSED and vote == "No")
		if with_party:
			agreed += weight
		else:
			disagreed += weight
	var total := agreed + disagreed
	if total <= 0.0:
		return 50
	return roundi(50.0 + 50.0 * (agreed - disagreed) / total)


static func _position_of(bill: Dictionary, party_id: String) -> Dictionary:
	for position: Variant in bill.get("positions", []):
		if str((position as Dictionary).get("party_id", "")) == party_id:
			return position as Dictionary
	return {}
