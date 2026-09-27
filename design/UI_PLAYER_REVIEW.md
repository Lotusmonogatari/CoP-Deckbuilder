# A player-perspective UI review

Everything else in this repo proves a screen *works*: it opens, its numbers
resolve correctly, a real click does the right thing. This asks a different
question — would a first-time player looking at the screen understand it,
trust it, and have what they need? Built 2026-09-27/28 from one screenshot
per screen *shape* (not per stage — the same principle
`design/PLAYTEST_CHECKLIST.md` uses), each one cross-checked against the
real code and data behind it, not just read cold.

**Three lenses**, per the review plan:
- **Confusing** — a player could plausibly misread or not understand it.
- **Inaccurate** — the text on screen doesn't match the real game state.
- **Lacking** — information a player would need isn't there.

**What's deliberately left out of this doc**, so it isn't mistaken for a
finding:
- Missing art placeholders (`OP01_ATTACKING.PNG`-style labels, flat colour
  boxes for card art) — a documented, working-as-designed fallback (§13),
  not a bug. Every screen below shows several; none are listed as findings.
- Two screenshots reflect this driver's own synthetic state, not real
  content, and are excluded rather than misreported: the Deck screen
  (`GameState.owned_cards` was intentionally emptied by an earlier shot in
  the same run and never restored, so "12 of 12 chosen" legitimately shows
  no ownable cards); the original Steering Committee and Rhetoric-Training-
  adjacent shots that an earlier pass of this same driver got wrong (a
  scene-layering bug and a stale mid-draw resume) were re-shot after fixing
  the driver, not the game, and are not reported here.
- One thing was actively suspected as a real engine bug and ruled out:
  screenshot 05 (committee sequence, opponent 2 of 3) originally appeared
  to show "Turn 1 of 7" alongside "Gaffes 4/5" — looking like
  `_reset_for_new_bout()` (`scripts/rules/BattleEngine.gd`) wasn't actually
  clearing the gaffe meter between bouts, which would contradict §7.5's own
  claim that it does. Traced to the driver instead: its greedy-play helper
  only checked its stop condition *between turns*, so after the reset fired
  it kept playing up to 20 more cards against the fresh opponent before
  ever looking again. Fixed the helper to check every card play; the
  corrected shot reads `turn=1 gaffe=0/5 guard=0` — the reset works
  exactly as documented.

## Combat screens

| # | Screen | Finding | Lens |
|---|---|---|---|
| 06/07 | Press Conference (ST04) vs. TV Debate (ST06) | **Fixed.** ST06's own `bar_unit` cell in the workbook read `"Press tone"`, copied from ST04 and never changed for the TV Debate room. Cameron's call: **"Viewer Tone."** Edited directly in `design/CoP_Starter_Card_Stage_Data.xlsx`'s Stages tab (only ST06's own cell — ST04 and ST19 still correctly read "Press tone") and re-exported; `data/stages.json` now shows `ST06: "Viewer Tone"`. | Inaccurate |
| 17 | Battle screen, Details panel | **Fixed.** Two things, both from code written this session: (1) The panel's backdrop was translucent enough that the battle header behind it bled through and overlapped the panel's own text — now uses the same fully-opaque style `CardZoom` already used. (2) The party-colour labels used to be appended at the very end of the whole details block, far from the "You: …" / "Opponent: …" lines they described — each is now its own row (name + coloured party) sitting right where the old text-only line was. | Confusing |
| 16 | Battle screen, card zoom | Minor: the missing-art placeholder for card art is a semi-transparent kanji watermark centred over the card, and it sits across the middle of the effect text rather than in the art slot only — legible but visually busier than it needs to be while art is missing. Not fixing until real card art exists changes the picture anyway. | Confusing (minor) |
| 04–07, 18–19 | Every Combat screen | Consistent and correct: header wraps long names, the bar shows a clear threshold caption and a three-way breakdown (You / Undecided / Opponent), the status row's gaffe pips match `gaffe_limit`, win/loss overlays state the real reason (`outcome.reason.*`). No findings. | — |

## Non-combat and special screens

