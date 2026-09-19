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

# --- Everything the engine was given at setup ------------------------------
var _stage: Dictionary = {}
var _opponent: Dictionary = {}
var _cards: Dictionary = {}        ## card_id -> card row
var _affinity: Dictionary = {}     ## element -> { stage_id -> multiplier }
var _rules: Dictionary = {}
var _meta: Dictionary = {}         ## Jiban, Kanban, Kaban, Party support
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
##   committee_members rows from committee.json, for a committee stage
##   bill_difficulty   added to the opponent's starting support
##   start_adjustment  reputation's effect in a press stage
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

	if _stage.is_empty():
		setup_problems.append("no stage was given")
		return false

	_rng.seed = int(config.get("seed", 0)) if config.has("seed") else randi()

	state = BattleState.new()
	state.energy_per_turn = int(_stage.get("energy_per_turn", 3))
	state.energy_mode = str(_stage.get("energy_mode", "per_turn"))
	state.win_mode = str(_stage.get("win_mode", "threshold"))
	state.draw_mode = str(_stage.get("draw_mode", "refill"))
	_questions = _stage.get("questions", [])

	# A press conference deals a bigger opening hand and then nothing more,
	# so "opening_hand" wins over the ordinary hand size where both exist.
	state.hand_size = int(_stage.get("opening_hand", _stage.get("hand_size", 5)))
	state.gaffe_limit = int(_stage.get("gaffe_limit", 5))

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
		state.energy = int(_stage.get("energy_pool", state.energy_per_turn))
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
	_sequence_mode = str(_stage.get("sequence_mode", "single"))

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

	_intents = IntentRunner.new(pattern)
	if not _intents.is_valid():
		for problem: String in _intents.problems():
			setup_problems.append("%s: %s" % [_opponent.get("name", "the opponent"), problem])


func _setup_board(config: Dictionary) -> void:
	var members: Array = config.get("committee_members", [])

	if str(_stage.get("stage_id", "")) == "ST01":
		if members.is_empty():
			setup_problems.append("a committee stage needs its members, and none were given")
			return
		state.committee = CommitteeModel.create(members)
		return

	# The opponent starts further ahead when the bill is unpopular, and the
	# player starts ahead or behind on reputation in a press stage.
	var player_start := int(_stage.get("player_start", 0)) + int(config.get("start_adjustment", 0))
	var opponent_start := int(_stage.get("opp_start", 0)) + int(config.get("bill_difficulty", 0))

	state.bar = BarModel.create(
		BarModel.for_stage(_stage),
		int(_stage.get("bar_max", 100)),
		int(_stage.get("win_threshold", 51)),
		player_start,
		opponent_start,
	)


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

	var cost := int(card.get("cost", 0))
	if cost > state.energy:
		return _refused("not enough time left this turn")

	var context := {
		"affinity": affinity_for(card),
		"segment_share": CardResolver.segment_share(card, _stage),
		"kanban": int(_meta.get("Reputation", 50)),
		"opponent_gaffe": state.opponent_gaffe,
		"next_card_bonus": state.next_card_bonus,
	}
	var effect := CardResolver.resolve(card, context)

	# Paying for it, and taking it out of hand.
	state.energy -= cost
	state.hand.erase(card_id)
	state.next_card_bonus = 0   # a carried bonus is spent by the card that uses it

	var applied := _apply_effect(effect, target_index)

	# Into the discard pile only AFTER its effects have resolved. Otherwise a
	# card that draws could empty the deck, reshuffle, and deal the player
	# back the very card they just played.
	state.discard.append(card_id)

	# Side effects the card leaves behind for later in the turn.
	var flags: Dictionary = effect.get("flags", {})
	if flags.has("next_card_bonus"):
		state.next_card_bonus = int(flags["next_card_bonus"])
	if flags.get("reveal_next_intent", false):
		state.next_intent_revealed = true

	if not _questions.is_empty():
		_answer_question(card)

	_check_outcome()

	var result := {
		"ok": true,
		"card_id": card_id,
		"effect": effect,
		"applied": applied,
		"energy_left": state.energy,
	}

	# A card that passes the round hands the turn over as it is played, so
	# the player does not have to press End turn afterwards to mean the thing
	# they have just said they mean. Declining and then playing on would not
	# be declining.
	#
	# A press conference has no turn to hand over — every card answers the
	# question in front of it and the next reporter speaks — so this is only
	# reached where somebody is actually waiting to act.
	if flags.get("end_turn", false) and not state.is_over() and _intents != null:
		result["ended_turn"] = end_turn()

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
		applied["opponent_lost"] = state.bar.opponent_loses(opp_minus)

	# Guard is not multiplied by affinity — see CardResolver.
	var guard := int(effect.get("guard", 0))
	state.block += guard
	applied["guard"] = guard

	# The gaffe meter never goes below zero, so an apology on a clean record
	# is wasted rather than banked.
	var gaffe := int(effect.get("gaffe", 0))
	var before_gaffe := state.gaffe
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
## Returns what the opponent did and how the battle stands afterwards.
func end_turn() -> Dictionary:
	if state.is_over():
		return {"ok": false, "reason": "the battle is already over"}

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

	# Block is spent at the end of the turn whether or not it was needed.
	state.block = 0
	state.next_card_bonus = 0
	state.next_intent_revealed = false

	# Step 6: check, advance, redraw.
	_check_outcome(true)

	if not state.is_over():
		state.turn += 1
		# A pool stage is never topped up: what is left is what is left, and
		# running out means the turns you have left are empty ones.
		if state.energy_mode != "pool":
			state.energy = state.energy_per_turn
		# In a press conference what you were dealt is what you have. A card
		# that says "draw" still works; the turn itself gives you nothing.
		if state.draw_mode != "none":
			_draw_up_to_hand_size()

	return {
		"ok": true,
		"intent": intent,
		"opponent": opponent_result,
		"turn": state.turn,
		"outcome": state.outcome,
	}


