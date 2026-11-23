class_name VenuesController
extends Node
## Capitol venues on the Office screen (P16, 2026-11-23, Cameron): the Step out button, the place map, a venue's screen, the line
## pop-up and the Tips you hold pop-up. The Office owns one of these and hands it what it needs; the rules are VenueRules, VenueLines
## and RhetoricTips, the state is GameState's. Every sentence is a Text row.

## The Speech Coach's page is the existing Rhetoric Training page; the Office opens it (a Callable with no arguments).
var _open_coach_page: Callable
## A callback the Office gives to refresh its resources line after hours are spent.
var _on_spent: Callable
var _office: Control
var _step_button: Button
var _map_panel: Overlay
var _venue_panel: Overlay
var _line_panel: Overlay
var _tips_panel: Overlay
## The venue whose line pop-up is up (Keep listening needs to know which).
var _current_venue := ""


## Builds the panels on the Office and the Step out button under `after_button`.
func setup(office: Control, after_button: Button, open_coach_page: Callable, on_spent: Callable) -> void:
	_office = office
	_open_coach_page = open_coach_page
	_on_spent = on_spent
	name = "VenuesController"
	office.add_child(self)
	_map_panel = _panel("VenueMapPanel")
	_venue_panel = _panel("VenuePanel")
	_line_panel = _panel("VenueLinePanel")
	_line_panel.dismissable = true
	_line_panel.confirmed.connect(_on_keep_listening)
	_tips_panel = _panel("TipsPanel")
	_step_button = Button.new()
	_step_button.name = "StepOutButton"
	_step_button.set_meta("party_outline", true)
	_step_button.text = Text.say("venue.step_out")
	_step_button.custom_minimum_size = after_button.custom_minimum_size
	_step_button.size_flags_horizontal = after_button.size_flags_horizontal
	_step_button.pressed.connect(show_map)
	after_button.get_parent().add_child(_step_button)
	after_button.get_parent().move_child(_step_button, after_button.get_index() + 1)
	refresh_button()


func _panel(panel_name: String) -> Overlay:
	var panel := Overlay.new()
	panel.name = panel_name
	_office.add_child(panel)
	return panel


## Step out shows at the Capitol office only; when it cannot be used (a level, a full week) it is greyed and says why.
func refresh_button() -> void:
	if _step_button == null:
		return
	var state := GameState.step_out_state()
	_step_button.visible = state != VenueRules.ELSEWHERE
	var why := GameState.step_out_refusal()
	_step_button.disabled = not why.is_empty()
	_step_button.text = Text.say("venue.step_out") if why.is_empty() else "%s · %s" % [Text.say("venue.step_out"), why]


# --- The place map -----------------------------------------------------------------------------------------------------------------

func show_map() -> void:
	if not GameState.step_out_refusal().is_empty():
		return
	var look := OfficeFrameStyles.look()
	var rows: Array[Control] = [UiKit.line(Text.say("venue.map_blurb"))]
	var zone := ""
	var venues: Array = DataDB.venues.duplicate()
	venues.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("order", 0)) < int(b.get("order", 0)))
	for venue: Dictionary in venues:
		var this_zone := str(venue.get("zone", ""))
		if this_zone != zone:
			zone = this_zone
			var heading := UiKit.heading(Text.say("venue.zone_capital_area" if zone == "Capital Area" else "venue.zone_capitol_building"))
			heading.name = "Zone_" + zone.replace(" ", "")
			rows.append(heading)
		rows.append(_venue_card(look, venue))
	var frame := OfficeScreenFrame.new()
	frame.setup({"title": Text.say("venue.map_title"), "subtitle": Text.say("venue.map_subtitle_jp"), "chips": _chips(), "rows": rows})
	_map_panel.open_frame(frame, Text.say("ui.back_office"))


func _chips() -> Array:
	return [TravelText.level_badge(GameState.office_location), Text.say("office.docket_hours", {"count": GameState.work_hours_left()})]


## A venue's card on the map: its name with the Japanese accent, its blurb, and Go (or Coming soon, greyed).
func _venue_card(look: Dictionary, venue: Dictionary) -> Control:
	var venue_id := str(venue.get("venue_id", ""))
	var activity := VenueRules.activity_of(DataDB.venue_activities, venue_id)
	var built := VenueRules.is_built(activity)
	var card := OfficeFrameStyles.card(look)
	card.name = "VenueCard_" + venue_id
	var column := card.get_node("Column") as VBoxContainer
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 12)
	var title := UiKit.heading(str(venue.get("name", venue_id)))
	title.custom_minimum_size.x = 0.0
	name_row.add_child(title)
	var jp := UiKit.line(str(venue.get("name_jp", "")), "SmallLabel")
	jp.custom_minimum_size.x = 0.0
	jp.size_flags_vertical = Control.SIZE_SHRINK_END
	name_row.add_child(jp)
	column.add_child(name_row)
	var blurb := UiKit.line(str(venue.get("blurb", "")), "SmallLabel")
	blurb.custom_minimum_size.x = 0.0
	column.add_child(blurb)
	var go := Button.new()
	go.name = "Venue_" + venue_id
	go.custom_minimum_size = Vector2(0, OfficeFrameStyles.touch_height())
	go.text = Text.say("venue.go") if built else Text.say("venue.coming_soon")
	go.disabled = not built
	OfficeFrameStyles.dress_card_button(go, look, built)
	if built:
		go.pressed.connect(show_venue.bind(venue_id))
	column.add_child(go)
	return card


# --- A venue's screen ---------------------------------------------------------------------------------------------------------------

