# Writing review R3: the player's own lines (2026-11-09)

Draft by Claude (reviewer R3) for Cameron. Scope: `data/player_cues.json` (3,696 rows, 18,060 lines), `data/card_cues.json` (70 cards, 350 lines, read in full) and `data/level_intro_thoughts.json` (250 thoughts, read in full). Ledger: `design/review/WRITING_REVIEW_R3_2026-11-09.csv` (81 rows: 13 frame findings covering about 3,400 lines, 68 single-line findings). Nothing in the workbook, data or code was changed.

## Executive summary

| | |
|---|---|
| Biggest problem | **Bill-part (component) lines drop the article from organization names**: "Chamber of Commerce will fight us on this", "To fund harbor repairs is to keep faith with Fisheries Cooperative's members". 1,384 lines, every sponsored and drafted bill. One frame fix. |
| Most important truth problem | **Party replies assume the party backs the bill** (C4): "Our position is clear... I will vote for the bill", "The party's analysis overstates the gains". Wrong whenever the player's lean differs from the party's Floor Vote position. 12 rows. |
| Second truth problem | Bill lines say **"this chamber"** in town halls, caucus rooms and press rooms (62 lines), and component lines say the organization **"asked me to"** do something in a drafted bill nobody asked for (297 lines, C3). |
| Sample, player_cues | 320 random lines: **16.6% have any defect (95% range 12.9-21.0%)**, nearly all from frames; **C1-C4: 5.6% (3.6-8.7%)**, above the directive's 1-in-100 target until the frame fixes are applied. After the 13 frame fixes the remaining C1-C4 rate in the sample is 0.3% (1 line of 320, the BI28 facet in question 7). |
| What is clean | No C1 (once-only) defects anywhere in the three files; no C12 placeholder problems; quotes and apostrophes consistent; only 9 British spellings or terms. |

## How each file can appear (section 4 facts)

| Content | Repeats? | Where | Who hears it |
|---|---|---|---|
| Stage rows (636 rows) | Yes, pooled | Generic rooms ST01-ST22 and the no-bill topic rooms of LV61/LV62 (276 live rows) | The room's opponent |
| Topic-room stage rows PL169-PL528 (360 rows) | - | Only ST32-ST100, which are always in bill levels, where bill lines take priority (`CardCues.for_card`): **these rows are never shown today** | - |
| Bill rows (1,800) and reply rows (180) | Yes | Every room of that bill's level, including town hall, caucus, press and lobbyist rooms | Any opponent; the player's lean decides Support/Oppose |
| Component rows (1,080) | Yes, and a 2-3 part bill pools 2-3 rows of the **same six frames** | Sponsored and drafted bill levels | The player always argues for the part |
| Card cues | Yes; only a fallback (a card that neither attacks, gains nor guards, or a room with no lines) | Any room | Universal scope |
| Level intro thoughts | Repeat unless the level is One-Time (LV31-LV82 bill levels are One-Time; LV01-LV30, LV61-62, LV98-101 repeat) | Before the level, **before the lean is chosen** | The player's private thought |

## Counts by code

| Code | Ledger rows | Lines affected | Main source |
|---|---|---|---|
| C8 grammar and style | 22 | 2,240 | Component article frame (1,384), time words in bill frames (300), serial comma in facets (254), `{what}` agreement (84), "pretend ... agree" (142) |
| C2 unanchored | 16 | 544 | "them/their" frames in component and bill lines |
| C3 assumed history | 3 | 299 | "members asked me to" (component), "the part I worked hardest on" |
| C4 wrong speaker/listener | 22 | 132 | Party replies, "this chamber", "the opposition", proportional-block "my district" |
| C10 echo | 4 | 156 | Two component Appeal frames that repeat a neighbor |
| C11 tone | 1 | 50 | "Who gains: ... Who pays: ..." as a private thought |
| C7 American English | 9 | 9 | cheque, Modelled, offence, "agree a", "mark homework", "pilot scheme", "divide", "rings" |
| C5 machinery | 3 | 3 | "win" (card C30), "threshold" in a reply |
| C6 off-term | 1 | 1 | "every yen" (question for Cameron) |
| C1, C12 | 0 | 0 | |

## Sampling (directive section 6.3)

Random sample of 320 player_cues lines (seed 20261109; 159 bill, 92 component, 61 stage, 8 reply), each read in context. Wilson 95% ranges.

