extends GutTest
## Party Activists (BO31) and the Candidate Selection Committee (BO32),
## 2026-10-18: standing links, rivalries, per-body lean multipliers, list
## stage targets and the flip backing.

var _links_before: Array = []


func before_each() -> void:
	_links_before = DataDB.standing_links
	GameState.start_new_run("PC02")
	for id: String in GameState.booster_standing:
		GameState.booster_standing[id] = 50
	GameState.last_booster_change = {}
	GameState.last_booster_cause = {}
	GameState._link_carry = {}


func after_each() -> void:
	DataDB.standing_links = _links_before


func test_the_two_bodies_exist_with_the_agreed_numbers() -> void:
	var activists := DataDB.get_booster("BO31")
	var committee := DataDB.get_booster("BO32")
	assert_eq(activists["tier"], "Party")
	assert_eq(committee["tier"], "Party")
	assert_eq(int(activists["starting_standing"]), 5)
	assert_eq(int(committee["starting_standing"]), 15)
	assert_eq(float(activists["party_lean_multiplier"]), 2.0)
	assert_eq(float(committee["party_lean_multiplier"]), 0.5)
	assert_eq(float(DataDB.get_booster("BO02")["party_lean_multiplier"]), 1.5)


func test_settle_carries_fractions() -> void:
	var first := StandingLinks.settle(0.6, 0.0)
	assert_eq(first["whole"], 0)
	var second := StandingLinks.settle(0.6, first["carry"])
	assert_eq(second["whole"], 1)
	assert_almost_eq(float(second["carry"]), 0.2, 0.001)
	assert_eq(StandingLinks.settle(-1.5, 0.0)["whole"], -1)


func test_funds_counts_by_yen_per_point_and_others_by_range() -> void:
	assert_eq(StandingLinks.points_for_meta("Funds", 20000, {}, 10000), 2.0)
	assert_eq(StandingLinks.points_for_meta("Reputation", 10, {"min": 0, "max": 100}, 10000), 10.0)


func test_the_committee_follows_reputation_voters_and_headquarters() -> void:
	DataDB.standing_links = [
		{"source": "Reputation", "target": "BO32", "weight": 0.25},
		{"source": "BO18", "target": "BO32", "weight": 0.25},
	]
	GameState.booster_standing["BO32"] = 15
	GameState._cause = "test"
	GameState._record_meta_change({"Reputation": 8})   # 2.0 points
	assert_eq(int(GameState.booster_standing["BO32"]), 17)
	GameState._apply_booster_delta("BO18", 4)           # 1.0 point
	assert_eq(int(GameState.booster_standing["BO32"]), 18)
	GameState._cause = ""


func test_a_followed_change_does_not_start_another_link() -> void:
	DataDB.standing_links = [
		{"source": "BO01", "target": "BO32", "weight": 1.0},
		{"source": "BO32", "target": "BO31", "weight": 1.0},
	]
	GameState._apply_booster_delta("BO01", 4)
	assert_eq(int(GameState.booster_standing["BO32"]), 54)
	assert_eq(int(GameState.booster_standing["BO31"]), 50, "one hop only")


func test_a_rivalry_moves_the_rival_the_other_way_and_says_why() -> void:
	DataDB.standing_links = [{"source": "BO01", "target": "BO02", "weight": -0.5}]
	GameState._apply_booster_delta("BO01", 6)
	assert_eq(int(GameState.booster_standing["BO02"]), 47)
	var cause: String = GameState.last_booster_cause["BO02"][0]["cause"]
	assert_string_contains(cause, "rivalry")
	assert_string_contains(cause, "Party Headquarters")


func test_neglect_decay_does_not_trigger_links() -> void:
	DataDB.standing_links = [{"source": "BO03", "target": "BO32", "weight": 1.0}]
	GameState.booster_standing["BO03"] = 60
	GameState.booster_standing["BO32"] = 15
	GameState.last_booster_change = {}
	GameState._apply_neglect_decay()
	assert_lt(int(GameState.booster_standing["BO03"]), 60, "it did decay")
	assert_eq(int(GameState.booster_standing["BO32"]), 15, "decay of BO03 did not follow into BO32")


func test_a_stage_backing_can_name_several_rooms() -> void:
	var modifier := DataDB.get_modifier("M47")
	assert_true(ModifierEffects.targets_of(modifier).has("ST05"))
	assert_true(ModifierEffects.targets_of(modifier).has("ST03"))
	assert_eq(ModifierEffects.battle_start_bonus([modifier], "ST03")["start_support"], 5)
	assert_eq(ModifierEffects.battle_start_bonus([modifier], "ST05")["start_support"], 5)
	assert_eq(ModifierEffects.battle_start_bonus([modifier], "ST02")["start_support"], 0)
	for stage: Dictionary in DataDB.stages:
		var name := str(stage.get("name_en", ""))
		if name.contains("Town Hall") or name.contains("Caucus"):
			assert_true(ModifierEffects.targets_of(modifier).has(str(stage["stage_id"])),
				"%s is covered" % stage["stage_id"])


func test_the_flip_backing_pays_only_for_a_party_backed_bill_turned_to_pass() -> void:
	GameState.owned_modifiers = ["M48"]
	GameState.booster_standing["BO32"] = 50
	var own := GameState.own_party_id()
	var backed := {"bill_name": "X", "positions": [{"party_id": own, "disposition": "Supportive"}]}
	var opposed := {"bill_name": "X", "positions": [{"party_id": own, "disposition": "Opposed"}]}
	var turned := {"outcome_flipped_by_influence": true, "passed": true}
	GameState.meta["Party support"] = 40
	assert_eq(GameState.apply_flip_backing(backed, turned), 5)
	assert_eq(int(GameState.meta["Party support"]), 45)
	assert_eq(GameState.apply_flip_backing(opposed, turned), 0, "not a bill the party backs")
	assert_eq(GameState.apply_flip_backing(backed, {"outcome_flipped_by_influence": true, "passed": false}), 0, "flipped to fail")
	assert_eq(GameState.apply_flip_backing(backed, {"outcome_flipped_by_influence": false, "passed": true}), 0, "no flip")
	GameState.booster_standing["BO32"] = 5
	assert_eq(GameState.apply_flip_backing(backed, turned), 0, "the committee no longer holds")
	GameState.owned_modifiers = []
	GameState.booster_standing["BO32"] = 50
	assert_eq(GameState.apply_flip_backing(backed, turned), 0, "not owned")


func test_the_taste_phrases_are_in_player_language() -> void:
	assert_eq(Text.say("battle.taste_likes", {"styles": "divisive"}), "Likes divisive rhetoric.")
	assert_eq(Text.say("battle.taste_dislikes", {"styles": "data driven and earnest"}),
		"Dislikes data driven and earnest rhetoric.")
