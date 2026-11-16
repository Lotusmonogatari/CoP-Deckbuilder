class_name StaffAssignmentsView
extends RefCounted
## The Staff Assignments screen (Cameron, 2026-11-16; design/proposals/
## STAFF_ASSIGNMENTS_2026-11-16.md): the day's tasks as small icon cards, each
## hired person as a card with a picture, an 8-block workload bar and a box
## the player moves task icons into, the projected outcome, and Confirm.
## Tapping any icon opens a popup with its title, context, work, time cost
## and outcome for every kind of fit.
##
## Display only: what a plan does is StaffTasks.evaluate() (through GameState),
## and the screen reads the same numbers the day's end will apply. The Office
## passes `handlers` (Callables) for what a tap or drop should do.

const FIT_COLORS := {"strong": Color("#e8c25a"), "fair": Color("#bcc1cc"), "poor": Color("#ef6a62")}
const PLAIN_FRAME := Color("#4a5060")
## The biggest a staff picture is drawn on an assignment card: large, as on the
## profile (Cameron, 2026-11-16), leaving room beside it for the box of tasks.
const PORTRAIT_MAX := Vector2(340, 640)
const BLOCK_FREE := Color("#c8a24a")
const BLOCK_USED := Color(0.18, 0.2, 0.26)


# ---------------------------------------------------------------------------
# The screen
# ---------------------------------------------------------------------------

## The rows of the screen. `handlers`: popup(uid), dropped(uid, staff_id),
## profile(staff_id), confirm().
static func rows(handlers: Dictionary) -> Array[Control]:
	var out: Array[Control] = []
	var members := GameState.staff_members()
	if members.is_empty():
		out.append(UiKit.line(Text.say("assign.no_staff")))
		return out
	if GameState.staff_day_pool.is_empty():
		out.append(UiKit.line(Text.say("assign.no_tasks")))
		return out

	var projection := GameState.staff_projection()
	var fits := {}
	for line: Dictionary in projection["lines"]:
		fits[str(line["uid"])] = str(line["fit"])
	var given := {}
	for staff_id: String in GameState.staff_day_plan.keys():
		for uid: Variant in GameState.staff_day_plan[staff_id]:
			given[str(uid)] = staff_id

	var waiting := 0
	for entry: Dictionary in GameState.staff_day_pool:
		if not given.has(str(entry["uid"])):
			waiting += 1
	out.append(UiKit.line(Text.say("assign.date_line", {"date": WeekCalendar.date_label(GameState.staff_day_key), "count": waiting})))
	out.append(UiKit.line(Text.say("assign.hint")))

	out.append(UiKit.heading(Text.say("assign.tray_heading")))
	out.append(_tray(given, handlers))

	out.append(UiKit.heading(Text.say("assign.staff_heading")))
	for member: Dictionary in members:
		out.append(_staff_card(member, projection, fits, handlers))

	out.append(UiKit.heading(Text.say("assign.projection_heading")))
	for line: String in projection_lines(projection, GameState.staff_day_pool):
		out.append(UiKit.line(line))

	var refusal := GameState.staff_confirm_refusal()
	var confirm := UiKit.action_button(Text.say("assign.confirm"), refusal, handlers["confirm"], 110.0)
	confirm.name = "ConfirmDayButton"
	out.append(confirm)
	if GameState.staff_day_confirmed:
		out.append(UiKit.line(Text.say("assign.locked_note")))
	return out


static func _tray(given: Dictionary, handlers: Dictionary) -> Control:
	var flow := HFlowContainer.new()
	flow.name = "TaskTray"
	flow.add_theme_constant_override("h_separation", 12)
	flow.add_theme_constant_override("v_separation", 12)
	flow.custom_minimum_size = Vector2(UiKit.LINE_WIDTH + 200, 0)
	var any := false
	for entry: Dictionary in GameState.staff_day_pool:
		if given.has(str(entry["uid"])):
			continue
		any = true
		flow.add_child(_chip(entry, PLAIN_FRAME, false, handlers))
	if not any:
		flow.add_child(UiKit.line(Text.say("assign.tray_empty")))
	return flow


static func _chip(entry: Dictionary, frame: Color, compact: bool, handlers: Dictionary, fit: String = "") -> TaskChip:
	var task := StaffTasks.task_for(DataDB.staff_tasks, str(entry.get("task_id", "")))
	var chip := TaskChip.new()
	chip.setup(str(entry["uid"]), str(entry.get("title", "")), str(task.get("icon", "")),
		int(task.get("blocks", 1)), frame, compact, not GameState.staff_day_confirmed,
		"" if fit.is_empty() else fit_label(fit))
	chip.theme = card_theme()
	chip.tapped.connect(handlers["popup"])
	return chip


