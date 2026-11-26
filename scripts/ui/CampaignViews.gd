class_name CampaignViews
extends RefCounted
## The pieces of the Campaign Office (P20 phase B, 2026-11-26, Cameron): the status card (fund, capital, phase, actions left), an action card,
## a staff card, the van card, and the text of the phase banners. They draw what GameState tells them; nothing here decides a rule. Every
## sentence is a Text row. The one place the look is chosen is `look()`, so a campaign skin (P22) changes it in one line.


## The look every campaign screen draws with.
static func look() -> Dictionary:
	return OfficeFrameStyles.look()


# --- Small helpers -----------------------------------------------------------------------------------------------------------------

static func _small(node_name: String, text: String) -> Label:
	var label := UiKit.line(text, "SmallLabel")
	label.name = node_name
	label.custom_minimum_size.x = 0.0
	return label


static func _button(node_name: String, text: String, enabled: bool, look: Dictionary) -> Button:
	var button := Button.new()
	button.name = node_name
	button.custom_minimum_size = Vector2(0, OfficeFrameStyles.touch_height())
	button.text = text
	button.disabled = not enabled
	OfficeFrameStyles.dress_card_button(button, look, enabled)
	return button


static func _yen(amount: int) -> String:
	return WeekPaymentsView.yen(amount)


## The name of an action's kind as the player reads it.
static func action_name(kind: String) -> String:
	match kind:
		CampaignOffice.FUNDRAISE: return Text.say("campaign.action.fundraise")
		CampaignOffice.LETTERS: return Text.say("campaign.action.letters")
		CampaignOffice.MAILINGS: return Text.say("campaign.action.mailings")
	return Text.say("campaign.action.van")


static func role_name(role: String) -> String:
	match role:
		CampaignOffice.ROLE_ORGANIZER: return Text.say("campaign.staff.role_organizer")
		CampaignOffice.ROLE_FUNDRAISER: return Text.say("campaign.staff.role_fundraiser")
	return Text.say("campaign.staff.role_announcer")


static func phase_name(phase: String) -> String:
	match phase:
		ElectionCycle.ANNOUNCEMENT: return Text.say("campaign.phase.announcement")
		ElectionCycle.MUSTERING: return Text.say("campaign.phase.mustering")
		ElectionCycle.CAMPAIGN: return Text.say("campaign.phase.campaign")
		ElectionCycle.ELECTION_DAY: return Text.say("campaign.phase.election_day")
	return ""


## "N days to ..." for the phase the player is counting toward, or "" after the last election.
static func phase_note() -> String:
	var info := GameState.election_phase()
	var next := ElectionCycle.days_until_next_phase(GameState.campaign_today(), DataDB.election_cycles)
	var days := int(next["days"])
	match str(info["phase"]):
		ElectionCycle.BUILDING:
			return Text.say("campaign.phase_note.building", {"days": days}) if days > 0 and not str(info["cycle_id"]).is_empty() else ""
		ElectionCycle.ANNOUNCEMENT, ElectionCycle.MUSTERING:
			return Text.say("campaign.phase_note.mustering", {"days": days, "sprint": str(Levers.num("campaign_sprint_multiplier"))})
		ElectionCycle.CAMPAIGN:
			return Text.say("campaign.phase_note.campaign", {"days": days})
		ElectionCycle.ELECTION_DAY:
			return Text.say("campaign.phase_note.election_day")
	return ""


# --- The status card ---------------------------------------------------------------------------------------------------------------

