extends Node
## An automated playtest: plays the game to win, Easy difficulty (PC02),
## sequentially through the levels, looping back to replay an earlier
## unlocked level whenever Funds or XP are too short to proceed — spending
## both on cards and level unlocks along the way. Drives BattleEngine/
## OfficeHoursEngine directly, the same call sequence BattleScreen.gd and
## VisitorScreen.gd use in the real game (see their own start_battle()/
## start_visiting()), so this exercises the real rules, not a shortcut.
##
##     godot --headless --path . tools/playtest_optimal.tscn
##
## Prints a running log and a final BUGS/DISCREPANCIES section: anything
## observed that contradicts what the code or CLAUDE.md itself claims
## should happen. Not part of tools/verify.sh — a debugging pass, not a
## repeatable regression test.

const MAX_LEVEL_ATTEMPTS := 80
const MAX_STAGES := 600
const FUNDS_BUFFER := 5000   # never spend Funds below this on staff/backing

var _bugs: Array[String] = []
var _level_attempts := 0
var _stages_played := 0
var _wins := 0
var _losses := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_log("=== PLAYTEST START (Easy / PC02) ===")
	GameState.start_new_run("PC02")
	_log("Starting meta: %s   XP: %d" % [GameState.meta, GameState.xp])

	# Deal a legal starting deck rather than trust whatever reset_collection()
	# left in place, so set_deck() failures later are never blamed on a
	# starting condition this driver didn't control.
	var starter := Ledger.opening_deck(DataDB.cards, DataDB.balance)
	var deck_refusal := GameState.set_deck(starter)
	if not deck_refusal.is_empty():
		_bug("Ledger.opening_deck()'s own deck was refused by GameState.set_deck(): '%s'" % deck_refusal)

	while _level_attempts < MAX_LEVEL_ATTEMPTS and _stages_played < MAX_STAGES:
		_run_office_visit()

		var level_id := _choose_level()
		if level_id.is_empty():
			_log("No playable level found (all locked/on cooldown and unaffordable). Stopping.")
			break

		_level_attempts += 1
		_play_level(level_id)

	_report()


# ---------------------------------------------------------------------------
# Office: unlock cards, unlock the next level, hire cheap staff
# ---------------------------------------------------------------------------

func _run_office_visit() -> void:
	_unlock_affordable_cards()
	_rebuild_deck()
	_unlock_next_level_if_affordable()
	_hire_cheap_staff()


func _unlock_affordable_cards() -> void:
	var candidates: Array = []
	for card: Dictionary in DataDB.cards:
		if not GameState.owned_cards.has(str(card.get("card_id", ""))):
			candidates.append(card)
	# Cheapest first, so a small XP budget still buys something every visit.
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("xp_to_unlock", 0)) < int(b.get("xp_to_unlock", 0)))

	for card: Dictionary in candidates:
		var refusal := Ledger.card_refusal(card, GameState.owned_cards, GameState.xp)
		if refusal.is_empty():
			var bought := GameState.buy_card(str(card.get("card_id", "")))
			if not bought.is_empty():
				_bug("Ledger said %s was buyable (no refusal) but GameState.buy_card() refused: '%s'"
					% [card.get("card_id"), bought])
			else:
				_log("  bought card %s (%s) for %d XP" % [
					card.get("card_id"), card.get("name_en"), card.get("xp_to_unlock", 0)])


func _rebuild_deck() -> void:
	var deck_size := Ledger.deck_size(DataDB.balance)
	var candidate: Array[String] = GameState.deck.duplicate()
	var changed := false

	# Highest self_plus first among owned-but-unused cards — a simple
	# "biggest single swing" preference, not a real deckbuilding AI.
	var unused: Array = []
	for card_id: String in GameState.owned_cards:
		if not candidate.has(card_id):
			unused.append(DataDB.get_card(card_id))
	unused.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("self_plus", 0)) > int(b.get("self_plus", 0)))

	for card: Dictionary in unused:
		if candidate.size() >= deck_size:
			break
		var card_id := str(card.get("card_id", ""))
		var trial := candidate.duplicate()
		trial.append(card_id)
		if Ledger.deck_is_legal(trial, GameState.owned_cards, DataDB.balance):
			candidate = trial
			changed = true

	if changed:
		var refusal := GameState.set_deck(candidate)
		if not refusal.is_empty():
			_bug("Ledger.deck_is_legal() approved a deck that GameState.set_deck() then refused: '%s'"
				% refusal)
		else:
			_log("  deck now %d cards (added from owned collection)" % candidate.size())


func _unlock_next_level_if_affordable() -> void:
	for level: Dictionary in DataDB.levels:
		var level_id := str(level.get("level_id", ""))
		if GameState.levels_unlocked.has(level_id):
			continue
		var cost := Ledger.level_unlock_cost(level, GameState.staff_hired)
		if cost <= 0:
			continue   # always open, nothing to spend
		if cost <= GameState.xp:
			var refusal := GameState.unlock_level(level_id)
			if refusal.is_empty():
				_log("  unlocked level %s for %d XP" % [level_id, cost])
			else:
				_bug("level_unlock_cost said %s cost %d (affordable), GameState.unlock_level() refused: '%s'"
					% [level_id, cost, refusal])
		break   # only ever the next one — no reason to skip ahead


