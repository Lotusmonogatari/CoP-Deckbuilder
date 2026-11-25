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
## Catch Up on Paperwork, beside Step out (2026-11-25): an hour at the desk with a small chance of a standing point.
var _paperwork_button: Button
## What to do when the lunch result card closes (listen in), instead of redrawing the venue.
var _after_result: Callable
var _paperwork_panel: Overlay
var _map_panel: Overlay
var _venue_panel: Overlay
var _line_panel: Overlay
var _tips_panel: Overlay
## The tracks screen of a station, over the concourse (so its Back control returns to the concourse).
var _tracks_panel: Overlay
## What was just done at a venue (a costed activity's result card), over the venue's screen.
var _result_panel: Overlay
var _result_venue := ""
## The Library's two tabs and the Codex reader (P18).
var _library: LibraryController
## The scene behind an overheard line spoken by an area character (VenueSceneViews), or null.
var _scene: Control
## Where Continue leads after an overheard line ({"venue", "screen"}), or {} when the pop-up is an ordinary line.
var _continue_to: Dictionary = {}
## What a station's screens call on the Office: the trip's mode, confirm and go (see StationViews).
var _trip_hooks: Dictionary = {}
## The venue whose line pop-up is up (Keep listening needs to know which).
var _current_venue := ""


## Builds the panels on the Office and the Step out button under `after_button`.
func setup(office: Control, after_button: Button, open_coach_page: Callable, on_spent: Callable, trip_hooks: Dictionary = {}) -> void:
	_office = office
	_open_coach_page = open_coach_page
	_on_spent = on_spent
	_trip_hooks = trip_hooks
	name = "VenuesController"
	office.add_child(self)
	_map_panel = _panel("VenueMapPanel")
	_venue_panel = _panel("VenuePanel")
	_line_panel = _panel("VenueLinePanel")
	_line_panel.dismissable = true
	_line_panel.confirmed.connect(_on_keep_listening)
	_line_panel.closed.connect(_clear_scene)
	_tips_panel = _panel("TipsPanel")
	_tracks_panel = _panel("StationTracksPanel")
	_paperwork_panel = _panel("PaperworkPanel")
	_paperwork_panel.confirmed.connect(_paperwork_confirmed)
	_result_panel = _panel("VenueResultPanel")
	_result_panel.closed.connect(_on_result_closed)
	_library = LibraryController.new()
	_library.setup(office, self, _venue_panel, _chips)
	_step_button = Button.new()
	_step_button.name = "StepOutButton"
	_step_button.set_meta("party_outline", true)
	_step_button.text = Text.say("venue.step_out")
	_step_button.custom_minimum_size = after_button.custom_minimum_size
	_step_button.size_flags_horizontal = after_button.size_flags_horizontal
	_step_button.pressed.connect(show_map)
	_paperwork_button = Button.new()
	_paperwork_button.name = "PaperworkButton"
	_paperwork_button.set_meta("party_outline", true)
	_paperwork_button.custom_minimum_size = after_button.custom_minimum_size
	_paperwork_button.size_flags_horizontal = after_button.size_flags_horizontal
	_paperwork_button.pressed.connect(_do_paperwork)
	# Step out and Catch Up on Paperwork share one row under the Office's buttons (Cameron's idea: the paperwork button beside Step out).
	var row := HBoxContainer.new()
	row.name = "StepOutRow"
	row.add_theme_constant_override("separation", 16)
	after_button.get_parent().add_child(row)
	after_button.get_parent().move_child(row, after_button.get_index() + 1)
	for button: Button in [_step_button, _paperwork_button]:
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Each takes half the row and wraps its words, so the two never push the Office wider than the screen at the large text size.
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.x = 0.0
		row.add_child(button)
	refresh_button()


func _panel(panel_name: String) -> Overlay:
	var panel := Overlay.new()
	panel.name = panel_name
	_office.add_child(panel)
	return panel


## Step out shows at both offices; when it cannot be used (a level, a full week) it is greyed and says why.
func refresh_button() -> void:
	if _step_button == null:
		return
	var why := GameState.step_out_refusal()
	_step_button.disabled = not why.is_empty()
	_step_button.text = Text.say("venue.step_out") if why.is_empty() else "%s · %s" % [Text.say("venue.step_out"), why]
	_refresh_paperwork()


