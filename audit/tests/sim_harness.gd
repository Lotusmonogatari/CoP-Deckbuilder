extends Node
## Audit Phase 4: a headless, seeded simulation harness.
##
## Plays every Combat room with the real rules (BattleEngine, BattleSetup,
## LevelRunner), under two policies, and checks the frozen invariants after
## every action. It changes nothing on disk except its own JSON result.
##
##     AUDIT_POLICY=greedy|random   which policy plays (default greedy)
##     AUDIT_KIT=starter|full       opening deck only, or every card and backing
##     AUDIT_PC=PC02                protagonist
##     AUDIT_TRIALS=25              fights per room
##     AUDIT_SEED=1                 base seed; every fight's seed derives from it
##     AUDIT_PRESSURE=standard      relaxed | standard | harder
##     AUDIT_STAGES=ST02;ST05       optional: only these rooms
##     AUDIT_OUT=/path/out.json     where the result goes
##
##     .tools/godot --headless --path . audit/tests/sim_harness.tscn
##
## POLICIES
##   random  shuffles the affordable cards and plays them until energy runs
##           out, stopping early 20% of the time and passing 10% of turns.
##   (random never plays a card that makes you discard; greedy does.)
##   greedy  each step plays the affordable card with the best immediate
##           value (support gained, opponent support removed where it counts,
##           guard only against an attack that is coming, draw), refusing any
##           card that would fill the gaffe meter.
##
## WHAT IS SEEDED
##   The battle (draws, intents, conversions) by config["seed"]; the opening
##   deck by Ledger.opening_deck's seed; Godot's global generator by seed().
##   Who is seated comes from BattleSetup's own randomize()d generator, which
##   cannot be seeded from outside (audit/phase0_orientation.md section 4), so
##   the seated opponent is recorded instead and determinism is tested on the
##   engine with one fixed config (see determinism_check()).

const PASS_CHANCE := 0.10
const STOP_EARLY_CHANCE := 0.20
const MAX_TURNS := 80

var _policy := "greedy"
var _kit := "starter"
var _trials := 25
var _base_seed := 1
var _rng := RandomNumberGenerator.new()
var _violations: Array = []
var _card_tally := {}
var _suit_tally := {}
var _play_usec: Array[int] = []
var _end_usec: Array[int] = []
var _stage_usec: Array[int] = []
var _emits := {}
var _bar_model := ""


func _ready() -> void:
	_run.call_deferred()


func _env(name: String, fallback: String) -> String:
	var value := OS.get_environment(name)
	return fallback if value.is_empty() else value


func _run() -> void:
	_policy = _env("AUDIT_POLICY", "greedy")
	_kit = _env("AUDIT_KIT", "starter")
	_trials = int(_env("AUDIT_TRIALS", "25"))
	_base_seed = int(_env("AUDIT_SEED", "1"))
	var pc := _env("AUDIT_PC", "PC02")
	var pressure := _env("AUDIT_PRESSURE", "standard")
	seed(_base_seed)
	_rng.seed = _base_seed * 7919 + 13

	DataDB.clear_runtime()
	GameState.start_new_run(pc, pressure)
	_equip(pc)
	_watch_signals()

	var wanted := _env("AUDIT_STAGES", "")
	var only: Array = wanted.split(";", false) if not wanted.is_empty() else []
	var rooms := []
	var index := 0
	for stage: Dictionary in DataDB.stages:
		index += 1
		if str(stage.get("mode", "")) != "Combat":
			continue
		var stage_id := str(stage.get("stage_id", ""))
		if not only.is_empty() and not only.has(stage_id):
			continue
		if stage_id == MpVisit.FIGHT_STAGE:
			rooms.append({"stage_id": stage_id, "skipped": "exists only inside a sponsored-bill level"})
			continue
		rooms.append(_play_room(stage, index))

	var result := {
		"meta": {"policy": _policy, "kit": _kit, "pc": pc, "pressure": pressure, "trials": _trials,
			"seed": _base_seed, "deck": GameState.deck, "backings": GameState.owned_modifiers.size(),
			"date": Time.get_datetime_string_from_system()},
		"rooms": rooms,
		"cards": _card_tally, "suits": _suit_tally,
		"violations": _violations,
		"perf": {"play_card_usec": _stats(_play_usec), "end_turn_usec": _stats(_end_usec),
			"stage_usec": _stats(_stage_usec), "eventbus_emits": _emits,
			"static_mb_end": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
			"objects_end": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
			"orphans_end": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))},
		"determinism": determinism_check(),
	}
	var out := _env("AUDIT_OUT", "user://audit_sim.json")
	var file := FileAccess.open(out, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(result))
		file.close()
	var won := 0
	var fought := 0
	for room: Dictionary in rooms:
		won += int(room.get("wins", 0))
		fought += int(room.get("n", 0))
	print("AUDIT SIM %s/%s/%s seed %d: %d of %d fights won, %d invariant violations -> %s" % [
		_policy, _kit, pc, _base_seed, won, fought, _violations.size(), out])
	get_tree().quit(0)


