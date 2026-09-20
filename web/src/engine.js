// The rules, ported from scripts/rules/*.gd.
//
// THIS IS A MIRROR, NOT THE GAME. The Godot project is what ships; this
// exists so the level can be played in a browser without installing
// anything. Every rule below is a line-for-line port of its GDScript
// original, and tests.js re-runs the engine's assertions in the page so
// that if the two ever drift apart it says so out loud.
//
// If you change a rule here, change it in scripts/rules/ in the same
// commit, or the mirror starts lying.
//
// Ported from:
//   CardResolver.gd  SpecialEffects.gd  BarModel.gd  IntentRunner.gd
//   BattleEngine.gd  BattleState.gd  LevelRunner.gd  MetaRules.gd
//   BattleSetup.gd

'use strict';

// ---------------------------------------------------------------------------
// A seeded shuffle, so a game can be replayed
// ---------------------------------------------------------------------------
// Godot's RandomNumberGenerator is not reproducible outside Godot, so this is
// its own generator. It does not have to match Godot's sequence — only to be
// repeatable within a run, which is what a seed is for.

function makeRng(seed) {
  let state = (seed >>> 0) || 0x9e3779b9;
  return function next(limit) {
    state ^= state << 13; state >>>= 0;
    state ^= state >>> 17;
    state ^= state << 5;  state >>>= 0;
    return state % limit;
  };
}

function shuffle(cards, rng) {
  for (let i = cards.length - 1; i > 0; i--) {
    const j = rng(i + 1);
    const held = cards[i];
    cards[i] = cards[j];
    cards[j] = held;
  }
}

// ---------------------------------------------------------------------------
// CardResolver
// ---------------------------------------------------------------------------

// Rounds to the nearest whole number, with exact halves going up.
function roundHalfUp(value) {
  return Math.floor(value + 0.5);
}

function cardNumber(card, key) {
  const value = card[key];
  return value === null || value === undefined ? 0 : Math.trunc(value);
}

// How much of this stage's audience the card is aimed at, as 0..1.
function segmentShare(card, stage) {
  const segmentId = card.target_segment_id;
  if (segmentId === null || segmentId === undefined) return 1.0;
  const mix = stage.segment_mix || {};
  return Number(mix[segmentId] || 0);
}

// THE ORDER MATTERS: affinity multiplies the two support numbers only, then
// the special effect applies. Guard, draw and gaffe are used as written — a
// room that suits your rhetoric does not make you better at not putting your
// foot in your mouth.
function resolveCard(card, context) {
  const affinity = context.affinity === undefined ? 1.0 : Number(context.affinity);

  let effect = {
    self_plus: roundHalfUp(cardNumber(card, 'self_plus') * affinity),
    opp_minus: roundHalfUp(cardNumber(card, 'opp_minus') * affinity),
    guard: cardNumber(card, 'guard'),
    draw: cardNumber(card, 'draw'),
    gaffe: cardNumber(card, 'gaffe'),
    cost: cardNumber(card, 'cost'),
    flags: {},
  };

  const carried = Math.trunc(context.next_card_bonus || 0);
  if (carried !== 0 && effect.self_plus > 0) {
    effect.self_plus += carried;
    effect.flags.received_bonus = carried;
  }

  return applySpecial(card.special, card.special_value, effect, context);
}

// ---------------------------------------------------------------------------
// SpecialEffects
// ---------------------------------------------------------------------------

const KNOWN_SPECIALS = [
  'bonus_if_kanban_ge_60',
  'double_if_target_segment_ge_50',
  'bonus_if_target_segment_ge_50',
  'buff_next_card_this_turn',
  'reveal_next_intent',
  'bonus_opp_minus_if_opp_gaffe',
  'pass_turn',
];

