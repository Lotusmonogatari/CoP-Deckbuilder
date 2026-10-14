extends Node
## Late-game and extreme-state stress (2026-10-14, Cameron: "review game
## performance and mechanics, particularly late stage with multiple boosters
## and extreme states present").
##
## Builds a run that has everything a long game ends with — every card, every
## backing, every staff member at top tier, full item stacks, every bill in the
## statute book, every organisation at 100 (or 0) — and then beats on it:
##
##   A. Save size and save/load round trip, and the cost of the derived
##      numbers the rules ask for constantly (party opinion and friends).
##   B. A fight in every Combat room with that state, rules invariants checked
##      after every move, each fight timed.
##   C. Every Floor Vote bill, voted all three ways with the influence gate open.
##   D. Stage rewards, law effects and level payouts hammered until the meta
##      numbers have nothing left to move, checking nothing leaves its range.
##   E. The Office panels and a real battle screen drawn with that state, timed,
##      plus a node-count leak check across repeated screen loads.
##
## Four states are tried: "max" (all 100 and every item), "min" (all 0),
## "crisis" (every crisis trigger active at once) and "stacked" (huge item
## bonuses: +30 energy, +20 hand, +99 guard, +40 gaffe cap).
##
##     xvfb-run .tools/godot --path . tools/stress_late_game.tscn
##     STRESS_OUT=/path/report.json   (default user://stress_late_game.json)
##
## Prints a summary and exits 1 if any rule was broken. Timings wander, so
## they are reported, not failed (except a hard ceiling per fight/panel).

const OFFICE := "res://scenes/office_hours/OfficeScreen.tscn"
const BATTLE := "res://scenes/battle/BattleScreen.tscn"
const SEED := 20261014
const PROTAGONIST := "PC02"
## One fight or one panel slower than this is reported as a problem.
const SLOW_FIGHT_MS := 2000.0
const SLOW_PANEL_MS := 400.0
const MAX_TURNS := 80
const SAVE_PATH := "user://stress_late_game_save.json"
const OFFICE_PANELS := ["_show_levels", "_show_management", "_show_marketplace",
	"_show_reputation_menu", "_show_organisations", "_show_backing",
	"_show_parties", "_show_record", "_show_staff", "_show_deck",
	"_show_administration_menu"]

var _report := {}
var _problems: Array[String] = []
var _expected_total := 0
var _cards_played := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	await get_tree().process_frame
	seed(SEED)
	_report["started"] = Time.get_datetime_string_from_system()
	# STRESS_ONLY="C,F" runs just those stages (a quick re-check after a fix).
	var only := OS.get_environment("STRESS_ONLY")
	for kind: String in ["max", "min", "crisis", "stacked"]:
		_report[kind] = {}
		_build_state(kind)
		if _want(only, "A"): _stage_a_save_and_derived(kind)
		if _want(only, "B"): _stage_b_fights(kind)
		if _want(only, "C"): _stage_c_votes(kind)
		if _want(only, "D"): _stage_d_meta_hammer(kind)
		if _want(only, "E"): await _stage_e_screens(kind)
	if _want(only, "F"):
		await _stage_f_leaks()
	_report["problems"] = _problems
	_write()
	_print_summary()
	get_tree().quit(1 if not _problems.is_empty() else 0)


# ---------------------------------------------------------------------------
# State builders
# ---------------------------------------------------------------------------

