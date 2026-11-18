extends GutTest
## The plate under a party's name (panel P4, item 4): every party colour in the data reads at least 3 to 1
## on its plate (4.5 to 1 wherever the dark plate is used), and the colour itself is never changed.
## Pure red keeps the light plate at 3.6 to 1 (Cameron, 2026-11-18): black made it harder to read.


func test_every_party_reaches_3_to_1_on_its_plate_and_4_5_on_the_dark_one() -> void:
	for party: Dictionary in DataDB.parties:
		var colour := PartyDisplay.color_for(party)
		var plate := PartyDisplay.plate_for(colour)
		var needed := 3.0 if plate == PartyDisplay.PLATE_LIGHT else 4.5
		assert_gte(PartyDisplay.contrast(colour, plate), needed, "%s on its plate" % str(party.get("name", "")))


func test_red_gets_the_light_plate() -> void:
	assert_eq(PartyDisplay.plate_for(Color(1, 0, 0)), PartyDisplay.PLATE_LIGHT)


func test_the_plate_is_light_or_dark_never_a_new_hue() -> void:
	for party: Dictionary in DataDB.parties:
		var plate := PartyDisplay.plate_for(PartyDisplay.color_for(party))
		assert_true(plate == PartyDisplay.PLATE_LIGHT or plate == PartyDisplay.PLATE_DARK)


func test_a_party_label_keeps_the_party_colour() -> void:
	var party: Dictionary = DataDB.parties[0]
	var label := Label.new()
	PartyLabel.apply(label, party)
	assert_eq(label.get_theme_color("font_color"), PartyDisplay.color_for(party))
	assert_not_null(label.get_theme_stylebox("normal"))
	label.free()
