# Coliseum of Parliament: change log

What changed and why, newest last. **Everything before 2026-11-01 is summarized in the next section** (2026-11-06, Cameron's instruction); the full original text of those September and October entries is in git history: `git show 05b615e:design/CHANGELOG.md` (and the old index of every entry is in `git show 05b615e:CLAUDE.md`, section 15). For how the game works today, read `design/GAME_SYSTEMS.md`, not this file: this file is the record of how it got there.

Each entry says what was built, why, and how it was checked. Add a new `##` section at the end for every change, with a one-line entry in `CLAUDE.md` section 15.

---

## Summary: September and October 2026

### How the build went

| Dates | What happened |
|---|---|
| 09-21 to 09-28 | **The first playable game.** Data pipeline and rules engine; the battle screen; Office Hours; the Office, level runner and saving; XP and the shop; the four meta numbers and their crisis triggers; National Assembly Floor Voting; the Level Intro; cosmetics; mobile playtest fixes and a code stress test |
| 09-29 to 10-06 | **Making it hold together.** Standing rules and question grading, Your Record, the Staff Profile, Rhetoric Training as the only way to gain cards, the random opening deck, a How to Play guide, the Office menus, stage transitions (10-01) |
| 10-07 to 10-17 | **Bots, balance and polish.** A playtest bot and stage trials, committee retuning, party opinion, the legislation plan (suit and stage cues, the statute book, law effects), organization content, workbook batches adding twenty bills (BI31-BI50) with their rooms and levels, interface passes (wrapping, safe areas, text size, button outlines), terminology passes |
| 10-18 to 10-20 | **A through-line from rhetoric to bills.** The game clock; special levels; bill stance (lean, drift, vote); bill-specific rooms for every bill level; opponents sounding different per style; **Patron Bills** (organizations ask you to carry a bill), influence building (member visit, lobbyist trade, whipping), Draft a Bill, the component system |
| 10-21 to 10-30 | **The week.** Calendar in hours, party dues, name awareness, election strength; events (arranged, random, dated, hosted); district outings; seasons; outside scenes; image scroll and pan; the level briefing template; the content guide |
| 10-31 | **Commitments.** Choices cost what they promise; promises with deadlines; follow-up events; regional goods; events that start a level; the choice-honesty rewrite of all 452 choice sets; a mechanics audit |

### What exists, by area (and where to read about it now)

| Area | What the September and October builds put in place | Read now |
|---|---|---|
| **Data pipeline** | The workbook is the source of truth; `tools/export_data.py` writes `data/*.json` and checks cross-references and wording in both directions; `wbx.py` edits the workbook without corrupting it; a Text tab holds every sentence; a Balance tab holds every design number (`Levers`, `test_balance_keys.gd`); `tools/verify.sh` is the full gate; `content_depth.py` enforces the three-times rule | `ARCHITECTURE.md`, `CONTENT_GUIDE.md` |
| **Battle rules** | Intent-pattern opponents shown a turn ahead; guard as a bank (cap 5); the cost of winning people over (1, or 1/2/3 by roll, per person); suit affinity per room; question grading (strong 1.3x, weak 0.7x); shared-pool, single and survival bars; committees that reset between opponents; town halls that carry gaffes; a rising TV-debate line; instant loss when your own support hits zero; discard cards; special-effect cards | `GAME_SYSTEMS.md` section 7 |
| **Standing** | Organization standing (every answer counts, gains harder as it rises, caps, neglect and percent decay, links between organizations), backings gated by standing, party opinion blended from a direct number and the organizations tied to each party, party salience per bill, Your Record explaining why each number moved | `GAME_SYSTEMS.md` sections 4 and 6 |
| **The four numbers and crises** | Constituency support, Reputation, Funds (a cap of 100,000円 raised by petitions) and Party support, with Town Hall at 15 or below, the Steering Committee check-in below 25, a funding freeze at 0, a free backing above 75, and a one-time penalty at 50 lifetime gaffes. The Party-support-below-50 penalty and the Jiban-triggered freeze were removed or redesigned | `GAME_SYSTEMS.md` section 6 |
| **Cards, deck and shop** | 70 cards in four tiers; a fixed-size deck; a random 15-card opening deck; Rhetoric Training (see the card before paying, up to three looks) as the only source of new cards; the Marketplace with stage, level and timed item buffs, regional gifts, hosted dinners and tours; deck expansion; the Training Session Coupon | `GAME_SYSTEMS.md` section 4.3 |
| **People** | Three staff roles with ranks, firing and a profile screen; a seating draw that leans toward people you have met least; committees, the Cabinet and the caucus seating only who belongs | `GAME_SYSTEMS.md` section 4.3 |
| **Floor Votes and laws** | One Aye/Nay/Abstain choice on one bill; a bill needs a majority of the whole house (abstentions count against it); supermajority bills; party favorability; the influence swing behind a gate; whipping; the statute book and Law Effects (once or every level); every organization has a stake; the bill-lean through-line | `GAME_SYSTEMS.md` section 8 |
| **Bills beyond the 50** | Patron Bills (Favor and Flagship requests from organizations), 180 bill components, the patron visit, the member visit and the lobbyist trade, Draft a Bill, the component questions, lobbyist voices | `GAME_SYSTEMS.md` section 8 |
| **Time and money** | A game clock, then a calendar in hours (40-hour work week, optional 8-hour weekend), party dues, decay at the week end, awareness meters and their effects, election strength | `GAME_SYSTEMS.md` sections 3 and 4 |
| **Events and choices** | Buyable, random, dated, follow-up and hosted events; event-only levels; district outings; a Decline on random events; commitments (hours, Funds, items) and promises with deadlines; choice honesty | `GAME_SYSTEMS.md` sections 5 and 6, `CONTENT_GUIDE.md` section 9 |
| **Content** | 50 bills with bill-specific rooms, cues, questions, transitions, visitors and level intros; opponents sounding different in each style; a question set for every organization (at least 15 each); 101 levels; 56 events; 166 visitors | `CONTENT_GUIDE.md` |
| **Interface** | The Office and its menus; How to Play; Your Record; organization chips; the briefing template; the cue banner; stage transitions; Level Intro; text-size setting; safe areas and wrapping everywhere; button outlines; soft picture edges; Image Scroll and Image Pan; cosmetics (outfit, Office background, music, calendar style) | `INFORMATION_STANDARDS.md`, `ARCHITECTURE.md` |
| **Language** | Two terminology passes: Constituency support, Reputation, Funds (円), Party support, Aye/Nay, Threshold, Staff Rank, American spelling | `INFORMATION_STANDARDS.md` section 2 |
| **Testing and balance** | A playtest bot with stage trials; balance audits that retuned committees and rewards; unit and real-click tests for the rules and every screen; a compile check of every script; fixes to several memory leaks | `ARCHITECTURE.md` section 7 |

### Retired, so nobody revives it

| What | Replaced by |
|---|---|
| The Yoron (public-opinion) topic list, `bills.json` and bill difficulty (2026-09-26) | Nothing; Floor Votes and standing carry the political layer |
| A per-member "lean and lock" committee model (2026-09-25) | Committees are ordinary sequential battles with a reset between opponents |
| Buying cards directly with XP (2026-09-27) | Rhetoric Training |
| The funding freeze at Constituency support 0 (2026-09-25) | The freeze at Party support 0 |
| The Party-support-below-50 "Cold Shoulder" backing, M10, whose discount nothing applied (2026-10-11) | Nothing |
| A cooldown counted in other levels played, and decay at the end of every level (2026-10-18) | Cooldowns in clock units; decay once a week |
| A ten-organization model and "this sitting only" standing | 32 organizations, saved with the run |

### Decisions that still shape the work

- **Add content, never mechanics.** A new room, level or event is workbook rows built like the nearest existing one; anything needing code is proposed first.
- **Draft, label, never decide canon.** Names, parties, committees, places and political positions come only from the data; Claude's writing is always a draft.
- **Numbers and sentences are data.** A design number is a Balance row; a sentence is a Text row; the exporter and tests enforce it.
- **Structured columns are the truth**; when text and a column disagree, the text changes.
- **No deletion without Cameron's say-so**; candidates are listed in `design/CLEANUP_CANDIDATES.md`.
- **Three-times rule:** every room holds at least three times the content a run meets.
- **Choices are honest and costs are real**: nothing is promised that is not charged, and no option is the only thoughtful one.

---

## Changes since 2026-11-01

## Playtest notes: bigger transition portraits, a clearer stage Details panel, a deck expansion (2026-11-01, Cameron)

| # | Note | Change |
|---|---|---|
| 1 | Transition portraits too small | The portrait box on the Stage Transition screen grew from 420 to 1480 px tall. The player's and the speaker's portraits each take about half the width, matching Cameron's outlines. The scene and `tools/build_stage_transition_scene.gd` were changed together. |
| 2 | Stage Details panel | "With you" and "Against you" are gone, along with the three question lines ("This question is about...", "A strong answer pleases...", "...sets back..."). A new heading, **Applying Scrutiny This Turn:**, shows the same organizations as the stage screen's listening strip (`BattleScreen._scrutiny_ids()`, shared by both). The Turns and Win lines open the Room rules section. "Gaffes 7 = loss" now reads **"Gaffe out at 7"**. The gaffe and energy figures in that line are the live numbers, so an item that raises either one shows. New Text row `battle.scrutiny_heading`; `brief.stat.gaffes` and `brief.stat.gaffes_multiplied` reworded. |
| 4 | A Marketplace item that grows the deck | **SH34 Expanded Briefing Binder** (200 XP, draft) permanently adds one card slot, filled at once with an owned card not already in the deck. It can be bought at most five times (Balance **Deck Expansion: Maximum Purchases**), then leaves the Marketplace. It is refused when there is no spare card to add. New Shop column **Deck Size Increase** (with a header note); `GameState.deck_balance()`, `deck_size()` and `buy_deck_expansion()`; `deck_size_bonus` and `deck_expansions` are saved. Tests: `test_inventory.gd`. Icon `deck_expansion` is not drawn yet. |

Not used any more (for a cleanup pass): `BattleScreen._question_concerns_lines()` and the Text rows behind it, and `battle.nobody_pleased`.

## Bill-room replies fit the question (2026-11-01, Cameron)

Playtest note 3: in a bill room the player's spoken line came from a short list of the bill's own slogans, whatever the opponent had just asked, which read as a non-answer. Now the reply is written for the **kind** of question asked. Full analysis: `design/review/BILL_REPLIES_ANALYSIS_2026-11-01.md`.

| Change | Detail |
|---|---|
| Stage Questions: new column **Reply Kind** (O) | Cost, Evidence, Oversight, Risk, Impact, Alternative, Party, Voters, Criticism or Principle. All 2,539 rows pre-filled by a word-matching draft; Principle is the catch-all. The 589 questions bill rooms ask split 188 Principle, 93 Cost, 66 Party, 54 Voters, 47 Impact, 34 Alternative, 33 Oversight, 31 Criticism, 30 Risk, 13 Evidence. |
| Player Cues: new column **Reply Kind** (M) | A row with one is a reply line for any bill room, written with `{bill}` / `{Bill}` in place of the name. 180 new rows (PL3517-PL3696), 480 lines: every kind × every style × Support (3 lines), Oppose (3) and no lean (2). Each style keeps its own move: Earnest admits the trade-off, Emotional answers through people, Appeal invites, Data Driven gives a measure, Divisive turns it on the other side, Duplicitous commits to nothing. Claude's drafts. |
| Balance: **Player Cues: Full Bill Name Chance** (25) | The bill's full name appears on about a quarter of reply lines; the rest say "the Act" or "the bill" ("the Agreement" for the two agreements). |
| Code | `CardCues.for_card()` takes the question's Reply Kind and tries a reply line first (lean, then no-lean lines), then the bill's own lines as before. `CardCues.fill_bill()` puts the name in. `DataDB.get_reply_player_cue_lines()`. `BattleScreen` passes `engine.turn_question()`'s kind. |
| Exporter | Checks that a reply line's kind is one Stage Questions uses, that it names no Bill ID, and warns when a kind asked has no reply. |
| Tests | `test_player_cues.gd`: reply before bill lines, lean and no-lean, never outside a bill room, the 25% full-name share, and every kind asked has lines in every style and lean. |

The bill's own slogans stay as the fallback for room-pool questions (press, town hall), which have no Reply Kind column yet.

## Every ticker line names an outlet (2026-11-01, Cameron)

The Office news ticker now names one of the seven canonical outlets in every line: Yezo Political Insider, Sapporo Broadcasting Center, Sapporo Digital Networks, Otaru Radio 今日, Aomori's Morning Mori, Yezo News Nightly and 青森の青空109.9!. 109 lines were rewritten in the Office Ticker tab: the 100 bill-result lines (TK44-TK143, eight templates, each with a fixed outlet) and nine others (TK144-146, TK150-155). "Yezo News" became "Yezo News Nightly". New lines use the unquoted format: outlet named in the text, then " - ☼". TK152 lost its "Single-day template:" prefix and TK155's "Monday's" became "Mondays". All of it is Claude's draft for Cameron to rewrite.

## Open Debate: committees run out of questions, and now say so (2026-11-02, Cameron)

**What was happening.** A room deals its questions once, when the stage starts, and deals `turn_limit` of them (one a turn). That matches every room except a **committee** (`sequence_mode: reset`): each new opponent restarts the clock at turn 1, but the questions are not dealt again. So the whole committee shares one queue of 7 or 10 questions. Measured on all 381 combat stage slots in the levels: every other room asks exactly as many questions as it has turns; the 84 committee-style stages (130 of the 381 slots: ST01, ST10-ST18, the hearings and the bill-specific committees) have 2 to 4 opponents and so 14 to 40 turns for 7 or 10 questions. Opponent one gets the questions; whichever opponent comes after the last one is argued with no question, no listening organizations and no strong or weak answers, with no word about it. (ST271 Radio Debate is different: it has no question pool at all, so it never asks anything.)

**What changed.**
- `BattleEngine.in_open_debate()`: true when the room dealt questions, has asked them all, the stage goes on, and no turn is half answered.
- The **Open Debate!** popup: the CueBanner gets a third side, `PHASE`, a gold unslanted band with a "New phase" tag, the big line and a detail line naming whoever is in front of you. It shows once per stage, at the start of the first turn with no question (including when a card beats an opponent and the next one begins already out of questions). It queues behind the player's own line and a tap skips it, like every other banner. Text rows: `battle.open_debate.tag`, `.title`, `.detail` (drafts for Cameron to reword).
- Tests: `test_questions.gd` (five open-debate cases) and `test_cue_banner.gd` (the phase band).

**Not changed.** The rule that committees deal one shared queue. Whether each committee opponent should get fresh questions is Cameron's call.

## The next opponent stepping up gets its own popup (2026-11-02, Cameron)

When a card or the clock finished an opponent, the card's outcome line began "X is finished — Y rises" and the announcement was lost in it. It now has its own gold PHASE popup (the one made for Open Debate): tag "Next up", line "{next} steps up!", detail "{who} is finished." It shows after the card's own line (or after the opponent's move, when the clock ended the bout) and before the Open Debate popup if both apply. The card's outcome line no longer mentions the handover. Beating the last opponent is unchanged: there is nobody to step up, so "X is finished" stays in the outcome line. Text rows `battle.next_up.tag`, `.title`, `.detail` (drafts). `test_battle_narration.gd` follows.

## Stage transitions reviewed: who speaks, repeats, the Floor Vote (2026-11-02, Cameron)

Reviewed against §7.9 by simulating every transition in all 101 levels (396 stage-to-stage handoffs). What was found, and what was done:

| Finding | Before | Change |
|---|---|---|
| Only 6 of 21 staff candidates had transition lines | Hiring any of SF03-07, SF10-14, SF17-21 meant your staff never spoke | All 15 added to Transition Cast (any stage) with 12 general lines each (180 rows, TD2084-TD2263), written from each person's biography. Drafts for Cameron to rewrite; bill-specific lines for them are not written, so they fall back to general lines in bill levels. |
| Staff drowned out the opponent | With staff hired they spoke in 72-80% of transitions | Balance **Transition: Staff Speaker Chance** (50): when both a hired staff member and a cast opponent could speak, the chance it is staff. Staff still always speak where no opponent is cast (55 stages) |
| Repeats | The same speaker twice running in 8% of consecutive transitions; no memory of lines heard | The speaker is not the one who spoke last, and a line is not one already heard this level, whenever anything else will do (`GameState.transition_memory`, cleared when a level begins). Back-to-back speakers went to 0; line repeats are now only opponents who have a single line written |
| Bill levels often said nothing about the bill | Opponents have no bill lines, so only the player's thought carried the bill (about half of bill-level transitions) | Balance **Transition: Bill Level Thought Chance** (60) replaces the flat 30% in levels about a bill |
| The Floor Vote had no transition | None of the 50 bill levels paused before the vote (ST23's Show Transition was blank) | ST23 Show Transition = Yes: handoffs with a transition went from 326 to 376 of 396. With nobody cast it is a staff member or the player's thought; who else speaks there is Cameron's call |
| Name label | Centered across the screen, so it read as the player's name | Sits under the speaker's own portrait |

`StageTransition.pick_speakers()` and `resolve()` take `staff_chance` and `avoid` (both optional); the speaker record carries a `line_key`. Eight of the new media lines were reworded because the every-room rule (`test_generic_transition_lines_fit_every_room`) bans press words in lines that fit any stage. Tests: `test_stage_transition.gd` (staff chance, last speaker, heard lines, heard thoughts, all 21 staff can speak, ST23 shows one).

**Left as it was (decisions for Cameron):** every transition happens over the Office picture in 83% of cases (Keep Office, Cameron); 53 of 56 cast opponents have no drawn picture, so the speaker is a blank box; each cast opponent has exactly one line per stage, so the same line returns every time the stage is played; four Office Hours handoffs and the Media Ambush rooms have no transition (Media Ambush by design); Transition Speaker Count is 1 everywhere.

## Party leaders speak before the Floor Vote (2026-11-02, Cameron)

Cameron pointed to the Opponents tab's Title column, where some people hold several titles separated by "; ", party leader among them. Six rows read "Leader of the ...": OP10 Aki Rono (Prime Minister; Yezo Heritage Party), OP27 Ichizaki Namu (President and Speaker of the National Assembly; Frontier Party), OP67 Okabe Hideriai (Country Initiative), OP80 Soma Umehori (Five Point Independents), OP83 Teinei Macmillan (Keizaijiyuutou), OP91 Utemaru Naizen (Minister of Ethics and Prosecution; Butsutou). They match Parties' Leader Opp ID exactly, so nobody needed deciding.

- **Cast at ST23.** The six are in Transition Cast for ST23, each with four lines for the eve of a vote (24 rows, TD2264-TD2287), neutral about how anyone votes since that depends on the bill. OP10 and OP83 had no transition lines before; OP27 and OP80 had one. Drafts for Cameron to rewrite.
- **Party leader title kept.** `OpponentDisplay.title_for()` still shows only the first title (so Naizen reads "Minister of Ethics and Prosecution" in battle). New `OpponentDisplay.party_leader_title()` finds the "Leader of ..." part, and the name under a speaker on the transition screen uses it ("Ichizaki Namu, Leader of the Frontier Party").
- Tests in `test_stage_transition.gd`: the title is found among several, and every party's leader is cast at ST23 with at least four lines.

None of the six leaders has a drawn picture yet except as a placeholder.

## Transitions: locked opponents, two speakers, more lines, ST30 tidied (2026-11-02, Cameron)

| Request | What was done |
|---|---|
| ST30's two dialogue rows and one background | The rows (TD31 "Cameras are waiting at the dock...", TD32 "They will ask about labels...") are staff lines about the seafood-labeling level; they moved to ST29, the Town Hall at the Harbor in the same level (LV62). The background (TB08, the Media Ambush room picture) was deleted: only Media Ambush rooms use that picture and they show no transition. A new test fails if any transition row is tied to a stage that shows none. |
| An opponent who speaks is the opponent in the next stage | The transition now knows the stage that follows (who is seated, who is eligible, how many seats). An opponent speaks only if eligible for it and never more of them than it has seats; one already seated is preferred. Whoever speaks is then seated first, in speaking order, with the seat count unchanged (`StageTransition.lock_opponents()`, `GameState.reseat_current_stage()`, which also moves the met-people counts). Simulated over all 376 transitions with no staff hired: 301 opponent slots, 62 were already seated and 239 were swapped in; the seat count never changed and the order was always right. So most of the time the transition now decides the opponent, drawn from Transition Cast rather than the whole eligible pool. |
| The multiple speaker path | Works end to end: distinct speakers (opponents capped by the stage's seats, staff added freely), each with their own exchange, a name under the right portrait, the previous speaker sliding out before the next slides in. **Transition Speaker Count = 2** on the 20 stages that seat two or more opponents and have two cast opponents who can sit there: ST01, ST05, ST18, ST21, ST29, ST122, ST131, ST136, ST149, ST174, ST180, ST187, ST198, ST201, ST208, ST214, ST219, ST235, ST244, ST254. Every other stage stays at 1; it is one column to change. Real-click test: both speakers appear in turn and both are seated in the battle. |
| Three more lines per opponent | 174 rows (TD2288-TD2461), three any-stage lines for each of the 58 opponents who appear in transitions (the stage-scoped line they already had stays), each in the voice of their role, committee and rhetorical styles. Drafts for Cameron to rewrite; no policy positions. Every opponent now has at least four lines. |

Tests: `test_stage_transition.gd` (lock eligibility, preference for the seated, seat cap, `lock_opponents`, two speakers, the column only asks for two where two can sit, four lines per opponent, no dead rows) and `stage_transition_driver.gd` (the speaker is the battle's opponent; the two-speaker walk).

## Government bodies use the canon names (2026-11-02, Cameron)

Cameron asked for every named ministry in questions, cues, events and choices to match the canon ministries, which follow the committees and ministers. The canon is eight: Agriculture, Construction and Development, Ethics and Prosecution, Finance, Foreign Affairs, Government Administration, War, and the Environment (the eight "Minister of ..." titles in Opponents, each with a matching committee). All 62 data files were scanned for ministry, minister, committee, department and agency wording.

Found and fixed (4, all in the workbook):
| Where | Was | Now |
|---|---|---|
| Visitor Question VQ106, choice D | "the finance ministry's review" | "the Ministry of Finance's review" |
| Visitor Question VQ119 (tariffs for exports), choice D | "the trade ministry" (no such ministry) | "the Ministry of Foreign Affairs" (the canon home of trade agreements: the EU and China trade bills sit with the Committee on Foreign Affairs) |
| Visitor Question VQ47 (a direct flight to Mongolia), choice D | "the transport committee" (no such committee) | "the Committee on Construction and Development" (transport bills such as the Shinkansen one go there) |
| Event EV64, choice B | "the transport committee" | "the Committee on Construction and Development" |

Already correct: "Ministry of Government Administration" (SF04's biography), every "Minister of ..." title, and every "Committee on ...". Dozens of lines say only "the ministry" or "ministers" without naming one; those name nobody, so they were left alone. New `test_canon_names.gd` fails on any "Ministry/Minister of X" or "Committee on X" outside the canon lists, on a topic written in front of "ministry" or "committee" ("trade ministry"), and if the ministers in Opponents ever stop matching the list.

Noticed, not changed: "Cabinet Legislation Bureau Chief Rika Ashikaga" in an Office notice names a body (a bureau) that is not one of the ministries or committees; the Assembly's "Secretary-General" is likewise outside this rule.

## Playtest notes: card faces, soft boxes, week-end watch, Heritage Party rivals (2026-11-02, Cameron)

| # | Note | Cause and fix |
|---|---|---|
| 1 | "Work the Room First" often shows no "+2" line though it works | The face (`CardView.describe_effect()`) printed only the five plain numbers, "Answers this question." and, when nothing else applied, the workbook text. A card whose whole effect is a special (C11 prints 0 for every number) fell back to the workbook text only when no question was open, which is why it was "often" missing. The same hole hid the "+N more if ..." line of every conditional card (24 cards), the reveal, the discount and the pierce. Now `_special_parts()` writes each special from its structured columns: "Your next card this turn gets +2.", "+2 more to gain if Party Members ≥ 50%." (or "Includes +2 because ..." once it fires), "Doubled if/because ...", "+1 more to gain for every 20% Constituents, now +3.", "+3 more to gain if you trail the opponent.", "Ignores 3 of the opponent's Guard.", "Reveal the opponent's move after this one.", "Your next card this turn costs 1 less.", and "Includes +2 from the card before." on the card that received a buff. 14 new Text rows (Card face), drafts. `SpecialEffects` now records how much a bonus added (`flags.special_bonus`). **Audit:** `test_card_faces.gd` plays all 70 cards in six real rooms (floor debate, committee, press conference, town hall, TV debate, caucus) and four situations (plain, behind, ahead, gaffe) and checks that the face carries every number and special, that the played result equals the preview, that the energy charged equals the cost shown, and that the discards match the face. The only defect found was the missing special text; the test fails without the fix. |
| 2 | Soft blur on the top of the dark end-of-stage box | New `SoftEdge.gd` puts the picture fade (`soft_edge.gdshader`) on a panel's own fill, so the text stays sharp. Applied to the top of the battle's outcome panel. New Balance lever **Panel Edge Fade** (56 px; 0 = hard edges). |
| 3 | A translucent grey overlay under the Floor Vote text with the same edge blur | A grey veil (22/23/26, 66% opaque) behind the text block, reaching a little past it, all four edges soft, never taking a touch (`FloorVoteScreen._add_text_veil()`). Same lever. |
| 4 | After a level on a Friday and two walking tours the hours reached 0 but no choice (weekend or pay dues and go home) appeared until save and reload | The choice was only checked when the Office rebuilt itself. Hours are also spent where it does not rebuild (a promise kept, an event, an item), and a pop-up that opens under another is lost. I could not reproduce the exact sequence, but the Office now watches once a second (`_check_week_over`): when the work week is full and nothing else is open it shows the choice, and waits while another pop-up is open. The week button also stays, reading "The Work Week Is Over", so the choice is one tap away. Real-click test added to `week_test` (hours spent with the Office open; it waits under another pop-up and shows after). |
| 6 | Opponents for the Yezo Heritage Party: Our Traditional Society, Chamber of Commerce, Financial Industry | Read as the party's **Rivals** (the Parties popup shows "Rivals: None" for it). Added to Party Standing as PT02 rivals (negative weight -2 each, drafts for Cameron to tune): BO15 Our Traditional Society, BO05 Chamber of Commerce, BO24 Financial Industry Association. A rival's good standing with you now counts against the party's opinion of you. |

## Playtest notes, second round (2026-11-02, Cameron)

| # | Note | Change |
|---|---|---|
| 1 | No audience conditions or value-adjusting effects on a card face | The face keeps the live numbers and says only what the card does to what comes next: the buff or discount for the next card, the reveal, the pierce. The "+N more if ..." / "Includes +N" / "Doubled" / "now +N" / "from the card before" sentences are gone; the back explains conditions. `test_card_faces.gd` now checks the face never says them. |
| 2 | Remove "Answers this question." | Gone from the face (every card answers). |
| 3 | Custom bill start screen: player at the top center, stance lines centered | The player's portrait shows at the top (the spacer above it no longer pushes it down) and the With you / Against you headings and icons are centered (`StanceLines.stance_chip_rows(true)`). |
| 4 | "The case for the A bill to ..." | New `BillName.gd`: a name that starts with its own article reads "this bill to cap ..." (a drafted bill) or "the ... Act" (a named one), never "the A bill". `CardCues.fill_bill()` uses it; `test_bill_name.gd` checks every bill name and scans all content for "the A ...". All static cue lines were already fine (the bad one was the reply line `{bill}` I added on 2026-11-01). |
| 5 | Whip price on the info line differed from the buttons | The line now prints the price after the backers' discount, base and against-party (`VoteWhip.discounted_unit()`), the same arithmetic as the buttons; the Floor Vote click test compares them. |
| 6 | Statute book: "The bill passes, and Commuter Committee ..." | Pass and fail lines for all 54 patron bills now read "The bill passed. {org} will not forget who carried it." and "The bill fell short. {org} knows you tried." Tenses checked on the Your Record screens: laws and carried bills already read in the past (passed, failed, You voted). |
| 7 | Stage codes (ST04, ...) on the Boosters page | The modifier text replacer only worked when a modifier named one stage; most now name a family. `ModifierEffects.plain_stage_names()` replaces every code with the stage's name (and drops a code that is already followed by its name). A test checks every modifier. No other player-facing text carries a stage code (scanned all data). |
| 8 | Move "Likes ... Dislikes ..." off the combat screen | The strip of icons on the stage screen shows icons and marks only; the likes and dislikes are in the pop-up that opens when an icon is tapped on the Details screen (`OrgChip.make(..., detail)`). Still only for organizations whose backing you hold. |
| 9 | Office hours choice costs | Costs paid on the spot read "(Act Now: 1 hour)" (hours, Funds and items together), deferred ones "(Promise: ...)" and "(Follow-up later)", separated by a semicolon. New Text row `commit.act_now`; `commit.promise` is capitalized. |

## Office Hours: promise and cost text reviewed (2026-11-02, Cameron)

Reviewed all 397 visitor questions (1,588 choices): 92 carry a promise, 24 an Act Now cost (hours, Funds or an item).

| Finding | Status |
|---|---|
| **Silent costs.** `pay_commitments()` returned the lines "You promised X 1 hour of your time within N hours." and the Funds / item lines, but the visitor screen threw them away, and an hour spent on the spot had no line at all. A choice could spend time or record a promise with no word on screen. | **Fixed.** A small note under the choices after an answer: "1 hour passes." plus whatever was paid or promised (`GameState.commitment_note()`, Text rows `commit.hours_passed`). Test in `test_commitments.gd`. |
| **Deadlines in hours that do not match the game's hours.** A game week is 48 hours (40 work + 8 weekend), but 56 of the 92 promises say "within 168 hours" (a real week; here 3.5 game weeks), 17 say 96, 12 say 120, 3 say 72 and 2 say 48. | **Asked** (see below). |
| **Act Now choices written as later promises.** 18 of the 24 Act Now choices are phrased in the future ("I'll come and take the hard questions", 2 hours spent on the spot). | **Asked.** |
| Three promise choices carry no first-person future phrase (VQ21 a "I'm fine, Obaachan, I promise.", VQ58 c, VQ89 d, both imperatives). | Noted only. |
| The reaction chips sit over the visitor's title line. | Noticed, not changed. |

## Promise deadlines fit the 48-hour week; Act Now choices reworded (2026-11-02, Cameron)

| What | Change |
|---|---|
| Deadlines | 117 promise deadlines retuned to the 48-hour game week: 168→48, 120→36, 96→24, 72→18, 48→12, 32→8 (Visitor Questions, Event Choices, Event Options). Follow-up delays and the Balance default (48) are unchanged. |
| Act Now wording | 17 visitor choices that cost hours on the spot are now worded in the present ("Let me call the ward office right now.") instead of as later promises; a few replies adjusted to match. All drafts for Cameron to rewrite. |

## Strategy playtest: 168 bot runs at Funds, Election Strength and Party support (2026-11-02, Cameron)

| What | Detail |
|---|---|
| New tools | `tools/strategy_playtest.gd` (a bot with named strategies, run for a fixed number of game weeks), `tools/strategy_runs.sh` (four at a time), `tools/strategy_report.py` (tables) |
| Bot changes | `tools/playtest_optimal.gd`: the gaffe price, draw value, funds buffer and stage cap are now variables so a strategy can set them. No game rule changed. |
| Findings | `design/review/STRATEGY_PLAYTEST_2026-11-02.md`: dues exceed the Funds cap, paying dues earns nothing, Election Strength plateaus near 42 because gaffes zero out awareness, a Party-support death spiral, Media Ambush never won |

Addendum, same day: the bots never bought the Funds-cap petition (SH13), so the first batch's Funds and dues findings were overstated. `tools/strategy_playtest.gd` now has a `cap` option, simulated awareness-gaffe rules (`awareness_rule`) and in-memory Balance overrides (`balance`). 45 more runs are in `design/bench/strategy_cap.jsonl`; the review document has an addendum.

## Campaign Pressure: Relaxed, Standard, Harder (2026-11-02, Cameron)

| What | Detail |
|---|---|
| Setting | Chosen on the New Game screen above the protagonists; raised (never lowered) from Administration; shown in Your Record; saved with the run (an old save loads as Standard) |
| Rules | `scripts/rules/Difficulty.gd` (pure). `GameState.difficulty`, `raise_difficulty()`. `DataDB.balance_base` and `shop_base` keep the workbook's numbers so the live ones can be rewritten and restored |
| What changes | Fight margin (opponent start, or the bar for single-bar rooms), gaffe room (never under 2), awareness cost of leftover gaffes, Funds and XP paid by a win (stage and level), dues share and a new **Dues Holiday Weeks** row (3 on Standard and Relaxed, 0 on Harder), standing decay, promise deadline and broken penalty, item prices, Election Strength gain and fall |
| Data | 25 Balance rows named `Difficulty Relaxed: ...` / `Difficulty Harder: ...` plus `Dues Holiday Weeks`; 13 Text rows (`pressure.*`, `admin.*`, `record.pressure_line`) |
| Standard changed | Only by the new 3-week dues holiday (Cameron approved the proposal that included it) |
| Bot | `PLAYTEST_DIFFICULTY` on the strategy bot and runner; calibration in the proposal |
| Tests | `tests/test_difficulty.gd` (14 tests) |

## Decisions from the strategy playtest (2026-11-02, Cameron)

| Decision | What changed |
|---|---|
| Media Ambush | `Opponent Count` is 1 on ST19, ST30, ST188, ST194, ST203 and ST234 (was 2, where the bot never won). With one opponent the bot wins 100% with a full kit and 98% with the starter kit, so it may now be too easy; it is Cameron's to retune. |
| Gaffes and awareness | Leftover gaffes now add up over the whole run (`GameState.awareness_gaffe_tally`, saved). Every 65 cost 1 District awareness and every 35 cost 1 National (Balance: `Awareness Gaffes Per District Point`, `... Per National Point`). Was 1 point of each per gaffe. The stage result line explains the rule. The tiers' awareness percent still scales how fast the tally grows. |
| Dues | `Dues: Reward Percent` 30 to 15. To keep the Campaign Pressure tiers in order, Relaxed is 10 and Harder 20 (were 15 and 35). |
| Not changed | A grace week, lower base and step, and any hint about the Funds-cap petition (SH13) |

## Protagonist x Campaign Pressure playtest (2026-11-02, Cameron)

144 bot runs (4 protagonists, 3 tiers, 3 strategies, 4 seeds). Findings in `design/review/PC_DIFFICULTY_PLAYTEST_2026-11-02.md`; tools `tools/pc_difficulty_report.py`. No game rules changed. Main result: Election Strength now ends exactly on weekly gain x 30 weeks (90 / 75 / 60), so it measures time, not play.

## Custom bill audit (2026-11-02, Cameron)

Review of Draft a Bill and patron bills: `design/review/CUSTOM_BILL_AUDIT_2026-11-02.md`. New tools `tools/bill_audit.gd` (vote audit under the real gates), `tools/bill_draft_probe.gd` (draft lifecycle), drafting strategies in `tools/strategy_playtest.gd`. Two bot bugs fixed in `tools/playtest_optimal.gd` (drafted "PD" bills were not treated as patron bills; `visit_wins` was never filled). CLAUDE.md corrected: Reputation gate 60 (not 85), swing resistance 85 (not 70). No game rule changed.

## Two-part bills get the member visit half the time (2026-11-03, Cameron)

| What | Detail |
|---|---|
| Templates | BT01 (patron Favor) and BT03 (drafted, two parts) now list `MP_VISIT` after the hearing, with Visit Parties PT04 and PT02 as on the three-part templates |
| Chance | New optional column **Visit Chance (%)** on Bill Level Templates (blank = always): 50 on BT01 and BT03. The roll is made once, when the level is built (`PatronLevel.build_visit`), and kept with the level, so a saved level resumes with the same rooms. Three-part templates are unchanged (always) |
| Measured | Of 200 random two-part drafts, 106 got a visit (53%); 10 of 27 patron Favors (37%, a small sample); all 200 three-part drafts and all 27 Flagships |
| Tests | `test_patron_level.gd` (share between 40% and 60%, three parts always, visit stages follow the hearing); `test_mp_visit.gd`; the trade and level-length tests now allow or skip the visit |
| Tool fix | `tools/bill_audit.gd` used a fresh identically seeded generator per level, which repeated one roll; it now shares one |

## Member visit and lobbyist trade content review (2026-11-03, Cameron)

Ten real samples plus 400-level statistics, judged against each bill's theme: `design/review/VISIT_CONTENT_REVIEW_2026-11-03.md` (tools `tools/visit_review.gd`, `VISIT_STATS=1` for the statistics). Main findings: 9 of 24 member questions are ungrammatical with the part's phrase, answers are not tied to the question, the same few members and 12 lobbyists from 4 organizations recur, and several lobbyist grievances do not fit the part they target. No content or rule was changed.

## Member visit and lobbyist trade fixes (2026-11-03, Cameron)

All seven findings of the content review were applied: nine member questions rewritten; Reply Kind on every member and trade question with 120 kind-matched answers (a used kind needs two answers in every style, checked at export); questions take the bill's parts in turn; visit parties widened to all six and drawn at random, committee members used only when three or more sit there; every part's Loses rewritten from its own policy tags (180 rows, a draft opposition table for Cameron to correct); equally hurt organizations take turns to send a lobbyist; the part a lobbyist asks for is always tradeable. New exporter columns: Reply Kind on Visit Questions, Trade Questions and Visit Answers. Re-test results: `design/review/VISIT_CONTENT_REVIEW_2026-11-03.md`, last section.

## Prompts for revising the component system (2026-11-03, Cameron)

`design/prompts/COMPONENT_REVISION_PROMPTS_2026-11-03.md`: a shared briefing and five self-contained prompts (Bill Components audit, component-tagged content pass, member visit and lobbyist trade content, code revisions with a plan-first gate, balance validation), each with the facts already measured, the steps, deliverables and acceptance checks. No game change.

## Bill Components audit (2026-11-03, Cameron)

Phase 1 of the component revision plan. All 180 bill parts were checked: phrase, tags, loser, gains, hearing committee and exclusions. The full table is in `design/review/COMPONENT_AUDIT_2026-11-03.md`.

| What | Change |
|---|---|
| Losers | Each one rated Good (44), Fair (50) or Poor (86). Every Poor loser was replaced, 114 in all. No organization now loses more than 21 parts (12%); before, Chamber of Commerce lost 24 and Taxpayers' Alliance 23. Party bodies now lose only on party matters, 3 parts instead of 21. |
| Gains | 26 parts also gain a natural second organization by +1. |
| Hearing committees | 25 parts moved out of Government Administration (72 down to 47). They went to National Assembly, Finance, Construction, Ethics and Prosecution, Environment, and Cabinet (ST18, which now hears 4 parts). |
| Excludes | 8 new pairs for contradictions and repeats, entered on both rows. |
| Tags | CB254 no longer counts public loans as Economic Liberalization. |
| Effect | The Chamber of Commerce lobbyist's share of trades fell from about 34% to 25%. Vote results in `bill_audit.gd` are unchanged. |

## Member visit and lobbyist trade content, phase 3 (2026-11-03, Cameron)

Phase 3 of the component revision plan. Details: `design/review/VISIT_CONTENT_REVIEW_2026-11-03.md`, section "Phase 3 content pass".

| What | Change |
|---|---|
| Member questions | 24 to 30. MV07 and MV19 rewritten. MV24 moved from Party to Trust. Every Reply Kind now has at least two questions. |
| Trade questions | 12 to 20, in aggrieved, bargaining and resigned registers. None uses the Party kind, because a lobbyist has no party. |
| Answers | Three per Reply Kind and style, up from two (MA157 to MA216). Voters and Deal lines now suit a lobbyist as well as a member. Three clock words removed. |
| Fit | Ten new samples (`design/bench/visit_review_samples_phase3_2026-11-03.md`): member visits Good 8 of 10, lobbyist trades Good 8 of 10. |
| Proposed only | New reaction lines, and organization flavor for the ten lobbyist organizations; the flavor lines need a new column. |

## Component system code changes, phase 4 (2026-11-03, Cameron)

Phase 4 of the component revision plan; details and audit output in `design/proposals/component_code_plan_2026-11-03.md` ("Built").

| What | Change |
|---|---|
| Readiness before committing | The Request and Draft panels show "Still needed: ..." for the parties a sway would have to move. |
| Hearing committee | The Draft panel names the hearing committee chosen by the first part. |
| Best case | The "not winnable" refusal says it is checked in the best case. |
| Member visits | A hearing-committee member half the time (Balance: MP Visit: Committee Member Percent, 50); parties weighted by open seats. |
| Lobbyists | Among equally hurt organizations, the least-met lobbyist speaks. |
| Bots | Draft looks, refusals by reason, visits and trades in drafts; report section 12b. |
| Not built (Cameron's call) | No refund on a lapsed draft; no standing floor; no Funds cap hint. |

## Custom bill validation, phase 5 (2026-11-03, Cameron)

Phase 5 of the component revision plan, a report only: `design/review/CUSTOM_BILL_VALIDATION_2026-11-03.md`. The data is 54 bot runs (`design/bench/custom_bill_validation.jsonl`), the vote audit and three draft probes.

| Measure | Before | After |
|---|---|---|
| Bot drafts passed | 4 of 78 | 37 of 233 |
| Prepared player's drafts passed | 8 or 9 of 14 | 27 of 42 |
| Bot drafts lapsed at the hearing | most failures | 25 of 233 |

The vote is now the wall: bots never meet the influence gates. Drafting pays in Party support (+11) and standing (+41 summed) but costs Funds. Three decisions are listed for Cameron.

## Component questions written from each part, phase 2 (2026-11-03, Cameron)

Phase 2 of the component revision plan, limited to the questions (Cameron's call; the cues stay templated).

| Measure | Before | After |
|---|---|---|
| Component questions | 1,440 | 1,440 (same IDs, grades and themes) |
| Distinct question wordings | 572 | 1,440 |
| Wordings used more than twice | 32 (five used on 150 to 180 parts each) | 0 |
| Questions whose Reply Kind did not match what they asked | 738 | 0 |

The 900 templated rows (five per part) were rewritten in 15 batches so each asks about its own policy, covering the principle, the voters, the impact on an ordinary person, oversight and a smaller alternative. Measured but not rewritten: player and opponent component cues (about 80 and 70 wordings across 5,400 lines each) and transition lines (56 wordings across 900). All of it is draft for Cameron.

## Lobbyist Lines: each lobbyist speaks in their organization's voice (2026-11-03, Cameron)

A new workbook tab, **Lobbyist Lines** (`data/lobbyist_lines.json`): Line ID, Organization ID, Kind and Line (EN). It has 20 draft rows, a Protect line and a Deal line for each of the ten organizations with a lobbyist.

| Kind | When it is said |
|---|---|
| Protect | When the lobbyist names the part they want dropped (the pick screen) |
| Deal | When the player chooses what to ask for in return (the package screen) |

Lines appear under the screen's question, quoted and attributed to the lobbyist (Text row `trade.flavor`; `TradeScreen._with_flavor`, `LobbyistTrade.flavor_line`); one line of each kind is drawn per trade. They were first put on the spoken banner, but the banner covered the buttons and blocked the trade, so they moved into the question text. If an organization has several rows of one kind, one is picked at random; if it has none, the lobbyist says nothing extra. The exporter checks the Organization ID, the Kind and the 20-word limit. Tests: `test_lobbyist_trade.gd` (+2) and `trade_test` (the Protect line is spoken).

## Quality control audit (2026-11-03, Cameron)

A full code and asset audit: `design/review/QC_AUDIT_2026-11-03.md`. Fixed: crisis-alert Text keys are written out and tested (`test_trigger_alert_text.gd`); a test that had stopped asserting; the art checklist now counts bare `{ID}.png` staff portraits (Staff 105 of 105); the Assets tab's Drawn column (88 rows); one placeholder list. Seven items are left for Cameron, including PC03's name in the Assets tab and the minimum art sizes.

## The bot plays discard cards; a discard card trial (2026-11-03, Cameron)

- **Bot.** `tools/playtest_optimal.gd` (`_best_play`, `_best_combo`, `_score_card`) now plays cards that make you discard: it plans the rest of the turn with the energy left and throws away cards it would not have played, then the weakest. Before, it never played one, so no balance figure covered C55 to C70.
- **Trial.** `PLAYTEST_CARD_TRIAL=N` swaps each card (`PLAYTEST_CARD_TRIAL_CARDS`) into a fixed deck (`PLAYTEST_CARD_TRIAL_BASE`) for its weakest card and fights eight rooms N times with the same seeds. Results and options in `design/review/DISCARD_CARD_TRIAL_2026-11-03.md`: C69, C70 and C67 add 17 to 19 points of win rate, more than any ordinary card tested. No card was changed; Cameron chose to leave them as they are (rare unlocks meant to feel strong).
- **Exporter.** The "has no Stage listed" warning skips the four protagonists' own opponent rows (OP06, OP22, OP35, OP40), which are unseated on purpose.

## Office Hours choices that promise something now cost something (2026-11-03, Cameron)

From Cameron's playtest: some choices read as promises but cost nothing. Full table in `design/review/PROMISE_WORDING_2026-11-03.md`.

| What | Change |
|---|---|
| Pledges and follow-ups | 102 visitor choices ("I'll push for ...", "I will ask the culture office", "Yes" to "Will you back ...?") now make a promise of 1 hour within 48 game hours (2 for an evening event), each with its own Promise Kept Text. |
| On the spot | VQ220 A "Yes, here is my share." pays 20,000円; VQ84 D "First round's mine" takes 1 hour. |
| Reworded | 51 choices that only stated a disposition ("I vote on each bill on its merits", the eleven bill dilemmas' "Yes. I support it, and here is why.") no longer promise anything; 4 replies adjusted. |
| Events (second pass) | All 198 event choices read with their results. EV36 B and EV54 C now make a promise (1 hour within 12 and 24 hours); six choices worded as a later action now happen on the spot or state a position (EV17 A, EV25 C, EV26 A, EV40 C, EV47 C, EV58 C); EV37 A and EV39 C results and EV18 B's kept line no longer imply an unpaid promise or the wrong time. Hosted events needed nothing. |

## Hosted events: a reply that promises nothing (2026-11-04, Cameron)

- **What changed.** The last step of the Walking Tour (HE01) and the Dinner (HE02) now has a ninth option, TC9 and DC9 "Promise only to keep listening". It has no tags, so no guest reacts, and no commitment, so nothing is owed. Before this, every step-3 option was a promise of an hour.
- **Also fixed.** DC1's kept line no longer says "local" business.
- **Report.** `design/review/PROMISE_WORDING_2026-11-03.md`, section "Hosted event pass".

## In-universe content review (2026-11-04, Cameron)

- **What was checked.** Every player-facing string, for offices, the legislature, places, foreign powers, history and election rules, against the canon titles, parties and bills. Report: `design/review/CANON_REVIEW_2026-11-04.md`.
- **Fixed (162 cells, workbook only).**
  - "the president's new building" now reads "the university president's new building".
  - "Party Leader Hideriai" now reads "Country Initiative Leader Hideriai".
  - ST18's Japanese accent: 内閣員会 is now 内閣委員会.
  - VQ50 and VI25 now name the party Secretary-General.
  - 156 nationwide "Hokkaido" phrases from the bill parts (ports, foreign banks, jobs, firms, graduates) now say "Yezo".
- **Kept, by Cameron's decision.** The six Japanese-only ticker lines, and both "Parliament" and "National Assembly".
- **Follow-up.** VQ50's reply to choice B ("my district needs more attention") was about a bigger office. It now reads "Your district? Every member says that. Earn the attention first."

## Press conference: the reporters' moves are shown (2026-11-04, Cameron)

- **The problem.** Each turn a reporter attacks, gains or guards on a pattern like any opponent, and attacks take press tone. The screen showed none of it: the reporter's row left its move line blank on purpose (written when reporters had no moves), and after the turn their spoken cue appeared with an empty name tag and no word of what it did.
- **Before the turn.** The reporter's row shows their move, "Attacking · −2 to −4", "Gaining · +1 to +3" or "Guarding · 2 to 4" (`OpponentPresenter.show_state()`). A card that reveals the next move (C12 Head Count) now works here too.
- **After the turn.** The banner speaks under the name of the reporter who asked that turn's question, with what the move did underneath, for example "Aoba Shindou: 4 press tone taken from you." (`BattleScreen._on_end_turn()`). Elsewhere a written cue still replaces the narration; in a press conference both show, since a reporter's line never says what it did.
- **Rules unchanged.** A reporter's gain and guard still do nothing to a single tone bar, and the banner says so ("... pressed the case and won nobody over.", "developed 3 guard").
- **Test.** New click test `press_test` plays three real turns. It fails without the fix: blank row, no named move.

## Journalists only attack, for 1-2 (2026-11-04, Cameron)

- **Change.** The eight journalists (OP110-OP117) now have one move, an attack of 1-2, every turn. Their Gain and Block range cells in the Opponents tab are blank, which means "never does this". Before, attacks ranged from 1-3 up to 4-7, and each journalist also gained and guarded. In a press conference those two moves did nothing.
- **Where it applies.** Everywhere the journalists appear (Cameron's choice): press conferences, Media Ambush (ST19) and the bill-specific press and ambush rooms. Nothing else changed, because no other opponent has the Journalist role.
- **Balance check.** In the bot's stage trial (a fully equipped player, 2 x 60 fights) ST04 won 100% before and after; ST19 went from 98% to 100%. That bot is too strong to show the difference; newer players will feel it most.

## The stage end screen no longer explains gaffes and awareness (2026-11-04, Cameron)

- **Removed.** The line "N gaffes left at the end count against your name. Every X cost 1 National awareness; every Y cost 1 District." under a Combat stage's result (`OutcomePresenter._body_for()`), and its Text row `awareness.gaffe_line`.
- **Unchanged.** Leftover gaffes still cost awareness (`GameState.apply_awareness_gaffes()`), at the same Balance rates.

## Law, neglect and staff-audience wording; staff audience rewards become organizations (2026-11-04, Cameron)

| # | Question | Finding | Change |
|---|---|---|---|
| 1 | Public Broadcasting Act: an Aye vote, yet "Reactions to Your Vote" showed National Media -1 | Not a penalty for the vote. The -1 is the bill's own failed-outcome effect (Law Effects LW71), which applies however the player voted. The heading was wrong. | The heading now reads "Because the bill passed:" or "Because the bill failed:" (new Text rows `record.law_now_passed` / `record.law_now_failed`, replacing `record.law_now`). |
| 2 | "Going unvisited this level" | Neglect runs at the end of each **week**, not each level, for any organization whose standing did not move at all that week (from any cause). It drifts `neglect_decay` (1) × Week Decay Multiplier (2.5, rounded to 3) toward its starting standing. | `record.cause_neglect` now reads "not engaged this week" (Cameron's wording, same day). |
| 3 | A staff bonus to Bureaucrats | Audience-group (SGxx) rewards moved a saved `segment_favorability` number that nothing in the game read: no stage, screen or Election Strength. | The five staff with audience rewards now name an organization instead (Staff tab, drafts). |

Staff swaps (point values unchanged; where the organization was already in the same reward, the two merge):

| Staff | Was | Now |
|---|---|---|
| SF04 Policy Research Assistant | Bureaucrats | BO16 Innovation Society |
| SF11 Media Spokesperson | Press | BO08 National Media (+4 from rank 1) |
| SF13 Media Spokesperson | Party Members | BO31 Party Activists (+4 at rank 2) |
| SF18 District Representative | Constituents | BO18 Constituency Voters |
| SF21 District Representative | Boosters | BO03 Local Kōenkai |

**Tests.** Two tests had used SF04's audience reward as their real-data example. They now use a reward of their own, since the rule still handles one. New `test_no_real_staff_reward_names_an_audience` fails if an audience target comes back.

## Stance, vote and outcome rewards shown together (2026-11-04, Cameron)

**The question.** On the Public Broadcasting Act (LV66), a player who leaned Support and voted Aye saw only a −1 for National Media in Your Record, which read like a penalty. A probe of the same run showed the rewards do arrive: National Media 10 → 12 (one stage won) → 14 (Aye vote) → 13 (the bill failed). Each of LV66's three Combat stages is worth +2, and the Aye vote +2. Failing costs every supporter 1, however they voted. The screens just never showed these together.

| Screen | Before | Now |
|---|---|---|
| Stance choice (Level Intro) | Who is with you and against you, no numbers | Adds "Each stage you win: +2 with your side, −2 with the other. Your vote: +2 with your side. Changing your vote costs 5 standing." (new Text row `level_intro.stakes`, numbers from Balance: Stance Win Drift, Stance Vote Delta, Stance Flip Abandoned Penalty) |
| Vote result | The vote's chips, unlabeled. The outcome's own effects were applied but not shown. | Two headed rows: "Your vote:" and "Because the bill passed/failed:" (`FloorVoteScreen._show_outcome_chips()`) |
| Your Record law panel | The outcome's effects only | "Your vote:" chips first, then the outcome's. The statute-book entry now keeps a `vote_effects` field, so only votes cast from now on show it. |

New `StatuteBook.effect_chips()` builds the outcome chips for both screens. New Text row `record.law_your_vote` ("Your vote:"). Tests: `test_effect_chips_lists_each_organization_move_for_the_outcome`, `test_the_statute_entry_remembers_what_the_vote_moved`. All three screens were checked on a real run with screenshots.

## Bill content review: grammar, coherence and honesty (2026-11-04, Cameron)

About 1,300 workbook cells were rewritten across Player Cues, Opponent Cues, Stage Questions, Transition Dialogue, Level Intro Thoughts and Vote Influence Cues, plus the bill facets. The causes were all at the template level: a cost slot used for people, non-people "gain" groups, "who/what" clauses after "for", verbs right after slots that can be singular or plural, three alternatives containing "instead", and a few garbled frames. Six bills' opposition now speaks for a principled constituency rather than only insiders (Cameron's choices, two of them weighted between two phrases). The facets README records the rules. Report: `design/review/BILL_CONTENT_REVIEW_2026-11-04.md`.

## Levels explain themselves: purpose line, bill card, Read the Bill (2026-11-04, Cameron)

Before this, the stance choice came with no description of the bill. The Levels tab's Description only repeated the level name, and the 51 levels without a bill had no purpose text at all. All three designs are built, as Cameron chose:

| Piece | What the player sees | Data |
|---|---|---|
| **Purpose line** | The first line on every level's intro screen: what the level is for. Spoken by the staff member in the level's Purpose Speaker role, else the first hired staff member, else the player's own thought. Every level now opens on the intro screen. | New Levels columns **Level Purpose** and **Purpose Speaker**, drafted for all 101 levels (bill levels from a template naming who is for it and who is wary; the others hand-written) |
| **Bill card** | Above the lean buttons: the bill's name and description, then the sponsor and party line as before, then "For it / Against it" organization chips (replaced by the stance chips once a lean is picked) | Existing Bill Description |
| **Read the Bill** | A button that opens a page: what it does, who gains, who pays, the case for, the case against, the main risk, the middle ground, and where each party stands | New Floor Vote Bills columns **Who Gains, Who Pays, Case For, Case Against, Main Risk, Middle Ground**, filled from the reviewed bill phrases. Case For is new writing for all 50 bills. A blank cell skips its section. |

Code: `scripts/rules/LevelPurpose.gd` and `scripts/rules/BillDossier.gd` (pure), `LevelIntroScreen` (card, button, dossier, purpose first), and `OfficeScreen` (a level with a purpose opens the intro). There are 14 new Text rows (`level_intro.read_bill`, `level_intro.for_it` / `against_it`, `dossier.*`) and header notes on the 8 new columns.

Tests: `test_level_purpose.gd` (5, including "every level has a purpose"), `test_bill_dossier.gd` (3, including "every bill has a full dossier"). `level_intro_test` now checks that the purpose speaks first and that the card and dossier open on LV66. `loop_test` and `inventory_test` step through the intro screen. All text is a draft for Cameron.

## Characters never mention levels or stages (2026-11-04, Cameron)

- The 50 bill-level purpose lines said "...comes to a floor vote at the end of this level." They now say "...is heading for a floor vote in the National Assembly."
- A scan of every spoken line (cues, transitions, thoughts, intro lines, visitor and vote cues, lobbyist lines, purposes) found no other game-mechanic use. Ordinary English stays: "at this stage" as a hedge, a festival's stage, a level voice.
- New `test_spoken_no_game_terms.gd` fails on "this/next/each/every level or stage" in any spoken line. The rule is also in `design/CONTENT_GUIDE.md`.

## Opponents argue their own party's side of a bill (2026-11-04, Cameron)

Before this, bill lines were picked by speaking style only, so an MP or a party leader could profess the opposite of their party's position. Every bill and bill-part opponent line now has a Side (new Opponent Cues columns Cue 1-5 Side, drafted by sentence frame). `MemberStance.gd` decides who may say which side:

- **Leaders** speak for their party, and also say their party's Floor Vote line for the bill.
- **Members** speak their party's side. When the party is Neutral, or 30%+ of its seats abstain (Balance "Member Stance: Split Party Abstain Percent"), each member takes a personal side rolled from the party's Aye/Nay/Abstain split, fixed per member and bill.
- **People with no party** follow their organization's side.

`DataDB.get_bill_opponent_cue_lines()` filters by side. The exporter rejects a bad Side value. `test_member_stance.gd` has 7 tests, including a real-data audit of every bill room. Report: `design/review/MEMBER_STANCE_REVIEW_2026-11-04.md`.

## Opponent lines: no repeats, every side, demanding allies (2026-11-04, Cameron)

Cameron asked for enough opponent bill lines that 30 opponent turns go by
without a repeat, covering every side and every speaking style, and that an
opponent who supports a bill can argue for it against a player who opposes it.
The plan is `design/proposals/opponent_cue_expansion_plan_2026-11-04.md`.

| Change | What it does |
|---|---|
| No-repeat picker | `OpponentCues.pick_unused()` remembers the lines a level has heard (`GameState.opponent_lines_said`, cleared when a level begins) and picks an unused one first; once a pool is used up, the line said longest ago comes back. |
| The player's own side counts | `MemberStance.sides()` takes the player's lean. An opponent on the other side says Neutral lines plus their own side's (For or Against): a supporter argues for the bill against a player who opposes it, and the reverse. An opponent on the player's own side says Neutral lines plus **Ally** lines instead. Before this, 368 Against lines ("You would ask us to...") could reach a player who also opposed the bill. |
| Ally lines | A new Side value. An Opponent Cues row with Ally lines and no Bill ID is shared by every bill and bill part (`DataDB._ally_opponent_cues`), and never joins the general pools. 84 lines, 24 rows. |
| Coverage tool | `tools/cue_coverage.py` simulates 30-turn stretches of every bill level and of drafted and sponsored bills, with the player leaning either way, and lists short pools. `tools/verify.sh` runs it as a warning (a random simulation can shift by a line after an unrelated edit). |
| New lines | 1,082 lines in 698 new Opponent Cues rows, filled from 145 frames (138 for written bills, 7 for bill parts) into only the short pools: written bills to 85% of stretches, bill parts to 75% (Cameron: about 1,000 lines, only short pools). All drafts; the frames are listed for review in `design/review/opponent_line_frames_2026-11-04.md`. |
| Facets | BI30's and BI36's `local` phrases were clauses ("who votes in...", "which firms..."); now noun phrases, as the facets README requires. Older Player Cues built from BI30's old phrase still read "the right thing for who votes in your town's mayoral race" and are not changed here. |

`test_component_content.gd` now asks for at least five attack lines per part and style (new For lines make some six or seven). Bill parts carry attack lines only, as before; their gain and block moves
still use the general pools. Tests: `test_opponent_cues.gd` (no repeats, the
oldest line comes back, a new level forgets, shared Ally lines reach only a
same-side speaker), `test_member_stance.gd` (the player's side decides argued
or Ally lines; the real-data audit now checks every player lean). The
generator is archived in `tools/workbook/archive/b7/`.

## Promise deadlines pause during a level; a level must end within the work week (2026-11-04, Cameron)

| Change | What it does |
|---|---|
| Promises pause | The Office, where promises are kept, cannot be reached mid-level, so promise deadlines no longer run while a level is played. `GameState.level_clock_started` (saved) marks the level's start; `_break_overdue_promises()` waits while it is set. When the level ends or is abandoned, `Promises.resume_after_level()` moves each due time on by the hours the level took (from the level's start, or from when the promise was made if it was made during the level, e.g. in Office Hours), then any still overdue break. Each promise now records `made_at`. |
| Work-week rule | `WeekCalendar.level_refusal()`: on a weekday a level must end within the hours left in the work week ("Too long for the hours left"); before this the extra hours spilled away. The weekend rule (flagged levels that fit) is unchanged. Sponsored and drafted bill levels, which had no calendar check, now get the same work-week check (`GameState.work_week_level_refusal()`); the Office shows the reason. |

No written level is longer than a week (the longest is LV19, 35 hours), so none
is blocked outright; the rule decides the latest day each can start (at the
start of the day: Monday 40 hours left, Tuesday 32, Wednesday 24, Thursday 16,
Friday 8):

| Latest start | Levels |
|---|---|
| Monday only | 3: LV19 (35 h), LV24 (34), LV30 (33) |
| Up to Tuesday | 5: LV25 (32), LV23 (31), LV18 (31), LV10 (27), LV29 (25) |
| Up to Wednesday | 23 (17-24 h) |
| Up to Thursday | 46 (9-16 h) |
| Any weekday | 24 (8 h or less) |

Still able to run past Friday: hours added once a level is under way (a Town
Hall or Steering Committee check-in inserted by a crisis, or a visitor choice
that costs hours). Those hours spill away as before. Tests:
`test_week_calendar.gd`, `test_promises.gd`, `test_patron_level.gd`.

## Legislative Work: carried bills move into their law pop-ups (2026-11-05, Cameron)

| Change | What it does |
|---|---|
| Rename | Your Record's "Statute book" heading is now **Legislative Work** (Text row `office.record_statute_heading`). |
| Carried bills | The separate "Bills you carried" section is gone. A bill an organization asked the player to carry is already one of the Legislative Work buttons (a drafted or sponsored bill is filed there when voted on), so tapping it now shows, under PASSED or FAILED, "You carried this bill for {organization}." and that organization's own comment on how it went ("The bill passed. {organization} will not forget who carried it."). Bills that were not carried show neither line. New Text row `record.law_carried`; the four `record.carried_*` rows nothing asks for any more were removed. |

Checked on a real screen with one carried and one ordinary bill: the heading reads
Legislative Work, the old section is absent, and only the carried bill's pop-up
carries the two lines. The button text itself is unchanged.

## An extra member visit on drafted bills; "Convince <member>" (2026-11-05, Cameron)

| Change | What it does |
|---|---|
| Draft toggle | The Draft a Bill screen has a button, "Add a second member visit (2 Hours, 50 XP)". Tap again to remove it. It is greyed out, with a reason ("No member left to win over for this bill."), when every party is already fully on the player's side of the vote. Drafts only; sponsored bills do not offer it. |
| Where it sits | One more Member Visit and Win Over a Member pair, directly before the vote (after the lobbyist trade). It is added on top of whatever the template already gives, so a Flagship draft (three parts, always a visit) gets two, and a Favor draft (two parts, a visit half the time) gets one or two. |
| Who | A different party from the first visit's when another has a seat left to win, else another member of the same party; never the same member twice. Same questions, rapport and fight as the first visit. Winning each fight wins 1 seat. Declining one visit keeps the other. |
| Cost | 50 XP on top of the draft's 350 (`Draft Bill: Extra Visit XP Cost`, Balance), paid only if the level really gets its second visit. The visit and the fight are **1 hour each**, so 2 hours: the Stages tab's Time Units for ST260 and ST261 were 2 each and are now 1 each. That also shortens every existing member-visit level (sponsored and drafted) by 2 hours. The work-week rule applies, so a draft that would not fit this week is refused with nothing paid. |
| Fight title | The Win Over a Member fight (ST261) is titled "Convince <member's name>" (`stage.convince_member`). The Stages tab's own name is now "Convince Your Colleague", the fallback shown when no member is known. |
| How it is built | A level holds `visit` and `visit_2`; each visit stage records `visit_index` (1 or 2, by order in the level), and `GameState.current_visit()` and the start bonus read the one in progress. Old saves load unchanged. `DraftBill.row_for()` records `extra_visit`. Also fixed: `GameState.level_hours()` did not recognise a sponsored or drafted bill's vote slot as the Floor Vote room (it only matched "BI..") and fell back to the default of one hour, which happened to be the same number. |

Checked with real clicks: the toggle flips, Draft charges 400 XP, and the level ends trade, extra visit, fight, vote. Tests: `test_extra_visit.gd` (12).

## Bigger character portraits in rooms and visits (2026-11-05, Cameron)

Playtest on a phone: the two portraits in a battle were small, with a lot of
background above them and unused space below the status row.

| Screen | Before | Now |
|---|---|---|
| Battle (every combat room) | Portraits filled the lower 70% of the art box; the art zone took 3/4 of the free height | Portraits fill the whole art box (anchor top 0.30 to 0.0), and the art zone takes 8/9 of the free height (stretch ratio 3 to 8). On a 1080 x 2340 screen: portraits 471 to 837 px tall (about 1.8 times as big); the spare gap above the hand shrank from 295 to about 130 px. |
| Office Hours, Member Visit, Lobbyist Trade | Portrait box 220 x 320 beside the visitor's name, with half the screen empty below | 420 x 760 |
| Level Intro and stance screen | Staff portrait already fills the spare height; the stance row is tight | Unchanged (tried bigger lean-row portraits; the Let's go button moved down, so it was reverted) |
| Stage Transition, Office | Already large (a 1480 px art box; a 525 px Office portrait) | Unchanged |
| Floor Vote party cards | Small by design (six at once) | Unchanged |

Only scene sizes changed (`BattleScreen.tscn`, `VisitorScreen.tscn`, `VisitScreen.tscn`,
`TradeScreen.tscn`); no code. Checked with before and after screenshots of each
screen with real art. A portrait still keeps its own proportions, so a wide pose
is limited by the width of its half of the screen.

Side effect found by the click tests: with the portrait taller, the choices on the
Office Hours, Member Visit and Lobbyist Trade screens moved down into the middle
band where a character's reply is shown. The previous reply's band stayed up after
Continue and sat over the next question's choices, swallowing taps. Pressing
Continue now takes the band down on all three screens.

## The hand's scroll bar moves above the cards, in gold (2026-11-05, Cameron)

| Change | What it does |
|---|---|
| Position | The bar that scrolls the hand sideways now sits directly above the cards, not underneath them (under the thumb that holds them). With a discard pick in progress, the Confirm / Cancel bar sits above it. |
| Colour | The game's standard gold (the same as the cue banner's edge, `CueBanner.EDGE_COLOUR`): a gold grabber, a little brighter while held, on a faint gold track, 34 px high. Only this bar is gold; other lists keep the theme's white scroll bars. |
| How | A new `HandScrollBar` (one small script) mirrors the hand's own scroll bar, which is switched off. Dragging it scrolls the hand; dragging the cards moves it. When the whole hand fits on screen the bar fades out but keeps its space, so the cards do not jump up and down as the hand grows. |

Checked on a real screen with a hand wider than the screen (bar and hand follow each
other both ways) and with `test_hand_scroll_bar.gd` (3 tests).

## Score bars take the cue band's slant and gold edges (2026-11-05, Cameron)

| Change | What it does |
|---|---|
| Slanted sides | The support bar (a battle's win bar), the Floor Vote result bar (Aye / Abstain / Nay) and the three party bars under it lean at the cue band's own angle: the top edge sits 0.18 of the bar's height to the right of the bottom edge. Every division inside a bar, the threshold line and the "votes needed" mark lean the same way. |
| Gold edges | A thin gold border along the top and bottom of each bar (4 px on the support bar, 3 px on the other two; the band's is 8 px on a taller box), in the band's gold (`CueBanner.EDGE_COLOUR`). None down the sides, as on the band. |
| How | A new `SlantBar` helper draws all three, so they always match each other. `CueBanner` now takes its slant from `SlantBar.SLANT`, so changing it moves the band and the bars together. |

Checked on a real screen (a battle, and a Floor Vote result) and with
`test_slant_bar.gd` (5 tests of the geometry). The bars have the same height as
before, so the slant is subtle (about 10 px across the support bar), the same angle
as the band rather than the same width of lean.

## Documentation review: new references, a slim brief, September and October summarized (2026-11-06, Cameron)

| What | Change |
|---|---|
| New: `design/GAME_SYSTEMS.md` | The mechanics, written against the code and data: names, the player's journey, time (calendar and hidden clock), every resource and standing with how it grows and declines, where the player chooses, growth and decline in one place (stage, level, week end, crisis triggers, decay, dues), the shape of a fight, bills and votes, **every `GameState` variable** (saved or not), and where the numbers live |
| New: `design/INFORMATION_STANDARDS.md` | How the player must be told things: what is shown before and after each kind of choice, the fixed terms, who may say what, honest choices, layout and touch, and that wording and numbers are data |
| New: `design/ARCHITECTURE.md` | How the code is organised, taken from the old `CLAUDE.md` "seams" and working notes and checked against the code |
| `CLAUDE.md` | From 82 KB to about 19 KB: the brief, constraints, canon, data contract (every data file grouped), open switches, status, information-standards summary, working agreement. The mechanics, the code notes and the 290-entry change index moved or were removed; the old section numbers still resolve (7, 8 and 13 are short pointers) because many code comments cite them. The previous version is at commit `05b615e` |
| `design/CHANGELOG.md` | The September and October entries (about 2,880 lines, 390 KB) were summarized into one section and erased, as Cameron asked; the November entries (since 2026-11-01) are unchanged. Old text: `git show 05b615e:design/CHANGELOG.md` |
| Updated | `GAME_DESIGN.md` (November's changes, dues share, counts), `CONTENT_GUIDE.md` (counts, next free IDs, the dues share, Level Purpose, the dossier columns, the Opponent Cues Side columns), `EDITING_TEXT.md` (stale "ships empty" notes, bill range, spelling), `NEW_CHAT_STARTUP.md` (rewritten for today), `README.md` |
| Stale facts corrected | Party dues take **15%** of the week's Funds, not 30% (the Balance row; a comment and two documents said 30%); standing decay runs **once a week**, not at the end of every level; the game has **32 organizations**, not ten; XP is spent on much more than a "checkpoint"; shop item IDs had been renumbered, so comments citing SH13 to SH19, SH25 and SH26 were rewritten to the current items (the Fund Limit petition is SH13, the Staff Training Consultancy SH12, card training SH09 to SH11); the comments saying saving was not built were removed; `stage_types.json` no longer exists |
| Code comments only | `GameState.gd`, `DataDB.gd`, `OfficeScreen.gd`, `OutcomePresenter.gd`, `InventoryPanel.gd`, `Ledger.gd`, `Items.gd`, `RewardTargets.gd`, `PartyDues.gd`, `BattleEngine.gd`; and `tools/build_visitor_scene.gd` now builds the 420 × 760 portrait the scene has (one number) |
| Noted for Cameron, not changed | `design/CLEANUP_CANDIDATES.md` lists historical working papers (nothing deleted) and four findings: `segment_favorability` is stored but read by nothing; the Sanban low/high "consequence" cells are text only; a switched-off second decay path; an unused level-purchase function |

## Mechanic Coherence and Clarity Test: expert pass and test kit (2026-11-06, Cameron)

**What:** Cameron supplied a research protocol (MC²T) for judging whether a mobile deckbuilder's mechanics are clear and coherent to players. I ran every part that needs no participants and prepared the rest. No game content, layout or rules were changed.

| Piece | Result |
|---|---|
| Touch-target audit (`tools/ui_target_audit*`) | Walks 21 real screens, measures 405 controls: 93% are under the iOS 44 pt minimum; the standard button is about 34 dp |
| Keyword audit (`tools/mc2t_lexicon.py`) | No forbidden terms on screen; found "Boosters" naming both the backing shop button and an audience group, several words for standing, two discard phrasings |
| Expert pass and scores | `design/review/MC2T_REPORT_2026-11-06.md`: provisional composite about 3.2; fails two mobile gates (touch targets, nothing saved mid-stage) pending real-phone tests |
| Test kit (`tools/mc2t_kit.py`) | 12 predict-then-reveal items with answers computed from the game's own card rule, freeze probes, term definitions, recording sheet |
| Protocol kept at | `design/reference/MC2T_PROTOCOL.md` |

**Decisions waiting for Cameron:** taller buttons, a per-turn stage save, renaming the "Boosters" button to "Backings", and which opacities to declare intended (report sections 3 and 4).

**Checked:** the tools run; `tools/verify.sh` passes.

## MC²T follow-up: 144 px buttons, a save at each defeated opponent, wording (2026-11-06, Cameron)

| Change | What it does |
|---|---|
| Buttons 144 px | New Balance row `Touch: Minimum Button Height`. `Layout` raises every button to it a moment after it appears; picture-only buttons (organization chips) become square. Card faces, invisible click overlays and the gold hand scroll bar are exempt |
| Save when an opponent is defeated | In a stage with several opponents (committees, floor debate, Town Hall) the run is saved when one is defeated, with where to resume: the next opponent, plus what carries over in that stage type (gaffes, hand, guard, clock) and the items the stage began with. Closing the app and returning picks the stage up at the next opponent. A stage with one opponent still returns to the start of that stage. The save point is cleared when the stage ends |
| Wording | The Office button into the backing shop reads "Backers"; "Their goodwill" and "approval among" become "standing"; card text "Discard 1 other card (to play)" becomes "Discard N card(s)" |
| MC²T report | Opacity declaration approved; decisions recorded (`design/review/MC2T_REPORT_2026-11-06.md` §8) |

Checked: 7 new tests in `tests/test_stage_checkpoint.gd`; `tools/verify.sh`.

## Buttons back to their earlier sizes (2026-11-06, Cameron)

Cameron found the 144 px buttons too large. The Layout rule and the Balance row `Touch: Minimum Button Height` are removed; every button is the size it was before. The MC²T touch-target finding (most buttons under 44 pt) is still open, to be revisited at a size Cameron picks. The save at each defeated opponent and the wording changes stay.

## Five organization chips stay full size (2026-11-06, Cameron)

On the stage screen the "who is listening" strip switched to two rows as soon as there were five organizations, which shrank every icon to about half size even though five fit side by side. It now uses one row whenever the icons fit across the screen at full height, and wraps to two only when they really cannot. Test: `tests/test_listening_strip_size.gd`.

## The battle picture ends above the hand's scroll bar (2026-11-06, Cameron)

The stage picture used to stop at a fixed three-quarters of the screen, which left the gold hand scroll bar sitting over it. The picture (and its darkening layer) now ends exactly where the scroll bar begins, and the plain panel starts there. The picture still pans vertically, so all of it can be seen.

## A two-second hold on a stage's Continue button (2026-11-06, Cameron)

When a stage's opening scene (the Stage Transition) first appears, its Continue button stays inactive for 2 seconds so the scene is seen before it can be tapped past. The delay is a Balance row, `Stage: Continue Delay Seconds` (0 turns it off). Tests and bots skip it with the `COP_NO_CONTINUE_DELAY` setting that `tools/verify.sh` sets; the stage-transition click test turns it back on to prove it holds, then releases. Other Continue buttons (Level Intro, visits, events) are unchanged: tell me if they should wait too.

## Levels on cooldown leave the level list (2026-11-06, Cameron)

A level that is still cooling down after being played no longer shows as a greyed-out "wait" row in Choose a Level; it is taken off the list and comes back when its cooldown is over. Locked levels (not yet bought with XP) and levels the calendar refuses still show with their reason. Only applies while `level_gating_enabled` is on (it is). Checked with a throwaway script: clearing LV01 dropped the list from 75 buttons to 74.

## Cameron's workbook update: bill votes, party positions, influence thresholds (2026-11-07)

Cameron uploaded a new workbook and new protagonist art (PC01, PC02, PC03 expressions). Reviewed and re-exported; nothing in the code had to change.

| What changed in the workbook | Effect |
|---|---|
| Seat splits for 20 bills (BI02-10, 12-14, 17-22, 26, 29) | Fewer bills pass at baseline: 14 now do (was 27). 13 of those pass even if you vote against (was 27). BI02 now sits exactly on the 51 line, so your own seat can decide it |
| 12 party dispositions turned (for example Keizaijiyuutou Supportive to Opposed on BI04, BI10, BI14; Heritage and Frontier Opposed on BI29) | Opponents of those parties now argue the other side in those bills' rooms (derived at run time from the positions, no edit needed). 44 position cue lines were reworded by Cameron to match |
| Vote Influence Triggers: Constituency support 60 to 50 and several organization gates lowered by 5 to 15 | The influence swing opens sooner |
| Small wording edits: three level intro cues, one lobbyist line, ticker lines, a few transition lines | None |

Fixed: the upload carried calcChain records Excel would "repair" (`Vote Tally & Swing`); a no-change save by `wbx` dropped the chain. Checked: export "No errors", every bill's party splits still add up to each party's seats, `tools/verify.sh` passes, and the bill rubric scores the same as before (59 of 64; its two failures, D1 and D3 on law effects, were failing before this update).

For Cameron: **BI18, Five Point Independents** now reads 4 Yes / 1 No but is still "Opposed" with the cue "No one person should hold that power" (it was 2 / 3). Likely the numbers were swapped; left as is. Twelve "Neutral" positions have lopsided splits (for example BI29 Keizaijiyuutou 2 / 18 / 5); that reads as a split party, so left alone.

## 33 opponent lines for the bills whose party positions changed (2026-11-07, Cameron)

After the workbook update the new party positions moved which sides draw from which line pools, leaving 33 pools (bill, rhetorical style, move) one line short on BI02, 04, 10, 12, 13, 14, 20 and 29. One line was added to each as a new row in the Opponent Cues tab (OC3831 to OC3863): 22 Neutral, 9 For and 3 Against, written in the voice of the existing lines and built from each bill's own facts. All are Claude's draft for Cameron to rewrite. `tools/cue_coverage.py --list` now shows none of those bills short (overall shortfall 544 to 511 lines). The batch is kept in `tools/workbook/archive/b8/opponent_line_top_up.py`.

## Two empty event slots filled: EV01 and EV02 (2026-11-07, Cameron)

The Events tab had two empty rows at the top (EV01 and EV02, with six empty rows in Event Choices). They are now filled with draft events, so no new IDs were used (next free is still EV66). Both are Random, weight 5, with three choices each, one of which costs nothing.

| Event | Trigger | Content |
|---|---|---|
| EV01 Sapporo Grand Sumo Wants an Answer | Random, both days, 2 hours, Summer, festival picture | The tournament can return every year if the city and legislators stand behind it. A: pledge to fight for it yearly (promise of 2 hours within 72 for the Small Business Owners' Association; Mayors' Network and small business up, Taxpayers' Alliance down); B: welcome it once and ask for the public costs first (Taxpayers' Alliance and Neighborhood Associations up, small business down); C: send a staff member to hear both sides |
| EV02 The Temple Bell Needs a Ringer | Random, both days, 1 hour, Winter, winter festival picture | The Buddhist Temples Association asks you to ring out the old year; the bell tower roof leaks. A: take a turn at the bell; B: send a staff member with a 10,000円 donation; C: offer to speak for the roof at the next heritage debate (promise of 1 hour within 72) |

All text is Claude's draft for Cameron to rewrite; EV02 was my choice of subject. Only existing organizations are used, and "the sumo association" is left unnamed. The batch is `tools/workbook/archive/b10/fill_ev01_ev02.py`. Checked: export "No errors", `tools/verify.sh` passes.

## EV01 Sapporo Grand Sumo rewritten to Cameron's spec (2026-11-07, Cameron)

EV01 now opens with the sumo association's organizing committee lobbyist asking legislators to back an annual Sapporo Grand Sumo tournament (Japanese culture, alignment with Japan, visitors in local shops, a low-barrier sport for students). Random, both days, 1 hour for the visit, Summer.

| Choice | Cost | Pleased (+) | Annoyed (-) |
|---|---|---|---|
| A. Go on the radio to back an annual tournament | Promise 2 hours within 72 hours | Our Traditional Society, Small Business Owners' Association (+1) | Care and Welfare Council, Innovation Society (-1) |
| B. Welcome it this year and fund tickets for constituents | Promise 4 hours within 120 hours, and 100,000円 paid now | Our Traditional Society, Students United, Local Kōenkai (+2, double the usual) | Taxpayers' Alliance, Care and Welfare Council, Innovation Society (-1) |
| C. Reply that you are focused on more pressing issues | The visit's 1 hour only | Care and Welfare Council, Innovation Society (+1) | Our Traditional Society, Small Business Owners' Association (-1) |

Broken promises cost the named organizations more than a kept one pays (A: -3 each and Reputation -2; B: -4 each and Reputation -2). Two points to confirm: the game cannot yet owe Funds later, so B's 100,000円 is paid when chosen and only the hours are owed within 120 hours; and C's one hour is read as the visit itself (the event's Hours), because the export requires every event to keep a choice with no extra cost. Draft wording by Claude. Batch: `tools/workbook/archive/b10/rewrite_ev01_sumo.py`.

## Promises can owe Funds; EV01 option B uses it (2026-11-07, Cameron)

Cameron approved the plan: a choice can say `Promise Funds N within H for BOxx`. The Funds are taken when the player keeps the promise in the Promises panel (the button greys out with "Not enough Funds" while short); nothing is held back when the promise is made; one still unpaid at its deadline is broken like any other. The choice label shows it before it is picked (for example "Promise: 100,000円 within 120 hours"). A choice owing hours and Funds gives its own kept and broken terms to the first promise only, so bonuses and penalties are not doubled. Changes: the exporter's commitment grammar, `Promises.gd`, `GameState` (what, refusal, keep), one Text row (`promise.what_funds`), the CONTENT_GUIDE grammar table, and seven tests in `tests/test_promises.gd`.

EV01 option B now owes both: 4 hours and 100,000円 within 120 hours for Our Traditional Society (the earlier "paid now" reading is replaced), and its result text says the player pledges the tickets.

## Office Hours organization chips centered beside the visitor (2026-11-07, Cameron)

After an answer, the organization chips used to float at a fixed spot that sat over the visitor's name and title (a long name wrapped across them). They are now placed once the screen has laid out: centered in the space to the right of the visitor's picture and level with the middle of the picture, wrapping to more rows only if they must. Checked with a throwaway screenshot driver (since deleted).

## Office Hours screen laid out around the spoken line (2026-11-07, Cameron)

Following Cameron's sketches, third version: the visitor's picture fills the office window (760 px wide, centered), with the name box over its top left corner. The organization chips sit across the middle where the spoken-line band normally is, sized to fill the row (up to 200 px, never under 120 px). The question and the four choices sit in the plain panel below the window, and the spoken line pops up over them (`CueBanner` now has a per-screen `centre`; `CueBanner.zone()` is the shared rule). The layout is worked out from the window's anchor and the screen's margins, so it is right before the first layout pass, and it re-fits when the window changes. `VisitorScreen.tscn` is untouched, so re-running its builder does not lose the change. Checked with throwaway screenshots (deleted), including one with real visitor art.

Neutral picture fallback: already how the game works (`ArtLoader.expression_chain`: the face asked for, its fallbacks, then neutral, then a plain `ID.png`, and only then a labelled placeholder), and every visitor, opponent, staff member and protagonist with any art has a neutral or plain picture, so none shows a placeholder for a missing expression. No change made.

## Everyday casework: 26 visitor questions, 8 events, 9 follow-ups (2026-11-08, Cameron)

Small requests modelled on real Japanese and American constituency casework (potholes, crows at the garbage point, a stuck passport, a missing pension, a veteran's claim, a barking dog, a station with no elevator, a sidewalk sign, a broken harbor ice machine, phone scams, a turbine on the ridge, a valley with no signal), each spoken by an existing visitor whose role fits, plus random events and follow-ups that pay the story off later. Of Cameron's 50 ideas, 13 were already in the game (streetlight, crosswalk, sidewalk shoveling, festival road closure, wildlife, rural buses, school lunch, library hours, interns, heating bills, card fees, childcare, shop openings) and were not repeated.

| Added | IDs | Notes |
|---|---|---|
| Visitor Questions | VQ398-VQ423 | Four sincere answers each, inside the content budget; promises carry kept text; at least one answer costs nothing |
| Random events | EV66-EV73 | Elders' day certificates (Autumn), blossom litter (Spring), the car that never moves, the washed-out farm road (Summer, Autumn), old campaign boards, a supporter's grandson's wedding (weekend), the flooding ditch (Summer), lending your name to a charity run; Declines by the 1.5x rule with seven new Text rows |
| Follow-ups | EV74-EV82 | The streetlight is back on (from VQ01 A, now scheduling it), the passport arrives, the crows move a street over, the pothole is patched, the veteran's claim comes back, the empty house's owner is found, the phone company writes back, the scam calls come again, the turbine meeting |

All Claude's draft for Cameron to rewrite; only existing visitors, organizations and places are used. Batch: `tools/workbook/archive/b11/mundane_casework.py`. Checked: export "No errors", `tools/verify.sh` passes (content budget, promise text, spoken-terms and follow-up checks included).

## Cameron's visitor update: three names, new pictures (2026-11-08)

Cameron uploaded a new workbook and new visitor pictures. The only data change is three visitor names: VI03 Saki Mori is now Inra Mori, VI11 Leo Aoyama is now Lele Aoyama (with Japanese and romaji to match), and the placeholder VI24 "Party Member A" is now Hiroshi Furuya, Party Steering Committee Member. No other content refers to the old names (one historical review paper mentions "Leo"), and none of the 2026-11-08 casework uses these three visitors, so nothing else needed changing. The casework batch (VQ398-VQ423, EV66-EV82) is intact in the new workbook. As with the last upload, Excel's calculation chain on the Vote Tally & Swing tab would have triggered a "repair" message; a no-change save by `wbx` dropped it. Checked: export "No errors", `tools/verify.sh` passes.

## Real Aomori and Hokkaido places in the casework (2026-11-08, Cameron)

Cameron allowed any real town, landmark or geographic name in Aomori or Hokkaido. The casework batch now sits in real places, spread across both, and each follow-up points back to the same town: the pothole on the road into Hakodate's morning market, crows in Kotoni, garbage rules in Niseko, roof snow on Otaru's Sakaimachi Street, the Sapporo passport office, the Kushiro pension office, a Nemuro coast guard veteran, a hundredth birthday in Hirosaki, an Asahikawa night shift, Nakajima Park, a station on the Gonō Line, bicycles by Hachinohe Station, an empty house in Imabetsu, a Muroran bathhouse, a sign on Tanukikōji, the Shari harbor ice machine, a park by the Ishikari River in Takikawa, the Nibutani museum, a Neputa float in Hirosaki, temple graves in Esashi, the prefectural office in Aomori City, the Kita Ward office, scam calls in Obihiro, a fish plant in Monbetsu, a turbine near Cape Sōya and the valley road out of Yūbari. Events: Furano, Hirosaki Park, Ebetsu, Biei, Chitose, Hachinohe, Iwamizawa and Lake Ōnuma, and EV02's temple bell is now in Matsumae. Batch: `tools/workbook/archive/b12/place_names.py`. Claude's draft.

## Real places for the earlier questions and events; places kept apart from the player's district (2026-11-08, Cameron)

109 earlier Visitor Questions and 18 earlier events now name a real Aomori or Hokkaido place where they describe a concrete local situation; policy questions stay general. Each recurring visitor keeps one home town across all their questions (Hanako Okuda in Kotoni, Gen Tsukamoto in Rausu, Fumiko Sugawara in Betsukai, Ryo Kawabata in Muroran, Daigo Ishikari at Lake Akan, Hiroshi Wada in Esashi, Kiyoshi Murata in Shimokawa, Tomoko Ide in Asahikawa, Haruto Ebina in Furano, Sora Kudo on the Ōma-Hakodate ferry, and the one-room visitors in towns that fit their trade: Niseko ski staff, Abashiri drift ice, Rishiri kombu, Itayanagi apples, Noboribetsu inns, the Sapporo Snow Festival, Takayama Inari Shrine, and more), and follow-ups share their source's place (the Kitami transfer station and its meeting, the Hakodate port letter and the ministry's reply).

Named places are never described as the player's own district, since each protagonist has a different one: questions about "the district" and the player's own campaign stay unnamed (EV70's campaign boards lost their town), EV71's wedding is in Hachinohe "where the bride's family lives", and VQ234-VQ235's "onsen district" became "onsen town". Batch: `tools/workbook/archive/b13/place_names_earlier.py`. Claude's draft.

## With no staff, a level's purpose line is narration, not the player's (2026-11-08, Cameron)

Cameron saw a line written to "you" ("Lobbyists have asked for your time...") spoken by the player character on a Level Intro, just before the player's own thought. It was the level's Purpose line: it is spoken by a staff member, and with no staff hired it fell back to the player. It now shows as narration instead, with no name tag and no portrait, and the player's own thought follows as before. With staff hired nothing changes. The Stage Transition already falls back only to the player's own written thoughts (PLAYER rows), so it needed no change.

## Spoken lines stay centered two seconds longer (2026-11-08, Cameron)

Every line on the cue banner (battles, Office Hours, visits, Level Intro, Stage Transitions) now holds in the middle of the screen 2 seconds longer than its reading time; the slide in and the slide out keep their speed. The extra is a Balance row, `Cue: Extra Hold Seconds` (set it to 0 to go back).

## Expanded Staff Office: more staff per role, and a primary (2026-11-08, Cameron)

A new Marketplace item, SH35 Expanded Staff Office (150 XP, 300,000円 and 15 Reputation), adds one place to every staff role; it can be bought up to twice (three people per role at most). The first person hired in a role stays its **primary**, the one every scene reads (Level Intro cues, the purpose line, notices, ticker, item bonuses, Member Visit briefing), so nothing conflicts. Extra staff pay their rank rewards on hire and upgrade, can be upgraded and fired on their own, and may speak in stage transitions (Cameron's choice). The staff screen lists everyone in a role with the primary tagged; an extra's profile has a **Make primary** button; firing the primary promotes the first extra. Both new fields (`staff_extra`, `staff_slot_buys`) are saved; old saves load with no extras.

Decisions by Cameron: the Reputation price is a Balance row, not a new Shop column (`Staff Slots: Reputation Cost` 15), so the code finds the item by a Balance number (`Staff Slots: Item Number` 35) and the cap is `Staff Slots: Maximum Purchases` (2). Nine Text rows added. Tests: `tests/test_staff_slots.gd` (13). Checked with throwaway screenshots (deleted): the staff screen lists every person with the primary tagged and an extra's profile shows Make primary.

## Floor Vote screen: gold lines, Influence Status, Vote Projections (2026-11-08, Cameron)

Gold lines now separate the information blocks. The influence gate moved behind an **Influence Status** button (every missing requirement on its own row, scrolling), with a line above it: "Your influence will / will not affect the vote." "If the vote went each way" became **Vote Projections**: a bar per choice with the label "Vote Aye - Likely Passes/Fails". Part of the house (10 to 25%, drawn when a level begins or a stage ends, so it is fixed before the screen is built) shows black as Unknown, pulled from Aye, Nay and Abstain in proportion; the exact tally waits for the outcome screen. Influence and whips are inside the projection. Whip rules sit behind a **Whip Details** button (Cameron picked this of two layouts).

Balance: `Vote Projection: Unknown Minimum Percent` 10 and `Maximum Percent` 25. New rules file `VoteProjection.gd` with `tests/test_vote_projection.gd`. The "influence flips the result" note is no longer shown. Wording is Claude's draft.

## Policy Research Assistant: Vote Intention Research (2026-11-08, Cameron)

A hired **primary** Policy Research Assistant helps on the Floor Vote screen in two ways. Passively, their tier takes points off both ends of the Unknown range when it is drawn (Tier 0/1/2: 1/2/3 points; the tier's own number, not added up). Actively, a **Vote Intention Research** button above the whip block clears a further 1/2/3% of the house from the Unknown share, once per vote, for 2 hours and 50 XP; the cost line sits above the button and a disabled button says why (no assistant, already done, no hours, not enough XP, nothing left to clear). A line says "Your research assistant has narrowed the vote projection uncertainty." The drawn Unknown share and the "already briefed" flag are now saved.

Balance rows: `Research Assistant: Passive Points Tier 0-2`, `Briefing Clears Tier 0-2`, `Briefing Hours` (2), `Briefing XP` (50). Rules: `VoteProjection.narrowed_range()` and `by_tier()` with tests. Decisions by Cameron: points of the whole house, 2 hours kept even inside a level, the "Likely Passes/Fails" label stays as it is. Wording is Claude's draft.

## Cleanup pass (2026-11-08, Cameron: "Approve all")

Six unused Floor Vote Text rows and 98 working papers nothing reads were removed (details and what was kept on purpose are in `design/CLEANUP_CANDIDATES.md`). Everything is in git history.

## Important Stakeholders: change buttons, a new intro (2026-11-09, Cameron)

Each organization's change in standing is now a button reading only the signed number (for example +3); pressing it opens a pop-up listing the factors behind it, one per row ("a hosted gathering: +6"). The small line of linked backings under each organization is gone. The intro paragraph now reads: "Your performance and conduct are scrutinized closely. The following are key organizations that can support or oppose you based on their sentiment." (Claude fixed "performace" and "is" to "are"; reword freely.) New Text rows: `office.stakeholder_factor`, `office.stakeholder_no_cause`, `office.stakeholder_change_title`.

## Higher-tier non-combat levels (2026-11-09, Cameron)

Non-combat levels now climb in tiers. Six families, each with a Tier 1 level (two stages) and a Tier 2 level (three stages): Ward Tour and District Tour, Regional Festival and Grand Festival, Extended Office Hours and Open House Day, Health Fair and Regional Health Forum, Education Forum and Graduation Ceremony, Trade Fair and Export Expo (LV102-LV113, 15 new stages ST274-ST288). Tier 1 pays 120-180 XP over 5-8 hours and Tier 2 pays 200-280 XP over 9-12 hours, both about 20-25 XP per hour as at Tier 0, and they add Funds (20,000-120,000円), Reputation, Party support, and national awareness. Unlock prices are 60/50/40/30 XP and 120/100/80/60 XP (by Policy Research Assistant rank); cooldowns 48-72 and 96-144 hours. All are hidden until the right organization's gathering is hosted (Tier 1 Regional Festival: a Summer or Autumn season instead). Tier 1 reveals through BO06, BO18, BO21, BO11 and BO25; Tier 2 through BO03, BO20, BO04, BO26, BO15 and BO13. The follow-up, receiving line and closing reception stages are shared across levels. Visitors were added to the new stages' Stage cells. Names, purpose lines and numbers are Claude's draft for Cameron to rewrite (the script is `tools/workbook/archive/b14/higher_tier_noncombat.py`); `tests/test_noncombat_tiers.gd` checks the shape.

## Level list: non-combat levels first, a gold line, then battles (2026-11-09, Cameron)

Inside each tier of the level selection screen, the non-combat levels (office hours, festivals, walkabouts and the like) are listed first, then a thin gold line, then the combat levels. A level counts as non-combat when all of its stages are Non-combat rooms (`Ledger.level_is_non_combat`). No line shows when a tier has only one kind. The gold line is now one shared helper, `UiKit.gold_rule()`, also used by the Floor Vote screen.

## Level list: the gold line is removed (2026-11-09, Cameron)

The gold line between non-combat and combat levels in the level list did not look good and is gone. Non-combat levels are still listed first within each tier. Each level row is now named after its level (`Level_LV01`), and the click tests pick the first combat level by looking that level up, instead of relying on the line.

## Writing review applied (2026-11-09, Cameron)

The wording fixes from the six writing reviews (R1 interface text, R2 opponent lines, R3 player lines and thoughts, R4 questions and visitors, R5 transitions and level text, R6 events and bills) are now in the workbook, following Cameron's 62 decisions. 7,028 cells changed in 32 tabs. Of the 3,918 ledger rows that proposed a change, 3,807 were applied (R1 100, R2 2,607, R3 53 single lines plus 13 pattern findings expanded into 3,096 lines, R4 273, R5 687, R6 74), 111 were skipped, and none failed to match. A further 120 lines changed from the decisions themselves: every organization takes "the" except Local Kōenkai, Our Traditional Society and Students United (#62); Students United and the Neighborhood Associations take the singular (#13); every ticker line ends with the dash and the ☼ (#59); the serial comma in the bill-facet lists; and three small drafts (T27 "introduce" working visas, VQ229's reply, LV103's purpose line). Highlights: opponents rally their own side on a gain move instead of praising the player (#27), bill-part lines no longer assume the player backs the part (#28), visitor replies match what a choice costs (#36), "Say ..." options read as speech (#35), the card C16 is now "Release the White Paper" (#16; its Japanese name 白書を突きつける was left for Cameron to check), follow-up events carry the heading "Following up" (#21), and Funds backings read "after each level you win" (#19).

Skipped on purpose, with the decision number in the log: canon and style Cameron kept ("my district", "the opposition", "every yen", spoken yes/no, LV24, the Media Ambush accusations), Cameron's own card cues C01-C54 where the suggestion was low confidence, the unused patron request, accept and decline lines (listed in `design/CLEANUP_CANDIDATES.md` instead), and the five bill-part renames (CB123, CB134, CB143, CB185, CB273), because a part's short label is also the Theme key its questions are filed under, so renaming it is a key change to ask about. Two drafts were adjusted to pass the tests: TD2157 keeps its grammar fix without the word "press" (generic transitions must fit every room), and two long player lines use "the Chamber of Commerce's members" to stay within 25 words.

Deferred to group 2 (code, moves or new writing; outlines in `design/proposals/WRITING_REVIEW_GROUP2_PLAN_2026-11-09.md`): follow-ups only after a kept promise (#20, so EV81 is unchanged), BI26 and BI35 positions (#12), moving room questions and S573-S582 (#31, #32), T32 and T33 (#33), journalist lines (#55, #57), rotating bill templates (#56), topic-room stance tags (#58), per-bill visitor replies VQ135-VQ156 (#37), per-event decline lines (#49), renaming the Boosters segment and backings M05/M25 and M06/M24 (#17, #14), bill facts BI01, BI08 and BI09 (#48), EV16 B's dues (#24), varied ambush hints for LV02, LV05 and LV62 (#42), the critic-clause variety (#30), and rewording EV17-EV27 and EV71 for repeats (#22, #23, no ledger rows yet).

Files: the log of every row (applied, skipped with its reason) is `design/review/WRITING_REVIEW_APPLIED_2026-11-09.csv`; the scripts are `tools/workbook/archive/b15/build_change_list.py` and `writing_review.py`, with the change list `changes.json`. `design/reference/bill_facets.json` gained its serial commas. New canon recorded in `design/CONTENT_GUIDE.md` (Sapporo is the capital; the opposition at the start of the session includes Country Initiative and Keizaijiyuutou), and "room" is now an allowed player-facing word in `design/INFORMATION_STANDARDS.md` (#18). All rewrites are drafts for Cameron.

## Organization names: three more without "the" (2026-11-09, Cameron)

After the writing review, Members of Parliament, Neighborhood Associations and Constituency Voters join Local Kōenkai, Our Traditional Society and Students United as names that take no "the" in a sentence, and Neighborhood Associations takes plural verbs ("Neighborhood Associations want"). 150 opponent, player and transition lines changed (`tools/workbook/archive/b15/no_article_names.py`). The bill-part names CB123, CB134, CB143, CB185 and CB273 and card C16's Japanese name stay as they are.

## Writing review, group 2 content (2026-11-09, Cameron)

The content half of the second group of writing-review items (decisions #12, #15, #31-#33, #37, #55-#58, #66-#68 in `design/review/WRITING_REVIEW_DECISIONS_2026-11-09.md`). Scripts in `tools/workbook/archive/b16/`. All new writing is a draft for Cameron.

| Item | What changed |
|---|---|
| B. BI26 and BI35 | Civil Service Merit Act: Butsutou turns Supportive (16 Aye / 2 Nay / 1 Abstain); the others become Yezo Heritage 1/12/1, Frontier 5/22/0, Five Point 0/5/0, Keizaijiyuutou 1/24/0, Country Initiative 3/8/0, so the totals stay 26/73/2 and the Vote Tally formulas still agree. Butsutou's Floor Vote line is now "A post earned fairly serves everyone." Opponent bill lines carry their own side, so Butsutou members now argue For with no other change; no transition, intro or question named the parties' positions. Political Donation Transparency Act: proposed by the Yezo Heritage Party (still Neutral). |
| C, E. Room questions | 244 questions that name a policy area leave the shared pools for the generic room's own Stage Questions (S2540-S2783): Press 11 (to ST04), Town Hall 110 incl. T32 and T33 (ST05), Lobbyist 82 (ST20), Policy Study 39 (ST21), Media Ambush A21-A22 (ST19). Pools keep 23, 34, 25, 21 and 31 general questions, above every room's turn limit. Kept as general: Q28-Q30, T24, T25, T30, T34, T99, T103, T111, T121-T124, L70, L78, L84, L93, L95, B26, A23-A33. List: `b16_2_moved.tsv`. Note: a room deals its own questions first, so the generic Town Hall (17 questions a stage) now asks almost only the moved, policy-specific ones. |
| F. Reporter lines | The journalists' 48 gain and block line sets become attack sets: 34 lines kept as they were, 206 reworded as a reporter's challenge in the same style, none repeating a journalist's existing line. |
| I. Bill visitors | VQ135-VQ156: choices and replies written for each visitor's own bill (176 cells); costs, effects, promises, reactions and the right answer unchanged. |
| G. Bill-part lines | Two new frame sets per style for player and opponent part lines (`component_frames_v2.py`, which also records today's wording as set A). A part's set follows its slot (X, Z: A; Y, W: B; A, B, C, D, V: C), so the parts of a sponsored bill never share one. 756 player and 756 opponent sets rewritten; set A rows untouched. |
| H. Topic-room lines | PL169-PL528 tagged Support (61 rows), Oppose (77) or blank (222); in the donation rooms the tags follow that the bill restricts donations. New Balance row Player Cues: Room Line Chance = 25. The exporter accepts a Stance on a room's own lines. |
| 7. Candidate selection | New room ST289 Candidate Selection Committee (a copy of the Party Caucus, its people and picture; JP 候補者選考委員会, draft) and a one-room Tier 1 level LV114 Candidate Selection Interview (150/100/50/10 XP, cooldown 96, always listed). S573-S582 now come up only there. |

Test change: `tests/test_stage_rules_columns.gd` now expects ST04's and ST05's question count to be the pool plus their own Stage Questions.

## Rooms with a question pool cap their own questions (2026-11-09, Cameron)

After the writing review moved 244 policy-specific questions into the generic rooms' own Stage Questions, a generic Town Hall would have asked almost nothing else. A room that also has a general pool now deals its own questions for at most a third of what it asks (Balance `Questions: Own Share Percent`, 34; 100 turns the cap off), picked at random each time, and fills the rest from the pool. A room with no pool, or one too small to fill the rest, still uses all of its own. Tests in `tests/test_questions.gd`.

## Project audit and its first fixes (2026-11-10, Cameron)

A read-only audit of the whole project is in `audit/` (seven reports, 55 findings: 5 blockers about shipping, none about game logic). Cameron approved four batches of fixes; what was done is in `audit/07-actions.md`. In short:

- **Art weighs less.** Backgrounds, card art, card frames and characters import as Lossy with a size limit; the source PNGs are untouched. The imported texture data fell from 175 MB to 27 MB. The duplicate `ST22.png` is gone (ST22 borrows ST08's picture).
- **A stage menu.** The stage info panel has three new buttons: **Abandon Level** (asks first; the stage is lost with its ordinary penalties and the level ends), **Settings** (the same text size, Image Scroll and Image Pan buttons as the Office) and **How to Play**.
- **Screen changes fade.** Every change of screen goes through `SceneChange.to()`, with a short fade to black (Balance `Scene Change: Fade Seconds`, 0.12).
- **Tidy-ups.** Developer reports print only in debug builds; one gold-line helper; one constant for the Office scene path; `Layout` no longer rebuilds the party name every frame.

New Text rows: `stage_menu.abandon`, `stage_menu.settings`, `stage_menu.abandon_title`, `stage_menu.abandon_warning`, `outcome.reason.abandoned` (Claude's draft). Tests: `forfeit` and an abandoned level in `tests/test_battle_engine.gd` and `tests/test_level_runner.gd`.

## The Japanese fallback font is shrunk (2026-11-10, Cameron)

`assets/fonts/NotoSansJP[wght].ttf` went from 9.6 MB to 3.0 MB (audit A-07). The new `tools/subset_font.py` keeps every character used anywhere in `data/*.json` or in script strings, all hiragana and katakana, ASCII, Latin, punctuation, arrows and symbols, and the 2,965 common (JIS level 1) kanji as headroom for new names. The full font stays in `tools/fonts/` (not shipped, hidden from the editor) so the tool can be run again. `tests/test_font_coverage.gd` fails the build if a character the data uses is lost, so after adding content with an unusual kanji, run `python3 tools/subset_font.py` (it needs the `fonttools` Python package, which is not a game dependency). Two symbols the data uses, ☼ (every ticker line) and ✕, are missing from the full font too and were already drawn by Godot's fallback; they are unchanged.

## Party dues lowered (2026-11-10, Cameron)

Two Balance rows changed in the workbook: `Dues: Step Amount` 50,000 to 10,000 and `Dues: Reward Percent` 15 to 10. The week-end dues are now 50,000円, plus 10,000円 for every full 15 points of Party support above 40, plus 10% of the Funds earned Monday to Friday. No code changed. `GAME_SYSTEMS.md`, `GAME_DESIGN.md` and `CONTENT_GUIDE.md` updated. The unit tests build their own settings and do not read these two rows. Open question for Cameron: Relaxed's dues share is still 10%, which now equals Standard (Harder is 20%).

## Relaxed dues share 5% (2026-11-10, Cameron)

`Difficulty Relaxed: Dues Reward Percent` 10 to 5, so the tiers stay in order after Standard fell to 10% (Harder stays 20%). A workbook row only; `GAME_SYSTEMS.md` updated.

## National awareness dues relief halved (2026-11-11, Cameron)

`AE01` (National awareness 80 or more) now takes 50,000円 off the base party dues instead of 100,000円, because the base itself fell when the dues were lowered (2026-11-10). A workbook row only; `GAME_SYSTEMS.md` and the awareness test updated. Cameron's workbook upload of 2026-11-10 (two visitor renames and 20 new visitor pictures) was brought in first and re-exported.

## Loss saves, haptics, back button, Tier 0 pay, Resign (2026-11-11, Cameron)

| Item | What changed |
|---|---|
| Result saved when shown | When a stage's result appears it is written to the save (`pending_stage_result`); `finish_stage` clears it. Reopening on a result screen counts the result, so closing the app on a loss no longer gives a free retry. Tests in `test_pending_stage_result.gd`. |
| Gaffe, then threshold | Already how the engine ran; now pinned by two tests (gaffe beats a same-card crossing; a crossing ends the stage before the queued attack) and written in `GAME_SYSTEMS.md`. |
| Haptics | `Haptics.confirm()` on confirming buttons; Balance `Haptics: Confirm Milliseconds` (25); on/off switch in Administration and the stage menu (Text `office.haptics`). |
| Back button | Swallowed in `Layout`; overlays already have Back buttons. |
| Tier 0 stage pay | 18 stage rows used by Tier 0 levels cut to 30,000 (Win ΔYen): ST05, ST06, ST15, ST17, ST20, ST29, ST98, ST122, ST123, ST132, ST133, ST134, ST136 to ST139, ST271, ST273. The six shared with Tier 1 and 2 drop there too, so the Tier 1 average is now 29,143. |
| Resign | New button, rules (`ResignRules`), Balance rows (`Resign: ...`), Text rows (`office.resign`, `resign.body`, `resign.to_title`) and screen (`ResignScreen`). RESIGN.png is a labelled placeholder until the picture is added. |
| Not changed | Losses paying a little XP or Funds is by design (audit T-06 withdrawn); the Funds cap is raised by an item up to 1,000,000, and patron bills do not check Funds. |

## Resign screen in two parts (2026-11-11, Cameron)

The Resign screen now has a crimson "Goodbye" button (Text `resign.to_title`, same style as the Resign button). Goodbye swipes the first part off to the left and a second part in from the right: RESIGN_2.png with the words and button mirrored, then a hold, a fade to black, a pause in black and the title screen. The four timings are Balance rows (`Resign: Swipe Seconds` 0.6, `Hold Seconds` 2, `Fade Seconds` 1 (first draft), `Black Seconds` 2). The mirror is applied to the margin box, because a container resets its children's scale. RESIGN.png and RESIGN_2.png are labelled placeholders until the pictures are added (`assets/backgrounds/`).

## Every button press saves (2026-11-11, Cameron)

`SaveManager` now connects to every button as it enters the game and saves the run once the frame after a press (presses in one frame share one save). It stays silent (no "Saved" flash), does nothing during a stage (the stage's own saves cover that), and does nothing until a run is started or loaded, so a title-screen button can never overwrite the real save with a blank run. A save takes about 1 ms for a new run's 4 KB file (measured). Not covered by a unit test: the save manager is switched off in test runs so tests never touch a real save.

## Resign and title pictures added (2026-11-11, Cameron)

Cameron uploaded `Resign.png`, `Resign_2.png` and `Title.png`. They were renamed to the game's ids (`RESIGN.png`, `RESIGN_2.png`, `TITLE.png`): picture ids are upper case, and a folder holding both `Title.png` and `TITLE.png` would break a checkout on Windows or macOS. `TITLE.png` replaces the earlier 37 KB title picture (still in git history). Screenshots of the title screen and both Resign parts were taken at 1080 x 2340.

## The Funds-cap petition leaves the Marketplace at the ceiling (2026-11-11, Cameron)

Once the Funds limit reaches its 1,000,000 ceiling (`GameState.funds_cap_maxed()`), the Marketplace no longer lists the Funds Cap Increase Petition (SH13), the same way the staff-recruitment, deck-expansion and staff-slot items already leave when maxed. Buying still refuses at the ceiling as a safeguard. Test added in `test_inventory.gd`.

## The TV debate bar shows the opponent again (2026-11-12, Cameron)

TV and radio debates (the `Survival` bar model) now count people like a floor debate: yours, undecided and the opponent's, with the minimum line kept and still judged at the end of every turn. Before, the opponent's Gain did nothing, their Guard had nothing to block and the player's Opp minus cards did nothing, because the bar was one number. Now they all work (`BarModel.counts_people()`). `Opp start` on the 11 Survival stages (ST06, ST41, ST44, ST73, ST84, ST91, ST98, ST205, ST224, ST245, ST271) went from 50 to 25, so a room starts at 60 you, 15 undecided, 25 them (50 would have overfilled the 100 bar). Decisions by Cameron: opponent Gain takes the undecided first and then the player; Opp minus works as in a floor debate. Tests updated and added in `test_battle_engine.gd`. Balance check with the bot (4 runs, indicative): TV and radio debates were won 43 of 51 times (84%), against 684 of 693 (99%) before.

## Your Record: changes behind buttons (2026-11-12, Cameron)

On Your Record, the "(-14) because of ..." text after Constituency support, Reputation, Funds and Party support is gone from the line. Each number that moved last level now has a button beside it showing only the change (for example -14 or -115,820円), the same way Important Stakeholders does. Pressing it opens a panel, titled "<name>: what changed", with one row per factor and its signed amount (commas and 円 for Funds). It shares the stakeholder factors panel (`_open_factors`). The line's 760 px minimum width is lowered to 300 on these rows so the wide Funds button fits.

## Visitor pictures VI46 to VI57 added; V54 renamed (2026-11-12, Cameron)

Ten new visitor pictures arrived (VI46, VI47, VI48, VI50, VI52, VI53, VI54, VI55, VI56, VI57) with their Godot import files. The file uploaded as `V54.png` was renamed `VI54.png` so the game finds it. 57 of the 166 visitors now have a picture.

## The lobbyist's organization always applies scrutiny (2026-11-12, Cameron)

In a Lobbyist Meeting (the rooms that draw from the `lobbyist_meeting` question pool, 13 stages), the opponent's organization (Affiliation) is now always in the list of organizations applying scrutiny, shown first. Before, it was there only about 14% of the time (29 of 200 lobbyist and question pairings in the data), because each question carries its own fixed list. When a question names the organization on neither side, it is added to the organizations the question pleases, so the icon and the real standing effect agree; a question that already pleases or displeases it is left as written. Cameron chose this over a display-only icon and over limiting it to a displeased side, and limited it to Lobbyist Meetings. Tests in `test_battle_engine.gd`. Checked on LV07: the Labor Federation lobbyist's organization (BO09) is first of five.

## A long speaker name no longer pushes the cue band off the screen (2026-11-12, Cameron)

From Cameron's phone screenshot of an Office Hours visit: the speaker tag on the cue banner could not wrap, so "Ainu Language and Culture Foundation Representative" made the band about 1,436 px wide on a 1,080 px screen and pushed it off the right edge, over the choices. `CueBanner._limit_tag_width()` now gives a name that would not fit the band's text width and lets it wrap onto a second line inside its tag; a name that fits keeps its own width. Tests in `test_cue_banner_long_name.gd` use a phone-sized viewport and fail without the fix.

## Items that take hours show a greyed Use button when there is no time (2026-11-12, Cameron)

In the Office item pop-up, an item that expends hours (the Outreach Dinner SH19 and the Walking Tour SH20) used to show a live Use button and refuse only after it was pressed. When there is no time for it, the button is now greyed out and its text gives the reason ("The work week is over." or "Not enough hours left for that."), the same way a level that is too long for the week shows a disabled button with its reason. The rule itself is unchanged (`GameState.item_hours_refusal`, the existing `_hours_refusal`): a full work week refuses; in a weekend, more hours than remain refuses. `Overlay.open` gained a `confirm_enabled` option. Tests in `test_item_use_needs_hours.gd`.

## Items that take hours follow the level rule (2026-11-12, Cameron)

Following Cameron's reply, the time check for an Office item that takes hours (the dinner, the walking tour) and for the Research Assistant's briefing is now the same rule that decides whether a level can be played (`WeekCalendar.level_refusal`): a full week refuses, and so does an item that needs more hours than are left, on a weekday as well as in a weekend. Before, a weekday item was refused only when the work week was completely full. The greyed Use button shows the same reasons ("The work week is over." or "Not enough hours left for that."). A new test covers a 4-hour dinner with 2 hours left.


## A lost Act: the cue, the absent vote, and a 7,488-hour replay timer (2026-11-12, Cameron)

| Piece | What |
|---|---|
| Replay timer | The 50 bill levels (Acts) changed from cooldown 5,994 and One-Time Yes to cooldown **7,488 hours** and One-Time No: about three years, a parliament's tenure at 48 hours a week. Patron, sponsored and drafted bills keep their own rules. |
| Cue | A stage whose loss ends a bill level shows a cue on the battle screen before the result panel (`BattleScreen._show_bill_loss_cue`, `BillLossCue`). Gaffes full: the tongue-tied line ("your staff", or "your party staff" with none hired) with crimson lines. Any other loss: "Your party pulled you away from this bill due to lackluster performance." with lines in the player's party colour. Abandoning: no cue. `CueBanner.say` takes an optional edge colour and the banner has a `drained` signal. |
| Absent vote | A lost or abandoned Act still comes to a vote with the player abstaining (`GameState.record_absent_vote_if_lost_act`). The result goes into the statute book through the normal route, so a passed bill takes effect with its normal Law Effects, and the entry is marked `absent`. |
| The record | Legislative Work shows "<Bill>: passed in your absence." or "failed in your absence."; its pop-up shows the result and "Stakeholders for this bill observed your absence from proceedings." A real vote later replaces an absent entry. |
| Text | Six new rows (`bill_loss.*`, `office.record_law_absent_*`, `record.law_absent_note`). The lines you wrote are verbatim; the two record rows are a Claude draft. |
| Tests | `test_lost_act.gd`. |

## Acts: voted bills stay gone, absent or abstained bills return (2026-11-13, Cameron)

A bill the player voted Aye or Nay on never comes back. A bill they were absent for (a lost or abandoned Act) or abstained on returns after the 7,488-hour replay timer, and a later real vote replaces that entry. `GameState.act_is_settled` leaves a settled Act out of the level list and out of level purchases; `StatuteBook.player_took_a_side` and `is_replaceable` carry the rule. The 50 Act levels keep One-Time No and cooldown 7,488; the Aye-or-Nay case is decided by the statute book instead of the One-Time flag. Tests in `test_lost_act.gd`.

## Transitions for the stages unique to custom bills (2026-11-13, Cameron)

Patron Visit (ST263), Member Visit (ST260) and Lobbyist Trade (ST262), the stages that exist only in patron, sponsored and drafted bill levels, had no transition: no Show Transition flag, no cast, no lines. Cameron chose these three (not Convince Your Colleague, ST261) and staff-only speakers. Workbook rows only, no code: Show Transition is now Yes on the three stages; 126 staff lines (two per stage for each of the 21 staff, written per role: Policy Research Assistant, Media Spokesperson, District Representative); nine lines for the player's own thought when no staff is hired; and three Transition Backgrounds rows (the backgrounds the stages already use: ST07, ST07, ST20). All of it is a Claude draft for Cameron to rewrite. Tests in `test_custom_bill_transitions.gd`.

## Twelve events favorable to six organizations (2026-11-13, Cameron)

From the representation analysis (`design/review/ORG_REPRESENTATION_2026-11-13.md`, `ORG_OUTCOMES_2026-11-13.md`): twelve new Random events, EV83 to EV94, two for each of Taxpayers' Alliance, Chamber of Commerce, Small Business Owners' Association, Financial Industry Association, Innovation Society and Our Traditional Society. Workbook rows only (Events, Event Choices and the twelve Decline result lines in Text); no code. Every event has the usual four choices: A favors the winners at a cost to a named loser, B sends a staff member for half the benefit, C favors the loser instead, D is the Decline (1.5 x the shortfall of sending staff against accepting, rounded half up). Nothing costs Funds or time beyond the event's hours (1, or 2 for EV85 and EV90).

| ID | Title | Winners (choice A) | Losers (choice A) |
|---|---|---|---|
| EV83 | The Auditor's Report Is Out | Taxpayers' Alliance | Care and Welfare Council |
| EV84 | The Budget Hearing Draws a Crowd | Taxpayers' Alliance, Consumer Advocacy Network | Rural Revitalization Council |
| EV85 | The Chamber Hosts a Trade Fair | Chamber of Commerce, Small Business Owners' Association | Neighborhood Associations |
| EV86 | A Foreign Buyer Visits the Port | Chamber of Commerce, Fisheries Cooperative | Labor Federation |
| EV87 | The Shopping Street Wants Late Hours | Small Business Owners' Association | Urban Neighborhood Alliance, Family Network |
| EV88 | The Family Shop Faces a New Rule | Small Business Owners' Association, Our Traditional Society | Consumer Advocacy Network |
| EV89 | The Bank Offers a Small Loan Scheme | Financial Industry Association, Innovation Society | Students United |
| EV90 | A Savings Fair at the Community Hall (weekend) | Financial Industry Association, Care and Welfare Council | Family Network |
| EV91 | The Startup Demo Day | Innovation Society, Students United | Our Traditional Society |
| EV92 | The Data Center Wants the Old Mill | Innovation Society, Chamber of Commerce | Rural Revitalization Council |
| EV93 | The Old Craft Fair Needs Support | Our Traditional Society, Yezo Artisans Guild | Financial Industry Association |
| EV94 | The Hall's Roof Is Failing | Our Traditional Society, Neighborhood Associations | Financial Industry Association |

Also fixed: two Text rows added on 2026-11-12 (`office.record_law_absent_*`) now list their `{name}` placeholder. Next free event is EV95. Every sentence is a Claude draft for Cameron to rewrite.

**What it did to the numbers** (events plus promise outcomes): Chamber of Commerce 1 to 4 events (index 0.85 to 1.04), Financial Industry Association 2 to 4 (0.98 to 1.08), Innovation Society 4 to 7, Small Business Owners' Association 6 to 9, Our Traditional Society 6 to 10. Taxpayers' Alliance rose from 16 to 20 events and stays the most over-represented, still 62% negative (it loses in EV93 and EV94, and every Decline costs the target organization standing).

**Follow-up the same day (Cameron's call):** in EV93 and EV94 the Taxpayers' Alliance's part was swapped for the Financial Industry Association (it is the loser in choice A and the winner in choice C). Taxpayers' Alliance is no longer a loser in any new event, but its net standing is unchanged (it also lost its two gains in choice C): 12 gained, 21 lost, still the most negative organization at 64%. EV83 choice C still costs it 1; removing that is the next step if it should come out ahead.

## Resign screen: slower swipe, longer linger (2026-11-13, Cameron)

Two Balance rows doubled: `Resign: Swipe Seconds` 0.6 to 1.2 (the swipe from the player-facing part to the reversed-text part) and `Resign: Hold Seconds` 2 to 4 (how long the reversed-text part stays before the fade). The fade (1 s) and the black pause (2 s) are unchanged, so the whole sequence now runs about 8.2 seconds, up from 5.6. Workbook rows only.

## Cameron's visitor update: 22 names and titles, 24 pictures, one new visitor (2026-11-13)

Cameron's 2026-11-13 uploads: a workbook update and new visitor pictures (VI58 to VI78, VI144, VI167). In the workbook, 21 visitors (VI60 to VI81) went from "<Organization> Representative" placeholders to named people with titles (for example VI60 Sannyoaino Masanori, Sirur Council Envoy; VI67 Riichi Fukuda, Kita Corporate Group Lobbyist), and VI167 Masashi Mumotsu, Volcanologist, is new. 81 of 167 visitors now have a picture (57 before).

Found and fixed while checking it: VI167 has **no Stage cell**, so its `stages` is null; the game cast that to an Array and every visitor lookup crashed (`DataDB.get_visitors_for_stage`, the data check, and several tests). Fixed: a blank list cell now reads as empty (`DataDB._list_or_empty`), the three test helpers do the same, and the export warns "has no Stage cell, so it never appears in any room". Test in `test_visitor_without_stage.gd`. VI167 still has no stages, rewards, penalty or questions, so it never appears until Cameron fills them. Also: Excel's stale formula chain in the uploaded workbook (Vote Tally & Swing F33 and J33, which hold no formula) was cleared by re-saving through the workbook tool, so the check passes.

Also re-subset the shrunken Japanese font (`python3 tools/subset_font.py`) because the new names use 絆 (Kizuna Ienaga); the font is still 2.99 MB.

## Characters list in Administration (2026-11-13, Cameron)

A new **Characters** button in Administration opens a scrolling list of every opponent and visitor, in two groups (**Opponents**, then **Visitors**). Met people are listed A to Z by name; people not yet met come last, in a fixed order that does not hint at who they are. Tapping a button opens the character: picture, English name, Japanese name (visitors only; opponents have none in the data), title, party and organization.

- **Met** means the person actually appeared: seated in a bout, spoke in a stage transition, or showed up in Office Hours, a member visit or a lobbyist trade. It is saved in the new `GameState.met_characters` (additive; old saves load and start unmet). It is filled when someone appears, not when a level starts, so nobody is spoiled. Opponents faced before this change are therefore shown as unmet until they appear again.
- **Unmet** buttons read exactly **誰ですか。** (Text row `characters.unmet_name`) and keep their colour. This is Cameron's deliberate exception to "Japanese only beside English" (noted in `INFORMATION_STANDARDS.md`).
- **Colours:** an opponent with a named party takes that party's colour. A person whose organization is a party body (Party Headquarters, Faction, Activists, Selection Committee) but who names no party takes the **player's party colour**. Everyone else takes one muted colour per tier of their organization (Constituency, National) or "no organization". These three are nine Balance rows (`Characters colour ... red/green/blue`) in the workbook. A visitor's organization is the first target of their reward list.
- New: `scripts/rules/CharacterCodex.gd` (pure rules), `scripts/ui/CharacterCodexPanel.gd`, `tests/test_character_codex.gd`, eleven Text rows (`characters.*`, `office.characters`). Draft wording for Cameron to rewrite.

## Start-up guide refreshed (2026-11-13, Cameron)

`design/NEW_CHAT_STARTUP.md` updated: current counts, what changed from 2026-11-06 to 2026-11-13 (saves, Resign, dues, lost Acts, the Characters list), and the open items.

## VI167 Masashi Mumotsu gets rooms, standing and six questions (2026-11-13, Cameron)

Chosen by Cameron in a popup; all wording and numbers are **drafts for him to rewrite**.

| Part | Draft |
|---|---|
| Rooms (16) | Office Hours (ST07), Follow-Up, Extended, Open House Day, Receiving Line, Closing Reception, plus Health Fair, Regional Health Forum, Education Forum, Ward Tour, District Tour and the five festival rooms (ST264-266, ST279-280) |
| Reward | Innovation Society +1 to +2, Mayors' Network +1 |
| Penalty | Innovation Society -2 |
| Questions VQ424 to VQ429 | Seismometers, a shared evacuation map, simpler alert levels, a field-station grant, crater-trail closures, an ash plan. Real Hokkaido places only (Mount Usu, Mount Tarumae). Each follows the budget in CONTENT_GUIDE section 6: a friend-pleaser, a rival-pleaser, a middle path and a refusal. One choice per question costs an hour; the evacuation map is a promise of 2 hours within 48 for the Mayors' Network. |

The old test that pinned "VI167 is never offered" now checks that he is offered in Office Hours and asks six questions. The next free visitor ID is VI168 and the next question ID is VQ430.

## A picture behind every scrolling screen: BASE_SCROLLING (2026-11-13, Cameron)

Cameron added `assets/backgrounds/BASE_SCROLLING.png` (flat cream, 1080 x 1350). It now sits behind every panel built on `Overlay` (events, hosted events, information screens, Administration, Characters, shops, the inventory, How to Play and the rest) and behind the battle's Details and card-zoom panels. `BaseImage.install_behind_panel()` puts the picture at the back with a dark tint over it (the same 0.55 the bottom panels use), because the theme's text is light and would not read on bare cream. Both ignore touches, so scrolling and taps are unchanged. With no picture drawn the panels keep their old dark colour. Not changed: the stage-end and visit result boxes (the soft-edged panels over a room picture) and the full-screen scenes that already use `BASE_<SCREEN>.png`. The tint is a draft for Cameron to judge on a real screen. Test: `test_base_scrolling.gd`.

## Characters headings, Scroll speed, Political Pressure (2026-11-13, Cameron)

| Change | Detail |
|---|---|
| Characters list | The group headings read "Those in the arena." and "Those in the community." (Text rows `characters.opponents_heading`, `characters.visitors_heading`). |
| Scroll speed (new setting) | Administration and the stage menu have a "Scroll speed: N" button; one tap goes up a level, 5 wraps to 1. Level 1 is the original speed. It multiplies how far every list moves for the same finger drag, wheel notch and glide (`DragScroll`, rules in `scripts/rules/ScrollSpeed.gd`). The five percentages are Balance rows `Scroll speed level 1` to `5` (100, 150, 200, 250, 300: **draft numbers** for Cameron). Saved in the player's settings file, kept apart from the save. Test: `test_scroll_speed.gd`. |
| Political Pressure | "Campaign Pressure" is now "Political Pressure" everywhere the player sees it (the New Game heading, Your Record, the Administration raise button and its already-at-top line, the Office report line). Code and Balance names (`difficulty_*`) are unchanged. |

## Haze after tapping through cues fixed (2026-11-13, Cameron)

Cameron's report: after several cues were tapped through quickly in a combat stage, a faint haze stayed over the screen (and the Details panel) until the next card. Cause: each cue flashes a full-screen white layer that fades over a quarter second; tapping a cue (`skip()`) or `clear()` killed that fade part-way and nothing reset it. `CueBanner._stop_motion()` now sets the flash back to clear. Test: `test_cue_banner_haze.gd`.

## Move flash behind the player and opponent (2026-11-13, Cameron)

A short glow just outside the character's edge, in the same moment the picture changes: attack, gain, guard, hit, defeat and victory, for the player and for the opponent.

| Part | Detail |
|---|---|
| New workbook tab **Move Flashes** | 12 rows (6 moves x player and opponent): Colour (blank = the character's Characters-list colour, or "R, G, B"), Width (5 px), Strength, Hold and Fade seconds. **Draft numbers** (0.8 strength, 0.15 s hold, 0.65 s fade) for Cameron. More variety later is more rows or a colour in a row. The exporter checks sides, moves, one row each, colours and ranges. |
| Colour | Opponents: `CharacterCodex.opponent_color` (the same rule as the Characters list: party colour, the player's party colour for party bodies, else the tier colours in Balance). The player: their own party colour. |
| Code | `scripts/rules/MoveFlash.gd` (pure), `scripts/ui/MoveFlashLayer.gd`, shader `assets/shaders/move_glow.gdshader` (traces the picture's transparent outline; an undrawn portrait glows around its square). Called from `PlayerPortraitPresenter` and `OpponentPresenter` where the face changes. |
| Behavior notes | The opponent flashes when their face changes (including when a new opponent steps up), not on every redraw. The glow never takes a touch. Test: `test_move_flash.gd`. |

## Member visit uses the Office Hours layout; visitors' Japanese names (2026-11-13, Cameron)

The member visit now lays out like Office Hours: the person's picture big at the top, filling the office window, the name box over its top left corner, and the question and choices in the blank space below. Office Hours and the member visit share one function, `VisitLayout.fit()` (Office Hours' own layout code moved there unchanged). The lobbyist trade followed in the next entry. In Office Hours a visitor's Japanese name now sits under the English name and above their title (muted, hidden when a visitor has none). Opponents have no Japanese name in the data, so the member visit shows none. Test: `test_visitor_japanese_name.gd`.

## Lobbyist trade uses the Office Hours layout too (2026-11-13, Cameron)

Following Cameron's answer on the trade screen: the picture sits on top as in Office Hours, the leverage label and bar sit directly under it, and the lines below move up to fill the space. `VisitLayout.fit(..., fit_to_content: true)` gives the picture exactly the height the rest of the screen leaves it and moves the room picture's lower edge (and the plain panel's upper edge) to meet it, so the deal screen's leverage bar, four rewards, Walk away and Make the deal all fit. The picture is therefore shorter on the deal screen than on the first pick screen, and the name box may sit over its top corner. Checked with the trade click test and screenshots of both phases.

## Continue and Make the deal sit above the BASE line (2026-11-13, Cameron)

On Office Hours, the member visit and the lobbyist trade, the Continue (and "Make the deal") button is 90 px tall instead of 110, and the screen's bottom margin is 90 px instead of 50, so the button ends about 2250 px down a 2340 px screen, above the brush line at the bottom of `BASE.png` (it starts at about 2271 px). Scene edits only (`Safe` margin and `ContinueButton` height in the three scenes); the shared layout code reads both values, and the trade's picture simply takes the space.

## Buttons above the BASE line on every screen that uses BASE (2026-11-13, Cameron)

Audit: each screen that sits on `BASE.png` was opened at 1080 x 2340 and the lowest button measured against the brush line that starts about 2271 px down.

| Screen | Lowest button before | After |
|---|---|---|
| Office | 2250 | 2250 (already clear) |
| Office Hours, member visit, lobbyist trade | 2250 | 2250 (fixed earlier today) |
| Floor Vote (Yes, No, Abstain) | 2290, over the line | 2250 |
| Battle (End Turn; the hand sits higher) | 2290, over the line | 2249 |

The fix is the Safe area's bottom margin, 50 to 90 px, on the battle and Floor Vote scenes. The stage-end and result boxes already keep 120 px, and the full-screen panels use the flat `BASE_SCROLLING` picture, which has no line. `test_base_line_margin.gd` keeps all six screens at 90 px or more.

## Icon uploads wired to their items (2026-11-14, Cameron)

Cameron's 2026-11-13 uploads added nine item icons named after the items (`BOX_OF_AOMORI_APPLES.png` and so on) and re-saved the organization, Sanban and item icons at a larger size. The pictures matched their names, but the Shop tab's Icon column was blank for SH25 to SH33 (the game then looks for a file named after the item ID, `SH25.png`, and shows the blue square) and SH34 still said `deck_expansion`, a file that does not exist. The Icon cells now name the files exactly: SH25 `BOX_OF_AOMORI_APPLES`, SH26 `TSUGARU_LACQUER_CHOPSTICKS`, SH27 `DRIED_HOKKAIDO_SCALLOPS`, SH29 `WAKKANAI_MILK_CARAMELS`, SH30 `WHITE_CHOCOLATE_COOKIES`, SH31 `NEBUTA_FESTIVAL_HAND_TOWEL`, SH32 `BOTTLE_OF_DISTRICT_SAKE`, SH33 `HASKAP_YOITOMAKE`, SH34 `EXPANDED_BRIEFING_BINDER`. Still undrawn: SH28 Wind-Dried Salmon. Test: `test_icon_names.gd` (every named icon is a real, exactly spelled file).

## Salmon icon (2026-11-14, Cameron)

Cameron uploaded the Wind-Dried Salmon picture as `WIND-DRIED_SALMON.png`. Every other icon file uses underscores, so it is now `WIND_DRIED_SALMON.png` and SH28's Icon cell names it. All regional gift items (SH25 to SH33) now have pictures. `test_icon_names.gd` also fails the build on a hyphen in an icon file name.


## Audit hardening, rules in the workbook, dues that bite (2026-11-16, Cameron)

Cameron approved the audit's roadmap items one popup at a time (`audit/roadmap.md`). Done so far:

| Item | What changed |
|---|---|
| E-01 / W-9 | A blank win threshold, start or bar size on a combat room is now an **export error** (it was a warning) and `BattleEngine.setup` refuses such a stage; no fight can fail to end |
| E-02 / C-5 | `int(null)` reads in the battle engine and set-up use `SafeNum` defaults (energy 3, hand 5, gaffe limit 5, card cost 0) |
| E-03 / C-1 | Reading a newer-version backup or undo file no longer switches saving off; only the main slot does |
| E-05, E-06 / C-2 | A loaded save is checked: ranges, a negative clock, a deck of the wrong size, and a text standing are put right (`GameState.sanitize_loaded_run`); Funds above the current cap are kept on purpose |
| W-11 | The exporter now also errors on a Balance lever a script asks for that the workbook lacks, a Text row with no English, an Icon naming a missing file, and a visitor naming a missing stage |
| F-16 / C-7 | `PatronVisit` no longer calls `DataDB`/`Text`; a new `test_rules_stay_pure.gd` fails the build if any rules file reaches an autoload or a file |
| F-25 / C-10 | The button-outline colour follows the protagonist when one is chosen instead of being checked every frame |
| C-12 | The party-body lean on laws is documented in `GAME_SYSTEMS.md` section 8 (intended, Cameron). The rubric tool still expects different numbers for BO01/BO32 on some bills: open, see `audit/followup.md` |
| **W-1** | New workbook tabs **Rules**, **Standing Rules** and **Party Start Standing**. The exporter writes `rules.json`, `booster_standing.json` and `party_standing.json` from them; the values were copied across unchanged (checked identical). Lists and objects are JSON text in the cell; `true`/`false` are booleans. One-off builder: `tools/workbook/archive/w1_rules_tabs_2026-11-16.py` |
| **W-2** | Owing party dues now (1) locks the party's backings and switches the free Party Backing off (Balance `Dues Debt Locks Backings`, new Text row `backing.refuse_dues_owed`) and (2) raises the unpaid-dues Party support penalty from 10 to 30 (**draft number**). In 30-week simulations (3 seeds) a debtor ends near Party support 70 instead of 90 (penalty 20: 80; 40: 29 to 55 and more lost stages). Tests: `test_dues_lock.gd`, `test_audit_hardening.gd` |

Future action item recorded: Party-support-locked events for the player's own party (`design/proposals/PARTY_SUPPORT_LOCKED_EVENTS_2026-11-16.md`).

## Audit follow-up: rewards, rooms, patron lines, save points, numbers in the workbook (2026-11-16, Cameron)

| Item | What changed |
|---|---|
| **W-4** | Level rewards in the Levels tab (columns S to W) are 20% larger on the 31 hardest levels. Draft numbers for Cameron to retune |
| **W-6** | The 15 easiest rooms are harder (Stages tab: threshold, opponent start and gaffe limit moved together; thresholds or energy alone barely changed committee rooms) |
| **W-7** | The sponsor's own lines are shown in the request panel (`RequestLines.patron_line`), with a spoken answer when the player accepts or declines |
| **C-3** | Stage save points checked and proven by `test_save_points.gd`: at the start of a level (now explicit in `begin_level`, it was race-dependent), at each defeated opponent, and when the result is shown |
| **C-6** | Typed-in gameplay numbers in the rules files moved to 12 new Balance rows read through `Levers` (bill positions, special effects, election overdue share, staff severance). `test_no_balance_fallbacks.gd` bans code defaults for Balance keys. Structural constants that are not design numbers stay in code |
| **C-8** | `BattleSetup` can take a seed for its people draws, so audit runs repeat exactly |
| **C-9** | Measured on desktop: `DataDB.load_all()` takes about 0.7 s, JSON parsing about 0.3 s of it (the cue files are the largest). Not a problem at start-up; measure on a phone before changing anything. Tool: `audit/tests/load_profile.tscn` |

Waiting on Cameron: W-3 (Sanban decay), W-5 (card drafts, `audit/w5_card_proposal.md`), W-8.

## W-5 card power changes applied, W-3 left as is (2026-11-16, Cameron)

Cameron approved the recommended Draft 2 (`audit/w5_card_proposal.md`) without the C41 change. Cards tab: C63 Opp −9 to −6, C64 −11 to −9, C65 −11 to −8, C67 Gain 11 to 8, C69 Gain 10 to 7; C04, C16 and C44 cost 3 to 2; C20 gaffe +3 to +2. Effect text updated to match. W-3: Cameron keeps the current Sanban decay values (no change).


## Staff wages, Loyalty, daily Staff Assignments and event delegation (2026-11-16, Cameron)

Built from the two proposals in `design/proposals/` (`STAFF_LOYALTY_2026-11-16.md`, `STAFF_ASSIGNMENTS_2026-11-16.md`) after Cameron's answers. Details in `GAME_SYSTEMS.md`, "Addendum 2026-11-16: staff wages, Loyalty, daily tasks and delegation".

| Phase | What |
|---|---|
| 1 Wages and Loyalty | Weekly wage (10% of invested), Loyalty from 30, Restless and About to leave, rank loss, resignation, severance 3 x hire price, Raise pay, Thank in public; the profile shows Loyalty and why it moved; the week-end popup lists wages |
| 2 Task pool | New **Staff Assignments** tab (17 tasks, 8 icon families LL01 to LL08), `StaffTasks.gd`, a seeded daily pool, projection and resolution from one function |
| 3 The screen | Management > Staff Assignments: cards with an 8-block workload bar and a drop box, task icon popup, projection, Confirm, and a day report |
| 4 Delegation | Event Choices gains `Delegate Role` and `Delegate Blocks`; 42 "send a staff member" choices name a role; a "Who goes?" screen |

Also: the Save button-hook no longer connects a re-added button twice. Tests: `test_staff_loyalty.gd`, `test_staff_tasks.gd`, `test_staff_assignments_view.gd`, `test_staff_delegation.gd`. Open for Cameron: the draft task numbers and the 42 role assignments, gifts as recognition, the Restless/leaving bands.

## BASE pictures undimmed; staff text and pictures reviewed (2026-11-16, Cameron)

- **BASE tint removed everywhere.** `BaseImage` no longer lays a dark navy tint over `BASE_SCROLLING.png` (every scrolling panel) or makes the bottom panel of the BASE screens translucent-dark (it is now clear, so `BASE.png` shows as drawn). Over the scrolling panels each line of text gets its own dark translucent plate instead (`BaseImage.plate_theme()`), so the picture shows between and around the lines. The other BASE screens keep their own boxes behind their text. A theme with no plates is used inside dark cards.
- **Staff text to current norms.** Informational lines on the Staff Assignments screen, the Staff list and the profile were 26 px small text (about 10 sp on a phone); they are now body size (34 px). Section headings in the task popup are headings. The fit is said in words under each placed icon as well as by the frame colour; the fit colours are brighter for contrast. The person's name is a 90 px touch target. Staff pictures on the assignment cards are large (up to 340 x 640, as large as the profile's picture allows beside the task box).
- **Every word editable in the workbook.** The "XP" and awareness names in projections are Text rows; the posts and committee phrase that find ministers and committees in the opponents' Title column are Rules tab rows (`staff_task_official_prefixes`, `staff_task_committee_marker`); task titles, context and work are the Staff Assignments tab; effect names in that tab are fixed keywords (the four meta names, XP, District awareness, National awareness, Standing, Loyalty, Loyalty all).

Task popup redesign (2026-11-16, Cameron): the outcome is three slanted colour-coded blocks (positive, neutral, negative) with no staff role named; staff are large pictures in a gold-framed row that scrolls sideways (tap to give); a No Assignment button takes the task back; Close is at the bottom. New `SlashBlock.gd`.

## Staff Assignments: hours, Assign To, roles, items for staff (2026-11-16, Cameron)

"Blocks" is now "Hours" everywhere the player reads it (the Event Choices column is `Delegate Hours`). The task popup says "Assign To", its Time cost is one line ("Time cost" left, "3 Hours" right), and each staff picture shows the person's role with no fitness colour. New: the **Items for your staff** row at the top of the screen (coffee +1 hour, tea +1, Kaiju-sized +2), one item per person, drag into their box, used up when the day is confirmed. New Shop column `Staff Hours`; tests `test_staff_items.gd`.

Staff pictures in the popups are wider and taller (340 x 580) with room for a name and a role on two lines each, so the longest names and "Policy Research Assistant" show in full. Cameron's icons `LL01` to `LL08` are in `assets/icons/` and show on the task cards.

Task family names (2026-11-16, Cameron): a one-word `Family` column on the Staff Assignments tab (Correspondence, Press, Analysis, Meetings, Constituents, Administration, Chores, Rest) shows under each task icon in a staff box in place of the fit note.

## Staff tasks expansion, phases 1 and 2 (2026-11-16, Cameron)

From `design/proposals/STAFF_TASKS_EXPANSION_2026-11-16.md`.

| Part | What |
|---|---|
| 47 new tasks | 64 in all, 8 per icon family (Claude's draft names, text and numbers). Rest has eight time-off variants (1 to 4 hours of the person's day) |
| Staff Task Families tab | Each family's daily Min, Max, Cap and Weekend Factor |
| Staff Task Ramp tab | The most tasks a day delivers by week: 0, 1, 2, 3, then 15 |
| The draw | `StaffTasks.draw_pool` rolls each family, picks its tasks, then trims to the day's maximum (a family's chance follows the count it rolled) |
| No staff, ignored days | Tasks arrive with no staff hired; every delivered day's Due tasks cost their penalty at day end, confirmed or not; the player sees a report |
| Retired | Balance rows `Staff Tasks: Pool Size` and `Weekend Pool Size` |

Tests: `test_staff_tasks.gd` (quotas, ramp, trim, no-staff, ignored days) and the other staff tests now use a fixed day. Next (not built): drivers, person items, pool items, gift tastes.

## Staff tasks expansion, phases 3 to 6 (2026-11-16, Cameron)

| Phase | What |
|---|---|
| 3 Drivers | New Staff Task Drivers tab (14 draft rows); `StaffPoolModifiers.gd`; the screen says why the day looks as it does and how many tasks it may deliver |
| 4 Person items and gifts | Seven Reference Sets, Training Voucher, Quiet Desk Pass; the nine regional gifts now work as Loyalty gifts; gift tastes (likes, dislikes, per-person Loyalty) on all 21 staff, revealed by giving a gift |
| 5 Office box | Eight Office items change the next pool; event choices can too (Task Pool columns); the Office box on the screen |
| 6 Tuning | `audit/tests/staff_pool_sim.tscn` and `audit/staff_tasks_tuning.md`: no numbers changed; the week 4 to 5 step is a cliff you may want to smooth |

New Shop columns (Staff Effect, Value, Target, Slot, Days), Staff columns (Gift ...), Event Choices columns (Task Pool ...), Balance rows `Staff Gift: ...`. Fixed: a staff task's awareness change now reaches the right meter. Tests: `test_staff_pool_modifiers.gd`. New items have no pictures yet (the blue square shows): name the file in the Shop tab's Icon cell when drawn.

The "Most tasks today" and "why these tasks today" lines are no longer shown on the Staff Assignments screen (2026-11-16, Cameron): they are working detail, kept in the run state only.

Staff Assignments testing rubric (`design/STAFF_ASSIGNMENTS_RUBRIC.md`) and its first evaluation (`audit/staff_assignments_rubric_run.md`, tool `audit/tests/staff_rubric_run.tscn`) (2026-11-16, Cameron): 20 back-to-back days, 20 days at full volume and 10 days interrupted by levels. Findings: the ramp strands staff (Loyalty), rewards run richer than intended, levels cost most of the staff value. No game numbers were changed.

Rubric follow-up (2026-11-16, Cameron: "Both"): `Staff Tasks: Cap Meta` 3 to 2, `Staff Wage: Percent` 10 to 15, Funds rewards on five tasks roughly halved. Funds now PASS the rubric; net points a week still FAIL (XP). See `audit/staff_assignments_rubric_run.md`.

Rubric fixes 1 and 3 (2026-11-16, Cameron): idle Loyalty loss only when work was left that would have fitted, and new hires start at Loyalty 50. The ramp weeks now pass the rubric (R1.7, R5.6). Remaining: net points a week (XP).

XP cap (2026-11-16, Cameron, rubric R4.2): `Staff Tasks: Cap XP` 6 to 3. R4.2 moves from FAIL to WARN; the rubric now has no FAIL. R6.4 left as is.

Staff rank adds working hours (2026-11-16, Cameron): Tier 0 works 8 hours, Tier 1 works 9, Tier 2 works 10 (Balance `Staff Tasks: Hours Per Tier`), counted from the rank held when tasks are given out; stacks with coffee and tea; no weekend bonus.

Dragging a staff item or task card (2026-11-16, Cameron): the whole card is carried as one piece (frame, picture and words) and held up and to the left of the finger instead of below and to the right. `test_task_chip_drag.gd`.

Words stay whole (2026-11-16, Cameron): wrapped text no longer breaks in the middle of a word and leaves a hanging letter. The `TextFit` autoload looks at every wrapping label and button once it has its real width, wraps at word boundaries only, and shrinks the type a size at a time (down to Balance `Text Fit: Minimum Font Size`, 20) when one word is wider than its box; only if even that fails does it allow a split. Cards are left alone. `WordFit.gd` measures; tests `test_word_fit.gd`. The Staff Assignments empty-box notes no longer force the screen wider than the phone.

Kaiju-sized coffee and tea (2026-11-16, Cameron): now Office box items that add +1 hour to every staff member today (Shop effect HOURS_ALL); regular coffee and tea stay one-person items.

## Items with uses, and six office-supply items (2026-11-16, Cameron)

| Piece | What |
|---|---|
| Uses | New Shop column **Uses** (blank = 1). A copy has that many uses; one use comes off the **most-used copy first**; at 0 the copy is thrown away and a line says so. Handing an item over (gift, promise) removes a whole copy. Run state `item_uses`, saved; old saves and starting items get full uses (`ItemUses.gd`, `GameState._spend_use`, `item_copies`) |
| Shown | Staff item cards ("· 2 uses left"), the item popup ("Uses left: 2 of 3"), Inventory (uses on each copy), Marketplace ("3 uses") |
| Kaiju-sized coffee and tea | 2 uses each; one use is spent per confirmed day in the Office box, each use gives every staff member +1 hour that day |
| SH36 Printer | Office, 3 uses. Used at once: adds 3 tasks to today's list, past the week's maximum |
| SH37 Shredder | Office, 3 uses. Used at once: clears up to 3 tasks nobody has been given and that are not Due, at random |
| SH38 Flex-Work | Person, 3 uses. The best-paying task that person completes pays double; +2 Loyalty |
| SH39 Priority Inbox | Office, 1 use. Used at once: today's tasks are drawn again, given tasks included |
| SH40 Commendation Gift | Person, 1 use. No Loyalty change from an idle or overworked day |
| SH41 Lunch Delivery | Person, 1 use. None of a weak fit's penalties |

The 17 draft staff items SH36 to SH52 are replaced. Prices are drafts (6,000 to 20,000円). Item pictures (`SH36.png` to `SH41.png`) are to come from Cameron; the Icon cells are blank until then. Builders: `tools/workbook/archive/shop_item_uses_2026-11-16.py`, `item_uses_text_2026-11-16.py`. Tests: `test_item_uses.gd`; `test_staff_pool_modifiers.gd` and `test_staff_items.gd` updated.

## Documents refreshed; the last fixed numbers and ids moved into the workbook (2026-11-17, Cameron)

| Piece | What |
|---|---|
| Documents | `NEW_CHAT_STARTUP.md` (counts, what was done, open items), `GAME_SYSTEMS.md` (person items, Office box, new state tables for staff and item uses, numbers section, where the player chooses), `GAME_DESIGN.md` (Staff Assignments and item uses), `ARCHITECTURE.md` (staff and item code), `CLAUDE.md` (snapshot counts, data files, guide list), `CLEANUP_CANDIDATES.md` (unused staff effect code and columns) |
| Scan | Every script was searched for design numbers and ids typed into code, and every `.get("key", default)` was checked against the data. Nearly all of it was already in the workbook; the rest were runtime state keys, which are not design |
| Balance (new) | `Staff Loyalty: Restless Boost Percent` 50 (a Restless person's boosts were fixed at half), `Patron Request: Tries` 2 (a request lapsed after a fixed two tries) |
| Rules (new) | `training_coupon_item` SH21, `bill_vote_stage` ST23, `party_dues_hq_organization` BO01, `party_dues_selection_organization` BO32 (were typed into `GameState` and `BattleSetup`) |
| Tests | `test_balance_keys.gd` now also checks every `get_rule("...")` key and that the four id rules name rows that exist |

Known and left alone: the majority of 51 in two places (canon), default fallbacks used only when a data row is missing (`50` starting standing, `3` energy), and the 0 to 100 range of Loyalty.

## Card faces readable everywhere; the question banner steps aside from the zoom (2026-11-17, Cameron)

Design review of 2026-11-17: card fronts and backs were dark with dark text in Rhetoric Training, the Office card View and the battle zoom, while the hand was fine. Cause: every panel built on `Overlay`, and the battle's card zoom, carry `BaseImage.plate_theme()` (a dark translucent plate behind every Label, added when `BASE_SCROLLING` arrived on 2026-11-13); the card's own Labels inherited it, so ink sat on a dark plate. Each card label (`CardView`, `CardBackView`) now overrides its plate with an empty box (`CardView.no_plate`). The cue banner, which lay across the zoomed card, is hidden while the zoom is open and returns when it closes. New real-screen test `tests/interaction/card_faces_test.gd` renders a front and back of each of the six suits in the hand, the Rhetoric Training offer, the card View and the zoom, and fails if the effect-text area is more than 10% darker than the plain face or its ink contrast is under 4.5 to 1 (measured from pixels; the faces measure 7 to 15 to 1). Decisions (Cameron): the question's grade and the room's affinity stay off the zoom (INFORMATION_STANDARDS section 1 reworded to match), and no "people reached" range. Report and shots: `design/review/p2_card_faces_2026-11-17/`.

Round 2 of the same panel (2026-11-17): the zoom no longer just hides the cue banner. `CueBanner.set_suppressed(on)` pauses its hold timer and its slide, flash and jolt tweens and hides the band and flash; on release the same line returns with its remaining hold, the queue is untouched, `lines_shown` does not move while the zoom is open, a band that was not showing or was cleared meanwhile stays hidden, and a line said during the zoom waits for the release. New real-screen test `tests/interaction/cue_zoom_test.gd` (it fails on the old visibility toggle). Also: `design/review/` and `design/proposals/img/` now hold a `.gdignore` so Godot no longer imports review pictures, and their 34 `.import` files were deleted (Cameron, 2026-11-17).

## Text sweep: every screen readable at every text size and screen shape (2026-11-17, Cameron)

Panel P3. At Large text the Floor Vote's title wrapped one letter per line and pushed the whole screen off the bottom, so the vote could not be read or cast. New checker `tools/text_sweep.gd` / `tools/text_sweep.sh` (documented in ARCHITECTURE) sweeps about 50 screens at 1080 x 2340 and 1080 x 1920 and at Small, Normal and Large text for letter-stacking, off-screen text, overlapping text and small buttons; verify.sh (full run) now fails on the first two (Cameron's choice). Fixes, layout only: the Floor Vote title and header expand (`FloorVoteScreen.tscn`) and its scroll area is lower; the Office front page and the Level Intro are inside a scroll box; the character pictures are **never made smaller** (Cameron: "don't minimize the character images"): when the screen is short or the text is big, `PortraitBehind` lifts the picture out of the column, draws it full size behind the text and the text lies over its lower part (the Office's text blocks already carry a translucent plate; the Level Intro gets a faint one, `BaseImage.faint_plate_theme`); then the Office's calendar and dues boxes turn compact, and only then does the page scroll ("compact first, then scroll"); the Promises button follows the dues box's real height. Before 39 letter-stacking or off-screen rows (Large text) and 45 overlap rows; after, none of the first two and no overlap rows on these screens. Report only, unchanged: 90 px buttons in most lists. Files: `design/review/p3_text_sweep_2026-11-17/` (`sweep_before.csv`, `sweep_after.csv`, before and after pictures).

## Information standards, panel P4 (2026-11-17, Cameron)

Item 1, the week-over popup: before the player chooses Work the Weekend or Pay Party Dues and Go Home it now says what going home costs and pays: this week's dues (base for Party support, the share of the week's earnings, any National awareness relief), dues still owed from earlier weeks, staff wages, Funds now and after dues and wages, and, when Funds fall short, the shortfall, the Party support and standing penalties and the party backings that would be withdrawn, and that standing settles back. `GameState.week_end_preview()` works the numbers out with the functions that settle the week (`PartyDues.settle`, `overdue_penalties`, `party_backings`, `StaffLoyalty.pay_order` and `settle_wages`), and `tests/test_week_end_preview.gd` checks the preview against what `go_home()` then charges (Funds covered, dues short, wages short, awareness relief, dues holiday). Wording is draft Text rows `office.week_cost_*`. Shots: `design/review/p4_information_2026-11-17/item1/`.

Item 2, costs above the Funds limit: Draft a Bill and any Marketplace item priced above the Funds limit now say why they are greyed and what raises the limit. The draft button reads "Drafting costs 300,000円, more than your Funds limit of 100,000円, so you cannot afford it yet. Buy the Funds Cap Increase Petition in the Marketplace to raise the limit." (`DraftBill.refusal`, `Items.buy_refusal`; the petition is found by its Funds Cap Increase column, not its id). Text rows `draft.cost_over_limit` and `shop.funds_over_limit`, drafts for Cameron. Tests in `tests/test_week_end_preview.gd`. Shots: `design/review/p4_information_2026-11-17/item2/`.

Item 3, the Marketplace header: when Funds are at (or above) the limit the header now adds one line, in Cameron's wording: "Earnings exceed the approved limit. Request a Funds cap increase. Excess funds go to the parliament pension program." (Text row `shop.funds_limit_note`, draft.) In real play Funds are clamped to the limit, so "above the limit" in the review shots was a hand-set state. Test in `tests/test_week_end_preview.gd`. Shots: `design/review/p4_information_2026-11-17/item3/`.

Item 4, contrast: party names in their party colours now sit on a plate chosen per party (light or dark, whichever reads better), so the hues are untouched. Applied at the party title, the party picker, the Parties heading and the allies heading, and to the Scrutiny, Pleased and Annoyed icons in Details (a light plate behind each icon group). Measured from screenshot pixels: party names 4.6 to 15.5 to 1 (Butsutou 8.3, Yezo Heritage 15.5, Frontier 4.6, Five Point 5.6, Keizaijiyuutou 4.8, Country Initiative 5.7; target 4.5), Details icons 16.6 to 1 (target 3). New: `PartyLabel`, `IconPlate`, `PartyDisplay.plate_for`, tests `test_party_plate.gd` and `party_plate_test`.

Item 5, the win result: the two organization icons seen "behind" Taken care of were the battle screen's listening strip showing through the result panel (the panel is 85% opaque). The strip is now hidden once the stage is over. The question band was checked first with a capture 8 seconds later: it times out by itself (gone in the second shot), so it was left alone. Layout only.

Item 6, Staff Assignments items: the Office box note (`assign.office_hint`) now says that items which act at once (Printer, Shredder, Priority Inbox) are used from the Items row and take effect immediately; only Office-slot items placed in the box wait for Confirm. A Staff Assignments item opened in the Marketplace or Inventory pop-up now says "Use this on the Staff Assignments screen." (`item.refused.staff_screen`) instead of "This can't be used here.", and no longer shows the untrue "Takes effect immediately." line there. New `Items.is_staff_item`, with a test. Both are Text rows (drafts for Cameron).

Item 7, Election Strength: Cameron said no, so the eight bars stay as they are. Nothing changed.

## UI styles and End of Week Payments, panel P9 (2026-11-17, Cameron)

What is in, what is not. See `design/review/p9_ui_styles_2026-11-17/REPORT.md` for the acceptance table.

- **Framework (A1).** A `ui_style` cosmetic slot; a `UI Style` column on Cosmetic Packages and a new **UI Styles** tab (colours, fonts, radii per style, seeded from the proposal's tokens); `UiStyles`, `UiStyle`, `UiStyleTheme`; three theme overlays; three fonts added (Barlow Condensed Bold Italic, Shippori Mincho B1, Zen Kaku Gothic New, Latin subsets, SIL OFL; Japanese falls back to Noto Sans JP). Living Office is the default; the style is saved with the run.
- **End of Week Payments (A2).** The Office dues box is now one total of party dues plus staff wages with its two parts and the Funds on hand; a tap opens the breakdown (each person's wage, raised pay marked, what is still owed, Funds after paying, who goes unpaid and what it costs); the same breakdown shows in the week-over pop-up before the choice. `WeekPayments` (pure) calls the same functions the week end settles with; `tests/test_week_payments.gd` checks the preview against the settlement line for line, including raised pay and a shortfall. Five old Text rows retired through the workbook.
- **Living Office, battle seats (A3, first part).** Seats in a semicircle for a room of people (20 seats of 5, rows 12 and 8, Balance rows `UI Style: Seat Count` and `UI Style: Seat Outer Row Percent`); a continuous arc, filled like the regular bar, for the press tone and percentages (Cameron's note).
- **The hand (all styles).** The cards overlap so every card of 3 to 6 shows; no sideways scroll needed.
- **Buying and switching (B3).** A Marketplace **Office styles** tab (swatch, description, state, unlock with a reason when refused, use this style), a row in Administration › Appearance and Music; Broadcast and Woodblock cost 1 XP each (placeholder, for playtesting).
- **Round 2 (Cameron's picks: Living Office first, rooms placed by Claude, Woodblock plaques):**
  - **Room objects.** In Living Office five Office buttons (Events, Reputation and Results, Promises, Office Management, Marketplace) become lamp pins on the picture, placed from a new hand-written `office_hotspots` key in `data/art.json` (one set for `OFFICE`, one for `OFFICE_UPGRADED`, fractions of the screen). They are the SAME buttons, moved, so every name, count and refusal reads the same; each pin is 122 px tall with its label always showing. The Start button is the paper docket card. The positions are Claude's first placement for Cameron to adjust. Labels are the destination names (the mockup's "Phone ·" object words would show different text in one style).
  - **Levels as manila folders** (Living Office): the first room's picture, the name, the hours (shown under every level's name in every style) and the button or the reason it cannot start; a folder that cannot be started is dimmed.
  - **Intent tag.** The opponent's line ("Attacking · -1 to -2") is a red pill (Living Office), a square tag (Broadcast) or a vermilion tag (Woodblock).
  - **Speech-bubble cue** (Living Office): a paper bubble in dark ink, no gold lines, same timing and tap to skip. **Hanging-scroll cue** (Woodblock): paper between two rods. Broadcast keeps today's band with its gold lines.
  - **Woodblock plaques** replace the halo: each label carries a light paper plaque, so dark ink reads over a picture.
- **Finishing the design (Cameron: "Finish this design first").**
  - **Broadcast Office:** the Start button is a gold slanted bar; Events, Promises, Office Management and Marketplace are a 2 x 2 grid of navy tiles with a gold edge; Reputation and Results is a wide bar with Administration beside it; the name is a slanted lower-third with a gold rule and the narration a strip with a red edge.
  - **Woodblock Office:** the Start button is an indigo plank with a red seal edge; the six destinations are a 3 x 2 grid of paper plaques with indigo tops; the name is a cartouche with a red offset shadow; the calendar and payments boxes have red seal edges.
  - **Levels:** Broadcast rows are schedule strips with a gold hours chip and the level's picture; Woodblock rows are print cards with a framed picture and a red hours seal.
  - **Battle:** room and turn plates and the End Turn button per style (amber pill and rounded plates in Living Office; slanted gold bar and plates with a gold rule in Broadcast; indigo plank and cartouches in Woodblock).
  - **Card fan:** Living Office tilts the hand's cards a little about their bottom centre.
  - **Text sweep in all three styles.** `tools/text_sweep.sh` takes `SWEEP_STYLE`; `tools/verify.sh` runs it for Living Office, Broadcast and Woodblock. It found a sideways scroll in Broadcast's levels list and a broken party name in Woodblock's Floor Vote, both fixed.
  - Everything in the Broadcast, Woodblock and Living Office mockups is now built, except the pieces listed in the report (folder-divider tier tabs, hours rings, picture previews in the styles shop).
- **Review of P9 (Cameron's panel), answered.**
  - **Blocker fixed:** the +/-/0 marks over the organization icons carried Woodblock's paper plaque, hiding the icons while a card was held. Marks now carry no plaque (`test_org_marks`, `org_marks_test`, which fails without the fix).
  - **Built (Cameron: "build all of them"):** Woodblock's 攻/守/得 intent seal (drawn, follows the opponent's move); Broadcast's gold diagonal between the characters; a docket card in every style (title, "N hours left this week", a folder and chevron in Living Office, a chevron in Broadcast, a red 行 seal in Woodblock); Living Office's payments tray (Funds left, payments right); Woodblock's ledger lines with dotted leaders; tier headings as tabs (a divider tab, a gold chip, a stamp) and a styled Draft a Bill tab; the hours left at the top of the Levels list.
  - **Hand (Cameron: raise the touched card):** a touched or held card rises 44 px and is drawn over its neighbours, so its full face and name can be read (`hand_raise_test`). The hand no longer clips, so raised and tilted cards show in full.
  - **Styles are bought in the Marketplace only (Cameron's pick):** Administration > Appearance and Music only switches between owned styles; its row is "Office styles", the same as the tab.
  - **Smaller:** a mark at the threshold on the seats; "1 of 2" and "Turn 1 of 10" use no-break spaces so the number is not left alone on a line; organization icons get a dark backing (Broadcast's measured 2.7 to 1, now 3.7 or more); a level that cannot be started dims only its picture, so the reason on its button stays at full strength.
  - **Evidence added:** week-end pop-up, a Levels list late in the week with levels that cannot start, a touched-card moment, and icon contrast per style measured from pixels.
- **Hour rings (Cameron: "Build the hour rings").** In Living Office each level row has its hours in a ring at the right of the folder: amber when the level can be started, red and tilted when it cannot (the reason stays on the button). The ring holds the same "N hours" line every style shows, moved rather than rewritten, so the same-information rule holds. Test: `style_elements_test`.
- **The last gaps closed (Cameron: "Finish the remaining gaps, use a screenshot for the preview").**
  - **Styles shop previews are real screenshots** of the Office in each style (`assets/ui_styles/preview_<style>.png`, see its README to retake them), replacing the colour swatches.
  - **Room-object words on the Living Office pins** ("Phone", "Bookshelf", "Notice board", "Front desk", "Errand list"): a small label of its own above each destination, so the button still reads only the destination. The parity test lets this one label through, as the room metaphor's decoration.
  - **Draft a Bill is a dashed tab** in Living Office: a dashed frame drawn over a paper tab (`StyleMarks.DASHED_FRAME`).
  - (Corrected later: five mockup elements are still not built; see the review follow-up below.)
- **The intent line is a pill, coloured for the opponent's party (Cameron, 2026-11-17).** In every style the opponent's intent ("Attacking · -1 to -2") is a floating pill as wide as its words (it was a full-width band). Its fill is the opponent's party colour when the opponent has a party that is not the player's; with no party, or the player's own party, it is the default red, `intent_default` in the UI Styles tab (#8C1D2F, a deep crimson). That default is held well apart from Keizaijiyuutou's red (255, 0, 0): `test_intent_pill` requires a distance over 100 from it and over 55 from every party colour. The ink is light or dark, whichever reads (4.5 to 1 or better on every party colour). It follows the opponent who is speaking, so each floor debater gets their own party's colour. New: `IntentPill` (rules), `test_intent_pill`, `intent_pill_test` (every style, four cases, read from the style box and the rendered pixels).
- **Review follow-up (all minor).** The report said nothing from the mockups was missing; five elements are: Woodblock's wave pattern and framed print, Broadcast's split character cut-ins, Living Office's page-a-day calendar and narration bubble. The report now lists them. The opponent was two colours (party-coloured pill, red seats and bar); the seats and bar now use the pill's colour, with a thin light ring on each seat. Every shot was retaken (three stale Living Office "short" Office shots and three stale "can't start" Levels shots among them). New tests: `hand_input_test` (a tap on a raised card still opens the zoom, a drag still plays it, the card settles) and, in `intent_pill_test`, the pill's text contrast for every party colour and no party, in every style.
  - Icon backings now follow the icon: a dark plate behind a light organization icon and a light plate behind a dark one (`IconBacking`, `test_icon_backing` over every organization icon), after a single dark backing left some icons at 1.8 to 1. Seats get a ring chosen the same way (yours 6.1, undecided 4.9, opponent 7.0 against it).
- **The five remaining mockup elements, built (Cameron: "build all five now"; the calendar adopts Era and Ainu).**
  - **Living Office page-a-day calendar:** a tear-off page with a red header strip (the weekday), the date and hours on paper, and a curled corner. It reads the same sources as the square, `GameState.calendar_date_text()` and `calendar_weekday_text()`, so it shows plain dates (Monday 月曜日 / 18.10.01), **Era** years (月曜日 / 平成30年10月1日) and the **Ainu** form (クンネチュプ / 2018.ウレポク.01) exactly as the square does; a long date wraps inside the page. `style_elements_test` checks all three against the calendar's own text.
  - **Living Office narration bubble:** the Office narration is a rounded paper bubble in dark ink with a tail toward the protagonist. A theme on the bubble gives every line, including lines added later, dark ink (a first version left late lines in light ink on paper; a check now fails on that).
  - **Woodblock wave (seigaiha) band** along the foot of the Office and the battle, drawn behind the content so it never covers text, and the **framed print** (indigo frame, paper mat, red offset shadow) round the Office portrait and the battle's character area, with the characters breaking its lower edge.
  - **Broadcast split cut-ins:** two slanted shots behind the characters, yours in blue and the opponent's in their pill colour, divided by the gold diagonal with gold rules top and bottom.
  - All are drawn marks (`StyleMarks`): no art files, no new words, so the same-information rule holds.


## 2026-11-17: A held card no longer covers the Guard and Gaffes counters

- While a card is held it rises only as far as just below the Guard and Gaffes counters, in every style and screen shape. Playing it still needs the same drag distance. No rule or number changed.
- `hand_input_test` now checks mid-drag that the card does not overlap either counter. The nine mid-drag battle shots in the P9 review folder were retaken.

## 2026-11-17: Woodblock status labels get the same plates as the room and turn labels

- In Woodblock, the speaker line, the threshold line, the tally, Guard and Gaffes now sit on paper plates with an ink edge and a vermilion offset shadow, like the room and turn plates at the top. The plates and their shadows are 10% see-through. The Inventory and Details buttons and the other styles are unchanged. No words or rules changed.

## 2026-11-17: A party-colour halo shows when a drag is past halfway

- Once a held card has been pulled halfway to the distance that plays it, a glow and outline in the player's party colour fade in behind it, reaching full strength when letting go would play the card. It disappears on release. Purely visual: no rule or number changed. Shots: `*_battle_2340_halfway.png` in the P9 review folder.
- `hand_input_test` checks there is no halo before halfway, some at 80% of the pull, and none after release.

## 2026-11-18: New Game screen: swipe strips for difficulty and theme, even portraits; marketplace and coupon fixes

- **New Game screen:** the three difficulty buttons (their descriptions removed) are now square buttons in a strip you swipe sideways, and beside it a second strip does the same for the display theme (Living Office, Broadcast, Woodblock). Picking a theme restyles the screen at once and the choice carries into the run: the chosen style is free here, owned from the start and equipped. A back-out from New Game in Administration restores the run's own style. Rules unchanged; the XP prices in the Marketplace stay.
- **Portraits:** the four protagonists are cropped to the visible figure and held to one height, so none looks smaller.
- **Party names:** Keizaijiyuutou (pure red) now sits on the light plate (3.6 to 1) instead of black; the plate rule is 3 to 1 on the light plate and 4.5 to 1 on the dark one. The party colour itself is untouched.
- **Rhetoric Training coupon:** Learn it says "Free" instead of an XP price (nothing was ever charged).
- **Marketplace:** an item above the Funds limit shows a greyed button reading "Insufficient Funds", not the long sentence. The header note about the limit is unchanged.
## 2026-11-18: A held card stays on top of its neighbours

- Pressing a card raised it above the others, but the moment the drag began it dropped back underneath the card on its right (starting a drag releases the press, which reset its layer). A held card now keeps its place on top until it is dropped. Visual only.
- `hand_input_test` now checks mid-drag that no neighbouring card is drawn over the held one (it fails without the fix).

## 2026-11-18: Every card takes two taps

- A card that would move organisations already took two taps (the first raised it and showed the listening strip, the second opened it); a card that moved nobody opened at once, which read as inconsistent. Now every card takes two taps: the first raises it to the front and selects it (with the organisation preview when it has one), the second, or Read, opens the popup (Cameron's choice, 2026-11-18). No rule changed.

## 2026-11-18: Battle bars: seats for people, a continuous arc for everything else

- The stage data says which battles measure a share (Bar Value Kind "Percentage": 187 stages, such as Favorability, Support, Appeasement, Consensus and Media Ambush's Press tone), but the code looked for a flag nothing ever set, so every shared-pool battle drew seats and none showed a percentage. It now reads the data.
- Living Office draws seats only where the bar counts people: Floor Debate and the four special committees. Percentage battles, the TV and radio debates (viewer interest) and the press conference (a single tone score) draw the continuous arc that fills like the plain bar. Those battles now also read in percent ("80% to advance", "You 30% · Undecided 25% · ..."). Other styles' bars are unchanged.
- `test_bar_drawing` pins it: exactly five combat stages draw seats.

## 2026-11-18: Your side of the battle bar is your party's colour

- The player's share of the bar (seats, arc and the straight bar in Broadcast and Woodblock) is drawn in the colour of the player's party, as in the demo. A player with no party keeps the usual blue. The opponent's side keeps its own rule (their party's colour, or the default crimson when they have no party or share yours). Visual only.

## 2026-11-18: Broadcast and Woodblock draw the semicircle too

- Every style now draws the battle bar as the semicircle (seats for Floor Debate and the special committees, a continuous arc for everything else), each in its own look. **Broadcast:** angular facets with slanted divisions, gold along the outer and inner rims (the bar's gold top and bottom), diamond seats edged in gold. **Woodblock:** a printed band with an ink edge, a vermilion offset shadow and ink division lines, printed discs for seats with the same shadow. The caption and the readout are centred and sized to their words, so Woodblock's plates no longer run across the arc. Visual only; the numbers and the straight bar code are unchanged.

## 2026-11-18: Polish: symmetrical Broadcast arc, longer card pull, no jolt, bars name their metric, New Game strips

- **Broadcast arc:** both feet are now mirror images (the right foot ran flat while the left leaned), and the inner gold rim stops at the leaned ends.
- **Card pull:** letting go plays a card once its bottom edge has been pulled up to halfway up the screen (never less than the old 220 px). The held card follows the finger all the way, so the Guard and Gaffes counters are drawn above it instead of the card stopping beneath them.
- **No jolt:** the held card used to leap by the lift distance (about 30 px) as the drag took over from the press; it now follows the finger from where the lift begins.
- **Battle bars name their metric:** the row under "80% to advance" says what it measures (Favorability, Appeasement, Seats...), unless the sentence already does.
- **New Game screen:** the difficulty and theme squares share their half of the row, so they fit with no scrolling and no cut-off, and the buttons' outlines are the title screen's gold.

## 2026-11-18: Bar caption on two rows; one chip for every organization icon

- **Bar caption** (Cameron): "[Number] of [Metric]" on one row and "to Advance" or "to Win" on the next, inside the arc: for example "80% of Favorability" over "to Advance". It replaces the separate metric line added earlier today. Text rows `bar.amount_of_metric`, `bar.to_win` and `bar.to_advance` (the last two now hold only "to Win" and "to Advance").
- **Organization icons** (Cameron): every icon in the battle's listening strip sits on the same light chip at 50% see-through, instead of a light or dark chip chosen per icon. The seat ring's per-colour rule is unchanged.

## 2026-11-18: Question text audit; Guard and Gaffes dim again; bar grammar

- **Questions unreadable:** on the Office Hours visitor, member visit and lobbyist trade screens the question sat in light ink on the light lower panel (measured 1.0 to 1.2 to 1: invisible in Living Office and Broadcast; Woodblock's own plaque hid it). It now sits on the style's plate (13 to 1 and better, measured from pixels). The visitor, member or lobbyist also says the question aloud as a cue, as every other spoken line is; the cue gives way to their reply when an answer is picked.
- **Guard and Gaffes at full brightness through the end-of-stage fade:** my "counters above the held card" change left them drawn above everything all the time. They now rise above the card only while a card is held, and dim with the rest of the screen otherwise (a check in `hand_input_test`).
- **Bar grammar:** "of" read wrongly for most bars. The first row is now "[Number] [Metric]" for a count or a share ("51 Seats", "20 Members", "80% Favorability") and "[Number] points of [Metric]" for a score on a scale ("55 points of Press tone", "65 points of Viewer Interest"); the second row is "to Win" or "to Advance". Text rows `bar.amount_metric` and `bar.amount_points` replace `bar.amount_of_metric`.

## 2026-11-18: Cues stay up 1.5 times as long; a cue blocks the buttons behind it

- **Longer cues** (Cameron): every spoken line stays on screen 1.5 times as long (Balance "Cue: Hold Multiplier", 1.5, on top of reading time plus the extra hold). The slides in and out keep their speed.
- **Click block** (Cameron): on the question screens (Office Hours visitor, member visit, lobbyist trade) the tap that dismissed a cue also pressed the choice behind it. While a cue is up, and for 0.35 s after it goes (Balance "Cue: Click Block Grace Seconds"), every tap on those screens is swallowed. Tapping the cue still dismisses it. In a battle the hand and End Turn stay usable while a line is up. `cue_block_test` taps with real clicks and fails without the block.

## 2026-11-18: Bar caption on one row under the arc; a no-effect card shows 0 on the organization icons

- **Caption** (Cameron): the two-row caption covered the arc (Woodblock's plate sat over its feet). It is now one row under the arc, above the figures row: "65 points of Viewer Interest to Win". The arc is never covered, in every style.
- **Organization icons** (Cameron): a card that moves no organization now shows a 0 on every listening icon when it is selected, as a card that moves some shows its changes. (The two-tap rule had left such a card with no marks at all.) `org_preview_test` checks it.

## 2026-11-18: Brand B: app icon, boot splash and start screen (panel P10)

- **Brand B, "The Assembly Seal"** is the brand: the icon, the boot splash and the start screen look the same whichever UI style is owned (the style is saved with the run; there is none before Continue). Card fronts and backs are untouched.
- **Assets:** `tools/brand/export_brand.gd` rebuilds every PNG in `assets/brand/` from the SVGs in `design/brand/source/` (the 1024 render matches the reference to within 22 of 255 on any pixel): the store icons, every iOS size Godot 4.5.1 reads, Android's legacy and adaptive layers (the seal inside the 66% safe circle, plus the monochrome layer), the splash seal, the start screen's wave band and the Google Play feature graphic. `tests/test_brand_assets.gd` checks them.
- **Project:** the icon, the version (0.1.0, a placeholder number) and the boot splash (the seal on washi) are set. Android and iOS export presets are in `tools/brand/export_presets.example.cfg` (copy to `export_presets.cfg`, which the repo ignores), with a placeholder package name and the short name "Coliseum".
- **Font:** the start screen and the feature graphic are set in **Antaka Brush Display** (Cameron's choice after seeing the start screen in every custom font), with Noto Sans JP behind it, so the 蓮物語 in the footer is drawn by the Japanese font.
- **Start screen:** rebuilt as bands, a framed print of the `TITLE` painting, a paper title plate with the seal, three buttons and a footer, over waves. Only the print flexes (shorter screens and Large text shrink it). Behaviour is unchanged; words are Text rows (`intro.title_top`, `intro.title_bottom`, `intro.tagline`, `intro.footer_mark`, `intro.version`). `intro_brand_test` measures contrast from pixels.

## 2026-11-18: The Promises button stays in its place (playtest)

- **Bug** (Cameron's playtest, Woodblock): with a promise open, the Promises tile was right after a level, but after buying the Funds cap increase and returning to the Office it floated up over the End of Week Payments box, leaving a gap in the grid. Cause: whenever the Office page changes height (here, the report gained a line) it re-fits itself, and that re-fit still wrote a bottom offset meant for the button's old corner spot above the payments box. In Woodblock and Broadcast the button is now a grid tile, so the write dragged it about 360 px up (Broadcast showed it already on the first view). Living Office had the same stray write: its Promises pin sat about 140 px higher than the room layout puts it.
- **Fix:** that corner spot is applied only while the button is still in its old corner holder (`_pin_promises_above_dues` in `OfficeScreen`); a grid tile or a room pin is left to where its layout puts it.
- **Test:** `promises_placement_test` builds the Office with an open promise in all three styles, grows the report a line, switches the compact layout on and off, and re-fits; the button may not move (and in the grid styles must stay inside the grid). It fails on the old code with exactly the playtest's jump.

## 2026-11-19: Built-in problem reporting (hold three fingers, or both volume buttons)

- **What it does** (Cameron's request): from any screen, hold three fingers on the screen for two seconds, or hold both volume buttons for two seconds (Android). A ring fills while you hold. The screen freezes; circle the problem with a finger (or skip), pick *Looks wrong, Doesn't work, Unclear wording, Too hard or too easy* or *An idea*, add an optional note, and save. The report text is copied to the clipboard and a zip is written. Cancel at any step saves nothing. The Administration menu says how (two Text lines; the volume line shows on Android only).
- **What a report holds:** a picture of the screen (and a copy with the circle), the screen name, display style, text size, phone model, screen and safe-area size, the run's week, hours, Funds and level, the last 60 things done (screens, buttons, taps), any errors the game noticed, layout faults found, which control was under the circle, and a compressed copy of the save so the run can be reloaded. It holds no name, email or device ID, and the game makes no network call; the form says so before saving.
- **The black box and crashes:** the game keeps the last 60 actions and the engine's errors in a small file. If the last session ended without closing (a crash, a freeze and a kill), the next start offers "Save a report about it". A script error shows a brief line ("The game noticed a problem...") at most once a minute.
- **Layout watch:** a moment after each screen and button press the game checks for a button outside the box of the group that holds it (the Promises tile that jumped over the payments box), off the screen, or on top of another button; a fault seen on two looks a second apart goes into the black box. `tools/text_sweep.gd` runs the same check on every screen (about 400 screen-views, none found), and a button outside its group now fails the sweep.
- **For the developer:** `python3 tools/read_report.py <pasted report>` prints it and unpacks the save; `--install` drops the save where the game reads it, keeping the existing one.
- **Numbers (Balance, "Report: ..."):** Enabled 1, Hold Seconds 2, Hold Fingers 3, Action Log Length 60, Layout Watch 1, Max Saved 10, Max Paste Characters 120,000. 32 Text rows `report.*` (Claude's draft).
- **Not tried yet, so please check on the phone:** that the Android volume buttons reach the game (tested with synthetic key events only; iOS cannot pass them on), that a three-finger hold is not taken by the phone's own gestures, that the touch circle feels right, and that the zip can be written to Downloads (without that, the pasted text still carries everything but the picture; a share-sheet plugin would be the smooth route and needs your approval as a dependency).

## 2026-11-19: A card plays when its middle reaches the bottom of the battle bar; Guard and Gaffes stay under the card

- **Where a dragged card plays** (Cameron, from a screenshot): letting go plays a card once its **middle** has risen to the bottom of the battle bar's semicircle, instead of its bottom edge reaching halfway up the screen. On the standard screen that is a pull of about 590 px instead of about 930. The line is read from the bar itself (`SupportBar.bottom_y`, handed to every card by `HandPresenter`), so it follows the bar on a shorter screen. The old rule stays only for a card shown outside a battle. The halo and the ready tint still scale to the new distance.
- **Guard and Gaffes** (Cameron): the two boxes are back to ordinary drawing order, so the held card covers them (as it already covers Inventory and Details), instead of my earlier change that drew them above it. They dim with the rest of the screen when a stage ends, as before.
- **Checks:** `hand_input_test` (all three styles) now measures the pull from the card's middle to the bar's bottom, that a drag short of it plays nothing, that the card's middle ends at the line, and that the boxes are under the held card. A picture of each style at the play point is in `design/review/card_play_spot_2026-11-19/`.

## 2026-11-19: Card playtest: icons answer a press; popups over raised cards; the top card takes the tap

- **Organization icons on press** (Cameron's playtest): pressing a card used to raise it but leave the organization icons blank until the card moved. They now show what the card would do the moment it is pressed. A tap leaves the card selected and the marks showing; a press slid off the card leaves the icons blank again.
- **Popups above raised cards:** a raised or selected card (z 2 to 4) was drawn over the Details panel, the card zoom and the outcome panel (z 0). Every popup, the Overlay class and those three battle panels, now draws at z 10, above a raised card and below the cue banner (z 50).
- **The Read button of a raised card** (Cameron's playtest): the hand's cards overlap, and a click goes to the last card in the row that covers the point, whatever is drawn above it. With a card raised over its right-hand neighbour, pressing the Read button (which the neighbour overlaps) opened the neighbour instead. A card is now hit only where no card drawn above it covers the point (`CardView._has_point`), so the tap reaches the card on top. This holds at any overlap, so the overlap itself did not have to change.
- **Overlap ("overlap only the last third", Cameron):** a standard hand is 5 cards in 995 px; each card is 336 px wide and now shows 165 px (49%) of itself. Showing two thirds of each card (overlapping only the last third) needs the cards about 19% smaller (271 px). A picture of both is in `design/review/card_overlap_2026-11-19/`; not built, waiting for Cameron's choice.
- **Checks:** `hand_stack_test` (new, two styles, real clicks): the icons show on press and clear after a slide-off; the raised card's overlapped part opens the raised card; each popup is above a selected card. All three failed before the changes.

## 2026-11-19: The hand overlaps only the last third of each card, and scrolls sideways

- **Overlap** (Cameron: current size, a horizontal scroll is acceptable): each card now shows its left two thirds (about 224 px of 336) instead of about half, so the cost, name, picture and most of the effect read, and the Read button sits clear of the next card. Cards keep their size. The overlap is Balance "Hand: Card Overlap Percent" (33).
- **A hand of 3 or 4 cards** still fits the row and is spread to fit (the overlap is a third or a little less). **A standard 5-card hand** is 231 px wider than the row, so it scrolls sideways: the gold bar above the hand shows where you are, a finger drag on the cards scrolls (drag right to bring the cards on the right into view, as everywhere in the game), and a card that is tapped while part of it is past the edge scrolls fully into view, so its Read button can be pressed. A card past the row's edge runs on to the screen's edge, which reads as "more this way".
- **Checks:** `hand_visible_test` now checks each hand size in all three styles (spacing, nothing hidden, a scroll only when the hand does not fit, every card reachable); `hand_stack_test` adds a sideways drag that scrolls without playing a card and a tap on the half-hidden last card. Pictures are in `design/review/hand_third_overlap_2026-11-19/`.

## 2026-11-19: Resign is confirmed by holding the button for five seconds

- **Hold to resign** (Cameron): the Resign button used to resign the instant it was pressed. It now has to be held. From the press the screen darkens from its outside edges inward and is fully black after 5 seconds (Balance "Resign: Confirm Hold Seconds"); holding all that time is the confirmation, so a stray tap does nothing. Letting go, sliding off the button or a drag that takes the press stops it and the screen lightens again in a moment. When the hold completes the run ends exactly as before (the Resign screen in two parts).
- **Words:** the button reads "Resign (hold 5 seconds)" and a small line under it says "Keep holding while the screen darkens. Let go to stop." (Text rows `office.resign`, `resign.hold_hint`; Claude's draft).
- **How:** `ResignHold` (a child of the button) draws a full-screen veil with a small shader on a canvas layer above every panel; the veil never takes a touch. The darkening maths (`ResignHold.shade`) is tested without a screen; `resign_hold_test` holds the real button: a tap does nothing, half a hold darkens the corners and then lightens, nothing happens at 4.4 seconds, the full hold resigns. Pictures at 0, 25, 50, 75 and 95 percent are in `design/review/resign_hold_2026-11-19/`.

## 2026-11-19: Crisis levels: recovery cancels them, the warning is saved, a full week is overridden on purpose

From the two-offices audit (`design/review/p11_two_offices_audit_2026-11-19/forced_and_dated.md`). Cameron decided three things; Claude made the changes.

- **A crisis that recovers cancels its level** (Cameron): when Constituency support (Town Hall) or Party support (Steering Committee) climbs back above its line, the waiting level is dropped: a countdown still running, or a level already at the top of the list, and a forced start with it. Before this the Office said "Constituency support has recovered." and the level arrived anyway. Falling in again starts a fresh countdown. A special level the player is already playing is untouched (its own end clears it). Code: `GameState._cancel_special()`, called from `_check_town_hall()` and `_check_steering_committee()`.
- **A crisis overrides a full week** (Cameron: left as it is, now on purpose): a forced Town Hall or Steering Committee starts at once even when the work week has no hours left, and its hours stop at the cap, so it costs nothing then. Written into `GAME_SYSTEMS.md` and pinned by two tests so a later change is deliberate.
- **The crisis warning is saved:** `pending_trigger_alerts` is now in the save. It was left out, so closing the app between a stage and the Office lost the warning. It is still cleared once the Office has shown it.
- **Checks:** `test_special_levels` gains 10 tests (recovery before the delay, after it is due, the Steering Committee, only its own level, a fresh countdown, a special level played to the end, the full-week override and its hours, the saved warning); `test_save_load` round-trips a warning. The recovery tests fail without the change.
- **Also:** a blank line before the previous section's heading.

## 2026-11-19: EV47 opens on a Monday, and its district choice becomes a Capitol one

From the two-offices audit: a Decision! event (today's Dated trigger) will move the player to the Capitol and open the week, so EV47 (the Prime Minister's Opening Address) had two things that did not fit. Cameron chose the fix; the wording is Claude's draft for Cameron to rewrite.

| What | Before | After |
|---|---|---|
| On Date | 18.10.09 (a Tuesday) | **18.10.08** (Monday, the first thing in the second week) |
| Choice C | "Keep your appointments in the district instead" | "Skip it and work through committee papers" (a sincere Capitol option, the same length as B; Party support -1 unchanged) |
| Choice C result | "The chamber is full without you. Someone in the party notices." | "You clear a stack of committee papers. The chamber is full without you, and someone in the party notices." |

- **Checks:** `test_events` now checks the address is not due on Friday 18.10.05 or the weekend, is due on Monday 18.10.08 and plays once, and that none of EV47's three choices names the district; `event_driver` (real clicks) follows the new date. Only the Events and Event Choices sheets changed in the workbook.

## 2026-11-19: The level briefing shows the level's end-of-level bonus

From the two-offices audit's finding that 93 of 114 levels pay a bonus when won (74 a meter or XP bonus, 69 organization standing) that no briefing said first, against Information Standard 1. Cameron approved the outline ("Show all of it", under Total Rewards, the full range on each chip). Pictures: `design/review/level_bonus_build_2026-11-19/`; the outline is `design/proposals/LEVEL_BONUS_BRIEFING_OUTLINE_2026-11-19.md`.

- **The block:** under "Total Rewards", a heading ("Level Bonus (paid if you win the whole level):"), one bullet for each of Reputation, Constituency support, Party support, XP Growth and Funds (a range such as "+1 to +2" when it is one), then "Standing with organizations:" and one chip per organization showing its range ("+2-4", "0-1"). A level that pays no bonus shows none of it. Funds and XP are after the Campaign Pressure, the same scaling the payout uses.
- **One source for the payout and the preview:** the new `LevelBonus` (rules) says which Levels columns are the bonus; `GameState._apply_level_bonus_win` now reads them from it, in the same order as before, so the random rolls are unchanged. `LevelBonusView` builds the rows; `OrgChip.make` takes an optional label (in a smaller font) for a range.
- **Words:** five Text rows (`briefing.level_bonus`, `briefing.level_bonus_orgs`, `briefing.xp_growth_range`, `reward.delta_range`, `reward.chip_range`), Claude's draft for Cameron to rewrite. The briefing's "nothing pays out yet" line no longer shows for a level whose only reward is its bonus.
- **Not previewed** (nor are they in the rooms' rewards): backings the player owns, a Funding Freeze, and standing other organizations pass along. The Funds ceiling is not applied either (at Standard, LV80's bonus alone is 96,000 to 144,000円, over the 100,000円 ceiling). **That is intended (Cameron, 2026-11-19):** a level can reward more than the ceiling and the excess is lost; the player buys the ceiling increase and chooses which levels to take, and when, so the briefing shows the whole amount.
- **Checks:** `test_level_bonus` (11 tests, including every payout of every level on every Campaign Pressure landing inside its preview, 12 rolls each; it fails if the preview is narrowed); `level_bonus_test` (real clicks: LV11 shows the block in order with three chips and their ranges, a level with no bonus shows none; it fails with the block removed); the text sweep already opens LV04's briefing, which has a bonus, at every text size and style.

## 2026-11-19: Draft office tags for the 167 visitors

From the two-offices audit: Office Hours is an Either level (it is held at both offices), but constituents belong to the District and fellow members and party people to the Capitol, so the visitor draw will need each visitor to carry an office. Cameron asked for a draft. **Claude's draft for Cameron to correct; nothing in the workbook or the game uses it yet** (there is no Location column until the two-offices build).

- **What:** `design/proposals/visitor_office_tags_2026-11-19/`: `visitor_office_tags.csv` (one row per visitor: proposed office, confidence, reason), `README.md` (method, the visitors to look at, three open questions) and `make_tags.py` (rebuilds the CSV from `data/visitors.json` and `data/boosters.json`).
- **Result:** District 128, Capitol 23, Either 16. Confidence: 114 high, 41 medium, 12 low (the low ones are left Either: lobbyists and people whose title and organizations disagree).
- **Method:** the title's words, and which kind of organization the visitor's reward and penalty touch (Party and Members of Parliament lean Capitol, Constituency organizations lean District); "Constituent" is always District, per the spec. Both agreeing is high confidence.

## 2026-11-19: Ten Capitol events, EV95 to EV104

From the two-offices audit: of 65 Random events, 37 were district casework and only 14 were Capitol, so once the Capitol is its own office its event pool would be thin. Cameron asked for about ten more. **All wording is Claude's draft for Cameron to rewrite.** Workbook rows only: no mechanic, no schema change, and no Location column (that waits for the two-offices build; each event's intended office is in the table below).

| ID | Title | Hours | Weight | Needs National awareness | Organization it touches | Intended office |
|---|---|---|---|---|---|---|
| EV95 | A Committee Clerk Needs a Signature | 1 | 6 | none | Members of Parliament | Capitol |
| EV96 | A Member From Another Party Asks You to Co-Sign | 1 | 5 | 10 | Members of Parliament | Capitol |
| EV97 | The Press Gallery Wants a Word After the Vote | 1 | 6 | 15 | National Media | Capitol |
| EV98 | A Lobbyist Leaves a Gift Basket | 1 | 5 | none | Chamber of Commerce | Capitol |
| EV99 | The Session Runs Late | 2 | 6 | none | Candidate Selection Committee | Capitol |
| EV100 | The Party Faction Invites You to Lunch | 2 | 5 | none | Party Faction, Party Headquarters | Capitol |
| EV101 | A Budget Annex Arrives Without a Summary | 2 | 5 | none | Taxpayers' Alliance | Capitol |
| EV102 | A School Group Visits the Gallery | 1 | 5 | none | Students United | Capitol (constituents visiting the Assembly) |
| EV103 | A Rival's Aide Offers to Compare Notes | 1 | 4 | 20 | Members of Parliament | Capitol |
| EV104 | The Labor Federation Asks for a Seat at the Table | 1 | 5 | none | Labor Federation | Capitol |

- **Built like the nearest existing event** (EV54, EV55, EV61): Random, Weekday, three choices (A engage, B send a staffer, C a careful middle path, four of them with a promise) and a **Decline** row. The Decline rows are computed from the content guide's rule (1.5 times what sending staff gives up against accepting, rounded half up; standing and awareness only, never XP or Funds) so they are not hand-set. Sending staff uses the Policy Research Assistant, or the Media Spokesperson for the press event, and greys out with "No staff hired" when nobody is hired.
- **Canon:** no new people, parties or committees. The only bodies named are the Ministry of Finance and the Candidate Selection Committee, both already in the data; organizations are existing ones.
- **Next free event ID is now EV105** (`CONTENT_GUIDE.md`); the data snapshot is 97 events.
- **Checks:** `python3 tools/export_data.py` "No errors" (the wording snapshot refreshed for the 10 new Decline lines); only the Events, Event Choices and Text sheets changed.

## 2026-11-19: Scripted edits can no longer corrupt a file the way two tests were

- **What went wrong (twice):** a script cut a block out of a file with `text[text.index(first):text.index(last)]` and then called `text.replace(block, new)`. When `last` came before `first`, the block was empty, and Python's `replace` on an empty string puts the new text between every character. The first time it mangled `hand_visible_test.gd`; the second, `event_driver.gd`, whose click test then hung and made a verify run time out. Both were caught and restored from git, and nothing broken was ever committed.
- **The fix:** `tools/safe_edit.py` with `replace_once` and `replace_block`. They refuse an empty search text, a search text that is missing or occurs more than once, a block whose markers are backwards or ambiguous or too long, and an edit that gives the wrong length; a refused edit leaves the file untouched. `python3 tools/safe_edit.py --selftest` checks all of that, including the original mistake, and `tools/verify.sh` runs it first thing.
- **The rule:** a "Scripted edits" note in `CLAUDE.md` section 14: use the Edit tool or `safe_edit.py`, never a slice followed by `replace`. The two docs, the verify step and this note were themselves written with `safe_edit.py`.

## 2026-11-19: The level briefing is redrawn (P12)

The panel that opens from the level list ("Go in, or Back") was rebuilt from the P12 package. **Cameron's choices: the top of the screen follows Template A (header, purpose, week, totals, organizations) and "Rooms, in order" follows Template B (a timeline with one block per room); the new Text rows were added with his corrections ("paid when you win the level", not "win all"); loss costs are left out for now.** The branch is `panel/p12-level-preview`; it is not merged.

| Part | What it is now |
|---|---|
| Header | The level's name, "Tier N · N rooms", an hours badge (a tilted vermilion seal in Woodblock, an amber ring in Living Office, a gold slanted chip in Broadcast), the purpose line (a staff member's, or narration when no staff is hired), and the week as a bar with "This week: N hours left" and "N left after this level" |
| "If you win every room" | A tile for each meter in the fixed order, then XP Growth and Funds, with the level bonus as a small line under each ("+1 to +2 bonus"), and a dashed note: each room pays when you win it, the bonus when you win the level (a level with no bonus says only the first half) |
| "Organizations, if you win" | Icon, name and range for each organization the bonus touches; the whole card is absent when there are none (45 of 114 levels) |
| "Rooms, in order" | One block per room, a number square, name, kind and hours ("Debate · 2 h"), reward chips, "Losing this stage costs you, but the level carries on." where it is true, an hour ruler and rail, and a marker for the level bonus at the end. One-room levels list no rooms |
| Foot | Back and **Go in · N hours**, fixed while the middle scrolls. When the level cannot start, Go in is greyed and shows the game's own reason (`GameState.level_calendar_refusal`) |

- **Rules and data:** `LevelBriefing.build()` (pure) gives the screen one plain dictionary. A test (`tests/test_level_briefing.gd`) checks it against a record of what the old briefing showed on all 114 levels at every Campaign Pressure, so no number changed; hidden rooms ("Reveal In Briefing" No) stay unnamed but their hours still count.
- **Three styles:** the palette is 30 new `brief_*` colour rows in the UI Styles tab (Claude's draft from the mockups); shapes live in `LevelBriefingStyles`. The contrast test (`tests/test_level_briefing_contrast.gd`) holds every text pair to 4.5:1 and every icon, bar and rail to 3:1 in all three styles.
- **Text:** 31 new `briefing.*` rows (a draft for Cameron to rewrite). No row says "win all" or "the whole level" (`tests/test_level_briefing_wording.gd`).
- **Not built, on purpose:** the "District office" badge (it needs a Location column; the data builder carries an empty `location` for it) and "If you lose" costs (carried in the data, not shown). **`INFORMATION_STANDARDS.md` is corrected:** it said the briefing listed "If you lose" costs; it no longer does.
- **Replaced:** the old Total Rewards, stage list and Level Bonus block. The Text rows they used are listed in `CLEANUP_CANDIDATES.md` (nothing deleted). `tests/interaction/level_bonus_driver.gd` was rewritten for the new layout.
- **Bugs found while checking the screenshots, fixed:** a one-room level shrank to a narrow column with its words stacked letter by letter (the scroll box needs its child set to expand); at Large text the level-bonus marker did not wrap and pushed the whole panel wider than the phone; the hours ring was too small for Large text.
- **Pictures and the deviations from the mockups** are in `design/review/p12_level_preview_2026-11-19/` (`REPORT.md`).

## 2026-11-20: Two offices, slice 1: where you are

**The first of seven slices of the two-offices build** (plan: `design/proposals/TWO_OFFICES_BUILD_PLAN_2026-11-20.md`; decisions: `TWO_OFFICES_DECISIONS_2026-11-20.md`). The player now stands at the Capitol or at their District office, and trips between them cost hours.

| Part | What changed |
|---|---|
| Districts swapped | Cameron's workbook upload swapped PC01 and PC04's districts. **PC01 Kenshin Sako is now the Aomori protagonist (District office Noheji, 7 h by train, plane ticket 2 h), PC04 Jyurou Nishihara the Wakkanai one (Daikoki, 6 h by train, private car 4 h).** Their district starting items flip: PC01 starts with the Box of Aomori Apples, PC04 with the Wakkanai Milk Caramels. PC02 keeps Akenoshinmachi (Tomakomai) and PC03 Teine Ward. |
| Data | `Location` (Capitol 80, District 29, Either 5) and `Travel Trips` on Levels, tagged from the audit; `Location` on Events (EV47 only for now) and on the Bill Level Templates; `District Office` on Player; nine Balance travel rows; two Rules switches (`travel_at_weekend` off, `start_office` Capitol); 28 Text rows (Claude's drafts). The exporter checks the new columns. |
| The trip | A button under "Choose a level": "To Noheji · 7 h · Rail pass". A popup states the cost and the hours left; the trip spends the hours (promise deadlines keep running), swaps the office picture (a labelled placeholder until the District pictures are drawn) and the level list. Refused with a reason: a level in progress, the weekend, too few hours. |
| Levels by office | The list shows only levels at the player's office, plus Either levels; each row says where it starts. A level elsewhere cannot start. |
| Mixed levels (24) | **Cameron's change to the spec's rule 5:** a mixed level charges its trips with its hours: a full round trip (2 trips; +14 h for PC01, +12 for PC04, +2 for the others), 1 trip for LV12, LV61 and LV62 (they end at the Capitol). The briefing says so ("Includes 14 h of travel by rail pass") and the hours badge, week bar and Go in count it. **Consequence: PC01 cannot play LV10 (27 h + 14 h) on the rail pass; it needs the plane ticket, which the Marketplace does not sell yet.** |
| Crisis levels, EV47 | LV83 (District) and LV84 (Capitol) wait at their own office and are forced in on arrival; the Dated EV47 opens the week at the Capitol. |
| Tests | New: `test_offices_travel`, `test_office_state`, the travel click test; the existing click drivers now stand at the office of the level they start. The text sweep and touch-target audit include the trip popup and a mixed level's briefing. |
| Not yet | The swipe, the District office in three styles, events/promises/notices/visitors by office, tickets and train encounters, the Places tab, the eight protagonist levels, re-simulation. |

## 2026-11-20: Two offices, slice 2: the train strip

The trip button became **a train on a track**. The words (where, how long, by what) are on the strip before anything is pressed. **Drag the train past 60% of the track and let go to travel** (a Balance number, `Travel Swipe Commit Percent`); short of that it springs back; **a tap opens the same confirm**, so the drag is the fast path and not the only one. The Office then fades to a card ("Rail pass / To Noheji / 7 h"), the trip is taken behind it, and the other office fades in. The train points the way it travels and sits at the other end after each trip. The strip is drawn in all three styles from the briefing's palette (placeholder train until `TRAIN_STRIP` is drawn). The four District offices share one set of room-object pins (`DISTRICT_OFFICE` in art.json, a copy of the Capitol's until the pictures exist), and the Living Office pins re-place after a trip. New: `Swipe` (pure) with `test_swipe`, drag/spring-back/greyed-strip checks in the travel click test.

## 2026-11-20: Two offices, slice 3: events, promises, notices, ticker and visitors by office

| Part | What changed |
|---|---|
| Data (drafts for Cameron, tagged from the audit) | `Location` on **Events** (all 97), **Event Choices** (the 20 promise-bearing rows), **Office Notices** (20), **Office Ticker** (the column exists; the audit flagged no line that must be pinned to one office) and **Visitors** (the 167 draft office tags); one Balance row, `Travel Promise Warning Hours`; three Text rows. |
| Events | Random events arrive only at their office; Buyable ones are listed only where they can be held; a follow-up that falls due elsewhere waits until the player arrives. |
| Promises | Each promise remembers where it can be kept (the choice's own Location, else where the player stood). "Keep it at Noheji" on the panel and on a greyed Keep button; the trip popup warns about a promise due soon that can only be kept at the office being left. |
| Notices and ticker | A line shows only at its office (the District Representative's greeting and the constituents' visits at the District). |
| Visitors | Office Hours draws the visitors tagged for the office first, and fills the room out with others rather than seating fewer people. |
| Tests | `test_offices_content` (the tags, each office's own draw, a follow-up waiting, promises, notices, ticker, visitors); the travel click test covers the Promises panel, the Keep button and the trip warning; `test_promises` stands at a follow-up's office. |

## 2026-11-20: Two offices, slice 4: tickets and train encounters

| Part | What changed |
|---|---|
| Tickets (Shop; **prices are drafts for Cameron**) | Paid Train Ticket SH42 (5,000円; +2 with BO23, BO05 and BO14 on each use), Private Car Trip SH43 (15,000円; PC02, PC03, PC04) and Plane Ticket SH44 (40,000円; PC01). New Shop columns `Travel Mode` and `Offered For`; the Marketplace lists a ticket only for the protagonists it is for. |
| Modes | With a ticket held, a row of modes appears under the train strip (the pass and a paid ticket set what the strip is pulled with; a car or plane has its own confirm and is instant). A mixed level's briefing has a "Travel by" row and its hours, badge, week bar and Go in follow the choice; each trip uses a ticket, and Go in is greyed when there are too few. **LV10 can now be played by PC01 by plane (31 h).** |
| Encounters | One trip in 8 (Balance `Travel Encounter One In`) by the pass or a paid ticket brings a short dilemma on the train: six draft Events with Trigger Train (EV105 to EV110, three choices each). Shown after a swipe trip, and before a mixed level begins. |
| Tests | `test_travel_tickets` (who is sold what, modes, a ticket's hours and standing, tickets per trip, the encounter rate and its exceptions); the travel click test covers the mode row, a ticket drag, a plane, the briefing row and an encounter. |
| Pictures | Art IDs still to be drawn: `TICKET_*` icons (the items have none yet), `TRAIN_INTERIOR` (the encounters' picture; the export warns it is missing). |

## 2026-11-20: Two offices, slice 5: places and place tokens

| Part | What changed |
|---|---|
| Places tab | New tab, 112 rows: each protagonist's named places by type, from the spec's catalog with PC01 and PC04 swapped. Real towns, mountains and straits keep their real names; companies and branded venues use the adopted Yezo brand names. A draft for Cameron to correct (notes such as "early August" were dropped from names). |
| Tokens | `{place:harbor}` and `{office_city}` in event text become the protagonist's own names; the pick among several names is stable per event. New pure rule `PlaceTokens`; `DataDB` fills the text when a protagonist is chosen and keeps the unfilled text. |
| Needs Place | New Events column. An event that asks for a type the district lacks is never drawn (and a Buyable one is not listed). The exporter errors on an unknown type, on a token the event does not list, and on a type no protagonist has. |
| Events rewritten (drafts) | 29 of the audit's 39 place-bound events now use tokens: EV02, EV12, EV13, EV17, EV19, EV20, EV24, EV26, EV27, EV35, EV37, EV39, EV42, EV48, EV49, EV50, EV52, EV53, EV56, EV57, EV58, EV63, EV66, EV69, EV82, EV86, EV87, EV90, EV94. **Ten were left as written because no place in their text could be replaced by a type:** EV01 (Sapporo's tournament), EV14, EV18, EV23, EV34, EV51 (a TV station, not a rail station), EV85, EV88, EV92, EV93. Some of the swaps change the setting (the Hakodate harbor letters now come from the district's own harbor; EV82's turbine meeting may pick a nuclear site in the Aomori district), so each is worth a read. |
| Tests | `test_place_tokens` (fill, stable picks, the swap, no token left on screen for any protagonist, Needs Place). |


## 2026-11-20: Two offices, slice 6: the eight protagonist levels

| Part | What changed |
|---|---|
| Protagonist column | New optional `Protagonist` column on **Levels** (approved 2026-11-20): blank means every protagonist, `PC02` means only that one. The level list and the random level offer skip a level that is not for the player (`GameState.level_is_for_player`). The exporter checks the IDs. |
| Eight levels (drafts for Cameron, LV115 to LV122) | One District fight and one Capitol policy fight for each protagonist, as ordinary workbook rows copied from the nearest level (LV11 for tier 1, LV21 for tier 2): **PC04 Wakkanai** "Keep the Sōya Line Running" (District) and "The Sakhalin Ferry" (Capitol); **PC02 Tomakomai** "Carbon Under the Harbor" (District) and "A Casino by Lake Utonai?" (Capitol); **PC03 Teine and Ishikari** "Wind on Ishikari Bay" (District) and "The Tunnel Under Teine" (Capitol); **PC01 Aomori** "The Rokkasho Question" (District) and "Ōma's Bluefin Quota" (Capitol). Each is 8 to 16 hours and reuses existing stages. |
| Trade-off | LV118 (the casino) charges standing with two organizations (BO26 and BO19, -2 to -1) on a win, shown in the briefing's Organizations card, as decision 20 allows. |
| Places | District purpose lines use place tokens (`{place:landmark}`, `{place:harbor}`, `{place:beach}`) or a real town; the exporter now checks tokens in a level's purpose line too. |
| Left out, on purpose | Weekend play for LV117 and LV119 (a weekend level must fit a 4-hour day); gating by discovery; a mixed Rokkasho variant; the spec's "unique hooks" (new mechanics need their own proposal). |
| Tests | `test_protagonist_levels` (who sees each level, places, hours, the trade-off); the travel click test checks that PC01 sees its own two levels at the right offices and not another protagonist's. Counts in `test_offices_travel`, `test_level_bonus` and `test_level_briefing` moved with the data. |

## 2026-11-20: Two offices, slice 7: measuring the week, the guide, the bot

| Part | What changed |
|---|---|
| Report (no number changed) | `design/review/two_offices_hours_2026-11-20/REPORT.md`: what travel takes of the 40-hour week, from a replay of the 144 old bot runs and from 336 new live bot runs (standard, harder and relaxed pressure, three policies). **PC02 and PC03 lose 2 to 5% of the week; PC01 and PC04 lose 10% if they stay put and 18 to 19% if they cross whenever the next level is at the other office**, about 16% (PC01) and 23% (PC04) less XP by week 10. Stage win rates do not move. With offices Kenshin (Easy) ends level with Jyurou (Very Hard) at week 30. Five options for PC01's and PC04's rating are in the report; the choice is Cameron's. |
| A finding | A bot that never leaves the Capitol never plays a District level, because the Capitol list never runs out, and ends with District awareness 56 to 69 instead of 100. Nothing in the game says to go home; a nudge would be a new proposal. |
| The strategy bot | `tools/strategy_playtest.gd` knows the offices: `PLAYTEST_OFFICES=0` plays the old way, `1` (default) crosses only when nothing is left at its office, `2` follows its own order and crosses whenever it needs to; it pays a mixed level's built-in trips. New: `tools/offices_bench_report.py` (the comparison tables), `tools/two_offices_hours.py` (the log replay); runs are in `design/bench/offices/`. |
| How to Play | Four new entries in Between Levels, HT35 to HT38: the two offices, taking the train, tickets and trips inside levels, promises and staff. Drafts for Cameron. |
| Documents | `NEW_CHAT_STARTUP.md` refreshed to 2026-11-20 (counts, the offices, P9 to P12, things that bite, the offices review list). |

## 2026-11-20: Two offices: Cameron's answers to the hours report

| Part | What changed |
|---|---|
| Ratings and starting items | The labels stay. **PC01 starts with four Plane Tickets (SH44 x4)**; PC04 gets nothing. New test: only PC01 starts with tickets. |
| Ticket prices | Paid Train Ticket **10,000円**, Private Car Trip **30,000円**, Plane Ticket **60,000円** (Shop tab; they were 5,000 / 15,000 / 40,000円). At the new price a plane trip costs about 12,000円 for each hour it saves PC01. |
| Spellings | PC04's District office is **Daikoku** and PC02's is **Akeno Shinmachi** (明野新町) in the Player tab; the tests and documents follow. The earlier changelog sections of 2026-11-20 still use the old spellings, which were Claude's guesses. |
| Places | Misawa, Tohoku and Shichinohe are confirmed inside Aomori Block 3: six draft names for PC01 (Places 112 to 118 rows). |
| Where it is written | `design/proposals/TWO_OFFICES_DECISIONS_2026-11-20.md` (decisions 25 to 28), the report's header, `GAME_SYSTEMS.md` section 3.1, `NEW_CHAT_STARTUP.md`. The workbook edit is `tools/workbook/archive/two_offices_decisions_2026-11-20.py`. |

## 2026-11-20: Cleanup pass (Cameron: "execute the cleanup")

| Part | What changed |
|---|---|
| Removed | The old Level Bonus block (`LevelBonusView`, `LevelBonus.chip_numbers`), 14 Text rows the redesigned briefing no longer asks for, `StageCarryOver` and its test, and five functions only their own tests called (`SaveManager.backup_time`, `RewardTargets.is_modifier` / `is_shop_item` / `is_segment`, `PatronRequests.room_to_open`, `BillName.sentence_start`). 2,270 unit tests pass (seven fewer, the tests of what was removed). |
| Kept, and why | `game_design_artifact.html` (it is the source of the published game design page, not a copy), the 17 papers code comments cite, and the helpers and wrappers tests rely on. The reasons are in `CLEANUP_CANDIDATES.md`. |
| New candidates | 16 more unused Text rows and about 210 MB of finished-panel screenshots in `design/review/`, noted for Cameron's word. |
| Decisions recorded | `TWO_OFFICES_DECISIONS_2026-11-20.md` decisions 29 to 32: no District nudge, no car price change, LV10 stays, four tickets are enough. |

## 2026-11-20: The trip strip's train is kept as the main icon

Cameron likes the train drawn in code (seen in the slice 2 screenshots) and keeps it as the main icon for now. So `TRAIN_STRIP` is no longer a picture to draw: the art list (`design/ART_ASSETS_TWO_OFFICES_2026-11-20.xlsx`) shows it as a grey Deferred row, the start-up guide and prompt no longer list it, and the comment in `TravelStrip.gd` says the code-drawn train is the icon. No behavior changed.

## 2026-11-20: P13, the Office screens on one frame (branch `panel/p13-office-screens`, not merged)

| Part | What changed |
|---|---|
| One frame | `OfficeScreenFrame` and `OfficeFrameStyles`: back control and chips, title with its Japanese accent, wrapping tabs, a scrolling column of cards, an optional fixed button; drawn in Woodblock, Living Office and Broadcast from the UI Styles tab (six new colours, `frame_up` and `frame_down`). It lives inside the panel (`Overlay.open_frame`), so the way out is unchanged. |
| Administration | Four grouped cards and a Political Pressure box (`AdministrationModel`, `AdministrationView`); a Scroll speed row and a "Saved" chip (Cameron). |
| Reputation and Results | Six tabs; a new Overview; Resign at its top (Cameron); every change a button showing only the signed number, the reasons only in the pop-up (`ReputationOverview`, `ReputationModel`, `ReputationView`). Your Record is folded into the Overview and the Laws tab. |
| Marketplace | Chips, the three tabs under their old names, a "You have" card, one card shape; the reason as a red line with a greyed button (`MarketModel`, `MarketView`). |
| Office Management | Tabs Staff, Your deck, Rhetoric Training; a card for every hired person, a dashed row for every open place, Staff Assignments fixed (`StaffRosterModel`, `StaffRosterView`, `DashedFrame`). |
| Events | Two tabs, a Decision! banner with no price or button, location badges, reasons in red (`EventsModel`, `EventsView`); `EventEngine.upcoming_dated` and the Balance number Events Coming Up Days (7). |
| Text and data | About 60 draft Text rows (the report lists which were not in the approved list), 6 UI Styles rows, 1 Balance row. |
| Tests | 80 new unit tests across seven files; the office menus, staff profile, shop items, inventory, how to play, new game, event and party plate click tests were updated on purpose (each change is named in the report). The text sweep passes in all three styles at three sizes. |
| Found, not fixed | A staff wage prints without a thousands comma ("6000円", an old row); the Resign button's black-on-crimson text is about 3.6:1; EV47's decision pop-up and the other pop-ups are still the old panels (P14). |
| Where | Report with before-and-after pictures: `design/review/p13_office_screens_2026-11-20/REPORT.md`; plan: `design/proposals/P13_PLAN_2026-11-20.md`; roadmap: `design/proposals/P13_P14_ROADMAP_2026-11-20.md`. |

## 2026-11-20: Follow-ups to P13, and Cameron's art uploads wired

| Part | What changed |
|---|---|
| Wage comma | A staff wage printed as "6000円". The money formatter only knew the placeholder names `count`, `cost`, `price` and `yen_*`, so rows written with `{yen}`, `{funds}`, `{base}`, `{share}` and `{earned}` (staff wages, dues, drafting costs) showed raw numbers. They now get thousands separators; a value already written with them is left alone. New test. |
| Resign contrast | The Resign and Goodbye buttons' text is white instead of black on the crimson fill (3.6 to 1 became 5.9 to 1). Same crimson. |
| Art uploads | Cameron's 27 pictures arrived named `X.png.png` and could not be found. They are renamed to `X.png` (a git rename). **Wired:** the three ticket icons (Shop Icon cells for SH42 to SH44: PAID_TRAIN_TICKET, PRIVATE_CAR_TRIP, PLANE_TICKET) and the six train interiors (the Image cell of EV105 to EV110 lists TRAIN_INTERIOR and _2 to _6; one is picked at random each time, the existing way). **Not wired, waiting on Cameron:** the District rooms (DISTRICT_LOBBYIST_MEETING, POLICY_STUDY and AMBUSH_STREET and their variants need a small code change so the shared rooms use them at the District office), DISTRICT_LEGISLATURE_1 to 3 and DISTRICT_LIBRARY_1 to 2 (not on the art list), and POLITICIAN_TRAIN_TICKET (a member's rail pass card; nothing shows an icon for the rail pass yet). |

## 2026-11-20: The District rooms and the trip row icons (Cameron: Go)

| Part | What changed |
|---|---|
| District rooms | At the **District office** the shared Lobbyist Meeting (ST20), Policy Study (ST21) and Media Ambush (ST19) rooms, and every stage that borrows them, show the District picture for the protagonist standing there: picture 1 for PC01, 2 for PC02, 3 for PC03, 4 for PC04 (Cameron). At the Capitol nothing changes; a picture not drawn falls back to the usual one. The list is the new `district_backgrounds` key in `data/art.json`; the rule is the pure `DistrictRooms`, used by `ArtLoader.background_path`. |
| Policy Study files | Cameron asked to swap the Policy Study pictures 2 and 4, so file numbers match protagonist numbers in all three rooms. The two files were swapped (a git rename). |
| Trip row icons | The travel-mode buttons (Office row and the level briefing's "Travel by" row) show a small picture: the member's rail pass card (`POLITICIAN_TRAIN_TICKET`), the paid ticket, the car and the plane (`travel_mode_icons` in `art.json`). No picture drawn: no icon. Words, names and hours are unchanged. |
| Still open | `DISTRICT_LEGISLATURE_1` to `_3` and `DISTRICT_LIBRARY_1` and `_2` are in the game folder but not used: Cameron to say where they go. |
| Tests | `tests/test_district_rooms.gd` (9): the rule, the data, the loader through real stages (at the District, at the Capitol, a borrowing stage, an unshared room), and the icons. |

## 2026-11-20: P14 part one: the pop-up card, the conversation screens, the Floor Vote and the stage outcome (Cameron: Go)

| Part | What changed |
|---|---|
| Pop-up card | `PopupCard` and `PopupCardStyles`, hosted by `Overlay.open_card`: a kind tag (DECISION!, SOMETHING COMES UP, YOUR EVENT n OF 3, WEEK'S END, PROMISES, PROMISE BROKEN, LEVEL IN PROGRESS), a meta line, a title, a scrolling body and a fixed button row, over a dimmed room. The Overlay keeps the way out, so a pop-up that must be answered still cannot be dismissed. |
| Screens on the card | Decision! and scenario events and their results, the arranged event (its step count read from its options), the gathering result, week over, promises, promise broken, trigger alerts, the level in progress, the forced special level, and the P13 reasons and open-place pop-ups. |
| Conversation dress | `ConversationStyles`: name plate, filled choices, accent Continue on Office Hours, the member visit, the lobbyist trade, the level intro, the stage transition and the Floor Vote's buttons. A held Continue now says "Hold for 2 seconds". |
| Stage outcome | A STAGE WON or STAGE LOST card over the dimmed room. |
| Floor Vote | Party discs: the leader's portrait, or else a colour disc with the first kanji of the Japanese name and the English initials (`PartyDisc`). The line under each party stays in its colour; the party name and position blurb are white on a dark plate so they read on the room picture (Cameron). |
| Data | Parties tab: Short Name and Japanese Name. UI Styles: `scrim`, `alarm`, `scrim_alpha`. Text: 20 rows. |
| Not built (P14b or later) | One card per promise, the redrawn bill card, the stacked Vote Projections, the staff speech card on a forced move. Left out on purpose: each answer's rhetorical style (Cameron to decide). |
| Where | Report with pictures: `design/review/p14_remaining_screens_2026-11-20/REPORT.md`; plan: `design/proposals/P14_PLAN_2026-11-20.md`. |

## 2026-11-20: The Floor Vote built to the mock-up (P14b, Cameron: "Build the mock up")

| Part | What changed |
|---|---|
| Layout | Under the party discs the Floor Vote is now cards in the style's own look: the bill card (its name, what it does, the rule it must pass by, whether your influence can sway others), the Vote Projections card (one bar for each choice), the stance card when you lean, a research and whip note card, and one row of three actions (Influence Status, Vote Intention Research, Whip Details). The vote buttons stay fixed at the foot. |
| Unchanged | The engine, every number and every sentence. The gold-ruled blocks and the grey veil are gone; the cards carry their own ground. |
| Likely outcome | Each projection shows the choice at the left and "Likely Passes" or "Likely Fails" at the right, green when the bill passes and red when it fails (Cameron). The words carry the meaning too. New Text row `floor_vote.projection_result`. |
| Actions | The row of three actions sits on its own card right under the bill, above the projections (Cameron: moved up); the research and whip notes close the body. |
| Not built | The mock-up's colour legend under the bars (it needs new wording). |
| Where | Pictures: `design/review/p14_remaining_screens_2026-11-20/img/floor_vote_cards_*.png`; side-by-side with the old: `floor_vote_projections_side_by_side.png`. |

## 2026-11-20: P14b commit 1: Staff Assignments, the staff profile and Rhetoric Training (Cameron: Go)

| Part | What changed |
|---|---|
| Staff Assignments | On the shared Office frame (place and hours as chips). Section cards: Today's tasks (date, how to play, the tray), Items for your staff, Office box, one card for **every hired person** (picture, role and rank, Loyalty, the 8-block bar, the box tasks are dropped into), and "If you confirm". Confirm is fixed in the frame's foot and greyed with its reason. Task and item chips stay dark tiles in every style. |
| Staff profile | On the frame as cards: identity (picture, role, flavor, hiring cost, biography), Loyalty and pay with Raise pay and Thank, Bonuses by rank, and one actions card where **Fire is last, drawn in the fall colour**. Hire for a candidate. |
| Rhetoric Training | Already cards on the frame from P13. It now names a coaching coupon you hold (the coupon is redeemed from your items for a free session; the spec's line "your next session is free" would have said something the game does not do, so the Text row is reworded). |
| Tests | `tests/test_group4_staff.gd` (3): every hired person has a card and Confirm is in the foot, the profile's cards with Fire last, the coupon note. No click test changed. |

## 2026-11-20: P14b commit 2: Your Deck, the card offer, the card look and the inventory sheet (Cameron: Go)

| Part | What changed |
|---|---|
| Your Deck | The tab shows a chip for each suit with how many of its cards are in the deck being built, a switch between **In your deck** and **Collection** (the Collection, every card you own with the ones left out dimmed, is the default, as before), and the cards in two columns. Each tile is the pick-or-drop button with its cost, the effect, and View. Three Text rows: `deck.filter_deck`, `deck.filter_all`, `deck.suit_chip`. |
| Card offer | A pop-up card: "Your coach suggests" in the header, the 1/3 counter, the card's two faces, Pass (while it is not the last look) above Learn it. |
| Card look | A pop-up card with the card's name, its Japanese name as a muted line, and both faces. |
| Inventory | The picked item's details are a bottom sheet over the grid, with Use (greyed with its reason) and Close; the same view in the Office and the battle. |
| Tests | `tests/test_group5_cards.gd` (4). No click test changed. |

## 2026-11-20: P14b commit 3: Travel, Draft a Bill, a bill to carry, the law detail, the party detail and the promises (Cameron: Go)

| Part | What changed |
|---|---|
| Travel | The confirm after a tap on the train strip is a **bottom sheet** (the cost, what is left, the promise and crisis-level warnings, Take the trip, Stay here) with a new **All trips** button. All trips opens the full **Travel page** (Cameron: the page too): where you are and the hours left, then the other office with what waits there and one button for each way you can go (rail pass, paid ticket, car, plane), each greyed with its reason. The strip and the mode row on the Office are unchanged. |
| Draft a Bill | On the frame: Your bill (each part removable, the hearing committee), If it passes (the vote, the influence it needs, the effects, the extra visit), Add a part from (organizations, then one organization's parts). **Draft** is fixed in the foot, greyed with its reason. |
| A bill to carry | A pop-up card: the organization's icon and what it asks, the vote and your party's position, the rewards, the amend options in the body; **Carry** filled and **Decline** (with its cost) last. |
| Law detail | A pop-up card whose tag is the outcome: PASSED in green or FAILED in red. |
| Party detail | On the frame: a band in the party's colour, its seats and leader (two Text rows), how it sees you, then Allies and Rivals as cards. Rival bars are the card's ink (white on the old dark panel would vanish on a light card): `office_menus_driver.gd` now expects that. |
| Promises | One tile for each promise: what and for whom, the time left (in the fall colour when it is close), the office, Keep. |
| Text | `travel.page_title`, `travel.where_title`, `travel.all_trips`, `party_opinion.seats_line`, `party_opinion.seats_line_no_leader`. |
| Tests | `tests/test_group6_bills_travel.gd` (6). One click test changed on purpose (`office_menus_driver.gd`, the rival bar colour). |

## 2026-11-20: P14b commit 4: Appearance and Music, How to Play, Characters and New Game (Cameron: Go)

| Part | What changed |
|---|---|
| Appearance and Music | On the shared frame (Funds and XP chips): one card for each package still to buy (picture, name and price, description, Buy), then one card for each slot with its owned options. The equipped option is **filled** in the accent colour. |
| How to Play | On the frame: the group names, then one numbered card for each entry with its picture or video slot. Used from the title screen, the Office and the battle. |
| Characters | On the frame: a card for Opponents and one for Visitors, the names in **two columns**, each with the character's colour as a thick left edge; people not met yet are dimmed as 誰ですか。 |
| New Game | On the frame: the Pressure and Theme strips in one card, then one card for each champion with its Choose button in the accent colour. **Not built:** the spec's pick-a-portrait-then-"Play as {name}" flow and three-way switches. That would change how a run starts, and you tuned the swipe strips and the Choose buttons recently, so I kept them; tell me if you want the new flow. |
| Tests | `tests/test_group7_reference.gd` (4). No click test changed. |

## 2026-11-20: P14b commit 5: the level intro's bill card (Cameron: yes, redraw it)

| Part | What changed |
|---|---|
| Bill card | The bill's name, what it does and who is for and against it are one card in the style's own look, with the stance note on a plate under it, so none of it sits as thin text on the room picture (it overlapped itself at some sizes before). Read the Bill and Let's go are dressed like every other choice. |
| Party disc | The two lean buttons show the party leader's portrait where one is in the assets, else a round colour disc with the first kanji of the party's Japanese name and its English initials. `PartyDiscView` is shared with the Floor Vote's party strip. |

## 2026-11-21: New Game built to the mock-up (Cameron: "Use the mock up version")

| Part | What changed |
|---|---|
| Flow | The four champions are a row of portraits; tapping one shows that champion's card (name, party, district and office, blurb, starting numbers in two columns). **Political Pressure** and **Theme** are three-way switches under it. **Play as {name}** is fixed in the foot and starts the run. Before, each champion had a card with its own Choose button, and the two choices were swipe strips. |
| Behavior kept | Choosing a theme still tries it at once and reopens this screen; the picked champion is remembered across that restyle. Backing out works as before (a first launch plays the default champion). |
| Text | `new_game.district_line` ("{district} · office in {office}"). |
| Tests | `new_game_driver.gd` and `intro_driver.gd` changed on purpose (tap the portrait, then Play as); `tests/test_group7_reference.gd` checks the portraits, the picked card, Play as in the foot and the switches. |

## 2026-11-21: The forced move card, with one line per staff role and a list true of the office (Cameron)

| Part | What changed |
|---|---|
| MOVED FOR YOU | A calendar event at the other office now opens a card of its own first (red tag, the day and "0 h"), then the event. The card says where you are, has a line from your **first primary staff member, one line per role** (Policy Research Assistant, Media Spokesperson, District Representative), says why you were taken there, lists what is not open here, and says the trip cost no hours. Continue opens the event. |
| "Not open while you are here" | **Reflective of the office** (Cameron): `ClosedHere` reads the Location tags on levels, events and visitors and lists the kinds that belong only to the other office, so it is true at either office and a kind with nothing tagged is not listed. |
| Text | Seven new rows, all drafts for you to reword: `travel.moved_line_research`, `_media`, `_district`, `travel.moved_speaker`, `travel.closed_levels`, `_events`, `_visitors`. |
| Tests | `tests/test_closed_here.gd` (4). |

## 2026-11-21: Lead organizations on events (Cameron)

| Part | What changed |
|---|---|
| Column | The Events tab has an optional **Lead Organizations** column (workbook schema change, approved): up to two organization IDs. A lead is an organization the event's own text names, usually the one bringing the issue forward; an organization with only a passive plus or minus from a choice is not a lead. |
| Filled | 24 events name one or two organizations in their own title or flavor, and those are filled as drafts for you to confirm. 79 events name none and stay blank by your rule. **EV90** is flagged: Family Network is named only as the picnic held at the same time. |
| Checked | The exporter errors on more than two or an unknown organization, and warns when a lead is not named in the event's own text. `EventLeads` reads the column; `tools/audit_event_leads.py` writes the review (`design/review/event_lead_organizations_2026-11-21.md`): no event names more than two; organizations named only in choices (EV01, EV93, EV99); 22 events whose choices give a passive plus to three or more organizations; 16 events with no organization at all. |
| Shown | The event card shows each lead's icon and name under the story. |
| Tests | `tests/test_event_leads.gd` (4). |

## 2026-11-21: Lead organization flags closed (Cameron: "Close out the flags")

| Flag | Decision |
|---|---|
| EV90 | Both organizations stay leads: the event is a choice between the Financial Industry Association's workshop and the Family Network's picnic, and both are named in its own flavor. Delete one ID to change it. |
| EV93, EV99, EV01 | No lead: their organizations appear only in choice results (passive). |
| 22 events with passive plus to three or more organizations; 16 with no organization | No change, by the rule. |
| Audit | `tools/audit_event_leads.py` keeps these decisions in `REVIEWED` and lists them under "Closed", so they are not raised again. No data changed. |

## 2026-11-21: The dinner is the Capitol's and the walking tour the District's (Cameron)

| Part | What changed |
|---|---|
| Lock | The Hosted Events tab has an optional **Location** column (workbook schema change, approved): HE02 the dinner = Capitol, HE01 the walking tour = District (blank or Either means anywhere). At the other office the Marketplace item's **Use button is greyed with the reason** ("This can only be hosted at the Capitol."), and the rules refuse it too, so nothing is spent and no evening begins. The item can still be bought. |
| Code | `Items.office_refusal` (pure), `GameState.item_office_refusal`, used by `use_item_in_office` and by the inventory's Use button. The exporter checks the new column like every other Location. |
| Text | `item.refused.hosted_office`, a draft for you to reword. |
| Tests | `tests/test_hosted_office_lock.gd` (5). Changed on purpose: `inventory_driver.gd` (host the tour from the District) and three unit tests that used the dinner or tour (`test_gated_levels`, `test_hosted_event`, `test_inventory`) now stand at the right office. |

## 2026-11-21: Sponsored and custom bills are Capitol-only (Cameron)

| Part | What changed |
|---|---|
| Where | Sponsored bills (organizations asking you to carry one) and custom bills (**Draft a Bill**) are carried at the Capitol only. At the District the levels list hides both and says so ("Sponsored and custom bills are carried at the Capitol."). |
| Rules | The office is read from the bill-level templates' Location (all four are Capitol), so retagging a template moves the bills. A bill level now carries that office, so the same office check as every other level refuses a sponsored bill started from the other office, and a draft is refused with "go to the Capitol". Nothing is spent and the request stays as it was. |
| Text | `office.bills_capitol_only`, a draft for you to reword. |
| Tests | `tests/test_bills_capitol_only.gd` (4). No existing test needed changing. |
## 2026-11-21: Accented letters match their sentence (a tester's problem report; Cameron)

| Part | What changed |
|---|---|
| The problem | A tester's report: the "Ō" in "Ōminato" was drawn in a different font from the rest of its sentence. Shippori Mincho B1 (Woodblock body) and Zen Kaku Gothic New (Living Office body) have no ō, Ō, ū, Ū, ā or ī, so those letters were borrowed from Noto Sans JP. |
| Fix | You asked for the Latin-extended pieces and for Antaka to be checked. The Latin-extended pieces of Shippori and Zen turned out to hold no macron letters at all (the fonts do not have them), so none were added for those two. **Antaka Brush Text has every accent the game uses**, so it is now the first fallback behind both body fonts; Noto stays last for Japanese and the symbols none of them has. Barlow Condensed (Broadcast headings) takes its own Latin-extended piece (one new font file, 15 KB, same family and licence). Antaka Brush Display and Text are unchanged where they are used. |
| Documents | The brief said Antaka had no ō; it does. Fixed in `CLAUDE.md`. |
| Tests | `tests/test_accent_fonts.gd` (2): the fallback order, and every accented letter the text uses is in a face of the chain. |

## 2026-11-21: Cameron's workbook merge, the district swap and the neighborhood pictures

| Part | What changed |
|---|---|
| Workbook merge | Cameron's upload (`cee6b85`) is exported into the game's data: **104 new office notices** (ON21 to ON124, 54 at the District and 50 at the Capitol, by staff role) and new blurbs for the four protagonists. |
| District swap (final, Cameron) | Kenshin Sako (PC01) is now **Sōya, office Daikoku**; Jyurou Nishihara (PC04) is now **Aomori, office Noheji**. Everything that follows a district moved with it: the **travel hours** (PC01 6 h train and 4 h car; PC04 7 h train and 2 h plane), the **plane ticket** offer and the four **starting plane tickets** (now PC04's; the private car is offered to PC01, PC02 and PC03), all **65 Places rows**, the four **protagonist levels** (LV115 and LV116, Sōya, to PC01; LV121 and LV122, Aomori, to PC04), and the district starting items (SH25 and SH29, from the Player tab). The **District office pictures are not swapped**: each protagonist keeps `DISTRICT_OFFICE_<their id>`. |
| Neighborhood pictures | The four events and three stages that named `OUT_NEIGHBORHOOD` now list all eight numbered pictures (`_1` to `_5` and `WINTER_1` to `_3`); the winter ones are chosen when the text is wintry. |
| Tests | Eight tests that pinned the old assignment now expect the new one: `test_office_state`, `test_offices_content`, `test_offices_travel`, `test_place_tokens`, `test_protagonist_levels`, `test_travel_tickets`, and the click drivers `travel_driver` and `level_briefing_driver`. |
## 2026-11-21: New backgrounds uploaded (Cameron): 12 pictures

| Picture | State |
|---|---|
| `DISTRICT_OFFICE_PC01` to `_PC04` | **In use already.** The Office asks for `DISTRICT_OFFICE_<protagonist>` at the District, so each protagonist now shows their own District office picture (before, a labelled placeholder). Checked for all four. |
| `OUT_NEIGHBORHOOD_1` to `_5`, `OUT_NEIGHBORHOOD_WINTER_1` to `_3` | **Not yet used.** Events and stages name the scene `OUT_NEIGHBORHOOD` with no number, so these need the workbook's Image cells to list them (`OUT_NEIGHBORHOOD_1; OUT_NEIGHBORHOOD_2; ...`); a picture whose name carries WINTER is chosen when the text is wintry. Waiting for Cameron's workbook merge so the two edits do not collide. |
| Files | The import files Godot makes for the 12 pictures are added. |

## 2026-11-21: Protagonist pictures for PC02 and PC03 (Cameron)

| Part | What changed |
|---|---|
| Updated pictures | The six expressions (neutral, attacking, damaged, gaining, guarding, victory) of **PC02 Haru Yashi** and **PC03 Arata Ran** were replaced with the new drawings. |
| Red outfit | Twelve new red-outfit pictures arrived named `PC02_attacking_red.png` and so on. The game looks for `<ID>_RED_<expression>.png` (as PC01 and PC04 already have), so the files were **renamed** (a git rename) to `PC02_RED_attacking.png` etc. The red outfit (cosmetic package CP01) now has all four protagonists and all six expressions. |
| Test | `tests/test_protagonist_outfit_pictures.gd` (2): the red picture resolves for every protagonist and expression, and the plain one is used without the outfit. |
## 2026-11-21: New visitor pictures (Cameron): 23 visitors

| Part | What changed |
|---|---|
| Pictures | `VI79` to `VI100` and `VI164` arrived (Rera Saru, Koichi Satomi, Takashi Hamada, Michiko Sasaki, Setsuko Omura and the rest). All 23 are in the Visitors tab and use the `<ID>.png` name the loader expects, so they show at once. The import files Godot makes for them are added. |
| To check | **VI79 (Rera Saru) is 154 x 493 px**, about a third the height of the others (most are over 1,300 px), so it will look soft at the size a visitor is shown. |
| Still without a picture | 63 visitors in the Visitors tab (VI19 and VI101 onward, with gaps) still show the labelled placeholder. |

## New visitor pictures VI101 and VI102, VI100 updated, three style icons (2026-11-21, Cameron)

| Part | What changed |
|---|---|
| Pictures | `VI101` (Sachiko Nomura, Farmers' Market Manager) and `VI102` (Tomekichi Sakai, Eighty-Four-Year-Old Farmer) arrived and match their Visitors-tab rows, so they show at once. `VI100` (Kenta Aoki) was replaced with a new picture. Their import files are added. |
| Style icons | `CP07`, `CP08` and `CP09` arrived in `assets/icons`, with import files. They are not shown yet: the Cosmetic Packages tab's Icon cells for CP07 and CP08 are blank and CP09 has no row; that waits on the Yezo Office decision. |
| Still without a picture | 61 visitors in the Visitors tab. |
## Decision! scenes, phase 1: the Decision Scenes tab and Mandatory scenes (2026-11-21, Cameron; branch `feature/decision-scenes-1`)

The first of four phases of the plan in `design/proposals/DECISION_SCENES_SCHEME_2026-11-21.md` (on branch `docs/art-gaps-and-decision-scenes-2026-11-21`). Content only so far: the Prime Minister's Opening Address (EV47) is now scene **DS01**, and plays exactly as before with two differences: its speaker comes from the new tab, and its card says **Mandatory**.

| Part | What changed |
|---|---|
| New tab | **Decision Scenes** in the workbook: Scene ID, Event ID, Kind (Mandatory or Optional), Opens, Closes, Office, Speaker, Second Speaker, Speaker Face, Scene Picture, Follows, Delay, Follow If, Activates, Notes. Exported to `data/decision_scenes.json`. The Events row still holds the title, flavor text, choices and rewards. |
| Checks | The exporter errors on: an Event ID that is not in Events, is not Dated, or whose On Date or Location differs from the scene's Opens or Office; an unknown Kind, Office or Speaker Face; a Speaker that is not an opponent, staff or visitor ID; an Optional scene with no Closes or a Closes before Opens; a scene ID or event used twice. A Scene Picture with no file is a warning. Follows is refused until phase 2. |
| Card | A scene's card ends with a note: "Mandatory. It opens on its date, wherever you are." (Optional text exists for phase 4.) Speakers can be opponents, staff or visitors, up to two side by side, wearing the Speaker Face. A scene's own pictures come before the event's Image cell. |
| Where you are taken | The scene's Office decides where a Mandatory scene takes you, and the Events lists show it. |
| Rules | `scripts/rules/DecisionScenes.gd` (pure) and `GameState.decision_scene_of`, `event_speakers`, `event_office`. A scene fires once because its event is Dated and is remembered in `dated_events_done`, as before. |
| Tests | `tests/test_decision_scenes.gd` (new) and a Mandatory check in the Dated-event click test. |
| Not yet | Follow-ups (phase 2), activations (phase 3), Optional scenes (phase 4), the `DEC_` picture fallback chain and the art checklist section. |

## Decision! scenes, phase 2: follow-ups with branching (2026-11-21, Cameron; branch `feature/decision-scenes-2`, stacked on `feature/decision-scenes-1`)

Content is still only DS01; the machinery now exists for you to write follow-ups in the Decision Scenes tab. Nothing in play changes until a follow-up row is added.

| Part | What changed |
|---|---|
| How to write one | A follow-up is a row whose **Follows** names an earlier scene, with **Delay** (days after that scene was *answered*) and **Follow If** (the earlier scene's choice letters that lead here; blank = any choice). Its **Event ID** is an Events row with Trigger **Followup** that holds its title, text and choices. **Opens** stays blank. |
| Branching | Two follow-ups may follow the same scene with different Follow If letters; only the one matching the choice made comes. A follow-up may itself be followed. |
| Limit | One first scene has at most **five** follow-ups in all, down every branch; the exporter errors above that. It also errors on a Follows that is not a scene or loops back, a Follow If letter the earlier event has no choice for, and a follow-up whose event is not Followup or which has an Opens. A blank Delay is a warning (the follow-up comes the day the earlier scene is answered). |
| In play | Answering a scene records the day and the letter (`GameState.decision_log`, saved). A follow-up comes due on that day plus its Delay and opens by itself at the next Office open, taking you to its office free, like any Mandatory scene; it wears the same DECISION! tag and Mandatory note, with no counter. It fires once. |
| Coming up | A follow-up whose Delay is running shows in the Events screen's Coming up tab. |
| Rules | `DecisionScenes.due_day`, `due_follow_ups`, `upcoming_follow_ups`, `descendant_count`, `follow_if`, `children_of` (pure). |
| Tests | Eight new tests in `tests/test_decision_scenes.gd` (delay from the answered day, branching, window, five-limit counting, loops, saving). |

## Decision! scenes, phase 3: scenes that start other parts of the game (2026-11-21, Cameron; branch `feature/decision-scenes-3`, stacked on phase 2)

Machinery only; no scene in the workbook activates anything yet, so nothing in play changes until you fill an **Activates** cell.

| Part | What changed |
|---|---|
| How to write it | The **Activates** cell lists entries `kind:ID` separated by `;`. Kinds: `level:LVxx` (an existing level, usually Event Only), `stage:STxx` (one room on its own), `vote:BIxx` (a Floor Vote on a named bill or motion row of the Floor Votes tab), `event:EVxx` (queued for the next Office visit), `unlock:LVxx` (the level becomes available, like a choice's Unlocks Level). |
| One addition to the scheme | An entry may end with `@A,B` to fire only for those choices ("vote:BI51@A; event:EV30"). Without it the entry fires whatever was chosen. This lets "Skip it" differ from "Take part" without a second scene. |
| In play | Answering the scene applies unlock and event at once. A level, stage or vote waits: the result card says "Next: <name>.", Continue opens its normal briefing, **Back leaves it waiting** and the Office offers it again each time it opens until Go in begins it. A stage or vote becomes a one-stage level (`DSL_<kind>_<ID>`); a debate-then-vote is a level that ends in the vote, or a stage entry followed by a vote entry on a later follow-up scene. |
| Not a cleared level | A scene's one-stage level is not added to the levels-cleared list. |
| Saving | Waiting activations and the level being played are saved (`pending_activations`, `scene_runtime`). |
| Checks | The exporter errors on an unknown kind, an ID that is not a level, stage, bill or event, a malformed entry, and an `@` letter the scene's event has no choice for. |
| Tests | Six unit tests (parsing, limits by choice, the one-stage level, unlock, queued event, playing a vote to its end) and a real-click test `scene_activation_test` (answer, result card, briefing, Back, offered again, Go in, a one-stage Floor Vote). |
| Not yet | Optional scenes (phase 4) and the `DEC_` picture fallback chain. |

## Decision! scenes, phase 4: Optional scenes, lapses and the picture fallback (2026-11-21, Cameron; branch `feature/decision-scenes-4`, stacked on phase 3)

The scheme is now fully built. Nothing in play changes until you write scenes: only DS01 (Mandatory) exists. A how-to is in `design/CONTENT_GUIDE.md` ("Decision! scenes").

| Part | What changed |
|---|---|
| Optional scenes | Kind `Optional` with a Closes date (or, for a follow-up, a window from its Delay to its Closes). They never open by themselves and never move you. The Events screen's Arrange here tab lists each as a red DECISION! card with "Optional · N days left" (or "last day"), its office, and **Open it**; away from its office the button is greyed with "Open this at <place>." The Coming up tab lists ones opening soon. Opening one shows the usual card, with the note "Optional. You chose to open this one." |
| Lapse | When the window closes unopened, the Office opens with one "Missed decisions" card: each title, "You let this one pass.", the L choice's result text and its effects. The scene is then remembered, so it is told once. The penalty charges what there is (never refused), spends no hours, and a scene with no L row lapses quietly. Follow If may use `L`. |
| Reserved letter | An event may have a choice lettered `L` only if its scene is Optional; it is never a button (`EventEngine.choices_for` hides it). |
| Pictures | A scene with no Scene Picture and no event Image wears `DEC_PLACE_CAPITOL` or `DEC_PLACE_DISTRICT` when drawn (one picture per office, a simplification of the planned `DEC_PLACE_<OFFICE>_<name>`). The art checklist has a Decision scenes section. |
| Text | Eight Text rows (`event.optional_*`, `decision.lapsed_*`). |
| Tests | Nine unit tests (windows, lapse, never self-opening, the hidden letter, penalty once, quiet lapse) and a real-click test `optional_scene_test` (lapse card on opening the Office, the listed card with its days, Open it, the note, answering once). |

## Woodblock is the default look; Yezo Office is a package (2026-11-21, Cameron; branch `feature/ui-default-woodblock`)

| Part | What changed |
|---|---|
| Default | A new Rules-tab switch, `default_ui_style`, is `woodblock`. The New Game screens, the loading screen and any run or save with no style picked show Woodblock. Before, the code assumed Living Office in these places. |
| Yezo Office | The old Living Office is now **Yezo Office**, package **CP09** (Name 会議室, "A modern office inspired by tradition.", 1 XP, UI Style `living_office`). All three styles are packages; the exporter requires exactly one package for each. |
| The pick | The style chosen on the New Game screen is owned free and equipped; the other two are bought in the Marketplace Styles tab ("Unlock · 1 XP"). A run with no pick, and a loaded save with no style, is given Woodblock free. A loaded save that already wears an owned style keeps it. |
| Marketplace | The Styles tab draws all three cards from their packages, with the icon beside the name. The blurb reads "The style you picked at the start is yours; the others cost XP." |
| Icons | CP07, CP08 and CP09 are named in the Icon column, so the three new pictures show. |
| Old saves | A save made before this with the old default (no style equipped) now opens in Woodblock. |
| Tests | Three test files updated for the new default; two new tests (a save with no style is given the default; a worn style is never overwritten). |
| Cleanup candidates | Three Text rows are now unused: `shop.style_living_name`, `shop.style_living_desc`, `shop.style_included` (listed in `design/CLEANUP_CANDIDATES.md`). |

**Known issue found while making Woodblock the default (2026-11-21); closed 2026-11-23: Cameron accepted it as is.** on the stage Details screen the organization icons sit on a light plate. In Yezo Office each icon has a dark tile and reaches 8.7 to 1; in Woodblock the tile is light paper and some icons reach only about 2.8 to 1 (the standard is 3 to 1), with a grey halo behind neutral ones. `tests/interaction/party_plate_test.gd` therefore measures those icons in Yezo Office. (Options were a dark tile under organization icons in every style, or redrawn icons; neither is planned.)

## Visitor pictures VI103 to VI125, VI168, VI169; VI100 replaced again; two renames (2026-11-22, Cameron; branch `feature/visitor-images-4`)

| Part | What changed |
|---|---|
| **Replaced picture (flagged)** | **`VI100` (Kenta Aoki) was replaced again** (first on 2026-11-21, now a second time). No other existing picture changed. |
| New pictures | `VI103` to `VI116`, `VI118` to `VI125` (VI117 is not in the upload), plus `VI168` and `VI169`, with their import files. Visitors VI103 to VI125 already had rows; **VI168 and VI169 have no workbook rows yet**, so their pictures wait (see `design/proposals/UPCOMING_VISITORS_VI168_VI169_2026-11-22.md`, with the questions for you). |
| Renames | VI123 is now **Javier Santos** (ハビエル・サントス, was Masato Kondo) and VI124 **Gabriella Santos** (ガブリエラ・サントス, was Michiko Aoki). Name, Japanese name and the romaji cell changed; nothing else did. |
| Font | The shrunken Japanese font was re-subset so the new katakana names draw in Japanese rather than the fallback. |

## VI168 Picante Paul and VI169 Kakata Jishinka; a Seasons column for visitor questions (2026-11-22, Cameron; branch `feature/visitors-vi168-vi169`)

All wording, effects and rooms are **drafts for Cameron**. The full record of his answers is in `design/proposals/UPCOMING_VISITORS_VI168_VI169_2026-11-22.md`.

| Part | What changed |
|---|---|
| Seasons column | The Visitor Questions tab has a **Seasons** column. A question naming seasons is only asked in those months, using the same season table as Events and Levels; if none of a visitor's questions is in season, any may be asked. The exporter checks the names. |
| VI168 Picante Paul (ピカンテ・ポール), Celebrity | Capitol only; Chamber of Commerce (BO05) and Innovation Society (BO16). Four questions, VQ430 to VQ433, one per season, about the brand Doki Doki Picante Pulse. The season's flavor is right (Spring Mikan, Summer Cherries, Autumn Chestnut, Winter Yuzu); the other twelve flavors are out of season or not Japanese, and none repeats across the questions. |
| VI169 Kakata Jishinka (侍臣家 過形), Retired | Capitol only; Members of Parliament (BO17) and Innovation Society (BO16). Four questions, VQ434 to VQ437, on the Liberal Party of the nineties and the Ministry of Ethics and Prosecution. His 1993 ministry and the coalition are never stated; his reactions only hint at them. |
| Rooms | Both use VI14's Capitol room list as a draft; please say where they should appear. |
| Liberal Party | The values Cameron gave are saved in `design/proposals/LIBERAL_PARTY_VALUES_2026-11-22.md`; it is historic and not in the game's parliament, so it is not in the Parties tab. |
| Tests | `tests/test_picante_and_jishinka.gd`: one question per season, the right flavor for each, sixteen distinct flavors, the question drawn matches the current season, no backstory in the questions, Capitol and organizations. |
| To do | Review the other 421 visitor questions for seasonality (noted, not started). |

The four right-answer replies of Picante Paul's questions carry ドキドキ・ピカンテ・パルス as an emphasis (Cameron's note, 2026-11-22). The draft effects were rebalanced to the content budget (a gain needs a cost, every choice 2 to 7 in size), and the Capitol visitor count in `tests/test_offices_content.gd` is now 25.

## Seasons on 42 older visitor questions, rooms for VI168 and VI169, a start-up guide refresh (2026-11-22, Cameron)

| Part | What changed |
|---|---|
| Seasons applied | Cameron approved the draft list (`design/review/visitor_questions_seasonality_draft_2026-11-22.md`) with a rule: a question about a **general matter** also takes the season before ("Autumn; Winter"); a **temporal** matter about what is happening now takes only its own season (VQ230, VQ260, VQ232, VQ250, VQ261, VQ270, VQ323, VQ374, VQ375, VQ380, VQ401, VQ413, VQ416, VQ421, VQ02). 42 Seasons cells were filled. |
| VI168 rooms | ST07, ST113, ST153, ST213, ST281, ST275, ST276, ST282, ST274 (Cameron's list). |
| VI169 rooms | ST07, ST281, ST105, ST110, ST170, ST193, ST118, ST120, ST274 (the suggestion without ST253, ST22 and ST276). |
| Text rows deleted | `shop.style_living_name`, `shop.style_living_desc` and `shop.style_included` (Cameron's go). |
| Documents | `design/NEW_CHAT_STARTUP.md` and the data snapshot in `CLAUDE.md` now describe Decision! scenes, Woodblock as the default, the new visitors and the current counts. |

**Layout fix found by the text sweep (2026-11-22):** adding VI168 and VI169 to the Office Hours room changed which visitor the sweep's fixed random draw picks (it now draws VI74), and that exposed an old problem: at 1080 x 1920 with Normal or Large text, a question whose choices wrap pushed Continue (and at Large, Choice D) partly off the bottom of the screen. The Office Hours window now keeps its usual height but gives up room when the question and choices below it need it, and grows back when they do not (`VisitLayout.fit`, new `shrink_only` option, used by `VisitorScreen`). Nothing changes on a screen where everything already fits.

## Visitor pictures VI126 to VI136 and VI170 to VI173 (2026-11-22, Cameron; branch `feature/visitor-images-5`)

| Part | What changed |
|---|---|
| Where they were | The upload put the 15 pictures in `assets/` instead of `assets/characters/visitors/`; they were moved. |
| Typo fixed | `V134.png` was renamed **`VI134.png`** (Taro Yoshida, Hospital Cleaner). |
| New pictures | `VI126` to `VI133`, `VI134`, `VI135`, `VI136`: all have visitor rows, so they show at once. **No existing picture was replaced.** |
| Pictures without a visitor | `VI170` to `VI173` had no rows; they were drafted the same day (next entry). |
| Still without a picture | 28 of the 173 visitors. |

## VI170 to VI173: four District service workers, 24 draft questions (2026-11-22, Cameron's "Go")

All names, titles, wording and effect numbers are **drafts for Cameron to rewrite**; the descriptions were drawn from the pictures.

| Visitor | Draft | Organizations | Questions |
|---|---|---|---|
| **VI170** Chizuru Nagai 長井千鶴 | Home Care Agency Coordinator | Care and Welfare Council, Labor Federation | VQ438 to VQ443: unpaid travel, night staff, forms, snow-closed routes, mentors, pay |
| **VI171** Mio Sugita 杉田美緒 | Senior Meal Delivery Worker | Care and Welfare Council, Family Network | VQ444 to VQ449: fuel, a skipped lunch, a broken van heater, the menu, paid chat time, cutting delivery days |
| **VI172** Nanami Arai 新井七海 | Visiting Nurse | Care and Welfare Council, Labor Federation | VQ450 to VQ455: travel pay, a patient who refuses help, a snowed-in dialysis patient, overtime, medication records, rural placements |
| **VI173** Reina Mochizuki 望月玲奈 | Courier Rider | Labor Federation, Small Business Owners' Association | VQ456 to VQ461: insurance, snow-day bans, per-parcel pay, fines for road delays, medicine runs, small-shop shipping |

All four are District visitors in the same rooms as VI125 (ST268, ST283, ST284). Each question follows the content budget (a friend-pleasing choice, a rival-pleasing one, a middle path and a refusal; a gain always has a cost) and the right answer rotates through A to D. The four winter questions (VQ441, VQ446, VQ452, VQ457, each a general matter) carry `Autumn; Winter`. `tests/test_visitors_170_to_173.gd` covers it, and the District visitor count in `tests/test_offices_content.gd` is now 132.

## The speech coach on the Rhetoric Training page (2026-11-22, Cameron; branch `feature/speech-coach`)

| Part | What changed |
|---|---|
| Picture | Cameron's `SPEECH_COACH.png` (an older man in a wheelchair with a microphone and headphones, 720 x 815) was uploaded into a folder spelled `captial area`. It now lives in **`assets/characters/capital_area/`**, a new folder kind for **special characters in the Capital Area, outside the Capitol building** (Cameron: the Capitol and the Capital Area are distinct), registered in `data/art.json` (`folders.capital_area`, and `character_prefixes` maps `SPEECH_COACH` to it). Future Capital Area pictures go in `assets/characters/capital_area/` named by their ID. |
| The page | The **Rhetoric Training** tab (Office Management) opens with a card: the coach's picture, the heading **Speech Coach** and the page's own introduction ("Book a session with a speaking coach..."), then the coupon note and the three sessions as before. |
| Name | The heading is a title only: **no personal name has been given**, so none is shown. Please say if he has one (and a Japanese name). |
| Art checklist | A new "Capital Area characters" line lists SPEECH_COACH. |
| Tests | `tests/test_speech_coach.gd`. |

## Rhetoric Training sessions take time: one hour per tier (2026-11-23, Cameron; branch `feature/training-hours`)

| Part | What changed |
|---|---|
| The rule | A Tier 1 session takes 1 hour, Tier 2 takes 2 and Tier 3 takes 3. The number is a new Balance row, **Rhetoric Training: Hours Per Tier** (1), times the tier. |
| When | The hours are taken when the session **begins** ("See a card"). Passing on a card, learning it, or reopening a draw already in progress takes nothing more, and a draw left open when the app closes has already been paid for. |
| Coupons | A Training Session Coupon's free session takes its tier's hours too (decided here; say if a coupon should be free of time as well). |
| No time | The "See a card" button is greyed with the usual reason ("Not enough hours left for that." or "The work week is over."), and a coupon's Use button is greyed the same way. |
| The page | Each session row names its hours: "Tier 2 session  —  500 XP  —  2 hours" (Text rows `rhetoric.session` and `rhetoric.session_one`). |
| Tests | `tests/test_training_hours.gd`. |
## The speech coach has a name: Masayuki Katō (2026-11-23, Cameron; branch `feature/coach-name`)

The Rhetoric Training card now shows **Masayuki Katō** as its heading with **加藤** (the surname, the only kanji given) as a muted accent beside it, then "Speech Coach" and the page's introduction. Two Text rows (`rhetoric.coach_name`, `rhetoric.coach_name_jp`). If he has a given-name kanji, say so and the accent can read in full.
## Checks: the full gate only before a merge; one-area click tests (2026-11-23, Cameron's option A; branch `docs/checks-option-a`)

| Part | What changed |
|---|---|
| Why it was slow | A full `tools/verify.sh` takes 15 to 18 minutes on this 4-core machine: data, boot and about 2,450 unit tests about 3.5 minutes; 54 real-click tests (each starts a fresh game on a virtual screen, 12 to 36 s) about 10 minutes at two at a time; the text sweep in three UI styles about 5 minutes. The old header said 2 to 3 minutes. |
| The routine now | While working: `tools/verify.sh --quick` (about 3 to 4 minutes) and `tools/click_test.sh NAME...` for the click tests of the area touched. The full gate runs once, right before a merge, and a merge still needs its "All checks passed". |
| New tool | `tools/click_test.sh`: runs only the named click tests the way verify.sh runs them; `--list` shows all 54. |
| Docs | `tools/verify.sh`'s header, `CLAUDE.md` section 14 and `design/NEW_CHAT_STARTUP.md` section 4 say this. |
| Closed out | The Woodblock icon contrast item (accepted as is) and the coupon-takes-hours decision (confirmed). |

## The speech coach's kanji: 加藤正幸 (2026-11-23, Cameron; branch `feature/coach-name-kanji`)

Cameron added 正幸 for Masayuki: the muted accent beside **Masayuki Katō** now reads **加藤正幸** (family name first, as is usual in Japanese). The Japanese font was re-subset so 正 and 幸 draw in it. **Merged without the full check at Cameron's instruction** (a one-text change); the speech coach unit test and the data export were run.

## New visitor pictures VI137 to VI166, VI174 checked; VI174 Harue Kobayashi added (2026-11-23, Cameron; branch `feature/visitor-images-6`)

**Review of the upload (28 files):**

| Check | Result |
|---|---|
| Replaced pictures | **None.** All 28 are new files; no existing picture changed. |
| Valid files | All 28 are PNGs in `assets/characters/visitors/` and imported (import files added). |
| Rows | 27 match a Visitors-tab row (`VI137`, `VI139` to `VI143`, `VI145` to `VI163`, `VI165`, `VI166`). `VI174` had none; it is drafted below. |
| Low resolution (flag) | `VI143` (Mika Kobayashi) is **397 x 915**, under half the usual 720 x 1648 and soft at portrait size. `VI79` (Rera Saru) is 411 x 1122 (it was 154 x 493 before it was redrawn; better, still small). Every other picture is at least 413 x 1181. |
| Gaps left | **1 of 174 visitors has no picture: `VI19`.** Every other visitor has one, and every picture has a visitor. |

**VI174, a draft for Cameron to rewrite.** From the picture (short brown hair with orange tips, glasses, a cow-print vest, a grey apron, pink boots, a big grin, a jug of milk) and the sister link to VI154 Kimiko Hasegawa, Dairy Farmer in Nakashibetsu:

| Part | Draft |
|---|---|
| Name | **Harue Kobayashi**, 小林春江 (Cameron, 2026-11-23: the family-name kanji VI143 Mika Kobayashi has; a different name from her sister Kimiko Hasegawa) |
| Title | Farm Creamery Owner |
| Office and rooms | District; the same rooms as her sister (ST270, ST287, ST288) |
| Organizations | Rural Revitalization Council (BO30), Small Business Owners' Association (BO25); Taxpayers' Alliance (BO23) as the cost-minded rival |
| Questions VQ462 to VQ467 | lighter inspection rules for small bottlers; a cheese-room license fee; school lunch milk for local farms; a snow-closed delivery route to Kushiro (`Autumn; Winter`); farm-of-origin labels; succession for a farm with a creamery. Real places only (Nakashibetsu, Kushiro). The right answer rotates through A to D. |
| Tests | `tests/test_visitor_174.gd`; the District count in `tests/test_offices_content.gd` is now 133. |

## VI19 Sora Kudo's picture arrives: every visitor has one (2026-11-23, Cameron)

`VI19.png` (592 x 1452, Ferry Captain Sora Kudo) was uploaded; it is a new file and replaces nothing. With it **all 174 visitors have a picture** and every picture has a visitor. The import file is added. Merged after the quick check.

## Parliament opens on 18.10.15; Yun-hee Seong (2026-11-23, Cameron; branch `fix/ds01-oct15-and-yun-hee`)

| Part | What changed |
|---|---|
| DS01 date | The Prime Minister's Opening Address (EV47, scene DS01) now opens on **Monday 18.10.15**, the day parliament opens (it was 18.10.08). Events On Date and Decision Scenes Opens both read 18.10.15. It shows on the Events screen's "Coming up" list from 18.10.08. |
| Name order | **OP74** is now **Yun-hee Seong** (was "Seong Yun-hee"), matching Lee-min Seong's order. The opponent data, the art checklist and the tests that mention her follow from the Opponents tab. |
| Tests | Date-pinned Decision! and events tests moved a week (week 2, 18.10.15); one new check that nothing opens on Monday 18.10.08 or the Friday after it. |
| Not part of this | The rules asked for with it (staff arranging evening travel the day before a Decision!, keeping levels from running over a Decision!) are in `design/proposals/P15_CPTPP_WHIP_PLAN_2026-11-23.md` and wait for "Go". |

## P15: the CPTPP Decision! sequence, two whips and two votes (2026-11-23, Cameron; branch `feature/p15-cptpp-whip`)

| Part | What changed |
|---|---|
| The chain | DS02 opens **Monday 18.10.22** and has eight follow-ups (approved): DS03 Home Front (Optional, Wed 18.10.24 to Thu 18.10.25, so a long level can outlast it and the Start anyway card shows) and DS04 Business Lobby (Optional, Wed 18.10.24 to Fri 18.10.26), DS05 Resu on the amendment and DS06 Resu on the final (Thu 18.10.25, back to back), DS07 the party whip (Fri 18.10.26), DS08 the amendment vote and DS09 the final vote (Mon 18.10.29, the same sitting), DS10 After the Vote (Optional). Every vote falls before Tuesday 18.10.30; the exporter checks it (`Must End By`). |
| Two whips | OP29 Imekanu Resu, Minister of Agriculture, whips every player in her own scenes: Aye on the amendment, Nay on the final vote. The party whip comes after and only on the final vote; the amendment is a free vote for the party. Siding with a whip moves on; pushing back starts **Whipped into Line** (ST290). Lose one fight and that vote is locked to what that whip asked; lose both whips on the final vote and the player must abstain, taking both penalties. |
| Votes | **BI51** the amendment (34 Aye, 58 Nay, 9 abstain: fails) and **BI52** Joining the CPTPP (63, 29, 9: passes) from Cameron's Story Votes sheet, Absent counted as abstain; no member-level copy is kept, the Floor Votes party positions hold the numbers. Floor Votes gains **Decision Scene**; Decision Scenes gains **Whip Bill, Whip Line, Minister, Vote Bill, Max Follow-Ups, Must End By**. |
| People | OP132 Tomoe Sakamoto, OP133 Isamu Takaoka, OP134 Nobuko Ezaki (Party Whip's Office, party blank: the whip wears the player's party) and visitors VI175, VI176 (they ask the existing whip questions VQ62 to VQ64); `art.json` `character_aliases` gives each opponent its visitor's picture. Parties gains three whip columns, Rules `whip_bands` and `whip_stage`. |
| Rules | A level that would run over a Mandatory Decision! is refused; one that would outlast an Optional window asks first. When a Mandatory scene opens and the player is at the other office, the staff's after-hours trip costs 100 XP (or all they have). A follow-up waits for the fight or vote its earlier scene started. |
| Tests | `test_whip_pick.gd`, `test_decision_clash.gd`, `test_whip_scenes.gd`, the click test `whip_fight_test`, and an exporter check for every new column. Review pictures: `design/review/p15_cptpp_whip_2026-11-23/REPORT.md`. |
| Also recorded | VI143 (Mika Kobayashi, 397 x 915) was accepted on screen: no redraw (Cameron, 2026-11-23). |

## P16: Capitol venues, phase 1 (2026-11-23, Cameron; branch `feature/p16-capitol-venues`)

| Part | What changed |
|---|---|
| Step out | A button on the Capitol office opens a place map: the Capitol Building (Cafeteria, Library, Gardens) and the Capital Area (Speech Coach, Sapporo Stage, Super Station). Walking is free; every venue is open every day; the Library, Stage and Station are greyed "Coming soon". Hidden at the District office, greyed with a reason during a level or when the week is full. |
| Cafeteria and Gardens | Eat with Colleagues and People Watching cost 1 hour a visit. Each venue deals 12 lines a day (seeded by run, day and venue, so a reload never reshuffles); Keep listening reveals up to 8 a day free, then one dry line and "Come back tomorrow". |
| Rhetoric tips | About 1 in 8 lines is a tip about a stage's Favored Suit or an opponent's lead suit, only for levels on offer this week or the next Decision!. Up to 10 are held, each for 14 days; a new one replaces the oldest; the same target refreshes. They show in the tip box, as a Tips button and pop-up on the Levels list, a "tip" badge on a level, and a mark under the tipped room in the briefing. |
| Speech Coach | Now a Capital Area venue; its activity opens the Rhetoric Training page unchanged (sessions, coupons, 1 hour per tier). The Rhetoric Training tab is gone from Office Management. |
| Data | New tabs Venues (6), Venue Activities (6) and Venue Lines (90); the 56 hint and UI Text rows; Rules rows `venue_walk_hours_building`, `venue_walk_hours_area`, `venue_daily_set`, `venue_daily_heard`, `venue_hint_share` (8 = one in eight), `tips_max_held`, `tips_days`. Exporter checks for every column. The run gains `run_seed`, `venue_days`, `venue_heard_once` and `held_tips` (old saves load with none). `GameState.levels_on_offer()` now holds the Levels list's filters. |
| Tests | `test_venue_rules`, `test_venue_lines`, `test_rhetoric_tips`, `test_venue_state`, the click test `venue_test`; the Rhetoric Training click path now goes through Step out. Review pictures: `design/review/p16_capitol_venues_2026-11-23/REPORT.md`. |

## Venue wording: no automatic "You overhear", opponent tips read as a condition (2026-11-23, Cameron; branch `feature/p16-venue-wording`)

| Part | What changed |
|---|---|
| "You overhear..." | No longer added to Gardens tips. A line that wants it writes it in its own words. |
| Opponent tips | Marked under every room the person can be seated in, and worded as a condition: "If {name} is seated here, they respond to [suit]". A stage tip is unchanged. |
| Guide | The rules, style guide and hint and chatter guidelines are compiled in one claude.ai doc; `CONTENT_GUIDE.md` points to it. |

## Tip wording: each suit gets a grammatical phrase; hint phrasings reviewed (2026-11-23, Cameron's comment on the venues guide)

| Part | What changed |
|---|---|
| Suit phrases | Tips say "responds to earnest / emotional / appealing / data-driven / divisive / duplicitous rhetoric" instead of the suit's name; the suit chip stays only in the Tips you hold list. A stage tip reads "The audience in the {stage} responds to ...". |
| Phrasing review | Eleven hint phrasings rewritten: no past events ("last session", "once changed a vote"), no invented facts about people ("half the committee are accountants"), and the people in the room, not the stage, do the liking and deciding, so a TV debate or a press conference reads right. |

## P16b: suit phrases, American spelling, weekend hours, tip slots from hint rows (2026-11-23, Cameron; branch `feature/p16b-venue-rules`)

| Task | Status before | What changed |
|---|---|---|
| 1. Suit phrases | Partly matched (mechanism built, three values differed) | `tips.rhetoric_emotional` is "emotive rhetoric", `_data_driven` "logical rhetoric and data", `_duplicitous` "double-speak". The test now checks the six values and fails on any Text row saying "rhetoric of". |
| 2. American spelling | Partly matched | "theatre" became "theater" in the Earnest stage hint. No other British spelling found in the venue content. |
| 3. Hours, weekdays and weekends | Mostly matched (the hours were already the current phase's pool) | The reasons now say weekday or weekend (two new Text rows), and a refused visit or a look at a venue deals no set. |
| 4. Tip slots from hint rows | Matched | Tests added; the exporter now fails a hint row with Text or a Topic other than `hint`. |

## Venue backgrounds arrive: Gardens follow the season, the Speech Coach page gets its studio (2026-11-23, Cameron; branch `feature/venue-backgrounds`)

Fourteen new pictures in `assets/backgrounds/` (all landscape, 1456 x 816 for rooms and 1792 x 672 or 1792 x 603 for stations). Only Capitol-side work was done; the District places are noted below and left unbuilt, as asked.

| Picture | Used now? |
|---|---|
| `CAPITOL_CAFETERIA`, `CAPITOL_GARDENS`, `AREA_COACH_STUDIO` | Yes: the Cafeteria and Gardens screens, and the Speech Coach page (a new picture at the top). |
| `CAPITOL_GARDENS_AUTUMN`, `CAPITOL_GARDENS_WINTER` | Yes: a venue shows `<its background>_<SEASON>` when that file exists, else the plain one. Seasons are rules.json's table (September to November autumn, December to March winter), the same one the seasonal levels and events use. Any venue gets seasons by adding such files. |
| `CAPITOL_LIBRARY` | Named by the Library's row already; shows when the Library is built ("Coming soon" today). |
| `AREA_SUPER_STATION`, `AREA_SUPER_STATION_TRACKS` | Not wired: Sapporo Super Station (the Departures venue) is "Coming soon". Two views: the concourse and the tracks. |
| `AREA_SAPPORO_STAGE` (renamed from `AREA_SAPPORO_STAGE_STAGE`, Cameron's say-so), `AREA_SAPPORO_STAGE_WINTER` | Named right for the Sapporo Stage row and the seasonal rule; shown when the Stage is built ("Coming soon" today). |
| `AREA_NOHEJI_STATION`, `AREA_TEINE_WARD_STATION`, `AREA_AKENO_SHINMACHI_STATION`, `AREA_DAIKOKU_STATION` | Not wired: District stations, noted for the later District venues work. Renamed 2026-11-24 (Cameron) from Aomori, Sapporo West, Tomakomai and Wakkanai to the District office each serves. |

Code: `VenueRules.seasonal_background`, `VenuesController.venue_picture_id`, the studio picture in `OfficeScreen._show_speech_coach_page`, and a `venue:gardens` screenshot case. Tests: two in `test_venue_rules.gd`.

## Travel at the stations: Cameron's decisions on the mock-up (2026-11-24, Cameron; branch `docs/travel-stations-mockup`; nothing built)

Mock-up: `design/proposals/img/travel_stations/` (board and eight screens).

| Question | Decision |
|---|---|
| Plane tickets and the private car | As mocked up: the plane boards on the concourse (no tracks), the car is listed greyed for protagonists who do not have one. Stations are the hub for travel for now. |
| District offices | Get **Step out**, listing the local station. |
| District station picture names | Named for the District office they serve: `AREA_DAIKOKU_STATION` (PC01), `AREA_AKENO_SHINMACHI_STATION` (PC02), `AREA_TEINE_WARD_STATION` (PC03), `AREA_NOHEJI_STATION` (PC04). The files are renamed. |
| Mixed levels with built-in trips | Travel **stays built into the level**: the trip is taken as the level begins, with the level briefing's own "Travel by" row, unchanged. |

Not built yet: moving the train strip, the mode row and the Travel page to the Super Station and the District stations. That needs a build brief (it touches the Office screen, the venue map and the trip rules) and is outlined for approval before any code.

## Travel at the stations: built (2026-11-24, Cameron; branch `feature/travel-at-stations`)

Cameron's go-ahead on the mock-up and his decisions (above), built as one piece. The train slider is the same component, unchanged in look and behavior (no extra marks).

| Part | What changed |
|---|---|
| The Office | The train strip and the row of ways to go are gone. Step out shows at both offices. |
| Capitol | Sapporo Super Station is built (VN06): the concourse with the Departures card and a To the tracks button, then the tracks screen with the strip. A plane or car leaves from the concourse. Only the protagonist's own fast mode is listed (Cameron, 2026-11-24: no plane for a protagonist who cannot use it, unless other destinations are added); the other is not shown at all. |
| District | One place, `{office} Station` (new Venues row VN07, zone District, new Venue Activities row VA07): one screen with the Departures card and the strip. Its picture is `AREA_<OFFICE>_STATION`, so the renamed files are found by office. |
| Trip | Unchanged (confirm sheet, fade card, hours, tickets, train encounters). Arriving closes the station screens. Travel in a level stays built in. |
| Workbook | 7 new Text rows (`station.*`, `venue.zone_district`), HT36 and HT37 rewritten (three sentences each), `venue.refuse_elsewhere` reworded ("You cannot get there from this office."). Script: `tools/workbook/archive/travel_stations_build.py`. |
| Exporter and tools | Zone District allowed; the art checklist expands the four station pictures and the tracks picture; screenshot, text-sweep and touch-target audits cover the station screens. |
| Tests | New rules and state tests; the travel click test now drives the stations. |

Note on the mock-up: it showed a plane for Kenshin Sako (PC01). The Balance rows give PC01 a private car (4 h) and only PC04 a plane (2 h), so the screens follow the data.

## Characters: the person's page puts the name on top, a big picture in the middle, the facts low (2026-11-24, Cameron; branch `fix/characters-detail-layout`)

On the Characters list's detail page for someone you have met, the name is pinned to the top, the picture is trimmed of empty margin and fills all the room between, and the four facts (name, Japanese name, title, party, organization) and Back sit at the bottom. A person not yet met keeps the old centered page. No rule or wording changed. Screenshot case: `popup:characterdetail`.

## The District's Old Shrine and Local Shotengai on the Step out map (2026-11-24, Cameron; branch `feature/district-shrine-shotengai`)

Eight new backgrounds (`AREA_SHRINE_PC01` to `PC04`, `AREA_SHOTENGAI_PC01` to `PC04`, one of each for every protagonist) and two activity icons (`ACT_SHRINE`, `ACT_SHOTENGAI`) arrived.

| Part | What changed |
|---|---|
| Step out at the District office | Now lists three places under "Around <office>": the station, the Old Shrine (VN08) and the Local Shotengai (VN09). The shrine and shotengai show their own protagonist's picture (a `{PC_ID}` token in the Background cell, filled from the protagonist). |
| What they do | Nothing yet: both are "Coming soon" until Cameron says what a visit gives. Their Venue Activities rows (VA08, VA09) use two placeholder kinds, `shrine` and `shotengai`, which the exporter now accepts. |
| Map cards | Every place card (Capitol too) has a small square of its picture at the left, with the name, Japanese accent and blurb beside it, as in the mock-up. |
| Art checklist | Lists each protagonist's shrine and shotengai picture, and the two new venue icons (`VEN_SHRINE`, `VEN_SHOTENGAI`) still to draw. |

Names, blurbs and Japanese are Claude's drafts. The Places tab has real names for each protagonist's shrine and market (Hokumon Shrine, Tarumae Shrine, Ishikari Benten Shrine, Osorezan Bodaiji or Tanabu Shrine; Wakkanai Central Arcade, Tomakomai Port Fish Market, Benten historic street, Towada Farmers' Market); the venues use generic names until Cameron says whether to show those.

## Venue activities: the Old Shrine, the Local Shotengai and the Library (2026-11-24, Cameron; branch `feature/district-shrine-shotengai`)

Cameron's spec for what each place lets the player do, built as one piece with the shrine and shotengai places above (they merge together). A venue now lists **every** activity it has, one card each, showing cost, what it gives and how many times are left today before it is pressed; doing one shows a result card.

| Place | Activity | Cost | Gives | Limit per day |
|---|---|---|---|---|
| Old Shrine | Clean the surroundings | 2 h | +2 Shrine Association, Buddhist Temples Association, Our Traditional Society | 2 |
| | Place 1,000円 in the saisenbako | 1,000円 | +2 to the same three | 1 |
| | Pay your respects | 1 h | counted; gifts at 5, 30, 75 and 150 times | 1 |
| Local Shotengai | Distribute district office flyers | 2 h | +1 District awareness | 1 |
| | Speak through a megaphone | 3 h | -1 Constituency Voters, -1 Local Kōenkai, +3 District awareness | 1 |
| | Treat local kōenkai members to a meal | 1 h, 15,000円 | +3 Local Kōenkai | 2 |
| Library | Nap | 2 h | +1 energy in the next stage | 1 |
| | Read about management practices | 2 h | +1 work hour for all staff today (+2 from the 51st use) | 1 |

Shrine gifts (Venue Milestones tab, cumulative count of Pay your respects): 5 gives 5,000円; 30 gives a free rhetoric training coupon; 75 gives +10 to the three organizations and District awareness; 150 gives +25 to the same and 100,000円. The screen shows only "Times done: N"; the gifts are a surprise. The Library's Browse the Shelves stays as a greyed Coming soon row.

| Part | What changed |
|---|---|
| Workbook | Venue Activities has six new columns (Rewards, District Awareness Δ, Staff Hours, Bonus After Uses, Bonus Staff Hours, Result Text) and a new Venue Milestones tab (VM01 to VM04). A new Kind `act` (the two placeholder kinds `shrine` and `shotengai` from the places commit are gone). 17 Text rows. Script: `tools/workbook/archive/venue_activities_build.py`. |
| Rules | `VenueActivities` (pure): daily limits, the use log, the staff-hour bonus, milestones crossed. `VenueRules.venue_built`. |
| Game state | `do_activity`, `activity_refusal`, `activity_gives_lines`; saved: `venue_activity_log`, `venue_activity_totals`, `staff_activity_hours`. The Library's staff hours join the Office-box hours in the staff day (`staff_office_hours`). |
| Screens | `VenueActivityViews` (the card), `VenuesController._show_activities` and a result card. |
| Funds limit | A Funds gift is told as the part that fit under the Funds limit (the 150th respect gives up to 100,000円, less if the player is already near the limit). |
| Tests | `test_venue_activities.gd` (rules), `test_venue_activity_state.gd` (the run), the venue click test drives the Library and the shrine. |

Follow-up on the same branch: a long screen title ("National Assembly Library" at the large text size) now steps down in size until it fits the width of the screen (`OfficeScreenFrame._fit_title`); before, it pushed the whole Library screen wider than the phone. Found by the text sweep, which now covers the shrine, its result card and the Library.

## Speech Coach: two practice activities beside Rhetoric Training (2026-11-24, Cameron; branch `feature/speech-coach-activities`)

The Speech Coach's screen now lists three cards: **Rhetoric Training** (opens the page, as before), **Practice your talking points** (1 h, 10,000円, +1 to the gaffe limit for the next stage, once a day) and **Work on your speech timing** (1 h, 20,000円, +1 turn for the next stage). The effects are the same one-stage bonuses the Tea and Wristwatch items give (`GAFFE_CAP`, `TURNS`), so they are handed to the next stage's setup.

Cameron gave a daily limit for the first only. The second is **once a day too**, so the bonus cannot be stacked without end; say if you want that changed. Workbook script: `tools/workbook/archive/speech_coach_activities_build.py` (VA16, VA17, three Text rows). Wording of the two result lines is a draft.

## Body text is Antaka Brush Text in Woodblock and Living Office (2026-11-24, Cameron; branch `feature/antaka-body-font`)

Woodblock's body face was Shippori Mincho B1 and Living Office's Zen Kaku Gothic New; both now use Antaka Brush Text, as the project did before the UI styles (P9). Headings stay Antaka Brush Display. Broadcast is unchanged (Barlow Condensed titles, Noto Sans JP body). Antaka Brush Text draws lowercase as small capitals, so body lines are wider; the text sweep checks every screen at every text size. `scripts/ui/UiStyleTheme.gd` names the fonts; `theme/cop_theme_woodblock.tres` and `cop_theme_living.tres` were rebuilt with `tools/build_theme.gd`. The `CLAUDE.md` fonts line is updated to match.

Follow-up on the same branch: with the body text in Antaka Brush Text, the Inventory and Details buttons on the battle screen came out about 10 px taller, which pushed End turn 10 px off the bottom of the 9:16 screen at the large text size (the text sweep and the aspect matrix click test both caught it). First fix tried: the opponent picture's minimum height 300 px instead of 320. **Reversed on Cameron's say-so (the character image has priority):** the picture is 320 px again, and the room is won from the two buttons instead. The battle's Inventory and Details buttons (metadata `compact`) are cancel buttons with 4 px of top and bottom padding instead of 8 (`Layout.COMPACT_CANCEL_VARIATION`), about 12 px shorter.

## P17: economy rebalance, the hourly standard (2026-11-24, Cameron; branch `feature/p17-economy`)

Cameron's economy review, built as briefed (`P17_ECONOMY_PROMPT.md`). One hour of play at standard difficulty now pays **8,000円 and 20 XP**; a room pays hours x that x a difficulty factor from its room type's starter-kit win rate in a fresh balance audit; a level adds a completion bonus by tier. The full report, with the bands, totals and every difference from the brief, is `design/bench/p17_economy_report.md`.

| Step | What changed |
|---|---|
| 1. Bands | Fresh starter-kit sweep (`tools/balance_audit.sh`), room types banded Easy 0.8, Standard 1.0, Hard 1.25, Very hard 1.5; bands saved in `design/bench/p17_bands.json`. |
| 2. Room pay | `tools/economy_apply.py` (rates as named constants, rerunnable, `--dry-run`): Win Funds and Win XP on 284 of 290 stages. A room that paid no Funds still pays none. |
| 3. Level bonus | Tier 0 none; tier 1 10% and tier 2 25% of the rooms' total (a level with no Funds bonus keeps none): 122 levels. |
| 4. Dues and wages | Balance: dues reward 15%, dues step 5,000円, staff wage 10%, new `Dues: Max Per Week` 90,000円. `PartyDues.week_dues` caps the dues, then the National-awareness relief comes off. Funds earned this week are counted before the Funds limit clamps them (`MetaRules` `requested`). The week-cost screen says when the limit holds the dues down. |
| 5. Prices | Commission Policy Research 12,000円, Press and District Engagement 24,000円; events EV03, EV05, EV06, EV31, EV35 cheaper; EV04's gains x4; the Paid Train Ticket gives +1 with the Commuter Committee only. |
| Campaign Pressure dues | Relaxed share 10% (was 5%), Standard 15%, Harder 20%: five either side of Standard (Cameron's call, 2026-11-24). |
| 6. Tests | `test_economy_p17.gd` (no Funds where there were none, the limit, Funds earned above the Funds limit, 10% wages); the briefing record's pay figures refreshed; tests that pinned the old wages, ticket standing, non-combat XP rate and bonus counts updated. |

## P18: the National Assembly Library's Codex and reference desk (2026-11-24, Cameron; branch `feature/p18-library-codex`)

Built as briefed (`SPEC.md` and `P18_LIBRARY_CODEX_PROMPT.md`). Cameron approved the schema first and chose: one hidden placeholder row per category, Nap and Read under the Reference desk tab below the desk, the kanji seal as drawn, and no XP for Room files.

| Step | What changed | Rows added | Tests added |
|---|---|---|---|
| 1. Codex | `read` is a built kind; Browse the Shelves opens the Codex tab. Categories, closed scrolls (NEW, Sealed), the reader with Previous, Roll up and Next, the first-read XP once, the four unlocks, "Added to the Codex" under a venue line. Scroll look is 14 colour and 13 other tokens per style in the UI Styles tab (`ScrollStyle`, `ScrollPaper`, `ScrollRoller`, `CodexViews`). | Library Documents tab (LD01 to LD03, hidden drafts); Rules `codex_first_read_xp`; UI Styles US130 to US213; 48 Text rows (`codex.*`, `desk.*`, `tips.source_library`) | `test_codex_rules.gd` (10), `test_codex_state.gd` (13) |
| 2. Reference desk | Kind `research`, VA18 (2 h, once a day). Room picker, the six-style reading with five-step meters, the tip box, the tip added through `RhetoricTips` (source `library`) and a Room file that lives as long as its tip. | Venue Activities VA18 | in the state tests above; the venue click test drives the desk, the Room file and the reader |
| 3. Saving | `codex_found` and `room_files` are saved; an old save has only its start and own-party documents and no Room files. | | state tests |
| 4. Checks | The exporter checks Library Documents (IDs, categories, unlocks, `line` documents named by a line and the reverse, `law` values, `own_party` parties) and warns on DRAFT rows. The text sweep draws the three screens. | | `tools/test_venue_exporter.py` (12 new) |

Differences from the spec: the desk's hours and daily limit live on the activity row (Hours 2, Per Day 1), so there are no `reference_desk_*` Rules rows; the Room file keeps its read mark when its room is researched again; the reader uses the Office's dimmed ground of each style rather than a separate picture. The three placeholder rows are in the tab so the structure is visible, and are hidden until their Note stops beginning with DRAFT.

## The place map's cards use a wide picture banner (2026-11-24, Cameron; branch `feature/place-card-banner`)

Each place on the Step out map now shows its picture as a wide banner across the top of the card (in the season it is now, so the Gardens follow the year), then its name, Japanese name and blurb, then Go. The 170 px thumbnail is gone. Cameron picked this from a mock-up of three ways to use a venue picture or the unused `VEN_*` icons (`design/review/venue_icons_2026-11-24/`) and chose the picture without a new icon; the Venues tab's Icon column and the nine `VEN_*.png` rows in the art checklist are therefore not needed by the map (left in place until Cameron says to remove them: candidates for `design/CLEANUP_CANDIDATES.md`).

## Area Characters: open-world people who speak in venues and stand over their backgrounds (2026-11-25, Cameron; branch `feature/area-characters`)

Cameron's design: a new tab for open-world characters, with a prefix on each ID. `VEN##` are specific venue characters (limited by a **Site** column, such as the speech coach), `CA##` appear in the Capital Area, `CB##` in the Capitol interior (Cameron's choice over `CP##`, which the Cosmetic Packages use) and `DI##` in the District. A venue pulls its zone's prefix unless a line names a VEN person; a line whose Speaker is `area` takes someone from the venue's pool.

| Step | What changed |
|---|---|
| Tab and checks | **Area Characters** tab (`area_characters.json`); the exporter checks the ID shape, that a VEN person has a Site, that every Site names real venues of the right zone, and that a line's speaker can appear at its venue. |
| Speech coach | `SPEECH_COACH` is now **VEN01** (picture `assets/characters/area/VEN01.png`, folder renamed from `capital_area`); his name, kanji and title are read from his row, so the Text rows `rhetoric.coach_name`, `coach_name_jp` and `coach_title` are no longer asked for (left in place). |
| Pictures | `art.json` maps `VEN`, `CA`, `CB` and `DI` to the area folder; the art checklist lists each person. |
| Overheard lines | A line an area person speaks puts the person full height over the venue's background with the card at the foot (`VenueSceneViews`); any other line keeps the plain card. The tag of a line at a place other than the Cafeteria or the Gardens is the place's name. |
| Tests | `test_area_characters.gd` (pool and Site rules, the seeded pick, the prefix folders, the coach as VEN01, speaker `area`, and the scene against the plain card for Cameron's six sample lines, used as fixtures: none is in the data); `tools/test_venue_exporter.py`; the text sweep draws the scene. |

Not built: lines for Capital Area and District places. Only the Cafeteria and the Gardens deal lines, so those venues need a line pool before their people can be overheard in the game itself.

## Overheard lines: a passing line every few moves, with the places and seasons in the workbook (2026-11-25, Cameron; branch `feature/overheard-lines`)

Cameron chose "every N moves" from three ways to make venues trigger lines, with N = 6, a wobble of 2 and a priority weight of 5, and asked that new venues and seasons need no code and that venue-specific lines beat general area lines.

| Step | What changed |
|---|---|
| Workbook | Venue Lines gets a **Where** column and the Pool value `overheard`; Venues gets **Overheard Every**; four Balance rows (`Overheard Every` 6, `Wobble` 2, `Specific Boost` 5, `No Repeat` 4); Cameron's six sample lines are rows (Capital Area, District and Capitol Building, speaker `area`). |
| Rules | `OverheardLines`: where a line fits (venue, zone or tracks), the pace and its seeded wobble, the weighted draw with the boost for a line that names the place, and the recent-line skip. The move counter, recent list and line count are saved; an old save starts at 0. |
| On screen | Go (and To the tracks) counts a move; on the N-th a line is overheard first (the stand-over scene for an area speaker, the plain card otherwise) with one Continue button, and the place opens after it. |
| Checks and tests | The exporter checks Where (places that exist, `/tracks` only on a station, no hint rows, speakers who can appear there) and Overheard Every; `test_overheard_lines.gd` (18) and 10 exporter cases. |

Your draft places map as: the Capitol and the Capital Area and District streets are zone names; Capitol Gardens, Library, the Shotengai and the Old Shrine are their venue IDs; Sapporo Odori Park is the Sapporo Stage (VN05); the station concourse is VN06 and the tracks `VN06/tracks`. The six sample lines are in the data; the Capital Area and District zone lines are heard at the stations, the shrine and the shotengai.

## Tester reports: the Marketplace's Back control, and "a bill comes up" for a level (2026-11-25; branch `feature/overheard-lines`)

| Report | Cause | Fix |
|---|---|---|
| "The back to office button is gone" (Android, Marketplace after a hosted event result) | A pop-up card wraps the buttons it borrows (its Back). When the Marketplace was drawn again on the same panel, the Back control kept the wrapping and shrank to one letter wide and many lines tall, so it could not be seen or tapped. | `dress_back` always sets one line (and marks it so nothing wraps it again); the card's `undress` turns wrapping off. `test_frame_back_button.gd` repeats the card-then-frame sequence. |
| "A bill opened after the district tour, but the level is District Tour" | The reveal sentence `item.hosted_reveal` said "a bill comes up"; what a gathering reveals is a level. | Now "Over the evening a new level comes up: {name}. It is now open to you." (Claude's draft wording for Cameron.) |