func _build_state(kind: String) -> void:
	GameState.start_new_run(PROTAGONIST)
	var high := kind != "min"
	for card: Dictionary in DataDB.cards:
		if not GameState.owned_cards.has(str(card["card_id"])):
			GameState.owned_cards.append(str(card["card_id"]))
	GameState.xp = 1000000 if high else 0

	# Meta at the ceiling (or the floor).
	for row: Dictionary in GameState.sanban_rows_with_bonuses():
		var variable := str(row.get("name_en", ""))
		if variable.is_empty() or not GameState.meta.has(variable):
			continue
		GameState.meta[variable] = int(row.get("max", 100)) if high else int(row.get("min", 0))

	for booster_id: String in GameState.booster_standing.keys():
		GameState.booster_standing[booster_id] = 100 if high else 0
	for party_name: String in GameState.party_standing.keys():
		GameState.party_standing[party_name] = 100 if high else 0

	if high:
		GameState.funds_cap_bonus = 900000
		for modifier: Dictionary in DataDB.modifiers:
			var mod_id := str(modifier.get("mod_id", ""))
			if mod_id != "M32" and not GameState.owned_modifiers.has(mod_id):
				GameState.owned_modifiers.append(mod_id)
		for candidate: Dictionary in DataDB.staff:
			GameState.staff_hired[str(candidate.get("role", ""))] = {
				"staff_id": str(candidate.get("staff_id", "")),
				"tier": int(candidate.get("highest_tier", 0))}
		for item: Dictionary in DataDB.shop:
			var cap: Variant = item.get("stack_cap")
			GameState.inventory[str(item.get("item_id", ""))] = int(cap) if cap != null else 5
		for level: Dictionary in DataDB.levels:
			var level_id := str(level.get("level_id", ""))
			if not GameState.levels_unlocked.has(level_id):
				GameState.levels_unlocked.append(level_id)
			GameState.levels_cleared[level_id] = 50
			GameState.level_last_completed_at[level_id] = 1
		GameState.levels_completed_count = 82 * 50
		for opponent: Dictionary in DataDB.opponents:
			GameState.faced_people[str(opponent.get("opp_id", ""))] = 40
		GameState.lifetime_gaffes = 99999
		GameState.gaffe_penalty_applied = true

	# Every bill in the book, passed.
	for bill: Dictionary in DataDB.floor_votes.values():
		var result := {"passed": true, "totals": {"Yes": 60, "No": 30, "Abstain": 11},
			"outcome_flipped_by_influence": false}
		GameState.record_floor_vote(bill, result, "Yes")
		GameState.bills_flipped_by_influence.append(str(bill.get("bill_id", "")))

	if kind == "crisis":
		GameState.town_hall_active = true
		GameState.steering_committee_active = true
		GameState.funding_frozen_active = true
		GameState.meta["Constituency support"] = 3
		GameState.meta["Party support"] = 0
		GameState.meta["Funds"] = 0
		for booster_id: String in GameState.booster_standing.keys():
			GameState.booster_standing[booster_id] = 12 if int(booster_id.substr(2)) % 2 == 0 else 95
	if kind == "stacked":
		var stacked := {"ENERGY": 30, "GUARD": 99, "DRAW": 20, "TURNS": 40, "GAFFE_CAP": 40}
		GameState.pending_stage_bonuses = stacked.duplicate()
		GameState.level_bonuses = stacked.duplicate()
	_report[kind]["state"] = {
		"cards": GameState.owned_cards.size(), "modifiers": GameState.owned_modifiers.size(),
		"statute_book": GameState.statute_book.size(), "inventory": GameState.inventory.size(),
		"funds": GameState.meta.get("Funds"),
	}


# ---------------------------------------------------------------------------
# A. Save size and derived numbers
# ---------------------------------------------------------------------------

func _stage_a_save_and_derived(kind: String) -> void:
	var out := {}
	var started := Time.get_ticks_usec()
	var saved := GameState.to_save()
	out["to_save_ms"] = _ms(started)
	started = Time.get_ticks_usec()
	var text := JSON.stringify({"version": 1, "run": JSON.from_native(saved)})
	out["json_ms"] = _ms(started)
	out["save_bytes"] = text.length()

	SaveManager.enabled = true
	started = Time.get_ticks_usec()
	var wrote := SaveManager.save_game(SAVE_PATH)
	out["save_game_ms"] = _ms(started)
	if not wrote:
		_problem(kind, "A", "save_game() failed with the extreme state")
	var before := GameState.to_save()
	started = Time.get_ticks_usec()
	var loaded := SaveManager.load_game(SAVE_PATH)
	out["load_game_ms"] = _ms(started)
	if not loaded:
		_problem(kind, "A", "load_game() failed with the extreme state")
	elif GameState.to_save() != before:
		var differing: Array[String] = []
		var after := GameState.to_save()
		for key: String in before.keys():
			if before[key] != after.get(key):
				differing.append(key)
		_problem(kind, "A", "save/load round trip changed: %s" % differing)
	SaveManager.enabled = false
	SaveManager.delete_save(SAVE_PATH)

	# Derived numbers asked for constantly.
	var timings := {}
	for name: String in ["party_support_effective", "effective_meta", "law_statuses",
			"party_support_change_this_level"]:
		started = Time.get_ticks_usec()
		for i in 200:
			GameState.call(name)
		timings[name + "_us_per_call"] = int((Time.get_ticks_usec() - started) / 200.0)
	started = Time.get_ticks_usec()
	for i in 200:
		for party: Dictionary in DataDB.parties:
			GameState.party_opinion_detail(str(party.get("party_id", "")))
	timings["party_opinion_detail_all_six_us"] = int((Time.get_ticks_usec() - started) / 200.0)
	out["derived"] = timings
	var effective := GameState.party_support_effective()
	if effective < 0 or effective > 100:
		_problem(kind, "A", "party_support_effective() = %d is outside 0..100" % effective)
	_report[kind]["A"] = out


