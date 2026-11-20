extends GutTest
## Reputation and Results on the shared frame (P13, 2026-11-20). One screen with six tabs replaces the menu of five buttons
## and the panels they opened. The Overview's values equal what the old Your Record page showed; every non-zero change is
## a button with only the signed number, and the reasons ("because of ...") appear only in the pop-up it opens; the Resign
## box sits at the top of the Overview while it is available (Cameron, 2026-11-20).

const STYLES := [UiStyles.WOODBLOCK, UiStyles.LIVING_OFFICE, UiStyles.BROADCAST]
const CAUSE := "Won the committee debate"


func before_each() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	UiStyle.trying = ""


func after_each() -> void:
	UiStyle.trying = ""


func _ids() -> Array:
	var out: Array = []
	for booster: Dictionary in DataDB.boosters:
		out.append(str(booster.get("booster_id", "")))
	return out


func _seed_moves() -> void:
	var ids := _ids()
	GameState.last_booster_change = {ids[0]: 2, ids[1]: -5, ids[2]: 5, ids[3]: 1}
	GameState.last_booster_cause = {ids[2]: [{"cause": CAUSE, "amount": 5}]}
	GameState.booster_standing[ids[2]] = 60


func _office() -> Control:
	var office := (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate() as Control
	add_child_autofree(office)
	return office


func _texts(root: Node) -> PackedStringArray:
	var out := PackedStringArray()
	for node: Node in root.find_children("*", "", true, false):
		if node is Label:
			out.append((node as Label).text)
		elif node is Button:
			out.append((node as Button).text)
	return out


# --- the pure picks ---------------------------------------------------------------------------------------------------

func test_the_biggest_moves_are_the_largest_changes_up_or_down() -> void:
	var picked := ReputationOverview.biggest_moves({"a": 2, "b": -5, "c": 5, "d": 1, "e": 0}, ["a", "b", "c", "d", "e"], 3)
	assert_eq(picked, ["b", "c", "a"], "5 down and 5 up tie, so data order decides; 2 is third; a zero never shows")


func test_nothing_that_did_not_move_is_a_move() -> void:
	assert_eq(ReputationOverview.biggest_moves({"a": 0}, ["a"], 3), [])
	assert_eq(ReputationOverview.biggest_moves({}, ["a", "b"], 3), [])


func test_the_latest_law_is_the_last_one_voted_on() -> void:
	assert_eq(ReputationOverview.latest_law([]), {})
	assert_eq(ReputationOverview.latest_law([{"bill_id": "BI01"}, {"bill_id": "BI02"}]), {"bill_id": "BI02"})


# --- the Overview's values equal the old page's ----------------------------------------------------------------------

func test_the_four_tiles_show_what_your_record_showed() -> void:
	GameState.last_meta_change = {"Reputation": -3, "Funds": 12000}
	var tiles := ReputationModel.tiles()
	assert_eq(tiles.size(), DataDB.sanban.size(), "one tile for each meta number")
	for tile: Dictionary in tiles:
		var name := str(tile["name"])
		var is_party := name == "Party support"
		var shown: Variant = GameState.party_support_effective() if is_party else GameState.meta.get(name, 0)
		assert_eq(tile["value"], Phrase.meta_amount(name, int(shown)), name + ": the number as the old page wrote it")
		var change := GameState.party_support_change_this_level() if is_party else int(GameState.last_meta_change.get(name, 0))
		assert_eq(int(tile["change"]), change, name + ": the change")
		assert_eq(tile["change_text"], Phrase.meta_amount(name, change, true) if change != 0 else "", name + ": only the signed number")


func test_the_moves_are_the_three_largest_and_carry_the_organizations_standing() -> void:
	_seed_moves()
	var ids := _ids()
	var moves := ReputationModel.moves()
	assert_eq(moves.size(), 3)
	assert_eq(str(moves[0]["id"]), ids[1], "-5 first (data order breaks the tie with +5)")
	assert_eq(str(moves[1]["id"]), ids[2])
	assert_eq(moves[1]["change_text"], "+5")
	assert_eq(int(moves[1]["standing"]), 60)
	assert_eq(moves[1]["node"], "StandingChange_" + ids[2])


func test_every_party_shows_the_opinion_score_the_parties_page_gives() -> void:
	var parties := ReputationModel.parties()
	assert_eq(parties.size(), DataDB.parties.size())
	for party: Dictionary in parties:
		assert_eq(int(party["score"]), int(GameState.party_opinion_detail(str(party["id"]))["opinion"]))


func test_the_latest_law_has_its_tally_and_your_vote() -> void:
	assert_eq(ReputationModel.latest_law({"vote_word": func(v: String) -> String: return v}), {}, "no law yet")
	var bill_id := str(DataDB.floor_votes.keys()[0])
	GameState.statute_book = [{"bill_id": bill_id, "passed": true, "yes": 60, "no": 38, "abstain": 3, "player_vote": "Yes"}]
	var law := ReputationModel.latest_law({"vote_word": func(v: String) -> String: return v})
	assert_true(bool(law["passed"]))
	assert_eq(law["tally"], Text.say("record.law_tally", {"yes": 60, "no": 38, "abstain": 3}))
	assert_eq(law["vote"], Text.say("record.law_voted", {"vote": "Yes"}))


# --- the screen -------------------------------------------------------------------------------------------------------

func test_there_are_six_tabs_and_each_builds_in_every_style() -> void:
	for style: String in STYLES:
		UiStyle.trying = style
		var office := _office()
		await get_tree().process_frame
		for tab: String in ["overview", "stakeholders", "backers", "parties", "election", "laws"]:
			office._show_reputation(tab)
			var menu := office.get_node("ReputationMenuPanel") as Overlay
			assert_true(menu.visible, "%s: %s opens" % [style, tab])
			assert_not_null(menu.find_child("FrameTab_" + tab, true, false), "%s: the %s tab exists" % [style, tab])
		office.queue_free()
		await get_tree().process_frame


func test_the_stakeholders_tab_lists_every_organization_with_its_change_button() -> void:
	_seed_moves()
	var office := _office()
	await get_tree().process_frame
	office._show_reputation("stakeholders")
	var menu := office.get_node("ReputationMenuPanel") as Overlay
	for id: String in _ids():
		var change := int(GameState.last_booster_change.get(id, 0))
		var button := menu.find_child("StandingChange_" + id, true, false) as Button
		if change == 0:
			assert_null(button, id + ": no button when nothing moved")
		else:
			assert_not_null(button, id + ": a button when it moved")
			assert_eq(button.text, "%+d" % change, "only the signed number")


func test_no_list_shows_the_reasons_only_the_pop_up_does() -> void:
	_seed_moves()
	var office := _office()
	await get_tree().process_frame
	for tab: String in ["overview", "stakeholders"]:
		office._show_reputation(tab)
		var menu := office.get_node("ReputationMenuPanel") as Overlay
		for text: String in _texts(menu):
			assert_false(text.contains(CAUSE), "%s: no reason in the list ('%s')" % [tab, text])
	office._show_reputation("overview")
	var menu := office.get_node("ReputationMenuPanel") as Overlay
	var button := menu.find_child("StandingChange_" + _ids()[2], true, false) as Button
	assert_not_null(button)
	button.pressed.emit()
	var popup := office.find_child("StandingFactorsPanel", true, false) as Overlay
	assert_true(popup.visible, "the change button opens the factors pop-up")
	var factors: Array[String] = []
	for node: Node in popup.find_children("StandingFactor", "Label", true, false):
		factors.append((node as Label).text)
	assert_eq(factors, [Text.say("office.stakeholder_factor", {"cause": CAUSE, "amount": "+5"})] as Array[String],
		"the same rows _open_factors has always built")
	assert_true(_texts(popup).has(Text.say("record.factors_standing", {"old": 55, "new": 60})), "it starts with where standing went")


func test_a_meta_change_button_opens_its_own_reasons() -> void:
	GameState.last_meta_change = {"Reputation": -3}
	GameState.last_meta_cause = {"Reputation": [{"cause": CAUSE, "amount": -3}]}
	var office := _office()
	await get_tree().process_frame
	office._show_reputation("overview")
	var menu := office.get_node("ReputationMenuPanel") as Overlay
	var button := menu.find_child("MetaChange_Reputation", true, false) as Button
	assert_not_null(button)
	assert_eq(button.text, "-3")
	button.pressed.emit()
	var popup := office.find_child("StandingFactorsPanel", true, false) as Overlay
	assert_true(popup.visible)
	assert_true(_texts(popup).has(Text.say("office.stakeholder_factor", {"cause": CAUSE, "amount": "-3"})))


func test_resign_is_the_first_box_while_it_is_available_and_absent_otherwise() -> void:
	var office := _office()
	await get_tree().process_frame
	office._show_reputation("overview")
	var menu := office.get_node("ReputationMenuPanel") as Overlay
	assert_eq(ResignRules.available(GameState.meta, DataDB.balance), menu.find_child("ResignBox", true, false) != null)
	GameState.meta["Reputation"] = 0
	GameState.meta["Party support"] = 0
	GameState.meta["Constituency support"] = 0
	assert_true(ResignRules.available(GameState.meta, DataDB.balance))
	office._show_reputation("overview")
	var box := menu.find_child("ResignBox", true, false)
	assert_not_null(box, "the Resign box shows")
	assert_eq(box.get_parent().get_child(0), box, "at the very top of the Overview")
	assert_eq(box.find_children("*", "Button", true, false).size(), 1, "one button in the box")
	assert_not_null(box.find_child("ResignButton", true, false), "the Office's own hold button")
	office._show_reputation("stakeholders")
	assert_null(menu.find_child("ResignBox", true, false), "only on the Overview")


func test_buying_a_backing_redraws_the_backers_tab() -> void:
	var office := _office()
	await get_tree().process_frame
	office._show_backing()
	var menu := office.get_node("ReputationMenuPanel") as Overlay
	assert_not_null(menu.find_child("FrameTab_backers", true, false))
	assert_true(menu.find_children("BackingCard_*", "", true, false).size() > 0, "backings are on offer")


func test_the_danger_box_reads_in_every_style() -> void:
	for style: String in STYLES:
		UiStyle.trying = style
		var look := OfficeFrameStyles.look()
		var wash: Color = (look["card"] as Color).lerp(look["down"], 0.12)
		assert_gte(IntentPill.contrast(look["down"], wash), 4.5, style + ": the Resign title on its wash")
		assert_gte(IntentPill.contrast(look["ink"], wash), 4.5, style + ": the hint on its wash")
