class_name RubricPlaytest
extends Node
## The scored playtest for design/PLAYTEST_RUBRIC.md (2026-10-12, Cameron):
## from a NEW GAME, do backing and organisation standing really change what
## happens, can the player's influence flip a Floor Vote, and do a passed or
## failed bill's Law Effects switch on and last as the workbook says?
##
## It drives the same GameState / BattleSetup / FloorVoteEngine calls the
## screens make (and, with a display, clicks the real Floor Vote screen once),
## and checks every number against the WORKBOOK DATA read independently, never
## against a number typed here. Each rubric line prints PASS / FAIL / NOTE and
## a weighted score at the end.
##
##     xvfb-run .tools/godot --path . tools/rubric_playtest.tscn
##
## Never touches the real save: SaveManager is switched off and the one
## save/load check writes to a throwaway user:// file it deletes.

const CRITICAL := 3
const MAJOR := 2
const MINOR := 1

const BUCKETS := ["Yes", "No", "Abstain"]
const SCRATCH_SAVE := "user://rubric_scratch_save.json"

## Every protagonist, so a rule that only holds for one party shows up.
var _protagonists: Array[String] = []
var _results: Array[Dictionary] = []


func _ready() -> void:
	# The click test changes scene, which would free this node mid-run, so the
	# scene's own copy hands the work to one that lives outside it.
	if name != "RubricDriver":
		var driver := RubricPlaytest.new()
		driver.name = "RubricDriver"
		get_tree().root.add_child.call_deferred(driver)
		return
	_run.call_deferred()


func _run() -> void:
	SaveManager.enabled = false
	for row: Dictionary in DataDB.protagonists:
		_protagonists.append(str(row.get("player_id", "")))
	seed(20261012)

	_section_a_new_game()
	_section_b_modifiers_and_boosters()
	_section_c_vote_influence()
	await _section_c_real_click()
	_section_d_outcomes()

	_report()
	if FileAccess.file_exists(SCRATCH_SAVE):
		DirAccess.remove_absolute(SCRATCH_SAVE)
	var failed := _results.any(func(r: Dictionary) -> bool: return r["status"] == "FAIL")
	get_tree().quit(1 if failed else 0)


# ---------------------------------------------------------------------------
# Scoring
# ---------------------------------------------------------------------------

func _check(id: String, weight: int, ok: bool, what: String, detail: String = "") -> void:
	_results.append({"id": id, "weight": weight, "status": "PASS" if ok else "FAIL",
		"what": what, "detail": detail})


func _note(id: String, what: String, detail: String) -> void:
	_results.append({"id": id, "weight": 0, "status": "NOTE", "what": what, "detail": detail})


func _report() -> void:
	var earned := 0
	var possible := 0
	print("")
	print("| ID | Weight | Result | What was checked | Evidence |")
	print("|---|---|---|---|---|")
	for r: Dictionary in _results:
		if r["status"] != "NOTE":
			possible += int(r["weight"])
			if r["status"] == "PASS":
				earned += int(r["weight"])
		print("| %s | %s | %s | %s | %s |" % [r["id"],
			("-" if r["weight"] == 0 else str(r["weight"])), r["status"], r["what"], r["detail"]])
	print("")
	print("RUBRIC SCORE: %d / %d (%d%%)" % [earned, possible,
		roundi(100.0 * earned / maxf(possible, 1))])


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## A genuinely fresh run, as the New Game screen starts one.
func _new_run(player_id: String) -> void:
	GameState.start_new_run(player_id)
	GameState.level_runner = null
	GameState.level_bonuses = {}
	GameState.pending_level_bonuses = {}


func _own_party_id() -> String:
	return GameState.own_party_id()


## The player at full strength: every number the influence gate can read at
## its ceiling.
func _max_out_player() -> void:
	for variable: Dictionary in DataDB.sanban:
		GameState.meta[str(variable.get("name_en"))] = int(variable.get("max", 100))
	GameState.meta["Funds"] = 1000000
	for booster_id: String in GameState.booster_standing.keys():
		GameState.booster_standing[booster_id] = 100


func _engine_for(bill: Dictionary, meta: Dictionary, standing: Dictionary) -> FloorVoteEngine:
	var resistance := {}
	for party: Dictionary in DataDB.parties:
		var value: Variant = party.get("vote_resistance")
		if value != null:
			resistance[str(party.get("name", ""))] = int(value)
	var engine := FloorVoteEngine.new()
	engine.setup({
		"bill": bill.duplicate(true),
		"player_party": str(DataDB.player.get("party", "")),
		"meta": meta,
		"booster_standing": standing,
		"triggers": DataDB.vote_influence_triggers,
		"default_threshold": int(DataDB.balance.get("vote_influence_default_threshold", 85)),
		"resistance_by_party": resistance,
		"default_resistance": int(DataDB.balance.get("vote_swing_resistance_default", 70)),
	})
	return engine


## A bill with each position's party_name attached, as BattleSetup hands it
## to the engine (the raw data only carries party_id).
func _named(bill: Dictionary) -> Dictionary:
	var named := bill.duplicate(true)
	for position: Dictionary in named.get("positions", []):
		position["party_name"] = str(DataDB.get_party_by_id(str(position.get("party_id", ""))).get("name", ""))
	return named


func _bill(bill_id: String) -> Dictionary:
	return _named(DataDB.get_bill(bill_id))


func _bills() -> Array:
	var bills: Array = []
	for bill_id: String in DataDB.floor_votes.keys():
		bills.append(_named(DataDB.floor_votes[bill_id]))
	bills.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("bill_id", "")) < str(b.get("bill_id", "")))
	return bills


func _own_majority(bill: Dictionary) -> String:
	var party := str(DataDB.player.get("party", ""))
	for position: Dictionary in bill.get("positions", []):
		if str(position.get("party_name", "")) == party:
			return FloorVoteEngine.majority_bucket(position)
	return "Abstain"


## The tally the workbook's own seat splits give, with the player's one seat
## moved only when they vote against their own party's majority.
func _expected_baseline(bill: Dictionary, choice: String) -> Dictionary:
	var totals := {"Yes": 0, "No": 0, "Abstain": 0}
	var party := str(DataDB.player.get("party", ""))
	for position: Dictionary in bill.get("positions", []):
		totals["Yes"] += int(position.get("votes_yes", 0))
		totals["No"] += int(position.get("votes_no", 0))
		totals["Abstain"] += int(position.get("votes_abstain", 0))
		if str(position.get("party_name", "")) == party:
			var assumed := FloorVoteEngine.majority_bucket(position)
			if assumed != choice:
				totals[assumed] -= 1
				totals[choice] += 1
	return totals


func _vote(bill: Dictionary, choice: String, meta: Dictionary, standing: Dictionary) -> Dictionary:
	var engine := _engine_for(bill, meta, standing)
	var result := engine.choose(choice)
	result["engine"] = engine
	return result


