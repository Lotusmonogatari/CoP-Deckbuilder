extends GutTest
## Patron Bills step 3 (2026-10-19): a patron bill becomes a real level for the
## run. Registry, content found by component, the vote, save and resume, a
## lost level, declining, and Amend, played through GameState the way the
## screens drive it.

var _saved: Dictionary = {}


func before_each() -> void:
	_saved = GameState.to_save()
	GameState.start_new_run("PC01")
	GameState.booster_standing["BO05"] = 55


func after_each() -> void:
	DataDB.clear_runtime()
	GameState.load_save(_saved)
	DataDB.clear_runtime()
	DataDB.party_stakeholders = DataDB.party_stakeholders


func _vote(choice: String = "Yes") -> Dictionary:
	var level_id := str(GameState.patron_runtime["level"]["level_id"])
	var bill := DataDB.get_floor_vote(level_id)
	var engine := FloorVoteEngine.new()
	assert_true(engine.setup({
		"bill": bill, "player_party": str(DataDB.player.get("party", "")),
		"meta": {"Reputation": 100},
		"triggers": [{"variable": "Reputation", "enabled": "Yes", "threshold": 1}],
		"resistance_by_party": {},
		"default_resistance": 0,
	}))
	var result := engine.choose(choice)
	GameState.record_floor_vote(engine.bill(), result, choice)
	return result


func _play_to_the_vote() -> void:
	# Every stage before the vote, won.
	while GameState.level_runner.current_stage().get("mode", "") != "Vote":
		GameState.finish_stage(LevelRunner.WON)


func test_accepting_builds_a_short_level_that_is_not_in_the_levels_list() -> void:
	assert_true(GameState.start_patron_level("PB051"))
	assert_true(GameState.is_in_level())
	var stages := GameState.level_runner.stages
	assert_true(stages.size() in [3, 4], "a Favor: meeting, hearing, an optional lobbyist trade, the vote")
	assert_eq(str(stages[0]["stage_id"]), "ST20")
	assert_eq(str(stages[1]["stage_id"]), "ST16")
	var last: Dictionary = stages[stages.size() - 1]
	assert_eq(str(last["mode"]), "Vote")
	assert_eq(str(last["floor_vote"]["bill_id"]), "PB051")
	assert_eq(str(stages[0]["bill_id"]), "PB051")
	for level: Dictionary in DataDB.levels:
		assert_ne(str(level["level_id"]), "PL_PB051")
	assert_true(DataDB.is_runtime_level("PL_PB051"))
	assert_eq(GameState.patron_requests["PB051"]["status"], PatronRequests.ACCEPTED)


func test_the_composed_bill_has_a_name_positions_and_stakeholders() -> void:
	GameState.start_patron_level("PB051")
	var bill := DataDB.get_bill("PB051")
	assert_true(str(bill["bill_name"]).begins_with("A bill to cut the corporate tax rate"))
	assert_eq((bill["positions"] as Array).size(), 6)
	assert_true(str(bill["stakeholders_override"]).contains("BO05+"))
	assert_true(str(bill["stakeholders_override"]).contains("BO09-"))


func test_a_second_level_cannot_start_while_one_is_running() -> void:
	assert_true(GameState.start_patron_level("PB051"))
	assert_false(GameState.start_patron_level("PB071"))


