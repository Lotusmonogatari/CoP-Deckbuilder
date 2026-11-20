extends GutTest
## Groups 2 and 3 of P14 (2026-11-20): the conversation screens and the Floor Vote take the style's dress without a node, text
## or signal changing; the party discs read the two new Parties columns; the stage outcome is a tagged card.

const STYLES := [UiStyles.WOODBLOCK, UiStyles.LIVING_OFFICE, UiStyles.BROADCAST]


func after_each() -> void:
	UiStyle.trying = ""


func test_the_disc_shows_the_first_kanji_not_the_kana() -> void:
	assert_eq(PartyDisc.kanji("仏党"), "仏")
	assert_eq(PartyDisc.kanji("エゾの遺産党"), "遺", "the kana in front are skipped")
	assert_eq(PartyDisc.kanji("辺境党"), "辺")
	assert_eq(PartyDisc.kanji("ABC"), "A", "no kanji: the first character")
	assert_eq(PartyDisc.kanji(""), "")


func test_the_initials_come_from_the_tab_or_the_name() -> void:
	assert_eq(PartyDisc.initials("YHP", "Yezo Heritage Party"), "YHP")
	assert_eq(PartyDisc.initials("", "Yezo Heritage Party"), "YHP")


func test_every_party_has_initials_and_a_japanese_name() -> void:
	assert_eq(DataDB.parties.size(), 6)
	for party: Dictionary in DataDB.parties:
		assert_false(str(party.get("short_name", "")).is_empty(), str(party.get("name", "")) + " has a Short Name")
		assert_false(PartyDisc.kanji(str(party.get("japanese_name", ""))).is_empty(), str(party.get("name", "")) + " has a Japanese Name")


func test_disc_lettering_reads_on_every_party_colour() -> void:
	for party: Dictionary in DataDB.parties:
		var fill := PartyDisplay.color_for(party)
		var ratio := PartyDisplay.contrast(PartyDisc.ink_on(fill), fill)
		assert_gte(ratio, 3.0, "%s: %.2f:1 (large lettering)" % [party.get("name", ""), ratio])


func test_a_conversation_button_is_dressed_in_every_style_and_keeps_its_state() -> void:
	for style: String in STYLES:
		UiStyle.trying = style
		var choice := Button.new()
		choice.custom_minimum_size = Vector2(0, 110)
		var way_on := Button.new()
		add_child_autofree(choice)
		add_child_autofree(way_on)
		var name := Label.new()
		add_child_autofree(name)
		ConversationStyles.dress(name, [choice], way_on)
		assert_eq(choice.custom_minimum_size.y, 110.0, style + ": the height the scene gave it is left alone (VisitLayout fits the picture to it)")
		var look := OfficeFrameStyles.look()
		assert_gte(IntentPill.contrast(look["ink"], look["card"]), 4.5, style + ": choice words on their fill")
		assert_gte(IntentPill.contrast(look["on_accent"], look["accent"]), 4.5, style + ": Continue words on their fill")
		way_on.disabled = true
		assert_not_null(way_on.get_theme_stylebox("disabled"), style + ": a disabled look exists")