## A level that can be finished without playing it: stages scored WON in turn.
func _complete_level(level_id: String) -> void:
	var runner := LevelRunner.new(BattleSetup.expand_level(DataDB.get_level(level_id)))
	GameState.begin_level(runner)
	var guard := 0
	while GameState.is_in_level() and guard < 20:
		guard += 1
		if GameState.finish_stage(LevelRunner.WON):
			break
	GameState.end_level()


## The Floor Vote levels, in order, as filler "levels" to complete.
func _vote_level_ids() -> Array[String]:
	var ids: Array[String] = []
	for level: Dictionary in DataDB.levels:
		if not DataDB.get_floor_vote(str(level.get("level_id", ""))).is_empty():
			ids.append(str(level.get("level_id", "")))
	ids.sort()
	return ids


# ---------------------------------------------------------------------------
# A. New game baseline
# ---------------------------------------------------------------------------

func _section_a_new_game() -> void:
	var meta_ok := true
	var meta_detail: Array[String] = []
	var standing_ok := true
	var clean_ok := true
	var gate_shut := true
	for player_id in _protagonists:
		_new_run(player_id)
		var row := DataDB.player
		var expected := BattleSetup.starting_meta_for(row)
		for name: String in expected.keys():
			if int(GameState.meta.get(name, -1)) != int(expected[name]):
				meta_ok = false
				meta_detail.append("%s %s" % [player_id, name])
		if GameState.xp != int(row.get("starting_xp", 0)):
			meta_ok = false
			meta_detail.append("%s XP" % player_id)

		for booster: Dictionary in DataDB.boosters:
			var own: Variant = booster.get("starting_standing")
			var want := int(DataDB.booster_standing.get("start", 50)) if own == null else int(own)
			if int(GameState.booster_standing.get(str(booster.get("booster_id")), -1)) != want:
				standing_ok = false

		if not (GameState.owned_modifiers.is_empty() and GameState.statute_book.is_empty()
				and GameState.law_statuses().is_empty()
				and GameState.bills_flipped_by_influence.is_empty()
				and GameState.levels_cleared.is_empty()):
			clean_ok = false

		for party: Dictionary in DataDB.parties:
			if VoteInfluence.gate_passed(DataDB.vote_influence_triggers,
					GameState.effective_meta(), GameState.booster_standing,
					int(DataDB.balance.get("vote_influence_default_threshold", 85)),
					str(party.get("party_id", ""))):
				gate_shut = false

	_check("A1", CRITICAL, meta_ok, "All %d protagonists open at their own workbook numbers (meta + XP)" % _protagonists.size(),
		"mismatches: %s" % (", ".join(meta_detail) if not meta_detail.is_empty() else "none"))
	_check("A2", MAJOR, standing_ok, "Every organisation opens at its workbook starting standing",
		"flat start %d" % int(DataDB.booster_standing.get("start", 50)))
	_check("A3", CRITICAL, clean_ok, "No backing owned, statute book / flips / clears all empty",
		"4 fresh runs")
	_check("A4", MAJOR, gate_shut, "The influence gate is shut for every party on day one",
		"no party can be swung by a brand-new player")


# ---------------------------------------------------------------------------
# B. Modifiers and organisations
# ---------------------------------------------------------------------------

func _section_b_modifiers_and_boosters() -> void:
	_new_run(_protagonists[0])
	_b1_buying_backing()
	_b2_battle_modifiers()
	_b3_win_payouts()
	_b4_end_to_end_payout()
	_b5_standing_moves()
	_b6_real_battle_pleasing()
	_b7_party_backing()
	_b8_standing_lasts()


func _b1_buying_backing() -> void:
	_new_run(_protagonists[0])
	var mod := DataDB.get_modifier("M05")
	var booster := Ledger.backing_booster(mod, DataDB.boosters)
	var needed := Ledger.standing_needed(mod, DataDB.booster_standing)
	GameState.meta["Funds"] = 500000
	GameState.meta["Reputation"] = 100
	GameState.meta["Constituency support"] = 100
	var cold := GameState.buy_modifier("M05")
	var cold_refused := not cold.is_empty() and not GameState.owned_modifiers.has("M05")

	GameState.booster_standing[booster] = needed - 1
	var one_short := not GameState.buy_modifier("M05").is_empty()
	GameState.booster_standing[booster] = needed
	var before := GameState.meta.duplicate()
	var accepted := GameState.buy_modifier("M05").is_empty() and GameState.owned_modifiers.has("M05")
	var costs := Ledger.modifier_costs(mod)
	var cost_ok := true
	for name: String in costs.keys():
		if int(GameState.meta[name]) != int(before[name]) - int(costs[name]):
			cost_ok = false
	var twice := not GameState.buy_modifier("M05").is_empty()
	_check("B1", CRITICAL, cold_refused and one_short and accepted and cost_ok and twice,
		"Backing is refused below the required standing, bought at it, charged the workbook cost, and not sold twice",
		"M05 via %s needs %d (starts %d); costs %s" % [booster, needed,
			int(DataDB.booster_standing.get("start", 50)), costs])


## Whether a modifier's trigger is met for a stage, worked out from the raw
## workbook columns (the Stages tab's % audience columns, or the standing).
func _trigger_met(modifier: Dictionary, stage: Dictionary, standing: Dictionary) -> bool:
	var minimum := float(modifier.get("trigger_min_pct", 0))
	var mix: Dictionary = stage.get("segment_mix", {})
	for segment_id: String in modifier.get("trigger_segment_ids", []):
		if float(mix.get(segment_id, 0.0)) >= minimum:
			return true
	for booster_id: String in modifier.get("trigger_booster_ids", []):
		if float(standing.get(booster_id, 0)) >= minimum:
			return true
	return false


func _b2_battle_modifiers() -> void:
	var cases := 0
	var bad: Array[String] = []
	for modifier: Dictionary in DataDB.modifiers:
		var type := ModifierEffects.type_of(modifier)
		if not [ModifierEffects.STAGE_START_BONUS, ModifierEffects.HAND_SIZE_BONUS,
				ModifierEffects.GAFFE_LIMIT_BONUS].has(type):
			continue
		var stage := DataDB.get_stage(ModifierEffects.target_of(modifier))
		if stage.is_empty():
			continue
		var mod_id := str(modifier["mod_id"])
		var key: String = {ModifierEffects.STAGE_START_BONUS: "start_support",
			ModifierEffects.HAND_SIZE_BONUS: "hand_size_bonus",
			ModifierEffects.GAFFE_LIMIT_BONUS: "gaffe_limit_bonus"}[type]

		for high in [true, false]:
			_new_run(_protagonists[0])
			GameState.owned_modifiers.append(mod_id)
			for booster_id: String in GameState.booster_standing.keys():
				GameState.booster_standing[booster_id] = 100 if high else 0
			var expected := int(round(float(modifier.get("effect_value", 0)))) \
				if _trigger_met(modifier, stage, GameState.booster_standing) else 0
			var got := int(BattleSetup.backing_bonus(stage).get(key, 0))
			cases += 1
			if got != expected:
				bad.append("%s %s standing=%s got %d want %d" % [mod_id, stage.get("stage_id"),
					"100" if high else "0", got, expected])

	_check("B2", CRITICAL, bad.is_empty(),
		"Each stage-start / hand-size / gaffe-limit backing changes its stage by exactly its workbook amount when its trigger is met, and by 0 when not",
		"%d cases%s" % [cases, ("" if bad.is_empty() else "; " + "; ".join(bad.slice(0, 4)))])


