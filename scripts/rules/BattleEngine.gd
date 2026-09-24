class_name BattleEngine
extends RefCounted
## Runs a single battle, start to finish.
##
## This is the referee. It knows the rules and nothing else — no screens, no
## animation, no sound, no autoloads. You hand it the stage data and a deck,
## call play_card() and end_turn(), and it tells you what happened. That's
## what makes it testable: the whole battle runs in memory in a fraction of a
## second, with no game window open.
##
## TYPICAL USE
##     var engine := BattleEngine.new()
##     engine.setup({ "stage": stage, "opponent": opponent, ... })
##     engine.play_card("C01")
##     engine.end_turn()
##     if engine.state.is_over(): ...
##
## THE TURN, in the order the brief sets out:
##   1. The opponent's intent for this turn is known and can be shown.
##   2. Energy refills. Anything unspent last turn is gone.
##   3. The player plays cards, paying their cost.
##   4. End of turn: the rest of the hand is discarded (a rules.json switch).
##   5. The opponent acts on its intent.
##   6. Win and loss are checked, the turn counter moves on, a new hand is
##      drawn.

var state := BattleState.new()

## Which stage IDs use the per-member committee model (§7.5) rather than a
## shared support bar. ST01 plus the ten workbook committees, ST09-ST18. ST08
## (Party Steering Committee) LOOKS like a committee by name but plays the
## same shared-pool model as ST03/ST05 — CLAUDE.md §7.3 is explicit that it is
## not one of these.
##
## Hardcoded rather than read from stages.json because nothing in the new
## workbook data distinguishes a committee stage from a shared-pool one:
## ST18 (a committee) and ST21 (not one) have the same bar_unit/bar_value_kind
## shape. DataDB.gd keeps the same list for the same reason, under
## `is_committee_stage()` — rules code cannot read DataDB, so it cannot be
## deduplicated further than "keep both lists in sync if this ever changes."
const COMMITTEE_STAGE_IDS := [
	"ST01", "ST09", "ST10", "ST11", "ST12", "ST13", "ST14", "ST15", "ST16",
	"ST17", "ST18",
]

## True for a committee stage. A STAGE THAT SAYS WHAT IT WANTS GETS IT, same
## rule BarModel.for_stage() already follows for bar_model "single"/
## "survival"/"shared_pool" — a "committee" value here is checked first, and
## only a stage with none at all (every canon row today) falls back to
## COMMITTEE_STAGE_IDS above. Kept in step with DataDB.is_committee_stage(),
## which makes the same check for the same reason (rules code cannot read
## DataDB, so the fallback list has to be duplicated; the data-driven path
## does not).
## A string field that may be an explicit JSON null (stages.json's optional
## "living rules" columns, 2026-09-24 — every canon row carries the key even
## where it is blank) rather than genuinely absent. str(null) is the literal
## text "<null>", not "", so the null has to be caught before the str() cast
## or a blank cell stops looking blank and a default never applies.
## Lowercased so a workbook cell can read naturally ("Pool", "Continuous")
## while every comparison against it (state.energy_mode == "pool",
## _sequence_mode == "reset", etc.) can stay a plain lowercase literal.
static func _string_field(stage: Dictionary, key: String, fallback: String) -> String:
	var value: Variant = stage.get(key)
	return str(value).to_lower() if value != null else fallback


static func is_committee_stage(stage: Dictionary) -> bool:
	var declared: Variant = stage.get("bar_model")
	if declared != null and not str(declared).is_empty():
		return str(declared).to_lower() == "committee"
	return COMMITTEE_STAGE_IDS.has(str(stage.get("stage_id", "")))

# --- Everything the engine was given at setup ------------------------------
var _stage: Dictionary = {}
var _opponent: Dictionary = {}
var _cards: Dictionary = {}        ## card_id -> card row
var _affinity: Dictionary = {}     ## element -> { stage_id -> multiplier }
var _rules: Dictionary = {}
var _meta: Dictionary = {}         ## Jiban, Kanban, Kaban, Party support

## Every sentence this engine says to the player, from the workbook.
var _words: Phrase = Phrase.new()
var _intents: IntentRunner = null
var _rng := RandomNumberGenerator.new()

## Everyone to be argued with in this stage, in order, and how they follow
## one another.
##
##   "single"      one opponent, the ordinary case
##   "reset"       the committee: separate arguments, everything starts
##                 fresh against each new opponent
##   "continuous"  the floor debate: one room, one clock, and the next
##                 opponent inherits whatever the last one left behind
var _opponents: Array = []
var _sequence_mode := "single"

## The reporters' questions, in a press conference. Empty everywhere else.
var _questions: Array = []

## Anything that stopped setup from working, in plain words.
var setup_problems := PackedStringArray()

## True when this opponent had no pattern of their own and is using the
## shared default from rules.json. Worth surfacing: it means the opponent is
## behaving generically rather than in character.
var used_default_intent_pattern := false


# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

