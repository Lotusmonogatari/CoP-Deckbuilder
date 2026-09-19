extends GutTest
## Tests for the committee stage: locking votes, counting a majority, and
## knowing when the arithmetic has run out.


## Module 01's actual committee: four members, one already against.
func _module_01_committee() -> CommitteeModel:
	return CommitteeModel.create([
		TestFixtures.committee_member("Noah Kain"),
		TestFixtures.committee_member("Ran Sachiko"),
		TestFixtures.committee_member("Kotake Kasumu"),
		TestFixtures.committee_member("Isoroku Adams", "Against"),
	])


# ---------------------------------------------------------------------------
# Setting up
# ---------------------------------------------------------------------------

func test_undecided_members_start_in_the_middle() -> void:
	var committee := _module_01_committee()
	assert_eq(committee.members[0]["lean"], 50)
	assert_eq(committee.members[0]["locked"], "", "undecided means not yet locked")


func test_an_opposed_member_starts_locked_against() -> void:
	# This is the harsher of the two readings of "Against" and the one the
	# brief specifies: an opposed member cannot be turned at all.
	var committee := _module_01_committee()
	assert_eq(committee.members[3]["locked"], "Against")
	assert_eq(committee.locked_against(), 1)


func test_a_supportive_member_starts_locked_for() -> void:
	var committee := CommitteeModel.create([TestFixtures.committee_member("Ally", "For")])
	assert_eq(committee.members[0]["locked"], "For")
	assert_eq(committee.locked_for(), 1)


# ---------------------------------------------------------------------------
# The majority
# ---------------------------------------------------------------------------

func test_a_majority_is_half_the_committee_plus_one() -> void:
	assert_eq(_module_01_committee().majority_needed(), 3, "3 of 4")
	assert_eq(CommitteeModel.create([
		TestFixtures.committee_member("A"), TestFixtures.committee_member("B"),
		TestFixtures.committee_member("C"),
	]).majority_needed(), 2, "2 of 3")
	assert_eq(CommitteeModel.create([
		TestFixtures.committee_member("A"), TestFixtures.committee_member("B"),
		TestFixtures.committee_member("C"), TestFixtures.committee_member("D"),
		TestFixtures.committee_member("E"),
	]).majority_needed(), 3, "3 of 5")


# ---------------------------------------------------------------------------
# Locking
# ---------------------------------------------------------------------------

func test_a_member_locks_for_at_sixty_six() -> void:
	var committee := _module_01_committee()

	var almost := committee.persuade(0, 15)
	assert_eq(almost["lean"], 65)
	assert_eq(almost["locked"], "", "65 is not enough")

	var over := committee.persuade(0, 1)
	assert_eq(over["lean"], 66)
	assert_eq(over["locked"], "For", "66 locks the vote")
	assert_true(over["newly_locked"])


func test_a_member_locks_against_at_thirty_three() -> void:
	var committee := _module_01_committee()

	assert_eq(committee.persuade(0, -16)["locked"], "", "34 is still in play")
	assert_eq(committee.persuade(0, -1)["locked"], "Against", "33 locks against")


func test_a_locked_member_stops_moving() -> void:
	var committee := _module_01_committee()
	committee.persuade(0, 20)   # locks For at 70
	assert_eq(committee.members[0]["locked"], "For")

	var attempt := committee.persuade(0, -50)
	assert_eq(attempt["moved"], 0, "a locked vote does not move")
	assert_eq(committee.members[0]["lean"], 70)
	assert_eq(committee.members[0]["locked"], "For")


func test_lean_stays_between_zero_and_a_hundred() -> void:
	var committee := _module_01_committee()
	committee.persuade(0, 500)
	assert_eq(committee.members[0]["lean"], 100)


func test_persuading_a_member_who_is_not_there_is_harmless() -> void:
	var committee := _module_01_committee()
	var result := committee.persuade(99, 10)
	assert_eq(result["moved"], 0)


# ---------------------------------------------------------------------------
# Winning
# ---------------------------------------------------------------------------

func test_the_player_wins_on_a_locked_majority() -> void:
	var committee := _module_01_committee()
	assert_false(committee.player_has_won())

	committee.persuade(0, 20)
	committee.persuade(1, 20)
	assert_false(committee.player_has_won(), "two of the three needed")

	committee.persuade(2, 20)
	assert_eq(committee.locked_for(), 3)
	assert_true(committee.player_has_won())


# ---------------------------------------------------------------------------
# Losing, by arithmetic
# ---------------------------------------------------------------------------

func test_a_majority_starts_out_reachable() -> void:
	# Module 01: one vote is already lost, leaving exactly the three needed.
	# It is winnable, but there is no room for a single mistake.
	var committee := _module_01_committee()
	assert_true(committee.majority_still_reachable())
	assert_eq(committee.undecided_count(), 3)
	assert_eq(committee.majority_needed(), 3)


func test_losing_one_more_vote_ends_it() -> void:
	var committee := _module_01_committee()
	committee.persuade(0, -20)   # locks Against at 30

	assert_eq(committee.locked_against(), 2)
	assert_false(committee.majority_still_reachable(),
		"two For plus one lost is only two — a majority of three is gone")


func test_votes_already_won_still_count_towards_reachability() -> void:
	var committee := _module_01_committee()
	committee.persuade(0, 20)    # locked For
	committee.persuade(1, -20)   # locked Against

	# One locked For plus one still undecided is two; the majority is three.
	assert_false(committee.majority_still_reachable())


# ---------------------------------------------------------------------------
# The chair
# ---------------------------------------------------------------------------

func test_the_chair_pushes_a_member_away_from_you() -> void:
	var committee := _module_01_committee()
	committee.chair_pressure(0, 8)
	assert_eq(committee.members[0]["lean"], 42)


func test_the_chair_pressure_is_always_downward() -> void:
	# Even handed a positive number, the chair never helps.
	var committee := _module_01_committee()
	committee.chair_pressure(0, 8)
	assert_eq(committee.members[0]["lean"], 42)


func test_the_chair_goes_after_the_member_closest_to_flipping() -> void:
	var committee := _module_01_committee()
	committee.persuade(1, 10)   # Ran Sachiko is now at 60, the nearest to 66

	assert_eq(committee.most_persuaded_unlocked(), 1)


func test_the_chair_ignores_members_whose_votes_are_settled() -> void:
	var committee := _module_01_committee()
	committee.persuade(0, 20)   # locks For at 70 — the highest lean, but settled
	committee.persuade(1, 5)    # 55, the highest lean still in play

	assert_eq(committee.most_persuaded_unlocked(), 1)


func test_there_is_no_target_once_every_vote_is_locked() -> void:
	var committee := CommitteeModel.create([TestFixtures.committee_member("Only", "Against")])
	assert_eq(committee.most_persuaded_unlocked(), -1)
