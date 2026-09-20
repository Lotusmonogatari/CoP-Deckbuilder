// The screens: the Office, a battle, and the three overlays.
//
// Mirrors scripts/ui/ — same information in the same order, following
// CLAUDE.md §10: stage name with a muted Japanese accent, then who is
// speaking, then the win condition, then energy and gaffes, then the hand,
// then one full-width button.

'use strict';

const DATA = window.COP_DATA;

const el = (tag, className, text) => {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
};

// Missing art never blocks testing: a flat block labelled with the asset ID,
// its hue derived from the ID so the same character is the same colour every
// time. Same idea as scripts/ui/ArtLoader.gd.
function placeholderArt(id, size) {
  const node = el('div', 'art');
  let hash = 0;
  for (let i = 0; i < id.length; i++) hash = (hash * 31 + id.charCodeAt(i)) >>> 0;
  node.style.setProperty('--art-hue', String(hash % 360));
  if (size) node.style.setProperty('--art-size', size);
  node.append(el('span', 'art-id', id || '—'));
  return node;
}

// ---------------------------------------------------------------------------
// The run
// ---------------------------------------------------------------------------

const run = {
  runner: null,
  meta: startingMeta(DATA),
  // Where the player stands with each organisation, held between levels —
  // unlike the pleased list, which lasts one level.
  boosterStanding: Object.fromEntries(
    DATA.boosters.map(b => [b.booster_id, int(DATA.booster_standing.start, 50)])),
  lastBoosterChange: {},
  lastLevelOutcome: '',
  lastMetaChange: {},
  engine: null,
  stage: null,
  selected: null,
};

const root = document.getElementById('screen');

function boosterNameOf(id) { return boosterNames(DATA)[id] || id; }

// How this room is treating this suit, in words rather than a multiplier.
// "×0.80" is precise and means nothing at the table; what a player needs to
// know is whether the room is with them, and roughly how much.
function describeRoomFor(affinity) {
  if (affinity >= 1.51) return 'Being greatly enhanced by supporters.';
  if (affinity > 1) return 'Being enhanced by supporters.';
  if (affinity < 0.5) return 'Being greatly suppressed by opponents.';
  if (affinity < 1) return 'Being suppressed by detractors.';
  return 'Landing as written here.';
}

// Who is in the room, and what it takes to win one of them over. Both are
// rules a player would otherwise have to work out by losing.
function roomLines(s) {
  const lines = [];

  const mix = run.engine._stage.segment_mix || {};
  const parts = [];
  for (const segment of DATA.segments) {
    const share = Number(mix[segment.segment_id] || 0);
    if (share > 0) parts.push(Math.round(share * 100) + '% ' + segment.name_en);
  }
  if (parts.length > 0) lines.push('In the room: ' + parts.join(', ') + '.');

  if (s.bar && s.bar.model === SHARED_POOL) {
    lines.push('Winning over somebody undecided takes one point. Somebody '
      + 'already against you takes one, two or three — you find out which as '
      + 'you go, and points you cannot spend are lost.');
  }

  return lines;
}

// ---------------------------------------------------------------------------
// The Office
// ---------------------------------------------------------------------------

function showOffice() {
  run.engine = null;
  root.replaceChildren();
  root.className = 'screen office';

  const player = DATA.player;
  const head = el('header', 'office-head');
  head.append(el('h1', 'office-name', player.name_en + ' · ' + player.party));
  head.append(el('p', 'jp', '陳情'));
  root.append(head);

  root.append(placeholderArt('PROTAGONIST', '148px'));

  const report = el('p', 'office-report', lastLevelReport());
  root.append(report);

  // The player's standing. Nothing else in the level shows these, and the
  // press conference now moves one of them.
  const standing = el('section', 'standing');
  standing.append(el('h2', 'label', 'Where you stand'));
  const grid = el('dl', 'standing-grid');
  for (const row of DATA.sanban) {
    const change = run.lastMetaChange[row.name_en];
    const dt = el('dt', null, row.name_en);
    const dd = el('dd', null, String(run.meta[row.name_en]));
    if (change) {
      const delta = el('span', change > 0 ? 'delta up' : 'delta down',
        (change > 0 ? '+' : '−') + Math.abs(change));
      dd.append(' ', delta);
    }
    grid.append(dt, dd);
  }
  standing.append(grid);
  root.append(standing);

  const start = el('button', 'primary', 'Start ' + DATA.playtest_level.name_en);
  start.id = 'start-level';
  start.addEventListener('click', startLevel);
  root.append(start);

  // Who is behind you, and how far. Secondary, so it lives behind a button.
  const orgs = el('button', 'ghost', 'The organisations');
  orgs.id = 'organisations';
  orgs.addEventListener('click', showOrganisations);
  root.append(orgs);

  root.append(rulesCheckLine());
}

