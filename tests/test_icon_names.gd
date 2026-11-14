extends GutTest
## Every Icon named in the Shop and Cosmetic Packages tabs is a real file in
## assets/icons/, spelled exactly (phones are case-sensitive). A blank Icon is
## allowed: that item simply has no picture yet and shows the blue square.

func _icon_files() -> Dictionary:
	var found := {}
	for file in DirAccess.get_files_at("res://assets/icons"):
		if file.ends_with(".png"):
			found[file.trim_suffix(".png")] = true
	return found


func test_shop_icons_name_real_files() -> void:
	var files := _icon_files()
	for item: Dictionary in DataDB.shop:
		var icon: Variant = item.get("icon")
		if icon == null or str(icon).strip_edges().is_empty():
			continue
		assert_true(files.has(str(icon)), "%s (%s) names icon '%s'" % [item.get("item_id"), item.get("name"), icon])


func test_cosmetic_icons_name_real_files() -> void:
	var files := _icon_files()
	for package: Dictionary in DataDB.cosmetic_packages:
		var icon: Variant = package.get("icon")
		if icon == null or str(icon).strip_edges().is_empty():
			continue
		assert_true(files.has(str(icon)), "%s names icon '%s'" % [package.get("package_id"), icon])


func test_the_regional_gift_icons_are_wired_to_their_items() -> void:
	var expected := {"SH25": "BOX_OF_AOMORI_APPLES", "SH26": "TSUGARU_LACQUER_CHOPSTICKS", "SH27": "DRIED_HOKKAIDO_SCALLOPS",
		"SH29": "WAKKANAI_MILK_CARAMELS", "SH30": "WHITE_CHOCOLATE_COOKIES", "SH31": "NEBUTA_FESTIVAL_HAND_TOWEL",
		"SH32": "BOTTLE_OF_DISTRICT_SAKE", "SH33": "HASKAP_YOITOMAKE", "SH34": "EXPANDED_BRIEFING_BINDER"}
	for id: String in expected:
		assert_eq(str(DataDB.get_shop_item(id).get("icon")), expected[id], "%s icon" % id)
