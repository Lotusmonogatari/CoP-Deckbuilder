extends GutTest
## Hiring and upgrading Staff, and what each tier's reward actually does.
##
## GameState is the run's memory and an autoload, so these tests put it back
## the way they found it, the same as test_game_state_spending.gd.
##
## Uses the real data/staff.json rows by ID rather than a hand-built fixture,
## because the point under test — a BOxx reward moving booster_standing, an
## SGxx reward moving segment_favorability — is exactly the shape those real
## rows carry (see GameState._apply_staff_reward()).

var _meta_before: Dictionary = {}
var _staff_before: Dictionary = {}
var _fired_before: Dictionary = {}
var _standing_before: Dictionary = {}
var _change_before: Dictionary = {}
var _favorability_before: Dictionary = {}
var _segment_change_before: Dictionary = {}
var _recruitment_tier_before := 0


func before_each() -> void:
	_meta_before = GameState.meta.duplicate(true)
	_staff_before = GameState.staff_hired.duplicate(true)
	_fired_before = GameState.staff_fired.duplicate(true)
	_standing_before = GameState.booster_standing.duplicate(true)
	_change_before = GameState.last_booster_change.duplicate(true)
	_favorability_before = GameState.segment_favorability.duplicate(true)
	_segment_change_before = GameState.last_segment_change.duplicate(true)
	_recruitment_tier_before = GameState.staff_recruitment_tier
	GameState.staff_hired = {}
	GameState.staff_fired = {}
	# This file is about hiring/firing/reward mechanics, not the SH18
	# recruitment-tier gate (that has its own coverage) — open every tier
	# so a real candidate's own highest_tier never refuses these hires.
	GameState.staff_recruitment_tier = 2


func after_each() -> void:
	GameState.meta = _meta_before.duplicate(true)
	GameState.staff_hired = _staff_before.duplicate(true)
	GameState.staff_fired = _fired_before.duplicate(true)
	GameState.booster_standing = _standing_before.duplicate(true)
	GameState.last_booster_change = _change_before.duplicate(true)
	GameState.segment_favorability = _favorability_before.duplicate(true)
	GameState.last_segment_change = _segment_change_before.duplicate(true)
	GameState.staff_recruitment_tier = _recruitment_tier_before


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


func test_hiring_applies_an_sgxx_reward_to_segment_favorability() -> void:
	# SF01's tier_0_reward is [{"delta": 1, "target": "SG03"}] — no BOxx at
	# all, and should move segment_favorability without touching any booster.
	var standing_before := GameState.booster_standing.duplicate(true)
	var before := int(GameState.segment_favorability.get("SG03", 50))
	GameState.meta["Funds"] = 999999

	var refusal := GameState.hire_staff("SF01")

	assert_eq(refusal, "")
	assert_eq(int(GameState.segment_favorability.get("SG03")), before + 1)
	assert_eq(int(GameState.last_segment_change.get("SG03")), 1)
	assert_eq(GameState.booster_standing, standing_before,
		"an SGxx-only reward touches no booster")


func test_segment_favorability_clamps_at_100() -> void:
	GameState.segment_favorability["SG03"] = 100
	GameState.meta["Funds"] = 999999

	GameState.hire_staff("SF01")   # +1 to SG03

	assert_eq(int(GameState.segment_favorability.get("SG03")), 100, "clamped, not 101")


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


# ---------------------------------------------------------------------------
# Firing
# ---------------------------------------------------------------------------

func test_firing_empties_the_role_and_spends_the_severance() -> void:
	var candidate := DataDB.get_staff("SF02")
	var role := str(candidate.get("role"))
	var severance := int(candidate.get("firing_cost_yen", 0))
	GameState.meta["Funds"] = 999999
	GameState.hire_staff("SF02")
	GameState.meta["Funds"] = severance

	var refusal := GameState.fire_staff(role)

	assert_eq(refusal, "", "should have gone through: %s" % refusal)
	assert_true(GameState.staff_hired.get(role, {}).is_empty(), "the role is vacant again")
	assert_eq(int(GameState.meta["Funds"]), 0, "the severance is spent")


func test_a_fired_candidate_is_remembered_and_never_hireable_again() -> void:
	GameState.meta["Funds"] = 999999
	GameState.hire_staff("SF02")
	var role := str(DataDB.get_staff("SF02").get("role"))

	GameState.fire_staff(role)

	assert_true(bool(GameState.staff_fired.get("SF02", false)))
	var refusal := GameState.hire_staff("SF02")
	assert_ne(refusal, "", "SF02 was fired and cannot be re-hired")
	assert_true(GameState.staff_hired.get(role, {}).is_empty())


func test_firing_lets_a_different_candidate_fill_the_role_right_away() -> void:
	GameState.meta["Funds"] = 999999
	GameState.hire_staff("SF02")
	var role := str(DataDB.get_staff("SF02").get("role"))
	GameState.fire_staff(role)

	# SF03 is a different candidate for the same role (Policy Research
	# Assistant) — see test_a_role_that_is_already_filled_cannot_be_hired_into_again.
	var refusal := GameState.hire_staff("SF03")

	assert_eq(refusal, "", "should have gone through: %s" % refusal)
	assert_eq(GameState.staff_hired.get(role, {}).get("staff_id"), "SF03")


func test_firing_does_not_claw_back_the_reward_already_earned() -> void:
	# SF02's tier_0_reward is [{"delta": 2, "target": "BO05"}] — Cameron's
	# decision, 2026-09-25 (design/proposals/staff_firing.md): firing never
	# refunds Funds spent or the standing/favourability already granted.
	var before := int(GameState.booster_standing.get("BO05", 50))
	var role := str(DataDB.get_staff("SF02").get("role"))
	GameState.meta["Funds"] = 999999
	GameState.hire_staff("SF02")
	GameState.fire_staff(role)

	assert_eq(int(GameState.booster_standing.get("BO05")), before + 2,
		"the reward from hiring SF02 stands, even after firing them")


func test_firing_an_empty_role_is_refused() -> void:
	var refusal := GameState.fire_staff("Media Spokesperson")
	assert_ne(refusal, "")


func test_firing_without_enough_funds_is_refused_and_the_hire_stays() -> void:
	var candidate := DataDB.get_staff("SF02")
	var role := str(candidate.get("role"))
	GameState.meta["Funds"] = 999999
	GameState.hire_staff("SF02")
	GameState.meta["Funds"] = 0

	var refusal := GameState.fire_staff(role)

	assert_ne(refusal, "")
	assert_eq(GameState.staff_hired.get(role, {}).get("staff_id"), "SF02",
		"still hired — the severance was never affordable")


# ---------------------------------------------------------------------------
# Segment favorability starts where segments.json says it should
# ---------------------------------------------------------------------------

func test_reset_seeds_segment_favorability_from_the_workbook() -> void:
	GameState.reset_segment_favorability()

	for segment: Dictionary in DataDB.segments:
		var segment_id := str(segment.get("segment_id"))
		var expected := int(segment.get("initial_favorability_pct", 50))
		assert_eq(int(GameState.segment_favorability.get(segment_id)), expected,
			"%s should start at its own Initial Favorability %%" % segment_id)
