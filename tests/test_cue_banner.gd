extends GutTest
## The banner that throws a spoken line across the screen (CueBanner.gd).

var _banner: CueBanner


func before_each() -> void:
	_banner = CueBanner.new()
	_banner.speed = 0.01
	add_child_autofree(_banner)


func test_a_line_is_shown_straight_away() -> void:
	_banner.say(CueBanner.PLAYER, "Hiro", "The numbers do not lie.", "+4 seats")
	assert_true(_banner.is_showing())
	assert_eq(_banner.current_line(), "The numbers do not lie.")


func test_an_empty_line_says_nothing() -> void:
	_banner.say(CueBanner.PLAYER, "Hiro", "   ")
	assert_false(_banner.is_showing())


func test_lines_wait_their_turn_and_all_get_shown() -> void:
	_banner.say(CueBanner.PLAYER, "Hiro", "First.")
	_banner.say(CueBanner.OPPONENT, "Opponent", "Second.")
	assert_eq(_banner.current_line(), "First.", "the second does not cut the first short")
	await wait_until(func() -> bool: return _banner.lines_shown >= 2, 3.0)
	assert_eq(_banner.lines_shown, 2)
	assert_false(_banner.is_showing())


func test_skip_moves_on_to_the_next_line() -> void:
	_banner.say(CueBanner.PLAYER, "Hiro", "First.")
	_banner.say(CueBanner.PLAYER, "Hiro", "Second.")
	_banner.skip()
	assert_eq(_banner.current_line(), "Second.")


func test_clear_drops_everything() -> void:
	_banner.say(CueBanner.PLAYER, "Hiro", "First.")
	_banner.say(CueBanner.PLAYER, "Hiro", "Second.")
	_banner.clear()
	assert_false(_banner.is_showing())
	await wait_seconds(0.2)
	assert_false(_banner.is_showing(), "nothing comes back after a clear")
