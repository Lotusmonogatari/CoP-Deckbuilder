class_name PatronLevel
extends RefCounted
## Builds the level for a patron bill the player has accepted (Patron Bills
## step 3, 2026-10-19). Like BattleSetup, this reads DataDB, so it lives beside
## it rather than in scripts/rules. The rules it leans on (ComposedBill,
## BillPositions, LevelTemplate, PatronRequests) stay pure.
##
## compose() turns a patron bill (plus an optional Amend swap and the
## components already law) into a floor_votes-shaped bill. level_row() turns
## the template and the bill into a levels.json-shaped row whose last slot is
## the bill itself, the same convention every bill level uses. register()
## does both and files them with DataDB for the run.

const LEVEL_PREFIX := "PL_"


static func patron_bill(patron_bill_id: String) -> Dictionary:
	for row: Dictionary in DataDB.patron_bills:
		if str(row.get("patron_bill_id", "")) == patron_bill_id:
			return row
	return {}


static func level_id_for(patron_bill_id: String) -> String:
	return LEVEL_PREFIX + patron_bill_id


## Everything ComposedBill needs from the workbook for a bill of `kind`.
static func context(kind: String, patron_bill_id: String) -> Dictionary:
	var balance := DataDB.balance
	return {
		"bill_id": patron_bill_id,
		"parties": DataDB.parties,
		"salience": BillPositions.salience_table(DataDB.party_values),
		"threshold": float(balance.get("bill_position_lean_threshold", 30)),
		"yes_cap": 51 - int(balance.get("patron_default_margin", 3)),
		"yes_floor": PatronRequests.default_yes_floor(kind, balance),
		"capacity": ComposedBill.swing_capacity(DataDB.parties,
				int(balance.get("vote_swing_resistance_default", 70))),
		"template_2": Text.say("custom_bill.name_2"),
		"template_3": Text.say("custom_bill.name_3"),
		"law_scale_percent": int(balance.get("custom_law_scale_percent", 50)),
	}


## The bill the player would carry. `enacted` is every component already law
## (Option A swaps those out); `replace`/`with_id` is an Amend swap (both blank
## for none). Returns {"ok": bool, "bill": Dictionary, "component_ids": Array,
## "amended": bool}; ok is false for an unknown bill or a repeat nothing can
## replace.
static func compose(patron_bill_id: String, enacted: Array, replace: String = "",
		with_id: String = "") -> Dictionary:
	var row := patron_bill(patron_bill_id)
	if row.is_empty():
		return {"ok": false, "bill": {}, "component_ids": [], "amended": false}
	var by_id := ComposedBill.index(DataDB.bill_components)
	var swapped := ComposedBill.substitute_enacted(row.get("components", []) as Array, by_id, enacted)
	var ids: Array = swapped["ids"]
	var amended := false
	if not replace.is_empty():
		var allowed := false
		var live := row.duplicate()
		live["components"] = ids
		for option: Dictionary in PatronRequests.amend_options(live, by_id, enacted):
			if option["replace"] == replace and option["with"] == with_id:
				allowed = true
		if not allowed:
			return {"ok": false, "bill": {}, "component_ids": ids, "amended": false}
		ids = PatronRequests.apply_amend(ids, replace, with_id)
		amended = true
	var kind := str(row.get("kind", PatronRequests.FAVOR))
	var bill := ComposedBill.compose(ids, by_id, context(kind, patron_bill_id))
	bill["patron_bill_id"] = patron_bill_id
	bill["patron_kind"] = kind
	bill["stakeholders_override"] = _stakeholders(bill["effects"] as Array)
	return {"ok": bool(swapped["ok"]), "bill": bill, "component_ids": ids, "amended": amended}


## "BO05+; BO09-": the organizations the bill helps and hurts, in the form
## BillStance reads, so the lean choice works for a composed bill.
static func _stakeholders(effects: Array) -> String:
	var parts: Array[String] = []
	for entry: Dictionary in effects:
		var target := str(entry.get("target", ""))
		if DataDB.get_booster(target).is_empty():
			continue
		parts.append("%s%s" % [target, "+" if int(entry.get("delta", 0)) > 0 else "-"])
	return "; ".join(parts)


## A levels.json-shaped row: the template's stages in order, the last slot
## holding the bill's id (the Floor Vote), as every bill level does.
static func level_row(row: Dictionary, bill: Dictionary) -> Dictionary:
	var template: Dictionary = {}
	for candidate: Dictionary in DataDB.bill_level_templates:
		if str(candidate.get("template_id", "")) == str(row.get("template_id", "")):
			template = candidate
	var owner_tier := str(DataDB.get_booster(str(row.get("organization", ""))).get("tier", ""))
	var stages := LevelTemplate.stages(template, str(bill.get("hearing_stage", "")), owner_tier)
	if stages.is_empty():
		return {}
	stages[stages.size() - 1] = str(bill.get("bill_id", ""))
	var level := {
		"level_id": level_id_for(str(row.get("patron_bill_id", ""))),
		"description": str(bill.get("bill_name", "")),
		"tier": template.get("level_tier"),
		"patron_bill_id": str(row.get("patron_bill_id", "")),
	}
	for index in range(stages.size()):
		level["stage_%d" % (index + 1)] = stages[index]
	return level


## Composes the bill, builds its level and files both with DataDB for the run.
## Returns {"ok", "bill", "level", "component_ids", "amended"}; ok is false (and
## nothing is registered) when the bill cannot be composed or has no level.
static func register(patron_bill_id: String, enacted: Array, replace: String = "",
		with_id: String = "") -> Dictionary:
	var composed := compose(patron_bill_id, enacted, replace, with_id)
	if not composed["ok"]:
		return composed
	var level := level_row(patron_bill(patron_bill_id), composed["bill"] as Dictionary)
	if level.is_empty():
		composed["ok"] = false
		return composed
	DataDB.register_runtime_bill(composed["bill"] as Dictionary, composed["component_ids"] as Array)
	DataDB.register_runtime_level(level)
	composed["level"] = level
	return composed