static func _staff_card(member: Dictionary, projection: Dictionary, fits: Dictionary, handlers: Dictionary) -> Control:
	var staff_id := str(member["staff_id"])
	var candidate := DataDB.get_staff(staff_id)
	var panel := PanelContainer.new()
	panel.name = "StaffCard_" + staff_id
	panel.theme = card_theme()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.17, 0.96)
	style.border_color = Color("#2d3344")
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	var portrait := PlaceholderArt.new()
	portrait.name = "StaffPortrait_" + staff_id
	portrait.kind = PlaceholderArt.Kind.CHARACTER
	portrait.art_id = staff_id
	portrait.custom_minimum_size = portrait_size(staff_id)
	portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(portrait)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)

	var name_button := Button.new()
	name_button.name = "Profile_" + staff_id
	name_button.flat = true
	name_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_button.text = str(candidate.get("name", staff_id))
	name_button.theme_type_variation = "HeaderLabel"
	name_button.custom_minimum_size = Vector2(0, 90)   # a touch-sized target
	name_button.pressed.connect(handlers["profile"].bind(staff_id))
	column.add_child(name_button)
	column.add_child(UiKit.line(Text.say("assign.role_line", {"role": str(member["role"]), "tier": int(member["tier"])})))
	var loyalty := GameState.staff_loyalty_of(staff_id)
	var today := int((projection["loyalty"] as Dictionary).get(staff_id, 0))
	column.add_child(UiKit.line(Text.say("assign.loyalty_line", {"word": StaffLoyaltyView.word_text(loyalty),
		"count": "%+d" % today})))
	column.add_child(StaffLoyaltyView.bar(loyalty))

	var used := GameState.staff_blocks_used(staff_id)
	var total := GameState.staff_day_blocks_total
	column.add_child(UiKit.line(Text.say("assign.blocks_line", {"used": used, "total": total})))
	column.add_child(blocks_bar(used, total))

	# The column sits beside a large picture: its lines wrap in what is left
	# instead of forcing the full column width (which pushed it off the screen).
	for child in column.get_children():
		if child is Label or child is ProgressBar:
			(child as Control).custom_minimum_size.x = 0
	var box := TaskBox.new()
	box.setup(staff_id)
	box.dropped.connect(handlers["dropped"])
	column.add_child(box)
	var inside := HFlowContainer.new()
	inside.add_theme_constant_override("h_separation", 8)
	inside.add_theme_constant_override("v_separation", 8)
	box.add_child(inside)
	var holds := false
	for uid: Variant in GameState.staff_day_plan.get(staff_id, []):
		var entry := StaffTasks.entry_for(GameState.staff_day_pool, str(uid))
		if entry.is_empty():
			continue
		holds = true
		var fit := str(fits.get(str(uid), "fair"))
		inside.add_child(_chip(entry, FIT_COLORS.get(fit, PLAIN_FRAME), true, handlers, fit))
	if not holds:
		inside.add_child(UiKit.line(Text.say("assign.box_empty")))
	return panel


## Inside a dark card or chip the page's text plates are not wanted: the card
## is the plate.
static func card_theme() -> Theme:
	var theme := Theme.new()
	theme.set_stylebox("normal", "Label", StyleBoxEmpty.new())
	return theme


## The drawing fitted into PORTRAIT_MAX with no empty margin, as on the staff
## profile (the same rule as OfficeScreen); a missing picture gets the full box.
static func portrait_size(staff_id: String) -> Vector2:
	var path := ArtLoader.character_path(staff_id)
	var texture := load(path) as Texture2D if not path.is_empty() else null
	if texture == null or texture.get_height() <= 0:
		return PORTRAIT_MAX
	var aspect := float(texture.get_width()) / float(texture.get_height())
	var width := minf(PORTRAIT_MAX.x, PORTRAIT_MAX.y * aspect)
	return Vector2(width, width / aspect)


## Eight (or four) blocks; the free ones are gold, the ones the plan uses are dark.
static func blocks_bar(used: int, total: int) -> Control:
	var bar := HBoxContainer.new()
	bar.name = "BlocksBar"
	bar.add_theme_constant_override("separation", 4)
	for i in total:
		var block := ColorRect.new()
		block.custom_minimum_size = Vector2(48, 20)
		block.color = BLOCK_USED if i >= total - used else BLOCK_FREE
		bar.add_child(block)
	return bar


# ---------------------------------------------------------------------------
# What the plan would do, in words
# ---------------------------------------------------------------------------

static func fit_label(fit: String) -> String:
	match fit:
		"strong":
			return Text.say("assign.fit_strong")
		"poor":
			return Text.say("assign.fit_poor")
	return Text.say("assign.fit_fair")