function applySpecial(key, value, effect, context) {
  const result = Object.assign({}, effect);
  result.flags = Object.assign({}, effect.flags || {});

  if (key === null || key === undefined || key === '') return result;
  if (!KNOWN_SPECIALS.includes(String(key))) {
    console.warn("SpecialEffects: no effect called '" + key + "'. The card plays as its plain numbers.");
    return result;
  }

  const amount = value === null || value === undefined ? 0 : Math.trunc(value);
  const share = Number(context.segment_share || 0);

  switch (String(key)) {
    case 'bonus_if_kanban_ge_60':
      if (Math.trunc(context.kanban || 0) >= 60) {
        result.self_plus += amount;
        result.flags.special_triggered = true;
      }
      break;
    case 'double_if_target_segment_ge_50':
      if (share >= 0.5) {
        result.self_plus *= 2;
        result.flags.special_triggered = true;
      }
      break;
    case 'bonus_if_target_segment_ge_50':
      if (share >= 0.5) {
        result.self_plus += amount;
        result.flags.special_triggered = true;
      }
      break;
    case 'buff_next_card_this_turn':
      result.flags.next_card_bonus = amount;
      result.flags.special_triggered = true;
      break;
    case 'reveal_next_intent':
      result.flags.reveal_next_intent = true;
      result.flags.special_triggered = true;
      break;
    case 'bonus_opp_minus_if_opp_gaffe':
      if (Math.trunc(context.opponent_gaffe || 0) > 0) {
        result.opp_minus += amount;
        result.flags.special_triggered = true;
      }
      break;
    case 'pass_turn':
      // The card's own gaffe number is the price; this only hands the round
      // over. In a press conference the round IS the question, and every card
      // answers one already, so this does nothing there and the card still
      // works: you have declined out loud and the next reporter speaks.
      result.flags.end_turn = true;
      result.flags.special_triggered = true;
      break;
  }

  return result;
}

// ---------------------------------------------------------------------------
// BarModel
// ---------------------------------------------------------------------------
// SHARED_POOL  a fixed room: yours, theirs, undecided, always summing to the
//              whole. Winning someone over takes from the undecided first.
// SINGLE       one number, up and down. The press tone.
// SURVIVAL     one number, but you must be at or above the line at the end of
//              every turn, not just at the finish.

const SHARED_POOL = 0, SINGLE = 1, SURVIVAL = 2;

class BarModel {
  constructor(model, maximum, threshold, playerStart, opponentStart) {
    this.model = model;
    this.maximum = Math.max(maximum, 1);
    this.threshold = threshold;
    this.player = clamp(playerStart, 0, this.maximum);
    this.opponent = clamp(opponentStart, 0, this.maximum);

    if (model === SHARED_POOL) {
      this.undecided = Math.max(this.maximum - this.player - this.opponent, 0);
      // If the starting numbers overfill the room, trim the opponent: the
      // designer set the player's number on purpose.
      if (this.player + this.opponent > this.maximum) {
        this.opponent = Math.max(this.maximum - this.player, 0);
        this.undecided = 0;
      }
    } else {
      this.opponent = 0;
      this.undecided = 0;
    }
  }

  static forStage(stage) {
    // A stage built out of reporters' questions is a press conference
    // wherever it appears, read from its shape rather than from its name.
    if (Array.isArray(stage.questions) && stage.questions.length > 0) return SINGLE;
    if (stage.stage_id === 'ST04') return SINGLE;
    if (stage.stage_id === 'ST06') return SURVIVAL;
    return SHARED_POOL;
  }

  playerGains(amount) {
    if (amount <= 0) return 0;
    if (this.model !== SHARED_POOL) {
      const before = this.player;
      this.player = clamp(this.player + amount, 0, this.maximum);
      return this.player - before;
    }
    const fromUndecided = Math.min(amount, this.undecided);
    this.undecided -= fromUndecided;
    this.player += fromUndecided;

    const fromOpponent = Math.min(amount - fromUndecided, this.opponent);
    this.opponent -= fromOpponent;
    this.player += fromOpponent;

    return fromUndecided + fromOpponent;
  }

  // Whoever the opponent loses goes back to undecided — they are not
  // automatically convinced of the other case.
  opponentLoses(amount) {
    if (amount <= 0) return 0;
    if (this.model !== SHARED_POOL) return this.playerGains(amount);

    const moved = Math.min(amount, this.opponent);
    this.opponent -= moved;
    this.undecided += moved;
    return moved;
  }

  opponentGains(amount) {
    if (amount <= 0) return 0;
    if (this.model !== SHARED_POOL) return 0;

    const fromUndecided = Math.min(amount, this.undecided);
    this.undecided -= fromUndecided;
    this.opponent += fromUndecided;

    const fromPlayer = Math.min(amount - fromUndecided, this.player);
    this.player -= fromPlayer;
    this.opponent += fromPlayer;

    return fromUndecided + fromPlayer;
  }

  playerLoses(amount) {
    if (amount <= 0) return 0;
    const moved = Math.min(amount, this.player);
    this.player -= moved;
    if (this.model === SHARED_POOL) this.undecided += moved;
    return moved;
  }

  playerHasWon() { return this.player >= this.threshold; }
  opponentHasWon() { return this.model === SHARED_POOL && this.opponent >= this.threshold; }
  playerBelowThreshold() { return this.player < this.threshold; }

  // In a shared pool the three numbers must always add up to the size of the
  // room, no matter what has happened.
  totalsBalance() {
    if (this.model !== SHARED_POOL) return true;
    return this.player + this.opponent + this.undecided === this.maximum;
  }
}

