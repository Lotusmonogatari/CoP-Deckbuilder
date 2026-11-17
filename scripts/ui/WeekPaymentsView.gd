class_name WeekPaymentsView
extends RefCounted
## End of Week Payments (P9, 2026-11-17): the breakdown the Office box opens on
## a tap and the week-over popup shows before its choice. Every number comes
## from GameState.week_end_preview()["payments"], which is WeekPayments, the
## same functions the week end settles with. Draws; decides nothing.


## "Label ........ 12,000円", the label wrapping on the left and the amount on the right.
static func pair(label: String, amount: String, small: bool = false, warn: bool = false) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(UiKit.LINE_WIDTH, 0)
	row.add_theme_constant_override("separation", 16)
	var left := Label.new()
	left.text = label
	left.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var right := Label.new()
	right.text = amount
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for node: Label in [left, right]:
		if small:
			node.theme_type_variation = &"SmallLabel"
		if warn:
			node.theme_type_variation = &"GaffeWarning"
	row.add_child(left)
	if UiStyle.current() == UiStyles.WOODBLOCK:
		# A ledger line: dots lead the eye from the label to the amount (Woodblock).
		left.size_flags_horizontal = 0
		var leader := StyleMarks.make(StyleMarks.Kind.LEADER, UiStyle.colour("rule_dots", Color(0.64, 0.59, 0.5)), Vector2(40, 40))
		leader.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(leader)
	row.add_child(right)
	return row


static func yen(amount: int) -> String:
	return "%s円" % Phrase.with_separators(amount)


## The breakdown rows: dues (and what is still owed), each person's wage, the
## total, Funds after, and, when Funds are short, who goes unpaid.
static func rows(preview: Dictionary, with_heading: bool = true) -> Array[Control]:
	var out: Array[Control] = []
	var pay: Dictionary = preview["payments"]
	var dues: Dictionary = pay["dues"]
	if with_heading:
		out.append(UiKit.heading(Text.say("office.week_payments_title")))
	var this_week := int(dues["total"]) - int(dues["carried"])
	out.append(pair(Text.say("week_end.breakdown_dues"), yen(this_week)))
	if int(dues["carried"]) > 0:
		out.append(pair(Text.say("week_end.breakdown_owed"), yen(int(dues["carried"]))))
	var wages: Array = pay["wages"]
	if wages.is_empty():
		out.append(UiKit.line(Text.say("office.week_payments_no_staff")))
	for line: Dictionary in wages:
		var key := "week_end.breakdown_wage_raised" if bool(line["raised"]) else "week_end.breakdown_wage"
		out.append(pair(Text.say(key, {"name": str(line["name"])}), yen(int(line["wage"])), false, not bool(line["paid"])))
	out.append(UiKit.gold_rule())
	out.append(pair(Text.say("week_end.breakdown_total"), yen(int(pay["total"]))))
	out.append(pair(Text.say("week_end.breakdown_after"), yen(int((pay["funds"] as Dictionary)["after"]))))
	var short := short_line(pay)
	if not short.is_empty():
		out.append(UiKit.line(short, "GaffeWarning"))
		if (pay["unpaid"] as Array).size() > 0:
			out.append(UiKit.line(Text.say("week_end.breakdown_unpaid_wage",
				{"count": Levers.whole("staff_loyalty_missed_penalty")}), "SmallLabel"))
	return out


## "Funds are short by X. Unpaid: A, B." or "" when everything can be paid.
static func short_line(pay: Dictionary) -> String:
	if int(pay["short_by"]) <= 0:
		return ""
	var who: Array[String] = []
	if bool(pay["unpaid_dues"]):
		who.append(Text.say("office.week_payments_unpaid_dues"))
	for name: Variant in pay["unpaid"]:
		who.append(str(name))
	return Text.say("office.week_payments_short",
		{"amount": yen(int(pay["short_by"])), "who": ", ".join(PackedStringArray(who))})
