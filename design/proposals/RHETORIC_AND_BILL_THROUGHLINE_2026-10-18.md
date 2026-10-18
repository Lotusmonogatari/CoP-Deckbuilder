# Rhetoric, organizations and the bill through-line: review and proposal (revised 2026-10-18)

Nothing here is built. Revision 2 folds in Cameron's four additions: bill-specific content in every bill level, a clear proponent party (and whether inverse bills help), organization icons with a live ± preview when a card is picked up, and a smaller vote-switch recovery (25%).

## Executive summary

| | |
|---|---|
| **Problem 1: the link is real but hidden** | A card affects organizations only through the question it answers, and the player sees who cares only in the Details panel and what changed only on the Outcome panel. |
| **Problem 2: the bill story breaks** | The lean is forgotten after the Level Intro. 30 of the 50 bill levels (LV31-LV60) play generic rooms. The bill has no named proponent. Your own vote does nothing to organizations. |
| **Fix 1: show the room listening** | Organization icons sit in the empty part of the battle screen every turn. Picking up or tapping a card shows a ± number on each icon over a green (gain), red (loss) or gray (no change) wash. Tapping selects and previews; a second tap or a **Read** button opens the card zoom. |
| **Fix 2: a backing reveals style tastes** | Owning an organization's backing shows which rhetorical styles it likes on its icon. |
| **Fix 3: the bill through-line** | Each bill names its **proponent party**. The lean is saved and decides who hears you as a friend or an opponent in every stage. Your own vote moves the stakeholders. Switching your vote recovers at most **25%** of what the stages cost you, rounded down, a lever future backings can raise. |
| **Fix 4: bill content in every bill level** | Content can be scoped to a **bill** rather than a room, so the 30 older bill levels gain bill questions and cues without building ~100 new rooms. |
| **2b: do inverse bills ease the work?** | **No, not for matching the player's direction.** A twin bill doubles the levels, rooms and content, while the stance problem is solved more cheaply by a Stance tag on player lines (Section 5). Inverse bills are worth having later, for variety, where the inverse is a genuinely different policy with a different proponent. |
| **Schema changes needed** | Three optional columns: **Proponent Party** (Floor Vote Bills), **Bill ID** scope (Stage Questions, Player Cues, Opponent Cues, Transition Dialogue) and **Stance** (Player Cues). Each needs Cameron's OK. |

## 1. How it works today