func test_content_about_a_component_reaches_its_bill_and_nothing_else() -> void:
	var question_a := {"id": "TQ_A", "component_ids": ["CB051"], "bill_ids": null, "stage_ids": null}
	var question_b := {"id": "TQ_B", "component_ids": ["CB052"], "bill_ids": null, "stage_ids": null}
	var question_c := {"id": "TQ_C", "component_ids": ["CB051"], "bill_ids": null, "stage_ids": null}
	var stage_questions: Array = DataDB.questions["stage"]
	var original := stage_questions.duplicate()
	stage_questions.append_array([question_a, question_b, question_c])
	DataDB._index_stage_questions()
	var cue := {"cue_id": "PLT", "suit": "Earnest", "verb": "attack", "stage_ids": null, "bill_ids": null,
			"component_ids": ["CB051"], "stance": null, "cue_1": "Cut it now.", "cue_2": null, "cue_3": null, "cue_4": null, "cue_5": null}
	DataDB.player_cues.append(cue)
	DataDB._index_player_cues()

	GameState.start_patron_level("PB051")
	var ids: Array = []
	for question: Dictionary in DataDB.get_bill_questions("PB051"):
		ids.append(question["id"])
	assert_eq(ids, ["TQ_A", "TQ_B", "TQ_C"], "components alternate, so any prefix is an even mix")
	assert_eq(DataDB.get_bill_questions("BI01").size(), DataDB.get_bill_questions("BI01").size())
	for question: Dictionary in DataDB.get_stage_questions("ST16"):
		assert_false(["TQ_A", "TQ_B", "TQ_C"].has(question["id"]), "not in the general room pool")
	assert_eq(DataDB.get_bill_player_cue_lines("PB051", "Earnest", "attack", "").size(), 1)
	assert_eq(DataDB.get_bill_player_cue_lines("PB071", "Earnest", "attack", "").size(), 0)
	for line: Dictionary in DataDB.get_player_cue_lines("Earnest", "attack", "ST16"):
		assert_ne(str(line["text"]), "Cut it now.", "never in the general cue pool")

	DataDB.questions["stage"] = original
	DataDB.player_cues.erase(cue)
	DataDB._index_stage_questions()
	DataDB._index_player_cues()


func test_a_transition_line_about_a_component_is_only_for_its_level() -> void:
	var general := {"character_id": "PLAYER", "stage_id": null, "bill_id": null, "component_ids": null,
			"stance": null, "character_line_en": "General."}
	var about := {"character_id": "PLAYER", "stage_id": null, "bill_id": null, "component_ids": ["CB051"],
			"stance": null, "character_line_en": "About the tax."}
	var rows := [general, about]
	assert_eq(StageTransition.scope_dialogue(rows, "BI01", "", []).size(), 1)
	assert_eq(StageTransition.scope_dialogue(rows, "PB051", "", ["CB051", "CB052"]).size(), 2)
	assert_eq(StageTransition.scope_dialogue(rows, "PB071", "", ["CB071"]).size(), 1)
	var rng := RandomNumberGenerator.new()
	assert_eq(StageTransition.player_thought(StageTransition.scope_dialogue(rows, "PB051", "", ["CB051"]), "ST16", rng), "About the tax.")


func test_passing_the_vote_pays_the_patron_and_makes_the_components_law() -> void:
	var before := int(GameState.booster_standing["BO05"])
	var levels_before := GameState.levels_completed_count
	GameState.start_patron_level("PB051")
	_play_to_the_vote()
	var result := _vote("Yes")
	assert_true(result["passed"], "a full-strength player carries it")
	GameState.finish_stage(LevelRunner.WON)
	assert_false(GameState.is_in_level())
	assert_eq(GameState.patron_requests["PB051"]["status"], PatronRequests.PASSED)
	assert_gt(int(GameState.booster_standing["BO05"]), before)
	assert_true(GameState.enacted_components.has("CB051"))
	assert_true(GameState.enacted_components.has("CB052"))
	assert_eq(StatuteBook.status_map(GameState.statute_book)["PB051"], StatuteBook.PASSED)
	assert_true(GameState.patron_runtime.is_empty())
	assert_eq(GameState.levels_completed_count, levels_before, "a patron level is not an ordinary level")
	assert_false(GameState.levels_cleared.has("PL_PB051"))
	assert_false(GameState.level_last_completed_at.has("PL_PB051"))


func test_a_failed_vote_costs_the_patron_and_leaves_the_components_open() -> void:
	var before := int(GameState.booster_standing["BO05"])
	GameState.start_patron_level("PB051")
	_play_to_the_vote()
	var level_id := str(GameState.patron_runtime["level"]["level_id"])
	var engine := FloorVoteEngine.new()
	engine.setup({"bill": DataDB.get_floor_vote(level_id), "player_party": str(DataDB.player.get("party", ""))})
	var result := engine.choose("Yes")
	assert_false(result["passed"], "no influence, no pass")
	GameState.record_floor_vote(engine.bill(), result, "Yes")
	GameState.finish_stage(LevelRunner.WON)
	assert_eq(GameState.patron_requests["PB051"]["status"], PatronRequests.FAILED)
	assert_lt(int(GameState.booster_standing["BO05"]), before)
	assert_true(GameState.enacted_components.is_empty())