## Starter: the opening deck, dealt from a seed. Full: every card owned, the
## 15 strongest by printed value per energy in the deck, every backing owned,
## standing and meta high (in memory only; nothing is saved).
func _equip(pc: String) -> void:
	if _kit == "starter":
		GameState.deck = Ledger.opening_deck(DataDB.cards, DataDB.balance, _base_seed * 100 + pc.hash() % 97)
		return
	var scored := []
	GameState.owned_cards.clear()
	for card: Dictionary in DataDB.cards:
		var id := str(card.get("card_id", ""))
		GameState.owned_cards.append(id)
		var cost := maxi(_n(card, "cost"), 1)
		var value := float(_n(card, "self_plus") + _n(card, "opp_minus")) + 0.5 * _n(card, "guard") \
			+ 1.5 * _n(card, "draw") - 1.5 * _n(card, "gaffe")
		scored.append([value / cost, id])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var chosen: Array[String] = []
	for entry: Array in scored:
		if chosen.size() < GameState.deck_size():
			chosen.append(str(entry[1]))
	GameState.deck = chosen
	for key: String in ["Constituency support", "Reputation", "Party support"]:
		GameState.meta[key] = 80
	for booster_id: String in GameState.booster_standing.keys():
		GameState.booster_standing[booster_id] = 80
	for modifier: Dictionary in DataDB.modifiers:
		var mod_id := str(modifier.get("mod_id", ""))
		if not mod_id.is_empty() and not GameState.owned_modifiers.has(mod_id):
			GameState.owned_modifiers.append(mod_id)


## The full kit's deck for one room: every card valued by the room's own
## preview (affinity applied, opponent-lowering ignored where it does nothing),
## per point of energy, best first.
func _build_room_deck(engine: BattleEngine) -> void:
	var scored := []
	for card: Dictionary in DataDB.cards:
		var effect := engine.preview(card)
		var value := float(int(effect.get("self_plus", 0))) + 0.5 * float(int(effect.get("guard", 0))) \
			+ 1.5 * float(int(effect.get("draw", 0))) - 1.5 * float(int(effect.get("gaffe", 0)))
		if bool(effect.get("opp_minus_counts", true)):
			value += float(int(effect.get("opp_minus", 0)))
		scored.append([value / float(maxi(_n(card, "cost"), 1)), str(card.get("card_id", ""))])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var chosen: Array[String] = []
	for entry: Array in scored:
		if chosen.size() < GameState.deck_size():
			chosen.append(str(entry[1]))
	GameState.deck = chosen


func _n(row: Dictionary, key: String) -> int:
	var value: Variant = row.get(key)
	return int(value) if (value is int or value is float) else 0


