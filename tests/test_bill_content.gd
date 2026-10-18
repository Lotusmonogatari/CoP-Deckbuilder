extends GutTest
## Content scoped to a bill (Bill ID column, 2026-10-18): questions, player
## cues, opponent cues and transition dialogue about a bill reach only that
## bill's level, and the player's lean picks between Support and Oppose lines.

var _saved := {}


func before_each() -> void:
	_saved = {
		"player_cues": DataDB.player_cues, "opponent_cues": DataDB.opponent_cues,
		"questions": DataDB.questions.duplicate(true),
	}


func after_each() -> void:
	DataDB.player_cues = _saved["player_cues"]
	DataDB.opponent_cues = _saved["opponent_cues"]
	DataDB.questions = _saved["questions"]
	DataDB._index_player_cues()
	DataDB._index_opponent_cues()
	DataDB._index_stage_questions()


func _cue(id: String, extra: Dictionary) -> Dictionary:
	var row := {"cue_id": id, "suit": "Earnest", "verb": "attack", "stage_ids": null,
		"cue_1": "line %s" % id, "cue_2": null, "cue_3": null, "cue_4": null, "cue_5": null,
		"bill_ids": null, "stance": null}
	row.merge(extra, true)
	return row


func test_bill_player_cues_never_leak_into_the_general_lookup() -> void:
	DataDB.player_cues = [_cue("PLX1", {"bill_ids": ["BI01"], "stance": "Oppose"})]
	DataDB._index_player_cues()
	assert_eq(DataDB.get_player_cue_lines("Earnest", "attack", ""), [])
	assert_eq(DataDB.get_bill_player_cue_lines("BI01", "Earnest", "attack", "Oppose").size(), 1)


func test_a_stance_row_beats_a_blank_stance_row_and_the_wrong_stance_is_skipped() -> void:
	DataDB.player_cues = [
		_cue("PLX1", {"bill_ids": ["BI01"], "stance": "Oppose"}),
		_cue("PLX2", {"bill_ids": ["BI01"], "stance": "Support"}),
		_cue("PLX3", {"bill_ids": ["BI01"]}),
	]
	DataDB._index_player_cues()
	assert_eq(DataDB.get_bill_player_cue_lines("BI01", "Earnest", "attack", "Oppose")[0]["text"], "line PLX1")
	assert_eq(DataDB.get_bill_player_cue_lines("BI01", "Earnest", "attack", "Support")[0]["text"], "line PLX2")
	assert_eq(DataDB.get_bill_player_cue_lines("BI01", "Earnest", "attack", "")[0]["text"], "line PLX3",
		"no lean taken: only the either-way line")
	assert_eq(DataDB.get_bill_player_cue_lines("BI02", "Earnest", "attack", "Oppose"), [])


func test_an_any_verb_bill_row_is_the_fallback_for_a_verb() -> void:
	DataDB.player_cues = [_cue("PLX4", {"bill_ids": ["BI01"], "verb": null})]
	DataDB._index_player_cues()
	assert_eq(DataDB.get_bill_player_cue_lines("BI01", "Earnest", "block", "Oppose").size(), 1)


func test_card_cues_use_the_bill_line_first_then_fall_back() -> void:
	DataDB.player_cues = [_cue("PLX1", {"bill_ids": ["BI01"], "stance": "Oppose"})]
	DataDB._index_player_cues()
	var card_id := ""
	for id: String in DataDB.card_cues.keys():
		if str(DataDB.get_card(id).get("suit", "")) == "Earnest":
			card_id = id
			break
	var applied := {"opponent_lost": 3}
	assert_eq(CardCues.for_card(card_id, "ST05", 1, applied, "BI01", "Oppose")["text"], "line PLX1")
	assert_ne(CardCues.for_card(card_id, "ST05", 1, applied, "", "")["text"], "line PLX1")
	assert_ne(CardCues.for_card(card_id, "ST05", 1, applied, "BI02", "Oppose")["text"], "line PLX1",
		"another bill's lines are not used")


