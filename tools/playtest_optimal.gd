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
## Two environment variables retune what gets played, for tools/stress.sh:
##
##   PLAYTEST_PROTAGONIST   which protagonist to run as (default "PC02").
##   PLAYTEST_RANDOM_MOVES  "1" swaps the greedy best-card heuristic for
##       _play_random_cards() — a shuffled, adversarial hand instead of a
##       smart one. THIS MODE IS EXPECTED TO LOSE CONSTANTLY; a low win
##       rate is not a bug. Its only job is to explore card-play orders and
##       timings the greedy heuristic never would (discarding whole hands,
##       far more deck-empty/reshuffle cycles, far more press-conference
##       declines) while the same invariant checks below still watch for a
##       genuine rules-engine problem.
##
## Prints a running log and a final BUGS/DISCREPANCIES section: anything
## observed that contradicts what the code or CLAUDE.md itself claims
## should happen — including, as of 2026-09-28, a set of invariant checks
## (_check_invariants()) run after every play_card()/end_turn() inside a
## battle: deck+hand+discard conservation, guard/gaffe/energy bounds, and
## bar bounds (BarModel.totals_balance()). A failing battle is fully
## reproducible: every bug message inside one names the stage's own random
## seed, and BattleEngine.setup()'s "seed" config key is the one thing in
## the whole engine that determines every in-battle random roll (shuffle,
## question pool, intent rolls, the bar's stubborn-vote-cost roll — see
## test_the_same_seed_deals_the_same_hand()/test_the_same_seed_plays_the_
## same_way_twice() in the GUT suite). Not part of tools/verify.sh — a
## debugging pass, not a repeatable regression test.

const MAX_LEVEL_ATTEMPTS := 80
const MAX_STAGES := 600
const FUNDS_BUFFER := 5000   # never spend Funds below this on staff/backing

## Per-turn chance of a deliberate pass in random-move mode, and per-card
## chance of stopping early even though another affordable card exists —
## between them, a random-mode turn plays anywhere from nothing to a full
## hand, which a greedy turn never would.
const RANDOM_PASS_CHANCE := 0.15
const RANDOM_STOP_EARLY_CHANCE := 0.2

var _bugs: Array[String] = []
var _level_attempts := 0
var _stages_played := 0
var _wins := 0
var _losses := 0

var _random_moves := false
var _protagonist := "PC02"

## Reset at the top of every _play_battle_stage() call: the deck+hand+
## discard total right after setup(), which must never change for the rest
## of that stage (a committee's per-bout reset recombines all three piles
## rather than dropping anything, so the same total holds across a whole
## multi-opponent stage too).
var _expected_card_total := -1


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_random_moves = OS.get_environment("PLAYTEST_RANDOM_MOVES") == "1"
	var protagonist_override := OS.get_environment("PLAYTEST_PROTAGONIST")
	if not protagonist_override.is_empty():
		_protagonist = protagonist_override

	_log("=== PLAYTEST START (%s / %s) ===" % [
		"random-move stress" if _random_moves else "Easy greedy", _protagonist])
	GameState.start_new_run(_protagonist)
	_log("Starting meta: %s   XP: %d" % [GameState.meta, GameState.xp])

	var trial := OS.get_environment("PLAYTEST_STAGE_TRIAL")
	if not trial.is_empty():
		_run_stage_trials(trial)
		return

	# start_new_run() has already rolled the random opening deck AND made the
	# player own it (GameState.reset_collection()). Handing a second, freshly
	# rolled deck to set_deck() here used to fail with "C03 is not yours" —
	# those cards were never owned. Re-submitting the deck the run actually
	# has proves the same thing (the game accepts its own opening deck)
	# without inventing a starting condition the real game never produces.
	_log("Opening deck: %s" % [GameState.deck])
	var deck_refusal := GameState.set_deck(GameState.deck.duplicate())
	if not deck_refusal.is_empty():
		_bug("The opening deck the game dealt was refused by GameState.set_deck(): '%s'" % deck_refusal)

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

