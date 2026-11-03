# Prompts for revising the custom-bill component system (2026-11-03)

Six self-contained prompts. Each can be pasted into a fresh session on its own. Run them in the order of section 1 if you want one coherent revision, or run any one alone. Prompt 0 is the shared briefing every other prompt assumes; paste it first, or let each session read this file.

| # | Prompt | Works on | Output | Needs Cameron's decisions first |
|---|---|---|---|---|
| 0 | Shared briefing | rules and facts | none | no |
| 1 | Bill Components audit and rewrite | `Bill Components` tab, 180 rows | corrected rows plus a change table | no (drafts) |
| 2 | Component-tagged content quality pass | Stage Questions, Player Cues, Opponent Cues, Transition Dialogue rows tagged with a Component ID | rewritten rows in batches | no (drafts) |
| 3 | Member visit and lobbyist trade content pass | Visit Questions, Trade Questions, Visit Answers | rewritten and added rows | the lobbyist-character question |
| 4 | Code revisions to the visit, trade and draft rules | `MpVisit`, `LobbyistTrade`, `PatronLevel`, `DraftBill`, Request and Draft panels | code, tests, plan first | yes, for items marked (D) |
| 5 | Balance and playtest validation | bots and audit tools | a before/after report | no |

## Prompt 0: shared briefing (paste first)

You are working on *Coliseum of Parliament*, a Godot 4 card-battler about Yezo's parliament. The designer, Cameron, is a legislature expert and not a programmer: explain every change in plain English, in short tables, with an executive summary first. Read `CLAUDE.md` before anything else.

Hard rules:
- Content is draft. Anything you write is for Cameron to rewrite. Never decide canon. Never invent a canon character (names of people, parties, committees); use neutral placeholders and flag them. Ministries and committees must use the canon names already in the data.
- All content lives in `design/Game_Workbook.xlsx`. Never save it with openpyxl. Edit it with `tools/workbook/wbx.py` (`WB`, `rows`, `set_cell(tab,row,col,val,style_from=row)`, `append_row`, `save`). After every workbook edit run `python3 tools/export_data.py`; it must say "No errors". Run it with `--accept-wording` only when Text-tab rows changed. Every sentence the game says is a Text-tab row.
- A change over about 150 lines of new code needs a plan first. Ask before changing a workbook schema, renaming an ID, or resolving anything marked open. Use a question popup for decisions that belong to Cameron.
- Every rules change needs a unit test (`tests/`). Run `tools/verify.sh` (about 2 minutes) and wait for "All checks passed" before merging to `main`. New `class_name` scripts need `.tools/godot --headless --path . --import`.
- Commit with a plain-English message ending with the two trailer lines the session gives you. Add a section to `design/CHANGELOG.md` and one line to the index at the end of `CLAUDE.md` (section 15).
- Do not delete anything without asking; list candidates in `design/CLEANUP_CANDIDATES.md`.

How custom bills work (verified 2026-11-02 and 2026-11-03):
- A custom bill is two or three **components** (parts) from `data/bill_components.json` (180 rows: slots X, Y, V, Z, W = 27 each; A = 18, B = 18, C = 7, D = 2). Patron bills (54: 27 Favor, 27 Flagship) use them in fixed sets; Draft a Bill lets the player pick any two or three. Code: `scripts/rules/ComposedBill.gd`, `scripts/DraftBill.gd`, `scripts/PatronLevel.gd`, `scripts/rules/PatronRequests.gd`.
- Each part has: phrase (verb phrase, "fund street lighting in residential blocks"), Value Tags (policy dimensions, for example `Federal Spending +0.6; Localism +0.6`), Gains and Loses (organizations and sizes), a hearing committee, Excludes. Tags feed party leans (`BillPositions.gd`, `Party Values` tab); Gains and Loses are summed, scaled to 50%, and become the law's standing changes and the "who it helps and hurts" lists.
- Levels come from four templates (`Bill Level Templates` tab): BT01 patron Favor, BT02 patron Flagship, BT03 drafted with two parts, BT04 drafted with three parts. Rooms: patron meeting (patron only), hearing for the first part's committee, member visit (always on three-part bills; 50% on two-part bills, column Visit Chance), public room, own party caucus, lobbyist trade (only when a lobbyist speaks for an organization the bill hurts and a part can be traded safely), floor vote.
- Content is tagged to a component with the Component ID column on Stage Questions (8 per component), Player Cues (6), Opponent Cues (6) and Transition Dialogue (3); up to 50% of a room's questions come from the bill's parts.
- The member visit uses `Visit Questions` (24 stems with a Reply Kind), `Visit Answers` (156 lines: 36 generic with a blank Reply Kind and 120 written per Reply Kind and style) and `MpVisit.gd`. The lobbyist trade uses `Trade Questions` (12 stems) and the same answers, plus `LobbyistTrade.gd`. Ten Reply Kinds: Principle, Voters, Cost, Risk, Party, Alternative, Trust, Evidence, Criticism, Deal. Six styles: Earnest, Emotional, Appeal, Data Driven, Divisive, Duplicitous.
- Passing a custom bill needs influence (`data/vote_influence_triggers.json`): Reputation 60, BO02 75 and BO03 70 for every party, plus party-specific standings, and Funds 500,000 to swing two parties. A bill cannot pass alone by design.

