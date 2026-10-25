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
	assert_eq(float(activists["party_lean_multiplier"]), 1.5)
	assert_eq(float(committee["party_lean_multiplier"]), 0.375)
	assert_eq(float(DataDB.get_booster("BO02")["party_lean_multiplier"]), 1.125)
	assert_eq(float(DataDB.get_booster("BO01")["party_lean_multiplier"]), 0.75)


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


func test_activists_like_divisive_and_duplicitous_rhetoric_and_the_committee_has_no_taste() -> void:
	var suits: Array = DataDB.suits.map(func(s: Dictionary) -> String: return str(s["element"]))
	var activists := BoosterSuitTendency.taste_of(DataDB.questions, "BO31", suits)
	assert_eq(activists["likes"], ["Divisive", "Duplicitous"])  # Duplicitous added 2026-10-25, Cameron
	var committee := BoosterSuitTendency.taste_of(DataDB.questions, "BO32", suits)
	assert_true((committee["likes"] as Array).is_empty(), "balanced: no liked style")
	assert_true((committee["dislikes"] as Array).is_empty(), "balanced: no disliked style")


func test_each_new_body_has_at_least_fifteen_questions_and_a_backing() -> void:
	for id: String in ["BO31", "BO32"]:
		var count := 0
		for pool: Array in DataDB.questions.values():
			for question: Dictionary in pool:
				if (question.get("pleases_boosters", []) as Array).has(id):
					count += 1
		assert_gte(count, 15, "%s has enough questions" % id)
		assert_false((DataDB.get_booster(id).get("linked_modifiers", []) as Array).is_empty())


func test_the_activist_backing_adds_five_support_in_a_real_town_hall_and_caucus_only_while_they_hold() -> void:
	GameState.owned_modifiers = ["M47"]
	for stage_id: String in ["ST05", "ST03", "ST24"]:
		var stage: Dictionary = DataDB.get_stage(stage_id)
		GameState.booster_standing["BO31"] = 60
		assert_eq(BattleSetup.backing_bonus(stage)["start_support"], 5, "%s with Activists at 60" % stage_id)
		GameState.booster_standing["BO31"] = 5
		assert_eq(BattleSetup.backing_bonus(stage)["start_support"], 0, "%s with Activists at 5" % stage_id)
	GameState.booster_standing["BO31"] = 60
	assert_eq(BattleSetup.backing_bonus(DataDB.get_stage("ST02"))["start_support"], 0, "not a Town Hall or Caucus")
	GameState.owned_modifiers = []


func test_decay_settles_back_by_a_percent_of_the_distance() -> void:
	assert_eq(BoosterStanding.decayed_percent(100, 5, 8.0), 92)    # 95 x 8% = 7.6 -> 8
	assert_eq(BoosterStanding.decayed_percent(6, 5, 8.0), 5, "at least one point, never past the start")
	assert_eq(BoosterStanding.decayed_percent(10, 30, 5.0), 11, "an offended organization settles back up")
	assert_eq(BoosterStanding.decayed_percent(50, 50, 5.0), 50)
	assert_eq(BoosterStanding.decayed_percent(80, 30, 0.0), 80, "0 turns it off")


func test_every_organization_has_its_own_decay_percent() -> void:
	for booster: Dictionary in DataDB.boosters:
		assert_not_null(booster.get("decay_percent"), "%s has a Decay Percent" % booster["booster_id"])
		assert_gt(float(booster["decay_percent"]), 0.0)


func test_ending_a_level_settles_every_organization_back() -> void:
	GameState.start_new_run("PC02")
	DataDB.standing_links = []
	for id: String in GameState.booster_standing:
		GameState.booster_standing[id] = 100
	GameState.last_booster_change = {}
	GameState._apply_standing_decay()
	for booster: Dictionary in DataDB.boosters:
		assert_lt(int(GameState.booster_standing[str(booster["booster_id"])]), 100,
			"%s settled back" % booster["booster_id"])
	assert_string_contains(GameState.last_booster_cause["BO31"][0]["cause"], "settling back")
