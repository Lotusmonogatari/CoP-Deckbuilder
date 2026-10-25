# Findings: slice11_3 (room questions c)

Saved from the reviewer's returned report (the reviewer could not write the file itself).

The Write tool refused to create /home/user/CoP-Deckbuilder/design/review/findings_slice11_3.md ("Subagents should return findings as text, not write report files"). Per the prompt, the full findings table follows here instead.

Rows read: 409 of 409 (S441 to S849). Counts: A = 14, B = 22, C = 21.

| ID | Field | Severity | Category | Problem | Suggested fix |
|---|---|---|---|---|---|
| S645 | question | A | grammar | Doubled word "instead instead". | "Why not a tax on the largest incomes instead of a consumption tax rise from 8 to 10 percent for pensions?" |
| S668, S671 | question | A | grammar | "instead of ... instead of" stacked. | "Why not an annual meeting instead of a standing Yezo-Japan commission on the Tsugaru Strait?" |
| S643 | question | B | logic | "a tax on the largest incomes instead" has nothing to be "instead" of. | "Would a tax on the largest incomes instead of a consumption tax rise protect everyone's interests better?" |
| S651 | question | A | grammar | "Why not devolving" is ungrammatical. | "Why not devolve one budget line as a trial instead of revenue and budget powers for the three prefectural assemblies?" |
| S754 | question | A | grammar | "Why not phasing" is ungrammatical. | "Why not phase tariffs down over a long period instead of lower tariffs with the European Union on dairy, wine, machinery and cars?" |
| S706 | question | A | grammar | "Is subsidies ... the real story". | "Are subsidies for firms that would come anyway the real story behind the Digital Economy Promotion Act?" |
| S790 | question | A | grammar | "Is gambling addiction and organized crime" (compound subject). | "Are gambling addiction and organized crime the real story behind the Integrated Resort Act?" |
| S635 | question | A | grammar | "What does grid links ... change". | "What do grid links and local wind and geothermal power change for turbines, power lines and blackout plans?" |
| S658, S660, S663 | question | A | grammar | "qualified candidates passed over" is missing "being"; S663 also has "candidates ... becomes". | S658 "...will not lead to qualified candidates being passed over?"; S660 "What in this bill stops it from leading to qualified candidates being passed over?"; S663 "What is our plan if qualified candidates being passed over becomes the story?" |
| S633, S776, S806 | question | B | grammar | Compound or plural subject with singular "becomes". | Use "become" ("...if exams that miss real-world skill become the story?"). |
| S598, S649 | question | B | grammar | Plural subject with "does not go far enough". | Change to "do not go far enough". |
| S720 | question | B | grammar | Missing comma after "wiretaps"; the descriptor runs into the verb. | "Supporters say the crime of planning serious organized crime, with wider wiretaps, does not go far enough. Do you agree?" |
| S583 | question | A | grammar | "in willing towns in this town" doubles "in". | "Who bears the cost of co-official status for Ainu in willing towns?" (drops the town tie; meaning narrows, designer to choose). |
| S614, S615, S617 | question | C | phrasing | "freight upgrades first, passengers later" is a run-on. | "Why not freight upgrades first and passengers later, instead of an earlier Sapporo extension of the Shinkansen?" (S615: "Would freight upgrades first and passengers later protect everyone's interests better?") |
| S684, S687 | question | C | phrasing | "grants for building safety only": "only" is ambiguous. | "Would grants limited to building safety protect everyone's interests better?" / "Why not grants limited to building safety instead of tax relief and restoration grants for temples and shrines?" |
| S692 | question | B | phrasing | "small projects paid for by the member's grant" is circular. | "What does an annual district grant for every Assembly member change for small local projects?" |
| S703 | question | B | logic | "Who bears the cost: tax revenue and local power supply?" Revenue and power supply do not bear costs (meaning shifts slightly). | "Who bears the cost if the Digital Economy Promotion Act strains tax revenue and local power supply?" |
| S601, S752, S792 | question | C | phrasing | "Who bears the cost: X?" is headline style, and S601 is loaded. | Optional: full sentences. |
| S729, S742 | question | B | phrasing | "How would we measure whether <long noun phrase> is happening?" is awkward. | S729 "How would we tell if power is being kept longer than the crisis lasts?"; S742 "How would we tell if the country is being drawn into a foreign conflict?" |
| S733, S737 | question | B | phrasing | "Is power kept longer than the crisis lasts the real story / the biggest danger" is hard to parse. | S733 "Is the real story behind the National Emergency Powers Act that power could be kept longer than the crisis lasts?"; S737 "Is the biggest danger in the National Emergency Powers Act that power could be kept longer than the crisis lasts?" |
| S718 | question | B | phrasing | "full price of the crime of planning..." prices a crime, not a law. | "What is the full price of enforcing the crime of planning serious organized crime, with wider wiretaps, and where does the money come from?" |
| S721, S798 | question | B | grammar | Descriptors with an internal comma lose their end ("...with wider wiretaps to the voters back home"). Same template defect touches S717, S789, S791, S793, S794. | S721 "...with wider wiretaps, to the voters back home?"; S798 "...with Tomakomai the leading site, to the voters back home?" Fix at template level. |
| S597, S650, S670, S693, S719 | question | C | phrasing | "Critics say it ..." uses "it" before the bill is named. | Name the bill first, e.g. "Critics say the Special Economic Zones Act carves out a second set of rules for the rich. Why should voters trust you on it?" |
| S616 | asker | A | logic | Our Traditional Society member says "My members care about commuters, freight shippers and tourist towns". | Cast a Commuter Committee or Mayors' Network asker, or reword to "People I speak with care about ...". |
| S644 | asker | A | logic | Fisheries Cooperative member speaks for "pensioners and elder care". | Cast a Care and Welfare Council asker, or reword. |
| S665 | asker | B | logic | Chamber of Commerce lobbyist speaks for "ferry operators, fishers and border towns". | Cast a Fisheries Cooperative or Commuter Committee asker, or reword. |
| S683 | asker | A | logic | Agricultural Cooperative member speaks for "temples, shrines and festival towns". | Cast a Buddhist Temples or Shrine Association asker, or reword. |
| S788 | asker | A | logic | Fisheries Cooperative member speaks for "construction workers, hotels and the host town". | Cast a Labor Federation, Small Business or Mayors' Network asker, or reword. |
| S605, S701 | asker | C | logic | Mayors' Network rep speaks for "new employers and the workers they hire" (closer to Chamber of Commerce). | Optional: reassign S605 to the Chamber of Commerce lobbyist (OP118). |
| S615 | asker | C | logic | A Student fills a Lobbyist Meeting slot with no organization role. | Prefer askers with an org role in ST138. |
| S568 | grades | B | logic | "Who is the establishment protecting, and who is it ignoring?" has Emo=W; the ignored is classic Emotional ground. | Emo=S, Dup=M. |
| S569 | grades | A | logic | "Will you stand with the members on the street...?" has four S (Ear, Dat, Div, Dup) and Emo=W; a solidarity question should reward Emotional. | Ear=S, Emo=S, App=M, Dat=W, Div=S, Dup=W. |
| S572 | grades | B | logic | "...members who think the party has lost its nerve?" has Ear=W and Emo=W with Dat=S, Div=S, Dup=S. | Ear=S, Emo=M, App=M, Dat=M, Div=S, Dup=W. |
| S566, S567, S570 | grades | B | logic | Ear=W on sincere values questions. | Raise Earnest to M. |
| S573 | grades | B | logic | "Why should this committee choose you over a safer candidate?" has Ear=W, Dat=S, Dup=S. | Ear=M, Dup=M. |
| S574 | grades | B | logic | "How do you show a local record...?" has Dat=M and Div=S. | Dat=S, Div=W, Emo=M. |
| S582 | grades | B | logic | "What has your work done for ordinary voters, beyond speeches?" has Dat=W and Ear=W. | Ear=M, Dat=S, Emo=M. |
| S581 | grades | C | logic | "How do you win both the party base and the undecided?" has Dat=W. | Dat=M. |
| S579 | grades | B | logic | "What will you do if the committee picks someone else?" has Dat=S, Dup=S, Ear=M. | Ear=S, Dat=W. |
| S573, S577, S579 | stage fit | B | fitness | Says "this committee" or "the committee", but the listed stage is a Party Caucus (ST03 ... +48). Only valid if the Candidate Selection Committee room is among the truncated stages. | Verify the stage list; otherwise say "the party" or bind to the Candidate Selection stage. |
| S576 | pleases | C | coherence | Candidate finances question pleases Financial Industry Association, a thin link. | Drop it or swap for Taxpayers' Alliance. |
| S441-S564 (124 templated rows) | stages/asker | C | fitness | "asked by None | stages (blank)" on all 31 bills x 4 questions. Fine if this is the bill-wide fallback pool; otherwise they never show. | Confirm intent. |
| S444, S448, S452, S456, S460, S464, S468, S472, S476, S480, S484, S488, S492, S496, S500, S504, S508, S512, S516, S520, S524, S528, S532, S536, S540, S544, S548, S552, S556, S560, S564 | grades | B | logic | "Backers say X does not go far enough. Where do you stand?" has Ear=W and Dat=W on every bill. A stand question is Earnest ground. | Ear=M (or S), keep Emo=S, Dup=S. |
| S441-S564 | grades | B | coherence | All four templated questions carry identical grades and pleases/displeases for every bill, so topics play identically. | Vary at least the cost question on non-fiscal bills (S473, S497, S521, S561). |
| S444 ... S564 (the "Backers say" rows above) | question | C | phrasing | "Backers say" here, "Supporters say" in S598, S649, S669, S694, S720; also collides with the proposed Donors-to-Backers rename. | "Supporters say" throughout. |
| S497-S500, S521-S524 | pleases | C | coherence | One pleased org, no displeased org, so no trade-off. | Designer decision. |
| S557-S560 | pleases | C | coherence | Mayors' Network (directly affected by mergers) is absent. | Consider adding to displeases. |
| S561-S564 | pleases | C | coherence | Party Leadership Selection Act pleases Students United, a thin link. | Replace with Party Activists or Party Faction. |
| S657-S664 | pleases | C | coherence | Candidate Gender Parity pleases only Family Network, a thin link, with no displeased org. | Add a relevant org after designer review. |
| S675-S680 | pleases | C | coherence | Judicial Appointments Commission pleases Consumer Advocacy Network, a thin link. | Drop it, or add Members of Parliament to displeases. |
| S705, S734, S789 | grades | C | logic | "Do you really have the votes...?" has Dat=W; a vote count is Data Driven. | Dat=M. |
| S587, S621, S627, S642, S655, S679, S700, S714, S721, S727, S740, S751, S758, S769, S798, S815, S828, S834 | grades | C | logic | "How will we explain X to the voters back home?" has Emo=W, Dat=S, Dup=S. | Emo=M. |
| S600/S603/S608; S599/S604/S607; S613/S618; S614/S617; S667/S672; S668/S671; S708/S711; S707/S712; S732/S735/S739; S731/S736/S738; S744/S749; S745/S748; S762/S767; S763/S766; S807/S811; S808/S810 | question | B | phrasing | Word-for-word duplicates across sibling stages of one bill, so one run can meet the same question two or three times. | Reword one of each group, or confirm they never share a level run. |
| S734 | question | C | coherence | "lets the Prime Minister govern by decree": "Prime Minister" appears nowhere else in this slice. Possible canon invention. | Confirm against bill data and use the data's own executive title. |
| S666, S667, S668, S671, S672 | question | C | grammar | "Yezo-Japan" uses a hyphen; other pairings use an en dash ("Yezo–EU", "Yezo–US"). | "Yezo–Japan". |
| S848 | question | C | phrasing | Two questions in one sentence. | "Should reservists train more often, if employers' costs are covered?" (meaning shifts slightly) |
| S565, S567, S572 | question | C | coherence | Three near-synonym "purity" questions in one caucus. | Give S572 a different angle, e.g. "...members who think the party has stopped standing for anything?" |

ROWS READ: 409 of 409

Biggest patterns:
1. Template-built sentences produce grammar slips whenever a bill descriptor is plural, compound or contains a comma ("instead instead", "Why not devolving", "Is subsidies", missing "being"); fix at the template level.
2. Lobbyist-meeting askers do not match the "My members care about ..." lines (S616, S644, S665, S683, S788), and identical questions repeat across sibling stages of one bill.
3. Grades are templated. "Backers say ... where do you stand?" grades Earnest weak on all 31 bills, and several candidate-selection and purity-caucus rows have grades that run against their wording (S569, S572, S574, S582, S579).

Findings file path (not created, Write refused): /home/user/CoP-Deckbuilder/design/review/findings_slice11_3.md
Rows read: 409 of 409. Counts: A = 14, B = 22, C = 21.