## "Constituency support +2, XP +3" for a list of {name, amount}.
static func effects_text(effects: Array, target_name: String = "") -> String:
	var parts: Array[String] = []
	for effect: Dictionary in effects:
		var name := str(effect["name"])
		var amount := "%+d" % int(effect["amount"])
		match name:
			"Standing":
				parts.append(Text.say("assign.effect_standing", {"name": target_name, "amount": amount}))
			"Loyalty":
				parts.append(Text.say("assign.effect_loyalty", {"amount": amount}))
			"Loyalty all":
				parts.append(Text.say("assign.effect_loyalty_all", {"amount": amount}))
			_:
				parts.append(Text.say("assign.effect_generic", {"name": name, "amount": amount}))
	return ", ".join(PackedStringArray(parts))


## The totals under "If you confirm": what the day would change.
static func projection_lines(projection: Dictionary, pool: Array) -> Array[String]:
	var lines: Array[String] = []
	for name: String in (projection["meta"] as Dictionary).keys():
		lines.append(Text.say("assign.effect_generic", {"name": name, "amount": "%+d" % int(projection["meta"][name])}))
	if int(projection["xp"]) != 0:
		lines.append(Text.say("assign.effect_generic", {"name": Text.say("assign.name_xp"), "amount": "%+d" % int(projection["xp"])}))
	for meter: String in (projection["awareness"] as Dictionary).keys():
		if int(projection["awareness"][meter]) != 0:
			lines.append(Text.say("assign.effect_generic", {
				"name": Text.say("awareness.district") if meter == "District" else Text.say("awareness.national"),
				"amount": "%+d" % int(projection["awareness"][meter])}))
	for organization: String in (projection["standing"] as Dictionary).keys():
		lines.append(Text.say("assign.effect_standing", {
			"name": str(DataDB.get_booster(organization).get("name_en", organization)),
			"amount": "%+d" % int(projection["standing"][organization])}))
	for gone: Dictionary in projection["undone"]:
		var entry := StaffTasks.entry_for(pool, str(gone["uid"]))
		lines.append(Text.say("assign.proj_undone", {"title": str(entry.get("title", "")),
			"penalty": effects_text(gone["effects"], str(entry.get("target_name", "")))}))
	if bool(projection["time_off_unused"]):
		lines.append(Text.say("assign.proj_time_off_unused", {"count": Levers.whole("staff_tasks_time_off_unused_loyalty")}))
	if lines.is_empty():
		lines.append(Text.say("assign.projection_none"))
	return lines


# ---------------------------------------------------------------------------
# The icon popup
# ---------------------------------------------------------------------------

