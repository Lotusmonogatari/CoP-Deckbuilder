class_name HostedEvent
extends RefCounted
## Hosted events (2026-10-23, Cameron): the walking tour and the dinner. Each is
## three screens of choices (what to do or eat, a policy topic, a modest
## promise); after each screen the guests react. A guest's organization likes
## and dislikes tags (Organization Tastes), each option carries tags (Event
## Options), and a reaction is the sum, kept between -2 and +2. The standing,
## awareness and reputation that come of the evening are the total of those
## reactions, not an automatic bonus for choosing the organization.
##
## Pure and UI-free (CLAUDE.md section 12): data and numbers come in as
## arguments, randomness through a RandomNumberGenerator the caller supplies.

const DELIGHTED := "Delighted"
const PLEASED := "Pleased"
const NEUTRAL := "Neutral"
const UNEASY := "Uneasy"
const OFFENDED := "Offended"

## Party-tier organizations follow the player's party and are never guests.
const PARTY_TIER := "Party"


static func settings(balance: Dictionary) -> Dictionary:
	return {
		"roster": maxi(1, int(balance.get("hosted_roster_size", 5))),
		"patron_weight": maxi(1, int(balance.get("hosted_patron_weight", 2))),
		"org_cap": maxi(1, int(balance.get("hosted_org_standing_cap", 6))),
		"divisor": maxi(1, int(balance.get("hosted_awareness_divisor", 2))),
		"awareness_max": int(balance.get("hosted_awareness_max", 6)),
		"awareness_min": int(balance.get("hosted_awareness_min", -3)),
		"good_net": int(balance.get("hosted_good_evening_net", 6)),
		"bad_net": int(balance.get("hosted_bad_evening_net", -4)),
	}


## The options of one step of one event, in workbook order.
static func options_for(options: Array, hosted_id: String, step: int) -> Array:
	var found: Array = []
	for row: Dictionary in options:
		if str(row.get("hosted_id", "")) == hosted_id and int(row.get("step", 0)) == step:
			found.append(row)
	return found


## The pick screens inside a step: each distinct Slot in order ("Entree",
## "Drink", "Side"), or one unnamed screen when the step has no slots.
static func slots_for(options: Array, hosted_id: String, step: int) -> Array[String]:
	var slots: Array[String] = []
	for row: Dictionary in options_for(options, hosted_id, step):
		var slot := str(row.get("slot", "")) if row.get("slot") != null else ""
		if not slots.has(slot):
			slots.append(slot)
	return slots


static func options_for_slot(options: Array, hosted_id: String, step: int, slot: String) -> Array:
	var found: Array = []
	for row: Dictionary in options_for(options, hosted_id, step):
		var own := str(row.get("slot", "")) if row.get("slot") != null else ""
		if own == slot:
			found.append(row)
	return found


## An organization's likes and dislikes as { likes: [], dislikes: [] }.
static func taste_of(tastes: Array, org_id: String) -> Dictionary:
	for row: Dictionary in tastes:
		if str(row.get("booster_id", "")) == org_id:
			return {"likes": row.get("likes", []) if row.get("likes") != null else [],
				"dislikes": row.get("dislikes", []) if row.get("dislikes") != null else []}
	return {"likes": [], "dislikes": []}


## How one guest takes what was chosen: +1 for each tag their organization
## likes, -1 for each it dislikes, over every option in `tag_lists`; kept
## between -2 and +2.
static func reaction(tastes: Array, guest_org: String, tag_lists: Array) -> int:
	var taste := taste_of(tastes, guest_org)
	var total := 0
	for tags: Variant in tag_lists:
		for tag: Variant in (tags as Array):
			if (taste["likes"] as Array).has(tag):
				total += 1
			if (taste["dislikes"] as Array).has(tag):
				total -= 1
	return clampi(total, -2, 2)


static func level_of(reaction_value: int) -> String:
	if reaction_value >= 2:
		return DELIGHTED
	if reaction_value == 1:
		return PLEASED
	if reaction_value == 0:
		return NEUTRAL
	if reaction_value == -1:
		return UNEASY
	return OFFENDED


## A line for this reaction, with {name} filled in; `pick` is a 0-up number the
## caller chooses so the same evening does not repeat itself.
static func line_for(lines: Array, level: String, guest_name: String, pick: int) -> String:
	var found: Array[String] = []
	for row: Dictionary in lines:
		if str(row.get("level", "")) == level:
			found.append(str(row.get("line", "")))
	if found.is_empty():
		return guest_name
	return found[absi(pick) % found.size()].replace("{name}", guest_name)