| Link | Now | What the player sees |
|---|---|---|
| Card → question | Suit graded S/M/W against the question; Strong x1.3, Weak x0.7. | One line on the card zoom. Nothing in the hand. |
| Question → organizations | The theme names who is pleased and who a strong answer sets back; every answer counts, banded and capped per stage. | The Details panel only. |
| Organizations → result | Applied when the stage ends. | Icons on the Outcome panel. |
| Card with no question | Never touches an organization. | Nothing. |
| Lean | Party support ± 2 against your party's disposition; not saved. | One line on the Level Intro. |
| Bill levels | LV63-LV82 have topic rooms. LV31-LV60 play generic rooms (21 of 118 rooms are shared across levels, so a room cannot simply be given one bill's questions). | Nothing ties the stage to the bill. |
| Proponent | Not in the data. Floor Vote Bills has name, description and per-disposition deltas only. | The player cannot tell whose bill it is. |
| Final vote → organizations | Law Effects apply to the bill's outcome whatever you voted. | Nothing for your choice. |

## 2. Fix 1: the room listening (Cameron's point 3)

| # | Behavior |
|---|---|
| 1a | **Icons every turn.** Each organization that matters this turn sits in the unused space of the battle screen: the current question's concerned organizations, those it sets back, and the level's bill stakeholders (Section 4). Each has a small "with you" or "against you" pin when a stance is set. Exact placement is chosen from screenshots at 9:16, 9:19.5 and tablet widths, so the hand and End Turn stay where they are. |
| 1b | **Preview on pick-up.** When a card is dragged up, or tapped once, each icon shows the change that card would make, as **+N** over a translucent green wash, **−N** over red, or **0** over gray. The number is the same banded, capped and stance-adjusted number that lands at the end of the stage, so the preview never lies. |
| 1c | **Tap changes.** First tap selects the card and shows the preview. A second tap on the same card, or a **Read** button that appears on a selected card, opens the zoom. Drag-to-play is unchanged. A tap elsewhere clears the selection. |
| 1d | **Live ticks.** When the card is played, its numbers float up off the icons and the running total stays on each icon for the rest of the stage. |
| 1e | **Card zoom wording** names the organizations: "A strong answer. Labor Federation will like this." |

Risk to note: tapping a card no longer opens the zoom at once. The click tests (`click_test`, `mash_test`) change with it.

## 3. Fix 2: a backing reveals style tastes

Organizations already have measurable style tastes (`BoosterSuitTendency`, the How to Play suit table). Owning any backing linked to an organization shows its liked and disliked suits on its icon (two suit marks up, one down). Later options: a hired Policy Research Assistant reveals tastes for everyone in the room; or a true style-affinity rule (new **Likes Suits / Dislikes Suits** columns, where a liked suit pleases even with no question). Hold the second until the first has been played.

## 4. Fix 3: the bill through-line

### 4.1 Proponent and stakeholders

| Piece | Source | Shown where |
|---|---|---|
| **Proponent party** | New Floor Vote Bills column **Proponent Party** (PTxx). A draft for all 50 bills can be derived from the Party Positions tab (the Supportive party with the highest salience), for Cameron to correct. | Level Intro ("The Yezo Heritage Party's bill"), the briefing, the vote screen header. |
| **Your party's stance** | Already in Party Positions (Supportive / Opposed / Neutral). | Level Intro, before the lean: "Your party (Country Initiative) opposes it." |
| **Supporters and opponents** | Derived from the bill's Passed Law Effects row (helped = supporters, hurt = opponents, Party Bodies left out); an optional **Stakeholders Override** cell where the row reads oddly. | Pins in Fix 1, the briefing, the vote preview. |

### 4.2 The four beats

| Beat | Rule | Starting number (Balance lever) |
|---|---|---|
| **Lean** | Saved for the level. Party support moves as today. Lean Support puts you with the bill's supporters; Lean Oppose with its opponents. | as today, 2 |
| **Stage rhetoric** | An answer that would please the *other side's* stakeholder pleases it at half (rounded down). Setting one back lands in full. Your own side is unchanged. | `stance_other_side_please_factor` 0.5 |
| **Stage success** | Each stage of the level you **win** moves the other side's stakeholders down and your side's up. A loss moves nothing. | `stance_win_drift` 2 |
| **Final vote** | Your vote moves stakeholders on top of the Law Effects: **Aye** Supporters +2, Opponents −2; **Nay** the reverse; **Abstain** nothing. If your vote **contradicts your lean**, the side you now vote with recovers **at most 25% of what the stages cost it this level, rounded down**, and Party support pays 1. | `vote_stakeholder_delta` 2, `flip_flop_recovery_percent` **25**, `flip_flop_party_cost` 1 |

The recovery share is a single lever, so a later backing or staff rank can raise it (for example a new modifier Effect Type, `FLIP_FLOP_RECOVERY_BONUS`, adding percentage points). Not built now.

### 4.3 The Ainu example (BI01, Country Initiative, Lean Oppose, three stage wins, then Aye)

| Moment | Ainu groups (Supporters) | Our Traditional Society, Chamber (Opponents) |
|---|---|---|
| Three stage wins | −6 each, and Ainu-pleasing answers count at half | +6 each |
| Switches to Aye | +2 for the vote, +1 recovered (25% of 6 = 1.5, rounded down) = **+3** | −2 |
| Net for the level | **−3**: a small recovery, most of the damage stays | **+4** |
| Party support | +2 lean, −1 for switching | |

Then the Law Effects apply to the bill's actual outcome, as now.

## 5. Fix 4: bill content in every bill level (Cameron's points 1 and 2b)

### 5.1 Why not one new room per bill

Content is keyed by room (Stage ID), and 21 rooms are shared by several levels, so ST05 cannot carry the Ainu bill's questions without them appearing in unrelated levels. Batch 3 solved this for 20 bills by building 69 new topic rooms. Doing the same for LV31-LV60 would mean about 100 more rooms, backgrounds and transition rows.

### 5.2 Recommended: content scoped to a bill

Add an optional **Bill ID** column to Stage Questions, Player Cues, Opponent Cues and Transition Dialogue. A row with a Bill ID applies to every stage of the level that votes on that bill, in any room, and is dealt first, the same way stage-scoped content is today. LV31 keeps its rooms and gains Ainu questions and lines. This is a code change of about 80 lines (lookups and the exporter) and no new rooms.

### 5.3 Matching the player's direction

| What | Needs a direction? | How |
|---|---|---|
| **Questions** | No. A question asks you to defend a position ("Who should pay for Ainu classes?"); the style grade decides strong or weak, not the stance. Your stance is applied mechanically (Section 4.2). | One set per bill |
| **Opponent cues** | Mostly no: an opponent is against you whichever way you lean. | One set per bill |
| **Player cues** | **Yes.** What you say should match your lean. | New optional **Stance** column (Support / Oppose / blank = either). Each bill gets a Support set and an Oppose set. |
| **Transitions, Level Intro thought** | Partly: staff and thoughts can react to the lean. | The same Stance column on Transition Dialogue and Level Intro Thoughts. |

### 5.4 Question 2b: does an inverse bill (twin) ease this?

| | Stance tag (recommended) | Inverse twin bills |
|---|---|---|
| Levels | Same 50 | Up to 100 |
| Questions, opponent cues | One set per bill | One set per twin (double) |
| Player cues | Two sets per bill (Support, Oppose) | One set per twin, but the player can still lean either way on each twin, so both directions are still needed: no saving |
| Rooms, transitions, Law Effects, party positions, influence cues | Unchanged | All doubled |
| Proponent clarity | From the new Proponent Party column | Very clear (each twin has its own proponent) |
| Best use | Every bill | Selected bills where the inverse is a real, different policy with a different proponent (for example "Ban public funds for Ainu classes in traditional schools", sponsored by Country Initiative), as extra variety later |

**Answer: no.** A twin does not remove the need to write lines in both directions, because the player can lean either way on either twin, and it doubles everything else. Twins help proponent clarity and variety, not workload.

### 5.5 Content estimate (draft batch, built and evaluated outside the master workbook)

| Per bill | Count | All 50 bills |
|---|---|---|
| Bill Stage Questions (enough for the 3x depth rule across a level's rooms) | 10 | 300 for LV31-LV60; LV63-LV82 already have 6 each, top up 4 = 80 |
| Player Cue rows (6 suits × Support and Oppose, any verb) | 12 | 600 |
| Opponent Cue rows (bill-scoped, by suit) | 6 | 300 |
| Transition and Level Intro thought lines, by stance | 4 | 200 |

## 6. Build plan

| Step | Work | Size | Needs from Cameron |
|---|---|---|---|
| 1 | Fix 1: icons, pick-up preview, tap-to-select / Read, live ticks; click tests updated; screenshots at three aspect ratios | ~250 lines | OK on behavior; review of the screenshots |
| 2 | Fix 2: backing reveals tastes | ~60 lines | OK |
| 3 | Schema: Proponent Party, Bill ID scope, Stance columns; exporter checks; header notes; draft Proponent for all 50 bills | ~120 lines | OK on the three columns; correct the draft proponents |
| 4 | Fix 3 rules in a pure `BillStance.gd` (saved lean, stakeholders, rhetoric factor, win drift, vote, 25% recovery), with tests | ~200 lines | OK on rules and numbers |
| 5 | Fix 3 display: Level Intro proponent and stance lines, briefing, vote preview, Your Record causes | ~100 lines + Text rows | — |
| 6 | Content batch: bill-scoped questions and stance-tagged lines for all 50 bills, as a draft workbook | content | Review of the draft |

Each step is its own commit with tests, `verify.sh`, and a stage-trial check that win rates did not move much.

## 7. Decisions for Cameron

| # | Decision | Recommendation |
|---|---|---|
| 1 | Fix 1 as described, including tap-to-select with a second tap or Read to open the zoom | Yes |
| 2 | Fix 2a: owning a backing reveals that organization's style tastes | Yes |
| 3 | New column **Proponent Party** on Floor Vote Bills, drafted from Party Positions | Yes |
| 4 | New optional **Bill ID** scope on Stage Questions, Player Cues, Opponent Cues and Transition Dialogue (instead of ~100 new rooms) | Yes |
| 5 | New optional **Stance** column on Player Cues, Transition Dialogue and Level Intro Thoughts | Yes |
| 6 | Inverse twin bills | Not now; later for selected bills as variety |
| 7 | The four beats with starting numbers: half pleasing for the other side, ±2 per stage win, ±2 for your vote, recovery at most 25% rounded down, −1 Party support for switching | Accept as drafts |
| 8 | A future modifier type that raises the recovery percentage | Note for later |
