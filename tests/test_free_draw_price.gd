extends GutTest
## The Learn it button on a free Training Session Coupon draw says Free, not an XP price (2026-11-18).


func test_a_coupon_draw_is_free_and_a_paid_session_is_not() -> void:
	var coupon := DataDB.get_shop_item(str(DataDB.get_rule("training_coupon_item", "")))
	assert_false(coupon.is_empty(), "the coupon item exists")
	assert_true(GameState.draw_is_free(coupon))
	var paid := {"item_id": "X", "card_tier": 1, "cost_xp": 150}
	assert_false(GameState.draw_is_free(paid))
