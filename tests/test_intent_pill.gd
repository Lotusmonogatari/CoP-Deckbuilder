extends GutTest
## The intent pill's colour (Cameron, 2026-11-17): the opponent's party colour when the opponent has a
## party that is not the player's; otherwise the default red, which must not be the Keizaijiyuutou red.

func _default_red() -> Color:
	return UiStyles.colour(UiStyles.index(DataDB.ui_styles), UiStyles.SHARED, "intent_default", Color.MAGENTA)


func _party_colour(name: String) -> Color:
	return PartyDisplay.color_for(DataDB.get_party(name))


func test_an_opponent_in_another_party_gets_that_partys_colour() -> void:
	var c := IntentPill.colour("Butsutou", "Frontier Party", _party_colour("Butsutou"), _default_red())
	assert_eq(c, _party_colour("Butsutou"))


func test_no_party_gets_the_default_red() -> void:
	assert_eq(IntentPill.colour("", "Frontier Party", Color.BLACK, _default_red()), _default_red())
	assert_eq(IntentPill.colour("  ", "Frontier Party", Color.BLACK, _default_red()), _default_red())


func test_the_players_own_party_gets_the_default_red() -> void:
	var c := IntentPill.colour("Frontier Party", "Frontier Party", _party_colour("Frontier Party"), _default_red())
	assert_eq(c, _default_red())


func test_the_default_red_is_not_the_keizaijiyuutou_red() -> void:
	var kj := _party_colour("Keizaijiyuutou")
	assert_ne(_default_red(), Color.MAGENTA, "the default red is in the workbook")
	assert_gt(IntentPill.distance(_default_red(), kj), 100.0, "well apart from Keizaijiyuutou's colour")
	assert_gt(absf(_default_red().r - kj.r) * 255.0 + absf(_default_red().b - kj.b) * 255.0, 100.0)


func test_the_default_red_matches_no_party_colour() -> void:
	for party: Dictionary in DataDB.parties:
		var c := PartyDisplay.color_for(party)
		assert_gt(IntentPill.distance(_default_red(), c), 55.0, "%s is not mistaken for the default red" % str(party.get("name")))


func test_the_ink_reads_on_every_pill_colour() -> void:
	var fills: Array[Color] = [_default_red()]
	for party: Dictionary in DataDB.parties:
		fills.append(PartyDisplay.color_for(party))
	for fill in fills:
		assert_gte(IntentPill.contrast(fill, IntentPill.ink_for(fill)), 4.5, "ink on %s" % fill.to_html(false))
