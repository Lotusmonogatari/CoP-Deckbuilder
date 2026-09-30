extends GutTest
## Cosmetic packages: cost, has_piece per slot, and buy refusal
## (scripts/rules/CosmeticPieces.gd).
##
## CosmeticPieces is pure (no DataDB access), so these use plain fixture
## dictionaries rather than real workbook rows — the workbook's own
## CP01/CP02 seed rows were removed 2026-09-30 (nothing to sell yet, the
## same blank-tolerant bargain every other empty table in this project
## keeps), so there is no real data left to test against here.

var _full_package: Dictionary
var _music_only_package: Dictionary


func before_all() -> void:
	_full_package = {
		"package_id": "CPTEST1", "name_en": "Test Package",
		"cost_xp": 0, "cost_yen": 500,
		"outfit_variant": "TESTA", "background_variant": "TESTBG",
		"music_office_sound": "music_office_test", "music_battle_sound": "music_battle_test",
	}
	_music_only_package = {
		"package_id": "CPTEST2", "name_en": "Test Package (Music Only)",
		"cost_xp": 0, "cost_yen": 300,
		"outfit_variant": null, "background_variant": null,
		"music_office_sound": "music_office_test2",
	}


func test_has_piece_per_slot() -> void:
	assert_true(CosmeticPieces.has_piece(_full_package, CosmeticPieces.OUTFIT))
	assert_true(CosmeticPieces.has_piece(_full_package, CosmeticPieces.BACKGROUND))
	assert_true(CosmeticPieces.has_piece(_full_package, CosmeticPieces.MUSIC))

	assert_false(CosmeticPieces.has_piece(_music_only_package, CosmeticPieces.OUTFIT))
	assert_false(CosmeticPieces.has_piece(_music_only_package, CosmeticPieces.BACKGROUND))
	assert_true(CosmeticPieces.has_piece(_music_only_package, CosmeticPieces.MUSIC))


func test_field_reads_a_blank_json_null_cell_as_empty_not_the_literal_null_text() -> void:
	# The music-only fixture's outfit_variant cell is blank -> JSON null.
	# Dictionary.get(key, default) only uses the default when the KEY is
	# absent, not when its value is null, so this guards the same <null>
	# bug class Party/Title fields already needed guarding for.
	assert_eq(CosmeticPieces.field(_music_only_package, "outfit_variant"), "")
	assert_ne(CosmeticPieces.field(_music_only_package, "outfit_variant"), "<null>")


func test_cost_reads_the_same_columns_items_gd_uses() -> void:
	var price := CosmeticPieces.cost(_full_package)
	assert_eq(int(price["Funds"]), 500)
	assert_eq(int(price["XP"]), 0)


func test_buy_refusal_when_already_owned() -> void:
	var refusal := CosmeticPieces.buy_refusal(_full_package, ["CPTEST1"], 9999, 9999)
	assert_ne(refusal, "")


func test_buy_refusal_when_affordable() -> void:
	var refusal := CosmeticPieces.buy_refusal(_full_package, [], 0, 500)
	assert_eq(refusal, "")


func test_buy_refusal_when_funds_short() -> void:
	var refusal := CosmeticPieces.buy_refusal(_full_package, [], 0, 100)
	assert_ne(refusal, "")


func test_buy_refusal_with_no_package_id() -> void:
	var refusal := CosmeticPieces.buy_refusal({}, [], 9999, 9999)
	assert_ne(refusal, "")
