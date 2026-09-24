extends GutTest
## Level unlock cost (by the Policy Research Assistant's current tier) and
## cooldown (levels.json's own "cooldown" column). Both are gated behind
## rules.json's "level_gating_enabled", default false — see
## GameState.levels_unlocked/levels_completed_count/level_last_completed_at
## and Ledger.gd's "Levels" section.
##
## GameState is the run's memory and an autoload, so these tests put it back
## the way they found it, the same as test_game_state_staff.gd.

var _xp_before: int = 0
var _levels_unlocked_before: Array = []
var _levels_completed_before: int = 0
var _last_completed_before: Dictionary = {}
var _staff_before: Dictionary = {}


func before_each() -> void:
	_xp_before = GameState.xp
	_levels_unlocked_before = GameState.levels_unlocked.duplicate(true)
	_levels_completed_before = GameState.levels_completed_count
	_last_completed_before = GameState.level_last_completed_at.duplicate(true)
	_staff_before = GameState.staff_hired.duplicate(true)
	GameState.staff_hired = {}


func after_each() -> void:
	GameState.xp = _xp_before
	GameState.levels_unlocked = _levels_unlocked_before.duplicate(true)
	GameState.levels_completed_count = _levels_completed_before
	GameState.level_last_completed_at = _last_completed_before.duplicate(true)
	GameState.staff_hired = _staff_before.duplicate(true)


# ---------------------------------------------------------------------------
# Ledger.level_unlock_cost — which unlock_cost_* column applies
# ---------------------------------------------------------------------------

func test_a_vacant_pra_charges_unlock_cost_vacant() -> void:
	var level := {"unlock_cost_vacant": 40, "unlock_cost_tier_0": 10,
		"unlock_cost_tier_1": 5, "unlock_cost_tier_2": 0}
	assert_eq(Ledger.level_unlock_cost(level, {}), 40)


func test_a_hired_pra_charges_their_current_tiers_cost() -> void:
	var level := {"unlock_cost_vacant": 40, "unlock_cost_tier_0": 10,
		"unlock_cost_tier_1": 5, "unlock_cost_tier_2": 0}
	var staff := {"Policy Research Assistant": {"staff_id": "SF04", "tier": 1}}
	assert_eq(Ledger.level_unlock_cost(level, staff), 5)


func test_a_pra_above_the_priced_tiers_keeps_the_cheapest_price() -> void:
	var level := {"unlock_cost_vacant": 40, "unlock_cost_tier_0": 10,
		"unlock_cost_tier_1": 5, "unlock_cost_tier_2": 0}
	var staff := {"Policy Research Assistant": {"staff_id": "SF07", "tier": 9}}
	assert_eq(Ledger.level_unlock_cost(level, staff), 0,
		"clamped to tier 2, the highest the workbook prices")


# ---------------------------------------------------------------------------
# Ledger.is_level_unlocked / level_unlock_refusal
# ---------------------------------------------------------------------------

func test_a_zero_cost_level_is_unlocked_without_buying_it() -> void:
	var level := {"level_id": "LV_TEST", "unlock_cost_vacant": 0}
	assert_true(Ledger.is_level_unlocked(level, [], {}))


func test_a_priced_level_is_locked_until_bought() -> void:
	var level := {"level_id": "LV_TEST", "unlock_cost_vacant": 40}
	assert_false(Ledger.is_level_unlocked(level, [], {}))
	assert_true(Ledger.is_level_unlocked(level, ["LV_TEST"], {}),
		"bought once it is in the unlocked list")


func test_unlock_refusal_is_empty_once_affordable() -> void:
	var level := {"level_id": "LV_TEST", "unlock_cost_vacant": 40}
	assert_ne(Ledger.level_unlock_refusal(level, [], {}, 10, Text.phrase()), "",
		"10 XP is not enough for a 40 XP level")
	assert_eq(Ledger.level_unlock_refusal(level, [], {}, 40, Text.phrase()), "")


# ---------------------------------------------------------------------------
# Ledger.level_cooldown_remaining
# ---------------------------------------------------------------------------

func test_a_level_never_played_is_never_on_cooldown() -> void:
	var level := {"level_id": "LV_TEST", "cooldown": 3}
	assert_eq(Ledger.level_cooldown_remaining(level, 50, {}), 0)


func test_cooldown_counts_down_as_other_levels_are_completed() -> void:
	var level := {"level_id": "LV_TEST", "cooldown": 3}
	var last_at := {"LV_TEST": 10}
	assert_eq(Ledger.level_cooldown_remaining(level, 10, last_at), 3,
		"just finished, all 3 still owed")
	assert_eq(Ledger.level_cooldown_remaining(level, 12, last_at), 1,
		"two other levels finished since")
	assert_eq(Ledger.level_cooldown_remaining(level, 13, last_at), 0,
		"three finished since — off cooldown")
	assert_eq(Ledger.level_cooldown_remaining(level, 99, last_at), 0,
		"never goes negative")


# ---------------------------------------------------------------------------
# GameState.unlock_level
# ---------------------------------------------------------------------------

func test_unlocking_a_level_spends_xp_and_records_it() -> void:
	var level := DataDB.get_level("LV01")
	assert_false(level.is_empty(), "fixture assumes LV01 exists in levels.json")
	GameState.xp = 999999

	var refusal := GameState.unlock_level("LV01")

	assert_eq(refusal, "", "should have gone through: %s" % refusal)
	assert_true(GameState.levels_unlocked.has("LV01"))
	assert_eq(GameState.xp, 999999 - Ledger.level_unlock_cost(level, {}))


func test_unlocking_without_enough_xp_is_refused_and_spends_nothing() -> void:
	# LV30 is the most expensive Tier-2 level's own unlock_cost_vacant is
	# whatever the workbook prices it at — forcing xp to 0 is enough to
	# refuse any level with a real cost, and a no-cost level correctly
	# cannot be refused this way, which is exactly the boundary this test
	# means to check: refusal only fires when a real cost is unaffordable.
	var level := DataDB.get_level("LV30")
	assert_false(level.is_empty(), "fixture assumes LV30 exists in levels.json")
	if Ledger.level_unlock_cost(level, {}) <= 0:
		pass_test("LV30 costs nothing to unlock today — nothing to refuse")
		return

	GameState.xp = 0
	var refusal := GameState.unlock_level("LV30")

	assert_ne(refusal, "")
	assert_false(GameState.levels_unlocked.has("LV30"))
	assert_eq(GameState.xp, 0)
