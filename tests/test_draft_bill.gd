extends GutTest
## Draft a Bill (patron step 7, 2026-10-19): the player assembles a bill from
## components of any organizations; it plays on the sponsored-bill machinery.

var _saved: Dictionary = {}
var _winnable: Array = []


func before_each() -> void:
	_saved = GameState.to_save()
	GameState.start_new_run("PC01")
	GameState.xp = 1000
	GameState.meta["Funds"] = 400000
	GameState.funds_cap_bonus = 900000


func after_each() -> void:
	DataDB.clear_runtime()
	GameState.load_save(_saved)
	DataDB.clear_runtime()


## Some two-part bills from different organizations that the rules accept.
func _pairs(limit: int) -> Array:
	var out: Array = []
	var owners := {}
	for component: Dictionary in DataDB.bill_components:
		var owner := str(component["owner"])
		if not owners.has(owner):
			owners[owner] = []
		(owners[owner] as Array).append(str(component["component_id"]))
	var ids: Array = owners.keys()
	for i in ids.size():
		var j := (i + 5) % ids.size()
		var pair := [(owners[ids[i]] as Array)[0], (owners[ids[j]] as Array)[1]]
		if GameState.draft_refusal(pair).is_empty():
			out.append(pair)
		if out.size() >= limit:
			break
	return out


func test_a_mixed_bill_can_be_drafted_and_plays_like_a_sponsored_one() -> void:
	var pairs := _pairs(1)
	assert_gt(pairs.size(), 0, "some mixed-organization pair is winnable")
	var xp_before := GameState.xp
	var funds_before := int(GameState.meta["Funds"])
	assert_true(GameState.start_draft(pairs[0]))
	assert_eq(GameState.xp, xp_before - 350)
	assert_eq(int(GameState.meta["Funds"]), funds_before - 300000)
	assert_true(GameState.is_in_level())
	assert_eq(GameState.patron_requests["PD01"]["status"], PatronRequests.ACCEPTED)
	var stages := GameState.level_runner.stages
	assert_eq(str((stages[stages.size() - 1] as Dictionary)["mode"]), "Vote")
	assert_eq(GameState.level_runner.problems().size(), 0)
	assert_eq(GameState.last_draft_at, GameState.time_units)


func test_the_refusals_say_why() -> void:
	var pair: Array = _pairs(1)[0]
	assert_ne(GameState.draft_refusal([pair[0]]), "", "one part is too few")
	GameState.xp = 10
	assert_string_contains(GameState.draft_refusal(pair), "350")
	GameState.xp = 1000
	GameState.enacted_components.append(pair[0])
	assert_string_contains(GameState.draft_refusal(pair), "already law")
	GameState.enacted_components.erase(pair[0])
	assert_eq(GameState.draft_refusal(pair), "")
	GameState.last_draft_at = GameState.time_units
	assert_ne(GameState.draft_refusal(pair), "", "the cooldown blocks a second draft")
	GameState.time_units += int(DataDB.balance.get("draft_bill_cooldown_units", 30))
	assert_eq(GameState.draft_refusal(pair), "")


func test_a_failed_draft_costs_nothing() -> void:
	var xp_before := GameState.xp
	assert_false(GameState.start_draft(["CB051"]))
	assert_eq(GameState.xp, xp_before)
	assert_true(GameState.patron_drafts.is_empty())


func test_every_accepted_pair_builds_a_valid_level_and_cannot_pass_alone() -> void:
	var tried := 0
	for pair: Array in _pairs(40):
		tried += 1
		var bill := DraftBill.bill_for(pair)
		assert_true(PatronLevel.carryable(bill), "%s is carryable and fails alone" % [pair])
		GameState.patron_drafts["PDX"] = DraftBill.row_for("PDX", pair)
		var level := PatronLevel.level_row(GameState.patron_drafts["PDX"], DraftBill.bill_for(pair, "PDX"))
		assert_false(level.is_empty(), "%s makes a level" % [pair])
		GameState.patron_drafts.erase("PDX")
	assert_gt(tried, 5)


func test_voting_a_drafted_bill_applies_its_effects_and_needs_no_patron() -> void:
	var pair: Array = _pairs(1)[0]
	assert_true(GameState.start_draft(pair))
	var level_id := str(GameState.patron_runtime["level"]["level_id"])
	while GameState.level_runner.current_stage().get("mode", "") != "Vote":
		GameState.finish_stage(LevelRunner.WON)
	var engine := FloorVoteEngine.new()
	assert_true(engine.setup({"bill": DataDB.get_floor_vote(level_id), "player_party": str(DataDB.player.get("party", "")),
		"meta": {"Reputation": 100}, "triggers": [{"variable": "Reputation", "enabled": "Yes", "threshold": 1}],
		"resistance_by_party": {}, "default_resistance": 0}))
	var result := engine.choose("Yes")
	GameState.record_floor_vote(engine.bill(), result, "Yes")
	assert_eq(GameState.patron_requests["PD01"]["status"],
		PatronRequests.PASSED if result["passed"] else PatronRequests.FAILED)
	if bool(result["passed"]):
		assert_true(GameState.enacted_components.has(pair[0]))


func test_abandoning_a_draft_cannot_be_offered_again() -> void:
	var pair: Array = _pairs(1)[0]
	assert_true(GameState.start_draft(pair))
	GameState.abandon_level()
	assert_eq(GameState.patron_requests["PD01"]["status"], PatronRequests.LAPSED)


func test_drafts_survive_a_save_and_the_new_run_forgets_them() -> void:
	var pair: Array = _pairs(1)[0]
	assert_true(GameState.start_draft(pair))
	var saved := GameState.to_save()
	assert_true((saved["patron_drafts"] as Dictionary).has("PD01"))
	GameState.start_new_run("PC01")
	assert_true(GameState.patron_drafts.is_empty())
	assert_eq(GameState.draft_counter, 0)
	assert_eq(GameState.last_draft_at, -1)