# ---------------------------------------------------------------------------
# B. A fight in every combat room
# ---------------------------------------------------------------------------

func _stage_b_fights(kind: String) -> void:
	var out := {"fights": 0, "wins": 0, "losses": 0, "slowest_ms": 0.0, "slowest_stage": "",
		"total_ms": 0.0, "max_turns": 0, "max_hand": 0, "setup_failures": 0, "cards_played": 0}
	var slow: Array[String] = []
	for stage_row: Dictionary in DataDB.stages:
		if str(stage_row.get("mode", "")) != "Combat":
			continue
		var stage_id := str(stage_row.get("stage_id", ""))
		var expanded := BattleSetup.expand_level({"level_id": "LVSTRESS", "stage_1": stage_id})
		var runner := LevelRunner.new(expanded)
		GameState.begin_level(runner)
		var config := BattleSetup.for_playtest_stage(
			runner.current_stage(), runner.carried_buffs(), GameState.meta)
		if config.is_empty():
			_problem(kind, "B", "%s: empty battle config" % stage_id)
			GameState.end_level()
			continue
		config["item_bonuses"] = GameState.take_item_bonuses_for_stage()
		var seed_value := randi()
		config["seed"] = seed_value
		var repro := "%s/%s seed=%d" % [kind, stage_id, seed_value]

		var started := Time.get_ticks_usec()
		var engine := BattleEngine.new()
		if not engine.setup(config):
			out["setup_failures"] += 1
			_problem(kind, "B", "%s: setup failed: %s" % [repro, engine.setup_problems])
			GameState.end_level()
			continue
		_expected_total = engine.state.deck.size() + engine.state.hand.size() + engine.state.discard.size()
		_invariants(engine, repro, "setup")
		out["max_hand"] = maxi(out["max_hand"], engine.state.hand.size())

		var turns := 0
		while not engine.state.is_over() and turns < MAX_TURNS:
			turns += 1
			_play_turn(engine, repro)
			if engine.state.is_over():
				break
			var ended := engine.end_turn()
			if not ended.get("ok", false):
				_problem(kind, "B", "%s: end_turn refused: %s" % [repro, ended.get("reason")])
				break
			_invariants(engine, repro, "end_turn")
		var took := _ms(started)
		out["fights"] += 1
		out["cards_played"] = _cards_played
		out["total_ms"] += took
		out["max_turns"] = maxi(out["max_turns"], turns)
		if took > out["slowest_ms"]:
			out["slowest_ms"] = took
			out["slowest_stage"] = stage_id
		if took > SLOW_FIGHT_MS:
			slow.append("%s %.0fms" % [stage_id, took])
		if turns >= MAX_TURNS and not engine.state.is_over():
			_problem(kind, "B", "%s: no conclusion in %d turns (gaffe %d/%d, turn %d/%s)" % [
				repro, MAX_TURNS, engine.state.gaffe, engine.state.gaffe_limit,
				engine.state.turn, stage_row.get("turn_limit")])
		var st := engine.state
		if st.outcome == "win":
			out["wins"] += 1
		elif st.outcome == "loss":
			out["losses"] += 1
		var level_over := GameState.finish_stage(st.outcome, st.player_score(),
			engine.pleased_boosters(), st.outcome == "loss" and st.gaffe >= st.gaffe_limit,
			st.gaffe, engine.displeased_boosters(), engine.crushed_opponent_boosters(),
			engine.opposed_boosters())
		_meta_in_range(kind, "after %s" % stage_id)
		if level_over or GameState.level_runner != null:
			GameState.end_level()
		# A fight changes the state; put the extremes back for the next room.
		_restore_extremes(kind)
	out["slow"] = slow
	_report[kind]["B"] = out