## One stage, many times, by a well-equipped player: a win-rate measurement,
## not a playthrough. PLAYTEST_STAGE_TRIAL="ST18:60" (stage:trials) or
## "ST18:60:65" (a third number overrides the stage's win threshold in
## memory only, to ask "what mark gives an even fight?"; a fourth overrides
## its energy, pool or per-turn, the same way). The player owns
## every card, plays the strongest legal deck, and has taken the backing and
## items the bot would have by mid-game, so the result is how the room plays
## for someone who has reached it, not for a fresh start.
func _run_stage_trials(spec: String) -> void:
	var parts := spec.split(":")
	var stage_id := parts[0]
	var trials := int(parts[1]) if parts.size() > 1 else 40
	if parts.size() > 2:
		for row: Dictionary in DataDB.stages:
			if str(row.get("stage_id", "")) == stage_id:
				row["win_threshold"] = int(parts[2])
				_log("Win threshold overridden to %d (memory only)" % int(parts[2]))
				if parts.size() > 3:
					row["energy_pool"] = int(parts[3])
					row["energy_per_turn"] = int(parts[3])
					_log("Energy overridden to %d (memory only)" % int(parts[3]))

	for card: Dictionary in DataDB.cards:
		var id := str(card.get("card_id", ""))
		if not GameState.owned_cards.has(id):
			GameState.owned_cards.append(id)
	GameState.xp = 2000
	GameState.meta["Funds"] = 100000
	GameState.meta["Constituency support"] = 80
	GameState.meta["Reputation"] = 80
	for booster_id: String in GameState.booster_standing.keys():
		GameState.booster_standing[booster_id] = 80
	_rebuild_deck()
	_buy_backing()
	_buy_backing()
	_buy_items()
	_log("Trial %s x%d — deck %s, backing %d, items held %s" % [
		stage_id, trials, GameState.deck, GameState.owned_modifiers.size(), GameState.inventory])

	var won := 0
	var turns_used: Array[int] = []
	var scores: Array[int] = []
	for i in trials:
		GameState.meta["Funds"] = 100000
		GameState.meta["Constituency support"] = 80
		GameState.meta["Reputation"] = 80
		_buy_items()
		var expanded := BattleSetup.expand_level({"level_id": "LVTRIAL", "stage_1": stage_id})
		var runner := LevelRunner.new(expanded)
		GameState.begin_level(runner)
		_level_items_used.clear()
		var before := _wins
		_play_battle_stage(runner.current_stage())
		if _wins > before:
			won += 1
	_log("")
	_log("=== TRIAL RESULT %s: %d / %d won (%d%%) ===" % [stage_id, won, trials, int(100.0 * won / maxi(trials, 1))])
	_report()


func _run_office_visit() -> void:
	_unlock_affordable_cards()
	_rebuild_deck()
	_unlock_next_level_if_affordable()
	_hire_cheap_staff()
	_buy_backing()
	_buy_items()


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


## Builds the best deck the collection allows, the way a player would: rank
## every owned card by what it does for its cost, then take cards from the
## top for as long as the deck stays legal (size, suit and tier limits live
## in Ledger.deck_is_legal()). It used to only top up a short deck, so a full
## random opening deck was never improved and every run lived or died on its
## opening roll.
func _rebuild_deck() -> void:
	var deck_size := Ledger.deck_size(DataDB.balance)
	var ranked: Array = []
	for card_id: String in GameState.owned_cards:
		var card := DataDB.get_card(card_id)
		if not card.is_empty():
			ranked.append(card)
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _card_strength(a) > _card_strength(b))

	var candidate: Array[String] = []
	for card: Dictionary in ranked:
		if candidate.size() >= deck_size:
			break
		var trial := candidate.duplicate()
		trial.append(str(card.get("card_id", "")))
		if Ledger.deck_is_legal(trial, GameState.owned_cards, DataDB.balance):
			candidate = trial

	if candidate.size() == deck_size and candidate != GameState.deck:
		var refusal := GameState.set_deck(candidate)
		if not refusal.is_empty():
			_bug("Ledger.deck_is_legal() approved a deck that GameState.set_deck() then refused: '%s'"
				% refusal)
		else:
			_log("  deck rebuilt to the strongest %d owned cards" % candidate.size())


