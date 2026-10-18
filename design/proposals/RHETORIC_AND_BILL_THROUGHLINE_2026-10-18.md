# Rhetoric, organizations and the bill through-line: review and proposal (2026-10-18)

Nothing here is built. It reviews how card plays, questions, organizations and parties connect today, and proposes changes for Cameron to approve, change or reject.

## Executive summary

| | |
|---|---|
| **Problem 1: the link is real but hidden** | A card only affects organizations through the question in front of you. The player sees which organizations care only in the Details panel, and what changed only on the end-of-stage Outcome panel. The hand never shows who is listening or which cards they like. |
| **Problem 2: the bill story breaks in three places** | The Lean Support / Lean Oppose choice moves Party support once and is then forgotten. The 30 original bill levels (LV31-LV60) play generic rooms that never mention the bill. At the vote, the law's effects on organizations ignore how *you* voted. |
| **Fix 1 (mostly display, no new data)** | A "Listening" strip on the battle screen, a strong/weak badge on each card in hand, and standing changes shown the moment a card answers. |
| **Fix 2 (the booster bonus Cameron asked for)** | Owning an organization's backing reveals which rhetorical styles that organization likes, shown on its icon in the strip. |
| **Fix 3 (the through-line)** | Remember the lean for the whole level. Treat the bill's winners and losers (already in the Law Effects tab) as the level's stakeholders. Your stance colors how they hear you in every stage, your own final vote moves them, and switching your vote earns a modest recovery. |
| **Content gap** | LV31-LV60 need topic questions for their bills, as LV63-LV82 already have. This is a content batch, not code. |
| **Schema changes** | None required. All three fixes derive from data that already exists. One optional column (explicit bill stakeholders) is offered as an override. |

## 1. How it works today

| Link | What happens now | What the player sees |
|---|---|---|
| Card → question | The card's suit is graded S/M/W against the question. Strong multiplies the card by 1.3, Weak by 0.7. | The card zoom says "strong / medium / weak answer". The hand shows nothing. |
| Question → organizations | The question's theme names who it pleases and who a strong answer sets back (Question Themes tab). Every answer is counted, then banded and capped per stage. | The Details panel lists "This question is about: …". Nothing on the main screen. |
| Organizations → result | Standing moves when the stage ends (`finish_stage`). | Icons on the Outcome panel, then Important Stakeholders in the Office. |
| A card with no question | Never touches an organization. | Nothing. |
| Lean Support / Oppose | Party support ± `lean_party_support_delta` (2), against your own party's disposition on the bill. Not saved. | One line on the Level Intro screen. |
| Bill level stages | LV63-LV82 play topic rooms with bill questions. LV31-LV60 play generic rooms (LV31, the Ainu Heritage and Language Act, is Office Hours, Town Hall, a committee and a caucus with no Ainu questions). | Nothing ties the stage to the bill. |
| Final vote → organizations | The Law Effects row for Passed or Failed applies **whatever you voted**. Party Bodies follow your party's disposition. | Law pop-up in Your Record. |
| Final vote → parties | Each party's favorability moves by its own disposition, scaled by salience. Your vote moves one seat. | The vote result panel. |

**The Ainu example today** (Country Initiative is Opposed to BI01): Lean Oppose gives +2 Party support. Nothing in the stages is about Ainu rights, so the Ainu groups hear nothing from you. If the bill fails, the Ainu groups lose 1 each whatever you voted. Voting Aye to change course changes nothing for them.

## 2. Fix 1: make listening visible (display only)

| # | Change | Data it uses | Size |
|---|---|---|---|
| 1a | **Listening strip.** A row of small organization icons under the support bar: who the current question concerns (party-colored edge) and who a strong answer sets back (red edge). Tap an icon for its name and current standing. | `pleases_boosters`, `displeases_boosters` on the current question | Small |
| 1b | **Hand badges.** Each card in hand gets a small gold up arrow (strong for this question), nothing (medium) or a red down arrow (weak). Refreshed when the question changes. | `BattleEngine.question_multiplier_for(card)`, already used by the zoom | Small |
| 1c | **Live ticks.** When a card answers, a "+3" or "−2" floats off the matching icon in the strip, using the same banded number the Outcome panel shows. | `BoosterChange.compute()` on the running tally | Small to medium |
| 1d | **Wording.** The card zoom's strong line names who it pleases: "A strong answer. Labor Federation will like this." | Same as 1a | Tiny (Text rows) |

## 3. Fix 2: a booster bonus that reveals rhetorical styles

Organizations already have real style tastes, measured from the questions that please them (`BoosterSuitTendency`, the How to Play suit table). They are just never shown in battle.

| Option | How it works | Schema | Recommendation |
|---|---|---|---|
| **2a. Backing reveals tastes** | Owning any backing linked to an organization reveals its liked (and disliked) suits on its icon in the Listening strip: two suit glyphs up, one down. | None | **Recommended.** It gives backings a second reason to exist and teaches the player by play. |
| 2b. Staff reveals tastes | A hired Policy Research Assistant at Rank 1+ reveals tastes for every organization in the strip. | None | Good as a later add, so a player without backings can still learn. |
| 2c. Real style affinity | New Boosters tab columns **Likes Suits** / **Dislikes Suits**. Playing a liked suit while that organization is listening pleases +1, even with no question. | Two new columns | Strongest card → organization link, but a new mechanic. Hold until 2a is played. |

## 4. Fix 3: the bill through-line

### 4.1 Who the bill's stakeholders are

