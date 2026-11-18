extends GutTest
## Your side of the bar takes your party's colour (2026-11-18).


func test_a_party_colour_is_used_and_none_falls_back() -> void:
	var blue := Color(0.36, 0.62, 0.85)
	assert_eq(SupportBar.player_fill(Color(0, 0.5, 0), blue), Color(0, 0.5, 0))
	assert_eq(SupportBar.player_fill(Color(0, 0, 0, 0), blue), blue)