## What one task is: title, context, work performed, time cost, and what each
## kind of fit does; with the people it can be given to. `handlers`: assign(uid,
## staff_id), unassign(uid).
static func popup_rows(uid: String, handlers: Dictionary) -> Array[Control]:
	var out: Array[Control] = []
	var entry := StaffTasks.entry_for(GameState.staff_day_pool, uid)
	var task := StaffTasks.task_for(DataDB.staff_tasks, str(entry.get("task_id", "")))
	if entry.is_empty() or task.is_empty():
		return out
	var target := str(entry.get("target_name", ""))

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	var art := PlaceholderArt.new()
	art.kind = PlaceholderArt.Kind.ICON
	art.art_id = str(task.get("icon", ""))
	art.custom_minimum_size = Vector2(120, 120)
	head.add_child(art)
	var title := UiKit.heading(str(entry.get("title", "")))
	title.custom_minimum_size = Vector2(600, 0)
	head.add_child(title)
	out.append(head)

	out.append(UiKit.heading(Text.say("assign.popup_context_heading")))
	out.append(UiKit.line(str(entry.get("context", ""))))
	out.append(UiKit.heading(Text.say("assign.popup_work_heading")))
	out.append(UiKit.line(str(task.get("work", ""))))
	out.append(UiKit.heading(Text.say("assign.popup_time_heading")))
	var blocks := int(task.get("blocks", 1))
	out.append(UiKit.line(Text.say("assign.time_one" if blocks == 1 else "assign.time_many", {"count": blocks})))

	out.append(UiKit.heading(Text.say("assign.popup_outcome_heading")))
	if str(task.get("kind", "")) == StaffTasks.KIND_TIME_OFF:
		out.append(UiKit.line(Text.say("assign.outcome_time_off", {"count": Levers.whole("staff_tasks_time_off_loyalty")})))
	else:
		for fit: String in ["strong", "fair", "poor"]:
			var role := StaffTasks.role_for(task, fit)
			var result := ""
			match fit:
				"strong":
					result = effects_text(StaffTasks.parse_effects(task.get("strong_reward")), target)
				"poor":
					result = effects_text(StaffTasks.parse_effects(task.get("poor_penalty")), target)
			var line := Text.say("assign.outcome_line", {"fit": fit_label(fit), "role": role,
				"result": result if not result.is_empty() else Text.say("assign.outcome_nothing")})
			var label := UiKit.line(line)
			label.add_theme_color_override("font_color", FIT_COLORS[fit])
			out.append(label)
	var due := StaffTasks.parse_effects(task.get("due_penalty"))
	if not due.is_empty():
		out.append(UiKit.line(Text.say("assign.popup_due", {"penalty": effects_text(due, target)})))

	# Who can do it.
	var holder := ""
	for staff_id: String in GameState.staff_day_plan.keys():
		if (GameState.staff_day_plan[staff_id] as Array).has(uid):
			holder = staff_id
	out.append(UiKit.heading(Text.say("assign.give_heading")))
	for member: Dictionary in GameState.staff_members():
		var staff_id := str(member["staff_id"])
		var fit := StaffTasks.effective_fit(task, str(member["role"]), GameState.staff_loyalty_of(staff_id))
		var name := str(DataDB.get_staff(staff_id).get("name", staff_id))
		var refusal := ""
		if staff_id == holder:
			refusal = Text.say("assign.already_theirs", {"name": name})
		else:
			var code := GameState.staff_assign_refusal(uid, staff_id)
			match code:
				"", StaffTasks.REFUSE_TAKEN:
					pass
				StaffTasks.REFUSE_LOCKED:
					refusal = Text.say("assign.refuse_locked", {"name": name})
				StaffTasks.REFUSE_BLOCKS:
					refusal = Text.say("assign.refuse_blocks", {"name": name})
		var button := UiKit.action_button(Text.say("assign.give_to", {"name": name, "fit": fit_label(fit)}),
			refusal, handlers["assign"].bind(uid, staff_id), 100.0)
		button.name = "GiveTo_" + staff_id
		out.append(button)
	if not holder.is_empty() and not GameState.staff_day_confirmed:
		var back := UiKit.action_button(Text.say("assign.take_back"), "", handlers["unassign"].bind(uid), 100.0)
		back.name = "TakeBackButton"
		out.append(back)
	return out


# ---------------------------------------------------------------------------
# The day's report
# ---------------------------------------------------------------------------

## What yesterday's staff work did, once: a line per task given, then the totals.
static func report_rows(report: Dictionary) -> Array[Control]:
	var out: Array[Control] = []
	if report.is_empty():
		return out
	var result: Dictionary = report["result"]
	var pool: Array = report.get("pool", [])
	out.append(UiKit.line(Text.say("assign.report_date", {"date": str(report.get("date", ""))})))
	for line: Dictionary in result["lines"]:
		var entry := StaffTasks.entry_for(pool, str(line["uid"]))
		var name := str(DataDB.get_staff(str(line["staff_id"])).get("name", ""))
		var what := effects_text(line["effects"], str(entry.get("target_name", "")))
		var result_text := what if not what.is_empty() else Text.say("assign.outcome_nothing")
		var text := ""
		if str(line.get("kind", "")) == StaffTasks.KIND_TIME_OFF:
			text = Text.say("assign.report_line_plain", {"name": name, "title": str(entry.get("title", "")), "result": result_text})
		else:
			text = Text.say("assign.report_line", {"name": name, "title": str(entry.get("title", "")),
				"fit": fit_label(str(line["fit"])), "result": result_text})
			# Say why when unrest made it count as a weaker fit than the role's own.
			if str(line.get("base_fit", line["fit"])) != str(line["fit"]):
				text += " " + Text.say("assign.report_unsettled")
		var label := UiKit.line(text)
		label.add_theme_color_override("font_color", FIT_COLORS.get(str(line["fit"]), Color.WHITE))
		out.append(label)
	for gone: Dictionary in result["undone"]:
		var entry := StaffTasks.entry_for(pool, str(gone["uid"]))
		out.append(UiKit.line(Text.say("assign.proj_undone", {"title": str(entry.get("title", "")),
			"penalty": effects_text(gone["effects"], str(entry.get("target_name", "")))})))
	if bool(result["time_off_unused"]):
		out.append(UiKit.line(Text.say("assign.proj_time_off_unused", {"count": Levers.whole("staff_tasks_time_off_unused_loyalty")})))
	out.append(UiKit.heading(Text.say("assign.report_totals")))
	for total: String in projection_lines(result, pool):
		out.append(UiKit.line(total))
	return out
