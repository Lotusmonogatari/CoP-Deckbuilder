extends GutTest
## RewardTargets.gd's prefix classification, and DataDB.resolve_reward_target()
## which pulls the real record it names. Built for Office Hours' Visitor
## Reward/Penalty columns (design/proposals/office_hours.md) — a single cell
## can read "BO05 +1; M12; SH04", and nothing in that cell says which kind
## each target is; the ID prefix already does. This is the one place that
## rule is written, and the one place a SHxx target actually resolves to a
## real data/shop.json row.


# ---------------------------------------------------------------------------
# RewardTargets.kind_of() — pure prefix classification, no data access
# ---------------------------------------------------------------------------

func test_a_bo_id_is_a_booster() -> void:
	assert_eq(RewardTargets.kind_of("BO05"), RewardTargets.BOOSTER)
	assert_true(RewardTargets.is_booster("BO05"))


func test_an_sh_id_is_a_shop_item() -> void:
	assert_eq(RewardTargets.kind_of("SH04"), RewardTargets.SHOP_ITEM)
	assert_true(RewardTargets.is_shop_item("SH04"))


func test_a_bare_m_id_is_a_modifier() -> void:
	assert_eq(RewardTargets.kind_of("M12"), RewardTargets.MODIFIER)
	assert_true(RewardTargets.is_modifier("M12"))


func test_an_sg_id_is_a_segment() -> void:
	assert_eq(RewardTargets.kind_of("SG02"), RewardTargets.SEGMENT)
	assert_true(RewardTargets.is_segment("SG02"))


func test_sh_is_checked_before_the_bare_m_prefix() -> void:
	# "SH04" also starts with neither "BO" nor a modifier-shaped "M04" —
	# this just pins down that a two-letter prefix is read as a whole, not
	# as "starts with S" or any other partial match.
	assert_eq(RewardTargets.kind_of("SH04"), RewardTargets.SHOP_ITEM)


func test_sg_is_checked_before_the_bare_m_prefix_too() -> void:
	assert_eq(RewardTargets.kind_of("SG02"), RewardTargets.SEGMENT)


func test_something_with_no_digits_is_unknown() -> void:
	assert_eq(RewardTargets.kind_of("BOOSTER"), RewardTargets.UNKNOWN)
	assert_eq(RewardTargets.kind_of("Modifier"), RewardTargets.UNKNOWN)


func test_an_unrelated_prefix_is_unknown() -> void:
	assert_eq(RewardTargets.kind_of("ST04"), RewardTargets.UNKNOWN)
	assert_eq(RewardTargets.kind_of("C11"), RewardTargets.UNKNOWN)


func test_whitespace_around_the_id_does_not_matter() -> void:
	assert_eq(RewardTargets.kind_of("  BO05  "), RewardTargets.BOOSTER)


# ---------------------------------------------------------------------------
# DataDB.resolve_reward_target() — the actual "pull" from an ID
# ---------------------------------------------------------------------------

func test_resolving_a_booster_target_pulls_the_real_row() -> void:
	var resolved := DataDB.resolve_reward_target({"target": "BO01", "delta": 1})
	assert_eq(resolved["kind"], RewardTargets.BOOSTER)
	assert_eq(resolved["id"], "BO01")
	assert_eq(resolved["delta"], 1)
	assert_eq(resolved["record"], DataDB.get_booster("BO01"))
	assert_false((resolved["record"] as Dictionary).is_empty(), "BO01 is real data")


func test_resolving_a_range_delta_target_passes_the_range_through_untouched() -> void:
	# tools/export_data.py's target_delta_list now accepts a range clause
	# ("BO01 +1-6" -> {"target": "BO01", "delta": {"min": 1, "max": 6}}).
	# Rolling that range into a real number is the applying code's job
	# (mirroring BattleSetup._opponent_count()) — nothing built yet touches
	# it — so this only proves resolve_reward_target() carries the shape
	# through opaque and unmodified, the same as it does an int or null.
	var resolved := DataDB.resolve_reward_target({"target": "BO01", "delta": {"min": 1, "max": 6}})
	assert_eq(resolved["kind"], RewardTargets.BOOSTER)
	assert_eq(resolved["delta"], {"min": 1, "max": 6})


func test_resolving_a_modifier_target_pulls_the_real_row() -> void:
	var resolved := DataDB.resolve_reward_target({"target": "M01", "delta": null})
	assert_eq(resolved["kind"], RewardTargets.MODIFIER)
	assert_null(resolved["delta"], "a modifier grant has no magnitude")
	assert_eq(resolved["record"], DataDB.get_modifier("M01"))
	assert_false((resolved["record"] as Dictionary).is_empty(), "M01 is real data")


func test_resolving_a_shop_item_target_pulls_the_real_row() -> void:
	# The point of this whole file: data/shop.json existed on disk but
	# nothing loaded it before 2026-09-25 — this is the actual "pull".
	var resolved := DataDB.resolve_reward_target({"target": "SH01", "delta": null})
	assert_eq(resolved["kind"], RewardTargets.SHOP_ITEM)
	assert_eq(resolved["record"], DataDB.get_shop_item("SH01"))
	assert_false((resolved["record"] as Dictionary).is_empty(), "SH01 is real data")


func test_resolving_a_segment_target_pulls_the_real_row() -> void:
	var resolved := DataDB.resolve_reward_target({"target": "SG02", "delta": 3})
	assert_eq(resolved["kind"], RewardTargets.SEGMENT)
	assert_eq(resolved["record"], DataDB.get_segment("SG02"))
	assert_false((resolved["record"] as Dictionary).is_empty(), "SG02 is real data")


func test_resolving_an_unknown_target_comes_back_empty_not_broken() -> void:
	var resolved := DataDB.resolve_reward_target({"target": "XY99", "delta": 3})
	assert_eq(resolved["kind"], RewardTargets.UNKNOWN)
	assert_true((resolved["record"] as Dictionary).is_empty())


func test_shop_json_is_actually_loaded() -> void:
	# Regression guard for the gap this file closes: shop.json existed on
	# disk with 29 real items and nothing ever read it.
	assert_gt(DataDB.shop.size(), 0, "data/shop.json should be loaded")


# ---------------------------------------------------------------------------
# BOOSTER_TIER (design/proposals/inventory.md, 2026-09-25 follow-up) — a
# "TIER:Party" target resolves to every current Party-tier booster, read
# live, rather than a fixed list a workbook edit could fall out of sync with.
# ---------------------------------------------------------------------------

func test_resolving_a_tier_target_lists_every_booster_of_that_tier() -> void:
	var resolved := DataDB.resolve_reward_target({"target": "TIER:Party", "delta": 1})
	assert_eq(resolved["kind"], RewardTargets.BOOSTER_TIER)
	var record: Dictionary = resolved["record"]
	assert_eq(record["tier"], "Party")
	var ids: Array = []
	for booster: Dictionary in (record["boosters"] as Array):
		ids.append(booster.get("booster_id"))
	assert_eq(ids, DataDB.boosters_for_tier("Party").map(
		func(b: Dictionary) -> String: return str(b.get("booster_id"))))
	assert_gt(ids.size(), 0, "sanity: Party has real boosters")


func test_boosters_for_tier_only_returns_that_tier() -> void:
	for booster: Dictionary in DataDB.boosters_for_tier("National"):
		assert_eq(booster.get("tier"), "National")
