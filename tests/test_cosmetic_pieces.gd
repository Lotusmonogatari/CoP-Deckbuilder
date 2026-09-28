extends GutTest
## Cosmetic packages: cost, has_piece per slot, and buy refusal
## (scripts/rules/CosmeticPieces.gd), against real workbook data (CP01/CP02).

var _cp01: Dictionary
var _cp02: Dictionary


func before_all() -> void:
	_cp01 = DataDB.get_cosmetic_package("CP01")   # outfit + background + music
	_cp02 = DataDB.get_cosmetic_package("CP02")   # music only


func test_real_packages_load() -> void:
	assert_eq(str(_cp01.get("package_id")), "CP01")
	assert_eq(str(_cp02.get("package_id")), "CP02")


func test_has_piece_per_slot() -> void:
	assert_true(CosmeticPieces.has_piece(_cp01, CosmeticPieces.OUTFIT))
	assert_true(CosmeticPieces.has_piece(_cp01, CosmeticPieces.BACKGROUND))
	assert_true(CosmeticPieces.has_piece(_cp01, CosmeticPieces.MUSIC))

	assert_false(CosmeticPieces.has_piece(_cp02, CosmeticPieces.OUTFIT))
	assert_false(CosmeticPieces.has_piece(_cp02, CosmeticPieces.BACKGROUND))
	assert_true(CosmeticPieces.has_piece(_cp02, CosmeticPieces.MUSIC))


func test_field_reads_a_blank_json_null_cell_as_empty_not_the_literal_null_text() -> void:
	# CP02's outfit_variant/background_variant cells are blank -> JSON null.
	# Dictionary.get(key, default) only uses the default when the KEY is
	# absent, not when its value is null, so this guards the same <null>
	# bug class Party/Title fields already needed guarding for.
	assert_eq(CosmeticPieces.field(_cp02, "outfit_variant"), "")
	assert_ne(CosmeticPieces.field(_cp02, "outfit_variant"), "<null>")


func test_cost_reads_the_same_columns_items_gd_uses() -> void:
	var price := CosmeticPieces.cost(_cp01)
	assert_eq(int(price["Funds"]), 500)
	assert_eq(int(price["XP"]), 0)


func test_buy_refusal_when_already_owned() -> void:
	var refusal := CosmeticPieces.buy_refusal(_cp01, ["CP01"], 9999, 9999)
	assert_ne(refusal, "")


func test_buy_refusal_when_affordable() -> void:
	var refusal := CosmeticPieces.buy_refusal(_cp01, [], 0, 500)
	assert_eq(refusal, "")


func test_buy_refusal_when_funds_short() -> void:
	var refusal := CosmeticPieces.buy_refusal(_cp01, [], 0, 100)
	assert_ne(refusal, "")


func test_buy_refusal_with_no_package_id() -> void:
	var refusal := CosmeticPieces.buy_refusal({}, [], 9999, 9999)
	assert_ne(refusal, "")
