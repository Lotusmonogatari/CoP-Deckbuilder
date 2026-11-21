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
static func rows(handlers: Dictionary, with_confirm: bool = true) -> Array[Control]:
	var out: Array[Control] = []
	var look := OfficeFrameStyles.look()
	var members := GameState.staff_members()
	if GameState.staff_day_pool.is_empty():
		out.append(UiKit.line(Text.say("assign.no_tasks")))
		if members.is_empty():
			out.append(UiKit.line(Text.say("assign.no_staff")))
		return out
	# With no staff the day's tasks are still delivered: they can be read, not
	# given out, and the Due ones cost their penalty when the day ends.
	if members.is_empty():
		out.append(UiKit.line(Text.say("assign.date_line", {"date": WeekCalendar.date_label(GameState.staff_day_key),
			"count": GameState.staff_day_pool.size()})))
		out.append(UiKit.line(Text.say("assign.no_staff_due")))
		out.append(UiKit.heading(Text.say("assign.tray_heading")))
		out.append(_tray({}, handlers))
		out.append(UiKit.heading(Text.say("assign.projection_heading")))
		for line: String in projection_lines(GameState.staff_projection(), GameState.staff_day_pool):
			out.append(UiKit.line(line))
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
	# The date and how to play it open the tasks card (P14b, 2026-11-20: the screen is cards on the shared frame).
	var tasks_card := OfficeFrameStyles.card(look, Text.say("assign.tray_heading"))
	tasks_card.name = "TasksCard"
	var tasks := tasks_card.get_node("Column") as VBoxContainer
	tasks.add_child(UiKit.line(Text.say("assign.date_line", {"date": WeekCalendar.date_label(GameState.staff_day_key), "count": waiting})))
	tasks.add_child(UiKit.line(Text.say("assign.hint"), "SmallLabel"))
	tasks.add_child(_tray(given, handlers))
	out.append(tasks_card)

	# How the day's tasks were arranged (the drivers, the maximum) is a working
	# detail, not shown to the player (Cameron, 2026-11-16); GameState keeps it
	# in staff_day_reasons and staff_day_max.

	var items_card := OfficeFrameStyles.card(look, Text.say("assign.items_heading"))
	items_card.name = "ItemsCard"
	items_card.get_node("Column").add_child(_items_row(handlers))
	out.append(items_card)
	var office_card := OfficeFrameStyles.card(look, Text.say("assign.office_heading"))
	office_card.name = "OfficeBoxCard"
	office_card.get_node("Column").add_child(UiKit.line(Text.say("assign.office_hint"), "SmallLabel"))
	office_card.get_node("Column").add_child(_office_box(handlers))
	out.append(office_card)

	out.append(UiKit.heading(Text.say("assign.staff_heading")))
	for member: Dictionary in members:
		out.append(_staff_card(member, projection, fits, handlers))

	var projection_card := OfficeFrameStyles.card(look, Text.say("assign.projection_heading"))
	projection_card.name = "ProjectionCard"
	for line: String in projection_lines(projection, GameState.staff_day_pool):
		projection_card.get_node("Column").add_child(UiKit.line(line))
	out.append(projection_card)

	if with_confirm:
		out.append(confirm_button(handlers))
	if GameState.staff_day_confirmed:
		out.append(UiKit.line(Text.say("assign.locked_note")))
	return out


## Confirm the day: the button the frame fixes at the foot while the cards scroll (greyed with the reason when it cannot be pressed).
static func confirm_button(handlers: Dictionary) -> Button:
	var confirm := UiKit.action_button(Text.say("assign.confirm"), GameState.staff_confirm_refusal(), handlers["confirm"], 110.0)
	confirm.name = "ConfirmDayButton"
	return confirm


