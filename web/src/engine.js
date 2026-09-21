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
  'pierce_guard',
  'bonus_if_self_gaffe_0',
  'bonus_if_behind',
  'discount_next_card_this_turn',
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
    case 'pierce_guard':
      // C16, C42, C49: "Ignores N of the opponent's Guard."
      //
      // A flag rather than a number change: the guard is not spent by being
      // ignored, so the battle has to take it off the opponent's bank BEFORE
      // the attack and put it back after. Doing it here would either
      // double-count or leave the bank wrong.
      result.flags.pierce_guard = amount;
      result.flags.special_triggered = true;
      break;
    case 'bonus_if_self_gaffe_0':
      // C25, C29: the reward for a clean record, and the reason to keep one.
      if (Math.trunc(context.self_gaffe || 0) === 0) {
        result.self_plus += amount;
        result.flags.special_triggered = true;
      }
      break;
    case 'bonus_if_behind':
      // C33, C53. Strictly behind: level pegging is not behind. A comeback
      // card that also fired when you were even would fire most of the time.
      if (Math.trunc(context.player_support || 0) < Math.trunc(context.opponent_support || 0)) {
        result.self_plus += amount;
        result.flags.special_triggered = true;
      }
      break;
    case 'discount_next_card_this_turn':
      // C36, the mirror of buff_next_card_this_turn: the battle spends it on
      // the next card played and it does not survive the turn.
      result.flags.next_card_discount = amount;
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

// What it costs, in persuasion points, to win over one seat.
//
// Somebody not yet committed either way comes across for a single point.
// Somebody already sitting with the opposition is harder, and how much
// harder varies from person to person: usually one point, sometimes two,
// occasionally three. That is what makes the end of a debate slower than the
// start even though the numbers look the same.
const UNDECIDED_COST = 1;
const OPPONENT_COST_ODDS = [
  { cost: 1, chance: 60 },
  { cost: 2, chance: 30 },
  { cost: 3, chance: 10 },
];

class BarModel {
  constructor(model, maximum, threshold, playerStart, opponentStart, costRoller) {
    this.model = model;
    // Handed in rather than made here, so the whole battle runs off one
    // seeded generator and a test can post a fixed answer. A bar built
    // without one rolls for itself: a missing roller must never quietly turn
    // the rule off and make every seat cost a point.
    this._costRoller = costRoller || (() => Math.floor(Math.random() * 100));
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

    // True in a stage where only the player's own total is scored.
    this.scoredOnly = false;

    // How the last gain was actually made, so a screen can say "2 from the
    // undecided, 1 argued across" rather than a bare total. `from_other_side`
    // means whoever was taken off the opposing side, so the same two keys
    // describe either side's move. `wasted` is the points that could not pay
    // for anybody: leftovers are lost, and the screen should say so.
    this.last_gain = { from_undecided: 0, from_other_side: 0, wasted: 0 };
  }

  static forStage(stage) {
    // A stage built out of reporters' questions is a press conference
    // wherever it appears, read from its shape rather than from its name.
    if (Array.isArray(stage.questions) && stage.questions.length > 0) return SINGLE;
    if (stage.stage_id === 'ST04') return SINGLE;
    if (stage.stage_id === 'ST06') return SURVIVAL;
    return SHARED_POOL;
  }

  // `amount` is a budget of persuasion points, not a number of seats. The
  // undecided come across first at a point each; once they run out, every
  // further seat has to be bought off the opposition at whatever that person
  // costs. Points that cannot pay for the next seat are LOST rather than
  // held over: a big push can fall just short of a stubborn vote.
  //
  // Returns the number of seats that actually moved.
  playerGains(amount) {
    if (amount <= 0) return 0;
    this.last_gain = { from_undecided: 0, from_other_side: 0, wasted: 0 };

    if (this.model !== SHARED_POOL) {
      const before = this.player;
      this.player = clamp(this.player + amount, 0, this.maximum);
      // A single bar is a level, not a room: nobody to win over, so the
      // whole move counts as one undivided rise.
      this.last_gain.from_undecided = this.player - before;
      return this.player - before;
    }

    let budget = amount;
    let moved = 0;

    while (budget > 0) {
      if (this.undecided > 0) {
        if (budget < UNDECIDED_COST) break;
        budget -= UNDECIDED_COST;
        this.undecided -= 1;
        this.player += 1;
        moved += 1;
        this.last_gain.from_undecided += 1;
        continue;
      }

      if (this.opponent <= 0) break;   // the whole room is already yours

      const cost = this.rollOpponentCost();
      if (budget < cost) break;        // and it is not banked
      budget -= cost;
      this.opponent -= 1;
      this.player += 1;
      moved += 1;
      this.last_gain.from_other_side += 1;
    }

    this.last_gain.wasted = budget;
    return moved;
  }

  // What the next seat held by the opposition costs, in points.
  rollOpponentCost() {
    const roll = this._costRoller();
    let seen = 0;
    for (const band of OPPONENT_COST_ODDS) {
      seen += band.chance;
      if (roll < seen) return band.cost;
    }
    return OPPONENT_COST_ODDS[OPPONENT_COST_ODDS.length - 1].cost;
  }

  // Whoever the opponent loses goes back to undecided — they are not
  // automatically convinced of the other case.
  //
  // Where the opponent's number is not part of the win condition this does
  // NOTHING. There is nobody in a press conference whose support you are
  // reducing, and in a caucus only your own total is scored. It used to
  // convert into your own gain, which made a card printing both numbers
  // worth double in a conference — a playtest caught that.
  opponentLoses(amount) {
    if (amount <= 0) return 0;
    if (this.reduceDoesNothing()) return 0;

    const moved = Math.min(amount, this.opponent);
    this.opponent -= moved;
    this.undecided += moved;
    return moved;
  }

