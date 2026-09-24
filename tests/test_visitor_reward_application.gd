extends GutTest
## GameState.apply_visitor_reward_entries() — resolving and applying the raw
## target_delta_list OfficeHoursEngine.answer() hands back (Reward on a
## correct answer, Penalty on a wrong one). GameState is an autoload, so
## these put booster_standing/owned_modifiers back the way they found them,
## the same discipline test_game_state_spending.gd already uses.

var _owned_before: Array[String] = []
var _standing_before: Dictionary = {}
var _favorability_before: Dictionary = {}
var _owned_items_before: Array[String] = []
var _shop_before: Array = []


func before_each() -> void:
	_owned_before = GameState.owned_modifiers.duplicate()
	_standing_before = GameState.booster_standing.duplicate(true)
	_favorability_before = GameState.segment_favorability.duplicate(true)
	_owned_items_before = GameState.owned_shop_items.duplicate()
	_shop_before = DataDB.shop.duplicate(true)


func after_each() -> void:
	GameState.owned_modifiers = _owned_before.duplicate()
	GameState.booster_standing = _standing_before.duplicate(true)
	GameState.segment_favorability = _favorability_before.duplicate(true)
	GameState.owned_shop_items = _owned_items_before.duplicate()
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
# Shop item entries (SHxx) — open point 1, design/proposals/office_hours.md,
# answered 2026-09-25: granting IS using it (no purchase/inventory screen
# exists), so it lands on owned_shop_items and its own "Grants" list applies
# immediately, through the very same apply path.
# ---------------------------------------------------------------------------

func test_a_shop_item_with_no_grants_is_just_recorded_as_owned() -> void:
	# Every real shop.json row today: the "Grants" column exists but is
	# blank (null, not absent — see _grant_shop_item()'s own comment).
	GameState.owned_shop_items.erase("SH01")
	GameState.booster_standing["BO01"] = 50
	GameState.apply_visitor_reward_entries([{"target": "SH01", "delta": null}])
	assert_true(GameState.owned_shop_items.has("SH01"))
	assert_eq(int(GameState.booster_standing["BO01"]), 50, "nothing to apply, so nothing moved")


func test_a_shop_item_already_owned_is_not_recorded_twice() -> void:
	GameState.owned_shop_items = ["SH01"]
	GameState.apply_visitor_reward_entries([{"target": "SH01", "delta": null}])
	assert_eq(GameState.owned_shop_items.count("SH01"), 1)


func test_a_shop_items_own_grants_apply_when_it_is_granted() -> void:
	# Injects a fake SH99 with a real "grants" list — every actual row today
	# has none, so this is what proves the recursive apply actually works,
	# not just that it's wired to a permanently-empty case.
	DataDB.shop.append({"item_id": "SH99", "grants": [{"target": "BO01", "delta": 3}]})
	DataDB._build_lookups()

	GameState.booster_standing["BO01"] = 50
	GameState.owned_shop_items.erase("SH99")
	GameState.apply_visitor_reward_entries([{"target": "SH99", "delta": null}])

	assert_true(GameState.owned_shop_items.has("SH99"))
	assert_eq(int(GameState.booster_standing["BO01"]), 53)


func test_a_shop_item_cannot_grant_a_second_shop_item() -> void:
	# The one hard rule (not a depth limit): granting SH98 must not chase
	# into SH97, which would be an infinite loop the moment two items ever
	# named each other. SH97 should be recorded as owned SH98's own effect
	# names it, per the current rule, but its OWN grants (a real booster
	# move) must NOT apply, since a shop item's grants may only move
	# boosters/modifiers/segments, never another item.
	DataDB.shop.append({"item_id": "SH98", "grants": [{"target": "SH97", "delta": null}]})
	DataDB.shop.append({"item_id": "SH97", "grants": [{"target": "BO01", "delta": 9}]})
	DataDB._build_lookups()

	GameState.booster_standing["BO01"] = 50
	GameState.owned_shop_items = GameState.owned_shop_items.filter(
		func(id: String) -> bool: return id != "SH98" and id != "SH97")
	GameState.apply_visitor_reward_entries([{"target": "SH98", "delta": null}])

	assert_true(GameState.owned_shop_items.has("SH98"), "SH98 itself was granted")
	assert_false(GameState.owned_shop_items.has("SH97"),
		"SH98's grants named SH97, but that should be refused, not chased")
	assert_eq(int(GameState.booster_standing["BO01"]), 50,
		"SH97's own booster move should never have run")
