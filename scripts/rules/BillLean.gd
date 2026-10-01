class_name BillLean
extends RefCounted
## The Level Intro screen's bill-lean choice (2026-10-01): on a level that
## names a Floor Vote bill, the player picks "Lean Support" or "Lean
## Oppose" on the bill's topic. That choice is compared against the
## player's own party's Disposition toward the bill (Floor Vote Party
## Positions' own "Disposition" column — Supportive/Opposed/Neutral, the
## same field Floor Vote's own screen already shows per party) to decide a
## Party support delta: agreeing with the party's own disposition is worth
## +balance.json's "lean_party_support_delta", disagreeing is worth the
## same amount negative. A Neutral disposition has no stance to agree or
## disagree with, so it never rewards or penalizes either lean.
##
## Pure and UI-free (CLAUDE.md §12): the caller resolves the player's own
## party's position dict and passes it straight in.

const SUPPORT := "Support"
const OPPOSE := "Oppose"


## `own_position` is the player's own party's row from a bill's
## "positions" list (data/floor_votes.json), which carries a "disposition"
## field. `lean` is BillLean.SUPPORT or BillLean.OPPOSE. `magnitude` is
## balance.json's "lean_party_support_delta", always applied as a positive
## number here — the sign is this function's to decide.
static func party_support_delta(own_position: Dictionary, lean: String, magnitude: int) -> int:
	var disposition := str(own_position.get("disposition", ""))
	var party_lean := ""
	if disposition == "Supportive":
		party_lean = SUPPORT
	elif disposition == "Opposed":
		party_lean = OPPOSE
	if party_lean.is_empty():
		return 0
	return magnitude if party_lean == lean else -magnitude
