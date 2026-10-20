class_name StanceLines
extends RefCounted
## The words for a bill level's stance (BillStance, 2026-10-18): whose bill it
## is, where the player's party stands, who is with and against the player, and
## what a vote would do. Every sentence is a Text-tab row; this only picks and
## fills them. Lives in the UI folder because it reads Text and DataDB.


## The lean as the player knows it: "Support" or "Oppose".
static func lean_name(lean: String) -> String:
	return Text.say("stance.support" if lean == BillStance.SUPPORT else "stance.oppose")


## "A, B and C", or "nobody in particular" for an empty list.
static func names_of(ids: Array) -> String:
	if ids.is_empty():
		return Text.say("stance.nobody")
	var names := BattleSetup.booster_names()
	var out: Array[String] = []
	for id: Variant in ids:
		out.append(str(names.get(str(id), str(id))))
	return CauseLines.join(out)


## The two lines the Level Intro screen shows before the lean choice: whose
## bill it is, and where the player's own party stands on it.
static func intro_lines(bill: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var proponent := DataDB.get_party_by_id(str(bill.get("proponent_party", "")))
	if not proponent.is_empty():
		lines.append(Text.say("level_intro.bill_proponent", {
			"bill": str(bill.get("bill_name", "")), "party": str(proponent.get("name", ""))}))
	var own := GameState.own_party_id()
	for position: Dictionary in bill.get("positions", []):
		if str(position.get("party_id", "")) != own:
			continue
		var key := "level_intro.party_neutral"
		match str(position.get("disposition", "")):
			"Supportive": key = "level_intro.party_supports"
			"Opposed": key = "level_intro.party_opposes"
		lines.append(Text.say(key, {"party": str(DataDB.player.get("party", ""))}))
	return lines


## "Your stance: Oppose. With you: ... Against you: ..." for the bill in the
## run's current stance.
static func stance_line() -> String:
	var lean := GameState.stance_lean()
	if lean.is_empty():
		return ""
	var sides := GameState.stance_sides()
	var mine := BillStance.my_side(sides, lean)
	var theirs := BillStance.other_side(sides, lean)
	if mine.is_empty() and theirs.is_empty():
		return Text.say("level_intro.stance_alone", {"lean": lean_name(lean)})
	return Text.say("level_intro.stance_head", {"lean": lean_name(lean)})


## The chip rows under the stance sentence: who is with the player and who is
## against, each under a short heading. Empty with no stance or nobody on a side.
static func stance_chip_rows() -> Array[Control]:
	var rows: Array[Control] = []
	var lean := GameState.stance_lean()
	if lean.is_empty():
		return rows
	var sides := GameState.stance_sides()
	for group: Array in [[BillStance.my_side(sides, lean), true, "stance.with_you"],
			[BillStance.other_side(sides, lean), false, "stance.against_you"]]:
		var ids: Array = group[0]
		if ids.is_empty():
			continue
		var heading := UiKit.line(Text.say(str(group[2])), "SmallLabel")
		heading.custom_minimum_size = Vector2.ZERO
		rows.append(heading)
		rows.append(OrgChip.side_row(ids, bool(group[1])))
	return rows


## A heading and a green or red row of organizations, for a list of ids.
static func org_group(heading_key: String, ids: Array, supports: bool) -> Array[Control]:
	var rows: Array[Control] = []
	if ids.is_empty():
		return rows
	var heading := UiKit.line(Text.say(heading_key), "SmallLabel")
	heading.custom_minimum_size = Vector2.ZERO
	rows.append(heading)
	rows.append(OrgChip.side_row(ids, supports, 80.0))
	return rows


## The same, for the briefing: the bill and who is for and against it.
static func briefing_lines(bill: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	if bill.is_empty():
		return lines
	var proponent := DataDB.get_party_by_id(str(bill.get("proponent_party", "")))
	lines.append(Text.say("briefing.bill_line", {
		"bill": str(bill.get("bill_name", "")),
		"party": str(proponent.get("name", Text.say("stance.nobody")))}))
	return lines


## The briefing's two chip rows: who is for the bill and who is against it,
## each under a short heading. Empty when the bill touches nobody.
static func briefing_sides(bill: Dictionary) -> Array[Control]:
	var rows: Array[Control] = []
	if bill.is_empty():
		return rows
	var sides := BillStance.sides(bill, DataDB.law_effects, GameState._party_tier_booster_ids())
	for group: Array in [["supporters", true, "briefing.sides_for"], ["opponents", false, "briefing.sides_against"]]:
		var ids: Array = sides[group[0]]
		if ids.is_empty():
			continue
		rows.append(UiKit.line(Text.say(str(group[2])), "SmallLabel"))
		rows.append(OrgChip.side_row(ids, bool(group[1])))
	return rows


## "Ainu Community Council +5, Chamber of Commerce -5, Party support -3".
static func describe_changes(deltas: Dictionary, party_delta: int) -> String:
	var names := BattleSetup.booster_names()
	var parts: Array[String] = []
	var ids := deltas.keys()
	ids.sort()
	for id: Variant in ids:
		var delta := int(deltas[id])
		if delta != 0:
			parts.append("%s %+d" % [str(names.get(str(id), str(id))), delta])
	if party_delta != 0:
		parts.append("%s %+d" % ["Party support", party_delta])
	return CauseLines.join(parts) if not parts.is_empty() else Text.say("floor_vote.stance_none")


## Organization changes ({ org_id: delta }) as chip entries, zero changes dropped.
static func chip_entries(deltas: Dictionary) -> Array:
	var out: Array = []
	for id: Variant in deltas.keys():
		if int(deltas[id]) != 0:
			out.append({"id": str(id), "delta": int(deltas[id])})
	return out
