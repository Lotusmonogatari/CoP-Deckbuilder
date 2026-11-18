extends GutTest
## Organization icons all sit on the same chip (2026-11-18): one light colour at half strength.


func test_the_chip_is_one_light_half_see_through_colour() -> void:
	assert_eq(IconBacking.CHIP.a, 0.5)
	assert_gt(IconBacking.luminance(IconBacking.CHIP), 0.7, "a light chip")


func test_every_icon_gets_the_same_chip() -> void:
	var seen := {}
	for booster: Dictionary in DataDB.boosters:
		seen[ListeningStrip._backing_for(str(booster.get("booster_id", "")))] = true
	assert_eq(seen.size(), 1, "one chip for every organization")


## The seat ring still follows its seat's colour (dark round a light seat and the other way round).
func test_a_seat_ring_follows_the_seat_colour() -> void:
	assert_true(IconBacking.use_light(0.02))
	assert_false(IconBacking.use_light(0.6))
