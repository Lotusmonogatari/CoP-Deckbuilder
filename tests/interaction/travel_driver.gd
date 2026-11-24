class_name TravelDriver
extends Node
## Two offices, slice 1 (2026-11-20), moved to the stations on 2026-11-24: the Office as a player uses it. The train strip is on the
## station screens now (the Capitol's Sapporo Super Station: concourse, then tracks; the District office's own station). The strip
## states where it goes, how long and by what before it is pressed; the popup states the cost again; a trip spends the hours,
## changes the office picture and the level list (a level is listed only at its own office); a trip that cannot be taken says why.

const STYLES := [UiStyles.LIVING_OFFICE, UiStyles.BROADCAST, UiStyles.WOODBLOCK]

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	OS.set_environment("COP_NO_RANDOM_EVENTS", "1")
	OS.set_environment("COP_NO_TRAVEL_FADE", "1")
	for style: String in STYLES:
		UiStyle.trying = style
		UiStyle.sync()
		GameState.start_new_run("PC04")
		GameState.awaiting_new_game = false
		GameState.calendar = WeekCalendar.fresh()
		await _open_office()
		await _trip(style)
		await _promise(style)
		await _tickets(style)
		await _own_levels(style)
	UiStyle.trying = ""
	UiStyle.sync()
	print("")
	if _failures.is_empty():
		print("TRAVEL TEST: PASS")
		get_tree().quit(0)
	else:
		print("TRAVEL TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_failures.append(what)


func _open_office() -> void:
	get_tree().change_scene_to_file("res://scenes/office_hours/OfficeScreen.tscn")
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout


func _screen() -> Node:
	return get_tree().current_scene


func _texts(node: Node) -> PackedStringArray:
	var out := PackedStringArray()
	for label: Node in node.find_children("*", "Label", true, false):
		out.append((label as Label).text)
	for button: Node in node.find_children("*", "Button", true, false):
		out.append((button as Button).text)
	return out


func _levels_panel() -> Overlay:
	_screen().call("_show_levels")
	await get_tree().create_timer(0.4).timeout
	return _screen().get_node("%LevelsPanel") as Overlay


func _left() -> int:
	return WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config())


## The train strip where the player stands: the Capitol's is on the tracks (reached from the concourse), the District office's is on
## its station screen. Null when the concourse's To the tracks button is greyed (the trip is refused).
func _strip_here() -> TravelStrip:
	var office := _screen()
	office.get("_venues").call("close_all")
	if GameState.office_location == Offices.CAPITOL:
		office.get("_venues").call("show_venue", "VN06")
		await get_tree().create_timer(0.4).timeout
		var tracks := office.get_node("VenuePanel").find_child("ToTracksButton", true, false) as Button
		if tracks == null or tracks.disabled:
			return null
		tracks.pressed.emit()
		await get_tree().create_timer(0.4).timeout
		return office.get_node("StationTracksPanel").find_child("TravelButton", true, false) as TravelStrip
	office.get("_venues").call("show_venue", "VN07")
	await get_tree().create_timer(0.4).timeout
	return office.get_node("VenuePanel").find_child("TravelButton", true, false) as TravelStrip