## Starts a battle.
##
## `config` holds:
##   stage             a row from stages.json                       (required)
##   deck              card IDs the player starts with              (required)
##   cards             card_id -> card row, for every card in the deck
##   opponent          a row from opponents.json
##   affinity          element -> { stage_id -> multiplier }
##   rules             the switches from rules.json
##   meta              current Jiban / Kanban / Kaban / Party support
##   committee_members rows from opponents.json eligible for this stage,
##                      for a committee stage (see COMMITTEE_STAGE_IDS)
##   bill_difficulty   added to the opponent's starting support
##   start_adjustment  reputation's effect in a press stage, plus any
##                      STAGE_START_BONUS modifier active for this stage
##   hand_size_bonus   +N cards from an active HAND_SIZE_BONUS modifier
##   gaffe_limit_bonus +N to the gaffe limit from an active GAFFE_LIMIT_BONUS
##   seed              fixes the shuffle, so a test always deals the same hand
##
## Returns true when the battle is ready to play. When it returns false,
## `setup_problems` says why, in words worth showing on screen.
func setup(config: Dictionary) -> bool:
	setup_problems.clear()
	used_default_intent_pattern = false

	_stage = config.get("stage", {})
	_opponent = config.get("opponent", {})
	_cards = config.get("cards", {})
	_affinity = config.get("affinity", {})
	_rules = config.get("rules", {})
	_meta = config.get("meta", {})

	# The wording, handed in like everything else. Left out — as the headless
	# fixtures leave it out — every sentence below comes back as its key,
	# which is harmless and is what those tests assert against.
	_words = Phrase.new(config.get("strings", {}))

	if _stage.is_empty():
		setup_problems.append("no stage was given")
		return false

	_rng.seed = int(config.get("seed", 0)) if config.has("seed") else randi()

	state = BattleState.new()
	state.energy_per_turn = int(_stage.get("energy_per_turn", 3))
	state.energy_mode = _string_field(_stage, "energy_mode", "per_turn")
	state.win_mode = str(_stage.get("win_mode", "threshold"))
	state.draw_mode = str(_stage.get("draw_mode", "refill"))
	_questions = _stage.get("questions", [])
	if _questions.is_empty():
		_questions = _draw_questions(config.get("question_pool", []))

	# A press conference deals a bigger opening hand and then nothing more,
	# so "opening_hand" wins over the ordinary hand size where both exist.
	#
	# hand_size_bonus / gaffe_limit_bonus come from an organisation's backing
	# — modifiers.json's HAND_SIZE_BONUS and GAFFE_LIMIT_BONUS effect types,
	# added up by BattleSetup for whichever modifiers are active in this room
	# and aimed at this stage. Zero when nothing applies.
	state.hand_size = (int(_stage.get("opening_hand", _stage.get("hand_size", 5)))
		+ int(config.get("hand_size_bonus", 0)))
	state.gaffe_limit = int(_stage.get("gaffe_limit", 5)) + int(config.get("gaffe_limit_bonus", 0))

	# A friendly reporter takes some of the heat before a word is said. Never
	# below zero: backing cannot put the meter into credit.
	state.gaffe = maxi(int(config.get("starting_gaffe", 0)), 0)
	state.guard_cap = int(_rules.get("guard_cap", 5))

	# Items used before this stage began — a Coffee from the Office, or a
	# level buff still running (GameState.take_item_bonuses_for_stage()).
	# { "ENERGY": 1, "DRAW": 2, ... }; applied before energy is handed out
	# and the opening hand is dealt, so both already include them.
	var item_bonuses: Dictionary = config.get("item_bonuses", {})
	for token: String in item_bonuses.keys():
		_apply_item_bonus(token, int(item_bonuses[token]), false)

	_setup_opponent(config)
	_setup_board(config)
	_setup_deck(config)

	if not setup_problems.is_empty():
		return false

	# Turn 1 begins: energy in, cards out.
	#
	# A pool stage hands out its whole allowance now and never tops it up,
	# so the player is budgeting across the stage rather than spending a
	# fresh allowance each turn.
	if state.energy_mode == "pool":
		var pool: Variant = _stage.get("energy_pool")
		# An item's ENERGY already raised energy_per_turn above; a stage with
		# its own pool size needs the same bonus added to the pool instead.
		state.energy = (int(pool) + int(item_bonuses.get("ENERGY", 0))) if pool != null \
			else state.energy_per_turn
	else:
		state.energy = state.energy_per_turn
	state.energy_max = state.energy

	_draw_up_to_hand_size()
	return true


func _setup_opponent(config: Dictionary) -> void:
	# Deck-playing opponents are a later milestone. Saying so here beats a
	# battle that starts and then does nothing.
	var engine_kind := str(_rules.get("opponent_engine", "intent_patterns"))
	if engine_kind == "deck_ai":
		setup_problems.append(
			"rules.json is set to 'deck_ai', but opponents that play their own "
			+ "cards are not built yet. Set it back to 'intent_patterns'."
		)
		return

	# A stage may line up several opponents. One is just a list of one.
	_opponents = config.get("opponents", [])
	if _opponents.is_empty():
		_opponents = [_opponent] if not _opponent.is_empty() else []
	_sequence_mode = _string_field(_stage, "sequence_mode", "single")

	if _opponents.is_empty():
		# A press conference has no opponent: the reporters' questions are
		# what pushes back, so there is nobody to take a turn. Any other
		# stage with nobody in it is a mistake worth refusing to start.
		if _questions.is_empty():
			setup_problems.append("there is nobody to argue with")
		state.opponent_count = 0
		return

	state.opponent_index = 0
	state.opponent_count = _opponents.size()
	_opponent = _opponents[0]

	_arm_intents(config)


## Points the intent runner at whoever is being argued with now.
##
## An opponent with a pattern of their own always uses it. When nobody has
## written one for them yet, they fall back to the shared default in
## rules.json, so a missing pattern makes an opponent generic rather than
## unplayable. The default lives in data, never in this file.
func _arm_intents(config: Dictionary = {}) -> void:
	var pattern: Variant = _opponent.get("intent_pattern")
	if pattern == null:
		pattern = config.get("intent_pattern")
	if pattern == null:
		pattern = _rules.get("default_intent_pattern")
		if pattern != null:
			used_default_intent_pattern = true

	# The opponent rolls its ranges off the battle's own generator, so a
	# seeded battle plays out the same way twice — the same arrangement the
	# bar uses for what a stubborn vote costs.
	_intents = IntentRunner.new(
		pattern,
		func(low: int, high: int) -> int: return _rng.randi_range(low, high))
	if not _intents.is_valid():
		for problem: String in _intents.problems():
			setup_problems.append("%s: %s" % [_opponent.get("name", "the opponent"), problem])


func _setup_board(config: Dictionary) -> void:
	var members: Array = config.get("committee_members", [])

	if is_committee_stage(_stage):
		if members.is_empty():
			setup_problems.append("a committee stage needs its members, and none were given")
			return
		state.committee = CommitteeModel.create(members)
		return

	# The opponent starts further ahead when the bill is unpopular, and the
	# player starts ahead or behind on reputation in a press stage.
	var player_start := int(_stage.get("player_start", 0)) + int(config.get("start_adjustment", 0))
	var opponent_start := int(_stage.get("opp_start", 0)) + int(config.get("bill_difficulty", 0))

	state.bar = _build_bar(player_start, opponent_start)


