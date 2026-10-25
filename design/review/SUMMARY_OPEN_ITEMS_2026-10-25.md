# Content review: what is fixed and what is still open (2026-10-25)

## Executive summary
| | |
|---|---|
| Rows read | about 11,000, every row, in 40 slices |
| Findings logged | about 1,460 table rows (some cover many IDs) |
| Fixed today | the shared question frames (1,635 cells), 19 single-row grammar slips, 540 rewritten theme questions, 23 repeated sibling-stage questions, 15 duplicate pairs, 8 organization contradictions plus about 55 weak pairings, about 60 grade cells, 5 stage lists, 32 "this bill" transition lines, 36 askers matched to organizations |
| Decided to leave | real-world place names; Ainu-related organization pairings |
| Still open | the groups below, about 40 patterns. Almost all sit in **generated cue and bill-template text**, not in hand-written content |
| Biggest risk if left | grammar faults in the player cues and opponent cues (plural topics with singular verbs, double possessives); rows that argue the wrong side of the player's stance; visitor replies that answer a different choice |

## Open patterns, most important first
Severity: A = grammar fault, logic or canon problem; B = should fix; C = polish. "Meaning?" = fixing it changes what the line says or what a number does.

| # | Pattern | Where | Sev | Fix | Meaning? |
|---|---|---|---|---|---|
| 1 | Topic or faction noun with the wrong verb number ("The regions is", "Rural hospitals deserves") | Opponent cues about 170 rows; player cues about 100 rows | A | Give each topic a singular/plural flag, or use frames with no verb | no |
| 2 | Double possessives and missing "the" on organization names ("Neighborhood Associations's") | Player cues and transition lines, about 60 rows | A | Possessive helper plus article flag | no |
| 3 | Bill-cue lines start lowercase after a full stop; plural subject with singular verb | Player cues about 120 rows | A | Capitalize; plural-safe frames | no |
| 4 | Clauses dropped into noun slots ("reaches who stands...") | Opponent cues, about 150 rows | A | Change the frames to noun-phrase slots | no |
| 5 | Support and Oppose lines that argue the other side | Player cues, about 100 rows | A | Rewrite the stance clause | yes |
| 6 | Wrong organization named for the topic in cues ("Perhaps {Org} will not mind") | Player cues about 110 rows, transition lines about 28 | A | Re-point by topic | yes |
| 7 | Frames that contradict the bill ("Do not ask families to carry the cost" on a paperwork bill) | Opponent cues, about 270 rows | A | Tag each bill with a cost/harm phrase, or use neutral frames | yes |
| 8 | Visitor replies answer a different choice; identical choices in one question | Visitor dilemmas VQ283-VQ389, about 60 rows | A | Rewrite each reply for its own choice | yes |
| 9 | Organization effects with no visible reason, or pointing the wrong way | Visitors (about 20 questions), room questions S112-S212, L35/L38/L43, T09/T27/T48/T49 | A | Reassign per row | yes (numbers) |
| 10 | Themes drifted off their questions (effects belong to the neighbor) | S140-S217 and S94/S99 | A | Retheme per the list | yes |
| 11 | Event and card/shop text that promises what the numbers do not give | EV12, EV44, EV45, EV05, AE07 draft note, C04 (8 vs 6), "Guard N this turn" on 5 cards, SH09-SH11, SH13 | A | Confirm intended values, then fix one side | yes |
| 12 | Floor Vote leader cue contradicts its disposition label | BI25/PT02, BI29/PT05 and about 10 Neutral lines | A | Rewrite or relabel | yes |
| 13 | Office ticker: five all-Japanese headlines, exact Reputation = 50 triggers, contradictory Funds bands | TK09-TK11, TK16-18, TK20-26, TK29, TK39-40, TK12, TK42 | A | Add English, use bands, reword | yes |
| 14 | UI text: "this turn" vs next turn (battle.passed); "A bill you vote on becomes law" (HT17) | 2 sentences | A | Corrected wording in the file | no |
| 15 | Presumed stance: "why we should X", "the data backs you" with no stance gate | Transition lines about 120, player cues about 200 | A | Neutral frame, or add a stance gate (a behavior change) | yes |
| 16 | Patron bills: all 54 share one script; plural organization names with singular verbs | PB031-PB302 | A | Verb-neutral shared lines; per-organization wording is yours | partly |
| 17 | Role and voice mismatches (PM saying "against the establishment", journalists as a faction, caucus lines presuming leadership) | Opponent cues about 40 rows; player cues | A/B | Per-role lines | yes |
| 18 | Wrong asker or voice remains for about 25 questions (citizen voice from a legislator, "Prime Minister Rono" on T30) | S54, S184, S123-S209, T81, T107-T132, L02, L07, L26 | B | Set Asked By Organization, or reword to third person | no |
| 19 | Neutral questions carry stock organization pairs (Care and Welfare, Members of Parliament, Labor vs Chamber on L01-L18) | Procedural and generic rows, about 60 | B | Empty list or one related organization | yes (lowers effects) |
| 20 | Same stock line repeated across 20 to 150 rows; same reply repeated | Cues, transitions, visitors (stock reactions "Nods." 116 times) | B | Add 2 to 4 variants per frame | no |
| 21 | Law Effects: notes name winners or losers the effects do not apply; unmotivated losses | BI10, 11, 13, 16, 31, 34, 40, 44-46 and components | B | Add the missing effects or fix the notes | yes |
| 22 | Law headlines and influence cues templated (100 headlines, 46 cues) | TK44-TK143 | B | Bill-specific headlines | yes |
| 23 | Level Intros and thoughts: plural subjects, rigid frames, partisan thoughts, lean-blind "hope" lines | LV31-LV82 | A/B | Verb-independent frames; write one bill-specific line per level | yes |
| 24 | Taxpayers' Alliance is the only opposing group on 8 to 12 bills; it is now also displeased 525 times against 203 pleased (my swaps raised it) | cues, Question Themes | B | Name bill-specific cost-bearers; consider rebalancing | yes |
| 25 | Modifier, shop and stage names: raw ST codes in text, names matching no organization, about 12 stage names over 45 characters | M01-M36, SH01-SH24, stage names | B | Drop codes, align names, add short titles | partly |
| 26 | Candidate-selection grade fixes (S566-S582) were reverted because a test pins Party Activists to Divisive only | S566-S582 | B | Your call: change the test or keep the grades | yes |
| 27 | Rows with no asker or stage (S365-S564, 200 rows) may never be reachable | Stage Questions | B | Check they attach at runtime by bill | no |
| 28 | How to Play gaps: whip discount, dated events, district activities | HT28, HT32 | B | Add entries (wording is yours) | yes |
| 29 | Canon-risk traits and names not in the data: "idol fame" (TK11), Yumi Satou, Rika Ashikaga, "Cabinet Legislation Bureau", LV24 history, VQ173 | listed rows | B | You confirm or I neutralize | yes |
| 30 | Gender assumption ("She will get one") | TD481, TD1177-1191, TD526 | B | "Then your editor will get one." | no |
| 31 | British spellings in an American-spelling game (licence, centre, queue, pavement, lift, biscuit tin...) | about 45 spots | C | Replace with American forms | no |
| 32 | Lines over 130 characters; curly versus straight quotes (about 35 ticker lines); duplicate keys; contractions mixed | scattered | C | Trim and normalize | no |
| 33 | Player-thought rows have a blank reply (417 rows) | Transition dialogue | C | Confirm the display handles a blank reply | no |

## Suggested order
1. Pure grammar and spelling (#1 to #4, #14, #30, #31, #32): no change of meaning; can be done in generators/templates.
2. Mechanics that disagree with their text (#11, #12, #13): small, but I need your intended values.
3. Voice and stance (#5 to #8, #15 to #17, #23): meaning-changing rewrites, in batches you can review.
4. Balance of effects (#9, #10, #19, #24, #26): numbers; decide the target first.
