class_name PatronRequests
extends RefCounted
## Patron requests (2026-10-19, Cameron): when an organization's standing with
## the player is high enough it asks them to carry a bill. A Favor (two of the
## organization's components) comes at the Favor threshold; a Flagship (two of
## its own plus one from an ally) at the higher one. This file decides who is
## due a request, what declining, amending and the vote's result do to
## standing. Every number is a Balance lever (the `balance` argument).
##
## A request's status is one of: "waiting" (due, in the queue), "open" (shown
## in the Requests block), "accepted" (the level is under way), "declined",
## "passed", "failed", "lapsed".
##
## Pure and UI-free (CLAUDE.md section 12).

const WAITING := "waiting"
const OPEN := "open"
const ACCEPTED := "accepted"
const DECLINED := "declined"
const PASSED := "passed"
const FAILED := "failed"
const LAPSED := "lapsed"
const FAVOR := "Favor"
const FLAGSHIP := "Flagship"

## A failed Favor lowers that organization's Flagship threshold by this much
## (the attempt is remembered). A lever in the workbook would be a later step.
const FLAGSHIP_DISCOUNT_AFTER_FAILED_FAVOR := 5


## The lowest default Yes a bill of this kind may start with. A Flagship has its
## own, lower floor (a harder vote); blank falls back to the Favor floor.
static func default_yes_floor(kind: String, balance: Dictionary) -> int:
	if kind == FLAGSHIP and balance.has("patron_flagship_default_yes_floor"):
		return int(balance["patron_flagship_default_yes_floor"])
	return int(balance.get("patron_default_yes_floor", -1))


static func threshold_for(patron_bill: Dictionary, balance: Dictionary) -> int:
	var cell: Variant = patron_bill.get("threshold")
	if cell != null:
		return int(cell)
	if str(patron_bill.get("kind", FAVOR)) == FLAGSHIP:
		return int(balance.get("patron_flagship_threshold", 70))
	return int(balance.get("patron_favor_threshold", 50))


## Patron bill ids that are due now and not yet in `statuses` ({pb_id: status}),
## given every organization's `standing` ({booster_id: number}). A Flagship
## also needs its organization's Favor to have been resolved (passed, failed,
## declined or lapsed); one request per kind per organization per run.
static func due(patron_bills: Array, standing: Dictionary, statuses: Dictionary,
		balance: Dictionary) -> Array:
	var out: Array = []
	for bill: Dictionary in patron_bills:
		var id := str(bill.get("patron_bill_id", ""))
		if statuses.has(id):
			continue
		var org := str(bill.get("organization", ""))
		var needed := threshold_for(bill, balance)
		if str(bill.get("kind", FAVOR)) == FLAGSHIP:
			var favor_status := _favor_status(patron_bills, statuses, org)
			if favor_status == "" or favor_status == WAITING or favor_status == OPEN or favor_status == ACCEPTED:
				continue
			if favor_status == FAILED:
				needed -= FLAGSHIP_DISCOUNT_AFTER_FAILED_FAVOR
		if int(standing.get(org, 0)) >= needed:
			out.append(id)
	out.sort()
	return out


static func _favor_status(patron_bills: Array, statuses: Dictionary, org: String) -> String:
	for bill: Dictionary in patron_bills:
		if str(bill.get("organization", "")) == org and str(bill.get("kind", "")) == FAVOR:
			return str(statuses.get(str(bill.get("patron_bill_id", "")), ""))
	return ""


## How many more requests may be shown right now (waiting at once is a lever).
static func room_to_open(statuses: Dictionary, balance: Dictionary) -> int:
	var shown := 0
	for id: String in statuses:
		if statuses[id] == OPEN or statuses[id] == ACCEPTED:
			shown += 1
	return maxi(0, int(balance.get("patron_requests_waiting_at_once", 2)) - shown)


static func decline_cost(kind: String, balance: Dictionary) -> int:
	if kind == FLAGSHIP:
		return int(balance.get("patron_flagship_decline_cost", 10))
	return int(balance.get("patron_favor_decline_cost", 5))


