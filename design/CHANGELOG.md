# Coliseum of Parliament: change log

The dated build notes that used to live in `CLAUDE.md` (moved 2026-10-20 to keep that file small enough to load every session). Each section records what was built, why, and how it was checked, in the order it happened. `CLAUDE.md` holds the rules and the current structure; read a section here when you need the history or the detail of a system.

### Implemented systems and remaining work

The project also contains a browser playtest, booster standing, scripted intent
patterns, card cues, opponent cues, and a text catalog exported from the
workbook. Canon Town Hall (ST05) now draws its own written questions the
same way a press conference does (`BattleSetup.QUESTION_POOL_BY_STAGE`), and
BattleScreen shows what is being asked on the CueBanner itself
(`_announce_question()`), as its own default content until the player's turn
gives the banner something else to say, since ST05's Shared_pool bar means
it never gets the press-conference-shaped opponent row. What actually
happened — the opponent's own narration, a bout finishing, or the player's
own pass/decline penalty — moved to a small `%RoomNotice` label instead
(2026-09-26), so the banner in a question-asking room is never anything but
the question or the opponent's own cue, and never restates a name its own
tag already carries. The weak-answer tone cost remains a placeholder value
of 1 pending playtesting, and ST05 does not set it at all today, so a weak
answer there costs nothing yet — Cameron's number to set, not a gap in the
wiring.

### §8's four crisis triggers — now wired (2026-09-25)

All four are live: see §8's own table above for what each does today and
where. `MetaRules.gd`'s own file comment carries the same summary next to
the pure functions themselves. Each of the three that inserts or freezes
something (Town Hall, Steering Committee, funding freeze) fires once on the
way INTO its threshold and stays quiet — even while the condition keeps
holding — until the player has come back OUT (`GameState.town_hall_active`/
`steering_committee_active`/`funding_frozen_active`); a Town Hall lost while
Jiban is still low does not immediately queue a second one. The player
finds out about either edge — entering or leaving — through a popup on the
Office screen the next time they're there (`GameState.pending_trigger_
alerts`, `OfficeScreen._show_trigger_alerts_if_any()`), the same panel
pattern the battle screen's own outcome panel uses.

A fifth, related system went in alongside these: lifetime meta-variables —
`GameState.stage_type_results` (wins/losses per stage_id, including any
stage type added later, with no code change needed), `lifetime_gaffes`,
`stages_lost_to_gaffes`. At `gaffes_lifetime_penalty_threshold` (Balance
tab, 50 today) lifetime gaffes, a one-time `gaffes_lifetime_penalty_jiban_
delta` (−15 today) hits Constituency support once and never again this run.

### The 2026-09-26 databook pull

A new export of the workbook expanded Player, Opponents, Boosters and
Opponent Cues, and added Office Notices; four things came out of it.

- **Player is now real data.** All four protagonists (`data/player.json`)
  are cast with real names and parties, exported by `export_data.py`'s new
  `fold_player()` from a Player tab (was hand-maintained placeholder data
  before). Fields beyond name/party/blurb (a per-protagonist `starting_meta`
  and `starting_xp`) exist but are display-only for now, per Cameron.
- **Opponents split Affiliation from Role**, rather than one free-text
  field doing both jobs: Affiliation is a booster_id (their organisation),
  Role is their real-world job. A Title column, when a row has one,
  overrides Role for display (`OpponentDisplay.title_for()`) — party post
  titles themselves are still Cameron's to define (§9).
- **Journalists are opponents.json rows now**, not a separate
  `journalists.json` (deleted, along with `ArtLoader`'s "journalist" art
  kind and folder — a journalist's portrait is an ordinary opponent
  portrait now). `asked_by` on a question is resolved by checking which
  opponents.json rows list that room's own stage_id in their `stages`
  (`export_data.py`'s `fold_questions()`, `DataDB.get_opponent()`) — the
  same dynamic-by-stage-ID selection every other room uses for its
  opponents, never a hardcoded reporter list or a Role text match.
- **Four opponents (OP15/22/35/40) have a blank Stage on purpose**: each
  shares a name with a protagonist — literally the same character, before
  being cast as playable — so the workbook leaves them out of the dynamic
  pool rather than risk the player fighting themselves.
  `BattleSetup.eligible_opponents()` now also guards this generally: any
  opponent whose name matches the current protagonist's name is skipped,
  whoever they are, so a future addition to the workbook can't reopen the
  same problem (`tests/test_real_battle.gd`'s `test_the_player_never_
  meets_an_opponent_with_their_own_name`).

**Office Notices** (new): one line of Office-screen flavor text per named
slot, each row (`data/office_notices.json`, hand-seeded) conditioned on
whether a staff role is hired or a meta-variable crosses a threshold —
Cameron's own example, `"{staff} is greeting visitors"` /
`"{if reputation < 30} Yezo News has not covered your work recently."` The
first row per slot whose condition holds wins; `OfficeNotices.resolve()` is
pure logic (`tests/test_office_notices.gd`), wired onto the Office screen
as a label under Resources (`OfficeScreen._refresh_notices()`).

**Yoron and Bills removed** (Cameron: "the deletion of yoron (remove that
mechanic)") — see §8's own note. **MOD01 and the caucus rival are gone**:
the old numbered-step Modules sheet was already retired in an earlier
session, and there was never a caucus-rival *mechanic* in code to remove
(no script referenced one) — the phrase only lived in `data/player.json`'s
old placeholder blurb and in this file's own §9, both now corrected to
match the real cast above.

### The 2026-09-27 databook pull: real Floor Vote content

30 real bills (BI01-30), 30 new levels built around them (LV31-60, each
with its own `"BIxx"` slot per §7.7), all six party leaders cast (`Leader
Opp ID` on the Parties tab), and every one of those 30 levels marked
`"One-Time (Yes/No)"` = Yes (§8) — Cameron used the mechanism exactly as
built, on his own, no prompting needed. This closed out every "Cameron's
to write" item §9 used to list for Floor Voting.

One real structural change came with it: the Floor Vote Bills tab **lost
its Level ID column** — the level-to-bill link now runs the other way,
a level names its own bill directly in its stage sequence (see §7.7's
now-current description). `tools/export_data.py`, `DataDB.gd`, and
`BattleSetup.gd` were updated to match (the previous pull's Level-ID-on-
the-bill design lived for about a day). Re-verified against real data,
not fabricated fixtures this time: LV31 (Ainu Heritage and Language Act,
BI01) played through the real `FloorVoteScreen` end to end, and its
resolved totals (45 Yes / 48 No / 8 Abstain) matched the workbook's own
**Vote Tally & Swing** tab exactly — independent confirmation that
`FloorVoteEngine`'s math and Cameron's own hand-check agree. That tab
itself is not exported (`NOT_EXPORTED`): it's a derived check, the same
status as Tone Guide and Assets.

### The 2026-09-27 playtest fixes

A phone playthrough of the 2026-09-27 build turned up nine problems; each
is its own commit.

| # | Problem | Fix |
|---|---|---|
| 1 | Long text ran off the right edge, taking the portrait and "Turn X of Y" with it | Opponent name/intent lines wrap; a room name wraps only when it can't fit on one line (`BattleScreen._fit_stage_name()`), otherwise its Japanese accent stays beside it; energy pips are an `HFlowContainer` and wrap. Edited straight into `BattleScreen.tscn` (§13's note on the drifted builder) |
| 2 | "Name, <null>" for opponents with no Title; several titles overflowed | `OpponentDisplay.title_for()` treats null as blank and shows only the first `;`-separated title |
| 3 | Press conference showed "Question 6 of 20" and was lost on time | `BattleSetup` wrote the whole pool's size into `questions_count`, which the engine reads as how many to ask; that field is now `question_pool_size`. The conference is judged on its threshold (§7.3) |
| 4 | Opening any Floor Vote level froze the game | `int(null)` on ST23's blank reward cells — `MetaRules.stage_delta()` |
| 5 | Any card could be bought outright for XP | "New cards" replaced by **Rhetoric Training** (Office Management): the six card-tier sessions (SH15-17 XP, SH27-29 Yen, moved out of Supplies). "See a card" shows a random unowned card of that tier, front and back, before anything is paid; "Learn it" pays and adds that exact card, "Pass" costs nothing (`GameState.offer_random_card()`/`learn_offered_card()`). Cameron's call, knowing Pass lets a player keep drawing until a card they want appears. `GameState.buy_card()`/`Ledger.card_refusal()` remain only for `tools/playtest_optimal.gd` |
| 6 | Losing showed and cost nothing | §7.4's loss deltas |
| 7 | No limit on consumables (20+ Coffees, 20+ energy pips) | `default_consumable_stack_cap` (§9) |
| 8 | Press conference questions asked by MPs | Workbook data fix, Cameron's choice over a code rule: ST04 added to the 8 journalists' Stage cells (OP110-117) and removed from the 12 MPs that listed it — so the dynamic-by-stage-ID rule still decides, and would need redoing if an older copy of the workbook is uploaded over it |
| 9 | Opponent lines appeared twice, once as "Them: …" | The narrated version of the opponent's move shows only when they have no written cue for it |
| 5b | (follow-up) Unlimited passing in Rhetoric Training | A draw shows up to `card_training_looks` (rules.json, 3) cards with a "1/3" counter; Pass shows the next, the last has no Pass and the pop-up can't be closed, so a draw always ends in a learned card. The draw is saved (`GameState.card_draw`), so quitting mid-draw brings the same card back. Learning is what starts a fresh draw (`GameState.pass_offered_card()`, `can_pass_offered_card()`) |

Ten new Text-tab rows came with 3, 5 and 6 (`reward.if_lost`,
`outcome.reason.conference_short/reached`, `office.rhetoric_training`,
`rhetoric.*`); `office.new_cards`, `office.cards_blurb`, `office.unlock` and
friends are now unused by the game.

### The 2026-09-28 systematic evaluation pass

Asked to design a plan to evaluate every mechanic, not just whatever a
recent playthrough happened to touch. Rather than build new machinery,
this read what already exists (798 GUT tests, 6 real-click interaction
tests, `tools/playtest_optimal.gd`'s full automated playthrough,
`tools/verify.sh`'s CI gate) and found two structural gaps that were real,
not guessed:

- **`tests/interaction/office_hours_test.tscn` and `shop_items_test.tscn`
  existed and passed, but `tools/verify.sh` never called them** — a
  real-click regression in Office Hours or the shop/Rhetoric Training
  flow could ship without the gate catching it. Both are now wired into
  step 4.
- **`playtest_optimal.gd` had no branch for Vote-mode stages** —
  `_play_level()` only ever split Non-combat vs. everything else into
  `_play_battle_stage()`, which builds a `BattleEngine` config and has no
  idea what a bill is. Every one of the 30 real Floor Vote levels
  (LV31-60) hit this; the full-game playtest was blind to a third of the
  level catalog. `_play_vote_stage()` now drives `FloorVoteEngine`
  directly, voting with the player's own party's assumed majority (the
  same no-reallocation case `FloorVoteScreen.gd`'s own real flow falls
  into) — confirmed against real bills, including the same LV31 totals
  (45/48/8) the 2026-09-27 pull verified by hand.

Two new interaction tests close the remaining hole — neither
`FloorVoteScreen.tscn` nor `LevelIntroScreen.tscn`, the two newest screen
families, had ever been opened by a real click before this:
`tests/interaction/floor_vote_driver.gd` (votes on LV31's real bill,
confirms the outcome shows its real 45/48/8 totals and that favorability
moved) and `level_intro_driver.gd` (proves both halves in one run on real
Tier-0 levels: LV01 with nothing written skips straight to its first
stage, LV02 with one fake in-memory cue shows the real hired staffer's
portrait/name/line and routes on correctly). Both now run in `verify.sh`
alongside the other six.

`design/MECHANIC_COVERAGE.md` is the resulting matrix — every stage type,
meta trigger, and shop mechanic against what actually checks it (GUT /
click / playtest), built by reading the real test files rather than from
memory, with the honest "—"s left in. It also names the fifth category
the matrix structurally can't show: six of the 2026-09-27 session's nine
bugs were a correct rule with a GUT test AND a correct screen that had
been click-tested — they only broke with real content at real scale (a
20-question pool, a two-clause title, a phone-width screen). No unit or
click test can catch that class by construction, which is what
`design/PLAYTEST_CHECKLIST.md` is for: a manual pass, one per stage type
plus every meta/shop/save system, each line a concrete action and what
"wrong" looks like.

### The 2026-09-28 mobile playtest fixes

A real-phone playthrough turned up three more problems.

| # | Problem | Fix |
|---|---|---|
| 1 | The flinch reaction on a character's face (yours or the opponent's) was too quick to register on a phone | `FLINCH_SECONDS` doubled, 0.9 → 1.8, in both `OpponentPresenter.gd` and `PlayerPortraitPresenter.gd` |
| 2 | A press conference's drawn question showed no speaker name, and with no name the CueBanner's own coloured name tag stayed hidden — the question read as coming from nobody in particular | `OpponentPresenter.display_name()` deliberately returns `""` in a press conference (no opponent whose support can be taken) — correct for the opponent row's own name label, but `BattleScreen._announce_question()` was reusing it for the banner's speaker name too. Added `OpponentPresenter.question_speaker_name()`, which resolves the real asking journalist the same way `_show_journalist()` already does, and pointed `_announce_question()` at it instead |
| 3 | Scrollbars felt inconsistently fast — some lists used the touch-drag-and-glide feel (`DragScroll`), others fell back to Godot's own default scroll speed | Three scroll views had never been wired to `DragScroll`: the battle screen's own Outcome panel, and the Outcome panel on both `FloorVoteScreen` and `VisitorScreen`. Every scrollable list now goes through the same `DragScroll.attach()` |

**The Office news ticker** (new, 2026-09-28, Cameron): a scrolling strip
along the bottom of the Office screen, the same idea as Office Notices but
for lines that cycle rather than sit still. A new **Office Ticker**
workbook tab (rows: `ticker_id`, `condition_type`/`condition_target`/
`condition_op`/`condition_value` — the exact same condition schema Office
Notices already uses, or `always` for an unconditional line — and
`text_en`) exports to `data/office_ticker.json` the same way Office
Notices does. `OfficeTicker.gd` (pure, `scripts/rules/`) decides which
line is eligible right now and picks the next one at random, never
repeating the line just shown unless it is the only one eligible —
`OfficeNotices.condition_met()` was made public so both files read the
same condition logic rather than duplicating it. Unlike Office Notices
there is no "slot": a ticker can show every line that is currently true,
one after another, instead of picking one winner per subject.
`TickerPresenter.gd` (`scripts/ui/`) owns the actual scrolling and timing,
driven every frame from `OfficeScreen._process()`. Two independent levers,
both in `rules.json`, both Cameron's to retune: `ticker_speed_px_per_sec`
(how fast the current line travels, 50 by default) and
`ticker_pull_interval_seconds` (how long to pause, with nothing showing,
after one line has fully scrolled off before the next one enters — 12 by
default). A line always travels the full width and disappears only once
every letter of it has scrolled past the strip's own left edge — it
originally swapped to a freshly-picked line on the interval alone,
wherever the current one had scrolled to, which cut a line off mid-screen
and popped it out of existence with letters still showing (2026-09-28
mobile playtest; `ticker_pull_interval_seconds` now measures the gap AFTER
a full exit, not a forced swap). Six seed lines (TK01-06) ship in the
workbook so the ticker has something to show out of the box; the rest of
the tab is Cameron's to write.

**A "{player}" token for `text_en`** (2026-10-03): any ticker row — `always`,
`meta`, or `staff_role` alike — can include the literal text `{player}` and
it is filled in with the current protagonist's own name before the line is
shown, e.g. `"{player}'s latest floor speech is already being clipped for
tonight's broadcast."` becomes "Haru Yashi's latest floor speech is
already...". `OfficeTicker.fill_tokens()` does the substitution inside
`eligible_lines()` (so `next_line()` picks up the filled version
automatically); `TickerPresenter._pull_next()` is the one real call site
and passes `DataDB.player.get("name_en", "")` in — `OfficeTicker.gd` stays
pure, never reading DataDB itself. Unlike Office Notices' own `{staff}`
token (only safe on a staff_role row, since that's the only row with a
lookup to resolve it), `{player}` is safe everywhere, since the player's
name is fixed for the whole run. A blank name (no run started) leaves the
token untouched rather than blanking it, so a half-wired caller never ships
a broken-looking line. No workbook rows use it yet — Cameron's to write as
he continues filling out the Office Ticker tab.

### A thorough code stress test (2026-09-28)

Everything above proves a mechanic *works*. `tools/stress.sh` (new) asks
whether it keeps working under punishment — not part of `tools/verify.sh`
or CI, the same bargain `stress_shop_items.gd`/`stress_crisis_triggers.gd`
already strike (minutes, not seconds; run before a release or after
touching `BattleEngine`/`GameState`/`Ledger`, not on every commit).

- **Invariant checks inside `tools/playtest_optimal.gd`'s own battle loop**
  (`_check_invariants()`): deck+hand+discard conservation, guard/gaffe/
  energy bounds, and bar bounds (`BarModel.totals_balance()`), checked
  after every `play_card()`/`end_turn()` against every real stage in the
  game — nothing in `BattleEngine` itself asserts these; it is all soft-
  refusal via `_refused()`. A violation names its own exact reproducer: a
  stage ID and a `BattleEngine` seed (now always explicit —
  `config["seed"]` — rather than left to `setup()`'s own `randi()`
  fallback), since that one seed decides every random roll in a battle.
- **An adversarial mode, same tool**: `PLAYTEST_RANDOM_MOVES=1` swaps the
  greedy best-card heuristic for a shuffled hand played in shuffled order,
  with a real chance of a deliberate pass — explores play orders and
  timings the greedy heuristic never would (discarding whole hands, far
  more deck-empty/reshuffle cycles, far more press-conference declines).
  Losing constantly is expected here, not a bug — only an invariant
  violation, a crash, or a stuck stage is. `PLAYTEST_PROTAGONIST` (falls
  back to the existing hardcoded `PC02`) lets a run sweep all four.
- **`tests/interaction/mash_test.gd`/`mash_driver.gd`** (new): real
  rapid-fire clicks — End Turn spammed, the same card dragged up twice in
  a row, Details opened/closed ten times fast, Vote Yes and a Supplies
  purchase each double-clicked — checking "exactly one effect, no stuck
  UI" rather than re-proving a screen works at all (`click_test.gd`'s own
  job). Confirmed while building it: this codebase's click handlers are
  end-to-end synchronous (check, mutate, refresh, no `await` in between),
  so a same-frame double-submit race structurally can't happen most
  places — these are regression guards more than bug hunts, except for
  the End Turn case, which does cross a real `await` boundary
  (`OpponentPresenter.flinch()`/`PlayerPortraitPresenter`'s own reaction
  animations), and is the one most likely to matter.
- `tools/stress.sh` runs all of the above plus the two existing fuzzers in
  one command, mirroring `tools/verify.sh`'s own shape and reporting.

**Rhetoric Training: only one draw at a time, now said out loud**
(2026-09-28). Cameron asked whether the XP route (SH15-17) and the Yen
route (SH27-29) could conflict or double up a card. They can't duplicate a
card — both draw from the exact same "unowned cards of this tier" pool
(`GameState._unowned_cards_at_tier()`), so a card learned through either
route is in `owned_cards` and out of every future draw regardless of
currency. But `GameState.card_draw` is a single field, so only one
Rhetoric Training draw can be open at a time — tapping "See a card" on a
different row while one is already in progress silently reopens THAT
draw (already true, already tested:
`test_seeing_a_card_again_mid_draw_returns_the_same_card_not_a_reroll`,
"even a different session"), with no explanation for why a different
row's price just appeared. `OfficeScreen._on_see_card()` now compares the
returned draw's own `item_id` against the row actually tapped and, when
they differ, shows a new line (`rhetoric.draw_in_progress`) saying a
session is already open — the draw itself is unchanged, only the player
now knows why.

**Party names, coloured everywhere by their own official RGB**
(2026-09-28). `FloorVoteScreen.gd` already coloured each party's own name
by its `data/parties.json` row (`r`/`g`/`b`, 0-255 each — three separate
keys, not a packed array); three other places showed a party name as
plain text. New `PartyDisplay.gd` (pure, `scripts/rules/`,
`color_for(party: Dictionary) -> Color`, a neutral grey for an unmatched
row so a name never goes invisible) is the one place the RGB→Color
conversion lives now, reused by:
- The New Game protagonist picker (`OfficeScreen._protagonist_row()`) —
  each candidate's own party line.
- The Office header — used to be one `"{name} · {party}"` string on a
  single Label, which cannot colour only part of itself; split into
  `_title` (the name) and a new `_title_party` Label (`"· {party}"`,
  built in code the same way `_notices_label` is) so only the party
  portion carries the colour.
- The battle screen's own Details panel — "You: {name}, {party}" and
  "Opponent: {name}, {party}" used to be two lines inside one big joined
  `_details_text` Label; the party is now two small labels
  (`_you_party_label`/`_opponent_party_label`) appended after it instead,
  each shown only when that side actually has a party (not every
  opponent does).
