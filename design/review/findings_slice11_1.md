# Findings: slice11_1 (room questions a)

Saved from the reviewer's returned report (the reviewer could not write the file itself).

Findings file path: /home/user/CoP-Deckbuilder/design/review/findings_slice11_1.md was NOT created. The Write tool refused, so the full findings table is below, as the prompt instructs.

Rows read: 409 of 409.
Counts: A=8, B=49, C=24 (81 finding rows; each row may list several IDs).

| ID | Field | Severity | Category | Problem | Suggested fix |
|---|---|---|---|---|---|
| L93 | pleases/displeases | A | logic | National Media is in both lists. | pleases=['Members of Parliament'], displeases=['National Media','Consumer Advocacy Network'] |
| L96 | pleases/displeases | A | logic | Urban Neighborhood Alliance is in both lists. | pleases=['Shrine Association'], displeases=['Students United','Urban Neighborhood Alliance'] |
| B31, B33 | pleases/displeases | A | logic | Taxpayers' Alliance is in both lists. | Remove Taxpayers' Alliance from pleases (pleases=['Agricultural Cooperatives']). |
| B40 | pleases/displeases | A | logic | Chamber of Commerce is in both lists; other craft rows displease it. | pleases=['Yezo Artisans Guild'], displeases=['Innovation Society','Chamber of Commerce'] |
| B49 | pleases/displeases | A | logic | Taxpayers' Alliance is in both lists; other care rows displease it. | pleases=['Care and Welfare Council'] |
| B50 | pleases/displeases | A | logic | Taxpayers' Alliance is in both lists. A cost-saving question pleases it, so keep it in pleases only (changes meaning vs B49). | displeases=['Financial Industry Association'] |
| B58 | pleases/displeases | A | logic | Financial Industry Association is in both lists. | pleases=['Rural Revitalization Council'] |
| L82, L88, L94, L103, L67, L100, L79, L85, L84, L106 | asker | A | coherence | A lobbyist says "Our union/guild/association/foundation/platform/alliance/network..." but the asker is the wrong kind of person: L82 "Our union" asked by a Chamber lobbyist; L88 "Our guild" by a Student; L94 "Our association...old trees" by the Mayors' Network rep; L103 "Our foundation" by a Neighborhood member; L67 "Our platform" by a Labor member; L100 "Our alliance" by an agri co-op member; L79 by a Neighborhood member; L85 by a Fisheries member; L84 by an agri co-op member; L106 "Our council" by a Chamber lobbyist. | Assign an asker whose organization matches (Shrine Association member for L94, Ainu Language and Culture Foundation member for L103, Students United member for L82, Artisans Guild member for L88, Family Network member for L85) or drop "our". The same rotation mismatch affects L07, L23, L55, L66, L73, L74, L77, L81, L89, L90 (B). |
| A16, A33 | question | B | phrasing | Near-identical ("Will you resign if this fails?" / "...goes wrong?"), same pool; Q16 covers it too. | Drop A33 or reword: "Who in your party takes the blame if this goes wrong?" |
| A09, A28, A29 | question | B | phrasing | Three Evasion questions in a 33-row pool; A09 and A28 are the same question. | Replace A28: "Why do your aides block every reporter's call?" |
| A05, A20 | question | B | phrasing | Same Credibility angle, near-same grades and orgs. | A20: "What have you actually accomplished to earn a hearing?" |
| A07, A32 | question | B | phrasing | Same Competence attack. | A32: "Which clause of this bill would you change first?" |
| A08, A14 | question | B | phrasing | Both Isolation, identical orgs, similar wording. | A14: "Which of your colleagues will still stand next to you tomorrow?" |
| A02, A05, A10, A13, A17, A18, A20 | grades | B | logic | Four of six styles are S, so card choice stops mattering. | Drop 1-2 to M per row: A10 Div=M, Dup=M; A02 Ear=M, Dup=M; A05/A20 Dup=M; A13 Ear=M; A17 Div=M; A18 Dup=M. |
| A03, A12, A04 | pleases/displeases | B | logic | A03 and A12 please Financial Industry/Chamber and displease Consumer/Labor; A04 (same cronyism angle) does the reverse. | Give A03/A12 the A04 pattern: pleases ['National Media','Consumer Advocacy Network'], displeases ['Financial Industry Association','Party Headquarters']. Changes meaning; Cameron to confirm. |
| A16, A33 | pleases/displeases | B | logic | Care and Welfare Council displeased by a resignation question; no link. | displeases=['Party Headquarters'] only. |
| Q16, Q18, S05, S06, B15, T58, T59, L45, L46 | displeases | B | logic | Care and Welfare Council displeased by accountability/transparency/party-funding questions; no theme link. | Remove it; displeases=['Party Headquarters'] (L45 add 'Chamber of Commerce'). |
| Q11, Q12 | pleases/displeases | B | logic | Opposite questions ("too far" / "too timid") give identical orgs (Labor pleased, Chamber displeased). | Q11: pleases ['Chamber of Commerce'], displeases ['Labor Federation']. Changes meaning. |
| Q02, Q04, Q06 | pleases/displeases | B | repetition | Three rows with the same HQ pleased / Faction displeased. | Q04 pleases ['Members of Parliament']; Q06 pleases ['Party Headquarters','Party Activists']. |
| Q03, Q14 | pleases/displeases | C | repetition | Press pool leans on one HQ/Faction pair. | No change needed; vary later. |
| Q09, T03, T14, T19, T30 | pleases/displeases | B | logic | Loyalty rows all use HQ + Veterans' Association pleased and Faction + Students United displeased; Veterans/Students have no link to "keep your promises". | Use Party HQ/Faction only; e.g. T19 pleases ['Local Kōenkai'], displeases []. |
| T03, T14 | question | B | phrasing | "Who are you really listening to?" and "Are you on our side or theirs?" ask the same thing. | T14: "When party leaders and our town disagree, whose side do you take?" |
| T02, T12, T16, Q17 | question | B | phrasing | Four trust questions, same orgs; T02 and T16 overlap. | T16: "What would make you different from the politicians who let us down?" |
| T02, T12 | grades | B | logic | Earnest=W on trust questions while T16/Q17 grade it S. | T02 Ear=M; T12 Ear=M. |
| T05, T08 | question | B | phrasing | Same neglect question, same four orgs. | T08: "When did you last visit the villages past the highway?" |
| T02, T05, T08, T12, T13, T16, T18, T21, T22, T23, T25, T29, T61 | pleases/displeases | B | logic | Generic town-hall questions carry Ainu, Buddhist, Our Traditional Society, Rural, Fisheries or HQ effects unsupported by the wording (T23 "lobbyists and journalists", T29 "broadband", T13 "listen if we disagree"). | Keep only supported orgs: T29 pleases ['Rural Revitalization Council','Innovation Society']; T23 pleases ['Local Kōenkai']; T13 pleases ['Local Kōenkai'], displeases []; drop Buddhist/Ainu/OTS elsewhere unless named. |
| T21, T22 | question | B | phrasing | Near-duplicates; "uplift our voices" is stock phrasing. | T22: "How do you make our town heard in the National Assembly?" |
| T04 | grades | B | logic | Numbers question ("What will this cost people like me?") has Dat=W, App=S. | Dat=S, App=M. |
| T36, T37 | grades | B | logic | "Where does the money come from?" has Dat=W; L24 grades the same Dat=S. | Dat=S for both; T36 Ear=M, T37 App=M. |
| T37, L24 | question | B | fitness | "If the food tax is suspended/cut..." has no antecedent if drawn without T36/L23. | T37: "If the tax on food is suspended, what gets cut or paid for another way?" L24: "If the consumption tax on food is cut, who pays for it?" |
| T38 | grades | C | logic | "How much more debt" asks for a figure but Dat=M, Emo=S; S25 grades Dat=S. | Dat=S, Emo=M. |
| T06 | grades | B | logic | "Are you going to fight for us?" has Emo=W, Dat=S. | Swap: Emo=S, Dat=W. |
| T30 | question | C | coherence | Names "Prime Minister Rono" (OP10 Aki Rono exists in data) in a reusable generic pool; Dat=S odd. | "Do you support the Prime Minister?" Dat=M. |
| T32 | question | B | coherence | Aliens-in-the-trees line breaks tone; pleases National Media / displeases Party HQ unrelated; App=S, Dat=S odd. | If not deliberate comedy, replace with "Strangers have been seen near our farms at night. Will you send more police?" and neutral orgs. Flag to Cameron. |
| T33 | question | C | phrasing | "prohibit the annoying use of my local parks" awkward. | "Children are noisy in my neighborhood park. Can you push a bill to restrict use of local parks?" |
| T26 | question | C | phrasing | "curtail tourist behavior" stiff. | "What are you doing about badly behaved tourists?" |
| T09, T27 | pleases/displeases | B | logic | Identical orgs; visas for the service industry do not obviously help Fisheries/Agricultural/Artisans. | T27: pleases ['Chamber of Commerce',"Small Business Owners' Association"], displeases ['Our Traditional Society']. Changes meaning. |
| T48, T49 | pleases/displeases | B | logic | T48 ("without leaving newcomers on their own") pleases Our Traditional Society and displeases Students United, the reverse of the wording; T49 pleases Ainu Language and Culture Foundation unrelated. | T48: pleases ['Students United','Labor Federation'], displeases ['Our Traditional Society']. T49: drop Ainu Language and Culture Foundation. |
| T34, T35, T36, T37, T64, T65, T72, T73, L23, L24, L51, L52, L60, Q33 | displeases | B | logic | Members of Parliament displeased by cost-of-living, tax, housing, tourism questions that do not touch the institution. | Remove; keep for institution rows (S13-S15, T121-T124, L91-L93). |
| T41, T54, T55 | displeases | C | logic | Yezo Artisans Guild displeased by drones, reactors, renewables; no link. | Remove. |
| T20 | question/asker | B | coherence | "Why should young people care about this?" asked by an Agricultural Cooperative Member; "this" has no referent. | "Why should young people care about politics at all?" with a student asker. |
| T111 | asker | B | coherence | Young-people line asked by the Kōenkai Association President; near-duplicate of T103. | Student asker; "Who will pay for the choices older voters made when I am their age?" |
| T92, T117 | question | B | phrasing | Both "My family has made [lacquerware] ... six generations." | T92: "Fewer people buy handmade goods every year. Will our craft survive?" |
| T84, T100 | question | B | phrasing | Both are "no lift/stairs at the station". | Reword or remove one. |
| T107, T114, T132, T81, T97, T112 | asker | B | coherence | First-person line does not fit asker: Student says "My child's school is closing" (T114), "My children left for the city" (T107), "I am old and alone" (T132), "Prices at the market fall..." (T81); agri member says "Fuel prices are killing our boats" (T97); Neighborhood member says "My degree is..." (T112). | Assign askers whose profile fits. |
| L05, L19 | question | B | phrasing | "Off the record" / "between us": same ask, same orgs. | L19: "Will this stay between you and me?" or a different Secrecy angle. |
| L13, L15 | question | B | phrasing | Two Inducement rows. | L15: "What would it take for our members to earn a meeting after hours?" or remove one. |
| L03, L12 | question | B | phrasing | Both Drafting, same orgs. | L12: "Would you accept our staff's draft wording?" |
| L61, L62 | question | B | phrasing | Consecutive Ainu preferential-cost rows, identical orgs; L62 "Our members" asked by a Neighborhood member. | L62: "People worry preferential rights will come out of their budgets. Will they?" |
| Q21, Q22, T74, A21, B21, L61 | question | B | phrasing | Six Ainu preferential/fairness questions with the same org sets; Q21/Q22 are in the same pool and near-duplicate. | Q22: "What do you say to a neighbor who feels the Ainu get something they do not?" |
| L01, L07, L08, L09, L10, L11, L17, L18 | pleases/displeases | B | logic | Generic lobbyist questions carry unrelated orgs (L18 "our industry" pleases Neighborhood Associations; L07 pleases Neighborhood/Care, displeases Taxpayers'; L08 and L01 pleases Agricultural/Rural/Financial/Activists). | L18: pleases ['Chamber of Commerce'], displeases []. L07: pleases ['Party Activists'], displeases []. Others: empty or tie to HQ/Faction/Chamber/Labor. |
| L02, L26 | asker/orgs | B | coherence | L26 "Bond markets are nervous" asked by a Labor Federation member; L02 asked by a Labor member displeases Labor Federation. | Reassign L26 to the Chamber lobbyist; L02 pleases ['Labor Federation','Consumer Advocacy Network'] or change asker. |
| L35 | pleases/displeases | B | logic | "Our industry can't find workers. Will you open the door wider?" pleases Labor, displeases Chamber; direction looks reversed. | pleases ['Chamber of Commerce',"Small Business Owners' Association"], displeases ['Labor Federation']. Changes meaning. |
| L38 | pleases/displeases | C | logic | Same Labor/Chamber direction, ambiguous. | Cameron to confirm. |
| L43 | pleases/displeases | B | logic | Semiconductor subsidy pleases Agricultural Cooperatives, displeases Urban Neighborhood Alliance; no link. | pleases ['Chamber of Commerce','Innovation Society'], displeases ['Labor Federation']. |
| L32, L33, L48, T44 | question | B | coherence | Real-world Japan specifics: "Self-Defense Forces", "Three Non-Nuclear Principles", "imperial succession". Data has a Committee on War and Minister of War, no SDF or imperial household; imperial succession risks canon invention. | L32: "Should the armed forces and emergency powers be written into the constitution?" L33: "Will you revisit Yezo's nuclear principles?" L48: remove unless Cameron confirms a monarchy exists. |
| L48 | pleases/displeases | B | logic | Six pleased orgs, several unrelated. | pleases ['Our Traditional Society','Shrine Association'], displeases ['Students United']. |
| L22 | question | C | coherence | "The weak yen" asserts a currency-market fact outside canon data. | "Prices have outrun wages for a decade. What's your plan?" |
| L55 | question | C | phrasing | "flood mitigation installation programs" clumsy. | "Will you fund flood protection for coastal factories and warehouses?" |
| L64 | ID | C | fitness | lobbyist_meeting jumps from L62 to L64; L63 missing. | Confirm deliberate. |
| T64, T67, L51, L53, L57 | question | C | coherence | Real place names (Hokkaido, Aomori, Kushiro Wetlands) beside fictional Yezo; only Hokkaido/Chishima appear elsewhere in stage names. | Confirm canon; else "the northern coast", "our prefecture". |
| T67 | question | C | phrasing | "What can Aomori count on..." is third person from a local Kōenkai president. | "What can our town count on when the last shop or rail link is at risk?" |
| L27 | question | B | logic | Theme Defense Budget but wording only says "overseas spending". | "Will you vote to increase defense spending?" |
| B02, B03, B05, B06, B07, B08, B09, B13, B16, B17, B19, B20 | pleases/displeases | B | logic | Neutral procedure questions all please Labor Federation / displease Chamber; B20 ("broad support within government") pleases Agricultural/Rural, displeases Urban. | Empty for pure procedure rows; B20 pleases ['Members of Parliament'], displeases []. |
| B12, B17, B18 | question | C | fitness | "the department" assumes the bill creates one. | B12: "What resources will this need?" B17: "Where can the implementers find flexibility?" |
| B12 | pleases/displeases | C | logic | Ainu Community Council pleased by a generic resources question. | Remove. |
| B20, B24, B28, B34, B35, B36 | grades | B | logic | Div=S on factual/data questions (tuition vs earnings, loan forgiveness cost, zoning effects). | B28 Div=M; B34 Div=W; B35 Div=M; B20, B24, B36 Div=M. |
| B31, B33 | grades | C | logic | App=S on an evidence question. | App=M. |
| B23, B32, B33, B34, B35, B55 | asker | C | coherence | Askers' committees unrelated to topic (Ethics on congestion charges, Foreign Affairs on farm water, Agriculture on Ainu dialects). | Reassign (OP46 Agriculture for B32, B33). |
| B22, B26 | grades | C | logic | No real fault beyond B26 pleasing party organs only in a policy-study pool. | No change. |
| S01, S02 | fitness | B | logic | Disaster/Reconstruction attached to ST219 (Land and Port Screening) and ST244 (Regional Minimum Wage). | Restrict to ST01 or remove ST219/ST244. |
| S03 | fitness | C | logic | Emergency powers attached to ST244 Regional Minimum Wage. | Restrict stage list. |
| S16 | fitness | B | logic | "Rice farmers leaving" attached to ST57 Hearing on Fishing Quota Reform. | Remove ST57. |
| S28 | fitness | B | logic | Paper-forms question attached to ST37 Rural Hospitals and ST47 Donation Transparency. | Restrict to an administrative/digital hearing. |
| S12 | asker | B | coherence | Minister of War asks a skeptical "invite a fight?" question. | Reassign, or "How does deterrence keep the peace?" |
| S14 | asker | C | coherence | The committee's own Chair asks "Is this committee's workload an excuse to skip hearings?" | Non-chair asker, or "Is the committee's workload a fair reason to skip hearings?" |
| S13, S15 | pleases/displeases | C | logic | Candidate Selection Committee pleased by member pay and debate rules. | Remove. |
| S10-S18 (and most S rows) | grades | C | logic | Dup=W on about two thirds of stage rows and Div=W on many; Duplicitous/Divisive never right in committees. | If unintended, raise Dup to M on S17, S18, S19, S23, S24. |
| Q32, T95 | pleases/displeases | C | logic | Savings questions please Financial Industry Association and displease Consumer Advocacy Network; odd pairing. | Optional: remove Consumer Advocacy Network. |
| A19, Q17 | pleases/displeases | C | logic | Buddhist Temples Association pleased by generic conviction/trust questions. | Remove. |
| T88, T126 | question | C | phrasing | Two festival-funding questions; T126 near T88. | T126: "Our festival needs more volunteers. How do we keep it going?" |

ROWS READ: 409 of 409

Biggest patterns:
1. Pleases/displeases lists put the same organization on both sides (L93, L96, B31, B33, B40, B49, B50, B58) or carry unrelated organizations (Care and Welfare Council on transparency questions, Members of Parliament on cost-of-living questions, Labor vs Chamber on every neutral procedure question).
2. Askers appear to be assigned by rotation, so first-person lines ("our guild", "my child's school", "our union") are voiced by the wrong people, mostly in lobbyist_meeting and town_hall.
3. There are near-duplicate questions within pools (A16/A33, A09/A28, A05/A20, T05/T08, T21/T22, L03/L12, L05/L19, Q21/Q22, L61/L62), four-S grade inflation in media_ambush, and real-world Japan specifics (Self-Defense Forces, imperial succession, Aomori, Kushiro) that may fall outside Yezo canon.
