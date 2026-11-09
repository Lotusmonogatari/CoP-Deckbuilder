# Writing review: directive for the reviewing agents (2026-11-09)

Draft by Claude for Cameron. This is the brief handed to each agent. One lead agent coordinates, six reviewers each take a family of content, and one applier makes the changes. Nobody changes the workbook until Cameron has approved the ledger.

---

## 1. The goal

Make every line the player reads:

1. **Well written:** plain, specific and grammatical, in the voice of whoever says it.
2. **Cohesive:** consistent with the game's fixed terms, tone and canon, and with the lines around it.
3. **True in context:** a line must be true **every time** it can appear, **wherever** it can appear, and **whoever** has the conditions it assumes.
4. **American English:** American spelling, punctuation, style **and terminology**, as `design/INFORMATION_STANDARDS.md` section 6 sets out. Japanese terms and Japanese English are welcome (section 3b).

Point 3 matters most. Most of the game's text is drawn from pools and repeats. A line that is fine the first time it is read can be false the fifth time, or in the wrong room.

## 2. Read these first (every agent)

| File | Why |
|---|---|
| `CLAUDE.md` sections 4, 6, 10 and 12 | Canon, the data rules, the information standards and the working rules |
| `design/INFORMATION_STANDARDS.md` | The fixed terms, "no character mentions the machinery", honest choices, spelling and dates |
| `design/CONTENT_GUIDE.md` | How each kind of content is written and where it appears |
| `design/EDITING_TEXT.md` | How Text-tab rows are edited and checked |
| `design/GAME_SYSTEMS.md` sections 2, 7 and 8 | When rooms, levels, transitions and votes happen, so you know a line's context |
| `tools/content_lint.py` | The existing mechanical checks (reuse its file list and field names) |

## 3. The defects to find

Each finding gets one of these codes.

| Code | Defect | Example of the problem | Example of a fix |
|---|---|---|---|
| **C1** | **Once-only claim in repeatable content.** A line says something can only be true once, but its pool, room or level can be met again. | "Welcome to your first committee hearing." in a hearing that recurs. "Finally, the day has come." in a repeatable level's intro. | "Another hearing, and the same faces." Or drop the claim. |
| **C2** | **Unanchored reference.** "This", "that", "it", "they", "the bill", "your promise" or "as I said" points at something the player was never told *in this room*. Common in generic rooms (ST01-ST23) that are not tied to any bill. | "This will ruin the fishing towns." spoken in a generic press conference. | Name the thing ("Cutting the harbor fund will...") or make the line general. |
| **C3** | **Assumed history.** The line assumes an earlier outcome, choice or meeting that may not have happened. | "After your win last week..." "You let us down on the vote." in a pool any player can meet. | Reword so it is true whatever happened, or move it to a pool that has that condition. |
| **C4** | **Wrong speaker or listener.** The line does not fit who says it or who hears it: a staff line said with no staff, an opponent cheering the player, a party member contradicting their party's position, a reply that answers a different question. | A Heritage Party member praising a bill their party opposes. | Match the line to the speaker's party, role and the position in the data. |
| **C5** | **Machinery in speech.** A character mentions levels, stages, turns, energy, cards, points or numbers. (`test_spoken_no_game_terms.gd` catches some of this.) | "That cost you 5 Reputation." spoken by a reporter. | Say it in the world: "That will be in every paper tomorrow." |
| **C6** | **Off-term.** A fixed term is replaced by a synonym, or an internal word shows on screen. | "booster", "jiban", "standing points", "yen" written out instead of 円, "Yes vote" instead of Aye. | Use the fixed term from `INFORMATION_STANDARDS.md`. |
| **C7** | **Not American English.** British spelling **or British terminology**: words and phrases an American would not use for the same thing (section 3a). Japanese terms and Japanese English are welcome (section 3b). | colour, centre, organise; a constituency "surgery"; "queue", "car park", "in hospital". | color, center, organize; "office hours"; "line", "parking lot", "in the hospital". |
| **C8** | **Grammar and style.** Agreement, tense, dangling phrases, run-ons, doubled words, stray spaces, inconsistent punctuation. Use the serial comma, "A, B, and C", which the game already uses. Dates are YY.MM.DD and thousands take commas. | "The committee are divided" for a single body; "Your performance and conduct is". | "The committee is divided"; "are". |
| **C9** | **Dishonest or lopsided choice.** Among the options of one question or event, one is clearly the only thoughtful answer, the lengths differ a lot, or the text promises a cost or reward that the structured columns do not give. | A 4-word "No." beside three full sentences. | Even out the options; when text and a column disagree, change the text, never the column. |
| **C10** | **Repetition in a pool.** Two lines in the same pool say the same thing in nearly the same words, so the player hears an echo. | Five opponent lines that all open with "Let me be clear". | Vary them, keeping each one's meaning. |
| **C11** | **Tone break.** The register does not fit the room, a press conference sounding like a town hall, a constituent sounding like a minister, or the line is flippant about something serious. | A grieving visitor answered with a joke. | Match the room and the person. |
| **C12** | **Broken placeholder.** A `{name}` placeholder is missing, misspelled, or left in a sentence that no longer reads well once filled. | "{org} have been told" reading "Fisheries Cooperative have been told". | "{org} has been told". |