function clamp(value, low, high) { return Math.min(Math.max(value, low), high); }

// ---------------------------------------------------------------------------
// IntentRunner
// ---------------------------------------------------------------------------

const KNOWN_VERBS = ['attack', 'gain', 'block', 'lean_down'];

class IntentRunner {
  constructor(pattern) {
    this.pattern = Array.isArray(pattern) ? JSON.parse(JSON.stringify(pattern)) : [];
    this.position = 0;
  }

  isValid() { return this.pattern.length > 0 && this.problems().length === 0; }

  problems() {
    const found = [];
    if (this.pattern.length === 0) {
      found.push('the opponent has no intent pattern, so it cannot take a turn');
      return found;
    }
    this.pattern.forEach((move, index) => {
      if (!Array.isArray(move) || move.length < 2) {
        found.push('move ' + (index + 1) + ' should be a verb and a number, such as ["attack", 6]');
        return;
      }
      if (!KNOWN_VERBS.includes(String(move[0]))) {
        found.push('move ' + (index + 1) + " uses '" + move[0] + "', which is not one of " + KNOWN_VERBS.join(', '));
      }
    });
    return found;
  }

  moveAt(index) {
    if (this.pattern.length === 0) return { verb: 'none', value: 0 };
    const move = this.pattern[((index % this.pattern.length) + this.pattern.length) % this.pattern.length];
    return { verb: String(move[0]), value: Math.trunc(move[1]) };
  }

  peek() { return this.moveAt(this.position); }
  peekAhead() { return this.moveAt(this.position + 1); }

  advance() {
    const move = this.moveAt(this.position);
    this.position = (this.position + 1) % Math.max(this.pattern.length, 1);
    return move;
  }

  static describe(move) {
    const value = Math.trunc((move && move.value) || 0);
    switch (String((move && move.verb) || 'none')) {
      case 'attack': return 'Attacking · −' + value;
      case 'gain': return 'Gaining · +' + value;
      case 'block': return 'Defending · ' + value;
      case 'lean_down': return 'Pressuring · −' + value;
      default: return 'Waiting';
    }
  }
}

// ---------------------------------------------------------------------------
// BattleState
// ---------------------------------------------------------------------------

class BattleState {
  constructor() {
    this.deck = [];
    this.hand = [];
    this.discard = [];

    this.turn = 1;
    this.energy = 0;
    this.energy_per_turn = 3;
    this.energy_mode = 'per_turn';   // 'per_turn' | 'pool'
    this.energy_max = 3;

    this.win_mode = 'threshold';     // 'threshold' | 'score'
    this.draw_mode = 'refill';       // 'refill' | 'none'
    this.hand_size = 5;

    this.block = 0;
    this.next_card_bonus = 0;

    this.gaffe = 0;
    this.gaffe_limit = 5;
    this.opponent_gaffe = 0;
    this.opponent_block = 0;

    this.bar = null;
    this.next_intent_revealed = false;

    this.question_index = 0;
    this.pleased_boosters = [];

    this.opponent_index = 0;
    this.opponent_count = 1;

    this.outcome = 'ongoing';
    this.outcome_reason = '';
  }

  isOver() { return this.outcome !== 'ongoing'; }
  playerScore() { return this.bar ? this.bar.player : 0; }
}

// ---------------------------------------------------------------------------
// BattleEngine
// ---------------------------------------------------------------------------

class BattleEngine {
  constructor() {
    this.state = null;
    this.setupProblems = [];
    this.usedDefaultIntentPattern = false;
    this._questions = [];
    this._opponents = [];
    this._intents = null;
    this._sequenceMode = 'single';
  }

  setup(config) {
    this.setupProblems = [];
    this._stage = config.stage || {};
    this._opponent = config.opponent || {};
    this._cards = config.cards || {};
    this._affinity = config.affinity || {};
    this._rules = config.rules || {};
    this._meta = config.meta || {};

    if (Object.keys(this._stage).length === 0) {
      this.setupProblems.push('no stage was given');
      return false;
    }

    this._rng = makeRng(config.seed === undefined ? (Date.now() & 0x7fffffff) : config.seed);

    const s = new BattleState();
    this.state = s;
    s.energy_per_turn = int(this._stage.energy_per_turn, 3);
    s.energy_mode = str(this._stage.energy_mode, 'per_turn');
    s.win_mode = str(this._stage.win_mode, 'threshold');
    s.draw_mode = str(this._stage.draw_mode, 'refill');
    this._questions = this._stage.questions || [];

    // A press conference deals a bigger opening hand and then nothing more,
    // so "opening_hand" wins over the ordinary hand size where both exist.
    s.hand_size = int(this._stage.opening_hand, int(this._stage.hand_size, 5));
    s.gaffe_limit = int(this._stage.gaffe_limit, 5);

    this._setupOpponent(config);
    this._setupBoard(config);
    this._setupDeck(config);

    if (this.setupProblems.length > 0) return false;

    // A pool stage hands out its whole allowance now and never tops it up.
    s.energy = s.energy_mode === 'pool'
      ? int(this._stage.energy_pool, s.energy_per_turn)
      : s.energy_per_turn;
    s.energy_max = s.energy;

    this._drawUpToHandSize();
    return true;
  }

