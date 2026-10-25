# Findings: slice10_2 (bill components)

Saved from the reviewer's returned report (the reviewer could not write the file itself).

The Write tool refused to create /home/user/CoP-Deckbuilder/design/review/findings_slice10_2.md, so no findings file exists. The full table is below, as the prompt says to do in that case.

Rows read: 180 of 180.
Counts: A = 0, B = 17 (one row with several IDs counts once), C = 8.

| ID | Field | Severity | Category | Problem | Suggested fix |
|---|---|---|---|---|---|
| CB192 | phrase/label/description | B | logic | "Keep the tax exemption" presupposes an exemption already exists in Yezo law, and that is not in the data. A bill to "keep" something also reads as a no-op next to Taxation -0.4. | phrase 'grant a tax exemption on temple land'; label 'Grant a tax exemption on temple land'. This shifts meaning from preserving to creating, so Cameron should confirm. |
| CB207 | phrase/label | B | phrasing | "Record" is ambiguous (audio recording vs. official listing). The Traditional Values tag points to designation. | phrase 'designate festival music and dance as living heritage' |
| CB073 | phrase/label | B | phrasing | "Hold fishing quotas through local cooperatives" is unclear (who holds? hold vs. allocate). | phrase 'allocate fishing quotas through local cooperatives' |
| CB101 | phrase/label | B | phrasing | "Support the rice price" is not idiomatic. The measure is a price floor. | phrase 'guarantee a minimum price for rice' |
| CB136 | phrase/label | B | phrasing | "Register master craftspeople as cultural assets" reduces people to assets and reads oddly aloud. | phrase 'honor master craftspeople as living cultural treasures' |
| CB243 | phrase/label | B | phrasing/coherence | "Build a financial hub zone" is odd, since a zone is designated, not built. It also overlaps CB053 "open special economic zones". | phrase 'designate a financial hub zone in Sapporo' |
| CB052, CB056 | phrase | B | coherence | Same owner, near-identical measures ("simplify business licensing" / "open a single window for business permits"). Paired, they read as redundant, and `excludes` is None. | Make them exclude each other, or reword CB056 to 'let firms file every permit application online'. |
| CB083, CB086 | phrase | B | coherence | Same owner. "Open every committee hearing to the press" is a subset of "guarantee press access to public meetings". | Make them mutually exclusive via `excludes`. |
| CB202, CB206 | phrase | B | coherence | Same owner. "Shrine forests" and "sacred groves" are the same measure, and both carry Environmentalism + Religious Traditionalism tags. | Exclude each other, or reword CB206 to 'protect sacred sites in national planning'. |
| CB141, CB145 | phrase | B | coherence | Same owner. Freezing fares and capping the monthly pass cost overlap. | Make mutually exclusive via `excludes`. |
| CB111 | tags | B | logic | "Cap university tuition" is tagged Federal Spending +0.7, but a cap is regulation, not spending. | Replace with Regulation +0.6 (keep Post-Industrialism +0.5), or reword the phrase to 'fund a cap on university tuition'. |
| CB032, CB035, CB037 | loses | B | logic | Taxpayers' Alliance (BO23) loses 2 for measures with no spending cost (easing gathering rules, open town days, a services directory). | Pick a loss that fits, or drop the loss on zero-cost components. |
| CB085 | loses | B | logic | Anti-SLAPP protection costing Party Headquarters (BO01) standing has no visible rationale. | Review the BO01 loss for press-freedom components. |
| CB232, CB233, CB234, CB235 | loses | B | logic | Care and Welfare Council (BO21) loses 2 for pure transparency and audit measures. The link works only for CB231 (spending cap). | Keep the BO21 loss on CB231 (and arguably CB233), or choose another rival for transparency items. |
| CB245, CB247 | loses | B | logic | Consumer Advocacy Network (BO26) loses 2 for simplifying fund registration and for financial-literacy classes. Literacy classes help consumers. | Remove the loss on CB247 or change its target. |
| CB205, CB207 | loses | B | logic | Chamber of Commerce (BO05) loses 2 for shrine cleanups and festival heritage, with a weak rival link. Only CB208 (street-closure fees) has a plausible commercial angle. | Review the BO05 loss for CB205 and CB207. |
| CB225 | loses | C | logic | Students United (BO11) loses 2 for war memorial maintenance, with no rationale. | Review the BO11 loss for non-spending veterans items. |
| CB285 | phrase/label | C | phrasing | "elders' knowledge programs" is vague. | phrase 'fund programs where Ainu elders pass on traditional knowledge' |
| CB062, CB077, CB108, CB156, CB201, CB295, CB306, CB308 | phrase/label | C | phrasing | "Support ..." is a vague verb repeated across components. In pairs it reads as filler. | CB062 'fund neighborhood watch groups'; CB201 'fund shrine festivals'; CB295 'fund Ainu language classes for adults'; CB308 'fund remote work hubs in villages'; CB306 'give small-town shops rent grants'; CB108 'help farmers sell directly at city markets'; CB077 'help fishers sell their catch directly to local markets'; CB156 'back traditional crafts in school clubs'. |
| CB254 | phrase/label | C | phrasing | "cheap loans" is colloquial for a legal bill. | phrase 'give small firms low-interest loans for equipment' |
| CB273 | phrase/label | C | grammar | "in the cities" implies a defined list of cities. | phrase 'cap rent rises in cities' |
| CB203 | phrase | C | logic | Presupposes a heritage register exists. It is created only by CB153 (BO15), and nothing ties the two together. | Reword to 'add shrine grounds to the national heritage list', or flag a dependency for the bill builder. |
| CB212, CB217 | phrase | C | coherence | Same owner. "Fund home care visits" and "send local care teams to visit isolated elders" overlap. | Optionally add `excludes`. |
| ALL 180 | description | C | phrasing | Every description is the phrase prefixed with "Would", so the Request panel adds nothing the label does not say. It meets the one-plain-sentence rule. | Optional: add a short effect or consequence clause. Acceptable as is. |
| Pattern: lead verbs "fund"/"give"/"let", plus inner "and" in CB045, CB161, CB195, CB207, CB225, CB276, CB281, CB294 | phrase | C | grammar | Pair-joining repeats the lead verb ("fund X and fund Y"). Phrases with an inner "and" make ambiguous three-way lists. | Have the joiner elide a repeated lead verb ("fund X and Y"), or use a comma or semicolon when a phrase contains "and". |
| Whole slice | gains/loses | C | coherence | Each owner has one fixed rival for all its components, so the loss mismatches above recur. No sign or target errors found: all gains point at the owner and all losses at a different organization. Slot X is always +3 and the others +2. | Consider per-component losses only where the rival link is natural. |

Hokkaido and Sapporo appear in data elsewhere (floor_votes, levels, ticker), so I dismissed them as a canon issue in CB054, CB243 and CB244.

ROWS READ: 180 of 180

Biggest patterns:
1. Loss targets are fixed per owner, so several components lose standing with a rival for no logical reason (transparency, heritage and literacy items).
2. Same-owner components overlap without `excludes` (CB052/CB056, CB083/CB086, CB202/CB206, CB141/CB145), and "Support ..." is a vague repeated verb.
3. A few phrases are ambiguous or presuppose law (CB192 "keep", CB207 "record", CB073 "hold", CB101 "support the rice price"), and descriptions only restate the phrases.
