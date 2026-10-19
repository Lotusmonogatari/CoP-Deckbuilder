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
	# A bill the player drafted themselves (Draft a Bill).
	return GameState.patron_drafts.get(patron_bill_id, {})


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
		# The raw rows, braces and all: ComposedBill fills {a}, {b} and {c}.
		"template_1": str(DataDB.strings.get("custom_bill.name_1", "A bill to {a}")),
		"template_2": str(DataDB.strings.get("custom_bill.name_2", "A bill to {a} and {b}")),
		"template_3": str(DataDB.strings.get("custom_bill.name_3", "A bill to {a}, {b} and {c}")),
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
	return {"ok": bool(swapped["ok"]), "bill": compose_ids(patron_bill_id, ids), "component_ids": ids, "amended": amended}


## The bill for an explicit list of components (no Option A swaps, no Amend):
## what a lobbyist trade recomposes after a component is dropped.
static func compose_ids(patron_bill_id: String, ids: Array) -> Dictionary:
	var row := patron_bill(patron_bill_id)
	var kind := str(row.get("kind", PatronRequests.FAVOR))
	var bill := ComposedBill.compose(ids, ComposedBill.index(DataDB.bill_components), context(kind, patron_bill_id))
	bill["patron_bill_id"] = patron_bill_id
	bill["patron_kind"] = kind
	bill["stakeholders_override"] = _stakeholders(bill["effects"] as Array)
	return bill


static func _template_has(template: Dictionary, token: String) -> bool:
	for slot in range(1, LevelTemplate.MAX_SLOTS + 1):
		if str(template.get("stage_%d" % slot, "")).strip_edges() == token:
			return true
	return false


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
static func level_row(row: Dictionary, bill: Dictionary, rng: RandomNumberGenerator = null) -> Dictionary:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var template: Dictionary = {}
	for candidate: Dictionary in DataDB.bill_level_templates:
		if str(candidate.get("template_id", "")) == str(row.get("template_id", "")):
			template = candidate
	var owner_org := str(row.get("organization", ""))
	if owner_org.is_empty():
		# A drafted bill has no patron: its first part's organization sets the public room.
		var first_ids: Array = bill.get("component_ids", []) as Array
		if not first_ids.is_empty():
			owner_org = str(ComposedBill.index(DataDB.bill_components).get(str(first_ids[0]), {}).get("owner", ""))
	var owner_tier := str(DataDB.get_booster(owner_org).get("tier", ""))
	var visit := build_visit(template, bill, rng)
	var trade := build_trade(template, row, bill, rng)
	var stages := LevelTemplate.stages(template, str(bill.get("hearing_stage", "")), owner_tier,
			not visit.is_empty(), not trade.is_empty())
	if stages.is_empty():
		return {}
	stages[stages.size() - 1] = str(bill.get("bill_id", ""))
	var level := {
		"level_id": level_id_for(str(row.get("patron_bill_id", ""))),
		"description": str(bill.get("bill_name", "")),
		"tier": template.get("level_tier"),
		"patron_bill_id": str(row.get("patron_bill_id", "")),
	}
	if not visit.is_empty():
		level["visit"] = visit
	# The opening visitor from the sponsoring organization, when the template
	# opens with one (PATRON_VISIT).
	if _template_has(template, "PATRON_VISIT"):
		var patron_visit := PatronVisit.build(str(row.get("organization", "")), bill.get("component_ids", []) as Array)
		if not patron_visit.is_empty():
			level["patron_visit"] = patron_visit
	if not trade.is_empty():
		level["trade"] = trade
	for index in range(stages.size()):
		level["stage_%d" % (index + 1)] = stages[index]
	return level