func _hire_cheap_staff() -> void:
	for role: String in Ledger.STAFF_ROLES:
		if not GameState.staff_hired.get(role, {}).is_empty():
			continue
		var candidates: Array = DataDB.get_staff_by_role(role)
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("hiring_cost_yen", 0)) < int(b.get("hiring_cost_yen", 0)))
		if candidates.is_empty():
			continue
		var cheapest: Dictionary = candidates[0]
		var funds := int(GameState.meta.get("Funds", 0))
		var cost := int(cheapest.get("hiring_cost_yen", 0))
		if cost > 0 and funds - cost >= FUNDS_BUFFER:
			var refusal := GameState.hire_staff(str(cheapest.get("staff_id", "")))
			if refusal.is_empty():
				_log("  hired %s (%s) for %d Yen" % [cheapest.get("name"), role, cost])


# ---------------------------------------------------------------------------
# Choosing which level to play
# ---------------------------------------------------------------------------

## Sequential order, looping back to the earliest already-completable level
## when the next one in line is locked or on cooldown — grinding for the
## Funds/XP (or the cooldown countdown, which only advances by finishing
## ANY level) the next one needs.
func _choose_level() -> String:
	var ordered: Array = DataDB.levels.duplicate()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("level_id", "")) < str(b.get("level_id", "")))

	var first_playable := ""
	for level: Dictionary in ordered:
		var level_id := str(level.get("level_id", ""))
		if not Ledger.is_level_unlocked(level, GameState.levels_unlocked, GameState.staff_hired):
			continue
		var cooldown := Ledger.level_cooldown_remaining(
			level, GameState.levels_completed_count, GameState.level_last_completed_at)
		if cooldown > 0:
			continue
		if first_playable.is_empty():
			first_playable = level_id
		# Prefer the LOWEST-numbered never-yet-attempted level — "play
		# sequentially" — and only fall back to a replay when nothing new
		# is available.
		if not GameState.level_last_completed_at.has(level_id):
			return level_id

	return first_playable


# ---------------------------------------------------------------------------
# Playing a level end to end
# ---------------------------------------------------------------------------

func _play_level(level_id: String) -> void:
	var level := DataDB.get_level(level_id)
	if level.is_empty():
		_bug("DataDB.get_level('%s') returned empty for an ID DataDB.levels itself listed" % level_id)
		return

	var expanded := BattleSetup.expand_level(level)
	var runner := LevelRunner.new(expanded)
	var problems := runner.problems()
	if not problems.is_empty():
		_bug("%s failed LevelRunner.problems(): %s" % [level_id, problems])
		return

	_log("--- Level %s (%s), %d stage(s) ---" % [level_id, level.get("name_en", ""), runner.stage_count()])
	GameState.begin_level(runner)

	var guard := 0
	while GameState.is_in_level() and guard < 20:
		guard += 1
		_stages_played += 1
		if _stages_played > MAX_STAGES:
			break
		var stage: Dictionary = GameState.level_runner.current_stage()
		if str(stage.get("mode", "")) == "Non-combat":
			_play_visitor_stage(stage)
		else:
			_play_battle_stage(stage)

	if guard >= 20:
		_bug("%s did not finish within 20 stage iterations — possible infinite stage insertion" % level_id)


func _play_battle_stage(stage: Dictionary) -> void:
	var stage_id := str(stage.get("stage_id", ""))
	var runner := GameState.level_runner
	var config := BattleSetup.for_playtest_stage(stage, runner.carried_buffs(), GameState.meta)
	if config.is_empty():
		_bug("%s: BattleSetup.for_playtest_stage() returned an empty config" % stage_id)
		_force_end_stage(LevelRunner.LOST)
		return
	config["item_bonuses"] = GameState.take_item_bonuses_for_stage()

	var engine := BattleEngine.new()
	if not engine.setup(config):
		_bug("%s: BattleEngine.setup() failed: %s" % [stage_id, engine.setup_problems])
		_force_end_stage(LevelRunner.LOST)
		return

	var turns := 0
	while not engine.state.is_over() and turns < 60:
		turns += 1
		_play_best_cards(engine)
		if engine.state.is_over():
			break
		var end_result := engine.end_turn()
		if not end_result.get("ok", false):
			_bug("%s: end_turn() refused mid-battle: %s" % [stage_id, end_result.get("reason")])
			break

	if turns >= 60 and not engine.state.is_over():
		_bug("%s: battle did not conclude within 60 turns (stuck at turn_limit=%s, gaffe=%d/%d)"
			% [stage_id, stage.get("turn_limit"), engine.state.gaffe, engine.state.gaffe_limit])

	var state := engine.state
	var gaffe_caused_loss := state.outcome == "loss" and state.gaffe >= state.gaffe_limit
	if state.outcome == "win":
		_wins += 1
	elif state.outcome == "loss":
		_losses += 1
	else:
		_bug("%s: battle ended with outcome '%s', neither win nor loss" % [stage_id, state.outcome])

	_log("  %s: %s (score=%d gaffe=%d/%d turn=%d/%s)" % [
		stage_id, state.outcome, state.player_score(), state.gaffe, state.gaffe_limit,
		state.turn, stage.get("turn_limit")])

	var level_over := GameState.finish_stage(
		state.outcome, state.player_score(), engine.pleased_boosters(), gaffe_caused_loss, state.gaffe)
	if level_over:
		GameState.end_level()