  _setupOpponent(config) {
    if (str(this._rules.opponent_engine, 'intent_patterns') === 'deck_ai') {
      this.setupProblems.push("rules.json is set to 'deck_ai', but opponents that play their own cards are not built yet.");
      return;
    }

    this._opponents = config.opponents || [];
    if (this._opponents.length === 0) {
      this._opponents = Object.keys(this._opponent).length > 0 ? [this._opponent] : [];
    }
    this._sequenceMode = str(this._stage.sequence_mode, 'single');

    if (this._opponents.length === 0) {
      // A press conference has no opponent: the reporters' questions are what
      // pushes back. Any other stage with nobody in it is a mistake.
      if (this._questions.length === 0) {
        this.setupProblems.push('there is nobody to argue with');
      }
      this.state.opponent_count = 0;
      return;
    }

    this.state.opponent_index = 0;
    this.state.opponent_count = this._opponents.length;
    this._opponent = this._opponents[0];
    this._armIntents(config);
  }

  // An opponent with a pattern of their own always uses it; otherwise they
  // fall back to the shared default in rules.json, so a missing pattern makes
  // an opponent generic rather than unplayable.
  _armIntents(config) {
    config = config || {};
    let pattern = this._opponent.intent_pattern;
    if (pattern === null || pattern === undefined) pattern = config.intent_pattern;
    if (pattern === null || pattern === undefined) {
      pattern = this._rules.default_intent_pattern;
      if (pattern !== null && pattern !== undefined) this.usedDefaultIntentPattern = true;
    }

    this._intents = new IntentRunner(pattern);
    if (!this._intents.isValid()) {
      for (const problem of this._intents.problems()) {
        this.setupProblems.push((this._opponent.name || 'the opponent') + ': ' + problem);
      }
    }
  }

  _setupBoard(config) {
    const playerStart = int(this._stage.player_start, 0) + int(config.start_adjustment, 0);
    const opponentStart = int(this._stage.opp_start, 0) + int(config.bill_difficulty, 0);

    this.state.bar = new BarModel(
      BarModel.forStage(this._stage),
      int(this._stage.bar_max, 100),
      int(this._stage.win_threshold, 51),
      playerStart,
      opponentStart
    );
  }

  _setupDeck(config) {
    const deck = config.deck || [];
    if (deck.length === 0) {
      this.setupProblems.push('the player has no deck');
      return;
    }
    for (const cardId of deck) {
      if (!this._cards[cardId]) {
        this.setupProblems.push("card '" + cardId + "' is in the deck but not in the card data");
      } else {
        this.state.deck.push(cardId);
      }
    }
    shuffle(this.state.deck, this._rng);
  }

  // The suit multiplier for this stage. A playtest stage can name a canon
  // stage under affinity_stage_id, so a press conference favours the same
  // suits wherever it is played.
  affinityFor(card) {
    const element = str(card.suit, '');
    const stageId = str(this._stage.affinity_stage_id, str(this._stage.stage_id, ''));
    const row = this._affinity[element];
    if (row && row[stageId] !== undefined) return Number(row[stageId]);
    return 1.0;
  }

  playCard(cardId) {
    const s = this.state;
    if (s.isOver()) return refused('the battle is already over');
    if (!s.hand.includes(cardId)) return refused('that card is not in hand');

    const card = this._cards[cardId];
    if (!card) return refused("there is no card with the ID '" + cardId + "'");

    const cost = int(card.cost, 0);
    if (cost > s.energy) return refused('not enough time left this turn');

    const context = {
      affinity: this.affinityFor(card),
      segment_share: segmentShare(card, this._stage),
      kanban: int(this._meta.Reputation, 50),
      opponent_gaffe: s.opponent_gaffe,
      next_card_bonus: s.next_card_bonus,
    };
    const effect = resolveCard(card, context);

    s.energy -= cost;
    s.hand.splice(s.hand.indexOf(cardId), 1);
    s.next_card_bonus = 0;

    const applied = this._applyEffect(effect);

    // Into the discard pile only AFTER its effects have resolved, or a card
    // that draws could empty the deck, reshuffle, and deal the player back
    // the very card they just played.
    s.discard.push(cardId);

    const flags = effect.flags || {};
    if (flags.next_card_bonus !== undefined) s.next_card_bonus = Math.trunc(flags.next_card_bonus);
    if (flags.reveal_next_intent) s.next_intent_revealed = true;

    if (this._questions.length > 0) this._answerQuestion(card);

    this._checkOutcome(false);

    const result = { ok: true, card_id: cardId, effect: effect, applied: applied, energy_left: s.energy };

    // A card that passes the round hands the turn over as it is played.
    // Declining and then playing on would not be declining.
    if (flags.end_turn && !s.isOver() && this._intents !== null) {
      result.ended_turn = this.endTurn();
    }
    return result;
  }

