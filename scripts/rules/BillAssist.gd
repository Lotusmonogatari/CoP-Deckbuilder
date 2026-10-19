class_name BillAssist
extends RefCounted
## Help (and hindrance) a patron bill's special stages put on one vote
## (2026-10-19, Cameron). The record is plain data so it can be saved:
##   { "won_over": {party_id: seats}, "worked_against": {party_id: seats} }
## `won_over` seats are guaranteed to move to the player's pick for this one
## vote, ignoring the influence gate and Vote Resistance (a member who was
## won over is one seat). `worked_against` seats are taken away from the
## player's pick by lobbyists. FloorVoteEngine applies both; nothing here
## touches a vote itself.
##
## Pure and UI-free (CLAUDE.md section 12).

static func empty() -> Dictionary:
	return {"won_over": {}, "worked_against": {}}


static func add(assist: Dictionary, kind: String, party_id: String, seats: int) -> void:
	if seats <= 0 or party_id.is_empty():
		return
	if not assist.has(kind):
		assist[kind] = {}
	var by_party: Dictionary = assist[kind]
	by_party[party_id] = int(by_party.get(party_id, 0)) + seats


static func total(assist: Dictionary, kind: String) -> int:
	var sum := 0
	var by_party: Variant = assist.get(kind, {})
	if by_party is Dictionary:
		for party_id: Variant in by_party:
			sum += int(by_party[party_id])
	return sum


static func is_empty(assist: Dictionary) -> bool:
	return total(assist, "won_over") == 0 and total(assist, "worked_against") == 0
