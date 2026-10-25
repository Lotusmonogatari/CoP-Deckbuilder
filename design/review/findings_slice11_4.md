# Findings: slice11_4 (room questions d)

Saved from the reviewer's returned report (the reviewer could not write the file itself).

The Write tool refused to create /home/user/CoP-Deckbuilder/design/review/findings_slice11_4.md, so no file exists. As the prompt instructs, the complete findings are below.

Rows read: 409 of 409 (S850 to S1258). Counts: A=1, B=26, C=10. The A and B counts treat each table row as one finding, and the table has 37 rows.

| ID | Field | Sev | Category | Problem | Suggested fix |
|---|---|---|---|---|---|
| S1105-S1112 | displeases | A | logic | "End paper filing for company registration" displeases Labor Federation. Nothing in the topic touches labor, so the player loses standing for no visible reason. | Leave displeases blank. |
| S1097-S1104 | displeases | B | logic | "Simplify business licensing" displeases Labor Federation. The link is weak. | Leave displeases blank, or confirm with Cameron that deregulation is meant to read as anti-labor. |
| S1113-S1136 | displeases | B | logic | Community hall repairs, neighborhood watch and street lighting all displease Chamber of Commerce. There is no business angle. | displeases=["Taxpayers' Alliance"] |
| S1137-S1160 | displeases | B | logic | Harbor repairs, fishing-boat fuel subsidy and cold storage displease Consumer Advocacy Network. The link is weak. | displeases=["Taxpayers' Alliance"] |
| S1233-S1256 | displeases | B | logic | Tuition cap, student transit discount and first-generation scholarships displease Our Traditional Society. No link to tradition. | displeases=["Taxpayers' Alliance"], or blank. |
| S1049-S1064 | displeases | B | logic | "Ease the rules on constituent gatherings" and "Let district offices hold open town days" displease Taxpayers' Alliance. Neither is a spending proposal. | Leave displeases blank for these two topics. |
| S1209-S1216 | displeases | C | logic | Rice price support displeases Urban Neighborhood Alliance. S894-S896 use Consumer Advocacy Network for the same issue. | displeases=["Consumer Advocacy Network"] |
| S1257-S1258 | displeases | C | logic | Child allowance displeases Small Business Owners' Association. Taxpayers' Alliance is the closer fit. | displeases=["Taxpayers' Alliance"] |
| All "{Org} wants us to ... Why should everyone else care?" rows: S1044, 1052, 1060, 1068, 1076, 1084, 1092, 1100, 1108, 1116, 1124, 1132, 1140, 1148, 1156, 1164, 1172, 1180, 1188, 1196, 1204, 1212, 1220, 1228, 1236, 1244, 1252 | question | B | grammar | The article is missing ("Local Kōenkai wants"). Plural orgs break agreement ("Neighborhood Associations wants", "Agricultural Cooperatives wants"). S1228 repeats itself ("Agricultural Cooperatives ... grain storage for farm cooperatives"). | Use "The {Org} want(s) ...". S1116: "The Neighborhood Associations want us to fund repairs to community halls. Why should everyone else care?" S1228: "The Agricultural Cooperatives want us to fund grain storage. Why should everyone else care?" |
| All "Is there a smaller way than to ..." rows (S1048, 1056, 1064 ... 1256, every 8th) | question | B | grammar | The phrase is ungrammatical and clumsy. | Template: "Is there a smaller step we could try before we {proposal}?" |
| All "What goes wrong if we ... badly?" rows (S1047, 1055 ... 1255) | question | B | grammar | "badly" at the end of the clause is stilted ("if we give towns unconditional block grants badly"). | Template: "What is the biggest risk if we {proposal}?" |
| All "... fairly and on schedule?" rows (S1046, 1054 ... 1254) | question | B | phrasing | "fairly and on schedule" does not make sense for ease-the-rules, corporate tax cut, protect sources, or ban unpaid trial work. | Write per topic. Example: "How would you cut the corporate tax rate without squeezing public services?" This changes the meaning, so flag it for Cameron. |
| All "What would it mean for my town if ..." rows (S1045, 1053 ... 1253), including S1093, 1109, 1165, 1173, 1181, 1189 | question | B | fitness | "my town" is nonsense for national topics: freedom of information, confidential sources, journalist lawsuits, corporate tax rate, company registration. | "What would it mean for people like me if ...?" |
| "Who pays if we ..." rows on non-spending topics: S1049, 1097, 1105, 1161, 1169, 1177, 1201 | question | B | logic | The question asks about cost where none is obvious (ease rules, simplify licensing, end paper filing, protect sources, ban unpaid trial work). | "Who loses out if we ...?" |
| S1041-S1258, whole template block | group | B | phrasing | About 220 rows are the same eight frames with a noun phrase swapped in, and the grades are identical across topics. Seven frames contain two sentences ("Critics say ... What do you tell them?"), against the one-sentence rule. | Hand-vary two or three frames per topic. Merge the critics frame into one sentence: "Critics say we should not {proposal}; what do you tell them?" |
| S919 | grades | B | logic | A logistics question grades Emotional S, Data Driven M. | Dat=S, Emo=M |
| S922 | grades | B | logic | A customs-speed question grades Emotional S, Data Driven M. | Dat=S, Emo=M |
| S933 | grades | B | logic | The employment numbers question has Data Driven only M. | Dat=S, Ear=M |
| S938 | grades | B | logic | "What evidence shows..." grades Data Driven M, Emotional S. | Dat=S, Emo=M |
| S950 | grades | B | logic | "Which exports gain the most" is a numbers question graded Dat=M, Emo=S. | Dat=S, Emo=M |
| S963 | grades | B | logic | "How many jobs..." is a numbers question graded Dat=M. | Dat=S, Emo=M |
| S974 | grades | B | logic | A procedural enforcement question grades Emotional S, Data Driven M. | Dat=S, Emo=M |
| S1000 | grades | B | logic | "How much of the revenue..." is a numbers question graded Dat=M. | Dat=S, Emo=M |
| S1010 | grades | B | logic | "What article ... is actually broken?" needs a specific answer but grades Dat=M, Emo=S. | Dat=S, Emo=M |
| S874 | grades | B | logic | "Who benefits most" is analytical but grades Dat=M, Emo=S. | Dat=S, Emo=M |
| S890 | grades | B | logic | "What would success look like" (measures) has Data Driven only M. | Dat=S, App=M |
| S940 | grades | B | logic | The question is how to answer a family worried about tradition. Divisive is S, which would alienate the family. Earnest and Emotional are only M. | Ear=S, Emo=S, Div=W |
| S872 | pleases/displeases | B | logic | "Is public debt a burden or a tool?" always displeases Care and Welfare Council, but a "tool" answer would favor welfare. | Drop Care and Welfare Council from displeases. |
| S888 | displeases | B | coherence | Party Activists are displeased by a question about stopping inquiries becoming a show. There is no visible link. | Remove, or use ['Party Faction']. |
| S937 | displeases | B | logic | The question names unions, protesters and journalists but displeases Financial Industry Association. | displeases=['Consumer Advocacy Network','Labor Federation','National Media'] |
| S946 | displeases | C | logic | The question is about fishing boats but Fisheries Cooperative is absent. | Add 'Fisheries Cooperative' to displeases. |
| S884 | asker | C | coherence | A minister (OP33) asks whether ministers should answer more often. | Use a non-minister asker. |
| S881 | asker | C | coherence | The Prime Minister cross-examines whether the Cabinet speaks with one voice. | Consider another Cabinet member. |
| S1024 | question | B | phrasing | "budgets they could not manage as well" has no comparison. | "Why trust universities with larger budgets when they have not always managed smaller ones well?" (slight meaning change) |
| S1028 | question | B | phrasing | Tangled: "make employers hire fewer people at risk of discrimination". | "Would penalties for repeat offenders make employers avoid hiring people likely to face discrimination?" |
| S959 | question | C | phrasing | "What do islanders and their descendants say" is not a question to the player. | "What would former islanders and their descendants say about sharing these waters?" |
| S895, S999 | question | C | phrasing | Each has two sentences. | S895: "Rice is cheaper abroad, so why should shoppers pay for the difference?" S999: "What does the levy do to a farmer who heats a barn with oil?" |
| S903 | question | C | coherence | Names Russia, a real-world state. Other rows use only data place names. Cameron to confirm. | "Do new radar stations deter foreign exercises, or invite them?" (meaning changes slightly) |
| S918 | question | C | grammar | Single quotes around 'effort'. | Is "effort" enough, or should the law set a number? |
| S850-S1040 | grades | C | fitness | The committee grades follow a rotating pattern (Dup=W nearly everywhere, Div alternating S/W). No row is all S or all W. | Spot-check only. |

ROWS READ: 409 of 409

Biggest patterns:
1. Rows S1041-S1258 are one eight-frame template. Five frames read badly (smaller way than to, badly, fairly and on schedule, my town, two sentences), and the "{Org} wants" frame has article and agreement errors.
2. In the template families, the displeased organizations are often irrelevant (Chamber for community halls, Labor for paper filing, Our Traditional Society for tuition). Taxpayers' Alliance is the real objector for spending topics.
3. Several numbers or evidence questions grade Data Driven M with Emotional S (S874, 890, 919, 922, 933, 938, 950, 963, 974, 1000, 1010).
