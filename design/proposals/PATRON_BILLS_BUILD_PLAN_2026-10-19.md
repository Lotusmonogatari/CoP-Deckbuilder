# Patron Bills and Custom Bills: build plan (2026-10-19)

Status: **plan for approval; nothing built.** It extends
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
| Count | 32 organizations × 2 = **64 patron bills**, built from **96 components** (3 per organization) |
| Where it shows | A **Requests** block at the top of the level list, beside Special Levels, after the existing countdown (`special_level_delay`) |
| Player choices | **Accept**, **Amend** (swap one component for a cost), **Decline** (a small standing cost), or leave it for later |
| What is played | A short level from a template: a meeting with the patron, the hearing for the lead component's committee, a public room (Flagship only), then the Floor Vote. Party bodies' requests end in a Party Caucus instead of a Floor Vote |
| Outcome | Pass: standing for the patron and the ally, lasting effects, and for a Flagship the patron's backing for free for a while. Fail or decline: smaller costs. Rivals move the other way |
| Content | Written once **per component** (8 questions, 6 player cues, 6 opponent cues, 2 transition lines, 1 thought), plus 4 lines per bill. About 2,000 workbook rows, all drafts |
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
| Party Headquarters, Faction, Activists, Selection Committee | Request too, but their bills are **party rule changes** voted in a Party Caucus (section 4) |

A request is not forced in after the next level the way a crisis Special Level
is: a favor can wait.

### 3.2 Positions and the vote

Party positions are computed in code from the components' value tags and
Cameron's party values (`design/reference/party_values.tsv`), with the same
model the twenty Batch 2 bills used: a party's lean is the sum of tag ×
salience; a lean of 30 or more takes a side; seat splits follow the
Supportive / Opposed / Neutral shapes. A bill's tags are the sum of its
components' tags. Deterministic, no rolls. The influence swing works as usual.
The vote needs 51 of 101.

### 3.3 Outcomes

| Event | Patron | Ally (Flagship only) | Rivals | Other |
|---|---|---|---|---|
| **Decline** | Favor −3, Flagship −5 | none | none | Request gone for the run |
| **Amend** (accept with a swap) | Rewards below × 0.75 | same scale | same | The swapped-in component's owner gains its own +2 if the bill passes |
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
| Party rule (Favor 2, Flagship 3 stages) | Patron meeting → Party Steering Committee (ST08) → Party Caucus (ST03), which decides the rule |

Stage numbers (thresholds, energy, turns) are copied from those families, as
the bill-specific stage copies already are, so the existing bot trials apply.

## 4. Party bodies' requests

Party Headquarters, Party Faction, Party Activists and the Candidate Selection
Committee follow the player's party, so their "bills" are changes to the
party's own rules. No Floor Vote: the Party Caucus decides, and winning it is
the pass. The name reads "A party rule to …" (a Text row) instead of "A bill
to …". Their components are tagged too, but only for flavor; positions are not
computed. Their rivalries already exist (Headquarters ↔ Faction, Activists ↔
Selection Committee, Standing Links tab).

## 5. Data (schema changes: need approval)

| Tab or column | Columns |
|---|---|
| **Bill Components** (new tab, shared with Draft a Bill) | Component ID (CBxx), Owner Organization, Slot (X core / Y modest / Z ambitious), Short Label, Phrase, Description, Hearing Committee (STxx), Value Tags, Gains (organizations), Loses (organizations), Excludes, Each Level Effect (optional), Amend Options (other CBxx allowed in its place) |
| **Patron Bills** (new tab) | Patron Bill ID (PBxx), Organization, Kind (Favor/Flagship), Threshold, Components, Ally, Short Title (optional override), Request Line, Accept Line, Decline Line, Pass Line, Fail Line, Template ID |
| **Bill Level Templates** (new tab) | Template ID, Stage slots as family tokens (PATRON_MEETING, HEARING, PUBLIC, CAUCUS, STEERING, VOTE), Tier, reward rule |
| **Party Values** (new tab) | Cameron's 34-dimension table, so the game can compute positions |
| **Component ID** column | On Stage Questions, Player Cues, Opponent Cues, Transition Dialogue, Level Intro Thoughts, Visitor Questions (optional **Stance** as for bills) |
| Balance levers | The ones in 3.1 and 3.3, plus `custom_law_scale` (50%) |
| Text rows | Request panel, Requests heading, "A bill to {a} and {b}", "A party rule to …", outcome lines, Your Record heading |

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

### Per component (96 components)

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

### Per patron bill (64 bills)

Request, Accept, Decline, Pass and Fail lines (5), and, for the patron meeting
stage, the organization's representative visitor with one dilemma question
(at least 10 organizations already have one, VI71–VI80; up to 22 more are needed).

### Totals

| Content | Rows |
|---|---|
| Questions | 768 |
| Player and opponent cue rows | 1,152 (5,760 lines) |
| Transition and thought lines | 288 |
| Question Themes rows | 96 |
| Patron bill rows | 64 |
| New visitors and questions | 22 + 22 |

Generated the same way as the 50 bills (archived batch scripts, then the tone,
time-word and length audits, and `tools/content_depth.py`).

## 8. Build order (each step stops for review)

