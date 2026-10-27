class_name WeekCalendar
extends RefCounted
## The game calendar (2026-10-23, Cameron). Time is counted in hours. A work
## week is five 8-hour days pooled together (Monday to Friday, 40 hours); the
## weekend is an optional pool of two 4-hour days. Each stage costs the hours
## in the Stages tab. Hours that run past a pool are lost: the week does not
## cross over. Day and week are derived from one small state:
##
##   { "week": 0, "phase": "work" | "weekend", "hours": hours used in the phase }
##
## The run starts on Monday 1 October 2018 (Balance levers). Pure and UI-free
## (CLAUDE.md section 12): every number comes in through `cfg`.

const WORK := "work"
const WEEKEND := "weekend"

## What a level cannot be started for. "" means it can.
const REFUSE_WEEK_OVER := "week_over"
const REFUSE_NOT_WEEKEND := "not_weekend"
const REFUSE_TOO_LONG := "too_long"


## The calendar levers, read once from Balance with the agreed defaults.
static func settings(balance: Dictionary) -> Dictionary:
	return {
		"workday_hours": maxi(1, int(balance.get("workday_hours", 8))),
		"work_days": maxi(1, int(balance.get("work_days_per_week", 5))),
		"weekend_day_hours": maxi(1, int(balance.get("weekend_day_hours", 4))),
		"weekend_days": maxi(1, int(balance.get("weekend_days", 2))),
		"start_year": int(balance.get("calendar_start_year", 2018)),
		"start_month": int(balance.get("calendar_start_month", 10)),
		"start_day": int(balance.get("calendar_start_day", 1)),
	}


static func fresh() -> Dictionary:
	return {"week": 0, "phase": WORK, "hours": 0}


## A state read from a save: anything missing or odd becomes a fresh week.
static func normalized(raw: Variant) -> Dictionary:
	if not (raw is Dictionary):
		return fresh()
	var phase := str((raw as Dictionary).get("phase", WORK))
	return {
		"week": maxi(0, int((raw as Dictionary).get("week", 0))),
		"phase": phase if phase == WEEKEND else WORK,
		"hours": maxi(0, int((raw as Dictionary).get("hours", 0))),
	}


## Hours in one day of the phase, and in the whole phase.
static func day_limit(phase: String, cfg: Dictionary) -> int:
	return int(cfg["weekend_day_hours"]) if phase == WEEKEND else int(cfg["workday_hours"])


static func pool_hours(phase: String, cfg: Dictionary) -> int:
	if phase == WEEKEND:
		return int(cfg["weekend_day_hours"]) * int(cfg["weekend_days"])
	return int(cfg["workday_hours"]) * int(cfg["work_days"])


## Hours left in the current phase (the work week, or the weekend).
static func hours_left(state: Dictionary, cfg: Dictionary) -> int:
	return maxi(0, pool_hours(str(state["phase"]), cfg) - int(state["hours"]))


static func is_full(state: Dictionary, cfg: Dictionary) -> bool:
	return hours_left(state, cfg) <= 0


## Hours left in today only. A day that has just ended reads as a fresh day.
static func hours_left_today(state: Dictionary, cfg: Dictionary) -> int:
	var phase := str(state["phase"])
	if is_full(state, cfg):
		return 0
	var limit := day_limit(phase, cfg)
	return limit - (int(state["hours"]) % limit)


## 0-based day within the phase (0 = Monday, or Saturday), never past its last day.
@warning_ignore("integer_division")
static func day_index(state: Dictionary, cfg: Dictionary) -> int:
	var phase := str(state["phase"])
	var days := int(cfg["weekend_days"]) if phase == WEEKEND else int(cfg["work_days"])
	return mini(int(state["hours"]) / day_limit(phase, cfg), days - 1)


## Whether it is the last weekday: the day the week may be ended early.
static func is_last_workday(state: Dictionary, cfg: Dictionary) -> bool:
	return str(state["phase"]) == WORK and day_index(state, cfg) == int(cfg["work_days"]) - 1


## Whether the player may choose to end the work week with hours still unused.
static func can_end_work_week_early(state: Dictionary, cfg: Dictionary) -> bool:
	return is_last_workday(state, cfg) and not is_full(state, cfg)


## The state after `hours` more have passed. Hours past the pool are dropped.
static func advance(state: Dictionary, hours: int, cfg: Dictionary) -> Dictionary:
	var next := state.duplicate()
	var pool := pool_hours(str(state["phase"]), cfg)
	next["hours"] = mini(pool, int(state["hours"]) + maxi(0, hours))
	return next


## Work week over (finished or ended early): the weekend begins. `skipped` is
## the work hours that were never used, which still count as time passing.
static func end_work_week(state: Dictionary, cfg: Dictionary) -> Dictionary:
	var skipped := hours_left(state, cfg) if str(state["phase"]) == WORK else 0
	return {"state": {"week": int(state["week"]), "phase": WEEKEND, "hours": 0}, "skipped": skipped}


## The weekend (played or not) is over: a new week starts on Monday. `skipped`
## is the weekend hours unused, which still count as time passing.
static func go_home(state: Dictionary, cfg: Dictionary) -> Dictionary:
	var skipped := pool_hours(WEEKEND, cfg)
	if str(state["phase"]) == WEEKEND:
		skipped = hours_left(state, cfg)
	return {"state": {"week": int(state["week"]) + 1, "phase": WORK, "hours": 0}, "skipped": skipped}