func show_venue(venue_id: String) -> void:
	var venue := GameState.venue_row(venue_id)
	var activity := VenueRules.activity_of(DataDB.venue_activities, venue_id)
	if venue.is_empty() or not VenueRules.is_built(activity):
		return
	var look := OfficeFrameStyles.look()
	var rows: Array[Control] = []
	var picture := PlaceholderArt.new()
	picture.name = "VenuePicture"
	picture.kind = PlaceholderArt.Kind.BACKGROUND
	picture.art_id = str(venue.get("background", ""))
	picture.custom_minimum_size = Vector2(0, 460)
	picture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.append(picture)
	rows.append(UiKit.line(str(venue.get("blurb", ""))))
	var card := OfficeFrameStyles.card(look)
	card.name = "ActivityCard"
	var column := card.get_node("Column") as VBoxContainer
	var cost := VenueRules.visit_cost(activity)
	var cost_text := Text.say("venue.activity_cost", {"hours": int(cost["hours"])}) if int(cost["hours"]) > 0 else Text.say("venue.activity_free")
	var why := GameState.venue_visit_refusal(venue_id)
	var button := Button.new()
	button.name = "Activity_" + venue_id
	button.custom_minimum_size = Vector2(0, OfficeFrameStyles.touch_height())
	button.text = "%s · %s" % [str(activity.get("name", "")), cost_text] if why.is_empty() else why
	button.disabled = not why.is_empty()
	OfficeFrameStyles.dress_card_button(button, look, why.is_empty())
	if why.is_empty():
		button.pressed.connect(_on_activity.bind(venue_id))
	column.add_child(button)
	if VenueRules.deals_lines(activity):
		# A look at the venue deals nothing: the counter reads today's set only if it has been dealt (P16b).
		var heard := GameState.venue_day_peek(venue_id)
		var counter := UiKit.line(Text.say("venue.heard_today", {"count": int(heard.get("heard", 0)), "limit": GameState.venue_limit()}), "SmallLabel")
		counter.name = "HeardToday"
		counter.custom_minimum_size.x = 0.0
		column.add_child(counter)
	rows.append(card)
	var frame := OfficeScreenFrame.new()
	frame.setup({"title": str(venue.get("name", venue_id)), "subtitle": str(venue.get("name_jp", "")), "chips": _chips(), "rows": rows})
	_venue_panel.open_frame(frame, Text.say("venue.screen_back"))


## The venue's activity: a chat or watch starts a visit and shows the first line; the Speech Coach opens the Rhetoric Training page.
func _on_activity(venue_id: String) -> void:
	var activity := VenueRules.activity_of(DataDB.venue_activities, venue_id)
	if str(activity.get("kind", "")) == "train":
		_venue_panel.close()
		_map_panel.close()
		_open_coach_page.call()
		return
	var visit := GameState.venue_visit(venue_id)
	if not bool(visit["ok"]):
		show_venue(venue_id)
		return
	_on_spent.call()
	refresh_button()
	_venue_panel.close()
	_current_venue = venue_id
	_hear(venue_id)


# --- The line pop-up ----------------------------------------------------------------------------------------------------------------

## Reveals the next line (free of hours) and shows it; with none left, the venue's screen shows again.
func _hear(venue_id: String) -> void:
	var heard := GameState.venue_hear_next(venue_id)
	if not bool(heard["ok"]):
		show_venue(venue_id)
		return
	SaveManager.autosave()
	var venue := GameState.venue_row(venue_id)
	var pool := str(heard.get("where", ""))
	var body: Array[Control] = []
	# No automatic "You overhear ..." lead (Cameron, 2026-11-23): a line that wants it says so in its own words.
	body.append(VenueViews.speaker_row(str(heard["text"]), str(heard.get("speaker", ""))))
	var hint: Dictionary = heard.get("hint", {})
	if not hint.is_empty():
		body.append(VenueViews.tip_box(hint, pool))
	elif str(heard["kind"]) != "dry":
		var note := UiKit.line(Text.say("venue.gossip_only"), "SmallLabel")
		note.name = "GossipOnly"
		note.custom_minimum_size.x = 0.0
		body.append(note)
	var meta := Text.say("venue.line_counter", {"count": int(heard["number"]), "limit": int(heard["limit"])}) if str(heard["kind"]) != "dry" else ""
	var done := bool(heard.get("last", false))
	_line_panel.open_card({"tag": Text.say("venue.tag_gardens" if pool == "gardens" else "venue.tag_cafeteria"), "meta": meta,
		"body": body},
		Text.say("venue.come_back") if done else Text.say("venue.keep_listening"),
		Text.say("venue.back_to", {"venue": str(venue.get("name", ""))}), not done)


func _on_keep_listening() -> void:
	if not _current_venue.is_empty():
		_hear(_current_venue)


# --- Tips you hold --------------------------------------------------------------------------------------------------------------------

func show_tips() -> void:
	var look := OfficeFrameStyles.look()
	var rows: Array[Control] = [UiKit.line(Text.say("tips.rule", {"days": int(DataDB.get_rule("tips_days", 14)),
		"max": int(DataDB.get_rule("tips_max_held", 10))}), "SmallLabel")]
	var held := GameState.tips_held()
	if held.is_empty():
		rows.append(UiKit.line(Text.say("tips.empty")))
	for tip: Dictionary in held:
		rows.append(VenueViews.tip_row(look, tip, GameState.tip_days_left(tip)))
	_tips_panel.open_card({"tag": Text.say("tips.title"), "meta": Text.say("tips.count", {"count": held.size(),
		"max": int(DataDB.get_rule("tips_max_held", 10))}), "body": rows}, "", Text.say("tips.close"))
