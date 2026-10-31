# Titles and question themes: what the workbook holds (2026-10-31)

Cameron asked for two open items to be laid out: the titles opponents carry, and the Question Themes map. Nothing below has been changed; the decisions are his.

## Executive summary

| Item | What is there now | Main points |
|---|---|---|
| Titles | 15 of 131 opponents have a Title. Everyone else shows their Role (a committee name, or Journalist, Student and so on) in its place. | Six titles name a party leader. Three of those leaders also hold a government post, and the screen shows only the first title, so they appear as Prime Minister, President of the National Assembly and Minister of Ethics and Prosecution, never as party leader. No party has any other internal post (secretary-general, policy chief, whip). |
| Question Themes | 698 themes. Each names the organizations a strong answer pleases and, for some, those it sets back. They cover 2917 questions. | The columns are what the game uses. 32 "Why" notes no longer match their Annoys column. 17 themes are used by no question. Annoyance falls very unevenly: the Chamber of Commerce is set back by 128 themes, while Family Network, the Commuter Committee and the Candidate Selection Committee are never set back. |

## 1. Titles

**How titles work.** The Opponents tab has a **Title** column and a **Role** column. On screen (`OpponentDisplay.title_for()`), a name is followed by the first part of its Title (everything before the first `;`). When the Title is blank, the Role is shown instead. Party Name and Party Acronym are separate columns and are not titles.

**Your rule:** *party leader is the only canon title to preserve.* Every other title below was written into the workbook without being marked canon.

### The 15 opponents with a Title

| Opponent | Name | Party | Title (as written) | Shown on screen as | Holds a party-leader title |
|---|---|---|---|---|---|
| OP10 | Aki Rono | Yezo Heritage Party | Prime Minister; Leader of the Yezo Heritage Party | Prime Minister | Yes |
| OP102 | Emi Katsuragawa | — | President, District Kōenkai Association | President, District Kōenkai Association | No |
| OP110 | Kenta Aoshima | — | Chief Political Correspondent | Chief Political Correspondent | No |
| OP27 | Ichizaki Namu | Frontier Party | President of the National Assembly; Chair of the Committee on the National Assembly; Speaker of the National Assembly; Leader of the Frontier Party | President of the National Assembly | Yes |
| OP29 | Imekanu Resu | Frontier Party | Minister of Agriculture; Chair of the Committee on Agriculture | Minister of Agriculture | No |
| OP33 | Juba Kasumu | Butsutou | Minister of the Environment; Chair of the Committee on the Environment | Minister of the Environment | No |
| OP36 | Kakuei Sato | Five Point Independents | Minister of Construction and Development; Chair of the Committee on Construction and Development | Minister of Construction and Development | No |
| OP47 | Kitahime Haibi | Five Point Independents | Minister of Finance; Chair of the Committee on Finance | Minister of Finance | No |
| OP57 | Masanori Shizugata | Butsutou | Minister of War; Chair of the Committee on War | Minister of War | No |
| OP67 | Okabe Hideriai | Country Initiative | Leader of the Country Initiative | Leader of the Country Initiative | Yes |
| OP78 | Siatuy Sanota | Yezo Heritage Party | Minister of Government Administration; Chair of the Committee on Government Administration | Minister of Government Administration | No |
| OP80 | Soma Umehori | Five Point Independents | Leader of the Five Point Independents | Leader of the Five Point Independents | Yes |
| OP82 | Tama Tsujikonou | Frontier Party | Minister of Foreign Affairs; Chair of the Committee on Foreign Affairs | Minister of Foreign Affairs | No |
| OP83 | Teinei Macmillan | Keizaijiyuutou | Leader of the Keizaijiyuutou | Leader of the Keizaijiyuutou | Yes |
| OP91 | Utemaru Naizen | Butsutou | Minister of Ethics and Prosecution; Chair of the Committee on Ethics and Prosecution; Leader of the Butsutou | Minister of Ethics and Prosecution | Yes |

### Party leaders (Parties tab, Leader Opp ID)

| Party | Seats | Leader | Leader title shown on screen? |
|---|---|---|---|
| Butsutou | 19 | OP91 Utemaru Naizen | No: shows "Minister of Ethics and Prosecution" |
| Yezo Heritage Party | 14 | OP10 Aki Rono | No: shows "Prime Minister" |
| Frontier Party | 27 | OP27 Ichizaki Namu | No: shows "President of the National Assembly" |
| Five Point Independents | 5 | OP80 Soma Umehori | Yes |
| Keizaijiyuutou | 25 | OP83 Teinei Macmillan | Yes |
| Country Initiative | 11 | OP67 Okabe Hideriai | Yes |

### What everyone else shows (the Role column)

| Role shown in place of a title | Opponents |
|---|---|
| Committee on Ethics and Prosecution | 12 |
| Committee on the Environment | 12 |
| Committee on Foreign Affairs | 12 |
| Committee on Government Administration | 12 |
| Committee on the National Assembly | 10 |
| Committee on Agriculture | 10 |
| Student | 9 |
| Committee on Construction and Development | 7 |
| Committee on Finance | 7 |
| Journalist | 7 |
| Committee on War | 6 |
| Constituent | 3 |
| Neighborhood Association Member | 2 |
| Family Network Member | 1 |
| Chamber of Commerce Lobbyist | 1 |
| Labor Federation Member | 1 |
| Agricultural Cooperative Member | 1 |
| Fisheries Cooperative Member | 1 |
| Mayors' Network Representative | 1 |
| Our Traditional Society Member | 1 |

Most of the 116 shown by Role are MPs whose "title" is the committee they sit on (e.g. "Committee on War"). That reads as a seat, not a post.

### Points for you to decide

1. **The government posts that are not party-leader titles**: Prime Minister, President and Speaker of the National Assembly, eight Ministers (each also listed as Chair of the matching committee), Chief Political Correspondent, and President of the District Kōenkai Association. Should they keep, change or lose these titles?
2. **Leaders hidden behind a government post**: OP10 (Prime Minister), OP27 (President of the National Assembly) and OP91 (Minister of Ethics and Prosecution) never show "Leader of …", because only the first title is displayed. If the party-leader title is the one to preserve, it could be listed first for these three.
3. **Party posts below leader** (secretary-general, policy chief, whip and so on): none exist. Either leave them out, or name the ones Yezo's parties have.
4. **MPs with no title**: keep showing the committee name, or show something else, such as "Member, <Party>".

## 2. Question Themes

**What the tab does.** Every question in a room (press conferences, town halls, lobbyist meetings, study sessions, Media Ambush and bill rooms) carries a **Theme**. When the player gives a **strong** answer (one whose suit the question grades S), every organization in the theme's **Organization** column gains standing, and every organization in **Annoys** loses some. A weak answer costs the pleased organizations instead. The exporter copies these lists onto each question, which is why there is no separate data file. The **Why** column is a note for you and is never read by the game. I wrote the whole tab as a draft for you to correct.

### The numbers

| | Count |
|---|---|
| Themes | 698 |
| Questions using a theme | 2917 |
| Themes no question uses | 17 |
| Themes that set someone back | 593 |
| Themes with a stale Why note (it names different organizations from Annoys) | 32 |

### Review findings

| # | Finding | Detail | Suggestion |
|---|---|---|---|
| 1 | Stale Why notes | 32 notes still name the organizations a theme set back before the 2026-10-11 theme rebalance. For example, Aging's note says it sets back the Taxpayers' Alliance (BO23); the Annoys column, which the game uses, says the Chamber of Commerce (BO05). | Rewrite those notes from the columns. Text only; no effect on play. |
| 2 | Themes no question uses | Integration, Labor, Subsidy, Logging jobs, Personal privacy, Press independence, Member fundraising, Public revenue, Small shop fairness, Household energy costs, Fuel for farms and boats, Shipbuilding subsidies, Commission membership, Island security, Trade dependence, Ballot integrity, General question. | Keep them for future questions, or delete them. "General question" also pleases nobody. |
| 3 | Uneven annoyance | Most often set back: Chamber of Commerce (BO05, 128 themes covering 406 questions), Our Traditional Society (BO15, 71 / 293), Urban Neighborhood Alliance (BO27, 77 / 268) and the Taxpayers' Alliance (BO23, 37 / 263). Never set back: Family Network (BO12), Commuter Committee (BO14) and the Candidate Selection Committee (BO32). Almost never: Fisheries Cooperative (BO07, 1), Temples (BO19, 1), Ainu Language and Culture Foundation (BO29, 1) and Party Activists (BO31, 1). | Give the never-annoyed organizations a few natural rivals, and thin out BO05's 128. |
| 4 | Themes with no downside | 21 themes please three or more organizations and annoy nobody: Conservation, Family support, Identity, Infrastructure, Faction loyalty, Party platform, Prefectural Fiscal Devolution Act debate, Temple and Shrine Heritage Act debate, Local standing, Candidate quality, Whistleblower protection, Reserve training, Service families, Village survival, Citizens abroad, Resettlement, Emergency reserves, Permit delays, Digital access, Question time, Governing for all. | Fine for consensus topics (Conservation, Infrastructure). For contested ones, add a rival: Temple and Shrine Heritage Act debate (17 questions), Prefectural Fiscal Devolution Act debate (15) and Resettlement. |
| 5 | Party-tier organizations in the map | Party HQ (BO01), Faction (BO02), Activists (BO31) and Selection Committee (BO32) are pleased or set back by about 70 themes. They follow the player's own party. | Working as intended; listed so you know. |
| 6 | Bill-debate themes are the most used | The "… Act debate" themes are each used by 15-21 questions, so their mapping matters most. Examples: the Special Economic Zones Act pleases BO05, BO24 and BO16 and sets back BO27 and BO13; the National Emergency Powers Act pleases BO22 and BO15 and sets back BO26 and BO18. | Check the top 15 first (listed below). |

### Each organization: how often themes please it and set it back

| Organization | Tier | Themes that please it | Questions those cover | Themes that set it back | Questions those cover |
|---|---|---|---|---|---|
| BO01 Party Headquarters | Party | 14 | 39 | 14 | 43 |
| BO02 Party Faction | Party | 12 | 43 | 10 | 27 |
| BO03 Local Kōenkai | Constituency | 22 | 118 | 3 | 25 |
| BO04 Mayors' Network | Constituency | 46 | 175 | 6 | 33 |
| BO05 Chamber of Commerce | National | 52 | 256 | 128 | 406 |
| BO06 Neighborhood Associations | Constituency | 30 | 110 | 2 | 9 |
| BO07 Fisheries Cooperative | Constituency | 37 | 184 | 1 | 0 |
| BO08 National Media | National | 65 | 237 | 16 | 52 |
| BO09 Labor Federation | National | 44 | 135 | 45 | 154 |
| BO10 Agricultural Cooperatives | National | 45 | 149 | 13 | 34 |
| BO11 Students United | Constituency | 54 | 221 | 55 | 156 |
| BO12 Family Network | Constituency | 47 | 142 | 0 | 0 |
| BO13 Yezo Artisans Guild | National | 32 | 120 | 20 | 90 |
| BO14 Commuter Committee | Constituency | 28 | 156 | 0 | 0 |
| BO15 Our Traditional Society | National | 40 | 217 | 71 | 293 |
| BO16 Innovation Society | National | 41 | 201 | 26 | 105 |
| BO17 Members of Parliament | National | 37 | 78 | 39 | 159 |
| BO18 Constituency Voters | Constituency | 48 | 146 | 22 | 66 |
| BO19 Buddhist Temples Association | National | 20 | 94 | 1 | 19 |
| BO20 Shrine Association | National | 33 | 132 | 3 | 34 |
| BO21 Care and Welfare Council | National | 50 | 156 | 30 | 106 |
| BO22 Veterans' Association | National | 42 | 187 | 7 | 39 |
| BO23 Taxpayers' Alliance | National | 69 | 206 | 37 | 263 |
| BO24 Financial Industry Association | National | 32 | 151 | 61 | 198 |
| BO25 Small Business Owners' Association | Constituency | 46 | 162 | 31 | 130 |
| BO26 Consumer Advocacy Network | Constituency | 54 | 218 | 57 | 259 |
| BO27 Urban Neighborhood Alliance | Constituency | 41 | 151 | 77 | 268 |
| BO28 Ainu Community Council | Constituency | 42 | 129 | 2 | 14 |
| BO29 Ainu Language and Culture Foundation | National | 33 | 103 | 1 | 7 |
| BO30 Rural Revitalization Council | Constituency | 60 | 191 | 48 | 213 |
| BO31 Party Activists | Party | 30 | 56 | 1 | 1 |
| BO32 Candidate Selection Committee | Party | 12 | 32 | 0 | 0 |

