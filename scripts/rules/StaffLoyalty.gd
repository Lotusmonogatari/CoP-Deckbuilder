class_name StaffLoyalty
extends RefCounted
## Staff wages and Loyalty (Cameron, 2026-11-16; design/proposals/
## STAFF_LOYALTY_2026-11-16.md and STAFF_ASSIGNMENTS_2026-11-16.md).
##
## Every hired person is paid a weekly wage (a share of everything invested in
## them) and has a Loyalty number, 0 to 100. Paying on time, how the player
## stands with the organizations the person is allied to, time with the
## office, promotion and the daily tasks (StaffTasks.gd) move it. Low Loyalty
## weakens the person, loses them a rank, and finally makes them quit for good.
##
## Pure rules: no UI, no autoloads, no files. Every number is a Balance lever
## read through Levers (the audit C-6 rule); the run state lives in GameState.

const BAND_NORMAL := "normal"
const BAND_RESTLESS := "restless"
const BAND_LEAVING := "leaving"

## The words the player reads for a Loyalty value (Text rows name them).
const WORD_DEVOTED := "devoted"
const WORD_STEADY := "steady"
const WORD_RESTLESS := "restless"
const WORD_LEAVING := "leaving"


## The wage one person costs this week: a percent of everything invested in
## them (hire price plus every upgrade paid), more when pay was raised.
static func wage(invested: int, pay_raised: bool) -> int:
	var base := int(floor(invested * Levers.num("staff_wage_percent") / 100.0))
	if pay_raised:
		return int(floor(base * Levers.num("staff_raise_pay_multiple_percent") / 100.0))
	return base


## What a person has cost so far if only their rank is known (an older save,
## or a test): the hiring price plus each upgrade up to the current rank.
static func invested_for(candidate: Dictionary, tier: int) -> int:
	var total := int(candidate.get("hiring_cost_yen", 0))
	var start := int(candidate.get("starting_tier", 0))
	if tier > start:
		var first: Variant = candidate.get("upgrade_cost_0_to_1_yen")
		var second: Variant = candidate.get("upgrade_cost_1_to_2_yen")
		if start <= 0 and tier >= 1 and first != null:
			total += int(first)
		if start <= 1 and tier >= 2 and second != null:
			total += int(second)
	return total


## Restless (boosts and tasks one step weaker), leaving (one step weaker still),
## or normal.
static func band(loyalty: int) -> String:
	if loyalty < Levers.whole("staff_loyalty_leaving_below"):
		return BAND_LEAVING
	if loyalty < Levers.whole("staff_loyalty_restless_below"):
		return BAND_RESTLESS
	return BAND_NORMAL


## The word for a value: Devoted, Steady, Restless or About to leave.
static func word(loyalty: int) -> String:
	if loyalty < Levers.whole("staff_loyalty_leaving_below"):
		return WORD_LEAVING
	if loyalty < Levers.whole("staff_loyalty_restless_below"):
		return WORD_RESTLESS
	if loyalty >= Levers.whole("staff_loyalty_devoted_from"):
		return WORD_DEVOTED
	return WORD_STEADY


## How many boosters' worth of weight each organization has for this person:
## every organization named in the rewards of the ranks they hold counts once
## per mention (Cameron: "multiple of the same organization multiplies").
## `tier` is the rank held now; ranks from 0 up to it count.
static func allies(candidate: Dictionary, tier: int) -> Dictionary:
	var weights := {}
	for held in range(0, tier + 1):
		var rewards: Variant = candidate.get("tier_%d_reward" % held)
		if not (rewards is Array):
			continue
		for reward: Variant in rewards:
			if not (reward is Dictionary):
				continue
			var target := str((reward as Dictionary).get("target", ""))
			if target.begins_with("BO"):
				weights[target] = int(weights.get(target, 0)) + 1
	return weights


## The weekly Loyalty change from standing with the person's allies: the
## weighted average standing, then +/- `affinity_loyalty_step` for every
## `affinity_points_step` points above or below the pivot (50).
static func affinity(ally_weights: Dictionary, standing: Dictionary) -> int:
	var total := 0
	var weight_sum := 0
	for organization: String in ally_weights.keys():
		var weight := int(ally_weights[organization])
		total += int(standing.get(organization, Levers.num("staff_loyalty_affinity_pivot"))) * weight
		weight_sum += weight
	if weight_sum <= 0:
		return 0
	var average := float(total) / float(weight_sum)
	var points := maxf(1.0, Levers.num("staff_loyalty_affinity_points_step"))
	return roundi((average - Levers.num("staff_loyalty_affinity_pivot")) / points * Levers.num("staff_loyalty_affinity_step"))