## The member visit for a level built from `template`, or {} when the template
## has none or no listed party has a seat outside the player's side. The party
## is the first in the template's Visit Parties with seats outside Yes (the
## sponsor votes Yes); the member and the questions are drawn now and kept
## with the level so a saved level resumes with the same visit.
static func build_visit(template: Dictionary, bill: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var has_token := false
	for slot in range(1, LevelTemplate.MAX_SLOTS + 1):
		if str(template.get("stage_%d" % slot, "")) == "MP_VISIT":
			has_token = true
	if not has_token:
		return {}
	var parties: Array = template.get("visit_parties", []) as Array if template.get("visit_parties") is Array else []
	var party_id := MpVisit.pick_party(parties, bill.get("positions", []) as Array)
	if party_id.is_empty():
		return {}
	var party := DataDB.get_party_by_id(party_id)
	var committee := str(DataDB.get_stage(str(bill.get("hearing_stage", ""))).get("name_en", ""))
	var opponents: Array = []
	for opponent: Dictionary in DataDB.opponents:
		opponents.append(opponent)
	var member := MpVisit.pick_member(opponents, str(party.get("name", "")), committee, GameState.faced_people, rng)
	if member.is_empty():
		return {}
	var phrase := ""
	var first_ids: Array = bill.get("component_ids", []) as Array
	if not first_ids.is_empty():
		phrase = str(ComposedBill.index(DataDB.bill_components).get(str(first_ids[0]), {}).get("phrase", ""))
	var questions := MpVisit.build_questions(member, DataDB.visit_questions, DataDB.visit_answers,
			int(DataDB.balance.get("mp_visit_questions", 3)), phrase, rng)
	if questions.is_empty():
		return {}
	return {
		"party_id": party_id, "party_name": str(party.get("name", "")),
		"opp_id": str(member.get("opp_id", "")), "member_name": str(member.get("name", "")),
		"questions": questions, "rapport": 0, "taken": false, "won": false,
	}


## True when a full-strength player (every influence gate open) could still
## carry `bill`, and the bill does not pass without influence. Used to offer
## only trades that leave the bill winnable.
static func carryable(bill: Dictionary) -> bool:
	var resistance := {}
	for party: Dictionary in DataDB.parties:
		if party.get("vote_resistance") != null:
			resistance[str(party.get("name", ""))] = int(party["vote_resistance"])
	var player_party := str(DataDB.player.get("party", ""))
	if player_party.is_empty():
		player_party = str((DataDB.parties[0] as Dictionary).get("name", ""))
	var alone := FloorVoteEngine.new()
	if not alone.setup({"bill": bill.duplicate(true), "player_party": player_party}):
		return false
	if bool(alone.choose("Yes").get("passed", false)):
		return false
	var carried := FloorVoteEngine.new()
	carried.setup({
		"bill": bill.duplicate(true), "player_party": player_party, "meta": {"Reputation": 100},
		"triggers": [{"variable": "Reputation", "enabled": "Yes", "threshold": 1}],
		"resistance_by_party": resistance,
		"default_resistance": int(DataDB.balance.get("vote_swing_resistance_default", 70)),
	})
	return bool(carried.choose("Yes").get("passed", false))


## The components the player may trade away: each one whose removal leaves a
## bill that is still carryable.
static func safe_drops(patron_bill_id: String, ids: Array) -> Array:
	var out: Array = []
	for dropped: Variant in LobbyistTrade.drop_options(ids):
		var rest := ids.duplicate()
		rest.erase(dropped)
		if carryable(compose_ids(patron_bill_id, rest)):
			out.append(dropped)
	return out


## The lobbyist's trade for a level built from `template`, or {} when the
## template has none or no organization the bill hurts has a representative.
## The lobbyist, the component they most want gone and the negotiation
## questions are drawn now and kept with the level (the dropped component's
## words are filled in when the player chooses it).
static func build_trade(template: Dictionary, row: Dictionary, bill: Dictionary,
		rng: RandomNumberGenerator) -> Dictionary:
	var has_token := false
	for slot in range(1, LevelTemplate.MAX_SLOTS + 1):
		if str(template.get("stage_%d" % slot, "")) == "LOBBYIST_TRADE":
			has_token = true
	var drops := safe_drops(str(row.get("patron_bill_id", "")), bill.get("component_ids", []) as Array) if has_token else []
	if drops.is_empty():
		return {}
	var lobbyists: Array = []
	for opponent: Dictionary in DataDB.opponents:
		var party: Variant = opponent.get("party")
		var role := str(opponent.get("role", ""))
		if (party == null or str(party).strip_edges().is_empty()) and opponent.get("affiliation") != null \
				and role != "Journalist" and role != "Constituent":
			lobbyists.append(opponent)
	var ally := str(row.get("ally", "")) if row.get("ally") != null else ""
	var picked := LobbyistTrade.pick_lobbyist(bill.get("effects", []) as Array, str(row.get("organization", "")),
			ally, lobbyists, GameState.faced_people, rng)
	if picked.is_empty():
		return {}
	var lobbyist: Dictionary = picked["lobbyist"]
	var asked := LobbyistTrade.asked_component(bill.get("component_ids", []) as Array,
			ComposedBill.index(DataDB.bill_components), str(picked["org"]))
	var questions := MpVisit.build_questions(lobbyist, DataDB.trade_questions, DataDB.visit_answers,
			int(DataDB.balance.get("trade_rounds", 3)), "{component}", rng)
	if questions.is_empty():
		return {}
	return {
		"org": str(picked["org"]), "opp_id": str(lobbyist.get("opp_id", "")),
		"lobbyist_name": str(lobbyist.get("name", "")), "asked": asked, "drops": drops,
		"questions": questions, "done": false, "deal": false,
	}


## Starting support the one-on-one fight gives the player from the visit's
## rapport (0 when no visit is in progress).
static func visit_start_bonus() -> int:
	var level: Variant = GameState.patron_runtime.get("level")
	if not (level is Dictionary):
		return 0
	var visit: Dictionary = (level as Dictionary).get("visit", {})
	return MpVisit.start_bonus(int(visit.get("rapport", 0)), int(DataDB.balance.get("mp_visit_rapport_start_per_point", 5)))


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