func _trip(style: String) -> void:
	var where := "in %s: " % style
	var office := _screen()
	# The Office no longer carries the strip or a row of modes.
	_expect(office.find_child("TravelButton", true, false) == null, where + "the Office has no train strip")
	_expect(office.find_child("TravelModes", true, false) == null, where + "and no row of travel modes")
	var button := await _strip_here()
	_expect(button != null, where + "the tracks have the train strip")
	if button == null:
		return
	_expect(button.text == "To Noheji · 7 h · Rail pass" and not button.disabled, where + "the strip says where, how long and how (%s)" % button.text)
	_expect(button.size.y >= 100.0 and button.get_global_rect().end.x <= 1081.0, where + "it is big enough and on screen")
	_expect(button.direction == 1, where + "from the Capitol the train is pulled to the right")

	# A short drag springs back and takes no trip; a long drag takes it.
	await _drag(button, 0.3)
	_expect(GameState.office_location == Offices.CAPITOL and _left() == 40, where + "a short drag takes no trip")
	_expect(button.progress() == 0.0, where + "and the train is back at the start (%.2f)" % button.progress())
	var report := office.get_node("%Report") as Label
	_expect(report.text.begins_with("You are at the Capitol."), where + "the Office says where you are (%s)" % report.text)

	# At the Capitol: Capitol and Either levels are listed, District levels are not.
	office.get("_venues").call("close_all")
	var levels := await _levels_panel()
	var seen := _texts(levels)
	_expect(seen.has("Hearing at the Committee on the Environment"), where + "a Capitol level is listed at the Capitol")
	_expect(seen.has("Meeting Lobbyists"), where + "an Either level is listed at the Capitol")
	_expect(not seen.has("Talking with Constituents"), where + "a District level is not listed at the Capitol")
	levels.close()
	await get_tree().process_frame

	# The popup says the cost before the trip is taken.
	button = await _strip_here()
	_tap(button)
	await get_tree().create_timer(0.3).timeout
	var panel := office.get_node("TravelPanel") as Overlay
	var words := _texts(panel)
	_expect(panel.visible, where + "the trip popup opens")
	_expect(words.has("Go to Noheji: 7 h by rail pass. Free on the member's rail pass."), where + "it states the trip (%s)" % [words])
	_expect(words.has("You will have 33 h left this week."), where + "and what is left")
	_expect(GameState.office_location == Offices.CAPITOL and _left() == 40, where + "nothing is spent until the trip is taken")
	var stay := _find_button(panel, "Stay here")
	_expect(stay != null, where + "there is a way to stay")
	if stay != null:
		stay.pressed.emit()
		await get_tree().process_frame
		_expect(not panel.visible and GameState.office_location == Offices.CAPITOL, where + "staying changes nothing")

	# Take it.
	_tap(button)
	await get_tree().create_timer(0.3).timeout
	var go := _find_button(panel, "Take the trip")
	_expect(go != null, where + "the popup has the button that takes the trip")
	if go == null:
		return
	go.pressed.emit()
	await get_tree().create_timer(0.5).timeout
	_expect(GameState.office_location == Offices.DISTRICT, where + "the player is at the District office")
	_expect(not office.get_node("VenuePanel").visible and not office.get_node("StationTracksPanel").visible, where + "the station screens closed behind the trip")
	_expect(_left() == 33, where + "seven hours were spent (%d left)" % _left())
	button = await _strip_here()
	_expect(button != null and button.text == "To the Capitol · 7 h · Rail pass", where + "the District station's strip now goes back (%s)" % [button.text if button != null else "none"])
	_expect(button != null and button.direction == -1, where + "from the District office the train is pulled to the left")
	_expect(report.text.begins_with("You are at your District office in Noheji."), where + "the Office says so (%s)" % report.text)
	var background: Variant = office.get("_background")
	_expect(background != null and str(background.art_id) == "DISTRICT_OFFICE_PC04", where + "the District office picture (a labelled placeholder until it is drawn)")

	# At the District: the lists swap.
	office.get("_venues").call("close_all")
	levels = await _levels_panel()
	seen = _texts(levels)
	_expect(seen.has("Talking with Constituents"), where + "a District level is listed at the District office")
	_expect(seen.has("Meeting Lobbyists"), where + "an Either level is listed there too")
	_expect(not seen.has("Hearing at the Committee on the Environment"), where + "a Capitol level is not")
	levels.close()
	await get_tree().process_frame

	# A trip that cannot be taken says why (Information Standard 2): the District station's strip is greyed with the reason, and so is
	# the Capitol concourse's To the tracks button.
	GameState.calendar = {"week": 0, "phase": WeekCalendar.WORK, "hours": 36}
	button = await _strip_here()
	_expect(button != null and button.disabled and button.text == "The trip takes 7 h and the week has less left.", where + "too few hours: greyed, with the reason (%s)" % [button.text if button != null else "none"])
	GameState.calendar = {"week": 0, "phase": WeekCalendar.WEEKEND, "hours": 0}
	button = await _strip_here()
	_expect(button != null and button.disabled and button.text == "No travel at the weekend.", where + "at the weekend: greyed, with the reason (%s)" % [button.text if button != null else "none"])
	GameState.office_location = Offices.CAPITOL
	GameState.calendar = {"week": 0, "phase": WeekCalendar.WORK, "hours": 36}
	_expect(await _strip_here() == null, where + "at the Capitol the concourse's To the tracks button is greyed when the trip is refused")
	var why := office.get_node("VenuePanel").find_child("ToTracksButton", true, false) as Button
	_expect(why != null and why.disabled and why.text == "The trip takes 7 h and the week has less left.", where + "and says why (%s)" % [why.text if why != null else "none"])
	GameState.calendar = WeekCalendar.fresh()

	# The drag takes the trip (the far side of the track), and back again.
	button = await _strip_here()
	await _drag(button, 0.9)
	_expect(GameState.office_location == Offices.DISTRICT and _left() == 33, where + "a long drag takes the trip (%s, %d left)" % [GameState.office_location, _left()])
	button = await _strip_here()
	await _drag(button, 0.9)
	_expect(GameState.office_location == Offices.CAPITOL and _left() == 26, where + "and a long drag from the District office brings the player back")
	# A greyed strip ignores a drag.
	GameState.office_location = Offices.DISTRICT
	GameState.calendar = {"week": 0, "phase": WeekCalendar.WORK, "hours": 36}
	button = await _strip_here()
	await _drag(button, 0.9)
	_expect(GameState.office_location == Offices.DISTRICT, where + "a greyed strip ignores the drag")
	GameState.office_location = Offices.CAPITOL
	GameState.calendar = WeekCalendar.fresh()
	office.get("_venues").call("close_all")


