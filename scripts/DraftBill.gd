class_name DraftBill
extends RefCounted
## Draft a Bill (patron step 7, 2026-10-19): the player assembles their own bill
## from components of any organizations. It runs on the sponsored-bill machinery
## (a runtime patron row with no patron), so the level, the vote, the visit and
## the trade all work as they do for a request. Reads DataDB, so it lives beside
## PatronLevel; the numbers are Balance levers.

const PREFIX := "PD"
const MIN_PARTS := 2
const MAX_PARTS := 3


static func kind_for(count: int) -> String:
	return PatronRequests.FLAGSHIP if count >= MAX_PARTS else PatronRequests.FAVOR


## Two parts play like a Favor, three like a Flagship (their template and the
## default vote floor follow the kind).
static func template_for(kind: String) -> String:
	return "BT04" if kind == PatronRequests.FLAGSHIP else "BT03"


static func id_for(number: int) -> String:
	return "%s%02d" % [PREFIX, number]


## The runtime patron-bill row: no organization, no ally, flagged as a draft.
static func row_for(draft_id: String, ids: Array) -> Dictionary:
	var kind := kind_for(ids.size())
	return {"patron_bill_id": draft_id, "organization": "", "kind": kind, "ally": "",
		"components": ids.duplicate(), "template_id": template_for(kind), "draft": true}


## The bill these parts would make (same composition as a request).
static func bill_for(ids: Array, draft_id: String = "PDTEMP") -> Dictionary:
	var kind := kind_for(ids.size())
	var bill := ComposedBill.compose(ids, ComposedBill.index(DataDB.bill_components),
			PatronLevel.context(kind, draft_id))
	bill["patron_bill_id"] = draft_id
	bill["patron_kind"] = kind
	bill["stakeholders_override"] = PatronLevel._stakeholders(bill["effects"] as Array)
	return bill


## Why `ids` cannot be drafted right now, as player-facing text; "" when it can.
## `state` carries enacted (component ids already law), xp, funds, time_units,
## last_draft_at (-1 for never) and in_level.
static func refusal(ids: Array, state: Dictionary) -> String:
	var by_id := ComposedBill.index(DataDB.bill_components)
	if bool(state.get("in_level", false)):
		return Text.say("draft.busy")
	if ids.size() < MIN_PARTS:
		return Text.say("draft.too_few")
	if ids.size() > MAX_PARTS:
		return Text.say("draft.too_many")
	for id: Variant in ids:
		if not by_id.has(str(id)):
			return Text.say("draft.too_few")
		if (state.get("enacted", []) as Array).has(id):
			return Text.say("draft.repeat", {"part": str((by_id[str(id)] as Dictionary).get("short_label", id))})
	if ComposedBill.has_conflict(ids, by_id):
		return Text.say("draft.conflict")
	var last := int(state.get("last_draft_at", -1))
	var cooldown := int(DataDB.balance.get("draft_bill_cooldown_units", 30))
	if last >= 0 and int(state.get("time_units", 0)) - last < cooldown:
		return Text.say("draft.cooldown")
	var xp_cost := int(DataDB.balance.get("draft_bill_xp_cost", 350))
	var funds_cost := int(DataDB.balance.get("draft_bill_funds_cost", 300000))
	if int(state.get("xp", 0)) < xp_cost or int(state.get("funds", 0)) < funds_cost:
		return Text.say("draft.cost", {"xp": xp_cost, "funds": Phrase.with_separators(funds_cost)})
	if not PatronLevel.carryable(bill_for(ids)):
		return Text.say("draft.not_winnable")
	return ""