## The short note under a staff item card: what it does and (for the shelf)
## how many are still free.
static func item_caption(item: Dictionary, free: int = -1) -> String:
	var tail := "" if free < 0 else " " + Text.say("assign.item_left", {"free": free})
	# An item with several uses shows the uses left on its next copy instead.
	if int(item.get("uses", 1)) > 1 and int(item.get("uses_left", 0)) > 0:
		tail = " " + (Text.say("assign.uses_left_one") if int(item["uses_left"]) == 1
			else Text.say("assign.uses_left", {"left": int(item["uses_left"])}))
	match str(item.get("effect", "")):
		"HOURS":
			return (Text.say("assign.item_in_box_one") if int(item.get("hours", 0)) == 1
				else Text.say("assign.item_in_box", {"hours": int(item.get("hours", 0))})) + tail
		"HOURS_ALL":
			return (Text.say("assign.item_cap_all_one") if int(item.get("value", 0)) == 1
				else Text.say("assign.item_cap_all", {"hours": int(item.get("value", 0))})) + tail
		"STRONG_FAMILY":
			return Text.say("assign.item_cap_family", {"family": str(item.get("target", ""))}) + tail
		"REWARD_MULT":
			return Text.say("assign.item_cap_mult", {"percent": int(item.get("value", 100))}) + tail
		"QUIET":
			return Text.say("assign.item_cap_quiet") + tail
		"GIFT":
			return Text.say("assign.item_cap_gift") + tail
		"POOL_FAMILY":
			return Text.say("assign.item_cap_pool", {"family": str(item.get("target", "")), "amount": "%+d" % int(item.get("value", 0))}) + tail
		"POOL_MAX":
			return Text.say("assign.item_cap_max", {"amount": "%+d" % int(item.get("value", 0))}) + tail
		"ADD_TASKS":
			return Text.say("assign.item_cap_add", {"count": int(item.get("value", 0))}) + tail
		"CLEAR_TASKS":
			return Text.say("assign.item_cap_clear", {"count": int(item.get("value", 0))}) + tail
		"RESHUFFLE":
			return Text.say("assign.item_cap_reshuffle") + tail
		"DOUBLE_BEST":
			return Text.say("assign.item_cap_double") + tail
		"NO_PENALTY":
			return Text.say("assign.item_cap_nopenalty") + tail
	return tail.strip_edges()


## The same card info for one item id (a placed item).
static func _item_info(item_id: String) -> Dictionary:
	var info := GameState.staff_item_info(item_id)
	var item := DataDB.get_shop_item(item_id)
	return {"item_id": item_id, "name": str(item.get("name", item_id)), "effect": str(info["effect"]),
		"slot": str(info["slot"]), "value": int(info["value"]), "target": str(info["target"]),
		"hours": GameState.staff_item_hours(item_id),
		"uses": int(info.get("uses", 1)), "uses_left": GameState.item_uses_left(item_id),
		"icon": str(item.get("icon", "")) if item.get("icon") != null else ""}


## The staff items you hold, as cards to drag into a person's box (one item per
## person; each acts on their day) or, for the Office kind, into the Office box.
static func _items_row(handlers: Dictionary) -> Control:
	var flow := HFlowContainer.new()
	flow.name = "ItemTray"
	flow.add_theme_constant_override("h_separation", 12)
	flow.add_theme_constant_override("v_separation", 12)
	flow.custom_minimum_size = Vector2(UiKit.LINE_WIDTH + 200, 0)
	var any := false
	for item: Dictionary in GameState.staff_usable_items():
		any = true
		var chip := TaskChip.new()
		chip.setup_item(str(item["item_id"]), str(item["name"]), str(item["icon"]),
			item_caption(item, int(item["free"])), PLAIN_FRAME, false,
			not GameState.staff_day_confirmed and int(item["free"]) > 0)
		chip.theme = card_theme()
		chip.tapped.connect(handlers["popup"])
		if int(item["free"]) <= 0:
			chip.modulate = Color(1, 1, 1, 0.55)
		flow.add_child(chip)
	if not any:
		flow.add_child(UiKit.line(Text.say("assign.items_none")))
	return flow


## The Office box: where an item that changes the next day's tasks is placed.
static func _office_box(handlers: Dictionary) -> Control:
	var box := TaskBox.new()
	box.setup(GameState.OFFICE_BOX)
	box.dropped.connect(handlers["dropped"])
	box.item_dropped.connect(handlers["item_dropped"])
	var inside := HFlowContainer.new()
	box.add_child(inside)
	var placed := GameState.staff_office_item
	if placed.is_empty():
		var office_note := UiKit.line(Text.say("assign.office_empty"))
		office_note.custom_minimum_size.x = 380
		inside.add_child(office_note)
	else:
		var info := _item_info(placed)
		var chip := TaskChip.new()
		chip.setup_item(placed, str(info["name"]), str(info["icon"]), item_caption(info), FIT_COLORS["strong"], true, false)
		chip.theme = card_theme()
		chip.tapped.connect(handlers["popup"])
		inside.add_child(chip)
	return box


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