## Swaps Amend allows. Favor: replace either of the two components with the
## owner's spare from the same pool (slot V). Flagship: replace the ally's offer
## with another of the ally's offers. Returns [{"replace": id, "with": id}],
## leaving out components that are already law (`enacted`) or in the bill.
static func amend_options(patron_bill: Dictionary, by_id: Dictionary, enacted: Array) -> Array:
	var ids: Array = patron_bill.get("components", []) as Array
	var out: Array = []
	if ids.is_empty():
		return out
	var replace_pool: Array = ids.duplicate()
	if str(patron_bill.get("kind", FAVOR)) == FLAGSHIP and ids.size() >= 3:
		replace_pool = [ids[2]]
	for replaced: Variant in replace_pool:
		var component: Dictionary = by_id.get(str(replaced), {})
		var owner := str(component.get("owner", ""))
		var pool := ComposedBill.pool_of(str(component.get("slot", "")))
		for candidate_id: Variant in ComposedBill.pool_members(owner, pool, by_id):
			if not ids.has(candidate_id) and not enacted.has(candidate_id):
				out.append({"replace": str(replaced), "with": str(candidate_id)})
	return out


## The component ids after an Amend swap.
static func apply_amend(ids: Array, replace: String, with_id: String) -> Array:
	var out: Array = ids.duplicate()
	var at := out.find(replace)
	if at >= 0:
		out[at] = with_id
	return out


## Standing changes when the player declines: [{"target", "delta"}].
static func decline_deltas(patron_bill: Dictionary, balance: Dictionary) -> Array:
	return [{"target": str(patron_bill.get("organization", "")),
			"delta": -decline_cost(str(patron_bill.get("kind", FAVOR)), balance)}]


## What the vote does to standing, as {"standing": [{"target","delta"}],
## "free_backing_units": int, "remember_failed_favor": bool}. The patron gets
## the pass or fail amount, the Flagship ally its own, and the organizations
## the bill hurts (`rivals`) lose or gain a little. An amended bill's rewards
## (gains, never costs) are scaled by `patron_amend_reward_percent`.
static func outcome(patron_bill: Dictionary, ally: String, rivals: Array, passed: bool,
		amended: bool, balance: Dictionary) -> Dictionary:
	var kind := str(patron_bill.get("kind", FAVOR))
	var org := str(patron_bill.get("organization", ""))
	var flagship := kind == FLAGSHIP
	var standing: Array = []
	var scale := int(balance.get("patron_amend_reward_percent", 75)) / 100.0 if amended else 1.0
	if passed:
		var pass_key := "patron_flagship_pass_standing" if flagship else "patron_favor_pass_standing"
		if not org.is_empty():
			standing.append({"target": org, "delta": PartySalience.scaled(int(balance.get(pass_key, 6)), scale)})
		if flagship and not ally.is_empty():
			standing.append({"target": ally, "delta": PartySalience.scaled(int(balance.get("patron_ally_pass_standing", 4)), scale)})
		var rival_key := "patron_flagship_rival_penalty" if flagship else "patron_favor_rival_penalty"
		for rival: String in rivals:
			standing.append({"target": rival, "delta": -int(balance.get(rival_key, 2))})
	else:
		if not org.is_empty():
			standing.append({"target": org, "delta": -int(balance.get("patron_fail_standing", 2))})
		if flagship and not ally.is_empty():
			standing.append({"target": ally, "delta": -int(balance.get("patron_ally_fail_standing", 1))})
		for rival: String in rivals:
			standing.append({"target": rival, "delta": int(balance.get("patron_rival_fail_standing", 1))})
	return {
		"standing": standing,
		"free_backing_units": int(balance.get("patron_free_backing_units", 30)) if passed and flagship and not org.is_empty() else 0,
		"remember_failed_favor": (not passed) and not flagship,
	}


## Organizations a bill hurts: every target with a negative merged effect,
## the patron and ally never counted as rivals.
static func rivals_of(effects: Array, org: String, ally: String) -> Array:
	var out: Array = []
	for entry: Dictionary in effects:
		var target := str(entry.get("target", ""))
		if int(entry.get("delta", 0)) < 0 and target != org and target != ally:
			out.append(target)
	return out