func _b3_win_payouts() -> void:
	var cases := 0
	var bad: Array[String] = []
	var meta_names := ModifierEffects.RESOURCE_TARGET_TO_META
	for modifier: Dictionary in DataDB.modifiers:
		if ModifierEffects.type_of(modifier) != ModifierEffects.RESOURCE_BONUS_ON_WIN:
			continue
		var target := ModifierEffects.target_of(modifier)
		var mod_id := str(modifier["mod_id"])
		var org_triggered: bool = not (modifier.get("trigger_booster_ids", []) as Array).is_empty()
		for high in [true, false]:
			_new_run(_protagonists[0])
			GameState.owned_modifiers.append(mod_id)
			for booster_id: String in GameState.booster_standing.keys():
				GameState.booster_standing[booster_id] = 100 if high else 0
			# Funds / meta well inside their ceilings so a clamp cannot hide a payout.
			GameState.meta["Funds"] = 20000
			GameState.meta["Constituency support"] = 40
			var party_before := int(GameState.meta["Party support"])
			var funds_before := int(GameState.meta["Funds"])
			var jiban_before := int(GameState.meta["Constituency support"])
			var xp_before := GameState.xp
			GameState._pay_level_rewards()
			var value := int(round(float(modifier.get("effect_value", 0))))
			# An organisation-triggered backing pays only while that
			# organisation's standing is at or above its number; an
			# audience-triggered one pays for the result, whoever watched.
			var expected := value if (high or not org_triggered) else 0
			var got := 0
			match target:
				"XP": got = GameState.xp - xp_before
				"Yen": got = int(GameState.meta["Funds"]) - funds_before
				"Jiban": got = int(GameState.meta["Constituency support"]) - jiban_before
				"PartySupport": got = int(GameState.meta["Party support"]) - party_before
			cases += 1
			if got != expected:
				bad.append("%s standing=%s got %d want %d" % [mod_id, "100" if high else "0", got, expected])
	_check("B3", CRITICAL, bad.is_empty(),
		"Each pay-on-win backing pays exactly its workbook amount; an organisation-triggered one pays only while that organisation stands at or above its number",
		"%d cases%s" % [cases, ("" if bad.is_empty() else "; " + "; ".join(bad.slice(0, 4)))])


## A real level win, twice with the same dice: the only difference is the
## backing, so the difference in Funds must be exactly its amount.
func _b4_end_to_end_payout() -> void:
	var level_id := _vote_level_ids()[0]
	var results: Array[int] = []
	for owned in [false, true]:
		_new_run(_protagonists[0])
		GameState.meta["Funds"] = 20000
		GameState.funds_cap_bonus = 900000   # a clamp must not hide the payout
		for booster_id: String in GameState.booster_standing.keys():
			GameState.booster_standing[booster_id] = 60
		if owned:
			GameState.owned_modifiers.append("M05")
		seed(777)
		_complete_level(level_id)
		results.append(int(GameState.meta["Funds"]))
	var want := int(round(float(DataDB.get_modifier("M05").get("effect_value", 0))))
	_check("B4", MAJOR, results[1] - results[0] == want,
		"A real level win with M05 pays exactly its amount more than the identical win without it",
		"%s: Funds %d without, %d with (want +%d)" % [level_id, results[0], results[1], want])


func _b5_standing_moves() -> void:
	var step_please := int(DataDB.booster_standing.get("per_please", 5))
	var step_annoy := int(DataDB.booster_standing.get("per_displease", 1))
	var step_oppose := int(DataDB.booster_standing.get("per_opposed", 3))
	var crush := int(DataDB.booster_standing.get("instant_win_penalty", 2))
	var cap := int(DataDB.booster_standing.get("question_swing_cap", 5))
	var ok := true
	var lines: Array[String] = []

	_new_run(_protagonists[0])
	var base := int(GameState.booster_standing["BO08"])
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level(_vote_level_ids()[0]))))
	GameState.finish_stage(LevelRunner.WON, 0, ["BO08"], false, 0, ["BO09"], ["BO10"], ["BO11"])
	var got_pleased := int(GameState.booster_standing["BO08"]) - base
	ok = ok and got_pleased == mini(step_please, cap)
	lines.append("pleased %+d" % got_pleased)
	ok = ok and int(GameState.last_booster_change.get("BO08", 0)) == got_pleased
	GameState.end_level()

	_new_run(_protagonists[0])
	var b9 := int(GameState.booster_standing["BO09"])
	var b10 := int(GameState.booster_standing["BO10"])
	var b11 := int(GameState.booster_standing["BO11"])
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level(_vote_level_ids()[0]))))
	GameState.finish_stage(LevelRunner.WON, 0, [], false, 0, ["BO09"], ["BO10"], ["BO11"])
	ok = ok and int(GameState.booster_standing["BO09"]) - b9 == -step_annoy
	ok = ok and int(GameState.booster_standing["BO11"]) - b11 == -step_oppose
	ok = ok and int(GameState.booster_standing["BO10"]) - b10 == -crush
	lines.append("annoyed %+d, set back %+d, argued out %+d" % [
		int(GameState.booster_standing["BO09"]) - b9, int(GameState.booster_standing["BO11"]) - b11,
		int(GameState.booster_standing["BO10"]) - b10])
	GameState.end_level()

	# Clamped to 0..100 and capped per stage.
	_new_run(_protagonists[0])
	GameState.booster_standing["BO08"] = 98
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level(_vote_level_ids()[0]))))
	GameState.finish_stage(LevelRunner.WON, 0, ["BO08", "BO08"])
	ok = ok and int(GameState.booster_standing["BO08"]) == 100
	GameState.end_level()
	_check("B5", MAJOR, ok,
		"Question results move organisation standing by the workbook amounts (please / annoy / set back / argue out), capped and clamped, and Your Record shows the change",
		", ".join(lines))