## What the player has to work with: the phase and its clock, the fund and capital, the actions left this week, and a locked-office line.
static func status_card(look: Dictionary) -> PanelContainer:
	var card := OfficeFrameStyles.card(look, Text.say("campaign.office.status"))
	card.name = "CampaignStatusCard"
	var column := card.get_node("Column") as VBoxContainer
	var info := GameState.election_phase()
	var phase := phase_name(str(info["phase"]))
	if not phase.is_empty():
		column.add_child(_small("PhaseLine", Text.say("campaign.office.phase_line", {"phase": phase})))
	var note := phase_note()
	if not note.is_empty():
		column.add_child(_small("PhaseNote", note))
	var locked := GameState.campaign_locked()
	if not locked.is_empty():
		column.add_child(_small("LockedLine", Text.say("campaign.office.locked_stepped_aside")))
	column.add_child(_small("FundLine", Text.say("campaign.stat.line", {"name": Text.say("campaign.office.fund"), "value": _yen(GameState.campaign_fund)})))
	column.add_child(_small("CapitalLine", Text.say("campaign.stat.line", {"name": Text.say("campaign.office.capital"), "value": str(GameState.campaign_capital)})))
	column.add_child(_small("StrengthLine", Text.say("campaign.stat.line", {"name": Text.say("campaign.stat.strength"), "value": str(roundi(GameState.election_strength))})))
	column.add_child(_small("AlignmentLine", Text.say("campaign.stat.line", {"name": Text.say("campaign.alignment"), "value": str(GameState.party_alignment())})))
	if GameState.campaign_fund >= Levers.whole("election_war_chest_limit"):
		column.add_child(_small("FundFull", Text.say("campaign.office.fund_full")))
	if ElectionCycle.is_campaign(str(info["phase"])):
		column.add_child(_small("ActionsLine", Text.say("campaign.office.actions_unlimited")))
	else:
		column.add_child(_small("ActionsLine", Text.say("campaign.office.actions_left",
			{"used": GameState.campaign_actions_week, "limit": Levers.whole("campaign_actions_per_week")})))
	return card


# --- An action ---------------------------------------------------------------------------------------------------------------------

## What an action costs, as one line: hours, Political Capital (XP) and the campaign fund.
static func cost_line(result: Dictionary) -> String:
	var parts: Array[String] = [Text.say("campaign.action.hours", {"hours": int(result["hours"])})]
	if int(result["xp_spent"]) > 0:
		parts.append(Text.say("campaign.action.cost_xp", {"xp": int(result["xp_spent"])}))
	if int(result["fund_spent"]) > 0:
		parts.append(Text.say("campaign.action.cost_fund", {"yen": int(result["fund_spent"])}))
	return " · ".join(PackedStringArray(parts))


