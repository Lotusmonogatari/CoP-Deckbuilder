class_name StationViews
extends RefCounted
## The pieces of a station's screens (travel at the stations, 2026-11-24, Cameron): the Departures card (where, how, what is left)
## and the train strip. They draw what they are given from GameState's travel rules; nothing here decides a rule. The Office owns the
## trip itself (the confirm, the fade card, the arrival), so the pieces take a `hooks` dictionary of Callables:
##   "mode"     () -> String           the way the strip is pulled with now (the rail pass or a paid train ticket)
##   "set_mode" (mode)                 pick the rail pass or the paid ticket
##   "confirm"  (mode)                 open the trip's confirm sheet (also how a plane or a car leaves)
##   "go"       (mode)                 take the trip (the strip's drag)
##   "refresh"  ()                     draw the screen again after a pick
## Every sentence is a Text row.

## The order the ways of going are listed in.
const MODE_ORDER: Array[String] = [Travel.PASS, Travel.TICKET, Travel.PLANE, Travel.CAR]


## Whether this protagonist has the way of going at all: the rail pass always, a paid ticket if one is sold to them, and the fast mode
## their Balance rows give them (a plane or a car), never the other one. Only these are listed on a station's Departures card.
static func is_yours(mode: String) -> bool:
	match mode:
		Travel.PASS: return true
		Travel.TICKET: return not GameState.travel_item_id(Travel.TICKET).is_empty()
	return mode == Travel.fast_mode(DataDB.balance, GameState.protagonist_id)


## One button for a way of going: its name and hours (and how many tickets are left), the mode's picture beside it, greyed when it
## cannot be used (none left, or the one the strip already uses). A way that is not the protagonist's is not listed at all.
static func mode_button(look: Dictionary, mode: String, hooks: Dictionary) -> Button:
	var button := Button.new()
	button.name = "TravelMode_" + mode
	button.custom_minimum_size = Vector2(0, OfficeFrameStyles.touch_height())
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.clip_text = false
	var usable := true
	if mode == Travel.PASS:
		button.text = Text.say("travel.mode_button", {"mode": TravelText.mode_name(mode), "count": GameState.trip_hours(mode)})
	else:
		var held := GameState.travel_tickets(mode)
		button.text = Text.say("travel.mode_button_owned", {"mode": TravelText.mode_name(mode),
			"count": GameState.trip_hours(mode), "owned": held})
		usable = held > 0
	var strip_mode: String = (hooks["mode"] as Callable).call()
	var is_strip_mode: bool = (mode == Travel.PASS or mode == Travel.TICKET) and mode == strip_mode
	button.disabled = not usable or is_strip_mode
	OfficeFrameStyles.dress_card_button(button, look, usable and not is_strip_mode)
	TravelText.dress_mode_icon(button, mode, 90.0)
	if usable and not is_strip_mode:
		button.pressed.connect(_on_mode.bind(mode, hooks))
	return button


## The rail pass and a paid ticket choose how the strip is pulled; a plane or a car opens its own confirm.
static func _on_mode(mode: String, hooks: Dictionary) -> void:
	if mode == Travel.CAR or mode == Travel.PLANE:
		(hooks["confirm"] as Callable).call(mode)
		return
	(hooks["set_mode"] as Callable).call(mode)
	(hooks["refresh"] as Callable).call()


## The Departures card: where the trip goes, one button for each way of going, and what is left of the week after it.
static func departures_card(look: Dictionary, title: String, hooks: Dictionary) -> PanelContainer:
	var destination := Offices.other(GameState.office_location)
	var by: String = (hooks["mode"] as Callable).call()
	var card := OfficeFrameStyles.card(look, title)
	card.name = "DeparturesCard"
	var column := card.get_node("Column") as VBoxContainer
	var to := UiKit.line(Text.say("travel.destination", {"place": TravelText.place_name(destination)}), "SmallLabel")
	to.name = "DeparturesTo"
	to.custom_minimum_size.x = 0.0
	column.add_child(to)
	for mode: String in MODE_ORDER:
		# A plane for a protagonist who has none (or a car for one who has the plane) is never listed: only their own ways of going.
		if is_yours(mode):
			column.add_child(mode_button(look, mode, hooks))
	var why := GameState.travel_refusal(by)
	var after := UiKit.line(why if not why.is_empty() else Text.say("travel.after_line", {"count": maxi(0, GameState.work_hours_left() - GameState.trip_hours(by))}), "SmallLabel")
	after.name = "DeparturesAfter"
	after.custom_minimum_size.x = 0.0
	column.add_child(after)
	return card


## The train strip, as it was on the Office (the same drag-or-tap component, nothing added): where, how long and by what on its face,
## greyed with the reason when the trip cannot be taken.
static func train_strip(hooks: Dictionary) -> TravelStrip:
	var by: String = (hooks["mode"] as Callable).call()
	var destination := Offices.other(GameState.office_location)
	var refusal := GameState.travel_refusal(by)
	var strip := TravelStrip.new()
	strip.name = "TravelButton"
	strip.text = refusal if not refusal.is_empty() else Text.say("travel.button", {
		"place": TravelText.place_name(destination), "count": GameState.trip_hours(by), "mode": TravelText.mode_name(by)})
	strip.disabled = not refusal.is_empty()
	strip.direction = 1 if GameState.office_location == Offices.CAPITOL else -1
	strip.tapped.connect((hooks["confirm"] as Callable).bind(by))
	strip.committed.connect((hooks["go"] as Callable).bind(by))
	return strip
