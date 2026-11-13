# How the Player Must Receive Information

*The standards for everything the game tells the player: wording, units, what must be shown before and after a choice, who may say what, and how it is laid out. Written 2026-11-06 by collecting the decisions Cameron made over the Sept–Nov 2026 builds (the detail is summarized in `design/CHANGELOG.md`). Where a standard is enforced by a test or the exporter, the check is named. For how the mechanics work see `design/GAME_SYSTEMS.md`; for how to write content see `design/CONTENT_GUIDE.md`.*

## The short version

| # | Standard |
|---|---|
| 1 | **Say what a choice costs and gives before it is made, and what it did after.** Nothing the player pays or earns may be a surprise. |
| 2 | **Refuse with a reason.** A button the player cannot press shows why on the button, never silence. |
| 3 | **One idea, one name.** Use the terms in section 2 everywhere; never show an internal ID, a romaji name or a code word. |
| 4 | **Every sentence is a row in the Text tab** (or a workbook cell), asked for by a literal key. No sentence in a script. |
| 5 | **No character ever talks about the game's machinery** ("this level", "next stage", "win", "turns", numbers of energy). |
| 6 | **Choices are honest.** Every option is a sincere position of similar length; none is the only thoughtful one; every cost promised is the cost charged. |
| 7 | **English first; Japanese only as a small muted accent beside English, never alone** (the six Japanese-only ticker lines are Cameron's deliberate exception). |
| 8 | **The hidden clock stays hidden.** The player sees hours, days and dates, never `time_units`. |
| 9 | **Portrait, safe areas, wrapping, and a text-size setting.** Nothing may run off the right edge or hide under a notch. |
| 10 | **All text is a draft for Cameron.** Claude never decides canon, names or political positions. |

## 1. What the player is told, and when

| Moment | Must show | Where it is built |
|---|---|---|
| **Before entering a level** | The level's hours (a total, and per stage), each stage's win rewards, **"If you lose: …"** costs, the totals in the fixed order Reputation, Constituency support, Party support, anything else, then XP and Funds; one-stage levels show only the totals; a stage whose "Reveal In Briefing" is No is not named. Gold rules separate stages. | `BriefingSummary.gd`, `OfficeScreen` briefing; `LevelRunner.loss_penalties()` |
| **Why a level cannot be started** | The reason on the button: too long for the hours left, week over, not a weekend level, cooling down, or the XP price | `GameState.level_calendar_refusal()`, `OfficeScreen._level_row()` |
| **Level Intro** | The level's **purpose** first (spoken by the role named in Purpose Speaker, else the first hired staff, else the player's own thought), then staff lines; for a bill level, the **bill card** (name, description, sponsor and party line, "For it / Against it" organization chips), a **Read the Bill** page (what it does, who gains, who pays, the case for, the case against, the main risk, a middle ground, where each party stands), and the stakes line: "Each stage you win: +2 with your side, −2 with the other. Your vote: +2 with your side. Changing your vote costs 5 standing." (numbers read from Balance) | `LevelPurpose.gd`, `BillDossier.gd`, `LevelIntroScreen` |
| **Before a card is played** | The card zoom gives the question's grade (strong, medium or weak) for the card's suit and how the room favors or resists that suit | card zoom |
| **Before the opponent moves** | The opponent's intent a turn ahead ("Attacking · −2 to −4", "Gaining", "Guarding"), including a press conference's reporters; the Details panel says who a question is about | `OpponentPresenter.show_state()` |
| **During a spoken line** | The cue banner, with a name tag and what the move did underneath. Press conference replies always show the move, since a reporter's line never says what it did. Lines queue; a tap skips; the banner never blocks the hand. | `CueBanner.gd` |
| **After a stage** | A result panel: what each number moved by and **why** (the cause is filed with the change), each organization's change as a small icon chip, a card's or answer's effect | `OutcomePresenter.gd`, `CauseLines` |
| **Before a vote** | What each choice would do (a preview), whether the influence swing is ready and what is still needed, the vote's requirement ("Majority Vote to Pass: 51 of 101 Aye votes needed. Abstentions count against a bill.") | `FloorVoteScreen` |
| **After a vote** | The tally as three tiles (Aye, Abstain, Nay) with a mark where the Aye votes needed end; two headed rows of chips, **"Your vote:"** and **"Because the bill passed / failed:"**; the bill goes into Legislative Work | `FloorVoteScreen._show_outcome_chips()` |
| **A law, later** | The pop-up for each bill in Legislative Work: PASSED or FAILED, requirement, tally, how you voted, whether your influence turned it, your vote's effects, then what the law did once and does at the end of each later level; a bill you carried says so and shows the organization's comment | `OfficeScreen._show_law()` |
| **A cost on the spot** | The cost is on the choice's button (hours, Funds, an item); when it cannot be paid the button is greyed out with the reason ("Insufficient Work Hours", "Not enough Funds", "Needs: …") | `Commitments.gd`, `GameState.commitment_label()` |
| **A promise** | What is owed and when, in the Promises panel; the pop-up when one breaks | `Promises.gd` |
| **Learning a card** | The card is shown, front and back, **before** anything is paid; Pass costs nothing | Rhetoric Training |
| **Hiring staff** | A full profile: picture, name, cost, role, biography, what each rank gives | Staff Profile |
| **The calendar** | Date (YY.MM.DD) with the weekday, hours left today and this week; the Office says when a week is over and offers the choice again from a button if the pop-up was missed | `WeekCalendar`, `OfficeScreen` |