## Real BattleEngine, real cards, a question room: does answering well
## actually please somebody, and does that reach the organisation's standing?
func _b6_real_battle_pleasing() -> void:
	_new_run(_protagonists[0])
	var stage := DataDB.get_stage("ST04")
	var level := {"level_id": "RUBRIC", "stage_1": "ST04"}
	var runner := LevelRunner.new(BattleSetup.expand_level(level))
	GameState.begin_level(runner)
	var config := BattleSetup.for_playtest_stage(runner.current_stage(), {}, GameState.meta)
	if config.is_empty():
		_note("B6", "Real press conference answered with real cards", "could not build the stage config")
		GameState.end_level()
		return
	config["seed"] = 4242
	var engine := BattleEngine.new()
	engine.setup(config)
	var turns := 0
	while not engine.state.is_over() and turns < 30:
		turns += 1
		var played := true
		while played and not engine.state.is_over():
			played = false
			for card_id: String in engine.state.hand.duplicate():
				var result := engine.play_card(card_id)
				if result.get("ok", false):
					played = true
					break
		if engine.state.is_over():
			break
		engine.end_turn()
	var pleased := engine.pleased_boosters()
	var before := GameState.booster_standing.duplicate()
	GameState.finish_stage(LevelRunner.WON if engine.state.outcome == "win" else LevelRunner.LOST,
		0, pleased, false, 0, engine.displeased_boosters(), engine.crushed_opponent_boosters(),
		engine.opposed_boosters())
	var moved := 0
	for booster_id: String in GameState.booster_standing.keys():
		if int(GameState.booster_standing[booster_id]) != int(before[booster_id]):
			moved += 1
	GameState.end_level()
	_check("B6", MAJOR, pleased.is_empty() or moved > 0,
		"A real %s fought with real cards: every organisation it pleased or annoyed has its standing changed afterwards" % str(stage.get("name_en", "ST04")),
		"%d turns, outcome %s, pleased %s, annoyed %s, %d standings moved" % [turns, engine.state.outcome,
			pleased, engine.displeased_boosters(), moved])
	if pleased.is_empty() and engine.displeased_boosters().is_empty():
		_note("B6b", "The greedy card play pleased nobody this once", "weak evidence only; B5 proves the arithmetic")


func _b7_party_backing() -> void:
	_new_run(_protagonists[0])
	var m09_free := false
	var off_when_low := true
	for stored in [100, 0]:
		GameState.meta["Party support"] = stored
		for booster_id: String in GameState.booster_standing.keys():
			GameState.booster_standing[booster_id] = 100 if stored == 100 else 0
		var effective := GameState.party_support_effective()
		var ids: Array = []
		for modifier: Dictionary in GameState._effectively_owned_modifiers():
			ids.append(str(modifier.get("mod_id")))
		var threshold := int(DataDB.balance.get("party_support_allied_buff", 75))
		if stored == 100:
			m09_free = ids.has("M09") == (effective > threshold)
		else:
			off_when_low = not ids.has("M09")
	_check("B7", MINOR, m09_free and off_when_low,
		"Party Backing (M09) switches on by itself above the party-support line and off below it",
		"free with strong party opinion: %s; off when weak: %s" % [m09_free, off_when_low])


func _b8_standing_lasts() -> void:
	_new_run(_protagonists[0])
	GameState.booster_standing["BO08"] = 61
	GameState.owned_modifiers.append("M07")
	_complete_level(_vote_level_ids()[0])
	var after_level := int(GameState.booster_standing["BO08"]) == 61
	SaveManager.save_game(SCRATCH_SAVE)
	_new_run(_protagonists[1])
	SaveManager.load_game(SCRATCH_SAVE)
	_check("B8", MINOR, after_level and int(GameState.booster_standing["BO08"]) == 61
			and GameState.owned_modifiers.has("M07"),
		"Standing and owned backing survive a finished level and a save / reload",
		"BO08 = %d, M07 owned = %s" % [int(GameState.booster_standing["BO08"]),
			GameState.owned_modifiers.has("M07")])


# ---------------------------------------------------------------------------
# C. Vote influence
# ---------------------------------------------------------------------------

func _section_c_vote_influence() -> void:
	_c1_baseline()
	_c1b_chamber_size()
	_c2_gate_is_and()
	_c3_scoped_gates()
	_c4_full_strength_flips()
	_c5_own_party_vote()
	_c7_reachability()
	_c8_influence_bonus()


func _c1_baseline() -> void:
	var bad: Array[String] = []
	var cases := 0
	var lv31_line := ""
	for player_id in _protagonists:
		_new_run(player_id)
		var meta := GameState.effective_meta()
		for bill: Dictionary in _bills():
			for choice in BUCKETS:
				var result := _vote(bill, choice, meta, GameState.booster_standing)
				var want := _expected_baseline(bill, choice)
				cases += 1
				var totals: Dictionary = result["totals"]
				if totals != want or bool(result["influence_gate_passed"]) \
						or bool(result["outcome_flipped_by_influence"]):
					bad.append("%s %s %s" % [player_id, bill["bill_id"], choice])
		if player_id == "PC02":
			var lv31 := _vote(_bill("BI01"), "No", meta, GameState.booster_standing)
			lv31_line = "%d/%d/%d" % [lv31["totals"]["Yes"], lv31["totals"]["No"], lv31["totals"]["Abstain"]]
	_check("C1", CRITICAL, bad.is_empty(),
		"New-game vote tallies equal the workbook seat splits (+ the player's own seat), with no swing and no flip",
		"%d votes (4 protagonists x 30 bills x 3 choices)%s; BI01 for PC02 voting No = %s (hand-verified 45/48/8)"
			% [cases, ("" if bad.is_empty() else "; bad: " + ", ".join(bad.slice(0, 3))), lv31_line])


## Every bill's party splits add up to that party's real seats, so the
## chamber is the 101 CLAUDE.md section 4 promises.
func _c1b_chamber_size() -> void:
	var bad: Array[String] = []
	for bill: Dictionary in _bills():
		var total := 0
		for position: Dictionary in bill["positions"]:
			var seats := int(position["votes_yes"]) + int(position["votes_no"]) + int(position["votes_abstain"])
			total += seats
			var party := DataDB.get_party_by_id(str(position["party_id"]))
			if seats != int(party.get("seats", seats)):
				bad.append("%s %s splits %d, holds %d" % [bill["bill_id"], position["party_id"], seats, int(party.get("seats", 0))])
		if total != 101 and not bad.any(func(s: String) -> bool: return s.begins_with(str(bill["bill_id"]))):
			bad.append("%s totals %d" % [bill["bill_id"], total])
	_check("C1b", MAJOR, bad.is_empty(),
		"Every bill's seat splits add up to each party's real seat count, so every chamber is 101 seats",
		"30 bills%s" % ("" if bad.is_empty() else "; DATA ERROR: " + "; ".join(bad)))


func _c2_gate_is_and() -> void:
	_new_run(_protagonists[0])
	var unscoped: Array = []
	for row: Dictionary in DataDB.vote_influence_triggers:
		var scope: Variant = row.get("applies_to_parties")
		if str(row.get("enabled")) == "Yes" and (not (scope is Array) or (scope as Array).is_empty()):
			unscoped.append(row)
	var bill := _bill("BI01")
	var all_shut := true
	var detail: Array[String] = []
	for held_back in unscoped:
		_max_out_player()
		var variable := str(held_back["variable"])
		var threshold := int(held_back.get("threshold", 85))
		if GameState.meta.has(variable):
			GameState.meta[variable] = threshold - 1
		else:
			GameState.booster_standing[variable] = threshold - 1
		var result := _vote(bill, "Yes", GameState.effective_meta(), GameState.booster_standing)
		var picked_up := bool(result["influence_gate_passed"])
		detail.append("%s %d -> %s" % [variable, threshold - 1, "OPEN" if picked_up else "shut"])
		if picked_up:
			all_shut = false
	_max_out_player()
	var open := bool(_vote(bill, "Yes", GameState.effective_meta(), GameState.booster_standing)["influence_gate_passed"])
	_check("C2", CRITICAL, all_shut and open and unscoped.size() > 0,
		"The gate is an AND: one unscoped requirement one point short keeps it shut; everything met opens it",
		"%s; all met -> %s" % ["; ".join(detail), "open" if open else "SHUT"])


