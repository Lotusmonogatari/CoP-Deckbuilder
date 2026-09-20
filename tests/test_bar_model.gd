extends GutTest
## Tests for the support bar, especially the shared pool used by the floor
## debate — the model where every seat won has to come from somewhere.


## Rolls a fixed answer instead of a random one, so a test can say exactly
## what a stubborn vote costs and then assert exact numbers.
##
## The roller returns a percentile, the same shape the battle hands in: 0-59
## is a one-point vote, 60-89 costs two, 90-99 costs three.
func _always(percentile: int) -> Callable:
	return func() -> int: return percentile

const CHEAP := 0      # a one-point vote
const AWKWARD := 60   # a two-point vote
const STUBBORN := 90  # a three-point vote


func _floor_debate(cost_roller: Callable = Callable()) -> BarModel:
	# The real ST02 numbers: 101 seats, 51 to win, both sides starting on 40,
	# so 21 seats are undecided.
	if not cost_roller.is_valid():
		cost_roller = _always(CHEAP)
	return BarModel.create(BarModel.Model.SHARED_POOL, 101, 51, 40, 40, cost_roller)


# ---------------------------------------------------------------------------
# The invariant
# ---------------------------------------------------------------------------

func test_the_room_starts_full() -> void:
	var bar := _floor_debate()
	assert_eq(bar.player, 40)
	assert_eq(bar.opponent, 40)
	assert_eq(bar.undecided, 21, "101 seats, 80 taken, 21 undecided")
	assert_true(bar.totals_balance())


func test_the_seats_always_add_up() -> void:
	# Whatever happens, the three numbers must still total 101. This is the
	# single most important property of the shared pool: seats cannot be
	# created or destroyed, only moved.
	var bar := _floor_debate()

	bar.player_gains(10)
	assert_true(bar.totals_balance(), "after the player gains")

	bar.opponent_loses(15)
	assert_true(bar.totals_balance(), "after the opponent loses")

	bar.opponent_gains(30)
	assert_true(bar.totals_balance(), "after the opponent gains")

	bar.player_loses(8)
	assert_true(bar.totals_balance(), "after the player loses")

	bar.player_gains(500)
	assert_true(bar.totals_balance(), "after asking for more than the room holds")

	assert_eq(bar.player + bar.opponent + bar.undecided, 101)


# ---------------------------------------------------------------------------
# Where gains come from
# ---------------------------------------------------------------------------

func test_gains_come_from_the_undecided_first() -> void:
	var bar := _floor_debate()
	var moved := bar.player_gains(10)

	assert_eq(moved, 10)
	assert_eq(bar.player, 50)
	assert_eq(bar.undecided, 11, "all ten came from the undecided")
	assert_eq(bar.opponent, 40, "the opponent was not touched")


func test_gains_take_from_the_opponent_once_the_undecided_run_out() -> void:
	var bar := _floor_debate(_always(CHEAP))
	var moved := bar.player_gains(25)

	assert_eq(moved, 25, "with every vote costing a point, 25 points is 25 seats")
	assert_eq(bar.undecided, 0, "all 21 undecided went first")
	assert_eq(bar.opponent, 36, "then 4 more came off the opponent")
	assert_eq(bar.player, 65)


func test_a_gain_cannot_take_more_than_the_room_holds() -> void:
	var bar := _floor_debate(_always(CHEAP))
	var moved := bar.player_gains(200)

	assert_eq(moved, 61, "21 undecided plus the opponent's 40")
	assert_eq(bar.player, 101)
	assert_eq(bar.opponent, 0)
	assert_eq(bar.undecided, 0)


# ---------------------------------------------------------------------------
# What a seat costs
# ---------------------------------------------------------------------------
# Somebody not yet committed comes across for a point. Somebody already
# sitting with the opposition is harder, and how much harder varies from
# person to person. That is what makes the end of a debate slower than the
# start even though the numbers look the same.