| Step | Work | Proven by |
|---|---|---|
| 1 | Schema: the four tabs and the Component ID columns, exporter checks, header notes. Seed 4 organizations' components and bills | `export_data.py` clean |
| 2 | Rules: `BillPositions`, `ComposedBill`, `PatronRequests`, `LevelTemplate` | GUT tests; positions match the Python model on the same tags |
| 3 | Runtime level: registry, content keyed by components, save/resume, statute book | A headless driver plays a patron level end to end |
| 4 | UI: Requests block, Request panel, Amend, outcomes, Your Record | Real-click test in `verify.sh`; screenshots at 1080x2340 |
| 5 | Content batch 1: Favor components (64) for all 32 organizations | Audits; three-times rule per component pair |
| 6 | Content batch 2: Flagship components (32) and the 22 visitors; balance | Bot runs: request counts per run, win rates per template |
| 7 | Draft a Bill mode on the same engine | Click test; costs and cooldown levers |

## 9. Calibration finding from the draft tags

With the draft tags below, **48 of the 56 Floor Vote bills pass by default** (8
fail, 8 are party rules). Spending and local-power components please most
parties, so summed tags make bills easy to pass. The level's combat stages
remain the real test, but if a patron bill should be a fight in the chamber
too, the options are: scale a bill's summed tags down (for example by the
number of components), raise the 30-point threshold for composed bills, or
weight each patron bill's rivals into the opposing parties. This is Step 6's
tuning, and Cameron's call.

## 10. Decisions needed

| # | Question | Recommendation |
|---|---|---|
| 1 | Thresholds 50 and 70 as drafted? | Yes, as levers |
| 2 | Can a request be declined, and at what cost? | Yes, −3 / −5 |
| 3 | Amend: allowed, and how costly? | Yes, one swap, rewards × 0.75 |
| 4 | Party bodies' rules decided in a Party Caucus, not the Floor Vote? | Yes |
| 5 | Flagship reward: free backing for a while? | Yes, 30 units |
| 6 | How hard should the vote be? (section 9) | Scale summed tags down by the number of components, then bot-test |
| 7 | Up to 2 requests waiting at once? | Yes |
| 8 | Are the organizations' interests and rivals below right? | Cameron to correct; they are drafts |

## Appendix: components and the 64 patron bills (drafts)

Generated by `tools/workbook/archive/b9/patron_plan.py`. Each organization owns
three components: X (core), Y (modest), Z (ambitious). **Favor = X + Y** at
standing 50. **Flagship = X + Z + the ally's X** at 70. "Party lean" codes:
BU Butsutou, YH Yezo Heritage Party, FR Frontier Party, FP Five Point
Independents, KJ Keizaijiyuutou, CI Country Initiative; S Supportive, O Opposed,
N Neutral. "Default vote" is without the player's influence. Party bodies'
bills read "A party rule to …" in the game.

### Component library (96)