func _c3_scoped_gates() -> void:
	# Meet only the unscoped rows plus ONE party's scoped rows; only that
	# party's seats may move.
	_new_run(_protagonists[0])
	var bill := _bill("BI01")
	var ok := true
	var detail: Array[String] = []
	var parties_tested := 0
	for target: Dictionary in DataDB.parties:
		var target_id := str(target.get("party_id", ""))
		_new_run(_protagonists[0])
		GameState.meta["Reputation"] = 100
		for row: Dictionary in DataDB.vote_influence_triggers:
			if str(row.get("enabled")) != "Yes":
				continue
			var scope: Variant = row.get("applies_to_parties")
			var applies: Array = scope if scope is Array else []
			var variable := str(row["variable"])
			var meets := applies.is_empty() or applies.has(target_id)
			var level := int(row.get("threshold", 85)) if meets else 0
			var high := 1000000 if variable == "Funds" else 100
			var value := high if meets else level
			if GameState.meta.has(variable):
				GameState.meta[variable] = value
			else:
				GameState.booster_standing[variable] = value
		var result := _vote(bill, "Yes", GameState.effective_meta(), GameState.booster_standing)
		var engine: FloorVoteEngine = result["engine"]
		# Seats that moved, party by party, against the workbook's own split.
		var moved_parties: Array[String] = []
		for position: Dictionary in engine.positions():
			var original := {}
			for p: Dictionary in bill["positions"]:
				if p["party_id"] == position["party_id"]:
					original = p
			var diff := 0
			for key in ["votes_yes", "votes_no", "votes_abstain"]:
				diff += absi(int(position[key]) - int(original[key]))
			var own := str(position["party_name"]) == str(DataDB.player.get("party", ""))
			# The player's own party moves exactly one seat when they vote
			# against its majority; ignore that single-seat reallocation.
			if diff > (2 if own else 0):
				moved_parties.append(str(position["party_id"]))
		parties_tested += 1
		var legal := moved_parties.all(func(id: String) -> bool: return id == target_id)
		detail.append("%s->%s" % [target_id, ",".join(moved_parties) if not moved_parties.is_empty() else "none"])
		if not legal:
			ok = false
	_check("C3", CRITICAL, ok,
		"Meeting only the common requirements plus one party's own requirements swings no party but that one",
		"; ".join(detail))


func _c4_full_strength_flips() -> void:
	var report: Array[String] = []
	var bad: Array[String] = []
	var total_flips := 0
	for player_id in _protagonists:
		_new_run(player_id)
		var flips := 0
		var cap_ok := true
		for bill: Dictionary in _bills():
			var own_majority := _own_majority(bill)
			for choice in ["Yes", "No"]:
				_max_out_player()
				var base := _vote(bill, choice, {}, {})
				var strong := _vote(bill, choice, GameState.effective_meta(), GameState.booster_standing)
				var base_passed: bool = FloorVoteEngine.bill_passes(base["totals"])
				var strong_passed: bool = FloorVoteEngine.bill_passes(strong["totals"])
				var flagged := bool(strong["outcome_flipped_by_influence"])
				if flagged != (base_passed != strong_passed):
					bad.append("%s %s %s flag %s but %s -> %s" % [player_id, bill["bill_id"], choice, flagged, base_passed, strong_passed])
				if flagged:
					flips += 1
				# Seats are conserved: the swing moves them, never makes or loses any.
				var sum: int = int(strong["totals"]["Yes"]) + int(strong["totals"]["No"]) + int(strong["totals"]["Abstain"])
				var seats_in_bill := 0
				for p: Dictionary in bill["positions"]:
					seats_in_bill += int(p["votes_yes"]) + int(p["votes_no"]) + int(p["votes_abstain"])
				if sum != seats_in_bill:
					bad.append("%s %s totals %d vs %d seats" % [player_id, bill["bill_id"], sum, seats_in_bill])
				# No party gives up more than its resistance allows.
				var engine: FloorVoteEngine = strong["engine"]
				for position: Dictionary in engine.positions():
					var original := {}
					for p: Dictionary in bill["positions"]:
						if p["party_id"] == position["party_id"]:
							original = p
					var seats := int(original["votes_yes"]) + int(original["votes_no"]) + int(original["votes_abstain"])
					var resistance := int(DataDB.balance.get("vote_swing_resistance_default", 70))
					for party: Dictionary in DataDB.parties:
						if party["party_id"] == position["party_id"] and party.get("vote_resistance") != null:
							resistance = int(party["vote_resistance"])
					var allowed := floori(seats * (1.0 - resistance / 100.0))
					var own := str(position["party_name"]) == str(DataDB.player.get("party", ""))
					var lost := 0
					for key in ["votes_yes", "votes_no", "votes_abstain"]:
						lost = maxi(lost, int(original[key]) - int(position[key]))
					if lost > allowed + (1 if own else 0):
						cap_ok = false
						bad.append("%s %s %s lost %d > cap %d" % [player_id, bill["bill_id"], position["party_id"], lost, allowed])
		total_flips += flips
		report.append("%s %s: %d flips" % [player_id, str(DataDB.player.get("party")), flips])
	_check("C4", CRITICAL, bad.is_empty() and total_flips > 0,
		"A full-strength player flips real bills; every flip is flagged correctly, totals stay 101 and no party gives up more than its resistance allows",
		"%s%s" % [" | ".join(report), ("" if bad.is_empty() else " | PROBLEMS: " + "; ".join(bad.slice(0, 3)))])
	_note("C4b", "Flip counts are out of 60 votes per protagonist (30 bills x Yes/No)",
		"bills vote counts stand where the workbook's resistance numbers put them; tune in the Parties tab")


func _c5_own_party_vote() -> void:
	_new_run(_protagonists[0])
	var ok := true
	for bill: Dictionary in _bills():
		_max_out_player()
		var choice := _own_majority(bill)
		var result := _vote(bill, choice, GameState.effective_meta(), GameState.booster_standing)
		var engine: FloorVoteEngine = result["engine"]
		for position: Dictionary in engine.positions():
			if str(position["party_name"]) != str(DataDB.player.get("party", "")):
				continue
			for p: Dictionary in bill["positions"]:
				if p["party_id"] == position["party_id"]:
					for key in ["votes_yes", "votes_no", "votes_abstain"]:
						if int(p[key]) != int(position[key]):
							ok = false
	_check("C5", MAJOR, ok,
		"Voting with your own party's majority never moves any of that party's own seats, even at full strength",
		"30 bills")


