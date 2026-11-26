extends GutTest
## P22 (2026-11-26, Cameron): the campaign skin is scoped. A skinned build and a plain build in the same session never leak into each other; the party
## colour replaces only the accent family; every other part of the game keeps the player's look.


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	DataDB.rules["campaign_skin"] = "samurai"
	UiStyle.end_scope()


func after_each() -> void:
	UiStyle.end_scope()
	DataDB.rules["campaign_skin"] = "samurai"


func test_the_skin_is_only_in_force_between_begin_and_end() -> void:
	var plain := OfficeFrameStyles.look()
	assert_eq(str(plain["skin"]), "", "no skin before")
	assert_true(CampaignLook.begin())
	var skinned := OfficeFrameStyles.look()
	assert_eq(str(skinned["skin"]), CampaignSkin.SAMURAI)
	CampaignLook.end()
	var after := OfficeFrameStyles.look()
	assert_eq(str(after["skin"]), "", "no skin after")
	assert_eq(after["ground"], plain["ground"], "the player's look is exactly what it was")
	assert_eq(after["accent"], plain["accent"])


func test_inside_the_skin_every_style_dependent_shape_is_woodblocks() -> void:
	CampaignLook.begin()
	assert_eq(UiStyle.current(), UiStyles.WOODBLOCK)
	assert_true(bool(OfficeFrameStyles.look()["wood"]))
	CampaignLook.end()


func test_the_party_colour_replaces_the_accent_family_only() -> void:
	CampaignLook.begin()
	var party := CampaignLook.party_accent()
	assert_gt(party.a, 0.0, "the player has a party")
	assert_eq(UiStyle.colour("accent"), party)
	assert_eq(UiStyle.colour("tab_on"), party)
	assert_eq(UiStyle.colour("brief_accent"), party)
	assert_ne(UiStyle.colour("ink"), party, "ink is the skin's own")
	assert_eq(UiStyle.colour("phase_bar"), Color("#16130F"), "the phase bar is not in the family")
	CampaignLook.end()


func test_a_player_without_a_party_colour_keeps_the_skins_own_accent() -> void:
	UiStyle.begin_scope(CampaignSkin.SAMURAI, Color(0, 0, 0, 0))
	assert_eq(UiStyle.colour("accent"), Color("#A61E1E"), "vermilion is the fallback")
	UiStyle.end_scope()


func test_off_leaves_the_players_look() -> void:
	DataDB.rules["campaign_skin"] = "off"
	assert_false(CampaignLook.begin())
	assert_eq(UiStyle.scope, "")
	assert_eq(str(OfficeFrameStyles.look()["skin"]), "")


func test_gladiator_sets_the_capitals_the_numerals_and_its_own_ground() -> void:
	DataDB.rules["campaign_skin"] = "gladiator"
	CampaignLook.begin()
	var look := OfficeFrameStyles.look()
	assert_true(bool(look["caps"]))
	assert_eq(str(look["numerals"]), "roman")
	assert_eq(look["ground"], Color("#E6DCC6"))
	assert_eq(LevelBriefingStyles.title_text(look, "Campaign Office"), "CAMPAIGN OFFICE")
	assert_not_null(look["display_font"])
	CampaignLook.end()


func test_the_banner_art_and_nobori_colours_follow_the_party() -> void:
	# The player is Frontier (PT03): the three nobori are Frontier, Keizaijiyuutou and the Yezo Heritage Party.
	var colours := CampaignLook.nobori_colours()
	assert_eq(colours.size(), 3)
	assert_eq(colours[0], "#008000")
	assert_eq(colours[1], "#ff0000")
	assert_eq(colours[2], "#00ffff")
	CampaignLook.begin()
	assert_not_null(CampaignLook.banner(CampaignSkin.SAMURAI, "announcement", 1080.0))
	assert_not_null(CampaignLook.emblem(CampaignSkin.SAMURAI, 20.0))
	CampaignLook.end()


func test_the_phase_picks_the_skin_when_the_rule_says_phase() -> void:
	DataDB.rules["campaign_skin"] = "phase"
	for week in range(1, 400):
		GameState.calendar = {"week": week, "phase": "work", "hours": 0}
		if str(GameState.election_phase()["phase"]) == "campaign":
			assert_eq(CampaignLook.skin(), CampaignSkin.GLADIATOR)
			break
	GameState.calendar = {"week": 1, "phase": "work", "hours": 0}
	assert_eq(CampaignLook.skin(), CampaignSkin.SAMURAI)