## The one-word family name under a task's icon in a staff box (the Family
## column on the Staff Assignments tab).
static func _family_of(task: Dictionary) -> String:
	var raw: Variant = task.get("family")
	return "" if raw == null else str(raw)


static func _chip(entry: Dictionary, frame: Color, compact: bool, handlers: Dictionary) -> TaskChip:
	var task := StaffTasks.task_for(DataDB.staff_tasks, str(entry.get("task_id", "")))
	var chip := TaskChip.new()
	chip.setup(str(entry["uid"]), str(entry.get("title", "")), str(task.get("icon", "")),
		int(task.get("blocks", 1)), frame, compact, not GameState.staff_day_confirmed and not GameState.staff_members().is_empty(),
		_family_of(task) if compact else "")
	chip.theme = card_theme()
	chip.tapped.connect(handlers["popup"])
	return chip


static func _staff_card(member: Dictionary, projection: Dictionary, fits: Dictionary, handlers: Dictionary) -> Control:
	var staff_id := str(member["staff_id"])
	var candidate := DataDB.get_staff(staff_id)
	# One card for every hired person, in the style's own look (P14b, 2026-11-20).
	var panel := OfficeFrameStyles.card(OfficeFrameStyles.look())
	panel.name = "StaffCard_" + staff_id

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.get_node("Column").add_child(row)

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
	var total := GameState.staff_day_hours(staff_id)
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
	box.item_dropped.connect(handlers["item_dropped"])
	column.add_child(box)
	var inside := HFlowContainer.new()
	inside.add_theme_constant_override("h_separation", 8)
	inside.add_theme_constant_override("v_separation", 8)
	box.add_child(inside)
	var holds := false
	var given_item := str(GameState.staff_day_items.get(staff_id, ""))
	if not given_item.is_empty():
		holds = true
		var held_info := _item_info(given_item)
		var item_chip := TaskChip.new()
		item_chip.setup_item(given_item, str(held_info["name"]), str(held_info["icon"]), item_caption(held_info),
			FIT_COLORS["strong"], true, false)
		item_chip.theme = card_theme()
		item_chip.tapped.connect(handlers["popup"])
		inside.add_child(item_chip)
	for uid: Variant in GameState.staff_day_plan.get(staff_id, []):
		var entry := StaffTasks.entry_for(GameState.staff_day_pool, str(uid))
		if entry.is_empty():
			continue
		holds = true
		var fit := str(fits.get(str(uid), "fair"))
		inside.add_child(_chip(entry, FIT_COLORS.get(fit, PLAIN_FRAME), true, handlers))
	if not holds:
		var empty_note := UiKit.line(Text.say("assign.box_empty"))
		empty_note.custom_minimum_size.x = 380   # narrow enough for a staff card, wide enough not to wrap letter by letter
		inside.add_child(empty_note)
	return panel


