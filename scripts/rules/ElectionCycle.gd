class_name ElectionCycle
extends RefCounted
## The election calendar (P20, 2026-11-26, Cameron). Each cycle (the Election Cycles tab) has three dates: the Banners date (the party's call for
## candidates, Banners of War Rising), Campaign Open (Gladiators of War Unleashed) and Election Day (Sengoku no Hi). Between cycles the game is
## `building`; from the Banners date it is `mustering` until the day before Campaign Open; `campaign` runs to the day before Election Day.
##
## Phases (the codes are data and code names; the player sees the Text rows campaign.phase.*):
##   building      the cycle ahead is still far off (no banner)
##   announcement  the Banners date itself, one day; it also starts mustering (is_mustering is true for it)
##   mustering     Banners date + 1 to the day before Campaign Open
##   campaign      Campaign Open to the day before Election Day
##   election_day  Election Day itself
##
## A date is a day number on WeekCalendar's scale (WeekCalendar.parse_date turns "YY.MM.DD" into one). Pure and UI-free (CLAUDE.md section 12).

const BUILDING := "building"
const ANNOUNCEMENT := "announcement"
const MUSTERING := "mustering"
const CAMPAIGN := "campaign"
const ELECTION_DAY := "election_day"


## The Election Cycles rows with their dates as day numbers, earliest first:
## [{id, banners, open, day, player_runs}]. A row with a date that is not real is left out (the exporter rejects it).
static func normalized(cycles: Array) -> Array:
	var out: Array = []
	for row: Variant in cycles:
		var cycle := row as Dictionary
		if cycle.has("banners") and cycle.has("day"):
			out.append(cycle)   # already normalized
			continue
		var banners := WeekCalendar.parse_date(str(cycle.get("banners_date", "")))
		var open := WeekCalendar.parse_date(str(cycle.get("campaign_open_date", "")))
		var day := WeekCalendar.parse_date(str(cycle.get("election_day", "")))
		if banners < 0 or open < 0 or day < 0:
			continue
		out.append({"id": str(cycle.get("cycle_id", "")), "banners": banners, "open": open, "day": day,
			"player_runs": str(cycle.get("player_runs", "Y")).strip_edges().to_upper() != "N"})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["day"]) < int(b["day"]))
	return out


## The cycle ahead of `date` (the first whose Election Day is today or later), or {} when every cycle is behind.
static func cycle_ahead(date: int, cycles: Array) -> Dictionary:
	for cycle: Dictionary in normalized(cycles):
		if date <= int(cycle["day"]):
			return cycle
	return {}


## Which phase `date` is in, and for which cycle: {cycle_id, phase, player_runs}. After the last Election Day there is no cycle ahead: the phase
## is `building` with a blank cycle_id.
static func phase_on(date: int, cycles: Array) -> Dictionary:
	var cycle := cycle_ahead(date, cycles)
	if cycle.is_empty():
		return {"cycle_id": "", "phase": BUILDING, "player_runs": true}
	var phase := BUILDING
	if date == int(cycle["day"]):
		phase = ELECTION_DAY
	elif date >= int(cycle["open"]):
		phase = CAMPAIGN
	elif date > int(cycle["banners"]):
		phase = MUSTERING
	elif date == int(cycle["banners"]):
		phase = ANNOUNCEMENT
	return {"cycle_id": str(cycle["id"]), "phase": phase, "player_runs": bool(cycle["player_runs"])}


## True for the phases that follow the Banners date, the announcement day included: the sprint (the rise limit and the rewards of campaign
## actions) starts that day.
static func is_mustering(phase: String) -> bool:
	return phase == MUSTERING or phase == ANNOUNCEMENT


## True when the campaign proper is on, so the weekly limit on campaign actions is lifted.
static func is_campaign(phase: String) -> bool:
	return phase == CAMPAIGN or phase == ELECTION_DAY


