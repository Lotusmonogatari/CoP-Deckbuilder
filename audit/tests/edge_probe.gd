extends Node
## Audit Phase 6: edge-case probe. One case per process (AUDIT_CASE=name) so a
## script error in one case cannot hide another; audit/tests/run_edge.sh loops
## over every case and writes audit/tests/results/edge_cases.json.
##
##   AUDIT_CASE=deck_empty .tools/godot --headless --path . audit/tests/edge_probe.tscn
##
## Each case prints one line:  EDGE <case> | <what happened>
## A script error shows on stderr and is captured by run_edge.sh.

const CASES := [
	"deck_empty", "deck_one_card", "deck_unknown_card", "hand_size_zero", "energy_zero",
	"turn_limit_zero", "stage_null_field", "card_null_number", "meta_overflow", "funds_over_cap",
	"lever_missing", "crisis_simultaneous", "save_corrupt", "save_truncated", "save_newer_version",
	"save_wrong_types", "save_bad_deck", "suspend_mid_stage", "level_no_stage", "visitor_no_questions",
	"zero_cost_card_loop", "draw_loop", "whip_below_floor", "dues_negative_funds",
]
var _case := ""


func _ready() -> void:
	_case = OS.get_environment("AUDIT_CASE")
	_run.call_deferred()


func _say(text: String) -> void:
	print("EDGE %s | %s" % [_case, text])


func _config(stage_id: String, overrides: Dictionary = {}, seed_value: int = 11) -> Dictionary:
	var expanded := BattleSetup.expand_level({"level_id": "LVEDGE", "stage_1": stage_id})
	var runner := LevelRunner.new(expanded)
	var stage: Dictionary = (runner.current_stage() as Dictionary).duplicate(true)
	for key: String in overrides:
		stage[key] = overrides[key]
	var config := BattleSetup.for_playtest_stage(stage, runner.carried_buffs(), GameState.meta)
	config["seed"] = seed_value
	return config


## Plays turns (greedy-ish: first affordable card) until the fight ends or the cap.
func _play_out(engine: BattleEngine, cap: int = 120) -> String:
	var turns := 0
	var plays := 0
	while not engine.state.is_over() and turns < cap:
		turns += 1
		var guard := 0
		while guard < 40 and not engine.state.is_over():
			guard += 1
			var moved := false
			for id: String in engine.state.hand.duplicate():
				var card := DataDB.get_card(id)
				if card.is_empty() or engine.card_cost(card) > engine.state.energy or engine.discard_required(card) > 0:
					continue
				if engine.play_card(id).get("ok", false):
					plays += 1
					moved = true
					break
			if not moved:
				break
		if not engine.state.is_over():
			engine.end_turn()
	return "outcome=%s after %d turns, %d plays%s" % [engine.state.outcome, turns, plays, " (CAP HIT: not over)" if not engine.state.is_over() else ""]


func _run() -> void:
	seed(3)
	DataDB.clear_runtime()
	GameState.start_new_run("PC02")
	call("_case_" + _case)
	get_tree().quit(0)


# --- battle -----------------------------------------------------------------

func _case_deck_empty() -> void:
	var config := _config("ST02")
	config["deck"] = []
	var engine := BattleEngine.new()
	_say("setup=%s problems=%s" % [engine.setup(config), engine.setup_problems])


func _case_deck_one_card() -> void:
	var config := _config("ST02")
	config["deck"] = ["C23"]
	var engine := BattleEngine.new()
	if not engine.setup(config):
		_say("setup refused: %s" % [engine.setup_problems]); return
	_say("hand=%s deck=%s | %s" % [engine.state.hand, engine.state.deck, _play_out(engine)])


func _case_deck_unknown_card() -> void:
	var config := _config("ST02")
	config["deck"] = ["C23", "ZZ99"]
	var engine := BattleEngine.new()
	_say("setup=%s problems=%s" % [engine.setup(config), engine.setup_problems])


