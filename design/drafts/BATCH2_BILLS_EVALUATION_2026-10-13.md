# Batch 2 draft: twenty new bills (BI31-BI50)

Draft workbook: `design/drafts/CoP_Batch2_Bills_Draft_2026-10-13.xlsx` (the adopted master plus the bills; the master is unchanged). Everything here is a draft for Cameron to rewrite. Written 2026-10-13.

## Executive summary

| | |
|---|---|
| **What it is** | 20 new bills, taking the total to 50. Each has its bill row, six party positions with a leader's line each, a Vote Influence Cue for the one flip that can happen, and a passed and a failed Law Effects row. |
| **How the positions were made** | Each bill is tagged with the dimensions it touches (taxation, civil liberties, rural focus and so on) and a direction. A party's lean is the sum of tag x its **salience** for that dimension, from `design/reference/party_values.tsv`. A strong lean takes a side; a weak one is Neutral. Seat splits follow the shapes in the 30 existing bills. |
| **Does it fit?** | Yes. The export is clean, GUT passes (1,044), the rubric passes 66 / 66 with all 50 bills, every chamber is 101 seats, and 10 of the 20 pass by default (28 of 50 overall, against 18 of 30 before). |
| **Not yet playable** | No level names these bills, so the export warns that 20 bills are named by no level. The rooms come next, and these bills say what makes each one unique. |

## The twenty bills

| Bill | Default | Yes / No / Abst. | Stance (S supportive, O opposed, N neutral) | Tier | Room ideas it suggests |
|---|---|---|---|---|---|
| BI31 Wilderness and Wildlife Protection Act | Fails | 36 / 58 / 7 | BUS YHPN FPO FPIN KJTO CIO | 3 | Logging town hall; wilderness hearing (Environment); ranger-station press conference |
| BI32 Rural Hospital Network Act | Passes | 52 / 33 / 16 | BUN YHPS FPS FPIS KJTN CIO | 5 | Rural clinic town hall; hospital funding hearing (Finance); medical lobbyist meeting |
| BI33 Digital Identity Card Act | Fails | 24 / 49 / 28 | BUN YHPN FPN FPIN KJTO CIN | 5 | Privacy press conference; identity-card policy study; TV debate on convenience vs surveillance |
| BI34 Public Broadcasting Independence Act | Fails | 44 / 32 / 25 | BUN YHPN FPS FPIN KJTN CIO | 3 | Broadcaster independence hearing (Government Administration); newsroom media ambush |
| BI35 Political Donation Transparency Act | Fails | 25 / 61 / 15 | BUN YHPN FPO FPIO KJTO CIO | 5 | Fundraising media ambush; donor lobbyist meeting; ethics hearing |
| BI36 Corporate Tax Reduction Act | Passes | 56 / 25 / 20 | BUN YHPO FPN FPIN KJTS CIS | 5 | Business lobbyist meeting; local-budget town hall; finance hearing |
| BI37 Carbon Levy Act | Fails | 36 / 53 / 12 | BUS YHPS FPN FPIN KJTO CIO | 5 | Farmers' town hall on fuel costs; carbon-price policy study; industry lobbyist meeting |
| BI38 Fisheries Quota Modernization Act | Passes | 60 / 35 / 6 | BUS YHPS FPS FPIS KJTO CIN | 3 | Harbour town hall; quota hearing (Agriculture); fishers' lobbyist meeting |
| BI39 Shipbuilding and Defense Industry Act | Passes | 55 / 34 / 12 | BUO YHPN FPS FPIN KJTS CIS | 5 | Shipyard town hall; defense hearing (War); procurement media ambush |
| BI40 Constitutional Review Commission Act | Passes | 56 / 27 / 18 | BUN YHPN FPS FPIN KJTS CIN | 3 | Constitutional commission hearing (National Assembly); TV debate on amendments |
| BI41 Japan Customs and Border Cooperation Act | Fails | 47 / 33 / 21 | BUS YHPO FPN FPIN KJTN CIS | 3 | Customs-data policy study; border-town hall; Japan relations press conference |
| BI42 Chishima Resource Development Agreement Act | Passes | 55 / 29 / 17 | BUS YHPN FPN FPIN KJTS CIS | 3 | Island residents' town hall; resource hearing (Foreign Affairs); fishers' lobbyist meeting |
| BI43 Yezo–China Trade Normalization Act | Fails | 38 / 39 / 24 | BUN YHPN FPN FPIN KJTS CIO | 5 | Trade lobbyist meeting; farmers' town hall; import-price press conference |
| BI44 Farm Succession Support Act | Passes | 67 / 29 / 5 | BUS YHPS FPS FPIS KJTO CIN | 3 | Young farmers' town hall; succession hearing (Agriculture); co-op lobbyist meeting |
| BI45 University Autonomy and Research Funding Act | Passes | 70 / 29 / 2 | BUS YHPS FPS FPIS KJTS CIO | 3 | Campus town hall; research-funding policy study; finance hearing |
| BI46 Workplace Equality Act | Passes | 66 / 35 / 0 | BUS YHPS FPS FPIS KJTO CIO | 5 | Workers' town hall; employers' lobbyist meeting; equality hearing (Ethics) |
| BI47 Parental Leave and Childcare Act | Passes | 61 / 39 / 1 | BUS YHPS FPS FPIS KJTO CIO | 5 | Parents' town hall; childcare policy study; employers' lobbyist meeting |
| BI48 Public Safety Surveillance Act | Fails | 26 / 47 / 28 | BUN YHPN FPN FPIN KJTO CIN | 5 | Civil-liberties TV debate; transport-hub town hall; policing hearing (Ethics) |
| BI49 Local Government Mergers Act | Fails | 26 / 55 / 20 | BUN YHPO FPO FPIO KJTN CIN | 3 | Mayors' town hall; local-services policy study; administration hearing |
| BI50 Party Leadership Selection Act | Fails | 32 / 49 / 20 | BUN YHPS FPN FPIN KJTO CIO | 1 | Party-room caucus on leadership; members' ballot press conference; steering committee |

