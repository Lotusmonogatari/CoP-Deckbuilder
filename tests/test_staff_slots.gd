extends GutTest
## The staff slot item (Cameron, 2026-11-08): each purchase adds a place to
## every staff role. The first hire in a role is its primary (the one every
## scene reads); later ones are extras, who pay rank rewards and may speak in
## transitions. One can be made primary. Costs: 150 XP, 300,000円, and 15
## Reputation (a Balance number).

func before_each() -> void:
	GameState.start_new_run("PC01")
	GameState.staff_recruitment_tier = 9
	GameState.meta["Funds"] = 1000000
	GameState.meta["Reputation"] = 50
	GameState.xp = 500


func _two_in(role: String) -> Array[String]:
	var ids: Array[String] = []
	for row: Dictionary in DataDB.get_staff_by_role(role):
		ids.append(str(row["staff_id"]))
	return ids


func test_a_role_holds_one_person_until_the_item_is_bought() -> void:
	var ids := _two_in("Media Spokesperson")
	assert_eq(GameState.hire_staff(ids[0]), "")
	assert_ne(GameState.hire_staff(ids[1]), "", "no second place yet")
	assert_eq(GameState.staff_in_role("Media Spokesperson").size(), 1)


func test_the_item_charges_xp_funds_and_reputation_and_adds_a_place() -> void:
	var item := DataDB.get_shop_item("SH35")
	assert_false(item.is_empty())
	assert_true(GameState.is_staff_slot_item(item))
	var xp := GameState.xp
	var funds := int(GameState.meta["Funds"])
	var reputation := int(GameState.meta["Reputation"])
	var result := GameState.buy_staff_slots("SH35")
	assert_true(result["ok"])
	assert_eq(GameState.xp, xp - 150)
	assert_eq(int(GameState.meta["Funds"]), funds - 300000)
	assert_eq(int(GameState.meta["Reputation"]), reputation - 15)
	assert_eq(GameState.staff_slots(), 2)


func test_it_is_refused_when_reputation_is_short_and_says_so() -> void:
	GameState.meta["Reputation"] = 10
	var result := GameState.buy_staff_slots("SH35")
	assert_false(result["ok"])
	assert_string_contains(str(result["message"]), "Reputation")
	assert_eq(GameState.staff_slots(), 1)
	assert_eq(int(GameState.meta["Funds"]), 1000000, "nothing was charged")


func test_it_can_be_bought_up_to_the_balance_limit_and_no_more() -> void:
	var limit := int(DataDB.balance.get("staff_slots_maximum_purchases", 2))
	for i in limit:
		assert_true(GameState.buy_staff_slots("SH35")["ok"])
		GameState.xp = 500
		GameState.meta["Funds"] = 1000000
		GameState.meta["Reputation"] = 50
	assert_false(GameState.buy_staff_slots("SH35")["ok"])
	assert_true(GameState.staff_slots_maxed())


func test_the_first_hire_is_primary_and_later_ones_are_extras() -> void:
	GameState.buy_staff_slots("SH35")
	var ids := _two_in("Media Spokesperson")
	GameState.hire_staff(ids[0])
	assert_eq(GameState.hire_staff(ids[1]), "")
	assert_eq(str(GameState.staff_hired["Media Spokesperson"]["staff_id"]), ids[0])
	assert_eq(GameState.staff_in_role("Media Spokesperson").size(), 2)
	assert_false(bool(GameState.hired_member(ids[1])["primary"]))
	assert_ne(GameState.hire_staff(ids[2]), "", "the role is full")


func test_an_extra_pays_its_rank_reward_when_hired() -> void:
	GameState.buy_staff_slots("SH35")
	var ids := _two_in("Policy Research Assistant")
	GameState.hire_staff(ids[0])
	var candidate := DataDB.get_staff(ids[1])
	var rewards: Variant = candidate.get("tier_%d_reward" % int(candidate.get("starting_tier", 0)))
	var target := ""
	if rewards is Array and not (rewards as Array).is_empty():
		target = str((rewards as Array)[0]["target"])
	var before := int(GameState.booster_standing.get(target, 0))
	GameState.hire_staff(ids[1])
	if target.begins_with("BO"):
		assert_ne(int(GameState.booster_standing.get(target, 0)), before, "the extra's reward landed")


