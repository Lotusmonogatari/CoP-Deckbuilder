# Bill Components audit (2026-11-03)

Phase 1 of `design/prompts/COMPONENT_REVISION_PROMPTS_2026-11-03.md`: every one of the 180 bill parts checked for phrase, tags, loser, gains, hearing committee and exclusions. All edits were made in the workbook (`Bill Components` tab) with `wbx.py`. All of it is draft content for Cameron to correct.

## Summary

| Check | Result |
|---|---|
| Phrases | All 180 start with a lower-case verb, none says "this bill", all read after "a plan to". One flagged clock word, CB058 "in their first year", is a tax term, not a game date; left as is because questions and cues quote the phrase. |
| Value Tags | Every dimension exists in Party Values. One tag fixed (CB254: public loans are not Economic Liberalization). CB059's Democratic Norms tag is a stretch, but changing it made two amended patron bills uncarryable, so it stays. |
| Losers rated | Good 44, Fair 50, Poor 86. Every Poor loser replaced. 114 losers changed in all (some Fair ones too, to spread the load). |
| 12% cap (21 parts) | Held: the most any organization now loses is 21 (was 24). |
| Party bodies as losers | Down from 21 to 3, all on party matters: open committee hearings and petitions (Party Faction), political ad disclosure (Party Headquarters). |
| Gains | Every part gains its owner. 25 parts now also gain a natural second organization by +1. |
| Hearing committees | 25 parts moved out of Government Administration (72 to 47); the Cabinet committee (ST18) now hears 4 parts. Every committee used has at least 4 parts and seated opponents. |
| Excludes | 8 new pairs, entered on both rows. |
| Lobbyist spread | Chamber of Commerce lobbyist share in trades fell from about 34% to 25% (`visit_review.gd` stats); all 10 lobbyist organizations appear. |
| Checks | Export "No errors"; unit tests 1,693 passing; `bill_audit.gd` vote results unchanged. |

## Losers per organization

| Organization | Before | After |
|---|---|---|
| Taxpayers' Alliance (BO23) | 23 | 21 |
| Chamber of Commerce (BO05) | 24 | 21 |
| Urban Neighborhood Alliance (BO27) | 21 | 21 |
| Small Business Owners' Association (BO25) | 6 | 16 |
| Mayors' Network (BO04) | 4 | 15 |
| Consumer Advocacy Network (BO26) | 8 | 9 |
| Our Traditional Society (BO15) | 9 | 8 |
| Labor Federation (BO09) | 7 | 8 |
| Students United (BO11) | 12 | 7 |
| Neighborhood Associations (BO06) | 5 | 7 |
| Financial Industry Association (BO24) | 5 | 6 |
| Local Kōenkai (BO03) | 5 | 6 |
| Care and Welfare Council (BO21) | 1 | 5 |
| Agricultural Cooperatives (BO10) | 13 | 4 |
| Rural Revitalization Council (BO30) | 0 | 3 |
| Members of Parliament (BO17) | 10 | 3 |
| Shrine Association (BO20) | 0 | 3 |
| Fisheries Cooperative (BO07) | 2 | 2 |
| Ainu Language and Culture Foundation (BO29) | 0 | 2 |
| Party Faction (BO02) | 5 | 2 |
| Commuter Committee (BO14) | 0 | 2 |
| Family Network (BO12) | 2 | 2 |
| Buddhist Temples Association (BO19) | 1 | 2 |
| National Media (BO08) | 0 | 1 |
| Party Headquarters (BO01) | 16 | 1 |
| Innovation Society (BO16) | 0 | 1 |
| Ainu Community Council (BO28) | 1 | 1 |
| Constituency Voters (BO18) | 0 | 1 |

Organizations that still never lose a part: Candidate Selection Committee, Party Activists, Veterans' Association, Yezo Artisans Guild.

## Hearing committees

| Committee | Before | After |
|---|---|---|
| Ethics and Prosecution (ST09) | 4 | 9 |
| the Environment (ST10) | 7 | 9 |
| War (ST11) | 5 | 5 |
| the National Assembly (ST12) | 6 | 11 |
| Agriculture (ST13) | 13 | 13 |
| Foreign Affairs (ST14) | 5 | 5 |
| Construction and Development (ST15) | 31 | 36 |
| Finance (ST16) | 37 | 41 |
| Government Administration (ST17) | 72 | 47 |
| the Cabinet (ST18) | 0 | 4 |