function lastLevelReport() {
  if (!run.lastLevelOutcome) return 'Nothing on today. The House sits shortly.';
  if (run.lastLevelOutcome === WON) return 'The bill carried. Word has got round.';
  return 'The bill failed. There will be questions.';
}

function startLevel() {
  run.runner = new LevelRunner(DATA.playtest_level);
  run.lastLevelOutcome = '';
  run.lastMetaChange = {};
  run.lastBoosterChange = {};
  openStage();
}

// The ten organisations, and where the player stands with each.
//
// Grouped by tier rather than listed flat, because the tiers are the real
// distinction: a Constituency group is worth something different from a
// National one, and seeing them mixed hides that.
function showOrganisations() {
  overlay('The organisations', sheet => {
    sheet.append(el('p', 'detail-line', 'Answering a reporter in the suit '
      + 'their question invites pleases the organisation behind it, and that '
      + 'standing is carried between levels.'));

    for (const tier of ['Party', 'Constituency', 'National']) {
      const inTier = DATA.boosters.filter(b => b.tier === tier);
      if (inTier.length === 0) continue;

      sheet.append(el('h3', 'org-tier', tier));
      for (const booster of inTier) {
        const row = el('div', 'org');
        const head = el('p', 'org-name');
        head.append(booster.name_en + ' ');
        head.append(el('span', 'jp', booster.name_jp || ''));

        const standing = el('span', 'org-standing',
          String(run.boosterStanding[booster.booster_id]));
        const change = run.lastBoosterChange[booster.booster_id];
        if (change) standing.append(' ', el('span', 'delta up', '+' + change));
        head.append(' — ', standing);

        row.append(head);
        row.append(el('p', 'org-boosts', booster.boosts || ''));
        sheet.append(row);
      }
    }

    const back = el('button', 'ghost', 'Back');
    back.id = 'organisations-close';
    back.addEventListener('click', () => sheet.closest('.backdrop').remove());
    sheet.append(back);
  });
}

// Raises the player's standing with everyone pleased in a stage.
function pleaseOrganisations(boosters) {
  const step = int(DATA.booster_standing.per_please, 5);
  const low = int(DATA.booster_standing.min, 0);
  const high = int(DATA.booster_standing.max, 100);

  for (const id of boosters) {
    const before = run.boosterStanding[id];
    const after = Math.min(Math.max(before + step, low), high);
    run.boosterStanding[id] = after;
    if (after !== before) run.lastBoosterChange[id] = after - before;
  }
}

// ---------------------------------------------------------------------------
// A battle
// ---------------------------------------------------------------------------

function openStage() {
  run.stage = run.runner.currentStage();
  run.engine = new BattleEngine();

  const ok = run.engine.setup(forPlaytestStage(
    DATA, run.stage, run.runner.carriedBuffs(), run.meta,
    Math.floor(Math.random() * 0x7fffffff)));

  if (!ok) {
    root.replaceChildren();
    root.className = 'screen office';
    root.append(el('h1', 'office-name', 'This stage could not start'));
    const list = el('ul', 'problems');
    for (const problem of run.engine.setupProblems) list.append(el('li', null, problem));
    root.append(list);
    const back = el('button', 'primary', 'Back to the Office');
    back.addEventListener('click', () => { run.runner = null; showOffice(); });
    root.append(back);
    return;
  }

  drawBattle();
}

