extends GutTest
## P22 (2026-11-26, Cameron): which skin each phase wears, the numerals, the party colours and the nobori recolouring.


func test_the_rule_chooses_the_skin() -> void:
	assert_eq(CampaignSkin.skin_for("building", "samurai"), CampaignSkin.SAMURAI)
	assert_eq(CampaignSkin.skin_for("campaign", "samurai"), CampaignSkin.SAMURAI, "Samurai always")
	assert_eq(CampaignSkin.skin_for("building", "gladiator"), CampaignSkin.GLADIATOR)
	assert_eq(CampaignSkin.skin_for("campaign", "off"), "", "off is the player's own look")
	assert_eq(CampaignSkin.skin_for("anything", "unknown"), CampaignSkin.SAMURAI)


func test_the_phase_value_gives_gladiator_only_in_the_campaign() -> void:
	for phase: String in ["building", "announcement", "mustering", "election_day"]:
		assert_eq(CampaignSkin.skin_for(phase, "phase"), CampaignSkin.SAMURAI, phase)
	assert_eq(CampaignSkin.skin_for("campaign", "phase"), CampaignSkin.GLADIATOR)


func test_numerals() -> void:
	assert_eq(CampaignSkin.numeral(0, "roman"), "0")
	assert_eq(CampaignSkin.numeral(1, "roman"), "I")
	assert_eq(CampaignSkin.numeral(2, "roman"), "II")
	assert_eq(CampaignSkin.numeral(3, "roman"), "III")
	assert_eq(CampaignSkin.numeral(2, "arabic"), "2")


func test_the_banners_three_parties_never_repeat_a_colour() -> void:
	assert_eq(CampaignSkin.banner_parties("PT03", ["PT05", "PT02"], "PT03"), ["PT03", "PT05", "PT02"])
	assert_eq(CampaignSkin.banner_parties("PT05", ["PT05", "PT02"], "PT03"), ["PT05", "PT03", "PT02"], "a Keizaijiyuutou player: the spare party stands in")
	assert_eq(CampaignSkin.banner_parties("PT02", ["PT05", "PT02"], "PT03"), ["PT02", "PT05", "PT03"], "a Yezo Heritage player too")


func test_the_nobori_cloths_are_recoloured_and_the_sun_is_not() -> void:
	var svg := FileAccess.get_file_as_string("res://assets/campaign/banner_announcement_samurai.svg")
	var out := CampaignSkin.recolour_nobori(svg, ["#111111", "#222222", "#333333"])
	assert_true(out.contains('height="360" fill="#111111"'))
	assert_true(out.contains('height="360" fill="#222222"'))
	assert_true(out.contains('height="360" fill="#333333"'))
	assert_true(out.contains('<circle cx="195" cy="170" r="92" fill="#A61E1E"'), "the sun stays vermilion")
	assert_eq(CampaignSkin.recolour_nobori("<svg/>", ["#111111", "#222222", "#333333"]), "<svg/>", "no cloths, no change")


func test_the_skin_tokens_are_in_the_data_and_a_skin_is_never_a_choice() -> void:
	var index := UiStyle.idx()
	for skin: String in CampaignSkin.STYLES:
		assert_eq(UiStyles.token(index, skin, "colour", "paper"), UiStyles.token(index, skin, "colour", "brief_card"), "the card ground")
		assert_gt(CampaignSkin.accent_family(index, skin).size(), 3)
		assert_false(UiStyles.ALL.has(skin), "never offered at New Game or in the Marketplace")
	assert_eq(UiStyles.token(index, CampaignSkin.GLADIATOR, "type", "numerals"), "roman")
	assert_eq(UiStyles.token(index, CampaignSkin.SAMURAI, "font", "display"), "Antaka Brush Display")