  // Support, then guard, then gaffe, then draw.
  _applyEffect(effect) {
    const s = this.state;
    const applied = { gained: 0, opponent_lost: 0, guard: 0, gaffe: 0, drawn: 0 };

    applied.gained = s.bar.playerGains(int(effect.self_plus, 0));
    applied.opponent_lost = s.bar.opponentLoses(int(effect.opp_minus, 0));

    const guard = int(effect.guard, 0);
    s.block += guard;
    applied.guard = guard;

    // The gaffe meter never goes below zero, so an apology on a clean record
    // is wasted rather than banked.
    const beforeGaffe = s.gaffe;
    s.gaffe = Math.max(s.gaffe + int(effect.gaffe, 0), 0);
    applied.gaffe = s.gaffe - beforeGaffe;

    applied.drawn = this._draw(int(effect.draw, 0));
    return applied;
  }

  endTurn() {
    const s = this.state;
    if (s.isOver()) return { ok: false, reason: 'the battle is already over' };

    // A hand you cannot replace is the exception: in a press conference you
    // are dealt six cards and draw no more, so throwing the rest away would
    // end the conference with questions still coming.
    if (bool(this._rules.discard_hand_end_of_turn, true) && s.draw_mode !== 'none') {
      s.discard = s.discard.concat(s.hand);
      s.hand = [];
    }

    // The opponent acts — if there is one.
    let intent = { verb: 'none', value: 0 };
    let opponentResult = { verb: 'none' };
    if (this._intents !== null) {
      intent = this._intents.advance();
      opponentResult = this._resolveIntent(intent);
    }

    s.block = 0;
    s.next_card_bonus = 0;
    s.next_intent_revealed = false;

    this._checkOutcome(true);

    if (!s.isOver()) {
      s.turn += 1;
      if (s.energy_mode !== 'pool') s.energy = s.energy_per_turn;
      if (s.draw_mode !== 'none') this._drawUpToHandSize();
    }

    return { ok: true, intent: intent, opponent: opponentResult, turn: s.turn, outcome: s.outcome };
  }

  _resolveIntent(intent) {
    const s = this.state;
    const value = int(intent.value, 0);

    switch (str(intent.verb, 'none')) {
      case 'attack': {
        const absorbed = Math.min(s.block, value);
        const through = Math.max(value - s.block, 0);
        return { verb: 'attack', absorbed: absorbed, damage: s.bar.playerLoses(through) };
      }
      case 'gain':
        return { verb: 'gain', gained: s.bar.opponentGains(value) };
      case 'block':
        s.opponent_block += value;
        return { verb: 'block', guard: value };
    }
    return { verb: 'none' };
  }

  _checkOutcome(endOfTurn) {
    const s = this.state;
    if (s.isOver()) return;

    // Losing on gaffes happens the moment it happens, mid-turn.
    if (s.gaffe >= s.gaffe_limit) return this._finish('loss', 'The gaffe meter filled.');

    // A press conference ends when the reporters run out of questions, or
    // when the player runs out of anything to answer with.
    if (this._questions.length > 0) {
      if (this.questionsRemaining() <= 0) {
        return this._finish('win', 'Every question was answered.');
      }
      // The discard pile is not counted: in a conference that never draws, a
      // card once played is gone for good.
      let canStillAnswer = s.hand.length > 0;
      if (s.draw_mode !== 'none') canStillAnswer = canStillAnswer || s.deck.length > 0;
      if (!canStillAnswer) {
        return this._finish('win', 'The questions ran on, but there was nothing left to say.');
      }
    }

    // Three stages have no threshold to cross: a survival stage is staying
    // alive, a scored stage has no line at all, and a press conference runs
    // until the reporters are finished.
    const hasThreshold = s.bar.model !== SURVIVAL
      && s.win_mode !== 'score'
      && this._questions.length === 0;

    if (hasThreshold && s.bar.playerHasWon()) {
      // In a committee, winning the argument wins this bout, not the stage.
      if (this._sequenceMode === 'reset' && this.hasMoreOpponents()) {
        return this._advanceToNextOpponent();
      }
      return this._finish('win', this._victoryReason());
    }

    // On the floor, arguing an opponent's seats down to nothing brings on the
    // next. Running out of opponents wins it even short of a majority.
    if (this._sequenceMode === 'continuous' && s.bar.opponent <= 0) {
      if (this.hasMoreOpponents()) return this._advanceToNextOpponent();
      return this._finish('win', 'Every opponent has been argued out of the chamber.');
    }

    if (bool(this._rules.opponent_can_win_by_threshold, false) && s.bar.opponentHasWon()) {
      return this._finish('loss', 'The opponent reached the threshold first.');
    }

    if (endOfTurn && s.bar.model === SURVIVAL && s.bar.playerBelowThreshold()) {
      return this._finish('loss', 'Support fell below the line during the debate.');
    }

    if (endOfTurn) this._checkTurnLimit();
  }