func _resolve_intent(intent: Dictionary) -> Dictionary:
	var value := int(intent.get("value", 0))

	match str(intent.get("verb", "none")):
		"attack":
			# Block absorbs the attack first. Anything left gets through.
			var absorbed := mini(state.block, value)
			var through := maxi(value - state.block, 0)
			var lost := 0
			if state.is_committee_stage():
				# An attack has no meaning against a set of votes; the chair's
				# pressure is the "lean_down" verb instead.
				lost = 0
			else:
				lost = state.bar.player_loses(through)
			return {"verb": "attack", "absorbed": absorbed, "damage": lost}

		"gain":
			var gained := 0 if state.is_committee_stage() else state.bar.opponent_gains(value)
			return {"verb": "gain", "gained": gained}

		"block":
			state.opponent_block += value
			return {"verb": "block", "guard": value}

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
		_finish("loss", "The gaffe meter filled.")
		return

	# A press conference ends when the reporters run out of questions, or
	# when the player runs out of anything to answer with. Either way it is
	# over rather than lost: what it produces is the organisations pleased
	# along the way.
	if not _questions.is_empty():
		if questions_remaining() <= 0:
			_finish("win", "Every question was answered.")
			return
		# An empty hand is the end of it. The discard pile is not counted:
		# in a conference that never draws, a card once played is gone for
		# good, so cards sitting in the discard are not answers you still have.
		var can_still_answer := not state.hand.is_empty()
		if state.draw_mode != "none":
			can_still_answer = can_still_answer or not state.deck.is_empty()
		if not can_still_answer:
			_finish("win", "The questions ran on, but there was nothing left to say.")
			return

	if state.is_committee_stage():
		if state.committee.player_has_won():
			_finish("win", "A majority of the committee locked in favour.")
			return
		if not state.committee.majority_still_reachable():
			_finish("loss", "Too many members locked against — a majority is no longer possible.")
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
		var has_threshold := (state.bar.model != BarModel.Model.SURVIVAL
			and state.win_mode != "score"
			and _questions.is_empty())

		if has_threshold and state.bar.player_has_won():
			# In a committee, winning the argument wins this bout, not the
			# stage: the next member of the panel is waiting.
			if _sequence_mode == "reset" and has_more_opponents():
				_advance_to_next_opponent()
				return
			_finish("win", _victory_reason())
			return

		# On the floor, arguing an opponent's seats down to nothing brings on
		# the next. Running out of opponents wins it even short of a majority,
		# because there is nobody left to argue against.
		if _sequence_mode == "continuous" and state.bar.opponent <= 0:
			if has_more_opponents():
				_advance_to_next_opponent()
				return
			_finish("win", "Every opponent has been argued out of the chamber.")
			return
		if bool(_rules.get("opponent_can_win_by_threshold", false)) and state.bar.opponent_has_won():
			_finish("loss", "The opponent reached the threshold first.")
			return

		# The TV debate is survived, not won: the player has to be at or above
		# the line at the end of every turn.
		if end_of_turn and state.bar.model == BarModel.Model.SURVIVAL and state.bar.player_below_threshold():
			_finish("loss", "Support fell below the line during the debate.")
			return

	if end_of_turn:
		_check_turn_limit()


