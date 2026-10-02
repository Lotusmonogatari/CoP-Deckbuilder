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
## Per-party scope (2026-10-02): a row can also carry "Applies To Parties"
## (data's own `applies_to_parties`, a list of party_ids) so a trigger can
## gate the swing into one or a few specific parties rather than the whole
## chamber — a blank/empty list still means every party, so a row written
## before this column existed behaves exactly as it always did. The caller
## (FloorVoteEngine) checks the gate once per party it's considering
## swinging, passing that party's own party_id in.
##
## Pure and UI-free (CLAUDE.md §12): everything it needs is passed in, no
## autoload access, so it is tested headless like every other rules file.


## `triggers` = data/vote_influence_triggers.json's own rows, each
## { variable, enabled, threshold, applies_to_parties }. `variable` names
## either a GameState.meta key ("Reputation", "Party support", ...) or a
## booster_id ("BO02") — meta is checked first, so a variable name that
## happens to collide with both reads as meta (meta's key set is small and
## fixed; booster IDs are namespaced BOxx and never collide with it in
## practice).
##
## `party_id` scopes the check to one party: a row whose own
## `applies_to_parties` is non-empty and does not name `party_id` is
## skipped entirely, as if it didn't exist for this party. A row with a
## blank/empty list always counts, regardless of `party_id` (including the
## default "" the caller gets when it isn't checking on behalf of any
## specific party).
static func gate_passed(triggers: Array, meta: Dictionary,
		booster_standing: Dictionary, default_threshold: int,
		party_id: String = "") -> bool:
	var any_enabled := false
	for row: Dictionary in triggers:
		if str(row.get("enabled", "")) != "Yes":
			continue

		var scoped_raw: Variant = row.get("applies_to_parties")
		var scope: Array = scoped_raw if scoped_raw is Array else []
		if not scope.is_empty() and not scope.has(party_id):
			continue
		any_enabled = true

		var variable := str(row.get("variable", ""))
		var threshold_cell: Variant = row.get("threshold")
		var threshold := default_threshold if threshold_cell == null else int(threshold_cell)

		var value := int(meta[variable]) if meta.has(variable) else int(booster_standing.get(variable, 0))
		if value < threshold:
			return false

	return any_enabled