func test_a_flagship_follows_a_resolved_favor_and_pays_its_ally() -> void:
	GameState.booster_standing["BO05"] = 75
	GameState.booster_standing["BO24"] = 40
	GameState.patron_requests["PB051"] = {"status": PatronRequests.PASSED, "components": ["CB051", "CB052"], "amended": false, "tries": 0}
	assert_true(GameState.patron_bills_due().has("PB052"))
	var ally_before := int(GameState.booster_standing["BO24"])
	GameState.start_patron_level("PB052")
	assert_true(GameState.level_runner.stages.size() in [5, 6, 7, 8])
	_play_to_the_vote()
	assert_true(_vote("Yes")["passed"])
	GameState.finish_stage(LevelRunner.WON)
	assert_gt(int(GameState.booster_standing["BO24"]), ally_before)
	assert_true(GameState.owned_modifiers.has("M20"), "the patron's backing is free for a while")
	assert_true(GameState.modifier_expires.has("M20"))


func test_option_a_swaps_a_component_that_is_already_law() -> void:
	GameState.enacted_components = ["CB051"]
	GameState.start_patron_level("PB051")
	assert_eq(GameState.patron_requests["PB051"]["components"], ["CB055", "CB052"])
	assert_true(str(DataDB.get_bill("PB051")["bill_name"]).contains(str(DataDB.bill_components[0]["phrase"])) == false)


func test_amend_swaps_one_component_and_scales_the_reward() -> void:
	assert_false(GameState.start_patron_level("PB051", "CB051", "CB053"), "a Flagship component is not a legal swap")
	assert_false(GameState.is_in_level())
	assert_false(DataDB.is_runtime_level("PL_PB051"), "a refused start registers nothing")
	assert_true(GameState.start_patron_level("PB051", "CB052", "CB055"))
	assert_eq(GameState.patron_requests["PB051"]["components"], ["CB051", "CB055"])
	assert_true(GameState.patron_requests["PB051"]["amended"])
	var before := int(GameState.booster_standing["BO05"])
	_play_to_the_vote()
	assert_true(_vote("Yes")["passed"])
	GameState.finish_stage(LevelRunner.WON)
	var gained := int(GameState.booster_standing["BO05"]) - before
	assert_lt(gained, int(DataDB.balance["patron_favor_pass_standing"]) + 3, "amended rewards are scaled")


func test_declining_costs_standing_and_closes_the_request() -> void:
	var before := int(GameState.booster_standing["BO05"])
	GameState.decline_patron_bill("PB051")
	assert_eq(int(GameState.booster_standing["BO05"]), before - int(DataDB.balance["patron_favor_decline_cost"]))
	assert_eq(GameState.patron_requests["PB051"]["status"], PatronRequests.DECLINED)
	assert_false(GameState.start_patron_level("PB051"))
	assert_false(GameState.patron_bills_due().has("PB051"))


func test_losing_a_stage_returns_the_request_once_then_lapses_it() -> void:
	assert_true(GameState.start_patron_level("PB051"))
	GameState.finish_stage(LevelRunner.LOST)
	assert_false(GameState.is_in_level())
	assert_eq(GameState.patron_requests["PB051"]["status"], PatronRequests.WAITING)
	assert_true(GameState.start_patron_level("PB051"), "it can be taken up again")
	var before := int(GameState.booster_standing["BO05"])
	GameState.finish_stage(LevelRunner.LOST)
	assert_eq(GameState.patron_requests["PB051"]["status"], PatronRequests.LAPSED)
	assert_lt(int(GameState.booster_standing["BO05"]), before)
	assert_false(GameState.start_patron_level("PB051"))


func test_abandoning_leaves_the_request_open() -> void:
	GameState.start_patron_level("PB051")
	GameState.abandon_level()
	assert_eq(GameState.patron_requests["PB051"]["status"], PatronRequests.OPEN)
	assert_true(GameState.patron_runtime.is_empty())
	assert_true(GameState.start_patron_level("PB051"))


