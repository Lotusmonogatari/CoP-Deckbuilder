# Writing review R2: opponent lines (2026-11-09)

Draft by Claude (reviewer R2) for Cameron. Scope: `data/opponent_cues.json` (3,863 rows, 16,739 lines) and `data/opponents.json` (131 people). The ledger is `design/review/WRITING_REVIEW_R2_2026-11-09.csv` (2,613 rows). Nothing in the workbook, `data/`, scripts or tests was changed.

## Executive summary

| | |
|---|---|
| Lines reviewed | 16,739 lines: 5,859 bill-part (component) lines, 5,340 personal lines (one opponent), 5,156 bill lines, 180 shared-pool lines, 120 room-pool lines (ST24-ST31), 84 demanding-ally lines |
| How | Clustered by masked shape and first four words; traced each large cluster to its generator; read a random sample of 320 lines; swept the whole file for every pattern-shaped defect |
| Findings | 2,613 ledger rows: **C4 1,454, C8 1,094, C3 40, C1 15, C5 6, C2 3, C10 1** (representative). 675 high, 1,919 medium, 19 low confidence |
| Sampled C1-C4 rate | **12.2%** of lines (95%: 9.0-16.2%), well above the 1-in-100 target; almost all of it comes from two frame families, so fixing frames fixes it |
| Clean | No British spellings or terms (C7), no off-terms (C6), no broken placeholders (C12), no machinery talk except one line (C5), and no near-duplicate lines inside any one pool (C10) |

The three problems that matter most:

1. **Opponents cheer the player on their own Gain move** (C4, 708 rows). Many "gain" lines are reactions of approval ("Bless that answer!", "That is an honest case. Thank you.", "Someone who truly cares, at last!") while the banner shows the opponent winning support. They come from the gain banks in `oc_styles.py` and the role lines in `b5/oc.py`, and from the shared pools OC02, OC05, OC08, OC35 and the room pools OC45-OC46, OC51-OC52, OC57-OC58.
2. **Bill-part (component) lines tagged Neutral talk to the player as the part's backer** (C4, 744 rows). "Why should we {p}? Tell me honestly." can be said by a supporter to a player who opposes the part, or by an ally. The Content Guide's rule is that such a line is an Against line.
3. **Slot misfits in generated frames** (C8, about 1,100 rows): organization names without "the" ("Urban Neighborhood Alliance fears..."), party-concern and topic phrases that do not fit the frame ("The vulnerable win over theirs.", "The budget deserves this kindness!", "No cost estimate for ordinary people."), list phrases without the serial comma, and "This is not paperwork. It is people, and you want to fund respite care...".

## Counts by code

| Code | Rows | Main source |
|---|---|---|
| C4 Wrong speaker or listener | 1,454 | 744 component Neutral lines that assume the player backs the part; 708 gain lines praising the player (19 shared pool, 23 room pool, 666 personal lines); 1 room line ("Your fares..."); 1 representative student line |
| C8 Grammar and style | 1,094 | 371 missing "the" before an organization; 222 serial commas; 183 topic or party-concern slot misfits; 152 "This is not paperwork..."; about 160 bill-frame fixes; 3 "Answer it" for a plural |
| C3 Assumed history | 40 | "Funny how your tune on {b} changes." (36); "That is not what you said in private." (4) |
| C1 Once-only claim | 15 | "Someone who truly cares, at last!" (11); "Finally, ..." (4). OC3177 ("finally hopeful") is filed as C8 |
| C5 Machinery in speech | 6 | "The threshold is not met." |
| C2 Unanchored reference | 3 | Room pools ST24-ST31: "your fare projection", "the fare review", "your label policy" |
| C10 Repetition | 1 (representative of 289) | The critic clause opens up to 8 lines per bill |
| C6, C7, C9, C11, C12 | 0 | Swept, nothing found (C9 does not apply to cues) |

A row can carry two codes; where two fixes touch one line, every ledger row for that line carries the combined rewrite.

## Sampling (320 lines, random, seed 20261109)

Stratified by row kind and spread over 120 opponents, 36 bills, 95 bill parts and every suit and verb. Lines that can never be spoken (below) were not counted as defects.

