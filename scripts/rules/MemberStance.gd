class_name MemberStance
extends RefCounted
## Which side of a bill an opponent argues in that bill's rooms (2026-11-04,
## Cameron), so nobody professes the opposite of their party's position.
##
## Every bill line on the Opponent Cues tab carries a Side (For, Against, Ally,
## or blank = Neutral). An opponent may always say Neutral lines. Facing a
## player on the other side of the bill (or with no lean), they add their
## argued side's lines; facing a player on their own side, they add Ally lines
## instead (sides()). Their argued side is:
##   - a party leader: their party's own position (Supportive = For,
##     Opposed = Against, Neutral = none);
##   - a party member: the same, unless the party is Neutral on the bill or at
##     least `split_percent` of its seats abstain. Then each member takes a
##     personal side, rolled from the party's own Aye / Nay / Abstain split for
##     this bill and fixed per (member, bill), so a person never changes their
##     mind between turns. An abstainer only asks neutral questions;
##   - someone with no party position (a journalist, a lobbyist): their own
##     organization's side on the bill if it has one, else none.
## Pure and UI-free (CLAUDE.md §12): callers hand in the bill, the parties and
## the bill's stakeholder sides (BillStance.sides()).

const FOR := "For"
const AGAINST := "Against"
const NEUTRAL := "Neutral"
## A demanding ally's line: pushes a player who is on the speaker's own side.
const ALLY := "Ally"


## The sides this opponent may argue on this bill: always NEUTRAL, plus FOR or
## AGAINST when they hold one.
##
## `player_side` is the player's own lean (FOR, AGAINST, or "" with none) —
## the player's stance matters because For and Against lines address a player
## on the OTHER side ("You would ask us to..."), 2026-11-04, Cameron:
##   - opponent and player on opposite sides (or no player lean): NEUTRAL plus
##     the opponent's argued side, so a supporter argues for the bill against a
##     player who opposes it, and the reverse;
##   - opponent and player on the same side: NEUTRAL plus ALLY lines, the
##     demanding ally who pushes the player to make the case properly.
static func sides(opponent: Dictionary, bill: Dictionary, parties: Array,
		stakeholder_sides: Dictionary, split_percent: int, player_side: String = "") -> Array[String]:
	var out: Array[String] = [NEUTRAL]
	var argued := argued_side(opponent, bill, parties, stakeholder_sides, split_percent)
	if argued.is_empty():
		return out
	out.append(ALLY if argued == player_side else argued)
	return out


## The player's own side from their lean on the stance screen ("Support" /
## "Oppose"), or "" when they picked none.
static func player_side_for(lean: String) -> String:
	match lean:
		"Support": return FOR
		"Oppose": return AGAINST
	return ""


## FOR, AGAINST or "" (no argued side), by the rules above.
static func argued_side(opponent: Dictionary, bill: Dictionary, parties: Array,
		stakeholder_sides: Dictionary, split_percent: int) -> String:
	var party := _party_of(opponent, parties)
	var position := _position_for(bill, str(party.get("party_id", "")))
	if position.is_empty():
		var org := str(opponent.get("affiliation", ""))
		if (stakeholder_sides.get("supporters", []) as Array).has(org):
			return FOR
		if (stakeholder_sides.get("opponents", []) as Array).has(org):
			return AGAINST
		return ""

	var disposition := str(position.get("disposition", ""))
	var leader := str(party.get("leader_opp_id", "")) == str(opponent.get("opp_id", ""))
	if not leader and _splits(position, disposition, split_percent):
		return _rolled_side(opponent, bill, position)
	match disposition:
		"Supportive": return FOR
		"Opposed": return AGAINST
	return ""


## The leader's own Floor Vote line for this bill (Floor Vote Party
## Positions), or "" when the opponent leads no party on it.
static func leader_line(opponent: Dictionary, bill: Dictionary, parties: Array) -> String:
	var party := _party_of(opponent, parties)
	if party.is_empty() or str(party.get("leader_opp_id", "")) != str(opponent.get("opp_id", "")):
		return ""
	var position := _position_for(bill, str(party.get("party_id", "")))
	var raw: Variant = position.get("cue_text")
	return "" if raw == null else str(raw).strip_edges()


## A party splits when it takes no side, or when enough of it abstains.
static func _splits(position: Dictionary, disposition: String, split_percent: int) -> bool:
	if disposition == "Neutral":
		return true
	var total := _votes(position, "votes_yes") + _votes(position, "votes_no") + _votes(position, "votes_abstain")
	if total <= 0:
		return false
	return _votes(position, "votes_abstain") * 100 >= split_percent * total


## A member's own side, weighted by the party's Aye / Nay / Abstain split and
## fixed for this member and this bill.
static func _rolled_side(opponent: Dictionary, bill: Dictionary, position: Dictionary) -> String:
	var yes := _votes(position, "votes_yes")
	var no := _votes(position, "votes_no")
	var total := yes + no + _votes(position, "votes_abstain")
	if total <= 0:
		return ""
	var key := "%s|%s" % [opponent.get("opp_id", ""), bill.get("bill_id", "")]
	var roll := absi(key.hash()) % total
	if roll < yes:
		return FOR
	if roll < yes + no:
		return AGAINST
	return ""


static func _votes(position: Dictionary, field: String) -> int:
	return SafeNum.to_int(position.get(field))


static func _party_of(opponent: Dictionary, parties: Array) -> Dictionary:
	var name := str(opponent.get("party") if opponent.get("party") != null else "")
	if name.is_empty():
		return {}
	for party: Dictionary in parties:
		if str(party.get("name", "")) == name:
			return party
	return {}


static func _position_for(bill: Dictionary, party_id: String) -> Dictionary:
	if party_id.is_empty():
		return {}
	for position: Variant in bill.get("positions", []):
		if position is Dictionary and str((position as Dictionary).get("party_id", "")) == party_id:
			return position
	return {}
