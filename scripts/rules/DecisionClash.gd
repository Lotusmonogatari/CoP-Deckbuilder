class_name DecisionClash
extends RefCounted
## A level must not run over a Decision! (P15, 2026-11-23, Cameron). A Mandatory scene opens by itself on its day, so a level that
## would still be running when that day comes is refused (the player is told why); an Optional scene only gets an alert: a level
## that would end after the scene's window closes can still be started if the player says so. Pure: no screens, no autoloads, no
## files (the tests prove it). The calendar is WeekCalendar's: a work week of pooled hours, five 8-hour days, and a level never
## carries over into the next week, so a scene on the Monday after a week can never be run over; only a scene later in the same
## work week can.


## Hours of play left before day number `day` begins, counting from now. -1 when that day is not later in this work week (a level
## cannot cross into another week, so there is nothing to protect), 0 when it is today or past.
static func hours_until_day(state: Dictionary, cfg: Dictionary, day: int) -> int:
	if str(state.get("phase", "")) != WeekCalendar.WORK:
		return -1
	var today := WeekCalendar.today_number(state, cfg)
	if day <= today:
		return 0
	var days_ahead := day - today
	var days_left_in_week := int(cfg["work_days"]) - 1 - WeekCalendar.day_index(state, cfg)
	if days_ahead > days_left_in_week:
		return -1
	return WeekCalendar.hours_left_today(state, cfg) + (days_ahead - 1) * int(cfg["workday_hours"])


## The Mandatory scenes that open after today, as [{"scene": row, "day": day number}], earliest first. A follow-up whose earlier
## scene has not been answered has no known day yet and is left out.
static func mandatory_ahead(scenes: Array, log: Dictionary, today: int) -> Array:
	var found: Array = []
	for scene: Variant in scenes:
		if not (scene is Dictionary) or log.has(str((scene as Dictionary).get("scene_id", ""))) \
				or not DecisionScenes.is_mandatory(scene as Dictionary):
			continue
		var day := _opening_day(scene as Dictionary, log)
		if day > today:
			found.append({"scene": scene, "day": day})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["day"]) < int(b["day"]))
	return found


static func _opening_day(scene: Dictionary, log: Dictionary) -> int:
	if DecisionScenes.is_follow_up(scene):
		return DecisionScenes.due_day(scene, log)
	var opens: Variant = scene.get("opens")
	return WeekCalendar.parse_date(str(opens)) if opens != null else -1


## The first Mandatory scene a level of `level_hours` hours would run over, as {"scene", "day", "hours"}; {} when it clears them
## all. "Run over" means the level would not be finished by the end of the day before the scene.
static func mandatory_clash(scenes: Array, log: Dictionary, state: Dictionary, cfg: Dictionary, level_hours: int) -> Dictionary:
	var today := WeekCalendar.today_number(state, cfg)
	for entry: Dictionary in mandatory_ahead(scenes, log, today):
		var room := hours_until_day(state, cfg, int(entry["day"]))
		if room >= 0 and level_hours > room:
			return {"scene": entry["scene"], "day": entry["day"], "hours": room}
	return {}


## The first unanswered Optional scene whose window a level of `level_hours` hours would outlast, as {"scene", "closes"}; {} when
## it fits them all. Only scenes the player can still open (their window not yet closed) count.
static func optional_clash(scenes: Array, log: Dictionary, state: Dictionary, cfg: Dictionary, level_hours: int) -> Dictionary:
	var today := WeekCalendar.today_number(state, cfg)
	var found: Array = []
	for scene: Variant in scenes:
		if not (scene is Dictionary) or log.has(str((scene as Dictionary).get("scene_id", ""))) \
				or not DecisionScenes.is_optional(scene as Dictionary):
			continue
		var span := DecisionScenes.window(scene as Dictionary, log)
		if span[0] < 0 or span[1] < today:
			continue
		found.append({"scene": scene, "closes": span[1]})
	found.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["closes"]) < int(b["closes"]))
	for entry: Dictionary in found:
		# The level has to end by the end of the closing day, so it must clear the start of the day after.
		var room := hours_until_day(state, cfg, int(entry["closes"]) + 1)
		if room >= 0 and level_hours > room:
			return {"scene": entry["scene"], "closes": entry["closes"]}
	return {}


## What the staff's after-hours trip costs: all the XP the player has, up to `cap` (100 in the Balance tab).
static func evening_xp_cost(xp: int, cap: int) -> int:
	return mini(maxi(xp, 0), maxi(cap, 0))