func _watch_signals() -> void:
	for name: String in ["card_played", "turn_started", "turn_ended", "intent_revealed",
			"gaffe_changed", "battle_ended", "meta_changed", "xp_changed"]:
		_emits[name] = 0
	# Counted for real: whatever the rules layer and GameState emit while the
	# harness runs (the battle SCREEN's own emissions are not exercised here).
	EventBus.card_played.connect(func(_a: Variant, _b: Variant) -> void: _emits["card_played"] += 1)
	EventBus.turn_started.connect(func(_a: Variant) -> void: _emits["turn_started"] += 1)
	EventBus.turn_ended.connect(func(_a: Variant) -> void: _emits["turn_ended"] += 1)
	EventBus.intent_revealed.connect(func(_a: Variant) -> void: _emits["intent_revealed"] += 1)
	EventBus.gaffe_changed.connect(func(_a: Variant, _b: Variant, _c: Variant, _d: Variant) -> void: _emits["gaffe_changed"] += 1)
	EventBus.battle_ended.connect(func(_a: Variant, _b: Variant) -> void: _emits["battle_ended"] += 1)
	EventBus.meta_changed.connect(func(_a: Variant, _b: Variant, _c: Variant) -> void: _emits["meta_changed"] += 1)
	EventBus.xp_changed.connect(func(_a: Variant, _b: Variant) -> void: _emits["xp_changed"] += 1)


func _play_room(stage_row: Dictionary, index: int) -> Dictionary:
	var stage_id := str(stage_row.get("stage_id", ""))
	var wins := 0
	var turns_won: Array[int] = []
	var turns_all: Array[int] = []
	var causes := {}
	var cards_per_fight := 0
	var opponents := 1
	_bar_model = str(stage_row.get("bar_model", ""))
	var limit := 0
	var problems := 0
	for trial in _trials:
		var fight_seed := _base_seed * 1000003 + index * 1009 + trial
		seed(fight_seed)
		if _kit == "starter":
			# A fresh opening deck for every fight, from the fight's own seed, so
			# one lucky or unlucky deal does not decide a whole room's number.
			GameState.deck = Ledger.opening_deck(DataDB.cards, DataDB.balance, fight_seed)
		var expanded := BattleSetup.expand_level({"level_id": "LVAUDIT", "stage_1": stage_id})
		var runner := LevelRunner.new(expanded)
		if not runner.is_valid():
			problems += 1
			continue
		var stage: Dictionary = runner.current_stage()
		var config := BattleSetup.for_playtest_stage(stage, runner.carried_buffs(), GameState.meta)
		if config.is_empty():
			problems += 1
			continue
		config["seed"] = fight_seed
		var engine := BattleEngine.new()
		if not engine.setup(config):
			problems += 1
			continue
		if _kit == "full" and trial == 0:
			# A late player builds the deck for the room: the 15 cards worth most
			# here (this room's affinity; no credit for numbers the room ignores).
			_build_room_deck(engine)
		if _kit == "full":
			config = BattleSetup.for_playtest_stage(stage, runner.carried_buffs(), GameState.meta)
			config["seed"] = fight_seed
			engine = BattleEngine.new()
			if not engine.setup(config):
				problems += 1
				continue
		var fight := _fight(engine, stage_id, fight_seed)
		opponents = int(fight["opponents"])
		limit = engine.turn_limit()
		turns_all.append(int(fight["turns"]))
		cards_per_fight += int(fight["cards"])
		if fight["outcome"] == "win":
			wins += 1
			turns_won.append(int(fight["turns"]))
		else:
			var cause := str(fight["cause"])
			causes[cause] = int(causes.get(cause, 0)) + 1
	var fought := turns_all.size()
	return {
		"stage_id": stage_id, "name": str(stage_row.get("name_en", "")),
		"bar_model": str(stage_row.get("bar_model", "")), "n": fought, "wins": wins,
		"sequence_mode": str(stage_row.get("sequence_mode", "")), "opponent_count": opponents,
		"background_id": str(stage_row.get("background_id", "")),
		"energy_mode": str(stage_row.get("energy_mode", "")),
		"turn_limit": limit, "turns_won_mean": _mean(turns_won), "turns_all_mean": _mean(turns_all),
		"cards_per_fight": snappedf(float(cards_per_fight) / maxi(fought, 1), 0.1),
		"loss_causes": causes, "setup_problems": problems,
	}