| Stratum (population) | Sample | C1 | C3 | C4 | C8 | Any C1-C4 |
|---|---|---|---|---|---|---|
| Personal lines (5,340) | 105 | 0 | 0 | 17 (16.2%, 10.4-24.4%) | 7 (6.7%, 3.3-13.1%) | 16.2% |
| Bill-part lines (5,859) | 95 | 0 | 0 | 16 (16.8%, 10.6-25.6%) | 7 (7.4%, 3.6-14.4%) | 16.8% |
| Bill lines (5,156) | 100 | 0 | 2 (2.0%, 0.6-7.0%) | 0 | 6 (6.0%, 2.8-12.5%) | 2.0% |
| Shared, room and ally pools (384) | 20 | 1 | 0 | 4 (20%, 8.1-41.6%) | 0 | 20% |
| **All, raw** | **320** | 1 (0.3%, 0.1-1.7%) | 2 (0.6%, 0.2-2.2%) | 37 (11.6%, 8.5-15.5%) | 20 (6.2%, 4.1-9.5%) | **39 (12.2%, 9.0-16.2%)** |
| All, weighted to the population | | 0.1% | 0.6% | 11.5% ± 3.5 | 6.6% ± 2.8 | 12.1% ± 3.6 |

C2, C5, C6, C7, C10, C11, C12: 0 of 320 (95% upper bound 1.2%). Every sampled defect is covered by a ledger row except one low-value case left as is ("I will not hand the other camp letting each town decide for itself.", a gerund in the {alt} slot). After the frame fixes, the remaining C1-C4 rate in the sample is 0 of 320 (upper bound 1.2%).

## The ten worst findings

| # | Code | Rows | Example now | Proposed |
|---|---|---|---|---|
| 1 | C4 | 708 | "Bless that answer!" (Prime Minister, gain) | "Bless everyone standing with me!" |
| 2 | C4 | 744 | "Why should we make school lunches free? Tell me honestly." (Neutral) | "Should we make school lunches free? This room deserves an honest answer." (or retag Against: Question 2) |
| 3 | C8 | 371 | "Urban Neighborhood Alliance fears what happens if we subsidize farm machinery!" | "The Urban Neighborhood Alliance fears..." |
| 4 | C8 | 12 | "The vulnerable win over theirs." | "Our side speaks for the vulnerable. Theirs does not." |
| 5 | C8 | 152 | "This is not paperwork. It is people, and you want to fund respite care for family caregivers!" | "Real people will live with this, and you want to fund respite care for family caregivers?" |
| 6 | C1/C4 | 11 | "Someone who truly cares, at last!" | "I truly care, and people can see it!" |
| 7 | C3 | 36 | "Funny how your tune on the Carbon Levy Act changes." | "Funny how your tune on the Carbon Levy Act depends on who is listening." |
| 8 | C8 | 36 | "I will not pretend that it buys power that costs more." (For side; reads as a concession) | "Critics say it buys power that costs more. I do not accept it." |
| 9 | C8 | 2 | "Think of employers short of workers tonight, finally hopeful! That is the Specified Skilled Worker Visa Act!" | "Think of employers short of workers, hopeful for once! The Specified Skilled Worker Visa Act is for them!" |
| 10 | C5 | 6 | "The threshold is not met." | "The evidence falls short. My answer is no." |

## Frames to fix

Fix the frame, then re-run or hand-apply the row rewrites in the ledger (each ledger row names its frame in `source`). The live text of several families was edited in the workbook after the scripts ran (commit `903d91d`, 2026-10-25), so the archived scripts are the origin, not an exact copy; the ledger rewrites are made against today's text.

