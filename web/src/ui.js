// The screens: the Office, a battle, and the three overlays.
//
// Mirrors scripts/ui/ — same information in the same order, following
// CLAUDE.md §10: stage name with a muted Japanese accent, then who is
// speaking, then the win condition, then energy and gaffes, then the hand,
// then one full-width button.

'use strict';

const DATA = window.COP_DATA;

// PLAYTEST SETTING, mirroring GameState.open_collection in the Godot build.
// See where ownedCards is built, below, for what it is for.
const OPEN_COLLECTION = true;

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
  // What you own and what you are taking in. The deck is a fixed size, so
  // unlocking a card means leaving another out.
  //
  // OPEN_COLLECTION is a playtest setting, matching GameState.open_collection
  // in the Godot build: true hands you every card in the workbook from the
  // first moment. Cameron asked for the XP and Yen economy to be left aside
  // while he prices it by playing, and an unreachable card cannot be
  // playtested. Set it false and the collection starts at the opening tier
  // again; nothing else changes, because the Ledger still refuses anything
  // unaffordable.
  ownedCards: DATA.cards
    .filter(c => OPEN_COLLECTION || str(c.tier, '') === OPENING_TIER)
    .map(c => c.card_id),
  deck: openingDeck(DATA.cards, DATA.balance || {}),
  ownedModifiers: [],
  // The level picked in the Office, and the one a briefing describes.
  chosenLevel: null,
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
  standing.append(el('h2', 'label', T('office.where_you_stand')));
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

  const start = el('button', 'primary', T('office.choose_level'));
  start.id = 'start-level';
  start.addEventListener('click', showLevels);
  root.append(start);

  // Everything you can SPEND now lives behind one door. A playtest reported
  // not being able to find the XP and Funds stores at all, because they sat
  // as a quiet line of text above three buttons that looked alike and none
  // of which said which currency it wanted.
  //
  // What stays out here is the warning: a deck that is not legal cannot
  // start a level, and a player must not have to open a panel to find out.
  const deckSay = deckRefusal(run.deck, run.ownedCards, DATA.balance || {}, phrase(STRINGS));
  const spend = el('p', 'office-report', deckSay
    ? T('office.deck_warning', {reason: deckSay})
    : T('office.in_order'));
  root.append(spend);

  const management = el('button', 'ghost', T('office.management'));
  management.id = 'office-management';
  management.addEventListener('click', showManagement);
  root.append(management);

  // Who is behind you, and how far. Secondary, so it lives behind a button.
  const orgs = el('button', 'ghost', T('office.organisations'));
  orgs.id = 'organisations';
  orgs.addEventListener('click', showOrganisations);
  root.append(orgs);

  root.append(rulesCheckLine());
}

function lastLevelReport() {
  if (!run.lastLevelOutcome) return T('office.report.none');
  if (run.lastLevelOutcome === WON) return T('office.report.won');
  return T('office.report.lost');
}

// Everything there is to spend, and everything to spend it on.
//
// One door rather than three side by side, and it leads with the two
// currencies and what each of them buys. Knowing you have 30 Funds is no use
// if nothing says that Funds are what backing costs. Mirrors
// OfficeScreen._show_management.
function showManagement() {
  overlay(T('office.management'), sheet => {
    const money = [
      ['XP ' + run.xp, T('office.xp_buys')],
      ['Funds ' + int(run.meta.Funds, 0),
        T('office.funds_buys')],
    ];
    for (const [heading, note] of money) {
      sheet.append(el('h2', 'org-tier', heading));
      sheet.append(el('p', 'org-boosts', note));
    }

    const refusal = deckRefusal(run.deck, run.ownedCards, DATA.balance || {}, phrase(STRINGS));
    sheet.append(el('h2', 'org-tier',
      'Deck ' + run.deck.length + ' of ' + deckSize(DATA.balance || {})));
    sheet.append(el('p', 'org-boosts', refusal || T('office.deck_ready')));

    for (const [label, id, handler] of [
      [T('office.new_cards'), 'new-cards', showCardShop],
      [T('office.your_deck'), 'your-deck', showDeckScreen],
      [T('office.backing'), 'backing', showBackingShop],
    ]) {
      const button = el('button', 'ghost', label);
      button.id = id;
      button.addEventListener('click', () => {
        sheet.closest('.backdrop').remove();
        handler();
      });
      sheet.append(button);
    }
  });
}