`FloorVoteScreen.gd`'s own `_party_color()` is untouched — it already
reads the identical RGB from a pre-built `"party_color"` array
(`BattleSetup.gd`'s own Floor Vote position dicts), a different shape
than `PartyDisplay.color_for()`'s `{r,g,b}` row, and was already correct,
so there was nothing to fix there.

### "Your Record" — lifetime stats (2026-09-28)

Cameron asked how a Floor Vote's influence-swing flip (§7.7) gets tracked
— it didn't; the flag lived only for the instant of that one vote. Three
new lifetime counters, bundled into one new Office screen page:

- **`GameState.bills_flipped_by_influence`**: every `bill_id` the
  influence swing has flipped, in the order it happened.
  `GameState.record_bill_flip(bill_id)` (dedup-guarded, though a bill can
  only be voted once since every real Floor Vote level is One-Time)
  is called from `FloorVoteScreen._on_vote()`'s existing flip block.
- **`GameState.levels_cleared`**: `{level_id: win_count}`, bumped once
  inside `finish_stage()`'s existing `if last_level_outcome ==
  LevelRunner.WON:` block — a win only, never a loss, and it can bump
  past 1 on a replayed level.
- **Tier clears are derived, not a third counter**: the Office page sums
  `levels_cleared` by each level's own `tier` at display time rather than
  keeping a parallel tally that could drift out of sync — cheap over the
  ≤60 real levels, and correct by construction.

Both fields are in `_SAVED_FIELDS` (reset with everything else lifetime
on a new run — `bills_flipped_by_influence` in `reset_crisis_triggers()`,
`levels_cleared` in `reset_levels()`). New **"Your Record"** button beside
Organisations, built in code exactly like Inventory beside Management
(`OfficeScreen._build_record()`) — no `.tscn` edit, since `tools/build_
office_scene.gd` is unsafe to rerun (§13). `_show_record()` lists the
flipped bills by their real `bill_name`, each cleared level by its own
`description` and clear count, and clears per tier — all through new
Text-tab rows, per the "no sentence lives in a script" rule.

### Balance tuning and a question-effectiveness multiplier (2026-09-28, Cameron)

Five small, direct numbers, plus one new mechanic, from a single pass
through this file's own open-items list:

- **Floor Vote influence swing** (§7.7): `vote_swing_resistance_default`
  raised 70 → 85 (Balance tab), with three parties now overriding it on
  their own row (Parties tab's own Vote Resistance column, blank = the
  flat default): Frontier Party 75, Five Point Independents 99, Country
  Initiative 90. The other three parties (Butsutou, Yezo Heritage Party,
  Keizaijiyuutou) stay on the flat default.
- **Booster starting standing** (§13's own note on the flat `start`
  fallback): 50 → 30, `data/booster_standing.json`.
- **The Office ticker** (§8): `ticker_speed_px_per_sec` 50 → 70,
  `ticker_pull_interval_seconds` 12 → 10 (`data/rules.json`), each with
  its own dated rationale line alongside the original options, the same
  documented-choice shape every other `rules.json` lever already uses.
- **Whether the Town Hall asks questions** (§9's own list used to carry
  this as unresolved): it already does, and has since 2026-09-25
  (`BattleSetup.QUESTION_POOL_BY_STAGE`'s own `"ST05": "town_hall"` entry,
  proven against real level data by `tests/test_real_battle.gd`'s
  `test_st05_town_hall_actually_answers_its_drawn_question_too`) — the
  §9 bullet was stale, not a real gap, and is now removed.
- **A question's own effectiveness on the card that answers it** (new
  mechanic, redesigned once on the same day — see below): a Strong-graded
  answer now boosts that card's own `self_plus`/`opp_minus` **1.3x** this
  round, on top of the stage's own affinity, and still pleases the asking
  organisation exactly as before (settled 2026-09-21, untouched); a Weak
  one penalizes it **0.7x**; Medium is unchanged. `balance.json`'s new
  `question_strong_multiplier`/`question_weak_multiplier` (one pair of
  numbers across every question-asking room, not per-stage), both
  mirroring `affinity.json`'s own 0.7–1.3 range at Cameron's direct
  instruction. `BattleEngine.question_multiplier_for(card)` composes into
  the same `context["affinity"]` float `CardResolver.resolve()` already
  multiplies by — both `play_card()`'s real resolution and `preview()`'s
  card-zoom read from the same place, so what the zoom promises is what
  play_card() actually does. Shown to the player **before** they play the
  card: a second card-zoom line (`describe_question_for()`,
  `CardBackView.show_card()`'s new `question` parameter) right below the
  existing stage-affinity line, using the same "plain English, not a raw
  multiplier" convention. Both default to `1.0` (no change — today's
  exact behaviour outside a question-asking room) when a config never
  sets them, so every older fixture/test stays deterministic without
  knowing this mechanic exists; `BattleSetup.gd` is the one place that
  reads the real `balance.json` numbers for an actual game. No tone cost
  at all any more on a weak answer — not the old flat
  `weak_answer_tone_cost` (§9, still 1, still exported, now simply
  unread — the same "unused, not removed" precedent `office.new_cards`
  already set), and not an earlier same-day build of this feature (a
  75%-chance-to-cost-tone roll) that Cameron redesigned within the hour
  once he saw it described back to him: that version, and its
  `narration.not_convinced` "No one was convinced" line, are both fully
  gone, not layered under this one.

### A weak answer's own booster penalty, and a per-stage cap (2026-09-28, Cameron)

Two follow-ups once Cameron saw the theoretical-maximum math for how far
one stage's question-answering could move a booster's standing (§8's own
pleasing mechanic, until now a please-only, uncapped-by-anything-but-
dedup system):

- **A weak-graded answer now annoys the same organisation a strong one
  would have pleased**, by `per_displease` (`booster_standing.json`,
  1 — a tenth of `per_please`'s 5, Cameron's literal number). Mirrors
  pleasing exactly: `BattleState.displeased_boosters` (new field,
  deduplicated the same way `pleased_boosters` already is) is populated
  in `BattleEngine._answer_question()`'s `"W"` branch, off the same
  question's `pleases_boosters` list (there's no separate "annoys" column
  in the data — the org a weak answer annoys is the one a strong one
  would have pleased). `BattleEngine.displeased_boosters()` exposes it,
  the same shape as `pleased_boosters()`.
- **The two lists are kept deliberately separate, never merged**: only
  the pleased list carries a buff into a later stage of the same level
  (`LevelRunner.carried_buffs()`) — a weak answer must never grant that,
  so `displeased_boosters` is threaded everywhere as its own value,
  never mixed into `boosters`. `GameState.finish_stage()` gained a 6th,
  end-of-signature parameter, `displeased_boosters: Array = []`, so
  every existing positional call site (there are dozens, across the GUT
  suite) keeps working unchanged. `BattleScreen._on_outcome_closed()`
  is the one real call site, passing `engine.displeased_boosters()`.
- **A hard per-stage cap, both directions**: `GameState._apply_question_
  boosters()` (renamed from `_please_organisations()`, since it now
  handles both) computes one NET change per organisation touched —
  pleased once this stage: `+per_please`; displeased once:
  `-per_displease`; both (two different questions about the same
  organisation, one answered well and one badly): the two amounts settle
  together — then clamps that net to `booster_standing.json`'s new
  `question_swing_cap` (5) before applying it. With today's numbers
  (5 and 1) the cap never actually binds — pleasing alone already sits
  exactly at it — but it is a real, tested ceiling for whenever those two
  numbers get retuned, not just documentation.
- **Shown to the player**, the same "no news is no line" rule the pleased
  list already used: the battle Details panel gets a new "Annoyed so
  far: …" line beside "Pleased so far: …", and the end-of-stage Outcome
  panel gets a new `outcome.displeased` Text-tab row ("Annoyed: {names}.")
  beside `outcome.pleased` — the connection between a bad answer and a
  standing hit is otherwise lost by the time the player reaches the
  Office, the same reasoning `outcome.pleased`'s own comment already
  gives.

### Your Record's Sanban values, a real Media Ambush surprise, and a real Outcome-panel bug (2026-09-28, Cameron)

- **"Your Record" now opens on the four Sanban values** (Constituency
  support, Reputation, Funds, Party support) — `OfficeScreen._show_record()`,
  a new heading ahead of the bills/levels/tiers sections it already had,
  reading straight off `GameState.meta` (live, not the run's starting
  numbers the New Game screen shows) via the same `DataDB.sanban` loop and
  `new_game.stat_line` wording New Game's own `_starting_stat_lines()`
  already uses. New `office.record_sanban_heading` Text row ("Where you
  stand").
- **Media Ambush (ST19) is now a real surprise, not a half one.**
  `stages.json`'s `reveal_in_briefing: "No"` already hid a stage's name and
  opponent in the level briefing, but its win/loss numbers still showed —
  a deliberate earlier choice so the player could weigh the risk. Cameron's
  call this time: remove the stage from the briefing entirely instead —
  no heading, no placeholder, no rewards, no "if you lose" line. Confirmed
  live against LV02 (the real level pairing a Lobbyist Meeting with a
  Media Ambush): the briefing now shows exactly its one other stage and
  nothing else. `office.briefing.surprise_stage`'s old placeholder text is
  now unread, same "unused, not removed" precedent as `office.new_cards`.
- **A real bug, found chasing down what turned out to be a vague report**
  ("the negative outcome values are not displaying"): `OutcomePresenter.
  _body_for()`'s loss branch returned early, before the code that prints
  which organisations the player's answers pleased or annoyed — that block
  only ever ran on the WIN path. The standing change itself was always
  applied correctly (`GameState.finish_stage()` doesn't care about
  outcome for that); only the one place that explains WHY a booster's
  number just moved stayed silent, and only on the stage that lost. Fixed
  by moving the pleased/displeased lines ahead of the win/loss branch, so
  both show regardless of outcome. `tests/test_outcome_presenter.gd` (new)
  proves it two ways — confirmed failing before the fix, passing after:
  a lost stage's displeased organisation reaches the panel, so does a
  pleased one, and the loss's own cost line (Constituency support etc.)
  is untouched alongside it.

### A text veil behind the Office's floating text (2026-09-28)

The Office's header ("Kenshin Sako · Frontier Party") and its flavour-text
block (the last-level report, "XP · Funds", Office Notices) both sat
directly on the bookshelf background and the protagonist's own art with
only the screen's single uniform `BackgroundScrim` (0.55 alpha) behind
everything — legible, but low-contrast against a busy, lit background,
and the text visually crowded the character rather than reading as its
own layer. Cameron's ask: the same idea `CardBackView.gd`'s own veil
already uses behind a card's printed text, so the text reads as sitting
on its own surface rather than painted onto the art.

`scenes/office_hours/OfficeScreen.tscn`: a new shared `StyleBoxFlat`
(`Color(0.06, 0.05, 0.04, 0.6)`, rounded 18px corners, ~20/14px content
margins) backs two new `PanelContainer`s — `HeadingBackdrop` around the
title row, and `TextBackdrop` (wrapping a new `TextColumn` VBoxContainer)
around the Report/Resources block. Office Notices — built in code,
inserted at runtime right after `%Resources` via `_resources.get_parent()`
— needed no code change at all: that lookup now resolves to the new
`TextColumn` instead of the old bare `Column`, so the notices lines land
inside the same backdrop automatically. The Ticker strip already had its
own dedicated `TickerBackground` (0.85 alpha) and was left alone.

**Widened to near-full screen width** (2026-09-28, same day, Cameron's
follow-up): both boxes first shipped shrink-to-fit, hugging just their own
text — too narrow once seen on a real screenshot. Now each sits inside its
own `MarginContainer` (`HeadingBackdropMargin`/`TextBackdropMargin`) with
a 21.6px margin each side — 2% of the 1080px base width, Cameron's own
number — and the `PanelContainer` inside fills that margin's full
remaining width. That 2% is measured from `Safe`'s own already-inset
content area, not the true device edge: `Safe` (`MarginContainer`, 40px
each side) exists specifically for device safe areas (notches, rounded
corners, §3's own hard constraint), and these two boxes are the only
content on this screen that isn't already governed by it in some other
way, so shrinking that margin itself, or letting a box bleed past it, was
not this fix's call to make on its own. Confirmed by a real screenshot
before and after each change, not just a scene-file read.

### Three Office wording/structure changes (2026-09-28, Cameron)

- **"The organisations" → "Important Stakeholders"** — `OrganisationsButton`'s
  own hardcoded `.tscn` text and the `office.organisations` Text-tab row both
  updated; nothing else reads that wording.
- **Shop moved out of Office Management and into the Inventory screen,
  which is now called "Marketplace"** — `_show_supplies()` is gone;
  `_show_marketplace()` shows the held-items grid (`InventoryPanel.
  inventory_rows()`, split out for this) followed by the Supplies listing,
  in one panel. `InventoryPanel` (shared with the battle screen) gained a
  `reopen: Callable` so using an item from the Office's Marketplace comes
  back to the whole merged view rather than narrowing to the plain grid —
  the battle screen's own `InventoryPanel` instance never sets it, so its
  behavior is unchanged. A new `office.marketplace` Text row was added
  rather than reusing `inventory.button`/`inventory.title`, which the
  battle screen's own mid-stage Inventory button also reads — renaming
  those would have relabeled that button too.
- **"Cosmetic Packages" → "Appearance and Music"** — `office.cosmetics`
  Text-tab row updated.

All three interaction-test drivers that hardcoded the old Office
Management → Supplies path (`mash_driver.gd`, `shop_items_driver.gd`,
`inventory_driver.gd`) were updated to the new one-click Marketplace path.
Full GUT suite and `tools/verify.sh` confirmed green afterward.

**The Marketplace panel reordered** (2026-09-29, Cameron, from a real
screenshot): the panel used to open on its own "Marketplace" title with
the held-items grid (or "Nothing here yet…") sitting directly under it,
then a "Supplies" heading further down for the blurb, XP/Funds, and the
buyable rows. Cameron's read: the "Nothing here yet. Supplies you buy or
are given will appear here." line is really about Supplies, not about the
Marketplace heading it sat under — and he wanted "Supplies" to be what
opens the panel, with "Marketplace" as a second heading further down,
right above XP/Funds. `OfficeScreen._show_marketplace()` now opens on
`Text.say("shop.supplies")` (the panel's own title) with the blurb and
`InventoryPanel.inventory_rows()` first, then a `UiKit.heading("office.
marketplace")` row directly above the XP/Funds lines and the buyable
Supplies rows. No Text-tab or schema change — both keys already existed,
only which one is the panel title and where the other one sits as a row
changed. Confirmed with a real screenshot (`xvfb-run … "$GODOT" --path .`
— no `--headless`, since that swaps in the dummy renderer and
`get_viewport().get_texture()` comes back null) before deleting the
throwaway driver, the same convention as every other UI-only change this
session.

**A random Grants outcome now says which organisation it landed on**
(2026-09-29, Cameron): using a Commission item (SH01-03, Grants a random
booster from a tier) used to just say "{name} used." — the same generic
line every item gets, whether its effect was random or not. Which
organisation actually got the standing bump was only ever inferable
later, from Important Stakeholders' own "(+1)" line next to whichever one
moved. `GameState._apply_reward_entries()` now returns every entry it
actually applied (`{"kind","id","delta"}`, a BOOSTER_TIER pick recorded
as the concrete BOOSTER it resolved to), and `use_item_in_office()`/
`use_item_in_stage()` turn that into a "{name} used — {org} {+/-N}."
message (`_describe_grant_outcomes()`) whenever a booster or segment was
touched — a plain modifier or shop-item grant is left alone, since its
own name already says exactly what it is, nothing rolled. Three new Text
rows (`item.used_with_outcome`, `item.queued_with_outcome`,
`item.queued_level_with_outcome`), same wording shape as the existing
`item.used`/`item.queued`/`item.queued_level` rows they sit beside.

**A combat stage can now be won instantly by arguing the opponent down to
nothing** (2026-09-29, Cameron). CLAUDE.md's own §7.2 already described
"arguing a debater's seats down to nothing" as a way to end them short of
the threshold, but that branch (`BattleEngine._check_outcome()`) only
ever fired for `sequence_mode: "continuous"` — a shape built for the
floor debate but never actually used by any of the 23 real stages
(`stages.json`'s own `sequence_mode` column is `single` or `reset`
everywhere), so the rule was a dead seam, not something a real battle
could ever trigger. Generalized to fire whenever the room has a real
threshold to race toward at all (`has_threshold`, already computed just
above it — every Shared_pool Combat stage, i.e. not a press conference
and not the TV debate's survival bar) rather than only in the one
sequence_mode nothing uses: `state.bar.opponent <= 0` now ends a
single-opponent room outright, and ends the current bout of a committee
sequence the same way a threshold win already does
(`has_more_opponents()`/`_advance_to_next_opponent()`, both untouched).
The existing threshold-win check runs first in `_check_outcome()`, so a
turn that both crosses the threshold AND empties the opponent is still
an ordinary win, never this one — confirmed by a GUT test doing exactly
that.

Whichever opponent was argued out this way costs their own organisation
standing: `BattleState.crushed_opponent_boosters` (deduplicated per
stage, the same shape `displeased_boosters` already uses), read off the
opponent's own `affiliation` field (`opponents.json`) in the new
`BattleEngine._register_crushed_opponent()`, applied as a flat
`-instant_win_penalty` (2, hand-maintained in `booster_standing.json`
beside `per_please`/`per_displease` — that file is never exported, so no
workbook edit needed for the number itself) via the new `GameState.
_apply_instant_win_penalties()`, called from `finish_stage()`'s new 7th,
end-of-signature `crushed_boosters` parameter — the same positional-
default pattern `displeased_boosters` used, so every existing call site
keeps working (`BattleScreen._on_outcome_closed()` is the one real
caller, passing `engine.crushed_opponent_boosters()`). This is a
separate, simpler penalty from the please/displease netting a question's
own grade already applies — never capped or netted alongside it, since
it isn't about a question at all. Shown on the Outcome panel as a new
`outcome.crushed` line ("Argued out of the room: {names}.") beside
`outcome.pleased`/`outcome.displeased`, same reasoning as always: a
standing hit nobody's told about may as well not have happened.
Confirmed against a real level/stage/opponent (LV08's ST02, a real
opponent affiliated with BO17): opponent's support driven to zero ends
the stage in a win with the real "argued out of the chamber" text, and
BO17's standing drops from 30 to 28.

**The Floor Vote party row laid out as a semicircle instead of one
compressed line** (2026-09-30, Cameron, from a real screenshot): six
full portrait-plus-cue cards in a single `HBoxContainer` overlapped and
compressed on a 1080px-wide screen — nothing to scroll to, just too
narrow to hold six 100px-wide blocks of wrapped sentence text side by
side. `PartyRow` is now a plain `Control` (position managed in code,
not by an HBoxContainer's own layout pass) and `FloorVoteScreen.
_show_parties()` positions each of the six fixed card nodes along an
arc — left to right in the bill's own position order (Butsutou, Yezo
Heritage Party, Frontier Party, Five Point Independents, Keizaijiyuutou,
Country Initiative, since that is simply the order `floor_votes.json`'s
own Floor Vote Party Positions rows are in for every real bill), a dome
shape with the two middle parties highest and the two end ones lowest —
the way a hemicycle's own back benches are usually diagrammed. **Spacing
is even in x, not in angle**: the first version spaced the six cards at
equal angles around a true semicircle, which — since cosine bunches near
0°/180° — crowded the two end cards hard against their neighbours
(caught on a real screenshot, not guessed at); recomputed to evenly
spaced x positions with a sine-curve height instead, which keeps the
same dome look with a guaranteed gap between every card. Portraits and
cue text both widened 100→150px alongside the fix, since a 150px-wide
sentence wraps to noticeably fewer lines than a 100px one.
`tests/interaction/floor_vote_driver.gd`'s own `PartyRow` type
annotation updated to match (`Control`, not `HBoxContainer`);
`floor_vote_test.tscn` confirmed still green afterward.

**A committee's "final blow" line named the wrong opponent**
(2026-09-30, Cameron, from a real screenshot): finishing off a
committee member mid-sequence showed something like "Atsuko Takeo is
finished — Yuki Kasukasa rises, ... argued away from Yuki Kasukasa" —
crediting the seats to whoever had just RISEN, not whoever was actually
argued down. `BattleScreen._play_selected()` read
`OpponentPresenter.display_name(engine)` AFTER `engine.play_card()`
returned — but a card that finishes the current opponent (a threshold
win, or the new instant-win mechanic above) already advances the engine
to the next one inside `play_card()` itself, so by the time the name was
read it was already the new opponent's. `_on_end_turn()` right below it
already reads its own `acting_opponent`/`speaker` BEFORE `_refresh()`,
with a comment explaining exactly why — the same care had just never
been applied to the player's own card-play narration path. Fixed by
capturing `acting_opponent_name` right after `preview()` (still the true
opponent) and before `play_card()`, then using that captured value
instead of a fresh read. Confirmed against a real committee (LV09/ST01):
forcing a lethal card against the first of three opponents, the
narration built from the name read after `play_card()` said "argued
away from Aoi Oba" (who had just risen); built from the name captured
before, it correctly said "argued away from Ayala Taiyounokage" (who
was actually beaten) — the exact bug, reproduced and confirmed fixed.

**A lesson worth keeping for later workbook edits**: `openpyxl` is safe
for *reading* `design/Game_Workbook.xlsx`, but a direct
`load_workbook()` → edit → `save()` round-trip silently corrupted the
Sanban tab's start/min/max values this session — caught only by
`export_data.py`'s own validation (3 errors), not by a before/after diff
that also used openpyxl to read both sides. Any future workbook edit
should use the raw-XML zip-surgery technique already established earlier
in this file's own history (edit the XML fragment directly, re-zip, then
confirm with a clean `export_data.py` run — never trust an openpyxl-based
diff alone). Confirmed again this session on comment-only edits (see
below): a plain `load_workbook()` → add-comments → `save()` round trip
still wiped every formula-cell cache on the Stages tab (`win_pct`,
`segment_check`, `favored_suit` all read back `null`) even though no
value was touched — caught the same way, by a clean `export_data.py`
diff immediately after, and reverted before it ever reached a commit.

### Defunct shop items removed; three player-facing raw-ID leaks fixed; Sanban deltas shown; workbook columns get their permutations (2026-09-30, Cameron)

Four small, independent asks in one pass.

- **Two defunct shop entries removed.** SH13/SH14 ("Unlock Tier 1/2
  Level") and CP01/CP02 ("Neon Ambition"/"Quiet Chamber") deleted
  outright from the Shop and Cosmetic Packages tabs — both rows'
  worth of feature, unpurchased content that had nothing behind it
  worth keeping in front of a player. Neither mechanism was torn out:
  `buy_random_level()`, the whole Cosmetics/Appearance-and-Music page,
  `CosmeticPieces.gd`, `ArtLoader`'s variant axis and `Audio`'s music
  override all stay exactly as built, the same "empty is a valid state"
  bargain every other optional table in this project already keeps —
  nothing stops Cameron from writing new rows into either tab later.
  Eight test/tool files that hardcoded these six specific IDs
  (`test_cosmetics_game_state.gd`, `test_cosmetic_pieces.gd`,
  `test_art_scheme.gd`, `test_save_load.gd`, `test_inventory.gd`,
  `shop_items_driver.gd`, `cosmetics_driver.gd`,
  `stress_shop_items.gd`) were updated to inject synthetic fixture rows
  straight into `DataDB` for their own duration instead — the same
  "fake row" technique `floor_vote_driver.gd`/`level_intro_driver.gd`
  already used for a table with nothing real in it.
- **Two real raw-ID leaks fixed.** The level briefing panel
  (`OfficeScreen._on_level_chosen()`) was titling itself with the raw
  `level_id` ("LV31") instead of the level's own `description` — its
  stated fallback text ("Before you go in") could never actually fire,
  since every real level has a `level_id`. The battle screen's own
  Details panel (`BattleScreen._refresh_details()`) printed
  `"Stage: Floor debate (ST02)"`, the raw `stage_id` included
  unconditionally; now just the name. A full audit of every other
  `.open()`/`.text =` call across `scripts/ui/` turned up nothing else
  unconditional — the remaining `get("name_en", some_id)`-style
  fallbacks only ever surface an ID on data that's missing entirely,
  which is the existing, intentional placeholder bargain, not a leak.
- **Sanban's own page ("Your Record") now shows a `(+N)`/`(-N)` next to
  each of the four meta-variables**, the same treatment Important
  Stakeholders already gives a booster's own recent change
  (`GameState.last_booster_change`). The underlying field,
  `last_meta_change`, already existed and was already being written on
  every stage reward — it had simply never been read anywhere. Two
  small fixes were needed to make it tell the truth: it used to reset
  itself at the top of `_apply_stage_rewards()`, per-stage, which would
  have wiped a Floor Vote's own favorability/influence-bonus swing
  before the Office ever got to show it (those land on Sanban via
  `apply_floor_vote_favorability()`/`apply_floor_vote_influence_bonus()`
  earlier in the same flow, before `finish_stage()` runs) — the reset
  was removed so it now scopes to the whole level, the same as
  `last_booster_change` already does. And three call sites that were
  genuine stage/vote *outcomes* — the Floor Vote's own favorability and
  influence bonus, and the lifetime-gaffe Constituency-support penalty
  — were routed through `_apply_meta_reward()` instead of the plain
  `_move_meta()` they'd used before, since only the reward-shaped path
  records into `last_meta_change`; `_move_meta()` itself is untouched
  and still deliberately silent for the Office's own spending (buying,
  hiring, firing), per its own existing doc comment — a purchase was
  never meant to look like a reward.
- **19 header-cell comments added to the workbook**, one per column
  whose values come from a closed set of text options rather than free
  prose: Stages' Mode/Bar Model/Energy Mode/Sequence Mode/Reveal In
  Briefing/Loss Ends Level/Reputation Affects Start, Cards' Type/Tier,
  Modifiers' Effect Type, Boosters' Tier, Floor Vote Party Positions'
  Disposition, Opponent Cues' Verb, Vote Influence Triggers' Enabled,
  Vote Influence Cues' Outcome Direction, and Office Notices'/Office
  Ticker's shared condition_type/condition_op pair — each comment
  spelling out the real permutations read straight from the code that
  consumes that column (`BarModel.gd`, `BattleEngine.gd`,
  `OfficeNotices.gd`, `export_data.py`'s own validation, and the real
  distinct values already in the exported data), not guessed at. Built
  by hand as raw comment/VML-drawing XML parts (`xl/commentsN.xml`,
  `xl/drawings/vmlDrawingN.vml`, one new worksheet `_rels` file per
  sheet, a `<legacyDrawing>` element added to each sheet, two new
  `[Content_Types].xml` entries) rather than through openpyxl, for
  exactly the reason the lesson above already gives — confirmed by
  reading the comments back with openpyxl (safe) and, more importantly,
  by a clean `export_data.py` diff showing zero data changes.

### A Level Buff's own Extra Guard bonus vanished after the first opponent in a committee (2026-09-30, Cameron)

Reported as "shop items that provide a bonus across a full level are not
working — the bonus applies only to the first stage used in." Confirmed
with a throwaway headless repro (deleted before commit, this session's
own convention) before touching any code: an item bought before a level
begins correctly reaches every real stage of that level — `GameState.
level_bonuses` isn't cleared between stages, and `take_item_bonuses_for_
stage()` hands it to a fresh `BattleEngine.setup()` each time, confirmed
against two real multi-stage levels for both a "bought in the Office" and
a "used mid-stage" purchase. The real bug was one level narrower than
"stage": inside a SINGLE committee stage (`sequence_mode: "reset"`,
§7.5), `BattleEngine._reset_for_new_bout()` unconditionally set
`state.block = 0` for every opponent after the first, with nothing to
re-grant an Extra Guard (Level Buff) item's own starting bonus. Energy
and hand-size bonuses never had this problem — they live in
`state.energy_per_turn`/`state.hand_size`, fields `_reset_for_new_bout()`
never touches — but guard is spent, not merely a baseline, so its bonus
had nowhere to survive a bout reset. To a player, a committee's full
support/gaffe/hand/deck reset between opponents already reads as "a new
fight," which is exactly why this shipped as "only the first stage."

Fixed by remembering the amount, not just applying it once: a new
`BattleEngine._item_guard_bonus` instance var accumulates every GUARD
application (`_apply_item_bonus`'s own "GUARD" case, whether from
config's `item_bonuses` at `setup()` or a Stage-duration item used
mid-battle — either way it's this stage's bonus, and a committee's
several opponents are all one stage), and `_reset_for_new_bout()` now
sets `state.block = clampi(_item_guard_bonus, 0, state.guard_cap)`
instead of a flat `0`. `tests/test_battle_engine.gd`'s new
`test_a_level_buffs_guard_bonus_carries_into_every_new_bout()` sits
right beside the existing `test_a_new_committee_bout_clears_both_banks()`
it's a variant of — the old test (no item bonus in its config) still
correctly asserts a plain `0`, since `_item_guard_bonus` defaults to
that; the new one uses the same fixture with `"item_bonuses": {"GUARD": 1}`
and asserts `1` survives the reset. `tools/verify.sh` confirmed green
afterward.

### SH19's own Funds cap increase was silently ignored by stage rewards (2026-09-30, Cameron)

Reported as "the yen/funds cap is not working — Funds accumulate beyond
the cap." Traced every place Funds is written before touching anything:
`GameState._move_meta()`/`_apply_meta_reward()` (Office spending, the
Floor Vote's own favorability/influence bonus, the lifetime-gaffe
penalty) all clamp correctly against `_sanban_row("Funds")`, which
already raises the ceiling by `funds_cap_bonus` (SH19, "Increase Office
Funds Cap," repeatable). A stage's own `win_delta_yen`/`loss_delta_yen`
and its score-effects path — `GameState._apply_stage_rewards()`, the one
place that actually pays out after a battle — went through `MetaRules.
apply_win_deltas()`/`apply_loss_deltas()`/`apply_score_effects()` with
`DataDB.sanban` passed in **raw**, un-adjusted for any purchased bonus.
The clamp itself was never missing (a real headless repro confirmed
Funds never exceeded either max, whichever one a given path happened to
check) — the bug is that stage rewards were capping against the flat
*workbook* number even after the player paid Yen or XP to raise it,
silently discarding the difference: buy SH19, win a stage, and the extra
headroom you paid for never landed. Read literally ("beyond the cap")
this is the mirror image — Funds falling short of the cap the player
actually has — but it's the one real inconsistency anywhere in the Funds
cap system, and "the cap isn't working" is an accurate description of a
stage-reward path quietly enforcing the wrong one.

Fixed with one new method, `GameState.sanban_rows_with_bonuses()` —
`DataDB.sanban`, with Funds' own row replaced by `_sanban_row("Funds")`'s
already-correct bonus-adjusted version, a no-op array copy when
`funds_cap_bonus` is 0 so nothing changes for a run that never bought
SH19. `_apply_stage_rewards()`'s three `MetaRules` calls now read from
it instead of `DataDB.sanban` directly. `OutcomePresenter._what_it_was_
worth()` had the identical bug, one layer up — it recomputes the same
deltas purely to show "+N Funds" on the outcome panel, and was reading
`DataDB.sanban` raw too, which would have kept promising the old amount
right after this fix corrected what actually lands — now reads
`GameState.sanban_rows_with_bonuses()` as well, so the panel and the
real payout always agree. New `tests/test_game_state_meta_tracking.gd`
coverage: a stage win near the flat max still clamps there with no
bonus bought; the same win with `funds_cap_bonus` set lands the full
delta past the old flat max instead of being clamped short.

### A combat stage can now be lost instantly too — the player's own support argued down to nothing (2026-10-01, Cameron)

The mirror image of 2026-09-29's instant win (§12, "A combat stage can
now be won instantly by arguing the opponent down to nothing"): where
that rule fires when `state.bar.opponent <= 0`, `BattleEngine._check_
outcome()` now checks `state.bar.player <= 0` right after it, under the
same `has_threshold` gate (every Shared_pool Combat stage — not a press
conference, not the TV debate's survival bar, not a scored stage), and
ends the stage outright in a loss (`outcome.reason.player_argued_out`,
a new Text-tab row). Two design calls, made rather than left for Cameron
to discover by accident, both because the opponent's own side of this
rule already settled them the same way:

- **It ends the whole stage, not just the current bout.** A committee's
  own instant-win advances to the NEXT opponent when the one in front of
  you is emptied out, because there's a fresh opponent waiting;
  symmetrically there is no fresh *player* waiting once the one at the
  table has been argued down, so `state.bar.player <= 0` is an outright
  loss even mid-sequence, never a bout reset.
- **A turn that empties both sides at once is a win, not a loss.** The
  existing opponent-emptied-out check already runs earlier in
  `_check_outcome()` than this new one, so the same priority the
  threshold-win check already enjoys over the opponent's own instant-win
  extends one step further: cross the threshold → win; empty the
  opponent → win; only then, empty your own side → loss. A single card
  that happens to drain both at once still reads as an ordinary win, the
  same reasoning CLAUDE.md already gives for threshold-vs-opponent-empty.

No stage in `stages.json` starts at `player_start: 0` for a Combat room
(only two Non-combat rows do, which never reach `BattleEngine` at all),
and `_check_outcome()` is only ever called after a card resolves or a
turn ends, never at `setup()` — so this cannot fire before the player
has had a turn. `tests/test_battle_engine.gd` gained three tests
alongside the existing opponent-side ones: a single-opponent room and a
mid-committee-sequence room both end outright in a loss when the
player's own support is driven to 0, and a turn that empties both sides
at once is confirmed still a win.

### The Level Intro screen gets a bill-lean choice (2026-10-01, Cameron)

Cameron's ask: on a bill level's Level Intro screen, after the staff
finish speaking, show the player protagonist's own internal thought about
the level, then let them pick "Lean Support" or "Lean Oppose" on the
bill's topic — two boxes, each with the player's own party leader's
headshot. The choice moves Party support ± depending on whether it agrees
or disagrees with the party's own stance on the bill.

- **Scope**: only a level that names a Floor Vote bill
  (`DataDB.get_floor_vote(level_id)` non-empty) gets this step — this is
  the level's own bill, read off whichever of its `stage_1..stage_10`
  slots names a `BIxx`, exactly §7.7's existing lookup. `OfficeScreen.
  _on_start()` now routes to the Level Intro screen on EITHER a written
  staff cue OR a bill, where before it was staff cues alone — a bill
  level with no staff cues at all still gets this screen now, since the
  lean choice is its whole point. `LevelIntroScreen.gd`'s own sequencing
  gates `%ContinueButton` (`disabled = true`) the moment a bill is
  present, so the choice can never be skipped by clicking through fast —
  the one place this screen needed real gating, since before this it had
  none at all (`_on_continue()` was always clickable).
- **Three new pieces of workbook data**, all per the user's own
  instruction that every number and line of text stay editable in the
  workbook, not hand-rolled in a script or a hidden JSON table:
  - A new **Level Intro Thoughts** tab (`data/level_intro_thoughts.json`,
    optional, blank-tolerant, one row per level_id) for the player's own
    thought line — kept as its own tab rather than another row on Level
    Intro Cues, since that tab's key is (level_id, role) and a thought
    isn't any one staff member's role, it's the level's own.
  - A new Balance lever, **"Lean: Party Support Delta"**
    (`balance.json`'s `lean_party_support_delta`, 2 — first-draft,
    Cameron's to retune) — the ± magnitude applied either way.
  - Two new Text rows, `level_intro.lean_support`/`level_intro.
    lean_oppose` ("Lean Support"/"Lean Oppose"), the two button labels.
- **"The party's position" is the bill's own Disposition** (Floor Vote
  Party Positions' existing Supportive/Opposed/Neutral column for the
  player's own party), not a vote-tally bucket — it's the field already
  designed to answer exactly this question. A Neutral disposition never
  rewards or penalizes either lean, since there's no stance to agree or
  disagree with. New pure rule, `scripts/rules/BillLean.gd`
  (`party_support_delta(own_position, lean, magnitude)`), and
  `LevelIntroCues.player_thought(thoughts, level_id)` for the thought
  lookup — both pure/UI-free per §12, both covered by new GUT tests
  (`tests/test_bill_lean.gd`, `tests/test_level_intro_cues.gd`'s new
  cases). The delta lands via the same `GameState.apply_floor_vote_
  favorability({own_party: delta})` a real Floor Vote's own favorability
  already uses — no new apply path.
- **UI**: two new cards on the Level Intro screen, each a leader portrait
  (`parties.json`'s `leader_opp_id`, the player's own party — both boxes
  show the same single leader, since there's only one) above a button,
  built via `tools/build_level_intro_scene.gd`'s new `_add_lean_row()`/
  `_add_lean_card()` (that tool is confirmed safe to rerun, unlike
  `build_battle_scene.gd` — see §13's own note). Hidden until every
  staff/thought line has shown, the same `lines_shown` polling
  `_process()` already used for swapping the speaking portrait.
- Confirmed end to end with a throwaway driver (deleted before commit,
  this session's own convention) against a real level (LV31, the Ainu
  Heritage and Language Act / BI01) and a real protagonist (PC02,
  Frontier Party — Opposed on BI01): Continue stayed disabled until a
  lean was picked, the leader portrait resolved to Frontier Party's own
  leader (OP27) on both boxes, picking "Lean Oppose" (aligned with the
  party's own Opposed stance) moved Party support by the full +2, and
  "Let's go" correctly landed on the level's own real first stage
  afterward.

### A text audit: 25 more sentences moved out of scripts and into the workbook (2026-10-01, Cameron)

Asked to review every `.gd` file for text that should have been a Text-tab
row and move what qualified. A systematic grep across `scripts/ui/` and
`scripts/rules/` for quoted English sentences, filtered by hand, found a
real, bounded set — several of them sitting right next to an already-
converted sibling line, which is what made them easy to confirm as gaps
rather than a deliberate exception:

- **`BattleScreen.gd`'s `describe_room_for()`** (the card-zoom's stage-
  affinity line: "Being greatly enhanced by supporters.", etc.) — its own
  sibling, `describe_question_for()` right below it, already read its
  three lines from `card.question_strong/medium/weak`; this one never
  had been. Five new keys, `card.room_greatly_enhanced/enhanced/neutral/
  suppressed/greatly_suppressed`.
- **The battle Details panel**, mostly converted already (`battle.
  one_at_a_time` was already `Text.say()`-driven) but with real gaps
  beside it: the always-visible "Gaffes {current} / {limit}" status-row
  label (`battle.gaffes_status`), the "You: {name}"/"Opponent: {name}"
  lines (`battle.you_name`/`battle.opponent_name`), "In the room:
  {mix}." (`battle.room_mix`), the shared-pool rules paragraph
  (`battle.shared_pool_rules`), "This question invites a {suit} answer."
  (`battle.question_invites`), and the pleased/annoyed lines
  (`battle.nobody_pleased`/`battle.pleased_so_far`/`battle.
  annoyed_so_far`).
- **`Overlay.gd`'s own default "Back" button label** — the widest reach
  of anything found, since every panel in the game that uses `Overlay`
  gets it. New `ui.back`, read in both of `Overlay.gd`'s two call sites
  (`_build()`'s own default, and `open()`'s fallback when no `back_text`
  is given).
- **`LevelIntroScreen.gd`'s own "Let's go"** — inconsistent with its own
  newer sibling, `StageTransitionScreen.gd`, whose equivalent button
  already read `stage_transition.continue`. New `level_intro.continue`.
- **The Office header** — `"{name}'s Office"` (shown only when the
  protagonist has a name but no party; `office.title_named`) and the
  header's own small Japanese accent, `"陳情"`, which was typed directly
  into the script rather than read from the Text tab like every other
  Japanese accent in the game (`office.subtitle_jp`).
- **The Levels list and briefing panel**, again partially converted
  already (`reward.delta`, `reward.nothing_set` sit right beside these):
  the list's own blurb (`office.levels_blurb`), "Tier {tier}" headings
  (`office.tier_heading`), the panel's own title (`office.levels_title`),
  a per-stage "What winning this is worth has not been set yet."
  (`reward.stage_not_set` — distinct from the existing `reward.
  nothing_set`, which is for a whole level with nothing set at all), the
  briefing's fallback title (`office.briefing_fallback_title` — a
  fallback only; every real level has its own `description`, so this
  cannot currently show) and its "Go in" button (`office.go_in`).
- **The level-start refusal message**, "This level cannot start:\n•
  {problems}" (`office.level_cannot_start`), at both of its two call
  sites (`OfficeScreen.gd`'s `_on_start()` and its resume-mid-level
  path).
- **One title reused rather than duplicated**: the Backing panel's own
  `_backing_panel.open(...)` call was passing the literal string
  "Backing" as its title, when `office.backing` ("Backing") already
  existed — it is the Office button that opens this same panel, just
  never reused for the panel's own title. No new key needed there.

**What was NOT moved, and why** — three categories deliberately left as
code, not oversights: the rules-layer's own diagnostic strings
(`LevelRunner.problems()`, `BattleEngine`'s `setup_problems`/
`_refused()`, `IntentRunner`, `FloorVoteEngine`, `OfficeHoursEngine` —
workbook-authoring-mistake messages like "a stage has no seq number",
not narrative content; moving them into the workbook that is broken to
explain the breakage would be circular); `BootCheck.gd`'s own labels
("Game data", "Floor debate") — a developer/QA diagnostic screen (§11's
M0), not player-facing gameplay; and internal lookup constants
(`Ledger.STAFF_ROLES`, `ModifierEffects`'s Jiban→"Constituency support"
map, `FloorVoteEngine.BUCKETS`) that have to match real data elsewhere
and are not duplicated sentences at all.

25 new Text-tab rows (344-368), same raw-XML workbook technique used all
session. Confirmed with a throwaway driver (deleted before commit): a
real screenshot of the Office (the "陳情" accent rendering correctly next
to the English title), the Levels panel (blurb, "Tier 0" heading, no
raw keys or unfilled placeholders), and a real battle's Details panel
("You: Haru Yashi · Frontier Party", "Opponent: Yuriko Mayeda · Frontier
Party", the room-mix and shared-pool-rules lines) — all reading real
wording, not keys or `{placeholders}`. Full GUT suite (922 tests) and
`tools/verify.sh` (including `click_test.gd`, which clicks "Back" on
real overlay panels, and `loop_test.gd`, which plays a real battle
through `BattleScreen`) both confirmed green afterward.

### A pure-special-effect card read as useless in every room (2026-10-03, Cameron)

Reported from a real playtest: "Work the Room First" (C11, `special:
buff_next_card_this_turn`) showed greyed out in hand in the Agriculture
committee, its own card-zoom saying it does nothing in this room. Not
specific to that stage — `BattleEngine.preview()`'s own `does_nothing`
check (used by both the hand's dimming and the card-zoom's own text) only
ever looked at a card's five plain resolved numbers (`self_plus`, `draw`,
`gaffe`, `opp_minus`, `guard`). C11 prints all five as 0 by design: its
whole effect lives in `SpecialEffects.gd`'s own `flags` side channel
(`next_card_bonus`), which the check never inspected at all — so the card
read as useless everywhere, not just the room a playtest happened to
catch it in. Fixed by also requiring `flags.special_triggered` to be
false before calling a card inert — the same `SpecialEffects.apply()`
flag every special effect already sets when it actually fires, whether or
not it touches one of the five plain numbers. New GUT test,
`test_a_pure_special_effect_card_is_not_called_useless()`, sits beside
the existing "does nothing" suite in `test_battle_engine.gd`.

While verifying this, `tools/verify.sh`'s `loop_test.tscn` turned out to
fail on a WIN — confirmed unrelated to this fix (reproduces identically
on the commit before it): the level `loop_driver.gd` plays first picked
up a second stage (`ST07`, Office Hours) from a recent workbook upload,
and the driver's own `EXPECTED_STAGES := 1` constant and Combat-only
click logic are now stale against it. Not a game bug — winning correctly
advances into the Office Hours stage; the driver just doesn't know how to
play a Non-combat screen. Left as a known gap, not fixed in this pass. **Fixed 2026-10-05:** `loop_driver.gd` now plays whichever screen each stage hands over (BattleScreen or VisitorScreen) until the Office returns, and `EXPECTED_STAGES` became a `MAX_STAGES` ceiling, since a lost combat stage ends a level early. Checked on both the loss path and a forced-win path through Office Hours.

### The Funds cap was already at its hard ceiling by default (2026-10-04, Cameron)

Reported from a playtest: "the income and XP point caps are not applied by
default." Diagnosed as two unrelated things, confirmed by actually reading
every write path rather than guessing:

- **XP has no cap anywhere, by design** — `GameState._move_xp()` is a
  plain `xp += delta`, and XP is deliberately not one of the four Sanban
  variables (Constituency support, Reputation, Funds, Party support) that
  carry a min/max. Cameron confirmed: correct as is, no cap wanted.
- **Funds' cap was real but wrong**: `GameState.funds_cap_bonus` (SH19,
  "Increase Office Funds Cap") was added straight onto sanban.json's own
  Funds "max" (1,000,000) — so a FRESH run, with nothing purchased, was
  already sitting at the full 1,000,000 ceiling, and every SH19 purchase
  after that pushed the cap PAST 1,000,000 with nothing to stop it. Both
  halves of "not applied by default" were literally true: the default cap
  was the hard ceiling itself, not a lower starting point, and the hard
  ceiling itself was never actually enforced as a ceiling.

Cameron's fix, confirmed directly: **100,000 is the real starting cap**
(a new `rules.json` lever, `funds_starting_cap`, the same self-documenting
`{value, options, question, means}` shape every other open-decision lever
here uses), each SH19 purchase ratchets it up by its own 100,000
`funds_cap_increase` exactly as before, and **1,000,000 is now a true hard
ceiling** no amount of purchases can ever cross —
`GameState._sanban_row("Funds")` computes the effective cap as
`mini(funds_starting_cap + funds_cap_bonus, hard_max)`, and
`buy_funds_cap()` refuses a purchase outright (`shop.funds_cap_maxed`,
new Text-tab row) once that sum already equals the ceiling, rather than
letting the player spend XP on a purchase that does nothing.

**A second, real bug surfaced while fixing the first one**: lowering the
default cap meant a balance already sitting above the new (lower) cap —
a test fixture, or in principle an existing save — would get silently
reset DOWN to the new cap on its very next write, even a pure SPEND. The
underlying `MetaRules.clamp_meta()` clamped the RESULT of every write
into `[min, max]` regardless of which direction the delta moved, so an
over-cap balance couldn't be spent down cleanly; the write itself
snapped it back to the cap first. Redesigned: `clamp_meta()` now takes
`before` and `delta` separately (not a pre-summed value) and computes
`effective_high := maxi(high, before)` — once a balance is already over
the cap, a further GAIN is blocked entirely (not partially let through,
not silently discarded past the cap), but a SPEND always lands in full,
and a later gain is limited by the real cap again the moment the balance
is back under it. All four real call sites (`GameState._apply_meta_
reward()`/`_move_meta()`, `MetaRules._apply_deltas()`/
`apply_score_effects()`) updated to the new signature.

Caught two more stale test fixtures the same way the SH09/EXPECTED_STAGES
gaps were caught — a test hardcoding the OLD flat-1,000,000-ceiling
assumption instead of reading the real effective cap:
`test_game_state_spending.gd`'s own `_funds_row()` now reads
`GameState._sanban_row("Funds")` (the effective cap) instead of
`DataDB.sanban`'s raw row (the hard ceiling) — the two are different
numbers by default now, where they used to be the same number.
`test_inventory.gd`'s `test_buying_a_funds_cap_increase_raises_the_
effective_cap` rewritten around the real starting-cap/ratchet/ceiling
shape, plus two new tests: the effective cap never exceeds the hard
ceiling no matter how large `funds_cap_bonus` gets, and a purchase at
the ceiling is refused. `test_meta_rules.gd` gained
`test_clamp_meta_never_confiscates_a_balance_already_over_the_max()`,
proving the spend/gain asymmetry directly. Full GUT suite (938 tests)
and `tools/verify.sh` confirmed green afterward (`loop_test.tscn`'s own
pre-existing, already-documented WIN-path gap above is the one
unrelated, known failure).

### The 2026-09-27/28 player-perspective UI review

Every mechanic proven correct is not the same as every screen reading
clearly to someone seeing it for the first time — so this pass took one
screenshot per screen *shape* (not per stage, same reasoning as
`design/PLAYTEST_CHECKLIST.md`), at the real 1080×2340 resolution, and
cross-checked each one against the real code and data behind it rather
than trusting a first impression. `design/UI_PLAYER_REVIEW.md` is the
result — findings tagged Confusing/Inaccurate/Lacking, design-touching
items (ST06's bar label, a Supplies item's name, the flat 50 booster
standings) left as open questions for Cameron rather than decided here.
All three are now answered: ST06's `bar_unit` is "Viewer Tone" (edited
directly in the workbook's Stages tab and re-exported — only ST06's own
cell changed; ST04 and ST19 still correctly read "Press tone"); `"ね3"
Coffee` is confirmed as an intentional in-universe brand name, not a
data artifact; and the flat-50 booster standings now have a real
mechanism to vary. First pass put the override in a hand-maintained
`start_by_booster` table inside `data/booster_standing.json`; Cameron
asked whether the starting value already lived on a workbook sheet he
could just edit, so it moved there instead — the Boosters tab now has
its own **Starting Standing** column (`boosters.json`'s own
`starting_standing`), which `GameState.reset_booster_standing()` reads
per booster before falling back to `booster_standing.json`'s flat
`start` for any row the column leaves blank. The column itself is still
blank for all 16 organisations — how warm each real organisation is to a
brand-new legislator is Cameron's own political-characterization call,
left for him to write in the workbook rather than guessed at.

Everything else — three real layout bugs with no design call attached —
was fixed directly in a follow-up pass: the battle Details panel's text
bleed-through (its backdrop now uses the same fully-opaque style
`CardZoom` already did) and its party-colour labels moved from the very
end of the block to sit right next to the "You:"/"Opponent:" lines they
describe; the Party Steering Committee Check-In header no longer clips
its Japanese accent and visitor counter off the right edge
(`VisitorScreen.gd` now has its own `_fit_stage_name()`, the same
wrap-long-titles fix `BattleScreen` got in the 2026-09-27 playtest pass,
plus a scene fix — `VisitorScreen.tscn`'s header `Title` container needed
`size_flags_horizontal` set to expand, the same as `BattleScreen.tscn`'s,
or the wrapped label had nowhere to wrap into and collapsed to one letter
per line); and the Level Intro screen's CueBanner no longer covers the
speaking staffer's own portrait (the screen used to centre its portrait
vertically with two expanding spacers, landing it in the banner's fixed
band — the top spacer no longer expands, so the portrait sits above it).

One suspected engine bug was chased down and ruled out along the way: a
screenshot of a committee sequence's second bout appeared to show gaffes
carrying over from the bout just won, seemingly contradicting §7.5's own
claim that `_reset_for_new_bout()` clears them. It didn't — the
screenshot driver's own greedy-play helper only checked its stop
condition between turns, so it kept playing cards into the freshly reset
bout before the loop noticed the fight had moved on. Fixed the driver,
not the engine; the corrected shot shows a clean `gaffe=0/5` on turn 1 of
the new bout, exactly as documented. Worth recording because it's the
same "is this real or is this the harness" question this session's
stress-testing work keeps running into, and this time the answer was
"the harness."

Also fixed in passing, found the same way this session finds most
`<null>`-class bugs — by actually looking at a real screenshot: a battle
Details panel could show the literal text `<null>` for a side with no
party, the same bug class already guarded for opponent titles.
`PartyDisplay.party_name()` (`scripts/rules/PartyDisplay.gd`) is now the
one place every party-display call site reads the field from, rather
than stringifying it directly.

### A new workbook upload dropped the Question Themes tab, and renumbered the whole Shop tab (2026-10-04)

While landing the Funds-cap fix above, pulling in Cameron's latest
workbook/asset upload (merged into this branch) surfaced two real,
independent changes on his end, not bugs in anything built this session.

- **The "Question Themes" tab is gone from the workbook.** It used to
  fold into each question's own `pleases_boosters` field
  (`export_data.py`'s `fold_questions()`) — never a real standalone
  output file (the exporter pops the raw table after folding it in), so
  nothing downstream depended on the file itself. But its total absence
  was a hard export error before this fix: an entire tab missing is
  different from a tab with blank rows, and the exporter didn't
  distinguish them. Fixed by adding `"optional_sheet": True` to that
  `SHEETS` entry, the same degrade-gracefully bargain a totally blank
  tab already got — re-export is clean again. **The real consequence**:
  with the tab empty, every question in the game now resolves with no
  organisation to please, which the existing GUT coverage correctly
  flags (`test_every_question_has_somebody_to_please_and_somebody_asking`
  fails for all ~140 real questions) — a strong answer anywhere in the
  game currently pleases nobody. This is real content loss, not a test
  bug, and it's Cameron's to say whether the tab's removal was
  deliberate (a rewrite in progress) or an accident.
- **The Shop tab was fully renumbered**, compacting the gaps left by the
  two defunct SH13/SH14 rows removed 2026-09-30: `SH15/16/17→SH09/10/11`
  (the three random-card-unlock tiers), `SH18→SH12` (staff recruitment
  tier), `SH19→SH13` (Increase Office Funds Cap — the item this
  session's own Funds-cap fix calls by ID), `SH20→SH14` (Extra Draw),
  and four new Level Buff items (`SH15-18`: Extra Energy/Guard/Gaffe Cap/
  Turn) plus `SH25→SH19` (Host National Booster Dinner) and a new
  `SH20` (Host District Walking Tour). **The real game is unaffected** —
  every production call site dispatches by the item's own data field
  (e.g. `item.get("funds_cap_increase") != null`), never a hardcoded ID,
  confirmed by grepping `scripts/` outside `tests/`. Only the test suite,
  which intentionally hardcodes specific IDs to exercise specific
  mechanics, went stale: ~18 GUT tests across `test_inventory.gd` and a
  few others now reference pre-renumbering IDs (`SH25` for the National
  Booster Dinner item, etc.). This session's own two new Funds-cap tests
  were fixed (`SH19`→`SH13`) since they're squarely part of the feature
  just built; the rest of the renumbering fallout — a larger, multi-file
  job — was left for a follow-up pass rather than absorbed silently.
  `tools/verify.sh`'s own `shop_items_test`/`inventory_test` interaction
  drivers hit the same stale-ID wall (`SH15`/`SH18`/`SH19`/`SH25`/`SH26`
  all moved) — confirmed as the same pre-existing gap, not a new
  regression, before landing the two fixes below.

### The Question Themes tab is back, updated for the current question set (2026-10-04, Cameron)

The tab noted missing above is restored — Cameron asked for it back,
rebuilt against the CURRENT question content rather than the old one.
The old tab only ever covered 72 themes (the original Press/Town Hall
question set); the real `data/questions.json` today carries 146 distinct
theme strings across all five question-asking rooms (press conference,
Town Hall, Lobbyist Meeting, Policy Study, Media Ambush — the last three
are new since the old tab existed). The 72 old mappings were pulled
straight from an untouched pre-deletion commit and reused unchanged; the
other ~74 are a fresh draft against the now-18-strong booster roster
(six of which — Students United, Family Network, Yezo Artisans Guild,
Commuter Committee, Our Traditional Society, Innovation Society,
Members of Parliament, Constituency Voters — didn't exist when the old
tab was written), same "Claude's draft, Cameron corrects" bargain the
tab's own Why column has always carried. Two exact-case-sensitive
duplicates in the current question data (`Base Burden`/`Base burden`,
`Emergency Powers`/`Emergency powers`, `Family Law`/`Family law`, etc.)
each got their own row rather than being silently merged, since the
fold join in `export_data.py` matches theme strings exactly and a single
row would have left one capitalization unmapped.

Built with a new, larger-scale version of the same raw-XML zip-surgery
technique this project has used all along — this time adding a whole
new worksheet (146 data rows + a header, `xl/worksheets/sheet42.xml`,
one new `<sheet>`/`<Relationship>`/`<Override>` entry each in
`workbook.xml`/`workbook.xml.rels`/`[Content_Types].xml`) rather than
editing an existing one. Every cell uses `inlineStr`
(`t="inlineStr"><is><t>...</t></is>`) instead of a `sharedStrings.xml`
reference — the established "never touch sharedStrings.xml" discipline,
extended from a single appended row to an entire new sheet. Verified the
same way every other workbook edit here is: every other sheet's own
`iter_rows(values_only=True)` compared old-vs-new and found byte-for-byte
identical before the swap, then a clean `export_data.py` run. The
`"optional_sheet": True` flag added when the tab went missing stays in
place — it costs nothing now that the tab exists again, and means a
future accidental deletion degrades gracefully instead of blocking every
other change in the same upload, same as it did this time.

The 18-item "names no organisation to please" GUT failure class
(`test_every_question_has_somebody_to_please_and_somebody_asking`, one
assertion per real question) is gone — confirmed before/after (18
failures → 0 from this class specifically; the unrelated Shop-renumbering
fallout noted above is untouched by this fix).

### Town Hall only ever fought the first of its four constituents (2026-10-04, Cameron)

Reported from a real playtest screenshot: beating the first Town Hall
attendee ("Taken care of — the support threshold was reached") closed
the whole stage and offered "On to the next stage," even though the
stage is set up for 4 opponents ("1 of 4" in the caption). Confirmed by
reading `stages.json`'s real ST05 row: `opponent_count` was correctly
`{min:4, max:4}`, but `Sequence Mode` was `single` — the one setting
that tells `BattleEngine._check_outcome()` whether a threshold win
should advance to the next opponent or end the stage outright
(`scripts/rules/BattleEngine.gd`'s `if _sequence_mode != "single" and
has_more_opponents(): _advance_to_next_opponent()`). With
`sequence_mode` left at its default, the other three opponents were
being built into the battle config and shown in the UI's own "X of N"
caption, then simply never fought.

**Not fixed as a committee-style "reset."** The engine already has a
third sequence mode, `"stream"`, purpose-built for exactly this shape —
its own source comment reads "a town hall: the clock and your record
carry across the queue, but each new face is a fresh three energy,"
and a GUT test (`test_a_town_hall_keeps_the_clock_but_refreshes_the_
energy`) already proves it against a stage literally named `TOWNHALL`.
`"reset"` (what committees use) would also wipe gaffes, the turn
counter, and the whole deck/hand/discard pile between every constituent
— a much harsher reset than CLAUDE.md's own §7.3 ever described for
Town Hall, and not what the stage's own `stage_types.json` draft (a
pre-canon config file, confirmed dead for every real level today since
`BattleSetup.resolve_type()` only fires on a `"type"` field no real
level sets) already specified for it. `"stream"` was simply never
wired from that old draft config into the real canon `stages.json` row
— a one-cell fix (`Sequence Mode`: `single` → `stream`), same raw-XML
technique as above, confirmed by comparing every other sheet's rows
before/after and finding only that one cell changed.

Confirmed end to end with a throwaway driver (deleted before commit):
building LV01's real ST05 and forcing a threshold win against the first
of its four opponents (Emi Katsuragawa) now advances to the second
(Daichi Moribe) rather than ending the stage — gaffes and the turn
counter carried over unchanged, energy refreshed to a full 3. Full GUT
suite and `tools/verify.sh` confirmed no new failures (the Shop-
renumbering fallout above is the only pre-existing gap either run
still shows).

**Floor Debate and Party Caucus had the same bug — now fixed too
(2026-10-04, Cameron: "if a stage is set to have multiple opponents it
needs to cycle through them").** ST02 (Floor Debate) and ST03 (Party
Caucus) carried the identical `opponent_count: 2` /
`sequence_mode: single` mismatch Town Hall just had — both only ever
fought the first of their two opponents. Neither uses `"reset"` (that
would wipe gaffes/hand/deck/clock between the two, which is a committee
shape, not a continuous one-room debate) or `"stream"` (that explicitly
tops energy back up to full for each new face, which is Town Hall's own
shape, not a floor debate's). Both got the engine's **third** sequence
mode instead, `"continuous"` — defined by Cameron directly: a stage is
continuous when its energy is a pool that carries across opponents
without resetting. The engine already had this mode fully built and
GUT-tested (`scripts/rules/BattleEngine.gd`'s own doc comment: "the
floor debate: one room, one clock, and the next opponent inherits
whatever the last one left behind"; `tests/test_battle_engine.gd`'s
`_five_on_the_floor()` fixture and its own note that "no real stage in
stages.json ever sets sequence_mode to 'continuous'" — true until this
fix) — it had simply never been wired to the two real canon rows that
need it, the same gap Town Hall's `stream` mode had. One cell each
(`Sequence Mode`: `single` → `continuous`), same raw-XML technique,
confirmed by comparing every other sheet's rows before/after and finding
only those two cells changed.

Confirmed end to end with a throwaway driver (deleted before commit)
against two real levels: LV08's ST02 (Ayala Taiyounokage → Ani Aman) and
LV04's ST03 (Yuriko Mayeda → Isoroku Adams) — both advance to their
second opponent on a threshold win instead of ending the stage, with
gaffes and the turn counter carried over unchanged exactly as
`"continuous"` promises. Full GUT suite (921/938, the same 17
pre-existing Shop-renumbering failures as before) and `tools/verify.sh`
(the same 3 pre-existing interaction-test failures, same cause)
confirmed no new regressions from either fix.

### Cleared the Shop-renumbering test fallout; a real UI bug found while doing it (2026-10-04, Cameron)

Asked what was outstanding; the biggest real item was the ~18 GUT tests
and 2 interaction tests (`inventory_test`, `shop_items_test`) left stale
by Cameron's Shop-tab renumbering (§13's own earlier note). Walked every
file that hardcoded an old SHxx ID (`test_inventory.gd`,
`test_visitor_reward_application.gd`, `tools/stress_shop_items.gd`,
`tests/interaction/{shop_items,inventory,mash}_driver.gd`) and pointed
each at the item the ID now actually names — `SH20`→`SH14` (Extra Draw),
`SH25`→`SH19` (Host National Booster Dinner), `SH26`→`SH20` (Host
District Walking Tour), `SH18`→`SH12` (recruitment tier), `SH19`→`SH13`
(Funds cap, picking up a couple of refs the last session's own fix
missed), `SH16`→`SH10` (a Tier 2 XP card session SH16 no longer is).
The three Yen-cost "Purchase Random Tier N Card" items (once SH27-29)
are gone from the data entirely now, not renumbered — Cameron removed
them outright — so the GUT-level tests that specifically exercise the
Yen route (as opposed to the generic draw/pass/learn mechanism, which
any card-tier item proves equally well) got synthetic `SHTEST_CARD1/2/3`
fixture rows injected into `DataDB` for their own duration, the same
"fake row" technique already established for SH13/14's own 2026-09-30
removal; `stress_shop_items.gd`'s own `_try_funds_cap()` also had its
expected-cap math corrected to the real 2026-10-04 formula
(`min(funds_starting_cap + funds_cap_bonus, hard_max)`), which it had
never been updated for. `tools/verify.sh` went from 3 failing checks to
0; the full GUT suite's own Shop-ID-caused failures all cleared (the 3
remaining failures — stale question-pool-size assumptions against the
2026-10-04 content expansion, and one card's flavor text over its own
nine-word limit — are a separate, unrelated gap, left for its own pass).

**A real, previously-hidden UI bug surfaced by this fix**: `shop_items_
test`'s real-click walk through Rhetoric Training's full draw (1/3 →
Pass → 2/3 → Pass → 3/3 → Learn it) could never reach the Confirm click
before, since the old hardcoded "SH15" session no longer existed in the
real Office panel — the test always failed earlier with "Rhetoric
Training does not list SH15." With the ID fixed, a REAL new failure
appeared: clicking "Learn it" at 3/3 did nothing — no card granted, no
XP spent, the draw just silently vanished. Traced (debug prints added
to `Overlay.gd`/`OfficeScreen.gd`, removed again once found) to
`Overlay._input()`'s own "tap outside the content closes the panel"
logic: `_on_see_card()` opens the card-offer popup (`CardRevealPanel`)
ON TOP of the Rhetoric Training list (`CardsPanel`), which **stays open
underneath it** (the function's own existing comment says so) — but
Godot delivers `_input()` to every node that overrides it, in sibling
order, regardless of which one is actually drawn on top. A tap on the
TOP panel's own Confirm button still reached the BOTTOM panel's
`_input()` first; since that button's position can sit below the
bottom panel's own (shorter, unrelated) content rect, the bottom panel
read it as a tap outside ITSELF and silently closed, consuming the
event before the top panel — or its Button — ever saw it. Not a
Rhetoric-Training-specific bug: anywhere one Overlay opens on top of
another that stays open underneath, the same silent swallow could
happen. Fixed generally, in `Overlay.gd` itself: `_input()` now bails
out immediately if any LATER sibling `Overlay` (i.e. drawn on top of
it, since later-added siblings render in front) is also visible,
deferring to whichever panel is actually frontmost. Confirmed via the
same real-click test: a full draw now correctly learns the card shown,
pays for it, and the other two sessions (SH10, SH11) learn cleanly too.

### Resume or Abandon a level in progress (2026-10-04, Cameron)

Reopening the app mid-level used to silently resume it — the Start
button's own label just said "Resume level," and clicking it jumped
straight back into the saved stage with no other way out; the Levels
panel was unreachable until that level actually concluded. Cameron's
ask: a real choice, shown when the app reopens into a level still in
progress — **Resume the Level** (exactly the old behaviour) or
**Abandon the Level** (throws the attempt away and sends the player to
an ordinary Office screen, with the level staying exactly as available
as it was before — not shown-locked like a cooldown, not hidden like a
finished One-Time level).

**Where this can even fire**: confirmed by reading every path back to
the Office screen (`BattleScreen._on_outcome_closed()`) — normal play
never routes back to the Office mid-level at all; every intermediate
stage of a multi-stage level goes straight to the next one via
`StageRouting`, and the Office is only reached once `GameState.
finish_stage()` says the whole level is over. The ONE exception is
exactly the scenario asked about: the app was closed and reopened with
`GameState.is_in_level()` still true from the last save. So the new
choice is gated on that same flag, inside `OfficeScreen._build()`
(`_show_resume_choice_if_in_level()`, called right after the existing
`_show_trigger_alerts_if_any()` so, on the rare run where both apply,
this one ends up the frontmost panel) — it can never pop up mid-level
during ordinary play by construction, not just by convention.

**`GameState.abandon_level()`** (new): clears `level_runner`,
`level_bonuses`, and `shop_bought_this_level` — the same per-level state
a normal conclusion already resets — without touching
`level_last_completed_at`, `levels_completed_count`, or `levels_cleared`,
so `Ledger.level_is_hidden()`/`level_cooldown_remaining()` read the level
exactly as if it had never been started. Whatever the player already
banked from EARLIER stages of this same attempt (if it was stage 3 of 5,
say) stays banked — those rewards were already applied and saved when
each of those stages concluded; only the stage still ahead of them is
thrown away, and picking the level again starts it over from stage one.

**UI**: a new Overlay built in code exactly like `_trigger_alert_panel`
(`_resume_choice_panel`, `dismissable = false`, `show_back = false` —
the same "only the forced buttons get you out" shape `_card_reveal_
panel` already uses, since accidentally dismissing this one must never
silently pick either option) with two plain button rows, "Resume level"
(reusing the Start button's own existing `office.resume_level` string)
and the new `office.abandon_level`. Resume does exactly what the old
Start-button branch did — `StageRouting.scene_for(GameState.level_
runner.current_stage())` — and Abandon calls the new GameState method,
autosaves, and rebuilds the Office screen in place. The Start button's
own pre-existing "Resume level"/"Choose a level" label logic, and
`_on_start_pressed()`'s own is_in_level() fast path, are both left
exactly as they were: harmless now that this panel's full-screen opaque
backdrop (`Overlay.BACKDROP`, already fully opaque) covers the Start
button entirely until the player answers, but still correct as a
fallback.

Confirmed end to end with a throwaway driver (deleted before commit,
using the same "thin outer scene hands off to a driver parented at the
tree root" trick `loop_driver.gd` already established, since the driver
has to survive the very scene change it triggers): began a real level
(LV08), ended its first stage without ever calling `end_level()` —
exactly what a quit-and-relaunch mid-level leaves behind — then loaded
the real Office screen twice. Once, clicking the real Abandon button:
`is_in_level()` flipped to false, the panel closed, and `Ledger.level_
is_hidden()` confirmed the level was never marked complete or hidden.
Once more, clicking the real Resume button: the scene changed straight
to `BattleScreen`, landing on the exact stage (`ST04`) the level had
reached. Full GUT suite (935/938, the same 3 pre-existing unrelated
failures) and `tools/verify.sh` (all 8 real-click interaction tests
green) confirmed no regressions.

### A random 15-card opening deck (2026-10-05, Cameron)

A new run's deck is no longer the six Tier 0 cards plus a lowest-ID fill. `Ledger.opening_deck()` now rolls **15 cards** (`starter_deck_size`, 12 → 15) inside a recipe held on the Balance tab: **suits** balanced to within one card (15 over six suits is 3/3/3/2/2/2, the three double suits chosen at random), **tiers** 4 × Tier 0, 4 × Tier 1, 6 × Tier 2, plus one *flex* slot that is Tier 3 with a 25% chance and Tier 2 otherwise, and **never more than one Tier 3**. Five new levers, all Cameron's to retune: `starter_deck_tier_0_cards` / `_1_` / `_2_cards` (4/4/6), `starter_deck_tier_3_chance` (25, a percent) and `starter_deck_max_tier_3_cards` (1). Any slot left over after the three tier counts is a flex slot, so changing the deck size alone grows the flex pool.

The recipe is why it is not a plain random draw: Tier 2 is 29 of the 54 cards, so an unconstrained draw would hand out nearly all Tier 2. The tiers are shuffled across the suit slots (retrying while some suit has no card left of the tier it was dealt, up to 200 times), then each slot gets a random card of its suit and tier. If the card set can't satisfy the recipe, or the levers are absent (an older workbook, test fixtures), it falls back to the old deterministic fill (`_filled_deck()`) rather than a short deck. The roll happens once per new run (`GameState.reset_collection()`) and is saved with the deck and collection, so it never changes on reload; all four protagonists share the same roll logic. `Ledger.opening_deck(cards, balance, rng_seed)` takes an optional seed so tests are repeatable. Covered by new tests in `tests/test_game_state_starter_deck.gd` (300 seeds against the real cards: size, uniqueness, suit counts, tier counts, Tier 3 cap, variety, fallback). Workbook edit by raw XML on the Balance sheet, as always; `export_data.py` clean.

**Gaffe cards capped at 50% of the opening deck (2026-10-05, Cameron).** A "gaffe card" is one that *adds* to the gaffe meter (`gaffe` above 0; the four that remove gaffes don't count). Divisive and Duplicitous are gaffe cards almost without exception, so a suit-balanced random deck could otherwise hold 9 of 15. New Balance lever `starter_deck_max_gaffe_cards` (50, a percent; 50 of 15 cards = at most 7). `Ledger._recipe_deck()` re-deals any roll over the cap, within the same 200 attempts as the suit/tier fit. Absent lever = no cap. Two limits worth knowing: a cap very close to the minimum a suit-balanced deck can hold (4 of 15) would often exhaust the 200 attempts and fall back to the old fixed deck, which ignores the cap, and the cap applies only to the opening deck, not to decks the player builds on the deck screen (`Ledger.deck_refusal()` is unchanged). New tests in `tests/test_game_state_starter_deck.gd` (500 seeds against real data, plus a check that the uncapped roll really does exceed 7 sometimes).

### A How to Play guide (2026-10-06, Cameron)

A **How to Play** button on the title screen (`IntroScreen`) and on the Office opens one shared guide: the mechanics and win/lose conditions a new player needs. Both buttons are built in code (`IntroScreen._ready()`, `OfficeScreen._build_how_to_play()`, beside Appearance and Music) and open the same panel, `HowToPlayPanel.gd` (`attach()` builds the Overlay, `open()` fills it), so the guide can't differ by where it was opened. It does **not** open by itself at a first New Game (Cameron's call); the buttons are the only way in.

**All the words are the workbook's.** A new **How To Play** tab exports to `data/how_to_play.json`: `Entry ID` (HTxx), `Order`, `Group`, `Heading (EN)`, `Heading (JP)` (small muted accent), `Body (EN)`, `Screenshot`, `Caption`, `Video`; every cell but the ID is optional, and the tab itself is optional (an empty guide shows `how_to_play.empty`). 18 seed entries ship in five groups (The Goal, Winning and Losing, Cards, Between Battles, Saving), written as draft for Cameron to rewrite. Six Text-tab rows came with it (`intro.how_to_play`, `office.how_to_play`, `how_to_play.title/empty/watch/stop`). `scripts/rules/HowToPlay.gd` (pure) sorts entries by `Order` then ID (unnumbered last), gathers them under their `Group` (a group sits where its first entry does), and fills **live tokens** so a retuned number never leaves the guide wrong: `{majority}`/`{seats}` (Floor Debate ST02's win mark and seats), `{guard_cap}`, `{pass_penalty}` (rules.json), and `{gaffe_min}`/`{gaffe_max}` (lowest/highest gaffe limit across Combat rooms: it varies from 2 to 10, so there is deliberately no single `{gaffe_limit}`). An unknown `{token}` is left as written so a typo is visible; a GUT test proves every token in the real guide resolves.

**Screenshots and video** are file names, no extension, under `assets/howto/` (see `assets/howto/README.txt`): `Screenshot` "x" is `x.png`, `Video` "y" is `y.ogv`. **Video must be Ogg Theora (`.ogv`)**: it is the one format Godot decodes on every platform, and mp4/webm will not play on iOS or Android (ffmpeg: `-c:v libtheora`). A video shows a dark frame with a Watch the demo / Stop the demo button and plays nothing until pressed. A named file that does not exist shows a grey placeholder labelled with the file it is waiting for, the project's usual missing-art bargain. Confirmed end to end with throwaway real files (deleted): a PNG renders at column width with its caption, and a real `.ogv` starts, advances and toggles its button.

New tests: `tests/test_how_to_play.gd` (11, rules and real-data tokens) and `tests/interaction/how_to_play_test.tscn` (real clicks open the guide from both screens, check group headings, filled seat numbers and placeholders, and scroll to Back), added to `tools/verify.sh`. The intro screen's own click test is not part of `verify.sh`.

### The Office's button row got two intermediary menus (2026-10-06, Cameron)

The Office's row had grown to seven buttons. It is now Choose a level, Office Management, Marketplace, **Reputation and Results** and **Administration**. Reputation and Results opens a small menu holding **Important Stakeholders** and **Your Record**; Administration opens one holding **Appearance and Music** and **How to Play**. Each menu is an ordinary `Overlay` (`ReputationMenuPanel`, `AdministrationMenuPanel`, built in `OfficeScreen._build_menus()`), and each row in it is a button that opens the same panel it always did (`_show_organisations`, `_show_record`, `_show_cosmetics`, the How to Play guide). The four buttons keep their node names (`OrganisationsButton`, `RecordButton`, `CosmeticsButton`, `HowToPlayButton`) but now only exist while their menu is open (`Overlay.open()` rebuilds a panel's rows each time). The scene's old `OrganisationsButton` node is renamed `ReputationButton` (a small `OfficeScreen.tscn` edit; the Administration button is built in code beside it). Two new Text rows: `office.reputation_and_results`, `office.administration` (also the menus' headings). The old labels are unchanged.

**One non-obvious thing:** panels draw in the order they were added, and the menus are added after some of the panels they open (the scene's own `OrganisationsPanel`, for one), so `_menu_button()` moves the opened panel to the front of the Office's children after calling its opener; without that the menu would sit on top of the very panel it just opened. The menu stays open underneath, so Back from a panel lands on its menu again, and `Overlay._input()`'s existing "defer to a later visible Overlay" rule keeps clicks going to the frontmost one. The title screen's How to Play button is unchanged.

New real-click test `tests/interaction/office_menus_test.tscn` (the row has the two menu buttons and none of the four loose ones; each menu holds the right buttons; each panel opens above its menu and Back returns to the menu), added to `tools/verify.sh`. `cosmetics_driver.gd` and `how_to_play_driver.gd` now go through the Administration menu first.

### Cosmetic icon cells fixed; the art checklist tool works again (2026-10-06, Cameron)

The Cosmetic Packages tab's `Icon` cells read `{Workplace_Casual}` and `{Workplace_Modern}` with literal curly braces (the game would have looked for a file with braces in its name); they now read `Workplace_Casual` and `Workplace_Modern`, matching the drawn `assets/icons/Workplace_Casual.png` and `Workplace_Modern.png`. Workbook edit by raw XML (the two cells became inline strings; nothing else in the file changed).

`tools/art_checklist.py` had been crashing since 2026-09-26 because it still read `data/journalists.json` (deleted when journalists became ordinary opponents), so `design/ART_CHECKLIST.md` was out of date. The Reporters group is removed, and three icon sections are listed alongside Organisation icons: **Shop item icons** and **Cosmetic package icons** (each row's own `Icon` cell, falling back to its ID when blank, the same rule `InventoryPanel.icon_name()` uses; duplicates listed once). Re-run it with `python3 tools/art_checklist.py`; it only reads data and the disk. All 40 icons (18 organisations, 20 shop items, 2 cosmetic packages) are drawn as of this run.

### Three stale tests now follow the workbook (2026-10-07, Cameron)

`test_questions.gd` no longer expects exactly 20 questions per room (only that a pool is not empty), no longer enforces a nine-word limit on card cues (Cameron's call: length is the designer's), and `test_visitor_selection.gd` reads how many visitors ST07 draws from the Stages tab's own `opponent_count` instead of assuming 1. Growing a pool in the workbook can no longer fail a test. Full GUT suite: 956/956.

### The playtest bot got smarter, and its deck bug is fixed (2026-10-07, Cameron)

`tools/playtest_optimal.gd` (tooling only, no game change):
- **Deck bug fixed.** It used to roll a second opening deck and hand it to `set_deck()` before owning those cards ("C03 is not yours"), logging a false bug in every run. It now re-submits the deck `start_new_run()` actually dealt, and logs that deck.
- **Smarter play.** Each move scores every affordable combination of cards in hand by what they truly do in this room (`engine.preview()`: affinity, question grade, whether opponent support or guard count at all), treats gaffes as a budget to spend rather than dodge, values guard against the attack actually coming, values arguing a small opponent to zero, and orders buffs/draws first. It replays after every card because a draw changes the hand.
- **Real deck building.** It ranks owned cards by strength per energy and rebuilds the strongest legal deck each visit (before, it only topped up a short deck, so it never improved the opening roll).
- Result: the bot now clears all 60 levels on good opening rolls (e.g. PC01 and PC03 runs: Town Hall 19/28 and 29/31 won). It still stalls on some rolls: of four PC02 runs, two cleared 47 of 60 levels and two never won Town Hall. The stalled decks have markedly lower total `self_plus` (26 vs 34-38 for the clearing ones). That is a signal about how much the random opening deck varies in power, not a claim that the level can't be won by a person.
- Run the four protagonists one after another, not in parallel: parallel runs share one `user://` folder and contaminate each other.

### The playtest bot now takes backing and uses items (2026-10-07, Cameron)

`tools/playtest_optimal.gd` (tooling only): each Office visit it buys the most useful backing it is allowed (`Ledger.modifier_refusal()` decides which organisations are warm enough; it never spends Constituency support below 40, Reputation below 30 or Funds below the buffer) and buys battle-only shop items (stage/level buffs, never standing grants or player-choice items) with XP and Funds left over after cards, levels and staff (XP reserve 120). Held items are used at the start of every stage via `GameState.use_item_in_stage()` (a level buff once per level). The summary prints backing taken and items bought/used. Effect: with these two doors in play the bot cleared all 60 levels for PC01 and PC04 and Town Hall went from 0 wins to 28-30 of 30, consistent with Cameron's view that people win easily. Random-move mode skips items.

**Stage opponents are now a random draw (2026-10-07, Cameron).** They used to be the lowest opp_ids of the stage's pool (Town Hall was always OP102/103/104). `BattleSetup._opponent_for()`/`_opponents_for()` now draw at random from `eligible_opponents()` each time a level is set up, never the same person twice in one stage, still skipping anyone with the player's own name, and a pin in `level_opponent_overrides.json` still wins. Unseeded, like every other roll in setup. **Office Hours visitors are random too** (same day, Cameron: "all stage opponents of all types need to be random"): `_visitors_for()` draws at random from the eligible pool, no repeats, pin still wins. Question askers in press/town hall/lobbyist/media rooms were already varied (askers are spread across a randomly drawn question pool); Floor Vote leaders are fixed by party by design. Covered by `tests/test_opponent_draw.gd` and `tests/test_visitor_selection.gd`; GUT 959/959, `tools/verify.sh` green.

### A stage-trial mode for the bot, and what it found about the Cabinet committee (2026-10-07, Cameron)

`PLAYTEST_STAGE_TRIAL="ST18:60"` (stage:trials, optional `:threshold` and `:energy` overrides, memory only) makes `tools/playtest_optimal.gd` fight one stage many times as a well-equipped player (all cards, strongest deck, backing and items) and print a win rate. Results for PC02: ST09/ST16/ST17 committees 40/40; **ST18 Committee of the Cabinet 0/60 as tuned** (threshold 100 on a 100-point bar, energy a stage-long pool of 8, gaffe limit 3, opponent opens at 55), and 0/40 at every threshold from 60 to 90 with that energy. A perfect 8-energy selection tops out at a combined self_plus+opp_minus of about 31-35, so the room cannot be won as tuned. With threshold 60 it flips from ~0% to ~97% between an energy pool of 20 and 22; threshold 65 at 24 energy was 2%. These are the bot's numbers, not a person's, and not applied: ST18's numbers are Cameron's to set.

### The Cabinet committee (ST18) retuned for a ~45-50% bot win rate (2026-10-07, Cameron)

Stages tab, ST18 row: win threshold 100 → 60, energy per turn / energy pool 8 → 26 (it is an energy-pool room, so the pool is what bites). Chosen by averaging the bot's stage-trial mode (`PLAYTEST_STAGE_TRIAL`, backing only, 8 runs x 40 fights per setting, window 23-26 energy at threshold 60: 34% / 27% / 54% / 50%). Individual runs ranged 0-95% depending on the deck the bot assembled, so treat the average as +/-15 points; one later single check on PC03 got 12%. A person is expected to win more often than the bot. Workbook edited by raw XML (three cells), `export_data.py` clean, only those three values changed in `stages.json`.

### Two How to Play entries on live card numbers (2026-10-07, Cameron)

How To Play tab, group Cards: **HT19 "Card numbers change as you play"** (a card's displayed numbers are recomputed from the live battle after every play: next-card boosts and discounts, bonuses that need a clean gaffe meter or trailing support, and audience-mix bonuses) and **HT20 "Why a card is bigger or smaller"** (the room's suit match and a question's grade scale gain and opponent loss; guard, draw and gaffe are never scaled). Written in relative language only ("a larger boost", "a moderate boost", "held back", "reduced") and with no percentages or multipliers, so retuning affinity.json or the question multipliers in the workbook never makes the guide wrong. Raw-XML workbook edit (two rows, orders 121/122), clean export.

### A Staff Profile screen (2026-10-07, Cameron)

Tapping a staff member in Office Management → Staff now opens a **profile** instead of hiring on the spot: portrait (a labelled placeholder until staff art is drawn), name, role, hiring cost, then **Bonuses by tier**: one block per tier the person can be at (their own starting tier up to their highest tier), each with its bonus lines ("+2 standing with Party Faction", "+2 sentiment among Constituents") and, for a tier still to be bought, its upgrade cost ("Tier 1 · upgrade cost 30000 Yen"). The arrival tier reads "given when hired", a hired person's current tier reads "current", a step with no price entered reads "upgrade cost not set". **Hire** sits at the bottom with the usual greyed-out reason (cost, recruitment tier, already filled, fired); for the hired person it is **Upgrade** and **Fire** instead (Fire closes the profile and opens the existing severance warning). The list rows are just buttons now; a fired candidate stays greyed with no button.

`scripts/rules/StaffProfile.gd` (pure) builds the tier rows from `staff.json` plus the booster/segment names; `OfficeScreen._show_staff_profile()` draws them in `StaffProfilePanel` (built in code, before the fire panel so the warning draws on top). Eleven new `staff.*` Text rows (placeholders column filled in); bonus lines use only the data's own names, never raw IDs. Tests: `tests/test_staff_profile.gd` (7, real candidates: no upgrades, three tiers, starts at tier 1, names not IDs, sign kept) and `tests/interaction/staff_profile_test.tscn` (real clicks: open from list, check tiers/costs, Hire, reopen, Upgrade, Fire → warning), added to `tools/verify.sh`; `shop_items_driver.gd` now checks the recruitment-tier gate on the profile's Hire button, and `tools/shot_staff_driver.gd` calls `_on_profile_hire`. Full GUT 967/967, `verify.sh` green.

### Backing is now "Boosters", inside Reputation and Results (2026-10-07, Cameron)

The Backing screen (the organisations' modifiers, bought with Funds) moved out of Office Management and into the **Reputation and Results** menu, between Important Stakeholders and Your Record, and its label (`office.backing`, also the panel's title) now reads **Boosters**. Only that label changed: `office.backing_blurb`, `office.take_backing` ("Take their backing") and `office.funds_buys` ("Buys the organisations' backing") still say "backing" in their prose, Cameron's to reword if he wants. `OfficeScreen._show_reputation_menu()` holds the new `BackingButton`; `tests/interaction/office_menus_driver.gd` checks it opens above its menu and Back returns. Text-tab cell edited by raw XML; verify.sh green.

### Organisation images in three places (2026-10-07, Cameron)

Each organisation's icon (`assets/icons/{BOOSTER_ID}.png`, via `ArtLoader.icon()`, labelled placeholder when missing) now appears beside its row in **Important Stakeholders** and beside each backing in **Boosters** (`OfficeScreen._with_booster_icon()`). On the battle **Outcome panel** the three name lists (pleased / annoyed / argued out) became one row of tappable icons (`OutcomeBoosters`, built by `OutcomePresenter._build_booster_icons()`); tapping an icon shows "Name: ±N" (tap again hides). The number is the **net** for the stage, from the new pure `BoosterChange.compute()`: a question's pleased and annoyed amounts settle together, clamped to `question_swing_cap`, then the flat crush penalty on top, the same arithmetic `GameState` applies when the panel closes. Two new Text rows (`outcome.booster_hint`, `outcome.booster_change`); `outcome.pleased/displeased/crushed` are only used when a presenter has no icon container (tests). New tests in `tests/test_outcome_presenter.gd`; GUT 969, `verify.sh` green. Not yet checked against a real screenshot.

### A refilling press conference ended early with cards still in the discard (2026-10-10, Cameron)

From a phone screenshot: Press Conference ended at "Question 4 of 6 ... nothing left to say" and was lost. The real ST04 has no `draw_mode`, so it refills its hand each turn like any room, but `BattleEngine._check_outcome()`'s "can the player still answer?" test counted only the hand and the draw pile, not the discard, which is reshuffled into the draw pile at the next draw. Playing the last card in hand with the draw pile empty therefore closed the conference. The discard now counts whenever `draw_mode` is not `none`; a no-draw conference is unchanged. New test in `tests/test_battle_engine.gd`; GUT 970/970, `verify.sh` green.

### The briefing says what a loss costs and what resets between opponents (2026-10-10, Cameron)

Each Combat stage in the level briefing now says **"Losing this stage ends the level."** or **"…costs you, but the level carries on."** (from `loss_ends_level`), and a stage with several opponents adds **"Between opponents these start again: …"** and **"These carry over: …"** (`StageCarryOver.between_opponents()`, pure, mirrors `BattleEngine._advance_to_next_opponent()`; the battle Details panel shows the same lines via `CarryOverLines.for_stage()` (`scripts/ui/CarryOverLines.gd`)). Ten new Text rows (`briefing.*`).

Cameron's rules, confirmed against the engine: your support reaching 0 already loses the stage, and the level ends only where the stage's own `loss_ends_level` says so, so no new level-loss switch was built. Reaching the stage maximum already wins (a threshold win fires first, ending that opponent, or the whole stage on the last one); single-bar rooms (press conference, TV debate) stay as designed. New this pass: a **scored** room (`win_mode: "score"`, no real stage uses it today) now ends as a win when its bar is filled and a loss when emptied. **Open for Cameron:** ST19 (3 opponents) and ST21 (2) are `Sequence Mode: single`, so only their first opponent is ever fought, the same mismatch Town Hall, Floor Debate and Caucus had.

### ST19 and ST21 now cycle through their opponents (2026-10-10, Cameron)

The open item above is closed. ST19 Media Ambush (3 opponents, an energy **pool**) is now `Sequence Mode: continuous` and ST21 Policy Study Session (2 opponents, per-turn energy, a question room like Town Hall) is `stream`: the same two modes ST02/ST03 and ST05 use for the same shapes (Cameron's definition: continuous when energy is a pool that carries across opponents). I picked the modes from those precedents; each is a one-cell change in the Stages tab if he wants the other. Raw-XML edit (two cells), clean export, only those two `sequence_mode` values changed in `stages.json`. `test_stage_carry_over.gd` now fails if any Combat stage lists several opponents but is `single`.

### How each party sees the player: one model for all six parties (2026-10-10, Cameron)

`PartyOpinion.gd` (pure) blends two parts into an **opinion** (0-100) per party, your own included: **direct** (votes, rewards, leans: `Party support` for your own party, `party_standing` for the other five) and **stakeholder** (how the organisations the workbook ties to that party feel about you). Default blend 50/50 (Balance: `Party opinion: Direct Weight` / `Stakeholder Weight`); starting directs stay at 50. Stakeholder score = `50 + sum(weight x (standing - 50)) / sum(|weight|)`, so 50 is neutral, a **negative weight is a rival** (its good standing lowers the party's opinion of you), and the scale of the weights never matters. A party with no rows has no stakeholder part and its opinion is its direct number.

**Option A (Cameron): your own party's opinion drives the rules.** `GameState.party_support_effective()` (the blend) is what the Town Hall/Steering Committee check-in, the funding freeze and the free M09/M10 modifiers read instead of the raw meta number, and `GameState.effective_meta()` feeds the Floor Vote influence gate. Stage rewards, votes and leans still add to the stored `Party support`, so every existing source works unchanged. Consequence worth knowing: organisations now start at 30, so your effective party support starts below the stored number for most protagonists.

**Party Standing tab** (`data/party_stakeholders.json`): one row per (Party ID, Booster ID, Weight, Note). Party ID is a PTxx, or `OWN` for whichever party the player belongs to (Party Headquarters, Party Faction, Members of Parliament). New organisations or parties are new rows. **64 rows ship as Claude's draft from Cameron's party descriptions, his to correct**: Frontier (rural over city, lower on free market), Butsutou (social care, families, Buddhist and light Shinto), Country Initiative (social and national conservatives), Keizaijiyuutou (free market, cities, Chamber of Commerce biggest), Five Point Independents (special interests, media, constituencies, cities), Yezo Heritage Party (Ainu interests). Six new Balance levers (blend weights and the Hostile/Cold/Neutral/Warm/Allied cut-offs).

**12 new organisations (BO19-BO30), also a draft**: Buddhist Temples Association, Shrine Association, Care and Welfare Council, Veterans' Association, Taxpayers' Alliance, Financial Industry Association, Small Business Owners' Association, Consumer Advocacy Network, Urban Neighbourhood Alliance, Ainu Community Council, Ainu Language and Culture Foundation, Rural Revitalization Council. Names, Japanese names, romaji and tiers are Claude's drafts for Cameron to correct; no icons yet (labelled placeholders), no linked modifiers, no question-theme mappings. A new **Parties** page in Reputation and Results lists all six with colour, score, word, the two parts and who is helping or hurting. 12 new Text rows. Tests: `tests/test_party_opinion.gd` (12); the five Party-support trigger tests in `test_game_state_meta_tracking.gd` now run with no stakeholder rows so they still test the triggers alone.

### Your Record shows the live Party support; a theme rebalance is proposed (2026-10-10, Cameron)

**Your Record** now shows Party support as the live number the rules read (`GameState.party_support_effective()`, the blend of votes and stakeholders) with its change this level (`party_support_change_this_level()`, which counts both the stored number's change and the tied organisations' changes), so it agrees with the Parties page. The other three meta values are unchanged.

**`design/THEME_REBALANCE_PROPOSAL.md`** (a proposal, nothing applied): every Question Themes row pleases exactly one organisation today, 14 of 30 organisations are never pleased, and National Media is pleased by 31 of 193 questions. The proposal lets a theme please 1-4 organisations (the column already supports a list), gives every organisation at least 2 themes, moves 29 primaries to better fits, and lifts the thinnest parties' coverage (Yezo Heritage Party 18 to 52 questions, Butsutou 36 to 61). Cameron's to correct before it goes into the workbook.

### Ainu rights, fisheries and commuter questions; a strong answer can now set organisations back (2026-10-10, Cameron)

**24 new questions** across the five question tabs (Town Hall T74-T84, Lobbyist L61, L62, L64, L65, Press Q21-Q24, Policy Study B21-B23, Media Ambush A21-A22), all drafts for Cameron to rewrite, with 15 new Question Themes rows:
- **Ainu preferential rights** (11 questions, 7 themes: preferential rights, reserved seats, harvest rights, land return, language funding, cost, fairness). A strong answer pleases the Ainu Community Council and the Ainu Language and Culture Foundation (BO28/BO29) **and sets back** one organisation each from Country Initiative (BO15 Traditional Society, BO22 Veterans', BO20 Shrine), Five Point Independents (BO26 Consumer Network, BO27 Urban Alliance) and Keizaijiyuutou (BO05 Chamber, BO23 Taxpayers', BO24 Financial). Which organisation stands for which party follows the Party Standing draft; the pairings per theme are Claude's, Cameron's to correct.
- **Fisheries** (BO07; 6 questions, themes: fishing quotas, harbour upkeep, catch prices, seafood labelling) and **Commuter Committee** (BO14; 7 questions, themes: commuter fares, rail timetables, station access, road congestion). Pure please-themes.

**New mechanic (schema change, optional):** Question Themes gains an optional **Annoys** column (exports as a question's `displeases_boosters`). A *strong* answer on that theme sets those organisations back by `per_opposed` (3, hand-maintained in `data/booster_standing.json`). A weak or medium answer does nothing to them (a weak answer still annoys the *pleased* organisation, as before). It is its own list, `BattleState.opposed_boosters` / `BattleEngine.opposed_boosters()`, passed as a new final argument to `GameState.finish_stage()` and `BoosterChange.compute()`; it nets with a please/displease the same stage and obeys `question_swing_cap`. The Outcome panel's organisation icons include these organisations with their negative net. Because the party-opinion model reads organisation standing, this also lowers those parties' stakeholder score. It does not touch any party's direct number. New Text row `outcome.opposed`. Tests: engine (strong sets back, weak does not), `BoosterChange`, and `GameState` standing.

### The theme rebalance is applied (2026-10-11, Cameron)

`design/THEME_REBALANCE_PROPOSAL.md` went into the Question Themes tab: 105 of the 146 older themes now please 1-5 organisations (the Organisation column already took a semicolon list) instead of one, and their Why cell says "Rebalanced 2026-10-10 (draft)" with who was added. Every one of the 30 organisations is now pleased by at least 5 questions (before, 14 were never pleased); the most pleased are National Media (31), Ainu Community Council (30) and Rural Revitalization Council (21). The 15 themes added for Ainu rights, fisheries and commuters are unchanged. No code or schema change: `pleases_boosters` was already a list, and the engine, outcome icons and standing cap treat a multi-organisation theme as before (each pleased organisation gets its own +5, capped per stage). Raw-XML edit of the Question Themes sheet only; `export_data.py` clean. All pairings remain Claude's draft for Cameron to correct in the workbook.

### How to Play: which suits please which organisations (2026-10-11, Cameron)

Asked how clear the booster/suit mechanic is. Finding: **no organisation has a favourite suit in the data.** What pleases an organisation is the *question's own* S/M/W grade for the suit you answer with; the organisation only comes from the question's theme (Question Themes tab). The old guide (HT12, HT20) said the invited suit pleases "the organisation asking" without saying who or how a player could tell. New entry **HT21 "Who is pleased by which suit"** (Cards group, order 123) explains that and carries a live token `{pleasing_table}`: one line per suit naming the organisations it tends to please. `BoosterSuitTendency` (pure, `scripts/rules/`) computes it from `questions.json` (Strong +1, Medium 0, Weak −1, averaged over every question that pleases the organisation; listed when the average is at least 0.4, the organisation has at least 5 questions, and at most 4 per suit), so it follows the workbook and cannot go stale. `HowToPlayPanel.data_tokens()` is the one place the real data feeds the tokens (panel, tests and click driver). Today's table: Earnest: National Media, Ainu Language and Culture Foundation, Commuter Committee, Consumer Advocacy Network; Emotional: Financial Industry Association, Care and Welfare Council; Appeal: Agricultural Cooperatives, Party Faction; Data Driven: Labor Federation, Commuter Committee, Ainu Language and Culture Foundation, Small Business Owners' Association; Divisive: Party Headquarters, Agricultural Cooperatives; Duplicitous: Labor Federation, Consumer Advocacy Network, National Media, Innovation Society. The three cut-offs are constants in that file, not workbook levers (Cameron's to ask for if he wants them tunable). Tests: `tests/test_booster_suit_tendency.gd`; the token test now covers `{pleasing_table}`.

### New Game moved to the Administration menu (2026-10-11, Cameron)

The "New Game" button left Office Management and now sits in the **Administration** menu (`OfficeScreen._show_administration_menu()`, button `NewGameMenuButton`), under Appearance and Music and How to Play. It still asks first (the same warning/confirm panel, `_confirm_new_game()`); the menu closes before the warning opens so it is not left underneath. Same Text row (`office.new_game`). `new_game_driver.gd` now goes through Administration; `office_menus_driver.gd` is unchanged, since its generic "Back returns to the menu" check does not suit a button that closes its menu.

### Performance pass and cleanup (2026-10-11, Cameron)

**A benchmark first.** `tools/bench.sh <label>` runs `tools/benchmark.tscn` twice (headless, and on a virtual display so texture memory is real) and saves `design/bench/<label>.json`; `tools/bench.sh --compare A B` prints a before/after table. It measures data load, each screen's first ("cold") and later ("warm") load, battle redraw after a card and after a turn (on a real LV08/ST02 battle with a fixed seed), each Office panel's open time, and memory. Not in `verify.sh`: timings on the shared build machine wander 20-70% between identical runs, so `--compare` only flags a timing more than 30% worse (memory 5%). Memory is the reliable number. `design/bench/baseline.json` is the before; `after_phase1.json` the after.

| Measurement (display mode) | Before | After |
|---|---|---|
| Texture memory after every screen | 207 MB | 55 MB |
| First Office load | ~1.8 s | ~0.5 s |
| First battle screen load | ~0.54 s | ~0.40 s |
| Hand redraw (profiled alone) | ~10 ms | ~1 ms |

**What changed:**
- **Card frames** (12 PNGs, 1500x2100, about 12 MB each in memory) import with `process/size_limit=1300`: a card is never drawn larger than about 900x1260 (the zoom). The PNGs themselves are untouched. Backgrounds and portraits keep full size, since they can be drawn larger than any cap.
- **Card frames load on demand.** `CardView.frame_for(suit)` / `CardBackView.back_for(suit)` load a frame the first time a card of that suit is drawn and keep it, instead of preloading all twelve when the card scripts are first seen.
- **The hand stays on screen between redraws.** `HandPresenter.show_state()` used to take every card off the row and put it back each redraw; re-entering the tree was about 12 ms of a 15 ms redraw. It now adds new cards, removes gone ones and reorders with `move_child()`.
- **The battle Details panel is only rebuilt while open** (`_toggle_details()` fills it on open). It turned out cheap (0.4 ms), but there was no reason to rebuild a hidden panel.

**Cleanup (all confirmed unused by grep before removal):** `DataDB.get_affinity`/`get_tier_cost` (and the affinity cache), `Ledger.modifier_cost`, `HandPresenter.reveal`, `DragScroll.is_dragging`, `Audio.is_muted`, the never-connected `DataDB.data_ready` signal, two unused constants, an unused local; **16 Text-tab rows nothing asks for** (old New Cards shop, committee voting, card reveal; removed from the workbook by raw XML); `tools/build_office_scene.gd` and `tools/build_battle_scene.gd` (unsafe and drifted scene builders), the 18 `tools/shot_*` throwaway screenshot scripts (one already broken), the empty `assets/characters/journalists/` folder; **`data/stage_types.json`**, `BattleSetup.resolve_type()` and the `"type"` branch of the question-pool lookup (no real level ever set a `"type"`, so this was dead for every real stage), which also retires the unread `weak_answer_tone_cost` placeholder; and `lists.json` is no longer loaded at runtime (nothing read it; the exporter still writes and uses it).

**Left in place on purpose:** `data/playtest_cards.json` (empty, but its README keeps it as a proven hook for a future card); `GameState.buy_card()`/`Ledger.card_refusal()` (the playtest bot still buys through them); tests-only helpers that work as test probes (`BarModel.totals_balance`, `Ledger.deck_is_legal`, `BattleSetup.fill_tokens`).

**Both open questions answered the same day (Cameron): remove.**
- **M10 Cold Shoulder is gone**: its Modifiers-tab row, its place in BO01's linked modifiers, the "Party support: debuff (<)" Balance lever that granted it, and the `< 50` branch of `MetaRules.party_support_modifiers()`.
- **M12 Faction Patronage is gone too** (Cameron, same day): its Modifiers-tab row and its place in BO02's linked modifiers. It was the last user of the `UNLOCK_DISCOUNT` effect type, so that type is removed as well (`ModifierEffects.UNLOCK_DISCOUNT`/`unlock_discount()`, the exporter's allowed list, the Effect Type header comment on the Modifiers tab, and its two tests). No price had ever applied it.
- **Unread Balance levers removed** from the workbook: `W_self`, `W_opp`, `W_guard` (same unread family, removed with the others), `W_draw`, `W_gaffe`, `Primary suit share`, `Secondary suit share`; and the exporter no longer emits the empty `committee_size_bands` sub-table. Raw-XML row deletions on Balance and Modifiers, one cell on Boosters; only those three sheets changed.

### Every organisation now has at least 15 questions (2026-10-12, Cameron)

Cameron asked for 15 as a floor per organisation (a lean toward each one's natural suit, secular civic angles for Shrine Association and Our Traditional Society, one batch). Sixteen organisations were under 15 (Innovation Society had 5, Our Traditional Society 6, Students United 7). **52 new questions** (Press Q25-34, Town Hall T85-102, Lobbyist L66-77, Policy Study B24-30, Media Ambush A23-27) and **30 new Question Themes rows**, all drafts for Cameron to rewrite; the Why cells begin "Draft 2026-10-12". Many themes please two or three organisations so one question lifts several, and nine Commuter questions reuse existing themes. After the batch the lowest count is 15 (several organisations sit exactly on it, so removing a question in the workbook can drop one below). Raw-XML edit of the five question sheets and Question Themes; `export_data.py` clean, GUT 997/997. The How to Play suit table (HT21) follows the new grades: Divisive now lists only Party Headquarters (Agricultural Cooperatives fell below the 0.4 cut-off as new, mostly Divisive-weak, questions diluted its average).

### Divisive lean for Students United, Our Traditional Society and Party Faction (2026-10-12, Cameron)

Cameron asked for these three to clear the How to Play suit table's 0.4 Divisive cut-off. Done by re-grading 14 of the draft questions added the same day (Divisive column only, Weak to Strong; one Weak to Medium), no new questions: Students United 16 questions, Divisive average 0.50 (nine research, tech-transfer, graduate-jobs, zoning and campus-housing questions); Our Traditional Society 15, 0.53 (festival funding and crafts); Party Faction 15, 0.53 (committee seats). The HT21 Divisive line now reads Party Headquarters, Party Faction, Our Traditional Society, Students United (the four-per-suit maximum, so one more organisation clearing 0.4 would be cut by `MAX_PER_SUIT`). Questions shared with other organisations also shift their Divisive averages (Urban Neighbourhood Alliance via the zoning questions, Shrine Association and Yezo Artisans Guild via festival and craft ones). Raw-XML edit of the question sheets' Divisive cells; `export_data.py` clean.

### Three in-group / out-group Divisive questions (2026-10-12, Cameron)

One new question each for Students United (T103, theme "Generational divide": young against old voters), Our Traditional Society (T104, "Customs and belonging": who counts as part of the tradition) and Party Faction (L78, "Faction discipline": "with us or against us"). Divisive is Strong on each, written as a hard line between an in-group and an out-group or an entrenched view rather than plain confrontation. Three new Question Themes rows, each pleasing only its one organisation, all drafts. Divisive averages are now 0.53, 0.56 and 0.56 over 17, 16 and 16 questions. Raw-XML edit; `export_data.py` clean.

### Phase 1 of the legislation plan: suit- and stage-based cues and questions (2026-10-12, Cameron)

Three additions, all optional workbook data that ships empty, so no current behaviour changes until rows are written. `design/EDITING_TEXT.md` §3a and §4a are the guide.
- **Player Cues tab** (`data/player_cues.json`): Cue ID (PLxx), Suit, Verb (attack/gain/block, blank = any), Stage ID (blank = any), Cue 1-5. `CardCues.for_card()` now takes the card's `applied` result and checks, most specific first, this stage + verb, this stage any verb, any stage + verb, any stage any verb (`DataDB.get_player_cue_lines()`), and only then the card's own Flavor Text lines. `CardCues.verb_for()` reads the verb in the same order the portrait reacts (attack, then gain, then block).
- **Opponent Cues: optional Stage ID column.** Lookup is now opponent + stage, opponent, stage + suit, suit (`DataDB.get_bespoke_opponent_cue_lines()` / `get_general_opponent_cue_lines()` take a stage_id).
- **Stage Questions tab** (folded into `questions.json` as a `"stage"` pool, each question carrying `stage_ids`; `asked_by` from the opponents of the first stage named). `BattleSetup` passes them as `question_pool_first`; `BattleEngine._draw_questions()` deals them before the room pool, then shuffles the dealt set. A stage with no room pool (every committee) asks only these, so writing rows is the per-stage on/off switch: committees ask questions (with the Strong/Weak multiplier and organisation pleasing) only once Cameron writes some. An empty list leaves every existing seeded draw identical (tested).
Tests: `tests/test_player_cues.gd` (new), stage-row cases in `test_opponent_cues.gd`, Stage Questions draw cases in `test_questions.gd`; checked end to end on a real LV33 Finance committee with an injected question. Raw-XML workbook edit: two new sheets (Player Cues, Stage Questions, header only) and one header cell on Opponent Cues; `export_data.py` clean.

### Draft content for Phase 1: committee questions and committee Player Cues (2026-10-12, Cameron)

All drafts for Cameron to rewrite. **Stage Questions**: 33 questions, three for each committee (ST01, ST09-ST18), S01-S33, each graded for the six suits and themed so it pleases organisations; 26 reuse existing Question Themes, and 7 themes (Ethics rules, Member pay, Parliamentary procedure, Rice policy, Crop insurance, Farm succession, Digital government) got Question Themes rows. Every committee now asks one question per turn. **Player Cues**: 18 rows (six suits x attack/gain/block, five lines each), **scoped to the committees only** (Stage ID lists ST01 and ST09-ST18), so the card's own Flavor Text lines still play everywhere else; clearing the Stage ID cell would make a row apply in every room and override the card lines there. **Balance consequence (bot stage trial, PC02, 40 fights each):** the Cabinet committee ST18 went from 16/40 (40%) to 40/40 once it asked questions, because a Strong-graded answer multiplies the card by 1.3; ST16 and ST09 stayed at 40/40. ST18 was tuned to ~45-50% on 2026-10-07, so its threshold/energy (or its questions) are Cameron's to revisit. `test_stage_rules_columns.gd`'s "no pool means 0" test now expects a committee's own Stage Questions count. GUT 1010/1010, `verify.sh` green, `export_data.py` clean.
Cameron's call (2026-10-12): **leave it** (option C). The Cabinet committee keeps its three questions and its 2026-10-07 tuning, accepting that it is now much easier.

### Phase 2 of the legislation plan: the statute book and Law Effects (2026-10-12, Cameron)

- **Statute book** (`GameState.statute_book`, saved, cleared on a new run): one entry per bill that came to a Floor Vote, passed or failed, with its Yes/No/Abstain totals, how the player voted, whether the influence swing flipped it, the level and `enacted_at` (levels completed at the time). Written by `GameState.record_floor_vote()` from `FloorVoteScreen._on_vote()` (and the playtest bot); a bill already in the book is ignored. Shown in **Your Record** under "Statute book" (seven new Text rows: `office.record_statute_heading/empty`, `office.record_law_passed/failed`, `office.record_vote_yes/no/abstain`).
- **Law Effects tab** (`data/law_effects.json`, ships empty): Law ID (LWxx), Bill ID, Outcome (Passed/Failed), Timing (blank/Once = at the vote; Each level = at the end of every later level, win or loss, never the level that held the vote), Effects (the same `target_delta_list` as Shop Grants, applied through `GameState._apply_reward_entries()`), Constituency support / Reputation / Funds / Party support (through `_apply_meta_reward()`, so Your Record's `(+N)` shows them) and XP. Pure logic in `scripts/rules/StatuteBook.gd`; the exporter checks Bill ID, Outcome and Timing.
- **"law" condition** for Office Notices and the Office Ticker: `condition_type` law, `condition_target` BIxx, `condition_op` passed/failed (`OfficeNotices.condition_met()` and `OfficeTicker` take an optional `laws` map from `GameState.law_statuses()`; the exporter checks the bill and op).
- Not built (yet): level unlock/hide and direct party-opinion effects; repeal. Tests: `tests/test_statute_book.gd` (9), and `floor_vote_driver.gd` now checks a real click writes BI01 into the book. GUT 1019/1019, `verify.sh` green, `export_data.py` clean. `design/EDITING_TEXT.md` §6a is the guide.

### Draft Law Effects for all 30 bills, and a note on every workbook column (2026-10-12, Cameron)

**Law Effects tab: 63 draft rows (LW01-LW63), Cameron's to correct.** Every bill (BI01-BI30) has a **Passed / Once** row (its main beneficiary organisation +3, other beneficiaries +2, the organisations it hurts -2) and a **Failed / Once** row (beneficiaries -1, opponents +1). Three bills also pay **each level** while on the books: BI14 Constituency Development Grants +2,000 Funds (and +2 Constituency support once, when passed), BI07 Grid Resilience and BI24 Tomari Restart +1,000 Funds each. Which organisations each bill helps or hurts is Claude's reading of the bill text (the Note cell says why, starting "Draft 2026-10-12"); no party opinion or canon was decided. Effects apply whatever the player voted, since the law is the chamber's, not the player's. Raw-XML edit of the Law Effects sheet; `export_data.py` clean.

**Every column on every tab now has a header note** (478 notes across 45 tabs) (hover the header cell in Excel): what the column means, what it accepts, what blank means and what the game does with it, drafted from the exporter and the code that reads it. The 19 older "Permutations" notes are kept, below the new explanation. README and Tone Guide (prose tabs) have none. Built as raw comment/VML parts per sheet (`xl/commentsN.xml`, `xl/drawings/vmlDrawingN.vml`, a `legacyDrawing` in each sheet, a content-type entry per comments part), never through openpyxl; confirmed by reading the notes back read-only and a clean export with no data change. When a column is added later, its note is a hand edit in Excel (Insert Note), which is safe because Excel itself saves it.

**Two findings from writing the notes (the first was built the same day, see the next section):**
- **A Modifiers row triggered by an organisation (BOxx) never switched on in battle.** `MetaRules.active_modifiers()` only checks SGxx audience shares; the exporter splits out `trigger_booster_ids` but nothing reads it. So M05-M08, M11, M13 and M15-M31 (whole-number Trigger min % such as 15) never give their stage-start, hand-size or gaffe-limit bonus; a RESOURCE_BONUS_ON_WIN still pays on a level win. What a BOxx trigger should mean (that organisation's standing at or above the number?) is Cameron's call.
- **Vote Tally & Swing's "51 Yes" result column tests Yes >= 50**, while the game passes a bill when Yes is greater than No. The tab is a hand-check, not exported; its notes say so.

### A scored playtest of backing, influence and laws; a BOxx trigger now means standing (2026-10-12, Cameron)

**Cameron's call: a modifier tied to an organisation switches on when that organisation's standing is at or above `Trigger min %`.** `MetaRules.active_modifiers()` takes the standings (`GameState.booster_standing`, passed by `BattleSetup.backing_bonus()`) and `MetaRules.booster_trigger_met()` answers per modifier; `GameState._pay_level_rewards()` pays a pay-on-win backing only while its organisation holds. An audience (SGxx) trigger is unchanged (and a pay-on-win SGxx one still pays whoever watched). Because buying a backing already needs standing 60 and the numbers are 15-30, a BOxx trigger rarely bites unless standing later falls.

**`design/PLAYTEST_RUBRIC.md`** is the rubric (A new game, B backing and organisations, C vote influence, D laws; weights 3/2/1) with the scored result, and **`tools/rubric_playtest.gd`** (`xvfb-run .tools/godot --path . tools/rubric_playtest.tscn`, ~90 s) plays it from a new game and checks every number against the workbook data. Result: **62/64**. Not in `verify.sh` (slow; exits 1 while any line fails).

- **Real bug found by a real click and fixed:** a flip crashed `FloorVoteScreen._on_vote()` (`int(null)` on the blank Influence Bonus cells), so the result panel never opened. `FloorVoteEngine.influence_bonus()` now reads blank as 0 (tests added). No earlier test flipped a bill with a real click because the gate had never been opened in a click test.
- **Workbook data error left for Cameron:** BI25 (Integrated Resort Act) splits PT02 16 and PT06 13, but they hold 14 and 11 seats, so its chamber is 105. `export_data.py` now warns on any bill whose splits do not add up to each party's seats. The rubric line C1b fails until it is corrected; it is Cameron's number to fix.
- Also confirmed: all 60 bill outcomes apply exactly their Law Effects rows; "Each level" laws pay nothing on the vote's own level and the exact amount on each later one, through a save/reload; a full-strength player flips 23-24 of 60 yes/no votes per protagonist.

### BI25's seat counts fixed; every organisation now has a stake in the statute book (2026-10-12, Cameron)

- **BI25 Integrated Resort Act seats corrected** with Cameron's rule (a party over its seat count loses the surplus from Abstain first, Yes second, No third): Yezo Heritage Party (PT02) 8/8/0 became 6/8/0 and Country Initiative (PT06) 8/5/0 became 6/5/0, so the chamber is 101 again. The exporter's seat-total warning is clear. Workbook edit by raw XML (four cells). BI25 now fails by a slightly different margin than before (fewer Yes votes), which is the workbook's own numbers, not a new rule.
- **Every organisation is now pleased by at least one bill outcome and annoyed by at least one.** Only Neighborhood Associations (BO06) was missing from the Law Effects tab. Draft rows (Cameron's to correct): BI14 Constituency Development Grants passed BO06 +2 / failed -1 (neighbourhood projects get funded or not), BI25 Integrated Resort Act passed BO06 -2 / failed +1 (a casino resort is a neighbourhood worry). Appended to the existing Once rows' Effects cells; their Note cells say what was added. The rubric has a new check, D8, so a future organisation added to the Boosters tab with no bill that touches it is caught. Rubric result: **66/66**.

### A guide for an assistant expanding the workbook (2026-10-12, Cameron)

`design/WORKBOOK_EXPANSION_GUIDE.md`: how stages, questions, cues, organisations, parties, votes and laws connect; the numbers that matter (affinity house style two up/two down/two neutral, S/M/W effects, standing thresholds); recipes for a new unique stage and its questions; and how to phrase lines by scope (universal, stage-scoped, opponent-scoped, with party/affiliation voice only for opponent-scoped lines). Two things it records that are not obvious from the workbook: a question's **asker is assigned in rotation** from everyone eligible for the stage, so question text must not name the asker's party unless every eligible asker shares it (an optional "Asked By" column would need code, not built); and the **Party Caucus (ST03) draws MPs from all six parties** although it is named for the player's own, an open question for Cameron. `design/EDITING_TEXT.md` points to it.

### Asked By Party, and the caucus seats only your own party (2026-10-12, Cameron)

- **Asked By Party** (optional column on all six question tabs: party IDs, or `OWN` for the player's own party). The exporter assigns askers only from those parties among the people the room seats, and reports an error if a named party has nobody there. In the game, `BattleSetup.questions_for_room()` runs every room's questions through the new pure `QuestionAskers.resolve()`: the asker must be someone the room seats this time and of an allowed party; otherwise someone who is replaces them (picked by question ID, so stable), and a party-limited question nobody present may ask is left out of the room. This also fixes the older gap where a Stage Questions row naming several stages could show an asker from the first stage only.
- **Own Party Only** (new Stages column, Yes/No, blank = No), set Yes on **ST03 Party Caucus**: `BattleSetup.eligible_opponents()` keeps only MPs of the player's party (falling back to everyone, with a warning, if the workbook seats none), and a level pin must also pass it. Frontier Party had only one caucus MP (OP101), not enough for the caucus's two opponents and the party of PC01 and PC02, so **OP17 (Furukawa Hideki, Frontier Party, Committee on the Environment) now also lists ST03**: a data choice of which existing MP attends, Cameron's to change. Yezo Heritage Party and Five Point Independents still have one caucus MP each (no protagonist belongs to them).
- Tests: `tests/test_question_askers.gd` (8, including real ST03 for three protagonists and real rooms' askers). Header notes added for the seven new header cells. `design/WORKBOOK_EXPANSION_GUIDE.md` §6 rewritten to match; a Word copy was given to Cameron in chat.

### A review of the expansion guide against the workbook; the mechanical fixes applied (2026-10-12, Cameron)

An outside review of `design/WORKBOOK_EXPANSION_GUIDE.md` was checked claim by claim against the data: 18 of its 21 points were right, 3 partly right. Applied (the rest is listed below as Cameron's calls):
- **Guide corrected:** there are 20 Combat rooms (23 stages in all); Earnest is not rewarded in the ethics committee (ST09 favours Emotional and Data Driven) and the Emotional row was incomplete; the Town Hall seats a fifth organisation (BO03, OP102); intent ranges may be a single number; the Opponent Count rule is for Combat stages (ST07's count is visitors); a Theme must be typed with exactly the Question Themes row's capitals; the Question Pool note says ST05's blank cell uses the built-in Town Hall default; and the grading rule is now one rule (the room tabs' footers: at least 2 S, at most 2 W, no specific policy area; Stage Questions may be specific).
- **Player Cues rewritten** (29 lines in PL03-PL18): my Phase 1 drafts broke the Tone Guide (time words such as always, again, already, still, before; invented history such as "what you said privately"; lines that depend on a reply). Now clean of time words and over-length lines.
- **Six stale "Why" cells refreshed** on Question Themes (Cost, Defense Budget, Defense spending, Equal rights, Public debt, Stimulus): my 2026-10-10 rebalance moved their organisations but left the old rationale.
- **Two stale cached formula values refreshed** in the workbook: ST18's Win % (1, now 0.6, which also corrects `win_pct` in stages.json) and the Vote Tally row for BI25 (was 52/43/10 = 105; now 48/43/10 = 101, which the tab's own rule, Yes >= 50, reads as Fails). Excel recalculates both on open anyway.
- **Exporter check added:** an Office Notices or Office Ticker row whose staff_role is not in the Staff tab is now a warning. It flags TK38-TK40 ("Press Secretary" is not a role): TK38 can never show, and TK39/TK40 always show, even after hiring. A warning rather than an error so it cannot block the export.

**Left for Cameron:** whether the Ticker lines should say Media Spokesperson (or a Press Secretary role be added); the repeated suits on 19 opponents; OP05's affiliation (BO18, every other committee MP is BO17); BI02's name against LV32's ("Price Stabilization" and "Supply Chain"); the stray "BI" in "themseBIes" (Party Positions G57); the Opponent Cues that break the Tone Guide (OC01, OC05, OC09, OC12, OC18, OC19, OC32, OC34); about 12 questions with fewer than 2 S and about 37 with no W; the README tab (still says 21 stages, 30 levels, 16 boosters, 69 themes, and lists resolved gaps); the Assets tab calling VI01 "Dog Man"; and the missing L63.

**TK38-TK40 renamed (2026-10-12, Cameron):** the three Office Ticker lines that named the staff role "Press Secretary" now name **Media Spokesperson**, the role the Staff tab actually has. TK38 ("hired") now shows once a Media Spokesperson is hired; TK39 and TK40 ("not_hired") now stop showing once one is. The exporter's staff-role warning is clear. The lines' own wording still says "press secretary", which reads fine in-world.

### Review leftovers applied: typo, names, cues, grades, README, Assets (2026-10-12, Cameron)

Cameron approved the recommendation table. **Applied** (raw-XML workbook edit; `export_data.py` clean; only these cells changed): "themseBIes" typo fixed (Party Positions); LV32 renamed "Agricultural Price Stabilization Act" to match BI02; OP05 Aptoas Ahun's Affiliation BO18 to BO17 (Committee on Finance, like the other committee MPs); eight Opponent Cues (OC01, OC05, OC09, OC12, OC18, OC19, OC32, OC34) plus OC02 and Flavor Text C51 cue 1 reworded to meet the Tone Guide (time words, a reply-dependent line, and over-length lines); 12 questions with fewer than 2 S each gained one S (M to S, W count unchanged): Q34, L75, B21, B22, B23, B25, B30, A23, S10, S14, S20, S25; L31's theme "Constitution" to "Ainu reserved seats"; README tab counts refreshed and its four resolved Known Gaps replaced by the real open ones; Assets tab: 12 name cells corrected (protagonists, VI01-03, five reversed or misspelt opponent names) and 108 new rows for visitors VI04-VI39 (neutral/gaining/damaged, Drawn = No), placed after VI03's rows.

**Left on purpose (Cameron):** the 19 opponents with a repeated suit; the 37 questions with no W (legal under the footers, the guide now calls a W good practice, not a rule); the unused ID L63. The Cosmetic Outfit rows on the Assets tab called PC01 "Hiro"; they now say Kenshin Sako (2026-10-12), and the CueBanner example and test name use it too.

### The expansion guide revised (2026-10-12, Cameron)

`design/WORKBOOK_EXPANSION_GUIDE.md` refreshed: current counts in the header, a sixth key point and an Assets row in §7 (every new person needs Opponents/Visitors, Assets and matching names), a clearer line on no-W questions, and two new hand-over checks (names agree across tabs, Tone Guide read-through; keep the README tab's counts true). No rules or data changed.

### A second review of the guide and workbook (2026-10-12, Cameron)

Fixed: Opponent Cues OC20 (two garbled lines), Player Cue PL01 cue 2 (no longer leans on invented history), five player-facing typos (LV10 "Advancing" and its Sanban note, Level Intro Thoughts for LV10, LV13 and LV47), the stale cached word counts on Flavor Text C51 (now 8/7/7/7/8, max 8), and the **Assets item-icon rows**, which still described the old 29-item Shop (SH09 "Blue Profile Package" and so on): they are rebuilt from the 20 current Shop rows (ID, name and Icon cell), all marked Drawn since every icon file exists. The guide now labels its suit table as examples, notes that repeated suits are deliberate, and extends the name check to the Shop tab.

**One claim not accepted:** the review said BI25 now *fails* by default so its "Flipped to Fail" cue cannot fire. The game passes a bill when Yes outnumbers No (`FloorVoteEngine`, `passed: totals.Yes > totals.No`), and BI25's tally is 48 Yes / 43 No, so it **passes** by default and a Fail flip is the right cue. The "Fails" in the Vote Tally & Swing tab is that hand-check tab's own Yes >= 50 rule, which differs from the game; my earlier note that "BI25 now fails" was wrong about the game and is corrected here. Whether the hand-check tab should use the game's rule is Cameron's call.

### A bill now needs a majority of the whole house (2026-10-12, Cameron)

Cameron's call (option B: "the mechanics mirror reality"). A Floor Vote bill used to pass when Yes outnumbered No, abstentions ignored. It now passes only when **Yes reaches a majority of the whole house**: `FloorVoteEngine.yes_needed()` is house size / 2 + 1 (51 of 101, Yezo's floor majority, derived from the seats so it cannot go stale) and `FloorVoteEngine.bill_passes()` applies it. The same test decides `passed`, the influence-flip flag and the rubric. Abstentions now count against a bill. **Four bills change default outcome**: BI15 (48-34-19), BI19 (44-42-15), BI25 (48-43-10) and BI28 (43-33-25) now fail unless the player's influence flips them. Their Vote Influence Cues already matched (Cameron had written BI15, BI19 and BI28 as "Flipped to Pass"), except BI25, whose only cue was "Flipped to Fail", so a draft **BI25 "Flipped to Pass"** cue was added (the old Fail cue stays, unreachable). The Vote Tally & Swing tab's Result and Surplus/Shortfall columns now test Yes >= 51 (they used >= 50), so the tab and the game agree on all 30 bills. Law Effects for those four bills now apply their Failed rows by default. Tests: three new in `test_floor_vote_engine.gd`; GUT 1033/1033, `verify.sh` green, rubric 66/66, `export_data.py` clean. The guide and How to Play text were checked for the old rule (none mention it).

### The Party Steering Committee (ST08) is now Own Party Only (2026-10-12, Cameron)

ST08's Own Party Only cell was blank, so rival parties' MPs sat on a player's own Steering Committee. It is now Yes, the same flag the Party Caucus (ST03) uses. ST08 draws one MP. Frontier Party (OP82) and Country Initiative (OP02) already had a member listing ST08, but **Keizaijiyuutou had none**, so PC03 would have fallen back to everyone. **OP30 Isoroku Adams (Keizaijiyuutou, already in the caucus) now also lists ST08**: a data choice of which existing MP attends, Cameron's to change, like OP17 for the caucus. Yezo Heritage Party and Butsutou still have members there but no protagonist belongs to them. New test `test_the_steering_committee_seats_only_the_players_own_party` covers all four protagonists. Raw-XML edit (one cell on Stages, one on Opponents); `export_data.py` clean.

### The expansion guide revised after a draft review; feedback for the drafter (2026-10-13, Cameron)

A 21-room, 6-bill consolidated draft (outside the repo, `CoP_Content_Consolidated_Draft_2026-10-13.xlsx`) was audited against the workbook and code. Mechanically it was clean; the problems were engine behaviours the guide had not stated. `design/WORKBOOK_EXPANSION_GUIDE.md` now has **§2.7** (questions per stage, switching questions on, Player Cues shadowing card Flavor Text, Opponent Cue tiers, transition length and firing, the 51-of-101 rule, tab formulas), suit spread targets in §2.3, a visitor-question rule, stricter §8 hand-over checks (rebase edits, numbers as numbers, an audit table, bot trials, a canon list) and a §10 map from each problem to its rule. `design/EXPANSION_DRAFT_FEEDBACK_2026-10-13.md` is the keep/change list handed to the drafter. Findings worth remembering: the draft's OP30 edit would have removed ST08 (stale base); Stage Questions are dealt ahead of a room's pool and a stage asks only turn_limit questions in total (six on ST04 would hide all 34 press questions); transitions fire only before a non-first stage and the banner holds a line at most 4 seconds. No game or data change.

### Expansion ground rule: add content, never mechanics; every room may carry generic and stage-specific content (2026-10-13, Cameron)

Cameron's reply to the draft review: the new geography and people (Aomori, Hokkaido and Chishima assemblies, the people seated in them) are approved; new rooms follow the game's current norm; the expansion changes no mechanics; **every room, existing or new, may draw on the base (generic) content and on stage-specific content where it applies.** An earlier note from the same day told the drafter to strip stage-specific content from existing rooms and keep transitions off; that was a mistake and is withdrawn. `design/WORKBOOK_EXPANSION_GUIDE.md` has §3.0 (family templates with the live numbers for committee/hearing, Town Hall-like, Policy Study-like and caucus rooms) and §2.7 (how the engine reads content, so stage-specific content is sized well: Stage Questions never crowd out a room's generic pool, cue cells get at least 10 lines, transitions fit a 4-second banner, turning questions on for a room is bot-trialled). `design/EXPANSION_DRAFT_FEEDBACK_2026-10-13.md` was reissued to match. No game or data change.

### Expansion focus: content gaps and topic-specific rooms (2026-10-13, Cameron)

The expansion is to fill content gaps and build out questions and cues for general rooms and for topic-specific rooms (a committee or floor stage for one bill). `design/WORKBOOK_EXPANSION_GUIDE.md` §2.8 holds the measured gaps (committees ask 3 questions in 10 turns; ST02/03/06/08 ask none; no bill has its own room; transitions off everywhere), per-room quotas, a priority order and recipes for a topic committee or floor stage. A topic needs its own STxx row because the engine keys questions and cues by stage ID. `design/EXPANSION_DRAFT_FEEDBACK_2026-10-13.md` points to it. No game or data change.

### Expansion focus widened: transitions are a gap; topic rooms of any kind (2026-10-13, Cameron)

Transitions (all off, pools empty) are named a gap to fill, and topic-specific rooms are not limited to committees: a town hall, policy study, committee hearing or press conference can each be a new stage written around one subject (for example "Press Conference on Raising Train Fares" in a train-policy level). Guide §2.8 now has a room-kind table (what to build each from, where its questions come from, which columns to set), a topic-room sizing rule (Stage Questions up to turn_limit with Question Pool blank for a topic-pure room), transition quotas and rules, and a priority order. The feedback memo points to it. No game or data change.

### Batch 1 draft: transitions and two topic levels; a transition bug fixed (2026-10-13, Cameron)

A first draft batch was written against guide §2.8 and kept **outside the master workbook**: `design/drafts/CoP_Batch1_Draft_2026-10-13.xlsx` (a full copy with the batch applied) and `design/drafts/BATCH1_EVALUATION_2026-10-13.md` (what it holds and how it fits the scheme). It has the transition pools (6 staff cast, 9 backgrounds, 34 exchanges), Show Transition on for 20 existing combat rooms, eight new topic rooms (ST24-ST31: Town Hall on Commuter Fares, Policy Study on Rail Timetables, Press Conference on Raising Train Fares, Hearing on Rail Safety, Lobbyist Meeting on Fishing Quotas, Town Hall at the Harbour, Media Ambush on Seafood Labelling, Hearing on Fishery Quotas), two levels (LV61, LV62), 36 Stage Questions with 11 themes, and 48 room-scoped cue rows. Evaluated by swapping it in temporarily (export clean, GUT and `verify.sh` green, bot win rates in family) and then restoring the master; to adopt it, copy the draft over the master workbook and re-export.

**A real bug was found and fixed:** `PoolPicker.eligible()` read a blank Stage ID (JSON null) as the text "<null>", so wildcard rows in the three transition tables never matched and no transition could ever appear (the pools had been empty). Fixed with a GUT test, plus a new real-click test, `tests/interaction/stage_transition_test.tscn`, in `verify.sh` (it skips while no stage shows a transition; confirmed it fails without the fix). `office_hours_driver.gd` now taps Continue when a transition sits before the next stage. GUT 1035/1035, `verify.sh` green. Open for Cameron: Media Ambush wins 0 of 160 for the bot (ST19 too, so the new room inherits it), LV61 overlaps LV14, and the Japanese names are drafts.

### The three-times rule, a depth audit, and a revised Batch 1 draft (2026-10-13, Cameron)

Cameron's rule: every room should hold at least **three times** as much content as an average run meets, general and room-specific together (a room asking 10 questions needs 30 to draw from); and LV61 does not overlap LV14, since each room carries its own content on top of the general content. New tooling: `tools/content_depth.py` (reads `data/*.json`; per combat room, questions asked against questions it can draw, people seated against needed, player and opponent cue lines per (suit, verb) against cards played and turns ended, transitions available; `--md`, `--rooms`, `--fail-under 3`) and `tools/measure_plays.sh` (writes `design/bench/plays_per_stage.json`: cards played and turns per fight from the playtest bot, which the audit uses; the stage trial now also prints "TRIAL PLAYS"). Guide section 2.9 states the rule and how to meet it by content alone.

**Master audit:** 26 measures short in 20 rooms. Every committee asks 10 questions but can draw 3 (0.3x); Media Ambush 2.5x; the long committees, Town Hall and Caucus run short on player cues; several rooms are short on people. **Findings:** Stage Questions are always dealt first (all of them when a room has fewer than it asks), and a Stage Questions row's Stage ID cell takes a list, so one general question can serve every committee. The revised draft (`design/drafts/`) adds 28 shared committee questions, 12 press questions for the topic press conference, 6 general Media Ambush questions, and cue sets for the Town Hall family, Caucus, TV Debate and the committees. **With the draft, every combat room clears 3x on everything but people** (9 rooms; 8 new characters would fix it, listed in `BATCH1_EVALUATION_2026-10-13.md`). The draft was evaluated by swapping it in temporarily (export clean, GUT 1035/1035, `verify.sh` green, bot win rates in family) and restoring the master. No game or master-data change in this entry.

### Committee seating rule, a lean-toward-the-unmet people draw, Media Ambush (2026-10-13, Cameron)

- **Committees seat only their own members.** `tools/export_data.py` now fails the export if a stage named "Committee on ..." lists an MP whose Role is another committee (ST09-ST17 already comply; the draft hearings ST27/ST31 seat Construction and Agriculture members only). The Special Committee (ST01, 12 outsiders) and the Committee of the Cabinet (ST18, 9 outsiders) are warnings only: they seat members of other committees, and who sits on them is Cameron's to say.
- **People may return, but the draw leans unique.** New pure `scripts/rules/PeopleDraw.gd`: everyone eligible is grouped by how often they have been seated this run, the least-met group is drawn first (shuffled within), so nobody repeats in a stage and a pool's unmet people come before repeats. `BattleSetup._opponent_for/_opponents_for/_visitors_for` use it; `GameState.faced_people` (saved, cleared on a new run) is counted in `begin_level()` and when a crisis stage is inserted (`record_faced()`). A level pin still wins. `tests/test_people_draw.gd` (6). GUT 1041/1041, `verify.sh` green.
- **Media Ambush may be lost** (it does not end the level), so a low win rate is acceptable. For reference the bot with every card and item wins 0% at threshold 30, 20 and 25, about 12% at 15, 35-93% around 11-14 (noisy, a fresh deck each fight), 100% at 10; a late kit cannot pass it as tuned. Not changed.

### Special Committee and Cabinet seating decided; Media Ambush left alone (2026-10-13, Cameron)

Cameron's answers: **any MP who is not a minister may sit on the Special Committee (ST01); all ministers and committee chairs are eligible for the Committee of the Cabinet (ST18); Media Ambush numbers are not adjusted.** Done: ST01's Stage cells now list all 88 non-minister MPs with a stage list (79 added; the Prime Minister, the Minister of War and the Minister of Foreign Affairs removed from it; the four protagonist-named MPs stay blank on purpose); ST18 already held exactly the 9 ministers plus the President of the National Assembly (the one chair who is not a minister), so it is unchanged. Ministers and chairs are read from the Title column. `export_data.py` now **fails** the export for a "Committee on ..." room seating another committee's member, an ST01 seat held by a minister or non-MP, or an ST18 seat held by anyone who is not a minister or chair (the earlier warnings are gone). `tests/test_committee_seating.gd` (3) checks the real data. Raw-XML edit of the Opponents sheet only (confirmed byte-identical elsewhere); GUT 1044/1044, `verify.sh` green. The Batch 1 draft was rebuilt on this master.

### Party values saved as reference for bill drafting (2026-10-13, Cameron)

Cameron supplied the six parties' values on 34 dimensions (civil liberties through Japan alignment), each with a **value**, a **priority** and a **salience**. Saved verbatim as `design/reference/party_values.tsv` (header row, one row per party, tab-separated; 102 numbers per party). Checked on entry: for all 204 value/priority/salience cells, **salience = value x priority**, so the file transcribed cleanly. It is reference for drafting future bills and their Party Positions (which way each party leans on a bill's subject, and how strongly), not game data: nothing reads it and no canon is decided from it. Cameron's next direction: once the Batch 1 scheme is established, keep building toward 100 unique stages and 50 custom bills; not started.

### Batch 1 adopted into the master workbook (2026-10-13, Cameron)

Cameron: "Adopt batch one." `design/drafts/CoP_Batch1_Draft_2026-10-13.xlsx` (built on the master as it stood after the Special Committee/Cabinet seating change) is now `design/Game_Workbook.xlsx`, re-exported (31 stages, 62 levels, 125 opponents; export clean). The README tab's counts were refreshed (31 stages, 62 levels, 212 themes, 33 Media Ambush questions). Verified after adoption: GUT 1044/1044, `tools/verify.sh` green, `tools/content_depth.py` shows 9 measures short, all of them people (8 new characters would fix it). The draft file stays in `design/drafts/` as the record of the batch. Next, per Cameron: bills first (they inform what makes each stage unique), toward 50 bills and 100 stages.

### Batch 2 draft: twenty new bills, BI31-BI50 (2026-10-13, Cameron)

Cameron: bills first, because they inform how to make each stage unique. `design/drafts/CoP_Batch2_Bills_Draft_2026-10-13.xlsx` (adopted master + the bills; master unchanged) and `design/drafts/BATCH2_BILLS_EVALUATION_2026-10-13.md` (the 20 bills, their default results and the rooms each suggests). Each bill: a Floor Vote Bills row, six Party Positions rows (seat split, disposition, a leader's line), one Vote Influence Cue for the flip that can happen, and two Law Effects rows (LW64-LW103). **Positions came from a model, not by hand:** each bill is tagged with the party-value dimensions it touches (a direction between -1 and 1 each); a party's lean is the sum of tag x salience (`design/reference/party_values.tsv`); |lean| of 30 or more takes a side, below that is Neutral; splits follow the shapes in the 30 existing bills (Supportive about 79% Yes, Opposed about 73% No, Neutral about a third each). The tag directions are drafts. Result: export clean, GUT 1044/1044, rubric 66/66 over all 50 bills (it iterates every bill; a few labels still say "30"), 10 of the 20 pass by default, a full-strength player flips 32-34 of 100 votes. 20 bills are named by no level yet (export warns, as expected). The Vote Tally & Swing hand-check tab was not extended.

### Batch 2 bills adopted (2026-10-13, Cameron)

The twenty draft bills BI31-BI50 (with their party positions, Vote Influence Cues and Law Effects LW64-LW103) are now in the master workbook (50 bills, 103 Law Effects rows); `export_data.py` clean, GUT 1044/1044. No level names them yet (the export warns), so they do not appear in play until the rooms and levels are built. `design/BILL_BOOSTER_PARTY_REPORT_2026-10-13.md` counts, per organisation, the bills that favour or annoy it and, per party, the bills it aligns with, opposes or is neutral on. Not yet done: the 69 rooms and 20 levels around the new bills.

### Booster and party balance across the 50 bills; Party-tier organisations follow the player's party (2026-10-13, Cameron)

Cameron asked for more equality between organisations (and parties) pleased and annoyed by the bills, and for Party Headquarters and Party Faction to respond to a bill according to **party lean**, so different protagonists' parties see the same bill differently.

- **Party-tier lean (new rule, two Balance levers).** Organisations whose Boosters-tab tier is `Party` (today BO01 Party Headquarters and BO02 Party Faction) no longer have fixed Law Effects rows. When a bill is voted, `GameState._apply_party_tier_lean()` reads the bill's Party Positions disposition for the **player's own party** and `StatuteBook.party_tier_delta()` moves them: a bill the party backed passing, or one it opposed failing, pleases (`law_lean_party_tier_pass_delta` 3 on a pass, `law_lean_party_tier_fail_delta` 1 on a fail); the reverse annoys; a Neutral party moves nothing. Their old fixed entries were removed from every Law Effects row. A new organisation tier of `Party` joins automatically. Tests in `test_statute_book.gd`; the rubric's D8 skips Party-tier organisations (they have no fixed rows by design).
- **Law Effects rebalanced** (draft, Cameron's to correct): 60+ entries added, dropped or flipped across both the original and new bills. Favoured/annoyed counts per organisation are now close (Chamber of Commerce 14/5 to 10/8, Taxpayers' Alliance 2/13 to 6/10, Students United 11/2 to 7/6, Innovation Society 10/0 to 7/4, Our Traditional Society 4/9 to 8/7). Failed rows regenerated as the exact reverse at 1.
- **Party positions on the 20 new bills rebalanced** (28 draft overrides; the original 30 are untouched). Aligns/opposes over all 50 bills: Butsutou 22/14, Yezo Heritage 21/16, Frontier 22/13, Five Point 22/11, Keizaijiyuutou 22/17, Country Initiative 20/21 (before: 24/10, 21/16, 25/8, 21/6, 19/21, 16/25). Three bills (BI39, BI40, BI41) changed default result, so each got the opposite Vote Influence Cue. `design/BILL_BOOSTER_PARTY_REPORT_2026-10-13.md` has the full tables.

### Batch 3 draft: rooms and levels for the twenty new bills (2026-10-13, Cameron)

Cameron: build out the rooms, levels and content for BI31-BI50, all at once. `design/drafts/CoP_Batch3_Rooms_Draft_2026-10-13.xlsx` (master + the batch; **master unchanged**) and `design/drafts/BATCH3_ROOMS_EVALUATION_2026-10-13.md`. 20 levels (LV63-LV82, one-time, tiered by bill size), 69 rooms (ST32-ST100) built from the existing families (Hearing, Town Hall, Press, Policy Study, TV Debate, Lobbyist, plus a topic Party Caucus before each vote), 120 topic Stage Questions in 60 new themes, 360 templated topic Player Cue rows, 207 room-scoped transitions, 69 backgrounds and Show Transition on everywhere. Evaluated by swapping it in temporarily and restoring the master: export clean, GUT 1046/1046, `verify.sh` green, rubric 66/66, every new room at 3x or better except people (the same three canon gaps), bot trials in family except a few Party Caucus rooms (see the evaluation). Not yet adopted.

### Batch 3 adopted; town halls cast from existing characters (2026-10-13, Cameron)

Cameron: "Adopt the batch. Cast from existing eligible characters." `design/drafts/CoP_Batch3_Rooms_Draft_2026-10-13.xlsx` is now the master (100 stages, 82 levels, 272 themes; README tab counts refreshed; every bill BI01-BI50 is now named by a level). To close the people shortfall without new characters: **OP123 (Neighborhood Association Member), OP124 (Student) and OP120 (Agricultural Cooperative Member)**, all existing and until now seated only in Lobbyist Meetings, now also attend **every Town Hall room** (12 rooms; 11 people for 3 needed: above 3x). The new **hearings** ST51 (Finance members, 9) and ST60 (War members, 8) now draw 3 and 2 opponents instead of 4 and 3, and ST27 (Construction, 7) draws 2, so each clears 3x without seating anyone outside the committee (a committee seats only its own members). **Left as they are (Cameron's canon tunings):** the original committees ST11, ST15, ST16 and both Media Ambush rooms (ST19, ST30), which stay a little under 3x on people; the five remaining measures. Verified on the adopted master: export clean, GUT 1046/1046, `verify.sh` green, rubric 66/66.

### The last five people shortfalls closed; branch merged to main (2026-10-13, Cameron)

Cameron: "Adopt all and merge." The original committees on War (ST11) and Construction (ST15) now draw 2 opponents, Finance (ST16) 3, and both Media Ambush rooms (ST19, ST30) 2, so every room has at least 3x the people it needs (`tools/content_depth.py`: 0 measures below 3x across 97 rooms). A one-cell change per room in the Stages tab (Opponent Count), reversible; these fights are now shorter. GUT 1046/1046, export clean, `verify.sh` green. The working branch was merged into `main`.

### Salience-scaled party opinion, a visitor per bill, Level Intro and opponent cues (2026-10-14, Cameron)

- **Policy salience informs how strongly parties react.** Floor Vote Party Positions gained a **Salience** column (a party's |lean| on the bill's subject, from `design/reference/party_values.tsv`). `PartySalience.factor()` turns it into a 0.5-2.0 multiplier (Balance: `party_salience_reference`, `_min_factor`, `_max_factor`) that scales each party's favorability delta (`FloorVoteEngine._favorability_deltas()`) and the Party-tier organisations' lean (`GameState._apply_party_tier_lean()`); a nonzero move never rounds to 0. Dispositions of the original 30 bills are unchanged, only magnitudes. Tests: `test_party_salience.gd`, `test_statute_book.gd`.
- **One Office Hours stage and one unique visitor per bill (BI31-BI50).** Stages ST101-ST120, visitors VI40-VI59 (each with two questions), pinned in `data/level_visitor_overrides.json` to slot 1 of LV63-LV82; the stage's general visitors can still be drawn as well. Draft content, Cameron's to rewrite. `test_bill_visitors.gd`.
- **Level Intro Cues for all 82 levels** (Policy Research Assistant, Media Spokesperson, District Representative; 246 rows): hand-written for LV01-30/61/62, templated on the bill's topic for the rest.
- **Opponent-specific cues for all 125 opponents** (OC61-OC435): each opponent's first suit x attack/gain/block, three lines drawn from a voice bank for their role (committee, journalist, constituent, organisation member). Drafts; many people in one role share bank lines in rotation.
- No bill repeal for now (Cameron).

### Unhired staff no longer speak in transitions; blank cue cells no longer say "<null>" (2026-10-14, Cameron)

- **Transitions:** an SFxx character in Transition Cast speaks only if that person is currently hired (`StageTransition.pick_speakers()` takes the hired staff IDs; `StageTransitionScreen` passes `GameState.staff_hired`). Opponents are unaffected. Consequence: the wildcard cast today is six staff, so a room whose transition has no opponent-scoped cast shows no transition until the matching staff is hired (the screen skips straight on). Writing opponent-scoped Transition Cast rows is how to give such rooms a transition regardless of hiring. The click test hires the cast staff in memory.
- **`<null>` line:** `DataDB._cue_lines()` treated a blank Cue cell as the text "<null>", so any cue row with fewer than five lines (all the new opponent-specific rows) could speak it. Blank cells are now skipped.

### Wrapping everywhere, and safe-area margins (2026-10-14, Cameron)

- **Text wraps.** A long panel title ("Host a District Walking Tour for a Constituency") used to widen its whole panel past the screen. `UiKit.wrap_all()` now makes every label and button in an `Overlay` row wrap; headings wrap; panels never scroll sideways and their column has a fixed 1000 px width (`Overlay.COLUMN_WIDTH`); scene labels that carry runtime text (outcome titles, battle readout, visitor/staff/speaker names) wrap. `tests/test_overlay_wrap.gd`.
- **Safe areas (step 1 of `design/DYNAMIC_SCREEN_PLAN.md`).** New `Layout` autoload + pure `SafeArea.gd`: any MarginContainer named "Safe" (screens) or "Margin" (panels) has each side raised to the device's notch/home-bar inset when that is larger than its designed margin (never added to it). A desktop window reports no inset, so nothing changes there. Not yet checked on a real notched phone. `tests/test_safe_area.gd`.
- The rest of the plan (aspect-ratio screenshots, short-screen battle layout, tablet cap, text scale) is waiting for Cameron's go-ahead.

### Parties popup, and dynamic screens steps 2-4 (2026-10-14, Cameron)

- **Parties page:** each party has a **See allies and rivals** button that opens a popup (`PartyDetailPanel`) instead of the old "Helping/Hurting" lines (which read like things the player had done). `PartyAllies.groups()` (pure) splits the party's stakeholder contributions into **Allies** (positive weight; higher standing is better) and **Rivals** (negative weight; lower standing is better). Each row shows the organisation, its standing, a 0-100 bar (**the party's own colour for an ally, white for a rival**) and a tag for what it is doing to the party's view of you now: **Improving Favorability**, **Neutral** or **Reducing Favorability** (within 0.5 points either way is Neutral). Eleven new `party_opinion.*` Text rows; `party_opinion.helping/hurting` are now unread. Tests: `test_party_allies.gd`, and `office_menus_driver.gd` clicks a real party's button and checks tags, bars and colours.
- **Aspect-ratio test (step 2):** `tests/interaction/aspect_matrix_test.tscn` (in `verify.sh`) draws the Intro, Office, Battle, Floor Vote, Visitor and Level Intro screens at 1080x1920, 2160, 2340, 2520 and 1600x2000 and fails if content runs off the sides or End Turn/Continue/Start is pushed off the bottom. `ASPECT_SHOTS=<dir>` saves a PNG of each.
- **Short screens (step 3):** the battle art box's minimum height fell from 620 to 320 (it was already the elastic block), so a 9:16 phone keeps End Turn on screen. Caught in passing: autowrap on the battle `Readout` label (zero width in its container) turned "Press tone" into a vertical column of letters, so that one change was reverted.
- **Wide screens (step 4):** `Layout.gd` adds side margins to every "Safe"/"Margin" container when the screen is wider than 1080 (`SafeArea.side_extra()`), so a tablet shows a centred 1080 column with the background down the sides.
- Open: step 5 (text size setting) and step 6 (real-device pass).

### A text-size setting (2026-10-14, Cameron)

Step 5 of `design/DYNAMIC_SCREEN_PLAN.md`: an Administration-menu button, **Text size: Normal**, cycles Small, Normal, Large. `Layout.apply_text_scale()` multiplies every font size in the project theme from its authored size (kept, so cycling never compounds), using `TextScale.gd` (pure) and two Balance levers, **Text scale: Small** (90) and **Text scale: Large** (120), percent; Normal is always 100. The choice is saved in `user://settings.json`, not the game save, so New Game never resets it. Cards keep their own fixed fonts. Four new Text rows (`office.text_size`, `text_size.small/normal/large`). The aspect test now also draws every screen at Large text and found two real overflows, both fixed: the Office header row (name, party, Japanese accent) is an `HFlowContainer` now so it wraps, and the Floor Vote header wraps a long stage name (`FloorVoteScreen._fit_stage_name()`, same rule as the Visitor screen). Tests: `test_text_scale.gd`; the Office-menus click test taps the button through all three sizes. Only step 6 (a real Android/iOS pass) remains.

### Transition audit: a thought when no one can speak, no transitions on Media Ambush (2026-10-14, Cameron)

- **No one to speak, the player thinks.** When a transition resolves with no eligible speaker (no staff hired, no opponent cast), `StageTransition.resolve()` now falls back to one **internal thought** from Transition Dialogue rows whose Character ID is `PLAYER` (line in Character Line, reply blank; Stage ID scopes it like any row). `StageTransitionScreen` shows it on the blue side with no speaker portrait. With no PLAYER rows the transition is skipped as before. 10 generic first-person thoughts ship (TD242-TD251), drafts for Cameron to rewrite. `export_data.py` accepts `PLAYER` in that tab.
- **Media Ambush has no transitions:** Show Transition is No on ST19 and ST30.
- **Audit:** a Lobbyist Meeting had pulled the wildcard line "The cameras are ready, but you do not need them." (TD08), and TD05 spoke of reporters gathering. Both were press-flavoured lines with a blank Stage ID, reachable from any room; they are rewritten to be generic. The stage-scoped rows were checked family by family and fit their rooms (press/studio lines sit only in Press, TV Debate and Media Ambush rooms). Two new GUT tests guard this: no blank-Stage-ID line mentions camera/reporter/press/studio/headline/broadcast, and press/studio/viewer lines are scoped only to press-style rooms.

### Gap-filling batch: questions, transitions, cues, ticker (2026-10-14, Cameron)

All drafts for Cameron to rewrite; raw-XML workbook edit, `export_data.py` clean, `tools/content_depth.py` 0 measures below 3x and no room with zero questions.
- **Stage Questions (+142, S223-S364):** 90 generic (Floor Debate 30, Party Caucus 30, TV Debate 15, Steering Committee 15). The caucus set also serves every topic Party Caucus room and the TV set every topic TV Debate room (a Stage ID cell takes a list); each topic caucus/TV room also has 2 questions on its own topic, themed like that topic's sibling rooms. **This switches questions on in those rooms.** Bot trial (PC01, 40 fights): ST02 100% to 100%, ST03 27% to 100%, ST06 100% to 100%, ST08 0% to 0% (unchanged, already unwinnable for the bot), ST35 (topic caucus) about 85% to 52% (noisy), ST41 100% to 100%. Caucus got easier; its tuning is Cameron's to revisit.
- **Transitions:** 36 more generic staff lines (8 per staff member), 20 more player thoughts (30), 2 staff lines per topic room, and an opponent speaker from the seated pool in 82 slots across 59 rooms with a cast (not Caucus, Steering or Media Ambush: a caucus seats only the player's party).
- **Level Intro Thoughts:** LV61, LV62. **Vote Influence Cues:** the missing flip direction for every bill. **Office Ticker:** passed/failed line (law condition) for each of the 50 bills (+100). **Opponent Cues:** Cue 4 and 5 filled on the 250 opponent-specific rows (750 cells) from a suit-and-verb bank.
- **Not done:** topic Player Cue sets stay templated; Visitor questions for VI04-VI39; Office Notices law lines; the transition backgrounds gap proved empty (rooms fall back to their own stage art).

### Review fixes: stuck stage screens, safer saves, three engine bugs (2026-10-14, Cameron)

From `design/REVIEW_2026-10-14.md`:
- **A stage that cannot start now has an exit.** `StageStartFailure.show_on()` (`scripts/ui/StageStartFailure.gd`) covers the battle, visitor and vote screens with the reason and a "Back to the Office" button that ends the level. Two new Text rows (`stage.cannot_start_title`, `stage.cannot_start_leave`); the vote screen's raw setup problems now go through `battle.cannot_start`.
- **Saves.** `SaveManager.save_game()` checks the write succeeded and parses before swapping it in, and keeps the previous good save as `savegame.json.bak`; `read_save()` falls back to the backup if the main file is unreadable and sets `last_problem` ("unreadable" or "newer"). The title screen's Continue now shows a notice (Text rows `save.*`) instead of silently starting a new game. `GameState.load_save()` keeps the fresh run's entries for `meta`, `booster_standing` and `party_standing` (so a save from an older build gains new variables and drops removed ones) and `drop_stale_ids()` forgets cards, modifiers, levels, shop items, staff and packages the current data no longer has.
- **Engine.** A committee bout won at the end of a turn starts the next opponent on turn 1 with full energy (it started on turn 2); later committee members keep the config's default intent pattern; a "retry" stage outcome (`tie_retry`) replays the stage (`LevelRunner.RETRY`) instead of clearing it. Tests added for each.
- Not done from the review: R4-R11, the typed-in strings (U5), small fonts (U6), tween cleanup (U7), tap-outside-closes (U8).

### Late-game stress test, and two memory leaks fixed (2026-10-14, Cameron)

`tools/stress_late_game.gd` (step 6 of `tools/stress.sh`; `design/STRESS_LATE_GAME_2026-10-14.md` has the table) builds four extreme runs (everything maxed, everything zero, all crisis triggers on, huge stacked item bonuses) and checks rules in all 97 combat rooms, all 50 bills voted three ways, 400 level ends each, screen timings and a leak check. Result: no rule or range violations. It found **two leaks, both fixed**: `Overlay` left its Back/Confirm buttons outside the tree until opened (every Office load leaked about 130 objects and 0.4 MB), and the battle's random-roll lambdas captured `self`, so the engine and its runner held each other (about 40 KB per battle), plus the cue banner's `await`s now use a `Timer` child. Tests: `test_overlay_leak.gd`, `test_a_battle_engine_is_freed_when_nothing_holds_it`. Rule for new code: a lambda stored in a long-lived object must capture the thing it needs (the generator), not `self`; a Node must not `await` a timer.

### Thousands separators and a roomier Marketplace grid (2026-10-14, Cameron)

`Phrase._fill()` now writes whole numbers of 1,000 or more with commas when the placeholder is `{count}`, `{cost}` or `{price}` ("1,000,000 Yen", "25,000 Yen", "10,000 short."), so every Funds, price and shortfall line is covered in one place; seat counts, years and other placeholders are untouched (`Phrase.with_separators()`; `tests/test_number_format.gd`). Held-item tiles in the Marketplace/Inventory are 300 px wide and expand to fill, and at Large text the grid is two across with taller tiles (440 px) and icons capped at 200 px (three across and 300 px otherwise), so a long word such as COMMISSION no longer breaks mid-word and names stay inside their tile. The first build of this change silently failed to apply the column switch; a real screenshot at Large text caught it. Tests that matched raw numbers (`test_ledger.gd`, the staff-profile driver) now expect the comma form. Checked in a real 1080x2340 screenshot at Large text; not checked on a real device.

### Remaining icons identified; a brief and a merge checker for them (2026-10-14, Cameron)

The only icons not yet drawn are the 12 organisation icons **BO19-BO30** (the other 18 organisations, all 20 shop items and both cosmetic packages are done). `design/ICON_GENERATION_BRIEF.md` is the hand-off for whoever draws them: a per-organisation table (what it stands for, a suggested single-object picture, a dominant colour), the existing style (flat two-tone shapes, cream trim, one white sparkle, no text or background) with the exact palette taken from the finished icons, the technical spec (PNG, 256x256 RGBA, transparent corners, 16 px margin) and how to return the files. `design/reference/org_icon_style_sheet.png` shows the 18 finished organisation icons as the style reference. `tools/merge_icons.py <folder>` checks each returned file (name, size, mode, transparent corners, margin, fill, palette) and prints a pass/fail table; `--apply` copies them into `assets/icons/` only when every file passes and refreshes `design/ART_CHECKLIST.md`. Run `.tools/godot --headless --import` afterwards. The Ainu icons (BO28, BO29) are written to use real community motifs simply and respectfully; Cameron may want to review them first.

### The twelve organisation icons are drawn and merged (2026-10-14, Cameron)

BO19-BO30 arrived as a zip, passed `tools/merge_icons.py` (all twelve: 256x256 RGBA, transparent corners, margin, palette) and were checked by eye against the existing 18, then copied into `assets/icons/`. Every organisation, shop item and cosmetic package now has its icon (`design/ART_CHECKLIST.md`). The drawer's choices: a three-tier pagoda (BO19), a shimenawa rope with paper streamers (BO20), a hand cradling a heart (BO21), a medal on a ribbon (BO22), a coin purse with a magnifier (BO23), rising bars with a coin (BO24, no bank building), a shopfront (BO25), a basket with a check mark (BO26), apartment blocks with a tree (BO27), a banner with a symmetric spiral-and-scroll motif (BO28), an open book with a spiral motif (BO29) and a farmhouse with a sprout (BO30). Cameron may want to review the two Ainu icons (BO28, BO29).

### Backing prices get thousands separators; "free" comes from the Text tab (2026-10-14, Cameron)

The Boosters panel's price line (`OfficeScreen._cost_line()`) was built with a plain `%d`, so it read "25000 Funds" and "15000 Funds" while every Text-tab price already had commas; it now uses `Phrase.with_separators()`, and its typed-in word "free" now reads the existing `shop.item_free` row. `tests/interaction/office_menus_driver.gd` now opens the Boosters panel and fails on any bare run of four or more digits or if no price shows a comma. Found by looking at a real screenshot of the panel. The small standing numbers and a few other typed strings (review item U5) are still in scripts.

### Backings for the twelve new organisations; audience icons in the Boosters panel (2026-10-14, Cameron)

Cameron asked for both of: icons on the five Boosters rows that show none, and backings so BO19-BO30 appear in the panel.
- **Audience rows get audience icons.** The five backings triggered by an audience group (M01 Local Support, M02 Shotengai, M03/M04 the press ones, M09 Party Backing) belong to no organisation, so they showed no icon. `OfficeScreen._modifier_row()` now shows the group's own icon (`assets/icons/SG01.png` ... via `_audience_of()`), a labelled placeholder square until drawn. `tools/art_checklist.py` lists "Audience icons (Boosters panel)" (0 of 5 drawn today); `tools/merge_icons.py` now also checks and merges SG01-SG05; `design/ICON_PROMPT_AUDIENCE.md` is the filled-in paste-ready prompt for them (`design/ICON_PROMPT.md` is the reusable template).
- **Twelve draft backings, M33-M44, one per new organisation** (Modifiers tab rows 31-42; each linked from its organisation in the Boosters tab's Linked modifiers cell). All drafts for Cameron to correct, using only the four effect types the game already runs: M33 Temple Community Support (+1 card at Town Hall), M34 Shrine Festival Backing (+2 Jiban per level won), M35 Care Council Testimony (ST21 starts +10), M36 Veterans' Endorsement (ST11 +10), M37 Taxpayers' Scrutiny Backing (ST09 +10), M38 Financial Industry Backing (+3,000 Funds per level won, the richest payout), M39 Small Business Backing (+1 card at Lobbyist Meeting), M40 Consumer Watchdog Backing (Town Hall gaffe limit +1, 10,000 Funds), M41 Urban Alliance Backing (ST17 +10), M42 Ainu Council Backing (ST12 +10), M43 Language Foundation Backing (+10 XP per level won), M44 Rural Revitalization Backing (+1 card at ST13). Trigger minimums 15-30, costs 5-10 Reputation or Constituency support (M40 also 10,000 Funds). Like every backing they need standing 60 with the organisation, so they stay out of reach until standing rises. Raw-XML edit of the Modifiers and Boosters sheets only (confirmed no other sheet changed); `export_data.py` clean. Real screenshot: all twelve icons show in the panel. New tests in `test_modifier_effects.gd` (every booster-triggered backing is linked from its own organisation, every backing is implemented, each new organisation has one). BO17 Members of Parliament and BO18 Constituency Voters still have no backing.

### Backings for BO17 and BO18 (2026-10-14, Cameron)

Two more drafts, so **every one of the 30 organisations now has a backing to buy** (Modifiers tab rows 43-44, linked from the Boosters tab; Cameron's to correct): **M45 Parliamentary Colleagues' Support** (BO17 Members of Parliament; +1 card drawn at the start of ST02 Floor Debate, a stage no backing touched, 10 Reputation + 5 Constituency support, trigger 20) and **M46 Voters' Mandate** (BO18 Constituency Voters; +3 Jiban after each level won, one more than the Kōenkai's +2, 10 Reputation, trigger 25). Raw-XML edit, only the Modifiers and Boosters sheets changed; `export_data.py` clean. `test_every_organisation_has_a_backing` now covers BO17-BO30.

### Workbook editing tool and batch-builder scripts added to the repo (2026-10-14, Cameron)

The raw-XML workbook editor that every workbook change since 2026-09 relied on (`wbx.py`) had only ever lived in a scratch folder. It is now `tools/workbook/wbx.py`, with `tools/workbook/README.md` (how to use it and the after-every-edit checklist) and `tools/workbook/selftest.py` (copies the workbook, appends a Modifiers row, proves it reads back and that only that sheet changed). The scripts that generated each content batch (Batches 1-3, visitors and Level Intro cues, opponent cues, the gap-filling batch) and the read-only audit scripts are archived under `tools/workbook/archive/` as historical worked examples; they hard-code scratch paths and are not runnable as they stand. The expansion guide and the new-chat start-up document point at it. No game code or data changed.

### The five audience icons are drawn and merged (2026-10-14, Cameron)

SG01-SG05 (Press, Party Members, Constituents, Donors, Bureaucrats) now exist in `assets/icons/`, so the Boosters panel's five audience rows show icons instead of coloured placeholder squares. They were **generated by a script, not hand-drawn**: `tools/icons/make_audience_icons.py` follows the house recipe of the hand-drawn organisation icons (flat base shape, darker bevel along the lower right, thin cream rim on the upper left, one white sparkle, 4x supersampled to a clean 256x256 RGBA) with the exact palette. Subjects: a spiral notebook with a pen (Press, gold; M03 and M04 share it), a scalloped rosette with ribbon tails (Party Members, orange-red), three citizens (Constituents, teal), an envelope with a wax seal and a coin (Donors, orange-red), a document folder with papers and an official stamp (Bureaucrats, teal). All five passed `tools/merge_icons.py`, were compared by eye against the hand-drawn set and checked in a real Boosters screenshot. They are a draft in the same way the backings are: Cameron may prefer hand-drawn versions (`design/ICON_PROMPT_AUDIENCE.md` remains the prompt for that). Every icon the game asks for is now present (`design/ART_CHECKLIST.md`).

### An art prompt template; two review leftovers closed (2026-10-14, Cameron)

- **Art prompt template.** `design/ART_PROMPT_TEMPLATE.md` is one fill-in-the-slots prompt for every kind of picture (character, card art, background, icon): fixed style/canon/consistency blocks, a per-kind block with the canvas sizes from `data/art.json`, and a return checklist. `python3 tools/art_prompt.py character|card|background <ID>...` fills the slots the data knows (name, gender, role, party, card text and suit, stage name) and leaves `{HOUSE_STYLE}`, `{APPEARANCE}`, `{OUTFIT}`, `{SCENE}`, `{PLACE}`, `{MOOD}` for Cameron, since looks are his call. Icons keep their fuller prompt, `design/ICON_PROMPT.md`.
- **R9:** `GameState.reset_booster_standing()` fell back to 50 when `booster_standing.json` lacked `start`; every other path used 30. All now use 30.
- **U7:** `CueBanner` and `StageTransitionScreen` keep their tweens and kill them when a line is skipped or cleared (and the banner's jolt resets), so skipping mid-slide cannot leave the next line mis-positioned.
- **U8** was already handled (`Overlay.is_tap_outside()` ignores drags). Still open: R4-R8, R10-R11, U5 (typed-in strings), U6 (small fonts). GUT and `tools/verify.sh` green.

### Button outlines (2026-10-15, Cameron)

Every button has a 2 px outline (5 px until 2026-10-15, then reduced at Cameron's request; one constant, `Layout.OUTLINE_WIDTH`) in the player's party colour (`parties.json` RGB via `PartyDisplay`); buttons that back out of a screen have a white one. `Layout.gd` builds the outlined style boxes into the project theme at start (copied from Godot's own button states, so only the outline changes) and re-colours them when the protagonist's party changes (`_process`), so buttons already on screen follow. Before a run has a protagonist (title screen) the outline is a soft white. Cancel buttons use the theme variation `CancelButton`, applied to any plain Button named `Back` (every Overlay's way out), `DetailsClose`, `ZoomClose` or `LeaveButton`, or one with the meta `cancel` set (`Layout.CANCEL_NAMES`; add a name there for a new back-style button). Outcome-panel "continue" buttons keep the party colour. `tests/test_button_outline.gd`; checked in a real screenshot (Frontier Party green on the Office and battle screens). Not yet looked at: every Overlay panel's Back in a screenshot.

**Battle controls white too (2026-10-15, Cameron):** End Turn, Inventory and Details (`EndTurnButton`, `InventoryButton`, `DetailsButton`) also take the white outline; they are in `Layout.CANCEL_NAMES`.

**Marketplace button (2026-10-15, Cameron):** the Office's Marketplace button shares the node name `InventoryButton` with the battle screen's Inventory button, so it had picked up the white outline by mistake. It now carries the meta `party_outline`, which `Layout.is_cancel_button()` honours over the name, so it takes the party colour; the battle Inventory button stays white.

### A text pass: 11 more sentences moved into the Text tab (2026-10-15, Cameron)

Review item U5. Typed-in player-visible strings now read from the Text tab: the battle Details "Deck · Hand · Discard" line (`battle.deck_hand_discard`), the Boosters standing lines (`backing.standing`, `backing.standing_needs`), the briefing's "Against ..." and reporters lines (`briefing.against_one/many`, `briefing.reporters_ask`, `briefing.stage_fallback`), fallback names (`visitor.fallback_name`, `opponent.fallback_name`) and two staff messages (`staff.unknown_candidate`, `staff.nobody_hired`). Left as code on purpose: unused `BarModel.caption()`, the rules layer's `LevelRunner` fallback, language-neutral "name — N" formats and diagnostics. Only the Text sheet changed; wording snapshot accepted; GUT and `verify.sh` green.

### A "Saved" flash and one manual backup slot (2026-10-15, Cameron)

- **Saved flash.** `GameState.finish_stage()` now calls `SaveManager.autosave(true)`; on a successful write `Layout.flash(Text.say("save.saved"))` fades a small "Saved" line in at the top of whatever screen is showing (a CanvasLayer in the `Layout` autoload, so it survives the scene change). Other autosaves stay silent; test and click runs never flash (saving is off there).
- **Manual backup.** Administration menu: **Back up now** writes `user://savegame.manual.json` (`SaveManager.backup_now()`; never touched by autosave), **Restore the backup** (shown once one exists, with when it was made) asks first, then loads it, makes it the main save and reloads the Office (`restore_backup()`). One slot only; New Game leaves it alone. Nine Text rows (`save.saved`, `office.backup_*`). Test: `test_the_manual_backup_is_a_separate_slot_that_restores`.

### Floor Vote: influence readiness and a result preview (2026-10-15, Cameron)

Under the bill text the vote screen now says whether the player's influence can sway other parties yet (`FloorVoteEngine.influence_status()` → `VoteInfluence.status()`: ready if the gate passes for at least one party in the bill; otherwise the first three missing thresholds, "Reputation 25 of 60, ... and 13 more") and what each choice would give (`FloorVoteEngine.preview(choice)` builds a throwaway engine from the same config and votes it, so the real vote is untouched; shows totals, pass/fail and "Your influence turns the result." when the swing flips it). Nine Text rows (`floor_vote.influence_*`, `floor_vote.preview_*`). The text sits in a scroll container; the party row's minimum height rose 400 → 620 because the cue text of six parties had always run past 400 and was only hidden by the bill text being centred lower. Tests in `test_floor_vote_engine.gd`; checked in a real 1080x2340 screenshot and the aspect matrix.

### Your Record says why each number moved (2026-10-15, Cameron)

Each Sanban line that changed this level now ends with "because of ..." (e.g. "Reputation 40 (+5) because of won Floor Debate, level win bonuses"). `GameState.last_meta_cause` ({variable: [causes]}, cleared with `last_meta_change`) is filled by `_record_meta_change()` from `_cause`, which callers set around a block of rewards: stage win/loss (`record.cause_stage_win/loss`, with the stage name), level win bonuses, a Floor Vote's favorability and influence bonus (`apply_floor_vote_favorability()`/`apply_floor_vote_influence_bonus()` take an optional `cause`), the Level Intro lean, Law Effects rows (the law's bill name) and the lifetime gaffe penalty. The same cause is listed once per variable. Spending in the Office stays uncaused, like its `(+N)`. Nine `record.*` Text rows. Party support's displayed change also includes organisation moves, which carry no cause line.

### Player thoughts open transitions more often (2026-10-15, Cameron)

A transition with speakers now opens with the player's own private thought (a `PLAYER` row in Transition Dialogue) a set share of the time: new Balance lever **Transition: Player Thought Chance** (`transition_player_thought_chance`, 30 percent, Cameron's to retune; 0 = never). `StageTransition.resolve()` takes `thought_chance`; the thought plays first on the blue side, then the speakers as before (`StageTransitionScreen._lead_lines` keeps the speaker portrait in step). A transition with nobody to speak still always uses a thought when one is written. Test in `test_stage_transition.gd`; click test and `verify.sh` green.

### A Training Session Coupon (2026-10-15, Cameron)

New Shop item **SH21 Training Session Coupon** (150 XP, draft price) and a new optional Shop column **Free Card Tier** (`free_card_tier`; blank on every other row). Using the coupon in the Office (Marketplace) spends it and opens a free Rhetoric Training draw at that tier: the same up-to-three looks and Pass rules, nothing paid on **Learn it** (`GameState.use_item_in_office()` starts the draw, `learn_offered_card()` skips the price for a free draw, `_draw_tier()` reads either column). It is refused, and the coupon kept, while another draw is open or no card of that tier is left. `Items.has_effect()` counts a coupon as having an effect. After learning, the Office returns to the Marketplace. One new Text row (`rhetoric.coupon_used`); the Learn button reads "Learn it (Free)" from the existing rows. Icon `training_coupon` is not drawn yet (labelled placeholder; `art_checklist.py` shows 20/21).

**Cameron asked for a Tier 0 pull, but every Tier 0 card is already owned at the start of a run, so a Tier 0 coupon could never grant anything.** The cell is set to **Tier 1**; changing it is one number in the Shop tab. The column's header note is not written yet (add it in Excel with Insert Note). Tests: `tests/test_training_coupon.gd`.

### New runs start with a Training Session Coupon; two small fixes; proposals (2026-10-15, Cameron)

- **Starting coupon.** New Balance lever **Starting Training Session Coupons** (`starting_training_session_coupons`, 1): `GameState.reset_collection()` puts that many SH21 coupons in a new run's inventory (a loaded save overwrites it, so only new runs get them). Test: `test_a_new_run_starts_with_the_balance_lever_s_coupons`.
- **Floor Vote:** the influence note and result preview showed through the result panel after voting (my own regression, caught in a screenshot); they are hidden once the vote is cast. A meta trigger such as Reputation no longer triggers a "no booster with ID" warning in the influence line.
- **Your Record / New Game** show Funds with a thousands separator ("100,000"), found in the same screenshot.
- **Guard between opponents** needed no change: it already follows the stage's Sequence Mode (`reset` clears it, `stream` and `continuous` carry it), which is what the briefing and Details panel say (`StageCarryOver`). Review item R4 is therefore by design.
- **Proposals, not built:** `design/proposals/UI_PROPOSALS_2026-10-15.md` (vote result tiles, statute book, crisis alert wording, a crisis-stage plan, backup slot design), with the screenshots it refers to.

### Vote result tiles, Majority/Supermajority, law pop-ups, a fuller backup slot (2026-10-15, Cameron)

- **Floor Vote result (proposal 6).** The result panel now opens with three big tiles (**Aye / Nay / Abstain**), a whole-house meter (`VoteMeter`: Aye block green on a pass and red on a fail, with a white mark where the Yes votes needed end) and one line: "Majority Vote to Pass: 51 of 101 Yes votes needed. Short by 5. Abstentions count against a bill." (or "Cleared by N."). The same requirement line shows under the bill before voting. The existing per-party bars stay (each is scaled to its own total, so the 51 mark lives on the new meter, not on them).
- **Majority or Supermajority.** New optional **Vote Requirement** column on Floor Vote Bills (blank or Majority = 51 of 101; Supermajority = a share of the whole house) and Balance lever **Supermajority: Percent of House** (`supermajority_percent`, 67, rounded up, so 68 of 101; first draft, Cameron's to set). `FloorVoteEngine.yes_needed()`/`bill_passes()` take the requirement; `choose()` returns `requirement` and `yes_needed`; the statute book keeps both. **No bill is flagged Supermajority yet.** The exporter rejects any other value. Tests in `test_floor_vote_engine.gd`.
- **Law pop-ups (proposal 7).** Each law in Your Record's statute book is a button (tap hint above the list) that opens a pop-up (`LawPanel`): bill name, PASSED/FAILED, the requirement and what it needed, Aye/Nay/Abstain, how you voted, whether your influence turned it, and its fixed effects "when it was voted" and "at the end of every later level" from Law Effects (`_show_law()`, `_law_effect_lines()`). Party Headquarters and Party Faction are not listed, since they follow the player's party. Every level with a bill stage has such a law once voted.
- **Backup slot (proposal 12).** The label now reads "time · Last level cleared: ... · Inventory: n · XP: n · Funds: n" (`SaveSummary.of()`, pure; `SaveManager.summary_of()`). **Restore** shows the backup beside the current run before it asks; **Back up now** asks before replacing an existing backup; every restore first writes the current run to `user://savegame.undo.json`, and an **Undo the last restore** button (spent after use) puts it back. A restore is refused if the safety copy cannot be written. 27 new Text rows. Tests: `tests/test_save_summary.gd`. Checked in real 1080x2340 screenshots (vote result, law pop-up, Administration menu, restore warning).

### Vote result alignment, Aye / Nay wording, Administration cleanup (2026-10-15, Cameron)

- **The vote meter carries its own numbers.** The separate Aye/Nay/Abstain tiles are gone; `VoteMeter` now prints each count over its own block, in the same order as the blocks (Aye, Abstain, Nay), so Abstain sits over the Abstain block. Colours are fixed whatever the outcome: **Aye green, Nay red, Abstain white**. The gold mark is where the Aye votes needed end. `FloorVoteScreen._show_result_summary()` no longer builds tiles.
- **Aye / Nay everywhere a vote is shown:** "Vote Aye" / "Vote Nay" buttons, "46 Aye, 47 Nay, 8 abstaining", "Aye votes needed", the preview lines, Your Record's law lines and "You voted Aye", and the three party bars, now headed **Aye Votes / Nay Votes / Abstain Votes** (`floor_vote.bar_*`, set in code from the Text tab). Internal keys stay Yes/No/Abstain.
- **Law pop-up:** "When it was voted" now reads **"Reactions to Your Vote"** (`record.law_now`).
- **Administration menu:** the backup summary line (and the "no backup yet" line) between the buttons is removed; the buttons remain and the summary still shows in the restore, overwrite and undo warnings.

### Administration menu spacing and Save Game / Load Game labels (2026-10-15, Cameron)

The backup buttons used to sit inside one zero-gap column, so Save and Load touched. `OfficeScreen._backup_buttons()` now returns them as separate rows of the menu itself, so every gap matches the other buttons (checked in a real screenshot). Labels: "Back Up Now" is now **Save Game** and "Restore the Backup" is now **Load Game** (`office.backup_now`, `office.backup_restore`). The Reputation and Results menu already used plain rows, so its spacing was already even. Not checked: the Load Game button's own spacing in a screenshot (the throwaway shot had no backup written, so it was hidden).

### TV Debate rising threshold: workbook columns added, engine waiting for approval (2026-10-16, Cameron)

Stages tab columns **Threshold Rise Min**, **Threshold Rise Max** and **Threshold Cap** (`threshold_rise_min/max`, `threshold_cap`; blank = the line never moves, cap blank = Bar max) exist and export; `export_data.py` checks both-or-neither, Min 0 or more, Max at least Min, Cap between the Win threshold and Bar max, and warns on a non-Survival stage. Seeded 0 to 3 on ST06 and the six topic TV Debates (ST41, 44, 73, 84, 91, 98) as a draft. **The engine does not read them yet**, so no behaviour changed. The plan, rule and open decisions are in `design/proposals/TV_DEBATE_RISING_THRESHOLD_2026-10-16.md`. Header notes for the three columns are not written (Insert Note in Excel).

### The TV Debate's line now rises each turn (2026-10-16, Cameron)

Cameron approved the plan and kept the draft range **0 to 3**. `BattleEngine._raise_threshold()` runs in `end_turn()` after the survival check passes (so never after the last turn): on a Survival bar with **Threshold Rise Min/Max** set (Stages tab), it rolls a whole number from Min to Max inclusive off the battle's own seeded generator and adds it to the line, never past **Threshold Cap** (blank = Bar max). Turn 1 always uses the base line; the rise accumulates; blank Min/Max or any other bar model leaves the line alone. `end_turn()`'s result carries `threshold_rise` and `threshold`. `BattleScreen` says "The line rises by N, to M." (Text `battle.threshold_rises`) in the notices, the bar redraws at the new number, `StageBrief` says the range in the Details panel (`brief.winning.survival_rising`), and How to Play HT06 mentions it in relative words. Seeded on ST06 and the six topic TV Debates; Cameron will edit the numbers in the workbook. Tests: seven in `test_battle_engine.gd` (inside the range, accumulates, cap, blank, no rise after the last turn, losing to the risen line, ignored on other rooms). Bot stage trial ST06 (PC02, 40 fights): 40/40 won, as before. GUT and `verify.sh` green.

### Terminology pass 1: money, the audience group, bar and Jiban wording (2026-10-16, Cameron)

From `design/TERMINOLOGY_REVIEW_2026-10-16.md` (H3, the "support" overload, is revisited later).
- **Funds is a category; an amount of money is written with the 円 mark.** `Phrase.meta_amount(variable, amount, signed)` writes Funds as "100,000円" / "+1,500円" and every other variable as a plain number; used for the New Game and Your Record Sanban lines, the Your Record effect line, the briefing and outcome reward/loss lines ("Funds +10,000円"), a backing's cost ("Funds 10,000円"), and the backup label. Prices and costs in the Text tab now read "{cost}円" instead of "{cost} Yen" (shop, staff hire/upgrade/severance, Funds cap, "10,000円 short."). A shortfall in a variable that is not Funds uses the new `shop.meta_short` ("{count} short."), not `shop.funds_short`. The six backing effect cells that read "+1,500 Funds (Yen)" now read "Funds +1,500円 ...". `office.funds_buys` no longer says "donors and backers".
- **The audience group Donors (SG04) is now "Boosters"** (Segments tab, the three cards that read it, C24's text and note). The Stages tab column `% Donors` became `% Boosters` (`pct_boosters`; the exporter derives that column name from the segment's name, so renaming the segment alone broke every stage's audience total). Not changed: the segment's Japanese name (支援者), the Boosters panel's own name, visitor dialogue that says "Donors", design docs, and the `ArtLoader`/icon ID SG04.
- **TV Debate backing** (M04) now says "+10 Viewer Interest", the room's own bar word. **Four backing effect cells that said "Jiban"** now say "Constituency support".
- GUT 1115 and `verify.sh` green; `test_ledger.gd` shortfall expectations now carry 円.

### Terminology pass 2: American spelling, Threshold, Staff Rank, Party Bodies (2026-10-16, Cameron)

From the round-2 audit; his decisions applied (bar unit names, "Support", "Press" and the Boosters overload were left alone on purpose; the Boosters wording waits for a more detailed round).
- **American spelling everywhere** (359 workbook cells, the header notes, and the Question Themes header, now "Organization", with `export_data.py` following): favor, neighbor, defense, honor, labor, harbor, organization, apologize, labeling and the like, including the stage bar unit "Favorability" and the backing text. Theme keys in Stage/Question tabs changed together, so the exact-match join still holds.
- **Threshold** replaces "the line" and "win mark" in outcome reasons, the rising-threshold notice, the Details brief and How to Play (HT03, HT06).
- **Card zoom** room lines now describe what really drives them, the stage's suit affinity: "This room (greatly) favors / resists this suit." (the old "supporters / detractors" implied an audience).
- **Staff Rank** replaces "Tier" for staff (hire, upgrade, profile, recruitment, SH12, and the "is Rank N" conditions on the Commission items). Card tier, level tier and the Tier columns stay.
- **Organization scope headings**: Important Stakeholders shows **Party Bodies**, Constituency and National (new Text rows `office.scope_*`); the data value "Party" is unchanged because the rules read it. Shop Commission and dinner text says "Party Bodies booster group" / "National booster group".
- **Staff approval bonuses** read "approval among {audience}" (organizations keep "standing with").
- **Funds (Yen)** removed from the SH09-SH11 conditions. **"Battle"** retired from How to Play and the stage-start message ("Between Levels" group). The unused Office XP caption was removed from Office Management (`office.xp_buys` row now unused). The card name "Drawing Battle Lines" stays (a card name).
- Not changed: developer comments in hand-maintained JSON, column headers such as "Tier", "Funds (Yen)", "Music: Battle Sound".

### Press conference: the last turn is played out; questions are cues (2026-10-16, Cameron)

- **The final question no longer ends the conference on the first card.** The last question is answered by the first card of turn N of N, but `BattleEngine._check_outcome()` closed the conference at once, throwing away the rest of the hand and energy (screenshot: closed on 51 against 55 with energy left). It now closes when the player ends that turn (or when nothing is left to play, as an ordinary close, not "ran out of cards"). Extra cards that turn still raise the tone; the one question per turn rule is unchanged. Test `test_a_conference_waits_for_the_end_of_the_last_turn`; two older tests now end the turn before expecting the close.
- **Questions appear as CueBanner cues.** The reporter's question used to be printed as static text beside the portrait with no name plate; that line is blank now (`OpponentPresenter.show_state()`), and `BattleScreen._announce_question()` also runs in a press conference, so the question arrives on the banner under the asking journalist's name tag, like a Town Hall question. "That was the last question." is no longer shown (nothing speaks it).

**Banner nameplate is the name only (2026-10-16, Cameron):** a press-conference question's cue-banner tag shows just the journalist's name (`OpponentPresenter.question_speaker_name()`), without title or affiliation, like every other banner speaker. The opponent row's own label keeps its title.

**Title-screen outlines are gold (2026-10-16, Cameron):** the title screen's buttons took the party green of a run left loaded in memory. `Layout.set_outline_override()` makes every party-coloured outline the cue-banner gold (`CueBanner.EDGE_COLOUR`) while `IntroScreen` is open, and `IntroScreen._exit_tree()` hands the colour back to the player's party. Checked in a real 1080x2340 screenshot with a Frontier Party run loaded.

### Booster standing is harder to hold; the Details panel says who a question is about (2026-10-16, Cameron)

Play tests showed organizations' standing only ever rose (a strong answer +5 per org, a weak one −1, no decay). Cameron approved options 1-4, 6 and 7 of the evaluation (rival organizations, option 5, held for later).
- **Every answer counts, penalties match rewards (1).** `BattleState.booster_tally` ({id: {pleased, displeased, opposed}}, filled by `BattleEngine._tally_answer()`, read through `engine.booster_tally()`) counts each answer; the old lists stay deduplicated for icons and carried buffs. `booster_standing.json`: `per_displease` 1 → 3, `question_swing_cap` 5 → 10 (either way). `finish_stage()` takes the tally as a new final argument; without it each listed org counts once.
- **Diminishing returns (3).** `gain_bands` (x1.0 below 40, x0.6 below 60, x0.4 above) and `loss_bands` (x1.0 below 60, x1.5 above), ordered {below, factor} steps; a non-zero amount never rounds to 0. Pure `BoosterStanding.net_for()`; `BoosterChange.compute()` (outcome panel icons) and `GameState._apply_question_boosters()` share it, reading the standing as it is now, so the number shown is the number that lands.
- **Neglect decay (2).** `neglect_decay` (1): at the end of each level, every organization whose standing did not move at all that level (`last_booster_change`) drifts that many points toward its own starting standing (`GameState._apply_neglect_decay()`, `BoosterStanding.decayed()`). 0 turns it off. The drift shows as a (−1) on Important Stakeholders like any change.
- **Who cares (4).** The Details panel's "This question invites a {suit} answer." is replaced by live lines (`BattleScreen._question_concerns_lines()`): "This question is about: {orgs}." / "A strong answer pleases them. A weak one annoys them." / "A strong answer sets back: {orgs}." (`battle.question_concerns/stakes/sets_back`; `battle.question_invites` is unused now).
- **More set-back themes (7).** Question Themes' Annoys column filled on 226 of 272 themes: each theme's first one or two organizations' rival interests (a draft map: Chamber and Small Business against Labor, Financial against Consumer Advocacy, Taxpayers against Care and Welfare, Innovation against Artisans, Urban against Rural and Agricultural, Traditional Society against Students and the Ainu groups, Media against Party Headquarters, and so on), each cell's Why note says "Draft 2026-10-16". Claude's pairings, Cameron's to correct.
- **Deliberate snubs (6).** All 59 visitors' Penalty cells (what a wrong answer costs) are harsher: each negative delta x3 (−1 → −3) and the visitor's main rival organization is annoyed −2. A schema with per-choice booster effects, and snub shop items, were not built (a schema change; option for later).
- **Balance check** (simulation, random answers vs a 60% strong-answer player, 8 questions a stage): a casual player now settles around 30-40 standing and a skilled one around 50, so the backing threshold of 60 needs targeted play. Tests: `tests/test_booster_standing.gd` (12). GUT 1128/1128.

### Visitor dilemmas and three snub items (2026-10-16, Cameron)

- **Visitor dilemmas (V3).** Visitor Questions gained twelve optional columns: **Effects A-D** (a target list per choice), **Response A-D** and **Reaction A-D**. `OfficeHoursEngine.answer()` applies the picked choice's own effects, response and reaction; a choice with no Effects falls back to the visitor's Reward (the Correct Choice) or Penalty, and blank Response/Reaction to the old Right/Wrong lines, so unfinished questions still play. `correct` now means "not a net setback" (`OfficeHoursEngine.net_delta()`); `outcome()` also returns every `effects` list. The visitor screen shows what moved ("Standing: Neighborhood Associations +3, Mayors' Network -1.", `office_hours.effects`); the end line is now just "N visitors seen." (`GameState.apply_visitor_reward_entries()` returns the description). DataDB validates every target in an Effects cell, and only demands a Correct Choice when no choice has effects. Sanban variables cannot be Effects targets (only organizations, items, modifiers, segments). Visitor standing changes are flat; the battle's standing bands do not scale them. **All 134 questions now have dilemma effects** (batch 1, 39 questions, then the other 95 on 2026-10-16; drafts for Cameron to correct); the fallback still serves any future question left blank. Guide and budget rules: `design/VISITOR_DILEMMA_GUIDE.md`.
- **Snub items (Shop SH22-SH24).** **SH22 Attacking Op-Ed** (10 XP + 10,000円, a National organization -3, Office only), **SH23 Leak a Memo** (100 XP, a Constituency organization -4, Office only), **SH24 Public Rebuke** (30 XP, a Party Body -5, Office only, once a level). All are player-choice grants over one tier each (`TIER:National`, `TIER:Constituency`, `TIER:Party`; Cameron narrowed them 2026-10-16). The `TIER:All` pool (`RewardTargets.TIER_ALL`) still exists but no item uses it. Flat grants, no bands. Icons reuse existing art: Attacking Op-Ed `press_engagement`, Leak a Memo `paperwork_automation`, Public Rebuke `BO01` (Party Headquarters), and the Training Session Coupon `unlock_card_t1`; all 21 shop icons are present. Tests: `tests/test_snub_items.gd`, new cases in `test_office_hours_engine.gd`.
- Header notes for the twelve new columns were written 2026-10-16 (see below). GUT 1141/1141, `verify.sh` green.

### Header notes for the newest columns (2026-10-16, Cameron)

18 notes added: the twelve Visitor Questions columns (Effects/Response/Reaction A-D), Shop **Free Card Tier**, Stages **Threshold Rise Min/Max** and **Threshold Cap**, Floor Vote Bills **Vote Requirement** and Floor Vote Party Positions **Salience**. `tools/workbook/add_notes.py` (new) appends a note to a header by editing only that tab's comments and VML parts (the rest of the .xlsx stays byte-identical; confirmed by comparing every zip member, and `export_data.py` output unchanged). Later columns can use it: `add_notes(path, [(sheet, "AD", "text")])`. Not covered: the Affinity tab's newer stage columns (ST24 onward), whose headers are stage IDs.

### All visitor questions are dilemmas (2026-10-16, Cameron)

The remaining 95 visitor questions (VQ21, VQ40-VQ134: the party visitors VI16-VI39 and the one-per-bill visitors VI40-VI59) now carry Effects, Response and Reaction for all four choices, so every one of the 134 questions is a dilemma. The same budget as batch 1 (2 to 7 points a choice, a gain above 1 must cost something, one strongly pleasing choice, no more than two good ones, no time words, responses of 14 words or fewer) was checked by an audit script before writing and is now a permanent test (`test_every_real_dilemma_stays_inside_the_content_budget`). Party visitors mostly move Party Headquarters and Party Faction against each other (plus Members of Parliament, Constituency Voters, National Media and a few others); bill visitors move their own friend organizations against the rival the old Penalty named. All drafts. The playtest bot (`tools/playtest_optimal.gd`, `_play_visitor_stage()`) now picks the choice with the best net standing change instead of the retired Correct Choice. Raw-XML edit of the Visitor Questions tab only (confirmed by comparing every zip member); `export_data.py` clean.

### The rhetoric and bill through-line (2026-10-18, Cameron)

Cameron's ask: card plays and questions should visibly connect to organizations, and a bill level should hold together from the bill's nature through the player's lean, the stages and the final vote (`design/proposals/RHETORIC_AND_BILL_THROUGHLINE_2026-10-18.md`). Built in six steps.

**Bill stance rules** (`scripts/rules/BillStance.gd`, pure; saved as `GameState.bill_stance`, cleared at level start, end and abandon). The **lean** chosen at the Level Intro (Support/Oppose) makes two sides from the bill's Law Effects "Passed / Once" row, Party-tier organizations left out (they follow party lean): **winners** (positive delta) and **losers** (negative), or a **Stakeholders Override** cell (`BO05+; BO28-`) when the derived list is wrong. Your own side is the one you lean toward. Effects, all lever-driven so future modifiers can raise them (Balance tab): a rhetorical answer that pleases an organization on the far side counts **half** (`stance_other_side_please_percent` 50, rounded down; one answer counts for nothing); winning a Combat stage in a bill level pushes your side up and the far side down by `stance_win_drift` (2); at the vote, a vote matching the lean moves each side by `stance_vote_delta` (2); **switching** costs the abandoned side `stance_flip_abandoned_penalty` (5, harsher than a win drift) and can **recover** `stance_flip_recovery_percent` (25, rounded down) of what that side lost to your stance, never more; switching away from your party's position costs `stance_flip_party_support_away` (3) Party support, toward it earns `stance_flip_party_support_toward` (1); a Neutral party has no position, abstaining moves nobody. Flip-flopping is mitigation, not absolution. `GameState.apply_stance_vote()` / `preview_stance_vote()` / `stance_drift_preview()`; tests `test_bill_stance.gd`, `test_game_state_stance.gd` (the Ainu example on real LV31/BI01 as PC04).

**Where it shows:** Level Intro names the proponent party (new **Proponent Party** column on Floor Vote Bills, all 50 drafted) and each party's position, then the lean; the briefing lists the bill's winners and losers; the battle Details panel states your stance; the Floor Vote screen previews what each choice would do to each side and reports it afterward; the Outcome panel says the win drift. `StanceLines.gd` holds the wording helpers. Your Record carries a stance cause line for Party support only (organization changes have no cause lines yet).

**Bill-scoped content.** New optional columns: Stage Questions **Bill ID**, Player Cues **Bill ID** and **Stance**, Opponent Cues **Bill ID**, Transition Dialogue **Bill ID** and **Stance** (Stance only on rows with a Bill ID; blank Stance = both). A row with a Bill ID is indexed apart from room content and reaches only that bill's level. Priority: bill + verb + stance, bill + verb, bill any-verb + stance, bill any-verb; opponent cues try bill bespoke then bill + suit before everything else; transitions prefer bill rows. `BattleEngine._draw_questions()` deals bill questions first, up to `bill_question_share_percent` (50) of the questions a room asks. Level Intro Thoughts have **no** Stance column (the thought comes before the lean).

**Batch 4 content** (`tools/workbook/archive/batch4_bill_content_2026-10-18.py`, templated drafts for Cameron to rewrite): per bill, 4 questions (cost, need, critics, backers) and a Question Themes row (pleases the bill's Law Effects winners, sets back its losers), 12 Player Cue rows (6 suits x Support/Oppose), 18 Opponent Cue rows (6 suits x attack/gain/block, neutral probing lines), 8 Transition Dialogue rows (three staff x two stances, plus a PLAYER thought per stance). A bill name longer than five words appears as "this bill" in cue lines. `test_every_real_bill_has_questions_cues_and_transition_lines` guards all 50.

**Listening strip** (`ListeningStrip.gd`, `OrgPreview.gd`): in the table space of the battle screen, the organizations the open question concerns appear as icons. Lifting a card, or tapping it once, shows a translucent grey/green/red layer and a floating +N/-N for what playing it would do (`BattleEngine.answer_effect()` plus the same `BoosterChange` arithmetic as the Outcome panel, stance included); a **Read** button or a second tap opens the card. A card that would move nobody, or a room with no question, opens at once. After a play the real change flashes. An organization whose backing the player owns also shows the suits it likes and dislikes (`BoosterSuitTendency.taste_of()`, from the questions themselves). `tests/interaction/org_preview_test.tscn` (in `verify.sh`).

Also fixed in the same session: next-turn energy pips kept the old maximum after a stage item raised it (`energy_max`). Not built (shelved by Cameron): inverse twin bills. Guide: `design/WORKBOOK_EXPANSION_GUIDE.md` §2.10.

### Party Activists and the Candidate Selection Committee (2026-10-18, Cameron)

Two new **Party Bodies** (Tier Party, so they belong to whichever party the player is in, follow the player's party lean at votes, and are not stakeholders of any bill): **BO31 Party Activists** (党活動家, starting standing 5, likes divisive rhetoric) and **BO32 Candidate Selection Committee** (公認候補選考委員会, starting standing 15, balanced). Plan and decisions: `design/proposals/PARTY_ACTIVISTS_AND_SELECTION_COMMITTEE_2026-10-18.md`; builder scripts `tools/workbook/archive/batch5_*.py`, `tools/icons/make_party_body_icons.py`.

- **Per-body vote lean** (Cameron: "B"): Boosters gains **Party Lean Multiplier** (`party_lean_multiplier`, blank = 1.0). The Party-tier reaction to a bill (`law_lean_party_tier_*`, salience-scaled) is multiplied per body: Party Faction 1.5, Activists 2.0, Committee 0.5, Headquarters 1.0. A non-zero reaction never rounds to nothing.
- **Standing Links tab** (new, `data/standing_links.json`, optional): `Source` (a BOxx or a Sanban name) → `Target` (BOxx) with a signed `Weight`: the share of the source's change, in standing points, that the target takes; negative weights are **rivalries**. Funds counts one point per `Standing Links: Yen Per Point` yen (Balance, 10,000) so its volatility pulls little; other meta values are read on a 0-100 scale. One hop only (a followed change starts no further link) and neglect decay triggers nothing. Fractions carry over (`StandingLinks.settle()`), so small changes add up. `GameState._follow_links()`, hooked into `_apply_booster_delta()` and `_record_meta_change()`; Your Record and Important Stakeholders say why ("because of changes in Reputation", "its rivalry with Party Faction"). Draft rows: the Committee follows Reputation 0.25, Constituency Voters 0.25, Party Headquarters 0.15, Local Kōenkai 0.15, National Media 0.05 and Funds 0.1; rivalries Activists <-> Committee and Headquarters <-> Faction at -0.3 each way.
- **M47 Activist Ground Game**: +5 starting support at every Town Hall and Party Caucus room (`STAGE_START_BONUS`; Effect Target now accepts a semicolon list of stages, `ModifierEffects.targets_of()`). **M48 Selection Committee Endorsement**: new effect type `PARTY_BILL_FLIP_BONUS` (target PartySupport, value 5): +5 Party support when the player's influence turns a bill their own party backs from failing to passing (`GameState.apply_flip_backing()`, called by `FloorVoteScreen`). Both need the organization's standing at the Trigger min % to apply (20 and 15) and 60 standing to buy, like any backing.
- **Rhetorical styles, not suits, to the player.** Player-facing text no longer says "suit": the battle taste line reads "Likes divisive rhetoric." / "Dislikes data driven and earnest rhetoric."; the room lines read "This room favors this rhetorical style."; the How to Play entries (HT09, HT12, HT20, HT21) and its table ("Earnest rhetoric: ...") follow. Internal names stay (Earnest, Emotional, Appeal, Data Driven, Divisive, Duplicitous). Use this wording in all new player-facing content.
- **Content (drafts):** BO31 added to 28 existing themes with strong Divisive answers plus 8 new questions (taste reads Divisive only); BO32 added to 7 party-process themes plus 10 new balanced questions (no taste shown); 18 new Stage Questions in every Party Caucus; 6 visitor dilemmas (VQ35, 36, 38, 39, 40, 52) gained effects on the two bodies; four Office Ticker lines (TK144-TK147). Icons are script-drawn (`BO31.png` raised fist with a flame at the wrist, `BO32.png` ballot paper with a magnifying glass); Cameron may prefer hand-drawn versions.
- Tests: `tests/test_party_bodies.gd`. Tests that put organizations at exact values now clear `DataDB.standing_links` for their duration, and the Commission "TIER:Party" pool now has four members.

### Bill-specific stages for every bill level; a default background for every stage (2026-10-18, Cameron)

Plan: `design/proposals/BILL_STAGES_PLAN_2026-10-18.md`. All 50 bill levels now play bill-specific stages. The 20 newer levels (LV63-LV82) already did; the 30 older ones (LV31-LV60) used generic rooms in 140 slots. `tools/workbook/archive/batch9_bill_stages_2026-10-18.py` replaced each with a **copy of the generic stage about that bill**: 139 new stages ST121-ST259, one per (bill, generic stage), named "{Room} on {Topic}" ("Town Hall on Ainu Heritage and Language"), "Committee on Finance: {Topic}" for committees and "Office Hours: {Topic}", with the generic row's numbers copied (thresholds, energy, turns, opponent count, sequence mode, rewards, question pool, transition flag; the Japanese name stays the generic stage's, since bill names have no Japanese yet). A copy has its own Affinity column (the generic stage's multipliers). Every table that names the generic stage also names its copies, so the same people, shared questions, cues, transitions and the Town Hall/Caucus backing M47 reach them (Opponents, Stage Questions, Player Cues, Opponent Cues, Visitors, Modifiers, and rows duplicated in Transition Cast, Transition Backgrounds and Transition Dialogue). The bill's own content (bill-scoped questions, stance cues, transitions) already reached every stage of its level. The 11 older levels with Office Hours also have a **bill-specific visitor** (VI60-VI70, "{Organization} Representative", no invented person) with two dilemma questions (VQ135-VQ156) built from the bill's Law Effects winners and losers, pinned to that slot (`level_visitor_overrides.json`).

**Background ID** (new Stages column, `background_id`; blank = own ID). `ArtLoader.background_path()` tries the stage's own picture, then its Background ID's (`DataDB.stage_background_id()`). Every stage from ST24 on has one: Town Hall ST05, Party Caucus ST03, Press Conference ST04, Policy Study ST21, TV Debate ST06, Lobbyist ST20, Media Ambush ST19, Office Hours ST07, and a Hearing takes its committee's stage (Environment ST10, War ST11, National Assembly ST12, Agriculture ST13, Foreign Affairs ST14, Construction ST15, Finance ST16, Government Administration ST17, Ethics ST09). Give a stage its own `ST33.png` and it is used automatically. The exporter's committee seating rule now reads the room kind before a colon, so a "Committee on Finance: Topic" copy still seats only Finance members. Tests: `tests/test_bill_stages.gd` (no generic stage in a bill level, every stage resolves to a background, copies match their family, every copy seats people, pinned visitors are eligible). `tools/content_depth.py`: 0 measures below 3x across 225 rooms.

### Content 2: opponents sound different in each style they use (2026-10-18, Cameron)

Cameron's call on the opponent-cue expansion (his option A and C). Opponents have three styles (`suit_1` 55%, `suit_2` 30%, `suit_3` 10% of moves, 5% a style not theirs). Until now a personal Opponent Cues row ignored its Suit when looked up, so an opponent spoke the same 15 lines whichever style they rolled and the shared style pools (60 rows) were never heard.
- **A: personal rows are style-aware.** `DataDB.get_bespoke_opponent_cue_lines()` takes the rolled style and tries, most specific first: this opponent in this stage, this opponent in this style, this opponent in any style (the old behaviour), then the style's shared pool. Rows are filed by opponent + suit + verb as well as opponent + verb. **693 new personal rows (OC1336 onward)** give every opponent lines for their second and third style (an opponent with a repeated style gets one), in that style's Tone Guide voice, with a line on the speaker's business (Role) and one on their party's concern. Generator and voice banks: `tools/workbook/archive/b7/`. Drafts for Cameron to rewrite.
- **C: the shared style pool speaks now and then.** New Balance lever **Opponent Cues: General Pool Chance** (`opponent_cues_general_pool_chance`, 25 percent, first draft): after the personal lookup, that share of moves uses the shared pool for the rolled style instead. 0 turns it off.
- Tests in `tests/test_opponent_cues.gd` (style-aware lookup, pool chance); the older tests set the lever to 0 so they stay pinned.

### Content 3: every bill-specific room asks its own questions (2026-10-18, Cameron)

253 Stage Questions (S583 onward) for the bill-specific copies ST121-ST259: two for each question-asking room (one for a TV Debate; Office Hours copies have visitors instead), each with the copy's own Stage ID so it reaches that room alone. They are written from `design/reference/bill_facets.json` (new: for each of the 50 bills, the core provision, who gains, who pays, what changes locally, the risk, the critics' line and a smaller alternative, all drafts) through family-shaped stems (a hearing asks who runs it and what stops the risk, a Town Hall what changes locally, a press conference how voters can trust it, a caucus how to explain it back home, and so on) with grade profiles that follow the Stage Questions rules (at least two Strong, at most two Weak). Theme is each bill's own "{bill} debate" theme. Generator: `tools/workbook/archive/b8/clone_questions.py`.

**A real bug found on the way:** the six Town Hall copies (ST122, ST136, ST149, ST174, ST180, ST198) had no question pool, because the base Town Hall gets its pool from a built-in default (`BattleSetup.QUESTION_POOL_BY_STAGE`) that copies do not inherit, so they asked only the shared and bill questions. Their Question Pool cell now says town_hall, and `test_a_stage_copy_draws_from_its_families_question_pool` guards every copy. Tests: `test_every_bill_stage_copy_of_a_question_room_has_its_own_questions`. Bot trials on three copies: 30/30 each, in line with their families.

### Content 4: five generic questions for every committee (2026-10-18, Cameron)

55 Stage Questions (11 committees: ST01 and ST09-ST18, five each), each shared with the committee's bill-specific and topic copies (the Stage ID cell lists the base room and every stage whose Background ID is that room). They are committee-generic: no bill, no party, no named person. Examples: Ethics asks whether members should publish every gift; Finance asks which budget line you would cut; Construction asks who pays when a road runs over budget. 55 new Question Themes rows (pleasing 1-3 organizations, annoying the obvious rival) are Claude's draft, tagged "Draft 2026-10-18". A committee now draws from 36-41 questions for the 10 it asks (about 3.6x) instead of 31. Generator: `tools/workbook/archive/b8/committee_questions.py`. Bot trials (PC01, 30 fights each) on ST01, ST09, ST16 and ST18: 30/30, as before (the Cabinet committee stays much easier than its 2026-10-07 tuning, which Cameron chose to leave).

### Content 5: more ways to please the organizations that stayed out of reach (2026-10-18, Cameron)

The balance audit found ten organizations that no bot run lifted to the 60 standing a backing needs (Agricultural Cooperatives, Students United, Family Network, Yezo Artisans Guild, Members of Parliament, Shrine Association, Care and Welfare Council, Urban Neighborhood Alliance, Ainu Language and Culture Foundation, Rural Revitalization Council). Each gained **ten questions** (four Town Hall T105 onward, three Lobbyist L79 onward, three Study Session B31 onward; 100 in all), written in the voice of that group's people and graded so the group's natural rhetorical style is Strong, with 100 new Question Themes rows (pleasing the group, sometimes a second, and setting back its obvious rival). Each also has **one visitor** (VI71-VI80, "{Organization} Representative", no invented person) with **two dilemma questions** (VQ157-VQ176; a friend-pleaser, a rival-pleaser, a middle path and a refusal, inside the dilemma budget). Visitors list the same Office Hours stages as VI01. Party Activists were not touched (36 questions already). Generators: `tools/workbook/archive/b8/org_questions.py`, `org_visitors.py`.

Also fixed: the 22 bill-visitor questions (VQ135-VQ156) read "the the Ainu Heritage and Language" (doubled article, "Act" dropped); they now name the bill in full (`fix_visitor_bill_names.py`).

### Content 6: more dilemmas for the original fifteen visitors (2026-10-18, Cameron)

VI01-VI15 each gained three new dilemma questions (45 in all, VQ177-VQ221; each visitor now has 5 to 6), on new scenes rather than repeats: the neighbors' leaking hall roof, seals eating the catch, platform doors, a faction boss's rising rival, and so on. Each question follows the dilemma budget (a friend-pleaser, a rival-pleaser, a middle path, a refusal); the friend and rival organizations for each visitor are listed at the top of `tools/workbook/archive/b8/visitor_variety.py`. All drafts. The dilemma budget test in `test_office_hours_engine.gd` covers them.

### Content 10: the player's style lines for six more room families (2026-10-18, Cameron)

Floor Debate (ST02), Press Conference (ST04), Party Steering Committee (ST08), Media Ambush (ST19), Lobbyist Meeting (ST20) and Policy Study Session (ST21) had no player cues of their own, so the player spoke the card's generic Flavor Text there. Each now has **18 Player Cue rows** (six styles x attack, gain, block, five lines each; 108 rows, PL starting after the last existing row), shared with every bill-specific and topic copy of that room (the Stage ID cell lists the room and every stage whose Background ID is that room). Lines use each room's own setting (the floor and its benches, reporters and headlines, the party's platform and discipline, cameras and the hallway, access and interests, studies and experts) in the Tone Guide's style voices. Where a topic room already had its own cue set, the two sets merge into one pool. All drafts. Generator: `tools/workbook/archive/b8/room_family_cues.py`.

**A flake fixed on the way:** `org_preview_test` sometimes clicked a card in the hand that lies beyond the right edge (the hand row scrolls, 5 cards do not fit in 1080 px) and failed; it now taps only a card that is on screen.

### Content 7: the player's thoughts (2026-10-18, Cameron)

- **Level Intro Thoughts:** every level now has **three** thoughts instead of one (164 new rows; the 50 bill levels' two new ones are written from the bill's facets in `design/reference/bill_facets.json`: who gains and who pays, and the worry and the hope; the other 32 levels have two hand-written each). Several rows may now name one level, and `LevelIntroCues.player_thought()` picks one at random (an optional `roll` pins it in tests); the exporter no longer warns about repeats. **The thought is now spoken on any level whose intro screen shows**, not only on bill levels (before, the 32 non-bill levels' thoughts were never heard). A level with no written staff lines and no bill still skips the intro screen, as before.
- **Transition Dialogue now accepts a list in its Stage ID cell** ("ST05; ST122; ST136"), as Stage Questions and Player Cues already did: `PoolPicker.eligible()` matches any listed stage, and the exporter checks each. This lets one thought serve a room family and its copies.
- **PLAYER thoughts (254 new rows):** nine room-family sets of six (Town Hall, Party Caucus, Press Conference, Policy Study, TV Debate, Lobbyist, Floor Debate, Steering Committee and all committees together), each shared with the family's bill-specific and topic copies, and four for every bill (two Support, two Oppose; for example "If I back {the bill}, I should be ready to answer for {its risk}" and "Someone has to speak for {who pays}"). All drafts. Generator: `tools/workbook/archive/b8/thoughts.py`.
- Two transition audit tests now ignore a bill-scoped line's subject matter (a surveillance bill may talk about cameras) and read a Stage ID list. New tests: several thoughts per level, and a list in a Stage ID cell.

### Content 1: the templated bill content is now written from each bill (2026-10-18, Cameron)

The bill-scoped lines from Batch 4 were one pattern repeated across all 50 bills. They are now written from **`design/reference/bill_facets.json`** (per bill: the core provision, who gains, who is hurt, who pays, what changes locally, the risk, the critics' line and a smaller alternative; all drafts, with usage rules in its README) through hand-written frames (`tools/workbook/archive/b8/bill_frames.py`):
- **600 bill Player Cue rows** (6 styles x Support/Oppose x 50 bills) and **900 bill Opponent Cue rows** (6 styles x attack/gain/block x 50) were rewritten in place: each row picks five of seven frames in its style's voice, rotated by bill so neighbours differ, with no line over 20 words and no time words (checked on all 7,500 lines).
- **150 new hand-written Stage Questions** (three per bill, written for that bill's real provisions: the Ainu land-claims process, tradeable fishing quotas, a surveillance footage retention period, a merged town's name on the town hall, and so on) with the bill's own "{bill} debate" theme. Together with the four from Batch 4 each bill now has seven, and `bill_question_share_percent` still caps them at half a room's questions. Questions: `bill_questions.py`; builder: `bill_content.py`.
- Still drafts for Cameron to rewrite. Inverse twin bills and Japanese bill names remain unbuilt.

### The game clock (2026-10-18, Cameron) -- step 1 of 3

A quiet clock counts units of time (`GameState.time_units`, saved, zero on a new run). Finishing a stage, win or lose, adds that stage's **Time Units** (new Stages column, blank = 1, 0 allowed; `TimeClock.units_for_stage()`), so a 10-stage level is 10 units by default and a long or short stage can be set in the workbook. **The clock is never shown to the player and no player-facing text uses a time word for it** (Cameron's call): it only decides when things happen. New Balance lever **Special Level Delay** (`special_level_delay`, 5, first draft) is the countdown used by step 2. Step 2 turns the Town Hall and Steering Committee crisis triggers into Special Levels shown at the top of the level list; step 3 moves cooldowns, standing decay and optional item and modifier durations onto the clock. Tests: `tests/test_time_clock.gd`.

### Special Levels: the crisis triggers on the game clock (2026-10-18, Cameron) -- step 2 of 3

**This replaces the in-level insertion described in section 8 and the 2026-09-25 notes.** When Constituency support first falls to its Town Hall threshold, or Party support below its Steering Committee threshold, nothing is inserted any more. A countdown starts on the game clock (`GameState.special_levels`, saved) and runs for the Balance lever **Special Level Delay** (5 units, first draft). When it has run, the level appears at the **top of the level list under "Special Levels"**:
- Two new Levels rows carry a new optional **Special Trigger** column: **LV83 Constituency Town Hall** (ST05) and **LV84 Party Steering Committee Check-In** (ST22), one level per trigger (exporter-checked). They are left out of the ordinary list, can be played from the Special Levels block once due, and need no unlock or cooldown.
- **If the player plays an ordinary level instead**, the due special level is forced in right after that level: `GameState.special_forced` is set when the ordinary level ends, and the Office opens a panel ("Something needs you", one "Go in" button) that starts it (`take_forced_special()`, `OfficeScreen._show_forced_special_if_due()`). Town Hall comes first when both are due. A special level that is played, win or lose, is cleared; playing a special level does not force the other one (only an ordinary level does). Abandoning one leaves it waiting. It never expires.
- The countdown starts when the condition is first met and is not restarted while it holds; the "left the zone" latch is unchanged (a recovery cancels nothing already waiting).
- **No clock or time word is shown to the player.** The Office's crisis alert now reads "Constituency support fell to N. Your district is growing restless." / "Party support fell to N. The Steering Committee has noticed." (and "has recovered." on leaving).
- Rules in `scripts/rules/SpecialLevels.gd` (pure); tests `tests/test_special_levels.gd`, the Town Hall/Steering tests in `test_game_state_meta_tracking.gd` rewritten, and a real-click test `tests/interaction/special_levels_test.tscn` (in `verify.sh`). The playtest bot plays a forced special level and never picks one itself.

### Cooldowns and decay on the game clock (2026-10-18, Cameron) -- step 3a of 3

- **Level cooldown is measured in clock units**, not "other levels played". The Levels column is renamed "Cooldown Period (game clock units before this level is available to play again)" and every existing number was multiplied by 6 (a level averages about 6 stages), so the old pace holds: 15 other levels became 90, the one-time bill levels' 999 became 5994. `GameState.level_cleared_units` (saved) records the clock at each completion; `Ledger.level_cooldown_remaining(level, now_units, last_cleared_units)`. **The player is only told "Not available yet"** (`office.level_cooldown`), never a count. `levels_completed_count` and `level_last_completed_at` still exist (statute dates, one-time hiding, the save summary).
- **Decay runs on the clock.** It used to run once at the end of every level. Now `GameState._apply_time_decays()` runs after each stage and ticks once per **Decay Interval** units (new Balance lever `decay_interval`, 6, first draft; 0 turns it off; `last_decay_at` is saved): neglect decay, every organization's Decay Percent, and the Sanban meta values' Decay Percent, in that order. "Dealt with" for neglect decay now means the organization's standing moved (other than by decay) since the last tick (`booster_moved_in_period`, saved), not "moved this level". Pays "Each level" laws and level rewards are unchanged (still at level end).
- Tests: clock, decay interval and cooldown cases in `tests/test_time_clock.gd`; the older decay and stance tests that assumed decay at level end were corrected. Step 3b (optional Duration Units on Shop items and Modifiers) follows.

### Optional durations in clock units for items and backings (2026-10-18, Cameron) -- step 3b of 3

Two new optional workbook columns, both **Duration Units** (whole numbers of game-clock units; blank changes nothing, so every item and backing behaves as before until one is filled in; the player is never shown the number):
- **Shop tab:** an item whose stage effects (Extra Energy, Extra Guard and the like) should last N units from the moment it is used, across stages and levels, instead of one stage or one level. `Items.duration_units()`; the effects go into `GameState.timed_bonuses` ({bonuses, expires_at}, saved) and are merged into every stage's item bonuses by `take_item_bonuses_for_stage()` until they run out. Used in a stage, it applies to that battle at once and keeps running afterwards. The item pop-up says only "It starts with your next stage and wears off by itself." / "It applies now and wears off by itself." (`item.timing.timed_*`).
- **Modifiers tab:** a bought backing lapses N units after it is bought (also when an item grants it): `GameState.modifier_expires` (saved), `_expire_modifiers()` runs whenever the clock moves, the backing leaves `owned_modifiers` and can be bought again, and the Office says "{name}'s backing has lapsed." (alert `backing_lapsed`).
- Header notes written for both. Tests: `tests/test_time_durations.gd`. No existing item or backing has a duration yet; filling the cell in is Cameron's to do.

**The clock work is complete:** stage lengths (Stages "Time Units"), Special Levels on a countdown, cooldowns and decay on the clock, and optional item and backing durations.

### The listening strip keeps one set of organizations for the whole turn (2026-10-18, Cameron)

Playing a card moves the question queue on at once, so the strip showed the next question's organizations while the turn was still the same one. `BattleEngine.turn_question()` now returns the question the turn is about (the answered one, until the turn ends), and the strip reads it. `answer_effect()` returns nothing once the turn's question is answered, so a further card shows no preview. Test: `test_the_turns_question_stays_the_same_after_a_card_is_played`. `verify.sh` green.

**Everything shown follows the turn's question, not the next one (2026-10-19, Cameron).** The card-zoom question line, the Details panel's "who cares" lines, the banner announcement, the press-conference asker and the "Question N of M" caption now read `BattleEngine.turn_question()`. `BattleEngine.question_open()` is true until the turn's question is answered; after that a further card in the same turn has no question multiplier (`question_multiplier_for()` returns 1.0, which was a real bug: it graded the extra card against the next question), no "answers the question" flag, and no zoom line. Tests: the next turn picks up the next question, and a second card uses no multiplier. `verify.sh` green.

**Every card in a turn answers that turn's question (2026-10-19, Cameron).** The first card still moves the question queue on once; later cards the same turn are answered against the same question (`BattleEngine.active_question()`): each gets its Strong/Weak multiplier, tallies its pleased/annoyed/set-back organizations (`booster_tally` counts every card, the per-stage swing cap still limits the net), and shows the zoom line and listening preview. `question_open()` now means only "the queue has not moved this turn". Test: `test_every_card_in_a_turn_answers_the_same_question`.

### Card balance pass: gaffe-light Divisive, a free cantrip, a trimmed Data Driven (2026-10-19, Cameron)

From a review of the 54-card slate (the unlock system is a random draw per tier session at 250/500/1000 XP, so `xp_to_unlock` is not a per-card price and was not touched; tiers and counts were left alone so the opening-deck recipe is unchanged). Cards tab only, 13 cards, effect text updated to match:
- **Divisive** was the weakest suit once gaffes were counted (every card added gaffes). C17, C46 and C48 lose their gaffe; C45 drops to Gaffe +1 and gains Gain 1; C20 gains Gain 1. Divisive gaffe cards 9 to 6; the biggest (C47, C49) still cost 3.
- **Data Driven**, the most efficient suit, is trimmed: C42 costs 2 for Opponent -4; C44 is Gain 1 / Opponent -7. Its opponent-only cards (C13, C15) now also Gain 1 (with Opponent -2 and -4), so they are not dead in single-bar rooms (Press Conference, TV Debate).
- **Tier 1**: C07 Rousing Applause costs 0 (the first zero-cost card; the engine already floors costs at 0); C38 Call In a Favor is Gain 2 with no draw, so it no longer duplicates C07.
- **Duplicitous** guard overlap: C21 Guard 4; C50 Guard 3 with Gaffe +1 (C22 stays Guard 5).
- Rough value per energy after the pass: Divisive 1.83 to 2.28, Data Driven 2.95 to 2.83, Emotional 2.38 to 2.45, others within 0.06.
- **Not done**: room affinity (Appeal averages 1.16 across rooms, Emotional 0.89, Divisive 0.91) and a 4-cost card (most rooms give 3 energy). Both are design calls. `verify.sh` green.

### Patron Bills, step 1 of 7: schema and five seeded organizations (2026-10-19, Cameron)

Plan and Cameron's answers: `design/proposals/PATRON_BILLS_BUILD_PLAN_2026-10-19.md` (decline −5/−10, Amend swaps one component, **no party-body bills**, **no patron bill may pass without the player's influence**, every number editable in the workbook). Built so far, **schema only; nothing in the game reads any of it yet**:
- **Four new optional tabs** (`data/bill_components.json`, `patron_bills.json`, `bill_level_templates.json`, `party_values.json`): Bill Components (Owner, Slot X/Y/Z, Phrase, Value Tags, Hearing Committee, Gains, Loses, Excludes, Amend Options), Patron Bills (Kind Favor/Flagship, Components, Ally, Template ID, five lines), Bill Level Templates (stage tokens), Party Values (the 34-dimension table in long form). A **Component ID** column on Stage Questions, Player Cues, Opponent Cues and Transition Dialogue, with header notes (the new tabs have none: a new tab has no notes part).
- **16 Balance levers** (`patron_favor_threshold` 50, `patron_flagship_threshold` 70, decline costs 5 and 10, amend 75%, pass and fail standing, `patron_default_margin` 6, `custom_law_scale_percent` 50 and so on).
- **Exporter checks** (`export_data.py`): owner is a non-party organization; slots; Value Tag dimensions and weights; hearing stage exists; gains/loses signs; a Favor bill uses two of the owner's components and a Flagship the owner's two plus the ally's; one Favor and one Flagship per organization; template kind; content naming a real component. Confirmed with deliberately broken rows (eight errors raised), then restored. A Stage Questions row may now name a Component ID instead of a Stage or Bill ID.
- **Seeded**: Chamber of Commerce (BO05), Fisheries Cooperative (BO07), Agricultural Cooperatives (BO10), Financial Industry Association (BO24), Rural Revitalization Council (BO30): 15 components and 10 patron bills (drafts, lines templated). IDs: `CB` + organization number + slot (CB071), `PB` + organization number + 1 or 2 (PB072).
- Prototype (`tools/workbook/archive/b9/patron_plan.py`): with the abstain cap (default Yes held to 51 − margin), 0 of 56 bills pass by default. Step 2 must prove a full-strength player can flip each with the real vote engine.
- Content rows tagged with a Component ID must not be added until step 3, because nothing yet keeps them out of the general pools. `verify.sh` green.

**Patron Bills draft revised (2026-10-19, Cameron):** Members of Parliament (BO17) gets no bills (27 organizations, 54 bills, 81 components; the draft in `tools/workbook/archive/b9/patron_plan.py` still shows 0 of 54 passing by default). Small Business Owners' (BO25) ally is now the Yezo Artisans Guild (BO13), and their Flagship no longer cuts the corporate tax rate. The two Ainu groups now push different things so both bills compound: Council (BO28) harvest rights, community centers, land-use consultation; Foundation (BO29) translation of public documents, schools, broadcasting. Nothing seeded in the workbook changed (BO05, BO07, BO10, BO24, BO30 only). Open: own-slot and ally components still repeat across bills; the plan's section 10b lists it.

### Patron Bills, step 2 of 7: the rules (2026-10-19, Cameron)

Pure rules, no UI, nothing yet shown to the player. `DataDB` now loads the four patron tabs (`bill_components`, `patron_bills`, `bill_level_templates`, `party_values`).
- **`BillPositions`**: the lean model ported from `archive/b2/model.py` (tags x party salience; a lean of `bill_position_lean_threshold` (30, new Balance lever) or more takes a side), plus the patron **abstain cap** (Yes above 51 minus `patron_default_margin` becomes Abstain, weakest lean first). Checked against the Python model's own totals (45-30-26 and 45-39-17 at cap 45).
- **`ComposedBill`**: components to a floor_votes-shaped bill (name from the Text-tab templates, merged value tags, positions, merged effects scaled by `custom_law_scale_percent`). **Repeats (option A, my default, Cameron's to change):** a component already law is swapped for the same owner's next unused one; with nothing to swap in the request is not offered.
- **`PatronRequests`**: who is due (Favor 50, Flagship 70, a Flagship waits until that organization's Favor is resolved, a failed Favor lowers it by 5), room for requests (2 at once), decline costs, Amend options (Favor: the owner's third component; Flagship: another of the ally's), and the vote's standing changes (patron, ally, rivals; amended rewards x0.75; a passed Flagship gives free backing for 30 units). New lever `patron_rival_fail_standing` (1).
- **`LevelTemplate`**: template tokens to real rooms (meeting ST20, the lead component's hearing, public room ST05 for a Constituency organization or ST04 for a National one, caucus ST03, vote ST23).
- **Proof with the real vote engine** (`tests/test_patron_rules.gd`, 14 tests): every patron bill fails when the player cannot swing parties, and every one can be carried by a full-strength player for all four protagonists. This found that margin 6 left PB051 and PB241 at 49 of 51, so **`patron_default_margin` is now 3**. GUT 1268, `export_data.py` clean.

### Patron Bills: Option A coverage and the full component library (2026-10-19, Cameron)

Cameron asked whether Option A has enough swaps for every patron bill to arise and every variation to be amendable. **It did not** (with 3 components per organization no Flagship could follow its Favor). Fixed by building the alternatives:
- **Slots and pools** (exporter-enforced): Favor pool X, Y, V (a Favor uses X, Y; V is the Amend spare), Flagship own Z, W, and ally **offers** A-D (an ally needs one per Flagship naming it plus one spare). Swaps stay inside a pool (`ComposedBill.POOLS`, `pool_members()`). The Flagship is now Z + W + one ally offer (it no longer reuses the Favor's X). The exporter's "Option A coverage" block fails the export if a pool is too small.
- **The library:** 180 components for 27 organizations (135 own + 45 offers) and the 54 patron bills, all in the workbook (`tools/workbook/archive/b9/step2b_library.py`; Bill Components and Patron Bills tabs regenerated with `wbx.replace_sheet_data`). All drafts, Cameron's to correct; offers are things an organization would lend an ally.
- **Vote shaping so every variation is carryable:** new levers `patron_default_yes_floor` (44) and the cap now takes seats from the parties whose seats influence can win back (`BillPositions.cap_yes_recoverably`, `ComposedBill.swing_capacity()` from each party's Vote Resistance). One component retagged (CB059).
- **Proof** (`tests/test_patron_rules.gd`, 16 tests): 300 random acceptance and amend orders, all 54 bills arise and every component has an Amend alternative; all 157 variations fail without influence and can be carried by every protagonist's party. Step 3 (runtime level) is not started.

**Flagship floor lowered (2026-10-19, Cameron):** new lever `patron_flagship_default_yes_floor` (34; `PatronRequests.default_yes_floor(kind, balance)`), so a Flagship starts with fewer default Yes votes than a Favor (floor 44) and needs more swing from the player's influence. 34 is the lowest value at which every Flagship and every Amend variation is still carryable by a full-strength player (tests/test_patron_rules.gd uses the per-kind floor). Default Yes now ranges 44-48 for Favors and 34-48 for Flagships. Retagged to keep it attainable: CB233, CB234 (Taxpayers' Alliance Flagship) and CB056, CB059 (Chamber of Commerce offers).

### Patron Bills, step 3 of 7: the runtime level (2026-10-19, Cameron)

Accepting a patron bill now builds a real, playable level for the run. Nothing is shown in the Office yet (step 4); everything is driven through `GameState` and proven headless.
- **Runtime registry (`DataDB`)**: `register_runtime_bill()` files a composed bill in `floor_votes` (so every bill lookup finds it), `register_runtime_level()` keeps its level apart from `levels.json` (never in the Levels list), `component_ids_of()`/`content_keys()` map a bill to its components, `clear_runtime()` forgets them (new run, load, test cleanup). `BattleSetup._is_bill_id()` accepts a registered patron bill id as a level's vote slot.
- **`PatronLevel` (`scripts/PatronLevel.gd`)**: `compose()` (Option A swaps for components already law, optional Amend swap checked against `PatronRequests.amend_options`, `stakeholders_override` built from the merged effects so the Level Intro lean works), `level_row()` (template stages, last slot the bill), `register()`. Bill ids `PBxx`; level id `PL_PBxx`. Two new Text rows `custom_bill.name_2/3`.
- **Content by component**: rows with a **Component ID** (Stage Questions, Player Cues, Opponent Cues, Transition Dialogue) are filed like bill-scoped rows, never in a room's general pool, and found by the composed bill's own id. A composed bill pools its components' lines and deals questions round-robin across components, so any prefix is an even mix; the existing 50% bill-question share still applies. `StageTransition.scope_dialogue()` takes the level's component ids. **No component-tagged content rows exist yet** (steps 5 and 6).
- **`GameState`**: `patron_requests` ({id: status, components, amended, tries}), `enacted_components`, `patron_runtime` (level in progress) and `patron_composed` (saved so the statute book names a bill after reload); `patron_bills_due()`, `start_patron_level(id, replace, with)`, `decline_patron_bill(id)`. The vote (`record_floor_vote()` -> `_resolve_patron_vote()`) moves the patron, the ally and the organizations the bill hurts (`PatronRequests.outcome`, Amend rewards x0.75), applies the components' own scaled effects, makes a passed bill's components law, and gives a passed Flagship's patron backing free for `patron_free_backing_units` through the timed-backing machinery. A level that ends before the vote returns the request once (WAITING) and lapses it the second time (-`patron_fail_standing`); abandoning leaves it OPEN. A patron level is not an ordinary level: no cooldown, no `levels_cleared`, no completion count.
- **Save/resume**: the four fields are in `_SAVED_FIELDS`; `load_save()` re-files every composed bill and the level in progress.
- **Proof**: `tests/test_patron_level.gd` (17 tests): the level builds and is not in the list, accept/second-level refusal, content by component, pass/fail/Flagship/Option A/Amend/decline/lose-twice/abandon, save and resume mid-level, the statute book after reload, a new run forgets it, and **all 54 patron bills build a level with no problems, opponents in every Combat stage and a valid vote**. GUT 1287.

### Influence building, step A: `BillAssist`, the vote hook and the news ticker (2026-10-19, Cameron)

Cameron's notes on the two pinned ideas are in `design/proposals/INFLUENCE_BUILDING_IDEATION_2026-10-19.md` ("Decisions"). Shared rules, built first:
- **`BillAssist`** (pure): `{won_over: {party: seats}, worked_against: {party: seats}}`. **`FloorVoteEngine`** takes it as `config["assist"]`: **won over** seats go to the player's pick **before** the influence swing, one seat at a time from the party's larger bucket outside the pick, **ignoring the gate and Vote Resistance** (a guaranteed +1 even for Five Point Independents, whose resistance leaves the swing 0 seats); **worked against** seats leave the pick for its opposite **after** the swing (Yes and No swap; an Abstain pick loses them to No), so influence cannot win them back. Both count as influence for `outcome_flipped_by_influence`, and `preview()` includes them.
- **`GameState`**: `bill_assist` (saved; reset at level start, end and abandon; spent when the patron vote resolves), `add_won_over()`/`add_worked_against()`, `patron_news` (story -> clock units it runs until, `news_ticker_units` 12), `record_news()`, `active_news()`, `ticker_facts()` (laws plus `news:<key>`).
- **News on the Office ticker**: new Office Ticker/Notices condition type **`news`** (target `visit_success` or `lobbyist_work`, checked by the exporter); `GameState._resolve_patron_vote()` records a story when the assist had any won-over or worked-against seats. Rows TK148 and TK149 carry Cameron's two lines (with `{player}`). The Floor Vote screen shows "Members you won over: +N" / "Lobbyists working against you: -N" under the bill.
- Tests: `tests/test_bill_assist.gd` (12). The visit and the trade themselves (steps B and C) are not built yet.

### Influence building, step B: the member visit (2026-10-19, Cameron)

An optional visit for **patron Flagship** levels (not existing bills; Cameron pinned a different form of the idea for those). Notes applied: a visit is offered for the first listed party that still has seats outside the player's side (so it guarantees a seat unless the party is maxed out), one seat per member won, a lost fight costs only the stage, the visit is skippable, a Policy Research Assistant at **staff rank 2 or higher** (`mp_visit_briefing_staff_rank`; ranks stored 0-2 today, so only the top rank) briefs the player in natural speech on the member's preferred styles, none or lower means no briefing, and a success becomes the Office ticker story from step A.
- **Rules (`MpVisit`, pure)**: `pick_party`, `pick_member` (a party member on the bill's hearing committee first, leaning toward people not yet met), `grade` (Strong for the member's `suit_1/2`, Medium for `suit_3`, Weak otherwise), `choose_styles` (four distinct styles, at least one the member favors), `build_questions`, `briefing_available`, `start_bonus`.
- **Flow**: `MP_VISIT` is a new Bill Level Templates token (Stage 6-8 and a **Visit Parties** column added; BT02 lists `PT04; PT02`) that becomes two stages when a visit is offered: **ST260 Member Visit** (new mode `Visit`, `VisitScreen`: offer with Skip, the researcher's briefing, three style-answered questions, rapport -3 to +3) and **ST261 Win Over a Member** (an ordinary one-on-one Combat stage against that member; rapport changes the player's starting support by `mp_visit_rapport_start_per_point` x rapport, 5 by default, through `start_adjustment`). Winning the fight calls `GameState._won_over_member()`: a `BillAssist` won-over seat for that party (`mp_visit_seats_won`). Skipping (`GameState.skip_member_visit()`) passes both stages with no rewards, no time and no fight. The member, party and questions are drawn when the level is built (`PatronLevel.build_visit`) and saved with it.
- **Workbook**: stages ST260/ST261 (with Affinity columns), **Visit Questions** (24 member questions with `{component}`) and **Visit Answers** (36 lines, 6 per style) tabs, 26 `visit.*` Text rows, 7 `MP Visit:` Balance levers. All drafts, Cameron's to rewrite.
- **Proof**: `tests/test_mp_visit.gd` (14) and the real-click `tests/interaction/visit_test.tscn` (in `verify.sh`): offer, briefing, three questions, rapport, the fight against the visiting member, and a skipped visit with no researcher. `StageRouting` routes mode `Visit`; `LevelRunner.problems()` checks a visit has a member.

### Influence building, step C: the lobbyist trade (2026-10-19, Cameron)

An optional stage for **patron bills** (Favor and Flagship). Cameron's notes applied: leverage is a **budget** the player spends; refusing the lobbyist is **free on a Favor**, and on a **Flagship refusing costs 2 seats and meeting without an agreement costs 1** (BillAssist `worked_against`; levers `Trade: Favor/Flagship Refuse/No Deal Seats`, so Favor can be changed); any component but the last may be dropped; "help working the bill" is **one seat**; and both outcomes reach the Office ticker through the step A stories (`lobbyist_work` after a refusal or failed meeting).
- **Rules (`LobbyistTrade`, pure)**: `pick_lobbyist` (the most hurt organization the bill's merged effects name that is not the patron or ally and has a representative: any non-MP opponent with an affiliation who is not a journalist or constituent), `asked_component` (the component whose `loses` hurts that organization most), `starting_leverage` (25% of your standing with the organization + 20 if you drop the asked component, 5 otherwise), `after_answer` (Strong +15, Medium +5, Weak -10, graded against the lobbyist's own styles by `MpVisit`), the reward costs (donation 20, goodwill 30, party favor 40, help 50), `can_close`, `seats_lost`, `party_for_org`/`party_for_help` (the party best tied to the organization in Party Standing that has seats to lose or win), `drop_costs` (-3 to the patron, -1 to the ally for a component of theirs).
- **Flow**: `LOBBYIST_TRADE` is a new template token (BT01 and BT02 list it just before the vote) that becomes **ST262 Lobbyist Trade** (mode `Trade`, `TradeScreen`: offer, pick a component, three style-answered rounds moving a leverage bar, the reward menu, Make the deal or Walk away). `GameState.conclude_trade_deal()` recomposes the bill without the component (`PatronLevel.compose_ids`, a one-component bill reads "A bill to {a}" from `custom_bill.name_1`), updates the registry, the saved bill, the request's components and the **vote stage's bill**, charges the drop costs and pays the rewards (Funds and XP, organization standing, a party's favor, a won-over seat). `conclude_trade_without_deal(refused)` applies the seat cost.
- **The bill stays winnable**: only components whose removal leaves a bill a full-strength player can still carry (and that cannot pass alone) are offered (`PatronLevel.safe_drops()`/`carryable()`); a bill with none gets no trade. 26 of 54 bills hurt an organization that has a representative, so about half carry a trade today; casting more representatives in the Opponents tab (non-MP, with an affiliation) widens it. Cameron's to cast.
- **Workbook**: ST262 (+ Affinity), **Trade Questions** tab (12 stems, answers reuse Visit Answers), 41 `trade.*` and `custom_bill.name_1` Text rows, 21 `Trade:` Balance levers. All drafts.
- **Proof**: `tests/test_lobbyist_trade.gd` (19) and the real-click `tests/interaction/trade_test.tscn` (in `verify.sh`).

### Influence building, step D: the bot, balance and a small fix (2026-10-19, Cameron)

`tools/playtest_optimal.gd` now accepts due patron requests after each Office visit, plays patron levels, takes member visits (best-graded answers), runs lobbyist trades (drops the asked component, buys help first), and votes Yes with the full influence config and assist; `PLAYTEST_PATRON=0` turns it off. A PC01 run (50 patron levels, no invariant bugs): 17 visits, 15 trades, 27 help seats; **2 bills passed, 33 failed, 15 lost before the vote**. That is the design working: a bot with Reputation about 26 never opens the influence gate (the bill carries only with the player's influence), and it lost all 17 visit fights. So patron bills are hard for an average run and need a strong player; whether visits (rapport, start bonus) should be easier is Cameron's to tune (`MP Visit:` levers). Fixed a warning: `_follow_links` looked up a Sanban name (Reputation, Funds) as an organization.

### Patron Bills, step 4 of 7: the Requests block and Request panel (2026-10-19, Cameron)

The Levels panel opens with a **Requests** block: an organization's Favor or Flagship request appears once its standing reaches the threshold and the game-clock countdown (`special_level_delay`) has run (`GameState.arm_patron_requests()`/`patron_requests_shown()`, `patron_armed` saved; at most `patron_requests_waiting_at_once` show). Tapping one opens the **Request panel** (`OfficeScreen._open_request()`, lines from `RequestLines.gd`): the bill, its parts, the default vote and Aye votes needed, your own party's position, the rewards, and **Carry this bill** (starts the patron level at the Level Intro; the lean is auto-set to Support for a `PB` bill), **Swap one part** (Amend, previewed with a way back) and **Decline** (costs standing). **Your Record** gets a "Bills you carried" list with the patron bill's pass/fail line. 23 new Text rows (`request.*`, `record.carried_*`). Not built: an outcome pop-up after the vote. Tests: three in `test_patron_level.gd` and the real-click `tests/interaction/requests_test.tscn` (in `verify.sh`); `trade_driver.gd` was flaky (random lobbyist styles left too little leverage) and now zeroes the donation price.

### Patron content (steps 5-6), headings, and a balance evaluation (2026-10-19, Cameron)

- **Levels list headings:** "Sponsored Bills" (patron requests) sits at the top of the Levels panel; the Special Levels block is now "Urgent Matters".
- **Component content (steps 5-6):** all 180 components carry drafts: 1,440 questions (with 180 Question Themes rows), 1,080 player cue rows, 1,080 opponent cue rows, 360 staff transition lines and 180 player thoughts (`tools/workbook/archive/b11/`). Rows tagged with a Component ID are filed apart from room pools and reach only a composed bill. `tests/test_component_content.gd` guards them (limit 25 words per line; no clock words). Four older tests learned to skip component rows. Not built: a post-vote outcome pop-up, patron step 7, visitors in patron meetings (the meeting room is a Lobbyist Meeting, ST20).
- **Balance evaluation:** `design/proposals/TIER_BALANCE_2026-10-19.md`. Bot stage trials (PC01, PC04, 20 fights): 19 of 21 rooms 100%; ST08 now 100% (was 0% before it asked questions), Media Ambush 0-15% (left alone), Lobbyist Meeting 85-95%. No content number changed. Finding for Cameron: **bill levels do not pay more in higher tiers** (300 / 291 / 278 XP) while their unlock cost rises 50 / 100 / 200; the proposal suggests per-tier bonuses and eight re-sorts. Nothing applied.

### The sponsored-bill vote result, and an ST261 trial (2026-10-19, Cameron)

- **Request panel check:** the Sponsored Bills block and the Request panel were looked at in real 1080x2340 screenshots; no layout problem found.
- **Vote result pop-up:** after a sponsored bill's vote the Floor Vote result lists "The bill you carried:", each organization's standing change, any free backing ("You may call on {org}'s backing at no cost.") and what is now law (`GameState.last_patron_outcome`, set in `_resolve_patron_vote()`, never saved; `RequestLines.outcome_lines()`). Four Text rows (`request.outcome_*`). Test in `test_patron_level.gd`.
- **ST261 trial:** `PLAYTEST_STAGE_TRIAL="ST261:30"` now builds a real Flagship level (PB052) and fights the member at every rapport from -3 to +3 (`_run_visit_trial()`; `PLAYTEST_TRIAL_KIT=starter` uses the opening deck). Result: the visit fight is **won 96-100% at every rapport, even -3 with the opening deck**, so rapport barely matters and the fight is easy as tuned (threshold 49, player starts 20, opponent 40, 10 turns, 3 energy). Not changed; the numbers are Cameron's.

### Review leftovers closed (2026-10-19, Cameron)

From `design/REVIEW_2026-10-14.md`: **R5** a fresh committee bout clears the turn's card, item and question counts (so a pass against the next opponent is a pass); **R6** an attack value is never below 0 (a bad row cannot become free guard); **R7** `BarModel.player_gains()` clears `last_gain` even for a move of nothing; **R8** the player's own seat is only moved out of a bucket that has someone in it; **R10** new pure `SafeNum.to_int()` (null-safe whole numbers) used by `IntentRunner`, `VoteInfluence` and `PartyOpinion`. **Not changed, on purpose:** R11 (`pending_trigger_alerts` are deliberately unsaved news, as their own comment says); U6 (small fonts at Text size Small: raising the base sizes is a layout and design decision for Cameron); U9. Tests: `test_safe_num.gd`, new cases in `test_battle_engine.gd` and `test_bar_model.gd`; GUT 1348.

### Patron Visit: sponsored-bill levels open with the organization's representative (2026-10-19, Cameron)

Cameron chose option A. A sponsored bill's level no longer opens with a Lobbyist Meeting (ST20): it opens with **ST263 Patron Visit** (Non-combat, Office Hours format), where a "{organization} Representative" (no invented person) asks **two dilemma questions** about the bill's first two components ("We are counting on you to {phrase}. Will you stand with us?"). `PatronVisit.build()` (pure) makes them when the level is created and `PatronLevel.level_row()` keeps them with the level (`level["patron_visit"]`, saved with the level); `BattleSetup` hands them to the stage. Four choices (carry it, carry it with changes, not this time, refuse) move the patron's standing +4/+2/-2/-4, the component's first friend organization +1 on the first choice and its first rival -2/+1/+2 on the first three; nothing else. Workbook: stage ST263 (and Affinity column, time units 0), Bill Level Templates stage 1 now `PATRON_VISIT` (the old `PATRON_MEETING` token still works), 15 `patron_visit.*` Text rows. All drafts. Tests: `tests/test_patron_visit.gd`; older template tests now expect ST263.

### Draft a Bill: the player's own bill (patron step 7, 2026-10-19, Cameron)

A **Draft a Bill** button heads the Levels list. The player picks **two or three parts (components) from any organizations** (an organization list, ordered by standing, then that organization's parts), sees the bill's name, the default vote, their party's position and who it helps or hurts, and taps **Draft this bill**. It plays on the sponsored-bill machinery: `DraftBill.row_for()` files a runtime patron row (`patron_drafts`, id `PD01`..., no organization, no ally, `draft: true`; Favor-like for two parts with template BT03, Flagship-like for three with BT04), and `GameState.start_draft()` pays and starts the level (hearing for the first part, optional member visit and lobbyist trade as for any sponsored bill, the vote). **Cameron's numbers (Balance levers, drafts):** 350 XP, 300,000円 (`draft_bill_cost_funds`) and a cooldown of 30 clock units (`draft_bill_cooldown_units`); one drafted bill at a time. Rules in `DraftBill.refusal()`: two or three parts, none already law, no conflicting parts, cost, cooldown, not mid-level, and **winnable** (`PatronLevel.carryable()`: it fails on its own and a full-strength player can carry it). Of 200 random mixes of two and 200 of three, 198 and 199 pass that test, so nearly every mix is allowed. A drafted bill has no patron: the vote moves only the organizations its parts help or hurt (`PatronRequests.outcome()` skips an empty organization); a draft that never reaches its vote lapses with no refund and no penalty; Level Intro leans Support automatically. New fields saved: `patron_drafts`, `draft_counter`, `last_draft_at`. 24 `draft.*` Text rows, three Balance levers, templates BT03 and BT04. Tests: `tests/test_draft_bill.gd` (7), real-click `tests/interaction/draft_test.tscn` (in `verify.sh`).

### Organization chips, patron tab notes, component supply (2026-10-20, Cameron)

- **OrgChip** (`scripts/ui/OrgChip.gd`): an organization's (or audience group's) standing change drawn as its icon with a green, red or grey fade and the signed number in the fade; tapping the icon opens a name overlay (`OrgNameOverlay`). A preview wears a white outline. Used on the battle Outcome panel (the bill-stance drift is now folded into those numbers instead of a sentence), the sponsored-bill vote result, the Request and Draft panels, visitor answers (`GameState.last_visitor_effects`), law pop-ups, shop item results (`result["effects"]`), the Floor Vote stance preview/result, the level briefing ("For it / Against it" rows, `OrgChip.side_row`: green/red, no numbers), the Level Intro stance and the battle Details panel (stance sides, pleased and annoyed so far). Sanban values (Funds, XP, ...) stay as text lines. Shrine Association (BO20) and Our Traditional Society (BO15) swapped icons.
- **Patron requests that can never be offered are closed** (`GameState.arm_patron_requests()`): a due request whose every alternative component is already law becomes `lapsed` with no standing cost, so the same organization's Flagship (which waits for its Favor to be resolved) is no longer held up. Analysis of when components run out: `design/proposals/PATRON_COMPONENT_SUPPLY_2026-10-20.md` (only Draft a Bill can run them out; one drafted Z or W part shuts an organization's Flagship).
- **Header notes on the four patron tabs** (Bill Components, Patron Bills, Bill Level Templates, Party Values): `tools/workbook/add_notes_new_tabs.py` builds the comments/VML parts a brand-new tab lacks. Bill Components' Each Level Effect and Amend Options columns are reserved (not read).
- `design/proposals/PATRON_BILLS_BUILD_PLAN_2026-10-19.md` now records steps 1 to 7 as built.

### Bill player cues: fifteen lines per style and lean, leans read differently (2026-10-20, Cameron)

In a bill level the card cue pool for each style and lean grew from 5 to **15 lines** (1,200 new Player Cues rows, two per bill, style and lean, `tools/workbook/archive/b12/`), and the 101 lines that read identically under Support and Oppose were rewritten (203 cells). Support and Oppose now share no line in any style except **Duplicitous**, whose ambiguity is deliberate (three frames read either way). Rows with the same bill, style and lean merge into one pool, so more lines are just more rows. A line is at most 20 words, with no repeats in a pool and no clock words. `tests/test_bill_player_cues.gd` guards all 50 bills. Drafts for Cameron to rewrite.

### Repo cleanup (2026-10-20, Cameron)

`CLAUDE.md` went from 350 KB to about 73 KB: the dated build notes moved here, and its section 14 (working notes) and 15 (change log index) were added. 22 unused Text-tab rows were removed (the eight `office.trigger.*` rows look unused to the exporter but are read through a built-up key in `OfficeScreen`, so they stay). Five unused functions were removed (`StanceLines.names_of`, `RequestLines.parts_line`, `Audio.set_volume`, `Audio.set_muted`, `GameState.buy_card`; `Ledger.card_refusal` stays, it is tested). `design/Game_Workbook.backup.xlsx` and `design/CoP_Cards.xlsx` were deleted (git history has them); the 60 MB of raw balance-audit logs became `design/bench/balance_logs_2026-10.tar.gz`; the three adopted batch workbooks moved to `design/archive/`. Two tests that left orphan nodes now wait for queued frees (`test_battle_events.gd`, `test_hand_presenter.gd`), and four float/int comparisons in `test_real_battle.gd` were made explicit.

### Level Intro: a larger speaker portrait (2026-10-20, Cameron)

The speaker on the Level Intro screen was a fixed 260 x 380 box. The portrait now fills the free height (stretch ratio 3 against one each for the spacers above and below), so at 1080 x 2340 the character is about three times larger and the name card sits just under the feet, above "Let's go". `scenes/office_hours/LevelIntroScreen.tscn` and `tools/build_level_intro_scene.gd` carry the same setting. The cue banner still crosses the middle of the screen while a line is showing, as it does everywhere else.

### How to Play revised for the current mechanics (2026-10-21, Cameron)

Every guide entry is now at most three sentences (`test_every_guide_entry_is_at_most_three_sentences`). Updated: HT01 (levels about bills), HT06 (threshold wording), HT12 (every card in a turn answers that turn's question; the organization preview), HT13 (urgent levels and the forced Town Hall / Steering Committee check-in), HT14 (standing, neglect, Boosters, sponsored bills), HT15 (training coupon), HT16 (staff ranks, pressure supplies), HT17 (Aye/Nay, the whole-house majority, Your Record), HT18 (the backup slot) and the three long card entries HT19 to HT21 (shortened). New group **Bills and Parties**: HT22 taking a side on a bill, HT23 sponsored bills, HT24 drafting and winning votes (member visit, lobbyist trade), HT25 how the parties see you. No clock or time terms appear in the guide.

### Concise stage information text (2026-10-21, Cameron)

The battle Details panel used to open with about 110 words of room rules, mostly the same in every stage. Now: **one row of key numbers** ("Turns 7 · Gaffes 5 = loss"; Energy and Hand are printed only when the room differs from the standard, set by Balance levers **Brief: Standard Energy** (3) and **Brief: Standard Hand** (5)) and **one winning line** that also says what starts over between opponents (about 28 words for a committee). Everything else is behind a **Room rules** toggle in the panel: the question count and what skipping one costs, the interest-cooling line, deck / hand / discard counts and the room's audience mix. Removed from the panel: the Guard paragraph and the voter-cost paragraph (both now in How to Play: HT11 and the new HT26), the "3 of them, one at a time" line (the header caption says it), the "Stage:" line, and the rules.json default-pattern note (shown only in debug builds). The level briefing's two carry-over lines became one: "Everything starts over between opponents." for a committee, otherwise "Starts over between opponents: support, ...". `StageBrief` now has `headline()` and `details()` (`how_this_room_works()` joins them); `CarryOverLines.for_stage()` returns the single line. 28 Text rows replaced, 16 added; tests in `tests/test_text.gd`.

### Room rules notes, the audience mix adds to 100, card effect ideation (2026-10-21, Cameron)

`StageBrief.details()` now adds a line when a room treats a loss differently ("Losing this stage costs you, but the level carries on.", from `loss_ends_level`), so a non-standard room says so behind the Room rules toggle. The audience mix in Room rules uses the new pure `RoomMix.entries()`: whole percentages in segments order plus **Other** (the workbook's `pct_other`, or whatever the named groups leave), rounded by largest remainder so the total is always exactly 100 (`tests/test_room_mix.gd` checks every real combat stage). New Text row `battle.room_mix_other`. Ideation for card effects (audience scaling, discard to draw, discard to play) is in `design/proposals/CARD_EFFECTS_IDEATION_2026-10-21.md`; nothing in it is built.

### Discard cards and the 20% audience scale (2026-10-21, Cameron)

Plan: `design/proposals/DISCARD_CARDS_PLAN_2026-10-21.md` (approved).
- **Two new Cards columns:** `Discard To Play` (other cards you discard to play the card: Tier 1 = 2, Tier 2 = 1) and `Discard For Draw` (1: discard a card of your choice, then draw the Draw column's cards: Tier 1 draws 1, Tier 2 draws 1 or 2). Only Duplicitous, Divisive, Emotional and Data Driven; no Tier 0 or 3; `export_data.py` rejects anything else. Header notes written.
- **16 new cards, C55-C70** (one per mechanic, tier and suit): cyclers Trim the Appendix / Review the Record (Data Driven), Burn the Draft / Cut Your Losses (Divisive), Let It Go / A Fresh Start (Emotional), Shuffle the Papers / Lose the Evidence (Duplicitous); discard-to-play Compile the Dossier / The Full Audit, Burn the Bridge / No Quarter, Give Everything / Words From the Soul, The Quiet Deal / Back-Room Bargain. Names, Japanese names, numbers and five spoken lines each (Flavor Text) are drafts. The opening-deck recipe is unchanged.
- **Engine:** `BattleEngine.play_card(card_id, discard_ids)` validates the chosen discards (from the rest of the hand, exactly the number needed), pays the energy, discards them, then resolves. `discard_required()`, `play_block()` ("no_refill" in a room whose hand is not refilled, "few_cards" when the hand is too small) and `preview()["needs_discard"/"play_block"]`. Blocked cards grey out and the zoom says why.
- **UI:** playing such a card (zoom Play, or dragging it up) opens a **pick step**: a bar above the hand ("Choose 2 other cards to discard. 1 of 2 chosen.", Discard and play, Cancel); tap cards to mark them with a "Discard" tag. End turn cancels it. `tests/interaction/discard_test.tscn` (in `verify.sh`) clicks the whole thing.
- **Audience scale:** new special key `scale_per_20_target_segment`: +`special_value` per 20% of the target audience, never more than +5 or less than -5 (`SpecialEffects.MAX_SCALE_BONUS`). Applied to C10 and C28 (Constituents), C24 (Boosters) and C52 (Bureaucrats), which used the 50% switch that fires in few rooms.
- **Bots** (`playtest_optimal`, benchmark, stress) do not play discard cards. Not yet balance-tested with bot trials: the numbers are drafts. Tests: `tests/test_discard_cards.gd`; How to Play HT19 and new HT27.

### Whip the vote (2026-10-22, Cameron)

Plan: `design/proposals/PARTY_CAPITAL_IDEATION_2026-10-22.md` (option 2). On the Floor Vote screen of any bill the player can spend **stored Party support** to whip extra members of their own party to their pick. **Base cost 10 per extra vote; 3x (30) when the pick goes against the party's position on the bill** (Supportive party: anything but Aye; Opposed party: anything but Nay; a Neutral party has no position to go against). New Balance levers: `Whip: Base Cost` 10, `Whip: Against Party Multiplier` 3, `Whip: Max Per Vote` 3, `Whip: Party Support Floor` 30 (drafts for the last two): stored Party support may never be spent below the floor, so a whip cannot push the player into the party crisis. Pure arithmetic in `VoteWhip`; `FloorVoteEngine.set_whips()`, `whip_capacity()` (the party's seats outside the pick), `own_disposition()` and `whips_applied()` (whipped seats move before the influence swing, like won-over seats, and count as influence for the flip cue); `GameState.spend_party_support()` records "whipping the vote on {bill}" in Your Record. UI: a "Whip the vote" row with Whip fewer / Whip more, the preview lines add the whip cost, and each vote button names its price (greyed when unaffordable); the result says how many were whipped and what it cost. The vote buttons now wrap their text so a long price line cannot widen the screen. Tests: `tests/test_vote_whip.gd`, `tests/interaction/whip_test.tscn` (real clicks, in `verify.sh`); How to Play HT28. Not built: the other opportunities in the ideation (Level Intro boosts, a whip button in battle, a party-whip visitor, a backing, a shop item).

## Organization value pass: bigger backings, second backings, newer organizations' level rewards (2026-10-23, Cameron)

An analysis of what each organization is worth found the Yen and XP win payouts were 0.5 to 3% of a level's income (about 195,000 Yen and 460 XP per won level), and eight organizations' backings reached 9% of levels or fewer. All workbook values, no new mechanics.

| Change | Detail |
|---|---|
| Payouts raised | M20 2,500 to 20,000 Yen; M38 3,000 to 25,000; M15 2,000 to 15,000; M05 1,000 to 8,000; M28 1,500 to 12,000; M06 15 to 45 XP; M43 10 to 30 XP. M20 and M38 cost 5 more Reputation to activate. |
| Start bonuses raised | M22, M37, M42, M36, M30 from +10 to +15; M29 from +5 to +10. |
| Eight second backings (M49 to M56) | Draft names and values, each a win payout: BO07 +1 Constituency support, BO23 +12,000 Yen, BO30 +1, BO06 +1, BO14 +1, BO22 +25 XP, BO15 +1 Party support, BO28 +20 XP. Linked in the Boosters tab. |
| Levels tab: Win ΔBO17 to Win ΔBO32 | Sixteen new columns in the same range format as Win ΔBO01 to BO16 (columns AP to BE). The engine already read any `win_delta_boNN` column; the exporter's column list and check now cover all 32 organizations. 22 bill levels carry draft 0-1 values for the organizations their bill favors. |

Not built (not approved): the vote-whip discount for ungated organizations, and the tiered standing needed to buy a backing. Test: `test_game_state_level_bonus.gd` covers the new columns on real levels.

## The week calendar: hours, a work week, an optional weekend (2026-10-23, Cameron) -- steps 1 and 2

The quiet game clock became a player-facing calendar. Hours, not units: **Stages Time Units are now hours** (2 for Lobbyist Meeting, Town Hall, Office Hours, Press Conference, Policy Study, Check-In and the member/patron rooms; 4 for committees, Party Caucus, Party Steering Committee and Floor Debate; 3 for TV Debate; 1 for a Floor Vote and Media Ambush). `WeekCalendar.gd` (pure) holds the rules; `GameState.calendar` is `{ week, phase, hours }`, saved.

| Rule | Detail |
|---|---|
| Work week | Five 8-hour days pooled into 40 hours. A stage that runs past a day spills into the next. Hours past the pool are lost; the week does not cross over. |
| Friday | When Friday has hours left, "End the Work Week" asks first (it names the hours left). No bonus or penalty. |
| Weekend | Optional. Two 4-hour days. Only levels flagged **Weekend OK** (new Levels column; LV83 and LV84 for now) that fit in the hours left can be started. |
| Going home | "Pay Party Dues and Go Home" (weekend, or the choice when the work week is full) starts the next Monday with a popup on the Office. Unused hours still count as time passing, so cooldowns keep running. Dues come in step 3. |
| Calendar square | Gold-edged (the cue banner's gold), lower left of the Office: DD.MM.YY, and the hours left today. The run starts Monday 01.10.18 (Balance levers). |
| Time numbers (x3) | Cooldowns, Special Level Delay (15), News Ticker (36), Patron Free Backing Units (90), Draft Bill Cooldown (90). |
| Decay | Standing and meta decay moved to each week end (Decay Interval is now 0). A new lever, Week Decay Multiplier (2.5, draft), scales the percent and neglect steps because a week is about 2.4 levels. |

New files: `scripts/rules/WeekCalendar.gd`, `scripts/ui/CalendarSquare.gd`. Tests: `tests/test_week_calendar.gd`, additions to `tests/test_time_clock.gd`, and the real-click `tests/interaction/week_test.tscn` (in `tools/verify.sh`). The playtest bot goes home when the work week is full.

## Party dues, name awareness and election strength (2026-10-23, Cameron) -- steps 3, 4, 5 and the strength bar

| Piece | What it does | Where |
|---|---|---|
| **Party dues** | At each week end ("Pay Party Dues and Go Home") the party takes 100,000円, plus 50,000円 for every full 15 points of Party support above 40, plus 30% of the Funds earned Monday to Friday that week, less whatever National Awareness takes off. Paid from Funds as far as they go. | `PartyDues.gd`, `GameState._settle_dues()`, Balance "Dues: ..." levers |
| **Overdue** | Anything unpaid rolls over. A short week costs 10 Party support, withdraws the party's backings (any backing triggered by a Party-tier organization), and applies -20 Party HQ, -5 Selection Committee and +5 to each other party, all multiplied by 1.5 for every full 100,000円 owed. | same |
| **Awareness meters** | District and National, 0 to 100. Gaffes left at a Combat stage's end cost one point each on both (a stage lost to gaffes costs the whole limit). Stage wins add awareness through two new Stages columns (Win ΔDistrict / ΔNational Awareness, draft values by room type); a bill flipped by influence and a bill the player carried that passes add through Balance levers. | `GameState.apply_awareness_*`, Stages columns |
| **Awareness Effects tab** | Seven rows: National 80+ cuts dues by 100,000円; District 80+ earns a free Training Session Coupon at each week end; National 65+ starts Media Ambush, Press Conference and TV Debate rooms 5 ahead; District 65+ starts Town Halls 5 ahead; District 50 or less costs the Selection Committee 10; District 25 or less costs 50 XP; National 40 or less costs every National organization 5, growing by 5 for each consecutive week ("Escalating", a draft reading of "additive"). Rows are data: new ones need no code. | `AwarenessEffects.gd`, `data/awareness_effects.json` |
| **Election strength** | Built and shown, fires nothing. Eight inputs (District and National Awareness, Constituency support, organizations on side, war chest, experience, legislative record, party backing) add to a "potential" of 100; the strength moves toward it by at most 2.5 a week (falls at most 1.5), so even an easy start climbs slowly. A bar on the Office; each input on Your Record. | `ElectionStrength.gd`, Balance "Election: ..." levers |

New workbook tab **Awareness Effects** (header notes included). Tests: `test_party_dues.gd`, `test_awareness.gd`, `test_awareness_effects.gd`, `test_election_strength.gd`, and the real-click `week_test` now covers paying and falling short.

## Events: arranged or arriving, with fixed choices and variable rewards (2026-10-23, Cameron) -- step 6

An event is a screen of flavor text and two to four fixed choices; each choice rolls its own ranges. Two new workbook tabs, **Events** and **Event Choices**, both with header notes, hold the content (12 events and 31 choices, all drafts for Cameron to rewrite; no named characters).

| Piece | Detail |
|---|---|
| Buyable events | A new **Events** button on the Office lists them with hours and price (walking tour 4h and 10,000円, charity dinner and rally weekend only, newspaper ad, national TV spot, community grant). The price is paid when arranged, the hours when a choice is made. |
| Random events | After a level or a week end there is a Balance chance (Event: Random Chance Percent, 35) that one arrives, weighted, off cooldown, only at the right time of the week, and only once the player is known enough (Min District/National Awareness). |
| Choices | Each choice can cost Funds, roll Funds/XP/Constituency support/Reputation/Party support/District and National Awareness ranges, grant organization standing and items in the usual Rewards format, and **reveal a level**. |
| Revealing a level | New Levels column **Needs Discovery (Yes/No)**: such a level stays out of the list until an event reveals it, then shows with its normal XP price. LV34 (Hokkaido Shinkansen) is flagged as the first example, revealed by the "A Question About the Street" event. Clear its flag to show it from the start. |
| Calendar | Events spend hours like a stage does; a weekend event must fit the hours left; a finished work week takes none. |

Shop items SH19 (dinner) and SH20 (walking tour) are unchanged; the new Events duplicate their idea with choices. Tests: `tests/test_events.gd`, real-click `tests/interaction/event_test.tscn` (in `tools/verify.sh`, which now sets `COP_NO_RANDOM_EVENTS` so a chance pop-up never lands on another test's click). How to Play entries HT29 to HT33 cover the week, dues, awareness, events and election strength.

## Dues baseline 50,000円; weekend levels; "Attend a Local Festival" (2026-10-23, Cameron)

| Change | Detail |
|---|---|
| Dues | Balance "Dues: Base" is now 50,000円 (was 100,000円); the 50,000円-per-15-Party-support steps and the 30% share are unchanged. Tests updated. |
| LV85 "A Quiet Word with a Lobbyist" | One Lobbyist Meeting stage (ST20), no Media Ambush after it. Weekend OK. |
| LV86 "Weekend Office Hours" | One Office Hours stage (ST07), 2 hours. Weekend OK. |
| LV87 "Attend a Local Festival" and ST264 | A new Office Hours variant seating **ten** constituents (4 hours, Weekend OK). Wins pay District Awareness +3 and Constituency support +6. It draws from a pool of 14 new local visitors (VI81 to VI94) with 28 draft dilemmas (VQ222 to VQ249) on festivals, shrines, bears, vacant houses and the tax base, trash, village snow removal, overtourism, and publicizing ski resorts, onsen, mountains and scenic parks. The pool is festival-only (not in ordinary Office Hours). |

All three levels have cooldowns (16, 8 and 24 hours). Every dilemma obeys the existing content budget (each choice 2 to 7 points, any gaining choice also costs something, one strongly pleasing choice). Tests: `tests/test_weekend_levels.gd`.

## Gated bill levels, hosting that reveals bills, and a content build-out (2026-10-23, Cameron)

| Piece | Detail |
|---|---|
| **Half of the bill levels are hidden** | Of the 50 bill levels, 24 now carry **Needs Discovery**: 2 of tier 0's 5 (LV33, LV34), 13 of tier 1's 26, 9 of tier 2's 19 (half, rounded down). A hidden level stays out of the list until it is revealed, then shows with its normal XP price. The exporter errors on a hidden level with no way in. |
| **Two ways in** | 12 levels are revealed by an **event choice** (LV34, 35, 39, 43, 45, 49, 52, 57, 59, 60, 64, 73) and 12 by **hosting**, through a new Levels column **Host Org (BOxx)**: hosting that organization reveals one of its hidden levels each time (the dinner for National organizations, the walking tour for Constituency ones). The hosting-only levels are LV33, 55 and 75 (Chamber of Commerce), LV37 and 69 (Innovation Society), LV41 and 70 (Fisheries), LV47 (Urban Neighborhood), LV65 (Financial Industry), LV76 (Agricultural Cooperatives), LV79 (Family Network), LV81 (Taxpayers' Alliance). |
| **Items take hours** | New Shop column **Hours**: SH19 (dinner) and SH20 (walking tour) take 4. A gathering is refused when the work week is over or the weekend has fewer hours left. "Unlock Random Level" items no longer unlock a hidden level. |
| **Events: 24 more (36 in all)** | 11 reveal events for the gated levels (a veteran's letter, the mayors, a priest and a caretaker, a founder on the train, a reception, a hotel owner, a clerk's pay slip, a parents' meeting, a long-time resident, a closing clinic, a harbor customs officer); 5 Buyable (local radio spot, sponsoring a team, a podcast, a constituency office day, a festival float); 8 more Random (a radio host, a school visit, a trash-site dispute, a photograph going around, a retirement, heavy snow, a bear near a school, a union delegation). |
| **Six more levels** | LV88 A Press Gaggle, LV89 A Town Hall on Local Issues, LV90 A Policy Study Evening, LV91 A Late TV Interview, LV92 the Autumn Harvest Festival (ST265), LV93 the Winter Snow Festival (ST266), all weekend-capable. |
| **Festival content** | The two new festivals seat ten constituents each. Each has 8 new seasonal visitors (VI95 to VI102 harvest, VI103 to VI110 winter) with two dilemmas apiece (VQ250 to VQ281); the original 14 local visitors (VI81 to VI94) also appear at all three festivals, so each draw is ten from a pool of 22. |

All text is draft for Cameron to rewrite. Tests: `tests/test_gated_levels.gd` (half per tier, every gated level reachable, hosting reveals one at a time, the dinner and tour take four hours and respect the calendar, all festivals seat ten distinct constituents).

## Dining room and walking route pictures, with purchasable alternatives (2026-10-23, Cameron)

Four background assets, shown behind every hosted dinner and walking tour (the SH19 and SH20 result popup and the dinner and tour events). A missing picture shows a placeholder labelled with its ID until the art is drawn.

| Asset ID | File | What it is | How you get it |
|---|---|---|---|
| `DINING` | `assets/backgrounds/DINING.png` | Tasteful Dining Hall (default) | Always |
| `DINING_ALT` | `assets/backgrounds/DINING_ALT.png` | Grand Lakeside Dining Hall | Buy **CP03** for **50,000円** |
| `TOUR` | `assets/backgrounds/TOUR.png` | Suburban Street Tour (default) | Always |
| `TOUR_ALT` | `assets/backgrounds/TOUR_ALT.png` | City Corridor Tour | Buy **CP04** for **75 XP** |

Cosmetic package icons: `assets/icons/Dining_Alt.png` and `assets/icons/Tour_Alt.png`. All six are listed in the workbook's Assets tab (1080 x 2340 for backgrounds, 256 x 256 for icons).

Schema: Cosmetic Packages gains **Dining Variant** and **Tour Variant** (two new equip slots, "Dining room" and "Walking route", in Cosmetics); Shop and Events gain an **Image** column (SH19 and EV02 use DINING, SH20 and EV01 use TOUR). Each of those has a header note. Tests: `tests/test_dining_and_tour_images.gd`; the events real-click test checks the popup.

## The walking tour and the dinner are guest events (2026-10-23, Cameron)

SH20 (Host a District Walking Tour) and SH19 (Host a Dinner) now start two different three-screen events instead of applying +1 / +2 standing to the organization you pick. Choosing the organization still decides who your patron is and who most of the guests are; **what comes of it depends on how the guests react**.

| Screen | Walking tour (HE01, District Awareness) | Dinner (HE02, National Awareness) | After the screen |
|---|---|---|---|
| 1 | Where to go: the shrine, an orchard and farm, a manufacturing plant, the shotengai, a neighborhood, or the fishing port | The menu: an entree, a drink and a side, each from five dishes (Hakodate scallops, Japanese tuna, Australian beef, local pork cutlet, Aomori apple vegetables; French wine, local sake, Aomori apple juice, craft beer, barley tea; and so on) | Each guest reacts |
| 2 | A policy topic (eight, mirroring the organizations) | Same | Each guest reacts |
| 3 | A modest promise (cut business taxes, a crypto-yen, leave the alliances, more trade agreements, fund shrine restoration, protect farmland, a modest wage rise, rural broadband) | Same | Each guest reacts |

**How reactions work.** Every option carries tags; every organization likes and dislikes tags (new Organization Tastes tab, all 32 organizations); a guest reacts +1 for each liked tag and -1 for each disliked tag over what was chosen, kept to -2 to +2, shown with one of five wordings (Reaction Lines). A farm cooperative guest served French wine or Australian beef is offended; apple juice delights them.

**Who comes.** Up to five guests: the patron organization's own characters first (opponents by affiliation, visitors by the organizations they please), then characters of allied organizations (those sharing a party in Party Stakeholders). Party bodies never attend.

**What the evening does.** Each guest's organization moves by their reactions (the patron's own guests count double, capped at 6 per organization); the awareness meter moves by the total reactions divided by 2 (from -3 to +6); a very good evening adds 1 Reputation and a very bad one costs 1. It takes 4 hours, and hosting an organization still reveals one of its hidden bill levels at the end. All numbers are Balance levers ("Hosted: ...").

New tabs: **Hosted Events**, **Event Options**, **Organization Tastes**, **Reaction Lines** (all with header notes); new Shop column **Hosted Event**. The earlier stand-alone walking tour and charity dinner events (EV01, EV02) are retired. Open choices I made on Cameron's behalf, to confirm: tags rather than a per-guest table, five guests, commitments having no lasting effect, and a small Reputation effect only on a clearly good or bad evening. A hosted evening is not saved midway: closing the app during one uses up the item. Tests: `tests/test_hosted_event.gd` and the real-click `tests/interaction/hosted_test.tscn` (in `tools/verify.sh`). The Marketplace test now expects no automatic +2.

## Decisions batch: tiered backings, a whip discount, tier 0 shown, scheduled dues events (2026-10-23, Cameron)

| Change | Detail |
|---|---|
| **Tiered backing standing** | New Modifiers column **Required Standing**: the standing needed to buy that backing. Blank uses the flat default (60). Smaller organizations ask 45 to 50, powerful ones more. `Ledger.standing_needed()` reads the modifier's own value first |
| **Whip discount (max 1)** | When at least one organization is in your corner, every extra whipped vote costs 1 less Party support (a flat 1, not per organization), never below 5. An organization counts at standing 65 or more, with a positive stake in your own party (Party Stakeholders), and not already a row of the vote-influence gate for your party. New Balance levers Whip: Discount Amount (1), Whip: Discount Standing (65), Whip: Discount Floor (5). The whip row names the organizations. `VoteWhip.discount_orgs()` and `discounted_unit()`. Also fixed: the screen read a lever name (`whip_against_multiplier`) that does not exist; it now reads `whip_against_party_multiplier` |
| **Tier 0 shown in full** | LV33 and LV34 no longer need discovering. EV12 (the street question) no longer reveals a level; EV17 reveals LV35 and is the example in tests |
| **Scheduled dues events** | Three new Random events: **EV44 A Reminder From Party Headquarters** (only while unpaid dues are carried over), **EV45 The Party Treasurer Drops By**, **EV46 An Invitation to the Party Fundraiser**. New Events column **Needs Dues Owed**, new Event Choices column **Dues Δ** (a negative number writes down the carried balance, never below nothing) |
| **District activities** | Design only, awaiting approval: `design/proposals/DISTRICT_ACTIVITIES_2026-10-23.md` |

Tests: `test_vote_whip.gd`, `test_ledger.gd`, `test_events.gd`, `test_gated_levels.gd` updated and extended. The Events and Event Choices tabs have no header notes yet (the two new columns are described here).

## District activities: four single-stage outings (2026-10-23, Cameron)

Built from the approved design (`design/proposals/DISTRICT_ACTIVITIES_2026-10-23.md`, all four, defaults). Each is an Office Hours clone with its own pool of local visitors, open from the start and weekend-ready.

| Activity | Stage / Level | Hours | Seats | Pool | Cooldown | Main reward |
|---|---|---|---|---|---|---|
| Constituency Walkabout | ST267 / LV94 | 2 | 6 | 14 | 8 | District Awareness +2 |
| Community Clinic Day | ST268 / LV95 | 3 | 6 | 14 | 16 | Constituency support +5 |
| School Visit | ST269 / LV96 | 2 | 8 | 14 | 12 | Reputation +1 |
| Farmers' Market Stall | ST270 / LV97 | 4 | 10 | 14 | 24 | Funds +10,000円, District Awareness +2 |

56 visitors (VI111 to VI166) and 112 dilemma questions (VQ282 to VQ393), all inside the content budget. Visitors are generic local roles; names, wording and organization effects are a draft for Cameron to rewrite. The test `test_district_activities.gd` checks the shape; `test_bill_stages.gd` exempts the four stages from the Office Hours seat-count rule, as it does the festival.

## Written district-activity answers, and the dining and tour pictures (2026-10-23, Cameron)

| Change | Detail |
|---|---|
| **No more stock lines** | All 112 district-activity questions (VQ282 to VQ393) now carry their own fourth choice, their own responses to the wrong answers, and their own reactions for every choice. Before, those were four rotating lines reused across every question. The wrong-answer responses react to the mood of a dismissive reply rather than to each choice line by line, so they are the first thing to polish |
| **Pictures** | Your uploaded `DINING`, `Dining_alt`, `Tour` and `Tour_alt` backgrounds are in. The game looks files up by exact ID, so three were renamed to `TOUR.png`, `DINING_ALT.png` and `TOUR_ALT.png` |
| **Alternative icons** | CP03 and CP04 now use the main item icons (`booster_dinner`, `walking_tour`) instead of `Dining_Alt` and `Tour_Alt`, which were never drawn |

## Election Strength moves to its own page (2026-10-23, Cameron)

| Change | Detail |
|---|---|
| **Off the Office screen** | The election bar and its caption are gone from the Office. |
| **Its own button** | "Election Strength" sits in Reputation and Results, between Parties and Your Record. |
| **Three bars in the party colour** | Election strength, District Awareness and National Awareness are each a continuous 0-100 bar in the official colour of the player's own party, the same look as the allies popup. The awareness lines keep their "(+N)" recent change. |
| **No more two "National Awareness" numbers** | The meter (for example 10 / 100) and the points it feeds the strength (1.5 of 15) both carried the same name. The points are now "Points from district awareness" and "Points from national awareness", under the heading "What counts toward it". |
| **Your Record** | The election and awareness lines moved out of Your Record to the new page. |

The Office-menus click test now opens the new page and checks it has three bars in the party colour.

Follow-up (2026-10-23): the Election Strength page was confusing. The bar read 0 while a line said 10 (the target it grows toward), and each awareness meter appeared twice. Now: the line says "heading toward 10 of 100"; the heading "What feeds it" holds District Awareness and National Awareness once each, as bars that say what they add ("Adds 3.0 of 15 points"), followed by the other six inputs.

Follow-up (2026-10-23, Cameron): the Election Strength page is now nine bars and almost no text. Election strength is a bar in the standard gold (the cue-banner gold); District and National Awareness and the six other inputs are each a bar in the player's party colour (the six as their share of their own maximum). No points, no "adds", no "heading toward" line and no "What feeds it" heading.

Follow-up (2026-10-23, Cameron): the Election Strength page carries no numbers at all for now, only a name over each bar (including the awareness meters and the recent-change figure).

## Dated events: a scripted event on a calendar date (2026-10-23, Cameron)

| Piece | Detail |
|---|---|
| **Trigger = Dated** | A new Trigger value in the Events tab, with two new columns: **On Date** (DD.MM.YY, the same form the calendar square shows) and **Speaker Title** (optional). Export checks that the date is real and that some opponent carries the Speaker Title in its Title column. |
| **When it fires** | Forced. It opens by itself the first time the Office is open on or after its date, so a long level cannot make the player miss it. It never opens mid-level, and it plays once per run (saved as `dated_events_done`). If the screen is closed without choosing, it comes back at the next Office visit. |
| **The speaker** | The first opponent whose Title lists the Speaker Title ("Prime Minister" finds OP10 Aki Rono). The screen shows their picture and "Name, Title" under a "Scheduled for DD.MM.YY" line. |
| **Content** | The ordinary Event Choices tab: hours, Funds, XP, Party support, awareness, organization effects, and Unlocks Level. |
| **First example** | EV47 "The Prime Minister's Opening Address", 09.10.18 (Tuesday of week 2), 2 hours, three draft choices. |
| **One-off** | No yearly repeat; the game has no fixed election date. |

Tests: five new cases in `test_events.gd` and a real-click step in `event_test` (nothing on Monday, the address on Tuesday with the speaker's picture, played once). Real-click tests keep dated events off with the same `COP_NO_RANDOM_EVENTS` switch as random ones. The Events tab has no header notes yet, so the two new columns are described here.

### Singular hours, a YY.MM.DD calendar with the weekday, and two calendar packages (2026-10-26, Cameron)
- **"1 hour"**: every line that prints a number of hours (calendar square, end-work-week prompt, event list, "It took N hours", hosted events) now has a `.one` row in the Text tab and the code passes `count`. Test: `test_week_calendar.gd`.
- **Calendar square**: the date reads `YY.MM.DD` (dated events show their date the same way; the Events tab "On Date" column is still typed DD.MM.YY). A third row shows the weekday in English and Japanese ("Monday 月曜日").
- **Card back**: the "This question doesn't care how you answer it." line is gone (a medium-graded question now says nothing).
- **Era Name calendar (CP05, 2,000円) and Ainu calendar (CP06, 2,000円)**: cosmetic packages with a new *Calendar* slot (`Calendar Style` column: `era` / `ainu`), bought and switched like any other package from Appearance and Music. Era style writes `平成30年10月1日` with the weekday in kanji only; the era changes to 令和 on 2019-05-01 (first year written 元年). The era table is `data/rules.json`'s `calendar_eras`. Ainu style writes `2018.ウレポク.01` on two levels (no weekday, since no Ainu day names were given); the twelve month names are Text rows `calendar.ainu_month_01..12`, taken in order as January to December. Icons: `tools/icons/make_calendar_icons.py` draws `calendar_era.png` and `calendar_ainu.png` in the existing icon palette. Rules: `scripts/rules/CalendarStyles.gd`; tests: `tests/test_calendar_styles.gd`.
- **Audio plan**: `design/proposals/AUDIO_PLAN_2026-10-26.md` (nothing built yet; waiting on decisions).

## Marketplace item tiles show the quantity only, in a sideways row (2026-10-27, Cameron)
- A held item's tile in the Marketplace and inventory now shows its icon and "×count" only; the name is in the pop-up a tap opens (Text row `inventory.entry`, now just the count).
- The tiles sit in one row that scrolls sideways (`InventoryPanel.inventory_rows()`), so many kinds of item no longer lengthen the panel. The interaction driver now scrolls every ancestor scroller into view before clicking.

## Hard-coded numbers and lists moved to the workbook (2026-10-27, Cameron)
- Three Balance levers were misspelt in code (draft-bill costs, supermajority share) so workbook edits were ignored; fixed, and `tests/test_balance_keys.gd` now fails on any key the scripts read that the workbook lacks (Balance, Rules and `Levers`).
- 29 new Balance rows: win-over odds and Undecided cost, press reputation bonus, patron visit deltas, Flagship discount after a failed Favor, tendency cutoffs, ally neutral band, hosted guest share, audience scale cap. Rules files read them through `Levers` (filled by DataDB), with no fallback number.
- Staff roles come from the Staff tab, suit names from `suits.json`, card frames per suit from `data/art.json`. ST05 gained its Question Pool cell; the BattleSetup fallback tables are gone.
- Audit: `design/review/HARDCODED_AUDIT_2026-10-27.md`.

## Ainu weekday names (2026-10-27, Cameron)
- The Ainu calendar's third row now shows the day name in katakana (Text rows `calendar.ainu_weekday_sun..sat`): Monday クンネチュㇷ゚ト, Tuesday アペト, Wednesday ワッカト, Thursday ニト, Friday コンカネト, Saturday トイト, Sunday トカㇷ゚チュㇷ゚ト. Thursday has two names in Cameron's list (nito, cikunito); ニト is shown.

## Ticker lines for specific days and date ranges (2026-10-27, Cameron)
- Three optional columns on the Office Ticker tab: `weekdays` (Mon; Tue; ... or full names), `from_date` and `to_date` (YY.MM.DD, as the calendar square writes it, inclusive). Blank means no limit; they combine (AND) with the existing condition, so a line can be "always, but only on Fridays" or "when Funds is high, between 18.12.24 and 18.12.26". A single day is the same date in both columns.
- `OfficeTicker.calendar_met()` reads today from `GameState.ticker_facts()` (`today`, `weekday`). The exporter checks day names, real dates and that From is not after To. Tests: `tests/test_ticker_calendar.gd`.
- Dates are one-off (the run's own year); a yearly repeat such as 25 December every year is not built. Events' "On Date" column is still typed DD.MM.YY, unlike this one.

## One date format, template ticker dates, and a yearly repeat (2026-10-27, Cameron)
- **One format everywhere: YY.MM.DD.** The Events tab's On Date column now uses it too (EV47 is `18.10.09`); `WeekCalendar.parse_date()` is the single parser (the separate `parse_ymd` is gone), and the exporter checks Events dates the same way. Earlier notes above that say the Events column is DD.MM.YY are superseded.
- **Yearly option:** a `yearly` column on Office Ticker (Yes, No or blank). With Yes the year in From/To is ignored, so `18.12.24` to `19.01.03` means 24 December to 3 January every year, and a window crossing New Year works. It needs both dates; the exporter says so if one is missing.
- **Six template rows** (TK150-TK155) show each choice: one weekday, a weekend, a single day, a date range, a yearly window, and weekday plus range combined. Their text is plainly labelled "template"; edit or delete them.

## Excel repair message on opening the workbook (2026-10-27, Cameron)
- Excel reported "Removed Records: Shared formula from sheet20.xml" and "Formula from calcChain.xml". Cause: on the Press Questions tab the "Strong total" row (row 36) had a shared formula whose range was written as D22:I22 instead of D36:I36, and the calcChain cache still listed formula cells (in four question tabs and Vote Tally & Swing) that had since become plain text. Both are old, not from a recent edit.
- Fixed: the range is corrected and calcChain.xml is removed (Excel rebuilds it silently). `WB.save()` now drops it on every save, and `tools/workbook/check_formulas.py`, run by `tools/verify.sh`, fails if either problem comes back. No data changed.

## The workbook is now Game_Workbook.xlsx (2026-10-27, Cameron)
- `design/CoP_Starter_Card_Stage_Data.xlsx` is renamed `design/Game_Workbook.xlsx`; every reference in the exporter, the workbook tools, the docs and the archived batch scripts now uses the new name. Older entries in this log that mention the old name mean this file. Data and content are unchanged.

## Office dues box, staff gate, profile layout, faster verify, outside backgrounds (2026-10-28, Cameron)
- **Dues box.** A gold box beside the calendar square (`DuesBox.gd`, built in code like `CalendarSquare`): "Party Dues: ###円" over "Office Funds: ###円" (Text rows `dues.box_dues`, `dues.box_funds`). Dues is this week's total plus any carried balance (`GameState.dues_preview()`).
- **Cards.** The Japanese name no longer sits over the art on a card front; the card back drops the room's suit-match line and the question-effect line (and their helper functions). The eight `card.room_*`/`card.question_*` Text rows are now orphaned (see `design/CLEANUP_CANDIDATES.md`).
- **Staff delegation gate.** A choice whose text contains one of `rules.json`'s `staff_delegation_phrases` ("a staff member", "a staffer", "a deputy") is greyed out with "No staff hired" when nobody is hired (`StaffDelegation.gd`; event choices and visitor questions). Wording-based by Cameron's choice.
- **Briefing Back** returns to the levels list, not the bare Office (`_on_briefing_closed`; going in sets a flag first).
- **Workbook moves.** The public room a PUBLIC stage becomes now comes from two new Bill Level Templates columns (Public Room (Constituency)/(National), first defaults ST05/ST04); the unlock-tier cap is gone (a hired member's tier is capped by their own highest tier); the fixed 10-slot cap in `LevelTemplate` is gone (it reads whatever `stage_N` columns exist).
- **Staff pictures.** A plain `SF01.png` (no expression tag) is now the last resort for every expression of that character (`ArtLoader.character_path_candidates()`).
- **Staff profile.** Rearranged: the full picture top left (fitted so its top sits at 146 px), name/role/cost top right, a biography line, then the tiers and buttons; content pinned to the top (new `Overlay.top_aligned`), no empty heading bar, buttons kept inside the screen width. Two new Staff columns, **Biography** and **Role Flavor Text** (blank until Cameron writes them; the role flavor shows under the role line).
- **Verify is faster.** `tools/verify.sh` finds every `tests/interaction/*_test.tscn` itself (two were never run: intro, mash), runs four at a time in separate save folders alongside the unit tests (`XDG_DATA_HOME`), and has a `--quick` mode. About 2 minutes, down from about 5.5; the script is about 120 lines shorter.
- **Outside backgrounds.** Every bill or topic stage already shows its generic room's picture through the Stages tab's Background ID (2026-10-18). New: eight generic outside scenes in `data/art.json` (`outdoor_scenes`: OUT_FESTIVAL, HARBOR, LAKESIDE, FARM, SCHOOL, SHRINE, STREET, NEIGHBORHOOD). An `OUT_xxx` id used as a stage's Background ID or an event's Image shows `OUT_xxx.png` once drawn and the Town Hall (ST05) until then (`ArtLoader.background_path()`). Eleven outdoor events now carry one (EV06, 12, 13, 19, 32, 35, 37, 38, 41, 42, 43). `python3 tools/outdoor_backgrounds.py [--write]` lists each scene, who uses it, how much content mentions it, and a ready art prompt (`design/OUTDOOR_BACKGROUNDS.md`). OUT_LAKESIDE has no content mentioning lakes yet.
- **Tooling.** `WB.delete_row()` in `tools/workbook/wbx.py` (plain data tabs only; nothing was deleted from the workbook). `design/CLEANUP_CANDIDATES.md` lists unused rows and tools for a future pass; nothing removed.

## Marketplace limit line, and several pictures for one event (2026-10-29, Cameron)
- **Marketplace.** The top line is now "Funds 12,000円 / Limit 100,000円" (`GameState.funds_limit()`: the starting cap plus Funds-cap purchases, never past the hard ceiling; Text row `shop.funds_limit`). The page rebuilds after each purchase, so the limit follows.
- **Several pictures per event.** An Events Image cell can list background IDs separated by semicolons ("OUT_HARBOR_1; OUT_HARBOR_2"); `EventPicture.pick()` chooses one each time the event comes up and the result screen keeps the same one. A single ID behaves as before. Undrawn `OUT_` IDs show the Town Hall. `tools/outdoor_backgrounds.py` counts every listed ID. Tests: `tests/test_event_picture.gd`, `tests/test_funds_limit.gd`.
- **First outside pictures drawn (2026-10-29).** Cameron uploaded 17: festival (1, and 2 in regular and winter), harbor (2), school (2), shrine (2), street (3), farm (2), village road in snow (2) and the old coastal battery. Events now name them: street (EV06, 12, 39, 43), festival (EV13, 35), shrine (EV19), school (EV24, 37, 42), harbor (EV27), the coastal battery (EV17) and the snowed-in village road (EV41); two new scenes, `OUT_COAST_BATTERY` and `OUT_VILLAGE_ROAD_SNOW`, are in `data/art.json`. The winter festival picture is not used yet (no season rule). The pictures are square or landscape, not 1080 x 2340; an event's picture band crops them to fit. Farm pictures have no event yet.

## Terms in picture names, and thematic stages pick their pictures (2026-10-29, Cameron)
- **Terms.** A picture whose name carries a term (`OUT_FESTIVAL_2_WINTER` carries WINTER) is used only when the event's title and flavor, or the stage's name, contains that term or a related word. `data/art.json` `image_terms` lists each term and its related words (WINTER, SNOW, AUTUMN, SPRING, SUMMER, NIGHT, RAIN; Cameron's to edit). Preference: a term picture the context invokes; else a picture with no term; else any, so a list is never empty (`EventPicture.eligible()`). A name with several terms needs all of them.
- **Stages can list several pictures** in the Stages tab's Background ID cell, exactly like an event's Image cell. One is chosen when the stage's picture is set and kept while it is on screen (`ArtLoader._stage_choice`, `forget_pick`).
- **Workbook edits.** The district activities and one harbor room now name pictures: ST264 Local Festival, ST265 Autumn Harvest Festival (festival and farm), ST266 Winter Snow Festival (the festival list; its name invokes winter so the winter picture is the one used), ST267 Walkabout (street), ST268 Clinic Day (neighborhood, undrawn so the Town Hall shows), ST269 School Visit, ST270 Farmers' Market (street and farm), ST29 Town Hall at the Harbor (harbor). EV13 and EV35 also list the winter festival picture, which only appears in a winter context.

## A compile check for every script, and two Godot 4.7 fixes (2026-10-29, Cameron)
- Cameron's editor (Godot 4.7.2) reported three startup errors. `tests/test_battle_engine.gd` used an untyped `weakref()` result (4.7 treats the inferred Variant as an error; now `var ref: WeakRef`). `tools/playtest_optimal.gd` still read `Ledger.STAFF_ROLES`, removed on 10-27 when roles moved to the workbook (now `Ledger.staff_roles(DataDB.staff)`); the bot had been broken since. `tests/test_committee_model.gd` is not in the repo (CommitteeModel was removed 2026-09-25); it was a stale local file, delete it locally.
- **New `tools/compile_check.tscn`** (run by `tools/verify.sh` step 2): loads every script under `scripts/`, `tools/` and `tests/` inside the running project and fails if any cannot be instantiated. It catches a removed constant or renamed function in a file nobody runs daily. It runs on the project's Godot (4.5.1), so it cannot see warnings only a newer Godot treats as errors.

## Card title centering, a no-scroll training offer, and a View button in the deck (2026-10-29, Cameron)
- **Titles are centered in their plates.** Each suit's frame paints its title plate a little differently, and the title was centered in one fixed box that sat about 0.01 of the card height too high. `data/art.json` `card_frames.name_box` now lists each suit's measured plate [top, height]; `CardView.name_box_for()` reads it and `show_card()` moves the title label to it. A suit not listed falls back to the old box. Re-measure if a frame picture changes.
- **Rhetoric Training offer fits the screen.** The front and back were a fixed 2x and ran off the bottom on a phone (the Learn button needed a scroll). `OfficeScreen._card_faces()` now picks the largest scale (between 1x and 2x) that fits the screen height after setting aside room for the heading, counter and buttons (`CARD_OFFER_CHROME`).
- **View on the deck screen.** Each deck row has a View button beside its pick/drop button (Text row `office.deck_view`) that opens the card's front and back in a pop-up (`_card_look_panel`, closes with Back, deck unchanged), sized the same way.