## Why a level of `level_hours` hours (flagged weekend-OK or not) cannot be
## started now, or "". Weekdays take any level and let the extra hours spill
## away; the weekend takes only flagged levels that fit in what is left.
static func level_refusal(state: Dictionary, cfg: Dictionary, level_hours: int,
		weekend_ok: bool) -> String:
	if is_full(state, cfg):
		return REFUSE_WEEK_OVER if str(state["phase"]) == WORK else REFUSE_TOO_LONG
	if str(state["phase"]) == WEEKEND:
		if not weekend_ok:
			return REFUSE_NOT_WEEKEND
		if level_hours > hours_left(state, cfg):
			return REFUSE_TOO_LONG
	return ""


## Days since 1970-01-01 for a calendar date (the standard civil-day count).
@warning_ignore("integer_division")
static func days_from_civil(year: int, month: int, day: int) -> int:
	var y := year - (1 if month <= 2 else 0)
	var era := (y if y >= 0 else y - 399) / 400
	var yoe := y - era * 400
	var mp := (month + 9) % 12
	var doy := (153 * mp + 2) / 5 + day - 1
	var doe := yoe * 365 + yoe / 4 - yoe / 100 + doy
	return era * 146097 + doe - 719468


## The date for a day count, as [year, month, day].
@warning_ignore("integer_division")
static func civil_from_days(days: int) -> Array:
	var z := days + 719468
	var era := (z if z >= 0 else z - 146096) / 146097
	var doe := z - era * 146097
	var yoe := (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
	var y := yoe + era * 400
	var doy := doe - (365 * yoe + yoe / 4 - yoe / 100)
	var mp := (5 * doy + 2) / 153
	var d := doy - (153 * mp + 2) / 5 + 1
	var m := mp + (3 if mp < 10 else -9)
	return [y + (1 if m <= 2 else 0), m, d]


## Days since the start date: a week is seven days, the weekend follows Friday.
static func day_offset(state: Dictionary, cfg: Dictionary) -> int:
	var in_week := day_index(state, cfg)
	if str(state["phase"]) == WEEKEND:
		in_week += int(cfg["work_days"])
	return int(state["week"]) * 7 + in_week


## Today as one running day number (the same scale days_from_civil uses), so
## a date can be compared with it.
static func today_number(state: Dictionary, cfg: Dictionary) -> int:
	var start := days_from_civil(int(cfg["start_year"]), int(cfg["start_month"]), int(cfg["start_day"]))
	return start + day_offset(state, cfg)


## "DD.MM.YY" (as typed in the Events tab's On Date column) as a day number; -1 when it is
## not a real date. Two-digit years are 20xx.
static func parse_date(text: String) -> int:
	var parts := text.strip_edges().split(".")
	if parts.size() != 3 or not (parts[0].is_valid_int() and parts[1].is_valid_int() and parts[2].is_valid_int()):
		return -1
	var day := int(parts[0])
	var month := int(parts[1])
	var year := 2000 + int(parts[2])
	if month < 1 or month > 12 or day < 1 or day > 31:
		return -1
	var number := days_from_civil(year, month, day)
	var back := civil_from_days(number)
	return number if int(back[0]) == year and int(back[1]) == month and int(back[2]) == day else -1


## "YY.MM.DD" (the calendar square's own format) as a day number; -1 when it
## is not a real date. Two-digit years are 20xx.
static func parse_ymd(text: String) -> int:
	var parts := text.strip_edges().split(".")
	if parts.size() != 3 or not (parts[0].is_valid_int() and parts[1].is_valid_int() and parts[2].is_valid_int()):
		return -1
	var year := 2000 + int(parts[0])
	var month := int(parts[1])
	var day := int(parts[2])
	if month < 1 or month > 12 or day < 1 or day > 31:
		return -1
	var number := days_from_civil(year, month, day)
	var back := civil_from_days(number)
	return number if int(back[0]) == year and int(back[1]) == month and int(back[2]) == day else -1


## A day number as the calendar square writes it, "YY.MM.DD".
static func date_label(number: int) -> String:
	var date := civil_from_days(number)
	return "%02d.%02d.%02d" % [int(date[0]) % 100, int(date[1]), int(date[2])]


## "YY.MM.DD", for the calendar square (Cameron, 2026-10-26). The Events tab's
## "On Date" column is still typed DD.MM.YY (parse_date), as it always was.
static func date_text(state: Dictionary, cfg: Dictionary) -> String:
	var start := days_from_civil(int(cfg["start_year"]), int(cfg["start_month"]), int(cfg["start_day"]))
	var date := civil_from_days(start + day_offset(state, cfg))
	return "%02d.%02d.%02d" % [int(date[0]) % 100, int(date[1]), int(date[2])]


## Today's day of the week, 0 = Sunday ... 6 = Saturday.
static func weekday_index(state: Dictionary, cfg: Dictionary) -> int:
	# Day 0 of days_from_civil is 1970-01-01, a Thursday.
	return posmod(today_number(state, cfg) + 4, 7)
