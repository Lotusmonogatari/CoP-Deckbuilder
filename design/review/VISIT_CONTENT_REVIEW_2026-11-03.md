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
