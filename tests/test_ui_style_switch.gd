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


func test_a_new_run_is_living_office() -> void:
	assert_eq(UiStyle.current(), UiStyles.LIVING_OFFICE)


func test_the_two_styles_are_packages_priced_in_the_workbook() -> void:
	for style: String in [UiStyles.BROADCAST, UiStyles.WOODBLOCK]:
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
	var id := str(UiStyles.package_for(UiStyles.WOODBLOCK, DataDB.cosmetic_packages)["package_id"])
	GameState.xp = 10
	GameState.buy_cosmetic_package(id)
	var before := GameState.to_save().duplicate(true)
	GameState.equip_cosmetic(CosmeticPieces.UI_STYLE, id)
	assert_eq(UiStyle.current(), UiStyles.WOODBLOCK)
	var after := GameState.to_save().duplicate(true)
	var changed: Array[String] = []
	for key: String in after:
		if str(after[key]) != str(before.get(key)):
			changed.append(key)
	assert_eq(changed, ["active_cosmetics"], "only the equipped slot differs")
	assert_eq(((after["active_cosmetics"]) as Dictionary).get(CosmeticPieces.UI_STYLE), id)
	# And back to the free default.
	GameState.equip_cosmetic(CosmeticPieces.UI_STYLE, "")
	assert_eq(UiStyle.current(), UiStyles.LIVING_OFFICE)
	assert_eq(GameState.to_save().duplicate(true)["active_cosmetics"], before["active_cosmetics"])


func test_an_unowned_style_in_a_save_is_dropped_on_load() -> void:
	var id := str(UiStyles.package_for(UiStyles.BROADCAST, DataDB.cosmetic_packages)["package_id"])
	var data := GameState.to_save().duplicate(true)
	data["active_cosmetics"] = {CosmeticPieces.UI_STYLE: id}
	data["owned_cosmetic_packages"] = []
	GameState.load_save(data)
	assert_eq(UiStyle.current(), UiStyles.LIVING_OFFICE, "an unowned style falls back to Living Office")
