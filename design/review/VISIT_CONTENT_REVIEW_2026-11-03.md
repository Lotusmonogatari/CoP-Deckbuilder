# Member visits and lobbyist trades: do they fit their bills? (2026-11-03)

Method: `tools/visit_review.gd` builds real custom-bill levels with the game's own level builder and content rules and prints everything the player would see in the member visit (ST260/ST261) and the lobbyist trade (ST262): ten samples (five patron bills, five player-drafted), plus statistics over 400 more (`VISIT_STATS=1`). The ten full transcripts are in `design/bench/visit_review_samples_2026-11-03.md`. This reads the content as the screens would show it; it did not click through the screens (the real-click visit and trade tests in `tools/verify.sh` already do that). Sample 3 repeats sample 1 (the picker drew the same patron bill twice).

## Executive summary

| # | Finding | Evidence |
|---|---|---|
| 1 | **9 of the 24 member questions are ungrammatical** with the part's phrase | "What would it take for me to stand with you on *make large firms pay suppliers on time*?" Each visit asks 3 of 24, so 77.5% of visits contain at least one broken question. Broken: MV05, 13, 16, 17, 18, 19, 21, 22, 23 |
| 2 | **Answers rarely answer the question** | There are only 36 answer lines, six per style, and none depends on the question or the bill. "Tell me how the plan is paid for" can be answered Strong with "Be on the side people applaud." |
| 3 | **A member visit talks about one part of the bill, as if it were the whole bill** | The phrase is the first part only; a three-part bill is asked about as "a bill that would *{first part}*" |
| 4 | **The same few people appear every time** | 307 visits, 16 members, 81% from Five Point Independents and 19% from Yezo Heritage Party; three members are 74% of all visits (Soma Umehori 38%). The pool of members on a given committee is one to three people |
| 5 | **Lobbyists are 12 people from 4 organizations** | Three of them are 67% of all trades. Every organization has one fixed rival in the data, so the lobbyist's grievance is org-level, not part-level |
| 6 | **Several grievances do not fit the part they target** | Chamber of Commerce asks to drop "fund street lighting"; Students United asks to drop "fund local festivals" and "repair old wooden buildings"; Labor Federation asks to drop "make large firms pay suppliers on time" |
| 7 | **A lobbyist sometimes asks for a part the player cannot trade** | 5 of 266 trades. The screen still says "They want the plan to ... gone" |
| 8 | **Lobbyist stems fit the bill, answers do not fit the lobbyist** | All 12 trade questions use "the plan to {part}" correctly, but "What will you give us?" is answered with "I will be straight with you..." |
| 9 | **What works well** | The member always sits on the bill's hearing committee when their party has a member there (every sample); the offer and reaction text read well; the bill's name and parts are used correctly in lobbyist questions; a good fit appeared in samples 5 and 7 |

## The ten samples

Fit is my judgment: Good, Fair or Poor, for the member visit and the lobbyist trade separately.

| # | Bill (short) | Member visited | Lobbyist and what they want dropped | Member fit | Lobbyist fit | Notes |
|---|---|---|---|---|---|---|
| 1 | Patron Flagship: pay suppliers on time, cheap equipment loans, register craftspeople | Kitahime Haibi, Five Point (Finance, matches) | Chiyo Hatakenaka, Labor Federation: drop "pay suppliers on time" | Fair | Poor | Q2 broken ("stand with you on make large firms pay..."); Strong answer to "how is it paid for" is an applause line |
| 2 | Patron Flagship: financial hub zone, foreign banks, new-firm tax holiday | Kitahime Haibi (Finance) | Chiyo Hatakenaka: drop "new-firm tax holiday" | Fair | Fair | Q1 broken; a labor lobbyist against a tax holiday is believable |
| 3 | Repeat of sample 1 | | | | | Generator repeat |
| 4 | Patron Favor: local festivals, protect historic districts | Soma Umehori, Five Point (Government Administration) | Aoi Kamishiro, Students United: drop "fund local festivals" | Fair | Poor | Students against festivals is contrived |
| 5 | Patron Favor: cut taxes for small businesses, cut paperwork | Kitahime Haibi (Finance) | Chiyo Hatakenaka, Labor: drop "cut taxes for small businesses" | Good | Good | The best fit of the ten |
| 6 | Draft, 3 parts: repair old wooden buildings, consumer complaint line, new-firm tax holiday | Kakuei Sato, Five Point (Construction) | Chiyo Hatakenaka: drop "tax holiday" | Poor | Good | The member talks only about wooden buildings; the bill is three unrelated things |
| 7 | Draft, 3 parts: late-night commuter trains, neighborhood legal standing, Sapporo financial hub | Minami Okirasnunipa, Heritage (Construction) | Fumihiko Takashiro, Chamber of Commerce: drop "neighborhood legal standing" | Fair | Good | Business against planning rights is believable |
| 8 | Draft, 3 parts: street lighting, temple land exemption, open town days | Minami Okirasnunipa (Construction) | Fumihiko Takashiro, Chamber: drop "fund street lighting" | Fair | Poor | The Chamber has no reason to oppose lighting |
| 9 | Draft, 2 parts: repair old wooden buildings, open public data to start-ups | Kakuei Sato (Construction) | Yuto Hanazono, Students United: drop "repair old wooden buildings" | Fair | Poor | The part they ask for is not among the parts the player may trade |
| 10 | Draft, 2 parts: care worker housing, protect historic districts | Kakuei Sato (Construction) | Ryusei Tobata, Students United: drop "protect historic districts" | Fair | Fair | Students against preservation is plausible |

