extends GutTest
## The plate under a party's name (panel P4, item 4): every party colour in the data reaches 4.5
## to 1 on its plate, and the colour itself is never changed.


func test_every_party_reaches_4_5_to_1_on_its_plate() -> void:
	for party: Dictionary in DataDB.parties:
		var colour := PartyDisplay.color_for(party)
		var plate := PartyDisplay.plate_for(colour)
		assert_gte(PartyDisplay.contrast(colour, plate), 4.5, "%s on its plate" % str(party.get("name", "")))


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
