extends GutTest
## BillPositions, ComposedBill, PatronRequests and LevelTemplate (Patron Bills
## step 2, 2026-10-19). The numbers in the first tests were produced by the
## Python model the Batch 2 bills used (tools/workbook/archive/b2/model.py),
## so the port is checked against the original, not against itself.

func _ctx(extra: Dictionary = {}) -> Dictionary:
	var ctx := {
		"parties": DataDB.parties,
		"salience": BillPositions.salience_table(DataDB.party_values),
		"threshold": float(DataDB.balance.get("bill_position_lean_threshold", 30)),
		"yes_cap": 51 - int(DataDB.balance.get("patron_default_margin", 6)),
		"template_2": "A bill to {a} and {b}",
		"template_3": "A bill to {a}, {b} and {c}",
		"bill_id": "PB_TEST",
		"law_scale_percent": int(DataDB.balance.get("custom_law_scale_percent", 50)),
	}
	for key: String in extra:
		ctx[key] = extra[key]
	return ctx


func _components() -> Dictionary:
	return ComposedBill.index(DataDB.bill_components)


func _totals(positions: Array) -> Array:
	var t := [0, 0, 0]
	for p: Dictionary in positions:
		t[0] += int(p["votes_yes"])
		t[1] += int(p["votes_no"])
		t[2] += int(p["votes_abstain"])
	return t


func test_tags_parse_and_merge() -> void:
	var tags := BillPositions.parse_tags("Taxation -1; Economic Liberalization +0.7")
	assert_eq(tags["Taxation"], -1.0)
	assert_almost_eq(float(tags["Economic Liberalization"]), 0.7, 0.0001)
	var merged := BillPositions.merge_tags([{"A": 1.0}, {"A": 0.5, "B": -1.0}])
	assert_eq(merged["A"], 1.5)
	assert_eq(merged["B"], -1.0)
	assert_true(BillPositions.parse_tags(null).is_empty())


func test_positions_match_the_python_model() -> void:
	var by_id := _components()
	# The Python reference was run with the original margin of 6 (cap 45).
	var bill := ComposedBill.compose(["CB051", "CB052"], by_id, _ctx({"yes_cap": 45}))
	assert_eq(_totals(bill["positions"]), [45, 30, 26])
	var second := ComposedBill.compose(["CB071", "CB073", "CB101"], by_id, _ctx({"yes_cap": 45}))
	assert_eq(_totals(second["positions"]), [45, 39, 17])


func test_without_a_cap_the_lean_model_alone_is_not_held_down() -> void:
	var by_id := _components()
	var bill := ComposedBill.compose(["CB051", "CB052"], by_id, _ctx({"yes_cap": -1}))
	assert_gt(BillPositions.total_yes(bill["positions"]), 45)


func test_every_party_keeps_its_seats() -> void:
	var by_id := _components()
	var bill := ComposedBill.compose(["CB051", "CB052"], by_id, _ctx())
	for position: Dictionary in bill["positions"]:
		var party := DataDB.get_party_by_id(str(position["party_id"]))
		assert_eq(int(position["votes_yes"]) + int(position["votes_no"]) + int(position["votes_abstain"]),
				int(party["seats"]))


func test_bill_names() -> void:
	var by_id := _components()
	var two := ComposedBill.compose(["CB051", "CB052"], by_id, _ctx())
	assert_eq(two["bill_name"], "A bill to cut the corporate tax rate and %s" % by_id["CB052"]["phrase"])
	var three := ComposedBill.compose(["CB071", "CB073", "CB101"], by_id, _ctx())
	assert_true(str(three["bill_name"]).begins_with("A bill to "))
	assert_eq(str(three["bill_name"]).count(","), 1)


func test_repeats_are_swapped_for_the_owners_next_component() -> void:
	var by_id := _components()
	var swapped := ComposedBill.substitute_enacted(["CB051", "CB052"], by_id, ["CB051"])
	assert_true(swapped["ok"])
	assert_eq(swapped["ids"], ["CB053", "CB052"])
	var nothing_left := ComposedBill.substitute_enacted(["CB051", "CB052"], by_id, ["CB051", "CB052", "CB053"])
	assert_false(nothing_left["ok"])


func test_merged_effects_are_scaled_and_never_round_to_nothing() -> void:
	var by_id := {"A": {"component_id": "A", "gains": [{"target": "BO05", "delta": 3}], "loses": [{"target": "BO09", "delta": -1}]}}
	var scaled := ComposedBill.merged_effects(["A"], by_id, 50)
	assert_eq(scaled, [{"target": "BO05", "delta": 2}, {"target": "BO09", "delta": -1}])


func test_template_resolves_real_rooms() -> void:
	var favor := DataDB.bill_level_templates[0] as Dictionary
	assert_eq(LevelTemplate.stages(favor, "ST16", "National"), ["ST20", "ST16", "ST23"])
	var broken := {"stage_1": "NOT_A_TOKEN"}
	assert_eq(LevelTemplate.stages(broken, "ST16", "National"), [])
	var flagship := {"stage_1": "PATRON_MEETING", "stage_2": "HEARING", "stage_3": "PUBLIC", "stage_4": "CAUCUS", "stage_5": "VOTE"}
	assert_eq(LevelTemplate.stages(flagship, "ST13", "Constituency"), ["ST20", "ST13", "ST05", "ST03", "ST23"])
	assert_eq(LevelTemplate.stages(flagship, "ST13", "National")[2], "ST04")