| ID | Owner | Slot | Phrase | Hearing | Value tags (draft) |
|---|---|---|---|---|---|
| CB01 | BO01 | X | route campaign funding through party headquarters | Party Caucus | Leadership Interest +1.0, Clientelism -0.3 |
| CB02 | BO01 | Y | require party approval for members' private bills | Party Caucus | Leadership Interest +0.8, Democratic Norms -0.3 |
| CB03 | BO01 | Z | create a central campaign data office | Party Caucus | Leadership Interest +0.7, Technocratic +0.5 |
| CB04 | BO02 | X | award committee chairs by seniority | Party Caucus | Leadership Interest -0.6, Clientelism +0.6 |
| CB05 | BO02 | Y | protect faction study groups from headquarters control | Party Caucus | Leadership Interest -0.8 |
| CB06 | BO02 | Z | allow faction fundraising events with full disclosure | Party Caucus | Clientelism +0.8, Democratic Norms +0.2 |
| CB07 | BO31 | X | let members vote on the party platform | Party Caucus | Democratic Norms +0.8, Leadership Interest -0.6 |
| CB08 | BO31 | Y | open the party conference to all members | Party Caucus | Democratic Norms +0.6 |
| CB09 | BO31 | Z | let members choose candidates by ballot | Party Caucus | Democratic Norms +1.0, Leadership Interest -0.8 |
| CB10 | BO32 | X | set vetting standards for every candidate | Party Caucus | Leadership Interest +0.6, Democratic Norms +0.3 |
| CB11 | BO32 | Y | require candidates to disclose their finances | Party Caucus | Democratic Norms +0.6, Clientelism -0.5 |
| CB12 | BO32 | Z | create a candidate review board | Party Caucus | Leadership Interest +0.8, Technocratic +0.4 |
| CB13 | BO03 | X | raise allowances for district offices | Natl Assembly | Federal Spending +0.6, Localism +0.6, Clientelism +0.4 |
| CB14 | BO03 | Y | ease the rules on constituent gatherings | Natl Assembly | Localism +0.6, Regulation -0.4 |
| CB15 | BO03 | Z | create a constituency development fund | Finance | Federal Spending +0.9, Clientelism +0.7, Localism +0.5 |
| CB16 | BO04 | X | give towns unconditional block grants | Govt Admin | Localism +1.0, Federal Spending +0.6 |
| CB17 | BO04 | Y | let towns borrow for local projects | Govt Admin | Localism +0.8, Federal Spending +0.3 |
| CB18 | BO04 | Z | give towns their own tax-setting powers | Finance | Localism +1.0, Taxation +0.3 |
| CB19 | BO05 | X | cut the corporate tax rate | Finance | Taxation -1.0, Economic Liberalization +0.7 |
| CB20 | BO05 | Y | simplify business licensing | Govt Admin | Regulation -0.8, Economic Liberalization +0.5 |
| CB21 | BO05 | Z | open special economic zones | Finance | Economic Liberalization +1.0, Globalism +0.5, Industrialism +0.4 |
| CB22 | BO06 | X | fund repairs to community halls | Construction | Federal Spending +0.5, Localism +0.7 |
| CB23 | BO06 | Y | support neighborhood watch groups | Govt Admin | Localism +0.6, Traditional Values +0.3 |
| CB24 | BO06 | Z | give neighborhood associations legal standing in planning | Construction | Localism +1.0, Regulation +0.4 |
| CB25 | BO07 | X | fund harbor repairs | Construction | Federal Spending +0.6, Rural Focus +0.7 |
| CB26 | BO07 | Y | subsidize fuel for fishing boats | Agriculture | Federal Spending +0.6, Agrarianism +0.5, Environmentalism -0.4 |
| CB27 | BO07 | Z | hold fishing quotas through local cooperatives | Agriculture | Localism +0.7, Economic Liberalization -0.5, Rural Focus +0.5 |
| CB28 | BO08 | X | strengthen freedom of information requests | Govt Admin | Civil Liberties +0.8, Democratic Norms +0.6 |
| CB29 | BO08 | Y | protect reporters' confidential sources | Ethics | Civil Liberties +1.0, Judicial Independence +0.3 |
| CB30 | BO08 | Z | open every committee hearing to the press | Natl Assembly | Democratic Norms +0.9, Leadership Interest -0.5 |
| CB31 | BO09 | X | raise the minimum wage | Finance | Regulation +0.8, Economic Liberalization -0.7 |
| CB32 | BO09 | Y | enforce overtime pay | Govt Admin | Regulation +0.7 |
| CB33 | BO09 | Z | protect collective bargaining rights | Govt Admin | Regulation +0.6, Liberal Rights +0.4, Economic Liberalization -0.6 |
| CB34 | BO10 | X | support the rice price | Agriculture | Agrarianism +1.0, Federal Spending +0.5, Economic Liberalization -0.4 |
| CB35 | BO10 | Y | subsidize farm machinery | Agriculture | Agrarianism +0.8, Federal Spending +0.5 |
| CB36 | BO10 | Z | restrict foreign food imports | Foreign Affairs | Globalism -1.0, Agrarianism +0.8, Economic Liberalization -0.5 |
| CB37 | BO11 | X | cap university tuition | Finance | Federal Spending +0.7, Post-Industrialism +0.5 |
| CB38 | BO11 | Y | give students discounted transit | Construction | Federal Spending +0.4 |
| CB39 | BO11 | Z | build public student housing | Construction | Federal Spending +0.8, Post-Industrialism +0.4 |
| CB40 | BO12 | X | raise the child allowance | Finance | Federal Spending +0.8, Traditional Values +0.3 |
| CB41 | BO12 | Y | extend paid parental leave | Govt Admin | Gender Equality +0.7, Regulation +0.5 |
| CB42 | BO12 | Z | open more public childcare places | Govt Admin | Federal Spending +0.8, Gender Equality +0.5 |
| CB43 | BO13 | X | certify local crafts with a protected label | Govt Admin | Traditional Values +0.6, Localism +0.5 |
| CB44 | BO13 | Y | give tax relief for craft apprenticeships | Finance | Taxation -0.4, Traditional Values +0.5 |
| CB45 | BO13 | Z | promote craft exports abroad | Foreign Affairs | Globalism +0.6, Traditional Values +0.4 |
| CB46 | BO14 | X | freeze commuter fares | Construction | Federal Spending +0.6, Rural Focus -0.5 |
| CB47 | BO14 | Y | run late-night commuter trains | Construction | Federal Spending +0.5, Post-Industrialism +0.4 |
| CB48 | BO14 | Z | make every station step-free | Construction | Federal Spending +0.8, Minority Rights +0.4 |
| CB49 | BO15 | X | fund local festivals | Govt Admin | Traditional Values +0.8, Federal Spending +0.3 |
| CB50 | BO15 | Y | protect historic districts from redevelopment | Construction | Traditional Values +0.8, Regulation +0.5 |
| CB51 | BO15 | Z | create a national heritage register | Govt Admin | Traditional Values +1.0, Religious Traditionalism +0.3 |
| CB52 | BO16 | X | give a tax credit for research and development | Finance | Post-Industrialism +1.0, Taxation -0.4 |
| CB53 | BO16 | Y | offer visas to start-up founders | Foreign Affairs | Immigration +0.7, Post-Industrialism +0.6 |
| CB54 | BO16 | Z | move government services online | Govt Admin | Technocratic +0.9, Post-Industrialism +0.5 |
| CB55 | BO17 | X | raise members' staff allowances | Natl Assembly | Federal Spending +0.5, Democratic Norms +0.3 |
| CB56 | BO17 | Y | fund a committee research office | Natl Assembly | Technocratic +0.7, Democratic Norms +0.5 |
| CB57 | BO17 | Z | create an independent parliamentary budget office | Natl Assembly | Technocratic +0.9, Democratic Norms +0.6 |
| CB58 | BO18 | X | hold local referendums on large projects | Govt Admin | Democratic Norms +0.8, Localism +0.6 |
| CB59 | BO18 | Y | require public consultation before new projects | Construction | Democratic Norms +0.7, Regulation +0.4 |
| CB60 | BO18 | Z | let citizen petitions trigger committee hearings | Natl Assembly | Democratic Norms +1.0, Leadership Interest -0.4 |
| CB61 | BO19 | X | fund temple preservation | Govt Admin | Religious Traditionalism +0.8, Federal Spending +0.4 |
| CB62 | BO19 | Y | keep the tax exemption on temple land | Finance | Religious Traditionalism +0.7, Taxation -0.4 |
| CB63 | BO19 | Z | designate temples as disaster shelters | Construction | Religious Traditionalism +0.5, Federal Spending +0.5 |
| CB64 | BO20 | X | support shrine festivals | Govt Admin | Religious Traditionalism +0.8, Traditional Values +0.5 |
| CB65 | BO20 | Y | protect shrine forests from development | Environment | Environmentalism +0.7, Religious Traditionalism +0.5 |
| CB66 | BO20 | Z | list shrine grounds on the heritage register | Govt Admin | Traditional Values +0.8, Religious Traditionalism +0.6 |
| CB67 | BO21 | X | raise care workers' wages | Finance | Federal Spending +0.8, Regulation +0.3 |
| CB68 | BO21 | Y | fund home care visits | Govt Admin | Federal Spending +0.7 |
| CB69 | BO21 | Z | open dementia care centers in every district | Govt Admin | Federal Spending +0.9, Localism +0.3 |
| CB70 | BO22 | X | raise veterans' pensions | War | Militarism +0.6, Federal Spending +0.6 |
| CB71 | BO22 | Y | expand veterans' medical care | War | Militarism +0.5, Federal Spending +0.6 |
| CB72 | BO22 | Z | give veterans hiring preference in public jobs | War | Militarism +0.8, Regulation +0.3 |
| CB73 | BO23 | X | cap growth in government spending | Finance | Federal Spending -1.0 |
| CB74 | BO23 | Y | publish the full cost of every bill | Finance | Technocratic +0.6, Democratic Norms +0.4 |
| CB75 | BO23 | Z | add sunset clauses to new spending | Finance | Federal Spending -0.8, Technocratic +0.3 |
| CB76 | BO24 | X | ease bank lending rules | Finance | Regulation -0.8, Economic Liberalization +0.7 |
| CB77 | BO24 | Y | create tax-free investment accounts | Finance | Taxation -0.6, Economic Liberalization +0.5 |
| CB78 | BO24 | Z | build a financial hub zone in Sapporo | Finance | Economic Liberalization +0.9, Globalism +0.7 |
| CB79 | BO25 | X | cut taxes for small businesses | Finance | Taxation -0.8 |
| CB80 | BO25 | Y | cut paperwork for small firms | Govt Admin | Regulation -0.7 |
| CB81 | BO25 | Z | make large firms pay suppliers on time | Finance | Regulation +0.5, Economic Liberalization -0.2 |
| CB82 | BO26 | X | require clear price labels | Govt Admin | Regulation +0.7 |
| CB83 | BO26 | Y | give buyers a cooling-off period | Govt Admin | Regulation +0.6, Liberal Rights +0.3 |
| CB84 | BO26 | Z | cap bank fees | Finance | Regulation +0.8, Economic Liberalization -0.6 |
| CB85 | BO27 | X | set an affordable housing quota for new buildings | Construction | Regulation +0.6, Federal Spending +0.4, Rural Focus -0.5 |
| CB86 | BO27 | Y | build more city parks | Environment | Environmentalism +0.6, Rural Focus -0.4 |
| CB87 | BO27 | Z | cap rent rises in the cities | Construction | Regulation +0.9, Economic Liberalization -0.7 |
| CB88 | BO28 | X | restore Ainu fishing and harvest rights | Agriculture | Ainu Enhancement +1.0, Minority Rights +0.6 |
| CB89 | BO28 | Y | fund Ainu community centers | Govt Admin | Ainu Enhancement +0.8, Federal Spending +0.4 |
| CB90 | BO28 | Z | require consultation with Ainu communities on land use | Construction | Ainu Enhancement +1.0, Minority Rights +0.7, Localism +0.3 |
| CB91 | BO29 | X | teach the Ainu language in schools | Govt Admin | Ainu Enhancement +0.9, Ethnic Pluralism +0.5 |
| CB92 | BO29 | Y | put Ainu names on public signs | Govt Admin | Ainu Enhancement +0.7, Ethnic Pluralism +0.5 |
| CB93 | BO29 | Z | fund Ainu-language broadcasting | Govt Admin | Ainu Enhancement +0.9, Federal Spending +0.5 |
| CB94 | BO30 | X | keep rural bus routes running | Construction | Rural Focus +0.9, Federal Spending +0.5 |
| CB95 | BO30 | Y | pay grants to families moving to rural towns | Govt Admin | Rural Focus +0.9, Federal Spending +0.5 |
| CB96 | BO30 | Z | bring broadband to every village | Construction | Rural Focus +0.8, Post-Industrialism +0.5, Federal Spending +0.6 |