func _refresh_paperwork() -> void:
	if _paperwork_button == null:
		return
	var activity := GameState.office_activity()
	_paperwork_button.visible = not activity.is_empty()
	if activity.is_empty():
		return
	var why := GameState.activity_refusal(str(activity["activity_id"]))
	var label := Text.say("paperwork.button", {"hours": int(VenueRules.visit_cost(activity)["hours"])})
	_paperwork_button.disabled = not why.is_empty()
	_paperwork_button.text = label if why.is_empty() else "%s · %s" % [label, why]


# --- Seats and meals (2026-11-25) -----------------------------------------------------------------------------------------------------
# Eat with Colleagues asks where to sit (three seats drawn for the visit) and what to eat; ordering takes the hour, gives what the two choices
# give and shows a result card, and Listen in then opens the conversation as before.

func _show_seats(venue_id: String) -> void:
	var look := OfficeFrameStyles.look()
	var rows: Array[Control] = [UiKit.heading(Text.say("choice.seat_heading"))]
	for row: Dictionary in GameState.seat_options(venue_id):
		rows.append(VenueChoiceViews.card(look, row, Text.say("choice.sit"), _on_seat.bind(venue_id)))
	_open_choice_frame(venue_id, rows)


func _on_seat(seat_id: String, venue_id: String) -> void:
	var look := OfficeFrameStyles.look()
	var rows: Array[Control] = [UiKit.heading(Text.say("choice.meal_heading"))]
	for row: Dictionary in GameState.meal_options(venue_id):
		rows.append(VenueChoiceViews.card(look, row, Text.say("choice.order"), _on_meal.bind(venue_id, seat_id)))
	_open_choice_frame(venue_id, rows)


func _open_choice_frame(venue_id: String, rows: Array[Control]) -> void:
	var venue := GameState.venue_row(venue_id)
	var frame := OfficeScreenFrame.new()
	frame.setup({"title": str(venue.get("name", venue_id)), "subtitle": str(venue.get("name_jp", "")), "chips": _chips(), "rows": rows})
	_venue_panel.open_frame(frame, Text.say("venue.screen_back"))


func _on_meal(meal_id: String, venue_id: String, seat_id: String) -> void:
	var done := GameState.do_choice_visit(venue_id, seat_id, meal_id)
	if not bool(done["ok"]):
		show_venue(venue_id)
		return
	_on_spent.call()
	refresh_button()
	_venue_panel.close()
	_current_venue = venue_id
	_result_venue = ""
	_after_result = _hear.bind(venue_id)
	var body: Array[Control] = [UiKit.line(Text.say("choice.result_seat", {"seat": str(done["seat"])})), UiKit.line(Text.say("choice.result_meal", {"meal": str(done["meal"])}))]
	var effects: Array = done["effects"]
	if effects.is_empty():
		body.append(UiKit.line(Text.say("choice.result_nothing"), "SmallLabel"))
	for line: String in effects:
		body.append(UiKit.line(line, "SmallLabel"))
	body.append(UiKit.line(Text.say("choice.result_hour"), "SmallLabel"))
	_result_panel.open_card({"tag": Text.say("choice.result_tag"), "meta": str(GameState.venue_row(venue_id).get("name", "")), "body": body}, "",
		Text.say("choice.result_continue"))


## Catch Up on Paperwork asks first, saying what it costs and the odds of an extra (the information standards), then does it.
func _do_paperwork() -> void:
	var activity := GameState.office_activity()
	if activity.is_empty():
		return
	var odds := GameState.chance_line(activity)
	var body: Array[Control] = [UiKit.line(Text.say("paperwork.cost", {"hours": int(VenueRules.visit_cost(activity)["hours"])}))]
	if not odds.is_empty():
		body.append(UiKit.line(odds))
	_paperwork_panel.open_card({"tag": Text.say("paperwork.tag"), "meta": str(activity.get("name", "")), "body": body}, Text.say("paperwork.do"),
		Text.say("ui.back"))


func _paperwork_confirmed() -> void:
	var activity := GameState.office_activity()
	if activity.is_empty():
		return
	var done := GameState.do_activity(str(activity["activity_id"]))
	if not bool(done["ok"]):
		refresh_button()
		return
	_on_spent.call()
	refresh_button()
	_result_venue = ""
	_after_result = Callable()
	var body: Array[Control] = [UiKit.line(str(done["text"]))]
	for line: String in done["effects"]:
		body.append(UiKit.line(line, "SmallLabel"))
	_result_panel.open_card({"tag": Text.say("paperwork.tag"), "meta": str(activity.get("name", "")), "body": body}, "", Text.say("paperwork.back"))


