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

## What it costs, in persuasion points, to win over one seat.
##
## Somebody not yet committed either way comes across for a single point.
## Somebody already sitting with the opposition is harder, and how much
## harder varies from person to person: usually one point, sometimes two,
## occasionally three. That is what makes the end of a debate slower than
## the start even though the numbers look the same.
const UNDECIDED_COST := 1
const OPPONENT_COST_ODDS := [
	{"cost": 1, "chance": 60},
	{"cost": 2, "chance": 30},
	{"cost": 3, "chance": 10},
]

var model: Model = Model.SHARED_POOL
var maximum := 100      ## seats or supporters in the room
var threshold := 51     ## what the player needs to win
var player := 0
var opponent := 0

## Only meaningful for a shared pool: everyone not yet committed either way.
var undecided := 0

## True in a stage where only the player's own total is being scored — the
## caucus. Arguing the opposition down achieves nothing there, because their
## number is not what is being counted.
var scored_only := false

## Rolls what the next seat held by the opponent will cost.
##
## Handed in rather than made here, so the whole battle runs off one seeded
## generator and a test can post a fixed answer instead of a random one. A
## bar built without one rolls for itself: a missing roller must never
## quietly turn the rule off and make every seat cost a point.
var _cost_roller: Callable = Callable()


static func create(model_kind: Model, maximum_value: int, threshold_value: int,
		player_start: int, opponent_start: int,
		cost_roller: Callable = Callable()) -> BarModel:
	var bar := BarModel.new()
	bar.model = model_kind
	bar._cost_roller = cost_roller
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
##
## A stage built out of reporters' questions is a press conference wherever
## it appears, so it gets the press tone bar without having to be ST04. That
## is read from the stage's own shape rather than from its name, so a new
## press conference works the moment it has questions in it.
static func for_stage(stage: Dictionary) -> Model:
	var questions: Variant = stage.get("questions")
	if questions is Array and not (questions as Array).is_empty():
		return Model.SINGLE

	match str(stage.get("stage_id", "")):
		"ST04": return Model.SINGLE      # press tone
		"ST06": return Model.SURVIVAL    # stay above the line every turn
		_: return Model.SHARED_POOL


# ---------------------------------------------------------------------------
# Moving the numbers
# ---------------------------------------------------------------------------

## The player wins people over.
##
## `amount` is a budget of persuasion points, not a number of seats. In a
## shared pool the undecided come across first at a point each, and once they
## run out every further seat has to be bought off the opposition at whatever
## that person costs.
##
## Points that cannot pay for the next seat are LOST rather than held over: a
## big push can fall just short of a stubborn vote. Returns the number of
## seats that actually moved, which is what the screen reports.
##
## On a single bar there is nobody to buy anyone from, so a point is a point.
func player_gains(amount: int) -> int:
	if amount <= 0:
		return 0

	if model != Model.SHARED_POOL:
		var before := player
		player = clampi(player + amount, 0, maximum)
		return player - before

	var budget := amount
	var moved := 0

	while budget > 0:
		if undecided > 0:
			if budget < UNDECIDED_COST:
				break
			budget -= UNDECIDED_COST
			undecided -= 1
			player += 1
			moved += 1
			continue

		if opponent <= 0:
			break   # the whole room is already yours

		var cost := roll_opponent_cost()
		if budget < cost:
			break   # not enough left to shift this one, and it is not banked
		budget -= cost
		opponent -= 1
		player += 1
		moved += 1

	return moved


## What the next seat held by the opposition costs, in points.
func roll_opponent_cost() -> int:
	var roll := _roll_percent()
	var seen := 0
	for band: Dictionary in OPPONENT_COST_ODDS:
		seen += int(band["chance"])
		if roll < seen:
			return int(band["cost"])
	return int(OPPONENT_COST_ODDS[-1]["cost"])


## A number from 0 to 99, from the battle's generator where there is one.
func _roll_percent() -> int:
	if _cost_roller.is_valid():
		return int(_cost_roller.call())

	# No roller was handed in. Rolling for ourselves is worse than being
	# given the battle's generator — it cannot be replayed from a seed — but
	# it is far better than silently charging a point for everybody and
	# playing a different game from the one that was designed.
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return rng.randi_range(0, 99)


## The player argues the opponent down. Whoever the opponent loses goes back
## to undecided — they aren't automatically convinced of the other case.
##
## Where the opponent's number is not part of the win condition, this does
## NOTHING. There is nobody in a press conference whose support you are
## reducing, and in a caucus only your own total is being scored. Cameron
## chose this over converting it into your own gain: a card can simply be the
## wrong tool for the room, which is a real deckbuilding decision rather than
## a hidden conversion the player has to learn about.
##
## The screen has to say so, or the choice is a trap instead of a decision —
## see `reduce_does_nothing()`.
func opponent_loses(amount: int) -> int:
	if amount <= 0:
		return 0

	if reduce_does_nothing():
		return 0

	var moved := mini(amount, opponent)
	opponent -= moved
	undecided += moved
	return moved


## True where arguing the opposition down achieves nothing at all.
##
## The caucus is the awkward case: it IS a shared pool, so there are real
## opponent supporters to push into the undecided pile, and doing so used to
## make room for your next card to convert them at a point each. Scoring it
## as nothing removes that combination. If the caucus ever feels flat, this
## is the first thing to reconsider.
func reduce_does_nothing() -> bool:
	return model != Model.SHARED_POOL or scored_only


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