func _check_turn_limit() -> void:
	var limit := int(_stage.get("turn_limit", 0))
	if limit <= 0 or state.turn < limit:
		return

	# Surviving to the end IS the win in a TV debate, whatever the general
	# turn-limit switch says.
	if state.bar != null and state.bar.model == BarModel.Model.SURVIVAL:
		_finish("win", "Survived the whole debate above the line.")
		return

	# A scored stage is not won or lost on the clock — running out of turns
	# is simply how it ends. Whatever support was reached is the result, and
	# later stages of the level draw on it.
	if state.win_mode == "score":
		_finish("win", "The caucus closed with %d support." % state.player_score())
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
				_finish("win", "Time ran out with the player ahead.")
			else:
				_finish("loss", "Time ran out with the player behind.")

		"tie_retry":
			_finish("retry", "Time ran out with no decision. The stage restarts.")

		_:
			_finish("loss", "Time ran out before the threshold was reached.")


# ---------------------------------------------------------------------------
# The press conference
# ---------------------------------------------------------------------------

## True when this stage is driven by reporters' questions rather than by
## somebody taking turns opposite the player.
##
## It stays true once the last question is answered, so the screen does not
## change its shape at the moment the conference ends.
func is_press_conference() -> bool:
	return not _questions.is_empty()


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
	return "Question %d of %d" % [
		mini(state.question_index + 1, _questions.size()), _questions.size()]


## Uses a card as the answer to the question on the floor.
##
## Every card answers. Answering in the suit the question invites also
## pleases the organisation behind it — a data-driven answer to a question
## about costs satisfies the people who asked it.
func _answer_question(card: Dictionary) -> void:
	var question := current_question()
	if question.is_empty():
		return

	if card.get("suit") == question.get("prefers_suit"):
		var booster := str(question.get("pleases_booster", ""))
		if not booster.is_empty() and not state.pleased_boosters.has(booster):
			state.pleased_boosters.append(booster)

	state.question_index += 1


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
	return "%d of %d" % [state.opponent_index + 1, state.opponent_count]


## Brings on the next opponent.
##
## In a committee this is a fresh argument: support, gaffes, guard, energy,
## the clock and the cards all start again, because beating someone should
## not leave you worn down for the next person.
##
## On the floor it is the same room carrying on: the seats you have won stay
## won, your record follows you, and the clock keeps running. The new
## opponent takes their seats from those not yet committed either way.
func _advance_to_next_opponent() -> void:
	state.opponent_index += 1
	_opponent = _opponents[state.opponent_index]
	_arm_intents()

	if _sequence_mode == "reset":
		_reset_for_new_bout()
	elif state.bar != null:
		# Their seats have to come from somewhere, and taking them from the
		# player would punish winning. They come from the undecided.
		state.bar.opponent_gains(int(_stage.get("opp_start", 0)))


## Everything a new bout starts fresh with.
func _reset_for_new_bout() -> void:
	state.gaffe = 0
	state.block = 0
	state.opponent_block = 0
	state.next_card_bonus = 0
	state.next_intent_revealed = false
	state.turn = 1

	state.energy = state.energy_max
	if state.energy_mode != "pool":
		state.energy = state.energy_per_turn
		state.energy_max = state.energy_per_turn

	if state.bar != null:
		state.bar = BarModel.create(
			BarModel.for_stage(_stage),
			int(_stage.get("bar_max", 100)),
			int(_stage.get("win_threshold", 51)),
			int(_stage.get("player_start", 0)),
			int(_stage.get("opp_start", 0)),
		)

	# A clean deck, so the last argument's spent cards are not a handicap.
	state.deck.assign(state.deck + state.hand + state.discard)
	state.hand.clear()
	state.discard.clear()
	_shuffle(state.deck)
	_draw_up_to_hand_size()


## What to say when the player wins, which depends on what they just did.
func _victory_reason() -> String:
	if _sequence_mode == "reset" and state.opponent_count > 1:
		return "All %d were argued down." % state.opponent_count
	return "The support threshold was reached."


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


## "Turn 3 of 8" for the header.
func turn_caption() -> String:
	return "Turn %d of %d" % [state.turn, int(_stage.get("turn_limit", 0))]