## Inside a dark card or chip the page's text plates are not wanted: the card
## is the plate.
static func card_theme() -> Theme:
	var theme := Theme.new()
	theme.set_stylebox("normal", "Label", StyleBoxEmpty.new())
	# A chip is a dark tile in every style; the words on it stay light even inside a light card (P14b, 2026-11-20).
	theme.set_color("font_color", "Label", Color(0.93, 0.94, 0.96))
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
	# One line: "Time cost" on the left, "3 Hours" on the right (Cameron, 2026-11-16).
	var blocks := int(task.get("blocks", 1))
	var time_row := HBoxContainer.new()
	time_row.name = "TimeRow"
	time_row.add_theme_constant_override("separation", 8)
	var time_heading := UiKit.heading(Text.say("assign.popup_time_heading"))
	time_heading.custom_minimum_size = Vector2(0, 0)
	time_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	time_row.add_child(time_heading)
	var time_value := Label.new()
	time_value.name = "TimeValue"
	time_value.text = Text.say("assign.time_one" if blocks == 1 else "assign.time_many", {"count": blocks})
	time_value.theme_type_variation = "HeaderLabel"
	time_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_row.add_child(time_value)
	out.append(time_row)

	out.append(UiKit.heading(Text.say("assign.popup_outcome_heading")))
	# Three slanted blocks, colour-coded: the positive, neutral and negative
	# result, with no hint of which staff role earns which (Cameron, 2026-11-16).
	if str(task.get("kind", "")) == StaffTasks.KIND_TIME_OFF:
		out.append(_slash(Text.say("assign.outcome_time_off", {"count": Levers.whole("staff_tasks_time_off_loyalty")}), "strong"))
	else:
		var good := effects_text(StaffTasks.parse_effects(task.get("strong_reward")), target)
		var bad := effects_text(StaffTasks.parse_effects(task.get("poor_penalty")), target)
		out.append(_slash(good if not good.is_empty() else Text.say("assign.result_nothing"), "strong"))
		out.append(_slash(Text.say("assign.result_nothing"), "fair"))
		out.append(_slash(bad if not bad.is_empty() else Text.say("assign.result_nothing"), "poor"))
	var due := StaffTasks.parse_effects(task.get("due_penalty"))
	if not due.is_empty():
		out.append(UiKit.line(Text.say("assign.popup_due", {"penalty": effects_text(due, target)})))

	# Who can do it.
	var holder := ""
	for staff_id: String in GameState.staff_day_plan.keys():
		if (GameState.staff_day_plan[staff_id] as Array).has(uid):
			holder = staff_id
	out.append(UiKit.heading(Text.say("assign.give_heading")))
	# The staff, as pictures in a gold-framed row that scrolls sideways.
	var strip := HBoxContainer.new()
	strip.name = "StaffStrip"
	strip.add_theme_constant_override("separation", 14)
	for member: Dictionary in GameState.staff_members():
		var staff_id := str(member["staff_id"])
		var note := ""
		if staff_id == holder:
			note = Text.say("assign.tile_has_it")
		else:
			match GameState.staff_assign_refusal(uid, staff_id):
				StaffTasks.REFUSE_LOCKED:
					note = Text.say("assign.tile_locked")
				StaffTasks.REFUSE_BLOCKS:
					note = Text.say("assign.tile_no_room")
		strip.add_child(_staff_tile(staff_id, str(member["role"]), note, handlers["assign"].bind(uid, staff_id)))
	var scroll := ScrollContainer.new()
	scroll.name = "StaffScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, TILE_SIZE.y + 36)
	scroll.add_child(strip)
	DragScroll.attach(scroll, false)
	var frame := PanelContainer.new()
	frame.name = "StaffFrame"
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0, 0, 0, 0.45)
	frame_style.border_color = FIT_COLORS["strong"]
	frame_style.set_border_width_all(4)
	frame_style.set_corner_radius_all(10)
	frame_style.set_content_margin_all(10)
	frame.add_theme_stylebox_override("panel", frame_style)
	frame.theme = card_theme()
	frame.add_child(scroll)
	out.append(frame)

	# No Assignment: takes the task back (greyed when nobody has it, or the day is locked).
	var none := UiKit.action_button(Text.say("assign.no_assignment"), "", handlers["unassign"].bind(uid), 100.0)
	none.name = "NoAssignmentButton"
	none.disabled = holder.is_empty() or GameState.staff_day_confirmed
	out.append(none)
	return out


## The size of one staff picture tile in the row.
const TILE_SIZE := Vector2(340, 580)


## A staff member as a large picture you tap to give them the task: their
## name and their role. A person
## who cannot take it is dimmed, with the reason written on the tile.
static func _staff_tile(staff_id: String, role: String, note: String, on_press: Callable) -> Button:
	var button := Button.new()
	button.name = "GiveTo_" + staff_id
	button.custom_minimum_size = TILE_SIZE
	button.disabled = not note.is_empty()
	button.pressed.connect(Haptics.confirm)
	button.pressed.connect(on_press)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 8
	column.offset_right = -8
	column.offset_top = 8
	column.offset_bottom = -8
	column.add_theme_constant_override("separation", 4)
	var picture := PlaceholderArt.new()
	picture.kind = PlaceholderArt.Kind.CHARACTER
	picture.art_id = staff_id
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.custom_minimum_size = Vector2(0, 280)
	picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(picture)
	var name_label := Label.new()
	name_label.text = str(DataDB.get_staff(staff_id).get("name", staff_id))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(0, 96)   # room for a name on two lines
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(name_label)
	var caption := Label.new()
	# The role, in plain text: no colour code for how well they suit it.
	caption.text = note if not note.is_empty() else role
	caption.theme_type_variation = "SmallLabel"
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.custom_minimum_size = Vector2(0, 76)      # room for a role on two lines
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(caption)
	button.add_child(column)
	button.theme = card_theme()
	return button


