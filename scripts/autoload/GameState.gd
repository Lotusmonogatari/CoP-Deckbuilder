extends Node
## Holds the state of the current run: where the player is in the campaign,
## their meta-variables, their deck, and their XP.
##
## NOT BUILT YET. This is a placeholder so the project structure matches the
## build brief; it gets filled in at milestone M4, alongside the module runner
## and auto-saving.
##
## What will live here:
##   - the four meta-variables (Jiban, Kanban, Kaban, Party support), each
##     clamped to the min and max in sanban.json
##   - which module and step the player is on
##   - the player's current deck, unlocked cards, and upgraded cards
##   - XP earned and spent
##   - which booster organizations are active
##
## Deliberately kept separate from the rules engine: this is the campaign's
## memory, while scripts/rules/ is the maths of a single battle.

func _ready() -> void:
	# Nothing to do until M4. DataDB loads first and prints its own report.
	pass