| Code | Hits | Rate | 95% range |
|---|---|---|---|
| C1 | 0 | 0.0% | 0.0-1.2% |
| C2 | 9 | 2.8% | 1.5-5.3% |
| C3 | 8 | 2.5% | 1.3-4.9% |
| C4 | 1 | 0.3% | 0.1-1.7% |
| C8 | 36 | 11.2% | 8.2-15.2% |
| C10 | 7 | 2.2% | 1.1-4.4% |
| C5, C6, C7, C11, C12 | 0 | 0.0% | 0.0-1.2% |
| Any defect | 53 | 16.6% | 12.9-21.0% |
| C1-C4 | 18 | 5.6% | 3.6-8.7% |

card_cues (read in full): 13 of 350 lines flagged (3.7%), all low or medium except C39 cue_4. level_intro_thoughts (read in full): 13 single rows plus two low-confidence frame findings over the 100 bill thoughts.

## Frames to fix

| # | Frame (source) | Code | Lines | Fix |
|---|---|---|---|---|
| 1 | Component PLAYER, every `{owner}`/`{rival}`/`{owner_s}` frame (`tools/workbook/archive/b11/component_frames.py`; **the current wording exists only in data**, from the 2026-10-25 rewrite in commit `104d9ed`, so the frame file must be brought up to date before re-running `component_rewrite.py`) | C8 | 1,384 | Fill with "the Chamber of Commerce" style names; "the members of {the_owner}" instead of the possessive |
| 2 | Component Earnest "I will not pretend {rival} agree, but..." | C8 | 142 | "{The_rival} may disagree, but I believe we should {p}." |
| 3 | Component "members asked me to / have asked us to" | C3 | 297 | "Members of {the_owner} want us to {p}..." |
| 4 | Component "Hear them out...", "what it means to them", "leave them behind" | C2 | 330 | Name who: "the people it helps", "families", "people" |
| 5 | Component Appeal echoes | C10 | 153 | Replace two of the twelve Appeal frames |
| 6 | Bill Emotional "their stories/fears", "Their faces/worry" (`b12/extra_frames.py` EXTRA) | C2 | 200 | Use `{gain}`/`{hurt}` or "the families I have met" |
| 7 | Bill "today", "listening now", "Now vote/think" | C8 | 300 | Drop the time word |
| 8 | Bill Data Driven "this chamber" | C4 | 62 | Finish the 2026-10-20 fix: "before anyone votes", "to the public once it is in force" |
| 9 | Bill Earnest `{what}` as subject (`is a plain, fair idea`, `sounds fair on paper`) | C8 | 84 | Move `{what}` to object position |
| 10 | `design/reference/bill_facets.json`: 21 lists without the serial comma | C8 | 254 | Add the comma; regenerate (shared with R6) |
| 11 | Topic-room BANK (`b3/cues.py`): "Funny how {t} suits you", "Voters keep raising {t}", "Your side caused this over {t}" | C8 | 60 | Low priority: these rows never show today |
| 12 | Bill thoughts (`b8/thoughts.py`): "My hope is that {gain} come out better off" | C4 | 50 | Neutral before the lean is picked |
| 13 | Bill thoughts: "Who gains: X. Who pays: Y." | C11 | 50 | Read as a thought, not a dossier heading |

### The 50 largest clusters

