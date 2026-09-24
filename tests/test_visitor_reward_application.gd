extends GutTest
## GameState.apply_visitor_reward_entries() — resolving and applying the raw
## target_delta_list OfficeHoursEngine.answer() hands back (Reward on a
## correct answer, Penalty on a wrong one). GameState is an autoload, so
## these put booster_standing/owned_modifiers back the way they found them,
## the same discipline test_game_state_spending.gd already uses.

var _owned_before: Array[String] = []
var _standing_before: Dictionary = {}
var _favorability_before: Dictionary = {}
var _inventory_before: Dictionary = {}
var _pending_before: Dictionary = {}
var _shop_before: Array = []


func before_each() -> void:
	_owned_before = GameState.owned_modifiers.duplicate()
	_standing_before = GameState.booster_standing.duplicate(true)
	_favorability_before = GameState.segment_favorability.duplicate(true)
	_inventory_before = GameState.inventory.duplicate()
	_pending_before = GameState.pending_stage_bonuses.duplicate()
	_shop_before = DataDB.shop.duplicate(true)


func after_each() -> void:
	GameState.owned_modifiers = _owned_before.duplicate()
	GameState.booster_standing = _standing_before.duplicate(true)
	GameState.segment_favorability = _favorability_before.duplicate(true)
	GameState.inventory = _inventory_before.duplicate()
	GameState.pending_stage_bonuses = _pending_before.duplicate()
	DataDB.shop = _shop_before.duplicate(true)
	DataDB._build_lookups()   # DataDB.shop's own index (_shop_by_id) has to follow it back


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


func test_an_empty_list_does_nothing() -> void:
	var before := GameState.booster_standing.duplicate(true)
	var before_owned := GameState.owned_modifiers.duplicate()
	GameState.apply_visitor_reward_entries([])
	assert_eq(GameState.booster_standing, before)
	assert_eq(GameState.owned_modifiers, before_owned)


# ---------------------------------------------------------------------------
# Segment entries (SGxx) — added 2026-09-25 alongside the Shop "Grants"
# column, the same clamp GameState._apply_staff_reward() already used for
# its own SGxx targets, now reusable through the shared apply path.
# ---------------------------------------------------------------------------

func test_a_segment_delta_moves_favorability_by_exactly_that_amount() -> void:
	GameState.segment_favorability["SG02"] = 50
	GameState.apply_visitor_reward_entries([{"target": "SG02", "delta": 4}])
	assert_eq(int(GameState.segment_favorability["SG02"]), 54)


func test_a_negative_segment_delta_is_a_real_penalty() -> void:
	GameState.segment_favorability["SG02"] = 50
	GameState.apply_visitor_reward_entries([{"target": "SG02", "delta": -6}])
	assert_eq(int(GameState.segment_favorability["SG02"]), 44)


func test_a_segment_delta_is_clamped_0_to_100() -> void:
	GameState.segment_favorability["SG02"] = 98
	GameState.apply_visitor_reward_entries([{"target": "SG02", "delta": 50}])
	assert_eq(int(GameState.segment_favorability["SG02"]), 100)

	GameState.segment_favorability["SG02"] = 2
	GameState.apply_visitor_reward_entries([{"target": "SG02", "delta": -50}])
	assert_eq(int(GameState.segment_favorability["SG02"]), 0)


# ---------------------------------------------------------------------------
# Shop item entries (SHxx). Cameron, 2026-09-25: a visitor's item reward goes
# INTO THE INVENTORY, the same as buying one, for one consistent place items
# land — it is used later from the inventory, not applied on the spot.
# ---------------------------------------------------------------------------

func test_a_shop_item_reward_goes_into_the_inventory() -> void:
	GameState.inventory.erase("SH04")
	GameState.apply_visitor_reward_entries([{"target": "SH04", "delta": null}])
	assert_eq(GameState.item_count("SH04"), 1)


func test_a_shop_item_reward_with_a_delta_gives_that_many() -> void:
	GameState.inventory.erase("SH04")
	GameState.apply_visitor_reward_entries([{"target": "SH04", "delta": 3}])
	assert_eq(GameState.item_count("SH04"), 3)


func test_a_shop_item_reward_does_not_apply_its_grants() -> void:
	# SH04 Coffee grants ENERGY +1 — that belongs to USING it, not getting it.
	GameState.inventory.erase("SH04")
	GameState.pending_stage_bonuses = {}
	GameState.apply_visitor_reward_entries([{"target": "SH04", "delta": null}])
	assert_eq(GameState.pending_stage_bonuses, {})


func test_a_shop_item_reward_respects_the_stack_cap() -> void:
	# SH20 (Extra Draw) has a Stack Cap of 2 in the real workbook.
	GameState.inventory["SH20"] = 1
	GameState.apply_visitor_reward_entries([{"target": "SH20", "delta": 5}])
	assert_eq(GameState.item_count("SH20"), 2, "a gift beyond the cap is lost, not banked")


func test_a_stage_effect_reward_waits_for_the_next_stage() -> void:
	GameState.pending_stage_bonuses = {}
	GameState.apply_visitor_reward_entries([{"target": "ENERGY", "delta": 2}])
	assert_eq(int(GameState.pending_stage_bonuses.get("ENERGY", 0)), 2)


func test_a_pooled_reward_moves_exactly_one_booster_from_the_pool() -> void:
	for _i in 20:
		GameState.booster_standing["BO01"] = 50
		GameState.booster_standing["BO02"] = 50
		GameState.booster_standing["BO03"] = 50
		GameState.apply_visitor_reward_entries([{"target_pool": ["BO01", "BO02"], "delta": 4}])
		var moved := int(GameState.booster_standing["BO01"]) + int(GameState.booster_standing["BO02"]) - 100
		assert_eq(moved, 4, "exactly one of the pool gained 4")
		assert_eq(int(GameState.booster_standing["BO03"]), 50, "nothing outside the pool moved")
