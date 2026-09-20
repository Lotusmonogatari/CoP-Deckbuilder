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
  // Nothing spends this yet — the XP checkpoint is milestone M5 — but it is
  // banked rather than discarded so the checkpoint opens on a real number.
  xp: 0,
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
  start.addEventListener('click', showBriefing);
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

// What the level ahead is worth, before committing to it.
//
// Cameron asked for the STATIC values: what a stage pays flat for being won.
// What a press conference or a caucus produces depends on the number it
// closes on, so those are named as variable rather than forecast.
//
// Every reward in the playtest level is currently zero, and this screen says
// so in words. Four zeroes would read as "this level is worthless"; "not set
// yet" is the truth, and it is Cameron's to set.
function showBriefing() {
  overlay('Before you go in', sheet => {
    let anythingSet = false;

    for (const stage of DATA.playtest_level.stages) {
      sheet.append(el('h2', 'org-tier', stage.name_en));

      const who = opponentsLine(stage);
      if (who !== '') sheet.append(el('p', 'org-boosts', who));

      if (rewardsAreUnset(stage)) {
        sheet.append(el('p', 'org-boosts',
          'What winning this is worth has not been set yet.'));
        continue;
      }

      anythingSet = true;
      const rewards = winRewards(stage);
      for (const name of Object.keys(rewards)) {
        sheet.append(el('p', 'detail-line',
          name + ' ' + (rewards[name] > 0 ? '+' : '\u2212') + Math.abs(rewards[name])));
      }
      const xp = int(stage.xp_reward, 0);
      if (xp > 0) sheet.append(el('p', 'detail-line', xp + ' XP'));
      for (const line of variableRewards(stage)) {
        sheet.append(el('p', 'org-boosts', line));
      }
    }

    if (!anythingSet) {
      sheet.append(el('div', 'gap'));
      sheet.append(el('p', 'detail-line', 'Nothing in this level pays out yet. '
        + 'The slots are in the data waiting for numbers, and the moment they '
        + 'have any, they will land here and on your standing.'));
    }

    // Losing is the same everywhere for now, and saying so is worth a line:
    // the player should know what they are risking.
    sheet.append(el('div', 'gap'));
    sheet.append(el('p', 'org-boosts', 'Lose a stage and you earn nothing from '
      + 'it. Nothing else is taken off you.'));

    const go = el('button', 'primary', 'Go in');
    go.id = 'briefing-go';
    go.addEventListener('click', () => {
      sheet.closest('.backdrop').remove();
      startLevel();
    });
    sheet.append(go);

    const back = el('button', 'ghost', 'Back');
    back.id = 'briefing-back';
    back.addEventListener('click', () => sheet.closest('.backdrop').remove());
    sheet.append(back);
  });
}