## What a card is worth on paper, per point of energy spent. Used only to
## rank cards for deck building; in battle _best_first_card() judges the
## real numbers for the room.
func _card_strength(card: Dictionary) -> float:
	var cost := maxf(float(card.get("cost", 1)), 1.0)
	var gaffe := float(card.get("gaffe", 0))
	var raw := (float(card.get("self_plus", 0)) + float(card.get("opp_minus", 0))
		+ 0.5 * float(card.get("guard", 0)) + DRAW_VALUE * float(card.get("draw", 0)))
	raw -= GAFFE_PRICE * maxf(gaffe, 0.0) * 0.6
	raw += 0.5 * GAFFE_PRICE * maxf(-gaffe, 0.0)
	return raw / cost


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
# Backing (modifiers) and items — what a player does with the Office's
# other two doors, so the full-run results include their effect
# ---------------------------------------------------------------------------

## A meta value is never spent below these: Constituency support at or under
## 15 queues a Town Hall, and a player does not buy backing into a crisis.
const BACKING_FLOOR_CONSTITUENCY := 40
const BACKING_FLOOR_REPUTATION := 30
const BACKING_BUYS_PER_VISIT := 2
## XP kept back from items so cards and levels still get bought first.
const ITEM_XP_RESERVE := 120

var _backing_bought := 0
var _items_bought := 0
var _items_used := 0
var _level_items_used: Array[String] = []
var _stage_frequency: Dictionary = {}


## How often each stage ID appears across every level — the worth of a
## backing that helps one kind of room depends on how many rooms of that kind
## there are.
func _frequency_of_stage(stage_id: String) -> int:
	if _stage_frequency.is_empty():
		for level: Dictionary in DataDB.levels:
			for slot in range(1, 11):
				var id := str(level.get("stage_%d" % slot, ""))
				if not id.is_empty():
					_stage_frequency[id] = int(_stage_frequency.get(id, 0)) + 1
	return int(_stage_frequency.get(stage_id, 0))


## A rough worth for a modifier, used only to decide which to buy first.
func _backing_worth(modifier: Dictionary) -> float:
	var value := float(modifier.get("effect_value", 0))
	var target := str(modifier.get("effect_target", ""))
	match str(modifier.get("effect_type", "")):
		"STAGE_START_BONUS":
			return value * float(_frequency_of_stage(target))
		"HAND_SIZE_BONUS", "GAFFE_LIMIT_BONUS":
			return 8.0 * float(_frequency_of_stage(target))
		"RESOURCE_BONUS_ON_WIN":
			return 2.0
	return 0.5


## Buys the most useful backing the player can afford and is allowed (the
## organisation's standing has to be high enough — Ledger.modifier_refusal()
## decides that, so which organisations the bot "chooses" is simply which
## ones are warm enough). Never spends below the floors above.
func _buy_backing() -> void:
	var for_sale: Array = []
	for modifier: Dictionary in DataDB.modifiers:
		for_sale.append(modifier)
	for_sale.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _backing_worth(a) > _backing_worth(b))

	var bought := 0
	for modifier: Dictionary in for_sale:
		if bought >= BACKING_BUYS_PER_VISIT:
			return
		var mod_id := str(modifier.get("mod_id", ""))
		var costs := Ledger.modifier_costs(modifier)
		if int(GameState.meta.get("Funds", 0)) - int(costs["Funds"]) < FUNDS_BUFFER:
			continue
		if int(GameState.meta.get("Constituency support", 0)) - int(costs["Constituency support"]) < BACKING_FLOOR_CONSTITUENCY:
			continue
		if int(GameState.meta.get("Reputation", 0)) - int(costs["Reputation"]) < BACKING_FLOOR_REPUTATION:
			continue
		if GameState.owned_modifiers.has(mod_id):
			continue
		var refusal := GameState.buy_modifier(mod_id)
		if refusal.is_empty():
			bought += 1
			_backing_bought += 1
			_log("  took backing %s (%s)" % [mod_id, modifier.get("name_en")])