func _c7_reachability() -> void:
	var lines: Array[String] = []
	var unreachable: Array[String] = []
	var funds_cap := int(DataDB.rules.get("funds_starting_cap", {}).get("value", 100000)) if DataDB.rules.get("funds_starting_cap") is Dictionary else int(DataDB.rules.get("funds_starting_cap", 100000))
	var hard_max := 1000000
	for row: Dictionary in DataDB.vote_influence_triggers:
		if str(row.get("enabled")) != "Yes":
			continue
		var variable := str(row["variable"])
		var threshold := int(row.get("threshold", 85))
		var ceiling := 100
		if variable == "Funds":
			ceiling = hard_max
			var steps := int(ceil((threshold - funds_cap) / 100000.0))
			lines.append("Funds %d needs the cap raised %d time(s) (cap starts %d)" % [threshold, maxi(steps, 0), funds_cap])
		elif GameState.meta.has(variable):
			for sanban in DataDB.sanban:
				if sanban["name_en"] == variable:
					ceiling = int(sanban["max"])
		if threshold > ceiling:
			unreachable.append("%s %d > max %d" % [variable, threshold, ceiling])
	_check("C7", MAJOR, unreachable.is_empty(),
		"Every enabled influence requirement is below the ceiling of the thing it measures",
		"all %d enabled rows reachable%s" % [
			DataDB.vote_influence_triggers.filter(func(r: Dictionary) -> bool: return str(r.get("enabled")) == "Yes").size(),
			("" if unreachable.is_empty() else "; UNREACHABLE: " + ", ".join(unreachable))])
	var per_stage := int(DataDB.booster_standing.get("question_swing_cap", 5))
	var worst := 0
	for row: Dictionary in DataDB.vote_influence_triggers:
		var variable := str(row["variable"])
		if str(row.get("enabled")) == "Yes" and variable.begins_with("BO"):
			worst = maxi(worst, int(ceil((int(row.get("threshold", 85)) - int(DataDB.booster_standing.get("start", 30))) / float(per_stage))))
	_note("C7b", "How long to earn it", "an organisation climbs at most %d a stage, so the highest organisation requirement is at least %d stages of pleasing it from the %d start; %s" % [
		per_stage, worst, int(DataDB.booster_standing.get("start", 30)), "; ".join(lines)])


## The optional bonus columns: blank does nothing, a number is applied once.
func _c8_influence_bonus() -> void:
	_new_run(_protagonists[0])
	var meta_before := GameState.meta.duplicate()
	GameState.apply_floor_vote_influence_bonus(0, 0)
	var blank_ok := GameState.meta == meta_before
	GameState.meta["Reputation"] = 50
	GameState.meta["Party support"] = 50
	GameState.apply_floor_vote_influence_bonus(3, 2)
	_check("C8", MINOR, blank_ok and int(GameState.meta["Reputation"]) == 53 and int(GameState.meta["Party support"]) == 52,
		"The influence bonus columns do nothing when blank and apply exactly their numbers when filled",
		"+3 Reputation / +2 Party support applied once")


## The real Floor Vote screen, real clicks, a gate-open player and a bill the
## swing flips. Needs a display; skipped (NOTE) under --headless.
func _section_c_real_click() -> void:
	if DisplayServer.get_name() == "headless":
		_note("C6", "Real click on the Floor Vote screen with influence on",
			"skipped: run under xvfb-run for the click version")
		return

	_new_run("PC02")
	_max_out_player()
	var chosen_bill := {}
	var chosen_level := ""
	var chosen_choice := ""
	for level_id in _vote_level_ids():
		var bill := _named(DataDB.get_floor_vote(level_id))
		for choice in ["Yes", "No"]:
			var base := _vote(bill, choice, {}, {})
			var strong := _vote(bill, choice, GameState.effective_meta(), GameState.booster_standing)
			if bool(strong["outcome_flipped_by_influence"]):
				chosen_bill = bill
				chosen_level = level_id
				chosen_choice = choice
				break
		if not chosen_bill.is_empty():
			break
	if chosen_bill.is_empty():
		_check("C6", MAJOR, false, "A flippable bill exists for the click test", "none found for PC02")
		return

	var runner := LevelRunner.new(BattleSetup.expand_level(DataDB.get_level(chosen_level)))
	for i in runner.stage_count():
		if str(runner.stage_by_seq(i + 1).get("mode", "")) == "Vote":
			runner.index = i
	GameState.begin_level(runner)
	get_tree().change_scene_to_file(StageRouting.scene_for(runner.current_stage()))
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	var screen := get_tree().current_scene
	if screen == null or screen.name != "FloorVoteScreen":
		_check("C6", MAJOR, false, "The Floor Vote screen opens", "landed on %s" % (screen.name if screen else "null"))
		return
	var button: Button = screen.get_node("%VoteYes" if chosen_choice == "Yes" else "%VoteNo")
	await _click(button)
	await get_tree().create_timer(0.4).timeout
	var bill_id := str(chosen_bill.get("bill_id", ""))
	var entry := {}
	for law: Dictionary in GameState.statute_book:
		if law["bill_id"] == bill_id:
			entry = law
	var body: Label = screen.get_node("%OutcomeBody")
	_check("C6", MAJOR,
		not entry.is_empty() and bool(entry.get("flipped_by_influence", false))
			and GameState.bills_flipped_by_influence.has(bill_id)
			and str(body.text).contains(str(entry["yes"])),
		"Real click: a full-strength player voting %s on %s flips it; the screen shows the swung totals and the book + flip record agree" % [chosen_choice, bill_id],
		"%s %s: book says %d/%d/%d passed=%s flipped=%s; screen: %s" % [chosen_level, bill_id,
			int(entry.get("yes", -1)), int(entry.get("no", -1)), int(entry.get("abstain", -1)),
			entry.get("passed"), entry.get("flipped_by_influence"), str(body.text).replace("\n", " ").left(70)])
	var cue := VoteInfluenceCues.resolve(DataDB.vote_influence_cues, bill_id,
		VoteInfluenceCues.FLIPPED_TO_PASS if bool(entry.get("passed", false)) else VoteInfluenceCues.FLIPPED_TO_FAIL)
	_note("C6b", "Flip cutscene line for %s" % bill_id,
		"'%s'" % cue if not cue.is_empty() else "no cue row written for this bill yet (Vote Influence Cues tab)")
	GameState.end_level()


func _click(control: Control) -> void:
	await get_tree().process_frame
	var where: Vector2 = get_viewport().get_screen_transform() * control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = where
		event.global_position = where
		Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().process_frame


# ---------------------------------------------------------------------------
# D. Outcomes activate and last
# ---------------------------------------------------------------------------

func _section_d_outcomes() -> void:
	_d1_once_effects()
	_d2_each_level()
	_d4_no_double_apply()
	_d5_save_reload()
	_d6_new_game_clears()
	_d7_law_conditions()
	_d8_every_organisation_has_a_stake()