## Plays every affordable card in hand, cheapest first, until nothing more can
## be played. Deliberately naive: the point is exercising the rules.
func _play_turn(engine: BattleEngine, repro: String) -> void:
	var guard := 0
	while not engine.state.is_over() and guard < 200:
		guard += 1
		var picked := ""
		for card_id: String in engine.state.hand:
			if int(DataDB.get_card(card_id).get("cost", 99)) <= engine.state.energy:
				picked = card_id
				break
		if picked.is_empty():
			return
		var result := engine.play_card(picked)
		if not result.get("ok", false):
			return
		_cards_played += 1
		_invariants(engine, repro, "play_card " + picked)


func _restore_extremes(kind: String) -> void:
	if kind == "stacked":
		GameState.pending_stage_bonuses = {"ENERGY": 30, "GUARD": 99, "DRAW": 20, "TURNS": 40, "GAFFE_CAP": 40}
		GameState.level_bonuses = GameState.pending_stage_bonuses.duplicate()
	var high := kind != "min"
	for booster_id: String in GameState.booster_standing.keys():
		if kind == "crisis":
			continue
		GameState.booster_standing[booster_id] = 100 if high else 0


func _invariants(engine: BattleEngine, repro: String, moment: String) -> void:
	var s := engine.state
	var total := s.deck.size() + s.hand.size() + s.discard.size()
	if total != _expected_total:
		_problem("inv", "B", "%s: cards %d, expected %d after %s" % [repro, total, _expected_total, moment])
	if s.energy < 0:
		_problem("inv", "B", "%s: negative energy %d after %s" % [repro, s.energy, moment])
	if s.block < 0 or s.block > s.guard_cap:
		_problem("inv", "B", "%s: guard %d outside 0..%d after %s" % [repro, s.block, s.guard_cap, moment])
	if s.opponent_block < 0 or s.opponent_block > s.guard_cap:
		_problem("inv", "B", "%s: opponent guard %d after %s" % [repro, s.opponent_block, moment])
	if s.gaffe < 0:
		_problem("inv", "B", "%s: negative gaffe after %s" % [repro, moment])
	if s.gaffe >= s.gaffe_limit and s.outcome != "loss":
		_problem("inv", "B", "%s: gaffe at limit but outcome %s after %s" % [repro, s.outcome, moment])
	if s.hand_size < 0 or s.hand.size() > maxi(s.hand_size, 1) + 25:
		_problem("inv", "B", "%s: hand %d vs hand_size %d after %s" % [repro, s.hand.size(), s.hand_size, moment])
	if s.bar != null:
		var bar := s.bar
		if bar.player < 0 or bar.player > bar.maximum:
			_problem("inv", "B", "%s: bar.player %d outside 0..%d after %s" % [repro, bar.player, bar.maximum, moment])
		if bar.model == BarModel.Model.SHARED_POOL and (bar.opponent < 0 or bar.undecided < 0 or not bar.totals_balance()):
			_problem("inv", "B", "%s: pool does not balance after %s" % [repro, moment])


# ---------------------------------------------------------------------------
# C. Floor votes with the influence gate open
# ---------------------------------------------------------------------------