# --- The place map -----------------------------------------------------------------------------------------------------------------

func show_map() -> void:
	if not GameState.step_out_refusal().is_empty():
		return
	var look := OfficeFrameStyles.look()
	var rows: Array[Control] = [UiKit.line(Text.say("venue.map_blurb"))]
	var zone := ""
	# The Capitol's places at the Capitol office; the District office's own places (its station) at the District office.
	for venue: Dictionary in GameState.venues_here():
		var this_zone := str(venue.get("zone", ""))
		if this_zone != zone:
			zone = this_zone
			var heading := UiKit.heading(_zone_heading(zone))
			heading.name = "Zone_" + zone.replace(" ", "")
			rows.append(heading)
		rows.append(_venue_card(look, venue))
	var frame := OfficeScreenFrame.new()
	frame.setup({"title": Text.say("venue.map_title"), "subtitle": Text.say("venue.map_subtitle_jp"), "chips": _chips(), "rows": rows})
	_map_panel.open_frame(frame, Text.say("ui.back_office"))


func _zone_heading(zone: String) -> String:
	match zone:
		"Capital Area": return Text.say("venue.zone_capital_area")
		"District": return Text.say("venue.zone_district", {"office": GameState.district_office_name()})
	return Text.say("venue.zone_capitol_building")


func _chips() -> Array:
	return [TravelText.level_badge(GameState.office_location), Text.say("office.docket_hours", {"count": GameState.work_hours_left()})]


## A venue's card on the map: its name with the Japanese accent, its blurb, and Go (or Coming soon, greyed).
func _venue_card(look: Dictionary, venue: Dictionary) -> Control:
	var venue_id := str(venue.get("venue_id", ""))
	var built := VenueRules.venue_built(DataDB.venue_activities, venue_id)
	var card := OfficeFrameStyles.card(look)
	card.name = "VenueCard_" + venue_id
	var column := card.get_node("Column") as VBoxContainer
	# The place's picture as a wide banner across the top of the card (in the season it is now), then its name and blurb, then Go
	# (Cameron chose this card over the thumbnail one, 2026-11-24).
	var banner := _picture(_venue_picture_id(venue), 230.0)
	banner.name = "VenueBanner"
	banner.fade_all_sides = true   # all four sides blur out into the card, wherever the card is on the screen
	column.add_child(banner)
	var words := UiKit.tight_column()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(words)
	# The name on its own row (it may wrap), the Japanese accent under it.
	var title := UiKit.heading(str(venue.get("name", venue_id)))
	title.custom_minimum_size.x = 0.0
	words.add_child(title)
	var jp := UiKit.line(str(venue.get("name_jp", "")), "SmallLabel")
	jp.custom_minimum_size.x = 0.0
	words.add_child(jp)
	var blurb := UiKit.line(str(venue.get("blurb", "")), "SmallLabel")
	blurb.custom_minimum_size.x = 0.0
	words.add_child(blurb)
	var go := Button.new()
	go.name = "Venue_" + venue_id
	go.custom_minimum_size = Vector2(0, OfficeFrameStyles.touch_height())
	go.text = Text.say("venue.go") if built else Text.say("venue.coming_soon")
	go.disabled = not built
	OfficeFrameStyles.dress_card_button(go, look, built)
	if built:
		go.pressed.connect(_go_to.bind(venue_id, ""))
	column.add_child(go)
	return card


## The venue's background for the season it is now (CAPITOL_GARDENS_AUTUMN and _WINTER exist; a venue with no seasonal picture
## keeps its plain one). Seasons are rules.json's table, the same one the seasonal levels and events use.
static func venue_picture_id(venue: Dictionary, month: int, table: Dictionary) -> String:
	return VenueRules.seasonal_background(str(venue.get("background", "")), Seasons.season_of(month, table),
		func(id: String) -> bool: return ArtLoader.exists(ArtLoader.folder("background") + id + ".png"))


func _venue_picture_id(venue: Dictionary) -> String:
	return venue_picture_id(venue, GameState.current_month(), DataDB.rules.get("seasons", {}))


