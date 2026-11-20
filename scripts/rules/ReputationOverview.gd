class_name ReputationOverview
extends RefCounted
## What the Overview tab of Reputation and Results picks out (P13, 2026-11-20). Pure, like everything in
## scripts/rules/: it is handed plain data and answers which organizations moved most and which law is latest.

## The organizations whose standing moved most last level: ids ordered by the size of the change (up or down),
## largest first, only those that moved at all, at most `count`. A tie keeps the order of `order` (the data order).
static func biggest_moves(changes: Dictionary, order: Array, count: int = 3) -> Array:
	var moved: Array = []
	for id: Variant in order:
		if int(changes.get(str(id), 0)) != 0:
			moved.append(str(id))
	# A stable pick: the data order breaks a tie, so the same run always shows the same three.
	var ranked: Array = []
	for id: String in moved:
		var at := 0
		while at < ranked.size() and absi(int(changes[ranked[at]])) >= absi(int(changes[id])):
			at += 1
		ranked.insert(at, id)
	return ranked.slice(0, maxi(0, count))


## The most recent law in the statute book (the last entry), or {} when no bill has come to a vote.
static func latest_law(statute_book: Array) -> Dictionary:
	return statute_book[statute_book.size() - 1] if not statute_book.is_empty() else {}