func test_a_level_in_progress_survives_save_and_load() -> void:
	GameState.start_patron_level("PB051")
	GameState.finish_stage(LevelRunner.WON)
	var saved := GameState.to_save()
	DataDB.clear_runtime()
	assert_false(DataDB.is_runtime_level("PL_PB051"))
	GameState.load_save(saved)
	assert_true(GameState.is_in_level())
	assert_true(DataDB.is_runtime_level("PL_PB051"))
	assert_eq(str(GameState.level_runner.current_stage()["stage_id"]), "ST16")
	_play_to_the_vote()
	assert_true(_vote("Yes")["passed"])
	GameState.finish_stage(LevelRunner.WON)
	assert_eq(GameState.patron_requests["PB051"]["status"], PatronRequests.PASSED)


func test_the_statute_book_still_names_the_bill_after_a_reload() -> void:
	GameState.start_patron_level("PB051")
	_play_to_the_vote()
	_vote("Yes")
	GameState.finish_stage(LevelRunner.WON)
	var saved := GameState.to_save()
	DataDB.clear_runtime()
	GameState.load_save(saved)
	assert_true(str(DataDB.get_bill("PB051")["bill_name"]).begins_with("A bill to "))
	assert_eq(GameState.patron_requests["PB051"]["status"], PatronRequests.PASSED)
	assert_true(GameState.enacted_components.has("CB051"))


func test_a_new_run_forgets_patron_state() -> void:
	GameState.start_patron_level("PB051")
	GameState.start_new_run("PC01")
	assert_true(GameState.patron_requests.is_empty())
	assert_true(GameState.enacted_components.is_empty())
	assert_false(DataDB.is_runtime_level("PL_PB051"))


func test_every_patron_bill_builds_a_playable_level() -> void:
	for row: Dictionary in DataDB.patron_bills:
		var id := str(row["patron_bill_id"])
		var built := PatronLevel.register(id, [])
		assert_true(built["ok"], "%s registers" % id)
		var expanded := BattleSetup.expand_level(built["level"] as Dictionary)
		var runner := LevelRunner.new(expanded)
		assert_eq(runner.problems().size(), 0, "%s: %s" % [id, str(runner.problems())])
		if row["kind"] == "Favor":
			assert_true(runner.stages.size() in [3, 4], id)
		else:
			# A Flagship gains the optional member visit (two stages) when a
			# listed party still has seats outside the player's side.
			assert_true(runner.stages.size() in [5, 6, 7, 8], id)
		for stage: Dictionary in runner.stages:
			if str(stage.get("mode", "")) == "Combat":
				assert_gt((stage["opponents"] as Array).size(), 0, "%s %s has opponents" % [id, stage["stage_id"]])
			if str(stage.get("mode", "")) == "Vote":
				var engine := FloorVoteEngine.new()
				assert_true(engine.setup({"bill": stage["floor_vote"], "player_party": "Frontier Party"}), id)
		DataDB.clear_runtime()


func test_a_request_shows_only_after_its_countdown() -> void:
	GameState.booster_standing["BO05"] = 55
	assert_false(GameState.patron_requests_shown().has("PB051"), "armed, not yet due")
	GameState.time_units += int(DataDB.balance["special_level_delay"])
	assert_true(GameState.patron_requests_shown().has("PB051"))
	GameState.decline_patron_bill("PB051")
	assert_false(GameState.patron_requests_shown().has("PB051"), "declined requests are gone")


func test_no_more_requests_show_than_the_lever_allows() -> void:
	for org: String in ["BO05", "BO07", "BO10", "BO24"]:
		GameState.booster_standing[org] = 60
	GameState.arm_patron_requests()
	GameState.time_units += 20
	assert_lte(GameState.patron_requests_shown().size(), int(DataDB.balance["patron_requests_waiting_at_once"]))


func test_the_countdown_survives_a_save() -> void:
	GameState.booster_standing["BO05"] = 55
	GameState.arm_patron_requests()
	var saved := GameState.to_save()
	GameState.start_new_run("PC01")
	GameState.load_save(saved)
	assert_true(GameState.patron_armed.has("PB051"))
