extends GutTest
## GameState.apply_visitor_reward_entries() — resolving and applying the raw
## target_delta_list OfficeHoursEngine.answer() hands back (Reward on a
## correct answer, Penalty on a wrong one). GameState is an autoload, so
## these put booster_standing/owned_modifiers back the way they found them,
## the same discipline test_game_state_spending.gd already uses.

var _owned_before: Array[String] = []
var _standing_before: Dictionary = {}


func before_each() -> void:
	_owned_before = GameState.owned_modifiers.duplicate()
	_standing_before = GameState.booster_standing.duplicate(true)


func after_each() -> void:
	GameState.owned_modifiers = _owned_before.duplicate()
	GameState.booster_standing = _standing_before.duplicate(true)


# ---------------------------------------------------------------------------
# Booster entries
# ---------------------------------------------------------------------------

func test_a_fixed_booster_delta_moves_standing_by_exactly_that_amount() -> void:
	GameState.booster_standing["BO01"] = 50
	GameState.apply_visitor_reward_entries([{"target": "BO01", "delta": 4}])
	assert_eq(int(GameState.booster_standing["BO01"]), 54)


func test_a_negative_booster_delta_is_a_real_penalty() -> void:
	GameState.booster_standing["BO01"] = 50
	GameState.apply_visitor_reward_entries([{"target": "BO01", "delta": -6}])
	assert_eq(int(GameState.booster_standing["BO01"]), 44)


func test_a_booster_delta_is_clamped_to_the_ceiling() -> void:
	var high := int(DataDB.booster_standing.get("max", 100))
	GameState.booster_standing["BO01"] = high - 2
	GameState.apply_visitor_reward_entries([{"target": "BO01", "delta": 50}])
	assert_eq(int(GameState.booster_standing["BO01"]), high)


func test_a_booster_delta_is_clamped_to_the_floor() -> void:
	var low := int(DataDB.booster_standing.get("min", 0))
	GameState.booster_standing["BO01"] = low + 2
	GameState.apply_visitor_reward_entries([{"target": "BO01", "delta": -50}])
	assert_eq(int(GameState.booster_standing["BO01"]), low)


func test_a_range_delta_rolls_within_its_own_bounds() -> void:
	GameState.booster_standing["BO01"] = 50
	for _i in 20:
		GameState.booster_standing["BO01"] = 50
		GameState.apply_visitor_reward_entries([{"target": "BO01", "delta": {"min": 1, "max": 3}}])
		assert_between(int(GameState.booster_standing["BO01"]), 51, 53)


# ---------------------------------------------------------------------------
# Modifier entries
# ---------------------------------------------------------------------------

func test_a_modifier_entry_grants_it() -> void:
	GameState.owned_modifiers.erase("M01")
	GameState.apply_visitor_reward_entries([{"target": "M01", "delta": null}])
	assert_true(GameState.owned_modifiers.has("M01"))


func test_a_modifier_already_owned_is_not_granted_twice() -> void:
	GameState.owned_modifiers = ["M01"]
	GameState.apply_visitor_reward_entries([{"target": "M01", "delta": null}])
	assert_eq(GameState.owned_modifiers.count("M01"), 1,
		"answering two visitors who both reward the same modifier should not duplicate it")


# ---------------------------------------------------------------------------
# Mixed lists, unknowns, and shop items (still an open, undecided apply)
# ---------------------------------------------------------------------------

func test_a_mixed_list_applies_every_entry() -> void:
	GameState.booster_standing["BO01"] = 50
	GameState.owned_modifiers.erase("M01")
	GameState.apply_visitor_reward_entries([
		{"target": "BO01", "delta": 2},
		{"target": "M01", "delta": null},
	])
	assert_eq(int(GameState.booster_standing["BO01"]), 52)
	assert_true(GameState.owned_modifiers.has("M01"))


func test_an_unresolvable_target_does_not_crash_the_rest_of_the_list() -> void:
	GameState.booster_standing["BO01"] = 50
	GameState.apply_visitor_reward_entries([
		{"target": "XY99", "delta": 5},
		{"target": "BO01", "delta": 2},
	])
	assert_eq(int(GameState.booster_standing["BO01"]), 52,
		"one bad entry should not stop the rest of the list from applying")


func test_a_shop_item_entry_does_not_crash_and_touches_nothing_else() -> void:
	# Open point 1, design/proposals/office_hours.md: what granting a shop
	# item does is undecided. This only proves it fails safe — no crash, and
	# no side effect on the booster/modifier state around it — not that it
	# does the "right" thing, because nothing has said what that is yet.
	GameState.booster_standing["BO01"] = 50
	GameState.apply_visitor_reward_entries([
		{"target": "SH01", "delta": null},
		{"target": "BO01", "delta": 2},
	])
	assert_eq(int(GameState.booster_standing["BO01"]), 52)


func test_an_empty_list_does_nothing() -> void:
	var before := GameState.booster_standing.duplicate(true)
	var before_owned := GameState.owned_modifiers.duplicate()
	GameState.apply_visitor_reward_entries([])
	assert_eq(GameState.booster_standing, before)
	assert_eq(GameState.owned_modifiers, before_owned)