# --- A venue's screen ---------------------------------------------------------------------------------------------------------------

func show_venue(venue_id: String) -> void:
	var venue := GameState.venue_row(venue_id)
	var activity := VenueRules.activity_of(DataDB.venue_activities, venue_id)
	if venue.is_empty():
		return
	# The Library has a Codex and a reference desk: two tabs.
	if LibraryController.draws(venue_id):
		_library.open(venue_id, _library_tab)
		_library_tab = LibraryController.TAB_DESK
		return
	# A venue with costed activities (the shrine, the shotengai) lists them all.
	if GameState.venue_activities_of(venue_id).any(func(row: Dictionary) -> bool: return VenueActivities.is_act(row)):
		_show_activities(venue)
		return
	if not VenueRules.is_built(activity):
		return
	if str(activity.get("kind", "")) == "travel":
		_show_station(venue, activity)
		return
	var look := OfficeFrameStyles.look()
	var rows: Array[Control] = []
	var picture := PlaceholderArt.new()
	picture.name = "VenuePicture"
	picture.kind = PlaceholderArt.Kind.BACKGROUND
	picture.art_id = _venue_picture_id(venue)
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


## The tab the Library opens on when show_venue draws it next (the Codex after a document is read in the line pop-up).
var _library_tab := LibraryController.TAB_DESK


## Hours (or XP) were spent in a venue screen the Library controller draws: the Office's resources line and the Step out button follow.
func hours_spent() -> void:
	_on_spent.call()
	refresh_button()


## Does a costed activity (the Library's Nap and reading call this).
func do_activity(activity_id: String) -> void:
	_on_do_activity(activity_id)


## The venue's activity: a chat or watch starts a visit and shows the first line; the Speech Coach opens the Rhetoric Training page.
func _on_activity(venue_id: String) -> void:
	var activity := VenueRules.activity_of(DataDB.venue_activities, venue_id)
	if str(activity.get("kind", "")) == "train":
		_venue_panel.close()
		_map_panel.close()
		_open_coach_page.call()
		return
	# A venue with seats and meals (the Cafeteria) asks where to sit and what to eat first; the hour is taken when the meal is ordered.
	if GameState.venue_has_choices(venue_id):
		var why := GameState.venue_visit_refusal(venue_id)
		if not why.is_empty():
			show_venue(venue_id)
			return
		_show_seats(venue_id)
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


# --- Costed activities (2026-11-24) ------------------------------------------------------------------------------------------------
# The Old Shrine, the Local Shotengai and the Library: one card for each activity, with its cost, what it gives and how many times are
# left today before it is pressed. Doing one shows a result card over the venue, and the venue screen is drawn again after it.

func _show_activities(venue: Dictionary) -> void:
	var venue_id := str(venue.get("venue_id", ""))
	var look := OfficeFrameStyles.look()
	var rows: Array[Control] = [_picture(_venue_picture_id(venue), 460), UiKit.line(str(venue.get("blurb", "")))]
	rows.append_array(_stage_rows(venue_id))
	for activity: Dictionary in GameState.venue_activities_of(venue_id):
		rows.append(VenueActivityViews.card(look, activity, _on_do_activity, _on_activity))
	var frame := OfficeScreenFrame.new()
	frame.setup({"title": str(venue.get("name", venue_id)), "subtitle": str(venue.get("name_jp", "")), "chips": _chips(), "rows": rows})
	_venue_panel.open_frame(frame, Text.say("venue.screen_back"))


## The Stage's header: the events on today (name and blurb) and who is on stage; "Nothing is on today" when neither. Other venues add nothing.
func _stage_rows(venue_id: String) -> Array[Control]:
	var rows: Array[Control] = []
	if not GameState.venue_activities_of(venue_id).any(func(row: Dictionary) -> bool: return str(row.get("kind", "")) in ["listen", "perform"]):
		return rows
	var events := GameState.stage_events_today()
	var performers := GameState.stage_performers(venue_id)
	for event: Dictionary in events:
		var title := UiKit.heading(Text.say("stage.event_today", {"name": str(event.get("name", ""))}))
		title.name = "StageEvent_" + str(event.get("event_id", ""))
		title.custom_minimum_size.x = 0.0
		rows.append(title)
		if event.get("blurb") != null:
			var blurb := UiKit.line(str(event["blurb"]), "SmallLabel")
			blurb.custom_minimum_size.x = 0.0
			rows.append(blurb)
	for person: Dictionary in performers:
		var on_stage := UiKit.line(Text.say("stage.performer_today", {"name": str(person.get("name", ""))}))
		on_stage.name = "StagePerformer_" + str(person.get("character_id", ""))
		on_stage.custom_minimum_size.x = 0.0
		rows.append(on_stage)
	if events.is_empty() and performers.is_empty():
		var quiet := UiKit.line(Text.say("stage.quiet"), "SmallLabel")
		quiet.name = "StageQuiet"
		quiet.custom_minimum_size.x = 0.0
		rows.append(quiet)
	return rows