### The 15 most-used themes

| Theme | Questions | Pleases | Sets back |
|---|---|---|---|
| Special Economic Zones Act debate | 21 | Chamber of Commerce, Financial Industry Association, Innovation Society | Urban Neighborhood Alliance, Yezo Artisans Guild |
| Digital Economy Promotion Act debate | 21 | Innovation Society, Students United, Chamber of Commerce | Yezo Artisans Guild |
| National Emergency Powers Act debate | 20 | Veterans' Association, Our Traditional Society | Consumer Advocacy Network, Constituency Voters |
| Hokkaido Shinkansen Acceleration Act debate | 19 | Commuter Committee, Chamber of Commerce, Mayors' Network | Taxpayers' Alliance |
| Integrated Resort Act debate | 19 | Chamber of Commerce, Small Business Owners' Association, Taxpayers' Alliance, Mayors' Network | Shrine Association, Buddhist Temples Association |
| Tsugaru Strait Joint Commission Act debate | 17 | Fisheries Cooperative, Commuter Committee | — |
| Temple and Shrine Heritage Act debate | 17 | Buddhist Temples Association, Shrine Association, Our Traditional Society | — |
| Constituency Development Grants Act debate | 17 | Members of Parliament, Constituency Voters, Neighborhood Associations, Local Kōenkai | Taxpayers' Alliance, National Media |
| Yezo–US Security Consultation Agreement debate | 17 | Veterans' Association | Labor Federation |
| Strategic Land and Port Screening Act debate | 17 | Veterans' Association, Our Traditional Society, Fisheries Cooperative | Financial Industry Association, Innovation Society |
| Regional Minimum Wage Act debate | 16 | Labor Federation, Students United | Small Business Owners' Association, Innovation Society |
| Agricultural Price Stabilization Act debate | 15 | Agricultural Cooperatives, Rural Revitalization Council | Consumer Advocacy Network, Taxpayers' Alliance |
| Grid Resilience and Renewable Energy Act debate | 15 | Innovation Society, Rural Revitalization Council, Mayors' Network | Chamber of Commerce, Consumer Advocacy Network |
| Prefectural Fiscal Devolution Act debate | 15 | Mayors' Network, Taxpayers' Alliance, Local Kōenkai | — |
| Candidate Gender Parity Act debate | 15 | Family Network | — |

### The 32 stale Why notes

| Theme | The note says it sets back | The Annoys column (used by the game) |
|---|---|---|
| Accountability | Party Headquarters, Care and Welfare Council | Members of Parliament, Care and Welfare Council |
| Aging | Taxpayers' Alliance | Chamber of Commerce |
| Assistance | Taxpayers' Alliance | Chamber of Commerce |
| Beneficiaries | Taxpayers' Alliance | Chamber of Commerce |
| Childcare | Taxpayers' Alliance | Small Business Owners' Association |
| Credibility | Party Headquarters | Members of Parliament |
| Cronyism | Party Headquarters, Financial Industry Association | Chamber of Commerce, Financial Industry Association |
| Elder Care | Taxpayers' Alliance | Chamber of Commerce |
| Evasion | Party Headquarters | Members of Parliament |
| Fear | Party Headquarters | Our Traditional Society |
| Hardship | Taxpayers' Alliance | Chamber of Commerce |
| Honesty | Party Headquarters, Financial Industry Association | Chamber of Commerce, Financial Industry Association |
| Hypocrisy | Party Headquarters | Our Traditional Society |
| Influence | Party Headquarters | Chamber of Commerce |
| Motive | Party Headquarters | Chamber of Commerce |
| Openness | Party Headquarters | Members of Parliament |
| Oversight | Party Headquarters, Financial Industry Association | Members of Parliament, Financial Industry Association |
| Pensions | Chamber of Commerce, Taxpayers' Alliance | Chamber of Commerce, Small Business Owners' Association |
| Scandal | Party Headquarters | Local Kōenkai |
| Secrecy | Party Headquarters | Financial Industry Association |
| Transparency | Party Headquarters, Care and Welfare Council | Chamber of Commerce, Care and Welfare Council |
| Verdict | Party Headquarters | Members of Parliament |
| Vulnerable | Taxpayers' Alliance | Chamber of Commerce |
| Child safety | Taxpayers' Alliance | Innovation Society |
| Insurance reform | Consumer Advocacy Network, Taxpayers' Alliance | Consumer Advocacy Network, Chamber of Commerce |
| Disability support | Taxpayers' Alliance | Small Business Owners' Association |
| Rural health care | Urban Neighborhood Alliance, Taxpayers' Alliance | Urban Neighborhood Alliance, Financial Industry Association |
| Data security | Party Headquarters, Financial Industry Association | Innovation Society, Financial Industry Association |
| Regional coverage | Party Headquarters | Urban Neighborhood Alliance |
| Shipyard jobs | Students United, Ainu Community Council | Students United |
| Parent and child care | Taxpayers' Alliance | Small Business Owners' Association |
| Surveillance limits | Party Headquarters, Our Traditional Society | Innovation Society, Our Traditional Society |

## Appendix: the whole Question Themes tab

