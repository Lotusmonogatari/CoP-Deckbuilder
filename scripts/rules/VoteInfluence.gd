class_name VoteInfluence
extends RefCounted
## The Floor Vote influence swing's own "gate" (2026-09-28): whether the
## player is currently strong enough to swing other parties' seats at all.
##
## data/vote_influence_triggers.json is a flat list of rows Cameron edits
## straight in the workbook's Vote Influence Triggers tab: which meta value
## or booster standing counts, whether it's switched on right now, and the
## bar it has to clear. EVERY enabled row must clear its own threshold — a
## hard AND-gate, not a weighted score, so it stays legible ("you need all
## of these, not a good-enough average") and Cameron can add or remove which
## variables count just by flipping a row's own Enabled column, no code
## touched. Zero enabled rows means the gate never passes — a dormant
## feature until at least one row is turned on, the same "nothing written
## yet, nothing happens" bargain every other optional table here keeps.
##
## Pure and UI-free (CLAUDE.md §12): everything it needs is passed in, no
## autoload access, so it is tested headless like every other rules file.


## `triggers` = data/vote_influence_triggers.json's own rows, each
## { variable, enabled, threshold }. `variable` names either a GameState.meta
## key ("Reputation", "Party support", ...) or a booster_id ("BO02") — meta
## is checked first, so a variable name that happens to collide with both
## reads as meta (meta's key set is small and fixed; booster IDs are
## namespaced BOxx and never collide with it in practice).
static func gate_passed(triggers: Array, meta: Dictionary,
		booster_standing: Dictionary, default_threshold: int) -> bool:
	var any_enabled := false
	for row: Dictionary in triggers:
		if str(row.get("enabled", "")) != "Yes":
			continue
		any_enabled = true

		var variable := str(row.get("variable", ""))
		var threshold_cell: Variant = row.get("threshold")
		var threshold := default_threshold if threshold_cell == null else int(threshold_cell)

		var value := int(meta[variable]) if meta.has(variable) else int(booster_standing.get(variable, 0))
		if value < threshold:
			return false

	return any_enabled