| Frame (script) | Defect | Rows | Fix |
|---|---|---|---|
| `b7/oc_styles.py` STYLE[*]["gain"] generic, topic and party lists; role lines in `b5/oc.py` / `b6/content2.py` | C4: approval of the player on a gain move | 666 personal + 42 pool rows | Rewrite gain lines as the speaker rallying support ("Friends of {care} will back me.", "My plan helps the next harvest."). A full old-to-new table is in the ledger; 177 distinct lines |
| `b11/component_frames.py` OPPONENT Earnest and Data Driven (5 frames, Neutral) | C4: assumes the player backs the part | 744 | Stance-free wording (ledger), or tag the five frames Against |
| `b11/component_frames.py` and `b7/opponent_line_expansion.py` PART, slots {owner}/{rival} | C8: no article | 371 | Fill the slot with "the" for organizations that take one (all but Our Traditional Society, Students United, Members of Parliament, Constituency Voters, Agricultural Cooperatives, Neighborhood Associations, National Media, Party Activists) |
| component Emotional "This is not paperwork. It is people, and you want to {p}!" | C8: illogical for parts that help people | 152 | "Real people will live with this, and you want to {p}?" |
| `b7/oc_styles.py` TOPIC and CARE slots | C8: abstract nouns in people frames | 183 | 15 frames rewritten (win over theirs, against theirs, no cost estimate for, evidence for, measured against, deserves this kindness, brings hope to, my heart is with, shield ... with my heart, what does {topic} cost, {topic} metrics, glad of this, I weep for, served by a straight answer). Longer term: split CARE into a people phrase and a cause phrase |
| `design/reference/bill_facets.json` list phrases (16) and component phrases | C8: no serial comma | 222 | Add the serial comma in the facet phrases, then re-fill |
| `b8/bill_frames.py` OPPONENT | C8/C3 | 168 + 36 | "Let us keep {risk} between us" → "A quiet word on {risk}, between us."; "Some in this room live with {b}" → "would live with {b} every day"; "Yes: the trend for {gain} is clear" → "The trend for {gain} backs my view."; For "I will not pretend that {critic}" → "Critics say {critic}. I do not accept it."; {cost} in people slots → {hurt}; "Funny how your tune on {b} changes" → "...depends on who is listening." |
| `b7/opponent_line_expansion.py` BILL | C8 | 13 | "This room should feel what {local} means" → "what is at stake for {local}"; "Think of {gain} tonight, finally hopeful! That is the {bill}!" and the {hurt} twin |
| `b8/bill_frames.py` "Critics say {critic}." family | C10 | 289 lines, 1 representative row | Vary the openers so the critic clause is heard at most twice per bill |

## The 50 largest clusters (masked shape)

`{p}` is a bill part's phrase, `{owner}`/`{rival}` an organization, other braces are bill facets. All 50 come from the bill-part and bill frames; every one maps to `b11/component_frames.py` (live text edited since), `b7/opponent_line_expansion.py` PART, or `b8/bill_frames.py`.

| # | Lines | Shape | # | Lines | Shape |
|---|---|---|---|---|---|
| 1 | 180 | People have begged us to {p}! How can you say no? | 26 | 144 | A fairer plan would not {p} like this. |
| 2 | 175 | Friends, to {p} is a fair step. Why stand against it? | 27 | 144 | Where is the study that says we should {p}? |
| 3 | 155 | Not everyone agrees we should {p}. | 28 | 144 | Backers of a plan to {p} owe the rest of us an answer. |
| 4 | 155 | Show me the figures on a plan to {p}. | 29 | 144 | Nothing is settled on a plan to {p}, naturally. |
| 5 | 155 | Some say we should {p}. I would not like to comment. | 30 | 93 | The other side wants us to {p}. We should say no. |
| 6 | 153 | Be straight with us: is it fair to {p}? **(C4)** | 31 | 68 | Does {owner} speak for everyone when it asks us to {p}? **(C8 article)** |
| 7 | 153 | Do not ask families to carry the cost if we {p}! | 32 | 65 | {owner} wants us to {p}. Who speaks for everyone else? **(C8 article)** |
| 8 | 153 | You would ask us to {p}? Think of who it would hurt! | 33 | 60 | Does the {owner} speak for everyone when it asks us to {p}? |
| 9 | 153 | Friends, let us look for a better way than to {p}. | 34 | 60 | Your side wants us to {p}. We should say no. |
| 10 | 153 | The risks of a plan to {p} are not accounted for. | 35 | 59 | The {owner} wants us to {p}. Who speaks for everyone else? |
| 11 | 153 | The evidence for a plan to {p} is thin. | 36 | 47 | Do not tell me we cannot {p}! Families are waiting! |
| 12 | 153 | A plan to {p} is a gift to a few. | 37 | 39 | Surely we can all agree it is time to {p}. |
| 13 | 153 | Of course we may {p}. Just not like this. | 38 | 37 | I came with an open mind on {risk}. |
| 14 | 153 | It may be that a plan to {p} needs another look. | 39 | 37 | Critics say {critic}. What do the data say? **(C10)** |
| 15 | 152 | Who pays if we {p}? Say it plainly. **(C4)** | 40 | 37 | Show me the cost for {cost}. |
| 16 | 152 | This is not paperwork. It is people, and you want to {p}! **(C8)** | 41 | 36 | I want an honest answer on {risk}. |
| 17 | 148 | Most people I meet doubt that we should {p}. | 42 | 36 | Critics say {critic}. Answer them straight. **(C10)** |
| 18 | 148 | What does it cost to {p}? Give me the number. **(C4)** | 43 | 36 | Why not back {alt}? Tell me honestly. |
| 19 | 147 | I want an honest answer: what goes wrong if we {p}? **(C4)** | 44 | 36 | I speak for {gain} and I mean it. |
| 20 | 147 | I have heard the worry about a plan to {p}, and it is real! | 45 | 36 | That does not answer {gain}. |
| 21 | 147 | Surely we can find a middle path before we {p}. | 46 | 36 | I will not pretend that {critic}. **(C8)** |
| 22 | 147 | Those who push us to {p} serve one group only. | 47 | 36 | I will not let {risk} pass without an honest answer. |
| 23 | 147 | I could imagine a plan to {p}, quietly, in another form. | 48 | 36 | Do you feel nothing about {risk}? |
| 24 | 146 | Compare the alternatives before anyone moves to {p}. | 49 | 36 | People are more than a bill! |
| 25 | 144 | Why should we {p}? Tell me honestly. **(C4)** | 50 | 36 | Critics say {critic}, and my heart agrees! |

