extends GutTest
## Tapping quickly through several cues used to freeze the white flash part-way
## through its fade and leave a haze on screen (2026-11-13).

func _banner() -> CueBanner:
	var banner := CueBanner.new()
	add_child_autofree(banner)
	return banner


func test_skipping_cues_quickly_leaves_no_haze() -> void:
	var banner := _banner()
	await get_tree().process_frame
	for i in 3:
		banner.say(CueBanner.PLAYER, "A", "Line %d" % i, "+1")
	await get_tree().create_timer(0.05).timeout
	for i in 3:
		banner.skip()
		await get_tree().create_timer(0.03).timeout
	await get_tree().create_timer(0.4).timeout
	assert_false(banner.is_showing())
	assert_eq(banner._flash.color.a, 0.0, "the flash is clear once the cues are gone")


func test_clearing_the_banner_leaves_no_haze() -> void:
	var banner := _banner()
	await get_tree().process_frame
	banner.say(CueBanner.OPPONENT, "B", "A line", "-1")
	await get_tree().create_timer(0.05).timeout
	banner.clear()
	assert_eq(banner._flash.color.a, 0.0)