function drawBattle() {
  const engine = run.engine;
  const s = engine.state;
  const stage = run.stage;

  root.replaceChildren();
  root.className = 'screen battle';

  // 1. Header: stage name, a muted Japanese accent, and where you are.
  const head = el('header', 'battle-head');
  const name = el('div', 'stage-name');
  name.append(el('h1', null, stage.name_en));
  if (stage.name_jp) name.append(el('span', 'jp', stage.name_jp));
  head.append(name);
  head.append(el('div', 'turn',
    engine.isPressConference() ? engine.questionCaption() : engine.turnCaption()));
  root.append(head);

  // 2. Who is speaking.
  root.append(speakerRow());

  // 3. The win condition.
  root.append(supportBar());

  // 4. Energy and gaffes.
  const status = el('div', 'status');
  const pips = el('div', 'pips');
  for (let i = 0; i < Math.max(s.energy_max, 1); i++) {
    pips.append(el('span', i < s.energy ? 'pip on' : 'pip'));
  }
  status.append(pips);

  const right = el('div', 'status-right');
  // How much of the next attack is already covered. Shown only when there is
  // some: a permanent "Guarding 0" is noise.
  if (s.block > 0) right.append(el('span', 'guarding', 'Guarding ' + s.block));
  // The gaffe warning turns red ONLY when one more would end the stage.
  right.append(el('span', engine.gaffeIsCritical() ? 'gaffes warn' : 'gaffes',
    'Gaffes ' + s.gaffe + ' / ' + s.gaffe_limit));
  const details = el('button', 'link', 'Details');
  details.addEventListener('click', showDetails);
  right.append(details);
  status.append(right);
  root.append(status);

  root.append(el('div', 'spacer'));

  // 5. The hand.
  const hand = el('div', 'hand');
  if (s.hand.length === 0) {
    hand.append(el('p', 'empty-hand', 'Nothing left in hand.'));
  }
  for (const cardId of s.hand) {
    hand.append(cardFace(DATA.cards.find(c => c.card_id === cardId), s));
  }

  root.append(hand);

  // 6. One full-width button.
  const endTurn = el('button', 'primary', 'End turn');
  endTurn.id = 'end-turn';
  endTurn.disabled = s.isOver();
  endTurn.addEventListener('click', () => {
    const turn = engine.endTurn();
    drawBattle();
    // The pass penalty has always worked; nothing ever said so, which is why
    // a playtest read it as having stopped after the first time.
    if (turn.passed && !engine.state.isOver()) {
      flash(engine.isPressConference()
        ? 'You let that one go. The room cools.'
        : 'You said nothing. One less energy this turn.');
    }
  });
  root.append(endTurn);

  if (s.isOver()) showOutcome();
}

function speakerRow() {
  const engine = run.engine;
  const row = el('section', 'speaker');
  const text = el('div', 'speaker-text');

  if (engine.isPressConference()) {
    const question = engine.currentQuestion();
    const journalist = question
      ? DATA.journalists.find(j => j.journalist_id === question.asked_by)
      : null;
    if (journalist) {
      row.append(placeholderArt(journalist.journalist_id, '64px'));
      text.append(el('h2', null, journalist.name));
    }
    text.append(el('p', 'says', question ? question.text : 'That was the last question.'));
    row.append(text);
    return row;
  }

  const opponent = engine.currentOpponent();
  const caption = engine.opponentCaption();
  row.append(placeholderArt(String(opponent.opp_id || ''), '64px'));
  text.append(el('h2', null, (opponent.name || 'Visitor A') + (caption ? '  ·  ' + caption : '')));
  text.append(el('p', 'says', IntentRunner.describe(engine.currentIntent())));
  row.append(text);
  return row;
}

