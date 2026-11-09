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
