extends GutTest
## Resigning (2026-11-11, Cameron): the button's three-way condition lives in
## Balance rows, and resigning ends the run without touching a real save.

var _saved_run: Dictionary = {}
var _awaiting_before := false


func before_each() -> void:
	_saved_run = GameState.to_save()
	_awaiting_before = GameState.awaiting_new_game


func after_each() -> void:
	GameState.load_save(_saved_run)
	GameState.awaiting_new_game = _awaiting_before


func _meta(reputation: int, party: int, constituency: int) -> Dictionary:
	return {"Reputation": reputation, "Party support": party, "Constituency support": constituency}


func test_all_three_below_their_lines_allows_resigning() -> void:
	assert_true(ResignRules.available(_meta(9, 19, 19), DataDB.balance))


func test_any_one_at_or_above_its_line_forbids_it() -> void:
	assert_false(ResignRules.available(_meta(10, 19, 19), DataDB.balance), "Reputation 10")
	assert_false(ResignRules.available(_meta(9, 20, 19), DataDB.balance), "Party support 20")
	assert_false(ResignRules.available(_meta(9, 19, 20), DataDB.balance), "Constituency support 20")


func test_the_lines_come_from_the_balance_rows() -> void:
	var balance := {"resign_reputation_below": 50, "resign_party_support_below": 50,
		"resign_constituency_support_below": 50}
	assert_true(ResignRules.available(_meta(49, 49, 49), balance))
	assert_false(ResignRules.available(_meta(49, 49, 50), balance))


func test_resigning_ends_the_run_and_stops_saving() -> void:
	GameState.resign_run()
	assert_true(GameState.awaiting_new_game, "nothing saves until a new run starts")
	assert_false(GameState.is_in_level())


func test_the_button_is_crimson_with_black_text() -> void:
	var button := ResignScreen.button(func() -> void: pass)
	var box := button.get_theme_stylebox("normal") as StyleBoxFlat
	assert_eq(box.bg_color, ResignScreen.CRIMSON)
	assert_eq(box.border_color, ResignScreen.CRIMSON)
	assert_eq(button.get_theme_color("font_color"), Color.BLACK)
	button.free()