function supportBar() {
  const engine = run.engine;
  const s = engine.state;
  const bar = s.bar;
  const unit = run.stage.bar_unit || 'Support';

  // A scored stage has no threshold, and neither has a press conference: it
  // runs until the reporters are finished, whatever the tone.
  const hasThreshold = s.win_mode !== 'score' && !engine.isPressConference();
  const twoSided = bar.model === SHARED_POOL;

  const wrap = el('section', 'bar-wrap');
  wrap.append(el('p', 'bar-caption', hasThreshold
    ? bar.threshold + ' ' + unit.toLowerCase() + ' to win'
    : 'Raise ' + unit.toLowerCase() + ' as high as you can'));

  const track = el('div', 'bar');
  const mine = el('div', 'bar-mine');
  mine.style.width = (100 * bar.player / bar.maximum) + '%';
  track.append(mine);

  if (twoSided) {
    const theirs = el('div', 'bar-theirs');
    theirs.style.width = (100 * bar.opponent / bar.maximum) + '%';
    track.append(theirs);
  }
  if (hasThreshold) {
    const line = el('div', 'bar-line');
    line.style.left = (100 * bar.threshold / bar.maximum) + '%';
    track.append(line);
  }
  wrap.append(track);

  wrap.append(el('p', 'bar-readout', twoSided
    ? 'You ' + bar.player + ' · Undecided ' + bar.undecided + ' · Them ' + bar.opponent
    : unit + ' ' + bar.player + ' of ' + bar.maximum));
  return wrap;
}

// Tapping a card opens it rather than playing it, so a mis-tap never costs a
// turn.
function cardFace(card, s) {
  const face = el('button', 'card');
  face.dataset.cardId = card.card_id;
  face.classList.add('suit-' + card.suit.toLowerCase().replace(/\s+/g, '-'));
  if (Number(card.cost) > s.energy) face.classList.add('unaffordable');

  // What it will do HERE, not what it says on paper. The room moves the
  // numbers, and in some rooms a number does nothing at all.
  const effect = run.engine.preview(card);
  if (effect.does_nothing) face.classList.add('useless');

  face.append(el('span', 'card-cost', String(Math.trunc(card.cost))));
  face.append(el('span', 'card-name', card.name_en));
  if (card.name_jp) face.append(el('span', 'jp card-jp', card.name_jp));
  face.append(el('span', 'card-text', effectHere(effect, card)));

  face.addEventListener('click', () => showCardZoom(card));
  return face;
}

// A card's numbers as this room will actually use them. Showing the printed
// value and then quietly doing something else is how a player stops trusting
// the screen.
function effectHere(effect, card) {
  const parts = [];
  if (effect.self_plus) parts.push('Gain ' + effect.self_plus + '.');
  if (effect.opp_minus && effect.opp_minus_counts) {
    parts.push('Opponent \u2212' + effect.opp_minus + '.');
  }
  if (effect.guard && effect.guard_counts) parts.push('Guard ' + effect.guard + '.');
  if (effect.draw) parts.push('Draw ' + effect.draw + '.');
  if (effect.gaffe) parts.push('Gaffe ' + (effect.gaffe > 0 ? '+' : '') + effect.gaffe + '.');

  if (effect.does_nothing) parts.push('Nothing this card does counts in this room.');

  return parts.length > 0 ? parts.join(' ') : (card.effect_text || '');
}

// What a card just did, in the room's own units. The numbers are a budget,
// not an outcome: five points can win five people or three.
function describeWhatHappened(result, stage) {
  const applied = result.applied || {};
  const effect = result.effect || {};
  const unit = String(stage.bar_unit || 'support').toLowerCase();
  const parts = [];

  const wanted = int(effect.self_plus, 0);
  const won = int(applied.gained, 0);
  if (wanted > 0) {
    parts.push(won < wanted
      ? won + ' ' + unit + ' won over \u2014 ' + (wanted - won)
        + (wanted - won === 1 ? ' point short' : ' points short')
      : won + ' ' + unit + ' won over');
  }

  const stopped = int(applied.guard_stopped, 0);
  if (stopped > 0) parts.push('their guard stopped ' + stopped);

  const lost = int(applied.opponent_lost, 0);
  if (lost > 0) parts.push(lost + ' argued away from them');

  if (parts.length === 0) return '';
  const line = parts.join(', ');
  return line.charAt(0).toUpperCase() + line.slice(1) + '.';
}

