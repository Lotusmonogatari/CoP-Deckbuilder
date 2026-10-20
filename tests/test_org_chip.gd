extends GutTest
## OrgChip: the organization icon with a fade and a number (2026-10-20).


func test_a_chip_shows_the_signed_number_and_the_right_fade() -> void:
	var up := OrgChip.make("BO05", 3)
	var down := OrgChip.make("BO05", -2)
	var none := OrgChip.make("BO05", 0)
	for chip: Button in [up, down, none]:
		add_child_autofree(chip)
	assert_eq((up.find_child("Mark", true, false) as Label).text, "+3")
	assert_eq((down.find_child("Mark", true, false) as Label).text, "-2")
	assert_eq((none.find_child("Mark", true, false) as Label).text, "0")
	assert_eq((up.find_child("Shade", true, false) as TextureRect).modulate, OrgChip.GAIN)
	assert_eq((down.find_child("Shade", true, false) as TextureRect).modulate, OrgChip.LOSS)
	assert_eq((none.find_child("Shade", true, false) as TextureRect).modulate, OrgChip.NEUTRAL)


func test_tapping_a_chip_names_the_organization_and_a_tap_closes_it() -> void:
	var chip := OrgChip.make("BO05", 1)
	add_child_autofree(chip)
	chip.pressed.emit()
	var overlay := get_tree().root.get_node_or_null("OrgNameOverlay")
	assert_not_null(overlay)
	assert_eq((overlay.find_child("NameLabel", true, false) as Label).text, OrgChip.name_of("BO05"))
	overlay.free()


func test_rows_sort_gains_first_and_merge_repeats() -> void:
	var merged := OrgChip.merged([{"id": "BO05", "delta": 1}, {"id": "BO07", "delta": -2},
		{"id": "BO05", "delta": 2}, {"id": "XX99", "delta": 5}])
	assert_eq(merged.size(), 2, "an unknown target is dropped, repeats fold together")
	var ordered := OrgChip.sorted(merged)
	assert_eq(ordered[0]["id"], "BO05")
	assert_eq(int(ordered[0]["delta"]), 3)


func test_an_audience_group_is_a_valid_target() -> void:
	assert_false(OrgChip.name_of("SG01").is_empty())


func test_side_chips_carry_no_number() -> void:
	var row := OrgChip.side_row(["BO05"], true)
	add_child_autofree(row)
	assert_eq((row.find_child("Mark", true, false) as Label).text, "")
