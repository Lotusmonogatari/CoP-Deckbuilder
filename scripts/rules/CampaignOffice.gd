class_name CampaignOffice
extends RefCounted
## The Campaign Office's four actions and the campaign's two ledgers (P20, 2026-11-26, Cameron).
##
## Actions (Venue Activities CM01 to CM04): Fundraising calls, Outreach letters, Mailings to local organizations, the Campaign van speech. The
## first three are paid in Political Capital (XP), and that XP becomes campaign capital; the van speech is paid from the campaign fund. Every
## number is a Balance row (campaign_*); nothing is a column. Pure and UI-free (CLAUDE.md section 12): the run's readings come in a `state`.
##
## `state` (a Dictionary the caller fills):
##   office_open        bool    the Campaign Office has been opened (DS11, 18.11.01)
##   locked             String  "" | "not_selected" | "stepped_aside": the player's own campaign is closed
##   work_hours_left    int     work hours left this week (0 on the weekend: the Office takes no action on weekend-only hours)
##   actions_this_week  int     campaign actions already taken this week
##   phase              String  an ElectionCycle phase
##   xp                 int     Political Capital held
##   campaign_fund      int     the campaign fund
##   van_tier           int     -1 no van yet, 0 to 2 the van's tier
##   staff              Array   the campaign staff, CampaignStaff members ({staff_id, role, tier, lent_until, ...}) with `date` for the lending check
##   date               int     today's day number
##   penalty_orgs       Array   the organizations a van speech costs standing with (Rules campaign_van_speech_penalty_orgs)
##   voters_org         String  the organization the Van Announcer's flat bonus goes to (Rules campaign_van_voters_org)
##   constituency_orgs  Array   every organization of tier Constituency (the mailings go to them)

const FUNDRAISE := "campaign_fundraise"
const LETTERS := "campaign_letters"
const MAILINGS := "campaign_mailings"
const VAN := "campaign_van"
const KINDS: Array[String] = [FUNDRAISE, LETTERS, MAILINGS, VAN]

const ROLE_ORGANIZER := "Campaign Organizer"
const ROLE_FUNDRAISER := "Campaign Fundraiser"
const ROLE_ANNOUNCER := "Campaign Van Announcer"


## True for a campaign activity kind.
static func is_campaign_kind(kind: String) -> bool:
	return KINDS.has(kind)


## The XP (Political Capital) an action costs: 0 for the van speech, which is paid from the campaign fund.
static func xp_cost(kind: String) -> int:
	match kind:
		FUNDRAISE: return Levers.whole("campaign_fundraise_xp")
		LETTERS: return Levers.whole("campaign_letters_xp")
		MAILINGS: return Levers.whole("campaign_mailings_xp")
	return 0


## The campaign fund an action costs: only the van speech.
static func fund_cost(kind: String) -> int:
	return Levers.whole("campaign_van_speech_cost") if kind == VAN else 0


## The highest tier among the staff of `role` who are working (hired and not lent), or -1 when there is none.
static func working_tier(role: String, state: Dictionary) -> int:
	var best := -1
	for member: Variant in state.get("staff", []):
		var staff := member as Dictionary
		if str(staff.get("role", "")) != role or int(staff.get("lent_until", -1)) > int(state.get("date", 0)):
			continue
		best = maxi(best, int(staff.get("tier", 0)))
	return best


## Hours one action takes: campaign_action_hours, or campaign_action_hours_with_organizer for letters and mailings with a working Organizer.
static func hours_for(kind: String, state: Dictionary) -> int:
	if (kind == LETTERS or kind == MAILINGS) and working_tier(ROLE_ORGANIZER, state) >= 0:
		return Levers.whole("campaign_action_hours_with_organizer")
	return Levers.whole("campaign_action_hours")


## Whether the player may take the action now: {ok, reason_key}. The reason is a Text key (empty when ok) in the order the player should read it:
## closed for good, office not open, hours, the weekly limit, then what it costs.
static func can_act(kind: String, state: Dictionary) -> Dictionary:
	if not is_campaign_kind(kind):
		return {"ok": false, "reason_key": "campaign.reason.not_an_action"}
	var locked := str(state.get("locked", ""))
	if locked == "not_selected":
		return {"ok": false, "reason_key": "campaign.office.locked_not_selected"}
	if locked == "stepped_aside":
		return {"ok": false, "reason_key": "campaign.office.locked_stepped_aside"}
	if not bool(state.get("office_open", false)):
		return {"ok": false, "reason_key": "campaign.reason.office_closed"}
	if int(state.get("work_hours_left", 0)) < hours_for(kind, state):
		return {"ok": false, "reason_key": "campaign.reason.no_hours"}
	if not ElectionCycle.is_campaign(str(state.get("phase", ""))) and int(state.get("actions_this_week", 0)) >= Levers.whole("campaign_actions_per_week"):
		return {"ok": false, "reason_key": "campaign.reason.weekly_limit"}
	if kind == VAN and int(state.get("van_tier", -1)) < 0:
		return {"ok": false, "reason_key": "campaign.reason.no_van"}
	if int(state.get("xp", 0)) < xp_cost(kind):
		return {"ok": false, "reason_key": "campaign.reason.no_xp"}
	if int(state.get("campaign_fund", 0)) < fund_cost(kind):
		return {"ok": false, "reason_key": "campaign.reason.no_fund"}
	return {"ok": true, "reason_key": ""}


