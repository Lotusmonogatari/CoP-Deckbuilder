extends GutTest
## PartyDisplay.gd: a party's own r/g/b (data/parties.json) as a Color.


func test_color_for_reads_the_partys_own_rgb() -> void:
	var color := PartyDisplay.color_for({"r": 255, "g": 140, "b": 0})
	assert_almost_eq(color.r, 1.0, 0.01)
	assert_almost_eq(color.g, 140.0 / 255.0, 0.01)
	assert_almost_eq(color.b, 0.0, 0.01)


func test_color_for_an_unknown_party_is_a_visible_neutral_not_invisible() -> void:
	var color := PartyDisplay.color_for({})
	assert_eq(color, PartyDisplay.UNKNOWN_PARTY_COLOR)
	# Neither black nor white, so it never disappears against either
	# background this game uses.
	assert_gt(color.r, 0.0)
	assert_lt(color.r, 1.0)


func test_color_for_every_real_party_row_is_distinct_from_unknown() -> void:
	for party: Dictionary in DataDB.parties:
		var color := PartyDisplay.color_for(party)
		assert_ne(color, PartyDisplay.UNKNOWN_PARTY_COLOR,
			"%s's own colour should not coincide with the unknown-party fallback"
				% party.get("name", party.get("party_id", "?")))