func test_the_undecided_always_cost_a_point_each() -> void:
	# Even with the roller set to its most stubborn: the cost only applies to
	# people who have already taken a side.
	var bar := _floor_debate(_always(STUBBORN))
	var moved := bar.player_gains(10)

	assert_eq(moved, 10)
	assert_eq(bar.undecided, 11)
	assert_eq(bar.opponent, 40, "nobody was bought off the opponent")


func test_an_awkward_vote_costs_two_points() -> void:
	var bar := _floor_debate(_always(AWKWARD))
	bar.undecided = 0
	bar.player = 61   # 61 + 40 + 0 = 101

	var moved := bar.player_gains(6)
	assert_eq(moved, 3, "six points bought three votes at two each")
	assert_eq(bar.opponent, 37)
	assert_true(bar.totals_balance())


func test_a_stubborn_vote_costs_three_points() -> void:
	var bar := _floor_debate(_always(STUBBORN))
	bar.undecided = 0
	bar.player = 61

	var moved := bar.player_gains(6)
	assert_eq(moved, 2, "six points bought only two votes at three each")
	assert_eq(bar.opponent, 38)


func test_points_that_cannot_afford_the_next_vote_are_lost() -> void:
	# A big push can fall just short of a stubborn vote, and what is left
	# over is not banked for the next card.
	var bar := _floor_debate(_always(STUBBORN))
	bar.undecided = 0
	bar.player = 61

	var moved := bar.player_gains(5)
	assert_eq(moved, 1, "three points bought one; the other two bought nothing")
	assert_eq(bar.opponent, 39)
	assert_true(bar.totals_balance(), "and the two that were lost are not owed to anybody")


func test_the_odds_add_up_to_certainty() -> void:
	# Guards the table itself: a percentile that fell through every band
	# would silently return the last cost.
	var total := 0
	for band: Dictionary in BarModel.OPPONENT_COST_ODDS:
		total += int(band["chance"])
	assert_eq(total, 100, "every roll lands in exactly one band")


func test_every_percentile_is_priced() -> void:
	var bar := _floor_debate()
	for percentile in 100:
		bar._cost_roller = _always(percentile)
		var cost := bar.roll_opponent_cost()
		assert_between(cost, 1, 3, "a roll of %d priced a vote at %d" % [percentile, cost])


func test_the_bands_fall_where_the_odds_say() -> void:
	var bar := _floor_debate()
	var counts := {1: 0, 2: 0, 3: 0}
	for percentile in 100:
		bar._cost_roller = _always(percentile)
		counts[bar.roll_opponent_cost()] += 1

	assert_eq(counts[1], 60, "60 rolls in a hundred cost a point")
	assert_eq(counts[2], 30)
	assert_eq(counts[3], 10)


func test_a_bar_with_no_roller_still_charges() -> void:
	# A missing roller must never quietly turn the rule off: that would play
	# a different game from the one that was designed, and silently.
	var bar := BarModel.create(BarModel.Model.SHARED_POOL, 101, 51, 61, 40)
	bar.undecided = 0

	var moved := bar.player_gains(30)
	assert_lte(moved, 30, "some of those votes cost more than a point")
	assert_true(bar.totals_balance())


# ---------------------------------------------------------------------------
# Where losses go
# ---------------------------------------------------------------------------

func test_the_opponents_losses_go_back_to_undecided() -> void:
	# Arguing someone off your opponent does not make them agree with you.
	var bar := _floor_debate()
	var moved := bar.opponent_loses(6)

	assert_eq(moved, 6)
	assert_eq(bar.opponent, 34)
	assert_eq(bar.undecided, 27, "the six became undecided, not the player's")
	assert_eq(bar.player, 40, "the player gained nothing directly")


func test_the_players_losses_go_back_to_undecided_too() -> void:
	var bar := _floor_debate()
	bar.player_loses(5)

	assert_eq(bar.player, 35)
	assert_eq(bar.undecided, 26)
	assert_eq(bar.opponent, 40)