func _fight(engine: BattleEngine, stage_id: String, fight_seed: int) -> Dictionary:
	var where := "%s seed=%d" % [stage_id, fight_seed]
	var total := engine.state.deck.size() + engine.state.hand.size() + engine.state.discard.size()
	var started := Time.get_ticks_usec()
	var turns := 0
	var cards := 0
	_check(engine, where, "setup", total)
	while not engine.state.is_over() and turns < MAX_TURNS:
		turns += 1
		cards += _take_turn(engine, where, total)
		if engine.state.is_over():
			break
		var before := Time.get_ticks_usec()
		var ended := engine.end_turn()
		_end_usec.append(Time.get_ticks_usec() - before)
		if not ended.get("ok", false):
			_violations.append({"inv": "INV-12", "where": where, "what": "end_turn refused: %s" % str(ended.get("reason"))})
			break
		_check(engine, where, "end_turn", total)
	_stage_usec.append(Time.get_ticks_usec() - started)
	var state := engine.state
	if not state.is_over():
		_violations.append({"inv": "INV-12", "where": where, "what": "not over after %d turns" % turns})
	if state.is_over() and not (state.outcome in ["win", "loss", "retry"]):
		_violations.append({"inv": "INV-12", "where": where, "what": "outcome '%s'" % state.outcome})
	var limit := engine.turn_limit()
	if limit > 0 and state.turn > limit + 1:
		_violations.append({"inv": "INV-12", "where": where, "what": "turn %d past the limit %d" % [state.turn, limit]})
	var cause := ""
	if state.outcome != "win":
		if state.gaffe >= state.gaffe_limit:
			cause = "gaffes"
		elif state.bar != null and state.bar.player <= 0:
			cause = "argued_out"
		elif state.outcome == "retry":
			cause = "no_decision"
		elif _bar_model == "Single":
			cause = "tone_short"       # a press conference judged below its line
		elif _bar_model == "Survival" and limit > 0 and state.turn < limit:
			cause = "below_line"       # fell under the rising line before the last turn
		else:
			cause = "turn_limit"
	return {"outcome": state.outcome, "turns": turns, "cards": cards, "cause": cause,
		"opponents": maxi(state.opponent_count, 1)}


func _take_turn(engine: BattleEngine, where: String, total: int) -> int:
	var played := 0
	if _policy == "random" and _rng.randf() < PASS_CHANCE:
		return 0
	while played < 30 and not engine.state.is_over():
		var plan := {"id": _pick_random(engine)} if _policy == "random" else _pick_greedy(engine)
		var pick := str(plan.get("id", ""))
		if pick.is_empty():
			break
		var card := DataDB.get_card(pick)
		var before := Time.get_ticks_usec()
		var result := engine.play_card(pick, plan.get("discards", []))
		_play_usec.append(Time.get_ticks_usec() - before)
		if not result.get("ok", false):
			_violations.append({"inv": "harness", "where": where, "what": "play refused: %s" % str(result.get("reason"))})
			break
		played += 1
		_card_tally[pick] = int(_card_tally.get(pick, 0)) + 1
		var suit := str(card.get("suit", ""))
		_suit_tally[suit] = int(_suit_tally.get(suit, 0)) + 1
		_check(engine, where, "play %s" % pick, total)
		if _policy == "random" and _rng.randf() < STOP_EARLY_CHANCE:
			break
	return played


