extends GutTest
## UiStyles (P9): the equipped package decides the style, Living Office is the
## free default, and the token index reads the workbook rows.

func _packages() -> Dictionary:
	return {
		"CP07": {"package_id": "CP07", "ui_style": "broadcast"},
		"CP08": {"package_id": "CP08", "ui_style": "woodblock"},
		"CP01": {"package_id": "CP01", "outfit_variant": "RED"},
	}


func test_no_package_is_living_office() -> void:
	assert_eq(UiStyles.current({}), UiStyles.LIVING_OFFICE)
	assert_eq(UiStyles.current(_packages()["CP01"]), UiStyles.LIVING_OFFICE)


func test_a_style_package_sets_the_style() -> void:
	assert_eq(UiStyles.current(_packages()["CP07"]), UiStyles.BROADCAST)
	assert_eq(UiStyles.current(_packages()["CP08"]), UiStyles.WOODBLOCK)


func test_owned_styles_always_include_living_office_once() -> void:
	var lookup := func(id: String) -> Dictionary: return _packages().get(id, {})
	assert_eq(UiStyles.owned_styles([], lookup), [UiStyles.LIVING_OFFICE])
	assert_eq(UiStyles.owned_styles(["CP01", "CP08", "CP07", "CP08"], lookup),
		[UiStyles.LIVING_OFFICE, UiStyles.WOODBLOCK, UiStyles.BROADCAST])


func test_ui_style_is_a_cosmetic_slot() -> void:
	assert_true(CosmeticPieces.SLOTS.has(CosmeticPieces.UI_STYLE))
	assert_true(CosmeticPieces.has_piece(_packages()["CP07"], CosmeticPieces.UI_STYLE))
	assert_false(CosmeticPieces.has_piece(_packages()["CP01"], CosmeticPieces.UI_STYLE))


func test_token_index_reads_rows_and_falls_back() -> void:
	var idx := UiStyles.index([
		{"style": "broadcast", "group": "colour", "token": "gold", "value": "#E3B341"},
		{"style": "broadcast", "group": "size_pt", "token": "body", "value": "15"},
	])
	assert_eq(UiStyles.colour(idx, "broadcast", "gold"), Color.html("#E3B341"))
	assert_eq(UiStyles.number(idx, "broadcast", "size_pt", "body"), 15.0)
	assert_eq(UiStyles.token(idx, "woodblock", "colour", "ink", "x"), "x")


func test_shipped_tokens_have_every_colour_the_plates_need() -> void:
	var idx := UiStyles.index(DataDB.ui_styles)
	for style: String in UiStyles.ALL:
		assert_ne(UiStyles.plate_colour(idx, style), Color(0.97, 0.94, 0.88) if style != UiStyles.WOODBLOCK else Color.MAGENTA)
		assert_ne(UiStyles.token(idx, style, "colour", "ground"), "", "%s has a ground colour" % style)


func test_unreadable_colour_gives_the_fallback() -> void:
	var idx := UiStyles.index([{"style": "living_office", "group": "colour", "token": "seat_opponent", "value": "party colour"}])
	assert_eq(UiStyles.colour(idx, "living_office", "seat_opponent", Color.RED), Color.RED)