## Buys battle items (the ones that boost a stage or a whole level) with
## whatever XP and Funds are left once cards, levels and staff are paid for.
## Items that grant standing or a meta value, or that ask the player to pick
## a target, are left alone — those are the player's judgement calls.
func _buy_items() -> void:
	var words := Text.phrase()
	for item: Dictionary in DataDB.shop:
		if not _is_battle_item(item):
			continue
		var item_id := str(item.get("item_id", ""))
		var price := Items.costs(item)
		while true:
			if GameState.xp - int(price["XP"]) < ITEM_XP_RESERVE and int(price["XP"]) > 0:
				break
			if int(GameState.meta.get("Funds", 0)) - int(price["Funds"]) < FUNDS_BUFFER and int(price["Funds"]) > 0:
				break
			var refusal := Items.buy_refusal(item, GameState.item_count(item_id),
				int(GameState.shop_bought_this_level.get(item_id, 0)),
				GameState.xp, int(GameState.meta.get("Funds", 0)), words)
			if not refusal.is_empty():
				break
			var failed := GameState.buy_shop_item(item_id)
			if not failed.is_empty():
				_bug("Items.buy_refusal() allowed %s but GameState.buy_shop_item() refused: '%s'" % [item_id, failed])
				break
			_items_bought += 1
			_log("  bought item %s (%s)" % [item_id, item.get("name")])


## True for an item that does something to a battle and nothing else.
func _is_battle_item(item: Dictionary) -> bool:
	if not Items.usable_in(item, Items.STAGE) or Items.is_player_choice(item):
		return false
	var split := Items.split_grants(item)
	return (split["meta"] as Array).is_empty() and not (split["stage"] as Array).is_empty()


## Uses every battle item the player holds at the start of a stage. A level
## item is used once per level (it keeps running for the rest of it).
func _use_held_items(engine: BattleEngine, repro: String) -> void:
	for item_id: String in GameState.inventory.keys():
		var item := DataDB.get_shop_item(item_id)
		if not _is_battle_item(item) or GameState.item_count(item_id) <= 0:
			continue
		var is_level := Items.duration(item) == Items.DURATION_LEVEL
		if is_level and _level_items_used.has(item_id):
			continue
		var result := GameState.use_item_in_stage(item_id, engine)
		if result.get("ok", false):
			_items_used += 1
			if is_level:
				_level_items_used.append(item_id)
			_check_invariants(engine, repro, "use_item('%s')" % item_id)


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
	_level_items_used.clear()

	var guard := 0
	while GameState.is_in_level() and guard < 20:
		guard += 1
		_stages_played += 1
		if _stages_played > MAX_STAGES:
			break
		var stage: Dictionary = GameState.level_runner.current_stage()
		match str(stage.get("mode", "")):
			"Non-combat": _play_visitor_stage(stage)
			"Vote": _play_vote_stage(stage)
			_: _play_battle_stage(stage)

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

	# Explicit rather than left to BattleEngine's own randi() fallback, so a
	# bug found below can be named and replayed exactly: this same stage,
	# this same config, with "seed" set to seed_value.
	var seed_value := randi()
	config["seed"] = seed_value
	var repro := "%s seed=%d" % [stage_id, seed_value]

	var engine := BattleEngine.new()
	if not engine.setup(config):
		_bug("%s: BattleEngine.setup() failed: %s" % [repro, engine.setup_problems])
		_force_end_stage(LevelRunner.LOST)
		return

	_expected_card_total = engine.state.deck.size() + engine.state.hand.size() + engine.state.discard.size()
	_check_invariants(engine, repro, "setup()")
	if not _random_moves:
		_use_held_items(engine, repro)

	var turns := 0
	while not engine.state.is_over() and turns < 60:
		turns += 1
		if _random_moves:
			_play_random_cards(engine, repro)
		else:
			_play_best_cards(engine, repro)
		if engine.state.is_over():
			break
		var end_result := engine.end_turn()
		if not end_result.get("ok", false):
			_bug("%s: end_turn() refused mid-battle: %s" % [repro, end_result.get("reason")])
			break
		_check_invariants(engine, repro, "end_turn()")

	if turns >= 60 and not engine.state.is_over():
		_bug("%s: battle did not conclude within 60 turns (stuck at turn_limit=%s, gaffe=%d/%d)"
			% [repro, stage.get("turn_limit"), engine.state.gaffe, engine.state.gaffe_limit])

	var state := engine.state
	var gaffe_caused_loss := state.outcome == "loss" and state.gaffe >= state.gaffe_limit
	if state.outcome == "win":
		_wins += 1
	elif state.outcome == "loss":
		_losses += 1
	else:
		_bug("%s: battle ended with outcome '%s', neither win nor loss" % [repro, state.outcome])

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
## National Assembly Floor Voting (ST23, §7.7): no cards, one choice. Before
## 2026-09-28 this driver had no branch for "Vote" mode at all — every one
## of the 30 real Floor Vote levels (LV31-60) fell into _play_battle_stage()
## instead, which builds a BattleEngine config that has no idea what a bill
## or a FloorVoteEngine is. "Optimal" play here is the free, no-risk choice:
## vote with the player's own party's already-assumed majority bucket
## (FloorVoteEngine.majority_bucket(), the same "no reallocation happens"
## case FloorVoteScreen.gd itself falls into when nothing about the vote
## surprises anyone) — same as the real screen's own call shape.
func _play_vote_stage(stage: Dictionary) -> void:
	var stage_id := str(stage.get("stage_id", ""))
	var engine := FloorVoteEngine.new()
	var player_party := str(DataDB.player.get("party", ""))
	if not engine.setup({"bill": stage.get("floor_vote", {}), "player_party": player_party}):
		_bug("%s: FloorVoteEngine.setup() failed: %s" % [stage_id, engine.setup_problems])
		_force_end_stage(LevelRunner.LOST)
		return

	var own_position := {}
	for position: Dictionary in engine.positions():
		if str(position.get("party_name", "")) == player_party:
			own_position = position
	var choice := (FloorVoteEngine.majority_bucket(own_position) if not own_position.is_empty()
		else "Abstain")
	var result := engine.choose(choice)
	GameState.apply_floor_vote_favorability(result.get("favorability_deltas", {}))

	_log("  %s: voted %s on '%s' (%s) — Yes %d / No %d / Abstain %d" % [
		stage_id, choice, engine.bill().get("bill_name", "?"),
		"passed" if result.get("passed", false) else "failed",
		result["totals"]["Yes"], result["totals"]["No"], result["totals"]["Abstain"]])

	# Cannot be lost (§7.7) — always scored WON, same as VisitorScreen.gd.
	_wins += 1
	var level_over := GameState.finish_stage(LevelRunner.WON)
	if level_over:
		GameState.end_level()


