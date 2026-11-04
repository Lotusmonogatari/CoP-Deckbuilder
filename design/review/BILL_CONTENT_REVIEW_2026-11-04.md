# Bill content review: grammar, coherence and honesty (2026-11-04)

Cameron spotted "The people who pay are government control of messaging." on the stance screen. About 14,000 bill lines (player and opponent cues, stage questions, transitions, level-intro thoughts, vote cues) are built from 8 short phrases per bill (`design/reference/bill_facets.json`) dropped into about 950 sentence frames. Reviewing the frames and the 400 phrases covers every line. Fixes were made in the workbook, cell by cell, using each bill's own phrases.

## Executive summary

| Problem | Example (before) | Fix | Lines |
|---|---|---|---|
| A budget or an idea in a slot meant for people | "The people who pay are the national budget." / "Someone has to speak for privacy." | These frames now use the bill's "who loses out" group | ~140 |
| Non-people in the "who gains" group | "...after listening to pensioners and elder care"; "wildlife ... and tourism"; "some island jobs" | Gains rewritten as people (care workers; land users and tour operators; islanders looking for work) | ~215 |
| "Who/what/how" clauses after "for" | "the right thing for who decides the road and school budget" | Ten local phrases rewritten as noun phrases | ~140 |
| Number agreement | "The national budget carry the cost."; "What do overproduction cost?" | Frames reworded so the verb never follows a singular-or-plural slot | ~260 |
| Garbled frames | "Not a word about X gets past honesty."; "Where is the evidence for farmers?"; "I have seen what life is like for stations and timetables without it!" | Rewritten | ~180 |
| Doubled words | "a tax on the largest incomes instead instead" | Three alternatives no longer contain "instead" | ~40 |
| One-off lines | BI18's "Is power kept longer than the crisis lasts the real story..."; BI32 "balked at the bill for the hospitals"; BI31 "Speaker Ichizaki" | Rewritten; the Speaker is now "Speaker Namu", family name last like "Prime Minister Rono" | 5 |
| Repetition | "The people who pay are people who..." | Now "Who gains: ... Who pays: ..." | 50 |

## Intellectual honesty

The frames are paired: every supporting line has an opposing line in the same style, and the manipulative ones belong to the Divisive and Duplicitous styles by design. The imbalance was in the phrases. Some bills gave the opposition only insiders protecting their own interest, and two gave supporters only shareholders.

| Bill | Change | Source |
|---|---|---|
| BI12 Judicial Appointments | Opposition speaks for "citizens who want judges answerable" (~65%) and "voters who elect the Cabinet" (~35%) | Cameron |
| BI26 Civil Service Merit | Opposition: "local hires who know the town" and "towns short of applicants" (half each). Gains add "voters tired of patronage", the anti-patronage case. | Cameron |
| BI28 Election Commission | "voters who want elected mapmakers" (~55%) and "communities that new lines could split" (~45%) | Cameron (asked 65/35; few lines, so the split lands near) |
| BI34 Public Broadcasting | Opposition: "taxpayers who fund the broadcaster". Its cost is no longer "government control of messaging". | Cameron |
| BI35 Donation Transparency | Opposition: "small donors who fear being named in public" | Cameron |
| BI40 Constitutional Review | Opposition: "voters wary of amendments" | Cameron |
| BI36 Corporate Tax | Gains: "firms and the workers they hire" (was shareholders only) | Draft |
| BI17 Partnership Registration, BI19 US Agreement, BI30 Local Suffrage | Cost no longer names an abstraction ("traditional family norms in some eyes", "the idea that voting belongs to citizens") | Draft |

## Rules for future content

These are now in the facets file's README:
- **Gain and hurt:** plural groups of people. The hurt group is the opposition's strongest honest constituency.
- **Cost:** may be a budget, but never fills a people slot.
- **Local:** a noun phrase.
- **Alt:** never contains "instead".
- **Risk:** frames never put a verb right after it.

## Not changed

- Ellipses in the Duplicitous style.
- The `{bill}` placeholders, which the game fills in.
- Real-world names already decided on 2026-10-25.
- About 160 older component-bill cues run 21 to 23 words. That's over the 20-word limit, but they sit outside the test's scope; they're listed in case Cameron wants them trimmed.