func _stage_c_votes(kind: String) -> void:
	var out := {"votes": 0, "flips": 0, "gate_open_votes": 0}
	var party_name := str(DataDB.player.get("party", ""))
	# The fights before this one change the meta; judge the gate on the extreme.
	if kind == "max" or kind == "stacked":
		for row: Dictionary in GameState.sanban_rows_with_bonuses():
			var variable := str(row.get("name_en", ""))
			if GameState.meta.has(variable):
				GameState.meta[variable] = int(row.get("max", 100))
		for booster_id: String in GameState.booster_standing.keys():
			GameState.booster_standing[booster_id] = 100
	for level: Dictionary in DataDB.levels:
		var bill := DataDB.get_floor_vote(str(level.get("level_id", ""))).duplicate(true)
		if bill.is_empty():
			continue
		# BattleSetup adds each party's name to its position; do the same.
		for position: Dictionary in (bill.get("positions", []) as Array):
			position["party_name"] = str(DataDB.get_party_by_id(str(position.get("party_id", ""))).get("name", ""))
		for choice: String in ["Yes", "No", "Abstain"]:
			var engine := FloorVoteEngine.new()
			var ok := engine.setup({
				"bill": bill, "player_party": party_name,
				"meta": GameState.effective_meta(), "booster_standing": GameState.booster_standing,
				"triggers": DataDB.vote_influence_triggers,
				"default_threshold": int(DataDB.balance.get("vote_influence_default_threshold", 85)),
				"resistance_by_party": {}, "default_resistance": 0})
			if not ok:
				_problem(kind, "C", "%s: setup failed: %s" % [bill.get("bill_id"), engine.setup_problems])
				break
			var result := engine.choose(choice)
			out["votes"] += 1
			if result.get("influence_gate_passed", false):
				out["gate_open_votes"] += 1
			if result.get("outcome_flipped_by_influence", false):
				out["flips"] += 1
			var totals: Dictionary = result.get("totals", {})
			var house := int(totals.get("Yes", 0)) + int(totals.get("No", 0)) + int(totals.get("Abstain", 0))
			if house != 101:
				_problem(kind, "C", "%s/%s: house totals %d, expected 101 (%s)" % [bill.get("bill_id"), choice, house, totals])
			for k: String in totals.keys():
				if int(totals[k]) < 0:
					_problem(kind, "C", "%s/%s: negative %s total" % [bill.get("bill_id"), choice, k])
			var passed := bool(result.get("passed", false))
			if passed != (int(totals.get("Yes", 0)) >= 51):
				_problem(kind, "C", "%s/%s: passed=%s but Yes=%d" % [bill.get("bill_id"), choice, passed, totals.get("Yes")])
	_report[kind]["C"] = out


# ---------------------------------------------------------------------------
# D. Hammer the meta numbers
# ---------------------------------------------------------------------------

func _stage_d_meta_hammer(kind: String) -> void:
	var out := {"rounds": 0}
	var started := Time.get_ticks_usec()
	for round_index in 400:
		var outcome := LevelRunner.WON if round_index % 3 != 0 else LevelRunner.LOST
		var expanded := BattleSetup.expand_level({"level_id": "LVSTRESS", "stage_1": "ST02", "stage_2": "ST04"})
		GameState.begin_level(LevelRunner.new(expanded))
		for i in 2:
			if GameState.level_runner == null or GameState.level_runner.is_finished():
				break
			GameState.finish_stage(outcome, randi_range(0, 100),
				GameState.booster_standing.keys().slice(0, 12), randf() < 0.2, randi_range(0, 9),
				GameState.booster_standing.keys().slice(12, 24), [],
				GameState.booster_standing.keys().slice(24, 30))
		if GameState.level_runner != null:
			GameState.end_level()
		out["rounds"] += 1
		if round_index % 25 == 0:
			_meta_in_range(kind, "hammer round %d" % round_index)
	_meta_in_range(kind, "end of hammer")
	out["ms"] = _ms(started)
	out["ms_per_round"] = snappedf(out["ms"] / out["rounds"], 0.01)
	if float(out["ms_per_round"]) > 50.0:
		_problem(kind, "D", "a level end takes %.1f ms" % out["ms_per_round"])
	_report[kind]["D"] = out


