class_name ResignRules
extends RefCounted
## When the player may resign (2026-11-11, Cameron). All three at once:
## Reputation, Party support and Constituency support each below their own
## line. The lines are Balance rows ("Resign: ..."), not numbers here. Pure and
## UI-free (CLAUDE.md section 12).


static func available(meta: Dictionary, balance: Dictionary) -> bool:
	return (int(meta.get("Reputation", 0)) < int(balance.get("resign_reputation_below", 10))
		and int(meta.get("Party support", 0)) < int(balance.get("resign_party_support_below", 20))
		and int(meta.get("Constituency support", 0)) < int(balance.get("resign_constituency_support_below", 20)))
