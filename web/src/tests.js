// The engine's own assertions, ported from tests/.
//
// WHY THESE RUN IN THE PAGE
// The rules now exist twice: in GDScript for the game that ships, and in
// JavaScript so the level can be played in a browser. Two copies of a rule
// drift apart quietly. These run on load and print their result on screen,
// so drift shows up as a failing count rather than as a game that plays
// slightly differently from the real one.
//
// Ported from tests/test_battle_engine.gd, test_bar_model.gd,
// test_card_resolver.gd, test_intent_runner.gd, test_level_runner.gd and
// test_real_battle.gd — the assertions about rules, not the ones about
// Godot-specific plumbing.

'use strict';

function runRuleChecks(data) {
  const failures = [];
  let count = 0;

  function check(name, fn) {
    count += 1;
    try {
      fn();
    } catch (err) {
      failures.push(name + ' — ' + err.message);
    }
  }

  function eq(actual, expected, note) {
    if (actual !== expected) {
      throw new Error((note ? note + ': ' : '') + 'expected ' + expected + ', got ' + actual);
    }
  }
  function ok(value, note) {
    if (!value) throw new Error(note || 'expected true');
  }

  // --- fixtures, matching tests/fixtures.gd ---------------------------------

  function card(overrides) {
    return Object.assign({
      card_id: 'TEST01', name_en: 'Test Card', suit: 'Earnest', type: 'Gain',
      cost: 1, self_plus: 0, opp_minus: 0, guard: 0, draw: 0, gaffe: 0,
      target_segment: 'Any', target_segment_id: null,
      special: null, special_value: null,
    }, overrides || {});
  }

  function stage(overrides) {
    return Object.assign({
      stage_id: 'ST02', name_en: 'Floor Debate', bar_unit: 'Seats',
      bar_max: 101, win_threshold: 51, turn_limit: 8, energy_per_turn: 3,
      hand_size: 5, gaffe_limit: 5, player_start: 40, opp_start: 40,
      segment_mix: {},
    }, overrides || {});
  }

  function config(overrides) {
    const cards = {
      GAIN3: card({ card_id: 'GAIN3', self_plus: 3, cost: 1 }),
      ATTACK3: card({ card_id: 'ATTACK3', opp_minus: 3, cost: 1, suit: 'Data Driven' }),
      GUARD5: card({ card_id: 'GUARD5', guard: 5, cost: 1, suit: 'Duplicitous' }),
      GAFFE2: card({ card_id: 'GAFFE2', self_plus: 2, gaffe: 2, cost: 1 }),
      DRAW2: card({ card_id: 'DRAW2', draw: 2, cost: 1 }),
      FREE: card({ card_id: 'FREE', cost: 0, self_plus: 1 }),
    };
    return Object.assign({
      stage: stage(),
      opponent: { opp_id: 'TEST', name: 'Test Opponent', intent_pattern: [['attack', 5]] },
      cards: cards,
      affinity: { 'Data Driven': { ST02: 1.1 }, Earnest: { ST02: 1.0 } },
      rules: {
        default_intent_pattern: [['attack', 6], ['gain', 4], ['block', 5]],
        turn_limit_outcome: 'loss',
        opponent_can_win_by_threshold: false,
        opponent_engine: 'intent_patterns',
        discard_hand_end_of_turn: true,
      },
      meta: { Reputation: 50 },
      deck: ['GAIN3', 'GAIN3', 'ATTACK3', 'GUARD5', 'GAFFE2', 'DRAW2'],
      seed: 12345,
    }, overrides || {});
  }

  function started(overrides) {
    const engine = new BattleEngine();
    if (!engine.setup(config(overrides))) {
      throw new Error('setup failed: ' + engine.setupProblems.join('; '));
    }
    return engine;
  }

  function intoHand(engine, cardId) {
    if (!engine.state.hand.includes(cardId)) engine.state.hand.push(cardId);
  }

  // --- the card arithmetic --------------------------------------------------

  check('halves round up', () => {
    eq(roundHalfUp(2.5), 3);
    eq(roundHalfUp(2.4), 2);
    eq(roundHalfUp(-2.5), -2, 'towards positive, not away from zero');
  });

  check('affinity multiplies the support numbers', () => {
    const effect = resolveCard(card({ self_plus: 5, opp_minus: 4 }), { affinity: 1.3 });
    eq(effect.self_plus, 7, '5 x 1.3 = 6.5, rounded up');
    eq(effect.opp_minus, 5, '4 x 1.3 = 5.2');
  });

  check('affinity leaves guard, draw and gaffe alone', () => {
    const effect = resolveCard(card({ guard: 5, draw: 2, gaffe: 1 }), { affinity: 1.3 });
    eq(effect.guard, 5);
    eq(effect.draw, 2);
    eq(effect.gaffe, 1);
  });

  check('an untargeted card counts the whole room', () => {
    eq(segmentShare(card(), stage()), 1.0);
  });

  check('a targeted card reads the stage mix', () => {
    const s = stage({ segment_mix: { SG01: 0.4 } });
    eq(segmentShare(card({ target_segment_id: 'SG01' }), s), 0.4);
  });

  // --- the bar --------------------------------------------------------------

  // A fixed answer instead of a random one, so a test can say exactly what a
  // stubborn vote costs and then assert exact numbers. The roller returns a
  // percentile: 0-59 is a one-point vote, 60-89 two, 90-99 three.
  const CHEAP = 0, AWKWARD = 60, STUBBORN = 90;
  const always = p => () => p;
  const floorDebate = (p = CHEAP) => new BarModel(SHARED_POOL, 101, 51, 40, 40, always(p));

  check('a shared pool always adds up', () => {
    const bar = floorDebate();
    eq(bar.undecided, 21);
    bar.playerGains(10); ok(bar.totalsBalance(), 'after a gain');
    bar.opponentLoses(5); ok(bar.totalsBalance(), 'after a refutation');
    bar.playerLoses(30); ok(bar.totalsBalance(), 'after an attack');
    bar.opponentGains(12); ok(bar.totalsBalance(), 'after the opponent gains');
  });

  check('the player takes from the undecided before the opponent', () => {
    const bar = floorDebate();
    bar.playerGains(21);
    eq(bar.undecided, 0);
    eq(bar.opponent, 40, 'the opponent has not been touched yet');
    bar.playerGains(5);
    eq(bar.opponent, 35, 'now it comes off them');
  });

  check("the opponent's losses go back to undecided", () => {
    const bar = floorDebate();
    bar.opponentLoses(10);
    eq(bar.opponent, 30);
    eq(bar.undecided, 31, 'not convinced of the other case, just not theirs');
    eq(bar.player, 40);
  });

  check('a single bar has no opponent side', () => {
    const bar = new BarModel(SINGLE, 100, 55, 45, 45);
    eq(bar.opponent, 0);
    eq(bar.opponentGains(10), 0, 'there is nothing to raise');
  });

  check('a refutation does nothing on a single bar', () => {
    // There is nobody in a press conference whose support you are reducing.
    // It used to convert into tone, making a +3/-3 card worth +6 there.
    const bar = new BarModel(SINGLE, 100, 55, 45, 0);
    eq(bar.opponentLoses(3), 0, 'nothing moved');
    eq(bar.player, 45, 'and the tone is where it was');
  });

  check('a refutation does nothing in a scored stage', () => {
    const bar = floorDebate();
    bar.scoredOnly = true;
    eq(bar.opponentLoses(5), 0);
    eq(bar.opponent, 40, 'their supporters stayed where they were');
    ok(bar.totalsBalance());
  });

  check('a refutation still works where the opponent is the point', () => {
    const bar = floorDebate();
    eq(bar.opponentLoses(5), 5);
    eq(bar.opponent, 35);
  });

  check('a stage with questions is a press tone bar', () => {
    eq(BarModel.forStage({ stage_id: 'PT_S2', questions: [{ id: 'Q1' }] }), SINGLE);
    eq(BarModel.forStage({ stage_id: 'PT_S4' }), SHARED_POOL);
    eq(BarModel.forStage({ stage_id: 'ST06' }), SURVIVAL);
  });

  // --- the opponent's pattern -----------------------------------------------

  check('a pattern cycles in order', () => {
    const runner = new IntentRunner([['attack', 6], ['gain', 4]]);
    eq(runner.advance().verb, 'attack');
    eq(runner.advance().verb, 'gain');
    eq(runner.advance().verb, 'attack', 'and round again');
  });

  check('peeking does not use a move up', () => {
    const runner = new IntentRunner([['attack', 6], ['gain', 4]]);
    eq(runner.peek().verb, 'attack');
    eq(runner.peek().verb, 'attack');
    eq(runner.peekAhead().verb, 'gain');
  });

  check('an unknown verb is rejected', () => {
    const runner = new IntentRunner([['filibuster', 3]]);
    ok(!runner.isValid());
    ok(runner.problems()[0].includes('filibuster'));
  });

  // --- ranges, and the zero rule --------------------------------------------
  // Ported from tests/test_intent_runner.gd. Cameron's five patterns,
  // 2026-09-21.

  // A roller that hands back a fixed answer, so a test can say what was
  // rolled; and one that walks a list, to script a sequence of rolls.
  const fixedRoll = (value) => (low, high) => Math.min(Math.max(value, low), high);
  const scriptedRoll = (values) => {
    let i = 0;
    return (low, high) => {
      const value = values[i % values.length];
      i += 1;
      return Math.min(Math.max(value, low), high);
    };
  };

  check('a range is rolled between its ends', () => {
    const move = new IntentRunner([['attack', 1, 6]], fixedRoll(4)).advance();
    eq(move.verb, 'attack');
    eq(move.value, 4);
    eq(move.min, 1, 'and it says what was possible');
    eq(move.max, 6);
  });

  check('a range never lands outside its ends', () => {
    const runner = new IntentRunner([['attack', 2, 5]]);
    for (let i = 0; i < 200; i++) {
      const value = runner.advance().value;
      ok(value >= 2 && value <= 5, 'rolled ' + value);
    }
  });

  check('a fixed move keeps its plain shape', () => {
    // No min or max on a move that has no range: the battle and the screen
    // both read the absence as "this is exactly what happens".
    const move = new IntentRunner([['attack', 6]]).advance();
    eq(move.min, undefined);
    eq(move.value, 6);
  });

  check('the ends are included', () => {
    eq(new IntentRunner([['attack', 3, 7]], fixedRoll(3)).advance().value, 3);
    eq(new IntentRunner([['attack', 3, 7]], fixedRoll(7)).advance().value, 7);
  });

  check('a flat zero move is never taken', () => {
    // Pattern 4: attack 5 / gain 0-2 / block 0. That opponent never guards.
    const runner = new IntentRunner(
      [['attack', 5], ['gain', 0, 2], ['block', 0]], fixedRoll(2));
    const verbs = [];
    for (let i = 0; i < 12; i++) verbs.push(runner.advance().verb);

    ok(!verbs.includes('block'), 'the block is worth nothing, so it never happens');
    ok(verbs.includes('attack'));
    ok(verbs.includes('gain'));
  });

  check('a range that rolls zero gives way to the next move', () => {
    const runner = new IntentRunner(
      [['block', 0, 2], ['attack', 4]], scriptedRoll([0]));
    eq(runner.peek().verb, 'attack', 'the block rolled nothing');
    eq(runner.advance().value, 4);
  });

  check('no move ever comes out at nothing', () => {
    const runner = new IntentRunner([['attack', 0, 6], ['gain', 2, 4], ['block', 1, 3]]);
    for (let i = 0; i < 300; i++) ok(Math.trunc(runner.advance().value) !== 0);
  });

  check('a pattern of nothing but zeros waits rather than hanging', () => {
    const runner = new IntentRunner([['block', 0], ['gain', 0]]);
    eq(runner.advance().verb, 'none');
    ok(!runner.isValid(), 'and the data check refuses it up front');
    ok(runner.problems()[0].includes('never act'));
  });

  check('the skipped moves are used up', () => {
    const runner = new IntentRunner(
      [['attack', 5], ['gain', 1], ['block', 0]], fixedRoll(1));
    eq(runner.advance().verb, 'attack');
    eq(runner.advance().verb, 'gain');
    eq(runner.advance().verb, 'attack', 'the block was stepped over, not queued');
  });

  check('peeking rolls once however often the screen asks', () => {
    let rolls = 0;
    const counting = (low) => { rolls += 1; return low + 1; };
    const runner = new IntentRunner([['attack', 1, 6]], counting);
    for (let i = 0; i < 10; i++) runner.peek();
    eq(rolls, 1, 'ten repaints, one roll');
  });

  check('what was shown is what happens', () => {
    const runner = new IntentRunner(
      [['block', 0, 2], ['attack', 1, 6]], scriptedRoll([0, 5]));
    const shown = runner.peek();
    const done = runner.advance();
    eq(done.verb, shown.verb, 'the verb holds');
    eq(done.value, shown.value, 'and so does the number');
  });

  check('head count is not a lie', () => {
    // C12 reveals the move after next. That move must then be the one that
    // happens, rather than being rolled again when it comes round.
    const runner = new IntentRunner(
      [['attack', 1, 6], ['gain', 1, 6]], scriptedRoll([2, 5, 1]));
    const revealed = runner.peekAhead();
    runner.advance();
    eq(runner.peek().verb, revealed.verb, 'what Head Count showed is what arrives');
    eq(runner.peek().value, revealed.value);
  });

  check('a range is described as a range', () => {
    eq(IntentRunner.describe({ verb: 'attack', value: 4, min: 1, max: 6 }),
      'Attacking · −1 to −6');
    eq(IntentRunner.describe({ verb: 'gain', value: 3, min: 2, max: 4 }),
      'Gaining · +2 to +4');
    eq(IntentRunner.describe({ verb: 'lean_down', value: 2, min: 1, max: 3 }),
      'Pressuring · −1 to −3');
  });

  check('a described range never promises a zero', () => {
    // A "block 0 to 2" cannot actually come out at 0 — a zero would have
    // been stepped over and something else shown instead.
    eq(IntentRunner.describe({ verb: 'block', value: 1, min: 0, max: 2 }),
      'Guarding · 1 to 2');
    eq(IntentRunner.describe({ verb: 'gain', value: 1, min: 0, max: 1 }),
      'Gaining · +1', 'a range with one value left reads as one number');
  });

  check('every pattern in the data can be played', () => {
    let checked = 0;

    for (const level of data.levels) {
      for (const stage of level.stages) {
        for (const opponent of (stage.opponents || [])) {
          ok(opponent.intent_pattern !== undefined,
            (opponent.name || opponent.opp_id) + ' has no pattern');
          const runner = new IntentRunner(opponent.intent_pattern);
          ok(runner.isValid(),
            (opponent.name || opponent.opp_id) + ': ' + runner.problems().join(', '));
          checked += 1;
        }
      }
    }

    for (const oppId of Object.keys(data.intent_patterns || {})) {
      const runner = new IntentRunner(data.intent_patterns[oppId]);
      ok(runner.isValid(), oppId + ': ' + runner.problems().join(', '));
      checked += 1;
    }

    ok(checked > 20, 'every opponent in every level, plus the nine MPs');
  });

  // --- playing a battle -----------------------------------------------------

  check('a battle starts with a full hand and full energy', () => {
    const engine = started();
    eq(engine.state.hand.length, 5);
    eq(engine.state.energy, 3);
    eq(engine.state.turn, 1);
  });

  check('playing a card costs energy and moves the bar', () => {
    const engine = started();
    intoHand(engine, 'GAIN3');
    ok(engine.playCard('GAIN3').ok);
    eq(engine.state.energy, 2);
    eq(engine.state.bar.player, 43);
    ok(engine.state.discard.includes('GAIN3'), 'the card went to the discard pile');
  });

  check('a card cannot be played without the energy for it', () => {
    const engine = started();
    intoHand(engine, 'GAIN3');
    engine.state.energy = 0;
    ok(!engine.playCard('GAIN3').ok);
    eq(engine.state.bar.player, 40, 'nothing happened');
  });

  check('affinity is applied when a card is played', () => {
    // ATTACK3 is Data Driven, worth 1.1 on the floor: 3 x 1.1 = 3.3 -> 3.
    const engine = started();
    intoHand(engine, 'ATTACK3');
    engine.playCard('ATTACK3');
    eq(engine.state.bar.opponent, 37);
    eq(engine.state.bar.undecided, 24, 'the three went back to undecided');
  });

  check('block absorbs an attack', () => {
    const engine = started();
    intoHand(engine, 'GUARD5');
    engine.playCard('GUARD5');
    eq(engine.state.block, 5);
    eq(engine.endTurn().opponent.damage, 0, 'fully absorbed');
    eq(engine.state.bar.player, 40);
  });

  check('an attack bigger than the block gets partly through', () => {
    const engine = started({ opponent: { opp_id: 'T', name: 'T', intent_pattern: [['attack', 8]] } });
    intoHand(engine, 'GUARD5');
    engine.playCard('GUARD5');
    const turn = engine.endTurn();
    eq(turn.opponent.absorbed, 5);
    eq(turn.opponent.damage, 3);
  });

  check('guard is spent by what it stops, not by the clock', () => {
    // It used to be wiped at the end of every turn whether or not it had
    // been needed. Now only an attack takes it: here their 5 takes all 5.
    const engine = started();
    intoHand(engine, 'GUARD5');
    engine.playCard('GUARD5');
    engine.endTurn();
    eq(engine.state.block, 0, 'their attack of 5 took the whole bank');
  });

  check('guard is still there next turn when nothing takes it', () => {
    const engine = started({
      opponent: { opp_id: 'T', name: 'T', intent_pattern: [['block', 1]] },
    });
    intoHand(engine, 'GUARD5');
    engine.playCard('GUARD5');
    engine.endTurn();
    eq(engine.state.block, 5, 'a quiet turn spent guarding is not wasted');
  });

  check('guard stacks up to the cap', () => {
    const engine = started();
    engine.state.guard_cap = 5;
    intoHand(engine, 'GUARD5');
    eq(engine.playCard('GUARD5').applied.guard, 5);
    intoHand(engine, 'GUARD5');
    eq(engine.playCard('GUARD5').applied.guard, 0, 'it reports what fitted');
    eq(engine.state.block, 5, 'held at the cap');
  });

  check('an attack spends the guard it meets', () => {
    const engine = started({
      opponent: { opp_id: 'T', name: 'T', intent_pattern: [['attack', 3]] },
    });
    intoHand(engine, 'GUARD5');
    engine.playCard('GUARD5');
    eq(engine.endTurn().opponent.damage, 0, 'fully absorbed');
    eq(engine.state.block, 2, 'and three of the five were spent doing it');
  });

  check("the opponent's guard stops the player", () => {
    // The half that never worked: their "Guarding" intent was decoration.
    const engine = started({
      opponent: { opp_id: 'T', name: 'T', intent_pattern: [['block', 4]] },
    });
    engine.endTurn();
    eq(engine.state.opponent_block, 4);

    intoHand(engine, 'ATTACK3');
    const result = engine.playCard('ATTACK3');
    eq(result.applied.guard_stopped, 3, 'their guard took it all');
    eq(result.applied.opponent_lost, 0, 'so none of their people moved');
    eq(engine.state.opponent_block, 1, 'and three of their four were spent');
  });

  check('the gaffe meter ends the stage when it fills', () => {
    const engine = started();
    engine.state.gaffe = engine.state.gaffe_limit - 2;
    intoHand(engine, 'GAFFE2');
    engine.playCard('GAFFE2');
    eq(engine.state.outcome, 'loss');
    ok(engine.state.outcome_reason.includes('gaffe'));
  });

  check('the gaffe meter never goes below zero', () => {
    const engine = started();
    engine.state.gaffe = 0;
    engine._applyEffect({ gaffe: -3 });
    eq(engine.state.gaffe, 0, 'an apology on a clean record is wasted');
  });

  check('a drawn card cannot be the one just played', () => {
    const engine = started();
    engine.state.hand = ['DRAW2'];
    engine.state.deck = [];
    engine.state.discard = [];
    engine.playCard('DRAW2');
    ok(!engine.state.hand.includes('DRAW2'), 'it is in the discard, not back in hand');
  });

  check('the turn limit ends the stage', () => {
    const engine = started({ stage: stage({ turn_limit: 2 }) });
    engine.endTurn();
    engine.endTurn();
    eq(engine.state.outcome, 'loss');
  });

  check('an opponent with no pattern falls back to the default', () => {
    const engine = started({ opponent: { opp_id: 'OP03', name: 'Masato Maruyama', intent_pattern: null } });
    ok(engine.usedDefaultIntentPattern);
    eq(engine.currentIntent().verb, 'attack');
    eq(engine.currentIntent().value, 6);
  });

  // --- declining ------------------------------------------------------------

  check('ending a turn having played nothing costs you energy', () => {
    const engine = started();
    const result = engine.endTurn();
    ok(result.passed, 'the turn was a pass');
    eq(engine.state.energy, 2, 'next turn is one short');
  });

  check('playing anything at all avoids the penalty', () => {
    const engine = started();
    intoHand(engine, 'GAIN3');
    engine.playCard('GAIN3');
    ok(!engine.endTurn().passed);
    eq(engine.state.energy, 3, 'a full allowance');
  });

  check('a free card still counts as saying something', () => {
    // The count is of cards played, not energy spent.
    const engine = started();
    intoHand(engine, 'FREE');
    engine.playCard('FREE');
    ok(!engine.endTurn().passed);
    eq(engine.state.energy, 3);
  });

  check('the penalty does not follow you into the turn after', () => {
    const engine = started();
    engine.endTurn();
    eq(engine.state.energy, 2);
    intoHand(engine, 'GAIN3');
    engine.playCard('GAIN3');
    engine.endTurn();
    eq(engine.state.energy, 3, 'one quiet turn is not a running debt');
  });

  check('the penalty cannot take energy below nothing', () => {
    const engine = started({
      stage: stage({ energy_per_turn: 1 }),
      rules: Object.assign({}, config().rules, { pass_energy_penalty: 5 }),
    });
    engine.endTurn();
    eq(engine.state.energy, 0, 'nothing, rather than a negative allowance');
  });

  check('the penalty can be switched off', () => {
    const engine = started({
      rules: Object.assign({}, config().rules, { pass_energy_penalty: 0 }),
    });
    engine.endTurn();
    eq(engine.state.energy, 3, 'passing is free when Cameron says it is');
  });

  // --- what a vote costs ---------------------------------------------------

  check('the undecided always cost a point each', () => {
    const bar = floorDebate(STUBBORN);
    eq(bar.playerGains(10), 10);
    eq(bar.undecided, 11);
    eq(bar.opponent, 40, 'nobody was bought off the opponent');
  });

  check('an awkward vote costs two points', () => {
    const bar = floorDebate(AWKWARD);
    bar.undecided = 0;
    bar.player = 61;
    eq(bar.playerGains(6), 3, 'six points bought three votes at two each');
    eq(bar.opponent, 37);
    ok(bar.totalsBalance());
  });

  check('a stubborn vote costs three points', () => {
    const bar = floorDebate(STUBBORN);
    bar.undecided = 0;
    bar.player = 61;
    eq(bar.playerGains(6), 2, 'six points bought only two at three each');
    eq(bar.opponent, 38);
  });

  check('points that cannot afford the next vote are lost', () => {
    const bar = floorDebate(STUBBORN);
    bar.undecided = 0;
    bar.player = 61;
    eq(bar.playerGains(5), 1, 'three points bought one; the other two bought nothing');
    eq(bar.opponent, 39);
    ok(bar.totalsBalance(), 'and the two that were lost are not owed to anybody');
  });

  check('the bands fall where the odds say', () => {
    const bar = floorDebate();
    const counts = { 1: 0, 2: 0, 3: 0 };
    for (let p = 0; p < 100; p++) {
      bar._costRoller = always(p);
      counts[bar.rollOpponentCost()] += 1;
    }
    eq(counts[1], 60, '60 rolls in a hundred cost a point');
    eq(counts[2], 30);
    eq(counts[3], 10);
  });

  check('a bar with no roller still charges', () => {
    // A missing roller must never quietly turn the rule off.
    const bar = new BarModel(SHARED_POOL, 101, 51, 61, 40);
    bar.undecided = 0;
    ok(bar.playerGains(30) <= 30, 'some of those votes cost more than a point');
    ok(bar.totalsBalance());
  });

  // --- the press conference -------------------------------------------------

  function pressConfig(overrides) {
    return config(Object.assign({
      stage: stage({
        stage_id: 'PT_S2', name_en: 'Press Conference',
        draw_mode: 'none', opening_hand: 6,
        bar_max: 100, player_start: 45, opp_start: 45, gaffe_limit: 4,
        turn_limit: 0,
        questions: [
          { id: 'Q1', text: 'First question.', prefers_suit: 'Data Driven', pleases_booster: 'BO08' },
          { id: 'Q2', text: 'Second question.', prefers_suit: 'Earnest', pleases_booster: 'BO03' },
        ],
      }),
      opponent: {},
      opponents: [],
      deck: ['GAIN3', 'GAIN3', 'ATTACK3', 'GUARD5', 'GAFFE2', 'DRAW2', 'GAIN3', 'ATTACK3'],
    }, overrides || {}));
  }

  check('a press conference starts with nobody opposite', () => {
    const engine = new BattleEngine();
    ok(engine.setup(pressConfig()), engine.setupProblems.join('; '));
    eq(engine.state.opponent_count, 0);
    eq(engine.state.hand.length, 6, 'six, not the usual five');
  });

  check('any other stage still needs somebody to argue with', () => {
    const engine = new BattleEngine();
    const c = pressConfig();
    delete c.stage.questions;
    ok(!engine.setup(c));
  });

  check('ending a turn with nobody opposite is not an attack', () => {
    // Nobody is sitting there to act. The tone still falls, but that is the
    // cost of declining the question — not somebody taking a swing at you.
    const c = pressConfig();
    c.stage.decline_tone_cost = 0;
    const engine = new BattleEngine();
    engine.setup(c);
    const before = engine.state.bar.player;

    const result = engine.endTurn();
    ok(result.ok, 'the turn ends rather than crashing');
    eq(result.intent.verb, 'none', 'nobody acted');
    eq(engine.state.bar.player, before, 'so nothing was taken off you');
  });

  check('ending a turn keeps the hand you cannot replace', () => {
    const engine = new BattleEngine();
    engine.setup(pressConfig());
    const held = engine.state.hand.length;
    engine.endTurn();
    eq(engine.state.hand.length, held, 'every card is still in hand');
    ok(!engine.state.isOver(), 'so the conference carries on');
  });

  check('good press tone does not cut the questions short', () => {
    const engine = new BattleEngine();
    engine.setup(pressConfig());
    engine.state.bar.player = engine.state.bar.threshold + 10;
    engine.endTurn();
    ok(!engine.state.isOver(), 'the reporters are not finished');
  });

  check('answering in the invited suit pleases the people who asked', () => {
    const engine = new BattleEngine();
    engine.setup(pressConfig());
    engine.state.hand = ['ATTACK3'];   // Data Driven, like Q1
    engine.playCard('ATTACK3');
    ok(engine.pleasedBoosters().includes('BO08'));
  });

  check('running out of questions ends the conference', () => {
    // One question a turn, so answering both takes two turns. A card is
    // held back so that what ends the stage is the questions running out
    // rather than the hand running dry.
    const engine = new BattleEngine();
    engine.setup(pressConfig());
    engine.state.hand = ['GAIN3', 'GAIN3', 'GUARD5'];
    engine.playCard('GAIN3');
    ok(!engine.state.isOver(), 'one question left');

    engine.endTurn();
    engine.playCard('GAIN3');
    ok(engine.state.isOver(), 'and now none');
    eq(engine.state.outcome, 'win', 'it is not a stage you lose on points');
  });

  // --- several opponents in one stage ---------------------------------------

  check('a committee resets between bouts', () => {
    const engine = started({
      stage: stage({ stage_id: 'PT_S1', sequence_mode: 'reset', win_threshold: 45, turn_limit: 20 }),
      opponents: [
        { opp_id: 'A', name: 'Opponent A', intent_pattern: [['block', 1]] },
        { opp_id: 'B', name: 'Opponent B', intent_pattern: [['block', 1]] },
      ],
    });
    eq(engine.state.opponent_count, 2);
    engine.state.gaffe = 3;
    engine.state.bar.player = 45;
    engine._checkOutcome(false);
    eq(engine.state.opponent_index, 1, 'the next one stepped up');
    ok(!engine.state.isOver(), 'the stage is not over yet');
    eq(engine.state.gaffe, 0, 'a clean record for the new argument');
    eq(engine.state.bar.player, 40, 'and a fresh bar');
  });

  const fiveOnTheFloor = () => ({
    stage: stage({
      stage_id: 'PT_S4', sequence_mode: 'continuous',
      bar_max: 101, win_threshold: 51, player_start: 40, opp_start: 40,
      turn_limit: 20, gaffe_limit: 6,
    }),
    opponents: [
      { opp_id: 'A', name: 'One', intent_pattern: [['block', 1]] },
      { opp_id: 'B', name: 'Two', intent_pattern: [['block', 1]] },
    ],
  });

  check('a new debater means a fresh vote', () => {
    const engine = started(fiveOnTheFloor());
    engine.state.bar.playerGains(8);
    engine.state.gaffe = 2;
    engine.state.turn = 5;
    engine.state.bar.opponentLoses(40);
    engine._checkOutcome(false);

    eq(engine.state.bar.player, 40, 'the vote starts again for the new debater');
    eq(engine.state.bar.opponent, 40, 'and so does theirs');
    eq(engine.state.gaffe, 2, 'but your record is still your record');
    eq(engine.state.turn, 5, 'and the clock keeps running');
    ok(engine.state.bar.totalsBalance());
  });

  check('the threshold ends the debater, not the stage', () => {
    // The bug Cameron caught: reaching the number with debaters still
    // waiting used to carry the bill on the spot.
    const engine = started(fiveOnTheFloor());
    engine.state.bar.playerGains(11);
    engine._checkOutcome(false);

    ok(!engine.state.isOver(), 'there is another person to get through');
    eq(engine.currentOpponent().name, 'Two', 'the next debater rises');
  });

  check('beating the last debater at the threshold carries the bill', () => {
    const engine = started(fiveOnTheFloor());
    for (let i = 0; i < 2; i++) {
      engine.state.bar.playerGains(11);
      engine._checkOutcome(false);
    }
    ok(engine.state.isOver());
    eq(engine.state.outcome, 'win');
  });

  // --- what a stage leaves behind -------------------------------------------

  check('a score above the baseline is worth seats', () => {
    const press = { tone_effects: { baseline: 50, support_per_points: 10, allow_negative: true } };
    eq(LevelRunner.scoreToSupport(press, 70), 2);
    eq(LevelRunner.scoreToSupport(press, 30), -2, 'and below it costs them');
    eq(LevelRunner.scoreToSupport(press, 45), 0, 'falling just short costs nothing');
  });

  check('a stage that forgives a poor showing costs nothing', () => {
    const caucus = { tone_effects: { baseline: 50, support_per_points: 10, allow_negative: false } };
    eq(LevelRunner.scoreToSupport(caucus, 20), 0);
    eq(LevelRunner.scoreToSupport(caucus, 80), 3);
  });

  check('only the named stages are carried', () => {
    const runner = new LevelRunner({
      stages: [
        { seq: 1, name_en: 'First', opponents: [{ opp_id: 'A' }] },
        { seq: 2, name_en: 'Second', opponents: [{ opp_id: 'B' }] },
        { seq: 3, name_en: 'Third', opponents: [{ opp_id: 'C' }], carries_buffs_from: [1] },
      ],
    });
    runner.finishStage('win', 90, []);
    eq(runner.carriedBuffs().support_bonus, 0, 'stage 2 did not ask to carry anything');
    runner.finishStage('win', 0, []);
    eq(runner.carriedBuffs().support_bonus, 4, 'stage 3 did');
  });

  check('pleased organisations are carried forward without duplicates', () => {
    const runner = new LevelRunner({
      stages: [
        { seq: 1, opponents: [{ opp_id: 'A' }] },
        { seq: 2, opponents: [{ opp_id: 'B' }] },
        { seq: 3, opponents: [{ opp_id: 'C' }], carries_buffs_from: [1, 2] },
      ],
    });
    runner.finishStage('win', 0, ['BO08']);
    runner.finishStage('win', 0, ['BO08', 'BO03']);
    eq(runner.carriedBuffs().boosters.length, 2);
  });

  check('losing a stage ends the level there', () => {
    const runner = new LevelRunner({ stages: [{ seq: 1 }, { seq: 2 }] });
    runner.finishStage('loss', 0, []);
    ok(runner.isFinished());
    eq(runner.outcome(), 'loss');
  });

  check('a stage knows whether anybody carries its score', () => {
    const runner = new LevelRunner(data.playtest_level);
    ok(!runner.scoreIsCarriedFrom(1), 'nothing carries the committee');
    ok(runner.scoreIsCarriedFrom(2), 'the floor carries the press conference');
    ok(runner.scoreIsCarriedFrom(3), 'and the caucus');
    ok(!runner.scoreIsCarriedFrom(4), 'nothing comes after the floor');
  });

  // --- the player's standing ------------------------------------------------

  check('a good score raises the variable it names', () => {
    const press = { tone_effects: { baseline: 50, meta: { Reputation: 5 } } };
    const result = applyScoreEffects({ Reputation: 50 }, press, 70, data.sanban);
    eq(result.meta.Reputation, 54, 'twenty above, at five each');
    eq(result.applied.Reputation, 4);
  });

  check("the variable's ceiling is respected and reported honestly", () => {
    const press = { tone_effects: { baseline: 50, meta: { Reputation: 5 } } };
    const result = applyScoreEffects({ Reputation: 98 }, press, 100, data.sanban);
    eq(result.meta.Reputation, 100, 'clamped to the maximum');
    eq(result.applied.Reputation, 2, 'two points, not the ten the score was worth');
  });

  check('a stage that says nothing changes nothing', () => {
    const result = applyScoreEffects({ Reputation: 50 }, { name_en: 'Committee' }, 90, data.sanban);
    eq(result.meta.Reputation, 50);
    eq(Object.keys(result.applied).length, 0);
  });

  // --- the ending is named from the stage ----------------------------------
  // Three kinds of stage are scored — the caucus, the town hall and the TV
  // debate — and all three used to close by announcing they were a caucus.

  function scoredConfig(overrides) {
    return config({
      stage: stage(Object.assign({
        stage_id: 'SCORED', name_en: 'TV Debate',
        win_mode: 'score', turn_limit: 1,
        bar_unit: 'Press tone', bar_max: 100,
        player_start: 40, opp_start: 40,
      }, overrides || {})),
    });
  }

  check('a scored stage closes in its own name', () => {
    const engine = started(scoredConfig());
    engine.endTurn();
    ok(engine.state.isOver());
    ok(engine.state.outcome_reason.includes('TV Debate closed on'),
      engine.state.outcome_reason);
    ok(!engine.state.outcome_reason.toLowerCase().includes('caucus'),
      'a TV debate is not a caucus: ' + engine.state.outcome_reason);
  });

  check('a scored stage closes in its own units', () => {
    // "34 support" on a press tone bar was how the wrong unit showed up.
    const engine = started(scoredConfig());
    engine.endTurn();
    ok(engine.state.outcome_reason.includes('press tone'), engine.state.outcome_reason);
  });

  check('a stage counted as a share still closes on a share', () => {
    const engine = started(scoredConfig({ name_en: 'Party Caucus', bar_as_percent: true }));
    engine.endTurn();
    ok(engine.state.outcome_reason.includes('% of the room'), engine.state.outcome_reason);
    ok(engine.state.outcome_reason.includes('Party Caucus closed on'),
      engine.state.outcome_reason);
  });

  // --- a stage says what kind of bar it wants -------------------------------

  check('a stage can declare its own bar', () => {
    // THE BUG THIS EXISTS FOR. The model used to be picked by matching the
    // literal IDs "ST04" and "ST06", which the six levels never have: they
    // generate theirs from the type and the sequence. The TV debate was
    // therefore a room full of undecided people with a bar labelled "Press
    // tone", for three versions.
    eq(BarModel.forStage({ stage_id: 'TV_DEBATE_2', bar_model: 'single' }), SINGLE);
    eq(BarModel.forStage({ stage_id: 'ANYTHING', bar_model: 'survival' }), SURVIVAL);
    eq(BarModel.forStage({ stage_id: 'ANYTHING', bar_model: 'shared_pool' }), SHARED_POOL);
  });

  check('a stage that says nothing is still guessed at', () => {
    eq(BarModel.forStage({ stage_id: 'ST04' }), SINGLE);
    eq(BarModel.forStage({ stage_id: 'ST06' }), SURVIVAL);
    eq(BarModel.forStage({ stage_id: 'ST02' }), SHARED_POOL);
    eq(BarModel.forStage({ stage_id: 'X', questions: [{ id: 'Q1' }] }), SINGLE,
      'questions still make a press conference');
  });

  check('every TV debate in the data is one bar', () => {
    let checked = 0;
    for (const level of data.levels) {
      for (const st of level.stages) {
        if (st.type !== 'tv_debate') continue;
        eq(BarModel.forStage(st), SINGLE,
          level.level_id + ': a TV debate is press tone, not a room of people');
        checked += 1;
      }
    }
    ok(checked > 0, 'there are TV debates to check');
  });

  check('a level with nothing written signs off by naming itself', () => {
    // LV03 and LV04 are not about a bill, so they carry no win_text yet and
    // must not claim Parliament adopted one.
    for (const level of data.levels) {
      const written = str(level.win_text, '').trim();
      if (written) {
        ok(!['LV03', 'LV04'].includes(level.level_id),
          level.level_id + ' is not a bill level but carries a bill line');
      } else {
        ok(str(level.name_en, '') !== '',
          level.level_id + ' has no sign-off and no name to fall back on');
      }
    }
  });

  // --- the real data --------------------------------------------------------

  check('the starter deck comes from the workbook', () => {
    const deck = starterDeck(data);
    ok(deck.length > 0, 'there are opening-tier cards');
    for (const cardId of deck) {
      ok(cardTable(data)[cardId] !== undefined, cardId + ' is a real card');
    }
  });

  check('every stage of every level can be set up', () => {
    // The stage types were merged into the levels by the BUILD SCRIPT
    // (tools/build_web_playtest.py resolve_type), so what the page holds is
    // already a plain stage. If that merge ever drops a field, a stage fails
    // to start here rather than in front of a player.
    let checked = 0;
    for (const level of data.levels) {
      const runner = new LevelRunner(level);
      ok(runner.stageCount() > 0, level.level_id + ' has no stages');
      for (const st of runner.stages) {
        const engine = new BattleEngine();
        ok(engine.setup(forPlaytestStage(data, st, {}, null, 1)),
          level.level_id + ' ' + st.stage_id + ' starts: ' + engine.setupProblems.join('; '));
        checked += 1;
      }
    }
    eq(checked, 24, 'six levels, twenty-four stages');
  });

  check('every level names a stage type that exists', () => {
    // A row that named a type the build script could not find would have
    // stopped the build, so this is really asking the opposite: that the
    // merge left every stage with the things a stage needs.
    for (const level of data.levels) {
      for (const st of level.stages) {
        ok(str(st.stage_id, '') !== '', level.level_id + ' has a stage with no ID');
        ok(str(st.name_en, '') !== '', st.stage_id + ' has no name');
        ok(str(st.affinity_stage_id, '') !== '',
          st.stage_id + ' has no room for affinity to read');
      }
    }
  });

  check('every stage of the playtest level can be set up', () => {
    const runner = new LevelRunner(data.playtest_level);
    eq(runner.stageCount(), 4, 'hub, then four stages');
    for (const s of runner.stages) {
      const engine = new BattleEngine();
      ok(engine.setup(forPlaytestStage(data, s, {}, null, 1)),
        s.stage_id + ' starts: ' + engine.setupProblems.join('; '));
    }
  });

  check('every question can be answered in the suit it invites', () => {
    const suits = data.cards.filter(c => str(c.tier, '') === OPENING_TIER).map(c => c.suit);
    const press = data.playtest_level.stages.find(s => s.stage_id === 'PT_S2');
    for (const question of press.questions) {
      ok(suits.includes(question.prefers_suit),
        question.id + ' invites ' + question.prefers_suit + ' and no opening card is that suit');
    }
  });

  // --- the four specials the 2026-09-21 card slate introduced --------------
  // Ported from tests/test_battle_engine.gd.

  check('piercing ignores guard without spending it', () => {
    // The distinction that matters: a pierced guard is bypassed, not
    // removed. Subtracting it for real would let one card strip protection
    // it never claimed to take.
    const engine = started({ opponent: { opp_id: 'T', name: 'T', intent_pattern: [['block', 1]] } });
    engine.state.opponent_block = 5;
    engine._cards.PIERCE = card({
      card_id: 'PIERCE', opp_minus: 4, special: 'pierce_guard', special_value: 3,
    });
    engine.state.hand = ['PIERCE'];
    engine.state.energy = 3;

    const applied = engine.playCard('PIERCE').applied;
    eq(applied.guard_pierced, 3, 'three of the five were ignored');
    eq(applied.guard_stopped, 2, 'the other two still stopped what they could');
    eq(applied.opponent_lost, 2, 'so two of the four got through');
    eq(engine.state.opponent_block, 3,
      'the pierced three are still theirs; only the two that worked were spent');
  });

  check('piercing more than they have is not a bonus', () => {
    const engine = started({ opponent: { opp_id: 'T', name: 'T', intent_pattern: [['block', 1]] } });
    engine.state.opponent_block = 1;
    engine._cards.PIERCE = card({
      card_id: 'PIERCE', opp_minus: 3, special: 'pierce_guard', special_value: 9,
    });
    engine.state.hand = ['PIERCE'];
    engine.state.energy = 3;

    const applied = engine.playCard('PIERCE').applied;
    eq(applied.guard_pierced, 1, 'you cannot pierce guard they do not have');
    eq(applied.opponent_lost, 3, 'and the whole attack lands');
  });

  check('a clean record pays off', () => {
    const engine = started();
    const c = card({
      card_id: 'CLEAN', self_plus: 5, special: 'bonus_if_self_gaffe_0', special_value: 2,
    });
    engine.state.gaffe = 0;
    eq(engine.preview(c).self_plus, 7, '5 plus the 2 for a clean record');
    engine.state.gaffe = 1;
    eq(engine.preview(c).self_plus, 5, 'one slip and the bonus is gone');
  });

  check('trailing the opponent pays off', () => {
    const engine = started();
    const c = card({
      card_id: 'BEHIND', self_plus: 3, special: 'bonus_if_behind', special_value: 3,
    });
    engine.state.bar.player = 30;
    engine.state.bar.opponent = 50;
    eq(engine.preview(c).self_plus, 6, 'behind, so the comeback fires');

    engine.state.bar.player = 50;
    eq(engine.preview(c).self_plus, 3, 'level pegging is not behind');

    engine.state.bar.player = 60;
    eq(engine.preview(c).self_plus, 3, 'and ahead is certainly not behind');
  });

  check('a discount makes the next card cheaper', () => {
    const engine = started();
    engine._cards.QUIET = card({
      card_id: 'QUIET', cost: 1, self_plus: 2,
      special: 'discount_next_card_this_turn', special_value: 1,
    });
    engine.state.hand = ['QUIET', 'GAIN3'];
    engine.state.energy = 3;

    engine.playCard('QUIET');
    eq(engine.state.next_card_discount, 1);
    eq(engine.cardCost(engine._cards.GAIN3), 0,
      'a cost-1 card is free while the discount is up');

    engine.playCard('GAIN3');
    eq(engine.state.next_card_discount, 0, 'and the discount is spent by the card using it');
  });

  check('a discount cannot pay you to play', () => {
    const engine = started();
    engine.state.next_card_discount = 5;
    eq(engine.cardCost(card({ card_id: 'FREE2', cost: 1 })), 0, 'floored at nothing');
  });

  check('a discount does not survive the turn', () => {
    const engine = started();
    engine.state.next_card_discount = 1;
    engine.endTurn();
    eq(engine.state.next_card_discount, 0);
  });

  // --- the stage levers Cameron's Levels Design Scheme introduced ----------

  function questionsConfig(overrides) {
    const c = pressConfig();
    c.stage = Object.assign({}, c.stage, overrides || {});
    return c;
  }

  check('a turn presents one question however many cards you play', () => {
    // Before this, three energy could burn through three reporters in a
    // single turn. A conference is paced by the room, not by your hand.
    const engine = started(questionsConfig({ questions_per_turn: 1 }));
    const before = engine.questionsRemaining();
    engine.state.hand = ['GAIN3', 'GAIN3'];
    engine.state.energy = 3;
    engine.playCard('GAIN3');
    engine.playCard('GAIN3');
    eq(engine.questionsRemaining(), before - 1,
      'the second card played, but no reporter was waiting for it');
  });

  check('a study session asks two a turn', () => {
    const engine = started(questionsConfig({ questions_per_turn: 2 }));
    const before = engine.questionsRemaining();
    engine.state.hand = ['GAIN3', 'GAIN3'];
    engine.state.energy = 3;
    engine.playCard('GAIN3');
    engine.playCard('GAIN3');
    eq(engine.questionsRemaining(), before - 2);
  });

  check('a question left hanging at the end of a turn is declined', () => {
    const engine = started(questionsConfig({ questions_per_turn: 2, decline_tone_cost: 3 }));
    // A card held back: a conference ends the moment the player has nothing
    // left to say, and this one is not finished.
    engine.state.hand = ['GAIN3', 'GUARD5'];
    engine.state.energy = 1;
    engine.playCard('GAIN3');
    engine.endTurn();
    eq(engine.state.declined_questions, 1, 'the second went unanswered');
  });

  check('a gaffe costs double in an ambush', () => {
    const engine = started(questionsConfig({ gaffe_multiplier: 2 }));
    engine.state.hand = ['GAFFE2'];
    engine.state.energy = 3;
    engine.playCard('GAFFE2');
    eq(engine.state.gaffe, 4, 'two on the card, four in this room');
  });

  check('an apology is not worth less in a hard room', () => {
    // Only a gaffe gained is doubled. Multiplying a reduction would make the
    // ambush easier to clean up in than an ordinary conference.
    const engine = started(questionsConfig({ gaffe_multiplier: 2 }));
    engine.state.gaffe = 3;
    engine._applyEffect({ gaffe: -2 });
    eq(engine.state.gaffe, 1);
  });

  check('ducking a question ends an ambush', () => {
    const engine = started(questionsConfig({ decline_ends_stage: true, decline_tone_cost: 0 }));
    engine.endTurn();               // played nothing, so the question is ducked
    ok(engine.state.isOver());
    eq(engine.state.outcome, LOST);
    ok(engine.state.outcome_reason.includes('walked away'), engine.state.outcome_reason);
  });

  check("a lobbyist's interest cools every turn", () => {
    const engine = started(questionsConfig({ affinity_decay: 5, decline_tone_cost: 0 }));
    const before = engine.state.bar.player;
    engine.state.hand = ['GAIN3', 'GUARD5'];
    engine.state.energy = 1;
    engine.playCard('GAIN3');       // +3 on the bar
    engine.endTurn();               // then 5 off, whatever was said
    eq(engine.state.bar.player, before + 3 - 5, 'the clock is working against you');
  });

  check('a town hall keeps the clock but refreshes the energy', () => {
    const engine = started({
      stage: stage({ stage_id: 'TOWNHALL', sequence_mode: 'stream', win_threshold: 45, turn_limit: 12 }),
      opponents: [
        { opp_id: 'A', name: 'A farmer', intent_pattern: [['block', 1]] },
        { opp_id: 'B', name: 'A shopkeeper', intent_pattern: [['block', 1]] },
      ],
    });

    engine.state.gaffe = 2;
    engine.state.turn = 6;
    engine.state.energy = 0;
    engine.state.bar.player = 45;
    engine._checkOutcome(false);

    eq(engine.currentOpponent().name, 'A shopkeeper', 'the queue moved on');
    eq(engine.state.gaffe, 2, 'your record follows you down the queue');
    eq(engine.state.turn, 6, 'and so does the clock');
    eq(engine.state.energy, engine.state.energy_per_turn,
      'but the next person gets your full attention');
  });

  check('declining cools the room', () => {
    const c = pressConfig();
    c.stage.decline_tone_cost = 3;
    const engine = new BattleEngine();
    engine.setup(c);
    const tone = engine.state.bar.player;

    engine.endTurn();
    eq(engine.state.bar.player, tone - 3, 'silence costs you the room');
    eq(engine.state.declined_questions, 1);
  });

  check('the closing line names the stage it closed', () => {
    // Named from the stage, because a policy study session and a lobbyist
    // meeting both run on questions and neither of them is a press
    // conference. It said so anyway until a playtest read it.
    const engine = new BattleEngine();
    engine.setup(pressConfig());
    engine.state.hand = ['GAIN3', 'GAIN3', 'GUARD5'];
    engine.playCard('GAIN3');
    engine.endTurn();
    engine.playCard('GAIN3');
    ok(engine.state.outcome_reason.includes('Press Conference concludes.'),
      engine.state.outcome_reason);
  });

  check('a card that does nothing here says so', () => {
    const engine = new BattleEngine();
    engine.setup(pressConfig());
    const effect = engine.preview(card({ card_id: 'ATK', opp_minus: 4 }));
    ok(!effect.opp_minus_counts, 'nobody to reduce');
    ok(effect.does_nothing);
  });

  check('a guard card does nothing where nobody attacks', () => {
    const engine = new BattleEngine();
    engine.setup(pressConfig());
    const effect = engine.preview(card({ card_id: 'G', guard: 5 }));
    ok(!effect.guard_counts, 'no reporter takes a swing at you');
    ok(effect.does_nothing);
  });

  check('the preview shows the room, not the card', () => {
    const engine = started();
    const effect = engine.preview(card({
      card_id: 'BIG', self_plus: 10, suit: 'Data Driven',
    }));
    eq(effect.self_plus, 11, 'ten becomes eleven in this room');
  });

  check('everything counts in an ordinary battle', () => {
    const engine = started();
    const effect = engine.preview(card({
      card_id: 'MIX', self_plus: 3, opp_minus: 4, guard: 2,
    }));
    ok(effect.opp_minus_counts);
    ok(effect.guard_counts);
    ok(!effect.does_nothing);
  });

  check('passing declines the question in front of you', () => {
    const engine = new BattleEngine();
    engine.setup(pressConfig());
    const asked = engine.questionsRemaining();
    const pleased = engine.pleasedBoosters().length;

    engine.endTurn();

    eq(engine.questionsRemaining(), asked - 1, 'the next reporter speaks');
    eq(engine.pleasedBoosters().length, pleased, 'and nobody was pleased by silence');
  });

  check('a pool stage pays the pass out of the pool', () => {
    // There is no refill in a caucus to take the energy off, so it comes out
    // of what is left straight away.
    const caucus = data.playtest_level.stages.find(s => s.stage_id === 'PT_S3');
    const engine = new BattleEngine();
    engine.setup(forPlaytestStage(data, caucus, {}, null, 3));
    const pool = engine.state.energy;

    engine.endTurn();
    eq(engine.state.energy, pool - 1, 'one off the pool, and it does not come back');
  });

  check('a playtest stage borrows the room it is modelled on', () => {
    // The playtest stages carry no audience mix. Rather than invent
    // percentages, each borrows the canon stage it names.
    const press = data.playtest_level.stages.find(s => s.stage_id === 'PT_S2');
    const filled = withAudience(data, press);
    ok(filled.segment_mix, 'the conference has a room');

    let total = 0;
    for (const share of Object.values(filled.segment_mix)) total += share;
    ok(Math.abs(total - 1) < 0.001, 'and it adds up to the whole room');
  });

  check('the audience reaches the cards', () => {
    // A card aimed at one part of the room used to read that audience as
    // nought per cent of it.
    const press = data.playtest_level.stages.find(s => s.stage_id === 'PT_S2');
    const c21 = data.cards.find(c => c.card_id === 'C21');   // aimed at the Press
    ok(segmentShare(c21, withAudience(data, press)) > 0.5,
      'the room is mostly who this card is aimed at');
  });

  check('the floor debate asks 55 of each debater', () => {
    const engine = new BattleEngine();
    const floor = data.playtest_level.stages.find(s => s.stage_id === 'PT_S4');
    engine.setup(forPlaytestStage(data, floor, {}, null, 7));

    eq(engine.state.bar.threshold, 55, 'to end the debater in front of you');
    eq(engine.state.opponent_count, 5);
  });

  // --- who actually moved, ported from tests/test_bar_model.gd -------------

  check('a gain records that it came from the undecided', () => {
    const bar = new BarModel(SHARED_POOL, 101, 51, 40, 40, () => 0);
    bar.playerGains(3);
    eq(bar.last_gain.from_undecided, 3);
    eq(bar.last_gain.from_other_side, 0, 'none had to be prised away');
  });

  check('a gain records the split once the undecided run out', () => {
    const bar = new BarModel(SHARED_POOL, 101, 51, 40, 59, () => 0);
    eq(bar.undecided, 2, 'two waverers and nobody else free');
    bar.playerGains(5);
    eq(bar.last_gain.from_undecided, 2);
    eq(bar.last_gain.from_other_side, 3, 'the rest argued off the opposition');
  });

  check('points that cannot pay for anybody are recorded as wasted', () => {
    // The stubborn cost three and there are two points left: the seat does
    // not move and the points are gone.
    const bar = new BarModel(SHARED_POOL, 101, 51, 40, 61, () => 90);
    eq(bar.playerGains(5), 1, 'three points bought one stubborn vote');
    eq(bar.last_gain.wasted, 2, 'two points left, and nobody costs two here');
  });

  check('the opponent gains record the same way', () => {
    const bar = new BarModel(SHARED_POOL, 101, 51, 40, 40, () => 0);
    bar.opponentGains(25);
    eq(bar.last_gain.from_undecided, 21);
    eq(bar.last_gain.from_other_side, 4, 'four taken off the player');
  });

  // --- what a card will do, ported from tests/test_battle_engine.gd --------

  check('a card that only gaffes is not called useless', () => {
    // It does something — something bad. Calling it useless produced a card
    // reading "Gaffe +1. Nothing this card does counts in this room."
    const engine = started();
    const effect = engine.preview(card({ card_id: 'OOPS', gaffe: 2 }));
    ok(!effect.does_nothing, 'doing something bad is still doing something');
  });

  check('a preview says a card will answer the question', () => {
    const engine = new BattleEngine();
    ok(engine.setup(pressConfig()), engine.setupProblems.join('; '));

    const effect = engine.preview(card({ card_id: 'D1', draw: 1 }));
    ok(effect.answers_question, 'every card answers, including a draw-only one');
  });

  check('a preview outside a press conference answers nothing', () => {
    const engine = started();
    const effect = engine.preview(card({ card_id: 'D1', draw: 1 }));
    ok(!effect.answers_question);
  });

  // --- a finished debater, ported from tests/test_battle_engine.gd ---------

  check('a card that finishes a debater says so', () => {
    const engine = new BattleEngine();
    const floor = data.playtest_level.stages.find(s => s.stage_id === 'PT_S4');
    engine.setup(forPlaytestStage(data, floor, {}, null, 13));

    engine.state.bar.player = engine.state.bar.threshold - 1;
    engine.state.bar.undecided = 101 - engine.state.bar.player - engine.state.bar.opponent;

    const card = engine.state.hand.find(id => {
      const c = data.cards.find(x => x.card_id === id);
      return c && int(c.self_plus, 0) > 0;
    });
    ok(card, 'the opening hand has something that persuades');
    engine.state.energy = 9;

    const result = engine.playCard(card);
    ok(result.bout_won, 'the card ended the bout; the screen has to know');
    ok(result.bout_won.next !== '', 'and who rises in their place');
  });

  // --- what a stage is worth, ported from tests/test_level_runner.gd -------

  check('a stage reports the rewards it carries', () => {
    const rewards = winRewards({
      win_delta_jiban: 4, win_delta_kanban: -2,
      win_delta_kaban: 0, win_delta_party_support: 3,
    });
    eq(rewards['Constituency support'], 4);
    eq(rewards['Reputation'], -2, 'a penalty is a reward the other way');
    ok(!('Funds' in rewards), 'a variable this stage does not touch is not news');
  });

  check('a stage with no numbers set says so rather than showing zeroes', () => {
    ok(rewardsAreUnset({
      win_delta_jiban: 0, win_delta_kanban: 0,
      win_delta_kaban: 0, win_delta_party_support: 0, xp_reward: 0,
    }));
    ok(!rewardsAreUnset({ xp_reward: 20 }));
  });

  check('winning a stage applies its rewards', () => {
    // apply_win_deltas had no caller in either engine, so every stage in the
    // game was won for nothing.
    const result = applyWinDeltas({ Reputation: 50 },
      { win_delta_kanban: 3 }, data.sanban);
    eq(result.applied['Reputation'], 3);
    eq(result.meta['Reputation'], 53);
  });

  check('the real playtest stages have reward slots waiting', () => {
    for (const stage of data.playtest_level.stages) {
      ok('win_delta_jiban' in stage, stage.stage_id + ' needs a slot');
      ok('xp_reward' in stage, stage.stage_id + ' needs an XP slot');
    }
  });

  check('the caucus is named after the player\'s party', () => {
    const caucus = data.playtest_level.stages.find(s => s.stage_id === 'PT_S3');
    ok(!caucus.name_en.includes('{party}'), 'the token is resolved, not printed');
    ok(caucus.name_en.includes(data.player.party), 'and resolved to the real party');
    ok(caucus.bar_as_percent, 'and its bar reads as a share of the room');
  });

  // --- the ledger, ported from tests/test_ledger.gd ------------------------

  const BAL = { starter_deck_size: 12 };
  const STANDING_SETTINGS = { required_standing: 60 };
  const BOOSTER_IDS = ['BO01', 'BO03', 'BO08'];
  const aCard = o => Object.assign(
    { card_id: 'C99', tier: 'Tier 1', xp_to_unlock: 60 }, o || {});
  const aMod = o => Object.assign(
    { mod_id: 'M01', kaban_cost: 20, available_to: 'Both', source_booster: 'BO03' },
    o || {});

  check('a card you cannot afford says how short you are', () => {
    eq(cardRefusal(aCard(), [], 43), '17 XP short.');
    eq(cardRefusal(aCard(), [], 60), '', 'exactly enough is enough');
  });

  check('a card you already own cannot be bought twice', () => {
    eq(cardRefusal(aCard(), ['C99'], 999), 'Already yours.');
  });

  check('standing is checked before the price', () => {
    // Being told the price of something you may not buy is worse than
    // being told why you may not buy it.
    eq(modifierRefusal(aMod(), [], 0, { BO03: 10 }, STANDING_SETTINGS, BOOSTER_IDS),
      'Standing 10 of 60 needed.');
  });

  check('a backed modifier you can afford is yours', () => {
    eq(modifierRefusal(aMod(), [], 30, { BO03: 60 }, STANDING_SETTINGS, BOOSTER_IDS), '');
    eq(modifierRefusal(aMod(), [], 12, { BO03: 99 }, STANDING_SETTINGS, BOOSTER_IDS),
      '8 short.');
  });

  check('a modifier with no price is not for sale', () => {
    ok(!isForSale(aMod({ kaban_cost: null })));
    ok(!isForSale(aMod({ available_to: 'Opponent' })), 'not on the player shelf');
  });

  check('a modifier backed by nobody needs no standing', () => {
    // M09 and M10 name a meta-variable rather than an organisation.
    const m = aMod({ source_booster: 'Party support (meta)' });
    eq(backingBooster(m, BOOSTER_IDS), '');
    eq(modifierRefusal(m, [], 30, {}, STANDING_SETTINGS, BOOSTER_IDS), '');
  });

  check('a deck is exactly the right size and all yours', () => {
    const owned = [];
    for (let i = 0; i < 20; i++) owned.push('C' + i);
    eq(deckRefusal(owned.slice(0, 12), owned, BAL), '');
    eq(deckRefusal(owned.slice(0, 9), owned, BAL), '3 more to choose.');
    eq(deckRefusal(owned.slice(0, 14), owned, BAL), '2 too many.');
    eq(deckRefusal(['C0', 'NOPE'], ['C0'], BAL), 'NOPE is not yours.');
  });

  check('a new run opens with the opening-tier cards', () => {
    // Twelve wanted, two at the opening tier, so the rest is filled a suit
    // at a time from the tiers above. The opening two come first.
    const cards = [
      { card_id: 'S1', tier: OPENING_TIER, suit: 'Earnest' },
      { card_id: 'T1', tier: '1', suit: 'Earnest' },
      { card_id: 'S2', tier: OPENING_TIER, suit: 'Appeal' },
      { card_id: 'T2', tier: '1', suit: 'Appeal' },
    ];
    const deck = openingDeck(cards, BAL);
    eq(deck.slice(0, 2).join(','), 'S1,S2', 'the opening tier is dealt first');
    eq(deck.length, 4, 'and the fill stops when there is nothing left to add');
  });

  check('the fill keeps every suit represented', () => {
    // Six suits, one opening card each, twelve wanted. The fill must not
    // hand out six more of one element and none of another.
    const cards = [];
    const suits = ['Earnest', 'Emotional', 'Appeal', 'Data Driven', 'Divisive', 'Duplicitous'];
    for (const suit of suits) {
      cards.push({ card_id: 'O' + suit, tier: OPENING_TIER, suit: suit });
      for (let i = 0; i < 4; i++) cards.push({ card_id: 'X' + suit + i, tier: '1', suit: suit });
    }
    const deck = openingDeck(cards, BAL);
    eq(deck.length, 12);
    const byId = Object.fromEntries(cards.map(c => [c.card_id, c]));
    for (const suit of suits) {
      eq(deck.filter(id => byId[id].suit === suit).length, 2, suit + ' is in twice');
    }
  });

  // --- what backing does, ported from tests/test_modifier_effects.gd -------

  const BRIDGE = {
    M01: 'player_start_support', M03: 'starting_gaffe',
    M02: 'kaban_per_stage_win', M13: 'jiban_per_module_win',
  };

  check('the workbook column wins over the bridge', () => {
    // The bridge is temporary; the column must take over without anybody
    // remembering to delete the file.
    eq(effectKeyFor(aMod({ effect_key: 'starting_gaffe' }), BRIDGE), 'starting_gaffe');
    eq(effectKeyFor(aMod({}), BRIDGE), 'player_start_support');
  });

  check('backing raises where you start, and stacks', () => {
    const bonus = battleStartBonus(
      [aMod({ magnitude: 3 }), aMod({ magnitude: 4 })], BRIDGE);
    eq(bonus.start_support, 7);
  });

  check('a business circle pays for a stage won', () => {
    eq(stageWinFunds([aMod({ mod_id: 'M02', magnitude: 5 })], BRIDGE), 5);
    eq(stageWinFunds([aMod({ mod_id: 'M01', magnitude: 9 })], BRIDGE), 0,
      'start support is not an income');
  });

  check('an effect with nothing to bite on is not called built', () => {
    // The gaffe meter always opens at zero, so taking a point off it takes
    // nothing. The shop must not sell it as working.
    const m = aMod({ mod_id: 'M03', magnitude: 1 });
    ok(effectIsInertToday(m, BRIDGE));
    ok(!effectIsImplemented(m, BRIDGE));
    ok(effectIsImplemented(aMod({ magnitude: 3 }), BRIDGE), 'but this one is');
  });

  check('a module-level effect is known but not built', () => {
    const m = aMod({ mod_id: 'M13', magnitude: 3 });
    ok(effectIsKnownButUnbuilt(m, BRIDGE));
    ok(!effectIsImplemented(m, BRIDGE));
  });

  check('the player is never shown the word Magnitude', () => {
    // The effect column says "Magnitude" where a number belongs, because it
    // was written for a designer.
    eq(describeEffect(aMod({ magnitude: 3 }), BRIDGE), 'Start 3 ahead.');
    for (const modifier of data.modifiers) {
      const text = describeEffect(modifier, data.modifier_effects || {});
      ok(!text.includes('Magnitude'),
        modifier.mod_id + ' still shows it: ' + text);
    }
  });

  check('every bridged modifier is real and every effect is known', () => {
    for (const modId of Object.keys(data.modifier_effects || {})) {
      ok(data.modifiers.some(m => m.mod_id === modId),
        modId + ' is mapped to an effect but is not a modifier');
      const key = str((data.modifier_effects || {})[modId], '');
      ok(AT_BATTLE_START.includes(key) || AFTER_STAGE_WIN.includes(key)
        || NOT_YET_BUILT.includes(key),
        modId + " is mapped to '" + key + "', which nothing implements");
    }
  });

  check('the deck a battle is dealt is the one the run chose', () => {
    const floor = data.playtest_level.stages.find(s => s.stage_id === 'PT_S4');
    const engine = new BattleEngine();
    engine.setup(forPlaytestStage(data, floor, {}, null, 5,
      { deck: ['C01', 'C01', 'C01'], modifiers: [] }));
    eq(engine.state.deck.length + engine.state.hand.length, 3,
      'three cards in, three cards dealt and held');
  });

  check('backing you have bought starts you ahead', () => {
    const floor = data.playtest_level.stages.find(s => s.stage_id === 'PT_S4');
    const plain = new BattleEngine();
    plain.setup(forPlaytestStage(data, floor, {}, null, 5, {}));

    const backed = new BattleEngine();
    backed.setup(forPlaytestStage(data, floor, {}, null, 5,
      { deck: [], modifiers: ['M01'] }));

    // M01 wants Constituents >= 30% and the floor has 10%, so it does not
    // fire there — which is the audience gate doing its job.
    eq(backed.state.bar.player, plain.state.bar.player,
      'no constituents in the chamber, so the local association is no help');
  });

  return { count: count, failures: failures };
}