## A promise is kept at the office of the choice that made it (two offices, slice 3): the Promises panel says where, the Keep
## button is greyed with the reason at the other office, and the trip popup warns before the player leaves it behind.
func _promise(style: String) -> void:
	var where := "in %s: " % style
	var office := _screen()
	GameState.office_location = Offices.DISTRICT
	GameState.calendar = WeekCalendar.fresh()
	GameState.promises = []
	GameState.pay_commitments([{"kind": Promises.PROMISE_HOURS, "amount": 2, "within": 6}], "A visit", "BO01")
	office.call("_refresh_calendar")
	office.call("_show_promises")
	await get_tree().create_timer(0.3).timeout
	var panel := office.get("_promises_panel") as Overlay
	var keep := panel.find_child("Keep_*", true, false) as Button
	_expect(_texts(panel).has("Keep it at Noheji"), where + "the Promises panel says where it is kept (%s)" % [_texts(panel)])
	_expect(keep != null and not keep.disabled, where + "at the District office the promise can be kept")
	panel.close()
	office.call("_show_travel")
	await get_tree().create_timer(0.3).timeout
	var travel := office.get_node("TravelPanel") as Overlay
	var warned := false
	for line: String in _texts(travel):
		warned = warned or line.begins_with("Before you go:") and line.contains("Noheji")
	_expect(warned, where + "the trip popup warns about it (%s)" % [_texts(travel)])
	travel.close()
	GameState.office_location = Offices.CAPITOL
	office.call("_show_promises")
	await get_tree().create_timer(0.3).timeout
	keep = (office.get("_promises_panel") as Overlay).find_child("Keep_*", true, false) as Button
	_expect(keep != null and keep.disabled and keep.text == "Keep it at Noheji.", where + "at the Capitol the Keep button says where to go (%s)" % [keep.text if keep != null else "none"])
	(office.get("_promises_panel") as Overlay).close()
	GameState.promises = []
	GameState.office_location = Offices.CAPITOL