Derived, no new data: an organization the bill's **Passed** Law Effects row helps is a **Supporter**, one it hurts is an **Opponent**. Party Bodies are left out because they already follow your party. For BI01 that gives Supporters BO28 Ainu Community Council and BO29 Ainu Language and Culture Foundation, and Opponents BO05 Chamber of Commerce and BO15 Our Traditional Society.

An optional Floor Vote Bills column **Stakeholders Override** (e.g. `BO28+; BO29+; BO15-`) can replace the derived list where the Law Effects row reads oddly.

### 4.2 The four beats

| Beat | Rule | Default numbers (Balance levers) |
|---|---|---|
| **Lean** | The lean is saved for the level (`GameState.level_lean`). Party support moves as today. | as today (2) |
| **Stage rhetoric** | While a stance is set, an answer that would please one of the *other side's* stakeholders pleases it at half (rounded down, can reach 0). An answer that sets one back sets it back in full. Answers pleasing your own side's stakeholders are unchanged. | `stance_other_side_please_factor` 0.5 |
| **Stage success** | Each stage of the level you **win** moves the other side's stakeholders down and your side's up. A loss moves nothing. | `stance_win_drift` 2 (−2 / +2) |
| **Final vote** | Your own vote now moves stakeholders, on top of the Law Effects: **Aye** gives Supporters +2 and Opponents −2, **Nay** the reverse, **Abstain** nothing. If your vote **contradicts your lean**, Supporters of your vote also recover half of what the stage drift took from them this level (capped at that amount), and Party support pays `flip_flop_party_cost` (1). | `vote_stakeholder_delta` 2, `flip_flop_recovery_share` 50%, `flip_flop_party_cost` 1 |

### 4.3 The Ainu example under this rule

Country Initiative member, Lean Oppose on BI01, wins three stages, then votes Aye:

| Moment | BO28/BO29 (Supporters) | BO15/BO05 (Opponents) |
|---|---|---|
| 3 stage wins | −6 each (−2 × 3), and any Ainu-pleasing answers counted at half | +6 each |
| Votes Aye (switch) | +2 for the vote, +3 recovered (half of 6) = **+5** | −2 |
| Net for the level | **−1**: a modest recovery, not erased | **+4** |
| Party support | +2 lean, −1 flip-flop | |

Then the Law Effects apply to the bill's actual outcome as they do today.

### 4.4 Showing it

| Where | What it says |
|---|---|
| Level Intro, after the lean | "Your stance: Oppose. The Ainu Community Council and Ainu Language and Culture Foundation will hear you as an opponent. Our Traditional Society and the Chamber of Commerce are with you." |
| Level briefing / battle Details | One line: "Stance: Oppose · With you: … · Against you: …". The Listening strip marks stakeholders with a small "with" / "against" pin. |
| Vote screen, before voting | Preview line per choice: "Aye: Ainu groups +5 (switching your stance), Our Traditional Society −2." |
| Your Record | The cause line names the stance: "Ainu Community Council (−1) because of your stance on the Ainu Heritage and Language Act, your vote". |

### 4.5 Other parties (optional)

The lean could also nudge every other party's direct opinion by its own disposition (±1, salience-scaled), so a player hears early that Yezo Heritage Party disapproves of an Oppose. Today only your own party reacts to the lean. Recommended off at first (`lean_other_parties_delta` 0).

## 5. Content gap: topic questions for LV31-LV60

20 bill levels (LV63-LV82) have topic rooms. **30 (LV31-LV60) play only generic rooms**, so their stage rhetoric is never about the bill and Fix 3's rhetoric rule has nothing to work on there. The remedy is a content batch: about 4 Stage Questions per bill scoped to that level's existing rooms (a level's rooms are shared with other levels, so these would be new topic room variants, as Batch 3 did). This would be about 120 questions plus room rows. It is a draft batch like the earlier ones, built and evaluated outside the master workbook.

## 6. Build plan

| Step | Work | New code | Needs from Cameron |
|---|---|---|---|
| 1 | Fix 1 (strip, badges, live ticks, wording) | ~150 lines + Text rows | OK on the look |
| 2 | Fix 2a (backing reveals tastes) | ~60 lines | OK |
| 3 | Fix 3 rules (lean saved, stakeholders derived, rhetoric factor, win drift, vote and flip-flop) in a pure `BillStance.gd`, with tests | ~200 lines | OK on the rules and starting numbers |
| 4 | Fix 3 display (intro line, briefing, vote preview, Record causes) | ~100 lines + Text rows | — |
| 5 | Content: topic questions for LV31-LV60 | draft workbook | Review of the draft |

Each step is its own commit with tests, `verify.sh`, and a stage-trial check that win rates did not move much (the rhetoric rule only changes standing, not the bar).

## 7. Decisions for Cameron

| # | Decision | Recommendation |
|---|---|---|
| 1 | Build Fix 1 (Listening strip, hand badges, live ticks)? | Yes |
| 2 | Which reveal: 2a backings, 2b staff, 2c real style affinity? | 2a now, 2b later, hold 2c |
| 3 | Bill stakeholders derived from the Passed Law Effects row, with an optional override column? | Yes |
| 4 | The four beats and their starting numbers (half-pleasing, ±2 per win, ±2 for the vote, 50% flip-flop recovery, −1 Party support for a flip-flop) | Accept as drafts |
| 5 | Should the lean also nudge other parties (4.5)? | Off at first |
| 6 | Commission the LV31-LV60 topic-question content batch? | Yes, after steps 1-4 |