func _meta_in_range(kind: String, moment: String) -> void:
	for row: Dictionary in GameState.sanban_rows_with_bonuses():
		var variable := str(row.get("name_en", ""))
		if variable.is_empty() or not GameState.meta.has(variable):
			continue
		var value := int(GameState.meta[variable])
		var low := int(row.get("min", 0))
		var high := maxi(int(row.get("max", 100)), value if kind != "inv" else 0)
		if value < low or value > int(row.get("max", 100)):
			_problem(kind, "D", "%s = %d outside %d..%d (%s)" % [variable, value, low, int(row.get("max", 100)), moment])
	for booster_id: String in GameState.booster_standing.keys():
		var standing := int(GameState.booster_standing[booster_id])
		if standing < 0 or standing > 100:
			_problem(kind, "D", "standing %s = %d outside 0..100 (%s)" % [booster_id, standing, moment])
	for party_name: String in GameState.party_standing.keys():
		var p := int(GameState.party_standing[party_name])
		if p < 0 or p > 100:
			_problem(kind, "D", "party standing %s = %d outside 0..100 (%s)" % [party_name, p, moment])
	if GameState.xp < 0:
		_problem(kind, "D", "negative XP (%s)" % moment)


# ---------------------------------------------------------------------------
# E. Screens with the state present
# ---------------------------------------------------------------------------

func _stage_e_screens(kind: String) -> void:
	var out := {}
	_build_state(kind)
	GameState.mid_stage = false
	var office := (load(OFFICE) as PackedScene).instantiate()
	var started := Time.get_ticks_usec()
	get_tree().root.add_child(office)
	await get_tree().process_frame
	await get_tree().process_frame
	out["office_open_ms"] = _ms(started)
	var panels := {}
	for method: String in OFFICE_PANELS:
		if not office.has_method(method):
			continue
		var times: Array[float] = []
		for i in 3:
			started = Time.get_ticks_usec()
			office.call(method)
			await get_tree().process_frame
			times.append(_ms(started))
			_close_overlays(office)
			await get_tree().process_frame
		var med := _median(times)
		panels[method.trim_prefix("_show_")] = med
		if med > SLOW_PANEL_MS:
			_problem(kind, "E", "Office panel %s takes %.0f ms" % [method, med])
	out["panels_ms"] = panels
	out["office_nodes"] = _count_nodes(office)
	office.queue_free()
	await get_tree().process_frame

	# A real battle screen in a real level with the state in play.
	var expanded := BattleSetup.expand_level({"level_id": "LVSTRESS", "stage_1": "ST05"})
	GameState.begin_level(LevelRunner.new(expanded))
	var screen := (load(BATTLE) as PackedScene).instantiate()
	started = Time.get_ticks_usec()
	get_tree().root.add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	out["battle_open_ms"] = _ms(started)
	var engine: BattleEngine = screen.get("engine")
	if engine == null:
		_problem(kind, "E", "battle screen did not start a battle")
	else:
		out["hand_at_open"] = engine.state.hand.size()
		var refreshes: Array[float] = []
		var turns := 0
		while not engine.state.is_over() and turns < 25:
			var played := false
			for card_id: String in engine.state.hand:
				if int(DataDB.get_card(card_id).get("cost", 99)) <= engine.state.energy:
					engine.play_card(card_id)
					started = Time.get_ticks_usec()
					screen.call("_refresh")
					await get_tree().process_frame
					refreshes.append(_ms(started))
					played = true
					break
			if not played:
				engine.end_turn()
				screen.call("_refresh")
				await get_tree().process_frame
				turns += 1
		out["refresh_median_ms"] = _median(refreshes)
		out["refresh_max_ms"] = refreshes.max() if not refreshes.is_empty() else 0.0
		out["battle_nodes"] = _count_nodes(screen)
		if out["refresh_max_ms"] > SLOW_PANEL_MS:
			_problem(kind, "E", "battle refresh peaked at %.0f ms" % out["refresh_max_ms"])
	screen.queue_free()
	await get_tree().process_frame
	GameState.end_level()
	_report[kind]["E"] = out


# ---------------------------------------------------------------------------
# F. Leak check: repeated screens
# ---------------------------------------------------------------------------