Tools you can run (all in `tools/`): `bill_audit.gd` (vote audit under the real gates, draft affordability, which rooms are built), `bill_draft_probe.gd` (a full draft lifecycle for 14 mixes), `visit_review.gd` (ten full transcripts; `VISIT_STATS=1` for 400-level statistics), `strategy_playtest.gd` with `strategy_runs.sh` and `strategy_report.py` (bot runs; strategies `drafter_easy`, `drafter_random`). Run a tool with `.tools/godot --headless --path . tools/NAME.tscn`.

Findings already on record (do not rediscover; build on them): `design/review/CUSTOM_BILL_AUDIT_2026-11-02.md`, `design/review/VISIT_CONTENT_REVIEW_2026-11-03.md`, samples in `design/bench/visit_review_samples_after_2026-11-03.md`.

## Prompt 1: audit and rewrite the 180 Bill Components

Task: audit every row of the `Bill Components` tab (data in `data/bill_components.json`) for quality and coherence, then correct the rows that fail. Work in the workbook, not in the JSON.

Known facts to start from:
- Hearing committees are lopsided: 72 components point to Government Administration (ST17), 37 to Finance (ST16), 31 to Construction (ST15), 13 Agriculture, 7 Environment, 6 National Assembly, 5 Foreign Affairs, 5 War, 4 Ethics. The bot wins ST17 55%, ST16 31%, ST15 42% of the time and ST13 and ST10 99%, so the first part decides how risky a draft is.
- On 2026-11-03 every part's Loses were rewritten from its strongest policy tag through a draft table of mine (`OPP` in the session scratch file `rivals.py`; reproduce the logic from the tags). The Chamber of Commerce is the loser on 24 parts and Taxpayers' Alliance on 23, Urban Neighborhood Alliance 21. A few results are implausible (Students United against "register master craftspeople as cultural assets"; Neighborhood Associations against "payment within sixty days on public contracts").
- Owner organizations without a bill part as a loser never send a lobbyist; ten organizations have a lobbyist character (BO03, BO04, BO05, BO06, BO07, BO09, BO10, BO11, BO12, BO15).

Do this, in order:
1. Export a table of all 180 parts: id, owner, slot, phrase, tags, gains, loses, hearing committee, excludes. Check every phrase starts with a lower-case verb, has no clock words, no "this bill", and reads after "a plan to ___" and after "fund/protect/..." alone.
2. Value Tags: check that each dimension name exists in the Party Values tab, that the sign and size match the phrase (a part that cuts taxes must have Taxation negative), and that no part has a tag that contradicts its own phrase. List contradictions.
3. Loses: for each part decide whether its listed loser is plausible. Rate Good, Fair or Poor with one sentence of reasoning. Rewrite Poor ones by choosing a more plausible organization from the 32 in `Boosters`, keeping the size. Prefer organizations that have a lobbyist character when two are equally plausible. Do not let any organization lose on more than 12% of parts. Never choose the part's owner or a party body unless the part is about party matters.
4. Gains: check each part gains its owner and, where natural, a second organization.
5. Hearing committee: for each part judge whether its committee is the natural home (a tax part belongs to Finance). Propose reassignments for parts that sit in Government Administration only by default, aiming to move at least 25 of the 72 to a better-fitting committee while keeping every committee used by at least 4 parts. Check each target committee has opponents seated (`data/opponents.json`, field `stages`).
6. Excludes: confirm symmetric, and add exclusions for pairs that contradict (a tax cut and a tax rise).
7. Mixed bills: pick 30 random drafts of three parts and read the generated bill names and descriptions aloud; list the ten most incoherent pairings and propose Excludes or soft warnings.

Deliverables: (a) a change table (id, field, old, new, reason); (b) the edited workbook rows via wbx; (c) a re-run of `python3 tools/export_data.py`, `tools/bill_audit.gd` and the unit tests; (d) a short list of decisions for Cameron (for example a part that needs a new organization).
Acceptance: export says "No errors"; `tools/verify.sh` passes; no organization loses on more than 12% of parts; every Poor loser is gone or listed with a reason.

## Prompt 2: quality pass on component-tagged content

