# Room cast and organization balance audit (2026-10-31)

Generated from `data/*.json` by the session's audit scripts. Numbers count the 99 playable levels (crisis levels left out; the four Event Only levels included). Nothing in the game was rebalanced by this audit.

## 1. Who sits in each room, and which questions they ask


## questions naming an organization nobody in the room belongs to (3)
   ST28 Lobbyist Meeting on Fishing Quotas: 6 of 109 (L70, L82, L84, L94, L100...)
   ST77 Hearing on Farm Succession: 1 of 42 (S184)
   ST273 Campus Q&A: 7 of 156 (T81, T84, T92, T97, T107...)

## committee seats someone from another committee (2)
   ST31 Hearing on Fishery Quotas (Committee on Agriculture): OP15
   ST57 Hearing on Fishing Quota Reform (Committee on Agriculture): OP15

## too few people (1)
   ST261 Win Over a Member: 0 for 1 seats

## TV Debate seats a non-MP (1)
   ST271 Radio Debate: ['OP118', 'OP119', 'OP120', 'OP121', 'OP122', 'OP123', 'OP124', 'OP125']


Notes:
- **Radio Debate (ST271)** shows under "TV Debate seats a non-MP" only because it borrows the TV Debate picture; seating the organization representatives there is the design.
- **Win Over a Member (ST261)** has no seated people on purpose: the patron machinery picks the member at run time.
- **OP15 Edward Grinner** (Committee on Construction and Development) sits in two Agriculture fishing hearings (ST31, ST57). Edward Grinner is also the PC03 protagonist's name. Cameron to decide whether that is intended.
- **Questions naming an organization nobody in the room belongs to** fall back to whoever is seated (the usual rotation), so a student may read a farmers' question in Campus Q&A. Fixes: give Campus Q&A only its own questions (it would need about 45), or accept the fallback.

## 2. Organizations: what levels, laws, questions, visitors and events do for each

Columns: levels whose own Win reward raises (+) or lowers (-) the organization; bill levels whose law raises/lowers it if the bill passes or fails; levels with at least one question or visitor choice that can please it; events with a choice that raises/lowers it.