| Theme | Questions | Pleases | Sets back |
|---|---|---|---|
| A member's week | 1 | Members of Parliament, Constituency Voters | National Media, Consumer Advocacy Network |
| Access | 3 | Fisheries Cooperative, Ainu Community Council, Rural Revitalization Council | Our Traditional Society |
| Accountability | 8 | National Media, Taxpayers' Alliance | Members of Parliament, Care and Welfare Council |
| Add sunset clauses to new spending | 8 | Taxpayers' Alliance | Care and Welfare Council |
| After-school care | 1 | Family Network | Chamber of Commerce, Small Business Owners' Association |
| Agenda control | 1 | Members of Parliament, National Media | — |
| Aging | 1 | Care and Welfare Council, Family Network, Buddhist Temples Association | Chamber of Commerce |
| Agricultural Price Stabilization Act debate | 15 | Agricultural Cooperatives, Rural Revitalization Council | Consumer Advocacy Network, Taxpayers' Alliance |
| Ainu fairness | 3 | Ainu Community Council, Ainu Language and Culture Foundation | Our Traditional Society, Urban Neighborhood Alliance, Chamber of Commerce |
| Ainu harvest rights | 1 | Ainu Community Council, Ainu Language and Culture Foundation | Shrine Association, Urban Neighborhood Alliance, Chamber of Commerce |
| Ainu Heritage and Language Act debate | 13 | Ainu Community Council, Ainu Language and Culture Foundation | Our Traditional Society, Chamber of Commerce |
| Ainu land return | 1 | Ainu Community Council, Ainu Language and Culture Foundation | Our Traditional Society, Consumer Advocacy Network |
| Ainu language funding | 1 | Ainu Language and Culture Foundation, Ainu Community Council | Veterans' Association, Urban Neighborhood Alliance |
| Ainu preferential cost | 3 | Ainu Community Council, Ainu Language and Culture Foundation | Veterans' Association, Consumer Advocacy Network, Financial Industry Association |
| Ainu preferential rights | 1 | Ainu Community Council, Ainu Language and Culture Foundation | Our Traditional Society, Urban Neighborhood Alliance, Chamber of Commerce |
| Ainu reserved seats | 2 | Ainu Community Council, Ainu Language and Culture Foundation | Veterans' Association, Consumer Advocacy Network |
| Alliance | 3 | Members of Parliament | Constituency Voters |
| Alliance value | 1 | Veterans' Association, Our Traditional Society | — |
| Allied planning | 1 | Veterans' Association, Chamber of Commerce | Our Traditional Society |
| Allow denser housing near stations | 8 | Urban Neighborhood Alliance | Rural Revitalization Council |
| Arms Trade | 1 | Chamber of Commerce, Veterans' Association | Labor Federation, Students United |
| Assistance | 2 | Neighborhood Associations, Care and Welfare Council | Chamber of Commerce |
| Auditing the auditors | 1 | Taxpayers' Alliance, National Media | — |
| Balanced budgets | 1 | Financial Industry Association, Taxpayers' Alliance | Care and Welfare Council |
| Ballot integrity | 0 | Constituency Voters, National Media | Members of Parliament |
| Ban unpaid trial work | 9 | Labor Federation | Chamber of Commerce |
| Base Burden | 1 | Mayors' Network, Veterans' Association | Students United |
| Base burden | 2 | Mayors' Network, Veterans' Association | Students United |
| Beneficiaries | 2 | Neighborhood Associations, Care and Welfare Council | Chamber of Commerce |
| Benefit targeting | 1 | Family Network, Taxpayers' Alliance | Chamber of Commerce, Small Business Owners' Association |
| Bidding rules | 1 | Taxpayers' Alliance, Small Business Owners' Association | Chamber of Commerce |
| Big firms and small shops | 1 | Small Business Owners' Association | Chamber of Commerce |
| Bike safety | 1 | Urban Neighborhood Alliance, Commuter Committee | Rural Revitalization Council, Agricultural Cooperatives |
| Binding findings | 1 | Members of Parliament, Taxpayers' Alliance | — |
| Bring broadband to every village | 9 | Rural Revitalization Council | Urban Neighborhood Alliance |
| Broadcaster funding | 4 | Taxpayers' Alliance | Care and Welfare Council |
| Broadcaster funding (scrutiny) | 1 | Taxpayers' Alliance | — |
| Budget cuts | 1 | Taxpayers' Alliance, Financial Industry Association | Care and Welfare Council, Students United |
| Build a financial hub zone in Sapporo | 8 | Financial Industry Association | Consumer Advocacy Network |
| Build more city parks | 8 | Urban Neighborhood Alliance | Taxpayers' Alliance |
| Build park-and-ride lots at commuter stations | 8 | Commuter Committee | Rural Revitalization Council |
| Build public student housing | 8 | Students United | Our Traditional Society |
| Building safely | 1 | Labor Federation, Commuter Committee | Chamber of Commerce |
| Burden | 1 | Mayors' Network | — |
| Business investment | 5 | Taxpayers' Alliance, Chamber of Commerce, Small Business Owners' Association | Care and Welfare Council, Labor Federation |
| Cabinet openness | 1 | National Media, Consumer Advocacy Network | — |
| Cabinet unity | 1 | Party Headquarters, National Media | Party Faction |
| Campaign finance | 2 | Consumer Advocacy Network, Taxpayers' Alliance, National Media | Financial Industry Association, Care and Welfare Council |
| Campaign finance (scrutiny) | 2 | Consumer Advocacy Network, Taxpayers' Alliance, National Media | Financial Industry Association |
| Campus housing | 1 | Students United, Urban Neighborhood Alliance | Our Traditional Society, Rural Revitalization Council |
| Campus wellbeing | 1 | Students United, Care and Welfare Council | Our Traditional Society, Chamber of Commerce |
| Candidate finances | 1 | Candidate Selection Committee, Financial Industry Association | — |
| Candidate Gender Parity Act debate | 15 | Family Network | — |
| Candidate quality | 2 | Candidate Selection Committee, National Media, Constituency Voters | — |
| Candidate vetting | 1 | Candidate Selection Committee, National Media | — |
| Cap bank fees | 8 | Consumer Advocacy Network | Financial Industry Association |
| Cap growth in government spending | 8 | Taxpayers' Alliance | Care and Welfare Council |
| Cap rent rises in the cities | 9 | Urban Neighborhood Alliance | Rural Revitalization Council |
| Cap the cost of nursing home beds for families | 8 | Care and Welfare Council | Financial Industry Association |
| Cap the monthly cost of a commuter pass | 8 | Commuter Committee | Rural Revitalization Council |
| Cap university tuition | 8 | Students United | Financial Industry Association |
| Capabilities | 1 | Veterans' Association, Chamber of Commerce | Students United, Labor Federation |
| Carbon Levy Act debate | 8 | Innovation Society, Urban Neighborhood Alliance, Students United | Chamber of Commerce, Financial Industry Association |
| Care | 1 | Care and Welfare Council, Family Network | Taxpayers' Alliance |
| Care demand | 1 | Care and Welfare Council | Taxpayers' Alliance, Financial Industry Association |
| Care funding | 2 | Care and Welfare Council, Family Network | Taxpayers' Alliance |
| Care home waiting lists | 2 | Care and Welfare Council, Family Network | Taxpayers' Alliance, Financial Industry Association |
| Care staffing | 1 | Care and Welfare Council, Labor Federation | Chamber of Commerce, Financial Industry Association |
| Care technology | 1 | Care and Welfare Council, Innovation Society | Labor Federation, Financial Industry Association |
| Care worker pay | 1 | Care and Welfare Council, Labor Federation | Chamber of Commerce, Financial Industry Association |
| Caring for two generations | 1 | Family Network, Care and Welfare Council | Chamber of Commerce, Small Business Owners' Association |
| Catch limits | 1 | Fisheries Cooperative, Consumer Advocacy Network | Financial Industry Association |
| Catch monitoring | 2 | Small Business Owners' Association | Labor Federation |
| Catch monitoring costs | 1 | Small Business Owners' Association | Financial Industry Association |
| Catch prices | 2 | Fisheries Cooperative | — |
| Catch reporting | 1 | Fisheries Cooperative, Consumer Advocacy Network | Financial Industry Association |
| Certify local crafts with a protected label | 8 | Yezo Artisans Guild | Innovation Society |
| Changing positions | 1 | Members of Parliament, Constituency Voters | National Media, Consumer Advocacy Network |
| Child safety | 1 | Family Network, Care and Welfare Council | Innovation Society |
| Childcare | 1 | Family Network, Care and Welfare Council | Small Business Owners' Association |
| Childcare fairness | 2 | Care and Welfare Council, Labor Federation | Chamber of Commerce |
| Chip subsidies | 1 | Chamber of Commerce, Innovation Society | Labor Federation |
| Chishima Coastal Defense Modernization Act debate | 13 | Veterans' Association, Our Traditional Society, Fisheries Cooperative | Students United |
| Chishima Joint Economic Activity Act debate | 11 | Fisheries Cooperative, Small Business Owners' Association | Veterans' Association, Our Traditional Society |
| Chishima Resource Development Agreement Act debate | 7 | Innovation Society | Ainu Language and Culture Foundation, Ainu Community Council |
| Citizen input | 2 | Constituency Voters | — |
| Citizen rights | 1 | Members of Parliament | Constituency Voters |
| Citizen rights review | 1 | Constituency Voters | — |
| Citizens abroad | 1 | Family Network, Care and Welfare Council, Constituency Voters | — |
| City and country fairness | 2 | Care and Welfare Council, Mayors' Network | Urban Neighborhood Alliance |
| City bus service | 1 | Urban Neighborhood Alliance, Commuter Committee | Rural Revitalization Council, Agricultural Cooperatives |
| City housing | 1 | Urban Neighborhood Alliance, Students United | Rural Revitalization Council, Agricultural Cooperatives |
| City taxes | 1 | Urban Neighborhood Alliance, Taxpayers' Alliance | Rural Revitalization Council, Agricultural Cooperatives |
| Civil Service Merit Act debate | 15 | Consumer Advocacy Network, Taxpayers' Alliance, National Media | Members of Parliament, Local Kōenkai |
| Civil service rotation | 1 | Taxpayers' Alliance, Consumer Advocacy Network | Members of Parliament |
| Clarity | 4 | Neighborhood Associations, Consumer Advocacy Network | Financial Industry Association |
| Clean air | 6 | Innovation Society, Urban Neighborhood Alliance, Students United | Yezo Artisans Guild, Rural Revitalization Council |
| Cleanup costs | 1 | Taxpayers' Alliance, Fisheries Cooperative | Chamber of Commerce |
| Co-op support | 1 | Agricultural Cooperatives | Consumer Advocacy Network, Taxpayers' Alliance |
| Command accountability | 1 | Veterans' Association, National Media | — |
| Commission membership | 0 | Taxpayers' Alliance | Care and Welfare Council |
| Commitment | 4 | Party Headquarters, Veterans' Association | Party Faction, Students United |
| Committee credit | 1 | Members of Parliament | National Media, Consumer Advocacy Network |
| Committee seats | 4 | Party Faction, Members of Parliament, Candidate Selection Committee | Party Headquarters, Constituency Voters |
| Committee workload | 2 | Members of Parliament, Party Faction | Constituency Voters, Party Headquarters |
| Community customs | 1 | Shrine Association, Our Traditional Society | Students United, Urban Neighborhood Alliance |
| Community festivals | 1 | Shrine Association, Neighborhood Associations, Yezo Artisans Guild | Students United, Urban Neighborhood Alliance |
| Community strain | 1 | Neighborhood Associations, Urban Neighborhood Alliance, Buddhist Temples Association, Family Network | Rural Revitalization Council |
| Commuter fares | 11 | Commuter Committee | Rural Revitalization Council |
| Commuter fares (2) | 1 | Commuter Committee, Rural Revitalization Council | — |
| Competence | 6 | National Media | Party Headquarters |
| Competition | 1 | Chamber of Commerce, Small Business Owners' Association, Yezo Artisans Guild | Labor Federation |
| Compromise | 6 | Party Faction | Party Headquarters |
| Compromise | 6 | Party Activists | — |
| Conflicts of interest | 1 | National Media, Taxpayers' Alliance, Constituency Voters | Members of Parliament |
| Consent | 1 | Neighborhood Associations, Ainu Community Council | Our Traditional Society |
| Conservation | 2 | Neighborhood Associations, Shrine Association, Ainu Language and Culture Foundation | — |
| Constituency Development Grants Act debate | 17 | Members of Parliament, Constituency Voters, Neighborhood Associations, Local Kōenkai | Taxpayers' Alliance, National Media |
| Constituent service | 2 | Constituency Voters, Local Kōenkai | Members of Parliament |
| Constituents | 4 | Local Kōenkai | — |
| Constitution | 2 | Members of Parliament, Shrine Association | Constituency Voters |
| Constitutional reform | 4 | Members of Parliament | Constituency Voters |
| Constitutional Review Commission Act debate | 7 | Members of Parliament | — |
| Consultation | 4 | Mayors' Network, Neighborhood Associations | — |
| Consumption Tax Rate Act debate | 13 | Care and Welfare Council | Consumer Advocacy Network, Small Business Owners' Association |
| Contract oversight | 1 | Our Traditional Society, Labor Federation | Students United |
| Conviction | 3 | Local Kōenkai, Buddhist Temples Association | — |
| Cooperation | 3 | Party Faction | Party Headquarters |
| Coordination | 3 | Mayors' Network | — |
| Corporate Tax Reduction Act debate | 7 | Taxpayers' Alliance, Chamber of Commerce, Small Business Owners' Association, Financial Industry Association | Care and Welfare Council, Students United |
| Cost | 5 | Consumer Advocacy Network, Taxpayers' Alliance | Financial Industry Association, Care and Welfare Council |
| Cost of living | 3 | Constituency Voters, Consumer Advocacy Network, Students United | Members of Parliament, Financial Industry Association |
| Counterfeit crafts | 1 | Yezo Artisans Guild, Small Business Owners' Association | Innovation Society, Chamber of Commerce |
| Craft apprenticeships | 2 | Yezo Artisans Guild, Students United | Innovation Society, Chamber of Commerce |
| Craft certification | 1 | Yezo Artisans Guild, Consumer Advocacy Network | Innovation Society, Financial Industry Association |
| Craft economics | 1 | Yezo Artisans Guild | Innovation Society, Chamber of Commerce |
| Craft exports | 1 | Yezo Artisans Guild, Chamber of Commerce | Innovation Society, Labor Federation |
| Craft markets | 1 | Yezo Artisans Guild, Small Business Owners' Association | Innovation Society, Chamber of Commerce |
| Create a constituency development fund | 8 | Local Kōenkai | National Media |
| Create a national heritage register | 8 | Our Traditional Society | Students United |
| Create tax-free investment accounts | 8 | Financial Industry Association | Taxpayers' Alliance |
| Credibility | 5 | National Media | Members of Parliament |
| Criticism | 3 | National Media | Party Headquarters |
| Cronyism | 2 | National Media, Consumer Advocacy Network, Party Activists | Chamber of Commerce, Financial Industry Association |
| Crop insurance | 1 | Agricultural Cooperatives, Financial Industry Association | Urban Neighborhood Alliance, Consumer Advocacy Network |
| Crop price floors | 1 | Agricultural Cooperatives, Rural Revitalization Council | Taxpayers' Alliance, Consumer Advocacy Network |
| Customs and belonging | 1 | Our Traditional Society, Party Activists | Students United |
| Customs efficiency | 4 | Small Business Owners' Association | Labor Federation |
| Cut paperwork for small firms | 8 | Small Business Owners' Association | — |
| Cut taxes for small businesses | 8 | Small Business Owners' Association | Labor Federation |
| Cut the corporate tax rate | 8 | Chamber of Commerce | Labor Federation |
| Data privacy | 1 | Innovation Society, Consumer Advocacy Network | Yezo Artisans Guild, Financial Industry Association |
| Data security | 4 | National Media, Consumer Advocacy Network | Innovation Society, Financial Industry Association |
| Data sharing | 2 | Our Traditional Society, Ainu Community Council | Students United |
| Daycare access | 1 | Family Network, Care and Welfare Council | Chamber of Commerce, Small Business Owners' Association |
| Defending the Assembly | 1 | Members of Parliament | National Media, Consumer Advocacy Network |
| Defense Budget | 1 | Veterans' Association, Taxpayers' Alliance, Party Activists | Students United, Care and Welfare Council |
| Defense contracts | 2 | Taxpayers' Alliance, Students United, Care and Welfare Council | Veterans' Association, Our Traditional Society |
| Defense spending | 2 | Veterans' Association, Taxpayers' Alliance | Students United, Care and Welfare Council |
| Defense technology | 1 | Innovation Society, Veterans' Association | Yezo Artisans Guild, Students United |
| Defense value | 1 | Veterans' Association, Taxpayers' Alliance | Students United |
| Defining discrimination | 2 | Ainu Language and Culture Foundation, Ainu Community Council | Chamber of Commerce |
| Definitions | 2 | Labor Federation, Consumer Advocacy Network | Chamber of Commerce, Financial Industry Association |
| Density costs | 1 | Urban Neighborhood Alliance, Taxpayers' Alliance | Rural Revitalization Council, Agricultural Cooperatives |
| Designate temples as disaster shelters | 8 | Buddhist Temples Association | Taxpayers' Alliance |
| Deterrence | 2 | Members of Parliament, Veterans' Association, Party Activists | Constituency Voters, Students United |
| Dialect data | 1 | Ainu Language and Culture Foundation, Ainu Community Council | Our Traditional Society, Chamber of Commerce |
| Digital access | 1 | Care and Welfare Council, Family Network, Mayors' Network | — |
| Digital convenience | 5 | Innovation Society, Financial Industry Association | Yezo Artisans Guild, Consumer Advocacy Network |
| Digital Economy Promotion Act debate | 21 | Innovation Society, Students United, Chamber of Commerce | Yezo Artisans Guild |
| Digital government | 1 | Innovation Society, Consumer Advocacy Network | Yezo Artisans Guild, Financial Industry Association |
| Digital Identity Card Act debate | 7 | Innovation Society, Financial Industry Association | Consumer Advocacy Network, National Media |
| Disability support | 2 | Care and Welfare Council, Family Network | Small Business Owners' Association |
| Disaster readiness | 3 | Mayors' Network, Rural Revitalization Council | Urban Neighborhood Alliance |
| Discipline | 4 | Party Headquarters, Party Activists | Party Faction |
| Discipline of members | 1 | National Media, Party Headquarters | Party Faction |
| Disconnect | 2 | Local Kōenkai, Ainu Community Council, Party Activists | Our Traditional Society |
| Donor privacy | 2 | Chamber of Commerce, Members of Parliament | Labor Federation, Constituency Voters |
| Drafting | 2 | Labor Federation | Chamber of Commerce |
| Early childhood evidence | 1 | Family Network, Students United | Chamber of Commerce, Small Business Owners' Association |
| Ease bank lending rules | 8 | Financial Industry Association | Consumer Advocacy Network |
| Ease the rules on constituent gatherings | 8 | Local Kōenkai | — |
| Economic security | 1 | Chamber of Commerce, Financial Industry Association | Labor Federation, Consumer Advocacy Network |
| Elder Care | 1 | Care and Welfare Council, Family Network, Buddhist Temples Association | Chamber of Commerce |
| Emergency Powers | 1 | Members of Parliament, Party Activists | Constituency Voters |
| Emergency powers | 3 | Members of Parliament | Constituency Voters |
| Emergency reserves | 1 | Mayors' Network, Rural Revitalization Council, Veterans' Association | — |
| Emissions targets | 1 | Innovation Society, Students United, Urban Neighborhood Alliance | Chamber of Commerce, Agricultural Cooperatives |
| Employer costs | 2 | Chamber of Commerce, Innovation Society | Labor Federation, Yezo Artisans Guild |
| End paper filing for company registration | 8 | Chamber of Commerce | — |
| Energy | 1 | Innovation Society, Consumer Advocacy Network | Yezo Artisans Guild, Financial Industry Association |
| Energy transition | 3 | Innovation Society, Students United | Yezo Artisans Guild, Our Traditional Society |
| Enforce overtime pay | 8 | Labor Federation | Chamber of Commerce |
| Enforcement | 2 | Labor Federation, Consumer Advocacy Network | Chamber of Commerce, Financial Industry Association |
| Equal rights | 2 | Students United, Ainu Community Council | Our Traditional Society |
| Establishment | 2 | Party Activists, National Media | — |
| Ethics rules | 1 | Members of Parliament, National Media, Candidate Selection Committee | Constituency Voters, Party Headquarters |
| Evasion | 3 | National Media | Members of Parliament |
| Evidence | 2 | Labor Federation | Chamber of Commerce |
| Expand Ainu-language translation of public documents | 8 | Ainu Language and Culture Foundation | Our Traditional Society |
| Expand veterans' medical care | 8 | Veterans' Association | Care and Welfare Council |
| Export dependence | 1 | Our Traditional Society, Labor Federation | Students United |
| Export gains | 6 | Chamber of Commerce, Consumer Advocacy Network, Small Business Owners' Association | Labor Federation, Financial Industry Association |
| Extend paid parental leave | 8 | Family Network | Small Business Owners' Association |
| Faction discipline | 2 | Party Faction, Party Activists | Party Headquarters |
| Faction loyalty | 4 | Party Faction, Party Headquarters, Candidate Selection Committee | — |
| Fair treatment at work | 6 | Labor Federation, Ainu Language and Culture Foundation, Ainu Community Council | Chamber of Commerce, Our Traditional Society |
| Fairness | 1 | Neighborhood Associations | — |
| Family boats | 1 | Consumer Advocacy Network | Small Business Owners' Association |
| Family caregivers | 1 | Care and Welfare Council, Family Network | Chamber of Commerce, Financial Industry Association |
| Family housing | 1 | Family Network, Urban Neighborhood Alliance | Chamber of Commerce, Small Business Owners' Association |
| Family Law | 1 | Family Network, Buddhist Temples Association | — |
| Family law | 1 | Family Network, Buddhist Temples Association | — |
| Family support | 2 | Family Network, Buddhist Temples Association, Care and Welfare Council | — |
| Family-friendly work | 1 | Family Network, Labor Federation | Chamber of Commerce, Small Business Owners' Association |
| Fare relief | 3 | Commuter Committee, Students United, Care and Welfare Council | Rural Revitalization Council, Our Traditional Society |
| Farm and boat fuel | 1 | Fisheries Cooperative, Agricultural Cooperatives | Chamber of Commerce |
| Farm future | 1 | Agricultural Cooperatives, Rural Revitalization Council, Our Traditional Society | Consumer Advocacy Network, Urban Neighborhood Alliance |
| Farm input costs | 1 | Agricultural Cooperatives, Rural Revitalization Council | Consumer Advocacy Network, Chamber of Commerce |
| Farm markets | 1 | Agricultural Cooperatives | Consumer Advocacy Network |
| Farm subsidies | 1 | Taxpayers' Alliance | Care and Welfare Council |
| Farm subsidies (scrutiny) | 1 | Taxpayers' Alliance | — |
| Farm succession | 1 | Agricultural Cooperatives, Rural Revitalization Council | Urban Neighborhood Alliance |
| Farm Succession Support Act debate | 7 | Agricultural Cooperatives, Rural Revitalization Council, Our Traditional Society | Consumer Advocacy Network |
| Farm support design | 1 | Agricultural Cooperatives | Consumer Advocacy Network, Taxpayers' Alliance |
| Farm water rights | 1 | Agricultural Cooperatives, Fisheries Cooperative | Consumer Advocacy Network, Urban Neighborhood Alliance |
| Faster procedure | 1 | Members of Parliament, Constituency Voters | National Media, Consumer Advocacy Network |
| Fear | 2 | National Media | Our Traditional Society |
| Feasibility | 1 | Mayors' Network, Small Business Owners' Association | Labor Federation |
| Festival crowds | 1 | Shrine Association, Small Business Owners' Association | Students United, Urban Neighborhood Alliance |
| Festival economics | 1 | Shrine Association, Small Business Owners' Association | Students United, Urban Neighborhood Alliance |
| Festival funding | 2 | Shrine Association, Our Traditional Society, Yezo Artisans Guild | Students United |
| Festival routes | 1 | Shrine Association | Students United, Urban Neighborhood Alliance |
| Fintech rules | 2 | Innovation Society, Financial Industry Association | Yezo Artisans Guild, Consumer Advocacy Network |
| Fiscal discipline | 2 | Taxpayers' Alliance, Chamber of Commerce | Care and Welfare Council, Labor Federation |
| Fisheries Quota Modernization Act debate | 7 | Fisheries Cooperative, Consumer Advocacy Network | Small Business Owners' Association |
| Fishing livelihoods | 4 | Fisheries Cooperative, Rural Revitalization Council, Family Network | Urban Neighborhood Alliance |
| Fishing quotas | 9 | Fisheries Cooperative | — |
| Fishing waters | 1 | Fisheries Cooperative, Veterans' Association | Students United |
| Flexibility | 2 | Small Business Owners' Association, Chamber of Commerce | Labor Federation |
| Food standards | 1 | Agricultural Cooperatives, Consumer Advocacy Network | Chamber of Commerce |
| Food tax | 1 | Constituency Voters, Consumer Advocacy Network, Agricultural Cooperatives | Members of Parliament, Financial Industry Association |
| Foreign Resident Local Suffrage Act debate | 13 | Urban Neighborhood Alliance, Consumer Advocacy Network | Veterans' Association, Our Traditional Society |
| Forgive student loans for graduates who work in rural towns | 9 | Students United | Our Traditional Society |
| Freeze commuter fares | 8 | Commuter Committee | Rural Revitalization Council |
| Fuel for farms and boats | 0 | Urban Neighborhood Alliance, Students United | Chamber of Commerce |
| Fuel subsidy | 2 | Fisheries Cooperative, Agricultural Cooperatives | Urban Neighborhood Alliance |
| Fund a national craft museum | 8 | Yezo Artisans Guild | Innovation Society |
| Fund after-school care in every district | 8 | Family Network | Small Business Owners' Association |
| Fund Ainu community centers | 8 | Ainu Community Council | Our Traditional Society |
| Fund Ainu elders' knowledge programs | 8 | Ainu Community Council | Our Traditional Society |
| Fund Ainu-language broadcasting | 8 | Ainu Language and Culture Foundation | Our Traditional Society |
| Fund bike lanes in city centers | 8 | Urban Neighborhood Alliance | Small Business Owners' Association |
| Fund care worker housing near facilities | 8 | Care and Welfare Council | Chamber of Commerce |
| Fund clinics in rural towns | 8 | Rural Revitalization Council | Urban Neighborhood Alliance |
| Fund coworking hubs in regional cities | 9 | Innovation Society, Rural Revitalization Council | — |
| Fund craft workshops in vacant shopfronts | 8 | Yezo Artisans Guild | Innovation Society |
| Fund district office staff training | 8 | Local Kōenkai | Taxpayers' Alliance |
| Fund district offices that help citizens file paperwork | 8 | Local Kōenkai | Taxpayers' Alliance |
| Fund financial literacy classes in schools | 8 | Financial Industry Association | — |
| Fund grain storage for farm cooperatives | 8 | Agricultural Cooperatives | Urban Neighborhood Alliance |
| Fund harbor repairs | 8 | Fisheries Cooperative | Taxpayers' Alliance |
| Fund home care visits | 8 | Care and Welfare Council | Taxpayers' Alliance |
| Fund local festivals | 8 | Our Traditional Society | Urban Neighborhood Alliance |
| Fund local news outlets in small towns | 8 | National Media | Chamber of Commerce |
| Fund mental health care for veterans | 8 | Veterans' Association | Care and Welfare Council |
| Fund museum exhibits and archives on Ainu culture | 8 | Ainu Language and Culture Foundation | Our Traditional Society |
| Fund neighborhood cleanup days | 8 | Neighborhood Associations | Chamber of Commerce |
| Fund new cold storage at fishing ports | 8 | Fisheries Cooperative | Taxpayers' Alliance |
| Fund repairs to community halls | 8 | Neighborhood Associations | Taxpayers' Alliance |
| Fund repairs to temple halls damaged by weather | 8 | Buddhist Temples Association | Taxpayers' Alliance |
| Fund respite care for family caregivers | 8 | Care and Welfare Council | Financial Industry Association |
| Fund rural school buses | 8 | Rural Revitalization Council | Urban Neighborhood Alliance |
| Fund scholarships for first-generation students | 10 | Students United | Taxpayers' Alliance |
| Fund shrine-led community cleanups | 8 | Shrine Association | Taxpayers' Alliance |
| Fund street lighting in residential blocks | 8 | Neighborhood Associations | Taxpayers' Alliance |
| Fund street trees and shade in city centers | 8 | Urban Neighborhood Alliance | Rural Revitalization Council |
| Fund temple preservation | 8 | Buddhist Temples Association | Taxpayers' Alliance |
| Fund the repair of old wooden buildings | 8 | Our Traditional Society | Chamber of Commerce |
| Fund town planning staff | 8 | Mayors' Network | Urban Neighborhood Alliance |
| Fund university spin-off labs | 9 | Innovation Society | — |
| Funding | 4 | Financial Industry Association, Constituency Voters | Consumer Advocacy Network, Members of Parliament |
| Funding Reform | 1 | Party Headquarters, Taxpayers' Alliance, Party Activists | Party Faction, Care and Welfare Council |
| General evidence | 13 | Consumer Advocacy Network | — |
| General question | 0 | — | — |
| Generational divide | 1 | Students United, Party Activists | Our Traditional Society |
| Generational fairness | 1 | Students United | Our Traditional Society, Chamber of Commerce |
| Gentrification | 1 | Urban Neighborhood Alliance, Constituency Voters | Rural Revitalization Council, Members of Parliament |
| Gift disclosure | 1 | National Media, Consumer Advocacy Network, Taxpayers' Alliance | Members of Parliament |
| Give a tax credit for research and development | 8 | Innovation Society | — |
| Give buyers a cooling-off period | 8 | Consumer Advocacy Network | Financial Industry Association |
| Give families a tax deduction for each child | 8 | Family Network | Taxpayers' Alliance |
| Give grants to preserve traditional farmhouses | 8 | Our Traditional Society, Agricultural Cooperatives | — |
| Give neighborhood associations a seat on planning boards | 8 | Neighborhood Associations | Chamber of Commerce |
| Give neighborhood associations legal standing in planning | 8 | Neighborhood Associations | Chamber of Commerce |
| Give new firms a tax holiday in their first year | 8 | Chamber of Commerce | Labor Federation |
| Give small firms cheap loans for equipment | 8 | Small Business Owners' Association | Financial Industry Association |
| Give students discounted transit | 10 | Students United | Chamber of Commerce |
| Give tax breaks to firms opening in rural towns | 8 | Rural Revitalization Council | Urban Neighborhood Alliance |
| Give tax relief for craft apprenticeships | 8 | Yezo Artisans Guild | — |
| Give towns their own tax-setting powers | 8 | Mayors' Network | Rural Revitalization Council |
| Give towns unconditional block grants | 8 | Mayors' Network | Taxpayers' Alliance |
| Give veterans hiring preference in public jobs | 8 | Veterans' Association | Students United |
| Governing for all | 1 | Mayors' Network, Constituency Voters, Rural Revitalization Council | — |
| Graduate jobs | 6 | Students United, Innovation Society | Our Traditional Society, Yezo Artisans Guild |
| Grid Resilience and Renewable Energy Act debate | 15 | Innovation Society, Rural Revitalization Council, Mayors' Network | Chamber of Commerce, Consumer Advocacy Network |
| Grove management | 1 | Shrine Association, Ainu Community Council | Students United, Urban Neighborhood Alliance |
| Grove upkeep | 1 | Shrine Association, Rural Revitalization Council | Students United, Urban Neighborhood Alliance |
| Guarantee a living wage on public contracts | 8 | Labor Federation | Chamber of Commerce |
| Guarantee payment within sixty days on public contracts | 8 | Chamber of Commerce | Labor Federation |
| Guarantee press access to public meetings | 8 | National Media | Mayors' Network |
| Harbor upkeep | 3 | Fisheries Cooperative | — |
| Hardship | 2 | Neighborhood Associations, Care and Welfare Council, Buddhist Temples Association | Chamber of Commerce |
| Harvest losses | 1 | Agricultural Cooperatives | Financial Industry Association |
| Harvest risk | 1 | Agricultural Cooperatives, Financial Industry Association | Consumer Advocacy Network |
| Heritage labels | 1 | Yezo Artisans Guild, Our Traditional Society | Innovation Society, Chamber of Commerce |
| Hiring workers from abroad | 1 | Chamber of Commerce, Small Business Owners' Association | Labor Federation |
| Hokkaido Shinkansen Acceleration Act debate | 19 | Commuter Committee, Chamber of Commerce, Mayors' Network | Taxpayers' Alliance |
| Hold fishing quotas through local cooperatives | 9 | Fisheries Cooperative | Consumer Advocacy Network |
| Hold local referendums on large projects | 8 | Constituency Voters | Members of Parliament |
| Hold public question time with local officials | 8 | Constituency Voters | — |
| Home care shortage | 1 | Care and Welfare Council, Family Network | Chamber of Commerce, Financial Industry Association |
| Home visit value | 1 | Care and Welfare Council, Taxpayers' Alliance | Financial Industry Association |
| Honesty | 4 | National Media, Consumer Advocacy Network | Chamber of Commerce, Financial Industry Association |
| Hospital funding | 1 | Taxpayers' Alliance | Care and Welfare Council |
| Hospital funding (scrutiny) | 1 | Taxpayers' Alliance | — |
| Household energy costs | 0 | Chamber of Commerce, Fisheries Cooperative | Labor Federation |
| Household energy tax | 1 | Constituency Voters | Innovation Society |
| Household savings | 2 | Financial Industry Association, Family Network | Consumer Advocacy Network |
| Housing | 2 | Urban Neighborhood Alliance, Constituency Voters, Students United | Rural Revitalization Council, Members of Parliament |
| Housing and tourism | 1 | Urban Neighborhood Alliance, Constituency Voters | Rural Revitalization Council, Members of Parliament |
| Human rights | 1 | Labor Federation, Consumer Advocacy Network | Chamber of Commerce |
| Hypocrisy | 2 | National Media | Our Traditional Society |
| Identity | 2 | Ainu Community Council, Ainu Language and Culture Foundation, Our Traditional Society, Shrine Association | — |
| Illegal fishing | 2 | Fisheries Cooperative, Veterans' Association | Students United |
| Immigration | 1 | Our Traditional Society, Party Activists | Students United |
| Impact | 5 | Neighborhood Associations | — |
| Implementation | 6 | Mayors' Network, Small Business Owners' Association | Labor Federation |
| Import competition | 1 | Agricultural Cooperatives | Consumer Advocacy Network, Chamber of Commerce |
| Inbound Tourism Visa Waiver Act debate | 14 | Small Business Owners' Association, Yezo Artisans Guild | Our Traditional Society |
| Independent Election Commission Act debate | 15 | Consumer Advocacy Network, National Media | Members of Parliament |
| Independent judgment | 1 | Members of Parliament, Party Headquarters | National Media, Consumer Advocacy Network |
| Inducement | 2 | Agricultural Cooperatives, Rural Revitalization Council | Urban Neighborhood Alliance |
| Influence | 4 | National Media | Chamber of Commerce |
| Infrastructure | 2 | Mayors' Network, Commuter Committee, Rural Revitalization Council | — |
| Inquiries as theatre | 1 | National Media, Taxpayers' Alliance, Constituency Voters | Party Activists |
| Insurance reform | 1 | Financial Industry Association, Care and Welfare Council | Consumer Advocacy Network, Chamber of Commerce |
| Insure farmers against bad harvests | 8 | Agricultural Cooperatives | Urban Neighborhood Alliance |
| Integrated Resort Act debate | 19 | Chamber of Commerce, Small Business Owners' Association, Taxpayers' Alliance, Mayors' Network | Shrine Association, Buddhist Temples Association |
| Integration | 0 | Our Traditional Society, Ainu Language and Culture Foundation | Students United |
| Integration (no foundation) | 1 | Our Traditional Society | Students United |
| Internal democracy | 7 | Students United, Constituency Voters, National Media, Candidate Selection Committee | Our Traditional Society, Members of Parliament |
| Internship rules | 2 | Students United, Labor Federation | Our Traditional Society, Chamber of Commerce |
| Investigative independence | 1 | National Media, Consumer Advocacy Network | Members of Parliament |
| Island benefits | 1 | Fisheries Cooperative, Veterans' Association | Students United |
| Island defense | 2 | Veterans' Association, Fisheries Cooperative | Students United |
| Island resources | 4 | Innovation Society | Yezo Artisans Guild |
| Island security | 0 | Innovation Society | Fisheries Cooperative |
| Isolated elders | 1 | Care and Welfare Council, Mayors' Network | Financial Industry Association, Small Business Owners' Association |
| Isolation | 2 | Party Faction, Party Activists | Party Headquarters |
| Japan Customs and Border Cooperation Act debate | 7 | Small Business Owners' Association | Ainu Community Council, Our Traditional Society |
| Judicial Appointments Commission Act debate | 13 | National Media, Consumer Advocacy Network | — |
| Keep rural bus routes running | 8 | Rural Revitalization Council | Urban Neighborhood Alliance |
| Keep the tax exemption on temple land | 8 | Buddhist Temples Association | Taxpayers' Alliance |
| Label accuracy | 2 | Consumer Advocacy Network, Fisheries Cooperative, Party Activists | Financial Industry Association |
| Labor | 0 | Labor Federation | Chamber of Commerce |
| Language archives | 2 | Ainu Language and Culture Foundation, Ainu Community Council | Our Traditional Society, Chamber of Commerce |
| Language broadcasts | 1 | Ainu Language and Culture Foundation, National Media, Ainu Community Council | Our Traditional Society, Chamber of Commerce |
| Language in schools | 3 | Ainu Language and Culture Foundation, Ainu Community Council, Students United | Our Traditional Society, Chamber of Commerce |
| Language school costs | 1 | Ainu Language and Culture Foundation, Taxpayers' Alliance | Our Traditional Society, Chamber of Commerce |
| Language teachers | 2 | Ainu Language and Culture Foundation, Ainu Community Council, Students United | Our Traditional Society, Chamber of Commerce |
| Last speakers | 1 | Ainu Language and Culture Foundation, Ainu Community Council | Our Traditional Society, Chamber of Commerce |
| Legality | 1 | Labor Federation | Chamber of Commerce |
| Let businesses take on apprentices without extra forms | 8 | Chamber of Commerce | Labor Federation |
| Let citizen petitions trigger committee hearings | 8 | Constituency Voters | Members of Parliament |
| Let consumers sue together over defective goods | 8 | Consumer Advocacy Network | Financial Industry Association |
| Let district offices hold open town days | 8 | Local Kōenkai | — |
| Let festival organizers close streets without extra fees | 8 | Shrine Association | Chamber of Commerce |
| Let foreign banks open branches in Hokkaido | 8 | Financial Industry Association | Consumer Advocacy Network |
| Let neighborhood associations run small local grants | 8 | Neighborhood Associations | Chamber of Commerce |
| Let parents work shorter hours while children are young | 8 | Family Network | Small Business Owners' Association |
| Let residents vote on local budget priorities | 8 | Constituency Voters | Mayors' Network |
| Let start-ups test products in regulatory sandboxes | 8 | Innovation Society | — |
| Let temples run public meditation and care programs | 8 | Buddhist Temples Association, Care and Welfare Council | — |
| Let towns borrow for local projects | 8 | Mayors' Network | Taxpayers' Alliance |
| Let towns merge services across borders | 8 | Mayors' Network | Neighborhood Associations |
| Leverage | 1 | Agricultural Cooperatives, Financial Industry Association, Party Activists | Urban Neighborhood Alliance, Consumer Advocacy Network |
| Limits | 1 | Chamber of Commerce, Party Activists | Labor Federation |
| List shrine grounds on the heritage register | 8 | Shrine Association | Chamber of Commerce |
| Livelihood | 1 | Fisheries Cooperative, Agricultural Cooperatives, Yezo Artisans Guild, Rural Revitalization Council | Urban Neighborhood Alliance |
| Loan relief | 1 | Students United, Taxpayers' Alliance | Our Traditional Society, Chamber of Commerce |
| Local autonomy | 2 | Mayors' Network, Rural Revitalization Council | Urban Neighborhood Alliance |
| Local Consent | 1 | Neighborhood Associations, Ainu Community Council | Our Traditional Society |
| Local customs | 1 | Our Traditional Society, Shrine Association, Local Kōenkai, Party Activists | Students United |
| Local flexibility | 1 | Mayors' Network, Local Kōenkai, Rural Revitalization Council | Party Headquarters |
| Local Government Mergers Act debate | 7 | Taxpayers' Alliance, Chamber of Commerce | Rural Revitalization Council, Constituency Voters |
| Local identity | 1 | Mayors' Network, Neighborhood Associations | — |
| Local makers | 2 | Labor Federation, Agricultural Cooperatives | Chamber of Commerce, Urban Neighborhood Alliance |
| Local standing | 3 | Candidate Selection Committee, Local Kōenkai, Constituency Voters | — |
| Logging jobs | 0 | Chamber of Commerce, Rural Revitalization Council | Labor Federation, Urban Neighborhood Alliance |
| Logging work | 1 | Labor Federation, Rural Revitalization Council | Urban Neighborhood Alliance |
| Loyalty | 5 | Party Headquarters, Veterans' Association | Party Faction, Students United |
| Maintain war memorials and cemeteries | 8 | Veterans' Association | — |
| Maintenance first | 1 | Commuter Committee, Mayors' Network | — |
| Make every station step-free | 8 | Commuter Committee | Rural Revitalization Council |
| Make large firms pay suppliers on time | 8 | Small Business Owners' Association | Chamber of Commerce |
| Make school lunches free | 8 | Family Network | Small Business Owners' Association |
| Marine pollution | 2 | Fisheries Cooperative, Consumer Advocacy Network | Financial Industry Association |
| Master teachers | 1 | Yezo Artisans Guild, Students United | Innovation Society, Chamber of Commerce |
| Measuring success | 1 | Taxpayers' Alliance, Innovation Society | — |
| Member fundraising | 0 | Taxpayers' Alliance, National Media | Chamber of Commerce |
| Member fundraising (scrutiny) | 2 | Taxpayers' Alliance, National Media | Chamber of Commerce |
| Member pay | 1 | Members of Parliament, Taxpayers' Alliance, Candidate Selection Committee | Constituency Voters, Care and Welfare Council |
| Member staffing | 1 | Members of Parliament, Taxpayers' Alliance | National Media, Consumer Advocacy Network |
| Member workload | 1 | Members of Parliament, Taxpayers' Alliance | National Media, Consumer Advocacy Network |
| Members and bills | 1 | Members of Parliament, Constituency Voters | National Media, Consumer Advocacy Network |
| Merger savings | 4 | Taxpayers' Alliance, Chamber of Commerce | Care and Welfare Council, Labor Federation |
| Metrics | 1 | Labor Federation | Chamber of Commerce |
| Ministerial responsibility | 1 | National Media, Constituency Voters, Taxpayers' Alliance | Members of Parliament |
| Mixed-use zoning | 1 | Urban Neighborhood Alliance, Small Business Owners' Association | Rural Revitalization Council, Agricultural Cooperatives |
| Money | 2 | Financial Industry Association, Chamber of Commerce, Party Activists | Consumer Advocacy Network, Labor Federation |
| Moral Education Curriculum Act debate | 13 | Our Traditional Society, Shrine Association, Buddhist Temples Association | Urban Neighborhood Alliance, Students United |
| Motive | 5 | National Media, Party Activists | Chamber of Commerce |
| Move government services online | 8 | Innovation Society | — |
| National Emergency Powers Act debate | 20 | Veterans' Association, Our Traditional Society | Consumer Advocacy Network, Constituency Voters |
| National sovereignty | 2 | Small Business Owners' Association | Our Traditional Society |
| National symbols | 2 | Our Traditional Society, Members of Parliament, Party Activists | Students United, Constituency Voters |
| Neglect | 2 | Local Kōenkai, Rural Revitalization Council, Ainu Community Council, Buddhist Temples Association | Urban Neighborhood Alliance |
| Neighborhood noise | 1 | Urban Neighborhood Alliance, Neighborhood Associations | Rural Revitalization Council, Agricultural Cooperatives |
| Nuclear deterrence | 1 | Members of Parliament, Veterans' Association | Constituency Voters, Students United |
| Nuclear Energy | 1 | Innovation Society | Yezo Artisans Guild |
| Nuclear posture | 1 | Members of Parliament, Veterans' Association | Constituency Voters, Students United |
| Ocean changes | 1 | Fisheries Cooperative, Innovation Society | Yezo Artisans Guild |
| Offer visas to start-up founders | 9 | Innovation Society | — |
| Open a single window for business permits | 8 | Chamber of Commerce | Labor Federation |
| Open committees | 1 | National Media, Constituency Voters, Consumer Advocacy Network | Members of Parliament |
| Open dementia care centers in every district | 8 | Care and Welfare Council | Taxpayers' Alliance |
| Open every committee hearing to the press | 8 | National Media | Members of Parliament |
| Open more public childcare places | 8 | Family Network | Small Business Owners' Association |
| Open public data to start-ups | 8 | Innovation Society | — |
| Open special economic zones | 8 | Chamber of Commerce | Labor Federation |
| Open vacant city lots to community gardens | 8 | Urban Neighborhood Alliance | Rural Revitalization Council |
| Openness | 3 | National Media | Members of Parliament |
| Organized Crime Conspiracy Act debate | 15 | Veterans' Association, Our Traditional Society | Consumer Advocacy Network, Financial Industry Association |
| Oversight | 3 | National Media, Consumer Advocacy Network | Members of Parliament, Financial Industry Association |
| Oversight of overseers | 1 | National Media, Taxpayers' Alliance | — |
| Overtourism | 1 | Urban Neighborhood Alliance, Constituency Voters, Shrine Association, Yezo Artisans Guild | Rural Revitalization Council, Members of Parliament |
| Pace of lawmaking | 1 | Constituency Voters, Chamber of Commerce | — |
| Parent and child care | 4 | Family Network, Care and Welfare Council, Labor Federation | Small Business Owners' Association |
| Parental Leave and Childcare Act debate | 7 | Family Network, Care and Welfare Council, Labor Federation | Small Business Owners' Association, Innovation Society |
| Parliamentary procedure | 1 | Members of Parliament, Candidate Selection Committee | Constituency Voters |
| Participation | 1 | Local Kōenkai, Students United, Ainu Community Council, Ainu Language and Culture Foundation | Our Traditional Society |
| Partnership Registration Act debate | 14 | Students United, Urban Neighborhood Alliance | Shrine Association, Our Traditional Society |
| Party democracy | 7 | Students United, Constituency Voters | — |
| Party Leadership Selection Act debate | 7 | Students United, Constituency Voters, National Media | Members of Parliament |
| Party platform | 4 | Party Headquarters, Party Faction, Candidate Selection Committee | — |
| Party stability | 2 | Members of Parliament, Party Activists | Constituency Voters |
| Pay farmers to keep paddies in use | 8 | Agricultural Cooperatives | Urban Neighborhood Alliance |
| Pay grants to families moving to rural towns | 8 | Rural Revitalization Council | Urban Neighborhood Alliance |
| Pensions | 1 | Labor Federation, Care and Welfare Council, Financial Industry Association | Chamber of Commerce, Small Business Owners' Association |
| Permit delays | 1 | Small Business Owners' Association, Chamber of Commerce, Innovation Society | — |
| Personal privacy | 0 | Financial Industry Association | National Media |
| Persuasion | 5 | Party Faction | Party Headquarters |
| Place names | 1 | Ainu Language and Culture Foundation, Ainu Community Council | Our Traditional Society, Chamber of Commerce |
| Political Donation Transparency Act debate | 7 | Consumer Advocacy Network, Taxpayers' Alliance, National Media | Members of Parliament, Chamber of Commerce |
| Political funds | 2 | Party Headquarters, Taxpayers' Alliance | Party Faction, Care and Welfare Council |
| Port jobs | 2 | Fisheries Cooperative, Labor Federation | Chamber of Commerce |
| Position | 2 | Party Headquarters | Party Faction |
| Post government spending online by project | 8 | Taxpayers' Alliance | — |
| Power Prices | 1 | Consumer Advocacy Network, Chamber of Commerce | Financial Industry Association, Labor Federation |
| Prefectural Fiscal Devolution Act debate | 15 | Mayors' Network, Taxpayers' Alliance, Local Kōenkai | — |
| Preparedness | 1 | Mayors' Network, Veterans' Association | Students United |
| Press independence | 0 | National Media | Party Headquarters |
| Price | 1 | Consumer Advocacy Network, Chamber of Commerce | Financial Industry Association, Labor Federation |
| Principles | 3 | Members of Parliament, Buddhist Temples Association | Constituency Voters |
| Priority | 4 | Local Kōenkai | — |
| Project overruns | 1 | Taxpayers' Alliance, Constituency Voters | Chamber of Commerce |
| Promote craft exports abroad | 8 | Yezo Artisans Guild | Innovation Society |
| Protect coastal fishing grounds from industrial dumping | 8 | Fisheries Cooperative | Consumer Advocacy Network |
| Protect collective bargaining rights | 8 | Labor Federation | Chamber of Commerce |
| Protect historic districts from redevelopment | 8 | Our Traditional Society | Urban Neighborhood Alliance |
| Protect journalists from lawsuits meant to silence them | 8 | National Media | Chamber of Commerce |
| Protect old town names on maps and signs | 8 | Our Traditional Society | — |
| Protect reporters' confidential sources | 9 | National Media | Members of Parliament |
| Protect sacred groves in national planning | 8 | Shrine Association | Chamber of Commerce |
| Protect shrine forests from development | 8 | Shrine Association | Chamber of Commerce |
| Protest and privacy | 2 | Urban Neighborhood Alliance, Innovation Society | National Media |
| Public access to nature | 2 | Shrine Association | Chamber of Commerce |
| Public Broadcasting Independence Act debate | 7 | National Media | — |
| Public debt | 3 | Taxpayers' Alliance, Financial Industry Association | Care and Welfare Council, Consumer Advocacy Network |
| Public revenue | 0 | Mayors' Network, Students United, Financial Industry Association | Our Traditional Society |
| Public safety | 6 | Veterans' Association, Urban Neighborhood Alliance, Innovation Society | Students United, Rural Revitalization Council |
| Public Safety Surveillance Act debate | 7 | Veterans' Association, Urban Neighborhood Alliance, Innovation Society | Consumer Advocacy Network, Students United |
| Public trust | 2 | Constituency Voters | — |
| Publish a directory of district services | 8 | Local Kōenkai | Taxpayers' Alliance |
| Publish every project's full costs for public comment | 8 | Constituency Voters | Members of Parliament |
| Publish product safety recalls in one public list | 8 | Consumer Advocacy Network | Chamber of Commerce |
| Publish real-time delay data for every line | 8 | Commuter Committee | Rural Revitalization Council |
| Publish the full cost of every bill | 8 | Taxpayers' Alliance | — |
| Purity of the cause | 3 | Party Activists, Party Faction | — |
| Purpose | 1 | Labor Federation | Chamber of Commerce |
| Quality marks | 1 | Yezo Artisans Guild, Consumer Advocacy Network | Innovation Society, Chamber of Commerce |
| Question time | 1 | Members of Parliament, National Media, Constituency Voters | — |
| Quota trading | 3 | Fisheries Cooperative, Consumer Advocacy Network | Financial Industry Association |
| Rail funding | 3 | Taxpayers' Alliance, Commuter Committee | Care and Welfare Council, Rural Revitalization Council |
| Rail operator costs | 2 | Chamber of Commerce, Taxpayers' Alliance | Labor Federation, Care and Welfare Council |
| Rail safety | 3 | Commuter Committee, Consumer Advocacy Network | Rural Revitalization Council, Financial Industry Association |
| Rail timetables | 6 | Commuter Committee | Rural Revitalization Council |
| Raise allowances for district offices | 8 | Local Kōenkai | National Media |
| Raise care workers' wages | 8 | Care and Welfare Council | Chamber of Commerce |
| Raise the child allowance | 8 | Family Network | Taxpayers' Alliance |
| Raise the minimum wage | 9 | Labor Federation | Chamber of Commerce |
| Raise veterans' pensions | 8 | Veterans' Association | Taxpayers' Alliance |
| Ranger funding | 1 | Taxpayers' Alliance | — |
| Raw materials | 1 | Yezo Artisans Guild, Agricultural Cooperatives | Innovation Society, Urban Neighborhood Alliance |
| Reading the bill | 1 | Constituency Voters, Taxpayers' Alliance | Members of Parliament |
| Reconstruction | 2 | Mayors' Network, Rural Revitalization Council | Urban Neighborhood Alliance |
| Record festival music and dance as living heritage | 8 | Shrine Association | — |
| Redevelopment | 2 | Urban Neighborhood Alliance, Mayors' Network | Rural Revitalization Council |
| Refund fares for long delays | 8 | Commuter Committee | Rural Revitalization Council |
| Regional coverage | 2 | National Media | Urban Neighborhood Alliance |
| Regional Minimum Wage Act debate | 16 | Labor Federation, Students United | Small Business Owners' Association, Innovation Society |
| Regional security | 2 | Members of Parliament, Veterans' Association | Constituency Voters, Students United |
| Register master craftspeople as cultural assets | 8 | Yezo Artisans Guild | Innovation Society |
| Relocation | 1 | Mayors' Network, Rural Revitalization Council | Urban Neighborhood Alliance |
| Relocation grants | 1 | Rural Revitalization Council, Agricultural Cooperatives | Urban Neighborhood Alliance, Financial Industry Association |
| Rent policy | 1 | Urban Neighborhood Alliance, Small Business Owners' Association | Rural Revitalization Council, Agricultural Cooperatives |
| Representation | 2 | Local Kōenkai, Ainu Community Council, Ainu Language and Culture Foundation | Our Traditional Society |
| Require an audit of every large grant | 8 | Taxpayers' Alliance | Care and Welfare Council |
| Require clear price labels | 8 | Consumer Advocacy Network | Chamber of Commerce |
| Require consultation with Ainu communities on land use | 8 | Ainu Community Council | Our Traditional Society |
| Require disclosure of who pays for political advertising | 8 | National Media | Local Kōenkai |
| Require government data to be published in open formats | 8 | National Media | Mayors' Network |
| Require open hearings before closing local services | 8 | Constituency Voters | Mayors' Network |
| Require plain-language contracts | 8 | Consumer Advocacy Network | Financial Industry Association |
| Require public consultation before new projects | 8 | Constituency Voters | Members of Parliament |
| Research and innovation | 4 | Students United, Family Network | Our Traditional Society |
| Research funding | 3 | Innovation Society, Students United | Yezo Artisans Guild, Our Traditional Society |
| Reserve training | 1 | Veterans' Association, Our Traditional Society, Small Business Owners' Association | — |
| Resettlement | 1 | Family Network, Neighborhood Associations, Local Kōenkai | — |
| Resolve | 5 | Party Faction | Party Headquarters |
| Resources | 1 | Mayors' Network, Rural Revitalization Council, Ainu Community Council | Urban Neighborhood Alliance |
| Restore Ainu fishing and harvest rights | 8 | Ainu Community Council | Our Traditional Society |
| Restore old rail stations as community landmarks | 8 | Our Traditional Society, Commuter Committee | — |
| Restrict foreign food imports | 8 | Agricultural Cooperatives | Urban Neighborhood Alliance |
| Return ceremonial sites to Ainu stewardship | 8 | Ainu Community Council | Our Traditional Society |
| Revitalization offices | 1 | Rural Revitalization Council, Mayors' Network | Urban Neighborhood Alliance, Financial Industry Association |
| Revival lessons | 1 | Ainu Language and Culture Foundation, Ainu Community Council | Our Traditional Society, Chamber of Commerce |
| Rice policy | 1 | Agricultural Cooperatives, Consumer Advocacy Network | Urban Neighborhood Alliance, Financial Industry Association |
| Risk | 1 | Labor Federation, Financial Industry Association | Chamber of Commerce, Consumer Advocacy Network |
| Risk review | 2 | Consumer Advocacy Network, Labor Federation | Financial Industry Association |
| River protection | 1 | Fisheries Cooperative, Ainu Community Council, Rural Revitalization Council | Chamber of Commerce |
| Road congestion | 3 | Commuter Committee | Rural Revitalization Council |
| Run late-night commuter trains | 9 | Commuter Committee | Rural Revitalization Council |
| Rural broadband | 1 | Rural Revitalization Council, Innovation Society | Urban Neighborhood Alliance, Financial Industry Association |
| Rural clinics | 2 | Rural Revitalization Council, Care and Welfare Council | Urban Neighborhood Alliance, Financial Industry Association |
| Rural decline | 1 | Rural Revitalization Council, Mayors' Network | Urban Neighborhood Alliance |
| Rural health care | 4 | Rural Revitalization Council, Care and Welfare Council, Mayors' Network | Urban Neighborhood Alliance, Financial Industry Association |
| Rural Hospital Network Act debate | 7 | Rural Revitalization Council, Care and Welfare Council, Mayors' Network | Urban Neighborhood Alliance |
| Rural incentives | 1 | Rural Revitalization Council | Urban Neighborhood Alliance, Financial Industry Association |
| Rural rail service | 3 | Rural Revitalization Council, Mayors' Network, Commuter Committee | Urban Neighborhood Alliance |
| Rural schools | 1 | Rural Revitalization Council, Family Network | Urban Neighborhood Alliance, Financial Industry Association |
| Rural service costs | 1 | Rural Revitalization Council, Taxpayers' Alliance | Urban Neighborhood Alliance, Financial Industry Association |
| Rural Services | 1 | Rural Revitalization Council, Mayors' Network, Agricultural Cooperatives | Urban Neighborhood Alliance |
| Rural services | 1 | Rural Revitalization Council, Mayors' Network, Agricultural Cooperatives | Urban Neighborhood Alliance |
| Rural students | 4 | Family Network | — |
| Rural transport | 2 | Rural Revitalization Council, Commuter Committee, Mayors' Network | Urban Neighborhood Alliance, Financial Industry Association |
| Safe routes to school | 1 | Family Network, Neighborhood Associations | Chamber of Commerce, Small Business Owners' Association |
| Scandal | 2 | National Media | Local Kōenkai |
| School closures | 2 | Family Network, Rural Revitalization Council | Chamber of Commerce, Small Business Owners' Association |
| School meals | 1 | Family Network, Care and Welfare Council | Chamber of Commerce, Small Business Owners' Association |
| Scope | 2 | Labor Federation | Chamber of Commerce |
| Screen time | 1 | Family Network, Innovation Society | Yezo Artisans Guild |
| Seafood labeling | 3 | Fisheries Cooperative | — |
| Seasonal rites | 2 | Shrine Association, Agricultural Cooperatives | Urban Neighborhood Alliance |
| Secrecy | 3 | National Media | Financial Industry Association |
| Security strategy | 1 | Members of Parliament, Veterans' Association, Party Activists | Constituency Voters, Students United |
| Selection process | 3 | Candidate Selection Committee, Party Headquarters | — |
| Send local care teams to visit isolated elders | 8 | Care and Welfare Council | Chamber of Commerce |
| Service families | 1 | Veterans' Association, Family Network, Care and Welfare Council | — |
| Set an affordable housing quota for new buildings | 8 | Urban Neighborhood Alliance | Rural Revitalization Council |
| Set up a fisheries disaster relief fund | 8 | Fisheries Cooperative | Consumer Advocacy Network |
| Set up a free consumer complaint line | 8 | Consumer Advocacy Network | Chamber of Commerce |
| Shared farm facilities | 1 | Agricultural Cooperatives, Rural Revitalization Council | Consumer Advocacy Network, Small Business Owners' Association |
| Shared space | 1 | Neighborhood Associations, Urban Neighborhood Alliance, Shrine Association | Rural Revitalization Council |
| Shipbuilding and Defense Industry Act debate | 7 | Veterans' Association, Our Traditional Society, Labor Federation, Chamber of Commerce | Students United, Consumer Advocacy Network |
| Shipbuilding subsidies | 0 | Students United, Care and Welfare Council, Chamber of Commerce | Our Traditional Society, Taxpayers' Alliance |
| Shipyard jobs | 4 | Veterans' Association, Our Traditional Society, Labor Federation | Students United |
| Short-Term Rentals | 1 | Urban Neighborhood Alliance, Constituency Voters, Small Business Owners' Association | Rural Revitalization Council, Members of Parliament |
| Shrine groves | 1 | Shrine Association, Neighborhood Associations | Students United, Urban Neighborhood Alliance |
| Shrine land | 2 | Shrine Association, Our Traditional Society, Party Activists | Students United |
| Signal | 3 | Party Faction | Party Headquarters |
| Simplicity | 1 | Small Business Owners' Association, Chamber of Commerce | Labor Federation |
| Simplify business licensing | 8 | Chamber of Commerce | — |
| Simplify the registration of investment funds | 8 | Financial Industry Association | Consumer Advocacy Network |
| Small employer burden | 2 | Chamber of Commerce, Small Business Owners' Association, Students United | Labor Federation |
| Small farm fairness | 2 | Rural Revitalization Council, Our Traditional Society | Chamber of Commerce |
| Small shop fairness | 0 | Chamber of Commerce, Small Business Owners' Association | Mayors' Network |
| Small-state diplomacy | 1 | Veterans' Association, National Media | — |
| Solar Siting | 1 | Innovation Society, Rural Revitalization Council | Yezo Artisans Guild, Urban Neighborhood Alliance |
| Speaking for Yezo | 1 | Members of Parliament, National Media | — |
| Special committee membership | 1 | Members of Parliament, National Media | — |
| Special committee purpose | 1 | National Media, Constituency Voters | — |
| Special Economic Zones Act debate | 21 | Chamber of Commerce, Financial Industry Association, Innovation Society | Urban Neighborhood Alliance, Yezo Artisans Guild |
| Specified Skilled Worker Visa Act debate | 13 | Agricultural Cooperatives, Fisheries Cooperative | Our Traditional Society, Labor Federation |
| Speed approval of new financial products | 8 | Financial Industry Association | Consumer Advocacy Network |
| Speed up customs clearance at Hokkaido ports | 8 | Chamber of Commerce | Labor Federation |
| Stakes | 1 | Neighborhood Associations, Party Activists | — |
| Start a farm-to-school lunch program | 8 | Agricultural Cooperatives | Urban Neighborhood Alliance |
| Starting a farm | 1 | Agricultural Cooperatives, Rural Revitalization Council, Our Traditional Society | Urban Neighborhood Alliance |
| Station access | 4 | Commuter Committee | Rural Revitalization Council |
| Station staffing | 1 | Labor Federation, Commuter Committee | Chamber of Commerce, Rural Revitalization Council |
| Stimulus | 1 | Financial Industry Association, Small Business Owners' Association | Consumer Advocacy Network, Labor Federation |
| Strategic Land and Port Screening Act debate | 17 | Veterans' Association, Our Traditional Society, Fisheries Cooperative | Financial Industry Association, Innovation Society |
| Street mobilization | 1 | Party Activists, Constituency Voters | — |
| Strengthen freedom of information requests | 8 | National Media | Members of Parliament |
| Student debt | 3 | Students United, Family Network | Our Traditional Society, Chamber of Commerce |
| Student housing | 3 | Students United, Urban Neighborhood Alliance | Our Traditional Society, Chamber of Commerce |
| Student representation | 4 | Students United | Our Traditional Society, Chamber of Commerce |
| Subsidize farm machinery | 8 | Agricultural Cooperatives | Urban Neighborhood Alliance |
| Subsidize fuel for fishing boats | 8 | Fisheries Cooperative | Consumer Advocacy Network |
| Subsidy | 0 | Agricultural Cooperatives, Chamber of Commerce | Urban Neighborhood Alliance, Labor Federation |
| Subsidy targeting | 1 | Agricultural Cooperatives | Consumer Advocacy Network, Taxpayers' Alliance |
| Succession | 1 | Our Traditional Society, Yezo Artisans Guild, Buddhist Temples Association, Shrine Association, Ainu Language and Culture Foundation, Party Activists | Students United, Innovation Society |
| Supply Chains | 1 | Chamber of Commerce, Small Business Owners' Association, Yezo Artisans Guild | Labor Federation |
| Supply chains | 2 | Chamber of Commerce, Small Business Owners' Association, Yezo Artisans Guild | Labor Federation |
| Support | 3 | Agricultural Cooperatives, Rural Revitalization Council | Urban Neighborhood Alliance |
| Support Ainu language classes for adults | 8 | Ainu Language and Culture Foundation | Our Traditional Society |
| Support direct sales of catch to local markets | 8 | Fisheries Cooperative | Consumer Advocacy Network |
| Support farmers' direct sales at city markets | 8 | Agricultural Cooperatives | Urban Neighborhood Alliance |
| Support neighborhood watch groups | 8 | Neighborhood Associations | Taxpayers' Alliance |
| Support remote work hubs in villages | 8 | Rural Revitalization Council | Urban Neighborhood Alliance |
| Support shrine festivals | 8 | Shrine Association | Taxpayers' Alliance |
| Support small-town shops with rent grants | 8 | Rural Revitalization Council | Urban Neighborhood Alliance |
| Support the rice price | 8 | Agricultural Cooperatives | Consumer Advocacy Network |
| Support traditional crafts in school clubs | 8 | Our Traditional Society, Yezo Artisans Guild | — |
| Surveillance limits | 2 | National Media, Students United | Innovation Society, Our Traditional Society |
| Tax break limits | 1 | Taxpayers' Alliance, Consumer Advocacy Network | Chamber of Commerce |
| Tax cut priorities | 1 | Mayors' Network | Chamber of Commerce |
| Tax Relief | 1 | Constituency Voters, Taxpayers' Alliance, Small Business Owners' Association | Members of Parliament, Care and Welfare Council |
| Tax relief | 2 | Constituency Voters, Taxpayers' Alliance, Small Business Owners' Association | Members of Parliament, Care and Welfare Council |
| Tax revenue gap | 1 | Mayors' Network, Students United | Chamber of Commerce |
| Teach local traditions in schools | 8 | Our Traditional Society | Students United |
| Teach the Ainu language in schools | 8 | Ainu Language and Culture Foundation | Our Traditional Society |
| Teaching local history | 1 | Ainu Language and Culture Foundation, Ainu Community Council, Students United | Our Traditional Society, Chamber of Commerce |
| Tech transfer | 2 | Innovation Society, Students United | Yezo Artisans Guild, Our Traditional Society |
| Technique registry | 1 | Yezo Artisans Guild, Ainu Language and Culture Foundation | Innovation Society, Chamber of Commerce |
| Temple and Shrine Heritage Act debate | 17 | Buddhist Temples Association, Shrine Association, Our Traditional Society | — |
| Term length | 1 | Members of Parliament | National Media, Consumer Advocacy Network |
| Tomari Nuclear Restart Act debate | 13 | Chamber of Commerce, Financial Industry Association | Consumer Advocacy Network, Students United |
| Tourism Tax | 1 | Constituency Voters, Small Business Owners' Association, Yezo Artisans Guild | Members of Parliament, Labor Federation |
| Town hall staff | 1 | Labor Federation | — |
| Trade dependence | 0 | Consumer Advocacy Network, Small Business Owners' Association | Labor Federation |
| Trade sanctions | 1 | Labor Federation, Veterans' Association | Chamber of Commerce, Small Business Owners' Association |
| Traditional crafts | 3 | Yezo Artisans Guild, Our Traditional Society | Innovation Society, Students United |
| Train and certify more care workers | 8 | Care and Welfare Council | Small Business Owners' Association |
| Transit | 7 | Commuter Committee, Urban Neighborhood Alliance | Rural Revitalization Council, Agricultural Cooperatives |
| Transit value | 2 | Urban Neighborhood Alliance, Commuter Committee | Rural Revitalization Council, Agricultural Cooperatives |
| Transparency | 5 | National Media, Taxpayers' Alliance | Chamber of Commerce, Care and Welfare Council |
| Trust | 4 | Local Kōenkai, Ainu Community Council, Buddhist Temples Association | Our Traditional Society |
| Tsugaru Strait Joint Commission Act debate | 17 | Fisheries Cooperative, Commuter Committee | — |
| Tuition value | 3 | Students United, Financial Industry Association | Our Traditional Society, Chamber of Commerce |
| Unity | 3 | Party Headquarters | Party Faction |
| University Autonomy and Research Funding Act debate | 7 | Students United, Family Network | — |
| University spending | 2 | Taxpayers' Alliance | Care and Welfare Council |
| University spending (scrutiny) | 2 | Taxpayers' Alliance | — |
| Urban green space | 1 | Urban Neighborhood Alliance, Family Network | Rural Revitalization Council, Agricultural Cooperatives |
| Vacant homes | 1 | Urban Neighborhood Alliance, Constituency Voters | Rural Revitalization Council, Members of Parliament |
| Verdict | 1 | National Media, Party Activists | Members of Parliament |
| Village representation | 1 | Chamber of Commerce | Mayors' Network |
| Village representation (2) | 1 | Mayors' Network, Neighborhood Associations | — |
| Village survival | 2 | Rural Revitalization Council, Agricultural Cooperatives, Mayors' Network | — |
| Visas for service jobs | 1 | Chamber of Commerce, Small Business Owners' Association | Our Traditional Society |
| Volunteer groups | 1 | Shrine Association, Neighborhood Associations | Students United, Urban Neighborhood Alliance |
| Volunteer value | 1 | Shrine Association, Taxpayers' Alliance | Students United, Urban Neighborhood Alliance |
| Votes | 4 | Party Headquarters | Party Faction |
| Vulnerable | 2 | Neighborhood Associations, Care and Welfare Council, Buddhist Temples Association | Chamber of Commerce |
| Wages | 1 | Labor Federation, Small Business Owners' Association, Students United | Chamber of Commerce |
| Waive fees at craft fairs for small makers | 8 | Yezo Artisans Guild | — |
| Waive licensing fees for micro-enterprises | 8 | Small Business Owners' Association | — |
| Waive permit fees for shrine festival stalls | 8 | Shrine Association | Taxpayers' Alliance |
| Welcoming newcomers | 1 | Students United, Labor Federation | Our Traditional Society |
| What works rurally | 1 | Rural Revitalization Council, Mayors' Network | Urban Neighborhood Alliance, Financial Industry Association |
| Whistleblower protection | 1 | National Media, Labor Federation, Consumer Advocacy Network | — |
| Wilderness and Wildlife Protection Act debate | 7 | Ainu Community Council, Shrine Association | Rural Revitalization Council, Chamber of Commerce |
| Wilderness protection | 3 | Ainu Community Council, Shrine Association | Our Traditional Society |
| Wildlife and jobs | 1 | Ainu Community Council, Rural Revitalization Council | Chamber of Commerce, Labor Federation |
| Wind and view | 1 | Innovation Society, Rural Revitalization Council | Neighborhood Associations |
| Worker protection | 1 | Labor Federation | Small Business Owners' Association |
| Workforce | 2 | Labor Federation, Small Business Owners' Association | Chamber of Commerce |
| Workplace Equality Act debate | 7 | Labor Federation, Ainu Language and Culture Foundation, Ainu Community Council, Students United | Small Business Owners' Association, Chamber of Commerce |
| Workshop space | 1 | Yezo Artisans Guild, Urban Neighborhood Alliance | Innovation Society, Chamber of Commerce |
| Yezo–China Trade Normalization Act debate | 7 | Chamber of Commerce, Consumer Advocacy Network, Small Business Owners' Association | Veterans' Association, Yezo Artisans Guild |
| Yezo–EU Economic Partnership Agreement debate | 15 | Chamber of Commerce, Financial Industry Association, Yezo Artisans Guild | Rural Revitalization Council, Agricultural Cooperatives |
| Yezo–US Security Consultation Agreement debate | 17 | Veterans' Association | Labor Federation |
| Young farmers | 4 | Agricultural Cooperatives, Rural Revitalization Council, Our Traditional Society | Urban Neighborhood Alliance |
| Youth participation | 4 | Students United, Constituency Voters | Our Traditional Society, Chamber of Commerce |
| Zoning | 2 | Urban Neighborhood Alliance, Students United, Party Activists | Rural Revitalization Council, Our Traditional Society |