## The seat count, from the stage's own numbers.
##
## One place rather than two, because a continuous stage rebuilds it every
## time a new debater rises and the two must not drift apart.
func _build_bar(player_start: int, opponent_start: int) -> BarModel:
	var bar := BarModel.create(
		BarModel.for_stage(_stage),
		int(_stage.get("bar_max", 100)),
		int(_stage.get("win_threshold", 51)),
		player_start,
		opponent_start,
		# The bar rolls what a stubborn vote costs off the battle's own
		# generator, so a seeded battle plays out the same way twice.
		func() -> int: return _rng.randi_range(0, 99),
	)

	# In a caucus only the player's own total is scored, so there is nothing
	# to be gained by arguing the other side down.
	bar.scored_only = str(_stage.get("win_mode", "threshold")) == "score"
	return bar


func _setup_deck(config: Dictionary) -> void:
	var deck: Array = config.get("deck", [])
	if deck.is_empty():
		setup_problems.append("the player has no deck")
		return

	for card_id: String in deck:
		if not _cards.has(card_id):
			setup_problems.append("card '%s' is in the deck but not in the card data" % card_id)
		else:
			state.deck.append(card_id)

	_shuffle(state.deck)


# ---------------------------------------------------------------------------
# Playing a card
# ---------------------------------------------------------------------------

## Plays a card from hand.
##
## `target_index` picks the committee member to aim at; it is ignored
## everywhere else.
##
## Returns what happened: `ok` is false with a `reason` when the card cannot
## be played, and the battle is left untouched.
func play_card(card_id: String, target_index: int = -1) -> Dictionary:
	if state.is_over():
		return _refused("the battle is already over")
	if not state.hand.has(card_id):
		return _refused("that card is not in hand")

	var card: Dictionary = _cards.get(card_id, {})
	if card.is_empty():
		return _refused("there is no card with the ID '%s'" % card_id)

	# A discount left behind by an earlier card this turn. Never below zero:
	# a card cannot pay you to play it.
	var cost := card_cost(card)
	if cost > state.energy:
		return _refused("not enough time left this turn")

	var context := {
		"affinity": affinity_for(card),
		"segment_share": CardResolver.segment_share(card, _stage),
		"kanban": int(_meta.get("Reputation", 50)),
		"opponent_gaffe": state.opponent_gaffe,
		"next_card_bonus": state.next_card_bonus,
	}
	context.merge(_standing_context(), true)
	var effect := CardResolver.resolve(card, context)

	# Paying for it, and taking it out of hand.
	state.energy -= cost
	state.hand.erase(card_id)
	state.cards_played_this_turn += 1
	state.next_card_bonus = 0     # a carried bonus is spent by the card using it
	state.next_card_discount = 0  # and so is a carried discount

	var applied := _apply_effect(effect, target_index)

	# Into the discard pile only AFTER its effects have resolved. Otherwise a
	# card that draws could empty the deck, reshuffle, and deal the player
	# back the very card they just played.
	state.discard.append(card_id)

	# Side effects the card leaves behind for later in the turn.
	var flags: Dictionary = effect.get("flags", {})
	if flags.has("next_card_bonus"):
		state.next_card_bonus = int(flags["next_card_bonus"])
	if flags.has("next_card_discount"):
		state.next_card_discount = int(flags["next_card_discount"])
	if flags.get("reveal_next_intent", false):
		state.next_intent_revealed = true

	if not _questions.is_empty() and state.questions_answered_this_turn < _questions_per_turn():
		_answer_question(card)
		state.questions_answered_this_turn += 1

	# Who was in front of us before the outcome was checked. If a card
	# finishes a debater the whole room changes underneath the player, and
	# that is the first thing the screen has to say — Cameron watched a card
	# beat opponent four and was told only that a point had been wasted.
	var was_facing := state.opponent_index
	var beaten := current_opponent()

	_check_outcome()

	var result := {
		"ok": true,
		"card_id": card_id,
		"effect": effect,
		"applied": applied,
		"energy_left": state.energy,
	}
	if state.opponent_index != was_facing:
		result["bout_won"] = {
			"finished": str(beaten.get("name", "")),
			"next": str(current_opponent().get("name", "")),
			"remaining": state.opponent_count - state.opponent_index,
		}
	return result


## Applies a resolved card's numbers, in the order the brief sets out:
## support, then guard, then gaffe, then draw.
func _apply_effect(effect: Dictionary, target_index: int) -> Dictionary:
	var applied := {"gained": 0, "opponent_lost": 0, "guard": 0, "gaffe": 0, "drawn": 0}

	var self_plus := int(effect.get("self_plus", 0))
	var opp_minus := int(effect.get("opp_minus", 0))

	if state.is_committee_stage():
		# In a committee there is one bar per person, so both halves of a
		# card's persuasion go into the member being targeted: winning them
		# over and talking down the case against are the same act here.
		var index := target_index if target_index >= 0 else state.committee.most_persuaded_unlocked()
		var move := state.committee.persuade(index, self_plus + opp_minus)
		applied["gained"] = int(move.get("moved", 0))
		applied["member"] = move
	else:
		applied["gained"] = state.bar.player_gains(self_plus)
		# Who those people were: undecided, or argued off the other side.
		applied["gain_split"] = state.bar.last_gain.duplicate()

		# Arguing the opposition down is an attack, so their guard is the
		# first thing it meets and what it absorbs is spent. Until now this
		# went straight through and their "Guarding" intent did nothing at
		# all, which a playtest caught.
		#
		# Piercing IGNORES guard rather than spending it, so the pierced
		# amount is lifted off the bank before the attack lands and put back
		# afterwards. Subtracting it for real would let one pierce card
		# strip a guard that the card never claimed to remove.
		var pierced := mini(
			int(effect.get("flags", {}).get("pierce_guard", 0)), state.opponent_block)
		state.opponent_block -= pierced

		var stopped := mini(state.opponent_block, opp_minus)
		state.opponent_block -= stopped
		applied["guard_pierced"] = pierced
		applied["guard_stopped"] = stopped
		applied["opponent_lost"] = state.bar.opponent_loses(opp_minus - stopped)

		state.opponent_block += pierced

	# Guard is not multiplied by affinity — see CardResolver. It goes into a
	# bank that stays until something attacks, so what is reported is what
	# actually fitted: guarding 5 when you already hold 4 adds 1, not 5.
	var before_guard := state.block
	state.block = mini(state.block + int(effect.get("guard", 0)), state.guard_cap)
	applied["guard"] = state.block - before_guard

	# The gaffe meter never goes below zero, so an apology on a clean record
	# is wasted rather than banked.
	var gaffe := int(effect.get("gaffe", 0))
	var before_gaffe := state.gaffe
	# A stage can make a slip cost double — the media ambush does. Only a
	# gaffe GAINED is multiplied: an apology should not be worth less in a
	# hard room than an easy one.
	if gaffe > 0:
		gaffe *= _gaffe_multiplier()
	state.gaffe = maxi(state.gaffe + gaffe, 0)
	applied["gaffe"] = state.gaffe - before_gaffe

	applied["drawn"] = _draw(int(effect.get("draw", 0)))

	return applied


