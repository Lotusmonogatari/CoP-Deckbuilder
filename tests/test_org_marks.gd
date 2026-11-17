extends GutTest
## The +/-/0 marks lie over the organization icons (review of P9, finding 1): in no style may a plaque or
## plate fill the whole icon. Woodblock's paper plaque on every label once covered the icons while a
## card was dragged ("0  0" and no icon).

func after_each() -> void:
	GameState.active_cosmetics.erase(CosmeticPieces.UI_STYLE)
	UiStyle.forget()
	Layout.apply_ui_style()


func _equip(style: String) -> void:
	var package := UiStyles.package_for(style, DataDB.cosmetic_packages)
	if not package.is_empty():
		var id := str(package["package_id"])
		if not GameState.owned_cosmetic_packages.has(id):
			GameState.owned_cosmetic_packages.append(id)
		GameState.equip_cosmetic(CosmeticPieces.UI_STYLE, id)
	else:
		GameState.equip_cosmetic(CosmeticPieces.UI_STYLE, "")
	UiStyle.forget()
	Layout.apply_ui_style()


func test_a_chip_mark_has_no_plaque_in_any_style() -> void:
	for style: String in UiStyles.ALL:
		_equip(style)
		var chip := OrgChip.make("BO01", 2)
		add_child_autofree(chip)
		var mark := chip.find_child("Mark", true, false) as Label
		assert_not_null(mark, style + ": the chip has a mark")
		assert_true(mark.get_theme_stylebox("normal") is StyleBoxEmpty, style + ": the mark carries no plaque")
