extends GutTest
## Two small findings of the P13 review (2026-11-20), fixed: money placeholders are written with thousands separators, and the
## Resign button's text reads on its crimson fill at 4.5 to 1 or better.


func test_a_staff_wage_is_written_with_a_thousands_separator() -> void:
	assert_eq(Text.say("staff.summary", {"word": "Steady", "yen": 6000}), "Steady · wage 6,000円 a week")
	assert_eq(Text.say("staff.summary", {"word": "Steady", "yen": 450}), "Steady · wage 450円 a week", "under a thousand stays plain")


func test_the_other_money_placeholders_get_separators_too() -> void:
	assert_eq(Text.say("staff.week_paid", {"yen": 12500}), "Staff wages paid: 12,500円.")
	assert_eq(Text.say("draft.cost", {"xp": 40, "funds": 25000}), "Drafting needs 40 PC and 25,000円.")
	assert_eq(Text.say("office.week_cost_relief", {"yen": 50000}), "National awareness has already taken 50,000円 off.")


func test_a_value_already_written_with_separators_is_left_alone() -> void:
	assert_eq(Text.say("staff.week_paid", {"yen": "12,500"}), "Staff wages paid: 12,500円.")


func test_the_resign_button_text_reads_on_crimson() -> void:
	var button := Button.new()
	autofree(button)
	ResignScreen.style_crimson(button)
	var ink := button.get_theme_color("font_color")
	assert_gte(IntentPill.contrast(ink, ResignScreen.CRIMSON), 4.5, "white on crimson")
	for state: String in ["font_hover_color", "font_pressed_color", "font_focus_color"]:
		assert_eq(button.get_theme_color(state), ink, state + " matches")


func test_the_three_ticket_items_have_their_icons_and_the_train_events_their_six_pictures() -> void:
	for item_id: String in ["SH42", "SH43", "SH44"]:
		var icon := str(DataDB.get_shop_item(item_id).get("icon", ""))
		assert_ne(icon, "", item_id + " names an icon")
		assert_true(FileAccess.file_exists("res://assets/icons/%s.png" % icon), item_id + "'s icon file exists")
	for event_id: String in ["EV105", "EV106", "EV107", "EV108", "EV109", "EV110"]:
		var pictures := EventPicture.options(GameState.get_event(event_id).get("image"))
		assert_eq(pictures.size(), 6, event_id + " lists six train pictures")
		for picture: String in pictures:
			assert_true(FileAccess.file_exists("res://assets/backgrounds/%s.png" % picture), picture + " exists")