func _stage_f_leaks() -> void:
	_build_state("max")
	var out := {}
	var screens := {
		"office": [OFFICE, 40], "battle": [BATTLE, 20],
		"visitor": ["res://scenes/office_hours/VisitorScreen.tscn", 20],
		"floor_vote": ["res://scenes/office_hours/FloorVoteScreen.tscn", 20],
		"level_intro": ["res://scenes/office_hours/LevelIntroScreen.tscn", 20],
		"intro": ["res://scenes/menus/IntroScreen.tscn", 20],
	}
	for name: String in screens.keys():
		var path: String = screens[name][0]
		if not ResourceLoader.exists(path):
			continue
		var loads: int = screens[name][1]
		# One warm-up so caches are counted in the baseline, not as growth.
		await _load_free(path, name)
		var before := _objects()
		for i in loads:
			await _load_free(path, name)
		await get_tree().create_timer(2.5).timeout   # let any 1.8 s flinch timer end
		var after := _objects()
		out[name] = {"loads": loads,
			"objects_per_load": snappedf(float(after["objects"] - before["objects"]) / loads, 0.1),
			"nodes_before": before["nodes"], "nodes_after": after["nodes"],
			"static_mb_growth": snappedf(float(after["static"] - before["static"]) / 1048576.0, 0.01)}
		if int(after["nodes"]) - int(before["nodes"]) > 50:
			_problem("leak", "F", "%s: nodes grew from %d to %d over %d loads" % [
				name, before["nodes"], after["nodes"], loads])
	_report["leaks"] = out


func _load_free(path: String, kind: String) -> void:
	if kind == "battle":
		var expanded := BattleSetup.expand_level({"level_id": "LVSTRESS", "stage_1": "ST02"})
		GameState.begin_level(LevelRunner.new(expanded))
	var node := (load(path) as PackedScene).instantiate()
	get_tree().root.add_child(node)
	await get_tree().process_frame
	node.queue_free()
	await get_tree().process_frame
	if kind == "battle":
		GameState.end_level()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _want(only: String, stage: String) -> bool:
	return only.is_empty() or stage in only.split(",")


func _problem(kind: String, area: String, message: String) -> void:
	var line := "[%s %s] %s" % [kind, area, message]
	var same := 0
	for existing in _problems:
		if existing.begins_with("[%s %s]" % [kind, area]):
			same += 1
	if same < 6 and not _problems.has(line):
		_problems.append(line)


func _close_overlays(root: Node) -> void:
	for child in root.get_children():
		if child is Overlay and (child as Overlay).visible:
			(child as Overlay).close()


func _count_nodes(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _count_nodes(child)
	return total


func _objects() -> Dictionary:
	return {"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"static": int(Performance.get_monitor(Performance.MEMORY_STATIC))}


func _ms(started_usec: int) -> float:
	return snappedf((Time.get_ticks_usec() - started_usec) / 1000.0, 0.01)


func _median(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return sorted[sorted.size() / 2]


func _write() -> void:
	var out := OS.get_environment("STRESS_OUT")
	if out.is_empty():
		out = "user://stress_late_game.json"
	var file := FileAccess.open(out, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(_report, "  "))
		print("STRESS report written to ", out)


func _print_summary() -> void:
	print("")
	print("=== LATE-GAME STRESS SUMMARY ===")
	for kind: String in ["max", "min", "crisis", "stacked"]:
		var r: Dictionary = _report.get(kind, {})
		var a: Dictionary = r.get("A", {})
		var b: Dictionary = r.get("B", {})
		var e: Dictionary = r.get("E", {})
		print("%-8s save %d bytes (save %.0f ms, load %.0f ms) | fights %d (W%d/L%d) total %.0f ms slowest %s %.0f ms, max turns %d, max hand %d | office open %.0f ms, battle refresh med %.1f max %.1f ms" % [
			kind, int(a.get("save_bytes", 0)), float(a.get("save_game_ms", 0)), float(a.get("load_game_ms", 0)),
			int(b.get("fights", 0)), int(b.get("wins", 0)), int(b.get("losses", 0)), float(b.get("total_ms", 0)),
			str(b.get("slowest_stage", "")), float(b.get("slowest_ms", 0)), int(b.get("max_turns", 0)), int(b.get("max_hand", 0)),
			float(e.get("office_open_ms", 0)), float(e.get("refresh_median_ms", 0)), float(e.get("refresh_max_ms", 0))])
	print("leaks: ", _report.get("leaks", {}))
	print("problems: %d" % _problems.size())
	for line in _problems:
		print("  ! ", line)