func _affordable(engine: BattleEngine) -> Array[String]:
	var found: Array[String] = []
	for card_id: String in engine.state.hand:
		var card := DataDB.get_card(card_id)
		if card.is_empty() or engine.card_cost(card) > engine.state.energy:
			continue
		if engine.discard_required(card) > 0:
			continue   # the random policy never plays a card that makes you discard
		found.append(card_id)
	return found


func _pick_random(engine: BattleEngine) -> String:
	var options := _affordable(engine)
	if options.is_empty():
		return ""
	return options[_rng.randi_range(0, options.size() - 1)]


## What one card is worth right now (before dividing by its cost); a card that
## would fill the gaffe meter is worth less than nothing.
func _value(engine: BattleEngine, card: Dictionary) -> float:
	var state := engine.state
	var effect := engine.preview(card)
	var gaffe := int(effect.get("gaffe", 0))
	if state.gaffe + gaffe >= state.gaffe_limit:
		return -1000.0
	var value := float(int(effect.get("self_plus", 0)))
	if bool(effect.get("opp_minus_counts", true)):
		value += float(int(effect.get("opp_minus", 0)))
	if str(engine.current_intent().get("verb", "")) == "attack" and bool(effect.get("guard_counts", true)) \
			and state.block < state.guard_cap:
		value += 0.75 * float(mini(int(effect.get("guard", 0)), state.guard_cap - state.block))
	value += 1.5 * float(int(effect.get("draw", 0)))
	value -= 1.5 * float(gaffe)
	if bool(effect.get("flags", {}).get("special_triggered", false)):
		value += 0.5
	return value


## {"id": card, "discards": [cards]} or {} when nothing is worth playing. A
## card that makes you discard throws away the least valuable other cards, and
## is charged half of what they were worth (the hand is discarded at the end of
## the turn anyway).
func _pick_greedy(engine: BattleEngine) -> Dictionary:
	var state := engine.state
	var worth := {}
	for card_id: String in state.hand:
		var card := DataDB.get_card(card_id)
		worth[card_id] = _value(engine, card) if not card.is_empty() else 0.0
	var best := {}
	var best_value := 0.0
	for card_id: String in state.hand:
		var card := DataDB.get_card(card_id)
		if card.is_empty() or engine.card_cost(card) > state.energy:
			continue
		var value: float = worth[card_id]
		var discards: Array = []
		var needed := engine.discard_required(card)
		if needed > 0:
			if not engine.play_block(card).is_empty():
				continue
			var others: Array = state.hand.duplicate()
			others.erase(card_id)
			if others.size() < needed:
				continue
			others.sort_custom(func(a: String, b: String) -> bool: return float(worth[a]) < float(worth[b]))
			discards = others.slice(0, needed)
			for thrown: String in discards:
				value -= 0.5 * maxf(float(worth[thrown]), 0.0)
		value /= float(maxi(engine.card_cost(card), 1))
		if value > best_value:
			best_value = value
			best = {"id": card_id, "discards": discards}
	return best


## The frozen invariants that can be seen from a battle's state (benchmarks.md
## section C). Each failure is recorded with the stage and seed to replay it.
func _check(engine: BattleEngine, where: String, after: String, total: int) -> void:
	var state := engine.state
	var bad := func(inv: String, what: String) -> void:
		if _violations.size() < 400:
			_violations.append({"inv": inv, "where": where, "after": after, "what": what})
	if state.block > state.guard_cap or state.block < 0:
		bad.call("INV-05", "guard %d outside 0..%d" % [state.block, state.guard_cap])
	if state.energy < 0:
		bad.call("INV-06", "energy %d" % state.energy)
	if state.energy_mode == "per_turn" and state.energy > state.energy_max + 20:
		bad.call("INV-06", "energy %d far above the refill %d" % [state.energy, state.energy_max])
	if state.gaffe < 0:
		bad.call("INV-28", "gaffe %d" % state.gaffe)
	if state.gaffe >= state.gaffe_limit and state.outcome != "loss":
		bad.call("INV-07", "gaffe meter full (%d of %d) but outcome is '%s'" % [state.gaffe, state.gaffe_limit, state.outcome])
	if state.deck.size() + state.hand.size() + state.discard.size() != total:
		bad.call("INV-28", "cards in play %d, started with %d" % [
			state.deck.size() + state.hand.size() + state.discard.size(), total])
	if state.bar != null:
		if state.bar.player < 0 or state.bar.opponent < 0 or state.bar.undecided < 0:
			bad.call("INV-28", "bar below zero: you %d, them %d, undecided %d" % [
				state.bar.player, state.bar.opponent, state.bar.undecided])
		for number: Variant in [state.bar.player, state.bar.opponent]:
			if number is float and (is_nan(number) or is_inf(number)):
				bad.call("INV-28", "bar holds NaN or infinity")


