# Writing review R6: events and bills (2026-11-09)

Draft by Claude (reviewer R6) for Cameron. The ledger is `design/review/WRITING_REVIEW_R6_2026-11-09.csv` (98 rows). Nothing in the workbook or `data/` has been changed.

## Executive summary

Every event was read together with its choices and checked against the structured columns (costs, Funds, rewards, organization changes, promises and their deadlines, hours, follow-ups, levels started). Almost all of the text matches the columns. The main problems are:

1. **British words**, mostly in the newer event and hosted-event text: "surgery", "ring", "in hospital", "noticeboard", "housing estate", "shopfronts", "city centres", and **"table a proposal"** (which means *shelve* it in American English).
2. **Lines that assume something the player may not have done**: follow-up events assume a promise was kept; "the heritage bill" in a random event; dinner reactions that name farmers or a union man who may not be at the table.
3. **A few results that contradict their own promise deadline** (EV18 "next week" for a 36-hour promise; EV54 questions that arrive "a week later" for a 24-hour promise).
4. **The patron bill "fell short" line** (all 54 rows, shown in Legislative Work) reads badly for plural names: "Neighborhood Associations knows you tried".

## Counts by code

| Code | Rows | High | Medium | Low |
|---|---|---|---|---|
| C1 once-only | 3 | 0 | 1 | 2 |
| C2 unanchored | 14 | 2 | 8 | 4 |
| C3 assumed history | 5 | 0 | 4 | 1 |
| C7 not American | 46 | 17 | 21 | 8 |
| C8 grammar and style | 18 | 1 | 5 | 12 |
| C9 dishonest or lopsided choice | 6 | 1 | 2 | 3 |
| C10 repetition | 2 | 0 | 1 | 1 |
| C12 placeholder | 4 | 1 | 0 | 3 |
| **Total** | **98** | **22** | **42** | **34** |

No C4, C5, C6 or C11 defects were found. The sweep's C6 hits ("turn", "stage", "Energy") were all ordinary English or a bill name; its C1 hit for EV48 ("the first set") is fine, but the same event's result had a real once-only claim.

## Rows read and defect rate per file

Everything in scope was read, so these are full counts, not samples. The CB rows count each of the three fields (label, phrase, description) separately.

| File | Rows read | Findings | Rows with a finding |
|---|---|---|---|
| `events` | 75 events | 13 | 13 (17%) |
| `event_choices` | 261 choices | 38 | 33 (13%) |
| `event_options` + `hosted_events` | 59 options, 2 hosted events | 17 | 15 (25%) |
| `floor_votes` | 50 bills (7 text fields each) + 300 party cues | 11 | 11 (2% of 650 text cells) |
| `bill_components` | 180 components | 15 | 5 components (3%) |
| `patron_bills` | 54 rows (five identical draft lines) | 4 | all 54 share them |
| `law_effects` | 103 rows | 0 | only designer notes, no player text |

## The ten worst findings

| # | Where | Problem | Proposed |
|---|---|---|---|
| 1 | `patron_bills` fail_line, all 54 | "{org} knows you tried." reads "Agricultural Cooperatives knows you tried" in the law pop-up (C12) | "{org} will remember that you tried." |
| 2 | HE01 TC1/TC6, HE02 DC1/DC6 kept text | "You table a proposal/measure": American readers hear "shelve" (C7) | "submit a proposal", "introduce a measure"; also "send your guests a copy" (farmers may not be guests) |
| 3 | EV49 C | "a short speech on the heritage bill": no bill is named in this random event (C2) | "a short speech on Ainu heritage" |
| 4 | EV18 B | "Promise them a call next week", but the promise is due in 36 hours; result "They take your number" is backwards (C9, C8) | "in the next few days"; "You take their number." |
| 5 | EV81 | "since your session…": the follow-up arrives even if the promised session (VQ420 A) was never held (C3) | "two more of her clients hung up on scammers this month…"; "Hold a warning session in Kushiro" |
| 6 | EV22 | "the end of your surgery" (C7); the game's own name is Office Hours | "the end of your office hours" |
| 7 | EV54 C | The Chamber's questions arrive "a week later" though the promise to answer is due in 24 hours (C9) | "arrives the next morning" |
| 8 | BI48 description | "city centres" on the bill card (C7) | "city centers" |
| 9 | CB134 | "vacant shopfronts" in a component label shown on drafted bills (C7) | "vacant storefronts" |
| 10 | EV79 A | "The fox will need a new home": the fox appears only in VQ410's reply B, but only reply A leads here (C2) | "The animals living there will need a new home." |

