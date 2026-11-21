extends GutTest
## Buying and switching UI styles (P9): the purchase uses CosmeticPieces, a refusal says why, and
## switching changes nothing in the save but the equipped slot.

func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	UiStyle.forget()


func after_each() -> void:
	GameState.active_cosmetics.erase(CosmeticPieces.UI_STYLE)
	UiStyle.forget()


func test_a_new_run_with_no_pick_owns_and_wears_woodblock() -> void:
	assert_eq(UiStyle.current(), UiStyles.WOODBLOCK)
	var woodblock := str(UiStyles.package_for(UiStyles.WOODBLOCK, DataDB.cosmetic_packages)["package_id"])
	assert_true(GameState.owned_cosmetic_packages.has(woodblock), "owned free")
	assert_eq(GameState.active_cosmetics[CosmeticPieces.UI_STYLE], woodblock)
	var yezo := str(UiStyles.package_for(UiStyles.LIVING_OFFICE, DataDB.cosmetic_packages)["package_id"])
	assert_false(GameState.owned_cosmetic_packages.has(yezo), "the others are bought")


func test_the_three_styles_are_packages_priced_in_the_workbook() -> void:
	for style: String in UiStyles.ALL:
		var package := UiStyles.package_for(style, DataDB.cosmetic_packages)
		assert_false(package.is_empty(), style + " has a package")
		assert_true(CosmeticPieces.has_piece(package, CosmeticPieces.UI_STYLE))


func test_buying_uses_the_cosmetic_rules_and_a_refusal_says_why() -> void:
	var package := UiStyles.package_for(UiStyles.BROADCAST, DataDB.cosmetic_packages)
	var id := str(package["package_id"])
	GameState.xp = 0
	var refusal := GameState.buy_cosmetic_package(id)
	assert_ne(refusal, "", "no XP: refused")
	assert_false(GameState.owned_cosmetic_packages.has(id))
	GameState.xp = 10
	assert_eq(GameState.buy_cosmetic_package(id), "")
	assert_true(GameState.owned_cosmetic_packages.has(id))
	assert_ne(GameState.buy_cosmetic_package(id), "", "a second purchase is refused: already yours")


func test_switching_changes_only_the_equipped_slot() -> void:
	var woodblock := str(GameState.active_cosmetics[CosmeticPieces.UI_STYLE])
	var id := str(UiStyles.package_for(UiStyles.BROADCAST, DataDB.cosmetic_packages)["package_id"])
	GameState.xp = 10
	GameState.buy_cosmetic_package(id)
	var before := GameState.to_save().duplicate(true)
	GameState.equip_cosmetic(CosmeticPieces.UI_STYLE, id)
	assert_eq(UiStyle.current(), UiStyles.BROADCAST)
	var after := GameState.to_save().duplicate(true)
	var changed: Array[String] = []
	for key: String in after:
		if str(after[key]) != str(before.get(key)):
			changed.append(key)
	assert_eq(changed, ["active_cosmetics"], "only the equipped slot differs")
	assert_eq(((after["active_cosmetics"]) as Dictionary).get(CosmeticPieces.UI_STYLE), id)
	# And back to the one picked at the start.
	GameState.equip_cosmetic(CosmeticPieces.UI_STYLE, woodblock)
	assert_eq(UiStyle.current(), UiStyles.WOODBLOCK)
	assert_eq(GameState.to_save().duplicate(true)["active_cosmetics"], before["active_cosmetics"])
	# With nothing equipped at all the default shows.
	GameState.equip_cosmetic(CosmeticPieces.UI_STYLE, "")
	assert_eq(UiStyle.current(), UiStyles.WOODBLOCK)


func test_an_unowned_style_in_a_save_is_dropped_on_load() -> void:
	var id := str(UiStyles.package_for(UiStyles.BROADCAST, DataDB.cosmetic_packages)["package_id"])
	var data := GameState.to_save().duplicate(true)
	data["active_cosmetics"] = {CosmeticPieces.UI_STYLE: id}
	data["owned_cosmetic_packages"] = []
	GameState.load_save(data)
	assert_eq(UiStyle.current(), UiStyles.WOODBLOCK, "an unowned style falls back to the default, Woodblock")
	assert_true(GameState.owned_cosmetic_packages.size() >= 1, "and the default is given free")


func test_a_save_with_no_style_gets_the_default_free() -> void:
	var data := GameState.to_save().duplicate(true)
	data["active_cosmetics"] = {}
	data["owned_cosmetic_packages"] = []
	GameState.load_save(data)
	var woodblock := str(UiStyles.package_for(UiStyles.WOODBLOCK, DataDB.cosmetic_packages)["package_id"])
	assert_true(GameState.owned_cosmetic_packages.has(woodblock))
	assert_eq(GameState.active_cosmetics[CosmeticPieces.UI_STYLE], woodblock)


func test_an_owned_equipped_style_is_kept_on_load() -> void:
	var broadcast := str(UiStyles.package_for(UiStyles.BROADCAST, DataDB.cosmetic_packages)["package_id"])
	var data := GameState.to_save().duplicate(true)
	data["active_cosmetics"] = {CosmeticPieces.UI_STYLE: broadcast}
	data["owned_cosmetic_packages"] = [broadcast]
	GameState.load_save(data)
	assert_eq(UiStyle.current(), UiStyles.BROADCAST, "a pick is never overwritten by the default")
	assert_eq(GameState.owned_cosmetic_packages, [broadcast])
