extends GutTest
## Rhetoric Training takes time (2026-11-23, Cameron): one hour per tier, taken when a session begins, a coupon's session included.

var _calendar_before: Dictionary = {}
var _xp_before := 0
var _owned_before: Array = []


func before_each() -> void:
	_calendar_before = GameState.calendar.duplicate(true)
	_xp_before = GameState.xp
	_owned_before = GameState.owned_cards.duplicate()
	GameState.calendar = WeekCalendar.fresh()
	GameState.xp = 100000
	GameState.card_draw = {}
	GameState.inventory = {}
	GameState.shop_bought_this_level = {}


func after_each() -> void:
	GameState.calendar = _calendar_before
	GameState.xp = _xp_before
	GameState.owned_cards.assign(_owned_before)
	GameState.card_draw = {}
	GameState.inventory = {}


func _left() -> int:
	return WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config())


func test_a_session_takes_one_hour_per_tier() -> void:
	assert_eq(GameState.training_hours(1), 1)
	assert_eq(GameState.training_hours(2), 2)
	assert_eq(GameState.training_hours(3), 3)
	assert_eq(GameState.training_hours(0), 0)


func test_starting_a_session_takes_its_hours_once() -> void:
	for item_id: String in ["SH09", "SH10", "SH11"]:
		GameState.calendar = WeekCalendar.fresh()
		GameState.card_draw = {}
		if GameState._unowned_cards_at_tier(int(DataDB.get_shop_item(item_id)["card_tier"])).is_empty():
			continue
		var before := _left()
		var tier := int(DataDB.get_shop_item(item_id)["card_tier"])
		assert_true(GameState.offer_random_card(item_id)["ok"], item_id)
		assert_eq(before - _left(), tier, "%s takes %d hour(s)" % [item_id, tier])
		# Seeing the same session again, or passing on a card, takes nothing more.
		var after_start := _left()
		GameState.offer_random_card(item_id)
		assert_eq(_left(), after_start, "reopening the draw costs no hours")
		if GameState.can_pass_offered_card():
			GameState.pass_offered_card()
			assert_eq(_left(), after_start, "passing on a card costs no hours")
		GameState.card_draw = {}


func test_a_session_is_refused_with_a_reason_when_there_is_no_time() -> void:
	var cfg := GameState.calendar_config()
	GameState.calendar = WeekCalendar.advance(GameState.calendar, _left() - 1, cfg)
	assert_eq(_left(), 1)
	assert_eq(GameState.card_training_refusal("SH09"), "", "one hour left is enough for Tier 1")
	if not GameState._unowned_cards_at_tier(3).is_empty():
		assert_eq(GameState.card_training_refusal("SH11"), Text.say("item.refuse_hours"), "Tier 3 needs three")
		var result := GameState.offer_random_card("SH11")
		assert_false(result["ok"])
		assert_true(GameState.card_draw.is_empty(), "nothing started")
		assert_eq(_left(), 1, "and no hours were taken")
	GameState.calendar = WeekCalendar.advance(GameState.calendar, _left(), cfg)
	assert_eq(GameState.card_training_refusal("SH09"), Text.say("item.refuse_week_over"), "a full week refuses")


func test_a_coupon_session_takes_the_tier_hours_too() -> void:
	var tier := int(DataDB.get_shop_item("SH21")["free_card_tier"])
	if GameState._unowned_cards_at_tier(tier).is_empty():
		pending("no unowned card at the coupon's tier")
		return
	GameState.add_item("SH21")
	assert_eq(GameState.item_hours_refusal(DataDB.get_shop_item("SH21")), "")
	var before := _left()
	var result := GameState.use_item_in_office("SH21")
	assert_true(result["ok"])
	assert_eq(before - _left(), GameState.training_hours(tier))
	GameState.card_draw = {}
	GameState.add_item("SH21")
	GameState.calendar = WeekCalendar.advance(GameState.calendar, _left(), GameState.calendar_config())
	assert_eq(GameState.item_hours_refusal(DataDB.get_shop_item("SH21")), Text.say("item.refuse_week_over"), "no time, no coupon session")


func test_the_session_row_names_its_hours() -> void:
	assert_eq(Text.say("rhetoric.session_one", {"tier": 1, "price": "250 XP"}), "Tier 1 session  —  250 XP  —  1 hour")
	assert_eq(Text.say("rhetoric.session", {"tier": 2, "price": "500 XP", "hours": 2}), "Tier 2 session  —  500 XP  —  2 hours")
