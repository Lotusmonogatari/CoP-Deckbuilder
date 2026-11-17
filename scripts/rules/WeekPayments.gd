class_name WeekPayments
extends RefCounted
## End of Week Payments (P9, 2026-11-17): what the week's end will take, as one
## total made of party dues and staff wages, with every part and what happens
## when Funds are short.
##
## A DISPLAY OF WHAT THE WEEK END ALREADY SETTLES. It calls the same rule
## functions GameState.go_home() uses (PartyDues.settle, StaffLoyalty.pay_order
## and settle_wages), in the same order: dues first, then the confirmed staff
## day's Funds, then wages (primary staff first, then the least loyal; nobody is
## part-paid). No rule or number lives here. Pure: no autoload, file or scene.
##
## `staff` entries are { staff_id, name, primary, loyalty, wage, raised }.


## Returns:
##   dues:   { total, carried, paid, owed }       what the party is owed, paid and left owed
##   wages:  [ { staff_id, name, wage, raised, paid } ]   in the order they are paid
##   wages_total, wages_paid, unpaid: [names whose wage will be missed]
##   total:  dues.total + wages_total             the headline number
##   funds:  { now, after }                        Funds now, and after dues, the staff day and wages
##   short_by: how far Funds fall short of `total` (0 when everything can be paid)
##   unpaid_dues: true when some dues stay owed
static func build(dues_total: int, carried: int, funds_now: int, staff_day_funds: int,
		staff: Array) -> Dictionary:
	var settled := PartyDues.settle(dues_total, funds_now)
	var funds_before_wages := funds_now - int(settled["paid"]) + staff_day_funds
	var ordered := StaffLoyalty.pay_order(staff)
	var result := StaffLoyalty.settle_wages(ordered, funds_before_wages)
	var missed: Array = result["missed"]
	var wages: Array = []
	var wages_total := 0
	var unpaid: Array[String] = []
	for member: Dictionary in ordered:
		var id := str(member.get("staff_id", ""))
		var paid := not missed.has(id)
		wages.append({"staff_id": id, "name": str(member.get("name", id)), "wage": int(member.get("wage", 0)),
			"raised": bool(member.get("raised", false)), "paid": paid})
		wages_total += int(member.get("wage", 0))
		if not paid:
			unpaid.append(str(member.get("name", id)))
	var total := dues_total + wages_total
	return {
		"dues": {"total": dues_total, "carried": carried, "paid": int(settled["paid"]), "owed": int(settled["owed"])},
		"wages": wages, "wages_total": wages_total, "wages_paid": int(result["spent"]), "unpaid": unpaid,
		"total": total,
		"funds": {"now": funds_now, "after": funds_before_wages - int(result["spent"])},
		"short_by": maxi(0, total - funds_now - staff_day_funds),
		"unpaid_dues": int(settled["owed"]) > 0,
	}