func test_bill_opponent_cues_are_found_by_opponent_then_suit() -> void:
	DataDB.opponent_cues = [
		{"cue_id": "OCX1", "suit": "Earnest", "verb": "attack", "opponent_ids": ["OP01"], "stage_ids": null,
			"bill_ids": ["BI01"], "cue_1": "bespoke", "cue_2": null, "cue_3": null, "cue_4": null, "cue_5": null},
		{"cue_id": "OCX2", "suit": "Earnest", "verb": "attack", "opponent_ids": null, "stage_ids": null,
			"bill_ids": ["BI01"], "cue_1": "suit pool", "cue_2": null, "cue_3": null, "cue_4": null, "cue_5": null},
	]
	DataDB._index_opponent_cues()
	assert_eq(DataDB.get_bill_opponent_cue_lines("BI01", "OP01", "Earnest", "attack"), ["bespoke"])
	assert_eq(DataDB.get_bill_opponent_cue_lines("BI01", "OP02", "Earnest", "attack"), ["suit pool"])
	assert_eq(DataDB.get_bill_opponent_cue_lines("BI02", "OP01", "Earnest", "attack"), [])
	assert_eq(DataDB.get_bespoke_opponent_cue_lines("OP01", "attack", ""), [], "not in the general tiers")


func test_bill_questions_are_indexed_apart_from_stage_questions() -> void:
	# The real workbook now carries bill questions for BI01 too, so count
	# what the two fixture rows add.
	var base_all := DataDB.get_bill_questions("BI01").size()
	var base_st05 := BattleSetup.bill_questions_for("BI01", "ST05").size()
	var base_st17 := BattleSetup.bill_questions_for("BI01", "ST17").size()
	var rows: Array = DataDB.questions.get("stage", [])
	rows.append({"id": "ZB1", "text": "About the bill?", "theme": "x", "grades": {}, "bill_ids": ["BI01"], "stage_ids": []})
	rows.append({"id": "ZB2", "text": "In one room only", "theme": "x", "grades": {}, "bill_ids": ["BI01"], "stage_ids": ["ST05"]})
	DataDB.questions["stage"] = rows
	DataDB._index_stage_questions()
	assert_eq(DataDB.get_bill_questions("BI01").size(), base_all + 2)
	for q: Dictionary in DataDB.get_stage_questions("ST05"):
		assert_ne(q["id"], "ZB1")
	assert_eq(BattleSetup.bill_questions_for("BI01", "ST05").size(), base_st05 + 2)
	assert_eq(BattleSetup.bill_questions_for("BI01", "ST17").size(), base_st17 + 1, "the ST05-only one stays in ST05")
	assert_eq(BattleSetup.bill_questions_for("", "ST05"), [])


func _bill_question(n: int) -> Dictionary:
	return {"id": "B%d" % n, "text": "bill %d" % n, "grades": {"Earnest": "S"}, "bill_ids": ["BI01"]}


func test_the_engine_deals_bill_questions_up_to_their_share_only() -> void:
	var pool: Array = []
	for n in 12:
		pool.append({"id": "P%d" % n, "text": "room %d" % n, "grades": {"Earnest": "M"}})
	var bill: Array = []
	for n in 10:
		bill.append(_bill_question(n))
	var stage := TestFixtures.stage({"win_mode": "score", "questions_per_turn": 1, "turn_limit": 10, "player_start": 50})
	var config := TestFixtures.battle_config({"stage": stage})
	config["question_pool"] = pool
	config["question_pool_bill"] = bill
	config["bill_question_share_percent"] = 50
	var engine := BattleEngine.new()
	engine.setup(config)
	var about_bill := 0
	var total := 0
	while not engine.current_question().is_empty() and total < 20:
		if str(engine.current_question()["id"]).begins_with("B"):
			about_bill += 1
		total += 1
		engine.state.question_index += 1
	assert_eq(total, 10)
	assert_eq(about_bill, 5, "half of ten")


func test_a_room_with_only_bill_questions_asks_them_all() -> void:
	var bill: Array = []
	for n in 4:
		bill.append(_bill_question(n))
	var stage := TestFixtures.stage({"win_mode": "score", "questions_per_turn": 1, "turn_limit": 3, "player_start": 50})
	var config := TestFixtures.battle_config({"stage": stage})
	config["question_pool_bill"] = bill
	var engine := BattleEngine.new()
	engine.setup(config)
	assert_false(engine.current_question().is_empty())


