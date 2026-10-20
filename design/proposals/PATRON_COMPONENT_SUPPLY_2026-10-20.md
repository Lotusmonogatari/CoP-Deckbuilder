# Patron bill component supply: when do components run out? (2026-10-20)

## Executive summary

| Question | Answer |
|---|---|
| Can the sponsored (patron) bills run out of components on their own? | **No.** Through patron requests alone (accept, amend, fail, pass) every organization always has a swap left. The exporter enforces the counts and a GUT test plays 300 random orders. |
| What does run them out? | **Draft a Bill.** A drafted bill can make any component law, including parts a patron bill needs. |
| How few drafts does it take? | **One drafted bill** can shut down up to three organizations' Flagships (a Flagship has no spare for its own two parts). About **9 drafts** shut every Flagship; about **18** shut every Favor; 27 shut all 54. |
| Did a shut-down request block anything? | It did. A Favor with no alternatives never got a status, and the same organization's Flagship waits for its Favor to be resolved, so the Flagship never appeared. **Fixed 2026-10-20:** such a request is now closed automatically (no standing cost, it was never shown) so the Flagship proceeds. |
| Is progress through the game ever blocked? | **No.** Nothing outside the Requests block depends on a patron bill. |
| Do any component phrases repeat? | **No.** All 180 are unique, and no component is used by more than one patron bill. The "repeat" case is only a *substitution*: a component that is already law is replaced by a sibling (below). |

## Pools and what each bill needs

| Pool | Slots per organization | A bill uses | Spare | Blocked when |
|---|---|---|---|---|
| Favor | X, Y, V (3) | 2 (X, Y) | 1 (V) | 2 of the 3 are already law |
| Flagship | Z, W (2) | both | **0** | 1 of the 2 is already law |
| Ally offers | A to D (0 to 4; supply = flagships that name the ally + 1) | 1 per Flagship that names it | 1 | every offer is law (or in use by a passed Flagship) |

## What makes a component law

| Source | Effect on the pools |
|---|---|
| A patron bill passes | Its 2 or 3 components become law. A failed bill uses nothing. |
| Amend | Swaps one part for a pool sibling (Favor: V; Flagship: another ally offer); the swapped-in part becomes law on a pass. |
| **Draft a Bill that passes** | Makes 2 or 3 chosen components law, from any organization, whether or not a patron bill needs them. |

## The conditions that run out, with counts