func _case_hand_size_zero() -> void:
	var engine := BattleEngine.new()
	if not engine.setup(_config("ST02", {"hand_size": 0})):
		_say("setup refused: %s" % [engine.setup_problems]); return
	_say("hand=%d | %s" % [engine.state.hand.size(), _play_out(engine)])


func _case_energy_zero() -> void:
	var engine := BattleEngine.new()
	if not engine.setup(_config("ST02", {"energy_per_turn": 0})):
		_say("setup refused: %s" % [engine.setup_problems]); return
	_say("energy=%d | %s" % [engine.state.energy, _play_out(engine)])


func _case_turn_limit_zero() -> void:
	var engine := BattleEngine.new()
	if not engine.setup(_config("ST02", {"turn_limit": 0})):
		_say("setup refused: %s" % [engine.setup_problems]); return
	# Pass every turn: nothing is played, so only a turn limit or a loss can end it.
	var turns := 0
	while not engine.state.is_over() and turns < 300:
		turns += 1
		engine.end_turn()
	_say("turn_limit()=%d, passed %d turns, outcome=%s over=%s" % [engine.turn_limit(), turns, engine.state.outcome, engine.state.is_over()])


func _case_stage_null_field() -> void:
	# Every numeric stage field set to null in turn: what happens at setup and one turn?
	var report := []
	for field: String in ["energy_per_turn", "hand_size", "gaffe_limit", "turn_limit", "win_threshold",
			"player_start", "opp_start", "bar_max", "bar_model", "time_units", "energy_mode", "opponent_count"]:
		var config := _config("ST02", {field: null})
		var engine := BattleEngine.new()
		var ok := engine.setup(config)
		var outcome := "setup refused"
		if ok:
			outcome = _play_out(engine, 60)
		report.append("%s=null -> %s" % [field, outcome])
	_say("\n    ".join(report))


func _case_card_null_number() -> void:
	var config := _config("ST02")
	var cards: Dictionary = config["cards"]
	var report := []
	for field: String in ["cost", "self_plus", "opp_minus", "guard", "draw", "gaffe"]:
		var broken: Dictionary = (cards["C23"] as Dictionary).duplicate()
		broken[field] = null
		var table := cards.duplicate()
		table["C23"] = broken
		var copy := config.duplicate()
		copy["cards"] = table
		copy["deck"] = ["C23", "C23", "C23", "C23", "C23", "C23"]
		var engine := BattleEngine.new()
		if not engine.setup(copy):
			report.append("%s=null -> setup refused" % field); continue
		report.append("%s=null -> %s" % [field, _play_out(engine, 40)])
	_say("\n    ".join(report))


func _case_zero_cost_card_loop() -> void:
	var config := _config("ST02")
	config["deck"] = ["C07", "C07", "C07", "C07", "C07", "C07"]
	var engine := BattleEngine.new()
	if not engine.setup(config):
		_say("setup refused"); return
	var plays := 0
	for i in 500:
		if not engine.state.hand.has("C07"):
			break
		if not engine.play_card("C07").get("ok", false):
			break
		plays += 1
	_say("C07 (cost %d) played %d times in one turn; energy left %d; over=%s" % [
		engine.card_cost(DataDB.get_card("C07")), plays, engine.state.energy, engine.state.is_over()])


func _case_draw_loop() -> void:
	# A deck of draw-1 cards at cost 1: how many plays in one turn?
	var config := _config("ST02", {"energy_per_turn": 3})
	config["deck"] = ["C14", "C14", "C14", "C14", "C14", "C14", "C14", "C14", "C14", "C14"]
	var engine := BattleEngine.new()
	if not engine.setup(config):
		_say("setup refused"); return
	var plays := 0
	while engine.state.hand.has("C14") and engine.play_card("C14").get("ok", false):
		plays += 1
		if plays > 100:
			break
	_say("plays in one turn with 3 energy: %d" % plays)


