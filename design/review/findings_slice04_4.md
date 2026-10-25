# Findings: slice04_4 (transition dialogue)

Saved from the reviewer's returned report (the reviewer could not write the file itself).

The Write tool refused to create /home/user/CoP-Deckbuilder/design/review/findings_slice04_4.md, so the complete findings are below.

Rows read: 417 of 417. Findings: A=0, B=7, C=11.

| ID | Field | Sev | Category | Problem | Suggested fix |
|---|---|---|---|---|---|
| TD486, TD1210, TD1211, TD1212 (OP34, ST09/172/195/251); TD489, TD1221, TD1222, TD1223, TD1224 (OP04, ST12/163/202/241/250) | CHARACTER | B | logic | The member says "Our questions are few but pointed" while SF01 in the same stage (TD308, TD1048, TD1049, TD1050, TD314, TD1070-TD1073) says "The committee has a long list of questions". If both speak in one transition, they contradict each other. | Change the member line (the meaning shifts slightly): "Our questions are pointed. Keep your answers short." Keep the reply "Then my answers will be direct." |
| TD482/483, TD484/485, TD495/496, TD497/498, TD1192/1198, TD1193/1199, TD1194/1200, TD1195/1201, TD1196/1202, TD1197/1203, TD1264/1271, TD1265/1272, TD1266/1273, TD1267/1274, TD1268/1275, TD1269/1276, TD1270/1277, TD1204/1207, TD1205/1208, TD1206/1209, TD1156/1159, TD1157/1160, TD1158/1161 | CHARACTER and PLAYER | B | phrasing | The two eligible speakers in a stage get a word-for-word identical exchange. With Speaker Count 2, the player hears the same beat twice. The LINT duplicates are real here. | Give the second speaker of each pair a different line. For example, OP123: "Some of us have waited a long time to ask." / "Then I will not rush you." OP120: "Farming and labor want different things, but we share some ground." / "Then let us start there." OP91 (TV): "Short answers win nights like this one." / "Then I will keep mine short." For the chair pairs: "Questions will be taken in turn. Please be precise." / "I will be." |
| TD1177-TD1191 (all OP116 "My editor wants a clear answer today.") | PLAYER | B | logic | The reply "She will get one." assumes the editor's gender, which is not in the data. It also answers the editor rather than the reporter. | "Then your editor will get one." |
| TD1311 | CHARACTER | B | logic | "The best answer here is an honest 'I do not know'." overpromises. It could mislead a player into passing on questions in a study session. It also has nested quotes. | "Sometimes the honest answer here is 'I do not know'." |
| All SF02 "Keep every figure on X within reach." rows (TD309, TD311, TD313, TD315, TD317, TD319, TD321, TD323, TD325, TD1051-TD1155 SF02 rows) | PLAYER | B | phrasing | The reply "They are within reach." only parrots the staffer. It adds no character. | "Already in my folder." or "Everything I need is in the folder." |
| TD239, TD474, TD241 (ST100) | CHARACTER | B | phrasing | TD239 and TD474 (both SF15) say nearly the same thing. "Members at home" is ambiguous, since BO17 is Members of Parliament. "open ballots" is jargon the player may not know. | TD474: "Party members back home are following where you stand on Party Leadership Ballots." Use "Party Leadership Ballots" consistently in TD239/240/241. |
| TD326, TD327 (ST24) | CHARACTER | B | coherence | They repeat the hand-written TD19 and TD20 for the same speakers. "Commuter Fares" is title-cased mid-sentence, and "when Commuter Fares comes up" is awkward. | Drop TD326 and TD327 for ST24, or reword TD327: "Small kindnesses will count most when the fares come up." |
| TD1305 | CHARACTER | C | phrasing | "forgives nothing and forgets nothing" is a stock phrase. | "The camera keeps every word I say." |
| TD1315 (with TD1319) | CHARACTER | C | phrasing | "line" is used in two senses (the threshold, then quips), and TD1319 repeats the threshold sense. | "What holds the bar is a steady tone, not clever quips." |
| SF15 "This is your own party's room..." rows (TD239, TD958-TD987 SF15 set) | PLAYER | C | logic | "Then I will choose well." does not answer a line about words being noticed. | "Then I will choose my words well." |
| SF01/SF02 topic-filled rows (TD308-TD325, TD1048-TD1155 sets) | CHARACTER | C | grammar | The topic placeholder fills inconsistently: "on the Environment" versus "on War" versus "on Finance". "Keep every figure on War within reach" reads oddly. | Use "questions about {topic}" and "Keep your {topic} figures within reach", with articles handled in data. |
| All SF01 replies "Then I will take them one at a time." | PLAYER | C | phrasing | "Then" implies a conclusion the staff line did not give. It is the same reply on 40+ rows. | Vary a few: "Then I had better pace myself." |
| TD474 | PLAYER | C | phrasing | "Then I will stand carefully." is stiff. | "Then I will take my stand with care." |
| TD327 | PLAYER | C | phrasing | "Then I will be kind." is a flat reply. | "Then I will start with kindness." |
| TD328 | PLAYER | C | logic | "I will skim the clear parts." contradicts the study-room thoughts (TD1309, TD1313), which say to read the report. | "Then I will read the whole pack." |
| TD22 | PLAYER | C | phrasing | "Precise it is." is stilted. | "Then I will be precise." |
| TD1278-TD1283 (OP42 "Show me the numbers behind the promise.") | CHARACTER | C | coherence | The line is adversarial for study sessions (ST21 family), where the room is meant for learning (TD1308). | "Walk me through the numbers behind this." |
| All "We will keep this orderly. Answer what is asked." rows (TD487-TD496, TD1213-TD1263 sets) | CHARACTER | C | phrasing | About a dozen chairs and party leaders say this word for word. The committee beat sounds the same every time. | Write two or three variants per party. |

ROWS READ: 417 of 417

Three biggest patterns:
1. Identical exchanges go to both eligible speakers in the same stage (23 pairs). The "few questions" versus "long list of questions" clash between OP34/OP04 and SF01 is the other main logic problem.
2. Player replies are formulaic or parrot the line ("Then I will...", "They are within reach.", "Then I will choose well." to a line about words). "She will get one." assumes an editor's gender.
3. Templated topic placeholders read awkwardly (Title Case, articles). The ST24/ST25 template rows duplicate the hand-written ones.
