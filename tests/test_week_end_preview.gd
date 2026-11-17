extends GutTest
## The week-over popup tells the player what going home costs before they choose (panel P4,
## 2026-11-17). The preview must be the charge: every number is checked against what go_home()
## then does.


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC02")
	GameState.staff_recruitment_tier = 2
	GameState.calendar["week"] = 6          # past the dues holiday
	GameState.week_funds_earned = 80000
	GameState.meta["Party support"] = 55
	for id: String in ["SF04", "SF08"]:
		GameState.hire_staff(id)


func _go_and_compare(label: String) -> Dictionary:
	var preview := GameState.week_end_preview()
	var funds_before := int(GameState.meta["Funds"])
	var report := GameState.go_home()
	var dues: Dictionary = report["dues"]
	var pd: Dictionary = preview["dues"]
	assert_eq(int(dues["total"]), int(pd["total"]), label + ": dues total")
	assert_eq(int(dues["week_dues"]), int(pd["week_dues"]), label + ": this week's dues")
	assert_eq(int(dues["paid"]), int(pd["paid"]), label + ": dues paid")
	assert_eq(int(dues["owed"]), int(pd["owed"]), label + ": dues left owed")
	assert_eq(int(pd["week_dues"]), int(pd["base"]) + int(pd["share"]), label + ": base plus share is the week's dues")
	assert_eq((dues.get("withdrawn", []) as Array), (preview["withdrawn"] as Array), label + ": backings withdrawn")
	if int(dues["owed"]) > 0:
		assert_eq(dues.get("penalties", {}), preview["penalties"], label + ": penalties")
	assert_eq(int((report["staff"] as Dictionary)["paid_total"]), int((preview["staff"] as Dictionary)["wages_paid"]), label + ": wages paid")
	assert_eq(int(GameState.meta["Funds"]), int((preview["funds"] as Dictionary)["after"]), label + ": Funds after")
	assert_eq(funds_before - int(dues["paid"]) - int((report["staff"] as Dictionary)["paid_total"]), int(GameState.meta["Funds"]), label + ": Funds change is dues plus wages")
	return preview


func test_the_preview_equals_the_charge_when_funds_cover_it() -> void:
	GameState.meta["Funds"] = 900000
	var preview := _go_and_compare("covered")
	assert_eq(int(preview["short"]), 0)
	assert_true((preview["penalties"] as Dictionary).is_empty())


func test_the_preview_equals_the_charge_when_dues_are_short() -> void:
	GameState.meta["Funds"] = 60000
	GameState.owned_modifiers.append_array(PartyDues.party_backings(
		DataDB.modifiers.map(func(m: Dictionary) -> String: return str(m.get("mod_id", ""))), DataDB.modifiers, DataDB.boosters).slice(0, 2))
	var preview := _go_and_compare("short")
	assert_gt(int(preview["short"]), 0, "the dues are short in this case")
	assert_false((preview["penalties"] as Dictionary).is_empty())
	assert_gt((preview["withdrawn"] as Array).size(), 0, "a party backing was held and is withdrawn")


func test_dues_that_are_paid_but_wages_that_are_not() -> void:
	GameState.meta["Funds"] = int(GameState.week_end_preview()["dues"]["total"]) + 1000
	var preview := _go_and_compare("wages short")
	assert_gt(int((preview["staff"] as Dictionary)["wages_missed"]), 0, "somebody's wage is missed")


func test_national_awareness_relief_is_named() -> void:
	GameState.meta["Funds"] = 900000
	var plain := int(GameState.week_end_preview()["dues"]["relief"])
	GameState.awareness["national"] = 95
	var relieved := GameState.week_end_preview()["dues"] as Dictionary
	assert_gte(int(relieved["relief"]), plain)
	assert_eq(int(relieved["week_dues"]), int(relieved["base"]) + int(relieved["share"]))


func test_the_dues_holiday_shows_nothing_owed() -> void:
	GameState.calendar["week"] = 0
	GameState.meta["Funds"] = 900000
	var dues := GameState.week_end_preview()["dues"] as Dictionary
	assert_eq(int(dues["week_dues"]), 0)
	assert_eq(int(dues["base"]) + int(dues["share"]), 0)


# --- item 2 and 3: costs above the Funds limit say why and what raises it ---------------------

func test_a_draft_cost_above_the_funds_limit_names_the_petition() -> void:
	var state := {"enacted": [], "xp": 500, "funds": 100000, "time_units": 0, "last_draft_at": -1, "in_level": false,
		"extra_visit": false, "funds_limit": 100000, "petition": GameState.funds_cap_item_name()}
	var why := DraftBill.refusal(["CB031", "CB032"], state)
	assert_string_contains(why, GameState.funds_cap_item_name())
	assert_string_contains(why, "100,000")
	state["funds_limit"] = 1000000
	assert_false(DraftBill.refusal(["CB031", "CB032"], state).contains(GameState.funds_cap_item_name()), "with room under the limit it is the ordinary short-Funds message")


func test_an_item_priced_above_the_funds_limit_names_the_petition() -> void:
	var item := {"item_id": "X1", "cost_yen": 200000, "cost_xp": 0}
	var why := Items.buy_refusal(item, 0, 0, 500, 100000, Text.phrase(), 100000, "Funds Cap Increase Petition")
	assert_string_contains(why, "Funds Cap Increase Petition")
	var plain := Items.buy_refusal(item, 0, 0, 500, 100000, Text.phrase(), 1000000, "Funds Cap Increase Petition")
	assert_false(plain.contains("Petition"), "an item the limit would allow is just short of Funds")


func test_the_funds_cap_item_is_found_by_its_data() -> void:
	assert_ne(GameState.funds_cap_item_name(), "")


# --- item 3: the Marketplace header explains the limit when Funds are at it ---------------------

func test_the_marketplace_header_explains_the_limit_at_the_limit() -> void:
	GameState.awaiting_new_game = false
	var office: Control = (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate()
	add_child_autofree(office)
	await get_tree().process_frame
	GameState.meta["Funds"] = GameState.funds_limit() - 1000
	office.call("_show_marketplace")
	await get_tree().process_frame
	assert_null(office.find_child("MarketLimitNote", true, false), "no note below the limit")
	GameState.meta["Funds"] = GameState.funds_limit()
	office.call("_show_marketplace")
	await get_tree().process_frame
	assert_not_null(office.find_child("MarketLimitNote", true, false), "the note shows at the limit")