func _on_do_activity(activity_id: String) -> void:
	var activity := GameState.venue_activity(activity_id)
	var venue_id := str(activity.get("venue_id", ""))
	var done := GameState.do_activity(activity_id)
	if not bool(done["ok"]):
		show_venue(venue_id)
		return
	_on_spent.call()
	refresh_button()
	# Sit and Listen and Watch the Performance end on the person standing over the Stage with their line, then back to the Stage.
	if str(activity.get("kind", "")) in ["listen", "perform"]:
		_venue_panel.close()
		_continue_to = {"venue": venue_id, "screen": ""}
		var heard: Dictionary = done["heard"]
		var extra: Array = []
		if str(activity.get("kind", "")) == "perform":
			var person := DataDB.get_area_character(str(heard.get("speaker", "")))
			extra.append(Text.say("stage.watched", {"name": str(person.get("name", ""))}))
			extra.append_array(done["effects"])
		_show_heard(venue_id, {"ok": true, "kind": "overheard", "speaker": str(heard.get("speaker", "")), "text": str(heard.get("text", "")), "hint": {},
			"unlocked": "", "last": true, "where": ""}, true, Text.say("stage.back"), extra)
		return
	_result_venue = venue_id
	var body: Array[Control] = [UiKit.line(str(done["text"]))]
	for line: String in done["effects"]:
		body.append(UiKit.line(line, "SmallLabel"))
	for gift: Dictionary in done["gifts"]:
		body.append(UiKit.line(str(gift["text"])))
		for line: String in gift["effects"]:
			body.append(UiKit.line(line, "SmallLabel"))
	_result_panel.open_card({"tag": Text.say("venue.tag_done"), "meta": str(activity.get("name", "")), "body": body}, "",
		Text.say("venue.back_to", {"venue": str(GameState.venue_row(venue_id).get("name", ""))}))


## Closing the result card draws the venue's screen again, so the counts and limits are today's.
func _on_result_closed() -> void:
	if _after_result.is_valid():
		var next := _after_result
		_after_result = Callable()
		next.call()
		return
	if not _result_venue.is_empty():
		var venue_id := _result_venue
		_result_venue = ""
		show_venue(venue_id)


# --- Stations (travel at the stations, 2026-11-24) ----------------------------------------------------------------------------------
# Trips leave from the stations. The Capitol's station (Sapporo Super Station) has two screens: the concourse, where the player picks
# how to go, and the tracks, where the train strip boards it. The District office's station has one screen with the strip on it.
# A plane or a car leaves from the concourse with its own confirm. The trip itself (the confirm sheet, the fade card, the
# arrival) is the Office's; this draws the screens and calls it through `_trip_hooks`.

func _hooks() -> Dictionary:
	var hooks := _trip_hooks.duplicate()
	hooks["refresh"] = _redraw_station
	return hooks


## The station screen drawn last, so a pick of the rail pass or a paid ticket draws it again.
var _station_venue := ""
var _station_on_tracks := false


func _redraw_station() -> void:
	if _station_on_tracks:
		_show_tracks(_station_venue)
	else:
		show_venue(_station_venue)


## Going to a place (the Go button, or To the tracks): counts a move, and on the N-th a line is overheard first (OverheardLines); Continue then
## opens the place. The place's screen is drawn only after the line, so the move is not lost if the player leaves.
func _go_to(venue_id: String, screen: String) -> void:
	var heard := GameState.overheard_on_move(venue_id, screen)
	SaveManager.autosave()   # the move counter changed
	if heard.is_empty():
		_enter_place(venue_id, screen)
		return
	_continue_to = {"venue": venue_id, "screen": screen}
	_show_heard(venue_id, {"ok": true, "kind": "overheard", "speaker": str(heard["speaker"]), "text": str(heard["text"]), "hint": {},
		"unlocked": "", "last": true, "where": ""}, true)


