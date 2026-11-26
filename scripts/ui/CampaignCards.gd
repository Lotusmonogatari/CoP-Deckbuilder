class_name CampaignCards
extends RefCounted
## The campaign's system cards (P20 phase D, 2026-11-26, Cameron): the Candidate Selection Committee's decision, a campaign poll, and the end of the
## run (Not Selected, or stepping aside). Each returns a PopupCard config; the Office shows it. They draw what GameState tells them and decide
## nothing. Every sentence is a Text row; the row for an outcome or a mover is chosen by a literal match so the exporter can see it is used.


static func outcome_text(outcome: String) -> String:
	match outcome:
		Selection.NOT_SELECTED: return Text.say("selection.outcome.not_selected")
		Selection.LIST: return Text.say("selection.outcome.list")
		Selection.SMD: return Text.say("selection.outcome.smd")
		Selection.SMD_SAFETY_NET: return Text.say("selection.outcome.smd_safety_net")
	return ""


static func _line(text: String, small: bool = false) -> Label:
	var label := UiKit.line(text, "SmallLabel" if small else "")
	label.custom_minimum_size.x = 0.0
	return label


## The committee's card: its three parts, the score and what it decided.
static func selection_config(result: Dictionary) -> Dictionary:
	var body: Array[Control] = [_line(Text.say("selection.intro"))]
	var skin := CampaignViews.look() if not UiStyle.scope.is_empty() else {}
	for part: Array in [["selection.part.strength", float(result["strength"])], ["selection.part.alignment", float(result["alignment"])], ["selection.part.influence", float(result["influence"])]]:
		var part_name := Text.say(str(part[0]))
		body.append(_line(Text.say("selection.part_line", {"name": part_name, "value": str(roundi(float(part[1])))}), true))
		if not skin.is_empty():
			body.append(CampaignSkinParts.bar(skin, float(part[1]) / 100.0))   # a bar under each of the three parts (P22)
	body.append(_line(Text.say("selection.score_line", {"score": int(result["score"])}), true))
	var outcome := str(result["outcome"])
	if skin.is_empty():
		var headline := UiKit.heading(outcome_text(outcome))
		headline.name = "SelectionOutcome"
		body.append(headline)
	else:
		# The outcome is a tilted stamp; Not Selected wears the same stamp in the same colour.
		var stamp_word := Text.say("selection.stamp_not_selected") if outcome == Selection.NOT_SELECTED else Text.say("selection.stamp_selected")
		var stamp := CampaignSkinParts.stamp(skin, stamp_word, "" if outcome == Selection.NOT_SELECTED else outcome_text(outcome))
		stamp.name = "SelectionOutcome"
		body.append(stamp)
	body.append(_line(Text.say("selection.not_selected_note") if outcome == Selection.NOT_SELECTED else Text.say("selection.selected_note"), true))
	var config := {"tag": Text.say("selection.tag"), "tag_kind": PopupCardStyles.ALARM if outcome == Selection.NOT_SELECTED else PopupCardStyles.GOOD,
		"title": Text.say("selection.title"), "body": body, "meta": WeekCalendar.date_label(GameState.campaign_today())}
	_skin_card(config)
	return config


static func source_text(source_key: String) -> String:
	match source_key:
		CampaignPolls.SOURCE_INTERNAL: return Text.say("poll.source.internal")
		"poll.source.pr01": return Text.say("poll.source.pr01")
		"poll.source.pr02": return Text.say("poll.source.pr02")
	return Text.say("poll.source.pr03")


