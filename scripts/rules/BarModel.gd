class_name BarModel
extends RefCounted
## The support bar, in its three shapes.
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

## How the last gain was actually made, for the screen to describe.
##
## `player_gains()` returns a single total, but "3 seats won over" is not the
## same sentence as "2 from the undecided, 1 argued across" — and Cameron
## asked for the difference. Rather than change the return type that the
## whole test suite reads, the breakdown is recorded here and read straight
## afterwards by whoever wants it.
##
## `from_other_side` means whoever was taken off the opposing side, so the
## same two keys describe either side's move without a perspective flip.
##
## `wasted` is the points that could not pay for anybody: leftovers are lost
## rather than banked, so the screen can say so instead of leaving the
## player to wonder where the number went.
var last_gain := {"from_undecided": 0, "from_other_side": 0, "wasted": 0}


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


## Chooses the right shape for a stage.
##
## A STAGE THAT SAYS WHAT IT WANTS GETS IT. Everything below that is a guess
## made from the stage's shape, and a guess is only as good as the shapes it
## has seen: the TV debate spent three versions as a room full of undecided
## people while its bar was labelled "Press tone", because it was recognised
## by the literal ID "ST06" and the six levels generate IDs of their own
## (TV_DEBATE_2 and the like). Declaring `bar_model` in stage_types.json is
## how a stage stops depending on being recognised.
static func for_stage(stage: Dictionary) -> Model:
	# THE <null> TRAP, explained once here — every other place in
	# scripts/rules/ and scripts/BattleSetup.gd that reads an optional
	# stages.json column points back to this paragraph rather than
	# repeating it: the workbook's optional columns are exported as an
	# explicit JSON null on a row that doesn't set them, not an absent key.
	# str(null) is the literal text "<null>", not "", so the null has to be
	# caught before str() or a blank cell stops looking blank and its
	# default never applies. Lowercased here so a workbook cell can read
	# naturally ("Single", "Survival") while this match stays a plain
	# lowercase literal — a caller that needs different treatment of an
	# empty (non-null) string, trimming, or a non-string result makes its
	# own choice on top of the same null check; those differ by call site
	# and are not part of the trap itself.
	var declared: Variant = stage.get("bar_model")
	match (str(declared).to_lower() if declared != null else ""):
		"single": return Model.SINGLE
		"survival": return Model.SURVIVAL
		"shared_pool": return Model.SHARED_POOL

	# A stage built out of reporters' questions is a press conference wherever
	# it appears, so it gets the press tone bar without having to say so. That
	# is read from the stage's own shape rather than from its name, so a new
	# press conference works the moment it has questions in it.
	var questions: Variant = stage.get("questions")
	if questions is Array and not (questions as Array).is_empty():
		return Model.SINGLE

	# The workbook's own stages, which have fixed IDs and no bar_model column.
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

	last_gain = {"from_undecided": 0, "from_other_side": 0, "wasted": 0}

	if model != Model.SHARED_POOL:
		var before := player
		player = clampi(player + amount, 0, maximum)
		# A single bar is a level, not a room: there is nobody to win over,
		# so the whole move counts as one undivided rise.
		last_gain["from_undecided"] = player - before
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
			last_gain["from_undecided"] += 1
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
		last_gain["from_other_side"] += 1

	last_gain["wasted"] = budget
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

	# Recorded the same way the player's gains are, so one helper can
	# describe either side's move.
	last_gain = {
		"from_undecided": from_undecided,
		"from_other_side": from_player,
		"wasted": still_wanted - from_player,
	}
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