| BO | Organization | Tier | Lvl reward + | Lvl reward − | Law pass + | Law pass − | Law fail + | Law fail − | Qs can please (levels) | Qs can annoy | Visitor can please | Events + | Events − |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| BO01 | Party Headquarters | Party | 9 | 0 | 0 | 0 | 0 | 0 | 90 | 89 | 43 | 1 | 0 |
| BO02 | Party Faction | Party | 8 | 0 | 0 | 0 | 0 | 0 | 90 | 87 | 43 | 0 | 0 |
| BO03 | Local Kōenkai | Constituency | 10 | 0 | 1 | 1 | 1 | 2 | 89 | 21 | 43 | 0 | 0 |
| BO04 | Mayors' Network | Constituency | 10 | 0 | 4 | 3 | 3 | 5 | 88 | 1 | 44 | 1 | 1 |
| BO05 | Chamber of Commerce | National | 10 | 0 | 9 | 7 | 8 | 10 | 82 | 90 | 44 | 0 | 0 |
| BO06 | Neighborhood Associations | Constituency | 9 | 0 | 0 | 2 | 2 | 1 | 90 | 13 | 49 | 6 | 3 |
| BO07 | Fisheries Cooperative | Constituency | 7 | 0 | 6 | 2 | 3 | 6 | 85 | 0 | 48 | 1 | 1 |
| BO08 | National Media | National | 8 | 0 | 6 | 4 | 5 | 6 | 90 | 62 | 46 | 0 | 0 |
| BO09 | Labor Federation | National | 6 | 0 | 4 | 4 | 4 | 4 | 90 | 85 | 45 | 2 | 2 |
| BO10 | Agricultural Cooperatives | National | 5 | 0 | 3 | 3 | 3 | 3 | 66 | 64 | 48 | 0 | 0 |
| BO11 | Students United | Constituency | 5 | 0 | 7 | 5 | 6 | 7 | 90 | 89 | 48 | 2 | 1 |
| BO12 | Family Network | Constituency | 5 | 0 | 3 | 2 | 2 | 3 | 90 | 0 | 49 | 4 | 2 |
| BO13 | Yezo Artisans Guild | National | 5 | 0 | 2 | 3 | 3 | 2 | 86 | 87 | 46 | 0 | 0 |
| BO14 | Commuter Committee | Constituency | 6 | 0 | 2 | 2 | 2 | 2 | 83 | 0 | 46 | 0 | 0 |
| BO15 | Our Traditional Society | National | 5 | 0 | 8 | 7 | 7 | 8 | 87 | 86 | 48 | 2 | 2 |
| BO16 | Innovation Society | National | 5 | 0 | 6 | 4 | 4 | 7 | 87 | 83 | 48 | 1 | 1 |
| BO17 | Members of Parliament | National | 2 | 0 | 1 | 4 | 4 | 2 | 89 | 90 | 43 | 0 | 0 |
| BO18 | Constituency Voters | Constituency | 1 | 0 | 1 | 3 | 3 | 2 | 90 | 88 | 45 | 0 | 0 |
| BO19 | Buddhist Temples Association | National | 1 | 0 | 2 | 1 | 1 | 2 | 88 | 1 | 1 | 1 | 1 |
| BO20 | Shrine Association | National | 2 | 0 | 3 | 2 | 2 | 3 | 84 | 32 | 46 | 1 | 1 |
| BO21 | Care and Welfare Council | National | 2 | 0 | 3 | 2 | 2 | 3 | 90 | 89 | 49 | 2 | 2 |
| BO22 | Veterans' Association | National | 7 | 0 | 7 | 4 | 4 | 7 | 88 | 63 | 43 | 2 | 1 |
| BO23 | Taxpayers' Alliance | National | 4 | 0 | 6 | 8 | 10 | 6 | 89 | 63 | 50 | 0 | 0 |
| BO24 | Financial Industry Association | National | 1 | 0 | 4 | 3 | 3 | 5 | 89 | 90 | 50 | 0 | 0 |
| BO25 | Small Business Owners' Association | Constituency | 2 | 0 | 6 | 5 | 5 | 6 | 85 | 69 | 8 | 3 | 3 |
| BO26 | Consumer Advocacy Network | Constituency | 4 | 0 | 7 | 7 | 8 | 7 | 90 | 84 | 46 | 0 | 0 |
| BO27 | Urban Neighborhood Alliance | Constituency | 3 | 0 | 4 | 2 | 2 | 4 | 83 | 88 | 44 | 1 | 1 |
| BO28 | Ainu Community Council | Constituency | 2 | 0 | 3 | 2 | 2 | 3 | 83 | 0 | 43 | 1 | 1 |
| BO29 | Ainu Language and Culture Foundation | National | 1 | 0 | 2 | 1 | 1 | 2 | 83 | 0 | 43 | 2 | 1 |
| BO30 | Rural Revitalization Council | Constituency | 1 | 0 | 3 | 3 | 3 | 4 | 78 | 83 | 48 | 3 | 3 |
| BO31 | Party Activists | Party | 0 | 0 | 0 | 0 | 0 | 0 | 90 | 5 | 43 | 0 | 0 |
| BO32 | Candidate Selection Committee | Party | 0 | 0 | 0 | 0 | 0 | 0 | 81 | 0 | 43 | 0 | 0 |

Share of all question appearances across the levels that please or annoy each organization:

```
question appearances 20735
BO26 Consumer Advocacy Network please 14.0% annoy 6.1%
BO08 National Media please 13.0% annoy 1.5%
BO04 Mayors' Network please 8.9% annoy 0.0%
BO31 Party Activists please 8.8% annoy 0.0%
BO23 Taxpayers' Alliance please 8.6% annoy 1.3%
BO18 Constituency Voters please 7.9% annoy 3.4%
BO11 Students United please 7.1% annoy 7.5%
BO06 Neighborhood Associations please 7.0% annoy 0.1%
BO01 Party Headquarters please 6.9% annoy 6.0%
BO25 Small Business Owners' Association please 6.7% annoy 2.5%
BO28 Ainu Community Council please 6.5% annoy 0.0%
BO02 Party Faction please 6.5% annoy 4.5%
BO30 Rural Revitalization Council please 6.2% annoy 5.8%
BO21 Care and Welfare Council please 5.7% annoy 6.2%
BO09 Labor Federation please 5.6% annoy 6.2%
BO03 Local Kōenkai please 5.4% annoy 0.1%
BO12 Family Network please 5.4% annoy 0.0%
BO32 Candidate Selection Committee please 5.1% annoy 0.0%
BO17 Members of Parliament please 5.0% annoy 7.6%
BO29 Ainu Language and Culture Foundation please 4.6% annoy 0.0%
BO27 Urban Neighborhood Alliance please 4.5% annoy 7.7%
BO22 Veterans' Association please 4.5% annoy 0.9%
BO10 Agricultural Cooperatives please 4.0% annoy 1.8%
BO20 Shrine Association please 3.8% annoy 0.3%
BO13 Yezo Artisans Guild please 3.8% annoy 2.8%
BO19 Buddhist Temples Association please 3.7% annoy 0.1%
BO16 Innovation Society please 3.6% annoy 2.6%
BO14 Commuter Committee please 3.4% annoy 0.0%
BO05 Chamber of Commerce please 3.3% annoy 17.1%
BO15 Our Traditional Society please 3.3% annoy 8.9%
BO24 Financial Industry Association please 3.3% annoy 11.4%
BO07 Fisheries Cooperative please 2.9% annoy 0.0%
```

## 3. Parties: their organizations of interest (Party Standing tab)

```
OWN OWN orgs ['BO01', 'BO02', 'BO17', 'BO31', 'BO32'] | levels rewarding one of them 14 | penalizing 0 | bill levels whose law (if passed) pleases one 1
PT01 Butsutou orgs ['BO12', 'BO19', 'BO21', 'BO06', 'BO20', 'BO15', 'BO10', 'BO11', 'BO05', 'BO24'] | levels rewarding one of them 30 | penalizing 0 | bill levels whose law (if passed) pleases one 30
PT02 Yezo Heritage Party orgs ['BO28', 'BO29', 'BO07', 'BO13', 'BO10', 'BO11', 'BO12'] | levels rewarding one of them 21 | penalizing 0 | bill levels whose law (if passed) pleases one 21
PT03 Frontier Party orgs ['BO10', 'BO07', 'BO30', 'BO06', 'BO04', 'BO03', 'BO18', 'BO14', 'BO09', 'BO05', 'BO24'] | levels rewarding one of them 29 | penalizing 0 | bill levels whose law (if passed) pleases one 24
PT04 Five Point Independents orgs ['BO08', 'BO26', 'BO27', 'BO18', 'BO14', 'BO11', 'BO13', 'BO03', 'BO16', 'BO09', 'BO05'] | levels rewarding one of them 35 | penalizing 0 | bill levels whose law (if passed) pleases one 29
PT05 Keizaijiyuutou orgs ['BO05', 'BO24', 'BO23', 'BO16', 'BO25', 'BO27', 'BO08', 'BO13', 'BO09', 'BO10', 'BO30'] | levels rewarding one of them 30 | penalizing 0 | bill levels whose law (if passed) pleases one 32
PT06 Country Initiative orgs ['BO15', 'BO22', 'BO20', 'BO12', 'BO03', 'BO10', 'BO05', 'BO11', 'BO09', 'BO08', 'BO16'] | levels rewarding one of them 36 | penalizing 0 | bill levels whose law (if passed) pleases one 37

```

Weighted by each party's own organization weights (Party Standing tab), the levels' direct Win rewards:

```
OWN OWN weighted level-reward total 129 over 14 levels
PT01 Butsutou weighted level-reward total 146 over 21 levels
PT02 Yezo Heritage Party weighted level-reward total 103 over 21 levels
PT03 Frontier Party weighted level-reward total 224 over 24 levels
PT04 Five Point Independents weighted level-reward total 300 over 35 levels
PT05 Keizaijiyuutou weighted level-reward total 115 over 23 levels
PT06 Country Initiative weighted level-reward total 128 over 28 levels
```