| # | Lines | Kind | Shape (names masked) | Generator |
|---|---|---|---|---|
| 1 | 155 | component | To {p} is to keep faith with {owner_s} members. | b11/component_frames.py (current text: commit 104d9ed) |
| 2 | 155 | component | This is about real families, and we should {p}! | b11/component_frames.py (current text: commit 104d9ed) |
| 3 | 153 | component | {owner_s} members asked me to {p}, and I think they are right. | b11/component_frames.py (current text: commit 104d9ed) |
| 4 | 153 | component | Judge me on whether we {p} honestly. | b11/component_frames.py (current text: commit 104d9ed) |
| 5 | 153 | component | Do not turn away from those who need us to {p}! | b11/component_frames.py (current text: commit 104d9ed) |
| 6 | 153 | component | Think of the people who need us to {p}! | b11/component_frames.py (current text: commit 104d9ed) |
| 7 | 153 | component | The risks of a plan to {p} are measurable, and I have measured them. | b11/component_frames.py (current text: commit 104d9ed) |
| 8 | 153 | component | Of course we should {p}. Who would say otherwise? | b11/component_frames.py (current text: commit 104d9ed) |
| 9 | 153 | component | It may be that a plan to {p} deserves a quiet hearing. | b11/component_frames.py (current text: commit 104d9ed) |
| 10 | 149 | component | Perhaps {rival} will not mind a plan to {p} as much as feared. | b11/component_frames.py (current text: commit 104d9ed) |
| 11 | 148 | component | Hear them out, then help us {p}! | b11/component_frames.py (current text: commit 104d9ed) |
| 12 | 148 | component | {rival} will fight us on this. We should {p} anyway. | b11/component_frames.py (current text: commit 104d9ed) |
| 13 | 148 | component | Some say we should not {p}. I would not like to comment. | b11/component_frames.py (current text: commit 104d9ed) |
| 14 | 147 | component | If we {p}, I will answer for every part of it. | b11/component_frames.py (current text: commit 104d9ed) |
| 15 | 147 | component | I have seen what it means to them. We must {p}! | b11/component_frames.py (current text: commit 104d9ed) |
| 16 | 147 | component | Compare the options: weigh the plan to {p} fairly. | b11/component_frames.py (current text: commit 104d9ed) |
| 17 | 147 | component | I could imagine a plan to {p} in a more modest form. | b11/component_frames.py (current text: commit 104d9ed) |
| 18 | 146 | component | The other side fears change. We should {p}. | b11/component_frames.py (current text: commit 104d9ed) |
| 19 | 144 | component | Whoever stands against a plan to {p} owes {owner_s} members an answer. | b11/component_frames.py (current text: commit 104d9ed) |
| 20 | 144 | component | I will say plainly why we should {p}. | b11/component_frames.py (current text: commit 104d9ed) |
| 21 | 144 | component | {owner_s} members have asked us to {p}, and their voices matter! | b11/component_frames.py (current text: commit 104d9ed) |
| 22 | 144 | component | Here is what it takes to {p}, line by line. | b11/component_frames.py (current text: commit 104d9ed) |
| 23 | 144 | component | I would not want a plan to {p} misunderstood. | b11/component_frames.py (current text: commit 104d9ed) |
| 24 | 142 | component | I will not pretend {rival} agree, but I believe we should {p}. | b11/component_frames.py (current text: commit 104d9ed) |
| 25 | 141 | component | Those who block a plan to {p} are blocking {owner_s} members. | b11/component_frames.py (current text: commit 104d9ed) |
| 26 | 139 | component | Delay is a decision against {owner_s} members. We should {p}. | b11/component_frames.py (current text: commit 104d9ed) |
| 27 | 114 | component | Choose a side: we {p}, or we leave {owner_s} members behind. | b11/component_frames.py (current text: commit 104d9ed) |
| 28 | 100 | bill | I am open to {b}, naturally, and to other possibilities. | b8/bill_frames.py, b12/extra_frames.py |
| 29 | 100 | bill | One could say I lean a little, though I would not say which way. | b8/bill_frames.py, b12/extra_frames.py |
| 30 | 100 | bill | What I say in the chamber and over tea may differ. | b8/bill_frames.py, b12/extra_frames.py |
| 31 | 81 | component | Examine the figures on a plan to {p}. | b11/component_frames.py (current text: commit 104d9ed) |
| 32 | 80 | component | Friends, let us hear everyone on whether to {p}. | b11/component_frames.py (current text: commit 104d9ed) |
| 33 | 79 | component | Weigh the evidence on whether to {p}. | b11/component_frames.py (current text: commit 104d9ed) |
| 34 | 78 | component | Let us work together to decide whether to {p}. | b11/component_frames.py (current text: commit 104d9ed) |
| 35 | 78 | component | Everyone affected by a plan to {p} deserves a hearing. | b11/component_frames.py (current text: commit 104d9ed) |
| 36 | 78 | component | Run the numbers on a plan to {p}. They deserve scrutiny. | b11/component_frames.py (current text: commit 104d9ed) |
| 37 | 77 | component | Let us decide together on a plan to {p}. | b11/component_frames.py (current text: commit 104d9ed) |
| 38 | 75 | component | Everyone deserves a fair hearing on a plan to {p}. | b11/component_frames.py (current text: commit 104d9ed) |
| 39 | 74 | component | Whatever we decide about whether to {p}, let us decide together. | b11/component_frames.py (current text: commit 104d9ed) |
| 40 | 74 | component | Let us work together on whether to {p}. | b11/component_frames.py (current text: commit 104d9ed) |
| 41 | 74 | component | The figures on a plan to {p} deserve a look. | b11/component_frames.py (current text: commit 104d9ed) |
| 42 | 74 | component | Let us see the evidence on whether to {p}. | b11/component_frames.py (current text: commit 104d9ed) |
| 43 | 70 | component | Most of us would agree: hear everyone on whether to {p}. | b11/component_frames.py (current text: commit 104d9ed) |
| 44 | 70 | component | Run the numbers on a plan to {p}. Read them first. | b11/component_frames.py (current text: commit 104d9ed) |
| 45 | 68 | component | {owner_s} members are our neighbors. Ask them: should we {p}? | b11/component_frames.py (current text: commit 104d9ed) |
| 46 | 59 | component | I hope {rival} will join us: should we {p}? | b11/component_frames.py (current text: commit 104d9ed) |
| 47 | 50 | bill | I have read {b} line by line, and I stand behind it. | b8/bill_frames.py, b12/extra_frames.py |
| 48 | 50 | bill | {gain} asked for this, and I owe them an honest answer. | b8/bill_frames.py, b12/extra_frames.py |
| 49 | 50 | bill | I know {b} is not perfect. Here is what I would watch. | b8/bill_frames.py, b12/extra_frames.py |
| 50 | 50 | bill | Nobody is pretending the risk of {risk} is small. | b8/bill_frames.py, b12/extra_frames.py |