# --- state ------------------------------------------------------------------

func _case_meta_overflow() -> void:
	var before := GameState.meta.duplicate()
	GameState._apply_meta_reward("Funds", 1000000000000)
	var funds_high := int(GameState.meta["Funds"])
	GameState._apply_meta_reward("Funds", -1000000000000)
	var funds_low := int(GameState.meta["Funds"])
	GameState._apply_meta_reward("Reputation", 99999)
	var rep_high := int(GameState.meta["Reputation"])
	GameState._apply_meta_reward("Reputation", -99999)
	var rep_low := int(GameState.meta["Reputation"])
	GameState._apply_meta_reward("Constituency support", 2147483647)
	var con := int(GameState.meta["Constituency support"])
	_say("Funds +1e12 -> %d, -1e12 -> %d; Reputation +99999 -> %d, -99999 -> %d; Constituency +INT_MAX -> %d (was %s)" % [
		funds_high, funds_low, rep_high, rep_low, con, before])


func _case_funds_over_cap() -> void:
	GameState.meta["Funds"] = 5000000   # above the 1,000,000 hard ceiling, set directly
	GameState._apply_meta_reward("Funds", 1)
	_say("Funds set to 5,000,000 directly, then +1 -> %d (hard ceiling in the Sanban tab: 1,000,000)" % int(GameState.meta["Funds"]))


func _case_lever_missing() -> void:
	var backup: Variant = DataDB.balance.get("dues_base")
	DataDB.balance.erase("dues_base")
	Levers.balance = DataDB.balance
	GameState.meta["Party support"] = 50
	var dues := PartyDues.base_dues(PartyDues.settings(DataDB.balance), 50)
	_say("dues_base lever removed -> base dues for Party support 50 = %d (the workbook says %s)" % [dues, backup])


func _case_crisis_simultaneous() -> void:
	GameState.meta["Constituency support"] = 10
	GameState.meta["Party support"] = 0
	GameState.check_crisis_triggers()
	var alerts := []
	for a: Dictionary in GameState.pending_trigger_alerts:
		alerts.append(str(a.get("kind")))
	GameState.check_crisis_triggers()   # a second check must not fire again
	var again := GameState.pending_trigger_alerts.size()
	_say("alerts after first check: %s; total after second check: %d; special levels armed: %s" % [alerts, again, GameState.special_levels])


func _case_whip_below_floor() -> void:
	GameState.meta["Party support"] = 20   # below the whip floor of 30
	_say("Party support 20, whip floor 30, unit cost 10, 12 seats of capacity, cap 3 -> max_whips=%d; support 30 -> %d; support 45 -> %d" % [
		VoteWhip.max_whips(10, 20, 30, 12, 3), VoteWhip.max_whips(10, 30, 30, 12, 3), VoteWhip.max_whips(10, 45, 30, 12, 3)])


func _case_dues_negative_funds() -> void:
	GameState.meta["Funds"] = 0
	GameState.meta["Party support"] = 100
	var result := GameState.go_home()
	_say("go_home at Funds 0, Party support 100 -> Funds %d, Party support %d, dues_balance %d, keys=%s" % [
		int(GameState.meta["Funds"]), int(GameState.meta["Party support"]), GameState.dues_balance, result.keys()])


# --- saving -----------------------------------------------------------------

func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _case_save_corrupt() -> void:
	var path := "user://edge_corrupt.json"
	SaveManager.save_game(path)
	SaveManager.save_game(path)   # a second save makes the .bak
	_write(path, "{ this is not json")
	GameState.xp = 4242
	var ok := SaveManager.load_game(path)
	_say("garbage file with a good .bak -> load_game=%s, problem='%s'" % [ok, SaveManager.last_problem])
	_write(path, "{ nope"); DirAccess.remove_absolute(path + ".bak")
	_say("garbage file with no backup -> load_game=%s, problem='%s', xp still %d" % [SaveManager.load_game(path), SaveManager.last_problem, GameState.xp])


