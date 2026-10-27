# Batch 3 draft: rooms and levels for the twenty new bills (2026-10-13)

Draft workbook: `design/drafts/CoP_Batch3_Rooms_Draft_2026-10-13.xlsx` (the master after Batch 2 plus this batch). **The master workbook is unchanged.** Everything is a draft for Cameron to rewrite. To adopt: copy it over `design/Game_Workbook.xlsx` and run `python3 tools/export_data.py`.

## Executive summary

| | |
|---|---|
| **What it is** | One level per new bill (LV63-LV82, BI31-BI50), 69 new rooms (ST32-ST100) built from the existing room families, and the questions, cues and transitions around them. After this, all 50 bills are playable. |
| **Does it fit the scheme?** | **Yes.** Export is clean, all 1,046 game tests pass, `tools/verify.sh` is green (including the transition click test), the scored rubric is 66/66, and no bot trial crashed or stalled. |
| **Three-times rule** | Every new room clears 3x on questions, player cues, opponent cues and transitions. The only measure short is **people** in 11 rooms, the same three canon gaps already known (see below). |
| **Mechanics** | None changed. Rooms copy a base room's numbers (bigger bills +2 on a 100-point win mark, smaller bills -2, same for the Policy Study scaled by 1). |

## What was drafted

| Part | Count |
|---|---|
| New levels | 20 (LV63-LV82). Each: Office Hours, 2-3 topic rooms, a topic Party Caucus, then the bill vote. One-time, tiered 0/1/2 by the bill's size, unlock costs copied from LV31 / LV36 / LV49 |
| New rooms | 69 (ST32-ST100): 20 Party Caucus, 15 Hearing, 9 Town Hall, 9 Press Conference, 6 Policy Study, 6 TV Debate, 4 Lobbyist Meeting. No Media Ambush (it cannot be balanced; see your earlier call) |
| Stage Questions | 120 topic questions (6 per bill) in 3 graded themes per bill; each room asks only as many as leave its general pool in play (Press 3, Lobbyist 4, Policy Study and Media 5, Town Hall and Hearing 6) |
| Question Themes | 60 new rows (3 per bill), organisations taken from that bill's own Law Effects (benefit theme pleases the winners; cost theme pleases the sceptics; fairness theme pleases winners and sets back the main loser) |
| Player Cues | 360 topic rows (6 suits x attack / gain / block per bill, 5 lines each, templated with the bill's topic phrase); plus the existing family cue rows now list the new rooms |
| Transitions | Show Transition on for all 69; 69 stage backgrounds; 207 room-scoped exchanges (3 cast members per room, written by room type) |
| Seating | Each new room seats exactly the people its base room seats (hearings: that committee's members only) |
| Level Intro Thoughts | 20, one per bill |
| Affinity | 69 new columns, two up / two down / two neutral, ranked per bill by which suits suit the topic |

## Levels

| Level | Bill | Tier | Rooms (after Office Hours, before the vote) |
|---|---|---|---|
| LV63 | Wilderness and Wildlife Protection Act (BI31) | 1 | ST32 Press Conference, ST33 Hearing (Environment), ST34 Town Hall, ST35 Party Caucus |
| LV64 | Rural Hospital Network Act (BI32) | 2 | ST36 Town Hall, ST37 Hearing (Government Administration), ST38 Policy Study, ST39 Party Caucus |
| LV65 | Digital Identity Card Act (BI33) | 2 | ST40 Policy Study, ST41 TV Debate, ST42 Party Caucus |
| LV66 | Public Broadcasting Independence Act (BI34) | 1 | ST43 Press Conference, ST44 TV Debate, ST45 Party Caucus |
| LV67 | Political Donation Transparency Act (BI35) | 2 | ST46 Press Conference, ST47 Hearing (Government Administration), ST48 Lobbyist Meeting, ST49 Party Caucus |
| LV68 | Corporate Tax Reduction Act (BI36) | 2 | ST50 Policy Study, ST51 Hearing (Finance), ST52 Party Caucus |
| LV69 | Carbon Levy Act (BI37) | 2 | ST53 Town Hall, ST54 Hearing (Environment), ST55 Press Conference, ST56 Party Caucus |
| LV70 | Fisheries Quota Modernization Act (BI38) | 1 | ST57 Hearing (Agriculture), ST58 Town Hall, ST59 Party Caucus |
| LV71 | Shipbuilding and Defense Industry Act (BI39) | 2 | ST60 Hearing (War), ST61 Town Hall, ST62 Party Caucus |
| LV72 | Constitutional Review Commission Act (BI40) | 1 | ST63 Hearing (National Assembly), ST64 Press Conference, ST65 Party Caucus |
| LV73 | Japan Customs and Border Cooperation Act (BI41) | 1 | ST66 Hearing (Foreign Affairs), ST67 Lobbyist Meeting, ST68 Party Caucus |
| LV74 | Chishima Resource Development Agreement Act (BI42) | 1 | ST69 Hearing (Foreign Affairs), ST70 Press Conference, ST71 Lobbyist Meeting, ST72 Party Caucus |
| LV75 | Yezo–China Trade Normalization Act (BI43) | 2 | ST73 TV Debate, ST74 Hearing (Foreign Affairs), ST75 Party Caucus |
| LV76 | Farm Succession Support Act (BI44) | 1 | ST76 Town Hall, ST77 Hearing (Agriculture), ST78 Party Caucus |
| LV77 | University Autonomy and Research Funding Act (BI45) | 1 | ST79 Policy Study, ST80 Hearing (Government Administration), ST81 Party Caucus |
| LV78 | Workplace Equality Act (BI46) | 2 | ST82 Town Hall, ST83 Press Conference, ST84 TV Debate, ST85 Party Caucus |
| LV79 | Parental Leave and Childcare Act (BI47) | 2 | ST86 Town Hall, ST87 Policy Study, ST88 Lobbyist Meeting, ST89 Party Caucus |
| LV80 | Public Safety Surveillance Act (BI48) | 2 | ST90 Hearing (Government Administration), ST91 TV Debate, ST92 Press Conference, ST93 Party Caucus |
| LV81 | Local Government Mergers Act (BI49) | 1 | ST94 Town Hall, ST95 Hearing (Government Administration), ST96 Policy Study, ST97 Party Caucus |
| LV82 | Party Leadership Selection Act (BI50) | 0 | ST98 TV Debate, ST99 Press Conference, ST100 Party Caucus |

## The three-times rule

`python3 tools/content_depth.py` on the draft: **every new room is at 3x or better on questions, player cues, opponent cues and transitions.** Short measures (people only):

| Rooms | New characters needed |
|---|---|
| Town Halls (ST05 family, 9 new rooms) | 1 more constituent |
| Hearings on Government Administration, Finance, War, Construction (ST51, ST60 and the older ST11 / ST15 / ST16) | 1 to 3 more members each |

Total measures below 3x: 20 in the draft, against 9 before it. Eleven are new rooms inheriting the same canon gap their base room already has.

## Bot trials (PC02, 20 fights per room; a well-equipped player)

| Room kind | Result |
|---|---|
| Press, Town Hall, Policy Study, Hearing, Lobbyist, TV Debate | 18 to 20 wins of 20 almost everywhere (ST35, ST48, ST67, ST83 and a few Town Halls and Policy Studies sit at 10 to 19). In family with their base rooms |
| Party Caucus (20 rooms) | 22% to 100% across three other protagonists (ST03 itself is 83% to 100% for them and 35% for PC02). The weakest are ST93 (22%), ST39 (28%), ST62 (33%), ST56 and ST65 (38%). They depend heavily on whether the caucus affinity favours the deck's suits (ST03 gives Divisive 1.5). Cameron's call whether to nudge those |

## What writing it showed

| # | Finding | Action |
|---|---|---|
| 1 | A Town Hall copied from ST05 asked a pool of only 6 until its Question Pool cell said `town_hall` (ST05's blank cell relies on a built-in default) | Every new Town Hall row sets it; the guide already warned of this |
| 2 | Topic Player Cues replace a family's card Flavor Text lines (Policy Study, Press, Lobbyist and Media have no cue rows), so 3 lines per cue left Policy Study at 2x | Topic rows carry 5 lines each; every room is now above 3x |
| 3 | Question rows crowd out the general pool if they number as many as the room asks (a 6-question Press Conference would ask only topic questions) | Each room lists at most 3 to 6 of a bill's six questions, rotated by bill |
| 4 | TV Debate and Party Caucus ask no questions, so listing them under Stage Questions would turn questions on | Left off; topic voice comes through their cues and transitions |

## Needs your call

| Question | Why it matters |
|---|---|
| **Adopt the batch?** | Then it is playable, README counts refresh to 100 stages, 82 levels |
| **Topic cues are templated** (same five sentence shapes per suit and verb, with the topic phrase filled in) | Quick to write, plain to read; rewrite any you want in the Player Cues tab |
| **Weak caucus rooms** | ST93, ST39, ST62, ST56, ST65 are the hardest for the bot; leave or retune |
| **8 new characters** | Names and parties are yours; 11 new rooms and 9 old ones wait on them |
| **Japanese names** for 69 rooms are drafts | Check the Japanese |
