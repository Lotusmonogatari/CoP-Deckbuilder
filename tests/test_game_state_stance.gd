extends GutTest
## A bill level's stance in GameState (BillStance wired to the run), on the real
## LV31 / BI01 (Ainu Heritage and Language Act) played as PC04, a Country
## Initiative member whose party is Opposed to it: the example this feature
## was designed around.

var _saved: Dictionary = {}


func before_each() -> void:
	_saved = GameState.to_save()
	GameState.start_new_run("PC04")
	GameState.meta["Party support"] = 50
	for id: String in GameState.booster_standing:
		GameState.booster_standing[id] = 50


func after_each() -> void:
	GameState.load_save(_saved)


func _begin_lv31() -> void:
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV31"))))


func _win_next_stage() -> void:
	GameState.finish_stage(LevelRunner.WON)


func test_the_ainu_bill_has_ainu_groups_for_it_and_the_chamber_and_traditional_society_against() -> void:
	_begin_lv31()
	GameState.set_bill_lean("BI01", "Oppose")
	var sides := GameState.stance_sides()
	assert_true("BO28" in sides["supporters"] and "BO29" in sides["supporters"])
	assert_true("BO05" in sides["opponents"] and "BO15" in sides["opponents"])
	assert_false("BO01" in sides["supporters"] or "BO01" in sides["opponents"], "party bodies follow the party")


func test_winning_combat_stages_with_an_oppose_lean_pushes_the_sides_apart() -> void:
	_begin_lv31()
	GameState.set_bill_lean("BI01", "Oppose")
	_win_next_stage()   # ST07 Office Hours: not Combat, no drift
	assert_eq(GameState.booster_standing["BO28"], 50)
	_win_next_stage()   # ST05 Town Hall
	assert_eq(GameState.booster_standing["BO28"], 48)
	assert_eq(GameState.booster_standing["BO05"], 52)
	assert_eq(int(GameState.bill_stance["cost"]["BO28"]), 2)


func test_a_lost_stage_moves_nobody() -> void:
	_begin_lv31()
	GameState.set_bill_lean("BI01", "Oppose")
	_win_next_stage()
	GameState.finish_stage(LevelRunner.LOST)
	# The lost Town Hall ended the level, and an organization nobody dealt
	# with drifts one point toward where it started (neglect decay): that is
	# all that moved, not the stance's two.
	assert_eq(GameState.booster_standing["BO28"], 49)


func test_the_whole_ainu_example_with_a_switch_at_the_vote() -> void:
	_begin_lv31()
	GameState.set_bill_lean("BI01", "Oppose")
	for i in 4:
		_win_next_stage()   # Office Hours, Town Hall, committee, caucus
	assert_eq(GameState.booster_standing["BO28"], 44, "three Combat wins cost 6")
	assert_eq(GameState.booster_standing["BO05"], 56)
	var party_before: int = GameState.meta["Party support"]
	var result := GameState.apply_stance_vote("Yes")
	assert_true(result["flip"])
	assert_eq(GameState.booster_standing["BO28"], 47, "+2 for the vote, +1 recovered (25% of 6)")
	assert_eq(GameState.booster_standing["BO05"], 51, "-5 for the side you leave")
	assert_eq(GameState.booster_standing["BO15"], 51)
	assert_eq(GameState.meta["Party support"], party_before - 3, "Country Initiative opposes it")


func test_switching_toward_your_party_earns_one_party_support() -> void:
	_begin_lv31()
	GameState.set_bill_lean("BI01", "Support")   # against the party's Opposed
	var party_before: int = GameState.meta["Party support"]
	GameState.apply_stance_vote("No")            # back with the party
	assert_eq(GameState.meta["Party support"], party_before + 1)


func test_a_vote_that_matches_the_lean_is_no_flip() -> void:
	_begin_lv31()
	GameState.set_bill_lean("BI01", "Oppose")
	var party_before: int = GameState.meta["Party support"]
	var result := GameState.apply_stance_vote("No")
	assert_false(result["flip"])
	assert_eq(GameState.booster_standing["BO05"], 52)
	assert_eq(GameState.booster_standing["BO28"], 48)
	assert_eq(GameState.meta["Party support"], party_before)


func test_abstaining_moves_nobody_and_a_second_vote_is_ignored() -> void:
	_begin_lv31()
	GameState.set_bill_lean("BI01", "Oppose")
	GameState.apply_stance_vote("Abstain")
	assert_eq(GameState.booster_standing["BO28"], 50)
	assert_eq(GameState.apply_stance_vote("Yes"), {}, "the vote was already counted")


func test_without_a_lean_nothing_happens() -> void:
	_begin_lv31()
	_win_next_stage()
	_win_next_stage()
	assert_eq(GameState.booster_standing["BO28"], 50)
	assert_eq(GameState.apply_stance_vote("Yes"), {})


func test_rhetoric_pleasing_the_far_side_counts_less() -> void:
	_begin_lv31()
	GameState.set_bill_lean("BI01", "Oppose")
	var tally := {"BO28": {"pleased": 2, "displeased": 0, "opposed": 0},
		"BO05": {"pleased": 2, "displeased": 0, "opposed": 0}}
	var adjusted := GameState.stance_adjust_tally(tally)
	assert_eq(adjusted["BO28"]["pleased"], 1)
	assert_eq(adjusted["BO05"]["pleased"], 2)


func test_the_stance_survives_a_save_and_clears_when_the_level_ends() -> void:
	_begin_lv31()
	GameState.set_bill_lean("BI01", "Oppose")
	_win_next_stage()
	_win_next_stage()
	var saved := GameState.to_save()
	GameState.end_level()
	assert_eq(GameState.bill_stance, {})
	GameState.load_save(saved)
	assert_eq(GameState.stance_lean(), "Oppose")
	assert_eq(int(GameState.bill_stance["cost"]["BO28"]), 2)
	GameState.abandon_level()
	assert_eq(GameState.bill_stance, {})


func test_a_new_level_starts_without_a_stance() -> void:
	_begin_lv31()
	GameState.set_bill_lean("BI01", "Oppose")
	_begin_lv31()
	assert_eq(GameState.bill_stance, {})
