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


# --- When a person is about (2026-11-25, Sapporo Stage) ----------------------------------------------------------------------------------
# Days ("Wed; Sun") and Months ("10-12; 4-7", a range may wrap: "8-3" is August through March) say when a person is about; blank means always.
# VEN04 and VEN05 perform on the Stage on their own days and months. A Speaker cell may list several people ("VEN04|VEN05"): whichever is about.

const WEEKDAY_NAMES := ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]


## The weekdays of a Days cell as 0 = Sunday ... 6 = Saturday; [] for blank. A name is read by its first three letters.
static func days_of(cell: Variant) -> Array[int]:
	var out: Array[int] = []
	if cell == null:
		return out
	for part: String in str(cell).replace(",", ";").split(";"):
		var name := part.strip_edges().to_lower().left(3)
		if WEEKDAY_NAMES.has(name):
			out.append(WEEKDAY_NAMES.find(name))
	return out


## The months (1 to 12) of a Months cell: "10-12; 4-7", "8", "11-2" (wrapping past December); [] for blank.
static func months_of(cell: Variant) -> Array[int]:
	var out: Array[int] = []
	if cell == null:
		return out
	for part: String in str(cell).replace(",", ";").split(";"):
		var text := part.strip_edges()
		if text.is_empty():
			continue
		var ends := text.split("-")
		var first := int(ends[0])
		var last := int(ends[ends.size() - 1])
		if first < 1 or first > 12 or last < 1 or last > 12:
			continue
		var month := first
		while true:
			if not out.has(month):
				out.append(month)
			if month == last:
				break
			month = month % 12 + 1
	return out


## Whether a person is about on a weekday (0 = Sunday) in a month (1 to 12): blank Days and Months mean always.
static func present_on(character: Dictionary, weekday: int, month: int) -> bool:
	var days := days_of(character.get("days"))
	var months := months_of(character.get("months"))
	return (days.is_empty() or days.has(weekday)) and (months.is_empty() or months.has(month))


## True for a person who keeps a schedule (Days or Months filled): a performer on the Stage.
static func is_scheduled(character: Dictionary) -> bool:
	return not days_of(character.get("days")).is_empty() or not months_of(character.get("months")).is_empty()


## The people a Speaker cell lists: "VEN04|VEN05" gives both, "area" or one ID gives itself.
static func speakers_of(cell: String) -> Array[String]:
	var out: Array[String] = []
	for part: String in cell.split("|"):
		var id := part.strip_edges()
		if not id.is_empty():
			out.append(id)
	return out


## The people who appear at a venue and are about on that weekday and month (the rows in the tab's order).
static func pool_present(characters: Array, venue: Dictionary, weekday: int, month: int) -> Array:
	var out: Array = []
	for row: Variant in pool_for(characters, venue):
		if present_on(row as Dictionary, weekday, month):
			out.append(row)
	return out