  _checkTurnLimit() {
    const s = this.state;
    const limit = int(this._stage.turn_limit, 0);
    if (limit <= 0 || s.turn < limit) return;

    if (s.bar && s.bar.model === SURVIVAL) {
      return this._finish('win', 'Survived the whole debate above the line.');
    }

    // A scored stage is not won or lost on the clock — running out of turns
    // is simply how it ends.
    if (s.win_mode === 'score') {
      return this._finish('win', 'The caucus closed with ' + s.playerScore() + ' support.');
    }

    switch (str(this._rules.turn_limit_outcome, 'loss')) {
      case 'highest_support_wins':
        return s.bar.player > s.bar.opponent
          ? this._finish('win', 'Time ran out with the player ahead.')
          : this._finish('loss', 'Time ran out with the player behind.');
      case 'tie_retry':
        return this._finish('retry', 'Time ran out with no decision. The stage restarts.');
      default:
        return this._finish('loss', 'Time ran out before the threshold was reached.');
    }
  }

  currentOpponent() {
    const i = this.state.opponent_index;
    if (i < 0 || i >= this._opponents.length) return this._opponent;
    return this._opponents[i];
  }

  hasMoreOpponents() { return this.state.opponent_index + 1 < this._opponents.length; }

  opponentCaption() {
    if (this.state.opponent_count <= 1) return '';
    return (this.state.opponent_index + 1) + ' of ' + this.state.opponent_count;
  }

  // In a committee this is a fresh argument. On the floor it is the same room
  // carrying on: the seats you have won stay won and the clock keeps running.
  _advanceToNextOpponent() {
    const s = this.state;
    s.opponent_index += 1;
    this._opponent = this._opponents[s.opponent_index];
    this._armIntents();

    if (this._sequenceMode === 'reset') {
      this._resetForNewBout();
    } else if (s.bar) {
      // Their seats have to come from somewhere, and taking them from the
      // player would punish winning. They come from the undecided.
      s.bar.opponentGains(int(this._stage.opp_start, 0));
    }
  }

  _resetForNewBout() {
    const s = this.state;
    s.gaffe = 0;
    s.block = 0;
    s.opponent_block = 0;
    s.next_card_bonus = 0;
    s.next_intent_revealed = false;
    s.turn = 1;

    s.energy = s.energy_max;
    if (s.energy_mode !== 'pool') {
      s.energy = s.energy_per_turn;
      s.energy_max = s.energy_per_turn;
    }

    s.bar = new BarModel(
      BarModel.forStage(this._stage),
      int(this._stage.bar_max, 100),
      int(this._stage.win_threshold, 51),
      int(this._stage.player_start, 0),
      int(this._stage.opp_start, 0)
    );

    // A clean deck, so the last argument's spent cards are not a handicap.
    s.deck = s.deck.concat(s.hand, s.discard);
    s.hand = [];
    s.discard = [];
    shuffle(s.deck, this._rng);
    this._drawUpToHandSize();
  }

  _victoryReason() {
    if (this._sequenceMode === 'reset' && this.state.opponent_count > 1) {
      return 'All ' + this.state.opponent_count + ' were argued down.';
    }
    return 'The support threshold was reached.';
  }

  _finish(outcome, reason) {
    this.state.outcome = outcome;
    this.state.outcome_reason = reason;
  }

  // Draws cards, reshuffling the discard pile back in when the deck runs dry.
  _draw(count) {
    const s = this.state;
    let drawn = 0;
    for (let i = 0; i < count; i++) {
      if (s.deck.length === 0) {
        if (s.discard.length === 0) break;   // every card is already in hand
        s.deck = s.discard;
        s.discard = [];
        shuffle(s.deck, this._rng);
      }
      s.hand.push(s.deck.shift());
      drawn += 1;
    }
    return drawn;
  }

