class_name StaffRosterModel
extends RefCounted
## What the Staff tab of Office Management shows (P13, 2026-11-20), as plain data: the summary (what the staff cost this
## week, how many people are hired of how many places, places per role) and, for each role, one entry for every hired
## person and a count of open places. It reads the same sources the old staff list read (GameState, Ledger, DataDB) and says
## nothing it did not; StaffRosterView only draws it. The staff count is the number of people listed, by construction.


static func build() -> Dictionary:
	var slots := GameState.staff_slots()
	var roles: Array = []
	var hired_total := 0
	for role: String in Ledger.staff_roles(DataDB.staff):
		var members := GameState.staff_in_role(role)
		var people: Array = []
		for i in members.size():
			people.append(person(role, members[i], i))
		hired_total += people.size()
		roles.append({"role": role, "people": people, "open": maxi(0, slots - members.size()), "places": slots,
			"filled_text": Text.say("office.staff_role_places", {"filled": members.size(), "places": slots})})
	return {
		"wages": Phrase.meta_amount("Funds", int(GameState.staff_wage_preview()["total"])),
		"staff_count": Text.say("office.staff_count_of", {"count": hired_total, "total": roles.size() * slots}),
		"hired_total": hired_total,
		"places": slots,
		"roles": roles,
	}


## One hired person: the line the old row showed (name and rank), the tag by place, the Loyalty and wage summary.
static func person(_role: String, hired: Dictionary, index: int) -> Dictionary:
	var staff_id := str(hired.get("staff_id", ""))
	var candidate := DataDB.get_staff(staff_id)
	var tags := [Text.say("office.staff_primary_tag"), Text.say("office.staff_second_tag"), Text.say("office.staff_third_tag")]
	return {"staff_id": staff_id, "node": "Profile_" + staff_id,
		"line": Text.say("office.staff_hired", {"name": candidate.get("name", staff_id), "tier": int(hired.get("tier", 0)),
			"highest": int(candidate.get("highest_tier", 0))}),
		"tag": str(tags[mini(index, tags.size() - 1)]), "primary": index == 0,
		"summary": StaffLoyaltyView.summary(staff_id)}