The largest personal-line clusters (exact text, many opponents): "Honesty has worked for me so far." and "My word is good here." (26 each), "I mean every word of this.", "Hold me to what I say." and "People feel this, and so do I." (20 each). The game never repeats a line inside one level (`pick_unused`), so these are not echoes in play.

## Sweeps and the lead's candidate list

- **Lead's 750 R2 candidates.** C2 (607): all but 3 are replies to the player's argument ("That claim does not hold.", "This weakens us abroad. Explain.") and are true in context; the 3 confirmed are room-pool lines. C6 (127): all false alarms ("turn your back", "wage levels", "Renewable Energy Act", "no vote from me"). C1 (16): 15 confirmed; OC3177 is a C8 grammar defect.
- **My own sweeps (whole file):** once-only words, history words, machinery words (level, stage, turn, energy, card, points, threshold, win, digits), off-terms, British spellings and terms, collective nouns with "are/have", plural organization agreement, articles before organization names, serial commas, double words and spaces, end punctuation, placeholders, and pool echoes (80% word overlap inside each of 2,421 pools: 1 pair, harmless). Only the findings above survived.

## Dead lines (not counted as defects)

275 personal lines are never spoken: the eight journalists have no Gain or Block move since 2026-11-04 (240 lines), and three committee members have no Block move (35 lines). The journalists' gain lines include more cheering ("Clear and quotable. Thank you."). Listed for `CLEANUP_CANDIDATES.md` if Cameron wants them gone.

## opponents.json

No defects found in names or titles; all are canon. Two things to check are under Questions.

## Questions for Cameron

1. **Gain lines (finding 1).** Is an opponent's Gain move meant to read as the opponent rallying their own support? If yes, the 708 rewrites stand. If you meant gain lines as grudging agreement that still wins the room over, say so and they become low priority.
2. **Bill-part lines that assume the player backs the part (finding 2).** Should the five frames ("Why should we {p}?", "Who pays if we {p}?", "what goes wrong if we {p}?", "is it fair to {p}?", "What does it cost to {p}?") be **retagged Against** in their Side column (no text change, but a structured column), or **reworded** as in the ledger so anyone may say them?
3. **Unaffiliated speakers in a legislator's voice.** Students and constituents (and journalists, though those lines are dead) draw on the party style banks with "ordinary people" as their cause: "Enemies of our future sit across the aisle.", "Ordinary people stay with our side." One representative row is in the ledger (about 76 such lines). Should students and other visitors get their own voice banks?
4. **The critic clause** repeats up to 8 times per bill. Vary the frames (my suggestion), or accept it?
5. **"Students United"** is treated as singular in some lines and plural in others. Which is it? (Same question for "Neighborhood Associations" pronouns.)
6. **opponents.json, canon:** OP27's title reads "President of the National Assembly; ... Speaker of the National Assembly". Are both posts meant? Elsewhere the body is "Parliament" (e.g. the organization "Members of Parliament"); is "National Assembly" the canon name for the chamber?
7. **opponents.json, canon:** names mix given-family and family-given order ("Kenta Aoshima" beside "Okabe Hideriai", "Iida Eri"). Is that deliberate?
8. **Dead journalist lines** (240): keep for a future reporter move, or list for cleanup?

All rewrites are drafts for Cameron.
