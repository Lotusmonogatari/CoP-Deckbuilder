class_name TravelText
extends RefCounted
## The words for the two offices and the ways between them (two offices, 2026-11-20). Every sentence is a Text row;
## this only picks which one, so the screens and the briefing say a place or a mode the same way.


## How a travel mode reads ("Rail pass", "Plane ticket").
static func mode_name(mode: String) -> String:
	match mode:
		Travel.TICKET:
			return Text.say("travel.mode_ticket")
		Travel.CAR:
			return Text.say("travel.mode_car")
		Travel.PLANE:
			return Text.say("travel.mode_plane")
	return Text.say("travel.mode_pass")


## Where a trip goes: "the Capitol", or the town of this protagonist's District office ("Noheji").
static func place_name(office: String) -> String:
	if Offices.normalize(office) == Offices.DISTRICT:
		var town := GameState.district_office_name()
		return town if not town.is_empty() else Text.say("travel.district_plain")
	return Text.say("travel.place_capitol")


## "You are at the Capitol." / "You are at your District office in Noheji."
static func here_line() -> String:
	if GameState.office_location == Offices.DISTRICT:
		var town := GameState.district_office_name()
		if town.is_empty():
			return Text.say("travel.here_district_plain")
		return Text.say("travel.here_district", {"place": town})
	return Text.say("travel.here_capitol")


## Puts the mode's picture beside the words on a travel-mode button (a rail pass card, a ticket, a car, a plane). No picture
## drawn: the button is as it was. The picture is scaled to the button's height; the text, name and hours do not change.
static func dress_mode_icon(button: Button, mode: String, height: float) -> void:
	var icon := ArtLoader.mode_icon(mode)
	if icon == null:
		return
	button.icon = icon
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_constant_override("icon_max_width", int(height))


## The word on a level's badge: where it starts. Empty for Either (nothing to say).
static func level_badge(tag: Variant) -> String:
	match Offices.normalize(tag):
		Offices.CAPITOL:
			return Text.say("briefing.location_capitol")
		Offices.DISTRICT:
			return Text.say("briefing.location_district")
	return Text.say("briefing.location_either")