| Part | Phrase | From | To |
|---|---|---|---|
| CB034 | fund district office staff training | ST17 | ST12 |
| CB035 | let district offices hold open town days | ST17 | ST12 |
| CB036 | fund district offices that help citizens file paperwork | ST17 | ST12 |
| CB037 | publish a directory of district services | ST17 | ST12 |
| CB041 | give towns unconditional block grants | ST17 | ST16 |
| CB042 | let towns borrow for local projects | ST17 | ST16 |
| CB045 | fund town planning staff | ST17 | ST15 |
| CB062 | support neighborhood watch groups | ST17 | ST09 |
| CB081 | strengthen freedom of information requests | ST17 | ST09 |
| CB084 | require government data to be published in open formats | ST17 | ST18 |
| CB134 | fund craft workshops in vacant shopfronts | ST17 | ST15 |
| CB137 | fund a national craft museum | ST17 | ST15 |
| CB146 | publish real-time delay data for every line | ST17 | ST15 |
| CB163 | move government services online | ST17 | ST18 |
| CB164 | open public data to start-ups | ST17 | ST18 |
| CB181 | hold local referendums on large projects | ST17 | ST12 |
| CB184 | publish every project's full costs for public comment | ST17 | ST16 |
| CB186 | let residents vote on local budget priorities | ST17 | ST16 |
| CB191 | fund temple preservation | ST17 | ST15 |
| CB208 | let festival organizers close streets without extra fees | ST17 | ST15 |
| CB232 | publish the full cost of every bill | ST16 | ST18 |
| CB255 | waive licensing fees for micro-enterprises | ST17 | ST16 |
| CB262 | give buyers a cooling-off period | ST17 | ST09 |
| CB265 | require plain-language contracts | ST17 | ST09 |
| CB266 | publish product safety recalls in one public list | ST17 | ST09 |
| CB275 | fund bike lanes in city centers | ST15 | ST10 |
| CB277 | open vacant city lots to community gardens | ST15 | ST10 |
| CB308 | support remote work hubs in villages | ST17 | ST15 |

