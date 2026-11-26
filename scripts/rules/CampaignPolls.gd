class_name CampaignPolls
extends RefCounted
## Campaign polls (P20, 2026-11-26, Cameron): a read-only report of the campaign's strength with a margin of error, on a schedule.
##
##   due()      is today a poll day: Mondays, every poll_every_weeks_building weeks while the election is far off (the first on the first Monday
##              after the Campaign Office opens), every poll_every_weeks_late weeks during mustering and the campaign, plus a final poll on the
##              last workday before Election Day. None in a cycle the player steps aside from (Player Runs N).
##   reading()  the strength +/- a margin, shifted by a seeded offset, so the range always contains the true value and the same run, date and
##              phase always give the same reading.
##   outlook()  the selection outcome the range points to ("likely X, could be Y").
##   movers()   which input rose most and which fell most since the last poll, as Text keys.
##   source()   who ran the poll: the Campaign Office internally while far off, then the three national outlets in turn.
## Pure and UI-free (CLAUDE.md section 12).

const SOURCE_INTERNAL := "poll.source.internal"
const OUTLET_SOURCES: Array[String] = ["poll.source.pr01", "poll.source.pr02", "poll.source.pr03"]

const MONDAY := 1


static func _weekday(date: int) -> int:
	return posmod(date + 4, 7)   # day 0 (1970-01-01) was a Thursday; 0 = Sunday


static func _is_workday(date: int) -> bool:
	var day := _weekday(date)
	return day >= 1 and day <= 5


## The last workday (Monday to Friday) before `election_day`.
static func final_poll_day(election_day: int) -> int:
	var day := election_day - 1
	while not _is_workday(day):
		day -= 1
	return day


## Whether a poll is due on `date`. `last_poll` is the day number of the previous poll (-1 for none), `office_open` the day the Campaign Office
## opened (-1 while it has not), `cycles` the Election Cycles rows.
static func due(date: int, last_poll: int, office_open: int, cycles: Array) -> bool:
	var info := ElectionCycle.phase_on(date, cycles)
	if str(info["cycle_id"]).is_empty() or not bool(info["player_runs"]) or office_open < 0 or date <= office_open:
		return false
	var cycle := ElectionCycle.cycle_ahead(date, cycles)
	if date == final_poll_day(int(cycle["day"])):
		return last_poll != date
	if _weekday(date) != MONDAY:
		return false
	var phase := str(info["phase"])
	if phase == ElectionCycle.ELECTION_DAY:
		return false
	var weeks := Levers.whole("poll_every_weeks_late") if phase != ElectionCycle.BUILDING else Levers.whole("poll_every_weeks_building")
	if last_poll < 0:
		return true   # the first Monday after the office opens
	return date - last_poll >= maxi(1, weeks) * 7


## The margin of error for a poll in `phase`; the final poll has its own.
static func margin(phase: String, is_final: bool) -> int:
	if is_final:
		return Levers.whole("poll_margin_final")
	if phase == ElectionCycle.CAMPAIGN or phase == ElectionCycle.ELECTION_DAY:
		return Levers.whole("poll_margin_campaign")
	if ElectionCycle.is_mustering(phase):
		return Levers.whole("poll_margin_mustering")
	return Levers.whole("poll_margin_building")


## The poll's range, {low, high}, as whole numbers inside 0 to 100: the strength +/- the margin, shifted by a seeded offset of at most half the
## margin either way (from the run seed and the date). The true strength is always inside it, and the same inputs give the same range.
static func reading(strength: float, phase: String, is_final: bool, run_seed: int, date: int) -> Dictionary:
	var spread := margin(phase, is_final)
	var half := spread / 2
	var offset := 0
	if half > 0:
		offset = posmod(hash("%d|%d" % [run_seed, date]), 2 * half + 1) - half
	var low := clampi(int(floor(strength - spread + offset)), 0, 100)
	var high := clampi(int(ceil(strength + spread + offset)), 0, 100)
	return {"low": low, "high": high}


## The selection outcome the range points to: {likely, could_be}. `likely` is the outcome at the middle of the range; `could_be` is a different
## outcome the range also reaches (the lower one when both ends differ from the middle), or "" when the whole range gives one outcome.
## `inputs`: alignment, party_support, committee_standing (the strength is the range's).
static func outlook(range_values: Dictionary, inputs: Dictionary) -> Dictionary:
	var at_low := _outcome_at(float(range_values["low"]), inputs)
	var at_high := _outcome_at(float(range_values["high"]), inputs)
	var at_mid := _outcome_at((float(range_values["low"]) + float(range_values["high"])) / 2.0, inputs)
	var other := ""
	if at_low != at_mid:
		other = at_low
	elif at_high != at_mid:
		other = at_high
	return {"likely": at_mid, "could_be": other}


static func _outcome_at(strength: float, inputs: Dictionary) -> String:
	return str(Selection.decide(strength, float(inputs.get("alignment", 50)), int(inputs.get("party_support", 0)), int(inputs.get("committee_standing", 0)))["outcome"])


## Which input rose most and which fell most since the last poll, as Text keys: {up, down} ("" when nothing rose or fell). `previous` and `parts`
## are ElectionStrength.components() lists ({id, points, max}); a tie goes to the input that comes first in the list.
static func movers(previous: Array, parts: Array) -> Dictionary:
	var before := {}
	for part: Variant in previous:
		before[str((part as Dictionary)["id"])] = float((part as Dictionary)["points"])
	var up_id := ""
	var down_id := ""
	var best_up := 0.0
	var best_down := 0.0
	for part: Variant in parts:
		var id := str((part as Dictionary)["id"])
		var change := float((part as Dictionary)["points"]) - float(before.get(id, (part as Dictionary)["points"]))
		if change > best_up:
			best_up = change
			up_id = id
		if change < best_down:
			best_down = change
			down_id = id
	return {"up": ("poll.up." + up_id) if not up_id.is_empty() else "", "down": ("poll.down." + down_id) if not down_id.is_empty() else ""}


## Who ran the poll, as a Text key: the Campaign Office's own poll while the election is far off, then the national outlets in turn.
## `late_poll_number` counts the mustering and campaign polls so far (0 for the first).
static func source(phase: String, late_poll_number: int) -> String:
	if phase == ElectionCycle.BUILDING:
		return SOURCE_INTERNAL
	return OUTLET_SOURCES[posmod(late_poll_number, OUTLET_SOURCES.size())]