func test_make_primary_swaps_who_every_scene_reads() -> void:
	GameState.buy_staff_slots("SH35")
	var ids := _two_in("District Representative")
	GameState.hire_staff(ids[0])
	GameState.hire_staff(ids[1])
	assert_eq(GameState.make_primary(ids[1]), "")
	assert_eq(str(GameState.staff_hired["District Representative"]["staff_id"]), ids[1])
	assert_true(bool(GameState.hired_member(ids[1])["primary"]))
	assert_false(bool(GameState.hired_member(ids[0])["primary"]))


func test_firing_the_primary_promotes_the_first_extra() -> void:
	GameState.buy_staff_slots("SH35")
	var ids := _two_in("Media Spokesperson")
	GameState.hire_staff(ids[0])
	GameState.hire_staff(ids[1])
	assert_eq(GameState.fire_staff_member(ids[0]), "")
	assert_eq(str(GameState.staff_hired["Media Spokesperson"]["staff_id"]), ids[1])
	assert_eq(GameState.staff_in_role("Media Spokesperson").size(), 1)
	assert_ne(GameState.hire_staff(ids[0]), "", "a fired candidate never returns")


func test_firing_an_extra_leaves_the_primary_alone() -> void:
	GameState.buy_staff_slots("SH35")
	var ids := _two_in("Media Spokesperson")
	GameState.hire_staff(ids[0])
	GameState.hire_staff(ids[1])
	assert_eq(GameState.fire_staff_member(ids[1]), "")
	assert_eq(str(GameState.staff_hired["Media Spokesperson"]["staff_id"]), ids[0])


func test_an_extra_can_be_upgraded_on_its_own() -> void:
	GameState.buy_staff_slots("SH35")
	var ids := _two_in("Media Spokesperson")
	GameState.hire_staff(ids[0])
	var upgradable := ""
	for id in ids.slice(1):
		if int(DataDB.get_staff(id).get("highest_tier", 0)) > int(DataDB.get_staff(id).get("starting_tier", 0)):
			upgradable = id
			break
	if upgradable.is_empty():
		pending("no extra with an upgrade in this role")
		return
	GameState.hire_staff(upgradable)
	var before := int(GameState.hired_member(upgradable)["tier"])
	assert_eq(GameState.upgrade_staff_member(upgradable), "")
	assert_eq(int(GameState.hired_member(upgradable)["tier"]), before + 1)


func test_extras_and_slots_survive_a_save_round_trip() -> void:
	GameState.buy_staff_slots("SH35")
	var ids := _two_in("Media Spokesperson")
	GameState.hire_staff(ids[0])
	GameState.hire_staff(ids[1])
	var saved := JSON.to_native(JSON.from_native(GameState.to_save())) as Dictionary
	GameState.start_new_run("PC01")
	GameState.load_save(saved)
	assert_eq(GameState.staff_slots(), 2)
	assert_eq(GameState.staff_in_role("Media Spokesperson").size(), 2)
	assert_eq(str(GameState.staff_hired["Media Spokesperson"]["staff_id"]), ids[0])


func test_every_hired_person_may_speak_in_a_transition() -> void:
	GameState.buy_staff_slots("SH35")
	var ids := _two_in("Media Spokesperson")
	GameState.hire_staff(ids[0])
	GameState.hire_staff(ids[1])
	var speaking := GameState.all_hired_staff_ids()
	assert_true(speaking.has(ids[0]))
	assert_true(speaking.has(ids[1]))


func test_a_new_run_forgets_extras_and_slots() -> void:
	GameState.buy_staff_slots("SH35")
	var ids := _two_in("Media Spokesperson")
	GameState.hire_staff(ids[0])
	GameState.hire_staff(ids[1])
	GameState.start_new_run("PC01")
	assert_eq(GameState.staff_slots(), 1)
	assert_true(GameState.staff_extra.is_empty())