| Condition | Minimum bills to cause it | Result |
|---|---|---|
| Any one Z or W of an organization is law (from a draft) | **1 draft** (one draft can carry three organizations' Z/W) | That organization's Flagship is never offered |
| Two of an organization's X, Y, V are law | 1 draft (a draft can carry two from one organization) | That Favor is never offered; closed automatically since 2026-10-20 |
| All offers of an ally are law or used | Supply minus passed Flagships | A Flagship that names it is never offered |
| Every Flagship shut | about 9 drafts (3 per draft) | 27 Flagships gone |
| Every Favor shut | about 18 drafts (3 per draft) | 27 Favors gone |
| Everything (54 patron bills) | about 27 drafts | No requests left; Draft a Bill itself keeps working until its own parts run out (180 components) |

Each draft costs 350 XP, 300,000円 and a 30-unit cooldown, and must be winnable, so a player reaches these limits slowly and only on purpose. Components cannot be un-made (no repeal).

## Phrasing of a substituted (repeated) component

When a component is already law, the bill swaps in the organization's spare in the same pool. The bill's name is rebuilt from the new phrase. Example, Chamber of Commerce:

| Case | Bill name |
|---|---|
| First offer | A bill to cut the corporate tax rate and simplify business licensing |
| Cutting the corporate tax rate is already law | A bill to end paper filing for company registration and simplify business licensing |

Every organization's Favor parts and its spare:

| Organization | Favor parts (X / Y) | Spare (V) | Flagships naming it as ally, of offers it holds |
|---|---|---|---|
| Local Kōenkai | raise allowances for district offices / ease the rules on constituent gatherings | let district offices hold open town days | 1 of 2 |
| Mayors' Network | give towns unconditional block grants / let towns borrow for local projects | fund town planning staff | 0 of 0 |
| Chamber of Commerce | cut the corporate tax rate / simplify business licensing | end paper filing for company registration | 3 of 4 |
| Neighborhood Associations | fund repairs to community halls / support neighborhood watch groups | fund street lighting in residential blocks | 1 of 2 |
| Fisheries Cooperative | fund harbor repairs / subsidize fuel for fishing boats | fund new cold storage at fishing ports | 1 of 2 |
| National Media | strengthen freedom of information requests / protect reporters' confidential sources | protect journalists from lawsuits meant to silence them | 2 of 3 |
| Labor Federation | raise the minimum wage / enforce overtime pay | ban unpaid trial work | 0 of 0 |
| Agricultural Cooperatives | support the rice price / subsidize farm machinery | fund grain storage for farm cooperatives | 2 of 3 |
| Students United | cap university tuition / give students discounted transit | fund scholarships for first-generation students | 0 of 0 |
| Family Network | raise the child allowance / extend paid parental leave | give families a tax deduction for each child | 1 of 2 |
| Yezo Artisans Guild | certify local crafts with a protected label / give tax relief for craft apprenticeships | waive fees at craft fairs for small makers | 1 of 2 |
| Commuter Committee | freeze commuter fares / run late-night commuter trains | cap the monthly cost of a commuter pass | 1 of 2 |
| Our Traditional Society | fund local festivals / protect historic districts from redevelopment | fund the repair of old wooden buildings | 3 of 4 |
| Innovation Society | give a tax credit for research and development / offer visas to start-up founders | fund university spin-off labs | 1 of 2 |
| Constituency Voters | hold local referendums on large projects / require public consultation before new projects | hold public question time with local officials | 1 of 2 |
| Buddhist Temples Association | fund temple preservation / keep the tax exemption on temple land | let temples run public meditation and care programs | 0 of 0 |
| Shrine Association | support shrine festivals / protect shrine forests from development | fund shrine-led community cleanups | 2 of 3 |
| Care and Welfare Council | raise care workers' wages / fund home care visits | cap the cost of nursing home beds for families | 2 of 3 |
| Veterans' Association | raise veterans' pensions / expand veterans' medical care | maintain war memorials and cemeteries | 0 of 0 |
| Taxpayers' Alliance | cap growth in government spending / publish the full cost of every bill | post government spending online by project | 0 of 0 |
| Financial Industry Association | ease bank lending rules / create tax-free investment accounts | simplify the registration of investment funds | 1 of 2 |
| Small Business Owners' Association | cut taxes for small businesses / cut paperwork for small firms | waive licensing fees for micro-enterprises | 0 of 0 |
| Consumer Advocacy Network | require clear price labels / give buyers a cooling-off period | require plain-language contracts | 1 of 2 |
| Urban Neighborhood Alliance | set an affordable housing quota for new buildings / build more city parks | fund bike lanes in city centers | 1 of 2 |
| Ainu Community Council | restore Ainu fishing and harvest rights / fund Ainu community centers | fund Ainu elders' knowledge programs | 0 of 0 |
| Ainu Language and Culture Foundation | expand Ainu-language translation of public documents / teach the Ainu language in schools | support Ainu language classes for adults | 0 of 0 |
| Rural Revitalization Council | keep rural bus routes running / pay grants to families moving to rural towns | give tax breaks to firms opening in rural towns | 2 of 3 |

## What changed in code

`GameState.arm_patron_requests()` now closes (as lapsed, with no standing cost) any due request whose every alternative is already law. Test: `test_a_favor_with_nothing_left_to_swap_is_closed_so_the_flagship_is_not_held_up`.

## Options if you want more headroom (not applied)

| Option | Effect |
|---|---|
| Refuse a draft that would shut down a still-open patron request | Keeps all 54 requests reachable; costs the player some freedom |
| Add a second spare (Flagship slot S) | Flagships survive one draft part; 27 new components to write |
| Let Draft a Bill reuse a component already law | Needs a rule for a component being enacted twice |
