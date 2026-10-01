extends GutTest
## GameState's cosmetics wiring: buy_cosmetic_package(), equip_cosmetic(),
## and that both fields reset with a new run.
##
## The workbook's own CP01/CP02 seed rows were removed 2026-09-30 (nothing
## to sell yet — the whole system stays blank-tolerant, per CLAUDE.md §8),
## so these tests inject two synthetic packages straight into DataDB for
## their own duration, the same "fake row" technique
## floor_vote_driver.gd/level_intro_driver.gd already use for a workbook
## tab that has nothing real to test against.
##
## GameState is the run's memory and an autoload; these tests put it back the
## way they found it.

const TEST_PACKAGE_1 := {"package_id": "CPTEST1", "name_en": "Test Package 1",
	"cost_xp": 0, "cost_yen": 500, "outfit_variant": "TESTA"}
const TEST_PACKAGE_2 := {"package_id": "CPTEST2", "name_en": "Test Package 2",
	"cost_xp": 0, "cost_yen": 300, "music_office_sound": "music_office_test"}

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
	DataDB.cosmetic_packages.append(TEST_PACKAGE_1)
	DataDB.cosmetic_packages.append(TEST_PACKAGE_2)
	DataDB._cosmetic_packages_by_id = DataDB._index(DataDB.cosmetic_packages, "package_id")


func after_each() -> void:
	GameState.owned_cosmetic_packages = _owned_before.duplicate(true)
	GameState.active_cosmetics = _active_before.duplicate(true)
	GameState.meta = _meta_before.duplicate(true)
	GameState.xp = _xp_before
	DataDB.cosmetic_packages = DataDB.cosmetic_packages.filter(
		func(p: Dictionary) -> bool: return str(p.get("package_id", "")).begins_with("CPTEST") == false)
	DataDB._cosmetic_packages_by_id = DataDB._index(DataDB.cosmetic_packages, "package_id")


func test_buying_a_package_deducts_funds_and_grants_ownership() -> void:
	var refusal := GameState.buy_cosmetic_package("CPTEST1")
	assert_eq(refusal, "")
	assert_true(GameState.owned_cosmetic_packages.has("CPTEST1"))
	assert_eq(int(GameState.meta.get("Funds", 0)), 500)


func test_buying_the_same_package_twice_is_refused() -> void:
	GameState.buy_cosmetic_package("CPTEST1")
	var refusal := GameState.buy_cosmetic_package("CPTEST1")
	assert_ne(refusal, "")
	assert_eq(GameState.owned_cosmetic_packages.count("CPTEST1"), 1)


func test_buying_when_funds_are_short_changes_nothing() -> void:
	GameState.meta["Funds"] = 100
	var refusal := GameState.buy_cosmetic_package("CPTEST1")
	assert_ne(refusal, "")
	assert_false(GameState.owned_cosmetic_packages.has("CPTEST1"))
	assert_eq(int(GameState.meta.get("Funds", 0)), 100)


func test_equip_sets_the_slot_and_default_clears_it() -> void:
	GameState.equip_cosmetic(CosmeticPieces.OUTFIT, "CPTEST1")
	assert_eq(str(GameState.active_cosmetics.get(CosmeticPieces.OUTFIT, "")), "CPTEST1")
	GameState.equip_cosmetic(CosmeticPieces.OUTFIT, "")
	assert_false(GameState.active_cosmetics.has(CosmeticPieces.OUTFIT))


func test_slots_are_independent() -> void:
	GameState.equip_cosmetic(CosmeticPieces.OUTFIT, "CPTEST1")
	GameState.equip_cosmetic(CosmeticPieces.MUSIC, "CPTEST2")
	assert_eq(str(GameState.active_cosmetics.get(CosmeticPieces.OUTFIT, "")), "CPTEST1")
	assert_eq(str(GameState.active_cosmetics.get(CosmeticPieces.MUSIC, "")), "CPTEST2")
	assert_false(GameState.active_cosmetics.has(CosmeticPieces.BACKGROUND))


func test_a_new_run_clears_both_fields() -> void:
	GameState.owned_cosmetic_packages.append("CPTEST1")
	GameState.active_cosmetics[CosmeticPieces.OUTFIT] = "CPTEST1"
	GameState.reset_collection()
	assert_true(GameState.owned_cosmetic_packages.is_empty())
	assert_true(GameState.active_cosmetics.is_empty())
