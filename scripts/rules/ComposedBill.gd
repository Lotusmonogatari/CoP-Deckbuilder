class_name ComposedBill
extends RefCounted
## A bill assembled from components (patron bills and Draft a Bill,
## 2026-10-19, Cameron). Components come from the Bill Components tab
## (data/bill_components.json); this file turns a list of them into one bill
## record in the same shape as a floor_votes.json row, so FloorVoteEngine and
## everything downstream can treat it as an ordinary bill.
##
## Option A for repeats (Cameron's default, 2026-10-19): a component that is
## already law is never offered again. substitute_enacted() swaps it for the
## same owner's next component that is not law and not already in the bill.
##
## Pure and UI-free (CLAUDE.md section 12).

## Slots and the pool each belongs to (2026-10-19). A swap always stays inside
## the pool: a Favor component for a Favor component, a Flagship's own for its
## own, an ally offer for an ally offer. Order inside a pool is the order below.
const POOLS := {
	"favor": ["X", "Y", "V"],
	"flagship": ["Z", "W"],
	"offer": ["A", "B", "C", "D"],
}


static func pool_of(slot: String) -> String:
	for pool: String in POOLS:
		if (POOLS[pool] as Array).has(slot):
			return pool
	return ""


## The owner's components in `pool`, in slot order, as component ids.
static func pool_members(owner: String, pool: String, by_id: Dictionary) -> Array:
	var out: Array = []
	for slot: String in POOLS.get(pool, []):
		for id: String in by_id:
			var component: Dictionary = by_id[id]
			if str(component.get("owner", "")) == owner and str(component.get("slot", "")) == slot:
				out.append(id)
	return out


## The bill's words: "A bill to {a} and {b}" or "A bill to {a}, {b} and {c}".
## `template_2`/`template_3` come from the Text tab (custom_bill.name_2/3).
static func bill_name(phrases: Array, template_2: String, template_3: String) -> String:
	if phrases.size() == 2:
		return template_2.replace("{a}", str(phrases[0])).replace("{b}", str(phrases[1]))
	if phrases.size() >= 3:
		return template_3.replace("{a}", str(phrases[0])).replace("{b}", str(phrases[1])).replace("{c}", str(phrases[2]))
	return str(phrases[0]) if phrases.size() == 1 else ""


## Components by id.
static func index(components: Array) -> Dictionary:
	var out := {}
	for component: Dictionary in components:
		out[str(component.get("component_id", ""))] = component
	return out


## True when any component in `ids` lists another one of them in Excludes.
static func has_conflict(ids: Array, by_id: Dictionary) -> bool:
	for id: String in ids:
		var excludes: Variant = (by_id.get(id, {}) as Dictionary).get("excludes")
		if excludes is Array:
			for other: Variant in excludes:
				if ids.has(str(other)):
					return true
	return false


## Replaces every component in `ids` that is already law (`enacted`, an array
## of component ids) with the same owner's first component, in the same pool and
## slot order, that is not law and not already in the bill. Returns {"ids":
## Array, "ok": bool}; ok is false when some repeat has nothing to replace it,
## in which case the bill should not be offered. (The workbook is checked at
## export so this cannot happen: see "Option A coverage" in export_data.py.)
static func substitute_enacted(ids: Array, by_id: Dictionary, enacted: Array) -> Dictionary:
	var out: Array = ids.duplicate()
	var ok := true
	for i in range(out.size()):
		if not enacted.has(out[i]):
			continue
		var component: Dictionary = by_id.get(out[i], {})
		var owner := str(component.get("owner", ""))
		var pool := pool_of(str(component.get("slot", "")))
		var swap := ""
		for candidate_id: Variant in pool_members(owner, pool, by_id):
			if not enacted.has(candidate_id) and not out.has(candidate_id):
				swap = str(candidate_id)
				break
		if swap == "":
			ok = false
		else:
			out[i] = swap
	return {"ids": out, "ok": ok}


## Sums each target's delta across the components' lists (`key` is "gains" or
## "loses"), then scales by `percent`. A non-zero delta never rounds to 0.
## Returns [{"target", "delta"}], sorted by target for a stable order.
static func merged_effects(ids: Array, by_id: Dictionary, percent: int) -> Array:
	var sums := {}
	for id: String in ids:
		var component: Dictionary = by_id.get(id, {})
		for key: String in ["gains", "loses"]:
			var list: Variant = component.get(key)
			if list is Array:
				for entry: Dictionary in list:
					var target := str(entry.get("target", ""))
					sums[target] = int(sums.get(target, 0)) + int(entry.get("delta", 0))
	var targets := sums.keys()
	targets.sort()
	var out: Array = []
	for target: String in targets:
		var delta := PartySalience.scaled(int(sums[target]), percent / 100.0)
		if delta != 0:
			out.append({"target": target, "delta": delta})
	return out


## The seats each party's vote resistance lets the player's influence swing:
## {party_id: floor(seats x (1 - resistance))}. A party without its own
## Vote Resistance uses `default_resistance` (percent).
static func swing_capacity(parties: Array, default_resistance: int) -> Dictionary:
	var out := {}
	for party: Dictionary in parties:
		var resistance := int(party.get("vote_resistance", default_resistance)) if party.get("vote_resistance") != null else default_resistance
		out[str(party.get("party_id", ""))] = floori(int(party.get("seats", 0)) * (1.0 - resistance / 100.0))
	return out


## The bill record. `ctx` carries everything the bill needs from outside:
##   parties, salience (BillPositions.salience_table), threshold, yes_cap (-1 =
##   none), yes_floor (-1 = none), capacity (swing_capacity()), template_2, template_3, bill_id, favorability {supportive, opposed,
##   neutral}, law_scale_percent, proponent_party.
static func compose(ids: Array, by_id: Dictionary, ctx: Dictionary) -> Dictionary:
	var phrases: Array = []
	var descriptions: Array = []
	var tag_sets: Array = []
	for id: String in ids:
		var component: Dictionary = by_id.get(id, {})
		phrases.append(str(component.get("phrase", "")))
		descriptions.append(str(component.get("description", "")))
		tag_sets.append(BillPositions.parse_tags(component.get("value_tags")))
	var tags := BillPositions.merge_tags(tag_sets)
	var favorability := ctx.get("favorability", {}) as Dictionary
	var first: Dictionary = by_id.get(str(ids[0]), {}) if not ids.is_empty() else {}
	return {
		"bill_id": str(ctx.get("bill_id", "")),
		"bill_name": bill_name(phrases, str(ctx.get("template_2", "")), str(ctx.get("template_3", ""))),
		"bill_description": " ".join(descriptions),
		"favorability_delta_supportive": int(favorability.get("supportive", 1)),
		"favorability_delta_opposed": int(favorability.get("opposed", -1)),
		"favorability_delta_neutral": int(favorability.get("neutral", 0)),
		"influence_bonus_reputation": null,
		"influence_bonus_party_support": null,
		"vote_requirement": null,
		"proponent_party": str(ctx.get("proponent_party", "")),
		"stakeholders_override": null,
		"component_ids": ids.duplicate(),
		"hearing_stage": str(first.get("hearing_stage", "")),
		"tags": tags,
		"effects": merged_effects(ids, by_id, int(ctx.get("law_scale_percent", 100))),
		"positions": BillPositions.positions(tags, ctx.get("parties", []) as Array,
				ctx.get("salience", {}) as Dictionary, float(ctx.get("threshold", 30)),
				int(ctx.get("yes_cap", -1)), {}, int(ctx.get("yes_floor", -1)),
				ctx.get("capacity", {}) as Dictionary),
	}