// A short line under the bar, for what just happened.
function flash(message) {
  if (!message) return;
  const bar = document.querySelector('.bar-wrap');
  if (!bar) return;
  const note = el('p', 'flash', message);
  bar.append(note);
}

// ---------------------------------------------------------------------------
// Overlays — every one closes three ways: its button, Escape, or the backdrop
// ---------------------------------------------------------------------------

function overlay(title, build, options) {
  options = options || {};
  const back = el('div', 'backdrop');
  const sheet = el('div', 'sheet');
  sheet.setAttribute('role', 'dialog');
  sheet.setAttribute('aria-modal', 'true');
  sheet.setAttribute('aria-label', title);

  sheet.append(el('h2', 'sheet-title', title));
  build(sheet);

  const close = () => back.remove();
  if (!options.noDismiss) {
    back.addEventListener('click', event => { if (event.target === back) close(); });
    document.addEventListener('keydown', function onKey(event) {
      if (event.key === 'Escape') { close(); document.removeEventListener('keydown', onKey); }
    });
  }

  back.append(sheet);
  document.body.append(back);
  return { sheet, close };
}

function showCardZoom(card) {
  const s = run.engine.state;
  const affinity = run.engine.affinityFor(card);

  overlay(card.name_en, sheet => {
    const meta = el('p', 'zoom-meta', card.suit + ' · ' + card.type
      + ' · ' + Math.trunc(card.cost) + ' energy');
    sheet.append(meta);
    if (card.name_jp) sheet.append(el('p', 'jp', card.name_jp + '  ' + (card.romaji || '')));
    sheet.append(placeholderArt(card.card_id, '120px'));
    sheet.append(el('p', 'zoom-text', card.effect_text || ''));
    sheet.append(el('p', 'zoom-room', describeRoomFor(affinity)));

    const play = el('button', 'primary', 'Play');
    play.id = 'zoom-play';
    play.disabled = Number(card.cost) > s.energy || s.isOver();
    play.addEventListener('click', () => {
      document.querySelectorAll('.backdrop').forEach(n => n.remove());
      const result = run.engine.playCard(card.card_id);
      drawBattle();
      flash(describeWhatHappened(result, run.stage));
    });
    sheet.append(play);

    const back = el('button', 'ghost', 'Back');
    back.addEventListener('click', () => sheet.closest('.backdrop').remove());
    sheet.append(back);
  });
}

function showDetails() {
  const engine = run.engine;
  const s = engine.state;

  overlay('Details', sheet => {
    const lines = [
      'Deck ' + s.deck.length + ' · Hand ' + s.hand.length + ' · Discard ' + s.discard.length,
      'Stage: ' + run.stage.name_en + ' (' + run.stage.stage_id + ')',
      'You: ' + DATA.player.name_en + ', ' + DATA.player.party,
    ];

    if (engine.isPressConference()) {
      const question = engine.currentQuestion();
      lines.push('');
      if (question) lines.push('This question invites a ' + question.prefers_suit + ' answer.');
      lines.push('One card answers one question, and you only draw if a card says so.');
      const pleased = engine.pleasedBoosters();
      lines.push(pleased.length === 0
        ? 'Nobody pleased yet.'
        : 'Pleased so far: ' + pleased.map(boosterNameOf).join(', ') + '.');
    } else {
      const opponent = engine.currentOpponent();
      if (opponent.name) lines.push('Opponent: ' + opponent.name + ', ' + (opponent.party || ''));
    }

    lines.push('');
    lines.push(...roomLines(s));

    if (s.opponent_count > 1) {
      lines.push('');
      if (run.stage.sequence_mode === 'reset') {
        lines.push(s.opponent_count + ' opponents, one at a time. Beat one and everything starts again against the next, including your gaffes.');
      } else {
        lines.push(s.opponent_count + ' debaters, one at a time, and ' + s.bar.threshold
          + ' ' + String(run.stage.bar_unit || 'support').toLowerCase()
          + ' ends the one in front of you — not the stage. Beat them and the house divides again from the start for the next.');
        lines.push('Your record, your hand and the clock carry across all '
          + s.opponent_count + ' of them.');
      }
    }

    if (s.energy_mode === 'pool') {
      lines.push('');
      lines.push('These ' + s.energy_max + ' are for the whole debate. They do not come back at the start of a turn.');
    }
    if (s.win_mode === 'score') {
      lines.push('There is nothing to reach here. However high the support gets is what carries into the floor debate.');
    }

    const carried = run.runner.describeCarriedBuffs(boosterNames(DATA));
    if (!carried.startsWith('Nothing')) { lines.push(''); lines.push(carried); }

    for (const line of lines) {
      sheet.append(line === '' ? el('div', 'gap') : el('p', 'detail-line', line));
    }

    const back = el('button', 'ghost', 'Back');
    back.id = 'details-close';
    back.addEventListener('click', () => sheet.closest('.backdrop').remove());
    sheet.append(back);
  });
}

