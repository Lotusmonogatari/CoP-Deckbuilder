class_name EventsView
extends RefCounted
## Draws the Events screen (P13, 2026-11-20) from EventsModel's data: the Decision! banner for a dated event coming up (never a
## buy row: it has no price and no button), and one card for every event that can be arranged here with its location badge,
## its cost and hours, the reason in red when it cannot be arranged now, and an "Arrange it" button (greyed then). Draws
## only: it reads no game state.


## The red banner for one dated event coming up: its kind tag, day, office and hours, the title and one line. It is set by
## the calendar, so it has no price and no button.
static func decision_banner(look: Dictionary, event: Dictionary) -> Control:
	var card := OfficeFrameStyles.danger_card(look, Text.say("event.decision_banner"))
	card.name = "Decision_" + str(event["event_id"])
	var column := card.get_node("Column") as VBoxContainer
	var meta := UiKit.line(str(event["meta"]), "SmallLabel")
	meta.custom_minimum_size.x = 0.0
	column.add_child(meta)
	var title := Label.new()
	title.name = "DecisionTitle"
	title.text = str(event["title"])
	title.theme_type_variation = "HeaderLabel"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(title)
	for text: String in [str(event["flavor"]), str(event["moves"])]:
		if not text.is_empty():
			var line := UiKit.line(text, "SmallLabel")
			line.custom_minimum_size.x = 0.0
			column.add_child(line)
	return card


## One event that can be arranged here. `on_arrange` is called with the event's id when Arrange it is pressed (never when
## it is greyed).
static func event_card(look: Dictionary, event: Dictionary, on_arrange: Callable) -> Control:
	var card := OfficeFrameStyles.card(look)
	card.name = "EventCard_" + str(event["event_id"])
	var column := card.get_node("Column") as VBoxContainer
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(8.0)))
	column.add_child(top)
	var title := UiKit.line(str(event["line"]))
	title.name = "EventLine"
	title.custom_minimum_size.x = 0.0
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var badge_holder := MarginContainer.new()
	badge_holder.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var badge := Label.new()
	badge.name = "LocationBadge"
	badge.text = str(event["badge"])
	badge.set_meta(UiKit.ONE_LINE_META, true)
	badge.autowrap_mode = TextServer.AUTOWRAP_OFF
	badge.add_theme_font_size_override("font_size", OfficeFrameStyles.px(LevelBriefingStyles.SIZE_SMALL))
	badge.add_theme_stylebox_override("normal", LevelBriefingStyles.chip_box(look))
	badge_holder.add_child(badge)
	top.add_child(badge_holder)
	var refusal := str(event["refusal"])
	if not refusal.is_empty():
		var why := UiKit.line(refusal)
		why.name = "EventRefusal"
		why.custom_minimum_size.x = 0.0
		why.add_theme_color_override("font_color", look["down"])
		column.add_child(why)
	var button := Button.new()
	button.name = str(event["node"])
	button.text = Text.say("event.arrange")
	button.disabled = not refusal.is_empty()
	button.custom_minimum_size.y = OfficeFrameStyles.touch_height()
	OfficeFrameStyles.dress_card_button(button, look, refusal.is_empty())
	if refusal.is_empty():
		button.pressed.connect(Haptics.confirm)
		button.pressed.connect(on_arrange.bind(str(event["event_id"])))
	column.add_child(button)
	return card