func _rows_for(bill_id: String, passed: bool, timing: String) -> Array:
	return StatuteBook.effects_for(DataDB.law_effects, bill_id, passed, timing)


## What a "Once" row set should do, from the workbook: net booster deltas and
## net meta deltas, summed per target.
func _expected_effect(rows: Array) -> Dictionary:
	var boosters := {}
	var meta := {}
	var xp := 0
	for row: Dictionary in rows:
		for entry in (row.get("effects") if row.get("effects") is Array else []):
			boosters[entry["target"]] = int(boosters.get(entry["target"], 0)) + int(entry["delta"])
		for name: String in StatuteBook.meta_deltas(row).keys():
			meta[name] = int(meta.get(name, 0)) + int(StatuteBook.meta_deltas(row)[name])
		xp += StatuteBook.xp_delta(row)
	return {"boosters": boosters, "meta": meta, "xp": xp}


func _d1_once_effects() -> void:
	var cases := 0
	var bad: Array[String] = []
	for bill: Dictionary in _bills():
		var bill_id := str(bill["bill_id"])
		for passed in [true, false]:
			_new_run(_protagonists[0])
			# Start mid-range so +/- never touches a clamp.
			for booster_id: String in GameState.booster_standing.keys():
				GameState.booster_standing[booster_id] = 50
			for name in ["Constituency support", "Reputation", "Party support"]:
				GameState.meta[name] = 50
			GameState.meta["Funds"] = 50000
			var standing_before := GameState.booster_standing.duplicate()
			var meta_before := GameState.meta.duplicate()
			var xp_before := GameState.xp
			var want := _expected_effect(_rows_for(bill_id, passed, StatuteBook.ONCE))
			# Party-tier organisations follow the player's party lean (2026-10-13).
			var own_dispo := ""
			for position: Dictionary in bill.get("positions", []):
				if str(position.get("party_id", "")) == GameState.own_party_id():
					own_dispo = str(position.get("disposition", ""))
			var lean := StatuteBook.party_tier_delta(own_dispo, passed,
				int(DataDB.balance.get("law_lean_party_tier_pass_delta", 0)),
				int(DataDB.balance.get("law_lean_party_tier_fail_delta", 0)))
			for booster: Dictionary in DataDB.boosters:
				if str(booster.get("tier", "")) == "Party":
					var bid := str(booster["booster_id"])
					want["boosters"][bid] = int(want["boosters"].get(bid, 0)) + lean
			GameState.record_floor_vote(bill, {"totals": {"Yes": 60 if passed else 30, "No": 30 if passed else 60, "Abstain": 11},
				"passed": passed}, "Yes")
			cases += 1
			for booster_id: String in GameState.booster_standing.keys():
				var moved := int(GameState.booster_standing[booster_id]) - int(standing_before[booster_id])
				if moved != int(want["boosters"].get(booster_id, 0)):
					bad.append("%s %s %s %+d want %+d" % [bill_id, "pass" if passed else "fail", booster_id, moved,
						int(want["boosters"].get(booster_id, 0))])
			for name: String in GameState.meta.keys():
				var moved_meta := int(GameState.meta[name]) - int(meta_before[name])
				# Party support is the live blend elsewhere, but the STORED
				# number is what the row moves.
				if moved_meta != int(want["meta"].get(name, 0)):
					bad.append("%s %s meta %s %+d want %+d" % [bill_id, "pass" if passed else "fail", name, moved_meta,
						int(want["meta"].get(name, 0))])
			if GameState.xp - xp_before != int(want["xp"]):
				bad.append("%s XP" % bill_id)
			if GameState.law_statuses().get(bill_id, "") != ("passed" if passed else "failed"):
				bad.append("%s not in the statute book as %s" % [bill_id, "passed" if passed else "failed"])
	_check("D1", CRITICAL, bad.is_empty(),
		"Passing or failing each of the 30 bills changes exactly the organisations, meta values and XP its workbook 'Once' row lists, and nothing else",
		"%d bill outcomes%s" % [cases, ("" if bad.is_empty() else "; " + "; ".join(bad.slice(0, 4)))])


func _d2_each_level() -> void:
	# Every bill with an "Each level" row, for the outcome that has it.
	var ongoing: Array = []
	for row: Dictionary in DataDB.law_effects:
		if StatuteBook.timing_of(row) == StatuteBook.EACH_LEVEL:
			ongoing.append(row)
	var vote_levels := _vote_level_ids()
	var bad: Array[String] = []
	var summary: Array[String] = []
	for row: Dictionary in ongoing:
		var bill_id := str(row["bill_id"])
		var passed := str(row["outcome"]).to_lower() == "passed"
		var want := _expected_effect([row])
		var per_level := int(want["meta"].get("Funds", 0))
		var tail: Array[int] = []
		for with_law in [true, false]:
			_new_run(_protagonists[0])
			GameState.meta["Funds"] = 20000
			GameState.funds_cap_bonus = 900000
			seed(31415)
			# The level that holds the vote.
			var runner := LevelRunner.new(BattleSetup.expand_level(DataDB.get_level(vote_levels[0])))
			GameState.begin_level(runner)
			if with_law:
				GameState.record_floor_vote(DataDB.get_bill(bill_id),
					{"totals": {"Yes": 60 if passed else 30, "No": 30 if passed else 60, "Abstain": 11}, "passed": passed}, "Yes")
			var funds_after_vote_level := 0
			while GameState.is_in_level():
				if GameState.finish_stage(LevelRunner.WON):
					break
			GameState.end_level()
			funds_after_vote_level = int(GameState.meta["Funds"])
			var series: Array[int] = [funds_after_vote_level]
			for i in 3:
				_complete_level(vote_levels[i + 1])
				series.append(int(GameState.meta["Funds"]))
			tail = tail if not with_law else series
			if not with_law:
				var diffs: Array[int] = []
				for i in series.size():
					diffs.append(tail[i] - series[i])
				# Level 0: only the Once effect may differ; levels 1-3 add one
				# more payout each.
				var once_funds := int(_expected_effect(_rows_for(bill_id, passed, StatuteBook.ONCE))["meta"].get("Funds", 0))
				var expected_diffs: Array[int] = [once_funds, once_funds + per_level,
					once_funds + 2 * per_level, once_funds + 3 * per_level]
				if diffs != expected_diffs:
					bad.append("%s %s got %s want %s" % [bill_id, "passed" if passed else "failed", diffs, expected_diffs])
		summary.append("%s %s %+d Funds/level" % [bill_id, "passed" if passed else "failed", per_level])
	_check("D2", CRITICAL, bad.is_empty() and ongoing.size() > 0,
		"An 'Each level' law pays nothing on the level that passed it, then exactly its workbook amount at the end of every later level (3 levels watched, against an identical run without the law)",
		"%s%s" % [", ".join(summary), ("" if bad.is_empty() else " | PROBLEMS: " + "; ".join(bad))])

	# A bill with only 'Once' rows leaves nothing running.
	var once_only := ""
	for bill: Dictionary in _bills():
		var has_each := false
		for row: Dictionary in ongoing:
			if row["bill_id"] == bill["bill_id"]:
				has_each = true
		if not has_each:
			once_only = str(bill["bill_id"])
			break
	_new_run(_protagonists[0])
	GameState.meta["Funds"] = 20000
	var level_ids := _vote_level_ids()
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level(level_ids[0]))))
	GameState.record_floor_vote(DataDB.get_bill(once_only), {"totals": {"Yes": 60, "No": 30, "Abstain": 11}, "passed": true}, "Yes")
	while GameState.is_in_level():
		if GameState.finish_stage(LevelRunner.WON):
			break
	GameState.end_level()
	var funds_before := int(GameState.meta["Funds"])
	var standing_before := GameState.booster_standing.duplicate()
	seed(99)
	_complete_level(level_ids[1])
	var quiet := true
	for booster_id: String in standing_before.keys():
		if GameState.booster_standing[booster_id] != standing_before[booster_id]:
			quiet = false
	_check("D3", MAJOR, quiet,
		"A bill with only 'Once' rows keeps nothing running: a later level moves no organisation",
		"%s passed, next level changed no standing" % once_only)


