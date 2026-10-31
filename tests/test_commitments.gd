extends GutTest
## Commitments, phase 1 (2026-10-31): a choice costs hours, Funds or an item on
## the spot; it is refused when that cannot be paid, and paying takes it.

const LIST := [{"kind": "hours", "amount": 2}, {"kind": "funds", "amount": 30000}, {"kind": "item", "item_id": "SH25"}]


func before_each() -> void:
	GameState.start_new_run("PC01")
	GameState.calendar = WeekCalendar.fresh()


func test_the_totals_are_read_from_the_list() -> void:
	assert_eq(Commitments.hours(LIST), 2)
	assert_eq(Commitments.funds(LIST), 30000)
	assert_eq(Commitments.items(LIST), ["SH25"] as Array[String])
	assert_eq(Commitments.of({}), [])


func test_each_shortfall_has_its_own_reason() -> void:
	assert_eq(Commitments.refusal(LIST, 1, 99999, {"SH25": 1}), Commitments.HOURS)
	assert_eq(Commitments.refusal(LIST, 8, 100, {"SH25": 1}), Commitments.FUNDS)
	assert_eq(Commitments.refusal(LIST, 8, 99999, {}), "SH25")
	assert_eq(Commitments.refusal(LIST, 8, 99999, {"SH25": 1}), "")


func test_a_missing_item_is_named_in_words() -> void:
	GameState.meta["Funds"] = 99999
	GameState.inventory.erase("SH25")
	var why := GameState.commitment_refusal(LIST)
	assert_eq(why, Text.say("commit.refuse_item", {"item": str(DataDB.get_shop_item("SH25")["name"])}))


func test_paying_spends_the_hours_the_funds_and_the_item() -> void:
	GameState.meta["Funds"] = 100000
	GameState.add_item("SH25")
	var hours_before := WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config())
	GameState.pay_commitments(LIST)
	assert_eq(int(GameState.meta["Funds"]), 70000)
	assert_eq(GameState.item_count("SH25"), 0)
	assert_eq(WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config()), hours_before - 2)


func test_the_label_says_what_the_choice_costs() -> void:
	var label := GameState.commitment_label("Commission a study", [{"kind": "funds", "amount": 30000}])
	assert_true(label.contains("Commission a study") and label.contains("30,000"), label)
	assert_eq(GameState.commitment_label("Plain", []), "Plain")


func test_an_event_choice_with_a_commitment_is_refused_until_it_can_be_paid() -> void:
	for choice: Dictionary in DataDB.event_choices:
		var list := Commitments.of(choice)
		if Commitments.funds(list) <= 0:
			continue
		GameState.meta["Funds"] = 0
		var refused := GameState.apply_event_choice(str(choice["event_id"]), str(choice["choice"]))
		assert_false(refused["ok"], "no Funds, no choice")
		var before := Commitments.funds(list) + 5000
		GameState.meta["Funds"] = before
		var taken := GameState.apply_event_choice(str(choice["event_id"]), str(choice["choice"]))
		assert_true(taken["ok"])
		assert_lt(int(GameState.meta["Funds"]), before, "the Funds were paid")
		return
	fail_test("the workbook has no event choice that costs Funds")
