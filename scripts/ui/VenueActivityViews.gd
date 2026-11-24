class_name VenueActivityViews
extends RefCounted
## The card for one costed venue activity (2026-11-24): its name, what it costs and gives before it is done, how many times are left
## today, how often it was done (only where it has gifts, which stay a surprise), and a button that does it or says why it cannot.
## Draws what GameState tells it; nothing here decides a rule. Every sentence is a Text row or the workbook's own result text.


## One card. `on_do` is called with the activity ID when the button is pressed.
static func card(look: Dictionary, activity: Dictionary, on_do: Callable) -> PanelContainer:
	var id := str(activity.get("activity_id", ""))
	var card := OfficeFrameStyles.card(look, str(activity.get("name", id)))
	card.name = "ActivityCard_" + id
	var column := card.get_node("Column") as VBoxContainer
	var built := VenueRules.is_built(activity)
	if built:
		var cost := cost_text(activity)
		column.add_child(_line("ActCost", Text.say("venue.act_costs", {"list": cost}) if not cost.is_empty() else Text.say("venue.act_free")))
		var gives := GameState.activity_gives_lines(activity)
		if not gives.is_empty():
			column.add_child(_line("ActGives", Text.say("venue.act_gives", {"list": ", ".join(PackedStringArray(gives))})))
		elif VenueActivities.has_milestones(DataDB.venue_milestones, id):
			column.add_child(_line("ActGives", Text.say("venue.act_counted")))
		var left := GameState.activity_left_today(id)
		if left >= 0:
			column.add_child(_line("ActLeft", Text.say("venue.act_left", {"count": left, "limit": int(activity.get("per_day", 0))})))
		if VenueActivities.has_milestones(DataDB.venue_milestones, id):
			column.add_child(_line("ActTimes", Text.say("venue.act_times", {"count": GameState.activity_times_done(id)})))
	var why := GameState.activity_refusal(id)
	var button := Button.new()
	button.name = "Activity_" + id
	button.custom_minimum_size = Vector2(0, OfficeFrameStyles.touch_height())
	button.text = Text.say("venue.act_do") if why.is_empty() else why
	button.disabled = not why.is_empty()
	OfficeFrameStyles.dress_card_button(button, look, why.is_empty())
	if why.is_empty():
		button.pressed.connect(on_do.bind(id))
	column.add_child(button)
	return card


## "2 h · 15,000円", or "" for an activity that is free.
static func cost_text(activity: Dictionary) -> String:
	var cost := VenueRules.visit_cost(activity)
	var parts: Array[String] = []
	if int(cost["hours"]) > 0:
		parts.append(Text.say("venue.cost_hours", {"count": int(cost["hours"])}))
	if int(cost["funds"]) > 0:
		parts.append(Text.say("venue.cost_funds", {"count": int(cost["funds"])}))
	return " · ".join(PackedStringArray(parts))


static func _line(node_name: String, text: String) -> Label:
	var label := UiKit.line(text, "SmallLabel")
	label.name = node_name
	label.custom_minimum_size.x = 0.0
	return label