func test_an_opponent_at_zero_cannot_lose_more() -> void:
	var bar := BarModel.create(BarModel.Model.SHARED_POOL, 101, 51, 40, 0)
	assert_eq(bar.opponent_loses(10), 0)
	assert_true(bar.totals_balance())


# ---------------------------------------------------------------------------
# Winning
# ---------------------------------------------------------------------------

func test_the_player_wins_at_the_threshold() -> void:
	var bar := _floor_debate()
	bar.player_gains(10)
	assert_eq(bar.player, 50)
	assert_false(bar.player_has_won(), "50 of 101 is not a majority")

	bar.player_gains(1)
	assert_eq(bar.player, 51)
	assert_true(bar.player_has_won(), "51 seats carries the house")


func test_the_opponent_can_reach_the_threshold_too() -> void:
	var bar := _floor_debate()
	bar.opponent_gains(11)
	assert_eq(bar.opponent, 51)
	assert_true(bar.opponent_has_won())


# ---------------------------------------------------------------------------
# The other two shapes
# ---------------------------------------------------------------------------

func test_a_single_bar_has_no_opponent_side() -> void:
	# The press conference: one "press tone" number, nothing to take from.
	var bar := BarModel.create(BarModel.Model.SINGLE, 100, 55, 45, 45)
	assert_eq(bar.player, 45)
	assert_eq(bar.opponent, 0)
	assert_eq(bar.undecided, 0)

	bar.player_gains(10)
	assert_eq(bar.player, 55)
	assert_true(bar.player_has_won())


func test_a_refutation_pushes_the_single_bar_the_players_way() -> void:
	# There is no opponent bar to knock down in a press conference, so a
	# "-3 to the opponent" card moves the one bar instead. Without this, every
	# Data Driven card would be dead weight there.
	var bar := BarModel.create(BarModel.Model.SINGLE, 100, 55, 45, 0)
	bar.opponent_loses(3)
	assert_eq(bar.player, 48)


func test_a_single_bar_cannot_exceed_its_maximum() -> void:
	var bar := BarModel.create(BarModel.Model.SINGLE, 100, 55, 95, 0)
	bar.player_gains(50)
	assert_eq(bar.player, 100)


func test_the_survival_bar_knows_when_the_player_has_slipped() -> void:
	# The TV debate: staying at or above the line is the whole game.
	var bar := BarModel.create(BarModel.Model.SURVIVAL, 100, 50, 50, 0)
	assert_false(bar.player_below_threshold(), "starting exactly on the line is fine")

	bar.player_loses(1)
	assert_true(bar.player_below_threshold(), "one point under is under")


# ---------------------------------------------------------------------------
# Choosing the shape
# ---------------------------------------------------------------------------

func test_each_stage_gets_the_right_shape() -> void:
	assert_eq(BarModel.for_stage({"stage_id": "ST02"}), BarModel.Model.SHARED_POOL, "floor debate")
	assert_eq(BarModel.for_stage({"stage_id": "ST03"}), BarModel.Model.SHARED_POOL, "party caucus")
	assert_eq(BarModel.for_stage({"stage_id": "ST05"}), BarModel.Model.SHARED_POOL, "town hall")
	assert_eq(BarModel.for_stage({"stage_id": "ST08"}), BarModel.Model.SHARED_POOL, "steering committee")
	assert_eq(BarModel.for_stage({"stage_id": "ST04"}), BarModel.Model.SINGLE, "press conference")
	assert_eq(BarModel.for_stage({"stage_id": "ST06"}), BarModel.Model.SURVIVAL, "tv debate")


func test_starting_numbers_that_overfill_the_room_are_trimmed() -> void:
	# A very unpopular bill could push the opponent's start past what's left.
	# The player's number is the one the designer set, so the opponent gives.
	var bar := BarModel.create(BarModel.Model.SHARED_POOL, 101, 51, 40, 80)
	assert_eq(bar.player, 40)
	assert_eq(bar.opponent, 61)
	assert_eq(bar.undecided, 0)
	assert_true(bar.totals_balance())