func _force_end_stage(outcome: String) -> void:
	var level_over := GameState.finish_stage(outcome)
	if level_over:
		GameState.end_level()


## Play cards until nothing left is worth playing this turn: highest
## (self_plus + opp_minus + guard*0.5 + draw*0.3) first, skipping anything
## that would push the gaffe meter to its limit — "use gaffes, don't hit
## the limit."
## The competent player. Each time it is about to play, it looks at every
## combination of the cards in hand it can afford, scores each combination
## by what the cards would ACTUALLY do in this room (engine.preview(): stage
## affinity, the question's grade, whether opponent support or guard count
## here at all), and plays the first card of the best combination. It then
## looks again, because a card that draws changes the hand. Compared with the
## old "highest printed number first" rule, it spends all its energy well,
## weighs guard against the attack actually coming, treats a gaffe as a cost
## that is worth more the less of the gaffe meter is left, and uses gaffe-
## clearing cards when the meter is high.
const GAFFE_PRICE := 0.8      ## support points one gaffe point is worth to avoid (a gaffe is a budget to spend, not a thing to dodge)
const DRAW_VALUE := 2.0       ## support points one drawn card is worth
const OPPONENT_SMALL := 30    ## an opponent at or under this many supporters can be argued out
const OPPONENT_SMALL_WEIGHT := 1.6
const SPECIAL_VALUE := 3.0    ## a special effect that does nothing else (a buff, a peek)

func _play_best_cards(engine: BattleEngine, repro: String) -> void:
	var played_this_turn := 0
	while played_this_turn < 20:
		if engine.state.is_over():
			return
		var best_id := _best_first_card(engine)
		if best_id.is_empty():
			return
		var result := engine.play_card(best_id)
		if not result.get("ok", false):
			_bug("%s: play_card('%s') was pre-checked as affordable/safe but refused: %s"
				% [repro, best_id, result.get("reason")])
			return
		_check_invariants(engine, repro, "play_card('%s')" % best_id)
		played_this_turn += 1


