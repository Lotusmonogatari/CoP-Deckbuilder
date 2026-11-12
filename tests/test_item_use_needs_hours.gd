extends GutTest
## An Office item that takes hours (the dinner SH19, the walking tour SH20)
## cannot be used when there is no time, and its pop-up says so on a greyed
## Use button (2026-11-12, Cameron).

var _calendar_before: Dictionary = {}


func before_each() -> void:
	_calendar_before = GameState.calendar.duplicate(true)
	GameState.calendar = WeekCalendar.fresh()


func after_each() -> void:
	GameState.calendar = _calendar_before


func _fill_the_work_week() -> void:
	GameState.calendar = WeekCalendar.advance(GameState.calendar,
		WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config()),
		GameState.calendar_config())


func test_the_dinner_can_be_used_when_there_is_time() -> void:
	assert_eq(GameState.item_hours_refusal(DataDB.get_shop_item("SH19")), "")


func test_the_dinner_and_the_tour_are_refused_when_the_week_is_full() -> void:
	_fill_the_work_week()
	assert_true(GameState.work_week_is_full())
	for item_id: String in ["SH19", "SH20"]:
		assert_eq(GameState.item_hours_refusal(DataDB.get_shop_item(item_id)), Text.say("item.refuse_week_over"))


func test_an_item_that_takes_no_hours_is_never_refused_for_time() -> void:
	_fill_the_work_week()
	assert_eq(GameState.item_hours_refusal(DataDB.get_shop_item("SH04")), "", "a coffee takes no time")


func test_the_pop_up_greys_the_use_button_and_says_why() -> void:
	_fill_the_work_week()
	var saved := GameState.inventory.duplicate()
	GameState.inventory["SH19"] = 1
	var panel := InventoryPanel.new()
	add_child_autofree(panel)
	panel.context = Items.OFFICE
	panel.show_item("SH19")
	var confirm: Button = panel._confirm
	assert_true(confirm.visible, "the button is still there")
	assert_true(confirm.disabled, "but cannot be pressed")
	assert_eq(confirm.text, Text.say("item.refuse_week_over"))
	GameState.inventory = saved


func test_with_time_the_use_button_is_live() -> void:
	var saved := GameState.inventory.duplicate()
	GameState.inventory["SH19"] = 1
	var panel := InventoryPanel.new()
	add_child_autofree(panel)
	panel.context = Items.OFFICE
	panel.show_item("SH19")
	assert_false(panel._confirm.disabled)
	assert_eq(panel._confirm.text, Text.say("item.use"))
	GameState.inventory = saved