func _refused(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}


## The suit multiplier for this card in this stage.
##
## A stage may borrow another stage's affinities with "affinity_stage_id".
## The playtest level uses this: its stages have their own IDs so they do not
## pick up the canon stages' rules, but a press conference should still
## favour the same suits wherever it is played.
func affinity_for(card: Dictionary) -> float:
	var element := str(card.get("suit", ""))
	var stage_id := str(_stage.get("affinity_stage_id", _stage.get("stage_id", "")))
	var row: Variant = _affinity.get(element)
	if row is Dictionary and (row as Dictionary).has(stage_id):
		return float((row as Dictionary)[stage_id])
	return 1.0


# ---------------------------------------------------------------------------
# Ending the turn
# ---------------------------------------------------------------------------

## Ends the player's turn and runs the opponent's.
##
## Ending a turn without having played anything is how you pass, and passing
## costs you: see _pass_penalty() for what it costs and why.
##
## Returns what the opponent did and how the battle stands afterwards.
func end_turn() -> Dictionary:
	if state.is_over():
		return {"ok": false, "reason": "the battle is already over"}

	var passed := state.cards_played_this_turn == 0
	if passed:
		_pass_penalty()

	# Step 4: the rest of the hand goes, unless the switch says otherwise.
	#
	# A hand you cannot replace is the exception. In a press conference you
	# are dealt six cards and draw no more, so throwing the rest away at the
	# end of a turn would end the conference with questions still coming.
	if bool(_rules.get("discard_hand_end_of_turn", true)) and state.draw_mode != "none":
		for card_id: String in state.hand:
			state.discard.append(card_id)
		state.hand.clear()

	# Step 5: the opponent acts — if there is one. In a press conference the
	# reporters' questions are the opposition and nobody takes a turn, so
	# ending the turn only refills energy and moves the clock on.
	var intent := {"verb": "none", "value": 0}
	var opponent_result := {"verb": "none"}
	if _intents != null:
		intent = _intents.advance()
		opponent_result = _resolve_intent(intent)

	# Guard is NOT cleared here. It is a bank now: it stays until something
	# takes it, so a quiet turn spent guarding is still worth something when
	# the attack finally comes.
	# A question left unanswered when the turn ends is a question declined.
	# Passing is not the only way to duck one now that a turn can hold more
	# cards than it holds questions.
	if not _questions.is_empty() and not passed:
		var unanswered := _questions_per_turn() - state.questions_answered_this_turn
		for _i in maxi(unanswered, 0):
			if current_question().is_empty():
				break
			_decline_question()

	# A lobbyist's interest cools while you talk, whatever you said.
	if _affinity_decay() > 0 and state.bar != null and not state.is_over():
		state.bar.player_loses(_affinity_decay())

	state.next_card_bonus = 0
	state.next_card_discount = 0
	state.next_intent_revealed = false
	state.cards_played_this_turn = 0
	state.items_used_this_turn = {}
	state.questions_answered_this_turn = 0

	# Step 6: check, advance, redraw.
	var was_facing := state.opponent_index
	var beaten := current_opponent()
	_check_outcome(true)
	var bout_won := {}
	if state.opponent_index != was_facing:
		bout_won = {
			"finished": str(beaten.get("name", "")),
			"next": str(current_opponent().get("name", "")),
			"remaining": state.opponent_count - state.opponent_index,
		}

	if not state.is_over():
		state.turn += 1
		# A pool stage is never topped up: what is left is what is left, and
		# running out means the turns you have left are empty ones.
		if state.energy_mode != "pool":
			var allowance := state.energy_per_turn
			if passed:
				allowance -= _pass_cost()
			state.energy = maxi(allowance, 0)
		# In a press conference what you were dealt is what you have. A card
		# that says "draw" still works; the turn itself gives you nothing.
		if state.draw_mode != "none":
			_draw_up_to_hand_size()

	return {
		"ok": true,
		"passed": passed,
		"intent": intent,
		"opponent": opponent_result,
		"bout_won": bout_won,
		"turn": state.turn,
		"outcome": state.outcome,
	}

## Deals this stage's questions out of its type's pool.
##
## A room that asks questions no longer names its own: it draws from the
## pool for its kind, so a new question is one row in the workbook rather
## than an edit to every level that has a press conference in it.
##
## Dealt from the battle's own seeded generator, so the same seed asks the
## same questions, and without repeats — being asked the same thing twice in
## one sitting reads as a bug whatever the dice say. A pool smaller than the
## stage needs is used whole rather than padded.
func _draw_questions(pool: Array) -> Array:
	if pool.is_empty():
		return []

	# How many this room asks. A stage that says so outright wins: these
	# rooms have no turn limit, so the number of questions IS the length of
	# the stage and it is the level's to set. Otherwise it works out from
	# the clock.
	var wanted := int(_stage.get("questions_count", 0))
	if wanted <= 0:
		wanted = maxi(_questions_per_turn(), 1) * maxi(int(_stage.get("turn_limit", 0)), 1)
	var bag := pool.duplicate()

	# Fisher-Yates on the battle's generator, the same shuffle the deck gets.
	for index in range(bag.size() - 1, 0, -1):
		var swap := _rng.randi_range(0, index)
		var held: Variant = bag[index]
		bag[index] = bag[swap]
		bag[swap] = held

	return bag.slice(0, mini(wanted, bag.size()))




## How many questions a turn presents.
##
## Cameron's design scheme: a press conference asks one a turn, a policy
## study session two. Before this every CARD answered a question, so three
## energy could burn through three reporters in one turn.
func _questions_per_turn() -> int:
	return maxi(int(_stage.get("questions_per_turn", 1)), 1)