## +1 every few weeks with the office, up to a total. Called once a week with
## the number of weeks the person has now worked.
static func tenure_gain(weeks_worked: int) -> int:
	var every := maxi(1, Levers.whole("staff_loyalty_tenure_weeks_per_point"))
	if weeks_worked > 0 and weeks_worked % every == 0 and weeks_worked / every <= Levers.whole("staff_loyalty_tenure_cap"):
		return 1
	return 0


## Promoted past the rank they were hired at.
static func pride_gain(tier: int, starting_tier: int) -> int:
	return Levers.whole("staff_loyalty_rank_pride") if tier > starting_tier else 0


## One week's Loyalty change, the sum of its parts, held inside the weekly
## swing limits so one bad week never ends a career alone.
static func weekly_total(paid: bool, ally_change: int, tenure: int, pride: int, tasks: int) -> int:
	var total := ally_change + tenure + pride + tasks
	total += Levers.whole("staff_loyalty_paid_bonus") if paid else -Levers.whole("staff_loyalty_missed_penalty")
	return clampi(total, -Levers.whole("staff_loyalty_weekly_loss_cap"), Levers.whole("staff_loyalty_weekly_gain_cap"))


## The order wages are paid in when Funds run short: primary staff first,
## then the least loyal first, so the most loyal forgive a late week.
## `members` are { staff_id, primary, loyalty }.
static func pay_order(members: Array) -> Array:
	var ordered := members.duplicate()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_primary := bool(a.get("primary", false))
		var b_primary := bool(b.get("primary", false))
		if a_primary != b_primary:
			return a_primary
		if int(a.get("loyalty", 0)) != int(b.get("loyalty", 0)):
			return int(a.get("loyalty", 0)) < int(b.get("loyalty", 0))
		return str(a.get("staff_id", "")) < str(b.get("staff_id", "")))
	return ordered


## Pays each person in full, in order, while Funds last; nobody is part-paid.
## `members` are { staff_id, wage }, already in pay order.
## Returns { paid: [ids], missed: [ids], spent }.
static func settle_wages(members: Array, funds: int) -> Dictionary:
	var paid: Array[String] = []
	var missed: Array[String] = []
	var left := maxi(0, funds)
	var spent := 0
	for member: Dictionary in members:
		var due := int(member.get("wage", 0))
		if due <= left:
			left -= due
			spent += due
			paid.append(str(member.get("staff_id", "")))
		else:
			missed.append(str(member.get("staff_id", "")))
	return {"paid": paid, "missed": missed, "spent": spent}


## What one person's Loyalty does at the week's end. Returns
## { loyalty, rank_lost, quits }: Loyalty at zero or below quits for good; a
## missed wage that leaves them under the rank-loss line loses one rank (never
## below the rank they were hired at) and restarts Loyalty higher.
static func after_week(loyalty: int, missed_wage: bool, tier: int, starting_tier: int) -> Dictionary:
	if loyalty <= Levers.whole("staff_loyalty_quit_at"):
		return {"loyalty": 0, "rank_lost": false, "quits": true}
	if missed_wage and loyalty < Levers.whole("staff_loyalty_rank_loss_below") and tier > starting_tier:
		return {"loyalty": Levers.whole("staff_loyalty_after_rank_loss"), "rank_lost": true, "quits": false}
	return {"loyalty": clampi(loyalty, 0, 100), "rank_lost": false, "quits": false}


## What leaving costs: Reputation, and standing with every ally, multiplied by
## that ally's weight. `quit` is true for a resignation, false for a firing
## (a firing costs no Reputation and a smaller standing hit).
static func leaving_penalty(ally_weights: Dictionary, quit: bool) -> Dictionary:
	var standing := {}
	var per_weight := Levers.whole("staff_quit_ally_standing") if quit else Levers.whole("staff_fire_ally_standing")
	for organization: String in ally_weights.keys():
		standing[organization] = -per_weight * int(ally_weights[organization])
	return {"reputation": -Levers.whole("staff_quit_reputation") if quit else 0, "standing": standing}


## A task result weaker for a person who is not at ease: a restless person's
## strong fit counts as fair; one about to leave does everything one step
## worse (strong becomes fair, fair becomes poor). `fit` is "strong", "fair" or
## "poor", returned the same way.
static func weakened_fit(fit: String, loyalty: int) -> String:
	match band(loyalty):
		BAND_RESTLESS:
			return "fair" if fit == "strong" else fit
		BAND_LEAVING:
			if fit == "strong":
				return "fair"
			if fit == "fair":
				return "poor"
	return fit