First four words, top 15: "It may be that" 223; "Run the numbers on" 220; "I have seen what" 182; "The risk of {risk}" 168; "To {p} is to" 155; "This is about real" 155; "Choose a side: we" 155; "{owner_s} members asked me" 153; "Judge me on whether" 153; "Do not turn away" 153; "Think of the people" 153; "Let us work together" 153; "The risks of a" 153; "Of course we should" 153; "Whoever stands against a" 150

Clusters 1-27 and 31-46 are the component frames (six rows per part, 180 parts); 28-30 and 47-50 are bill frames that every bill shares (100 or 50 lines each). The three Duplicitous lines at 28-30 ("I am open to {b}...", "One could say I lean a little...", "What I say in the chamber and over tea may differ.") are the same for Support and Oppose; that is acceptable (a Duplicitous player hides the lean) and they are not echoes within one pool.

## Ten worst findings

| # | Finding | Lines | Code |
|---|---|---|---|
| 1 | Organization names without "the" in every component line ("Chamber of Commerce will fight us on this.") | 1,384 | C8 |
| 2 | Party replies that assume the party backs the bill (PL3625, PL3628, PL3634, PL3635, PL3638...) | 12 rows | C4 |
| 3 | "members asked me to {p}" in drafted bills nobody asked for | 297 | C3 |
| 4 | "Hear them out" / "what it means to them" / "their stories" with no one named | 530 | C2 |
| 5 | "Before this chamber votes" / "to this chamber" said in town halls and press rooms | 62 | C4 |
| 6 | "{what} is a plain, fair idea" with plural subjects ("Five-year work visas ... is"); BI16 reads "The crime of planning serious organized crime, with wider wiretaps is a plain, fair idea" | 84 | C8 |
| 7 | Reply lines stating provisions a bill may not have ("{Bill} has a limit and a sunset", "names a lead agency and an independent auditor") and PL3553 "the part of the bill I worked hardest on" | 6 rows | C2, C3 |
| 8 | "today" / "now" in 300 bill lines against the time-word rule | 300 | C8 |
| 9 | Card C30 "Who's ready to win this thing?!" / "We can win this!" (winning is machinery) | 2 | C5 |
| 10 | C7 slips: "blank cheque", "Modelled", "offence", "mark their own homework", "pilot scheme", "rings" | 7 | C7 |

## Sweep candidates (directive section 7): what was confirmed