## What an action gives, in the words of its preview rows (the same numbers the action will apply).
static func preview_lines(kind: String, result: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var standing: Dictionary = result["standing"]
	match kind:
		CampaignOffice.FUNDRAISE:
			lines.append(Text.say("campaign.preview.fundraise", {"yen": int(result["fund_gain"])}))
		CampaignOffice.LETTERS:
			var amount := int(Levers.whole("campaign_letters_standing"))
			lines.append(Text.say("campaign.preview.letters", {"delta": "%+d" % _letters_amount(result, amount)}))
		CampaignOffice.MAILINGS:
			var each := 0
			for org: Variant in standing.keys():
				each = int(standing[org])
			lines.append(Text.say("campaign.preview.mailings", {"delta": "%+d" % each, "district": "%+d" % int(result["district"])}))
			if int(result["national"]) != 0:
				lines.append(Text.say("campaign.preview.national", {"delta": "%+d" % int(result["national"])}))
		CampaignOffice.VAN:
			var names: Array[String] = []
			var penalty := 0
			for org: Variant in standing.keys():
				if int(standing[org]) < 0:
					penalty = int(standing[org])
					names.append(str(DataDB.get_booster(str(org)).get("name_en", org)))
			lines.append(Text.say("campaign.preview.van", {"district": "%+d" % int(result["district"]), "penalty": "%+d" % penalty,
				"orgs": ", ".join(PackedStringArray(names))}))
	return lines


## A letters preview names no organization yet, so the amount is what any one organization would get.
static func _letters_amount(result: Dictionary, base: int) -> int:
	var standing: Dictionary = result["standing"]
	if standing.is_empty():
		var probe := CampaignOffice.resolve(CampaignOffice.LETTERS, GameState.campaign_state(), "probe")
		return int((probe["standing"] as Dictionary).get("probe", base))
	return int(standing.values()[0])


## One action's card: its name, what it does, what it costs and gives, and a button that does it or says why not.
static func action_card(look: Dictionary, kind: String, why: String, on_press: Callable) -> PanelContainer:
	var card := OfficeFrameStyles.card(look, action_name(kind))
	card.name = "CampaignAction_" + kind
	var column := card.get_node("Column") as VBoxContainer
	var result := GameState.campaign_preview(kind)
	column.add_child(_small("ActionBlurb", _blurb(kind)))
	column.add_child(_small("ActionCost", cost_line(result)))
	for line: String in preview_lines(kind, result):
		column.add_child(_small("ActionGives", line))
	var button := _button("Do_" + kind, Text.say("campaign.action.button", {"name": action_name(kind), "hours": int(result["hours"])}) if why.is_empty() else why,
		why.is_empty(), look)
	if why.is_empty():
		button.pressed.connect(on_press.bind(kind))
	column.add_child(button)
	return card


static func _blurb(kind: String) -> String:
	match kind:
		CampaignOffice.FUNDRAISE: return Text.say("campaign.action.blurb_fundraise")
		CampaignOffice.LETTERS: return Text.say("campaign.action.blurb_letters")
		CampaignOffice.MAILINGS: return Text.say("campaign.action.blurb_mailings")
	return Text.say("campaign.action.blurb_van")


# --- Staff -------------------------------------------------------------------------------------------------------------------------

## One campaign staff row: the name and role, what the role does, the tier, the wage and Loyalty once hired, and Hire or Upgrade (or why not).
static func staff_card(look: Dictionary, entry: Dictionary, on_hire: Callable, on_upgrade: Callable) -> PanelContainer:
	var row: Dictionary = entry["row"]
	var member: Dictionary = entry["member"]
	var id := str(row["staff_id"])
	var card := OfficeFrameStyles.card(look, str(row.get("name", id)))
	card.name = "CampaignStaff_" + id
	var column := card.get_node("Column") as VBoxContainer
	column.add_child(_small("StaffRole", role_name(str(row["role"]))))
	if row.get("role_flavor") != null:
		column.add_child(_small("StaffFlavor", str(row["role_flavor"])))
	if not bool(entry["available"]):
		column.add_child(_small("StaffUnavailable", Text.say("campaign.staff.unavailable")))
		return card
	if member.is_empty():
		var cost := CampaignStaff.hire_cost()
		column.add_child(_small("StaffCost", Text.say("campaign.staff.cost", {"capital": int(cost["capital"]), "yen": int(cost["yen"])})))
		var why := GameState.campaign_hire_refusal(id)
		var hire := _button("Hire_" + id, Text.say("campaign.staff.hire") if why.is_empty() else why, why.is_empty(), look)
		if why.is_empty():
			hire.pressed.connect(on_hire.bind(id))
		column.add_child(hire)
		return card
	var tier := int(member.get("tier", 0))
	column.add_child(_small("StaffTier", Text.say("campaign.staff.tier", {"tier": tier})))
	column.add_child(_small("StaffWage", Text.say("campaign.staff.wage", {"yen": CampaignStaff.wage_for(member)})))
	column.add_child(_small("StaffLoyalty", Text.say("campaign.staff.loyalty", {"word": StaffLoyaltyView.word_text(int(member.get("loyalty", 0)))})))
	if CampaignStaff.is_lent(member, GameState.campaign_today()):
		column.add_child(_small("StaffLent", Text.say("campaign.staff.lent", {"date": WeekCalendar.date_label(int(member["lent_until"]))})))
	if tier < CampaignStaff.highest_tier(row):
		var cost := CampaignStaff.upgrade_cost(tier)
		column.add_child(_small("UpgradeCost", Text.say("campaign.staff.cost", {"capital": int(cost["capital"]), "yen": int(cost["yen"])})))
		var why := GameState.campaign_upgrade_refusal(id)
		var upgrade := _button("Upgrade_" + id, Text.say("campaign.staff.upgrade", {"tier": tier + 1}) if why.is_empty() else why, why.is_empty(), look)
		if why.is_empty():
			upgrade.pressed.connect(on_upgrade.bind(id))
		column.add_child(upgrade)
	return card


# --- The van -----------------------------------------------------------------------------------------------------------------------

## The van card: what it is, what you have, and the next step with its price (or why it cannot be bought).
static func van_card(look: Dictionary, on_buy: Callable) -> PanelContainer:
	var card := OfficeFrameStyles.card(look, Text.say("campaign.van.title"))
	card.name = "CampaignVanCard"
	var column := card.get_node("Column") as VBoxContainer
	column.add_child(_small("VanIntro", Text.say("campaign.van.intro")))
	var tier := GameState.campaign_van_tier
	column.add_child(_small("VanOwned", Text.say("campaign.van.none") if tier < 0 else Text.say("campaign.van.owned", {"tier": tier})))
	for step in range(0, 3):
		var line := _small("VanStep_%d" % step, _step_text(step))
		line.add_theme_color_override("font_color", look["ink"] if step <= tier else look["muted"])
		column.add_child(line)
	var next_cost := GameState.campaign_van_next_cost()
	if next_cost >= 0:
		var why := GameState.campaign_van_refusal()
		var label := Text.say("campaign.van.buy", {"yen": next_cost}) if tier < 0 else Text.say("campaign.van.upgrade", {"tier": tier + 1, "yen": next_cost})
		var button := _button("BuyVan", label if why.is_empty() else why, why.is_empty(), look)
		if why.is_empty():
			button.pressed.connect(on_buy)
		column.add_child(button)
	return card


static func _step_text(step: int) -> String:
	match step:
		0: return Text.say("campaign.van.tier_0")
		1: return Text.say("campaign.van.tier_1")
	return Text.say("campaign.van.tier_2")


# --- The letters' organization picker ---------------------------------------------------------------------------------------------

## One row for an organization the letters may go to: its name and standing, a button to pick it.
static func org_row(look: Dictionary, booster: Dictionary, standing: int, on_pick: Callable) -> Button:
	var id := str(booster.get("booster_id", ""))
	var button := _button("LettersTo_" + id, Text.say("campaign.letters.row", {"org": str(booster.get("name_en", id)), "standing": standing}), true, look)
	button.pressed.connect(on_pick.bind(id))
	return button


# --- The phase banners -------------------------------------------------------------------------------------------------------------

## The values a phase banner's words are filled with, from the cycle's own dates.
static func banner_values(cycle_id: String) -> Dictionary:
	var cycle := {}
	for row: Dictionary in ElectionCycle.normalized(DataDB.election_cycles):
		if str(row["id"]) == cycle_id:
			cycle = row
	if cycle.is_empty():
		return {}
	var banners := int(cycle["banners"])
	var open := int(cycle["open"])
	var day := int(cycle["day"])
	return {"date": WeekCalendar.date_label(banners), "election_day": WeekCalendar.date_label(day), "weeks": (open - banners) / 7,
		"from": WeekCalendar.date_label(banners), "to": WeekCalendar.date_label(open), "days": day - open,
		"weekday": EventsModel.weekday_name(day), "actions": Levers.whole("campaign_actions_per_week"),
		"gain": roundi(float(ElectionStrength.settings(DataDB.balance)["gain_mustering"])), "campaign_from": WeekCalendar.date_label(open),
		"campaign_to": WeekCalendar.date_label(day)}


## A banner page as a PopupCard config, the Japanese accent beside the phase's English name.
static func banner_config(phase: String, cycle_id: String) -> Dictionary:
	var values := banner_values(cycle_id)
	var kicker := ""
	var sub := ""
	var cta := ""
	var jp := ""
	match phase:
		ElectionCycle.ANNOUNCEMENT:
			kicker = Text.say("campaign.banner.announcement.kicker", values)
			sub = Text.say("campaign.banner.announcement.sub", values)
			cta = Text.say("campaign.banner.announcement.cta")
			jp = Text.say("campaign.phase.announcement_jp")
		ElectionCycle.MUSTERING:
			kicker = Text.say("campaign.banner.mustering.kicker", values)
			sub = Text.say("campaign.banner.mustering.sub", values)
			cta = Text.say("campaign.banner.mustering.cta")
			jp = Text.say("campaign.phase.mustering_jp")
		ElectionCycle.CAMPAIGN:
			var campaign_values := values.duplicate()
			campaign_values["from"] = values.get("campaign_from", "")
			campaign_values["to"] = values.get("campaign_to", "")
			kicker = Text.say("campaign.banner.campaign.kicker", campaign_values)
			sub = Text.say("campaign.banner.campaign.sub")
			cta = Text.say("campaign.banner.campaign.cta")
			jp = Text.say("campaign.phase.campaign_jp")
		_:
			var day_values := values.duplicate()
			day_values["date"] = values.get("election_day", "")
			kicker = Text.say("campaign.banner.election_day.kicker", day_values)
			sub = Text.say("campaign.banner.election_day.sub")
			cta = Text.say("campaign.banner.election_day.cta")
			jp = Text.say("campaign.phase.election_day_jp")
	return {"config": {"tag": kicker, "title": phase_name(phase), "body": [UiKit.line(jp, "SmallLabel"), UiKit.line(sub)]}, "cta": cta}