// Which level to play. Six of them now, grouped by tier.
//
// Tier 1 and 2 are bought with XP in the finished game; while Cameron prices
// the economy by playing, every level is simply open. Mirrors
// OfficeScreen._show_levels.
function showLevels() {
  overlay('Levels', sheet => {
    sheet.append(el('p', 'detail-line', 'Each level is a run of stages. Pick '
      + 'one and you will see what it holds before you commit.'));

    const byTier = {};
    for (const level of DATA.levels) {
      const tier = int(level.tier, 0);
      (byTier[tier] = byTier[tier] || []).push(level);
    }

    for (const tier of [0, 1, 2]) {
      if (!byTier[tier]) continue;
      sheet.append(el('h2', 'org-tier', 'Tier ' + tier));
      for (const level of byTier[tier]) sheet.append(levelRow(level, sheet));
    }
  });
}

function levelRow(level, sheet) {
  const box = el('div', 'level-row');
  const count = (level.stages || []).length;

  box.append(el('p', 'detail-line',
    str(level.name_en, '') + '  ' + str(level.name_jp, '')));
  box.append(el('p', 'org-boosts',
    count + ' stage' + (count === 1 ? '' : 's') + '  ·  ' + str(level.blurb, '')));

  const button = el('button', 'ghost', 'Look it over');
  button.className = 'ghost level-pick';
  button.addEventListener('click', () => {
    run.chosenLevel = level;
    sheet.closest('.backdrop').remove();
    showBriefing();
  });
  box.append(button);
  return box;
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
  const level = run.chosenLevel;
  if (!level) { showLevels(); return; }

  overlay(level.name_en, sheet => {
    let anythingSet = false;

    for (const stage of level.stages) {
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
        sheet.append(el('p', 'detail-line', T('reward.delta', {
          name: name,
          amount: (rewards[name] > 0 ? '+' : '\u2212') + Math.abs(rewards[name]),
        })));
      }
      const xp = int(stage.xp_reward, 0);
      if (xp > 0) sheet.append(el('p', 'detail-line', T('outcome.xp', { count: xp })));
      for (const line of variableRewards(stage, phrase(STRINGS))) {
        sheet.append(el('p', 'org-boosts', line));
      }
    }

    if (!anythingSet) {
      sheet.append(el('div', 'gap'));
      sheet.append(el('p', 'detail-line', T('reward.nothing_set')));
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

    const back = el('button', 'ghost', 'Pick another');
    back.id = 'briefing-back';
    back.addEventListener('click', () => {
      sheet.closest('.backdrop').remove();
      showLevels();
    });
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
  run.runner = new LevelRunner(run.chosenLevel);
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
  overlay(T('office.organisations'), sheet => {
    sheet.append(el('p', 'detail-line', T('office.orgs_blurb')));

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

// ---------------------------------------------------------------------------
// Spending what a run has earned
// ---------------------------------------------------------------------------
// Three screens, one shape: a list of things, each with its price and either
// a button to buy it or the reason you cannot. Every one of those answers
// comes from the ledger in engine.js, so a screen can never offer what the
// rules would refuse.

function showCardShop() {
  overlay(T('office.new_cards'), sheet => {
    sheet.append(el('p', 'detail-line', T('office.cards_blurb')));
    sheet.append(el('h3', 'org-tier', 'XP ' + run.xp));

    for (const tier of ['Tier 1', 'Tier 2']) {
      const inTier = DATA.cards.filter(c => c.tier === tier);
      if (inTier.length === 0) continue;
      sheet.append(el('h3', 'org-tier', tier));

      for (const card of inTier) {
        const row = el('div', 'org');
        row.append(el('p', 'org-name', card.name_en + '  —  ' + cardCost(card) + ' XP'));
        row.append(el('p', 'org-boosts', card.suit + '  ·  ' + (card.effect_text || '')));

        const refusal = cardRefusal(card, run.ownedCards, run.xp, phrase(STRINGS));
        const buy = el('button', refusal ? 'ghost' : 'primary', refusal || T('office.unlock'));
        buy.disabled = !!refusal;
        if (!refusal) {
          buy.addEventListener('click', () => {
            run.xp -= cardCost(card);
            run.ownedCards.push(card.card_id);
            sheet.closest('.backdrop').remove();
            showOffice();
            showCardShop();
          });
        }
        row.append(buy);
        sheet.append(row);
      }
    }

    const back = el('button', 'ghost', 'Back');
    back.id = 'cards-close';
    back.addEventListener('click', () => sheet.closest('.backdrop').remove());
    sheet.append(back);
  });
}

// A fixed size, so unlocking a card means leaving another out. Without that
// constraint an unlock would be a free upgrade and this screen would have
// nothing to decide.
function showDeckScreen() {
  let draft = run.deck.slice();

  const build = () => {
    document.querySelectorAll('.backdrop').forEach(n => n.remove());
    overlay(T('office.your_deck'), sheet => {
      const refusal = deckRefusal(draft, run.ownedCards, DATA.balance || {}, phrase(STRINGS));
      sheet.append(el('h3', 'org-tier', draft.length + ' of '
        + deckSize(DATA.balance || {}) + ' chosen' + (refusal ? '  —  ' + refusal : '')));
      sheet.append(el('p', 'detail-line', T('office.deck_tap')));

      for (const cardId of run.ownedCards) {
        const card = DATA.cards.find(c => c.card_id === cardId);
        if (!card) continue;
        const chosen = draft.includes(cardId);

        const row = el('div', 'org');
        if (!chosen) row.style.opacity = '0.5';

        // The cost goes first, because that is what the choice turns on: a
        // deck of twelve threes cannot be played three energy at a time.
        //
        // The PRINTED cost, not what a battle would charge. There is no
        // battle here, so no discount applies and there is no engine to ask.
        //
        // The name on the button and the effect beneath it: both on the
        // button ran a long card off the side of the screen.
        const toggle = el('button', 'ghost',
          (chosen ? '✓  ' : '–  ') + int(card.cost, 0) + '  ' + card.name_en);
        toggle.addEventListener('click', () => {
          draft = chosen ? draft.filter(id => id !== cardId) : draft.concat([cardId]);
          build();
        });
        row.append(toggle);
        row.append(el('p', 'org-boosts', card.effect_text || ''));
        sheet.append(row);
      }

      if (!refusal) {
        const save = el('button', 'primary', T('office.deck_confirm'));
        save.id = 'deck-save';
        save.addEventListener('click', () => {
          run.deck = draft.slice();
          sheet.closest('.backdrop').remove();
          showOffice();
        });
        sheet.append(save);
      }

      const back = el('button', 'ghost', 'Back');
      back.id = 'deck-close';
      back.addEventListener('click', () => sheet.closest('.backdrop').remove());
      sheet.append(back);
    });
  };

  build();
}

// An organisation will not sell you its backing until you have given it
// reason to — the first thing standing has ever done.
function showBackingShop() {
  overlay(T('office.backing'), sheet => {
    sheet.append(el('p', 'detail-line', T('office.backing_blurb')));
    sheet.append(el('h3', 'org-tier', 'Funds ' + int(run.meta.Funds, 0)));

    const names = boosterNames(DATA);
    const ids = DATA.boosters.map(b => b.booster_id);
    const settings = DATA.booster_standing || {};
    const bridge = DATA.modifier_effects || {};

    for (const modifier of DATA.modifiers.filter(isForSale)) {
      const row = el('div', 'org');
      row.append(el('p', 'org-name',
        modifier.name_en + '  —  ' + modifierCost(modifier) + ' funds'));

      const booster = backingBooster(modifier, ids);
      if (booster) {
        const have = int(run.boosterStanding[booster], 0);
        const needed = standingNeeded(modifier, settings);
        row.append(el('p', 'org-boosts', (names[booster] || booster)
          + (have >= needed ? '  ·  standing ' + have
                            : '  ·  standing ' + have + ', needs ' + needed)));
      }
      row.append(el('p', 'org-boosts', describeEffect(modifier, bridge, phrase(STRINGS))));

      // A shop that sells something inert is the trap this project has
      // walked into twice.
      if (effectIsInertToday(modifier, bridge)) {
        row.append(el('p', 'org-boosts', T('office.no_effect_yet')));
      } else if (!effectIsImplemented(modifier, bridge)) {
        row.append(el('p', 'org-boosts',
          T('office.not_active_yet')));
      }

      const refusal = modifierRefusal(modifier, run.ownedModifiers,
        int(run.meta.Funds, 0), run.boosterStanding, settings, ids, phrase(STRINGS));
      const buy = el('button', refusal ? 'ghost' : 'primary',
        refusal || T('office.take_backing'));
      buy.disabled = !!refusal;
      if (!refusal) {
        buy.addEventListener('click', () => {
          // Clamped, like the stage payout below and like GameState._move_meta
          // in the Godot build. The Ledger has already refused anything
          // unaffordable, so this cannot bite today — but it was the one place
          // a standing could leave the range sanban.json gives it, and the two
          // builds should not disagree about their own money.
          const fundsRow = DATA.sanban.find(v => v.name_en === 'Funds') || {};
          run.meta.Funds = clampMeta(
            int(run.meta.Funds, 0) - modifierCost(modifier), fundsRow);
          run.ownedModifiers.push(modifier.mod_id);
          sheet.closest('.backdrop').remove();
          showOffice();
          showBackingShop();
        });
      }
      row.append(buy);
      sheet.append(row);
    }

    const back = el('button', 'ghost', 'Back');
    back.id = 'backing-close';
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
    Math.floor(Math.random() * 0x7fffffff),
    { deck: run.deck, modifiers: run.ownedModifiers }));

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
  right.append(el('span', 'guarding',
    T('battle.your_guard', { count: s.block, cap: s.guard_cap })));
  // And theirs. Banked and spent since the last round, never once shown, so
  // the player could only infer it after the fact from "their guard stopped 3".
  if (s.opponent_block > 0) {
    right.append(el('span', 'their-guard',
      T('battle.their_guard', { count: s.opponent_block, cap: s.guard_cap })));
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
        ? T('battle.declined')
        : T('battle.passed'));
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
    text.append(el('p', 'says',
      question ? question.text : T('battle.last_question')));
    row.append(text);
    return row;
  }

  const opponent = engine.currentOpponent();
  const caption = engine.opponentCaption();
  row.append(placeholderArt(String(opponent.opp_id || ''), '64px'));
  text.append(el('h2', null, caption
    ? T('battle.who_and_caption', { who: opponent.name || 'Visitor A', caption: caption })
    : (opponent.name || 'Visitor A')));
  text.append(el('p', 'says',
    IntentRunner.describe(engine.currentIntent(), phrase(STRINGS))));
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
    caption = T(winsStage ? 'bar.to_win' : 'bar.to_advance', {
      amount: amount(bar.threshold) + (percent ? '' : ' ' + unit.toLowerCase()),
    });
  } else if (percent) {
    caption = T('bar.take_the_room');
  } else {
    caption = T('bar.raise_as_high', { unit: unit.toLowerCase() });
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
  if (other === '' || other.length > 18) other = T('bar.them');

  wrap.append(el('p', 'bar-readout', twoSided
    ? T('bar.two_sided', {
        you: amount(bar.player),
        undecided: amount(bar.undecided),
        them: other,
        theirs: amount(bar.opponent),
      })
    : T('bar.one_sided', { unit: unit, count: bar.player, total: bar.maximum })));
  return wrap;
}

// Tapping a card opens it rather than playing it, so a mis-tap never costs a
// turn.
function cardFace(card, s) {
  const face = el('button', 'card');
  face.dataset.cardId = card.card_id;
  face.classList.add('suit-' + card.suit.toLowerCase().replace(/\s+/g, '-'));
  if (run.engine.cardCost(card) > s.energy) face.classList.add('unaffordable');

  // What it will do HERE, not what it says on paper. The room moves the
  // numbers, and in some rooms a number does nothing at all.
  const effect = run.engine.preview(card);
  if (effect.does_nothing) face.classList.add('useless');

  // The plate goes UNDER the frame: the picture window is a hole in an
  // otherwise opaque PNG, so anything laid beneath shows through exactly the
  // hole and cannot spill over the border the artwork draws around it.
  face.append(el('span', 'card-plate'));
  face.append(el('span', 'card-frame'));
  // And the cost disc goes OVER it, because that hole is the game's to fill.
  face.append(el('span', 'card-cost', String(run.engine.cardCost(card))));
  face.append(el('span', 'card-name', card.name_en));
  if (card.name_jp) face.append(el('span', 'card-jp', card.name_jp));
  face.append(el('span', 'card-text', effectHere(effect, card)));

  face.addEventListener('click', () => showCardZoom(card));
  return face;
}

// A card turned over: the same frame's back, with everything the front had
// no room for written on its ruled paper.
//
// Mirrors scripts/ui/CardBackView.gd. The line height is set in CSS to one
// rule exactly, so every line lands between two of them — text that does not
// know where the rules are sits ON them and reads as a mistake.
function cardBack(card, here, room) {
  const box = el('div', 'card-back');
  box.append(el('span', 'card-frame'));

  const text = el('p', 'card-back-text');
  const line = (html) => { const n = el('span'); n.innerHTML = html; text.append(n, el('br')); };
  const safe = (value) => String(value === undefined || value === null ? '' : value)
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

  line('<b>' + safe(card.name_en) + '</b>');
  if (card.name_jp) {
    line('<span class="faint">' + safe(card.name_jp) + '  ' + safe(card.romaji) + '</span>');
  }
  line(safe(T('card.line', {
    suit: card.suit, type: card.type, cost: run.engine.cardCost(card),
  })));
  line(safe(card.effect_text));
  if (here && here !== String(card.effect_text || '')) {
    line(safe(T('card.in_this_room', { effect: here })));
  }
  if (room) line('<span class="faint">' + safe(room) + '</span>');

  box.append(text);

  // The suit class paints nothing now that the colour strip is gone. It
  // stays because it is the hook a per-suit card template will need.
  box.classList.add('suit-' + String(card.suit).toLowerCase().replace(/\s+/g, '-'));
  return box;
}

// A card's numbers as this room will actually use them. Showing the printed
// value and then quietly doing something else is how a player stops trusting
// the screen.
function effectHere(effect, card) {
  const parts = [];
  if (effect.self_plus) parts.push(T('card.gain', { count: effect.self_plus }));
  if (effect.opp_minus && effect.opp_minus_counts) {
    parts.push(T('card.opponent', { count: effect.opp_minus }));
  }
  if (effect.guard && effect.guard_counts) parts.push(T('card.guard', { count: effect.guard }));
  if (effect.draw) parts.push(T('card.draw', { count: effect.draw }));
  if (effect.gaffe) {
    parts.push(T('card.gaffe',
      { amount: (effect.gaffe > 0 ? '+' : '') + effect.gaffe }));
  }

  if (effect.does_nothing) parts.push(T('card.does_nothing'));

  // Every card answers the question in front of you, whatever else it does.
  // A draw-1 card was spent in a playtest on the assumption it was free.
  if (effect.answers_question) parts.push(T('card.answers_question'));

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
  return trimmed === '' ? T('narration.their_generic')
                        : T('narration.their_named', {name: trimmed});
}

function them(name) {
  const trimmed = String(name || '').trim();
  return trimmed === '' ? T('narration.them_generic') : trimmed;
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
  if (undecided <= 0) return T('narration.all_off', {whom: fromWhom});
  return T('narration.split', {undecided: undecided, count: other, whom: fromWhom});
}

function boutWonLine(bout) {
  const who = nameOr(bout.finished, T('narration.that_opponent'));
  if (int(bout.remaining, 0) <= 0) return T('narration.bout_finished', {who: who});
  return who + ' is finished \u2014 ' + nameOr(bout.next, T('narration.the_next')) + ' rises';
}

function gainedLine(stage, state, applied, wanted, won, sayShortfall, opponentName) {
  // A level that rises has nobody to win over: it goes up, and by how much.
  if (!isARoom(state)) {
    const unit = String(stage.bar_unit || 'support');
    return won > 0 ? T('narration.raised', {unit: unit, count: won}) : T('narration.unmoved', {unit: unit});
  }

  let line = T('narration.won_over', {amount: quantity(stage, won)});

  const detail = splitDetail(stage, applied.gain_split, them(opponentName));
  if (detail !== '') line += ' \u2014 ' + detail;

  // The leftover. Points that cannot pay for the next person are LOST rather
  // than banked, so "nearly persuaded" would promise progress that does not
  // exist. Suppressed when the card finished a debater: the win is the news,
  // and a shortfall beside it is what made this line unreadable.
  const short = wanted - won;
  if (sayShortfall && short > 0 && won < wanted) {
    line += T('narration.short', {count: short});
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
  if (stopped > 0) parts.push(T('narration.guard_stopped', {who: theirs(opponentName), count: stopped}));

  const lost = int(applied.opponent_lost, 0);
  if (lost > 0) parts.push(T('narration.argued_away', {amount: quantity(stage, lost), whom: them(opponentName)}));

  const gaffe = int(applied.gaffe, 0);
  if (gaffe > 0) parts.push(T('narration.gaffe', {count: gaffe}));

  return sentence(parts);
}

// What the opponent's move just did. The engine has always computed this and
// thrown it away, so guard built, seats taken and panel members leaned on all
// happened in complete silence.
function describeOpponentMove(opponentResult, stage, state, opponentName) {
  if (!opponentResult || Object.keys(opponentResult).length === 0) return '';

  const who = nameOr(opponentName, T('narration.they'));
  const parts = [];

  switch (str(opponentResult.verb, 'none')) {
    case 'attack': {
      const absorbed = int(opponentResult.absorbed, 0);
      const damage = int(opponentResult.damage, 0);
      if (absorbed > 0) parts.push(T('narration.absorbed', {count: absorbed}));
      // Not "lost to Ito": the sentence already opens with their name, so
      // repeating it reads as two different people.
      if (damage > 0) parts.push(T('narration.taken', {amount: quantity(stage, damage)}));
      else if (absorbed > 0) parts.push(T('narration.nothing_through'));
      else parts.push(T('narration.nothing_to_take'));
      break;
    }
    case 'gain': {
      const gained = int(opponentResult.gained, 0);
      if (gained <= 0) return T('narration.gain_none', {who: who});
      parts.push(T('narration.won_over_them', {amount: quantity(stage, gained)}));
      const detail = splitDetail(stage, opponentResult.gain_split, 'you');
      if (detail !== '') parts.push(detail);
      break;
    }
    case 'block': {
      const guard = int(opponentResult.guard, 0);
      if (guard <= 0) return T('narration.block_none', {who: who});
      parts.push(T('narration.guard_built', {count: guard}));
      break;
    }
    case 'lean_down': {
      const member = opponentResult.member || {};
      const moved = Math.abs(int(member.moved, 0));
      if (moved <= 0) return T('narration.lean_none', {who: who});
      parts.push('leaned on ' + str(member.name, T('narration.a_member')) + ', ' + moved + ' against you');
      break;
    }
    default:
      return T('narration.waited', {who: who});
  }

  // Joined directly rather than through sentence(): capitalising and then
  // lowercasing back would also flatten any name inside the clause.
  return T('narration.sentence', {who: who, clauses: parts.join(', ')});
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
    sheet.append(cardBack(card, effectHere(run.engine.preview(card), card),
      describeRoomFor(affinity)));

    const play = el('button', 'primary', 'Play');
    play.id = 'zoom-play';
    play.disabled = run.engine.cardCost(card) > s.energy || s.isOver();
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

// How a room works, in plain sentences. Ported from scripts/ui/StageBrief.gd
// — keep the two in step.
//
// THE POINT IS THAT IT STATES THE DEFAULT. A policy study refills energy at
// the end of the turn, like almost every stage, and asks two questions a turn
// rather than one. Neither was written down anywhere, so energy looked finite
// to the player: they spent it, saw it not come back, and had no way to learn
// that ending the turn is what refills it.
//
// Built from the RESOLVED stage, so every number is the one the battle is
// actually running on. `state` may be null, for a stage described before
// there is a battle.
function howThisRoomWorks(stage, state) {
  const bullet = (labelKey, detail) =>
    T('brief.bullet', {label: T(labelKey), detail: detail});
  const lines = [T('brief.heading')];

  lines.push(bullet('brief.label.turns', briefTurns(stage)));
  lines.push(bullet('brief.label.energy', briefEnergy(stage, state)));

  const questions = stage.questions || [];
  if (questions.length > 0) {
    lines.push(bullet('brief.label.questions', briefQuestions(stage, questions.length)));
  }

  lines.push(bullet('brief.label.gaffes', briefGaffes(stage)));
  lines.push(bullet('brief.label.guard', briefGuard(state)));
  lines.push(bullet('brief.label.hand', briefHand(stage)));
  lines.push(bullet('brief.label.winning', briefWinning(stage)));

  const decay = int(stage.affinity_decay, 0);
  if (decay > 0) {
    lines.push(bullet('brief.label.decay', T('brief.decay', {count: decay})));
  }
  return lines;
}

function briefTurns(stage) {
  const limit = int(stage.turn_limit, 0);
  if (limit <= 0) return T('brief.turns.none');
  return T('brief.turns.limit', {count: limit});
}

function briefEnergy(stage, state) {
  if (str(stage.energy_mode, 'per_turn') === 'pool') {
    const left = state ? T('brief.energy.left', {count: state.energy}) : '';
    return T('brief.energy.pool', {count: int(stage.energy_pool, 0), left: left});
  }
  // The sentence that prompted all of this: "when you end the turn" is the
  // step the player could not see.
  return T('brief.energy.per_turn', {count: int(stage.energy_per_turn, 3)});
}

function briefQuestions(stage, total) {
  const perTurn = Math.max(int(stage.questions_per_turn, 1), 1);
  let sentence = perTurn === 1
    ? T('brief.questions.one_a_turn', {total: total})
    : T('brief.questions.several', {per_turn: perTurn, total: total});

  sentence += T('brief.questions.decline');
  if (bool(stage.decline_ends_stage, false)) {
    return sentence + T('brief.questions.ends_stage');
  }
  const cost = int(stage.decline_tone_cost, 3);
  return cost > 0
    ? sentence + T('brief.questions.costs', {count: cost})
    : sentence + T('brief.questions.free');
}

function briefGaffes(stage) {
  const limit = int(stage.gaffe_limit, 5);
  const multiplier = Math.max(int(stage.gaffe_multiplier, 1), 1);
  if (multiplier > 1) {
    return T('brief.gaffes.multiplied', {count: limit, multiplier: multiplier});
  }
  return T('brief.gaffes.plain', {count: limit});
}

function briefGuard(state) {
  const cap = state ? state.guard_cap : 5;
  return T('brief.guard', {count: cap});
}

function briefHand(stage) {
  if (str(stage.draw_mode, 'refill') === 'none') {
    return T('brief.hand.none', {count: int(stage.opening_hand, 8)});
  }
  return T('brief.hand.refill', {count: int(stage.hand_size, 5)});
}

function briefWinning(stage) {
  if (str(stage.win_mode, 'threshold') === 'score') {
    return T('brief.winning.score');
  }

  const threshold = int(stage.win_threshold, 0);
  const unit = str(stage.bar_unit, 'support').toLowerCase();
  if (threshold <= 0) return T('brief.winning.hold');

  const where = {count: threshold, unit: unit};
  switch (str(stage.sequence_mode, 'single')) {
    case 'reset':      return T('brief.winning.reset', where);
    case 'continuous': return T('brief.winning.continuous', where);
    case 'stream':     return T('brief.winning.stream', where);
    default:           return T('brief.winning.single', where);
  }
}

function showDetails() {
  const engine = run.engine;
  const s = engine.state;

  overlay('Details', sheet => {
    // The room's own rules come first, defaults included.
    const lines = howThisRoomWorks(run.stage, s).concat(['',
      'Deck ' + s.deck.length + ' · Hand ' + s.hand.length + ' · Discard ' + s.discard.length,
      'Stage: ' + run.stage.name_en + ' (' + run.stage.stage_id + ')',
      'You: ' + DATA.player.name_en + ', ' + DATA.player.party,
    ]);

    if (engine.isPressConference()) {
      const question = engine.currentQuestion();
      lines.push('');
      if (question) lines.push('This question invites a ' + question.prefers_suit + ' answer.');
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

    // How many there are to get through. How they follow one another is a
    // row in the table above, so only the count belongs here.
    if (s.opponent_count > 1) {
      lines.push('');
      lines.push(T('battle.one_at_a_time',
        { count: s.opponent_count, number: s.opponent_index + 1 }));
    }

    // Asked, not sniffed. This used to test whether the sentence began with
    // "Nothing", so rewording that line would have silently hidden the block.
    if (run.runner.anythingCarried()) {
      lines.push('');
      lines.push(run.runner.describeCarriedBuffs(boosterNames(DATA), phrase(STRINGS)));
    }

    for (const line of lines) {
      sheet.append(line === '' ? el('div', 'gap') : el('p', 'detail-line', line));
    }

    const back = el('button', 'ghost', 'Back');
    back.id = 'details-close';
    back.addEventListener('click', () => sheet.closest('.backdrop').remove());
    sheet.append(back);
  });
}

// ---------------------------------------------------------------------------
// What the game says
// ---------------------------------------------------------------------------
// The same table the Godot build reads: the Text tab of the design workbook,
// exported to data/strings.json. Cameron rewords a line there and it changes
// in BOTH builds, because both look it up rather than each holding a copy.
//
// Plurals are two rows, key.one and key.other, picked by a `count` value.
// A key with no row shows the key itself — the exporter refuses to write the
// file while the code asks for one the sheet has not got, so it should never
// be seen in a built page.

const STRINGS = (() => {
  const table = {};
  for (const row of (DATA.strings || [])) {
    const key = str(row.key, '').trim();
    if (key) table[key] = str(row.english, '');
  }
  return table;
})();

function T(key, values) {
  values = values || {};
  let template = null;

  if (Object.prototype.hasOwnProperty.call(values, 'count')) {
    const suffix = int(values.count, 0) === 1 ? '.one' : '.other';
    if (STRINGS[key + suffix] !== undefined) template = STRINGS[key + suffix];
  }
  if (template === null && STRINGS[key] !== undefined) template = STRINGS[key];
  if (template === null) return key;

  let filled = template;
  for (const name of Object.keys(values)) {
    filled = filled.split('{' + name + '}').join(String(values[name]));
  }
  return filled;
}

// How this level signs off, in its own words or in none.
function levelSignOff(key) {
  const level = (run.runner && run.runner.level) || {};
  const written = str(level[key], '').trim();
  if (written) return written;

  const name = str(level.name_en, '').trim();
  return name ? T('outcome.sign_off_named', {level: name})
              : T('outcome.sign_off_unwritten');
}

function showOutcome() {
  const engine = run.engine;
  const s = engine.state;

  let title = { win: T('outcome.carried'), loss: T('outcome.defeated'),
                retry: T('outcome.no_decision') }[s.outcome] || s.outcome;
  // Named from the stage. Three kinds of stage are scored — the caucus, the
  // town hall and the TV debate — and this said "Caucus closed" for all
  // three, so a TV debate ended by announcing it was a caucus.
  if (s.win_mode === 'score' && s.outcome === 'win') {
    const named = str(run.stage.name_en, '').trim();
    title = named ? T('outcome.closed', {stage: named}) : T('outcome.closed_unnamed');
  } else if (engine.isPressConference() && s.outcome === 'win') {
    title = T('outcome.conference_over');
  }

  // A stage whose score carries has to say so here, or the player never finds
  // out: the consequence lands in a stage they have not reached yet.
  //
  // "Carried" on its own is a word, not an ending. The last stage of a level
  // signs off IN THE LEVEL'S OWN WORDS, from levels.json. It used to say "you
  // convinced Parliament and your bill was adopted" whatever the level was,
  // so a media circuit and a research circuit both ended by announcing a bill
  // that never existed. A level with nothing written yet names itself.
  const lastStage = run.runner.index + 1 >= run.runner.stageCount();
  // WIN OR LOSE. This only ever asked for win_text, so the loss lines in
  // levels.json had never once reached the screen.
  const headline = (lastStage && (s.outcome === 'win' || s.outcome === 'loss'))
    ? levelSignOff(s.outcome === 'win' ? 'win_text' : 'loss_text')
    : '';

  const lines = [s.outcome_reason];
  const score = s.playerScore();

  if (s.outcome !== 'loss') {
    if (run.runner.scoreIsCarriedFrom(int(run.stage.seq, -1))) {
      const seats = LevelRunner.scoreToSupport(run.stage, score);
      if (seats > 0) lines.push(T('outcome.ahead', {count: seats}));
      else if (seats < 0) lines.push(T('outcome.behind', {count: -seats}));
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
        changes.push(T('reward.delta', {
          name: name,
          amount: (moved[name] > 0 ? '+' : '\u2212') + Math.abs(moved[name]),
        }));
      }
    }
    const xp = int(run.stage.xp_reward, 0);
    if (xp > 0) changes.push(T('outcome.xp', { count: xp }));

    // Which organisations the answers pleased. The Office shows the result,
    // but the connection between an answer and a standing is lost by then.
    const pleased = engine.pleasedBoosters();
    if (pleased.length > 0) {
      const names = boosterNames(DATA);
      lines.push('');
      lines.push(T('outcome.pleased',
        {names: pleased.map(id => names[id] || id).join(', ')}));
    }

    if (changes.length > 0) {
      lines.push('');
      lines.push(changes.join(', ') + '.');
    } else if (s.outcome === 'win' && rewardsAreUnset(run.stage)) {
      // The truth, rather than silence that reads as a bug.
      lines.push('');
      lines.push(T('outcome.no_rewards'));
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

        // What the organisations backing you pay out for a stage won.
        // Unlike the battle-start effects, this one does not care who was
        // in the room: a business circle pays for the result.
        const owned = DATA.modifiers.filter(
          m => run.ownedModifiers.includes(str(m.mod_id, '')));
        const paid = stageWinFunds(owned, DATA.modifier_effects || {});
        if (paid !== 0) {
          const row = DATA.sanban.find(v => v.name_en === 'Funds') || {};
          const before = int(run.meta.Funds, 0);
          run.meta.Funds = clampMeta(before + paid, row);
          run.lastMetaChange.Funds =
            int(run.lastMetaChange.Funds, 0) + (run.meta.Funds - before);
        }
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
  if (s.outcome === 'loss') return T('outcome.back_to_office');
  if (run.runner.index + 1 >= run.runner.stageCount()) return T('outcome.back_to_office');
  return T('outcome.next_stage');
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
