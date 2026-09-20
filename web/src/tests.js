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

  check('a refutation still helps on a single bar', () => {
    const bar = new BarModel(SINGLE, 100, 55, 45, 0);
    bar.opponentLoses(3);
    eq(bar.player, 48);
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

  check('block does not carry into the next turn', () => {
    const engine = started();
    intoHand(engine, 'GUARD5');
    engine.playCard('GUARD5');
    engine.endTurn();
    eq(engine.state.block, 0);
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
        stage_id: 'PT_S2', draw_mode: 'none', opening_hand: 6,
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

  check('ending a turn with nobody opposite does nothing to you', () => {
    const engine = new BattleEngine();
    engine.setup(pressConfig());
    const before = engine.state.bar.player;
    const result = engine.endTurn();
    ok(result.ok, 'the turn ends rather than crashing');
    eq(result.intent.verb, 'none', 'nobody acted');
    eq(engine.state.bar.player, before);
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
    const engine = new BattleEngine();
    engine.setup(pressConfig());
    engine.state.hand = ['GAIN3', 'GAIN3', 'GAIN3'];
    engine.playCard('GAIN3');
    engine.playCard('GAIN3');
    ok(engine.state.isOver());
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

  // --- the real data --------------------------------------------------------

  check('the starter deck comes from the workbook', () => {
    const deck = starterDeck(data);
    ok(deck.length > 0, 'there are Starter-tier cards');
    for (const cardId of deck) {
      ok(cardTable(data)[cardId] !== undefined, cardId + ' is a real card');
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
    const suits = data.cards.filter(c => c.tier === 'Starter').map(c => c.suit);
    const press = data.playtest_level.stages.find(s => s.stage_id === 'PT_S2');
    for (const question of press.questions) {
      ok(suits.includes(question.prefers_suit),
        question.id + ' invites ' + question.prefers_suit + ' and no Starter card is that suit');
    }
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

  return { count: count, failures: failures };
}