## One result block: the message on a slanted block coloured for its kind.
static func _slash(text: String, kind: String) -> SlashBlock:
	var fills := {"strong": Color("#7a5d0e"), "fair": Color("#4b505a"), "poor": Color("#8a2722")}
	var block := SlashBlock.new()
	block.name = "Result_" + kind
	block.setup(text, fills.get(kind, Color("#4b505a")), FIT_COLORS.get(kind, Color.WHITE))
	return block


# ---------------------------------------------------------------------------
# The item popup (coffee and tea for staff)
# ---------------------------------------------------------------------------

## What one staff item does and where it can go: a person (their picture in
## the sideways row) or, for an Office item, the Office box. `handlers`:
## assign_item(item_id, target), unassign_item(target).
static func item_popup_rows(item_id: String, handlers: Dictionary) -> Array[Control]:
	var out: Array[Control] = []
	var item := DataDB.get_shop_item(item_id)
	var info := _item_info(item_id)
	if item.is_empty() or str(info["effect"]).is_empty():
		return out
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	var picture := TextureRect.new()
	picture.texture = ArtLoader.item_icon(str(info["icon"]))
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.custom_minimum_size = Vector2(120, 120)
	head.add_child(picture)
	var title := UiKit.heading(str(info["name"]))
	title.custom_minimum_size = Vector2(600, 0)
	head.add_child(title)
	out.append(head)
	out.append(UiKit.heading(Text.say("assign.item_effect_heading")))
	out.append(UiKit.line(item_description(item_id)))
	if int(info["uses"]) > 1:
		out.append(UiKit.line(Text.say("assign.item_uses_line", {"left": int(info["uses_left"]), "full": int(info["uses"])})))
	var instant := GameState.staff_item_is_instant(item_id)
	out.append(UiKit.line(Text.say("assign.use_instant_rule" if instant
		else ("assign.office_one_rule" if str(info["slot"]) == "Office" else "assign.item_one_each"))))

	if instant:
		var why := ""
		match GameState.staff_item_refusal(item_id, GameState.OFFICE_BOX):
			StaffTasks.REFUSE_LOCKED:
				why = Text.say("assign.tile_locked")
			StaffTasks.REFUSE_ITEM_NONE:
				why = Text.say("assign.tile_none_left")
			StaffTasks.REFUSE_NOTHING:
				why = Text.say("assign.office_nothing")
			StaffTasks.REFUSE_UNKNOWN:
				why = Text.say("assign.office_no_tasks")
		var use_now := UiKit.action_button(Text.say("assign.office_use_now"), why,
			handlers["assign_item"].bind(item_id, GameState.OFFICE_BOX), 100.0)
		use_now.name = "UseNowButton"
		out.append(use_now)
		return out

	if str(info["slot"]) == "Office":
		var holder := GameState.staff_office_item == item_id
		var refusal := ""
		match GameState.staff_item_refusal(item_id, GameState.OFFICE_BOX):
			StaffTasks.REFUSE_LOCKED:
				refusal = Text.say("assign.tile_locked")
			StaffTasks.REFUSE_ITEM_HAVE:
				refusal = Text.say("assign.office_has_it")
			StaffTasks.REFUSE_ITEM_NONE:
				refusal = Text.say("assign.tile_none_left")
		var place := UiKit.action_button(Text.say("assign.office_place"), refusal,
			handlers["assign_item"].bind(item_id, GameState.OFFICE_BOX), 100.0)
		place.name = "PlaceInOfficeButton"
		out.append(place)
		var take := UiKit.action_button(Text.say("assign.no_assignment"), "", handlers["unassign_item"].bind(GameState.OFFICE_BOX), 100.0)
		take.name = "NoAssignmentButton"
		take.disabled = not holder or GameState.staff_day_confirmed
		out.append(take)
		return out

	var holder_id := ""
	for staff_id: String in GameState.staff_day_items.keys():
		if str(GameState.staff_day_items[staff_id]) == item_id:
			holder_id = staff_id
	out.append(UiKit.heading(Text.say("assign.give_heading")))
	var strip := HBoxContainer.new()
	strip.name = "StaffStrip"
	strip.add_theme_constant_override("separation", 14)
	for member: Dictionary in GameState.staff_members():
		var staff_id := str(member["staff_id"])
		var note := ""
		match GameState.staff_item_refusal(item_id, staff_id):
			StaffTasks.REFUSE_LOCKED:
				note = Text.say("assign.tile_locked")
			StaffTasks.REFUSE_ITEM_HAVE:
				note = Text.say("assign.tile_has_it")
			StaffTasks.REFUSE_ITEM_NONE:
				note = Text.say("assign.tile_none_left")
		strip.add_child(_staff_tile(staff_id, str(member["role"]), note, handlers["assign_item"].bind(item_id, staff_id)))
	out.append(_strip_frame(strip))
	var none := UiKit.action_button(Text.say("assign.no_assignment"), "", handlers["unassign_item"].bind(holder_id), 100.0)
	none.name = "NoAssignmentButton"
	none.disabled = holder_id.is_empty() or GameState.staff_day_confirmed
	out.append(none)
	return out


