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

# --- Battle ----------------------------------------------------------------

## A card was played. The payload describes what it did, for animation.
signal card_played(card_id: String, result: Dictionary)

## The turn counter moved on.
signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)

## The opponent's move for the coming turn is now known and can be shown.
signal intent_revealed(intent: Dictionary)

## A support bar changed, so the UI should animate it to the new value.
signal support_changed(who: String, value: int)

## The gaffe meter changed. `is_final_warning` is true only when one more
## gaffe would end the stage — that's the only time the UI turns red.
signal gaffe_changed(value: int, limit: int, is_final_warning: bool)

## A committee member's lean moved, or their vote locked.
signal member_changed(member_index: int, lean: int, locked_as: String)

## The stage ended. `outcome` is "win" or "loss"; `reason` explains why.
signal battle_ended(outcome: String, reason: String)

# --- Between battles -------------------------------------------------------

## A meta-variable moved: Jiban, Kanban, Kaban, or Party support.
signal meta_changed(variable_name: String, value: int, delta: int)

## A module step finished and the run moved on.
signal module_step_completed(module_id: String, seq: int)

## XP was earned or spent.
signal xp_changed(total: int, delta: int)

# --- Housekeeping ----------------------------------------------------------

## The game was saved. Useful for showing a brief confirmation.
signal game_saved()

## Something went wrong that the player should be told about in plain words.
signal player_facing_error(message: String)
