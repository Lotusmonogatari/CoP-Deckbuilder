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
## The tracks screen of a station, over the concourse (so its Back control returns to the concourse).
var _tracks_panel: Overlay
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
	_tips_panel = _panel("TipsPanel")
	_tracks_panel = _panel("StationTracksPanel")
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


## Step out shows at both offices; when it cannot be used (a level, a full week) it is greyed and says why.
func refresh_button() -> void:
	if _step_button == null:
		return
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
	var activity := VenueRules.activity_of(DataDB.venue_activities, venue_id)
	var built := VenueRules.is_built(activity)
	var card := OfficeFrameStyles.card(look)
	card.name = "VenueCard_" + venue_id
	var column := card.get_node("Column") as VBoxContainer
	# A small square of the place's picture at the left, its name and blurb beside it (the mock-up's place card, 2026-11-24).
	var top := HBoxContainer.new()
	top.name = "VenueTop"
	top.add_theme_constant_override("separation", 16)
	var thumb := _picture(str(venue.get("background", "")), 170.0)
	thumb.name = "VenueThumb"
	thumb.custom_minimum_size = Vector2(170, 170)
	thumb.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	thumb.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	top.add_child(thumb)
	var words := UiKit.tight_column()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(words)
	column.add_child(top)
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
		go.pressed.connect(show_venue.bind(venue_id))
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
	if venue.is_empty() or not VenueRules.is_built(activity):
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
			tracks.pressed.connect(_show_tracks.bind(venue_id))
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
	for panel: Overlay in [_tracks_panel, _line_panel, _venue_panel, _map_panel, _tips_panel]:
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
