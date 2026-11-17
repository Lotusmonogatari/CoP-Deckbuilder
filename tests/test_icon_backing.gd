extends GutTest
## Every organization icon reads at 3 to 1 or better against the backing IconBacking picks for it
## (review of P9, finding on Broadcast's icons at 2.7 to 1): the backing follows the icon.

func test_light_icons_get_the_dark_backing_and_dark_icons_the_light_one() -> void:
	assert_false(IconBacking.use_light(0.6), "a light icon sits on the dark backing")
	assert_true(IconBacking.use_light(0.02), "a dark icon sits on the light backing")


func test_every_organization_icon_reads_three_to_one() -> void:
	var checked := 0
	for booster: Dictionary in DataDB.boosters:
		var id := str(booster.get("booster_id", ""))
		if not ResourceLoader.exists("res://assets/icons/%s.png" % id):
			continue
		var image := (load("res://assets/icons/%s.png" % id) as Texture2D).get_image()
		if image == null:
			continue
		var median := IconBacking.median_luminance(image)
		var best := IconBacking.contrast_with(median, IconBacking.backing_for(median))
		assert_gte(best, 3.0, "%s reads %.1f to 1 on its backing" % [id, best])
		checked += 1
	assert_gt(checked, 20, "most organization icons were checked")