func _enter_place(venue_id: String, screen: String) -> void:
	_continue_to = {}
	if screen == "tracks":
		_show_tracks(venue_id)
	else:
		show_venue(venue_id)


func _picture(art_id: String, height: float) -> PlaceholderArt:
	var picture := PlaceholderArt.new()
	picture.name = "VenuePicture"
	picture.kind = PlaceholderArt.Kind.BACKGROUND
	picture.art_id = art_id
	picture.custom_minimum_size = Vector2(0, height)
	picture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return picture


func _show_station(venue: Dictionary, activity: Dictionary) -> void:
	var venue_id := str(venue.get("venue_id", ""))
	_station_venue = venue_id
	_station_on_tracks = false
	var look := OfficeFrameStyles.look()
	var hooks := _hooks()
	var at_district := str(venue.get("zone", "")) == VenueRules.ZONE_DISTRICT
	var rows: Array[Control] = [_picture(str(venue.get("background", "")), 460), UiKit.line(str(venue.get("blurb", "")))]
	var card := StationViews.departures_card(look, str(activity.get("name", "")), hooks)
	if at_district:
		# A District station is one screen: the strip sits in the card under the ways of going.
		(card.get_node("Column") as VBoxContainer).add_child(StationViews.train_strip(hooks))
		rows.append(card)
	else:
		rows.append(card)
		var by: String = (hooks["mode"] as Callable).call()
		var why := GameState.travel_refusal(by)
		var tracks := Button.new()
		tracks.name = "ToTracksButton"
		tracks.custom_minimum_size = Vector2(0, OfficeFrameStyles.touch_height())
		tracks.text = why if not why.is_empty() else Text.say("station.to_tracks")
		tracks.disabled = not why.is_empty()
		OfficeFrameStyles.dress_card_button(tracks, look, why.is_empty())
		if why.is_empty():
			tracks.pressed.connect(_go_to.bind(venue_id, "tracks"))
		rows.append(tracks)
		var hint := UiKit.line(Text.say("station.concourse_hint"), "SmallLabel")
		hint.name = "ConcourseHint"
		hint.custom_minimum_size.x = 0.0
		rows.append(hint)
	var frame := OfficeScreenFrame.new()
	frame.setup({"title": str(venue.get("name", venue_id)), "subtitle": str(venue.get("name_jp", "")), "chips": _chips(), "rows": rows})
	_venue_panel.open_frame(frame, Text.say("venue.screen_back"))


## The tracks: the station's second picture and the train strip.
func _show_tracks(venue_id: String) -> void:
	var venue := GameState.venue_row(venue_id)
	_station_venue = venue_id
	_station_on_tracks = true
	var look := OfficeFrameStyles.look()
	var hooks := _hooks()
	var picture_id := VenueRules.tracks_background(str(venue.get("background", "")),
		func(id: String) -> bool: return ArtLoader.exists(ArtLoader.folder("background") + id + ".png"))
	var rows: Array[Control] = [_picture(picture_id if not picture_id.is_empty() else str(venue.get("background", "")), 460),
		UiKit.line(Text.say("station.tracks_blurb"))]
	var card := OfficeFrameStyles.card(look)
	card.name = "TracksCard"
	(card.get_node("Column") as VBoxContainer).add_child(StationViews.train_strip(hooks))
	rows.append(card)
	var frame := OfficeScreenFrame.new()
	frame.setup({"title": Text.say("station.tracks_title"), "subtitle": Text.say("station.tracks_title_jp"), "chips": _chips(), "rows": rows})
	_tracks_panel.open_frame(frame, Text.say("station.back_concourse"))


## Every venue screen closed: the Office calls this when a trip begins, so the other office is what shows when the card fades.
func close_all() -> void:
	_after_result = Callable()
	_result_venue = ""   # a trip leaves; the venue screen is not drawn again behind it
	_library.close_all()
	for panel: Overlay in [_result_panel, _tracks_panel, _line_panel, _venue_panel, _map_panel, _tips_panel]:
		if panel != null and panel.visible:
			panel.close()


# --- The line pop-up ----------------------------------------------------------------------------------------------------------------