func _play_visitor_stage(stage: Dictionary) -> void:
	var stage_id := str(stage.get("stage_id", ""))
	var engine := OfficeHoursEngine.new()
	if not engine.setup({"visitors": stage.get("visitors", [])}):
		_bug("%s: OfficeHoursEngine.setup() failed: %s" % [stage_id, engine.setup_problems])
		_force_end_stage(LevelRunner.LOST)
		return

	var guard := 0
	while not engine.is_finished() and guard < 20:
		guard += 1
		var question: Dictionary = engine.current_question()
		var correct := str(question.get("correct_choice", "A"))
		var result := engine.answer(correct)   # always answer correctly — optimizing for wins
		var entries: Array = result.get("reward") if result.get("correct", false) else result.get("penalty")
		GameState.apply_visitor_reward_entries(entries)
		if result.get("correct", false) != true:
			_bug("%s: answering the documented correct_choice ('%s') was graded wrong" % [stage_id, correct])
		engine.advance()

	if guard >= 20:
		_bug("%s: OfficeHoursEngine did not finish within 20 visitors" % stage_id)

	_log("  %s: visitor room complete (%d visitors)" % [stage_id, engine.visitor_count()])
	_wins += 1   # per VisitorScreen.gd: always scored WON
	var level_over := GameState.finish_stage(LevelRunner.WON)
	if level_over:
		GameState.end_level()


## Used only when setup() itself failed — GameState still needs to be told
## the stage is over or the level would hang GameState.is_in_level() forever.
func _force_end_stage(outcome: String) -> void:
	var level_over := GameState.finish_stage(outcome)
	if level_over:
		GameState.end_level()


## Play cards until nothing left is worth playing this turn: highest
## (self_plus + opp_minus + guard*0.5 + draw*0.3) first, skipping anything
## that would push the gaffe meter to its limit — "use gaffes, don't hit
## the limit."
func _play_best_cards(engine: BattleEngine) -> void:
	var played_this_turn := 0
	while played_this_turn < 20:
		if engine.state.is_over():
			return
		var state := engine.state
		var best_id := ""
		var best_score := -INF
		for card_id: String in state.hand:
			var card := DataDB.get_card(card_id)
			if card.is_empty():
				continue
			var cost := engine.card_cost(card)
			if cost > state.energy:
				continue
			var gaffe := int(card.get("gaffe", 0))
			if gaffe > 0 and state.gaffe + gaffe >= state.gaffe_limit:
				continue   # would reach or exceed the limit — never play it
			var score := (float(card.get("self_plus", 0)) + float(card.get("opp_minus", 0))
				+ float(card.get("guard", 0)) * 0.5 + float(card.get("draw", 0)) * 0.3
				- float(maxi(gaffe, 0)) * 0.2)
			if score > best_score:
				best_score = score
				best_id = card_id

		if best_id.is_empty():
			return

		var result := engine.play_card(best_id)
		if not result.get("ok", false):
			_bug("play_card('%s') was pre-checked as affordable/safe but refused: %s"
				% [best_id, result.get("reason")])
			return
		played_this_turn += 1


# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

func _log(message: String) -> void:
	print(message)


func _bug(message: String) -> void:
	var entry := "[level_attempt=%d stage=%d] %s" % [_level_attempts, _stages_played, message]
	_bugs.append(entry)
	print("  !! BUG: " + entry)


func _report() -> void:
	_log("")
	_log("=== PLAYTEST SUMMARY ===")
	_log("Level attempts: %d   Stages played: %d   Wins: %d   Losses: %d"
		% [_level_attempts, _stages_played, _wins, _losses])
	_log("Levels completed at least once: %d / %d" % [
		GameState.level_last_completed_at.size(), DataDB.levels.size()])
	_log("Final meta: %s   XP: %d" % [GameState.meta, GameState.xp])
	_log("Owned cards: %d / %d   Deck size: %d" % [
		GameState.owned_cards.size(), DataDB.cards.size(), GameState.deck.size()])
	_log("Staff hired: %d / %d roles" % [GameState.staff_hired.size(), Ledger.STAFF_ROLES.size()])
	_log("Lifetime gaffes: %d   Stages lost to gaffes: %d   Gaffe penalty applied: %s"
		% [GameState.lifetime_gaffes, GameState.stages_lost_to_gaffes, GameState.gaffe_penalty_applied])
	_log("stage_type_results: %s" % [GameState.stage_type_results])
	_log("")

	if _bugs.is_empty():
		_log("No bugs or discrepancies observed.")
	else:
		_log("=== %d BUG(S) / DISCREPANCIES ===" % _bugs.size())
		for b: String in _bugs:
			_log("  - " + b)

	get_tree().quit(0 if _bugs.is_empty() else 1)