func _case_save_truncated() -> void:
	var path := "user://edge_trunc.json"
	SaveManager.save_game(path)
	var text := FileAccess.get_file_as_string(path)
	_write(path, text.substr(0, text.length() / 2))
	DirAccess.remove_absolute(path + ".bak")
	_say("half a save file -> load_game=%s, problem='%s'" % [SaveManager.load_game(path), SaveManager.last_problem])


func _case_save_newer_version() -> void:
	var path := "user://edge_newer.json"
	_write(path, JSON.stringify({"version": 99, "run": {"xp": 1}}))
	var before := SaveManager.enabled
	var ok := SaveManager.load_game(path)
	_say("version 99 file -> load_game=%s, problem='%s', SaveManager.enabled %s -> %s (a read of ONE file switches saving off for the session)" % [
		ok, SaveManager.last_problem, before, SaveManager.enabled])


func _case_save_wrong_types() -> void:
	var run := GameState.to_save()
	var bad := run.duplicate(true)
	bad["xp"] = "lots"; bad["meta"] = "none"; bad["calendar"] = {"week": "x", "hours": -50, "phase": 7}
	bad["booster_standing"] = {"BO01": "high", "BO99": 5}; bad["difficulty"] = "nightmare"
	bad["time_units"] = -5; bad["owned_cards"] = "all"
	GameState.load_save(bad)
	_say("wrong-typed fields -> xp=%s meta=%s calendar=%s difficulty=%s time_units=%s BO01=%s" % [
		GameState.xp, GameState.meta, GameState.calendar, GameState.difficulty, GameState.time_units, GameState.booster_standing.get("BO01")])


func _case_save_bad_deck() -> void:
	var run := GameState.to_save()
	run["deck"] = ["ZZ99", "C23"]
	GameState.load_save(run)
	var config := _config("ST02")
	var engine := BattleEngine.new()
	_say("deck after load = %s; set-up of a fight = %s %s" % [GameState.deck, engine.setup(config), engine.setup_problems])


func _case_suspend_mid_stage() -> void:
	var path := SaveManager.SAVE_PATH
	SaveManager.delete_save(path)
	GameState.xp = 777
	GameState.mid_stage = true
	SaveManager._notification(NOTIFICATION_APPLICATION_PAUSED)
	var saved_in_stage := FileAccess.file_exists(path)
	GameState.mid_stage = false
	SaveManager._notification(NOTIFICATION_APPLICATION_PAUSED)
	_say("pause while mid_stage -> save file written: %s; pause between stages -> written: %s" % [saved_in_stage, FileAccess.file_exists(path)])
	SaveManager.delete_save(path)


# --- levels and rooms -------------------------------------------------------

func _case_level_no_stage() -> void:
	var expanded := BattleSetup.expand_level({"level_id": "LVEDGE"})
	var runner := LevelRunner.new(expanded)
	_say("level with no stages -> valid=%s problems=%s finished=%s" % [runner.is_valid(), runner.problems(), runner.is_finished()])
	var unknown := LevelRunner.new(BattleSetup.expand_level({"level_id": "LVEDGE", "stage_1": "ST9999"}))
	_say("level with an unknown stage -> valid=%s problems=%s" % [unknown.is_valid(), unknown.problems()])


func _case_visitor_no_questions() -> void:
	var engine := OfficeHoursEngine.new()
	_say("Office Hours with no visitors -> setup=%s problems=%s" % [engine.setup({"visitors": []}), engine.setup_problems])
	var ghost := OfficeHoursEngine.new()
	_say("Office Hours with an unknown visitor -> setup=%s problems=%s" % [ghost.setup({"visitors": [{"visitor_id": "VI9999"}]}), ghost.setup_problems])