**Rewards and penalties are shown together.** A player who leans on a bill must be able to see, at the start (the stakes line), at the vote (your vote versus the outcome) and afterwards (Legislative Work), every standing change that was caused and by what: a stage won, the vote, and the bill passing or failing. A change must never read as a penalty for the wrong cause (a failed bill's effect is labelled "Because the bill failed", not "Reactions to your vote").

**Hidden by design:** the clock (`time_units`); how Standing Links propagate; the number of turns a cooldown has left (the player is told "not available yet", never the count); a level's hidden stage names; levels that need discovery until they are found.

## 2. Terms: one idea, one name

| Say | Never say | Notes |
|---|---|---|
| **Constituency support** | Jiban | One of the four meta numbers (they are lookup keys: never rename in one place) |
| **Reputation** | Kanban, Chimeido | |
| **Funds**, an amount written **100,000円** (thousands commas) | Kaban, Yen, Donors | An amount of money carries 円; Funds is the category |
| **Party support** | | |
| **organization** (in sentences); **Boosters** only as the panel name; **Important Stakeholders** only as the standing screen's name | booster, stakeholder in sentences | Scope headings: Party Bodies, Constituency, National |
| **standing** (an organization's feeling toward you); **opinion** (a party's) | sentiment, mood, favourability | Staff bonuses for audience groups read "approval among …" |
| **backing** | modifier | Something an organization lets you buy |
| **Aye / Nay / Abstain** | Yes / No | In every player-facing vote text |
| **Legislative Work** | Statute book | The internal name stays in code |
| **threshold** (the win line) | the line, win mark, target | |
| **Support** (shared bar), **Seats** (a vote), **Tone** (a single bar), **Viewer Interest** (TV) | other bar names | |
| **level** (the whole chain), **stage** (one encounter in it); **room** is allowed for the place where a stage happens (Cameron, 2026-11-09) | module, battle (as a heading) | Characters never say level or stage; see section 3 |
| **Staff Rank** | staff tier | Card tier, level tier and column headers keep "Tier" |
| **gaffe** | slip, failure | |
| **Hours**, singular "1 Hour" | time units, ticks | |
| **Training Session** (Rhetoric Training) | gacha, card draw | |
| **Convince <member>** (fallback **Convince Your Colleague**) | Win Over a Member as a stage title | The fight with a visiting member |
| **Marketplace** (the panel's button), **Supplies** (its heading) | Shop | Deliberate |

**Spelling is American** everywhere (favor, neighbor, defense, organization, harbor). **Dates are YY.MM.DD** everywhere (calendar square, Events "On Date", ticker dates); `WeekCalendar.parse_date()` is the one parser. **Placeholders that hold money** are named `cost`, `price`, `count` or `yen_…` so they get commas. No stat, ID, key or file name may appear on screen (the raw-ID leak fixes of 2026-09-30 are the precedent); a missing picture shows a labelled placeholder only in development.

## 3. Who may say what

| Rule | Why | Enforced by |
|---|---|---|
| **Characters never mention levels, stages, turns, energy, winning, thresholds or numbers of the machinery.** Say "the vote", "the hearing", "this week". Ordinary English (a festival's stage, "at this stage" as a hedge) is fine. | Immersion; Cameron's rule 2026-11-04 | `tests/test_spoken_no_game_terms.gd` |
| **Opponents argue their own party's side of a bill**, never the opposite of the party's position; a leader also says the party's Floor Vote line. Someone on the player's own side challenges as a demanding ally ("If you back it, defend it properly"), never "I agree with you". | A leader contradicting their party breaks the political model | `MemberStance.gd`, `test_member_stance.gd` |
| **No opponent line repeats inside a level while unused lines remain** | 30 turns must not repeat | `OpponentCues.pick_unused()`, `tools/cue_coverage.py` |
| **No invented canon.** Character names, parties, committees, places and political positions come only from the data; real offices use their canon names (there is no "President of Yezo"; a party's head is its party leader; where a line meant a party official it names the party's Secretary-General; "the university president" for a university). Where a name is missing use a neutral placeholder. | Canon is Cameron's | the Canon review (`design/review/CANON_REVIEW_2026-11-04.md`) |
| **Each side argues its strongest honest case**, with no strawman; a bill's opposition speaks for a principled constituency, not only insiders who lose out | Intellectual honesty | the bill facets README (`design/reference/`) |
| **Scope decides what a line may assume**: a universal line names no venue, audience, party, post, date or past event; a stage line may name the room's business; an opponent line their party's line and their organization's interest; a bill line the bill's subject | A wide line appears everywhere | `design/CONTENT_GUIDE.md` section 7.1 |

**Length limits** (so a line fits the banner and a phone): universal cues about nine words; bill lines 20 words (`test_bill_player_cues.gd` and the component content test); a transition line about 18 words and its reply 8; a level intro cue about 12; a visitor's response 14; a Floor Vote party cue about 12. Spoken lines take no time words (now, today, again, still, already, always, never) unless the room is explicitly about time.

**Slot rules for generated text** (bill phrases; `design/reference/bill_facets.json` README): *gain* and *hurt* are plural people; *cost* only after "falls on" or "who pays"; *local* is a noun phrase; *alt* contains no "instead" (the frame adds it); no verb directly after *risk*.

## 4. Honest choices

| Standard | How it is checked |
|---|---|
| **No right answer in a dilemma.** Each of the four choices carries its own effects; each is worth 2 to 7 points counting minus signs as plus; any choice that gains more than 1 also costs something somewhere; at least one choice is free to take | `tests/test_office_hours_engine.gd` on every real question |
| **Sincere positions of similar length.** No choice is padded, sarcastic or the only thoughtful one | The choice audit (`tools/choice_audit.py`) |
| **A choice costs what it promises.** Hours, Funds or an item named on the button are what is taken; a choice promising something later creates a promise with a deadline | `Commitments.gd`, `Promises.gd`, `test_promises.gd` |
| **A promise says what keeping it looks like** and what breaking it costs (default −5 standing and −2 Reputation; kept +2 standing) | Promise terms on the choice row |
| **At least one choice per event or question costs nothing** | The exporter errors otherwise |
| **A Decline exists on Random events** and costs 1.5× the shortfall of sending staff | The rule in `design/CONTENT_GUIDE.md` section 9.1 |
| **An option that needs staff says so and greys out** when nobody is hired ("No staff hired") | `StaffDelegation.gd` |

## 5. Layout and presentation

| Standard | Detail |
|---|---|
| **Portrait, 1080 × 2340 base**, stretch `canvas_items`, aspect `expand`; every full-screen container is named "Safe" or "Margin" and keeps clear of the device's safe area (notch, rounded corners, home bar) | `Layout.gd`, `SafeArea.gd` |
| **Text wraps; nothing runs off the right edge.** A control that wraps text must have a real width: a zero width makes word-wrap stack one word per line. In a narrow column set the line's minimum width to 0 (`UiKit.line()` forces a full-column minimum) | |
| **Text size is the player's** (Small 90%, Normal, Large 120% of every font size), in Administration | `TextScale.gd`, Balance `text_scale_*` |
| **Touch first.** Buttons 90 px or taller (`UiKit.action_button` defaults to 90); scroll bars 36 px wide; every list drags with a finger and a drag that starts on a button scrolls instead of pressing it; a card dragged up out of the hand plays it, a short pull drops it back | `DragScroll.gd` |
| **Gold is the game's accent**: the cue band's edge, the title screen's button outlines, the briefing's stage rules, the hand's scroll bar. One constant: `CueBanner.EDGE_COLOUR`. The score bars (support, vote result, party votes) lean at the cue band's angle (`SlantBar.SLANT`, 0.18) with thin gold top and bottom edges | |
| **Characters are large**: full-height cutouts fill their half of a battle's art box; a visitor, member or lobbyist portrait is 420 × 760. A reply band is cleared when Continue is pressed so it never covers the next choices | |
| **Fonts**: cards use Antaka Brush Display; everything else Antaka Brush Text with Noto Sans JP as its fallback for Japanese and the symbols Antaka lacks (ō, −, ×, •, →). Antaka has one weight and small caps: size alone carries hierarchy | `tools/build_theme.gd` |
| **Japanese** appears only as a small muted accent beside English (stage headers, card names), never alone | |
| **Art falls back, never blocks**: a missing picture shows a labelled placeholder; a missing face uses the neutral one; the portrait of the player's outfit and the Office background follow the equipped cosmetic | `ArtLoader`, `PlaceholderArt` |
| **Money, long numbers and hours read naturally**: thousands commas, 円 on yen, "1 Hour"/"2 Hours" | `Phrase.meta_amount()` |
| **Saving is visible**: a brief "Saved" flash; one automatic slot and one manual backup | |

**One deliberate exception to "Japanese only beside English":** the Characters list (Administration) labels a person the player has not met yet with **誰ですか。** alone, Cameron's own wording (Text row `characters.unmet_name`).

## 6. Wording is data

- **Every sentence the game says is a row in the workbook's Text tab**, asked for by a literal key (`Text.say("a.b")`, never a built-up key). The exporter errors for a key the code asks for and the tab lacks, and notes a row nothing asks for. `design/EDITING_TEXT.md` is the guide to changing each kind of prose.
- **No design number lives in a script**: it is a Balance-tab row read with `DataDB.balance.get(...)` (or `Levers` from a rules file); `tests/test_balance_keys.gd` fails the build if a script asks for a key the workbook lacks.
- `effect_text` on a card is for the player to read; the game never parses it.
- Text edited on purpose is accepted with `python3 tools/export_data.py --accept-wording`, which refreshes `tests/wording_snapshot.json`.