func test_requests_come_due_at_the_threshold_and_flagships_wait_for_the_favor() -> void:
	var bills := [
		{"patron_bill_id": "PB051", "organization": "BO05", "kind": "Favor", "threshold": null},
		{"patron_bill_id": "PB052", "organization": "BO05", "kind": "Flagship", "threshold": null},
	]
	var balance := DataDB.balance
	assert_eq(PatronRequests.due(bills, {"BO05": 49}, {}, balance), [])
	assert_eq(PatronRequests.due(bills, {"BO05": 50}, {}, balance), ["PB051"])
	# 80 standing but the Favor is still open: no Flagship yet.
	assert_eq(PatronRequests.due(bills, {"BO05": 80}, {"PB051": "open"}, balance), [])
	assert_eq(PatronRequests.due(bills, {"BO05": 80}, {"PB051": "passed"}, balance), ["PB052"])
	assert_eq(PatronRequests.due(bills, {"BO05": 69}, {"PB051": "passed"}, balance), [])
	# A failed Favor lowers the Flagship threshold by 5.
	assert_eq(PatronRequests.due(bills, {"BO05": 65}, {"PB051": "failed"}, balance), ["PB052"])


func test_how_many_requests_may_be_shown() -> void:
	var balance := {"patron_requests_waiting_at_once": 2}
	assert_eq(PatronRequests.room_to_open({}, balance), 2)
	assert_eq(PatronRequests.room_to_open({"A": "open", "B": "accepted", "C": "waiting"}, balance), 0)
	assert_eq(PatronRequests.room_to_open({"A": "passed", "B": "open"}, balance), 1)


func test_decline_costs() -> void:
	var balance := DataDB.balance
	assert_eq(PatronRequests.decline_deltas({"organization": "BO05", "kind": "Favor"}, balance),
			[{"target": "BO05", "delta": -5}])
	assert_eq(PatronRequests.decline_deltas({"organization": "BO05", "kind": "Flagship"}, balance),
			[{"target": "BO05", "delta": -10}])


func test_amend_swaps_one_favor_component_or_the_flagship_allys() -> void:
	var by_id := _components()
	var favor := {"kind": "Favor", "components": ["CB051", "CB052"]}
	var options := PatronRequests.amend_options(favor, by_id, [])
	assert_eq(options.size(), 2)
	assert_eq(options[0]["with"], "CB053")
	var flagship := {"kind": "Flagship", "components": ["CB051", "CB053", "CB241"]}
	var ally_options := PatronRequests.amend_options(flagship, by_id, [])
	for option: Dictionary in ally_options:
		assert_eq(option["replace"], "CB241")
		assert_true(str(option["with"]).begins_with("CB24"))
	assert_eq(PatronRequests.apply_amend(["A", "B"], "B", "C"), ["A", "C"])


func test_outcomes() -> void:
	var balance := DataDB.balance
	var flagship := {"organization": "BO05", "kind": "Flagship"}
	var win := PatronRequests.outcome(flagship, "BO24", ["BO09"], true, false, balance)
	assert_eq(win["standing"], [{"target": "BO05", "delta": 10}, {"target": "BO24", "delta": 4}, {"target": "BO09", "delta": -3}])
	assert_eq(win["free_backing_units"], 30)
	var amended := PatronRequests.outcome({"organization": "BO05", "kind": "Favor"}, "", [], true, true, balance)
	assert_eq(amended["standing"], [{"target": "BO05", "delta": 5}])
	var lost := PatronRequests.outcome({"organization": "BO05", "kind": "Favor"}, "", ["BO09"], false, false, balance)
	assert_eq(lost["standing"], [{"target": "BO05", "delta": -2}, {"target": "BO09", "delta": 1}])
	assert_true(lost["remember_failed_favor"])
	assert_eq(PatronRequests.rivals_of([{"target": "BO05", "delta": 3}, {"target": "BO09", "delta": -2}], "BO05", ""), ["BO09"])


## Cameron's rule: no patron bill passes without the player's influence, and a
## full-strength player must still be able to carry every one of them. Uses the
## real vote engine, the real parties and their own vote resistance.
func test_no_patron_bill_passes_alone_but_every_one_can_be_carried() -> void:
	var by_id := _components()
	var resistance := {}
	for party: Dictionary in DataDB.parties:
		if party.get("vote_resistance") != null:
			resistance[str(party["name"])] = int(party["vote_resistance"])
	assert_gt(DataDB.patron_bills.size(), 0)
	for patron_bill: Dictionary in DataDB.patron_bills:
		var ids: Array = patron_bill["components"]
		ids = ComposedBill.substitute_enacted(ids, by_id, [])["ids"]
		var bill := ComposedBill.compose(ids, by_id, _ctx({"bill_id": str(patron_bill["patron_bill_id"])}))
		for player in DataDB.protagonists:
			var party_name := str(player.get("party", ""))
			var config := {
				"bill": bill.duplicate(true), "player_party": party_name,
				"meta": {"Reputation": 100},
				"triggers": [{"variable": "Reputation", "enabled": "Yes", "threshold": 1}],
				"resistance_by_party": resistance,
				"default_resistance": int(DataDB.balance.get("vote_swing_resistance_default", 70)),
			}
			var quiet := FloorVoteEngine.new()
			assert_true(quiet.setup({"bill": bill.duplicate(true), "player_party": party_name}))
			var alone := quiet.choose("Yes")
			assert_false(alone["passed"], "%s passes alone for %s" % [patron_bill["patron_bill_id"], party_name])
			var carried := FloorVoteEngine.new()
			assert_true(carried.setup(config))
			var result := carried.choose("Yes")
			assert_true(result["passed"], "%s cannot be carried by %s: %s" % [patron_bill["patron_bill_id"], party_name, str(result["totals"])])