## One sentence on what an item does, from its Shop columns.
static func item_description(item_id: String) -> String:
	var info := _item_info(item_id)
	var days := int(GameState.staff_item_info(item_id).get("days", 1))
	match str(info["effect"]):
		"HOURS":
			return Text.say("assign.item_effect_one" if int(info["hours"]) == 1 else "assign.item_effect_many", {"hours": int(info["hours"])})
		"HOURS_ALL":
			return Text.say("assign.item_desc_all_one" if int(info["value"]) == 1 else "assign.item_desc_all", {"hours": int(info["value"])})
		"STRONG_FAMILY":
			return Text.say("assign.item_desc_family", {"family": str(info["target"])})
		"REWARD_MULT":
			return Text.say("assign.item_desc_mult", {"percent": int(info["value"])})
		"QUIET":
			return Text.say("assign.item_desc_quiet")
		"GIFT":
			return Text.say("assign.item_desc_gift")
		"POOL_FAMILY":
			return Text.say("assign.item_desc_pool_one", {"family": str(info["target"]), "amount": "%+d" % int(info["value"])}) if days <= 1 \
				else Text.say("assign.item_desc_pool_many", {"family": str(info["target"]), "amount": "%+d" % int(info["value"]), "days": days})
		"POOL_MAX":
			return Text.say("assign.item_desc_max_one", {"amount": "%+d" % int(info["value"])}) if days <= 1 \
				else Text.say("assign.item_desc_max_many", {"amount": "%+d" % int(info["value"]), "days": days})
		"ADD_TASKS":
			return Text.say("assign.item_desc_add", {"count": int(info["value"])})
		"CLEAR_TASKS":
			return Text.say("assign.item_desc_clear", {"count": int(info["value"])})
		"RESHUFFLE":
			return Text.say("assign.item_desc_reshuffle")
		"DOUBLE_BEST":
			return Text.say("assign.item_desc_double", {"count": int(info["value"])})
		"NO_PENALTY":
			return Text.say("assign.item_desc_nopenalty")
	return ""


## The gold-framed, sideways-scrolling row both popups put their staff pictures in.
static func _strip_frame(strip: HBoxContainer) -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "StaffScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(0, TILE_SIZE.y + 36)
	scroll.add_child(strip)
	DragScroll.attach(scroll, false)
	var frame := PanelContainer.new()
	frame.name = "StaffFrame"
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0, 0, 0, 0.45)
	frame_style.border_color = FIT_COLORS["strong"]
	frame_style.set_border_width_all(4)
	frame_style.set_corner_radius_all(10)
	frame_style.set_content_margin_all(10)
	frame.add_theme_stylebox_override("panel", frame_style)
	frame.theme = card_theme()
	frame.add_child(scroll)
	return frame


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
