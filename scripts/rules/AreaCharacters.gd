class_name AreaCharacters
extends RefCounted
## The open-world people (2026-11-25, Cameron): VEN## stand in the venue(s) their Site names, CA## in the Capital Area, CB## in the Capitol
## interior, DI## in the District. A zone person's Site is blank (the whole zone) or narrows them to venues of that zone. A venue line that
## names the speaker `area` takes someone from the venue's pool, chosen from a seed so a reload never reshuffles. Pure: no screens, no
## autoloads, no files (the tests prove it).

## The Speaker word that means "someone from this venue's pool".
const ANY := "area"

## Which zone each zone prefix belongs to, as the Venues tab spells it.
const ZONE_OF_PREFIX := {"CA": "Capital Area", "CB": "Capitol Building", "DI": "District"}


## True for an ID that is an Area Characters ID: VEN, CA, CB or DI followed by a number.
static func is_area_id(id: String) -> bool:
	for prefix: String in ["VEN", "CA", "CB", "DI"]:
		if id.begins_with(prefix) and id.length() > prefix.length() and id.substr(prefix.length()).is_valid_int():
			return true
	return false


## The venue IDs in a row's Site, split on semicolons or commas.
static func sites(character: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var raw: Variant = character.get("site")
	if raw == null:
		return out
	for part: String in str(raw).replace(",", ";").split(";"):
		var venue_id := part.strip_edges()
		if not venue_id.is_empty():
			out.append(venue_id)
	return out


## Whether this person appears at a venue (a Venues row): a VEN person only at the venues in Site; a zone person in their zone, narrowed to
## Site when it is filled.
static func appears_at(character: Dictionary, venue: Dictionary) -> bool:
	var named := sites(character)
	if not named.is_empty() and not named.has(str(venue.get("venue_id", ""))):
		return false
	var id := str(character.get("character_id", ""))
	if id.begins_with("VEN"):
		return not named.is_empty()
	return str(venue.get("zone", "")) == str(ZONE_OF_PREFIX.get(id.substr(0, 2), ""))


## Everyone who may appear at a venue, in the tab's order.
static func pool_for(characters: Array, venue: Dictionary) -> Array:
	var out: Array = []
	for row: Variant in characters:
		if appears_at(row as Dictionary, venue):
			out.append(row)
	return out


## The pool's pick for a seed ("" for an empty pool): the same seed always gives the same person.
static func pick(pool: Array, seed_value: int) -> String:
	if pool.is_empty():
		return ""
	return str((pool[absi(seed_value) % pool.size()] as Dictionary).get("character_id", ""))