| # | Screen | Finding | Lens |
|---|---|---|---|
| 09 | Party Steering Committee Check-In (ST22) | **Fixed.** The header row clipped: the English title was long enough ("Party Steering Committee Check-In") that the Japanese accent plus the "N of N" visitor counter ran past the right edge and got cut off. `VisitorScreen.gd` now has its own `_fit_stage_name()`, the same wrap-long-titles fix `BattleScreen` got in the 2026-09-27 playtest pass, which it had never inherited — plus a scene-structure fix (`Title`'s `size_flags_horizontal` wasn't set to expand, so the wrapped label had no room to wrap into and collapsed to one letter per line on the first attempt; `VisitorScreen.tscn`'s header now mirrors `BattleScreen.tscn`'s structure exactly). | Confusing |
| 10 | Level Intro screen | **Fixed.** The CueBanner (the staff member's spoken line) is positioned across the vertical middle of the screen by design ("Ace Attorney style," §13); this screen's own layout used two expanding spacers to vertically *centre* its portrait, which put it directly in the banner's fixed band. `LevelIntroScreen.tscn`'s top spacer no longer expands, so the portrait now sits at the top of the screen, clear of the banner. | Confusing |
| 08 | Office Hours (ST07) | No findings — layout matches spec, visitor/question/choices/footer all render correctly, the counter fits (see 09 above for the contrast). | — |
| 12 | Supplies | **Not a bug.** `"ね3" Coffee` is an intentional in-universe brand name (Cameron confirmed) — no change needed. | — |
| 13 | Staff | No findings — tier gating, prices, and "Not open to recruitment yet." all read clearly. | — |
| 14 | The Organisations (Backing) | **Mechanism built, values still open.** Every booster used to read the same flat 50 with no way to differ at all — `GameState.reset_booster_standing()` only ever read one global `start`. The workbook's Boosters tab now has its own **Starting Standing** column (`boosters.json`'s own `starting_standing`, per booster_id), read before the flat default for any booster it's left blank. Fill it in the same way as any other Boosters-tab column, re-export, done — no JSON to hand-edit. The column is still blank for all 16: how warm each real organisation is to a brand-new legislator is Cameron's own political-characterization call, not an engineering one, so it's left for him to write. | Lacking (mechanism done; values are Cameron's) |
| 15 | Deck | Not meaningfully reviewable this pass — see the note under "What's deliberately left out" above. Worth a real re-shot with real owned cards before trusting any finding here. | — (excluded) |
| 01 | New Game / protagonist picker | Each protagonist's stat block (Constituency support / Reputation / Funds / Party support / XP) is a flat list of labels at one text size and weight, mixed in directly below the difficulty blurb with no visual separation — a player has to read five lines of near-identical-looking text to find, say, just the Funds number. Not wrong, just dense. Worth a quick pass (bolding the numbers, or a light table/grid) if this screen gets attention later — low priority, first-launch-only screen. | Lacking (minor, cosmetic) |
| 02/03 | Office (fresh state / crisis alert) | Party colouring on the header ("Kenshin Sako · Frontier Party") reads correctly, and the low-reputation notices show correctly. The crisis-alert popup itself is accurate content-wise ("Constituency support fell to 12 — a Town Hall has been added to your schedule.") but sits in an otherwise fully empty dark screen with no dimmed Office visible behind it and a lot of unused vertical space above and below the message — not wrong, just visually sparse compared to how full the header/notice screen looks. | Lacking (minor, cosmetic) |

## Summary for Cameron

All three open items from this review are now resolved or in your hands:
1. **ST06's `bar_unit`** — changed to "Viewer Tone" (your call), in the
   workbook and re-exported.
2. **`"ね3" Coffee`** — confirmed intentional, no change made.
3. **The flat 50 booster standings** — the mechanism to vary them now
   exists as an ordinary workbook column, the Boosters tab's own **Starting
   Standing** (blank = the flat default); the actual numbers per
   organisation are still yours to write whenever you're ready, the same
   way you'd fill in any other Boosters-tab cell.

Everything else (the Details panel's text bleed-through and misplaced
party labels, the Steering Committee header clipping, the Level Intro
banner covering the portrait) had no design call attached and is fixed
directly — see each row above for what changed. `tools/verify.sh` is
green.
