extends GutTest
## Tests for the sentences the battle screen says.
##
## Wording is usually not worth a test. These are, because every one of them
## exists to correct something a playtester read off the screen and
## misunderstood: a press conference counting tone as if it were people, a
## won debate reported only as a wasted point, an opponent whose entire turn
## happened in silence.


func _state(bar: BarModel, stage: Dictionary = {}) -> BattleState:
	var state := BattleState.new()
	state.bar = bar
	return state


func _room() -> BarModel:
	return BarModel.create(BarModel.Model.SHARED_POOL, 101, 55, 40, 40)


func _level() -> BarModel:
	return BarModel.create(BarModel.Model.SINGLE, 100, 0, 45, 0)


const SEATS := {"bar_unit": "Seats"}
const TONE := {"bar_unit": "Press tone"}
const CAUCUS := {"bar_unit": "Support", "bar_as_percent": true}


# ---------------------------------------------------------------------------
# A room of people versus a level that rises
# ---------------------------------------------------------------------------

func test_a_room_of_people_is_won_over() -> void:
	var result := {
		"effect": {"self_plus": 3},
		"applied": {"gained": 3, "gain_split": {"from_undecided": 3, "from_other_side": 0}},
	}
	var line := BattleNarration.player_move(result, SEATS, _state(_room()), "")
	assert_eq(line, "3 seats won over.")


func test_press_tone_is_raised_not_won_over() -> void:
	# "3 press tone won over" is what Cameron actually read on screen. Tone
	# is a mood, not a crowd.
	var result := {"effect": {"self_plus": 3}, "applied": {"gained": 3}}
	var line := BattleNarration.player_move(result, TONE, _state(_level()), "")
	assert_eq(line, "Press tone raised by 3.")


func test_a_press_card_that_moves_nothing_says_so() -> void:
	var result := {"effect": {"self_plus": 3}, "applied": {"gained": 0}}
	var line := BattleNarration.player_move(result, TONE, _state(_level()), "")
	assert_eq(line, "Press tone did not move.")


func test_a_caucus_is_counted_in_percent() -> void:
	var result := {
		"effect": {"self_plus": 4},
		"applied": {"gained": 4, "gain_split": {"from_undecided": 4, "from_other_side": 0}},
	}
	var line := BattleNarration.player_move(result, CAUCUS, _state(_room()), "")
	assert_eq(line, "4% won over.", "a caucus is a share of the room, not a headcount")


# ---------------------------------------------------------------------------
# Who was won over
# ---------------------------------------------------------------------------

func test_a_mixed_gain_says_where_the_people_came_from() -> void:
	var result := {
		"effect": {"self_plus": 4},
		"applied": {"gained": 3, "gain_split": {"from_undecided": 2, "from_other_side": 1}},
	}
	var line := BattleNarration.player_move(result, SEATS, _state(_room()), "Ito")
	assert_string_contains(line, "2 from the undecided, 1 off Ito")


func test_a_gain_entirely_from_the_undecided_does_not_labour_the_point() -> void:
	# "3 seats won over, 3 from the undecided" is a clause that adds nothing.
	var result := {
		"effect": {"self_plus": 3},
		"applied": {"gained": 3, "gain_split": {"from_undecided": 3, "from_other_side": 0}},
	}
	var line := BattleNarration.player_move(result, SEATS, _state(_room()), "Ito")
	assert_eq(line, "3 seats won over.")


# ---------------------------------------------------------------------------
# The shortfall, and the win that used to hide behind it
# ---------------------------------------------------------------------------

func test_points_that_bought_nobody_are_reported_as_short() -> void:
	var result := {
		"effect": {"self_plus": 4},
		"applied": {"gained": 3, "gain_split": {"from_undecided": 3, "from_other_side": 0}},
	}
	var line := BattleNarration.player_move(result, SEATS, _state(_room()), "")
	assert_string_contains(line, "1 point short of the next")


func test_a_finished_debater_leads_the_sentence() -> void:
	# The whole of Cameron's note 11: he beat opponent four and the screen
	# told him only that a point had been wasted.
	var result := {
		"effect": {"self_plus": 4},
		"applied": {"gained": 3, "gain_split": {"from_undecided": 3, "from_other_side": 0}},
		"bout_won": {"finished": "Opponent 4", "next": "Opponent 5", "remaining": 1},
	}
	var line := BattleNarration.player_move(result, SEATS, _state(_room()), "")

	assert_true(line.begins_with("Opponent 4 is finished — Opponent 5 rises"),
		"the win is the news, not the leftover: got '%s'" % line)
	assert_false(line.contains("short"),
		"a shortfall beside a win is what confused him in the first place")


func test_beating_the_last_debater_does_not_promise_another() -> void:
	var result := {
		"effect": {"self_plus": 3},
		"applied": {"gained": 3},
		"bout_won": {"finished": "Opponent 5", "next": "", "remaining": 0},
	}
	var line := BattleNarration.player_move(result, SEATS, _state(_room()), "")
	assert_string_contains(line, "Opponent 5 is finished")
	assert_false(line.contains("rises"))


# ---------------------------------------------------------------------------
# The opponent, who used to move in silence
# ---------------------------------------------------------------------------

func test_the_opponent_guarding_is_reported() -> void:
	var line := BattleNarration.opponent_move(
		{"verb": "block", "guard": 5}, SEATS, _state(_room()), "Ito")
	assert_eq(line, "Ito: developed 5 guard.")


func test_the_opponent_winning_people_over_is_reported() -> void:
	var line := BattleNarration.opponent_move(
		{"verb": "gain", "gained": 4,
			"gain_split": {"from_undecided": 3, "from_other_side": 1}},
		SEATS, _state(_room()), "Ito")
	assert_string_contains(line, "won over 4 seats")
	assert_string_contains(line, "3 from the undecided, 1 off you")


func test_an_attack_says_what_the_guard_ate_and_what_got_through() -> void:
	var line := BattleNarration.opponent_move(
		{"verb": "attack", "absorbed": 3, "damage": 2}, SEATS, _state(_room()), "Ito")
	assert_string_contains(line, "your guard absorbed 3")
	assert_string_contains(line, "2 seats lost to Ito")


func test_an_attack_fully_absorbed_says_nothing_got_through() -> void:
	var line := BattleNarration.opponent_move(
		{"verb": "attack", "absorbed": 5, "damage": 0}, SEATS, _state(_room()), "Ito")
	assert_string_contains(line, "nothing got through")


func test_an_unnamed_opponent_is_still_described() -> void:
	# Placeholder data, or a stage where nobody sits opposite.
	var line := BattleNarration.opponent_move(
		{"verb": "block", "guard": 2}, SEATS, _state(_room()), "")
	assert_eq(line, "They: developed 2 guard.")


func test_no_move_produces_no_sentence() -> void:
	assert_eq(BattleNarration.opponent_move({}, SEATS, _state(_room()), "Ito"), "")


# ---------------------------------------------------------------------------
# Units
# ---------------------------------------------------------------------------

func test_one_seat_is_singular() -> void:
	assert_eq(BattleNarration.quantity(SEATS, 1), "1 seat")
	assert_eq(BattleNarration.quantity(SEATS, 3), "3 seats")


func test_a_percentage_bar_carries_its_sign() -> void:
	assert_eq(BattleNarration.quantity(CAUCUS, 1), "1%")