  _drawUpToHandSize() {
    return this._draw(Math.max(this.state.hand_size - this.state.hand.length, 0));
  }

  // --- the press conference ---

  // Stays true once the last question is answered, so the screen does not
  // change its shape at the moment the conference ends.
  isPressConference() { return this._questions.length > 0; }

  currentQuestion() {
    const i = this.state.question_index;
    if (i < 0 || i >= this._questions.length) return null;
    return this._questions[i];
  }

  questionsRemaining() {
    return Math.max(this._questions.length - this.state.question_index, 0);
  }

  pleasedBoosters() { return this.state.pleased_boosters; }

  questionCaption() {
    if (this._questions.length === 0) return '';
    return 'Question ' + Math.min(this.state.question_index + 1, this._questions.length)
      + ' of ' + this._questions.length;
  }

  // Every card answers. Answering in the suit the question invites also
  // pleases the organisation behind it.
  _answerQuestion(card) {
    const question = this.currentQuestion();
    if (!question) return;
    if (card.suit === question.prefers_suit) {
      const booster = String(question.pleases_booster || '');
      if (booster && !this.state.pleased_boosters.includes(booster)) {
        this.state.pleased_boosters.push(booster);
      }
    }
    this.state.question_index += 1;
  }

  currentIntent() { return this._intents ? this._intents.peek() : { verb: 'none', value: 0 }; }

  upcomingIntent() {
    if (this._intents === null || !this.state.next_intent_revealed) return null;
    return this._intents.peekAhead();
  }

  gaffeIsCritical() { return this.state.gaffe >= this.state.gaffe_limit - 1; }

  turnCaption() {
    return 'Turn ' + this.state.turn + ' of ' + int(this._stage.turn_limit, 0);
  }
}

function refused(reason) { return { ok: false, reason: reason }; }

// ---------------------------------------------------------------------------
// LevelRunner
// ---------------------------------------------------------------------------

const ONGOING = 'ongoing', WON = 'win', LOST = 'loss';

class LevelRunner {
  constructor(levelData) {
    this.level = levelData || {};
    this.stages = (this.level.stages || []).slice().sort((a, b) => int(a.seq, 0) - int(b.seq, 0));
    this.index = 0;
    this.results = {};
    this._outcome = ONGOING;
  }

  currentStage() { return this.stages[this.index] || {}; }
  stageCount() { return this.stages.length; }
  isFinished() { return this._outcome !== ONGOING; }
  outcome() { return this._outcome; }

  progressCaption() {
    return 'Stage ' + Math.min(this.index + 1, this.stages.length) + ' of ' + this.stages.length;
  }

  finishStage(stageOutcome, score, boosters) {
    if (this.isFinished()) return;
    const stage = this.currentStage();
    if (Object.keys(stage).length === 0) return;

    this.results[int(stage.seq, this.index + 1)] = {
      outcome: stageOutcome,
      score: Math.trunc(score || 0),
      boosters: (boosters || []).slice(),
    };

    if (stageOutcome === LOST) { this._outcome = LOST; return; }

    this.index += 1;
    if (this.index >= this.stages.length) this._outcome = WON;
  }

  carriedBuffs() {
    const buffs = { support_bonus: 0, boosters: [] };

    for (const entry of this.carriedBreakdown()) {
      buffs.support_bonus += entry.support_bonus;
    }
    for (const seq of (this.currentStage().carries_buffs_from || [])) {
      const result = this.results[Math.trunc(seq)];
      if (!result) continue;
      for (const boosterId of result.boosters) {
        if (!buffs.boosters.includes(boosterId)) buffs.boosters.push(boosterId);
      }
    }
    return buffs;
  }

  carriedBreakdown() {
    const entries = [];
    for (const seq of (this.currentStage().carries_buffs_from || [])) {
      const result = this.results[Math.trunc(seq)];
      if (!result) continue;
      const from = this.stageBySeq(Math.trunc(seq));
      entries.push({
        seq: Math.trunc(seq),
        name: str(from.name_en, 'An earlier stage'),
        score: result.score,
        support_bonus: LevelRunner.scoreToSupport(from, result.score),
      });
    }
    return entries;
  }

  // How much a stage's closing score is worth to a later one. The conversion
  // belongs to the stage that produced the score, under its own tone_effects,
  // so a press conference and a caucus can be worth different things.
  // Rounding is towards zero in both directions, so being five points short
  // of the baseline is worth nothing rather than costing a whole point.
  static scoreToSupport(stage, score) {
    const effects = stage.tone_effects || {};
    const per = int(effects.support_per_points, 10);
    if (per <= 0) return 0;

    const baseline = int(effects.baseline, 50);
    const bonus = Math.trunc((score - baseline) / per);

    if (bonus < 0 && !bool(effects.allow_negative, false)) return 0;
    return bonus;
  }

