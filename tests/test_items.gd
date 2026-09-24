extends GutTest
## Items.gd — the pure rules for shop items: where one can be used, how long
## it lasts, its caps and limits, and why it cannot be bought or used. Every
## rule is a Shop-tab cell (design/proposals/inventory.md), so these check
## that each cell does what its column says, blank included.


func _item(overrides: Dictionary = {}) -> Dictionary:
	var item := {
		"item_id": "SHT", "name": "Test Item", "cost_xp": 0, "cost_yen": 0,
		"grants": [{"target": "ENERGY", "delta": 1}],
		"use_in_office": "Yes", "use_in_stage": "Yes", "duration": null,
		"uses_per_turn": null, "stack_cap": null, "purchase_limit": null,
	}
	item.merge(overrides, true)
	return item


# ---------------------------------------------------------------------------
# Where and how long
# ---------------------------------------------------------------------------

func test_yes_no_cells_read_case_insensitively_and_blank_is_no() -> void:
	assert_true(Items.is_yes("Yes"))
	assert_true(Items.is_yes(" yes "))
	assert_false(Items.is_yes("No"))
	assert_false(Items.is_yes(null), "an unfilled cell is safely No")


func test_use_in_office_and_stage_are_separate_cells() -> void:
	var office_only := _item({"use_in_stage": "No"})
	assert_true(Items.usable_in(office_only, Items.OFFICE))
	assert_false(Items.usable_in(office_only, Items.STAGE))


func test_duration_blank_is_one_stage_and_level_is_read() -> void:
	assert_eq(Items.duration(_item()), Items.DURATION_STAGE)
	assert_eq(Items.duration(_item({"duration": "Level"})), Items.DURATION_LEVEL)


func test_uses_per_turn_defaults_to_one() -> void:
	assert_eq(Items.uses_per_turn(_item()), 1, "Cameron's default: once a turn")
	assert_eq(Items.uses_per_turn(_item({"uses_per_turn": 3})), 3)


func test_blank_stack_cap_and_purchase_limit_mean_none() -> void:
	assert_eq(Items.stack_cap(_item()), 0)
	assert_eq(Items.purchase_limit(_item()), 0)


# ---------------------------------------------------------------------------
# Buying
# ---------------------------------------------------------------------------

func test_an_affordable_item_can_be_bought() -> void:
	assert_eq(Items.buy_refusal(_item({"cost_xp": 10}), 0, 0, 10, 0), "")


func test_out_of_stock_once_the_purchase_limit_is_reached() -> void:
	var item := _item({"purchase_limit": 2})
	assert_eq(Items.buy_refusal(item, 0, 1, 100, 100), "")
	assert_eq(Items.buy_refusal(item, 0, 2, 100, 100), "shop.out_of_stock")
	assert_true(Items.is_out_of_stock(item, 2))
	assert_false(Items.is_out_of_stock(item, 1))


func test_out_of_stock_is_checked_before_price() -> void:
	# A sold-out row says Out of Stock, not "10 XP short".
	var item := _item({"purchase_limit": 1, "cost_xp": 10})
	assert_eq(Items.buy_refusal(item, 0, 1, 0, 0), "shop.out_of_stock")


func test_a_full_stack_refuses_the_purchase() -> void:
	assert_eq(Items.buy_refusal(_item({"stack_cap": 3}), 3, 0, 100, 100), "shop.stack_full")


func test_either_currency_can_be_short() -> void:
	var item := _item({"cost_xp": 20, "cost_yen": 500})
	assert_eq(Items.buy_refusal(item, 0, 0, 5, 1000), "shop.xp_short")
	assert_eq(Items.buy_refusal(item, 0, 0, 50, 100), "shop.funds_short")


func test_costs_reads_both_prices() -> void:
	assert_eq(Items.costs(_item({"cost_xp": 20, "cost_yen": 500})), {"XP": 20, "Funds": 500})


# ---------------------------------------------------------------------------
# Using
# ---------------------------------------------------------------------------

func test_none_left_is_refused_first() -> void:
	assert_eq(Items.use_refusal(_item(), Items.OFFICE, 0), "item.refused.none_left")


func test_an_item_marked_no_for_this_place_is_refused() -> void:
	assert_eq(Items.use_refusal(_item({"use_in_stage": "No"}), Items.STAGE, 1), "item.refused.not_here")


func test_an_item_with_no_grants_is_refused_rather_than_used_up() -> void:
	assert_eq(Items.use_refusal(_item({"grants": null}), Items.OFFICE, 1), "item.refused.no_effect")


func test_split_grants_separates_stage_effects_from_standing() -> void:
	var item := _item({"grants": [
		{"target": "ENERGY", "delta": 1},
		{"target": "BO01", "delta": 2},
		{"target_pool": ["BO01", "BO02"], "delta": 1},
	]})
	var split := Items.split_grants(item)
	assert_eq((split["stage"] as Array).size(), 1)
	assert_eq((split["meta"] as Array).size(), 2, "a pool of boosters is standing, not a stage effect")


func test_timing_line_follows_place_and_duration() -> void:
	assert_eq(Items.timing_line(_item(), Items.OFFICE), "item.timing.stage_next")
	assert_eq(Items.timing_line(_item(), Items.STAGE), "item.timing.stage_now")
	assert_eq(Items.timing_line(_item({"duration": "Level"}), Items.OFFICE), "item.timing.level_next")
	assert_eq(Items.timing_line(_item({"duration": "Level"}), Items.STAGE), "item.timing.level_now")
	assert_eq(Items.timing_line(_item({"grants": [{"target": "BO01", "delta": 1}]}), Items.OFFICE),
		"item.timing.now", "no stage effect means it lands immediately")


func test_stage_effect_words_are_recognised_by_reward_targets() -> void:
	for token: String in RewardTargets.STAGE_EFFECT_TOKENS:
		assert_eq(RewardTargets.kind_of(token), RewardTargets.STAGE_EFFECT)
	assert_eq(RewardTargets.kind_of("energy"), RewardTargets.STAGE_EFFECT, "case-insensitive")
	assert_eq(RewardTargets.first_target({"target_pool": ["BO03", "BO04"]}), "BO03")