// "Against Opponent A, Opponent B and Opponent C" — who is waiting.
function opponentsLine(stage) {
  const names = (stage.opponents || [])
    .map(o => String(o.name || '').trim())
    .filter(n => n !== '');

  if (names.length === 0) {
    return (stage.questions || []).length > 0
      ? 'The reporters ask the questions here.' : '';
  }
  if (names.length === 1) return 'Against ' + names[0];
  return 'Against ' + names.slice(0, -1).join(', ') + ' and ' + names[names.length - 1];
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
  // And theirs. Banked and spent since the last round, never once shown, so
  // the player could only infer it after the fact from "their guard stopped 3".
  if (s.opponent_block > 0) {
    right.append(el('span', 'their-guard', 'They guard ' + s.opponent_block));
  }
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
    // Read BEFORE ending the turn: a finished bout swaps in the next
    // opponent, and the sentence is about the one who just acted.
    const speaker = opponentDisplayName();
    const turn = engine.endTurn();
    drawBattle();

    const lines = [];
    // The pass penalty has always worked; nothing ever said so, which is why
    // a playtest read it as having stopped after the first time.
    if (turn.passed && !engine.state.isOver()) {
      lines.push(engine.isPressConference()
        ? 'You let that one go. The room cools.'
        : 'You said nothing. One less energy this turn.');
    }

    const said = describeOpponentMove(turn.opponent, stage, engine.state, speaker);
    if (said !== '') lines.push(said);

    // A debater finished by the clock or by their own attack rather than by
    // a card — the same news, from the other end of the turn.
    if (turn.bout_won && Object.keys(turn.bout_won).length > 0) {
      lines.push(describeWhatHappened(
        { bout_won: turn.bout_won }, stage, engine.state, speaker));
    }

    if (lines.length > 0) flash(lines.join(' '));
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

  const percent = isPercent(run.stage);
  const amount = (value) => percent ? value + '%' : String(value);

  // Reaching the threshold ends the STAGE only when nobody else is waiting
  // to rise. On the floor it ends one debater of five, and "55 seats to win"
  // read as though the first one finished it.
  const winsStage = !engine.hasMoreOpponents();

  const wrap = el('section', 'bar-wrap');
  let caption;
  if (hasThreshold) {
    caption = amount(bar.threshold) + (percent ? '' : ' ' + unit.toLowerCase())
      + (winsStage ? ' to win' : ' to advance');
  } else if (percent) {
    caption = 'Take as much of the room as you can';
  } else {
    caption = 'Raise ' + unit.toLowerCase() + ' as high as you can';
  }
  wrap.append(el('p', 'bar-caption', caption));

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

  // Whoever holds the other share, by name. The bar used to say "Them" even
  // where the stage data named them. A name long enough to break the row on
  // a phone falls back to its first word, or to "Them".
  // A name too long for the row falls back to "Them" rather than being
  // shortened: taking the first word turned "The Caucus Panel" into "The".
  let other = String(opponentDisplayName() || '').trim();
  if (other === '' || other.length > 18) other = 'Them';

  wrap.append(el('p', 'bar-readout', twoSided
    ? 'You ' + amount(bar.player) + ' · Undecided ' + amount(bar.undecided)
      + ' · ' + other + ' ' + amount(bar.opponent)
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

  // Every card answers the question in front of you, whatever else it does.
  // A draw-1 card was spent in a playtest on the assumption it was free.
  if (effect.answers_question) parts.push('Answers this question.');

  return parts.length > 0 ? parts.join(' ') : (card.effect_text || '');
}

// What a card just did, in the room's own units. The numbers are a budget,
// not an outcome: five points can win five people or three.
// ---------------------------------------------------------------------------
// What just happened, in the room's own terms
// ---------------------------------------------------------------------------
// A faithful port of scripts/ui/BattleNarration.gd. The player's move and the
// opponent's move use the SAME grammar, or the screen reads as two different
// games — and the grammar depends on what the bar is measuring:
//
//   A room of people — the floor, the committee, the caucus. There are seats,
//   and winning one means somebody changed their mind. "3 seats won over."
//
//   A level that rises — the press conference. Nobody to win over; a mood
//   going up and down. "Press tone raised by 3." "3 press tone won over" is
//   what a playtest actually read on screen, and it is nonsense.

// The name of whoever is opposite, for a sentence to use. Empty in a press
// conference: the journalist asking is named in the speaker row, but nobody
// there is an opponent whose support can be taken.
function opponentDisplayName() {
  if (run.engine.isPressConference()) return '';
  return str(run.engine.currentOpponent().name, '');
}

function isARoom(state) {
  if (state.committee) return true;
  if (!state.bar) return false;
  return state.bar.model === SHARED_POOL;
}

// The caucus is already a 0-100 scale, so this is a label rather than any
// kind of conversion: it stops the player counting heads in a body whose
// size changes from one party to the next.
function isPercent(stage) { return !!stage.bar_as_percent; }

function unitNoun(stage, count) {
  if (isPercent(stage)) return '%';
  const unit = String(stage.bar_unit || 'support').toLowerCase();
  return (count === 1 && unit.endsWith('s')) ? unit.slice(0, -1) : unit;
}

function quantity(stage, count) {
  return isPercent(stage) ? count + '%' : count + ' ' + unitNoun(stage, count);
}

function nameOr(name, fallback) {
  const trimmed = String(name || '').trim();
  return trimmed === '' ? fallback : trimmed;
}

function theirs(name) {
  const trimmed = String(name || '').trim();
  return trimmed === '' ? 'their' : trimmed + "'s";
}

function them(name) {
  const trimmed = String(name || '').trim();
  return trimmed === '' ? 'them' : trimmed;
}

// Joins the clauses and closes the sentence, capitalising only the first
// letter so a name inside the clause keeps its own.
function sentence(parts) {
  if (parts.length === 0) return '';
  const line = parts.join(', ');
  return line.charAt(0).toUpperCase() + line.slice(1) + '.';
}

// "2 from the undecided, 1 argued across" — who those people actually were.
// Both halves only matter when there are two: "3 from the undecided" when
// that is all there was adds a clause and no information.
function splitDetail(stage, split, fromWhom) {
  if (!split) return '';
  const undecided = int(split.from_undecided, 0);
  const other = int(split.from_other_side, 0);
  if (other <= 0) return '';
  if (undecided <= 0) return 'all of them off ' + fromWhom;
  return undecided + ' from the undecided, ' + other + ' off ' + fromWhom;
}

function boutWonLine(bout) {
  const who = nameOr(bout.finished, 'That opponent');
  if (int(bout.remaining, 0) <= 0) return who + ' is finished';
  return who + ' is finished \u2014 ' + nameOr(bout.next, 'the next') + ' rises';
}

function gainedLine(stage, state, applied, wanted, won, sayShortfall, opponentName) {
  // A level that rises has nobody to win over: it goes up, and by how much.
  if (!isARoom(state)) {
    const unit = String(stage.bar_unit || 'support');
    return won > 0 ? unit + ' raised by ' + won : unit + ' did not move';
  }

  let line = quantity(stage, won) + ' won over';

  const detail = splitDetail(stage, applied.gain_split, them(opponentName));
  if (detail !== '') line += ' \u2014 ' + detail;

  // The leftover. Points that cannot pay for the next person are LOST rather
  // than banked, so "nearly persuaded" would promise progress that does not
  // exist. Suppressed when the card finished a debater: the win is the news,
  // and a shortfall beside it is what made this line unreadable.
  const short = wanted - won;
  if (sayShortfall && short > 0 && won < wanted) {
    line += ', ' + short + (short === 1 ? ' point' : ' points') + ' short of the next';
  }
  return line;
}

function describeWhatHappened(result, stage, state, opponentName) {
  const applied = result.applied || {};
  const effect = result.effect || {};
  const parts = [];

  // A finished debater comes FIRST.
  const bout = result.bout_won;
  const hasBout = bout && Object.keys(bout).length > 0;
  if (hasBout) parts.push(boutWonLine(bout));

  const wanted = int(effect.self_plus, 0);
  const won = int(applied.gained, 0);
  if (wanted > 0) {
    parts.push(gainedLine(stage, state, applied, wanted, won, !hasBout, opponentName));
  }

  const stopped = int(applied.guard_stopped, 0);
  if (stopped > 0) parts.push(theirs(opponentName) + ' guard stopped ' + stopped);

  const lost = int(applied.opponent_lost, 0);
  if (lost > 0) parts.push(quantity(stage, lost) + ' argued away from ' + them(opponentName));

  const gaffe = int(applied.gaffe, 0);
  if (gaffe > 0) parts.push(gaffe + ' gaffe' + (gaffe === 1 ? '' : 's') + ' on your record');

  return sentence(parts);
}

// What the opponent's move just did. The engine has always computed this and
// thrown it away, so guard built, seats taken and panel members leaned on all
// happened in complete silence.
function describeOpponentMove(opponentResult, stage, state, opponentName) {
  if (!opponentResult || Object.keys(opponentResult).length === 0) return '';

  const who = nameOr(opponentName, 'They');
  const parts = [];

  switch (str(opponentResult.verb, 'none')) {
    case 'attack': {
      const absorbed = int(opponentResult.absorbed, 0);
      const damage = int(opponentResult.damage, 0);
      if (absorbed > 0) parts.push('your guard absorbed ' + absorbed);
      // Not "lost to Ito": the sentence already opens with their name, so
      // repeating it reads as two different people.
      if (damage > 0) parts.push(quantity(stage, damage) + ' taken from you');
      else if (absorbed > 0) parts.push('nothing got through');
      else parts.push('the attack found nothing to take');
      break;
    }
    case 'gain': {
      const gained = int(opponentResult.gained, 0);
      if (gained <= 0) return who + ' pressed the case and won nobody over.';
      parts.push('won over ' + quantity(stage, gained));
      const detail = splitDetail(stage, opponentResult.gain_split, 'you');
      if (detail !== '') parts.push(detail);
      break;
    }
    case 'block': {
      const guard = int(opponentResult.guard, 0);
      if (guard <= 0) return who + ' could not guard any further.';
      parts.push('developed ' + guard + ' guard');
      break;
    }
    case 'lean_down': {
      const member = opponentResult.member || {};
      const moved = Math.abs(int(member.moved, 0));
      if (moved <= 0) return who + ' leaned on the panel and moved nobody.';
      parts.push('leaned on ' + str(member.name, 'a member') + ', ' + moved + ' against you');
      break;
    }
    default:
      return who + ' waited.';
  }

  // Joined directly rather than through sentence(): capitalising and then
  // lowercasing back would also flatten any name inside the clause.
  return who + ': ' + parts.join(', ') + '.';
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
      const who = opponentDisplayName();
      const result = run.engine.playCard(card.card_id);
      drawBattle();
      flash(describeWhatHappened(result, run.stage, run.engine.state, who));
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
      // The figure above matches the pips because both read energy_max — but
      // it is the number still LEFT that changes, and that was never shown.
      lines.push(s.energy + ' of them left.');
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
  // "Carried" on its own is a word, not an ending. The last stage of a level
  // is the bill being adopted, and it should read like it.
  const lastStage = run.runner.index + 1 >= run.runner.stageCount();
  const headline = (s.outcome === 'win' && lastStage)
    ? 'You convinced Parliament and your bill was adopted.' : '';

  const lines = [s.outcome_reason];
  const score = s.playerScore();

  if (s.outcome !== 'loss') {
    if (run.runner.scoreIsCarriedFrom(int(run.stage.seq, -1))) {
      const seats = LevelRunner.scoreToSupport(run.stage, score);
      if (seats > 0) lines.push('You start ' + seats + ' ahead at the floor debate.');
      else if (seats < 0) lines.push('You start ' + (-seats) + ' behind at the floor debate.');
    }

    // What the stage was worth: flat for winning, and again for the number
    // it closed on. Totalled, so a variable moved twice reports once.
    const moved = {};
    const flat = applyWinDeltas(run.meta, run.stage, DATA.sanban).applied;
    for (const name of Object.keys(flat)) {
      moved[name] = int(moved[name], 0) + flat[name];
    }
    const scored = applyScoreEffects(run.meta, run.stage, score, DATA.sanban).applied;
    for (const name of Object.keys(scored)) {
      moved[name] = int(moved[name], 0) + scored[name];
    }

    const changes = [];
    for (const name of Object.keys(moved)) {
      if (moved[name] !== 0) {
        changes.push(name + ' ' + (moved[name] > 0 ? '+' : '\u2212') + Math.abs(moved[name]));
      }
    }
    const xp = int(run.stage.xp_reward, 0);
    if (xp > 0) changes.push(xp + ' XP');

    // Which organisations the answers pleased. The Office shows the result,
    // but the connection between an answer and a standing is lost by then.
    const pleased = engine.pleasedBoosters();
    if (pleased.length > 0) {
      const names = boosterNames(DATA);
      lines.push('');
      lines.push('Pleased: ' + pleased.map(id => names[id] || id).join(', ') + '.');
    }

    if (changes.length > 0) {
      lines.push('');
      lines.push(changes.join(', ') + '.');
    } else if (s.outcome === 'win' && rewardsAreUnset(run.stage)) {
      // The truth, rather than silence that reads as a bug.
      lines.push('');
      lines.push('This stage has no rewards set yet.');
    }
  }

  overlay(title, sheet => {
    if (headline !== '') sheet.append(el('h2', 'sheet-title', headline));
    for (const line of lines) {
      sheet.append(line === '' ? el('div', 'gap') : el('p', 'detail-line', line));
    }

    const next = el('button', 'primary', nextStepLabel(s));
    next.id = 'outcome-close';
    next.addEventListener('click', () => {
      sheet.closest('.backdrop').remove();

      // Losing a stage earns nothing. Both halves stack, and the change the
      // Office reports is the total.
      run.lastMetaChange = {};
      if (s.outcome === WON) {
        const won = applyWinDeltas(run.meta, run.stage, DATA.sanban);
        run.meta = won.meta;
        for (const name of Object.keys(won.applied)) {
          run.lastMetaChange[name] = int(run.lastMetaChange[name], 0) + won.applied[name];
        }
        run.xp = int(run.xp, 0) + int(run.stage.xp_reward, 0);
      }
      const result = applyScoreEffects(run.meta, run.stage, score, DATA.sanban);
      run.meta = result.meta;
      for (const name of Object.keys(result.applied)) {
        run.lastMetaChange[name] = int(run.lastMetaChange[name], 0) + result.applied[name];
      }
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