Task: review and improve the content tagged to components. Rows to read: Stage Questions with a Component ID (1,440 rows, 8 per component), Player Cues (1,080, 6 per component), Opponent Cues (1,080, 6), Transition Dialogue (540, 3).

Rules the rows must follow (from `design/CONTENT_GUIDE.md`; read it): no time words, no assumed past events, questions graded S/M/W per suit with at least 2 S and at most 2 W per question, spread of Strong and Weak share per suit within about 15 points of the master spread, each Strong suit share between 20% and 60%, no Weak share of 0%, player cues at most 20 words, opponent cues sound different by style, written about the component alone (never "this bill", never another component).

Steps:
1. Sample 40 components across slots X, Y, V, Z, W, A, B, C, D. For each, read its eight questions, six player cues, six opponent cues and three transition lines next to its phrase, tags, gains and loses. Rate each row Good, Fair or Poor for: names the specific policy rather than a generic one; fits the component's tags and owner; grammatical; voice fits the speaker; no repetition of another component's wording (measure duplicate stems across all 1,440 questions and list the worst 30).
2. Check Reply Kind on the component questions (the bill-room replies use Reply Kind): report how many component questions have each kind and whether any component lacks Cost, Voters or Oversight-style coverage.
3. Check Stance: bill levels offer Support and Oppose; list which component cues have a Stance and which are neutral; flag cues that read wrongly under either lean.
4. Rewrite every Poor row and the 30 most duplicated stems. Keep row IDs and tags. Rewrite in batches of at most 60 rows per commit.
5. Re-run the content tests (`tests/test_component_content.gd`, `tests/test_bill_content.gd`, `tests/test_bill_player_cues.gd`) and the exporter.

Deliverables: a rating table by component slot, the rewritten rows, and counts before and after (duplicate stems, Poor rows). Acceptance: all content tests pass; no stem appears more than twice across components; the S/M/W spread rules hold per batch; nothing names a canon character.

## Prompt 3: member visit and lobbyist trade content

Task: improve the member visit and lobbyist trade writing. Tabs: `Visit Questions` (24), `Trade Questions` (12), `Visit Answers` (156). Read `design/review/VISIT_CONTENT_REVIEW_2026-11-03.md` first, then run `VISIT_STATS=1 .tools/godot --headless --path . tools/visit_review.tscn` and `.tools/godot --headless --path . tools/visit_review.tscn` to see the current behavior.

Known facts:
- Answers are kind-matched but still generic: nothing depends on the bill's subject, the speaker's party, or (for the trade) the speaker's organization. All four lobbyists from one organization say the same lines.
- A question's text uses the part's phrase; for three-part bills the questions take the parts in turn.
- Fit of the ten samples read on 2026-11-03: member visit Good 6, Fair 4; lobbyist trade Good 3, Fair 5, Poor 2.
- One lobbyist (Fumihiko Takashiro, Chamber of Commerce) is 34% of all trades because the Chamber has one representative and loses on the most parts.

Do this:
1. Member questions: for each of the 24 stems write a one-line note of what the member really wants to know. Rewrite any stem that is vague, repeats another, or only makes sense for a tax bill. Aim for 30 stems covering the ten Reply Kinds with at least two stems per kind. Keep every `{component}` slot after "to", "would", "we" or "you" (a test enforces this).
2. Trade questions: write 20 stems (up from 12) from the lobbyist's side in three registers: aggrieved, bargaining, resigned. Each uses "the plan to {component}".
3. Answers: for each Reply Kind and style there are two lines. Raise this to three, and write them so the Strong, Medium and Weak grades are not obvious from tone alone (a Weak line should still sound plausible). Add a short **reaction** line per grade for members and lobbyists in the Text tab only if the existing `visit.react_*` and `trade.react_*` rows feel repetitive; propose, do not add, new Text rows.
4. Organization flavor: propose (do not add) a small table of org-specific trade lines for the ten organizations that have a lobbyist (BO03, BO04, BO05, BO06, BO07, BO09, BO10, BO11, BO12, BO15): for each, one sentence of how that organization would phrase the Deal and Protect kinds. If this needs a new column, stop and ask.
5. Re-run the 10 samples and the 400-level statistics. Read all ten transcripts and rate fit again with the same Good/Fair/Poor scale.

Constraints: no new characters; lines at most 20 words; no clock words; the exporter requires at least two answers in every style for every Reply Kind a question uses.
Deliverables: edited rows, the new samples file in `design/bench/`, and an appended section in `design/review/VISIT_CONTENT_REVIEW_2026-11-03.md`. Acceptance: exporter clean, `tools/verify.sh` passes, the second read rates at least 8 of 10 member visits and 6 of 10 lobbyist trades Good.

## Prompt 4: code revisions (plan first; stop for approval)

