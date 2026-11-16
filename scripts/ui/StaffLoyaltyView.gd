class_name StaffLoyaltyView
extends RefCounted
## What the Office shows about staff wages and Loyalty (Cameron, 2026-11-16):
## the one-line summary under a hired person, the Loyalty bar, "why Loyalty is
## moving" on their profile, and the lines the new-week popup adds. Display
## only: the rules are StaffLoyalty.gd and GameState's staff functions.


## "Steady · wage 4,000円 a week" under a hired person's row.
static func summary(staff_id: String) -> String:
	return Text.say("staff.summary", {"word": word_text(GameState.staff_loyalty_of(staff_id)),
		"yen": GameState.staff_wage_of(staff_id)})


## The Loyalty word, from literal Text rows.
static func word_text(loyalty: int) -> String:
	match StaffLoyalty.word(loyalty):
		StaffLoyalty.WORD_DEVOTED:
			return Text.say("staff.word_devoted")
		StaffLoyalty.WORD_RESTLESS:
			return Text.say("staff.word_restless")
		StaffLoyalty.WORD_LEAVING:
			return Text.say("staff.word_leaving")
	return Text.say("staff.word_steady")


## A thin bar for a Loyalty number, gold when steady, red when about to leave.
static func bar(loyalty: int) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.name = "LoyaltyBar"
	bar.min_value = 0
	bar.max_value = 100
	bar.value = loyalty
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(UiKit.LINE_WIDTH, 22)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#c8a24a") if loyalty >= Levers.whole("staff_loyalty_restless_below") \
		else (Color("#d98c3a") if loyalty >= Levers.whole("staff_loyalty_leaving_below") else Color("#b3342f"))
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0, 0, 0, 0.45)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)
	return bar


## Loyalty on the profile: the word and bar, this week's wage, and why it
## moved at the last week's end.
static func profile_rows(staff_id: String) -> Array[Control]:
	var rows: Array[Control] = []
	var loyalty := GameState.staff_loyalty_of(staff_id)
	rows.append(UiKit.heading(Text.say("staff.loyalty_heading")))
	rows.append(UiKit.line(summary(staff_id)))
	rows.append(bar(loyalty))
	var last: Dictionary = GameState.staff_last_week.get(staff_id, {})
	if last.is_empty():
		rows.append(UiKit.line(Text.say("staff.why_none"), "SmallLabel"))
		return rows
	rows.append(UiKit.line(Text.say("staff.why_heading"), "SmallLabel"))
	if bool(last.get("paid", false)):
		rows.append(UiKit.line(Text.say("staff.why_paid", {"count": _signed(Levers.whole("staff_loyalty_paid_bonus"))}), "SmallLabel"))
	else:
		rows.append(UiKit.line(Text.say("staff.why_missed", {"count": _signed(-Levers.whole("staff_loyalty_missed_penalty"))}), "SmallLabel"))
	for part: Array in [["affinity", "staff.why_affinity"], ["tenure", "staff.why_tenure"],
			["pride", "staff.why_pride"], ["tasks", "staff.why_tasks"]]:
		var amount := int(last.get(part[0], 0))
		if amount != 0:
			rows.append(UiKit.line(_why_line(str(part[1]), amount), "SmallLabel"))
	rows.append(UiKit.line(Text.say("staff.why_total", {"count": _signed(int(last.get("total", 0)))}), "SmallLabel"))
	return rows


static func _why_line(key: String, amount: int) -> String:
	match key:
		"staff.why_affinity":
			return Text.say("staff.why_affinity", {"count": _signed(amount)})
		"staff.why_tenure":
			return Text.say("staff.why_tenure", {"count": _signed(amount)})
		"staff.why_pride":
			return Text.say("staff.why_pride", {"count": _signed(amount)})
	return Text.say("staff.why_tasks", {"count": _signed(amount)})


static func _signed(amount: int) -> String:
	return "%+d" % amount


## The staff lines of the new-week popup.
static func week_rows(report: Dictionary) -> Array[Control]:
	var rows: Array[Control] = []
	if report.is_empty():
		return rows
	if int(report.get("paid_total", 0)) > 0:
		rows.append(UiKit.line(Text.say("staff.week_paid", {"yen": int(report["paid_total"])}), "SmallLabel"))
	var missed: Array = report.get("missed", [])
	if not missed.is_empty():
		rows.append(UiKit.line(Text.say("staff.week_missed", {"names": ", ".join(PackedStringArray(missed))}), "SmallLabel"))
	var lost: Array = report.get("rank_lost", [])
	if not lost.is_empty():
		rows.append(UiKit.line(Text.say("staff.week_rank_lost", {"names": ", ".join(PackedStringArray(lost))}), "SmallLabel"))
	for gone: Dictionary in report.get("quit", []):
		rows.append(UiKit.line(Text.say("staff.week_quit", {"name": str(gone.get("name", "")),
			"rep": int(gone.get("reputation", 0)), "allies": ", ".join(PackedStringArray(gone.get("allies", [])))}), "SmallLabel"))
	return rows