  // A stage whose score nobody carries should not promise the player that it
  // is worth something later, because it is not.
  scoreIsCarriedFrom(seq) {
    for (const stage of this.stages) {
      if (int(stage.seq, -1) <= seq) continue;
      for (const source of (stage.carries_buffs_from || [])) {
        if (Math.trunc(source) === seq) return true;
      }
    }
    return false;
  }

  stageBySeq(seq) {
    for (const stage of this.stages) {
      if (int(stage.seq, -1) === seq) return stage;
    }
    return {};
  }

  describeCarriedBuffs(names) {
    names = names || {};
    const lines = [];

    for (const entry of this.carriedBreakdown()) {
      if (entry.support_bonus > 0) {
        lines.push(entry.name + ' went well: you start ' + entry.support_bonus + ' ahead.');
      } else if (entry.support_bonus < 0) {
        lines.push(entry.name + ' went badly: you start ' + (-entry.support_bonus) + ' behind.');
      }
    }

    const boosters = this.carriedBuffs().boosters;
    if (boosters.length > 0) {
      lines.push('Pleased at the press conference: '
        + boosters.map(id => names[id] || id).join(', ') + '.');
    }

    if (lines.length === 0) return 'Nothing carried over from the earlier stages.';
    return lines.join('\n');
  }
}

// ---------------------------------------------------------------------------
// MetaRules
// ---------------------------------------------------------------------------

function clampMeta(value, variable) {
  return clamp(value, int(variable.min, 0), int(variable.max, 100));
}

function findVariable(rows, name) {
  for (const row of rows) if (row.name_en === name) return row;
  return {};
}

// A stage says what its score is worth under tone_effects.meta: a variable
// name mapped to how many points of score make one point of it.
function applyScoreEffects(meta, stage, score, sanbanRows) {
  const updated = Object.assign({}, meta);
  const applied = {};

  const effects = stage.tone_effects || {};
  const perVariable = effects.meta || {};
  if (Object.keys(perVariable).length === 0) return { meta: updated, applied: applied };

  const distance = score - int(effects.baseline, 50);

  for (const name of Object.keys(perVariable)) {
    const per = Math.trunc(perVariable[name]);
    if (per <= 0) continue;

    // Towards zero in both directions.
    const delta = Math.trunc(distance / per);
    if (delta === 0) continue;

    const variable = findVariable(sanbanRows, name);
    const before = int(updated[name], int(variable.start, 0));
    const after = clampMeta(before + delta, variable);
    updated[name] = after;
    applied[name] = after - before;
  }

  return { meta: updated, applied: applied };
}

// ---------------------------------------------------------------------------
// BattleSetup — the bridge from the data files to the engine
// ---------------------------------------------------------------------------

function cardTable(data) {
  const table = {};
  for (const card of data.cards) table[card.card_id] = card;
  return table;
}

function starterDeck(data) {
  return data.cards.filter(c => c.tier === 'Starter').map(c => c.card_id);
}

function affinityTable(data) {
  const table = {};
  for (const row of data.affinity) table[row.element] = row.multipliers || {};
  return table;
}

function boosterNames(data) {
  const names = {};
  for (const b of data.boosters) names[b.booster_id] = b.name_en;
  return names;
}

function startingMeta(data) {
  const meta = {};
  for (const row of data.sanban) meta[row.name_en] = int(row.start, 0);
  return meta;
}

function forPlaytestStage(data, stage, buffs, meta, seed) {
  buffs = buffs || {};
  const opponents = stage.opponents || [];
  return {
    stage: stage,
    opponent: opponents.length > 0 ? opponents[0] : {},
    opponents: opponents,
    cards: cardTable(data),
    affinity: affinityTable(data),
    rules: data.rules,
    meta: meta || startingMeta(data),
    deck: starterDeck(data),
    start_adjustment: int(buffs.support_bonus, 0),
    seed: seed,
  };
}

// --- small helpers, so a missing cell reads the same way it does in Godot ---

function int(value, fallback) {
  if (value === null || value === undefined || value === '') return fallback;
  const n = Math.trunc(Number(value));
  return Number.isNaN(n) ? fallback : n;
}

function str(value, fallback) {
  if (value === null || value === undefined) return fallback;
  return String(value);
}

function bool(value, fallback) {
  if (value === null || value === undefined) return fallback;
  return Boolean(value);
}