## What a slip costs here. Doubled in a media ambush.
func _gaffe_multiplier() -> int:
	return maxi(int(_stage.get("gaffe_multiplier", 1)), 1)


## How much of a lobbyist's interest cools each turn, whatever you say.
func _affinity_decay() -> int:
	return maxi(int(_stage.get("affinity_decay", 0)), 0)


## What saying nothing costs. One energy, from rules.json.
func _pass_cost() -> int:
	return int(_rules.get("pass_energy_penalty", 1))


## The price of a turn spent saying nothing.
##
## Standing up and declining to argue is a real choice — sometimes the right
## one — but it should never be the free one, or the best play in a tight
## spot would be to keep quiet and let the clock run.
##
## Two parts, depending on the stage:
##
## THE ENERGY. Normally it comes off next turn's allowance, which is applied
## where the turn refills. A pool stage is never refilled, so there is
## nothing there to dock and it has to come off what is left of the pool
## straight away. That makes it a permanent cut rather than a lost turn,
## which is the only version that means anything in a caucus.
##
## THE QUESTION. In a press conference the round IS the question in front of
## you, so passing is how you decline it: the next reporter speaks and
## nobody is pleased. There is no other way to duck one, because every card
## you could play would answer it.
func _pass_penalty() -> void:
	if state.energy_mode == "pool":
		state.energy = maxi(state.energy - _pass_cost(), 0)

	if not _questions.is_empty() and not current_question().is_empty():
		_decline_question()


## Ducking the question in front of you.
##
## Energy is close to worthless in a press conference — you are dealt six
## cards for five questions — so the ordinary pass cost meant a player could
## decline every awkward question and finish with the tone untouched and a
## clean record. A playtest found exactly that.
##
## So silence has its own price here: the room cools, and the organisation
## that asked is not pleased, which is felt later because standing carries
## between levels. Both numbers live in the stage's data.
func _decline_question() -> void:
	var cost := int(_stage.get("decline_tone_cost", 3))
	if cost > 0 and state.bar != null:
		state.bar.player_loses(cost)

	state.declined_questions += 1
	state.question_index += 1

	# In an ambush there is nowhere to go. Ducking one question ends it,
	# which is the whole character of the stage.
	if bool(_stage.get("decline_ends_stage", false)):
		_finish("loss", _words.say("outcome.reason.walked_away"))


func _resolve_intent(intent: Dictionary) -> Dictionary:
	var value := int(intent.get("value", 0))

	match str(intent.get("verb", "none")):
		"attack":
			# The player's guard is the first thing taken, and what it
			# absorbs is spent — this is the bank being drawn down rather
			# than a shield that happened to be up at the right moment.
			var absorbed := mini(state.block, value)
			var through := maxi(value - state.block, 0)
			state.block -= absorbed
			var lost := 0
			if state.is_committee_stage():
				# An attack has no meaning against a set of votes; the chair's
				# pressure is the "lean_down" verb instead.
				lost = 0
			else:
				lost = state.bar.player_loses(through)
			return {"verb": "attack", "absorbed": absorbed, "damage": lost}

		"gain":
			if state.is_committee_stage():
				return {"verb": "gain", "gained": 0, "gain_split": {}}
			var gained := state.bar.opponent_gains(value)
			return {
				"verb": "gain",
				"gained": gained,
				"gain_split": state.bar.last_gain.duplicate(),
			}

		"block":
			var before := state.opponent_block
			state.opponent_block = mini(state.opponent_block + value, state.guard_cap)
			return {"verb": "block", "guard": state.opponent_block - before}

		"lean_down":
			if not state.is_committee_stage():
				return {"verb": "lean_down", "moved": 0}
			var index := state.committee.most_persuaded_unlocked()
			var move := state.committee.chair_pressure(index, value)
			return {"verb": "lean_down", "member_index": index, "member": move}

	return {"verb": "none"}


# ---------------------------------------------------------------------------
# Winning and losing
# ---------------------------------------------------------------------------

## Works out whether the battle has finished.
##
## `end_of_turn` matters for two rules: the turn limit, and the TV debate's
## survival check, which only looks at where things stand once a turn is done.
func _check_outcome(end_of_turn: bool = false) -> void:
	if state.is_over():
		return

	# Losing on gaffes happens the moment it happens, mid-turn.
	if state.gaffe >= state.gaffe_limit:
		_finish("loss", _words.say("outcome.reason.gaffe_limit"))
		return

	# A press conference ends when the reporters run out of questions, or
	# when the player runs out of anything to answer with. Either way it is
	# over rather than lost: what it produces is the organisations pleased
	# along the way.
	#
	# This is bar_model "Single" specifically (is_press_conference()), not
	# "any room with a question pool" — 2026-09-25 fix. ST19/ST20/ST21
	# (Media Ambush, Lobbyist Meeting, Policy Study) also draw from a
	# question pool, but they are real Shared_pool-bar rooms with a real
	# support threshold; treating "ran out of questions" as an automatic win
	# for them let a room end the moment its questions were used up, at
	# whatever the bar happened to read — reported as ST21 "ending at 8"
	# instead of its actual win_threshold. Only a stage whose own bar_model
	# is genuinely tone-only (no threshold to race toward) ends this way.
	if is_press_conference():
		if questions_remaining() <= 0:
			_finish("win", _conference_closing())
			return
		# An empty hand is the end of it. The discard pile is not counted:
		# in a conference that never draws, a card once played is gone for
		# good, so cards sitting in the discard are not answers you still have.
		var can_still_answer := not state.hand.is_empty()
		if state.draw_mode != "none":
			can_still_answer = can_still_answer or not state.deck.is_empty()
		if not can_still_answer:
			_finish("win", _conference_closing(true))
			return

	if state.is_committee_stage():
		if state.committee.player_has_won():
			_finish("win", _words.say("outcome.reason.committee_for"))
			return
		if not state.committee.majority_still_reachable():
			_finish("loss", _words.say("outcome.reason.committee_against"))
			return
	else:
		# Three stages have no threshold to cross.
		#
		# A survival stage is staying alive rather than winning: the win
		# comes from lasting the full distance.
		#
		# A scored stage has no threshold at all. Ending it the moment some
		# total was passed would cut short the very thing the player is
		# trying to do, which is get as high as they can in the turns they
		# have. Both are settled in _check_turn_limit below.
		#
		# A press conference runs until the reporters are done. Walking out
		# early because the tone happened to be good would skip the questions
		# still to come, and the answers are the whole point of the stage.
		#
		# 2026-09-25: this used to read "and _questions.is_empty()", which
		# denied a threshold to ANY room with a question pool — including
		# ST19/20/21, whose bar is an ordinary Shared_pool with a real
		# win_threshold and whose questions are flavor on top of it, not the
		# win condition. Only the true press-tone room (bar_model Single, see
		# is_press_conference() above) should run out the question pool
		# instead of checking a threshold.
		var has_threshold := (state.bar.model != BarModel.Model.SURVIVAL
			and state.win_mode != "score"
			and state.bar.model != BarModel.Model.SINGLE)

		if has_threshold and state.bar.player_has_won():
			# Where a stage lines several people up, the threshold is what it
			# takes to finish THE PERSON IN FRONT OF YOU, not the stage. In a
			# committee the next member of the panel is waiting; on the floor
			# the next debater rises and the house divides again.
			if _sequence_mode != "single" and has_more_opponents():
				_advance_to_next_opponent()
				return
			_finish("win", _victory_reason())
			return

		# On the floor, arguing a debater's seats down to nothing ends them
		# too. Running out of opponents wins it even short of the threshold,
		# because there is nobody left to argue against.
		if _sequence_mode == "continuous" and state.bar.opponent <= 0:
			if has_more_opponents():
				_advance_to_next_opponent()
				return
			_finish("win", _words.say("outcome.reason.all_argued_out"))
			return
		if bool(_rules.get("opponent_can_win_by_threshold", false)) and state.bar.opponent_has_won():
			_finish("loss", _words.say("outcome.reason.opponent_first"))
			return

		# The TV debate is survived, not won: the player has to be at or above
		# the line at the end of every turn.
		if end_of_turn and state.bar.model == BarModel.Model.SURVIVAL and state.bar.player_below_threshold():
			_finish("loss", _words.say("outcome.reason.fell_below"))
			return

	if end_of_turn:
		_check_turn_limit()


