class_name BattleState
extends RefCounted
## Everything that is true about a battle right now.
##
## Just the numbers and the piles of cards — no rules, no decisions. The
## battle engine reads and writes this; the UI reads it to know what to draw;
## the save system writes it out whole.
##
## Keeping it separate from the engine means a battle can be saved and
## restored mid-turn by copying this one object.

# --- Cards -----------------------------------------------------------------
var deck: Array[String] = []       ## card IDs, top of the deck first
var hand: Array[String] = []
var discard: Array[String] = []

# --- This turn -------------------------------------------------------------
var turn := 1
var energy := 0                    ## spendable now
var energy_per_turn := 3

## How energy is handed out.
##
##   "per_turn"  refills to energy_per_turn every turn. The normal case.
##   "pool"      handed out once for the whole stage and never refilled, so
##               spending it is a budget rather than a rhythm. The caucus.
var energy_mode := "per_turn"

## How many pips to draw: a turn's worth normally, the whole pool otherwise.
var energy_max := 3

## How the stage is decided.
##
##   "threshold"  reach the win threshold. The normal case.
##   "score"      there is no threshold. The stage runs its full length and
##                however high the support got is the result, which later
##                stages draw on.
var win_mode := "threshold"
var hand_size := 5

## Guard held this turn. Absorbs the opponent's next attack, then resets.
var block := 0

## A bonus left behind for the next card played this turn (C11 Groundwork).
var next_card_bonus := 0

# --- Standing --------------------------------------------------------------
var gaffe := 0
var gaffe_limit := 5
var opponent_gaffe := 0
var opponent_block := 0

# --- The stage --------------------------------------------------------------
var bar: BarModel = null           ## null in a committee stage
var committee: CommitteeModel = null   ## null everywhere else

## Set when a card reveals what the opponent will do after this turn.
var next_intent_revealed := false

# --- The press conference ---------------------------------------------------
## How cards arrive.
##
##   "refill"  top the hand back up every turn. The normal case.
##   "none"    you are dealt a hand at the start and that is all you get,
##             unless a card itself says otherwise.
var draw_mode := "refill"

## Which reporter's question is waiting, counting from zero.
var question_index := 0

## The organisations pleased by answering in the suit they invited. These
## carry out of the stage and into the floor debate.
var pleased_boosters: Array[String] = []

# --- Several opponents in one stage ----------------------------------------
## Which opponent is being argued with, counting from zero, and how many
## there are in total. Both are 0 and 1 in an ordinary one-opponent stage.
var opponent_index := 0
var opponent_count := 1

## How the battle finished: "ongoing", "win", "loss", or "retry".
var outcome := "ongoing"
var outcome_reason := ""


func is_over() -> bool:
	return outcome != "ongoing"


func is_committee_stage() -> bool:
	return committee != null


## The player's current standing, whichever shape the stage uses. Committee
## stages count locked-For votes; everything else reads the bar.
func player_score() -> int:
	if committee != null:
		return committee.locked_for()
	return bar.player if bar != null else 0


func to_dictionary() -> Dictionary:
	return {
		"deck": deck.duplicate(),
		"hand": hand.duplicate(),
		"discard": discard.duplicate(),
		"turn": turn,
		"energy": energy,
		"block": block,
		"gaffe": gaffe,
		"gaffe_limit": gaffe_limit,
		"opponent_gaffe": opponent_gaffe,
		"opponent_block": opponent_block,
		"bar": bar.to_dictionary() if bar != null else null,
		"committee": committee.to_dictionary() if committee != null else null,
		"outcome": outcome,
		"outcome_reason": outcome_reason,
	}
