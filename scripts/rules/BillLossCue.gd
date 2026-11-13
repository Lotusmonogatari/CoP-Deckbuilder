class_name BillLossCue
extends RefCounted
## Which cue a lost bill level (an Act) shows (2026-11-12, Cameron). Pure and
## UI-free (CLAUDE.md section 12).
##
##   PARTY   the party pulled the player away for lackluster performance: a
##           stage whose loss ends the level was lost, by anything but gaffes.
##   TONGUE  the gaffe meter filled: staff pulled the player away.
##   NONE    no cue: not a bill level, a loss that does not end the level, a
##           win, or the player abandoning the level (their own choice).

const NONE := ""
const PARTY := "party"
const TONGUE := "tongue"


static func kind(in_bill_level: bool, lost: bool, loss_ends_level: bool,
		abandoned: bool, gaffe_loss: bool) -> String:
	if not in_bill_level or not lost or not loss_ends_level or abandoned:
		return NONE
	return TONGUE if gaffe_loss else PARTY
