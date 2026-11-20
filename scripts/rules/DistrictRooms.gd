class_name DistrictRooms
extends RefCounted
## The District versions of the shared rooms (2026-11-20, Cameron). The Lobbyist Meeting, Policy Study and Media Ambush rooms are
## shared by every protagonist; at the District office each of them shows its own picture for the protagonist standing there:
## the first for PC01, the second for PC02, the third for PC03, the fourth for PC04 (data/art.json "district_backgrounds").
## Pure, like everything in scripts/rules/: the pictures and the facts come in as arguments.


## The picture id a shared room shows at the District for this protagonist, or "" when the player is not at the District, the
## room is not one of the shared ones, or the list has no picture for this protagonist.
static func picture(rooms: Dictionary, room_id: String, protagonist_id: String, at_district: bool) -> String:
	if not at_district or not rooms.get(room_id) is Array:
		return ""
	var number := protagonist_number(protagonist_id)
	var list: Array = rooms[room_id]
	if number < 1 or number > list.size():
		return ""
	return str(list[number - 1])


## "PC03" gives 3; anything else gives 0.
static func protagonist_number(protagonist_id: String) -> int:
	if protagonist_id.length() < 3 or not protagonist_id.begins_with("PC"):
		return 0
	var digits := protagonist_id.substr(2)
	return int(digits) if digits.is_valid_int() else 0
