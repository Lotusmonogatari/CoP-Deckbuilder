extends Node
## A noticeboard for things that happen in the game.
##
## Screens announce events here and other screens listen, so a card view
## doesn't need to know the battle screen exists, and the battle screen
## doesn't need to know what's listening. That keeps the UI pieces
## independent of one another.
##
## The rules engine in scripts/rules/ does NOT use this. Rules code never
## emits or listens to signals — it takes values in and hands results back.
## That's what lets it be tested without any of the game running.
##
## THE RULE FOR THIS FILE: a signal exists only if something emits it. Five
## used to sit here describing events nothing announced, which is worse than
## no noticeboard at all — it reads as a seam that is already wired up. If you
## need a new one, add it in the same commit as its emitter.

# --- Battle ----------------------------------------------------------------

## A card was played. The payload describes what it did, for animation.
signal card_played(card_id: String, result: Dictionary)

## The turn counter moved on.
signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)

## The opponent's move for the coming turn is now known and can be shown.
signal intent_revealed(intent: Dictionary)

## The gaffe meter changed. `is_final_warning` is true only when one more
## gaffe would end the stage — that's the only time the UI turns red.
signal gaffe_changed(value: int, limit: int, is_final_warning: bool)

## The stage ended. `outcome` is "win" or "loss"; `reason` explains why.
signal battle_ended(outcome: String, reason: String)

# --- Between battles -------------------------------------------------------

## A meta-variable moved: Jiban, Kanban, Kaban, or Party support.
signal meta_changed(variable_name: String, value: int, delta: int)

## XP was earned or spent.
signal xp_changed(total: int, delta: int)
