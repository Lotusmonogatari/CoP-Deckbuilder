extends GutTest
## W-2 (2026-11-16, Cameron): owing party dues locks the party's backings and
## switches the free Party Backing (M09) off.

func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC02")


func _party_backing() -> Dictionary:
	for modifier: Dictionary in DataDB.modifiers:
		if not PartyDues.party_backings([str(modifier.get("mod_id", ""))], [modifier], DataDB.boosters).is_empty():
			return modifier
	return {}


func _enough_for(modifier: Dictionary) -> void:
	GameState.meta["Funds"] = 1000000
	GameState.meta["Reputation"] = 100
	GameState.meta["Constituency support"] = 100
	for booster_id: String in GameState.booster_standing.keys():
		GameState.booster_standing[booster_id] = 100


func test_a_party_backing_is_refused_while_dues_are_owed() -> void:
	var modifier := _party_backing()
	assert_false(modifier.is_empty(), "there is a party backing in the data")
	_enough_for(modifier)
	GameState.dues_balance = 0
	assert_eq(GameState.backing_refusal(modifier), "", "nothing owed: it can be taken")
	GameState.dues_balance = 50000
	assert_eq(GameState.backing_refusal(modifier), Text.say("backing.refuse_dues_owed"))


func test_a_backing_from_another_organization_is_not_locked() -> void:
	var other := {}
	for modifier: Dictionary in DataDB.modifiers:
		if PartyDues.party_backings([str(modifier.get("mod_id", ""))], [modifier], DataDB.boosters).is_empty() \
				and not (modifier.get("trigger_booster_ids", []) as Array).is_empty():
			other = modifier
			break
	_enough_for(other)
	GameState.dues_balance = 50000
	assert_ne(GameState.backing_refusal(other), Text.say("backing.refuse_dues_owed"))


func test_the_free_party_backing_switches_off_while_dues_are_owed() -> void:
	GameState.meta["Party support"] = 100
	for booster_id: String in GameState.booster_standing.keys():
		GameState.booster_standing[booster_id] = 100   # party_support_effective() blends in the organizations
	var ids := func() -> Array:
		var found := []
		for modifier: Dictionary in GameState._effectively_owned_modifiers():
			found.append(str(modifier.get("mod_id")))
		return found
	GameState.dues_balance = 0
	assert_true((ids.call() as Array).has("M09"), "M09 is on when nothing is owed")
	GameState.dues_balance = 1
	assert_false((ids.call() as Array).has("M09"), "M09 is off while dues are owed")


func test_the_lock_can_be_turned_off_in_the_workbook() -> void:
	DataDB.balance["dues_debt_locks_backings"] = 0
	GameState.dues_balance = 50000
	assert_false(GameState.dues_debt_locks_backings())