## Fit against the scheme

| Check | Result |
|---|---|
| Export ends "No errors" | Pass (the only new warnings are the 20 bills not yet named by a level) |
| Seat splits add up to each party's seats; chamber is 101 | Pass (checked as built, and by the rubric) |
| Default outcomes | 10 of 20 pass; the yes totals run 24 to 67 |
| Influence swing | A full-strength player flips 32-34 of the 100 yes/no votes per protagonist (it was 23-24 of 60) |
| Rubric (`tools/rubric_playtest.gd`) | 66 / 66, now running over all 50 bills (some of its labels still say "30 bills") |
| Cue lines | 9 words or fewer, in each party's voice, no names |
| Law Effects | Every row names existing organisations; winners +3 / +2, losers -2 on a pass, reversed at 1 on a fail |

## Things to know

| Item | Detail |
|---|---|
| Directions are my reading | The values file says how much a party cares and which way, but not what "higher Leadership Interest" or "Clientelism" means for a given bill. Each tag's direction is a draft judgement, so a bill's default result moves if you disagree. |
| Similar coalitions | BI44-BI47 (farm succession, university, workplace equality, parental leave) have close to the same supporters. They pass comfortably. Say if you want a harder one. |
| Far-off bills | BI33 (digital ID), BI48 (surveillance), BI49 (mergers) and BI35 (donations) fail by a wide margin; the others are within reach of the influence swing. |
| Vote Tally & Swing tab | Not extended to the new bills (it is a hand-check tab and not exported). |
| Names and topics | Bill names and descriptions, the cue lines, and the Law Effects pairings are drafts. Nothing new is canon until you say. |

## What to decide next

Adopt these 20 bills into the master so levels can be built around them, then draft the rooms. Each bill row above lists the room kinds it suggests.