## The first card of the best affordable, gaffe-safe combination in hand,
## or "" when nothing worth playing remains.
func _best_first_card(engine: BattleEngine) -> String:
	var state := engine.state
	var hand: Array = state.hand
	var count := mini(hand.size(), 8)   # 2^8 combinations at most
	var costs: Array[int] = []
	var values: Array[float] = []
	var gaffes: Array[int] = []
	var order_keys: Array[float] = []
	var intent := engine.current_intent()
	var incoming := float(intent.get("value", 0)) if str(intent.get("verb", "")) == "attack" else 0.0
	var gaffe_room := maxi(state.gaffe_limit - state.gaffe, 1)
	# The fewer gaffes left before the stage is lost, the dearer one is.
	var price := GAFFE_PRICE * (1.0 + 3.0 / float(gaffe_room))

	for i in count:
		var card := DataDB.get_card(str(hand[i]))
		if card.is_empty():
			costs.append(99)
			values.append(-INF)
			gaffes.append(0)
			order_keys.append(0.0)
			continue
		var fx := engine.preview(card)
		var value := float(fx.get("self_plus", 0))
		if fx.get("opp_minus_counts", true):
			# Arguing the opponent down to nothing wins outright (CLAUDE.md,
			# 2026-09-29), and it is the cheap way to win a room whose
			# opponent starts small — so a card that takes support from a
			# small opponent is worth more than the same points gained.
			var opp_weight := 1.0
			if state.bar != null and state.bar.opponent <= OPPONENT_SMALL:
				opp_weight = OPPONENT_SMALL_WEIGHT
			value += opp_weight * float(fx.get("opp_minus", 0))
		if fx.get("guard_counts", true):
			var guard := float(fx.get("guard", 0))
			var useful := minf(guard, maxf(incoming - float(state.block), 0.0))
			value += useful + 0.3 * (guard - useful)
		value += DRAW_VALUE * float(fx.get("draw", 0))
		var gaffe := int(fx.get("gaffe", 0))
		if gaffe > 0:
			value -= price * float(gaffe)
		elif gaffe < 0:
			value += price * float(mini(-gaffe, state.gaffe))   # only worth what there is to clear
		if bool(fx.get("flags", {}).get("special_triggered", false)):
			value += SPECIAL_VALUE
		costs.append(engine.card_cost(card))
		values.append(value)
		gaffes.append(gaffe)
		# Within a combination: buffs and draws first, then gaffe-clearing,
		# then everything else, so energy and gaffe room are never wasted.
		var key := float(gaffe)
		if bool(fx.get("flags", {}).get("special_triggered", false)) or int(fx.get("draw", 0)) > 0:
			key -= 100.0
		order_keys.append(key)

	var best_value := 0.0
	var best_first := -1
	for mask in range(1, 1 << count):
		var cost := 0
		var total := 0.0
		var members: Array[int] = []
		for i in count:
			if mask & (1 << i):
				cost += costs[i]
				total += values[i]
				members.append(i)
		if cost > state.energy or total <= best_value:
			continue
		members.sort_custom(func(a: int, b: int) -> bool: return order_keys[a] < order_keys[b])
		var running := state.gaffe
		var safe := true
		for i in members:
			running = maxi(running + gaffes[i], 0)
			if running >= state.gaffe_limit:
				safe = false
				break
		if not safe:
			continue
		best_value = total
		best_first = members[0]
	return "" if best_first < 0 else str(hand[best_first])


