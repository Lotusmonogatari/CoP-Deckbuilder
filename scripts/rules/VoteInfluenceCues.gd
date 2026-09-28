class_name VoteInfluenceCues
extends RefCounted
## Resolves data/vote_influence_cues.json (2026-09-28): the short optional
## line shown when the Floor Vote influence swing (VoteInfluence.gd,
## FloorVoteEngine._apply_influence_swing()) actually flips a bill's own
## pass/fail outcome — attributable specifically to the player's own
## influence, not just any swing. Entirely optional per (bill, direction)
## pair, the same "nothing written yet, nothing shown" bargain
## LevelIntroCues.gd already keeps.
##
## Pure and UI-free (CLAUDE.md §12): everything it needs is passed in, no
## autoload access, so it is tested headless like every other rules file.

const FLIPPED_TO_PASS := "Flipped to Pass"
const FLIPPED_TO_FAIL := "Flipped to Fail"


## The written line for this exact (bill_id, direction) pair, or "" if
## nothing has been written yet — CueBanner.say() is already a documented
## no-op on an empty line, so a caller can pass this straight through
## without checking first.
static func resolve(cues: Array, bill_id: String, direction: String) -> String:
	for row: Dictionary in cues:
		if str(row.get("bill_id", "")) == bill_id and str(row.get("outcome_direction", "")) == direction:
			return str(row.get("cue_text", ""))
	return ""
