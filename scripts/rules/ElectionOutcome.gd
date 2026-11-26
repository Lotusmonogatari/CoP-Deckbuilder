class_name ElectionOutcome
extends RefCounted
## What an Election Day does for a player the Candidate Selection Committee selected (P20 phase D, 2026-11-26, Cameron). A STUB: it only says
## the player is seated and returns the record the run keeps. Pure and UI-free (CLAUDE.md section 12).
##
## The direction Cameron has decided, not yet built and with no numbers yet:
##   - A player selected for a Single-Member District can LOSE that seat when the campaign strength is low: that is a game over.
##   - The safety net (the committee's `smd_safety_net` outcome) falls back to a place on the Proportional List, so a lost district seat
##     still seats the player.
##   - The results will feed the party's and the player's own success through thresholds, the way bill influence does.
## Until those thresholds exist, every selected player is seated.


## The Election Day record for a selected player: {cycle_id, outcome (the selection outcome), strength, seated}.
static func resolve(cycle_id: String, selection: Dictionary, strength: float) -> Dictionary:
	return {"cycle_id": cycle_id, "outcome": str(selection.get("outcome", "")), "strength": strength, "seated": Selection.is_selected(str(selection.get("outcome", "")))}