  // True where arguing the opposition down achieves nothing at all.
  //
  // The caucus is the awkward case: it IS a shared pool with real opponent
  // supporters, and pushing them into the undecided pile used to make room
  // for the next card. Scoring it as nothing removes that combination — if
  // the caucus ever feels flat, this is the first thing to reconsider.
  reduceDoesNothing() {
    return this.model !== SHARED_POOL || this.scoredOnly;
  }

  opponentGains(amount) {
    if (amount <= 0) return 0;
    if (this.model !== SHARED_POOL) return 0;

    const fromUndecided = Math.min(amount, this.undecided);
    this.undecided -= fromUndecided;
    this.opponent += fromUndecided;

    const stillWanted = amount - fromUndecided;
    const fromPlayer = Math.min(stillWanted, this.player);
    this.player -= fromPlayer;
    this.opponent += fromPlayer;

    // Recorded the same way the player's gains are, so one helper can
    // describe either side's move.
    this.last_gain = {
      from_undecided: fromUndecided,
      from_other_side: fromPlayer,
      wasted: stillWanted - fromPlayer,
    };
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

// A pattern is a list of moves. A move is a verb and either one number or a
// range to roll between, inclusive at both ends:
//
//     [["attack", 4], ["gain", 0, 1], ["block", 3, 5]]
//
// THE ZERO RULE. A move that comes out at zero is NOT TAKEN: the opponent
// steps to the next move in the cycle and does that instead, so nobody ever
// spends a turn guarding nothing. An opponent whose pattern carries a flat
// "block 0" simply never guards.
//
// WHEN THE ROLL HAPPENS, and why it matters: at peek, once, and then held.
// The screen repaints several times a turn, so rolling inside peek() without
// holding would re-roll the intent on every repaint. And skipping a zero
// CHANGES THE VERB — if the skip happened when the move resolved, the screen
// could announce "Guarding" and the opponent could attack instead.
function zeroShape() { return { verb: 'none', value: 0 }; }

class IntentRunner {
  // `roller` is handed in so the whole battle runs off one seeded generator
  // and a test can post a fixed answer, the same arrangement BarModel uses
  // for what a stubborn vote costs.
  constructor(pattern, roller) {
    this.pattern = Array.isArray(pattern) ? JSON.parse(JSON.stringify(pattern)) : [];
    this.position = 0;
    this._roller = roller || ((low, high) => low + Math.floor(Math.random() * (high - low + 1)));
    this._pending = null;
    this._pendingIndex = 0;
    this._ahead = null;
    this._aheadIndex = 0;
  }

  isValid() { return this.pattern.length > 0 && this.problems().length === 0; }

  problems() {
    const found = [];
    if (this.pattern.length === 0) {
      found.push('the opponent has no intent pattern, so it cannot take a turn');
      return found;
    }

    let anythingCanHappen = false;

    this.pattern.forEach((move, index) => {
      if (!Array.isArray(move) || move.length < 2) {
        found.push('move ' + (index + 1) + ' should be a verb and a number, such as ["attack", 6]');
        return;
      }
      if (!KNOWN_VERBS.includes(String(move[0]))) {
        found.push('move ' + (index + 1) + " uses '" + move[0] + "', which is not one of " + KNOWN_VERBS.join(', '));
      }
      // The largest this move could ever be. A move that can only come out
      // at zero is never taken, which is fine on its own — but a pattern
      // made entirely of them would leave the opponent standing there.
      const biggest = move.length >= 3
        ? Math.max(Math.trunc(move[1]), Math.trunc(move[2]))
        : Math.trunc(move[1]);
      if (biggest > 0) anythingCanHappen = true;
    });

    if (!anythingCanHappen) {
      found.push('every move in this pattern is worth nothing, so the opponent would never act');
    }
    return found;
  }

  // Finds the next move worth making, stepping past any that come out at
  // zero. Bounded to one lap: a pattern of nothing but zeros would otherwise
  // spin forever.
  _resolveFrom(index) {
    if (this.pattern.length === 0) return { move: zeroShape(), index: index };

    for (let step = 0; step < this.pattern.length; step++) {
      const at = this._wrap(index + step);
      const move = this._roll(this.pattern[at]);
      if (Math.trunc(move.value) !== 0) return { move: move, index: at };
    }
    return { move: zeroShape(), index: this._wrap(index) };
  }

  // Turns one written move into one that has happened. min and max ride
  // along only on a move that HAS a range: a fixed move keeps the plain
  // shape it has always had.
  _roll(raw) {
    if (!Array.isArray(raw) || raw.length < 2) return zeroShape();

    const verb = String(raw[0]);
    let low = Math.trunc(raw[1]);
    if (raw.length < 3) return { verb: verb, value: low };

    let high = Math.trunc(raw[2]);
    if (high < low) { const swap = low; low = high; high = swap; }

    return {
      verb: verb,
      value: high <= low ? low : Math.trunc(this._roller(low, high)),
      min: low,
      max: high,
    };
  }

  _wrap(index) {
    const size = this.pattern.length;
    return ((index % size) + size) % size;
  }

  peek() {
    if (this._pending === null) {
      const found = this._resolveFrom(this.position);
      this._pending = found.move;
      this._pendingIndex = found.index;
    }
    return this._pending;
  }

  peekAhead() {
    // The current move has to be settled first: where it lands is where the
    // one after it starts from, once any zeros have been stepped over.
    this.peek();
    if (this._ahead === null) {
      const found = this._resolveFrom(this._pendingIndex + 1);
      this._ahead = found.move;
      this._aheadIndex = found.index;
    }
    return this._ahead;
  }

  advance() {
    const move = this.peek();
    this.position = (this._pendingIndex + 1) % Math.max(this.pattern.length, 1);

    // Whatever Head Count already revealed becomes the next move rather than
    // being thrown away and rolled again, or the card would have lied.
    if (this._ahead === null) {
      this._pending = null;
    } else {
      this._pending = this._ahead;
      this._pendingIndex = this._aheadIndex;
    }
    this._ahead = null;

    return move;
  }

  setPosition(value) {
    const size = this.pattern.length;
    this.position = size === 0 ? 0 : ((value % size) + size) % size;
    // A held roll belongs to the position it was rolled for.
    this._pending = null;
    this._ahead = null;
  }

  // What this move could come out as: one number, or a low and a high.
  //
  // NEVER BELOW 1. A "block 0 to 2" cannot actually come out at 0 — a zero
  // would have been stepped over and something else shown instead — so
  // advertising "0 to 2" would promise an outcome that cannot happen.
  static shapeOf(move) {
    if (!move || move.min === undefined || move.max === undefined) {
      return [Math.trunc((move && move.value) || 0)];
    }
    const low = Math.max(Math.trunc(move.min), 1);
    const high = Math.trunc(move.max);
    if (high <= low) return [high > 0 ? high : low];
    return [low, high];
  }

  // The move written the way the player reads it: "Attacking · −6", or
  // "Attacking · −1 to −6" where it could be anything in a range.
  static describe(move) {
    const verb = String((move && move.verb) || 'none');
    if (verb === 'none') return 'Waiting';

    const shape = IntentRunner.shapeOf(move);
    const signed = (mark) => shape.length === 1
      ? mark + shape[0]
      : mark + shape[0] + ' to ' + mark + shape[1];
    const plain = () => shape.length === 1 ? String(shape[0]) : shape[0] + ' to ' + shape[1];

    switch (verb) {
      case 'attack': return 'Attacking · ' + signed('−');
      case 'gain': return 'Gaining · ' + signed('+');
      case 'block': return 'Guarding · ' + plain();
      case 'lean_down': return 'Pressuring · ' + signed('−');
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

    // Guard, as a bank on both sides: it stacks to guard_cap, carries
    // between turns, and is spent by whatever it stops.
    this.block = 0;
    this.opponent_block = 0;
    this.guard_cap = 5;
    this.next_card_bonus = 0;
    // A discount a card left behind for the next one played this turn. It
    // does not survive the turn.
    this.next_card_discount = 0;

    this.gaffe = 0;
    this.gaffe_limit = 5;
    this.opponent_gaffe = 0;

    // How many reporters were left without an answer.
    this.declined_questions = 0;

    this.bar = null;
    this.next_intent_revealed = false;

    // Ending a turn on zero is how a player passes, and passing costs
    // something. Counted rather than inferred from the energy spent: a card
    // can cost nothing, and a pool stage can leave energy unspent.
    this.cards_played_this_turn = 0;

    this.question_index = 0;
    // How many of this turn's questions have been answered. A room can take
    // more than one: the policy study session takes two.
    this.questions_answered_this_turn = 0;
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

    // A friendly reporter takes some of the heat before a word is said.
    // Never below zero: backing cannot put the meter into credit.
    s.gaffe = Math.max(int(config.starting_gaffe, 0), 0);
    s.guard_cap = int(this._rules.guard_cap, 5);

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

    // The opponent rolls its ranges off the battle's own generator, so a
    // seeded battle plays out the same way twice.
    this._intents = new IntentRunner(
      pattern, (low, high) => low + this._rng(high - low + 1));
    if (!this._intents.isValid()) {
      for (const problem of this._intents.problems()) {
        this.setupProblems.push((this._opponent.name || 'the opponent') + ': ' + problem);
      }
    }
  }

  _setupBoard(config) {
    this.state.bar = this._buildBar(
      int(this._stage.player_start, 0) + int(config.start_adjustment, 0),
      int(this._stage.opp_start, 0) + int(config.bill_difficulty, 0));
  }

  // The seat count, from the stage's own numbers. One place rather than
  // two, because a continuous stage rebuilds it every time a new debater
  // rises and the two must not drift apart.
  _buildBar(playerStart, opponentStart) {
    const bar = new BarModel(
      BarModel.forStage(this._stage),
      int(this._stage.bar_max, 100),
      int(this._stage.win_threshold, 51),
      playerStart,
      opponentStart,
      // The bar rolls what a stubborn vote costs off the battle's own
      // generator, so a seeded battle plays out the same way twice.
      () => this._rng(100)
    );

    // In a caucus only the player's own total is scored, so there is
    // nothing to be gained by arguing the other side down.
    bar.scoredOnly = str(this._stage.win_mode, 'threshold') === 'score';
    return bar;
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

    // A discount left behind by an earlier card this turn. Never below zero:
    // a card cannot pay you to play it.
    const cost = this.cardCost(card);
    if (cost > s.energy) return refused('not enough time left this turn');

    const context = Object.assign({
      affinity: this.affinityFor(card),
      segment_share: segmentShare(card, this._stage),
      kanban: int(this._meta.Reputation, 50),
      opponent_gaffe: s.opponent_gaffe,
      next_card_bonus: s.next_card_bonus,
    }, this._standingContext());
    const effect = resolveCard(card, context);

    s.energy -= cost;
    s.hand.splice(s.hand.indexOf(cardId), 1);
    s.cards_played_this_turn += 1;
    s.next_card_bonus = 0;     // a carried bonus is spent by the card using it
    s.next_card_discount = 0;  // and so is a carried discount

    const applied = this._applyEffect(effect);

    // Into the discard pile only AFTER its effects have resolved, or a card
    // that draws could empty the deck, reshuffle, and deal the player back
    // the very card they just played.
    s.discard.push(cardId);

    const flags = effect.flags || {};
    if (flags.next_card_bonus !== undefined) s.next_card_bonus = Math.trunc(flags.next_card_bonus);
    if (flags.next_card_discount !== undefined) s.next_card_discount = Math.trunc(flags.next_card_discount);
    if (flags.reveal_next_intent) s.next_intent_revealed = true;

    // A room can take more than one question a turn — the policy study
    // session takes two. Cards played past the quota still do everything
    // else they do; they just are not answers.
    if (this._questions.length > 0 && s.questions_answered_this_turn < this._questionsPerTurn()) {
      this._answerQuestion(card);
      s.questions_answered_this_turn += 1;
    }

    // Who was in front of us before the outcome was checked. A card that
    // finishes a debater changes the whole room underneath the player, and
    // that is the first thing the screen has to say.
    const wasFacing = s.opponent_index;
    const beaten = this.currentOpponent();

    this._checkOutcome(false);

    const result = { ok: true, card_id: cardId, effect: effect, applied: applied, energy_left: s.energy };
    if (s.opponent_index !== wasFacing) {
      result.bout_won = {
        finished: str(beaten.name, ''),
        next: str(this.currentOpponent().name, ''),
        remaining: s.opponent_count - s.opponent_index,
      };
    }
    return result;
  }

  // Support, then guard, then gaffe, then draw.
  _applyEffect(effect) {
    const s = this.state;
    const applied = { gained: 0, opponent_lost: 0, guard: 0, gaffe: 0, drawn: 0 };

    applied.gained = s.bar.playerGains(int(effect.self_plus, 0));
    // Who those people were: undecided, or argued off the other side.
    applied.gain_split = Object.assign({}, s.bar.last_gain);

    // Arguing the opposition down is an attack, so their guard is the first
    // thing it meets and what it absorbs is spent. Until now this went
    // straight through and their "Guarding" intent did nothing at all.
    //
    // Piercing IGNORES guard rather than spending it, so the pierced amount
    // is lifted off the bank before the attack lands and put back afterwards.
    // Subtracting it for real would let one pierce card strip a guard the
    // card never claimed to remove.
    const oppMinus = int(effect.opp_minus, 0);
    const pierced = Math.min(int((effect.flags || {}).pierce_guard, 0), s.opponent_block);
    s.opponent_block -= pierced;

    const stopped = Math.min(s.opponent_block, oppMinus);
    s.opponent_block -= stopped;
    applied.guard_pierced = pierced;
    applied.guard_stopped = stopped;
    applied.opponent_lost = s.bar.opponentLoses(oppMinus - stopped);

    s.opponent_block += pierced;

    // Guard goes into a bank, so what is reported is what actually fitted.
    const beforeGuard = s.block;
    s.block = Math.min(s.block + int(effect.guard, 0), s.guard_cap);
    applied.guard = s.block - beforeGuard;

    // The gaffe meter never goes below zero, so an apology on a clean record
    // is wasted rather than banked.
    //
    // A stage can make a slip cost double — the media ambush does. Only a
    // gaffe GAINED is multiplied: an apology should not be worth less in a
    // hard room than an easy one.
    let gaffe = int(effect.gaffe, 0);
    if (gaffe > 0) gaffe *= this._gaffeMultiplier();
    const beforeGaffe = s.gaffe;
    s.gaffe = Math.max(s.gaffe + gaffe, 0);
    applied.gaffe = s.gaffe - beforeGaffe;

    applied.drawn = this._draw(int(effect.draw, 0));
    return applied;
  }

  // Ending a turn without having played anything is how you pass, and
  // passing costs you: see _passPenalty() for what it costs and why.
  endTurn() {
    const s = this.state;
    if (s.isOver()) return { ok: false, reason: 'the battle is already over' };

    const passed = s.cards_played_this_turn === 0;
    if (passed) this._passPenalty();

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

    // Guard is NOT cleared here. It is a bank now: it stays until something
    // takes it, so a quiet turn spent guarding is still worth something.

    // A question left unanswered when the turn ends is a question declined.
    // Passing is not the only way to duck one now that a turn can hold more
    // cards than it holds questions.
    if (this._questions.length > 0 && !passed) {
      const unanswered = this._questionsPerTurn() - s.questions_answered_this_turn;
      for (let i = 0; i < Math.max(unanswered, 0); i++) {
        if (!this.currentQuestion()) break;
        this._declineQuestion();
      }
    }

    // A lobbyist's interest cools while you talk, whatever you said.
    if (this._affinityDecay() > 0 && s.bar !== null && !s.isOver()) {
      s.bar.playerLoses(this._affinityDecay());
    }

    s.next_card_bonus = 0;
    s.next_card_discount = 0;
    s.next_intent_revealed = false;
    s.cards_played_this_turn = 0;
    s.questions_answered_this_turn = 0;

    const wasFacing = s.opponent_index;
    const beaten = this.currentOpponent();
    this._checkOutcome(true);
    let boutWon = {};
    if (s.opponent_index !== wasFacing) {
      boutWon = {
        finished: str(beaten.name, ''),
        next: str(this.currentOpponent().name, ''),
        remaining: s.opponent_count - s.opponent_index,
      };
    }

    if (!s.isOver()) {
      s.turn += 1;
      if (s.energy_mode !== 'pool') {
        s.energy = Math.max(s.energy_per_turn - (passed ? this._passCost() : 0), 0);
      }
      if (s.draw_mode !== 'none') this._drawUpToHandSize();
    }

    return { ok: true, passed: passed, intent: intent, opponent: opponentResult,
      bout_won: boutWon, turn: s.turn, outcome: s.outcome };
  }

  // What saying nothing costs. One energy, from rules.json.
  _passCost() { return int(this._rules.pass_energy_penalty, 1); }

  // How many questions this room asks in a turn.
  //
  // A press conference asks one, a policy study session two. Before this
  // every CARD answered a question, so three energy could burn through three
  // reporters in a single turn.
  _questionsPerTurn() { return Math.max(int(this._stage.questions_per_turn, 1), 1); }

  // What a slip costs here. Doubled in a media ambush.
  _gaffeMultiplier() { return Math.max(int(this._stage.gaffe_multiplier, 1), 1); }

  // How much of a lobbyist's interest cools each turn, whatever you say.
  _affinityDecay() { return Math.max(int(this._stage.affinity_decay, 0), 0); }

  // What this card costs right now, after any discount a card left behind.
  //
  // Public because the hand has to show it: a card whose face says 2 and
  // then charges 1 is a screen the player stops trusting, and so is the
  // reverse. Floors at zero — a card cannot pay you to play it.
  cardCost(card) {
    return Math.max(int(card.cost, 0) - this.state.next_card_discount, 0);
  }

  // Where the player stands, for the effects that care.
  //
  // Read fresh each time rather than cached: "if you trail the opponent" has
  // to mean the moment the card is played, not the moment the hand was dealt.
  _standingContext() {
    const s = this.state;
    return {
      self_gaffe: s.gaffe,
      player_support: s.bar === null ? 0 : s.bar.player,
      opponent_support: s.bar === null ? 0 : s.bar.opponent,
    };
  }

  // The price of a turn spent saying nothing.
  //
  // Standing up and declining to argue is a real choice — sometimes the
  // right one — but it should never be the free one, or the best play in a
  // tight spot would be to keep quiet and let the clock run.
  //
  // THE ENERGY normally comes off next turn's allowance, applied where the
  // turn refills. A pool stage is never refilled, so there is nothing there
  // to dock and it comes off what is left of the pool straight away — a
  // permanent cut rather than a lost turn, which is the only version that
  // means anything in a caucus.
  //
  // THE QUESTION: in a press conference the round IS the question in front
  // of you, so passing is how you decline it. There is no other way to duck
  // one, because every card you could play would answer it.
  _passPenalty() {
    const s = this.state;
    if (s.energy_mode === 'pool') {
      s.energy = Math.max(s.energy - this._passCost(), 0);
    }
    if (this._questions.length > 0 && this.currentQuestion()) {
      this._declineQuestion();
    }
  }

  // Ducking the question in front of you.
  //
  // Energy is close to worthless in a press conference — six cards for five
  // questions — so the ordinary pass cost meant a player could decline every
  // awkward question and finish with the tone untouched and a clean record.
  // A playtest found exactly that.
  //
  // So silence has its own price: the room cools, and the organisation that
  // asked is not pleased, which is felt later because standing carries
  // between levels.
  _declineQuestion() {
    const s = this.state;
    const cost = int(this._stage.decline_tone_cost, 3);
    if (cost > 0 && s.bar) s.bar.playerLoses(cost);

    s.declined_questions += 1;
    s.question_index += 1;

    // In an ambush there is nowhere to go. Ducking one question ends it,
    // which is the whole character of the stage.
    if (bool(this._stage.decline_ends_stage, false)) {
      this._finish('loss', 'You walked away from the question. That is the story now.');
    }
  }

  _resolveIntent(intent) {
    const s = this.state;
    const value = int(intent.value, 0);

    switch (str(intent.verb, 'none')) {
      case 'attack': {
        // The player's guard is the first thing taken, and what it absorbs
        // is spent — the bank being drawn down, not a shield that happened
        // to be up at the right moment.
        const absorbed = Math.min(s.block, value);
        const through = Math.max(value - s.block, 0);
        s.block -= absorbed;
        return { verb: 'attack', absorbed: absorbed, damage: s.bar.playerLoses(through) };
      }
      case 'gain':
        {
          const gained = s.bar.opponentGains(value);
          return { verb: 'gain', gained: gained,
            gain_split: Object.assign({}, s.bar.last_gain) };
        }
      case 'block': {
        const before = s.opponent_block;
        s.opponent_block = Math.min(s.opponent_block + value, s.guard_cap);
        return { verb: 'block', guard: s.opponent_block - before };
      }
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
        return this._finish('win', this._conferenceClosing());
      }
      // The discard pile is not counted: in a conference that never draws, a
      // card once played is gone for good.
      let canStillAnswer = s.hand.length > 0;
      if (s.draw_mode !== 'none') canStillAnswer = canStillAnswer || s.deck.length > 0;
      if (!canStillAnswer) {
        return this._finish('win', this._conferenceClosing(true));
      }
    }

    // Three stages have no threshold to cross: a survival stage is staying
    // alive, a scored stage has no line at all, and a press conference runs
    // until the reporters are finished.
    const hasThreshold = s.bar.model !== SURVIVAL
      && s.win_mode !== 'score'
      && this._questions.length === 0;

    if (hasThreshold && s.bar.playerHasWon()) {
      // Where a stage lines several people up, the threshold is what it
      // takes to finish THE PERSON IN FRONT OF YOU, not the stage. In a
      // committee the next member is waiting; on the floor the next debater
      // rises and the house divides again.
      if (this._sequenceMode !== 'single' && this.hasMoreOpponents()) {
        return this._advanceToNextOpponent();
      }
      return this._finish('win', this._victoryReason());
    }

    // On the floor, arguing a debater's seats down to nothing ends them too.
    // Running out of opponents wins it even short of the threshold.
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
      // In the units the stage is read in: a caucus counted as a share of
      // the room should not close on a headcount.
      const closing = this._stage.bar_as_percent
        ? s.playerScore() + '% of the room'
        : s.playerScore() + ' support';
      return this._finish('win', 'The caucus closed with ' + closing + '.');
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

  // In a committee this is a fresh argument. On the floor it is a fresh vote
  // but not a fresh start: the house divides again on the new debater, so the
  // seat count goes back to where the stage opened — but your gaffes, your
  // hand, your deck and the clock all follow you in.
  _advanceToNextOpponent() {
    const s = this.state;
    s.opponent_index += 1;
    this._opponent = this._opponents[s.opponent_index];
    this._armIntents();

    if (this._sequenceMode === 'reset') {
      this._resetForNewBout();
    } else if (this._sequenceMode === 'stream') {
      // A town hall: the clock and your record carry across the queue, but
      // each new face is a fresh three energy. Neither of the other two
      // modes does that — "reset" would wipe the gaffes you have earned, and
      // "continuous" would leave you empty-handed in front of somebody who
      // has not heard you speak yet.
      s.energy = s.energy_per_turn;
      s.energy_max = s.energy_per_turn;
      if (s.bar) {
        s.bar = this._buildBar(
          int(this._stage.player_start, 0),
          int(this._stage.opp_start, 0));
      }
    } else if (s.bar) {
      s.bar = this._buildBar(
        int(this._stage.player_start, 0),
        int(this._stage.opp_start, 0));
    }
  }

  _resetForNewBout() {
    const s = this.state;
    s.gaffe = 0;
    s.block = 0;
    s.opponent_block = 0;
    s.next_card_bonus = 0;
    s.next_card_discount = 0;
    s.next_intent_revealed = false;
    s.cards_played_this_turn = 0;
    s.turn = 1;

    s.energy = s.energy_max;
    if (s.energy_mode !== 'pool') {
      s.energy = s.energy_per_turn;
      s.energy_max = s.energy_per_turn;
    }

    s.bar = this._buildBar(
      int(this._stage.player_start, 0),
      int(this._stage.opp_start, 0));

    // A clean deck, so the last argument's spent cards are not a handicap.
    s.deck = s.deck.concat(s.hand, s.discard);
    s.hand = [];
    s.discard = [];
    shuffle(s.deck, this._rng);
    this._drawUpToHandSize();
  }

  _victoryReason() {
    if (this._sequenceMode !== 'single' && this.state.opponent_count > 1) {
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

  // How a press conference ends. Never won or lost — it closes, and what it
  // produced is the tone and the organisations pleased. The count of
  // unanswered questions is recorded rather than judged.
  _conferenceClosing(ranOutOfCards) {
    // Named from the stage, because a policy study session and a lobbyist
    // meeting both run on questions and neither of them is a press
    // conference. It said so anyway until a playtest read it.
    const what = str(this._stage.name_en, '').trim();
    const lines = [(what || 'It') + ' concludes.'];
    if (ranOutOfCards) {
      lines.push('The questions ran on, but there was nothing left to say.');
    }
    const declined = this.state.declined_questions;
    if (declined === 1) lines.push('One question went unanswered.');
    else if (declined > 1) lines.push(declined + ' questions went unanswered.');
    return lines.join(' ');
  }

  // What a card will actually do in this room, before it is played.
  //
  // The printed number is not what happens: affinity multiplies the two
  // support numbers, and in some rooms a number does nothing at all. A
  // playtest reported this as the card not working, which is what happens
  // when a screen shows a promise the rules do not keep.
  preview(card) {
    const effect = resolveCard(card, Object.assign({
      affinity: this.affinityFor(card),
      segment_share: segmentShare(card, this._stage),
      kanban: int(this._meta.Reputation, 50),
      opponent_gaffe: this.state.opponent_gaffe,
      next_card_bonus: this.state.next_card_bonus,
    }, this._standingContext()));

    const reduceCounts = !this.state.bar || !this.state.bar.reduceDoesNothing();
    const guardCounts = this._intents !== null;

    effect.opp_minus_counts = reduceCounts;
    effect.guard_counts = guardCounts;
    // A gaffe counts. Leaving it out produced a card reading "Gaffe +1.
    // Nothing this card does counts in this room." — a sentence that
    // contradicts itself. Doing something bad is still doing something.
    effect.does_nothing = (
      int(effect.self_plus, 0) === 0
      && int(effect.draw, 0) === 0
      && int(effect.gaffe, 0) === 0
      && (int(effect.opp_minus, 0) === 0 || !reduceCounts)
      && (int(effect.guard, 0) === 0 || !guardCounts));

    // Every card answers the question in front of you, whatever else it
    // does — so a card whose numbers are all inert here still spends one.
    effect.answers_question = !!this.currentQuestion();

    return effect;
  }

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

// What a stage pays flat for being won, straight off the stage row.
//
// This existed in the Godot engine from milestone 1 and had no caller, and
// no JS counterpart at all — so every stage in the game was won for nothing.
function applyWinDeltas(meta, stage, sanbanRows) {
  const updated = Object.assign({}, meta);
  const applied = {};

  for (const key of Object.keys(WIN_DELTA_KEYS)) {
    const delta = int(stage[key], 0);
    if (delta === 0) continue;

    const name = WIN_DELTA_KEYS[key];
    const variable = findVariable(sanbanRows, name);
    const before = int(updated[name], int(variable.start, 0));
    const after = clampMeta(before + delta, variable);
    updated[name] = after;
    applied[name] = after - before;
  }

  return { meta: updated, applied: applied };
}

// The workbook's column names, and what the player calls them.
const WIN_DELTA_KEYS = {
  win_delta_jiban: 'Constituency support',
  win_delta_kanban: 'Reputation',
  win_delta_kaban: 'Funds',
  win_delta_party_support: 'Party support',
};

// The meta-variables a stage pays out on a win. Zero is left out rather than
// reported as "+0": a variable this stage does not touch is not news.
function winRewards(stage) {
  const rewards = {};
  for (const key of Object.keys(WIN_DELTA_KEYS)) {
    const delta = int(stage[key], 0);
    if (delta !== 0) rewards[WIN_DELTA_KEYS[key]] = delta;
  }
  return rewards;
}

// True where a stage's rewards have not been decided yet. Every playtest
// stage is in this state on purpose, waiting on Cameron's numbers — the
// screens must say "not set yet" rather than showing four zeroes.
function rewardsAreUnset(stage) {
  if (Object.keys(winRewards(stage)).length > 0) return false;
  if (int(stage.xp_reward, 0) !== 0) return false;
  return !stage.tone_effects;
}

// What a stage produces that is not a flat reward — described, not forecast.
// A press conference's worth depends on the tone it closes on, so a number
// here would be a guess presented as a promise.
function variableRewards(stage) {
  const lines = [];
  const effects = stage.tone_effects || {};
  const baseline = int(effects.baseline, 50);

  const perVariable = effects.meta || {};
  for (const name of Object.keys(perVariable)) {
    const per = int(perVariable[name], 0);
    if (per > 0) {
      lines.push(name + ', by how far above ' + baseline + ' you finish (1 per ' + per + ')');
    }
  }

  const perSupport = int(effects.support_per_points, 0);
  if (perSupport > 0) {
    lines.push('A head start later in the level, 1 per ' + perSupport + ' above ' + baseline);
  }

  if (Array.isArray(stage.questions) && stage.questions.length > 0) {
    lines.push('Standing with whichever organisations your answers please');
  }

  return lines;
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
// Ledger — what a thing costs, and whether you may have it
// ---------------------------------------------------------------------------
// Ported from scripts/rules/Ledger.gd. One place for every kind of purchase,
// so a screen can never offer what the rules would refuse and the refusal
// the player reads is the rules' own words.

// The tier a player owns from the first moment, named once.
//
// It was "Starter" until the 2026-09-21 card slate renamed the tiers to 0-3.
// Several places checked that string; now they ask here instead, so the next
// rename is one line. Mirrors Ledger.OPENING_TIER.
const OPENING_TIER = '0';

function cardCost(card) { return int(card.xp_to_unlock, 0); }

function cardRefusal(card, owned, xp) {
  const cardId = str(card.card_id, '');
  if (!cardId) return 'This card has no ID.';
  if (owned.includes(cardId)) return 'Already yours.';

  const cost = cardCost(card);
  if (cost <= 0) return '';
  if (xp < cost) return (cost - xp) + ' XP short.';
  return '';
}

function modifierCost(modifier) {
  const cost = modifier.kaban_cost;
  return (cost === null || cost === undefined) ? 0 : Math.trunc(cost);
}

function isForSale(modifier) {
  if (modifierCost(modifier) <= 0) return false;
  const audience = str(modifier.available_to, 'Both');
  return audience === 'Both' || audience === 'Player';
}

function standingNeeded(modifier, settings) {
  const perModifier = settings.required_standing_by_modifier || {};
  const modId = str(modifier.mod_id, '');
  if (modId in perModifier) return int(perModifier[modId], 60);
  return int(settings.required_standing, 60);
}

// The party-support pair name a meta-variable in the source_booster column
// rather than an organisation, so anything that is not a real booster ID is
// treated as "nobody backs this".
function backingBooster(modifier, boosterIds) {
  const source = str(modifier.source_booster, '');
  return boosterIds.includes(source) ? source : '';
}

function modifierRefusal(modifier, owned, funds, standing, settings, boosterIds) {
  const modId = str(modifier.mod_id, '');
  if (!modId) return 'This modifier has no ID.';
  if (owned.includes(modId)) return 'Already yours.';
  if (!isForSale(modifier)) return 'Not for sale.';

  // Standing first: being told the price of something you are not allowed
  // to buy is worse than being told why you cannot buy it.
  const booster = backingBooster(modifier, boosterIds);
  if (booster) {
    const needed = standingNeeded(modifier, settings);
    const have = int(standing[booster], 0);
    if (have < needed) return 'Standing ' + have + ' of ' + needed + ' needed.';
  }

  const cost = modifierCost(modifier);
  if (funds < cost) return (cost - funds) + ' short.';
  return '';
}

function deckSize(balance) { return Math.max(int(balance.starter_deck_size, 12), 1); }

// Exact rather than "at least": with no upgrades and a growing card set,
// the only thing making an unlock a decision is having to leave something out.
function deckRefusal(deck, owned, balance) {
  const wanted = deckSize(balance);

  for (const cardId of deck) {
    if (!owned.includes(cardId)) return cardId + ' is not yours.';
  }
  const seen = {};
  for (const cardId of deck) {
    if (seen[cardId]) return cardId + ' is in twice.';
    seen[cardId] = true;
  }
  if (deck.length < wanted) return (wanted - deck.length) + ' more to choose.';
  if (deck.length > wanted) return (deck.length - wanted) + ' too many.';
  return '';
}

// Every opening-tier card first — those are yours from the beginning and
// there is one per suit. The 2026-09-21 slate has six of them against a deck
// of twelve, so the rest is filled a suit at a time from the next tiers up,
// lowest card ID first.
//
// That fill is a SUGGESTION, not a design decision: it keeps all six suits
// represented so a first battle is playable, and the deck screen exists
// precisely so the player changes it.
function openingDeck(cards, balance) {
  const wanted = deckSize(balance);
  const deck = cards
    .filter(c => str(c.tier, '') === OPENING_TIER)
    .map(c => str(c.card_id, ''));

  if (deck.length > wanted) return deck.slice(0, wanted);

  // Round-robin by suit, so the fill cannot hand out six cards of one
  // element and none of another.
  const suits = [];
  for (const card of cards) {
    const suit = str(card.suit, '');
    if (suit && !suits.includes(suit)) suits.push(suit);
  }

  while (deck.length < wanted) {
    let added = false;
    for (const suit of suits) {
      if (deck.length >= wanted) break;
      for (const card of cards) {
        const cardId = str(card.card_id, '');
        if (str(card.suit, '') !== suit || deck.includes(cardId)) continue;
        deck.push(cardId);
        added = true;
        break;
      }
    }
    if (!added) break;   // every card there is, is already in
  }

  return deck;
}

// ---------------------------------------------------------------------------
// ModifierEffects — what an organisation's backing actually does
// ---------------------------------------------------------------------------
// Ported from scripts/rules/ModifierEffects.gd. The `effect` column is prose
// for a designer and CLAUDE.md forbids parsing it, so the machine-readable
// half is a key plus the magnitude the workbook already carries.

const AT_BATTLE_START = ['player_start_support', 'starting_gaffe'];
const AFTER_STAGE_WIN = ['kaban_per_stage_win'];
const NOT_YET_BUILT = [
  'opp_start_support_on_tag', 'kaban_per_module', 'party_support_per_module',
  'jiban_per_module_win', 'negates_cold_shoulder', 'start_lean_in_committee',
  'halve_jiban_losses',
];
// Wired and correct, but nothing yet produces the situation it answers: the
// gaffe meter always opens at zero, so taking a point off it takes nothing.
const INERT_TODAY = ['starting_gaffe'];

function effectKeyFor(modifier, bridge) {
  const key = str(modifier.effect_key, '').trim();
  if (key) return key;
  return str((bridge || {})[str(modifier.mod_id, '')], '');
}

function magnitudeOf(modifier) {
  const value = modifier.magnitude;
  return (value === null || value === undefined) ? 0 : Math.round(Number(value));
}

function effectIsImplemented(modifier, bridge) {
  const key = effectKeyFor(modifier, bridge);
  if (INERT_TODAY.includes(key)) return false;
  return AT_BATTLE_START.includes(key) || AFTER_STAGE_WIN.includes(key);
}

function effectIsInertToday(modifier, bridge) {
  return INERT_TODAY.includes(effectKeyFor(modifier, bridge));
}

function effectIsKnownButUnbuilt(modifier, bridge) {
  return NOT_YET_BUILT.includes(effectKeyFor(modifier, bridge));
}

// The effect column says "Magnitude" where a number belongs, because it was
// written for a designer. Putting that on a shop screen asks the player to
// read a spreadsheet.
function describeEffect(modifier, bridge) {
  const magnitude = magnitudeOf(modifier);
  switch (effectKeyFor(modifier, bridge)) {
    case 'player_start_support': return 'Start ' + magnitude + ' ahead.';
    case 'starting_gaffe': return 'Start with ' + magnitude + ' less on the gaffe meter.';
    case 'kaban_per_stage_win': return '+' + magnitude + ' funds for every stage won.';
  }
  const prose = str(modifier.effect, '').trim();
  if (!prose) return '';
  return prose.split('Magnitude').join(String(magnitude));
}

function battleStartBonus(active, bridge) {
  const bonus = { start_support: 0, starting_gaffe: 0 };
  for (const modifier of active) {
    const magnitude = magnitudeOf(modifier);
    switch (effectKeyFor(modifier, bridge)) {
      case 'player_start_support': bonus.start_support += magnitude; break;
      // The column reads "−Magnitude starting gaffe meter": the sign is in
      // the prose, so the number comes off here.
      case 'starting_gaffe': bonus.starting_gaffe -= magnitude; break;
    }
  }
  return bonus;
}

function stageWinFunds(owned, bridge) {
  let funds = 0;
  for (const modifier of owned) {
    if (effectKeyFor(modifier, bridge) === 'kaban_per_stage_win') {
      funds += magnitudeOf(modifier);
    }
  }
  return funds;
}

// Which modifiers fire given the room, ported from MetaRules.active_modifiers.
function activeModifiers(rows, stage, availableTo) {
  const active = [];
  const mix = stage.segment_mix || {};
  for (const modifier of rows) {
    const audience = modifier.available_to;
    if (audience !== null && audience !== undefined
        && audience !== 'Both' && audience !== (availableTo || 'Player')) continue;

    const minimum = modifier.trigger_min_pct;
    if (minimum === null || minimum === undefined) continue;
    const segmentId = modifier.trigger_segment_id;
    if (segmentId === null || segmentId === undefined) continue;

    if (Number(mix[segmentId] || 0) >= Number(minimum)) active.push(modifier);
  }
  return active;
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
  return data.cards.filter(c => str(c.tier, '') === OPENING_TIER).map(c => c.card_id);
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

// Fills in who is in the room, where a stage does not say.
//
// Every stage in the workbook carries a segment_mix — how much of the
// audience is Press, Loyalists, Constituents, Donors, Bureaucrats — and the
// hand-written playtest stages carry none, so every card aimed at a
// particular audience reads that audience as zero per cent of the room.
//
// Rather than invent percentages, a playtest stage borrows the mix of the
// canon stage it already names in affinity_stage_id. A stage that declares
// its own keeps it.
function withAudience(data, stage) {
  if (stage.segment_mix) return stage;

  const modelledOn = str(stage.affinity_stage_id, '');
  if (!modelledOn) return stage;

  const canon = (data.stages || []).find(row => row.stage_id === modelledOn);
  if (!canon || !canon.segment_mix) return stage;

  return Object.assign({}, stage, { segment_mix: canon.segment_mix });
}

// `owned` is the run's state: { deck, modifiers }. Absent in a standalone
// battle, which then deals the opening twelve and no backing.
function forPlaytestStage(data, stage, buffs, meta, seed, owned) {
  buffs = buffs || {};
  owned = owned || {};
  const opponents = stage.opponents || [];
  const filled = withAudience(data, stage);
  const backing = backingBonus(data, filled, owned.modifiers || []);

  return {
    stage: filled,
    opponent: opponents.length > 0 ? opponents[0] : {},
    opponents: opponents,
    cards: cardTable(data),
    affinity: affinityTable(data),
    rules: data.rules,
    meta: meta || startingMeta(data),
    deck: (owned.deck && owned.deck.length > 0) ? owned.deck.slice() : starterDeck(data),
    // A good caucus earlier in the level starts this stage ahead, and so
    // does an organisation whose backing you have bought.
    start_adjustment: int(buffs.support_bonus, 0) + backing.start_support,
    starting_gaffe: backing.starting_gaffe,
    seed: seed,
  };
}

// What the organisations backing you are worth in this room. Backing only
// counts where the audience it cares about is actually here: a friendly beat
// reporter does nothing in a caucus with no press in it.
function backingBonus(data, stage, ownedIds) {
  if (!ownedIds || ownedIds.length === 0) {
    return { start_support: 0, starting_gaffe: 0 };
  }
  const owned = data.modifiers.filter(m => ownedIds.includes(str(m.mod_id, '')));
  const active = activeModifiers(owned, stage, 'Player');
  return battleStartBonus(active, data.modifier_effects || {});
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