## Frames to fix

None for R6: event, bill and component text is written row by row. The patron bill lines are one draft repeated on 54 rows (note "Draft 2026-10-19 … Cameron to rewrite"), so one change covers them.

## Checked and found consistent

- Every cost named in a choice (Funds, hours, an item, a promise) is on that choice's Commitment or Funds Cost; every organization a result names is in the choice's Rewards with the right direction.
- Every send-staff choice contains "a staff member" or "a staffer", so it greys out when nobody is hired.
- Bill descriptions and the six dossier fields agree with each bill's party positions; no line states an opponent's position as fact.
- Real Aomori and Hokkaido places are used as approved; no invented names were found.

## Questions for Cameron

1. **Follow-ups fire even when the promise behind them is broken.** `GameState` schedules the follow-up when the choice is made. EV76 to EV82 read as if the promise was kept ("The nets work…", "The pothole is filled", "The village hall is full"); EV81 says so outright ("since your session"). Options: (a) fire a follow-up only when its promise is kept (a small code change; I recommend this); (b) reword each follow-up so it is true either way (rows given for EV81 only); (c) leave as is.
2. **Random events repeat once their 24-hour cooldown (`event_default_cooldown_hours`) is over.** A few read as one-time: EV70 (your last campaign's boards, again), EV71 (the same grandson's wedding), EV55 (a profile of "new" legislators), EV48 ("the first week"). EV17 to EV27 say "a … bill is being drafted" every time, even after that level is open. Should these be one-off, or have a long cooldown? (Rows are given for EV48, EV55 and EV70.)
3. **A bill's proponent party opposes it:** BI26 Civil Service Merit Act (proponent Butsutou, Opposed), BI35 Political Donation Transparency Act (Frontier Party, Opposed), BI49 Local Government Mergers Act (Keizaijiyuutou, Neutral). Is the proponent or the disposition right? (Canon and party positions, so not touched.)
4. **EV16 B "Offer a small advance"** costs 20,000円 but does not reduce the dues owed (EV44 A does). Add a Dues Δ to the column, or reword it as a gift (the row proposes the reword)?
5. **EV02 "ringing out the old year"** is in season all Winter, so it can arrive in February. Limit it to December, or drop the phrase (row given)?
6. **Bill content to check (policy, not wording):** BI09's Who Pays is "People in poorer prefectures", but no organization loses when it passes. BI08's middle ground ("A tax on the largest incomes") is an alternative rather than a middle ground. BI01: does co-official status go to the Ainu language (the row proposes that wording)?
7. **"Decline" is one word beside choices of 5 to 10 words** on every Random event (the `@event.decline` label). Keep it as a deliberate exception to the "similar length" rule?
8. **Patron request, accept and decline lines** are not read by any script today. The low-confidence rows fix their grammar in case they come back; they could also go on `CLEANUP_CANDIDATES.md`.
9. **"Yen" spelled out** in the hosted events ("a crypto-yen", "measured to the yen") is an idiom and a product, not an amount. I left it alone; say if you want 円 there.
10. **"Hokkaido" as an outlet's name** ("the Hokkaido evening paper", EV75; "Hokkaido craft beer", DD4). Is this covered by your approval of real Hokkaido places?
11. **The Floor Vote party cues** are your 2026-11-07 wording. Only the double space in BI09 is marked high; the other five cue edits (BI19, BI20, BI25, BI29, BI30) are offered as low-confidence suggestions.