Tally: member visit Good 1, Fair 7, Poor 1; lobbyist Good 3, Fair 2, Poor 4.

## Why

| Cause | Detail |
|---|---|
| Stems are written as "... {component} ..." with a verb phrase | Nine of them put the phrase where a noun or gerund belongs |
| Answers are keyed only to a style | Nothing ties an answer line to a kind of question. This is the problem the bill-room replies had until the Reply Kind work on 2026-11-01 |
| The phrase is the first part only (`PatronLevel.build_visit`) | Mixed three-part bills read as one idea |
| Visit parties are listed in template order (PT04 then PT02) and a party is chosen if it has any seat outside Yes | So Five Point Independents is almost always chosen |
| Members are drawn from the party's members on the hearing committee | Pools of one to three people, so the same names repeat |
| A rival is one fixed organization per owner (Bill Components Loses column) | Not per part |

## Options for Cameron (nothing has been changed)

| # | Issue | Options | My pick |
|---|---|---|---|
| 1 | Nine broken member questions | (a) Rewrite those nine as "to {part}" forms; (b) have the game turn the phrase into a gerund ("funding street lighting"); (c) leave | (a), a workbook-only fix |
| 2 | Answers do not fit the question | (a) Give each member and trade question a Reply Kind and write answers per kind and style (as for bill rooms); (b) leave | (a) |
| 3 | One part stands for the whole bill | (a) Use the part that matches the question's topic, or rotate parts across the questions; (b) name the whole bill in some stems; (c) leave | (a) |
| 4 | Same members | (a) Add more visit parties to the templates (for example PT01, PT03, PT05, PT06); (b) draw from the whole party when the committee pool is under three; (c) leave | (a) and (b) |
| 5 | Few lobbyists | (a) Add lobbyist rows for more organizations; (b) allow an allied organization to speak; (c) leave | (a) |
| 6 | Grievances do not fit the part | (a) Add a per-part Loses so each part has its own rival; (b) choose the lobbyist from the organization whose loss comes from the asked part and skip the trade when none fits; (c) leave | (a) |
| 7 | Asked part not tradeable | Hide the hint (or pick another part to ask for) when the asked part is not among the parts the player can trade | Do it; it is a one-line fix |

## Fixes applied and re-test (2026-11-03)

All seven recommendations were applied as recommended, then the same ten-sample read and 400-level statistics were repeated (new transcripts: `design/bench/visit_review_samples_after_2026-11-03.md`).

| # | Issue | What was done |
|---|---|---|
| 1 | Nine broken member questions | Rewritten as "the plan to {part}" forms (MV05, 13, 16, 17, 18, 19, 21, 22, 23); a unit test now checks every stem |
| 2 | Answers ignore the question | Every member and trade question has a Reply Kind (10 kinds); 120 new answers (kind x style x 2) were drafted; a question uses answers of its kind first, then the generic lines. The exporter fails if a used kind has fewer than two answers in any style |
| 3 | One part stands for the bill | The questions take the parts of the bill in turn |
| 4 | Same members | The templates list all six parties and one with seats outside Yes is drawn at random; the committee's members are used only when at least three sit there, otherwise the whole party |
| 5 | Few lobbyists | No new characters were invented (canon rule); the variety comes from fix 6, plus equally hurt organizations now take turns |
| 6 | Grievances do not fit the part | Every part's "who loses" was rewritten from its own policy tags (180 rows, same sizes), using a draft opposition table of mine for Cameron to correct |
| 7 | Asked part not tradeable | The part a lobbyist asks for is chosen among the parts the player may trade; when none hurts them, no hint is shown |