## One mover line (the key CampaignPolls.movers returned) as its sentence.
static func mover_text(key: String) -> String:
	match key:
		"poll.up.district": return Text.say("poll.up.district")
		"poll.down.district": return Text.say("poll.down.district")
		"poll.up.national": return Text.say("poll.up.national")
		"poll.down.national": return Text.say("poll.down.national")
		"poll.up.constituency": return Text.say("poll.up.constituency")
		"poll.down.constituency": return Text.say("poll.down.constituency")
		"poll.up.organizations": return Text.say("poll.up.organizations")
		"poll.down.organizations": return Text.say("poll.down.organizations")
		"poll.up.war_chest": return Text.say("poll.up.war_chest")
		"poll.down.war_chest": return Text.say("poll.down.war_chest")
		"poll.up.capital": return Text.say("poll.up.capital")
		"poll.down.capital": return Text.say("poll.down.capital")
		"poll.up.record": return Text.say("poll.up.record")
		"poll.down.record": return Text.say("poll.down.record")
		"poll.up.party": return Text.say("poll.up.party")
		"poll.down.party": return Text.say("poll.down.party")
	return ""


## A card in the campaign skin wears its emblem and the skin's label colour (the accent) instead of the green and red tags (P22).
static func _skin_card(config: Dictionary) -> void:
	if UiStyle.scope.is_empty():
		return
	config["tag_icon"] = CampaignLook.emblem(UiStyle.scope, 16.0)
	config["tag_kind"] = PopupCardStyles.ACCENT


## The poll card: who ran it, the range, the outlook (or what the committee decided), the arrow against the last poll and the two mover lines.
static func poll_config(poll: Dictionary) -> Dictionary:
	var body: Array[Control] = []
	body.append(_line(source_text(str(poll["source"]))))
	body.append(UiKit.heading(Text.say("poll.range", {"low": int(poll["low"]), "high": int(poll["high"])})))
	if not UiStyle.scope.is_empty():
		var marks: Array[int] = [Levers.whole("selection_threshold_list"), Levers.whole("selection_threshold_smd"), Levers.whole("selection_threshold_safety_net")]
		body.append(CampaignSkinParts.range_bar(CampaignViews.look(), int(poll["low"]), int(poll["high"]), marks))   # the range with the three marks (P22)
	var selected := str(poll.get("selected", ""))
	if not selected.is_empty():
		body.append(_line(Text.say("poll.selected_as", {"outcome": outcome_text(selected)})))
	else:
		body.append(_line(Text.say("poll.outlook_likely", {"outcome": outcome_text(str(poll["likely"]))})))
		if not str(poll.get("could_be", "")).is_empty():
			body.append(_line(Text.say("poll.outlook_could", {"outcome": outcome_text(str(poll["could_be"]))}), true))
	var mid := (float(poll["low"]) + float(poll["high"])) / 2.0
	var previous := float(poll.get("previous_mid", -1.0))
	if previous < 0.0:
		body.append(_line(Text.say("poll.trend_first"), true))
	elif mid > previous + 0.5:
		body.append(_line(Text.say("poll.trend_up", {"last": roundi(previous)}), true))
	elif mid < previous - 0.5:
		body.append(_line(Text.say("poll.trend_down", {"last": roundi(previous)}), true))
	else:
		body.append(_line(Text.say("poll.trend_same", {"last": roundi(previous)}), true))
	var movers: Array[String] = []
	for key: String in [str(poll.get("up", "")), str(poll.get("down", ""))]:
		if not key.is_empty():
			movers.append(mover_text(key))
	if not movers.is_empty():
		body.append(UiKit.heading(Text.say("poll.movers_heading")))
		for text: String in movers:
			body.append(_line(text, true))
	if bool(poll.get("final", false)):
		body.append(_line(Text.say("poll.final"), true))
	var config := {"tag": Text.say("poll.tag"), "title": Text.say("poll.title"), "body": body, "meta": WeekCalendar.date_label(int(poll["date"]))}
	_skin_card(config)
	return config


## The end of the run: "not_selected" (a game over) or "stepped_aside".
static func end_config(kind: String) -> Dictionary:
	var title := Text.say("game_over.not_selected.title") if kind == "not_selected" else Text.say("run_end.stepped_aside.title")
	var words := Text.say("game_over.not_selected.body") if kind == "not_selected" else Text.say("run_end.stepped_aside.body")
	return {"tag": Text.say("game_over.tag"), "tag_kind": PopupCardStyles.ALARM, "title": title, "body": [_line(words)]}