func _check_turn_limit() -> void:
	var limit := turn_limit()
	if limit <= 0 or state.turn < limit:
		return

	# Surviving to the end IS the win in a TV debate, whatever the general
	# turn-limit switch says.
	if state.bar != null and state.bar.model == BarModel.Model.SURVIVAL:
		_finish("win", _words.say("outcome.reason.survived"))
		return

	# A scored stage is not won or lost on the clock — running out of turns
	# is simply how it ends. Whatever support was reached is the result, and
	# later stages of the level draw on it.
	if state.win_mode == "score":
		# In the units the stage is read in: a caucus counted as a share of
		# the room should not close on a headcount, and a TV debate should
		# close on press tone rather than on "support".
		var closing := (_words.say("outcome.reason.percent_of_room",
				{"count": state.player_score()})
			if bool(_stage.get("bar_as_percent", false))
			else _words.say("outcome.reason.amount_of_unit", {
				"count": state.player_score(),
				"unit": str(_stage.get("bar_unit", "support")).to_lower()}))

		# NAMED FROM THE STAGE. Three kinds of stage are scored — the caucus,
		# the town hall and the TV debate — and this said "the caucus closed"
		# for all three until a playtest screenshot caught a TV debate
		# claiming to be one.
		var what := str(_stage.get("name_en", "")).strip_edges()
		_finish("win", (_words.say("outcome.reason.closed_on",
		{"stage": what, "closing": closing}) if not what.is_empty()
		else _words.say("outcome.reason.closed_on_unnamed", {"closing": closing})))
		return

	match str(_rules.get("turn_limit_outcome", "loss")):
		"highest_support_wins":
			if state.is_committee_stage():
				var for_votes := state.committee.locked_for()
				var against := state.committee.locked_against()
				if for_votes > against:
					_finish("win", "Time ran out with more members in favour than against.")
				else:
					_finish("loss", "Time ran out without a majority.")
			elif state.bar.player > state.bar.opponent:
				_finish("win", _words.say("outcome.reason.time_ahead"))
			else:
				_finish("loss", _words.say("outcome.reason.time_behind"))

		"tie_retry":
			_finish("retry", _words.say("outcome.reason.time_no_decision"))

		_:
			_finish("loss", _words.say("outcome.reason.time_short"))


# ---------------------------------------------------------------------------
# The press conference
# ---------------------------------------------------------------------------

## How a press conference ends.
##
## Never won or lost — it closes, and what it produced is the tone and the
## organisations pleased. The count of unanswered questions is recorded
## rather than judged: what it should cost beyond the tone is Cameron's, and
## this is the line those endings will hang off.
func _conference_closing(ran_out_of_cards: bool = false) -> String:
	# Named from the stage, because a policy study session and a lobbyist
	# meeting both run on questions and neither of them is a press
	# conference. It said so anyway until a playtest read it.
	var what := str(_stage.get("name_en", "")).strip_edges()
	var lines: Array[String] = [
		_words.say("outcome.reason.concludes", {"stage": what}) if not what.is_empty()
		else _words.say("outcome.reason.concludes_unnamed")]

	if ran_out_of_cards:
		lines.append(_words.say("outcome.reason.nothing_left"))

	var declined := state.declined_questions
	if declined > 0:
		lines.append(_words.say("outcome.reason.unanswered", {"count": declined}))

	return " ".join(lines)


## What this card costs right now, after any discount a card left behind.
##
## Public because the hand has to show it: a card whose face says 2 and
## which then charges 1 is a screen the player stops trusting, and so is the
## reverse. Floors at zero — a card cannot pay you to play it.
func card_cost(card: Dictionary) -> int:
	return maxi(int(card.get("cost", 0)) - state.next_card_discount, 0)


## Where the player stands, for the effects that care.
##
## Read fresh each time rather than cached: "if you trail the opponent" has
## to mean the moment the card is played, not the moment the hand was dealt.
func _standing_context() -> Dictionary:
	return {
		"self_gaffe": state.gaffe,
		"player_support": state.bar.player if state.bar != null else 0,
		"opponent_support": state.bar.opponent if state.bar != null else 0,
	}


