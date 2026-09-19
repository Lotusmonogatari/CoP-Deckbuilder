class_name BarModel
extends RefCounted
## The support bar, in its three non-committee shapes.
##
## Different stages measure "winning" differently, and the difference is real
## rather than cosmetic:
##
## SHARED POOL — Floor Debate, Party Caucus, Town Hall, Steering Committee
##   There is a fixed number of seats or supporters in the room. Everyone is
##   either with you, against you, or undecided, and the three always add up
##   to the total. Winning someone over takes them from the undecided pile
##   first, and only then off your opponent. That makes the late stage of a
##   debate harder than the early stage, which is the point.
##
## SINGLE — Press Conference
##   One "press tone" number that goes up and down. There is no opponent bar;
##   the reporters' questions are the pressure.
##
## SURVIVAL — TV Debate
##   One number again, but the player has to be at or above the threshold at
##   the end of every single turn, not just at the finish. Slipping once
##   loses the stage.

enum Model { SHARED_POOL, SINGLE, SURVIVAL }

var model: Model = Model.SHARED_POOL
var maximum := 100      ## seats or supporters in the room
var threshold := 51     ## what the player needs to win
var player := 0
var opponent := 0

## Only meaningful for a shared pool: everyone not yet committed either way.
var undecided := 0


static func create(model_kind: Model, maximum_value: int, threshold_value: int,
		player_start: int, opponent_start: int) -> BarModel:
	var bar := BarModel.new()
	bar.model = model_kind
	bar.maximum = maxi(maximum_value, 1)
	bar.threshold = threshold_value
	bar.player = clampi(player_start, 0, bar.maximum)
	bar.opponent = clampi(opponent_start, 0, bar.maximum)

	if model_kind == Model.SHARED_POOL:
		bar.undecided = maxi(bar.maximum - bar.player - bar.opponent, 0)
		# If the starting numbers overfill the room, trim the opponent rather
		# than the player — the designer set the player's number on purpose.
		if bar.player + bar.opponent > bar.maximum:
			bar.opponent = maxi(bar.maximum - bar.player, 0)
			bar.undecided = 0
	else:
		bar.opponent = 0
		bar.undecided = 0

	return bar


## Chooses the right shape for a stage, from its bar unit and signature rule.
static func for_stage(stage: Dictionary) -> Model:
	match str(stage.get("stage_id", "")):
		"ST04": return Model.SINGLE      # press tone
		"ST06": return Model.SURVIVAL    # stay above the line every turn
		_: return Model.SHARED_POOL


# ---------------------------------------------------------------------------
# Moving the numbers
# ---------------------------------------------------------------------------

## The player wins people over.
##
## In a shared pool this takes from the undecided first and only then from the
## opponent, which is the rule in the brief. Returns how much actually moved,
## which can be less than asked for when the room runs out.
func player_gains(amount: int) -> int:
	if amount <= 0:
		return 0

	if model != Model.SHARED_POOL:
		var before := player
		player = clampi(player + amount, 0, maximum)
		return player - before

	var from_undecided := mini(amount, undecided)
	undecided -= from_undecided
	player += from_undecided

	var still_wanted := amount - from_undecided
	var from_opponent := mini(still_wanted, opponent)
	opponent -= from_opponent
	player += from_opponent

	return from_undecided + from_opponent


## The player argues the opponent down. Whoever the opponent loses goes back
## to undecided — they aren't automatically convinced of the other case.
func opponent_loses(amount: int) -> int:
	if amount <= 0:
		return 0

	if model != Model.SHARED_POOL:
		# There's no opponent bar in a single-bar stage. A refutation still
		# helps: it pushes the one bar in the player's favour.
		#
		# OPEN QUESTION for Cameron: is that right for a press conference?
		# The alternative is that "Opponent -3" does nothing there, which
		# would make every Data Driven card dead weight in ST04.
		return player_gains(amount)

	var moved := mini(amount, opponent)
	opponent -= moved
	undecided += moved
	return moved


## The opponent wins people over, by the same rules as the player.
func opponent_gains(amount: int) -> int:
	if amount <= 0:
		return 0

	if model != Model.SHARED_POOL:
		return 0   # no opponent bar to raise

	var from_undecided := mini(amount, undecided)
	undecided -= from_undecided
	opponent += from_undecided

	var still_wanted := amount - from_undecided
	var from_player := mini(still_wanted, player)
	player -= from_player
	opponent += from_player

	return from_undecided + from_player


## The player loses ground — from an opponent's attack, after block.
func player_loses(amount: int) -> int:
	if amount <= 0:
		return 0

	var moved := mini(amount, player)
	player -= moved
	if model == Model.SHARED_POOL:
		undecided += moved
	return moved


# ---------------------------------------------------------------------------
# Reading the state
# ---------------------------------------------------------------------------

func player_has_won() -> bool:
	return player >= threshold


func opponent_has_won() -> bool:
	return model == Model.SHARED_POOL and opponent >= threshold


## For the survival stage: has the player slipped below the line?
func player_below_threshold() -> bool:
	return player < threshold


## A sanity check used by the tests: in a shared pool the three numbers must
## always add up to the size of the room, no matter what has happened.
func totals_balance() -> bool:
	if model != Model.SHARED_POOL:
		return true
	return player + opponent + undecided == maximum


## The caption under the bar, e.g. "51 seats to win".
func caption(unit: String) -> String:
	return "%d %s to win" % [threshold, unit.to_lower()]


func to_dictionary() -> Dictionary:
	return {
		"model": model,
		"maximum": maximum,
		"threshold": threshold,
		"player": player,
		"opponent": opponent,
		"undecided": undecided,
	}