Why: district-office parts belong to the National Assembly committee (members' offices are Assembly business); grants, borrowing and costings to Finance; buildings, streets and transport to Construction; legal remedies, policing and disclosure to Ethics and Prosecution; whole-of-government digital and data parts to the Cabinet committee; parks-style parts to the Environment.

## Every part's loser

| Part | Owner | Phrase | Old loser | Rating | New loser | Reason |
|---|---|---|---|---|---|---|
| CB031 | Local Kōenkai | raise allowances for district offices | Taxpayers' Alliance | Good | Constituency Voters | Voters resent MP perks more than any lobby does. |
| CB032 | Local Kōenkai | ease the rules on constituent gatherings | Members of Parliament | Poor | Neighborhood Associations | MPs would welcome looser rules; neighborhood associations host and police these gatherings in their halls. |
| CB033 | Local Kōenkai | create a constituency development fund | Taxpayers' Alliance | Good |  | A discretionary fund is the Taxpayers' Alliance's classic target. |
| CB034 | Local Kōenkai | fund district office staff training | Members of Parliament | Poor | Mayors' Network | MP district offices duplicate what town halls already staff. |
| CB035 | Local Kōenkai | let district offices hold open town days | Party Headquarters | Poor | Mayors' Network | A party body has no stake; town halls see MP town days as a rival front desk. |
| CB036 | Local Kōenkai | fund district offices that help citizens file paperwork | Members of Parliament | Poor | Mayors' Network | MPs gain; municipal offices lose the paperwork role they already fill. |
| CB037 | Local Kōenkai | publish a directory of district services | Party Headquarters | Poor | Mayors' Network | A party body has no stake; towns would rather publish their own service guides. |
| CB041 | Mayors' Network | give towns unconditional block grants | Party Headquarters | Poor | Local Kōenkai | No-strings grants bypass the MP-delivered projects a kōenkai trades on. |
| CB042 | Mayors' Network | let towns borrow for local projects | Members of Parliament | Poor | Taxpayers' Alliance | MPs have no reason to object; local debt is a taxpayer worry. |
| CB043 | Mayors' Network | give towns their own tax-setting powers | Party Headquarters | Poor | Small Business Owners' Association | A patchwork of local taxes hits small firms hardest. |
| CB044 | Mayors' Network | let towns merge services across borders | Members of Parliament | Poor | Neighborhood Associations | Merged services close the local counters neighborhood associations rely on. |
| CB045 | Mayors' Network | fund town planning staff | Party Headquarters | Poor | Neighborhood Associations | Professional planners override residents' own say. |
| CB051 | Chamber of Commerce | cut the corporate tax rate | Labor Federation | Good |  | Unions oppose corporate tax cuts. |
| CB052 | Chamber of Commerce | simplify business licensing | Consumer Advocacy Network | Good |  | Consumer groups see licensing as protection. |
| CB053 | Chamber of Commerce | open special economic zones | Agricultural Cooperatives | Good |  | Special zones invite cheap imports that farm cooperatives fight. |
| CB054 | Chamber of Commerce | speed up customs clearance at Hokkaido ports | Our Traditional Society | Poor | Fisheries Cooperative | Faster customs means more imported fish at the same ports. |
| CB055 | Chamber of Commerce | end paper filing for company registration | Labor Federation | Poor | Small Business Owners' Association | Unions have no stake; small firms without digital tools bear the switch. |
| CB056 | Chamber of Commerce | open a single window for business permits | Consumer Advocacy Network | Poor | Mayors' Network | Consumers lose nothing; town permit offices lose control of their own approvals. |
| CB057 | Chamber of Commerce | let businesses take on apprentices without extra forms | Labor Federation | Good |  | Unions guard apprentice protections. |
| CB058 | Chamber of Commerce | give new firms a tax holiday in their first year | Care and Welfare Council | Poor | Small Business Owners' Association | Welfare is a stretch; established small firms face subsidized new rivals. |
| CB059 | Chamber of Commerce | guarantee payment within sixty days on public contracts | Neighborhood Associations | Poor | Mayors' Network | Neighborhood associations have no stake; towns are among the slow payers. |
| CB061 | Neighborhood Associations | fund repairs to community halls | Taxpayers' Alliance | Good |  | Public money for halls draws the Taxpayers' Alliance. |
| CB062 | Neighborhood Associations | support neighborhood watch groups | Members of Parliament | Poor | Students United | MPs have no stake; young people are the ones patrols stop. |
| CB063 | Neighborhood Associations | give neighborhood associations legal standing in planning | Party Headquarters | Poor | Urban Neighborhood Alliance | A party body has no stake; legal standing lets block associations stall city housing. |
| CB064 | Neighborhood Associations | give neighborhood associations a seat on planning boards | Members of Parliament | Poor | Urban Neighborhood Alliance | A planning seat lets block associations stall city housing. |
| CB065 | Neighborhood Associations | fund street lighting in residential blocks | Party Headquarters | Poor | Taxpayers' Alliance | A party body has no stake; it is a new running cost. |
| CB066 | Neighborhood Associations | fund neighborhood cleanup days | Members of Parliament | Poor | Shrine Association | Shrines already lead the local cleanups and would lose that role. |
| CB067 | Neighborhood Associations | let neighborhood associations run small local grants | Party Headquarters | Poor | Local Kōenkai | Local grant-making takes a patronage tool away from the MP's kōenkai. |
| CB071 | Fisheries Cooperative | fund harbor repairs | Chamber of Commerce | Poor | Urban Neighborhood Alliance | Business gains from working harbors; city groups see rural spending. |
| CB072 | Fisheries Cooperative | subsidize fuel for fishing boats | Taxpayers' Alliance | Good |  | A fuel subsidy is a spending and climate target. |
| CB073 | Fisheries Cooperative | hold fishing quotas through local cooperatives | Party Headquarters | Poor | Ainu Community Council | A party body has no stake; cooperative quotas cut across Ainu fishing claims. |
| CB074 | Fisheries Cooperative | set up a fisheries disaster relief fund | Chamber of Commerce | Poor | Financial Industry Association | A public relief fund crowds out private marine insurance. |
| CB075 | Fisheries Cooperative | fund new cold storage at fishing ports | Taxpayers' Alliance | Fair | Agricultural Cooperatives | Farm cooperatives want the same storage subsidy for grain. |
| CB076 | Fisheries Cooperative | protect coastal fishing grounds from industrial dumping | Chamber of Commerce | Good |  | Industry is the dumper this restricts. |
| CB077 | Fisheries Cooperative | support direct sales of catch to local markets | Party Headquarters | Poor | Small Business Owners' Association | A party body has no stake; fishmongers and wholesalers lose the catch. |
| CB081 | National Media | strengthen freedom of information requests | Members of Parliament | Good |  | MPs and ministers dislike wider disclosure. |
| CB082 | National Media | protect reporters' confidential sources | Our Traditional Society | Poor | Members of Parliament | Traditionalists have no stake; MPs are the ones leaked about. |
| CB083 | National Media | open every committee hearing to the press | Party Faction | Good |  | Factions deal in closed rooms; this is a party matter. |
| CB084 | National Media | require government data to be published in open formats | Local Kōenkai | Poor | Members of Parliament | A kōenkai has no stake; ministries and MPs lose control of release. |
| CB085 | National Media | protect journalists from lawsuits meant to silence them | Our Traditional Society | Poor | Financial Industry Association | Traditionalists have no stake; banks and large firms are the usual litigants. |
| CB086 | National Media | guarantee press access to public meetings | Party Headquarters | Poor | Mayors' Network | A party body has no stake; town councils hold many closed meetings. |
| CB087 | National Media | fund local news outlets in small towns | Taxpayers' Alliance | Good |  | A subsidy draws the Taxpayers' Alliance. |
| CB088 | National Media | require disclosure of who pays for political advertising | Party Headquarters | Good |  | Party funding is a party matter. |
| CB091 | Labor Federation | raise the minimum wage | Small Business Owners' Association | Good |  | Small employers carry a wage rise. |
| CB092 | Labor Federation | enforce overtime pay | Financial Industry Association | Poor | Small Business Owners' Association | Banks are not the main offenders; small employers pay the overtime. |
| CB093 | Labor Federation | protect collective bargaining rights | Chamber of Commerce | Good |  | Business opposes bargaining rights. |
| CB094 | Labor Federation | guarantee a living wage on public contracts | Small Business Owners' Association | Good |  | Small contractors bid on public work. |
| CB095 | Labor Federation | ban unpaid trial work | Financial Industry Association | Poor | Small Business Owners' Association | Banks rarely use trial work; small shops and restaurants do. |
| CB101 | Agricultural Cooperatives | support the rice price | Chamber of Commerce | Poor | Consumer Advocacy Network | Business is indirect; shoppers pay the higher rice price. |
| CB102 | Agricultural Cooperatives | subsidize farm machinery | Urban Neighborhood Alliance | Fair |  | City groups object to farm spending; indirect. |
| CB103 | Agricultural Cooperatives | restrict foreign food imports | Chamber of Commerce | Good |  | Import restrictions hit traders and business. |
| CB104 | Agricultural Cooperatives | pay farmers to keep paddies in use | Urban Neighborhood Alliance | Fair |  | City groups see rural spending. |
| CB105 | Agricultural Cooperatives | fund grain storage for farm cooperatives | Chamber of Commerce | Poor | Urban Neighborhood Alliance | City groups see another rural subsidy. |
| CB106 | Agricultural Cooperatives | start a farm-to-school lunch program | Urban Neighborhood Alliance | Poor | Small Business Owners' Association | City groups have no stake; school caterers lose contracts. |
| CB107 | Agricultural Cooperatives | insure farmers against bad harvests | Chamber of Commerce | Poor | Financial Industry Association | Business has no stake; private insurers are crowded out. |
| CB108 | Agricultural Cooperatives | support farmers' direct sales at city markets | Urban Neighborhood Alliance | Poor | Small Business Owners' Association | City groups like the markets; city grocers lose sales. |
| CB111 | Students United | cap university tuition | Taxpayers' Alliance | Good |  | A tuition cap is a spending target. |
| CB112 | Students United | give students discounted transit | Taxpayers' Alliance | Fair |  | A cost objection. |
| CB113 | Students United | build public student housing | Chamber of Commerce | Fair |  | Landlords and developers face public competition. |
| CB114 | Students United | forgive student loans for graduates who work in rural towns | Taxpayers' Alliance | Good |  | Loan forgiveness is a spending target. |
| CB115 | Students United | fund scholarships for first-generation students | Taxpayers' Alliance | Fair |  | A cost objection. |
| CB121 | Family Network | raise the child allowance | Taxpayers' Alliance | Good | Care and Welfare Council | Elder-care groups compete for the same welfare budget. |
| CB122 | Family Network | extend paid parental leave | Buddhist Temples Association | Poor | Small Business Owners' Association | Temples have no stake; small employers cover the absence. |
| CB123 | Family Network | open more public childcare places | Taxpayers' Alliance | Good |  | A spending target. |
| CB124 | Family Network | make school lunches free | Taxpayers' Alliance | Good |  | A spending target. |
| CB125 | Family Network | give families a tax deduction for each child | Mayors' Network | Poor | Students United | Mayors have no stake; childless young adults carry the tax base. |
| CB126 | Family Network | fund after-school care in every district | Taxpayers' Alliance | Good | Care and Welfare Council | Elder-care groups compete for the same welfare budget. |
| CB127 | Family Network | let parents work shorter hours while children are young | Small Business Owners' Association | Good |  | Small employers absorb shorter hours. |
| CB131 | Yezo Artisans Guild | certify local crafts with a protected label | Urban Neighborhood Alliance | Poor | Chamber of Commerce | City groups have no stake; mass producers lose the name. |
| CB132 | Yezo Artisans Guild | give tax relief for craft apprenticeships | Labor Federation | Fair |  | Unions worry about cheap apprentice labor. |
| CB133 | Yezo Artisans Guild | promote craft exports abroad | Agricultural Cooperatives | Poor | Innovation Society | Innovators want export support spent on technology instead. |
| CB134 | Yezo Artisans Guild | fund craft workshops in vacant shopfronts | Students United | Poor | Urban Neighborhood Alliance | Students have no stake; city groups want those shopfronts as homes and shops. |
| CB135 | Yezo Artisans Guild | waive fees at craft fairs for small makers | Urban Neighborhood Alliance | Poor | Mayors' Network | City groups have no stake; towns lose fee income. |
| CB136 | Yezo Artisans Guild | register master craftspeople as cultural assets | Students United | Poor | Labor Federation | Students have no stake; a ranked status for some workers concerns unions. |
| CB137 | Yezo Artisans Guild | fund a national craft museum | Urban Neighborhood Alliance | Fair | Ainu Language and Culture Foundation | Ainu cultural groups compete for national museum funding. |
| CB141 | Commuter Committee | freeze commuter fares | Taxpayers' Alliance | Good |  | A fare freeze is a subsidy. |
| CB142 | Commuter Committee | run late-night commuter trains | Taxpayers' Alliance | Fair | Neighborhood Associations | Late trains bring noise to the blocks along the line. |
| CB143 | Commuter Committee | make every station step-free | Chamber of Commerce | Poor | Taxpayers' Alliance | Business has no stake; it is a large spending item. |
| CB144 | Commuter Committee | build park-and-ride lots at commuter stations | Taxpayers' Alliance | Fair | Urban Neighborhood Alliance | Park-and-ride favors drivers over city transit and land. |
| CB145 | Commuter Committee | cap the monthly cost of a commuter pass | Taxpayers' Alliance | Good |  | A fare cap is a subsidy. |
| CB146 | Commuter Committee | publish real-time delay data for every line | Local Kōenkai | Poor | Chamber of Commerce | A kōenkai has no stake; rail operators lose control of their record. |
| CB147 | Commuter Committee | refund fares for long delays | Chamber of Commerce | Good |  | Rail companies pay the refunds. |
| CB151 | Our Traditional Society | fund local festivals | Urban Neighborhood Alliance | Fair | Taxpayers' Alliance | A spending target more than a city one. |
| CB152 | Our Traditional Society | protect historic districts from redevelopment | Students United | Poor | Urban Neighborhood Alliance | Students have no stake; city groups need new housing. |
| CB153 | Our Traditional Society | create a national heritage register | Urban Neighborhood Alliance | Fair |  | A register limits city redevelopment. |
| CB154 | Our Traditional Society | teach local traditions in schools | Students United | Fair |  | Students object to compulsory curriculum time. |
| CB155 | Our Traditional Society | fund the repair of old wooden buildings | Urban Neighborhood Alliance | Fair |  | City groups want old buildings replaced with homes. |
| CB156 | Our Traditional Society | support traditional crafts in school clubs | Students United | Poor | Labor Federation | Students have no stake; the teachers' unions run club time. |
| CB157 | Our Traditional Society | protect old town names on maps and signs | Urban Neighborhood Alliance | Fair | Mayors' Network | Merged towns renamed their places and would have to undo it. |
| CB158 | Our Traditional Society | give grants to preserve traditional farmhouses | Students United | Poor | Urban Neighborhood Alliance | City groups see another rural subsidy. |
| CB159 | Our Traditional Society | restore old rail stations as community landmarks | Urban Neighborhood Alliance | Fair | Commuter Committee | Commuters would rather the money ran trains. |
| CB161 | Innovation Society | give a tax credit for research and development | Agricultural Cooperatives | Poor | Small Business Owners' Association | Farmers have no stake; credits favor large firms over small ones. |
| CB162 | Innovation Society | offer visas to start-up founders | Our Traditional Society | Good |  | Traditionalists resist new immigration. |
| CB163 | Innovation Society | move government services online | Neighborhood Associations | Fair |  | Older residents who rely on counters are left behind. |
| CB164 | Innovation Society | open public data to start-ups | Local Kōenkai | Poor | Consumer Advocacy Network | A kōenkai has no stake; consumer groups raise privacy concerns. |
| CB165 | Innovation Society | fund university spin-off labs | Agricultural Cooperatives | Poor | Students United | Students want university money spent on teaching, not spin-offs. |
| CB166 | Innovation Society | let start-ups test products in regulatory sandboxes | Consumer Advocacy Network | Good |  | Consumer groups oppose regulatory exemptions. |
| CB167 | Innovation Society | fund coworking hubs in regional cities | Agricultural Cooperatives | Poor | Urban Neighborhood Alliance | Regional hubs pull jobs out of the cities. |
| CB181 | Constituency Voters | hold local referendums on large projects | Party Faction | Fair | Chamber of Commerce | Referendums let residents stop large projects that business wants. |
| CB182 | Constituency Voters | require public consultation before new projects | Party Headquarters | Poor | Chamber of Commerce | A party body has no stake; developers face delays. |
| CB183 | Constituency Voters | let citizen petitions trigger committee hearings | Party Faction | Good |  | Committee agendas are a party matter factions control. |
| CB184 | Constituency Voters | publish every project's full costs for public comment | Party Headquarters | Poor | Local Kōenkai | A party body has no stake; full costs expose pork projects. |
| CB185 | Constituency Voters | hold public question time with local officials | Party Faction | Poor | Mayors' Network | Factions have no stake; mayors face the questions. |
| CB186 | Constituency Voters | let residents vote on local budget priorities | Party Headquarters | Poor | Mayors' Network | A party body has no stake; mayors lose budget control. |
| CB187 | Constituency Voters | require open hearings before closing local services | Party Faction | Poor | Mayors' Network | Factions have no stake; mayors make those closure decisions. |
| CB191 | Buddhist Temples Association | fund temple preservation | Urban Neighborhood Alliance | Fair | Shrine Association | Shrines compete for the same preservation money. |
| CB192 | Buddhist Temples Association | keep the tax exemption on temple land | Students United | Fair | Mayors' Network | Towns lose the property tax. |
| CB193 | Buddhist Temples Association | designate temples as disaster shelters | Consumer Advocacy Network | Poor | Mayors' Network | Consumer groups have no stake; towns run the official shelters and their budgets. |
| CB194 | Buddhist Temples Association | fund repairs to temple halls damaged by weather | Urban Neighborhood Alliance | Fair | Shrine Association | Shrines compete for the same repair money. |
| CB195 | Buddhist Temples Association | let temples run public meditation and care programs | Students United | Poor | Care and Welfare Council | Students have no stake; the welfare council competes for care funding. |
| CB201 | Shrine Association | support shrine festivals | Students United | Fair | Buddhist Temples Association | Temples compete for the same festival support. |
| CB202 | Shrine Association | protect shrine forests from development | Agricultural Cooperatives | Fair |  | Protected forest is land farmers cannot clear. |
| CB203 | Shrine Association | list shrine grounds on the heritage register | Urban Neighborhood Alliance | Fair | Chamber of Commerce | A listing limits development on valuable land. |
| CB204 | Shrine Association | waive permit fees for shrine festival stalls | Students United | Poor | Small Business Owners' Association | Students have no stake; shops near festivals lose trade to stalls. |
| CB205 | Shrine Association | fund shrine-led community cleanups | Consumer Advocacy Network | Poor | Buddhist Temples Association | Consumer groups have no stake; temples compete for the same civic role. |
| CB206 | Shrine Association | protect sacred groves in national planning | Urban Neighborhood Alliance | Fair | Chamber of Commerce | Developers lose planning freedom. |
| CB207 | Shrine Association | record festival music and dance as living heritage | Urban Neighborhood Alliance | Poor | Ainu Language and Culture Foundation | City groups have no stake; Ainu culture groups compete for heritage listing. |
| CB208 | Shrine Association | let festival organizers close streets without extra fees | Members of Parliament | Poor | Commuter Committee | MPs have no stake; road closures disrupt commuters. |
| CB211 | Care and Welfare Council | raise care workers' wages | Taxpayers' Alliance | Good |  | A spending target. |
| CB212 | Care and Welfare Council | fund home care visits | Chamber of Commerce | Poor | Taxpayers' Alliance | Business has no stake; a spending item. |
| CB213 | Care and Welfare Council | open dementia care centers in every district | Taxpayers' Alliance | Good |  | A spending target. |
| CB214 | Care and Welfare Council | train and certify more care workers | Taxpayers' Alliance | Fair | Labor Federation | Fast-track certification undercuts care workers' pay. |
| CB215 | Care and Welfare Council | cap the cost of nursing home beds for families | Chamber of Commerce | Fair |  | Private nursing homes lose pricing freedom. |
| CB216 | Care and Welfare Council | fund respite care for family caregivers | Taxpayers' Alliance | Good |  | A spending target. |
| CB217 | Care and Welfare Council | send local care teams to visit isolated elders | Taxpayers' Alliance | Fair | Neighborhood Associations | Paid teams displace the volunteer watch associations run. |
| CB218 | Care and Welfare Council | fund care worker housing near facilities | Chamber of Commerce | Fair | Urban Neighborhood Alliance | City groups need the same scarce housing sites. |
| CB221 | Veterans' Association | raise veterans' pensions | Family Network | Fair |  | Family groups compete for the same budget. |
| CB222 | Veterans' Association | expand veterans' medical care | Students United | Fair |  | Pacifist students resist military spending. |
| CB223 | Veterans' Association | give veterans hiring preference in public jobs | Ainu Community Council | Poor | Students United | Preference cuts into openings for young job seekers more than any one minority. |
| CB224 | Veterans' Association | fund mental health care for veterans | Family Network | Fair |  | Family groups compete for the same budget. |
| CB225 | Veterans' Association | maintain war memorials and cemeteries | Students United | Good |  | Pacifist students object to war memorials. |
| CB231 | Taxpayers' Alliance | cap growth in government spending | Mayors' Network | Good |  | Towns depend on grants. |
| CB232 | Taxpayers' Alliance | publish the full cost of every bill | Local Kōenkai | Fair |  | Costing exposes pork projects. |
| CB233 | Taxpayers' Alliance | add sunset clauses to new spending | Neighborhood Associations | Fair | Care and Welfare Council | Welfare programs are the ones that would expire. |
| CB234 | Taxpayers' Alliance | require an audit of every large grant | Local Kōenkai | Good |  | Audits expose kōenkai-linked grants. |
| CB235 | Taxpayers' Alliance | post government spending online by project | Neighborhood Associations | Poor | Local Kōenkai | Neighborhood associations have no stake; project-level posting exposes pork. |
| CB241 | Financial Industry Association | ease bank lending rules | Labor Federation | Fair | Consumer Advocacy Network | Looser lending rules endanger borrowers. |
| CB242 | Financial Industry Association | create tax-free investment accounts | Mayors' Network | Poor | Labor Federation | Mayors have no stake; unions see a break for the wealthy. |
| CB243 | Financial Industry Association | build a financial hub zone in Sapporo | Agricultural Cooperatives | Fair | Rural Revitalization Council | A Sapporo hub pulls firms from the regions. |
| CB244 | Financial Industry Association | let foreign banks open branches in Hokkaido | Our Traditional Society | Fair |  | Traditionalists resist foreign ownership. |
| CB245 | Financial Industry Association | simplify the registration of investment funds | Labor Federation | Poor | Consumer Advocacy Network | Unions have no stake; investor protection is a consumer issue. |
| CB246 | Financial Industry Association | speed approval of new financial products | Consumer Advocacy Network | Good |  | Consumer groups oppose faster product approval. |
| CB247 | Financial Industry Association | fund financial literacy classes in schools | Neighborhood Associations | Poor | Labor Federation | Neighborhood associations have no stake; teachers' unions guard class time. |
| CB251 | Small Business Owners' Association | cut taxes for small businesses | Mayors' Network | Poor | Care and Welfare Council | Mayors have no stake; lost revenue squeezes welfare budgets. |
| CB252 | Small Business Owners' Association | cut paperwork for small firms | Consumer Advocacy Network | Good |  | Paperwork is consumer protection. |
| CB253 | Small Business Owners' Association | make large firms pay suppliers on time | Financial Industry Association | Poor | Chamber of Commerce | Banks have no stake; large firms pay late. |
| CB254 | Small Business Owners' Association | give small firms cheap loans for equipment | Chamber of Commerce | Fair | Financial Industry Association | Banks are crowded out by cheap public loans. |
| CB255 | Small Business Owners' Association | waive licensing fees for micro-enterprises | Labor Federation | Poor | Consumer Advocacy Network | Unions have no stake; unlicensed traders worry consumer groups. |
| CB261 | Consumer Advocacy Network | require clear price labels | Chamber of Commerce | Good |  | Business carries the labeling cost. |
| CB262 | Consumer Advocacy Network | give buyers a cooling-off period | Small Business Owners' Association | Good |  | Small sellers lose sales. |
| CB263 | Consumer Advocacy Network | cap bank fees | Financial Industry Association | Good |  | Banks lose fee income. |
| CB264 | Consumer Advocacy Network | let consumers sue together over defective goods | Chamber of Commerce | Good |  | Manufacturers face lawsuits. |
| CB265 | Consumer Advocacy Network | require plain-language contracts | Small Business Owners' Association | Fair | Financial Industry Association | Banks and insurers write the densest contracts. |
| CB266 | Consumer Advocacy Network | publish product safety recalls in one public list | Financial Industry Association | Poor | Chamber of Commerce | Banks have no stake; manufacturers are named in recalls. |
| CB267 | Consumer Advocacy Network | set up a free consumer complaint line | Chamber of Commerce | Fair |  | Business fields the complaints. |
| CB271 | Urban Neighborhood Alliance | set an affordable housing quota for new buildings | Small Business Owners' Association | Fair | Chamber of Commerce | Developers carry the quota. |
| CB272 | Urban Neighborhood Alliance | build more city parks | Fisheries Cooperative | Poor | Rural Revitalization Council | Fishers have no stake; rural groups see city spending. |
| CB273 | Urban Neighborhood Alliance | cap rent rises in the cities | Chamber of Commerce | Good |  | Landlords and developers lose rent income. |
| CB274 | Urban Neighborhood Alliance | allow denser housing near stations | Consumer Advocacy Network | Poor | Neighborhood Associations | Consumer groups have no stake; residents resist density. |
| CB275 | Urban Neighborhood Alliance | fund bike lanes in city centers | Fisheries Cooperative | Poor | Small Business Owners' Association | Fishers have no stake; shops lose parking. |
| CB276 | Urban Neighborhood Alliance | fund street trees and shade in city centers | Chamber of Commerce | Poor | Rural Revitalization Council | Business has no stake; rural groups see city spending. |
| CB277 | Urban Neighborhood Alliance | open vacant city lots to community gardens | Party Headquarters | Poor | Chamber of Commerce | A party body has no stake; developers want the lots. |
| CB281 | Ainu Community Council | restore Ainu fishing and harvest rights | Agricultural Cooperatives | Fair | Fisheries Cooperative | Fishing rights come out of the cooperatives' own quota. |
| CB282 | Ainu Community Council | fund Ainu community centers | Our Traditional Society | Fair |  | Traditionalists resist the shift in cultural funding. |
| CB283 | Ainu Community Council | require consultation with Ainu communities on land use | Agricultural Cooperatives | Fair |  | Consultation slows farmland decisions. |
| CB284 | Ainu Community Council | return ceremonial sites to Ainu stewardship | Our Traditional Society | Fair |  | Traditionalists dispute who stewards the sites. |
| CB285 | Ainu Community Council | fund Ainu elders' knowledge programs | Agricultural Cooperatives | Poor | Our Traditional Society | Traditionalists compete for the same cultural funding. |
| CB291 | Ainu Language and Culture Foundation | expand Ainu-language translation of public documents | Agricultural Cooperatives | Poor | Taxpayers' Alliance | Farmers have no stake; a spending item. |
| CB292 | Ainu Language and Culture Foundation | teach the Ainu language in schools | Our Traditional Society | Fair |  | Traditionalists dispute curriculum time. |
| CB293 | Ainu Language and Culture Foundation | fund Ainu-language broadcasting | Agricultural Cooperatives | Poor | National Media | Farmers have no stake; the national media compete for broadcast funding. |
| CB294 | Ainu Language and Culture Foundation | fund museum exhibits and archives on Ainu culture | Our Traditional Society | Fair |  | Traditionalists dispute the national story. |
| CB295 | Ainu Language and Culture Foundation | support Ainu language classes for adults | Agricultural Cooperatives | Poor | Our Traditional Society | Traditionalists compete for the same cultural funding. |
| CB301 | Rural Revitalization Council | keep rural bus routes running | Chamber of Commerce | Poor | Urban Neighborhood Alliance | Business has no stake; city groups see rural subsidy. |
| CB302 | Rural Revitalization Council | pay grants to families moving to rural towns | Urban Neighborhood Alliance | Good |  | Cities lose residents. |
| CB303 | Rural Revitalization Council | bring broadband to every village | Chamber of Commerce | Poor | Urban Neighborhood Alliance | Business gains from broadband; city groups see rural spending. |
| CB304 | Rural Revitalization Council | fund clinics in rural towns | Urban Neighborhood Alliance | Fair |  | City groups see rural spending. |
| CB305 | Rural Revitalization Council | give tax breaks to firms opening in rural towns | Chamber of Commerce | Fair | Urban Neighborhood Alliance | Rural tax breaks pull firms out of the cities. |
| CB306 | Rural Revitalization Council | support small-town shops with rent grants | Urban Neighborhood Alliance | Poor | Chamber of Commerce | City groups have no stake; chains compete with the subsidized shops. |
| CB307 | Rural Revitalization Council | fund rural school buses | Chamber of Commerce | Poor | Urban Neighborhood Alliance | City groups see another rural subsidy. |
| CB308 | Rural Revitalization Council | support remote work hubs in villages | Urban Neighborhood Alliance | Fair |  | City groups see work leaving the city. |

## Second gains (+1)

| Part | Phrase | Also gains |
|---|---|---|
| CB051 | cut the corporate tax rate | Financial Industry Association |
| CB053 | open special economic zones | Innovation Society |
| CB091 | raise the minimum wage | Students United |
| CB101 | support the rice price | Rural Revitalization Council |
| CB106 | start a farm-to-school lunch program | Family Network |
| CB112 | give students discounted transit | Commuter Committee |
| CB114 | forgive student loans for graduates who work in rural towns | Rural Revitalization Council |
| CB136 | register master craftspeople as cultural assets | Our Traditional Society |
| CB143 | make every station step-free | Care and Welfare Council |
| CB151 | fund local festivals | Shrine Association |
| CB152 | protect historic districts from redevelopment | Yezo Artisans Guild |
| CB155 | fund the repair of old wooden buildings | Yezo Artisans Guild |
| CB158 | give grants to preserve traditional farmhouses | Rural Revitalization Council |
| CB167 | fund coworking hubs in regional cities | Rural Revitalization Council |
| CB193 | designate temples as disaster shelters | Neighborhood Associations |
| CB201 | support shrine festivals | Our Traditional Society |
| CB207 | record festival music and dance as living heritage | Our Traditional Society |
| CB213 | open dementia care centers in every district | Family Network |
| CB216 | fund respite care for family caregivers | Family Network |
| CB225 | maintain war memorials and cemeteries | Our Traditional Society |
| CB281 | restore Ainu fishing and harvest rights | Ainu Language and Culture Foundation |
| CB284 | return ceremonial sites to Ainu stewardship | Ainu Language and Culture Foundation |
| CB292 | teach the Ainu language in schools | Ainu Community Council |
| CB303 | bring broadband to every village | Innovation Society |
| CB304 | fund clinics in rural towns | Care and Welfare Council |

## New Excludes

| Pair | Why |
|---|---|
| CB103 and CB053 | restricting food imports against opening special economic zones |
| CB103 and CB054 | restricting imports against faster customs |
| CB152 and CB274 | freezing historic districts against denser housing |
| CB141 and CB145 | two fare subsidies that say the same thing |
| CB084 and CB164 | two open-data parts that say the same thing |
| CB153 and CB203 | a heritage register twice |
| CB184 and CB235 | publishing project costs twice |
| CB232 and CB235 | publishing costs twice |

## Thirty random three-part drafts

Read aloud, the drafts are grammatical; the weak point is sprawl, which a free draft invites. The ten least coherent:

| # | Mix | Problem |
|---|---|---|
| 1 | cap growth in government spending + fund new cold storage + apprentices without forms | a spending cap beside new spending |
| 2 | open special economic zones + cap rent rises + cut paperwork | liberalize and control in one breath |
| 3 | cut taxes for small businesses + rural tax breaks + collective bargaining | two tax cuts and a union right |
| 4 | child allowance + street lighting + faster financial products | three unrelated portfolios |
| 5 | bank lending rules + temple hall repairs + rail delay data | three unrelated portfolios |
| 6 | temple meditation programs + reporters' sources + investment funds | three unrelated portfolios |
| 7 | home care visits + cooling-off period + festival music heritage | three unrelated portfolios |
| 8 | street trees + cooling-off period + special economic zones | three unrelated portfolios |
| 9 | neighborhood planning standing + foreign banks + faster customs | local control beside opening up |
| 10 | open committee hearings + care worker housing + temple care programs | three unrelated portfolios |

No new exclusion is proposed for sprawl itself; see the decisions below.

## Decisions for Cameron

| # | Question | My suggestion |
|---|---|---|
| 1 | Should the Cabinet committee (ST18) hear draft and patron bills at all? It now hears 4 digital-government and costing parts. | Keep; it spreads risk and suits whole-of-government parts. |
| 2 | A spending cap (CB231) can sit beside new spending. Exclude it from the big spending parts, warn softly, or leave it as a political compromise? | Leave it; real bills do this. |
| 3 | Sprawling drafts: add a soft warning when the three parts share no policy tag? | Not now; a draft is the player's own mix. |
| 4 | Eleven organizations still never lose a part (Commuter Committee, Veterans, Innovation Society and others). Fine, or give each one loss? | Fine for now; several are new targets after this pass. |
| 5 | Every loser is still -2 and every owner +3. Vary sizes by how hard a part hits? | Later, with Phase 5's balance run. |