| Measure | Before | After |
|---|---|---|
| Member questions that read badly | 9 of 24 (77.5% of visits had one) | 0 of 24 |
| Visits whose answers fit the question kind | none were matched | all (kind-matched lines first) |
| Parties visited | 2 (81% Five Point Independents) | all 6, between 12% and 20% each |
| Distinct members across 290 to 309 visits | 16 (top three = 74%) | 82 (top member 4%) |
| Distinct lobbyists / organizations that speak | 12 / 4 | 19 / 10 |
| Most frequent lobbyist | 31% (Fumihiko Takashiro) | 34% (same person; the Chamber of Commerce has one representative) |
| Trades built in 400 levels | 266 | 275 to 331 (the share depends on the draw) |
| Trades asking for a part the player cannot trade | 5 of 266 | 0 of 275 (3 to 7 with no hint) |
| Visit member on the hearing committee | 10 of 10 samples | 5 of 10 samples |

Fit of the ten new samples (my judgment): member visit Good 6, Fair 4 (the four Fair ones are visits by a member from another committee); lobbyist trade Good 3, Fair 5, Poor 2 (before: Good 3, Fair 2, Poor 4). Remaining weak fits: Students United against "register master craftspeople as cultural assets", and Neighborhood Associations against "payment within sixty days on public contracts".

What the re-test shows is still open:

| Open | Detail |
|---|---|
| Committee match fell | Drawing from the whole party when fewer than three members sit on the committee gave variety but dropped the committee link in half the samples. A compromise would keep committee members about half the time |
| One lobbyist is a third of trades | The Chamber of Commerce loses on more parts than any other organization and has one representative. A second Chamber representative would need a new character, which is Cameron's to cast |
| The loser table is a draft | Each part's loser comes from its strongest policy tag through a table I wrote; a few results are still odd and Cameron should correct them in the Bill Components Loses column |

## Phase 3 content pass (2026-11-03)

Prompt 3 of `design/prompts/COMPONENT_REVISION_PROMPTS_2026-11-03.md`. All of it is draft writing for Cameron to correct.

### Summary