## INV-26: one fixed room and deck, the same seed twice, must give the same
## fight move for move; a different seed should give a different one.
func determinism_check() -> Dictionary:
	var stage_id := "ST02"
	var logs := []
	# Two separate set-ups under the same global seed: are the same people seated?
	var seated := []
	for attempt in 2:
		seed(99)
		var again := BattleSetup.expand_level({"level_id": "LVAUDIT", "stage_1": stage_id})
		var again_runner := LevelRunner.new(again)
		var again_config := BattleSetup.for_playtest_stage(again_runner.current_stage(), again_runner.carried_buffs(), GameState.meta)
		seated.append(str(again_config.get("opponent", {}).get("opp_id", "")))
	# One set-up, copied, so only the engine's own seed differs between fights.
	var expanded := BattleSetup.expand_level({"level_id": "LVAUDIT", "stage_1": stage_id})
	var runner := LevelRunner.new(expanded)
	var base_config := BattleSetup.for_playtest_stage(runner.current_stage(), runner.carried_buffs(), GameState.meta)
	for attempt in 3:
		var config: Dictionary = base_config.duplicate(true)
		config["seed"] = 424242 if attempt < 2 else 424243
		seed(1000 + attempt)   # a different global seed each time, on purpose
		var engine := BattleEngine.new()
		if not engine.setup(config):
			return {"ran": false}
		var trace := []
		var turns := 0
		var keep_policy := _policy
		_policy = "greedy"
		while not engine.state.is_over() and turns < MAX_TURNS:
			turns += 1
			while not engine.state.is_over():
				var plan := _pick_greedy(engine)
				var pick := str(plan.get("id", ""))
				if pick.is_empty():
					break
				engine.play_card(pick, plan.get("discards", []))
				trace.append("%s:%d" % [pick, engine.state.player_score()])
			if engine.state.is_over():
				break
			engine.end_turn()
			trace.append("end:%d:%d" % [engine.state.player_score(), engine.state.gaffe])
		_policy = keep_policy
		logs.append({"trace": "|".join(trace)})
	return {
		"ran": true, "stage": stage_id,
		"same_global_seed_seats_same_opponent": seated[0] == seated[1],
		"seated": seated,
		"same_engine_seed_same_fight": logs[0]["trace"] == logs[1]["trace"],
		"other_engine_seed_differs": logs[0]["trace"] != logs[2]["trace"],
	}


func _mean(values: Array[int]) -> float:
	if values.is_empty():
		return 0.0
	var sum := 0
	for value in values:
		sum += value
	return snappedf(float(sum) / values.size(), 0.01)


func _stats(values: Array[int]) -> Dictionary:
	if values.is_empty():
		return {"n": 0}
	var sorted := values.duplicate()
	sorted.sort()
	var sum := 0
	for value in sorted:
		sum += value
	return {"n": sorted.size(), "mean": snappedf(float(sum) / sorted.size(), 0.1),
		"median": sorted[sorted.size() / 2], "p95": sorted[int(sorted.size() * 0.95)],
		"max": sorted[sorted.size() - 1]}
