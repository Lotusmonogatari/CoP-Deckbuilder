# Two offices: decisions recorded (2026-11-20, Cameron)

These are Cameron's answers to the open questions in `TWO_OFFICES_SPEC_2026-11-19.md` (the spec copy there is rev 100 and does not yet show them) and in the audit (`design/review/p11_two_offices_audit_2026-11-19/REPORT.md` on branch `review/p11-two-offices-audit`). Where Cameron gave no preference, the spec's recommended default is recorded and marked so. **This file is a record of decisions only; nothing in the game, data or workbook changed.**

## Executive summary

| Question | Answer |
|---|---|
| Can art start? | **Yes, all of it.** No open design or mechanics question blocks any asset any more (list below). |
| Anything still open? | Small items only (the last table): none block art. |
| Next gate | The remaining build work runs in the spec's phases 2 to 5; the data approvals needed for it are given (decision 16). |

## Decisions that unblock art

| # | Decision | Detail |
|---|---|---|
| 1 | PC03 District office | **Teine Ward, Sapporo** |
| 2 | PC04 District office | **Mutsu** |
| 3 | PC01 and PC02 District offices | **PC01: Daikoki, a neighborhood of Wakkanai. PC02: Akenoshinmachi, a neighborhood of Tomakomai.** (Replaces the "Central Wakkanai / Central Tomakomai (proposed)" rows.) |
| 4 | Places vs. the office | Each district keeps its own localized place catalog (the 24 archetypes), **independent of where its District office stands**. Each District office has **its own image**. |
| 5 | Pins (room objects) on the District offices | **Same pin positions in all four.** The four images are drawn to one shared layout; one pin set serves all. The Capitol's set is unchanged. |
| 6 | Either rooms that need a new District background | **Lobbyist meeting, policy study and the media ambush street**, shared by all four protagonists. The **Office Hours room reuses each District office's own image** (no extra art). The picture missing for `OUT_NEIGHBORHOOD` is still a gap to fill. |
| 7 | Tickets | **Both ship:** the paid train ticket and the private car. The car **does not change the strip**: using it is **instant to do (no drag) with the same fade out and in**, and **it still spends its hours** (5 / 1 / 1 / 9 for PC01 to PC04; Cameron, 2026-11-20). |
| 8 | Brand names | **The proposed Yezo brand map is adopted now.** Cameron may edit it later; keep signs and logos minimal in art. |
| 9 | Train encounter format | No preference given: **the short dilemma** (the spec's recommendation). Rider art is portraits, silhouettes first (P7). |
| 10 | Train encounter rate | **1 in 8 trips on the rail pass.** (Cameron first said 1 in 12, then revised it back to 1 in 8.) The private car skips encounters. |

## Mechanics and data decisions

| # | Decision | Detail |
|---|---|---|
| 11 | Weekend travel | **No travel at the weekend.** The weekend is played where the week ended; the next week starts there. A weekend trip is refused with a reason (Standard 2). |
| 12 | Promise deadlines during travel | **They keep running.** Before leaving, the strip warns if a promise due soon can be kept only where the player stands. |
| 13 | Staff | **Work wherever the player is.** Only the District Representative's greeting (ON01, ON02) and the constituent notices (ON13 to ON16) move to the District office. |
| 14 | PC01 and PC04 difficulty ("Is Kenshin still Easy?") | No preference given: **decide after the re-simulation (P5)** shows real win rates. The travel hours stay as settled (6 / 1 / 1 / 6 by train, 5 / 1 / 1 / 9 by car). |
| 15 | Mixed levels LV10, LV21 and LV28 | **All three Capitol.** (LV12, LV61 and LV62 were decided earlier: District, finishing at the Capitol.) |
| 16 | Start of a new run | **The Capitol, for all four protagonists.** Old saves migrate to the Capitol. |
| 17 | New data columns and tabs | **Approved as written:** Location on Levels, Events, Event Choices, Office Notices and Office Ticker (blank means Either); Needs Place on Events; a Places tab; a Train Encounters tab. Also the **Protagonist column on Levels** (blank means everyone). |
| 18 | The eight protagonist levels | **The Protagonist column is approved; the eight levels are written after travel works**, as ordinary workbook rows using place tokens. |
| 19 | Overlap with the Integrated Resort Act and other acts (LV34, LV55, LV70, LV61) | **Flavor only.** A win changes nothing in the act. A discount or unlock would be new mechanics and would come as its own proposal. |
| 20 | Negative level rewards | **Allowed**, a few true trade-offs where the story calls for one, always shown in the briefing's Organizations card before Go in. |
| 21 | Real names in text | **Keep real geography** (towns, mountains, straits, neighbouring countries); **Yezo-ize companies and branded venues only**, per the adopted brand map. No mass rewrite of Hokkaido, Japan and similar. |

## Added later on 2026-11-20: mixed levels now cost travel (replaces spec rule 5)

The spec's rule 5 said a mixed level's travel is built in, free and not shown. **Cameron changed it:**

| # | Decision | Detail |
|---|---|---|
| 22 | A mixed level charges its travel time | **Level hours plus travel hours**, shown in the briefing. A **full round trip, capped**: 2 trips for the 20 Capitol levels with a District room in the middle; **1 trip for LV12, LV61 and LV62** (District to Capitol); LV10 (which alternates four times) is capped at one round trip. Data: a `Travel Trips` number on Levels (blank or 0 = none), which also says where the player ends (an odd count ends at the other office; an even one where they started). PC01 and PC04 pay 12 hours per round trip, PC02 and PC03 2. |
| 23 | Choosing the travel mode | **A mode row of three icons in the briefing** (rail pass, paid ticket, private car), showing only the modes the player has; the **hours in the briefing adjust at once** as the mode is picked. The rail pass is always there. |
| 24 | Encounters on a mixed level | **One roll at the start** on the rail pass and the paid ticket; the car skips it (1 in 8 on the pass, as for the swipe). Built in slice 4. |

**Effect on the numbers:** the audit's hours model assumed mixed-level travel was free. With 24 mixed levels, PC01 and PC04 now lose more hours than the audit's 5 to 11 a week; the re-simulation (slice 7) measures it, and decision 14 (the PC01 and PC04 rating) waits for it. By the audit's data no mixed level goes past 40 hours with its trips added (the longest, LV10, is 27 plus 12 for PC01 and PC04).

## What this means for the art list

| Asset | Status |
|---|---|
| District office image, four of them (Teine Ward; Mutsu; Daikoki, Wakkanai; Akenoshinmachi, Tomakomai), one shared layout | Unblocked |
| Long train picture for the swipe strip (the car uses the same strip) | Unblocked |
| Train interior background | Unblocked |
| District backgrounds: lobbyist meeting, policy study, media ambush street | Unblocked |
| `OUT_NEIGHBORHOOD` (named by three stages, no file) | Unblocked, a gap to fill |
| Rider silhouettes (P7) for the dilemma | Unblocked |
| Ticket icons: paid train ticket and private car | Unblocked |

## Still open (none block art)

| Item | Why it still matters |
|---|---|
| ~~Spelling check: "Daikoki"~~ **Resolved 2026-11-20: Daikoku** (PC01's neighborhood of Wakkanai) | Cameron wrote "Daikoki". Claude recalls a Wakkanai district usually romanized "Daikoku" (from memory, not checked in the repo's research); confirm the spelling wanted before it appears in text or art. "Akenoshinmachi" for Tomakomai was likewise not checked. |
| ~~Are Misawa, Tohoku and Shichinohe inside Aomori Block 3?~~ **Resolved 2026-11-20: yes.** | Spec "Settled" paragraph: they "still need Cameron's word". Affects PC04's place catalog only. |
| ~~Paid train ticket and car: prices;~~ **Resolved 2026-11-20: 10,000 / 30,000 / 60,000円 (train, car, plane).** Original question:  are BO23, BO05 and BO14 the right groups; does the +2 scale as usual or apply flat? | Spec open question 10. Prices are Balance rows. |
| PC04's car takes 9 hours against 6 by train, so as priced it costs Funds and 3 more hours (it only skips encounters, which are 1 in 8 trips on the pass). PC01's car saves 1 hour. | Not a new decision: the settled hours stand. Revisit with the re-simulation, together with the PC01 and PC04 rating (decision 14). |
| Does the car still need a confirm tap before it fades, or does choosing it start the trip at once? | "Instant to do" is recorded; whether a confirm step stays for the refusal and promise warnings is a build detail. |
| Which train encounters, riders and questions (about 8 rider types) | Content, after the format is built. |
| A fixed place for one row (Rokkasho's ports, the Ishikari Fish-House Baths) | Build detail, a place ID in the token. |
| Review of Claude's drafts: visitor office tags, the ten Capitol events EV95 to EV104, the P12 briefing text | Drafts for Cameron. The visitor tags are on `main` but unused (there is no Location column yet); EV95 to EV104 are on `main` and live as ordinary events; the P12 briefing text is on branch `panel/p12-level-preview`, not merged. |

## Cameron's answers after the hours report (2026-11-20)

| # | Decision | Detail |
|---|---|---|
| 25 | PC01 and PC04 ratings | **Keep the labels** (PC01 Easy, PC04 Very Hard). **PC01 starts a run with four Plane Tickets; PC04 gets nothing.** (The report's option B, for PC01 only.) Decision 14 is closed. |
| 26 | Ticket prices | **Paid train ticket 10,000円, private car 30,000円, plane ticket 60,000円** (the build's drafts were 5,000 / 15,000 / 40,000円). |
| 27 | Spellings | **Daikoku**, Wakkanai (not "Daikoki"). **Akeno Shinmachi** (明野新町), a residential neighborhood of Tomakomai (not "Akenoshinmachi"). Both are now the Player tab's District Office. The kanji accent is not shown anywhere yet. |
| 28 | Aomori Block 3 | **Misawa, Tohoku and Shichinohe lie inside it** (PC01's district). Six draft names for them were added to PC01's places (Misawa City Hall, Shichinohe Town Hall, Tohoku Town Office, Shichinohe-Towada Station, Lake Ogawara, Lake Ogawara's shijimi clam beds). |

## Cameron's answers on the open items (2026-11-20, after the build)

| # | Decision | Detail |
|---|---|---|
| 29 | A nudge to visit the District | **Not needed.** The Capitol list never running out is accepted. |
| 30 | The private car's price for PC02 and PC03 | **No change** (30,000円, though it saves them no hours). |
| 31 | LV10 for PC01 | **Fine** as it is: 41 hours on the rail pass, so it takes the plane. |
| 32 | Four starting plane tickets for PC01 | **Sufficient for now.** |
