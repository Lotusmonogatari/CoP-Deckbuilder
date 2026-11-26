class_name CampaignStaff
extends RefCounted
## The campaign's own staff pool (P20, 2026-11-26, Cameron): Campaign Organizers, Fundraisers and Van Announcers, separate from the regular
## office staff, who never do campaign work. Rows come from the Campaign Staff tab (campaign_staff.json); prices are Balance rows. Pure and
## UI-free (CLAUDE.md section 12).
##
## A hired member is {staff_id, role, tier, loyalty, invested_yen, lent_until}: `invested_yen` is the campaign fund paid for the hire and every
## upgrade (campaign capital does NOT count toward wages), `lent_until` the day number a lending ends (-1 when not lent).
##
## Hiring: allowed while the office is open and the date is not between the day after an Election Day and 31 December of that year. The day after
## Election Day every campaign staff member leaves (no firing cost); from 1 January they can be hired again at the hire price, from tier 0. A
## "chain" candidate (a Campaign Moment! found them) stays unlocked.

const AVAILABLE_OFFICE := "office"
const AVAILABLE_CHAIN := "chain"
const MAX_TIER := 2


## What hiring costs: {capital, yen}.
static func hire_cost() -> Dictionary:
	return {"capital": Levers.whole("campaign_staff_hire_capital"), "yen": Levers.whole("campaign_staff_hire_yen")}


## What upgrading from `tier` to `tier + 1` costs: each upgrade costs double the step before (the hire is step 0, so tier 0 -> 1 costs twice
## the hire and tier 1 -> 2 four times). {} when the member is already at the top.
static func upgrade_cost(tier: int) -> Dictionary:
	if tier < 0 or tier >= MAX_TIER:
		return {}
	var factor := int(pow(2.0, float(tier + 1)))
	return {"capital": Levers.whole("campaign_staff_hire_capital") * factor, "yen": Levers.whole("campaign_staff_hire_yen") * factor}


## The highest tier a row allows (the row's Highest Upgradable Tier, never above 2).
static func highest_tier(row: Dictionary) -> int:
	return clampi(int(row.get("highest_tier", 0)), 0, MAX_TIER)


## Whether a row can be hired at all right now: an `office` row once the Campaign Office is open; a `chain` row once a Campaign Moment! has
## found them (their ID is in `unlocked`).
static func available(row: Dictionary, office_open: bool, unlocked: Array) -> bool:
	match str(row.get("available", "")):
		AVAILABLE_OFFICE:
			return office_open
		AVAILABLE_CHAIN:
			return unlocked.has(str(row.get("staff_id", "")))
	return false


## Whether hiring is allowed on `date`: the office is open and no Election Day has just passed in the same year.
static func can_hire_on(date: int, cycles: Array, office_open: bool) -> bool:
	return office_open and not ElectionCycle.hiring_blocked(date, cycles)


## A new hire as a member Dictionary: tier = the row's starting tier, the hire paid in invested_yen, Loyalty at its usual start.
static func hire(row: Dictionary) -> Dictionary:
	return {"staff_id": str(row.get("staff_id", "")), "role": str(row.get("role", "")), "tier": int(row.get("starting_tier", 0)),
		"loyalty": Levers.whole("staff_loyalty_start"), "invested_yen": int(hire_cost()["yen"]), "lent_until": -1}


## The member after an upgrade (one tier up, the yen paid added to what is invested), or the same member when already at their row's top.
static func upgraded(member: Dictionary, row: Dictionary) -> Dictionary:
	var tier := int(member.get("tier", 0))
	if tier >= highest_tier(row):
		return member.duplicate()
	var next := member.duplicate()
	next["tier"] = tier + 1
	next["invested_yen"] = int(member.get("invested_yen", 0)) + int(upgrade_cost(tier)["yen"])
	return next


## A member's weekly wage: StaffLoyalty.wage on the YEN invested only (capital does not count).
static func wage_for(member: Dictionary) -> int:
	return StaffLoyalty.wage(int(member.get("invested_yen", 0)), false)


## Pays the week's wages from the campaign fund in the order given (the caller puts the longest-serving first): {paid, missed, spent}. A lent
## member is still paid.
static func settle_week(members: Array, fund: int) -> Dictionary:
	var owed: Array = []
	for member: Variant in members:
		owed.append({"staff_id": str((member as Dictionary).get("staff_id", "")), "wage": wage_for(member as Dictionary)})
	return StaffLoyalty.settle_wages(owed, fund)


## What a missed wage does to a member's Loyalty and rank: StaffLoyalty.after_week, with the row's starting tier as the floor.
static func after_week(member: Dictionary, missed_wage: bool, row: Dictionary) -> Dictionary:
	return StaffLoyalty.after_week(int(member.get("loyalty", 0)), missed_wage, int(member.get("tier", 0)), int(row.get("starting_tier", 0)))


## True while a member is lent to a colleague on `date`.
static func is_lent(member: Dictionary, date: int) -> bool:
	return int(member.get("lent_until", -1)) > date


## The member lent for `weeks` weeks from `date`: effects off, wage still paid.
static func lent(member: Dictionary, date: int, weeks: int) -> Dictionary:
	var next := member.duplicate()
	next["lent_until"] = date + maxi(1, weeks) * 7
	return next


## The free member (hired and not lent) with the highest tier; ties by staff ID. {} when none is free.
static func best_free(members: Array, date: int) -> Dictionary:
	var best: Dictionary = {}
	for member: Variant in members:
		var candidate := member as Dictionary
		if is_lent(candidate, date):
			continue
		if best.is_empty() or int(candidate.get("tier", 0)) > int(best.get("tier", 0)) \
				or (int(candidate.get("tier", 0)) == int(best.get("tier", 0)) and str(candidate.get("staff_id", "")) < str(best.get("staff_id", ""))):
			best = candidate
	return best


## Who is left after the day after an Election Day, or after the selection card says Not Selected: nobody (they go home; no firing cost).
static func after_leaving(_members: Array) -> Array:
	return []
