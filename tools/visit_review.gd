extends Node
## Prints ten real custom-bill levels that carry a member visit and a lobbyist
## trade, with everything the player would see in them, so the content can be
## judged against the bill's theme (2026-11-03).
##     godot --headless --path . tools/visit_review.tscn

func _ready() -> void:
	_run.call_deferred()


func _org(id: String) -> String:
	return str(DataDB.get_booster(id).get("name_en", id))


func _phrase_of(id: String) -> String:
	return str((ComposedBill.index(DataDB.bill_components).get(id, {}) as Dictionary).get("phrase", id))


func _stats() -> void:
	var by_id := ComposedBill.index(DataDB.bill_components)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var ids: Array = []
	for component: Dictionary in DataDB.bill_components:
		ids.append(str(component["component_id"]))
	var levels := 0
	var members := {}
	var members_by_committee := {}
	var parties := {}
	var lobbyists := {}
	var orgs := {}
	var asked_not_offered := 0
	var trades := 0
	var visits := 0
	var guard := 0
	while levels < 400 and guard < 4000:
		guard += 1
		var count := 3 if levels % 2 == 0 else 2
		var shuffled := ids.duplicate()
		for i in range(shuffled.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var held: Variant = shuffled[i]
			shuffled[i] = shuffled[j]
			shuffled[j] = held
		var pick: Array = shuffled.slice(0, count)
		if ComposedBill.has_conflict(pick, by_id):
			continue
		levels += 1
		var level := PatronLevel.level_row(DraftBill.row_for("PDREV", pick), DraftBill.bill_for(pick, "PDREV"), rng)
		if level.has("visit"):
			visits += 1
			var v: Dictionary = level["visit"]
			var committee := str(DataDB.get_stage(str(DraftBill.bill_for(pick, "PDREV")["hearing_stage"])).get("name_en", ""))
			members[v["member_name"]] = int(members.get(v["member_name"], 0)) + 1
			parties[v["party_name"]] = int(parties.get(v["party_name"], 0)) + 1
			var per: Dictionary = members_by_committee.get(committee, {})
			per[v["member_name"]] = int(per.get(v["member_name"], 0)) + 1
			members_by_committee[committee] = per
		if level.has("trade"):
			trades += 1
			var t: Dictionary = level["trade"]
			lobbyists[t["lobbyist_name"]] = int(lobbyists.get(t["lobbyist_name"], 0)) + 1
			orgs[t["org"]] = int(orgs.get(t["org"], 0)) + 1
			if not (t["drops"] as Array).has(t["asked"]):
				asked_not_offered += 1
	print("STATS levels %d, with member visit %d, with trade %d" % [levels, visits, trades])
	print("STATS visited parties: %s" % [parties])
	print("STATS distinct members visited: %d; most common: %s" % [members.size(), _top(members, 6)])
	for committee: String in members_by_committee:
		print("STATS committee %s -> members %s" % [committee, members_by_committee[committee]])
	print("STATS distinct lobbyists: %d; most common: %s" % [lobbyists.size(), _top(lobbyists, 6)])
	print("STATS lobbyist organizations: %s" % [orgs])
	print("STATS trades where the part the lobbyist asks for is NOT among the parts the player may trade: %d of %d" % [asked_not_offered, trades])


func _top(counts: Dictionary, n: int) -> String:
	var keys := counts.keys()
	keys.sort_custom(func(a: Variant, b: Variant) -> bool: return counts[a] > counts[b])
	return str(keys.slice(0, n).map(func(k: Variant) -> String: return "%s x%d" % [k, counts[k]]))


func _run() -> void:
	if OS.get_environment("VISIT_STATS") == "1":
		_stats()
		get_tree().quit(0)
		return
	var by_id := ComposedBill.index(DataDB.bill_components)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var ids: Array = []
	for component: Dictionary in DataDB.bill_components:
		ids.append(str(component["component_id"]))
	var wanted := ["patron Flagship", "patron Flagship", "patron Flagship", "patron Favor", "patron Favor",
		"draft 3 parts", "draft 3 parts", "draft 3 parts", "draft 2 parts", "draft 2 parts"]
	var patron_rows := {"patron Flagship": [], "patron Favor": []}
	for row: Dictionary in DataDB.patron_bills:
		patron_rows["patron Flagship" if str(row.get("kind")) == "Flagship" else "patron Favor"].append(row)
	var shown := 0
	for kind: String in wanted:
		var level := {}
		var bill := {}
		var row := {}
		var guard := 0
		while guard < 400:
			guard += 1
			if kind.begins_with("patron"):
				var pool: Array = patron_rows[kind]
				row = pool[rng.randi_range(0, pool.size() - 1)]
				bill = PatronLevel.compose(str(row["patron_bill_id"]), [])["bill"]
			else:
				var count := 3 if kind.contains("3") else 2
				var shuffled := ids.duplicate()
				for i in range(shuffled.size() - 1, 0, -1):
					var j := rng.randi_range(0, i)
					var held: Variant = shuffled[i]
					shuffled[i] = shuffled[j]
					shuffled[j] = held
				var pick: Array = shuffled.slice(0, count)
				if ComposedBill.has_conflict(pick, by_id):
					continue
				row = DraftBill.row_for("PDREV", pick)
				bill = DraftBill.bill_for(pick, "PDREV")
			level = PatronLevel.level_row(row, bill, rng)
			if level.has("visit") and level.has("trade"):
				break
			level = {}
		if level.is_empty():
			print("\n## Sample %d (%s): no level with both rooms found" % [shown + 1, kind])
			continue
		shown += 1
		print("\n## Sample %d: %s" % [shown, kind])
		print("**Bill:** %s" % bill["bill_name"])
		var parts: Array[String] = []
		for id: Variant in bill["component_ids"]:
			var c: Dictionary = by_id[str(id)]
			parts.append("%s (%s, %s, hearing %s)" % [c["phrase"], _org(str(c["owner"])), c["slot"], c["hearing_stage"]])
		print("**Parts:** " + "; ".join(parts))
		var helped: Array[String] = []
		var hurt: Array[String] = []
		for effect: Dictionary in bill["effects"]:
			(helped if int(effect["delta"]) > 0 else hurt).append("%s %+d" % [_org(str(effect["target"])), int(effect["delta"])])
		print("**Helps:** %s. **Hurts:** %s" % [", ".join(helped), ", ".join(hurt)])
		var lean: Array[String] = []
		for position: Dictionary in bill["positions"]:
			lean.append("%s %s (Y%d/N%d/A%d)" % [str(position["party_name"]).substr(0, 14), str(position["disposition"]), position["votes_yes"], position["votes_no"], position["votes_abstain"]])
		print("**Parties:** " + "; ".join(lean))
		var committee := str(DataDB.get_stage(str(bill["hearing_stage"])).get("name_en", ""))
		var visit: Dictionary = level["visit"]
		var member := DataDB.get_opponent(str(visit["opp_id"]))
		print("\n**MEMBER VISIT.** %s of %s, role '%s' (hearing committee: %s; same committee: %s). Styles: %s / %s / %s" % [
			visit["member_name"], visit["party_name"], member.get("role", ""), committee,
			"yes" if str(member.get("role", "")) == committee else "no",
			member.get("suit_1", ""), member.get("suit_2", ""), member.get("suit_3", "")])
		var q_no := 0
		for question: Dictionary in visit["questions"]:
			q_no += 1
			print("- Q%d: \"%s\"" % [q_no, question["text"]])
			for choice: Dictionary in question["choices"]:
				print("    - %s [%s, %s]: %s" % [choice["letter"], choice["style"], choice["grade"], choice["text"]])
		var trade: Dictionary = level["trade"]
		var asked_phrase := _phrase_of(str(trade["asked"]))
		var lobbyist := DataDB.get_opponent(str(trade["opp_id"]))
		print("\n**LOBBYIST TRADE.** %s (%s, role '%s') speaks for %s. Asks to drop: \"%s\". Parts offered to trade: %s" % [
			trade["lobbyist_name"], _org(str(lobbyist.get("affiliation", ""))), lobbyist.get("role", ""), _org(str(trade["org"])),
			asked_phrase, ", ".join((trade["drops"] as Array).map(func(x: Variant) -> String: return _phrase_of(str(x))))])
		var org_effect := 0
		for effect: Dictionary in bill["effects"]:
			if str(effect["target"]) == str(trade["org"]):
				org_effect = int(effect["delta"])
		print("The bill's effect on %s: %+d. Does the asked part belong to or hurt them? component owner = %s" % [_org(str(trade["org"])), org_effect, _org(str((by_id[str(trade["asked"])] as Dictionary)["owner"]))])
		q_no = 0
		for question: Dictionary in trade["questions"]:
			q_no += 1
			print("- Q%d: \"%s\"" % [q_no, str(question["text"]).replace("{component}", asked_phrase)])
			for choice: Dictionary in question["choices"]:
				print("    - %s [%s, %s]: %s" % [choice["letter"], choice["style"], choice["grade"], str(choice["text"]).replace("{component}", asked_phrase)])
	get_tree().quit(0)