## Tickets (slice 4, at the stations since 2026-11-24): the concourse lists every way of going (the ones the player has no ticket for,
## and the one that is not theirs, greyed), a paid ticket is pulled like the pass and pleases three organizations, a plane is
## instant (its own confirm), a mixed level's briefing has a row to pay for its trips, and a trip can bring an encounter on the train.
func _tickets(style: String) -> void:
	var where := "in %s: " % style
	var office := _screen()
	GameState.office_location = Offices.CAPITOL
	GameState.calendar = WeekCalendar.fresh()
	GameState.inventory = {}
	office.get("_venues").call("show_venue", "VN06")
	await get_tree().create_timer(0.4).timeout
	var concourse := office.get_node("VenuePanel")
	var none_ticket := concourse.find_child("TravelMode_ticket", true, false) as Button
	var none_plane := concourse.find_child("TravelMode_plane", true, false) as Button
	var not_car := concourse.find_child("TravelMode_car", true, false) as Button   # null: PC04's fast mode is the plane
	_expect(none_ticket != null and none_ticket.disabled and none_ticket.text == "Paid train ticket · 7 h · 0 left", where + "with no ticket the paid ticket is greyed (%s)" % [none_ticket.text if none_ticket != null else "none"])
	_expect(none_plane != null and none_plane.disabled and none_plane.text == "Plane ticket · 2 h · 0 left", where + "and so is the plane (%s)" % [none_plane.text if none_plane != null else "none"])
	_expect(not_car == null, where + "the car is not PC04's, so it is not listed at all")
	GameState.add_item("SH42")
	GameState.add_item("SH44")
	GameState.add_item("SH44")
	office.get("_venues").call("show_venue", "VN06")
	await get_tree().create_timer(0.4).timeout
	var standing := int(GameState.booster_standing.get("BO14", 0))
	(office.get_node("VenuePanel").find_child("TravelMode_ticket", true, false) as Button).pressed.emit()
	await get_tree().create_timer(0.4).timeout
	var strip := await _strip_here()
	_expect(strip != null and strip.text == "To Noheji · 7 h · Paid train ticket", where + "the strip is set to the ticket (%s)" % [strip.text if strip != null else "none"])
	await _drag(strip, 0.9)
	_expect(GameState.office_location == Offices.DISTRICT and GameState.item_count("SH42") == 0, where + "the ticket was handed over")
	_expect(int(GameState.booster_standing.get("BO14", 0)) == standing + 1, where + "and the Commuter Committee noticed (+1 since P17)")
	# A plane: the confirm names the cost, then the trip is instant.
	office.get("_venues").call("close_all")
	office.get("_venues").call("show_venue", "VN07")
	await get_tree().create_timer(0.4).timeout
	var plane := office.get_node("VenuePanel").find_child("TravelMode_plane", true, false) as Button
	_expect(plane != null and plane.text == "Plane ticket · 2 h · 2 left", where + "the plane button says its hours and tickets (%s)" % [plane.text if plane != null else "none"])
	plane.pressed.emit()
	await get_tree().create_timer(0.3).timeout
	var panel := office.get_node("TravelPanel") as Overlay
	_expect(_texts(panel).has("Go to the Capitol: 2 h by plane ticket. Uses one plane ticket."), where + "the plane's confirm (%s)" % [_texts(panel)])
	var go := _find_button(panel, "Take the trip")
	go.pressed.emit()
	await get_tree().create_timer(0.4).timeout
	_expect(GameState.office_location == Offices.CAPITOL and GameState.item_count("SH44") == 1, where + "the plane took the player to the Capitol and used one ticket")

	# A mixed level's briefing: a row of ways to pay for the trips, and the hours follow the choice.
	GameState.calendar = WeekCalendar.fresh()
	GameState.add_item("SH44")   # two plane tickets: one for each trip
	var briefing := await _brief("LV10")
	var modes := briefing.find_child("TravelModes", true, false)
	_expect(modes != null, where + "LV10's briefing has the row of travel modes")
	var go_in := briefing.find_child("Confirm", true, false) as Button
	_expect(go_in != null and go_in.disabled, where + "by rail pass LV10 is too long for the week (%s)" % [go_in.text if go_in != null else "none"])
	var by_plane := briefing.find_child("TravelMode_plane", true, false) as Button
	_expect(by_plane != null and by_plane.text == "Plane ticket · 4 h" and not by_plane.disabled, where + "the plane row says 4 h")
	by_plane.pressed.emit()
	await get_tree().create_timer(0.5).timeout
	briefing = office.get_node("BriefingPanel") as LevelBriefingPanel
	go_in = briefing.find_child("Confirm", true, false) as Button
	_expect(go_in != null and not go_in.disabled and go_in.text == "Go in · 31 hours", where + "by plane the briefing says 31 hours and Go in is open (%s)" % [go_in.text if go_in != null else "none"])
	briefing.close()
	await get_tree().process_frame

	# An encounter: a trip brings one, and it is shown as an event.
	OS.unset_environment("COP_NO_RANDOM_EVENTS")
	DataDB.balance["travel_encounter_one_in"] = 1
	GameState.inventory = {}
	GameState.office_location = Offices.CAPITOL
	GameState.calendar = WeekCalendar.fresh()
	office.call("_refresh_calendar")
	strip = await _strip_here()
	await _drag(strip, 0.9)
	var event_panel := office.get_node("EventPanel") as Overlay
	_expect(event_panel.visible and _texts(event_panel).has("On the train"), where + "the trip brought an encounter (%s)" % [_texts(event_panel)])
	_expect(event_panel.find_child("EventChoice_C", true, false) != null, where + "with its choices")
	event_panel.close()
	DataDB.balance["travel_encounter_one_in"] = 8
	OS.set_environment("COP_NO_RANDOM_EVENTS", "1")
	GameState.office_location = Offices.CAPITOL
	GameState.inventory = {}