### 3a. American terminology (C7)

American English means American words as well as American spelling. Judge by what an American political staffer or reporter would say. Examples found in the current text, and others to sweep for:

| British | American | Seen in the data |
|---|---|---|
| (constituency) surgery | office hours, constituent meetings | Office Hours is already the canon name; "surgery" in a medical sense is fine |
| queue, queued, queuing | line, wait in line | about 10 questions and visitor lines |
| car park | parking lot | 5 room questions |
| timetable | schedule | 7 visitor lines (a train or bus "timetable" may stay where Japan's railways use it; prefer "schedule") |
| rota | schedule, roster | 4 visitor reactions |
| shopfront | storefront | 2 visitor lines |
| full stop (as emphasis) | period | 2 opponent lines |
| pavement | sidewalk | 1 room question |
| bin, rubbish | trash can, garbage, trash | event text |
| in hospital | in the hospital | 1 event result |
| at the weekend | on the weekend | Text tab |
| Monday to Friday | Monday through Friday | |
| fortnight | two weeks | |
| petrol, lorry, motorway | gas, truck, highway or expressway | |
| flat, council estate | apartment, public housing | |
| high street | main street, downtown, shopping street | |
| mobile phone | cell phone | |
| ring someone | call someone | |
| stand for election | run for office | |
| table a motion | introduce or submit a motion (in American usage, "table" means to **shelve** it, the opposite) | check every "table" used about a motion or bill |
| "The committee are", "the party have" | "The committee is", "the party has" | collective nouns take the singular |

### 3b. Japanese terms and Japanese English are acceptable

Yezo is a Japanese setting, so these are **not** C7 defects:

- **Japanese terms** the data already uses or that fit the scene: kōenkai, chōnaikai, matsuri, onsen, ryokan, izakaya, bento, sake, kotatsu, omiyage, shrine and temple vocabulary, honorifics such as -san or -sensei when a character would use them. Keep macrons (ō, ū) where the data has them; on screen the Japanese fallback font draws them.
- **Japanese English** (wasei-eigo and Japanese usage carried into English), where it gives local color: salaryman, office lady, "my number" card, konbini, "morning service", "baby car" for a stroller, "paper driver". Use it in characters' speech, not in interface text.
- **Canon and parliamentary names** in the data stay as they are, even where an American would say something else: Parliament, Members of Parliament, constituency, prefecture, party post titles, "Constituency support".

When a word is both British and Japanese English (for example "mansion" for an apartment block), keep it only in a Japanese character's speech and only where the meaning is clear.

**Not a defect:** canon names, places and party positions in the data, even if they look odd. Leave them alone and list anything that looks wrong under "Questions for Cameron".

## 4. Know each line's context before judging it

For each row, record four facts before deciding anything. Most C1-C4 findings come from these.

| Fact | Where to find it |
|---|---|
| **Can it repeat?** | A pool line (cues, room questions, ticker, notices) repeats. A level's intro repeats unless the level is One-Time. An event repeats unless it is one-off. A one-time level or a dated event does not. |
| **Where can it appear?** | A generic room (stage ID ST01-ST23) is used by many levels and has **no bill attached**. Any room copied for a bill (ST101 and up), and the bill's own rows, does have one. |
| **Who says it, to whom?** | The speaker column, the opponent's party and role, the visitor's role, or the staff role (staff lines fall back to narration when no one is hired). |
| **What has the player been told so far?** | The level purpose, the bill card, the question just asked, and the previous line in the same exchange. |

## 5. Who reviews what

| Reviewer | Content (`data/` file, and the workbook tab it comes from) | Words | How to review |
|---|---|---|---|
| **R1 Interface** | `strings` (Text tab), `how_to_play`, `office_notices`, `office_ticker`, `shop`, `modifiers`, `cards` (names and effect text), `staff` biographies | about 20,000 | Read everything. Fixed terms and C6 matter most here. |
| **R2 Opponents** | `opponent_cues`, `opponents` | about 186,000 | Too large to read line by line. Use templates and sampling (section 6). |
| **R3 The player** | `player_cues`, `card_cues`, `level_intro_thoughts` | about 240,000 | Templates and sampling (section 6). C1 and C3 are common in the player's own thoughts. |
| **R4 Questions and visits** | `questions` (room pools and Stage Questions), `visitor_questions`, `visit_questions`, `visit_answers`, `trade_questions`, `lobbyist_lines`, `reaction_lines` | about 95,000 | Read every question with its answers together. C2 in generic rooms, C9 across options. |
| **R5 Scenes** | `transition_dialogue`, `level_intros`, `levels` (purpose lines), `vote_influence_cues` | about 47,000 | Read one stage's transition lines together. Check speaker, party and repeatability. |
| **R6 Events and bills** | `events`, `event_choices`, `event_options`, `hosted_events`, `floor_votes`, `bill_components`, `patron_bills`, `law_effects` | about 25,000 | Read every event with its options. Make sure what the text promises matches the structured columns. |

## 6. Large pools (R2 and R3): fix the source, then sample

Many cue lines were generated from frames by scripts in `tools/workbook/archive/` (for example `b8/bill_content.py` and the component and opponent-line batches). A defect in a frame repeats in hundreds of rows.

1. **Cluster.** Group lines by their first four words and by their shape once names are masked. Report the 50 largest clusters.
2. **Find the frame.** For each cluster, find the generator script and frame that wrote it. Propose the fix to the frame, plus the row-level rewrites it implies, as one finding.
3. **Sample the rest.** Read at least 300 lines from each file at random, spread across rooms, parties and opponents. Report the defect rate per code with a 95% confidence range.
4. **Sweep.** For any defect that can be described by a pattern (once-only words, unanchored "this" at the start of a line, off-terms, British spelling), sweep the whole file and list every hit.

## 7. Automated sweeps (the lead runs these first and shares the results)

Extend `tools/content_lint.py` with these checks, read-only, one line per hit, `file | id | field | code | text`:

| Check | Pattern (case-insensitive) | Scope |
|---|---|---|
| C1 once-only | `first time`, `for the first`, `finally`, `at last`, `never before`, `history is made`, `today we make`, `welcome to (your\|the) first`, `my first`, `your first`, `once and for all` | Rows that can repeat (section 4) |
| C2 unanchored | A line that **starts** with `This`, `That`, `It`, `They`, `These`, `Those`; or contains `the bill`, `this bill`, `this law`, `your promise`, `as I said`, `like I said`, `as we discussed` | Generic rooms (ST01-ST23) and their pools |
| C3 history | `last week`, `last time`, `again`, `once more`, `you lost`, `your win`, `after you`, `you promised`, `you voted` | Rows with no condition behind them |
| C6 off-term | `booster`, `jiban`, `sanban`, `yen`, `points`, `turn`, `energy`, `stage`, `level`, `Yes vote`, `No vote`, `standing points` | Spoken and on-screen text |
| C7 spelling and terms | The British spelling list, plus `whilst`, `amongst`, `learnt`, `spelt`, `programme`, `cheque`, `tyre`, `kerb`, `grey`, `travelled`, `cancelled`, `-ise`/`-isation` endings; and the British terms in section 3a (`surgery` about constituents, `queue`, `car park`, `timetable`, `rota`, `shopfront`, `full stop`, `pavement`, `bin`, `rubbish`, `in hospital`, `at the weekend`, `fortnight`, `petrol`, `lorry`, `motorway`, `flat`, `high street`, `mobile phone`, `stand for`, `table` with motion or bill; collective nouns with `are` or `have`) | All English text. Ignore code keys such as `cancelled_line`. Skip Japanese terms and Japanese English (section 3b). |
| C10 echo | Two rows in the same pool whose word overlap is 80% or more | Every pool |
| C12 placeholders | A `{...}` in the text that the row's Placeholders cell does not list, or the reverse | Text tab |

Every hit is only a candidate. A reviewer confirms it in context (section 4) before it becomes a finding.

## 8. What each reviewer delivers

One CSV file per reviewer, `design/review/WRITING_REVIEW_<R#>_2026-11-xx.csv`, with these columns:

`file, id, field, code, can_repeat (Y/N), room_kind (generic/bill/none), speaker, original, proposed, reason (one short sentence), confidence (high/medium/low), source (row or frame:<script>)`

Plus a short summary, `design/review/WRITING_REVIEW_<R#>_SUMMARY.md`, containing:

- counts by code, the defect rate per file from sampling, and the ten worst findings;
- the frames to fix (R2 and R3);
- **Questions for Cameron:** anything touching canon, a party's position, or a choice's balance.

## 9. Rules for rewriting

- **Keep the meaning.** Same stance, the same party position, the same promise and cost. Never invent canon: names, places, parties, titles and policy positions come only from the data. Real Aomori and Hokkaido place names are allowed only where Cameron has already approved them.
- **Keep the length.** Stay within about 20% of the original, so the cue banner and buttons still fit. Choices in one question stay close to each other in length.
- **Keep the plumbing.** Never change an ID, a key, a structured column, or a `{placeholder}` name. Never delete a row: propose it under "Questions for Cameron" instead.
- **Speak in the world.** No machinery words in spoken lines (C5). On-screen interface text uses the fixed terms.
- **English only.** Japanese accents and romaji are out of scope. If an English change makes a Japanese accent wrong, flag it.
- **Mark it as a draft.** Every rewrite is a draft for Cameron.
- **When unsure, ask.** Mark the finding low confidence and put it under "Questions for Cameron" rather than guess.

## 10. Order of work

| Step | Who | Output | Gate |
|---|---|---|---|
| 1 | Lead | Extended `content_lint.py`; candidate lists per reviewer; context table (section 4) for every pool and room | None |
| 2 | R1-R6, in parallel | CSV ledgers and summaries | Each ledger has a summary, and every high-confidence row has a reason |
| 3 | Lead | One merged ledger with duplicates removed and frame fixes grouped; a 1-page report for Cameron with 20 before-and-after examples and the questions | Cameron reviews |
| 4 | Cameron | Approves, edits or refuses per code, per file, or per row | **No changes are applied before this** |
| 5 | Applier | One script, `tools/workbook/archive/b15/writing_review.py`, using `wbx.py` only; re-run any frame generators; `python3 tools/export_data.py --accept-wording` | "No errors" |
| 6 | Applier | `tools/verify.sh`; a `## Writing review` section in `CHANGELOG.md`; the index line in `CLAUDE.md`; push to the working branch | "All checks passed"; merge only when Cameron says "merge" |

## 11. Done means

- Every C1-C4 hit from the sweeps is either fixed or marked as true in context, with a reason.
- Sampling shows fewer than 1 in 100 C1-C4 defects remaining in the large pools.
- No British spellings or British terms in English text (Japanese terms and Japanese English excepted). No off-terms on screen.
- `tools/content_lint.py` keeps the new checks, so later content is caught as it is written.