func test_with_no_bill_questions_the_draw_is_what_it_always_was() -> void:
	var pool: Array = []
	for n in 6:
		pool.append({"id": "P%d" % n, "text": "room %d" % n, "grades": {}})
	var stage := TestFixtures.stage({"win_mode": "score", "questions_per_turn": 1, "turn_limit": 4, "player_start": 50})
	var a := TestFixtures.battle_config({"stage": stage})
	a["question_pool"] = pool
	a["seed"] = 7
	var b := a.duplicate(true)
	b["question_pool_bill"] = []
	var one := BattleEngine.new()
	one.setup(a)
	var two := BattleEngine.new()
	two.setup(b)
	assert_eq(one.current_question(), two.current_question())


func test_transition_dialogue_is_scoped_by_bill_and_stance() -> void:
	var rows := [
		{"character_id": "SF01", "stage_id": null, "character_line_en": "general", "player_reply_en": "r", "bill_id": null, "stance": null},
		{"character_id": "SF01", "stage_id": null, "character_line_en": "ainu oppose", "player_reply_en": "r", "bill_id": "BI01", "stance": "Oppose"},
		{"character_id": "SF01", "stage_id": null, "character_line_en": "ainu support", "player_reply_en": "r", "bill_id": "BI01", "stance": "Support"},
		{"character_id": "SF01", "stage_id": null, "character_line_en": "other bill", "player_reply_en": "r", "bill_id": "BI02", "stance": null},
	]
	var scoped := StageTransition.scope_dialogue(rows, "BI01", "Oppose")
	var lines: Array = scoped.map(func(r: Dictionary) -> String: return r["character_line_en"])
	assert_eq(lines, ["general", "ainu oppose"])
	var no_bill := StageTransition.scope_dialogue(rows, "", "")
	assert_eq(no_bill.size(), 1)
	var cast := [{"character_id": "SF01", "stage_id": null}]
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var picked := StageTransition.pick_speakers(cast, rows, "ST05", 1, rng, null, "BI01", "Oppose")
	assert_eq(picked[0]["character_line"], "ainu oppose", "the bill's line is preferred to the general one")
	var plain := StageTransition.pick_speakers(cast, rows, "ST05", 1, rng, null, "", "")
	assert_eq(plain[0]["character_line"], "general")


# ---------------------------------------------------------------------------
# The real workbook: every bill carries its own content (batch 4, 2026-10-18)
# ---------------------------------------------------------------------------

func test_every_real_bill_has_questions_cues_and_transition_lines() -> void:
	for bill_id: String in DataDB.floor_votes.keys():
		assert_gte(DataDB.get_bill_questions(bill_id).size(), 4, "%s has bill questions" % bill_id)
		for suit: String in ["Earnest", "Emotional", "Appeal", "Data Driven", "Divisive", "Duplicitous"]:
			for stance: String in ["Support", "Oppose"]:
				assert_false(DataDB.get_bill_player_cue_lines(bill_id, suit, "attack", stance).is_empty(),
					"%s %s %s has player cues" % [bill_id, suit, stance])
			for verb: String in ["attack", "gain", "block"]:
				assert_false(DataDB.get_bill_opponent_cue_lines(bill_id, "", suit, verb).is_empty(),
					"%s %s %s has opponent cues" % [bill_id, suit, verb])
		for stance: String in ["Support", "Oppose"]:
			var rows := StageTransition.scope_dialogue(DataDB.transition_dialogue, bill_id, stance)
			var bill_rows := rows.filter(func(r: Dictionary) -> bool:
				return str(r.get("bill_id", "")) == bill_id)
			assert_gte(bill_rows.size(), 4, "%s %s has transition lines" % [bill_id, stance])


func test_a_bill_levels_combat_stage_carries_its_bills_questions() -> void:
	GameState.start_new_run("PC04")
	var config := BattleSetup.for_level_stage("LV31", "ST05")
	assert_false((config.get("question_pool_bill", []) as Array).is_empty(),
		"the Town Hall in the Ainu level is handed the bill's questions")