## A protagonist's own levels (slice 6): PC04 is the Aomori protagonist, so the Rokkasho level is listed at the District office and
## the bluefin quota at the Capitol; the Wakkanai levels (PC01's) never appear.
func _own_levels(style: String) -> void:
	var where := "in %s: " % style
	GameState.office_location = Offices.DISTRICT
	var panel := await _levels_panel()
	var seen := _texts(panel)
	_expect(seen.has("The Rokkasho Question"), where + "PC04's District level is listed at the District office")
	_expect(not seen.has("Keep the Sōya Line Running"), where + "PC01's is not")
	panel.close()
	await get_tree().process_frame
	GameState.office_location = Offices.CAPITOL
	panel = await _levels_panel()
	seen = _texts(panel)
	_expect(seen.has("Ōma's Bluefin Quota"), where + "PC04's Capitol level is listed at the Capitol (autumn)")
	_expect(not seen.has("The Sakhalin Ferry"), where + "PC01's is not")
	panel.close()
	await get_tree().process_frame


func _brief(level_id: String) -> LevelBriefingPanel:
	var here := Offices.normalize(DataDB.get_level(level_id).get("location"))
	GameState.office_location = Offices.CAPITOL if here == Offices.EITHER else here
	_screen().call("_on_level_chosen", DataDB.get_level(level_id))
	await get_tree().create_timer(0.5).timeout
	return _screen().get_node("BriefingPanel") as LevelBriefingPanel


## A press on the train, a drag of `share` of the track in the way it goes, and a release (what a finger does).
func _drag(strip: TravelStrip, share: float) -> void:
	var y := strip.size.y * 0.5
	var start_x := TravelStrip.MARGIN + 40.0 if strip.direction > 0 else strip.size.x - TravelStrip.MARGIN - 40.0
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(start_x, y)
	strip._gui_input(press)
	var move := InputEventMouseMotion.new()
	move.position = Vector2(start_x + float(strip.direction) * share * strip.track_length(), y)
	strip._gui_input(move)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = move.position
	strip._gui_input(release)
	await get_tree().create_timer(0.6).timeout


## A press and a release in the same place: a tap.
func _tap(strip: TravelStrip) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(100.0, 40.0)
	strip._gui_input(press)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(102.0, 40.0)
	strip._gui_input(release)


func _find_button(node: Node, text: String) -> Button:
	for button: Node in node.find_children("*", "Button", true, false):
		if (button as Button).text == text:
			return button as Button
	return null