### Patron bills (64)

| ID | Organization | At | Kind | Bill (assembled name) | Components | Gains | Loses | Hearing | Party lean | Default vote (Aye-Nay-Abstain) |
|---|---|---|---|---|---|---|---|---|---|---|
| PB01 | Party Headquarters | 50 | Favor | A bill to route campaign funding through party headquarters and require party approval for members' private bills | CB01 + CB02 | Party Headquarters | Party Faction | Party Caucus | own party only | Party Caucus decides |
| PB02 | Party Headquarters | 70 | Flagship | A bill to route campaign funding through party headquarters, create a central campaign data office and set vetting standards for every candidate | CB01 + CB03 + CB10 | Party Headquarters, Candidate Selection Committee | Party Faction | Party Caucus | own party only | Party Caucus decides |
| PB03 | Party Faction | 50 | Favor | A bill to award committee chairs by seniority and protect faction study groups from headquarters control | CB04 + CB05 | Party Faction | Party Headquarters | Party Caucus | own party only | Party Caucus decides |
| PB04 | Party Faction | 70 | Flagship | A bill to award committee chairs by seniority, allow faction fundraising events with full disclosure and let members vote on the party platform | CB04 + CB06 + CB07 | Party Faction, Party Activists | Party Headquarters | Party Caucus | own party only | Party Caucus decides |
| PB05 | Party Activists | 50 | Favor | A bill to let members vote on the party platform and open the party conference to all members | CB07 + CB08 | Party Activists | Candidate Selection Committee | Party Caucus | own party only | Party Caucus decides |
| PB06 | Party Activists | 70 | Flagship | A bill to let members vote on the party platform, let members choose candidates by ballot and award committee chairs by seniority | CB07 + CB09 + CB04 | Party Activists, Party Faction | Candidate Selection Committee | Party Caucus | own party only | Party Caucus decides |
| PB07 | Candidate Selection Committee | 50 | Favor | A bill to set vetting standards for every candidate and require candidates to disclose their finances | CB10 + CB11 | Candidate Selection Committee | Party Activists | Party Caucus | own party only | Party Caucus decides |
| PB08 | Candidate Selection Committee | 70 | Flagship | A bill to set vetting standards for every candidate, create a candidate review board and route campaign funding through party headquarters | CB10 + CB12 + CB01 | Candidate Selection Committee, Party Headquarters | Party Activists | Party Caucus | own party only | Party Caucus decides |
| PB09 | Local Kōenkai | 50 | Favor | A bill to raise allowances for district offices and ease the rules on constituent gatherings | CB13 + CB14 | Local Kōenkai | Taxpayers' Alliance | Natl Assembly | BU:N YH:S FR:S FP:S KJ:S CI:O | 69-25-7 passes |
| PB10 | Local Kōenkai | 70 | Flagship | A bill to raise allowances for district offices, create a constituency development fund and hold local referendums on large projects | CB13 + CB15 + CB58 | Local Kōenkai, Constituency Voters | Taxpayers' Alliance | Natl Assembly | BU:S YH:S FR:S FP:S KJ:N CI:O | 69-22-10 passes |
| PB11 | Mayors' Network | 50 | Favor | A bill to give towns unconditional block grants and let towns borrow for local projects | CB16 + CB17 | Mayors' Network | Taxpayers' Alliance | Govt Admin | BU:N YH:S FR:S FP:S KJ:O CI:O | 56-38-7 passes |
| PB12 | Mayors' Network | 70 | Flagship | A bill to give towns unconditional block grants, give towns their own tax-setting powers and keep rural bus routes running | CB16 + CB18 + CB94 | Mayors' Network, Rural Revitalization Council | Taxpayers' Alliance | Govt Admin | BU:O YH:S FR:S FP:S KJ:O CI:O | 52-47-2 passes |
| PB13 | Chamber of Commerce | 50 | Favor | A bill to cut the corporate tax rate and simplify business licensing | CB19 + CB20 | Chamber of Commerce | Labor Federation | Finance | BU:O YH:N FR:S FP:N KJ:S CI:S | 64-30-7 passes |
| PB14 | Chamber of Commerce | 70 | Flagship | A bill to cut the corporate tax rate, open special economic zones and ease bank lending rules | CB19 + CB21 + CB76 | Chamber of Commerce, Financial Industry Association | Labor Federation | Finance | BU:O YH:O FR:S FP:S KJ:S CI:S | 68-33-0 passes |
| PB15 | Neighborhood Associations | 50 | Favor | A bill to fund repairs to community halls and support neighborhood watch groups | CB22 + CB23 | Neighborhood Associations | Chamber of Commerce | Construction | BU:N YH:S FR:S FP:S KJ:O CI:O | 60-33-8 passes |
| PB16 | Neighborhood Associations | 70 | Flagship | A bill to fund repairs to community halls, give neighborhood associations legal standing in planning and raise allowances for district offices | CB22 + CB24 + CB13 | Neighborhood Associations, Local Kōenkai | Chamber of Commerce | Construction | BU:N YH:S FR:S FP:S KJ:O CI:O | 54-40-7 passes |
| PB17 | Fisheries Cooperative | 50 | Favor | A bill to fund harbor repairs and subsidize fuel for fishing boats | CB25 + CB26 | Fisheries Cooperative | Consumer Advocacy Network | Construction | BU:N YH:S FR:S FP:S KJ:N CI:O | 63-21-17 passes |
| PB18 | Fisheries Cooperative | 70 | Flagship | A bill to fund harbor repairs, hold fishing quotas through local cooperatives and support the rice price | CB25 + CB27 + CB34 | Fisheries Cooperative, Agricultural Cooperatives | Consumer Advocacy Network | Construction | BU:S YH:S FR:S FP:S KJ:O CI:O | 62-39-0 passes |
| PB19 | National Media | 50 | Favor | A bill to strengthen freedom of information requests and protect reporters' confidential sources | CB28 + CB29 | National Media | Party Headquarters | Govt Admin | BU:N YH:O FR:S FP:N KJ:S CI:N | 59-28-14 passes |
| PB20 | National Media | 70 | Flagship | A bill to strengthen freedom of information requests, open every committee hearing to the press and require clear price labels | CB28 + CB30 + CB82 | National Media, Consumer Advocacy Network | Party Headquarters | Govt Admin | BU:S YH:N FR:S FP:S KJ:O CI:O | 51-44-6 passes |
| PB21 | Labor Federation | 50 | Favor | A bill to raise the minimum wage and enforce overtime pay | CB31 + CB32 | Labor Federation | Chamber of Commerce | Finance | BU:S YH:N FR:N FP:N KJ:O CI:O | 40-44-17 fails |
| PB22 | Labor Federation | 70 | Flagship | A bill to raise the minimum wage, protect collective bargaining rights and raise care workers' wages | CB31 + CB33 + CB67 | Labor Federation, Care and Welfare Council | Chamber of Commerce | Finance | BU:S YH:S FR:S FP:S KJ:O CI:O | 59-42-0 passes |
| PB23 | Agricultural Cooperatives | 50 | Favor | A bill to support the rice price and subsidize farm machinery | CB34 + CB35 | Agricultural Cooperatives | Urban Neighborhood Alliance | Agriculture | BU:S YH:S FR:S FP:S KJ:O CI:O | 69-31-1 passes |
| PB24 | Agricultural Cooperatives | 70 | Flagship | A bill to support the rice price, restrict foreign food imports and keep rural bus routes running | CB34 + CB36 + CB94 | Agricultural Cooperatives, Rural Revitalization Council | Urban Neighborhood Alliance | Agriculture | BU:S YH:S FR:S FP:N KJ:O CI:O | 63-36-2 passes |
| PB25 | Students United | 50 | Favor | A bill to cap university tuition and give students discounted transit | CB37 + CB38 | Students United | Our Traditional Society | Finance | BU:S YH:S FR:S FP:S KJ:S CI:O | 75-25-1 passes |
| PB26 | Students United | 70 | Flagship | A bill to cap university tuition, build public student housing and give a tax credit for research and development | CB37 + CB39 + CB52 | Students United, Innovation Society | Our Traditional Society | Finance | BU:S YH:S FR:S FP:S KJ:S CI:O | 84-17-0 passes |
| PB27 | Family Network | 50 | Favor | A bill to raise the child allowance and extend paid parental leave | CB40 + CB41 | Family Network | Small Business Owners' Association | Finance | BU:S YH:S FR:S FP:S KJ:O CI:O | 63-38-0 passes |
| PB28 | Family Network | 70 | Flagship | A bill to raise the child allowance, open more public childcare places and raise care workers' wages | CB40 + CB42 + CB67 | Family Network, Care and Welfare Council | Small Business Owners' Association | Finance | BU:S YH:S FR:S FP:S KJ:N CI:O | 72-20-9 passes |
| PB29 | Yezo Artisans Guild | 50 | Favor | A bill to certify local crafts with a protected label and give tax relief for craft apprenticeships | CB43 + CB44 | Yezo Artisans Guild | Innovation Society | Govt Admin | BU:N YH:S FR:S FP:S KJ:N CI:S | 56-26-19 passes |
| PB30 | Yezo Artisans Guild | 70 | Flagship | A bill to certify local crafts with a protected label, promote craft exports abroad and fund local festivals | CB43 + CB45 + CB49 | Yezo Artisans Guild, Our Traditional Society | Innovation Society | Govt Admin | BU:S YH:S FR:S FP:S KJ:N CI:S | 70-20-11 passes |
| PB31 | Commuter Committee | 50 | Favor | A bill to freeze commuter fares and run late-night commuter trains | CB46 + CB47 | Commuter Committee | Rural Revitalization Council | Construction | BU:S YH:N FR:N FP:S KJ:S CI:O | 61-25-15 passes |
| PB32 | Commuter Committee | 70 | Flagship | A bill to freeze commuter fares, make every station step-free and set an affordable housing quota for new buildings | CB46 + CB48 + CB85 | Commuter Committee, Urban Neighborhood Alliance | Rural Revitalization Council | Construction | BU:S YH:N FR:S FP:S KJ:N CI:O | 52-34-15 passes |
| PB33 | Our Traditional Society | 50 | Favor | A bill to fund local festivals and protect historic districts from redevelopment | CB49 + CB50 | Our Traditional Society | Students United | Govt Admin | BU:S YH:S FR:S FP:N KJ:O CI:S | 56-41-4 passes |
| PB34 | Our Traditional Society | 70 | Flagship | A bill to fund local festivals, create a national heritage register and support shrine festivals | CB49 + CB51 + CB64 | Our Traditional Society, Shrine Association | Students United | Govt Admin | BU:S YH:S FR:S FP:N KJ:N CI:S | 68-20-13 passes |
| PB35 | Innovation Society | 50 | Favor | A bill to give a tax credit for research and development and offer visas to start-up founders | CB52 + CB53 | Innovation Society | Yezo Artisans Guild | Finance | BU:S YH:N FR:N FP:S KJ:S CI:O | 59-27-15 passes |
| PB36 | Innovation Society | 70 | Flagship | A bill to give a tax credit for research and development, move government services online and cut the corporate tax rate | CB52 + CB54 + CB19 | Innovation Society, Chamber of Commerce | Yezo Artisans Guild | Finance | BU:N YH:O FR:S FP:S KJ:S CI:S | 70-23-8 passes |
| PB37 | Members of Parliament | 50 | Favor | A bill to raise members' staff allowances and fund a committee research office | CB55 + CB56 | Members of Parliament | Taxpayers' Alliance | Natl Assembly | BU:N YH:N FR:S FP:N KJ:N CI:O | 56-22-23 passes |
| PB38 | Members of Parliament | 70 | Flagship | A bill to raise members' staff allowances, create an independent parliamentary budget office and award committee chairs by seniority | CB55 + CB57 + CB04 | Members of Parliament, Party Faction | Taxpayers' Alliance | Natl Assembly | BU:S YH:S FR:S FP:S KJ:O CI:O | 59-42-0 passes |
| PB39 | Constituency Voters | 50 | Favor | A bill to hold local referendums on large projects and require public consultation before new projects | CB58 + CB59 | Constituency Voters | Members of Parliament | Govt Admin | BU:S YH:S FR:S FP:S KJ:O CI:O | 63-36-2 passes |
| PB40 | Constituency Voters | 70 | Flagship | A bill to hold local referendums on large projects, let citizen petitions trigger committee hearings and fund repairs to community halls | CB58 + CB60 + CB22 | Constituency Voters, Neighborhood Associations | Members of Parliament | Govt Admin | BU:N YH:S FR:S FP:S KJ:O CI:O | 61-32-8 passes |
| PB41 | Buddhist Temples Association | 50 | Favor | A bill to fund temple preservation and keep the tax exemption on temple land | CB61 + CB62 | Buddhist Temples Association | Taxpayers' Alliance | Govt Admin | BU:S YH:S FR:S FP:S KJ:S CI:N | 73-20-8 passes |
| PB42 | Buddhist Temples Association | 70 | Flagship | A bill to fund temple preservation, designate temples as disaster shelters and support shrine festivals | CB61 + CB63 + CB64 | Buddhist Temples Association, Shrine Association | Taxpayers' Alliance | Govt Admin | BU:S YH:S FR:S FP:S KJ:S CI:O | 78-21-2 passes |
| PB43 | Shrine Association | 50 | Favor | A bill to support shrine festivals and protect shrine forests from development | CB64 + CB65 | Shrine Association | Chamber of Commerce | Govt Admin | BU:S YH:S FR:N FP:N KJ:N CI:N | 52-23-26 passes |
| PB44 | Shrine Association | 70 | Flagship | A bill to support shrine festivals, list shrine grounds on the heritage register and fund local festivals | CB64 + CB66 + CB49 | Shrine Association, Our Traditional Society | Chamber of Commerce | Govt Admin | BU:S YH:S FR:S FP:N KJ:N CI:S | 70-20-11 passes |
| PB45 | Care and Welfare Council | 50 | Favor | A bill to raise care workers' wages and fund home care visits | CB67 + CB68 | Care and Welfare Council | Taxpayers' Alliance | Finance | BU:S YH:S FR:S FP:S KJ:N CI:O | 61-31-9 passes |
| PB46 | Care and Welfare Council | 70 | Flagship | A bill to raise care workers' wages, open dementia care centers in every district and raise the child allowance | CB67 + CB69 + CB40 | Care and Welfare Council, Family Network | Taxpayers' Alliance | Finance | BU:S YH:S FR:S FP:S KJ:N CI:O | 67-24-10 passes |
| PB47 | Veterans' Association | 50 | Favor | A bill to raise veterans' pensions and expand veterans' medical care | CB70 + CB71 | Veterans' Association | Students United | War | BU:N YH:S FR:S FP:S KJ:S CI:O | 62-30-9 passes |
| PB48 | Veterans' Association | 70 | Flagship | A bill to raise veterans' pensions, give veterans hiring preference in public jobs and fund local festivals | CB70 + CB72 + CB49 | Veterans' Association, Our Traditional Society | Students United | War | BU:N YH:S FR:S FP:S KJ:O CI:O | 56-37-8 passes |
| PB49 | Taxpayers' Alliance | 50 | Favor | A bill to cap growth in government spending and publish the full cost of every bill | CB73 + CB74 | Taxpayers' Alliance | Care and Welfare Council | Finance | BU:O YH:O FR:O FP:O KJ:O CI:S | 31-67-3 fails |
| PB50 | Taxpayers' Alliance | 70 | Flagship | A bill to cap growth in government spending, add sunset clauses to new spending and cut the corporate tax rate | CB73 + CB75 + CB19 | Taxpayers' Alliance, Chamber of Commerce | Care and Welfare Council | Finance | BU:O YH:O FR:O FP:O KJ:S CI:S | 36-65-0 fails |
| PB51 | Financial Industry Association | 50 | Favor | A bill to ease bank lending rules and create tax-free investment accounts | CB76 + CB77 | Financial Industry Association | Consumer Advocacy Network | Finance | BU:O YH:N FR:S FP:N KJ:S CI:S | 61-31-9 passes |
| PB52 | Financial Industry Association | 70 | Flagship | A bill to ease bank lending rules, build a financial hub zone in Sapporo and cut the corporate tax rate | CB76 + CB78 + CB19 | Financial Industry Association, Chamber of Commerce | Consumer Advocacy Network | Finance | BU:O YH:O FR:S FP:S KJ:S CI:S | 71-30-0 passes |
| PB53 | Small Business Owners' Association | 50 | Favor | A bill to cut taxes for small businesses and cut paperwork for small firms | CB79 + CB80 | Small Business Owners' Association | Labor Federation | Finance | BU:O YH:N FR:N FP:N KJ:S CI:S | 56-27-18 passes |
| PB54 | Small Business Owners' Association | 70 | Flagship | A bill to cut taxes for small businesses, make large firms pay suppliers on time and cut the corporate tax rate | CB79 + CB81 + CB19 | Small Business Owners' Association, Chamber of Commerce | Labor Federation | Finance | BU:N YH:N FR:S FP:S KJ:N CI:S | 57-22-22 passes |
| PB55 | Consumer Advocacy Network | 50 | Favor | A bill to require clear price labels and give buyers a cooling-off period | CB82 + CB83 | Consumer Advocacy Network | Financial Industry Association | Govt Admin | BU:S YH:N FR:S FP:S KJ:O CI:O | 47-47-7 fails |
| PB56 | Consumer Advocacy Network | 70 | Flagship | A bill to require clear price labels, cap bank fees and strengthen freedom of information requests | CB82 + CB84 + CB28 | Consumer Advocacy Network, National Media | Financial Industry Association | Govt Admin | BU:S YH:N FR:S FP:S KJ:O CI:O | 50-45-6 fails |
| PB57 | Urban Neighborhood Alliance | 50 | Favor | A bill to set an affordable housing quota for new buildings and build more city parks | CB85 + CB86 | Urban Neighborhood Alliance | Rural Revitalization Council | Construction | BU:S YH:O FR:O FP:S KJ:O CI:O | 30-70-1 fails |
| PB58 | Urban Neighborhood Alliance | 70 | Flagship | A bill to set an affordable housing quota for new buildings, cap rent rises in the cities and freeze commuter fares | CB85 + CB87 + CB46 | Urban Neighborhood Alliance, Commuter Committee | Rural Revitalization Council | Construction | BU:S YH:N FR:O FP:S KJ:O CI:O | 32-64-5 fails |
| PB59 | Ainu Community Council | 50 | Favor | A bill to restore Ainu fishing and harvest rights and fund Ainu community centers | CB88 + CB89 | Ainu Community Council | Our Traditional Society | Agriculture | BU:S YH:S FR:S FP:N KJ:N CI:O | 55-34-12 passes |
| PB60 | Ainu Community Council | 70 | Flagship | A bill to restore Ainu fishing and harvest rights, require consultation with Ainu communities on land use and teach the Ainu language in schools | CB88 + CB90 + CB91 | Ainu Community Council, Ainu Language and Culture Foundation | Our Traditional Society | Agriculture | BU:S YH:S FR:S FP:N KJ:O CI:O | 59-38-4 passes |
| PB61 | Ainu Language and Culture Foundation | 50 | Favor | A bill to teach the Ainu language in schools and put Ainu names on public signs | CB91 + CB92 | Ainu Language and Culture Foundation | Our Traditional Society | Govt Admin | BU:N YH:S FR:O FP:O KJ:N CI:O | 37-45-19 fails |
| PB62 | Ainu Language and Culture Foundation | 70 | Flagship | A bill to teach the Ainu language in schools, fund Ainu-language broadcasting and restore Ainu fishing and harvest rights | CB91 + CB93 + CB88 | Ainu Language and Culture Foundation, Ainu Community Council | Our Traditional Society | Govt Admin | BU:S YH:S FR:S FP:O KJ:N CI:O | 54-38-9 passes |
| PB63 | Rural Revitalization Council | 50 | Favor | A bill to keep rural bus routes running and pay grants to families moving to rural towns | CB94 + CB95 | Rural Revitalization Council | Urban Neighborhood Alliance | Construction | BU:N YH:S FR:S FP:S KJ:O CI:O | 54-40-7 passes |
| PB64 | Rural Revitalization Council | 70 | Flagship | A bill to keep rural bus routes running, bring broadband to every village and support the rice price | CB94 + CB96 + CB34 | Rural Revitalization Council, Agricultural Cooperatives | Urban Neighborhood Alliance | Construction | BU:S YH:S FR:S FP:S KJ:O CI:O | 68-32-1 passes |

Default result without influence: 48 pass, 8 fail, 8 decided in caucus.
