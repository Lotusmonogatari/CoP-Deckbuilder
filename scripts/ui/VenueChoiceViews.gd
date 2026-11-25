class_name VenueChoiceViews
extends RefCounted
## The cards of the Cafeteria's seat and meal screens (2026-11-25): a name, what the seat or meal is, what it gives for sure, the odds of an extra
## and what it may give, and a button. Draws what GameState tells it; nothing here decides a rule. Every sentence is a Text row or the
## workbook's own words.


## One card for a Venue Choices row. `button_text` is "Sit here" or "Order this"; `on_pick` is called with the choice ID.
static func card(look: Dictionary, row: Dictionary, button_text: String, on_pick: Callable) -> PanelContainer:
	var id := str(row.get("choice_id", ""))
	var card := OfficeFrameStyles.card(look, GameState.choice_name(row))
	card.name = "Choice_" + id
	var column := card.get_node("Column") as VBoxContainer
	column.add_child(_line("ChoiceBlurb", GameState.choice_blurb(row)))
	var sure := GameState.choice_sure_lines(row)
	var odds := GameState.chance_line(row)
	if not sure.is_empty():
		column.add_child(_line("ChoiceGives", Text.say("choice.gives", {"list": ", ".join(PackedStringArray(sure))})))
	elif odds.is_empty():
		column.add_child(_line("ChoiceGives", Text.say("choice.gives_nothing")))
	if not odds.is_empty():
		column.add_child(_line("ChoiceChance", odds))
	var pick := Button.new()
	pick.name = "Pick_" + id
	pick.custom_minimum_size = Vector2(0, OfficeFrameStyles.touch_height())
	pick.text = button_text
	OfficeFrameStyles.dress_card_button(pick, look, true)
	pick.pressed.connect(on_pick.bind(id))
	column.add_child(pick)
	return card


static func _line(node_name: String, text: String) -> Label:
	var label := UiKit.line(text, "SmallLabel")
	label.name = node_name
	label.custom_minimum_size.x = 0.0
	return label
