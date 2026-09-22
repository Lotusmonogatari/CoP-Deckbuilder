extends GutTest
## Hiring and upgrading Staff, and what each tier's reward actually does.
##
## GameState is the run's memory and an autoload, so these tests put it back
## the way they found it, the same as test_game_state_spending.gd.
##
## Uses the real data/staff.json rows by ID rather than a hand-built fixture,
## because the point under test — a BOxx reward moving booster_standing, an
## SGxx reward being skipped — is exactly the shape those real rows carry
## (see GameState._apply_staff_reward()'s own note on why SGxx is skipped).

var _meta_before: Dictionary = {}
var _staff_before: Dictionary = {}
var _standing_before: Dictionary = {}
var _change_before: Dictionary = {}


func before_each() -> void:
	_meta_before = GameState.meta.duplicate(true)
	_staff_before = GameState.staff_hired.duplicate(true)
	_standing_before = GameState.booster_standing.duplicate(true)
	_change_before = GameState.last_booster_change.duplicate(true)
	GameState.staff_hired = {}


func after_each() -> void:
	GameState.meta = _meta_before.duplicate(true)
	GameState.staff_hired = _staff_before.duplicate(true)
	GameState.booster_standing = _standing_before.duplicate(true)
	GameState.last_booster_change = _change_before.duplicate(true)


# ---------------------------------------------------------------------------
# Hiring
# ---------------------------------------------------------------------------

func test_hiring_fills_the_role_and_spends_yen() -> void:
	var candidate := DataDB.get_staff("SF02")
	assert_false(candidate.is_empty(), "fixture assumes SF02 exists in staff.json")
	var role := str(candidate.get("role"))
	GameState.meta["Funds"] = int(candidate.get("hiring_cost_yen", 0))

	var refusal := GameState.hire_staff("SF02")

	assert_eq(refusal, "", "should have gone through: %s" % refusal)
	assert_eq(GameState.staff_hired.get(role, {}).get("staff_id"), "SF02")
	assert_eq(GameState.staff_hired.get(role, {}).get("tier"),
		int(candidate.get("starting_tier", 0)))
	assert_eq(int(GameState.meta["Funds"]), 0, "the hiring cost is spent")


func test_a_role_that_is_already_filled_cannot_be_hired_into_again() -> void:
	var first := DataDB.get_staff("SF02")
	var role := str(first.get("role"))
	GameState.meta["Funds"] = 999999
	GameState.hire_staff("SF02")

	# SF03 is a different candidate for the SAME role (Policy Research
	# Assistant) — the role, not just SF02, should be what blocks a second hire.
	var refusal := GameState.hire_staff("SF03")

	assert_ne(refusal, "", "the role is taken")
	assert_eq(GameState.staff_hired.get(role, {}).get("staff_id"), "SF02",
		"the original hire is untouched")


func test_hiring_without_enough_funds_is_refused_and_spends_nothing() -> void:
	GameState.meta["Funds"] = 0
	var refusal := GameState.hire_staff("SF02")

	assert_ne(refusal, "")
	assert_true(GameState.staff_hired.is_empty())
	assert_eq(int(GameState.meta["Funds"]), 0)


# ---------------------------------------------------------------------------
# Tier rewards on hire — BOxx applies, SGxx is skipped
# ---------------------------------------------------------------------------

func test_hiring_applies_a_boxx_reward_to_booster_standing() -> void:
	# SF02's tier_0_reward is [{"delta": 2, "target": "BO05"}] in the real data.
	var before := int(GameState.booster_standing.get("BO05", 50))
	GameState.meta["Funds"] = 999999

	GameState.hire_staff("SF02")

	assert_eq(int(GameState.booster_standing.get("BO05")), before + 2)


func test_an_sgxx_only_reward_moves_nothing_and_does_not_crash() -> void:
	# SF01's tier_0_reward is [{"delta": 1, "target": "SG03"}] — no BOxx at
	# all. Nothing tracks a current segment favourability (see the note on
	# GameState._apply_staff_reward), so this should simply do nothing.
	var standing_before := GameState.booster_standing.duplicate(true)
	GameState.meta["Funds"] = 999999

	var refusal := GameState.hire_staff("SF01")

	assert_eq(refusal, "")
	assert_eq(GameState.booster_standing, standing_before,
		"an SGxx-only reward touches no booster")


# ---------------------------------------------------------------------------
# Upgrading
# ---------------------------------------------------------------------------

func test_upgrading_advances_the_tier_and_spends_yen() -> void:
	var candidate := DataDB.get_staff("SF04")   # starts at 0, reaches 2
	var role := str(candidate.get("role"))
	GameState.meta["Funds"] = 999999
	GameState.hire_staff("SF04")

	GameState.meta["Funds"] = int(candidate.get("upgrade_cost_0_to_1_yen", 0))
	var refusal := GameState.upgrade_staff(role)

	assert_eq(refusal, "", "should have gone through: %s" % refusal)
	assert_eq(int(GameState.staff_hired[role]["tier"]), 1)
	assert_eq(int(GameState.meta["Funds"]), 0)


func test_a_candidate_at_their_highest_tier_cannot_be_upgraded_further() -> void:
	var candidate := DataDB.get_staff("SF05")   # starts and stays at tier 1
	var role := str(candidate.get("role"))
	GameState.meta["Funds"] = 999999
	GameState.hire_staff("SF05")

	var refusal := GameState.upgrade_staff(role)

	assert_ne(refusal, "")
	assert_eq(int(GameState.staff_hired[role]["tier"]), 1, "still at tier 1")


func test_upgrading_an_empty_role_is_refused() -> void:
	var refusal := GameState.upgrade_staff("Media Spokesperson")
	assert_ne(refusal, "")