## Organizations allied with `org_id`, nearest first: those that share a party
## with it (Party Stakeholders), by the product of their weights there. Party
## bodies are left out.
static func allies(org_id: String, stakeholders: Array, boosters: Array) -> Array[String]:
	var party_orgs := {}
	for booster: Dictionary in boosters:
		if str(booster.get("tier", "")) == PARTY_TIER:
			party_orgs[str(booster.get("booster_id", ""))] = true
	var by_party := {}
	for row: Dictionary in stakeholders:
		var party := str(row.get("party_id", ""))
		if not by_party.has(party):
			by_party[party] = {}
		(by_party[party] as Dictionary)[str(row.get("booster_id", ""))] = float(row.get("weight", 0))
	var scores := {}
	for party: String in by_party.keys():
		var weights: Dictionary = by_party[party]
		if not weights.has(org_id) or float(weights[org_id]) <= 0.0:
			continue
		for other: String in weights.keys():
			if other == org_id or party_orgs.has(other) or float(weights[other]) <= 0.0:
				continue
			scores[other] = float(scores.get(other, 0.0)) + float(weights[org_id]) * float(weights[other])
	var ordered: Array = scores.keys()
	ordered.sort_custom(func(a: String, b: String) -> bool:
		return float(scores[a]) > float(scores[b]) or (float(scores[a]) == float(scores[b]) and a < b))
	var result: Array[String] = []
	for id: Variant in ordered:
		result.append(str(id))
	return result


## Who comes. Up to `size` guests: the organization's own characters first (at
## most three), then characters of its allies, one from each in turn, then
## second helpings. `people_by_org` is { org_id: [{ id, name, title, org }] }.
static func pick_roster(org_id: String, people_by_org: Dictionary, ally_ids: Array,
		size: int, rng: RandomNumberGenerator) -> Array:
	var roster: Array = []
	var used := {}
	var own: Array = _shuffled(people_by_org.get(org_id, []), rng)
	var own_limit := mini(maxi(1, int(ceil(size * Levers.num("hosted_event_own_organization_guest_percent") / 100.0))), size)
	for person: Dictionary in own:
		if roster.size() >= own_limit:
			break
		roster.append(person)
		used[str(person["id"])] = true
	var pools := {}
	for ally: Variant in ally_ids:
		pools[str(ally)] = _shuffled(people_by_org.get(str(ally), []), rng)
	var progress := true
	while roster.size() < size and progress:
		progress = false
		for ally: Variant in ally_ids:
			if roster.size() >= size:
				break
			var pool: Array = pools[str(ally)]
			while not pool.is_empty():
				var person: Dictionary = pool.pop_front()
				if not used.has(str(person["id"])):
					roster.append(person)
					used[str(person["id"])] = true
					progress = true
					break
	return roster


static func _shuffled(source: Variant, rng: RandomNumberGenerator) -> Array:
	var copy: Array = (source as Array).duplicate() if source is Array else []
	for i in range(copy.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: Variant = copy[i]
		copy[i] = copy[j]
		copy[j] = swap
	return copy


## Every guest's reaction to what was chosen on one step:
## [{ guest, reaction }].
static func score_step(roster: Array, tastes: Array, tag_lists: Array) -> Array:
	var found: Array = []
	for guest: Dictionary in roster:
		found.append({"guest": guest, "reaction": reaction(tastes, str(guest.get("org", "")), tag_lists)})
	return found


## The evening in total, from every step's scored reactions:
## { org_deltas: { org: change }, net, awareness, reputation }.
static func totals(step_results: Array, patron_org: String, cfg: Dictionary) -> Dictionary:
	var deltas := {}
	var net := 0
	for step: Variant in step_results:
		for entry: Dictionary in (step as Array):
			var org := str((entry["guest"] as Dictionary).get("org", ""))
			var value := int(entry["reaction"])
			net += value
			var weight := int(cfg["patron_weight"]) if org == patron_org else 1
			deltas[org] = int(deltas.get(org, 0)) + value * weight
	for org: String in deltas.keys():
		deltas[org] = clampi(int(deltas[org]), -int(cfg["org_cap"]), int(cfg["org_cap"]))
	var awareness := clampi(roundi(float(net) / float(cfg["divisor"])),
		int(cfg["awareness_min"]), int(cfg["awareness_max"]))
	var reputation := 0
	if net >= int(cfg["good_net"]):
		reputation = 1
	elif net <= int(cfg["bad_net"]):
		reputation = -1
	return {"org_deltas": deltas, "net": net, "awareness": awareness, "reputation": reputation}