## What a card will actually do in this room, before it is played.
##
## The printed number on a card is not what happens: affinity multiplies the
## two support numbers, so a Divisive "+3" is a 2 in a committee. A playtest
## reported this as the card not working, which is what happens when a screen
## shows a promise the rules do not keep.
##
## Returns the resolved amounts plus `does_nothing`, which is true when every
## number on the card is inert here — an attack in a press conference, or a
## guard card in a room where nobody attacks you.
func preview(card: Dictionary) -> Dictionary:
	var effect := CardResolver.resolve(card, {
		"affinity": affinity_for(card),
		"segment_share": CardResolver.segment_share(card, _stage),
		"kanban": int(_meta.get("Reputation", 50)),
		"opponent_gaffe": state.opponent_gaffe,
		"next_card_bonus": state.next_card_bonus,
		"self_gaffe": state.gaffe,
		"player_support": state.bar.player if state.bar != null else 0,
		"opponent_support": state.bar.opponent if state.bar != null else 0,
	})

	# A number the rules will refuse to use is worse than no number: it
	# invites the player to count on it.
	var reduce_counts := state.bar == null or not state.bar.reduce_does_nothing()
	var guard_counts := _intents != null

	effect["opp_minus_counts"] = reduce_counts
	effect["guard_counts"] = guard_counts

	# A gaffe counts. It was left out of this test, which produced a card
	# reading "Gaffe +1. Nothing this card does counts in this room." — a
	# sentence that contradicts itself. Doing something bad is still doing
	# something, and the player should be told which.
	effect["does_nothing"] = (
		int(effect.get("self_plus", 0)) == 0
		and int(effect.get("draw", 0)) == 0
		and int(effect.get("gaffe", 0)) == 0
		and (int(effect.get("opp_minus", 0)) == 0 or not reduce_counts)
		and (int(effect.get("guard", 0)) == 0 or not guard_counts))

	# Every card answers the question in front of you, whatever else it does
	# — so a card whose numbers are all inert here still spends a question.
	# The card face has to say so, or spending one is an accident.
	effect["answers_question"] = not current_question().is_empty()

	return effect


## True when this stage is driven by reporters' questions rather than by
## somebody taking turns opposite the player.
##
## It stays true once the last question is answered, so the screen does not
## change its shape at the moment the conference ends.
##
## 2026-09-25: a question pool alone is not enough. ST19/20/21 (Media Ambush,
## Lobbyist Meeting, Policy Study Session) also draw from a question pool but
## are real Shared_pool rooms with a named opponent and a genuine win
## threshold — treating them as a press conference made the opponent row show
## "Reporter" instead of the real person (playtest #4) and made the room end
## the moment the pool ran dry instead of at its threshold (playtest #7).
## Only a stage whose declared bar_model is Single is the true press-tone
## room; everything else with a question pool asks questions on top of an
## ordinary bar.
func is_press_conference() -> bool:
	return not _questions.is_empty() and state.bar != null and state.bar.model == BarModel.Model.SINGLE


## The question waiting to be answered, or empty when there are none left.
func current_question() -> Dictionary:
	if state.question_index < 0 or state.question_index >= _questions.size():
		return {}
	return _questions[state.question_index]


func questions_remaining() -> int:
	return maxi(_questions.size() - state.question_index, 0)


## The organisations pleased so far. The floor debate draws on these.
func pleased_boosters() -> Array[String]:
	return state.pleased_boosters


## "Question 2 of 5", for the header.
func question_caption() -> String:
	if _questions.is_empty():
		return ""
	return _words.say("caption.question", {
		"number": mini(state.question_index + 1, _questions.size()),
		"total": _questions.size()})


## Uses a card as the answer to the question on the floor.
##
## Every card answers. Answering in the suit the question invites also
## pleases the organisation behind it — a data-driven answer to a question
## about costs satisfies the people who asked it.
func _answer_question(card: Dictionary) -> void:
	var question := current_question()
	if question.is_empty():
		return

	match _grade_of(card, question):
		"S":
			# A strong answer pleases whoever asked, as it always has.
			var booster := str(question.get("pleases_booster", ""))
			if not booster.is_empty() and not state.pleased_boosters.has(booster):
				state.pleased_boosters.append(booster)
		"W":
			# A weak answer is worse than a bland one: the room cools, the
			# same way declining does but by a smaller amount. The number is
			# the stage's, beside the decline cost it sits next to.
			var cost := int(_stage.get("weak_answer_tone_cost", 0))
			if cost > 0 and state.bar != null:
				state.bar.player_loses(cost)
			state.weak_answers += 1

	state.question_index += 1


## How well this card's suit answers this question: "S", "M" or "W".
##
## Two shapes of question are understood. The questions Cameron wrote in the
## workbook grade all six suits; the earlier hand-written ones name a single
## suit they prefer, which reads as S for that suit and M for the rest.
func _grade_of(card: Dictionary, question: Dictionary) -> String:
	var suit := str(card.get("suit", ""))

	var grades: Dictionary = question.get("grades", {})
	if not grades.is_empty():
		return str(grades.get(suit, "M"))

	return "S" if suit == str(question.get("prefers_suit", "")) else "M"


# ---------------------------------------------------------------------------
# Working through several opponents
# ---------------------------------------------------------------------------

## Whoever is being argued with at the moment.
func current_opponent() -> Dictionary:
	if state.opponent_index < 0 or state.opponent_index >= _opponents.size():
		return _opponent
	return _opponents[state.opponent_index]


func has_more_opponents() -> bool:
	return state.opponent_index + 1 < _opponents.size()


## "Opponent 2 of 5", for the header. Empty when there is only one.
func opponent_caption() -> String:
	if state.opponent_count <= 1:
		return ""
	return _words.say("caption.opponent", {
		"number": state.opponent_index + 1, "total": state.opponent_count})