## Reveals the next line (free of hours) and shows it; with none left, the venue's screen shows again.
func _hear(venue_id: String) -> void:
	var heard := GameState.venue_hear_next(venue_id)
	if not bool(heard["ok"]):
		show_venue(venue_id)
		return
	SaveManager.autosave()
	_show_heard(venue_id, heard)


## Draws a heard line. An Area Characters speaker stands over the venue's background with the card at the foot; any other line is the plain
## card over the Office (Cameron, 2026-11-25). Split from `_hear` so a screen can be drawn from a line without dealing one.
func _show_heard(venue_id: String, heard: Dictionary, overheard: bool = false, confirm_text: String = "", extra_lines: Array = []) -> void:
	_clear_scene()
	var venue := GameState.venue_row(venue_id)
	var pool := str(heard.get("where", ""))
	var speaker := str(heard.get("speaker", ""))
	var on_scene := AreaCharacters.is_area_id(speaker)
	var body: Array[Control] = []
	# No automatic "You overhear ..." lead (Cameron, 2026-11-23): a line that wants it says so in its own words.
	body.append(VenueViews.speaker_row(str(heard["text"]), speaker, "", not on_scene))
	var hint: Dictionary = heard.get("hint", {})
	if not hint.is_empty():
		body.append(VenueViews.tip_box(hint, pool))
	elif str(heard["kind"]) not in ["dry", "overheard"]:
		var note := UiKit.line(Text.say("venue.gossip_only"), "SmallLabel")
		note.name = "GossipOnly"
		note.custom_minimum_size.x = 0.0
		body.append(note)
	for extra: Variant in extra_lines:
		var extra_label := UiKit.line(str(extra), "SmallLabel")
		extra_label.custom_minimum_size.x = 0.0
		body.append(extra_label)
	var unlocked := str(heard.get("unlocked", ""))
	if not unlocked.is_empty():
		# A line that finds a document says so under its words (P18); the title is the document's own.
		var added := UiKit.line(Text.say("codex.added"), "SmallLabel")
		added.name = "CodexAdded"
		added.custom_minimum_size.x = 0.0
		body.append(added)
		var added_title := UiKit.line(unlocked, "HeaderLabel")
		added_title.name = "CodexAddedTitle"
		added_title.custom_minimum_size.x = 0.0
		body.append(added_title)
	var meta := Text.say("venue.line_counter", {"count": int(heard["number"]), "limit": int(heard["limit"])}) if str(heard["kind"]) not in ["dry", "overheard"] else ""
	var done := bool(heard.get("last", false))
	# The Cafeteria and the Gardens have their own tags; any other place (a line an area person speaks there) is tagged with its name.
	var tag := str(venue.get("name", "")) if pool not in ["gardens", "cafeteria"] else Text.say("venue.tag_gardens" if pool == "gardens" else "venue.tag_cafeteria")
	# An overheard line has one way on, Continue into the place: no Back, and a tap outside does not close it.
	_line_panel.show_back = not overheard
	_line_panel.dismissable = not overheard
	_line_panel.open_card({"tag": tag, "meta": meta, "bottom": on_scene, "body": body},
		confirm_text if not confirm_text.is_empty() else (Text.say("venue.overheard_continue") if overheard else (Text.say("venue.come_back") if done else Text.say("venue.keep_listening"))),
		Text.say("venue.back_to", {"venue": str(venue.get("name", ""))}), overheard or not done)
	if on_scene:
		# The scene sits behind the card, over an opaque ground (the pop-up's usual scrim would show the Office through the picture).
		_scene = VenueSceneViews.build(_venue_picture_id(venue), speaker)
		_line_panel.add_child(_scene)
		_line_panel.move_child(_scene, _line_panel.get_node("CardHost").get_index())
		_line_panel.set_ground(OfficeFrameStyles.look()["ground"])


## The scene of the last overheard line is taken down before another line or the pop-up closing.
func _clear_scene() -> void:
	if _scene != null:
		if _scene.get_parent() != null:
			_scene.get_parent().remove_child(_scene)   # out of the tree now, so a new scene is the only one in it
		_scene.queue_free()
		_scene = null


func _on_keep_listening() -> void:
	if not _continue_to.is_empty():
		_enter_place(str(_continue_to["venue"]), str(_continue_to["screen"]))
		return
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