function showOutcome() {
  const engine = run.engine;
  const s = engine.state;

  let title = { win: 'Carried', loss: 'Defeated', retry: 'No decision' }[s.outcome] || s.outcome;
  if (s.win_mode === 'score' && s.outcome === 'win') title = 'Caucus closed';
  else if (engine.isPressConference() && s.outcome === 'win') title = 'Conference over';

  // A stage whose score carries has to say so here, or the player never finds
  // out: the consequence lands in a stage they have not reached yet.
  const lines = [s.outcome_reason];
  const score = s.playerScore();
  let moved = {};

  if (s.outcome !== 'loss') {
    if (run.runner.scoreIsCarriedFrom(int(run.stage.seq, -1))) {
      const seats = LevelRunner.scoreToSupport(run.stage, score);
      if (seats > 0) lines.push('You start ' + seats + ' ahead at the floor debate.');
      else if (seats < 0) lines.push('You start ' + (-seats) + ' behind at the floor debate.');
    }
    moved = applyScoreEffects(run.meta, run.stage, score, DATA.sanban).applied;
    for (const name of Object.keys(moved)) {
      lines.push(name + ' ' + (moved[name] > 0 ? '+' : '−') + Math.abs(moved[name]) + '.');
    }
  }

  overlay(title, sheet => {
    for (const line of lines) sheet.append(el('p', 'detail-line', line));

    const next = el('button', 'primary', nextStepLabel(s));
    next.id = 'outcome-close';
    next.addEventListener('click', () => {
      sheet.closest('.backdrop').remove();

      const result = applyScoreEffects(run.meta, run.stage, score, DATA.sanban);
      run.meta = result.meta;
      run.lastMetaChange = result.applied;
      pleaseOrganisations(engine.pleasedBoosters());

      run.runner.finishStage(s.outcome, score, engine.pleasedBoosters());
      if (run.runner.isFinished()) {
        run.lastLevelOutcome = run.runner.outcome();
        run.runner = null;
        showOffice();
      } else {
        openStage();
      }
    });
    sheet.append(next);
  }, { noDismiss: true });
}

function nextStepLabel(s) {
  if (s.outcome === 'loss') return 'Back to the Office';
  if (run.runner.index + 1 >= run.runner.stageCount()) return 'Back to the Office';
  return 'On to the next stage';
}

// ---------------------------------------------------------------------------
// The rules check
// ---------------------------------------------------------------------------

function rulesCheckLine() {
  const result = runRuleChecks(DATA);
  const node = el('p', result.failures.length === 0 ? 'rules-check' : 'rules-check failed');

  if (result.failures.length === 0) {
    node.textContent = 'Rules check: ' + result.count + ' of ' + result.count
      + ' agree with the Godot engine.';
    return node;
  }

  node.append(el('strong', null, 'Rules check: ' + result.failures.length + ' of '
    + result.count + ' disagree with the Godot engine.'));
  const list = el('ul', 'problems');
  for (const failure of result.failures) list.append(el('li', null, failure));
  node.append(list);
  return node;
}

showOffice();