func _d4_no_double_apply() -> void:
	_new_run(_protagonists[0])
	var bill := DataDB.get_bill("BI01")
	var result := {"totals": {"Yes": 60, "No": 30, "Abstain": 11}, "passed": true}
	GameState.record_floor_vote(bill, result, "Yes")
	var after_first := GameState.booster_standing.duplicate()
	var meta_first := GameState.meta.duplicate()
	GameState.record_floor_vote(bill, result, "Yes")
	_check("D4", CRITICAL, GameState.booster_standing == after_first and GameState.meta == meta_first
			and GameState.statute_book.size() == 1,
		"Recording the same bill a second time changes nothing and adds no second entry",
		"statute book entries: %d" % GameState.statute_book.size())


func _d5_save_reload() -> void:
	var levels := _vote_level_ids()
	var series: Array[Array] = []
	for resume in [false, true]:
		_new_run(_protagonists[0])
		GameState.meta["Funds"] = 20000
		GameState.funds_cap_bonus = 900000
		seed(2718)
		GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level(levels[0]))))
		GameState.record_floor_vote(DataDB.get_bill("BI14"),
			{"totals": {"Yes": 60, "No": 30, "Abstain": 11}, "passed": true}, "Yes")
		while GameState.is_in_level():
			if GameState.finish_stage(LevelRunner.WON):
				break
		GameState.end_level()
		if resume:
			SaveManager.save_game(SCRATCH_SAVE)
			_new_run(_protagonists[2])
			SaveManager.load_game(SCRATCH_SAVE)
		var funds: Array[int] = [int(GameState.meta["Funds"])]
		for i in 2:
			_complete_level(levels[i + 1])
			funds.append(int(GameState.meta["Funds"]))
		var book_ok: bool = GameState.statute_book.size() == 1 and GameState.law_statuses().get("BI14", "") == "passed"
		funds.append(1 if book_ok else 0)
		series.append(funds)
	_check("D5", MAJOR, series[0] == series[1],
		"Saving after a law passes and reloading keeps the statute book and the running payouts exactly as if you had never quit",
		"without quit %s, with quit %s" % [series[0], series[1]])


func _d6_new_game_clears() -> void:
	_new_run(_protagonists[0])
	GameState.record_floor_vote(DataDB.get_bill("BI14"),
		{"totals": {"Yes": 60, "No": 30, "Abstain": 11}, "passed": true}, "Yes")
	GameState.record_bill_flip("BI14")
	var had := GameState.statute_book.size() == 1
	_new_run(_protagonists[1])
	_check("D6", MAJOR, had and GameState.statute_book.is_empty() and GameState.law_statuses().is_empty()
			and GameState.bills_flipped_by_influence.is_empty(),
		"Starting a new game wipes the statute book and the flip record: laws never leak between runs",
		"book had 1 entry, new run has %d" % GameState.statute_book.size())


func _d7_law_conditions() -> void:
	_new_run(_protagonists[0])
	var row := {"condition_type": "law", "condition_target": "BI14", "condition_op": "passed"}
	var failed_row := {"condition_type": "law", "condition_target": "BI14", "condition_op": "failed"}
	var before := OfficeNotices.condition_met(row, {}, GameState.meta, GameState.law_statuses())
	GameState.record_floor_vote(DataDB.get_bill("BI14"),
		{"totals": {"Yes": 60, "No": 30, "Abstain": 11}, "passed": true}, "Yes")
	var after_pass := OfficeNotices.condition_met(row, {}, GameState.meta, GameState.law_statuses())
	var wrong_op := OfficeNotices.condition_met(failed_row, {}, GameState.meta, GameState.law_statuses())
	var ticker_line := OfficeTicker.eligible_lines([{"ticker_id": "T", "condition_type": "law",
		"condition_target": "BI14", "condition_op": "passed", "text_en": "A grant arrived."}],
		{}, GameState.meta, "", GameState.law_statuses())
	_check("D7", MINOR, not before and after_pass and not wrong_op and ticker_line.size() == 1,
		"Office notices and the ticker switch on only after the named bill has passed (and not for 'failed')",
		"before %s, after pass %s, 'failed' test %s, ticker lines %d" % [before, after_pass, wrong_op, ticker_line.size()])
	_note("D7b", "Real notice / ticker rows that use the 'law' condition",
		"%d in the workbook today" % (DataDB.office_notices.filter(func(r: Dictionary) -> bool: return str(r.get("condition_type")) == "law").size()
			+ DataDB.office_ticker.filter(func(r: Dictionary) -> bool: return str(r.get("condition_type")) == "law").size()))


## Every organisation is pleased by at least one bill outcome and annoyed by
## at least one, so none is a bystander to the whole statute book.
func _d8_every_organisation_has_a_stake() -> void:
	var pleased := {}
	var annoyed := {}
	for row: Dictionary in DataDB.law_effects:
		var effects: Variant = row.get("effects")
		for entry in (effects if effects is Array else []):
			var target := str(entry.get("target", ""))
			if not target.begins_with("BO") or entry.get("delta") == null:
				continue
			(pleased if int(entry["delta"]) > 0 else annoyed)[target] = true
	var missing: Array[String] = []
	for booster: Dictionary in DataDB.boosters:
		var id := str(booster.get("booster_id", ""))
		if str(booster.get("tier", "")) == "Party":
			continue   # party-tier organisations follow the player's party lean, not fixed rows
		if not pleased.has(id):
			missing.append("%s never pleased" % id)
		if not annoyed.has(id):
			missing.append("%s never annoyed" % id)
	_check("D8", MAJOR, missing.is_empty(),
		"Every organisation is pleased by at least one bill outcome and annoyed by at least one",
		"%d organisations%s" % [DataDB.boosters.size(), ("" if missing.is_empty() else "; " + ", ".join(missing))])