| Candidate | Hits (R3) | Outcome |
|---|---|---|
| C6 "turn", "energy", "card", "point", "stage", "level" | 375 | **All true in context**: "turn away", "clean-energy firms", "Digital Identity Card Act", "they have a point", "implementation stage", "at this stage", "share this stage" (TV debate), "One good turn deserves another" (card C38), "wage levels". The LV16 and LV69 thoughts ("energy") likewise. |
| C6 "yen" | 4 | Idiom ("every yen"); one ledger row as a question, the rest listed below |
| C2 line-initial This/That/It/They and "the bill" | 376 | **True in context** for stage and reply rows: a played card answers the opponent's last move ("That is not what the record shows."), and "the bill" in reply rows is filled with the bill's name in a bill room. "This bill" in generic Floor Debate (ST02) is anchored by the room's business (CONTENT_GUIDE 7.1 lets a stage line name it). Card cues C05, C07, C08, C16, C21, C22, C27, C28, C31, C34, C38, C50, C52, C54, C57, C66, C68 are anchored by the card's own action. Fixed: C06, C18, C23 (low), PL16, PL06. |
| C1 "finally", "my first" | 39 | **True in context**: "This is about people finally being heard" describes the bill's effect, not a once-only moment; PL3555 "my first two questions too" is a reply; LV20 "Overlooked groups notice who finally calls" is a general truth. |
| C7 "Two analyses", "cheque", "Modelled" | 3 | "analyses" is correct American; the other two are in the ledger |
| LV06 "Friends in the party are worth earning slowly." (C8 candidate) | 1 | Fine as written |

## Questions for Cameron

1. **Party replies (C4).** Should the Party reply rows be split by "with my party / against my party" (needs a column or code), or written neutral as proposed in the ledger? Neutral loses some bite.
2. **Organization names in sentences.** Fix 1 needs "the" before most names. Which names take no article? I assumed Students United and Our Traditional Society; also "National Media", "Constituency Voters" and "Local Kōenkai" read oddly as "members of ...". A small lookup in the frame script avoids a schema change.
3. **Proportional-block protagonists.** PC03 and PC04 sit for proportional blocks, yet card cues C10 and C28 and the LV98 thought say "my district". Keep, or reword as proposed?
4. **"The opposition" and "the majority".** The data names no governing or opposition party. Should the player ever say "the opposition benches"? (PL55, PL1160, PL1196, PL1142.)
5. **Canon in thoughts:** LV24 "The post-war creation of Yezo tried to erase what made our people distinct", LV48 "The earthquake showed...", LV54 "The plant has sat idle since 2011" (real Tomari units stopped 2011-2012). Are these canon? The LV24 line is also the player's own belief whatever their positioning.
6. **"Every yen"** in four lines (PL25, PL3520, PL3522, PL3526): an idiom, or a breach of "an amount carries 円"?
7. **Facets that read badly in frames** (shared with R6): BI16 `what` ("the crime of planning serious organized crime, with wider wiretaps"), BI12 `hurt` ("voters who elect the Cabinet" — Yezo voters elect the Assembly, not the Cabinet), BI28 `local` ("the shape of your district", said by the player to anyone), BI50 `what` ("open ballot of party members", missing "an").
8. **Dead rows.** Stage rows PL169-PL528 (topic rooms ST32-ST100) and the bill-room stage IDs on PL01-PL18 are never chosen, because bill lines always win in a bill level. Keep as a fallback, or list in `design/CLEANUP_CANDIDATES.md`?
9. **Card C16's name "Table the White Paper"** (R1's scope): in American usage "table" means shelve. Worth a look with R1.
10. **Composed bills repeat frames.** A three-part bill pools three component rows built from the same six frames per style, so the player can say "Think of the people who need us to ..." three times in one level. Rotating frame sets per part would need more frames (a writing job, outline first).
11. **Card cues C01-C54 are Cameron's own lines**; every proposal on them is low confidence and only a suggestion.

## Notes for the applier

- Frame fixes 1-5 need `component_frames.py` brought up to the current data wording first; `component_rewrite.py` then rewrites by row order and rotation.
- Frame fixes 6-9 can be applied as string replacements on the rendered lines (the ledger lists every affected `id.field`), or by editing `extra_frames.py` and replaying `b12/apply.py`'s replacement step; the 19 bills that already use the "anyone votes" and "public once it is in force" wording show the target text.
- Fix 10 is a facet edit followed by regenerating the bill lines; coordinate with R6.
- Length: every proposal stays within about 20% of the original, except the component article fix, which adds "the" (two to five characters).