## Rounds half away from zero (GDScript's roundi), then keeps a positive reward at 1 or more.
static func _settle(value: float, was_reward: bool) -> int:
	var rounded := roundi(value)
	if was_reward and value > 0.0 and rounded < 1:
		return 1
	return rounded


## What the action does, as a Dictionary (nothing is changed here; the caller applies it):
##   hours, xp_spent, capital_gained, fund_spent, fund_gain,
##   standing {org_id: delta}, district (District awareness), national (National awareness).
## `target_org` is the organization the letters go to. The ORDER OF EFFECTS is always:
##   1. base values from Balance;
##   2. multipliers on the base: a working Fundraiser x2/x4/x8 on the yield; the van: tier 1 halves its penalties, tier 2 doubles its rewards
##      (tiers add up, so tier 2 does both);
##   3. x campaign_sprint_multiplier on REWARDS only, during mustering;
##   4. round half away from zero; a positive reward never rounds below 1;
##   5. flat staff bonuses last: Organizer tier 1+ +1 standing on letters, tier 2 +1 National awareness on mailings; Announcer tier 1+ +1
##      standing with the voters' organization on a van speech, tier 2 +1 District awareness.
## A lent staff member gives no effect while lent (working_tier skips them).
static func resolve(kind: String, state: Dictionary, target_org: String = "") -> Dictionary:
	var sprint := Levers.num("campaign_sprint_multiplier") if ElectionCycle.is_mustering(str(state.get("phase", ""))) else 1.0
	var result := {"kind": kind, "hours": hours_for(kind, state), "xp_spent": xp_cost(kind), "capital_gained": xp_cost(kind),
		"fund_spent": fund_cost(kind), "fund_gain": 0, "standing": {}, "district": 0, "national": 0}
	var organizer := working_tier(ROLE_ORGANIZER, state)
	var announcer := working_tier(ROLE_ANNOUNCER, state)
	match kind:
		FUNDRAISE:
			var fundraiser := working_tier(ROLE_FUNDRAISER, state)
			var yield_value := Levers.num("campaign_fundraise_yield")
			if fundraiser >= 0:
				yield_value *= Levers.num("campaign_fundraiser_multiplier_tier_%d" % clampi(fundraiser, 0, 2))
			result["fund_gain"] = _settle(yield_value * sprint, true)
		LETTERS:
			var amount := _settle(Levers.num("campaign_letters_standing") * sprint, true)
			if organizer >= 1:
				amount += Levers.whole("campaign_organizer_letters_bonus")
			if not target_org.is_empty():
				(result["standing"] as Dictionary)[target_org] = amount
		MAILINGS:
			var each := _settle(Levers.num("campaign_mailings_standing") * sprint, true)
			for org: Variant in state.get("constituency_orgs", []):
				(result["standing"] as Dictionary)[str(org)] = each
			result["district"] = _settle(Levers.num("campaign_mailings_district") * sprint, true)
			if organizer >= 2:
				result["national"] = Levers.whole("campaign_organizer_mailings_national")
		VAN:
			var tier := int(state.get("van_tier", -1))
			var penalty := Levers.num("campaign_van_speech_penalty")
			var district := Levers.num("campaign_van_speech_district")
			if tier >= 1:
				penalty *= 0.5
			if tier >= 2:
				district *= 2.0
			var cost_each := _settle(penalty, false)
			for org: Variant in state.get("penalty_orgs", []):
				(result["standing"] as Dictionary)[str(org)] = -cost_each
			result["district"] = _settle(district * sprint, true)
			var voters := str(state.get("voters_org", ""))
			if announcer >= 1 and not voters.is_empty():
				(result["standing"] as Dictionary)[voters] = int((result["standing"] as Dictionary).get(voters, 0)) + Levers.whole("campaign_announcer_voters_bonus")
			if announcer >= 2:
				result["district"] = int(result["district"]) + Levers.whole("campaign_announcer_district_bonus")
	return result


## Campaign capital after spending `xp_spent` Political Capital at the Office on letters, mailings or fundraising: it all becomes capital.
static func capital_after_spend(capital: int, xp_spent: int) -> int:
	return capital + maxi(0, xp_spent)


## Campaign capital after a week's end: election_capital_fade_percent of it fades, the faded amount rounded down to a whole number (so a
## small store, under 20, does not fade at all).
static func capital_after_week(capital: int) -> int:
	var faded := int(floor(float(capital) * Levers.num("election_capital_fade_percent") / 100.0))
	return maxi(0, capital - faded)


## The campaign fund after income, capped at election_war_chest_limit: {fund, lost} where `lost` is what did not fit.
static func fund_after_income(fund: int, amount: int) -> Dictionary:
	var limit := Levers.whole("election_war_chest_limit")
	var total := fund + maxi(0, amount)
	return {"fund": mini(total, limit), "lost": maxi(0, total - limit)}
