# Patron Bills and Custom Bills: build plan (2026-10-19)

Status: **approved 2026-10-19; step 1 (schema) built, see section 11.** Cameron's answers are applied below: decline costs 5 and 10, Amend swaps one component, **no party-body bills (27 organizations, 54 bills, 81 components)**, and **no patron bill passes without the player's influence**. It extends
`CUSTOM_BILL_MODE_2026-10-19.md` with the hybrid Cameron chose: one engine
(bill components, assembled bills, levels built at runtime) that serves two
entry points. **Patron Bills** are requests from an organization once its
standing is high enough. **Draft a Bill** is the player-built mode, which comes
last. All bill names, components, tags and numbers below are drafts for Cameron
to correct.

## 1. Summary

| Item | Plan |
|---|---|
| Trigger | Standing **50** with an organization: a **Favor** request (2 components). Standing **70**: a **Flagship** request (3 components, the third from an ally organization) |
| Count | 27 organizations × 2 = **54 patron bills**, built from **81 components** (3 per organization). Party Headquarters, Party Faction, Party Activists, the Candidate Selection Committee and Members of Parliament have none. |
| Where it shows | A **Requests** block at the top of the level list, beside Special Levels, after the existing countdown (`special_level_delay`) |
| Player choices | **Accept**, **Amend** (Favor: swap one of the two components; Flagship: swap the ally's component; rewards × 0.75), **Decline** (−5 Favor, −10 Flagship), or leave it waiting |
| What is played | A short level from a template: a meeting with the patron, the hearing for the lead component's committee, a public room and your own Party Caucus (Flagship only), then the Floor Vote |
| Outcome | Pass: standing for the patron and the ally, lasting effects, and for a Flagship the patron's backing for free for a while. Fail or decline: smaller costs. Rivals move the other way |
| Content | Written once **per component** (8 questions, 6 player cues, 6 opponent cues, 2 transition lines, 1 thought), plus 4 lines per bill. About 2,100 workbook rows, all drafts |
| Code | About 1,500–2,000 lines of GDScript plus tests, in 7 steps, each one reviewed |
| Draft a Bill mode | Step 7, on the same engine: the player assembles any components |

## 2. How it plays

1. An organization's standing reaches 50. A countdown starts on the game clock
   (the same `special_level_delay`, 5 units). Nothing is shown with a time word.
2. When it runs out, the request appears under **Requests** at the top of the
   level list, with the organization's icon.
3. Tapping it opens the **Request panel**: the organization's request line, the
   assembled bill name and its parts, a **preview** (each party's lean, the
   default vote, your own party's position and what carrying it would cost
   you), and the rewards.
4. **Accept** builds the level and starts it at the Level Intro. The lean is
   fixed to Support (you are carrying the bill). **Amend** swaps one component
   for another from an allowed list, at the cost of a smaller reward.
   **Decline** costs a little standing and the request is gone. Leaving it
   keeps it waiting.
5. The level plays like any bill level: bill-scoped content comes from the
   components, the rest from the rooms' generic content.
6. The result goes to the statute book under **Bills you carried**, and the
   outcome panel says what the patron, the ally and the rivals made of it.

The Flagship request comes only after that organization's Favor request is
resolved (passed, failed or declined), and only once its standing reaches 70.

## 3. Rules

### 3.1 Requests

| Rule | Draft value (Balance lever) |
|---|---|
| Favor threshold | 50 (`patron_favor_threshold`) |
| Flagship threshold | 70 (`patron_flagship_threshold`) |
| Countdown before a request shows | `special_level_delay` (5 units), reused |
| Requests waiting at once | 2 (`patron_max_open`); more wait in a queue |
| Requests per organization | One Favor and one Flagship per run |
| Does a request expire? | No (`patron_request_expiry` blank) |
| Party Headquarters, Faction, Activists, Selection Committee | **No requests.** They follow your party's lean at votes. |

A request is not forced in after the next level the way a crisis Special Level
is: a favor can wait.

### 3.2 Positions and the vote

Party positions are computed in code from the components' value tags and
Cameron's party values (`design/reference/party_values.tsv`), with the same
model the twenty Batch 2 bills used: a party's lean is the sum of tag ×
salience; a lean of 30 or more takes a side; seat splits follow the
Supportive / Opposed / Neutral shapes. A bill's tags are the sum of its
components' tags. Deterministic, no rolls. **No patron bill may pass on its own** (Cameron): after the lean model runs, Yes votes above the cap (51 − `patron_default_margin`, 6, so 45) are turned into **Abstain**, weakest supporters first. The player's influence swing (which draws seats from parties whose majority is not the picked bucket) is what gets the bill over 51. Step 2 must prove every one of the 56 bills can be flipped by a full-strength player, with the real vote engine.

### 3.3 Outcomes

| Event | Patron | Ally (Flagship only) | Rivals | Other |
|---|---|---|---|---|
| **Decline** | Favor −5, Flagship −10 | none | none | Request gone for the run |
| **Amend** (accept with a swap) | Rewards below × 0.75 | same scale | same | Favor: replace one of the two components with the owner's third. Flagship: replace the ally's component with another of the ally's. The swapped-in component's content is used |
| **Pass** (Favor) | +6 | n/a | −2 each | Components' gain/lose lists at the custom-law scale (50%); an Office notice line |
| **Pass** (Flagship) | +10 | +4 | −3 each | The patron's backing free for `patron_free_backing_units` (30 units); one "each level" law effect where the components have one |
| **Fail** (the vote) | −2 | −1 | +1 | A failed Favor lowers that organization's Flagship threshold by 5 (the attempt is remembered) |
| **Lose a stage that ends the level** | Request returns once, after the countdown | | | A second loss and the request lapses (−2) |
| **Your party opposes the bill** | | | | Carrying it costs `stance_flip_party_support_away` (3) Party support, shown in the preview |

All numbers are first drafts and become Balance levers, since the game reads
every number from the workbook.

### 3.4 Levels built from a template

| Template | Stages, in order |
|---|---|
| Favor (3 stages) | Patron meeting (Lobbyist Meeting family, ST20, seated as that family is today) → committee hearing (the lead component's committee) → Floor Vote |
| Flagship (5 stages) | Patron meeting → committee hearing → public room (Town Hall ST05 for a Constituency organization, Press Conference ST04 for a National one) → Party Caucus (ST03, your own party) → Floor Vote |
| 

Stage numbers (thresholds, energy, turns) are copied from those families, as
the bill-specific stage copies already are, so the existing bot trials apply.

## 4. Party bodies

No bills, requests or components (Cameron, 2026-10-19). Their effects come only from the party-lean rule at votes and from rivalry links.

## 5. Data (schema changes: need approval)

| Tab or column | Columns |
|---|---|
| **Bill Components** (new tab, shared with Draft a Bill) | Component ID (CBxx), Owner Organization, Slot (X core / Y modest / Z ambitious), Short Label, Phrase, Description, Hearing Committee (STxx), Value Tags, Gains (organizations), Loses (organizations), Excludes, Each Level Effect (optional), Amend Options (other CBxx allowed in its place) |
| **Patron Bills** (new tab) | Patron Bill ID (PBxx), Organization, Kind (Favor/Flagship), Threshold, Components, Ally, Short Title (optional override), Request Line, Accept Line, Decline Line, Pass Line, Fail Line, Template ID |
| **Bill Level Templates** (new tab) | Template ID, Stage slots as family tokens (PATRON_MEETING, HEARING, PUBLIC, CAUCUS, STEERING, VOTE), Tier, reward rule |
| **Party Values** (new tab) | Cameron's 34-dimension table, so the game can compute positions |
| **Component ID** column | On Stage Questions, Player Cues, Opponent Cues, Transition Dialogue (built in step 1). Not on Level Intro Thoughts or Visitor Questions: a patron level's thought is a player line in Transition Dialogue, and its meeting visitor belongs to the organization. |
| Balance levers | The ones in 3.1 and 3.3, plus `custom_law_scale` (50%) |
| Text rows | Request panel, Requests heading, "A bill to {a} and {b}", outcome lines, Your Record heading |

The exporter checks: every component named exists; a component's committee,
gains and loses are real IDs; tag names are real dimensions; every organization
has one Favor and one Flagship bill; Excludes are not violated inside a bill;
each component has at least its minimum content (section 7).

## 6. Code (rules first, UI last)

| File | Pure / UI | Does |
|---|---|---|
| `scripts/rules/BillPositions.gd` | pure | The lean model (ported from `archive/b2/model.py`): tags → each party's disposition and seat split |
| `scripts/rules/ComposedBill.gd` | pure | Components → a bill record in the same shape as a `floor_votes.json` row: name, text, positions, law effects (scaled), proponent |
| `scripts/rules/PatronRequests.gd` | pure | Who is due a request, the queue, accept / amend / decline / outcome deltas |
| `scripts/rules/LevelTemplate.gd` | pure | Template + bill → an ordered list of real stage IDs |
| `DataDB` | runtime registry | Holds the runtime bill and level so the existing lookups (`get_floor_vote`, bill-scoped content) find them |
| `GameState` | state | `patron_requests` (due, open, resolved), the running custom bill, save/resume, outcome application |
| `BattleSetup`, content lookups | small change | Bill-scoped content keyed by a **list** of component IDs; the bill question share split evenly across them |
| `OfficeScreen` | UI | Requests block, Request panel with preview, Amend picker, outcome notices, "Bills you carried" in Your Record |
| `tools/playtest_optimal.gd` | tool | Accepts requests, plays patron levels, reports request counts per run |

## 7. Content dependencies

### Per component (81 components)

| Content | Count | Why that many |
|---|---|---|
| Stage Questions (Component ID; theme pleases the owner, annoys the rival) | 8 | A room asks up to 10 questions and half can be bill content: 2 components × 8 = 16, at least 3x the 5 asked |
| Player Cues (one row per rhetorical style, Support) | 6 rows × 5 lines | One voice per style when carrying the bill |
| Opponent Cues (one row per style, attack) | 6 rows × 5 lines | Opponents argue against that component |
| Transition Dialogue (staff) | 2 | One per stage gap is enough for a 3–5 stage level |
| Level Intro Thought | 1 | A bill's thought is drawn from its components |
| Questions Themes row | 1 | Pleases the owner, annoys the rival |

Written about the component alone ("the rural bus routes", never "this bill" or
another component), so any mix reads naturally.

### Per patron bill (54 bills)

Request, Accept, Decline, Pass and Fail lines (5), and, for the patron meeting
stage, the organization's representative visitor with one dilemma question
(at least 10 organizations already have one, VI71–VI80; up to 18 more are needed).

### Totals

| Content | Rows |
|---|---|
| Questions | 648 |
| Player and opponent cue rows | 972 (4,860 lines) |
| Transition and thought lines | 243 |
| Question Themes rows | 81 |
| Patron bill rows | 54 |
| New visitors and questions | up to 18 + 18 |

Generated the same way as the 50 bills (archived batch scripts, then the tone,
time-word and length audits, and `tools/content_depth.py`).

## 8. Build order (each step stops for review)

| Step | Work | Proven by |
|---|---|---|
| 1 | Schema: the four tabs and the Component ID columns, exporter checks, header notes. Seed 4 organizations' components and bills | `export_data.py` clean |
| 2 | Rules: `BillPositions`, `ComposedBill`, `PatronRequests`, `LevelTemplate` | GUT tests; positions match the Python model on the same tags |
| 3 | Runtime level: registry, content keyed by components, save/resume, statute book | A headless driver plays a patron level end to end |
| 4 | UI: Requests block, Request panel, Amend, outcomes, Your Record | Real-click test in `verify.sh`; screenshots at 1080x2340 |
| 5 | Content batch 1: Favor components (X and Y, 56) for all 28 organizations | Audits; three-times rule per component pair |
| 6 | Content batch 2: the Z components (28) and the visitors; balance | Bot runs: request counts per run, win rates per template |
| 7 | Draft a Bill mode on the same engine | Click test; costs and cooldown levers |

## 9. Making sure influence is needed

Cameron's rule: **no patron bill passes by itself.** The draft tags made 48 of
56 pass without influence, so the lean model alone is not enough. The rule is
the abstain cap in section 3.2. Prototype result (`patron_plan.py`, same lean
model plus the cap): **0 of 56 bills pass by default; all 56 sit at 45 Yes or
fewer**, mostly with abstentions where parties leaned Supportive. Step 2 must
confirm with `FloorVoteEngine` that a full-strength player can still turn each
one over (Abstain seats are the easiest to swing, so this should hold).

## 10. Decisions (answered 2026-10-19)

| # | Decision |
|---|---|
| 1 | Thresholds 50 and 70, as levers. Yes |
| 2 | Decline costs −5 (Favor) and −10 (Flagship) |
| 3 | Amend: rewards × 0.75. Favor: swap one of the two components. Flagship: swap the ally's component |
| 4 | No party-body bills |
| 5 | Flagship backing free for 30 units. Yes |
| 6 | No bill passes without the player's influence; push parties toward abstaining |
| 7 | Up to 2 requests waiting at once. Yes |
| 8 | Organization interests, allies and rivals: yes, and every one must be editable in the workbook (Bill Components: Owner, Gains, Loses; Patron Bills: Ally; rivals come from each component's Loses list) |

## 10b. Revisions (2026-10-19)

| Change | Detail |
|---|---|
| Members of Parliament cut | No bills (27 organizations remain) |
| Small Business Owners | Ally is now the Yezo Artisans Guild (BO13), not a tax-cut ally; their Flagship no longer cuts the corporate tax rate |
| Ainu groups compound | Council (BO28): harvest rights, community centers, land-use consultation. Foundation (BO29): translation of public documents, schools, broadcasting. Each pushed bill adds something different |
| Repeats | Built as option A (default, Cameron may change): a component already law is never offered again; `ComposedBill.substitute_enacted()` swaps in the same owner's next component, and a request with nothing left to swap in is not offered |
| Default margin | `patron_default_margin` 6 became 3: with 6, two bills could not be carried by a full-strength player (49 of 51 Yes); with 3 every bill reaches 51 or more and none passes alone |

## 10c. Option A coverage check and the 180-component library (2026-10-19)

Cameron asked whether Option A has enough swaps for every patron bill to arise and every variation to be amendable. **It did not**: with three components per organization, a Flagship reused the Favor's core component, so once a Favor passed no Flagship could be offered (27 of 27 failed), and Amend had no spare in most cases. The library is now built to a counting rule the exporter enforces:

| Pool | Slots | Used by | Needs |
|---|---|---|---|
| Favor | X, Y, V | A Favor uses X and Y; V is the Amend spare | 3 per organization |
| Flagship own | Z, W | The organization's Flagship | 2 per organization |
| Offers | A, B, C, D | Other organizations' Flagships as their ally component | One per Flagship naming the organization as ally, plus one spare |

27 organizations x 5 own components + 45 offers = **180 components** (was 81); 54 bills unchanged in number. Swaps stay inside the pool. Proven in `tests/test_patron_rules.gd`: 300 random orders of accepting and amending every request (all 54 bills always arise, every component has an Amend alternative), and all 157 variations (the 54 bills plus every Amend choice) fail without influence and can be carried by a full-strength player of every protagonist's party. The component list in the workbook (Bill Components tab) replaces the appendix below, which shows the earlier 81-component draft.

To make every variation carryable the vote model got two patron-only shaping rules and one lever each: `patron_default_yes_floor` (44: a patron bill's default Yes never starts below it) and the recoverable cap (when Yes above 48 is turned into Abstain, it is taken from the parties whose seats the player's influence can win back, which Cameron's Vote Resistance numbers otherwise make impossible).

## 10d. Step 3 status (built 2026-10-19)

Runtime registry, `PatronLevel`, component-keyed content, `GameState` request state, vote resolution, save/resume and the statute book are built and tested (`tests/test_patron_level.gd`). Steps 4 to 7 remain. The influence-building ideas Cameron pinned for later are in `INFLUENCE_BUILDING_IDEAS_2026-10-19.md`.

## 11. Step 1 status (built 2026-10-19)

| Item | Done |
|---|---|
| New tabs | Bill Components, Patron Bills, Bill Level Templates, Party Values (204 rows, from `party_values.tsv`) |
| New column | Component ID on Stage Questions, Player Cues, Opponent Cues, Transition Dialogue, with header notes |
| Balance levers | 16 (`patron_*` and `custom_law_scale_percent`), all editable |
| Exporter | New tabs, and checks: owner is a non-party organization, slots, tag dimensions and weights, hearing stage, gains/loses signs, Favor/Flagship component ownership, one Favor and one Flagship per organization, template kind, content naming a real component |
| Seeded | 5 organizations (Chamber of Commerce, Fisheries Cooperative, Agricultural Cooperatives, Financial Industry Association, Rural Revitalization Council): 15 components, 10 patron bills, 2 templates |
| IDs | Component `CB` + organization number + slot (CB071 = BO07, slot 1); patron bill `PB` + organization number + 1 (Favor) or 2 (Flagship) |
| Not read by the game yet | By design: nothing reads these tabs until step 2 |

**Not built, and why:** header notes on the four new tabs (a new tab has no notes part; add them in Excel with Insert Note, or I can build the parts if you want them).

### Component library (81)

| ID | Owner | Slot | Phrase | Hearing | Value tags (draft) |
|---|---|---|---|---|---|
| CB031 | BO03 | X | raise allowances for district offices | Natl Assembly | Federal Spending +0.6, Localism +0.6, Clientelism +0.4 |
| CB032 | BO03 | Y | ease the rules on constituent gatherings | Natl Assembly | Localism +0.6, Regulation -0.4 |
| CB033 | BO03 | Z | create a constituency development fund | Finance | Federal Spending +0.9, Clientelism +0.7, Localism +0.5 |
| CB041 | BO04 | X | give towns unconditional block grants | Govt Admin | Localism +1.0, Federal Spending +0.6 |
| CB042 | BO04 | Y | let towns borrow for local projects | Govt Admin | Localism +0.8, Federal Spending +0.3 |
| CB043 | BO04 | Z | give towns their own tax-setting powers | Finance | Localism +1.0, Taxation +0.3 |
| CB051 | BO05 | X | cut the corporate tax rate | Finance | Taxation -1.0, Economic Liberalization +0.7 |
| CB052 | BO05 | Y | simplify business licensing | Govt Admin | Regulation -0.8, Economic Liberalization +0.5 |
| CB053 | BO05 | Z | open special economic zones | Finance | Economic Liberalization +1.0, Globalism +0.5, Industrialism +0.4 |
| CB061 | BO06 | X | fund repairs to community halls | Construction | Federal Spending +0.5, Localism +0.7 |
| CB062 | BO06 | Y | support neighborhood watch groups | Govt Admin | Localism +0.6, Traditional Values +0.3 |
| CB063 | BO06 | Z | give neighborhood associations legal standing in planning | Construction | Localism +1.0, Regulation +0.4 |
| CB071 | BO07 | X | fund harbor repairs | Construction | Federal Spending +0.6, Rural Focus +0.7 |
| CB072 | BO07 | Y | subsidize fuel for fishing boats | Agriculture | Federal Spending +0.6, Agrarianism +0.5, Environmentalism -0.4 |
| CB073 | BO07 | Z | hold fishing quotas through local cooperatives | Agriculture | Localism +0.7, Economic Liberalization -0.5, Rural Focus +0.5 |
| CB081 | BO08 | X | strengthen freedom of information requests | Govt Admin | Civil Liberties +0.8, Democratic Norms +0.6 |
| CB082 | BO08 | Y | protect reporters' confidential sources | Ethics | Civil Liberties +1.0, Judicial Independence +0.3 |
| CB083 | BO08 | Z | open every committee hearing to the press | Natl Assembly | Democratic Norms +0.9, Leadership Interest -0.5 |
| CB091 | BO09 | X | raise the minimum wage | Finance | Regulation +0.8, Economic Liberalization -0.7 |
| CB092 | BO09 | Y | enforce overtime pay | Govt Admin | Regulation +0.7 |
| CB093 | BO09 | Z | protect collective bargaining rights | Govt Admin | Regulation +0.6, Liberal Rights +0.4, Economic Liberalization -0.6 |
| CB101 | BO10 | X | support the rice price | Agriculture | Agrarianism +1.0, Federal Spending +0.5, Economic Liberalization -0.4 |
| CB102 | BO10 | Y | subsidize farm machinery | Agriculture | Agrarianism +0.8, Federal Spending +0.5 |
| CB103 | BO10 | Z | restrict foreign food imports | Foreign Affairs | Globalism -1.0, Agrarianism +0.8, Economic Liberalization -0.5 |
| CB111 | BO11 | X | cap university tuition | Finance | Federal Spending +0.7, Post-Industrialism +0.5 |
| CB112 | BO11 | Y | give students discounted transit | Construction | Federal Spending +0.4 |
| CB113 | BO11 | Z | build public student housing | Construction | Federal Spending +0.8, Post-Industrialism +0.4 |
| CB121 | BO12 | X | raise the child allowance | Finance | Federal Spending +0.8, Traditional Values +0.3 |
| CB122 | BO12 | Y | extend paid parental leave | Govt Admin | Gender Equality +0.7, Regulation +0.5 |
| CB123 | BO12 | Z | open more public childcare places | Govt Admin | Federal Spending +0.8, Gender Equality +0.5 |
| CB131 | BO13 | X | certify local crafts with a protected label | Govt Admin | Traditional Values +0.6, Localism +0.5 |
| CB132 | BO13 | Y | give tax relief for craft apprenticeships | Finance | Taxation -0.4, Traditional Values +0.5 |
| CB133 | BO13 | Z | promote craft exports abroad | Foreign Affairs | Globalism +0.6, Traditional Values +0.4 |
| CB141 | BO14 | X | freeze commuter fares | Construction | Federal Spending +0.6, Rural Focus -0.5 |
| CB142 | BO14 | Y | run late-night commuter trains | Construction | Federal Spending +0.5, Post-Industrialism +0.4 |
| CB143 | BO14 | Z | make every station step-free | Construction | Federal Spending +0.8, Minority Rights +0.4 |
| CB151 | BO15 | X | fund local festivals | Govt Admin | Traditional Values +0.8, Federal Spending +0.3 |
| CB152 | BO15 | Y | protect historic districts from redevelopment | Construction | Traditional Values +0.8, Regulation +0.5 |
| CB153 | BO15 | Z | create a national heritage register | Govt Admin | Traditional Values +1.0, Religious Traditionalism +0.3 |
| CB161 | BO16 | X | give a tax credit for research and development | Finance | Post-Industrialism +1.0, Taxation -0.4 |
| CB162 | BO16 | Y | offer visas to start-up founders | Foreign Affairs | Immigration +0.7, Post-Industrialism +0.6 |
| CB163 | BO16 | Z | move government services online | Govt Admin | Technocratic +0.9, Post-Industrialism +0.5 |
| CB181 | BO18 | X | hold local referendums on large projects | Govt Admin | Democratic Norms +0.8, Localism +0.6 |
| CB182 | BO18 | Y | require public consultation before new projects | Construction | Democratic Norms +0.7, Regulation +0.4 |
| CB183 | BO18 | Z | let citizen petitions trigger committee hearings | Natl Assembly | Democratic Norms +1.0, Leadership Interest -0.4 |
| CB191 | BO19 | X | fund temple preservation | Govt Admin | Religious Traditionalism +0.8, Federal Spending +0.4 |
| CB192 | BO19 | Y | keep the tax exemption on temple land | Finance | Religious Traditionalism +0.7, Taxation -0.4 |
| CB193 | BO19 | Z | designate temples as disaster shelters | Construction | Religious Traditionalism +0.5, Federal Spending +0.5 |
| CB201 | BO20 | X | support shrine festivals | Govt Admin | Religious Traditionalism +0.8, Traditional Values +0.5 |
| CB202 | BO20 | Y | protect shrine forests from development | Environment | Environmentalism +0.7, Religious Traditionalism +0.5 |
| CB203 | BO20 | Z | list shrine grounds on the heritage register | Govt Admin | Traditional Values +0.8, Religious Traditionalism +0.6 |
| CB211 | BO21 | X | raise care workers' wages | Finance | Federal Spending +0.8, Regulation +0.3 |
| CB212 | BO21 | Y | fund home care visits | Govt Admin | Federal Spending +0.7 |
| CB213 | BO21 | Z | open dementia care centers in every district | Govt Admin | Federal Spending +0.9, Localism +0.3 |
| CB221 | BO22 | X | raise veterans' pensions | War | Militarism +0.6, Federal Spending +0.6 |
| CB222 | BO22 | Y | expand veterans' medical care | War | Militarism +0.5, Federal Spending +0.6 |
| CB223 | BO22 | Z | give veterans hiring preference in public jobs | War | Militarism +0.8, Regulation +0.3 |
| CB231 | BO23 | X | cap growth in government spending | Finance | Federal Spending -1.0 |
| CB232 | BO23 | Y | publish the full cost of every bill | Finance | Technocratic +0.6, Democratic Norms +0.4 |
| CB233 | BO23 | Z | add sunset clauses to new spending | Finance | Federal Spending -0.8, Technocratic +0.3 |
| CB241 | BO24 | X | ease bank lending rules | Finance | Regulation -0.8, Economic Liberalization +0.7 |
| CB242 | BO24 | Y | create tax-free investment accounts | Finance | Taxation -0.6, Economic Liberalization +0.5 |
| CB243 | BO24 | Z | build a financial hub zone in Sapporo | Finance | Economic Liberalization +0.9, Globalism +0.7 |
| CB251 | BO25 | X | cut taxes for small businesses | Finance | Taxation -0.8 |
| CB252 | BO25 | Y | cut paperwork for small firms | Govt Admin | Regulation -0.7 |
| CB253 | BO25 | Z | make large firms pay suppliers on time | Finance | Regulation +0.5, Economic Liberalization -0.2 |
| CB261 | BO26 | X | require clear price labels | Govt Admin | Regulation +0.7 |
| CB262 | BO26 | Y | give buyers a cooling-off period | Govt Admin | Regulation +0.6, Liberal Rights +0.3 |
| CB263 | BO26 | Z | cap bank fees | Finance | Regulation +0.8, Economic Liberalization -0.6 |
| CB271 | BO27 | X | set an affordable housing quota for new buildings | Construction | Regulation +0.6, Federal Spending +0.4, Rural Focus -0.5 |
| CB272 | BO27 | Y | build more city parks | Environment | Environmentalism +0.6, Rural Focus -0.4 |
| CB273 | BO27 | Z | cap rent rises in the cities | Construction | Regulation +0.9, Economic Liberalization -0.7 |
| CB281 | BO28 | X | restore Ainu fishing and harvest rights | Agriculture | Ainu Enhancement +1.0, Minority Rights +0.6 |
| CB282 | BO28 | Y | fund Ainu community centers | Govt Admin | Ainu Enhancement +0.8, Federal Spending +0.4 |
| CB283 | BO28 | Z | require consultation with Ainu communities on land use | Construction | Ainu Enhancement +1.0, Minority Rights +0.7, Localism +0.3 |
| CB291 | BO29 | X | expand Ainu-language translation of public documents | Govt Admin | Ainu Enhancement +0.8, Technocratic +0.3, Ethnic Pluralism +0.5 |
| CB292 | BO29 | Y | teach the Ainu language in schools | Govt Admin | Ainu Enhancement +0.9, Ethnic Pluralism +0.5 |
| CB293 | BO29 | Z | fund Ainu-language broadcasting | Govt Admin | Ainu Enhancement +0.9, Federal Spending +0.5 |
| CB301 | BO30 | X | keep rural bus routes running | Construction | Rural Focus +0.9, Federal Spending +0.5 |
| CB302 | BO30 | Y | pay grants to families moving to rural towns | Govt Admin | Rural Focus +0.9, Federal Spending +0.5 |
| CB303 | BO30 | Z | bring broadband to every village | Construction | Rural Focus +0.8, Post-Industrialism +0.5, Federal Spending +0.6 |

### Patron bills (54)

| ID | Organization | At | Kind | Bill (assembled name) | Components | Gains | Loses | Hearing | Party lean | Default vote (Aye-Nay-Abstain) |
|---|---|---|---|---|---|---|---|---|---|---|
| PB031 | Local Kōenkai | 50 | Favor | A bill to raise allowances for district offices and ease the rules on constituent gatherings | CB031 + CB032 | Local Kōenkai | Taxpayers' Alliance | Natl Assembly | BU:N YH:S FR:S FP:S KJ:S CI:O | 45-25-31 fails |
| PB032 | Local Kōenkai | 70 | Flagship | A bill to raise allowances for district offices, create a constituency development fund and hold local referendums on large projects | CB031 + CB033 + CB181 | Local Kōenkai, Constituency Voters | Taxpayers' Alliance | Natl Assembly | BU:S YH:S FR:S FP:S KJ:N CI:O | 45-22-34 fails |
| PB041 | Mayors' Network | 50 | Favor | A bill to give towns unconditional block grants and let towns borrow for local projects | CB041 + CB042 | Mayors' Network | Taxpayers' Alliance | Govt Admin | BU:N YH:S FR:S FP:S KJ:O CI:O | 45-38-18 fails |
| PB042 | Mayors' Network | 70 | Flagship | A bill to give towns unconditional block grants, give towns their own tax-setting powers and keep rural bus routes running | CB041 + CB043 + CB301 | Mayors' Network, Rural Revitalization Council | Taxpayers' Alliance | Govt Admin | BU:O YH:S FR:S FP:S KJ:O CI:O | 45-47-9 fails |
| PB051 | Chamber of Commerce | 50 | Favor | A bill to cut the corporate tax rate and simplify business licensing | CB051 + CB052 | Chamber of Commerce | Labor Federation | Finance | BU:O YH:N FR:S FP:N KJ:S CI:S | 45-30-26 fails |
| PB052 | Chamber of Commerce | 70 | Flagship | A bill to cut the corporate tax rate, open special economic zones and ease bank lending rules | CB051 + CB053 + CB241 | Chamber of Commerce, Financial Industry Association | Labor Federation | Finance | BU:O YH:O FR:S FP:S KJ:S CI:S | 45-33-23 fails |
| PB061 | Neighborhood Associations | 50 | Favor | A bill to fund repairs to community halls and support neighborhood watch groups | CB061 + CB062 | Neighborhood Associations | Chamber of Commerce | Construction | BU:N YH:S FR:S FP:S KJ:O CI:O | 45-33-23 fails |
| PB062 | Neighborhood Associations | 70 | Flagship | A bill to fund repairs to community halls, give neighborhood associations legal standing in planning and raise allowances for district offices | CB061 + CB063 + CB031 | Neighborhood Associations, Local Kōenkai | Chamber of Commerce | Construction | BU:N YH:S FR:S FP:S KJ:O CI:O | 45-40-16 fails |
| PB071 | Fisheries Cooperative | 50 | Favor | A bill to fund harbor repairs and subsidize fuel for fishing boats | CB071 + CB072 | Fisheries Cooperative | Consumer Advocacy Network | Construction | BU:N YH:S FR:S FP:S KJ:N CI:O | 45-21-35 fails |
| PB072 | Fisheries Cooperative | 70 | Flagship | A bill to fund harbor repairs, hold fishing quotas through local cooperatives and support the rice price | CB071 + CB073 + CB101 | Fisheries Cooperative, Agricultural Cooperatives | Consumer Advocacy Network | Construction | BU:S YH:S FR:S FP:S KJ:O CI:O | 45-39-17 fails |
| PB081 | National Media | 50 | Favor | A bill to strengthen freedom of information requests and protect reporters' confidential sources | CB081 + CB082 | National Media | Party Headquarters | Govt Admin | BU:N YH:O FR:S FP:N KJ:S CI:N | 45-28-28 fails |
| PB082 | National Media | 70 | Flagship | A bill to strengthen freedom of information requests, open every committee hearing to the press and require clear price labels | CB081 + CB083 + CB261 | National Media, Consumer Advocacy Network | Party Headquarters | Govt Admin | BU:S YH:N FR:S FP:S KJ:O CI:O | 45-44-12 fails |
| PB091 | Labor Federation | 50 | Favor | A bill to raise the minimum wage and enforce overtime pay | CB091 + CB092 | Labor Federation | Chamber of Commerce | Finance | BU:S YH:N FR:N FP:N KJ:O CI:O | 40-44-17 fails |
| PB092 | Labor Federation | 70 | Flagship | A bill to raise the minimum wage, protect collective bargaining rights and raise care workers' wages | CB091 + CB093 + CB211 | Labor Federation, Care and Welfare Council | Chamber of Commerce | Finance | BU:S YH:S FR:S FP:S KJ:O CI:O | 45-42-14 fails |
| PB101 | Agricultural Cooperatives | 50 | Favor | A bill to support the rice price and subsidize farm machinery | CB101 + CB102 | Agricultural Cooperatives | Urban Neighborhood Alliance | Agriculture | BU:S YH:S FR:S FP:S KJ:O CI:O | 45-31-25 fails |
| PB102 | Agricultural Cooperatives | 70 | Flagship | A bill to support the rice price, restrict foreign food imports and keep rural bus routes running | CB101 + CB103 + CB301 | Agricultural Cooperatives, Rural Revitalization Council | Urban Neighborhood Alliance | Agriculture | BU:S YH:S FR:S FP:N KJ:O CI:O | 45-36-20 fails |
| PB111 | Students United | 50 | Favor | A bill to cap university tuition and give students discounted transit | CB111 + CB112 | Students United | Our Traditional Society | Finance | BU:S YH:S FR:S FP:S KJ:S CI:O | 45-25-31 fails |
| PB112 | Students United | 70 | Flagship | A bill to cap university tuition, build public student housing and give a tax credit for research and development | CB111 + CB113 + CB161 | Students United, Innovation Society | Our Traditional Society | Finance | BU:S YH:S FR:S FP:S KJ:S CI:O | 45-17-39 fails |
| PB121 | Family Network | 50 | Favor | A bill to raise the child allowance and extend paid parental leave | CB121 + CB122 | Family Network | Small Business Owners' Association | Finance | BU:S YH:S FR:S FP:S KJ:O CI:O | 45-38-18 fails |
| PB122 | Family Network | 70 | Flagship | A bill to raise the child allowance, open more public childcare places and raise care workers' wages | CB121 + CB123 + CB211 | Family Network, Care and Welfare Council | Small Business Owners' Association | Finance | BU:S YH:S FR:S FP:S KJ:N CI:O | 45-20-36 fails |
| PB131 | Yezo Artisans Guild | 50 | Favor | A bill to certify local crafts with a protected label and give tax relief for craft apprenticeships | CB131 + CB132 | Yezo Artisans Guild | Innovation Society | Govt Admin | BU:N YH:S FR:S FP:S KJ:N CI:S | 45-26-30 fails |
| PB132 | Yezo Artisans Guild | 70 | Flagship | A bill to certify local crafts with a protected label, promote craft exports abroad and fund local festivals | CB131 + CB133 + CB151 | Yezo Artisans Guild, Our Traditional Society | Innovation Society | Govt Admin | BU:S YH:S FR:S FP:S KJ:N CI:S | 45-20-36 fails |
| PB141 | Commuter Committee | 50 | Favor | A bill to freeze commuter fares and run late-night commuter trains | CB141 + CB142 | Commuter Committee | Rural Revitalization Council | Construction | BU:S YH:N FR:N FP:S KJ:S CI:O | 45-25-31 fails |
| PB142 | Commuter Committee | 70 | Flagship | A bill to freeze commuter fares, make every station step-free and set an affordable housing quota for new buildings | CB141 + CB143 + CB271 | Commuter Committee, Urban Neighborhood Alliance | Rural Revitalization Council | Construction | BU:S YH:N FR:S FP:S KJ:N CI:O | 45-34-22 fails |
| PB151 | Our Traditional Society | 50 | Favor | A bill to fund local festivals and protect historic districts from redevelopment | CB151 + CB152 | Our Traditional Society | Students United | Govt Admin | BU:S YH:S FR:S FP:N KJ:O CI:S | 45-41-15 fails |
| PB152 | Our Traditional Society | 70 | Flagship | A bill to fund local festivals, create a national heritage register and support shrine festivals | CB151 + CB153 + CB201 | Our Traditional Society, Shrine Association | Students United | Govt Admin | BU:S YH:S FR:S FP:N KJ:N CI:S | 45-20-36 fails |
| PB161 | Innovation Society | 50 | Favor | A bill to give a tax credit for research and development and offer visas to start-up founders | CB161 + CB162 | Innovation Society | Yezo Artisans Guild | Finance | BU:S YH:N FR:N FP:S KJ:S CI:O | 45-27-29 fails |
| PB162 | Innovation Society | 70 | Flagship | A bill to give a tax credit for research and development, move government services online and cut the corporate tax rate | CB161 + CB163 + CB051 | Innovation Society, Chamber of Commerce | Yezo Artisans Guild | Finance | BU:N YH:O FR:S FP:S KJ:S CI:S | 45-23-33 fails |
| PB181 | Constituency Voters | 50 | Favor | A bill to hold local referendums on large projects and require public consultation before new projects | CB181 + CB182 | Constituency Voters | Members of Parliament | Govt Admin | BU:S YH:S FR:S FP:S KJ:O CI:O | 45-36-20 fails |
| PB182 | Constituency Voters | 70 | Flagship | A bill to hold local referendums on large projects, let citizen petitions trigger committee hearings and fund repairs to community halls | CB181 + CB183 + CB061 | Constituency Voters, Neighborhood Associations | Members of Parliament | Govt Admin | BU:N YH:S FR:S FP:S KJ:O CI:O | 45-32-24 fails |
| PB191 | Buddhist Temples Association | 50 | Favor | A bill to fund temple preservation and keep the tax exemption on temple land | CB191 + CB192 | Buddhist Temples Association | Taxpayers' Alliance | Govt Admin | BU:S YH:S FR:S FP:S KJ:S CI:N | 45-20-36 fails |
| PB192 | Buddhist Temples Association | 70 | Flagship | A bill to fund temple preservation, designate temples as disaster shelters and support shrine festivals | CB191 + CB193 + CB201 | Buddhist Temples Association, Shrine Association | Taxpayers' Alliance | Govt Admin | BU:S YH:S FR:S FP:S KJ:S CI:O | 45-21-35 fails |
| PB201 | Shrine Association | 50 | Favor | A bill to support shrine festivals and protect shrine forests from development | CB201 + CB202 | Shrine Association | Chamber of Commerce | Govt Admin | BU:S YH:S FR:N FP:N KJ:N CI:N | 45-23-33 fails |
| PB202 | Shrine Association | 70 | Flagship | A bill to support shrine festivals, list shrine grounds on the heritage register and fund local festivals | CB201 + CB203 + CB151 | Shrine Association, Our Traditional Society | Chamber of Commerce | Govt Admin | BU:S YH:S FR:S FP:N KJ:N CI:S | 45-20-36 fails |
| PB211 | Care and Welfare Council | 50 | Favor | A bill to raise care workers' wages and fund home care visits | CB211 + CB212 | Care and Welfare Council | Taxpayers' Alliance | Finance | BU:S YH:S FR:S FP:S KJ:N CI:O | 45-31-25 fails |
| PB212 | Care and Welfare Council | 70 | Flagship | A bill to raise care workers' wages, open dementia care centers in every district and raise the child allowance | CB211 + CB213 + CB121 | Care and Welfare Council, Family Network | Taxpayers' Alliance | Finance | BU:S YH:S FR:S FP:S KJ:N CI:O | 45-24-32 fails |
| PB221 | Veterans' Association | 50 | Favor | A bill to raise veterans' pensions and expand veterans' medical care | CB221 + CB222 | Veterans' Association | Students United | War | BU:N YH:S FR:S FP:S KJ:S CI:O | 45-30-26 fails |
| PB222 | Veterans' Association | 70 | Flagship | A bill to raise veterans' pensions, give veterans hiring preference in public jobs and fund local festivals | CB221 + CB223 + CB151 | Veterans' Association, Our Traditional Society | Students United | War | BU:N YH:S FR:S FP:S KJ:O CI:O | 45-37-19 fails |
| PB231 | Taxpayers' Alliance | 50 | Favor | A bill to cap growth in government spending and publish the full cost of every bill | CB231 + CB232 | Taxpayers' Alliance | Care and Welfare Council | Finance | BU:O YH:O FR:O FP:O KJ:O CI:S | 31-67-3 fails |
| PB232 | Taxpayers' Alliance | 70 | Flagship | A bill to cap growth in government spending, add sunset clauses to new spending and cut the corporate tax rate | CB231 + CB233 + CB051 | Taxpayers' Alliance, Chamber of Commerce | Care and Welfare Council | Finance | BU:O YH:O FR:O FP:O KJ:S CI:S | 36-65-0 fails |
| PB241 | Financial Industry Association | 50 | Favor | A bill to ease bank lending rules and create tax-free investment accounts | CB241 + CB242 | Financial Industry Association | Consumer Advocacy Network | Finance | BU:O YH:N FR:S FP:N KJ:S CI:S | 45-31-25 fails |
| PB242 | Financial Industry Association | 70 | Flagship | A bill to ease bank lending rules, build a financial hub zone in Sapporo and cut the corporate tax rate | CB241 + CB243 + CB051 | Financial Industry Association, Chamber of Commerce | Consumer Advocacy Network | Finance | BU:O YH:O FR:S FP:S KJ:S CI:S | 45-30-26 fails |
| PB251 | Small Business Owners' Association | 50 | Favor | A bill to cut taxes for small businesses and cut paperwork for small firms | CB251 + CB252 | Small Business Owners' Association | Labor Federation | Finance | BU:O YH:N FR:N FP:N KJ:S CI:S | 45-27-29 fails |
| PB252 | Small Business Owners' Association | 70 | Flagship | A bill to cut taxes for small businesses, make large firms pay suppliers on time and certify local crafts with a protected label | CB251 + CB253 + CB131 | Small Business Owners' Association, Yezo Artisans Guild | Labor Federation | Finance | BU:S YH:S FR:S FP:S KJ:O CI:S | 45-41-15 fails |
| PB261 | Consumer Advocacy Network | 50 | Favor | A bill to require clear price labels and give buyers a cooling-off period | CB261 + CB262 | Consumer Advocacy Network | Financial Industry Association | Govt Admin | BU:S YH:N FR:S FP:S KJ:O CI:O | 45-47-9 fails |
| PB262 | Consumer Advocacy Network | 70 | Flagship | A bill to require clear price labels, cap bank fees and strengthen freedom of information requests | CB261 + CB263 + CB081 | Consumer Advocacy Network, National Media | Financial Industry Association | Govt Admin | BU:S YH:N FR:S FP:S KJ:O CI:O | 45-45-11 fails |
| PB271 | Urban Neighborhood Alliance | 50 | Favor | A bill to set an affordable housing quota for new buildings and build more city parks | CB271 + CB272 | Urban Neighborhood Alliance | Rural Revitalization Council | Construction | BU:S YH:O FR:O FP:S KJ:O CI:O | 30-70-1 fails |
| PB272 | Urban Neighborhood Alliance | 70 | Flagship | A bill to set an affordable housing quota for new buildings, cap rent rises in the cities and freeze commuter fares | CB271 + CB273 + CB141 | Urban Neighborhood Alliance, Commuter Committee | Rural Revitalization Council | Construction | BU:S YH:N FR:O FP:S KJ:O CI:O | 32-64-5 fails |
| PB281 | Ainu Community Council | 50 | Favor | A bill to restore Ainu fishing and harvest rights and fund Ainu community centers | CB281 + CB282 | Ainu Community Council | Our Traditional Society | Agriculture | BU:S YH:S FR:S FP:N KJ:N CI:O | 45-34-22 fails |
| PB282 | Ainu Community Council | 70 | Flagship | A bill to restore Ainu fishing and harvest rights, require consultation with Ainu communities on land use and fund harbor repairs | CB281 + CB283 + CB071 | Ainu Community Council, Fisheries Cooperative | Our Traditional Society | Agriculture | BU:S YH:S FR:S FP:S KJ:O CI:O | 45-34-22 fails |
| PB291 | Ainu Language and Culture Foundation | 50 | Favor | A bill to expand Ainu-language translation of public documents and teach the Ainu language in schools | CB291 + CB292 | Ainu Language and Culture Foundation | Our Traditional Society | Govt Admin | BU:N YH:S FR:N FP:O KJ:N CI:O | 29-46-26 fails |
| PB292 | Ainu Language and Culture Foundation | 70 | Flagship | A bill to expand Ainu-language translation of public documents, fund Ainu-language broadcasting and strengthen freedom of information requests | CB291 + CB293 + CB081 | Ainu Language and Culture Foundation, National Media | Our Traditional Society | Govt Admin | BU:S YH:S FR:S FP:N KJ:S CI:O | 45-30-26 fails |
| PB301 | Rural Revitalization Council | 50 | Favor | A bill to keep rural bus routes running and pay grants to families moving to rural towns | CB301 + CB302 | Rural Revitalization Council | Urban Neighborhood Alliance | Construction | BU:N YH:S FR:S FP:S KJ:O CI:O | 45-40-16 fails |
| PB302 | Rural Revitalization Council | 70 | Flagship | A bill to keep rural bus routes running, bring broadband to every village and support the rice price | CB301 + CB303 + CB101 | Rural Revitalization Council, Agricultural Cooperatives | Urban Neighborhood Alliance | Construction | BU:S YH:S FR:S FP:S KJ:O CI:O | 45-32-24 fails |

Default result without influence: 0 pass, 54 fail, 0 decided in caucus.