## 4. A worked probe: Our Traditional Society (BO15)

```
BO15 levels (reward on win): [('LV24', 'Guarding the Old Order'), ('LV19', 'Bridging Old Guard and New Wave'), ('LV26', 'Coalition Building 101'), ('LV15', 'Courting the Traditionalist Wing'), ('LV30', 'A Grand Bargain')]
BO15 bill levels whose law pleases if passed: [('LV51', 'Strategic Land and Port Screening Act'), ('LV76', 'Farm Succession Support Act'), ('LV59', 'Moral Education Curriculum Act'), ('LV43', 'Temple and Shrine Heritage Act'), ('LV46', 'Organized Crime Conspiracy Act'), ('LV48', 'National Emergency Powers Act'), ('LV35', 'Chishima Coastal Defense Modernization Act'), ('LV71', 'Shipbuilding and Defense Industry Act')]
BO15 bill levels whose law annoys if passed: [('LV36', 'Specified Skilled Worker Visa Act'), ('LV60', 'Foreign Resident Local Suffrage Act'), ('LV73', 'Japan Customs and Border Cooperation Act'), ('LV53', 'Chishima Joint Economic Activity Act'), ('LV52', 'Inbound Tourism Visa Waiver Act'), ('LV47', 'Partnership Registration Act'), ('LV31', 'Ainu Heritage and Language Act')]
events BO15 + ['EV24', 'EV48'] - ['EV48', 'EV49']

```

## 5. Findings for Cameron

1. **Direct level rewards are uneven.** Local Kōenkai, Mayors' Network and Chamber of Commerce are raised by 10 levels each; Constituency Voters, Buddhist Temples, Financial Industry, Ainu Language and Culture, Rural Revitalization by 1; Party Activists and Candidate Selection Committee by none. No level lowers anyone on a win.
2. **Questions: three organizations are much easier to annoy than to please.** Chamber of Commerce (3.3% please / 17.1% annoy), Financial Industry (3.3% / 11.4%), Our Traditional Society (3.3% / 8.9%). Consumer Advocacy (14.0%) and National Media (13.0%) are the easiest to please.
3. **Visitors rarely touch** Buddhist Temples (1 level) and Small Business Owners (8 levels); every other organization appears in 43-50.
4. **Events**: Chamber of Commerce, National Media, Agricultural Cooperatives, Artisans Guild, Commuter Committee, Taxpayers, Financial Industry and Consumer Advocacy appear in no event; Neighborhood Associations in 6.
5. **Parties**: by weighted direct rewards Five Point Independents lead (300 over 35 levels) and Yezo Heritage Party trail (103 over 21). Country Initiative's organizations are rewarded by 28 levels (128 weighted) and its laws favor it in 37 bill outcomes.

## 6. Cameron's decisions (2026-10-31) and what changed

| Item | Decision | Done |
|---|---|---|
| OP15 in Agriculture fishing hearings | Remove; use an Agriculture member. (Edward Grinner is not PC03 — PC03 is Arata Ran; the audit's note was wrong.) | OP15 off ST31 and ST57; OP06 (Committee on Agriculture, seated nowhere before) added to both |
| Campus Q&A questions | Its own questions only | Town Hall pool switched off for ST273; 33 more student questions (45 in all, 3x its 15 turns) |
| Uneven level rewards | Draft rewards so each organization is raised by 3+ levels | 22 Win ΔBO cells on fitting generic levels and outings; every organization now 3+ (drafts) |
| Questions annoy Chamber / Financial / Traditional Society more than they please | Leave as is | — |
| Visitors rarely touch Temples and Small Business Owners | Draft dilemmas | VQ394-VQ397 (Shop Owner x2, Granny Chiyo, Shrine Priest), inside the Office Hours budget: Temples 1 to 43 levels, Small Business Owners 8 to 48 |
| Eight organizations with no event | One event each | EV54-EV61 (Chamber, National Media, Agricultural Co-ops, Artisans, Commuters, Taxpayers, Financial Industry, Consumer Advocacy), each with a send-staff choice and a Decline by the 1.5x rule |
| Party balance | Leave as is | — |
| Student names | Cameron names them | Placeholders stay |
