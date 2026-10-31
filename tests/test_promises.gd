extends GutTest
## Promises (2026-10-31): a choice's "Promise ..." commitment is owed later,
## kept from the Office (item handed over, or hours spent), or broken when it
## falls due unkept. Numbers come from the Balance tab.

const ITEM := {"kind": "promise_item", "item_id": "SH25", "within": 10, "for": "BO06"}
const HOURS := {"kind": "promise_hours", "amount": 2, "within": 10}


func before_each() -> void:
	GameState.start_new_run("PC01")
	GameState.calendar = WeekCalendar.fresh()
	GameState.booster_standing["BO06"] = 50
	GameState.inventory.erase("SH25")


func test_a_promise_is_made_not_paid() -> void:
	var funds := int(GameState.meta["Funds"])
	GameState.pay_commitments([ITEM], "A test", "")
	assert_eq(GameState.promises.size(), 1)
	assert_eq(str(GameState.promises[0]["for_org"]), "BO06")
	assert_eq(int(GameState.promises[0]["due_at"]), GameState.time_units + 10)
	assert_eq(int(GameState.meta["Funds"]), funds, "nothing is paid yet")
	assert_true(GameState.item_is_promised("SH25"))


func test_a_promise_without_an_organization_goes_to_the_choice_s_own() -> void:
	GameState.pay_commitments([HOURS], "A test", "BO12")
	assert_eq(str(GameState.promises[0]["for_org"]), "BO12")


func test_an_item_promise_is_kept_once_the_item_is_held() -> void:
	GameState.pay_commitments([ITEM], "A test", "")
	var id := str(GameState.promises[0]["id"])
	assert_ne(GameState.keep_promise(id), "", "not held yet")
	GameState.add_item("SH25")
	assert_eq(GameState.keep_promise(id), "")
	assert_eq(GameState.promises.size(), 0)
	assert_eq(GameState.item_count("SH25"), 0, "the item was handed over")
	assert_eq(int(GameState.booster_standing["BO06"]), 50 + int(DataDB.balance.get("promise_kept_standing", 1)))


func test_an_hours_promise_spends_the_hours_when_kept() -> void:
	GameState.pay_commitments([HOURS], "A test", "")
	var before := WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config())
	assert_eq(GameState.keep_promise(str(GameState.promises[0]["id"])), "")
	assert_eq(WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config()), before - 2)


func test_a_promise_falling_due_unkept_is_broken() -> void:
	var reputation := int(GameState.meta.get("Reputation", 0))
	GameState.pay_commitments([ITEM], "A test", "")
	GameState.spend_hours(11)
	assert_eq(GameState.promises.size(), 0)
	assert_eq(GameState.promises_broken_unseen.size(), 1)
	assert_eq(int(GameState.booster_standing["BO06"]), 50 + int(DataDB.balance.get("promise_broken_standing", -3)))
	assert_lte(int(GameState.meta.get("Reputation", 0)), reputation)


func test_promises_are_saved_with_the_run() -> void:
	GameState.pay_commitments([ITEM], "A test", "")
	var saved := GameState.to_save()
	assert_true(saved.has("promises"))
	assert_eq((saved["promises"] as Array).size(), 1)


func test_the_hours_left_never_go_below_zero() -> void:
	assert_eq(Promises.hours_left({"due_at": 5}, 9), 0)
	assert_eq(Promises.hours_left({"due_at": 9}, 5), 4)