| Item | Before | After |
|---|---|---|
| Member questions | 24; Cost and Risk had 1 each | 30; every Reply Kind has at least 2 |
| Trade questions | 12 | 20, in three registers: aggrieved, bargaining, resigned |
| Answers per Reply Kind and style | 2 | 3 (60 new lines, MA157 to MA216) |
| Clock words in answers | 3 (MA39, MA79, MA100) | 0 |
| Member visits rated Good (10 samples) | 6 | 8 (target 8) |
| Lobbyist trades rated Good (10 samples) | 3 | 8 (target 6) |
| Chamber of Commerce lobbyist share | about 34% | 24% (most of this came from Phase 1's loser audit) |

New samples: `design/bench/visit_review_samples_phase3_2026-11-03.md`.

### What each member question asks

| ID | Kind | What the member really wants to know | Change |
|---|---|---|---|
| MV01 | Principle | Your reason for it. | |
| MV02 | Voters | Whether anyone at home benefits. | |
| MV03 | Voters | Whether it fits their mandate. | |
| MV04 | Criticism | Who is left out. | |
| MV05 | Alternative | Whether it deserves Assembly time. | |
| MV06 | Trust | Whether you would pay a price for it. | |
| MV07 | Cost | Who pays. | Rewritten: the old "how is it paid for" only fit spending parts. |
| MV08 | Alternative | Why now. | |
| MV09 | Criticism | Your answer to opponents. | |
| MV10 | Trust | Whether it is a favor to one group. | |
| MV11 | Party | How they would justify it to their party. | |
| MV12 | Risk | What fails first. | |
| MV13 | Evidence | Why it would work here. | |
| MV14 | Trust | Who is behind it. | |
| MV15 | Deal | What you would owe them. | |
| MV16 | Deal | Their price. | |
| MV17 | Trust | Whether you believe it. | |
| MV18 | Alternative | A smaller step. | |
| MV19 | Trust | Whether you will back them when their allies object. | Rewritten: the old line repeated MV06. |
| MV20 | Party | Why their party should take the risk. | |
| MV21 | Voters | A reason voters would thank them. | |
| MV22 | Evidence | Expert opinion. | |
| MV23 | Principle | Fairness to the next generation. | |
| MV24 | Trust | Whether you have the votes or are leaning on them. | Kind moved from Party to Trust: party answers missed the question. |
| MV25 | Cost | Which budget loses. | New |
| MV26 | Cost | The cost to their district. | New |
| MV27 | Risk | Who is hurt if it fails. | New |
| MV28 | Risk | Whether it will last. | New |
| MV29 | Criticism | Whether you can take press attacks. | New |
| MV30 | Principle | Whether it is the Assembly's business. | New |

### New trade questions

| ID | Kind | Register | Text |
|---|---|---|---|
| TQ13 | Alternative | bargaining | Could the plan to {component} be phased in, so our members can adjust? |
| TQ14 | Criticism | aggrieved | Nobody asked our members about the plan to {component}. Why were we not consulted? |
| TQ15 | Trust | resigned | We know the plan to {component} will pass. Will you remember who gave way? |
| TQ16 | Deal | bargaining | Soften the plan to {component} and we stay quiet. Is that a trade? |
| TQ17 | Risk | aggrieved | The plan to {component} hits our members hardest. Who answers for that? |
| TQ18 | Principle | aggrieved | Why should our members pay the price for the plan to {component}? |
| TQ19 | Trust | resigned | Your party courted us for years. How does the plan to {component} square with that? |
| TQ20 | Evidence | bargaining | Show us real numbers on the plan to {component}, and we may come around. |

No trade question uses the Party kind: those answers address the listener's party, which a lobbyist does not have.

### Answers

- The answer pool is shared by members and lobbyists, so the new Voters and Deal lines say "them" and "your top priority" rather than "your voters" and "your district". Party answers still say "your party", which is why no trade question uses that kind.
- Weak lines are written to sound reasonable in their own style. A Weak grade comes from the listener's taste, not from a careless line.

### Second read of the ten samples

| # | Member visit | Why | Lobbyist trade | Why |
|---|---|---|---|---|
| 1 | Good | Each question fits its part; the member sits on the hearing committee. | Good | Late supplier payment really does hurt the Chamber. |
| 2 | Good | | Good | Manufacturers named in recalls. |
| 3 | Good | One Trust answer is only loosely on point. | Good | |
| 4 | Good | | Good | Traditionalists dispute curriculum time. |
| 5 | Fair | MV24 drew Party answers (since moved to Trust). | Fair | The old TQ17 spoke of members going out of business (since rewritten). |
| 6 | Good | | Fair | "Costs us so much" overstates a directory of services. |
| 7 | Fair | MV24 again (since fixed). | Good | Import limits hurt traders. |
| 8 | Good | | Good | Faster customs means more imported fish. |
| 9 | Good | | Good | Private nursing homes lose pricing freedom. |
| 10 | Good | | Good | Developers lose valuable land. |

Totals: member visits Good 8, Fair 2; lobbyist trades Good 8, Fair 2. The two fixes in rows 5 and 7 were made after this read.

### Proposed, not added: reaction lines

The three `visit.react_*` and three `trade.react_*` lines per grade already vary enough. If Cameron wants more variety, two lines per grade would do it:

| Key (new) | Line |
|---|---|
| visit.react_strong_4 | {name} repeats your words back, as if testing how they sound. |
| visit.react_medium_4 | {name} tilts their head. Maybe. |
| visit.react_weak_4 | {name} checks their phone while you finish. |
| trade.react_strong_4 | {name} writes something down and underlines it. |
| trade.react_medium_4 | {name} says they will take it back to the members. |
| trade.react_weak_4 | {name} smiles politely, which is worse than arguing. |

### Proposed, not added: organization flavor for trades

One line each for how the ten lobbyist organizations would put the Deal and Protect asks. Using these needs a new column (organization-scoped trade lines), so this stops here for Cameron's decision.

| Org | Deal | Protect |
|---|---|---|
| Local Kōenkai (BO03) | Our supporters turn out at every election. Remember that when you write the next budget. | Do not take away what our members built in this district. |
| Mayors' Network (BO04) | Give the towns the money and the say, and the mayors will carry it home for you. | The towns run these services. Do not decide for us from Sapporo. |
| Chamber of Commerce (BO05) | Business can live with a lot, if it has time and a clear rule. | Every new rule is a cost our members pass on or lay off. |
| Neighborhood Associations (BO06) | Put residents in the room and you will find us easy to work with. | Our blocks were here before this plan and will be here after it. |
| Fisheries Cooperative (BO07) | Look after the harbors and the quota, and we will look after you. | The sea feeds this coast. Do not trade it away. |
| Labor Federation (BO09) | Write the protections in plainly and our members will back you. | Workers paid for the last reform. Not again. |
| Agricultural Cooperatives (BO10) | Keep the price steady and the paddies working, and you have the villages. | Farming families cannot absorb another shock. |
| Students United (BO11) | Give young people a real stake and we will be loud for you. | It is our generation that inherits this. |
| Family Network (BO12) | Put families first in the detail and we will say so publicly. | Parents are stretched thin already. |
| Our Traditional Society (BO15) | Respect what is old and we can talk about what is new. | Some things, once lost, are not rebuilt. |
