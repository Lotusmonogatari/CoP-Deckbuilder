extends GutTest
## GameState's cosmetics wiring: buy_cosmetic_package(), equip_cosmetic(),
## and that both fields reset with a new run. Against real workbook data
## (CP01 costs 500 Funds; CP02 costs 300 Funds).
##
## GameState is the run's memory and an autoload; these tests put it back the
## way they found it.

var _owned_before: Array[String] = []
var _active_before: Dictionary = {}
var _meta_before: Dictionary = {}
var _xp_before := 0


func before_each() -> void:
	_owned_before = GameState.owned_cosmetic_packages.duplicate(true)
	_active_before = GameState.active_cosmetics.duplicate(true)
	_meta_before = GameState.meta.duplicate(true)
	_xp_before = GameState.xp
	GameState.owned_cosmetic_packages = []
	GameState.active_cosmetics = {}
	GameState.meta["Funds"] = 1000


func after_each() -> void:
	GameState.owned_cosmetic_packages = _owned_before.duplicate(true)
	GameState.active_cosmetics = _active_before.duplicate(true)
	GameState.meta = _meta_before.duplicate(true)
	GameState.xp = _xp_before


func test_buying_a_package_deducts_funds_and_grants_ownership() -> void:
	var refusal := GameState.buy_cosmetic_package("CP01")
	assert_eq(refusal, "")
	assert_true(GameState.owned_cosmetic_packages.has("CP01"))
	assert_eq(int(GameState.meta.get("Funds", 0)), 500)


func test_buying_the_same_package_twice_is_refused() -> void:
	GameState.buy_cosmetic_package("CP01")
	var refusal := GameState.buy_cosmetic_package("CP01")
	assert_ne(refusal, "")
	assert_eq(GameState.owned_cosmetic_packages.count("CP01"), 1)


func test_buying_when_funds_are_short_changes_nothing() -> void:
	GameState.meta["Funds"] = 100
	var refusal := GameState.buy_cosmetic_package("CP01")
	assert_ne(refusal, "")
	assert_false(GameState.owned_cosmetic_packages.has("CP01"))
	assert_eq(int(GameState.meta.get("Funds", 0)), 100)


func test_equip_sets_the_slot_and_default_clears_it() -> void:
	GameState.equip_cosmetic(CosmeticPieces.OUTFIT, "CP01")
	assert_eq(str(GameState.active_cosmetics.get(CosmeticPieces.OUTFIT, "")), "CP01")
	GameState.equip_cosmetic(CosmeticPieces.OUTFIT, "")
	assert_false(GameState.active_cosmetics.has(CosmeticPieces.OUTFIT))


func test_slots_are_independent() -> void:
	GameState.equip_cosmetic(CosmeticPieces.OUTFIT, "CP01")
	GameState.equip_cosmetic(CosmeticPieces.MUSIC, "CP02")
	assert_eq(str(GameState.active_cosmetics.get(CosmeticPieces.OUTFIT, "")), "CP01")
	assert_eq(str(GameState.active_cosmetics.get(CosmeticPieces.MUSIC, "")), "CP02")
	assert_false(GameState.active_cosmetics.has(CosmeticPieces.BACKGROUND))


func test_a_new_run_clears_both_fields() -> void:
	GameState.owned_cosmetic_packages.append("CP01")
	GameState.active_cosmetics[CosmeticPieces.OUTFIT] = "CP01"
	GameState.reset_collection()
	assert_true(GameState.owned_cosmetic_packages.is_empty())
	assert_true(GameState.active_cosmetics.is_empty())