Task: write a plan, then implement what Cameron approves, for these changes. Items marked (D) need Cameron's decision before coding; ask with a question popup.

| # | Change | Where | Why (evidence) |
|---|---|---|---|
| 4.1 | Show influence readiness on the Request and Draft panels: reuse `VoteInfluence.status()` to list "Still needed: BO02 62 of 75, Funds 100k of 500k" for the party the vote would need | `scripts/ui/OfficeScreen.gd` Request and Draft panels, `scripts/ui/RequestLines.gd`, Text tab | Readiness shows only at the vote, after 300,000円 is spent; bots drafting when allowed passed 4 of 78 |
| 4.2 | Say when the Funds cap blocks drafting ("raise the Funds cap to 300,000 first") | `DraftBill.refusal`, Text tab | The refusal reads "Drafting needs 350 XP and 300,000円" even at a 100,000 cap |
| 4.3 (D) | Refund a share of the draft cost when a draft lapses at the hearing | `GameState._conclude_patron_level`, Balance lever | 22% of random drafts lapse; the cost is never refunded |
| 4.4 (D) | Show the hearing committee and how hard it has been before the player commits | Draft panel | The first part picks the committee; Finance is won 31% of the time |
| 4.5 (D) | Replace `PatronLevel.carryable()` with a check that uses the real triggers and the player's current standings, or label the current check "best case" | `PatronLevel.carryable`, `DraftBill.refusal` | It opens every gate at once; real standing at 72 carried 0 of 54 patron bills |
| 4.6 (D) | Committee-match compromise for member visits: use committee members about half the time, otherwise the whole party | `MpVisit.pick_member`, a Balance lever | Variety rose from 16 to 82 members but the visited member sat on the hearing committee in 5 of 10 samples (was 10 of 10) |
| 4.7 | Weight `MpVisit.pick_party` by seats outside Yes rather than uniformly | `MpVisit.pick_party` | Small parties are visited as often as large ones |
| 4.8 | Lobbyist choice: weight the equally-hurt draw by how little that lobbyist has already spoken (`faced_people`) | `LobbyistTrade.pick_lobbyist` | One lobbyist is 34% of trades |
| 4.9 | `visit_wins` and drafting coverage in the bots: keep the counters honest | `tools/playtest_optimal.gd`, `tools/strategy_playtest.gd` | `visit_wins` was never filled before 2026-11-02 |
| 4.10 | Ask whether Draft a Bill should require a standing floor with at least one organization for its parts | `DraftBill.refusal` | Drafting is allowed with any part regardless of standing |

For each change the plan must give: the files and functions touched, the Balance levers and Text keys added, the unit tests (names and what they assert), the real-click tests affected (`tests/interaction/draft_test`, `requests_test`, `trade_test`, `visit_test`), the approximate line count, and any schema change. Do not start coding until the plan is approved. After approval implement one item per commit with tests, then run `tools/verify.sh`.
Acceptance: all existing tests pass; each new rule has a test; the audit tools (`bill_audit.gd`, `bill_draft_probe.gd`) are re-run and their output is pasted into the report; Cameron can read every new player-facing sentence in the Text tab.

## Prompt 5: balance and playtest validation

Task: measure whether custom bills work as a game system after prompts 1 to 4, and report. Do not change rules in this prompt; report only.

1. Run `tools/strategy_runs.sh design/bench/custom_bill_validation.jsonl "1 2 3 4 5 6" PC02 cap_dues drafter_easy drafter_random` and also with `PLAYTEST_DIFFICULTY=relaxed` and `=harder`. Report per strategy: drafts started, passed, lost the vote, lapsed at the hearing, Funds at the end, Party support, Election Strength, laws passed.
2. Run `.tools/godot --headless --path . tools/bill_audit.tscn` and paste the vote audit (which standings carry all 54 patron bills and random drafts) and the "negotiation rooms actually built" table.
3. Run `.tools/godot --headless --path . tools/bill_draft_probe.tscn` three times; report the pass, fail and lapse counts and the standing moves of a passed draft.
4. Compute the economy of one passed draft: cost (350 XP and 300,000円, or the current lever values), the standing it gains and loses summed over organizations, the Party support change, and how many weeks of the bot's income the cost equals. State whether drafting pays for itself in Election Strength, Party support or Funds.
5. Compare with the baselines on record: before the fixes, bots drafting when allowed passed 4 of 78; a fully prepared player passed 8 or 9 of 14 with the rest lapsing at the hearing.

Report format: an executive summary table, then the evidence tables, then three to five findings ranked by severity, then decisions for Cameron. Say plainly where a number comes from a bot that is not a human; a bot accepts every request and never checks readiness.
Acceptance: every number in the report can be reproduced by a command you list; no claim is made without a measurement.