## The adversarial counterpart to _play_best_cards(), used when
## PLAYTEST_RANDOM_MOVES=1: a shuffled hand played in shuffled order, with a
## real chance of a deliberate pass and a real chance of stopping early with
## playable cards still in hand. No scoring, no gaffe avoidance — the point
## is to explore play orders and timings a competent hand never would, not
## to win. Still respects cost (an unaffordable card is never attempted,
## same as a real player who can only drag a playable card up) since the
## goal is stress, not exercising BattleEngine's own refusal path (that is
## GUT's job, e.g. test_battle_engine.gd's cost-refusal tests).
func _play_random_cards(engine: BattleEngine, repro: String) -> void:
	if randf() < RANDOM_PASS_CHANCE:
		return   # a deliberate pass, exercising the pass-penalty path (§7.2)

	var played_this_turn := 0
	while played_this_turn < 20:
		if engine.state.is_over():
			return
		var state := engine.state
		var affordable: Array[String] = []
		for card_id: String in state.hand:
			var card := DataDB.get_card(card_id)
			if not card.is_empty() and engine.card_cost(card) <= state.energy:
				affordable.append(card_id)
		if affordable.is_empty():
			return

		affordable.shuffle()
		var card_id: String = affordable[0]
		var result := engine.play_card(card_id)
		if not result.get("ok", false):
			_bug("%s: play_card('%s') was pre-checked as affordable but refused: %s"
				% [repro, card_id, result.get("reason")])
			return
		_check_invariants(engine, repro, "play_card('%s') (random mode)" % card_id)
		played_this_turn += 1

		if randf() < RANDOM_STOP_EARLY_CHANCE:
			return   # stop this turn even though another card could be played


# ---------------------------------------------------------------------------
# Invariants
# ---------------------------------------------------------------------------

## Checked after every state-mutating call inside a battle (setup(),
## play_card(), end_turn()). Nothing inside BattleEngine itself asserts
## these — it is all soft-refusal via _refused()/setup_problems (see its own
## file) — so a violation caught here is a genuine rules-engine bug, not a
## play-quality issue. `repro` names the stage and the exact seed
## (_play_battle_stage()'s own "stage_id seed=N" string) needed to replay it.
func _check_invariants(engine: BattleEngine, repro: String, moment: String) -> void:
	var state := engine.state

	var total := state.deck.size() + state.hand.size() + state.discard.size()
	if total != _expected_card_total:
		_bug("%s: card conservation broken after %s — deck+hand+discard=%d, expected %d"
			% [repro, moment, total, _expected_card_total])

	if state.energy < 0 or state.energy > state.energy_max:
		_bug("%s: energy %d out of bounds [0, %d] after %s"
			% [repro, state.energy, state.energy_max, moment])
	if state.block < 0 or state.block > state.guard_cap:
		_bug("%s: guard %d out of bounds [0, %d] after %s"
			% [repro, state.block, state.guard_cap, moment])
	if state.opponent_block < 0 or state.opponent_block > state.guard_cap:
		_bug("%s: opponent guard %d out of bounds [0, %d] after %s"
			% [repro, state.opponent_block, state.guard_cap, moment])
	if state.gaffe < 0:
		_bug("%s: gaffe %d is negative after %s" % [repro, state.gaffe, moment])
	if state.gaffe >= state.gaffe_limit and state.outcome != "loss":
		_bug("%s: gaffe %d/%d reached the limit but outcome is '%s', not 'loss', after %s"
			% [repro, state.gaffe, state.gaffe_limit, state.outcome, moment])
	if state.turn < 1:
		_bug("%s: turn counter %d is less than 1 after %s" % [repro, state.turn, moment])

	if state.bar != null:
		var bar := state.bar
		if bar.player < 0 or bar.player > bar.maximum:
			_bug("%s: bar.player %d out of bounds [0, %d] after %s"
				% [repro, bar.player, bar.maximum, moment])
		if bar.model == BarModel.Model.SHARED_POOL:
			if bar.opponent < 0 or bar.undecided < 0:
				_bug("%s: bar.opponent=%d bar.undecided=%d — one is negative after %s"
					% [repro, bar.opponent, bar.undecided, moment])
			if not bar.totals_balance():
				_bug("%s: bar totals do not balance after %s — player=%d opponent=%d undecided=%d max=%d"
					% [repro, moment, bar.player, bar.opponent, bar.undecided, bar.maximum])


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
	_log("Backing taken: %d (owned %d)   Items bought: %d   Items used: %d" % [
		_backing_bought, GameState.owned_modifiers.size(), _items_bought, _items_used])
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