## Brings on the next opponent.
##
## In a committee this is a fresh argument: support, gaffes, guard, energy,
## the clock and the cards all start again, because beating someone should
## not leave you worn down for the next person.
##
## On the floor it is a fresh vote but not a fresh start: the house divides
## again on the new debater, so the seat count goes back to where the stage
## opened — but your gaffes, your hand, your deck and the clock all follow
## you in. Beating five debaters means winning five divisions on one set of
## nerves and one afternoon.
func _advance_to_next_opponent() -> void:
	state.opponent_index += 1
	_opponent = _opponents[state.opponent_index]
	_arm_intents()

	if _sequence_mode == "reset":
		_reset_for_new_bout()
	elif _sequence_mode == "stream":
		# A town hall: the clock and your record carry across the queue, but
		# each new face is a fresh three energy. Neither of the other two
		# modes does that — "reset" would wipe the gaffes you have earned
		# and "continuous" would leave you empty-handed in front of somebody
		# who has not heard you speak yet.
		state.energy = state.energy_per_turn
		state.energy_max = state.energy_per_turn
		if state.bar != null:
			state.bar = _build_bar(
				int(_stage.get("player_start", 0)),
				int(_stage.get("opp_start", 0)))
	elif state.bar != null:
		state.bar = _build_bar(
			int(_stage.get("player_start", 0)),
			int(_stage.get("opp_start", 0)))


## Everything a new bout starts fresh with.
func _reset_for_new_bout() -> void:
	state.gaffe = 0
	state.block = 0
	state.opponent_block = 0
	state.next_card_bonus = 0
	state.next_card_discount = 0
	state.next_intent_revealed = false
	state.turn = 1

	state.energy = state.energy_max
	if state.energy_mode != "pool":
		state.energy = state.energy_per_turn
		state.energy_max = state.energy_per_turn

	if state.bar != null:
		state.bar = _build_bar(
			int(_stage.get("player_start", 0)),
			int(_stage.get("opp_start", 0)))

	# A clean deck, so the last argument's spent cards are not a handicap.
	state.deck.assign(state.deck + state.hand + state.discard)
	state.hand.clear()
	state.discard.clear()
	_shuffle(state.deck)
	_draw_up_to_hand_size()


## What to say when the player wins, which depends on what they just did.
func _victory_reason() -> String:
	if _sequence_mode != "single" and state.opponent_count > 1:
		return _words.say("outcome.reason.all_argued_down", {"count": state.opponent_count})
	return _words.say("outcome.reason.threshold")


func _finish(outcome: String, reason: String) -> void:
	state.outcome = outcome
	state.outcome_reason = reason


# ---------------------------------------------------------------------------
# The deck
# ---------------------------------------------------------------------------

## Draws cards, reshuffling the discard pile back in when the deck runs dry.
## Returns how many were actually drawn.
func _draw(count: int) -> int:
	var drawn := 0
	for _index in count:
		if state.deck.is_empty():
			if state.discard.is_empty():
				break   # every card is already in hand; nothing left to draw
			state.deck.assign(state.discard)
			state.discard.clear()
			_shuffle(state.deck)
		state.hand.append(state.deck.pop_front())
		drawn += 1
	return drawn


func _draw_up_to_hand_size() -> int:
	return _draw(maxi(state.hand_size - state.hand.size(), 0))


## Shuffles in place, using the engine's own random number generator so a
## test that sets a seed deals the same cards every run.
func _shuffle(cards: Array) -> void:
	for index in range(cards.size() - 1, 0, -1):
		var swap_with := _rng.randi_range(0, index)
		var held: Variant = cards[index]
		cards[index] = cards[swap_with]
		cards[swap_with] = held


# ---------------------------------------------------------------------------
# For the UI
# ---------------------------------------------------------------------------

## What the opponent is about to do, for the line at the top of the screen.
func current_intent() -> Dictionary:
	return _intents.peek() if _intents != null else {"verb": "none", "value": 0}


## The move after that — only known once a card has revealed it.
func upcoming_intent() -> Dictionary:
	if _intents == null or not state.next_intent_revealed:
		return {}
	return _intents.peek_ahead()


## True only when one more gaffe would end the stage. The UI turns the gaffe
## counter red on this and nothing else.
func gaffe_is_critical() -> bool:
	return state.gaffe >= state.gaffe_limit - 1


## The stage's turn limit including any turns an item added. 0 still means
## "no limit" — an item cannot put a clock on a stage that has none.
func turn_limit() -> int:
	var base := int(_stage.get("turn_limit", 0))
	return base + state.turn_limit_bonus if base > 0 else 0


# ---------------------------------------------------------------------------
# Items (design/proposals/inventory.md)
# ---------------------------------------------------------------------------

## Uses an item mid-stage. `effects` is the item's stage effects, already
## resolved to real numbers by the caller: [ { "token": "ENERGY", "amount": 1 } ].
## Free, and not a card play — it does not touch cards_played_this_turn, so
## it neither costs energy nor saves the player from the pass penalty.
##
## Refused, with the reason's Text key, when the stage is over or the item
## has already been used `uses_per_turn` times this turn. The engine cannot
## see the inventory; whether the player HAS one is the caller's question.
func use_item(item_id: String, effects: Array, uses_per_turn: int) -> Dictionary:
	if state.is_over():
		return {"ok": false, "reason": _words.say("item.refused.battle_over")}
	var used := int(state.items_used_this_turn.get(item_id, 0))
	if used >= uses_per_turn:
		return {"ok": false, "reason": _words.say("item.refused.turn_limit")}

	for effect: Dictionary in effects:
		_apply_item_bonus(str(effect.get("token", "")), int(effect.get("amount", 0)), true)
	state.items_used_this_turn[item_id] = used + 1
	return {"ok": true}


## One stage effect. The same five words mean the same thing whether the item
## was used in the Office (applied at setup, `now` false) or mid-stage (`now`
## true): "+1 energy for the stage" is +1 energy every turn of it, so a
## mid-stage ENERGY also tops up the turn in progress, and a mid-stage DRAW
## raises the hand size and deals the card straight away.
func _apply_item_bonus(token: String, amount: int, now: bool) -> void:
	if amount == 0:
		return
	match token.to_upper():
		"ENERGY":
			state.energy_per_turn += amount
			if now:
				state.energy = maxi(state.energy + amount, 0)
				state.energy_max = maxi(state.energy_max, state.energy)
		"GUARD":
			state.block = clampi(state.block + amount, 0, state.guard_cap)
		"DRAW":
			state.hand_size = maxi(state.hand_size + amount, 0)
			if now and amount > 0:
				_draw(amount)
		"TURNS":
			state.turn_limit_bonus += amount
		"GAFFE_CAP":
			state.gaffe_limit = maxi(state.gaffe_limit + amount, 1)


## "Turn 3 of 8" for the header.
func turn_caption() -> String:
	return _words.say("caption.turn", {
		"turn": state.turn, "total": turn_limit()})