## True from 1 January after an Election Day (while campaign staff may be hired again): the date is on or after 1 January following the latest
## Election Day that has passed.
static func is_rehire_window(date: int, cycles: Array) -> bool:
	var latest := -1
	for cycle: Dictionary in normalized(cycles):
		if int(cycle["day"]) < date:
			latest = int(cycle["day"])
	if latest < 0:
		return false
	var year: int = int(WeekCalendar.civil_from_days(latest)[0])
	return date >= WeekCalendar.days_from_civil(year + 1, 1, 1)


## True from the day after an Election Day to 31 December of that year: campaign staff have gone home and cannot be hired yet.
static func hiring_blocked(date: int, cycles: Array) -> bool:
	for cycle: Dictionary in normalized(cycles):
		var day := int(cycle["day"])
		if date > day:
			var year: int = int(WeekCalendar.civil_from_days(day)[0])
			if date < WeekCalendar.days_from_civil(year + 1, 1, 1):
				return true
	return false


## True on the day after an Election Day: the day every campaign staff member leaves.
static func is_day_after_election(date: int, cycles: Array) -> bool:
	for cycle: Dictionary in normalized(cycles):
		if int(cycle["day"]) + 1 == date:
			return true
	return false


## The Election Day of the cycle the player steps aside from (Player Runs N), as a day number; -1 when every cycle is run by the player.
static func run_end_date(cycles: Array) -> int:
	for cycle: Dictionary in normalized(cycles):
		if not bool(cycle["player_runs"]):
			return int(cycle["day"])
	return -1


## Days from `date` to the next phase boundary the player is counting toward: {next, days}. While building it is the Banners date; during
## announcement and mustering, Campaign Open; during the campaign, Election Day. {"", 0} on Election Day or after the last election.
static func days_until_next_phase(date: int, cycles: Array) -> Dictionary:
	var cycle := cycle_ahead(date, cycles)
	if cycle.is_empty():
		return {"next": "", "days": 0}
	match str(phase_on(date, cycles)["phase"]):
		BUILDING:
			return {"next": ANNOUNCEMENT, "days": int(cycle["banners"]) - date}
		ANNOUNCEMENT, MUSTERING:
			return {"next": CAMPAIGN, "days": int(cycle["open"]) - date}
		CAMPAIGN:
			return {"next": ELECTION_DAY, "days": int(cycle["day"]) - date}
	return {"next": "", "days": 0}


## True when an Election Day falls from `from_day` up to (not including) `to_day`: a week that has just ended passed an election.
static func passed_between(from_day: int, to_day: int, cycles: Array) -> bool:
	for cycle: Dictionary in normalized(cycles):
		if int(cycle["day"]) >= from_day and int(cycle["day"]) < to_day:
			return true
	return false


## The day a phase starts in the cycle ahead of `date`: ANNOUNCEMENT and MUSTERING start on the Banners date, CAMPAIGN on Campaign Open,
## ELECTION_DAY on Election Day. -1 when there is no cycle ahead or the phase is `building`.
static func start_of(phase: String, date: int, cycles: Array) -> int:
	var cycle := cycle_ahead(date, cycles)
	if cycle.is_empty():
		return -1
	match phase:
		ANNOUNCEMENT, MUSTERING:
			return int(cycle["banners"])
		CAMPAIGN:
			return int(cycle["open"])
		ELECTION_DAY:
			return int(cycle["day"])
	return -1


## The first cycle (earliest Election Day) the player runs in whose Campaign Open is today or earlier and whose id is not in `done`: the one whose
## selection card is owed. {} when none. `done` is the cycle IDs that already have a selection result. The card is owed from Campaign Open up to
## and including Election Day (a player who somehow reaches Election Day without one still gets it).
static func selection_owed(date: int, cycles: Array, done: Array) -> Dictionary:
	for cycle: Dictionary in normalized(cycles):
		if bool(cycle["player_runs"]) and date >= int(cycle["open"]) and not done.has(str(cycle["id"])):
			return cycle
	return {}


## The first cycle whose Election Day is today or earlier and that has not been settled (its id is not in `done`): {} when none.
static func election_owed(date: int, cycles: Array, done: Array) -> Dictionary:
	for cycle: Dictionary in normalized(cycles):
		if date >= int(cycle["day"]) and not done.has(str(cycle["id"])):
			return cycle
	return {}
