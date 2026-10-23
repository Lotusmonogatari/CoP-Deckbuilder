# Calendar, party dues, awareness and events: build plan (2026-10-23), waiting for approval

Cameron's answers to the campaign-layer ideation are recorded below as decisions. Everything marked **Assumption** is my reading; correct any that are wrong before I build. About 900 lines of new code in total, so the work is split into seven steps, each approved separately. Several steps add workbook columns or tabs (schema changes), which also need your OK.

## Executive summary

| Topic | Decision | Build step |
|---|---|---|
| Time | 8-hour workdays, Mon to Fri; Sat and Sun get 4 hours each. Hours per stage are set in the workbook. The calendar starts Monday 1 Oct 2018 and is shown on a small gold-edged square in the Office. | 1 |
| Week end | Fri may end the week early (no bonus or penalty). "Pay Party Dues and Go Home" ends Sunday. A cue popup on the Office screen announces the next week. | 2 |
| Dues | 100,000円 plus 30% of the week's Mon to Fri rewards, plus 50,000円 per 15 Party support above 40. | 3 |
| Overdue dues | The balance rolls over; Party support drops 10; positive party modifiers are cancelled; scaled penalties apply to Party HQ, the other parties and the Selection Committee. | 3 |
| Awareness | Two meters (district, national); leftover gaffes at a stage's end count against both; a new tab holds the awareness rewards and penalties. | 4 and 5 |
| Events | Fixed choices and flavor text with variable rewards; they can reveal a related bill level that is then bought with its XP price. | 6 |
| Election | No fixed date. The build is an unending sandbox. Campaign strength (idea 3) is parked. | none |

## Hours per stage

| Stage family | Hours | Note |
|---|---|---|
| Lobbyist Meeting, Town Hall, Office Hours, Press Conference | 2 | As you said |
| Committee hearing (Special Committee and the named committees), Party Caucus, Floor Debate | 4 | As you said |
| Floor Vote | 1 | As you said |
| TV Debate | 3 | As you said |
| **Assumption:** Media Ambush | 1 | Short, always follows a Lobbyist Meeting |
| **Assumption:** Party Steering Committee (ST08) | 4 | A caucus-like committee |
| **Assumption:** Steering Check-In (ST22), Policy Study Session, Member Visit, Trade, Win Over a Member | 2 | Like the other 2-hour rooms |
| Items | set per item | Walking tour and dinner are 4 hours |

The Stages tab already has a **Time Units** column (blank counts as 1). It becomes the hours column. One workbook edit sets about 260 rows by room family (clones like "Press Conference on..." follow their family).

### What the numbers do to a level

| Fact (from the current levels) | Value |
|---|---|
| Average level length at these hours | 16.3 hours, about two days |
| Range | 2 to 35 hours; 15 levels are 15 hours |
| Levels per work week (40 hours) | about 2.4 |
| Levels short enough for a 4-hour weekend day | LV01 (4h), LV83 Town Hall, LV84 Steering Check-In; LV02 is 3h but ends in a Media Ambush, so it is excluded as you asked |

**So the weekend needs new content.** Only three existing levels fit, and no real "district activity" level exists yet. Weekend levels need a new Levels column (**Weekend OK**) and new single-stage levels. Events, with a flag for work week, weekend or both, will carry much of this.

## Your decisions, restated (so I build the right thing)

| # | Decision |
|---|---|
| 1 | Day = 8 hours on weekdays; weekend days have a separate 4 hours each. Hours carry over into the next day if a stage runs past the limit. The week does not cross over. On Friday the player may end the week early. |
| 2 | Dues = 100,000円 + 30% of that work week's rewards. Plus 50,000円 for every 15 Party support above 40. |
| 3 | Two awareness meters, national and district. A stage's leftover gaffes count as negative points on both. A gaffe-out loss counts as minus the stage's gaffe limit (for example -5). |
| 4 | Awareness effects, in a new workbook tab (see the next table). |
| 5 | A small calendar square on the Office screen: top row DD.MM.YY, bottom row "# Work Hours", gold edge (the title screen's cue-banner gold). |
| 6 | Dues owed past the due point scale at 1.5x per 100,000円 overdue: -20 Party HQ, +5 to every other party, -5 Selection Committee. |
| 7 | No election date. Unending sandbox. |
| 8 | Events: a fixed screen of flavor text and choices, with variable rewards, which can unlock a related bill level (the player then pays that level's existing XP price). |

### Awareness effects (the new tab: "Awareness Effects")

| Meter | Condition | Effect |
|---|---|---|
| National | 80 or more | Baseline dues are 100,000円 lower |
| District | 80 or more | One free card gacha (a Rhetoric Training draw) |
| National | 65 or more | +5 starting support in Media Ambush, Press Conference, TV Debate |
| District | 65 or more | +5 starting support in Town Hall |
| District | 50 or less | -10 standing with the Candidate Selection Committee |
| District | 25 or less | -50 XP |
| National | 40 or less | -5 standing with every National-tier organization, added for each week that ends below 40 |

Each row is data: meter, comparison, threshold, effect type, target, value, timing. New rows can be added without code.

## Assumptions to confirm

| # | Assumption | Why it matters |
|---|---|---|
| A1 | "Party reputation" and "party support" are the same thing: the existing Party support meter. | Dues, the overdue penalty and the 50,000円 steps all read it |
| A2 | "Rewards during that work week" means the Funds (Yen) earned Mon to Fri from stages, levels, backings and visitors, not XP. Weekend rewards are not counted. | Sets the 30% |
| A3 | The 50,000円 step is one step per full 15 points above 40: 55 gives +50,000円, 70 gives +100,000円, 85 gives +150,000円, 100 gives +200,000円. | Sets the formula |
| A4 | Overdue scaling is 1.5 raised to the number of full 100,000円 overdue, applied to the base penalties (-20, +5, -5). So 100,000円 overdue is 1.5x, 200,000円 is 2.25x. | "1.5x per 100,000円" can also mean a straight 1.5x, 2x, 2.5x |
| A5 | The overdue penalties apply at each week's end while any balance remains unpaid, and the Party support drop of 10 happens once per week that dues are short. | Makes sustained debt costly |
| A6 | "Positive party modifiers/bonuses" are the backings from Party-tier organizations (BO01, BO02, BO31, BO32) and the free Party Backing (M09). Cancelled means removed and must be bought or earned again. | Defines what is lost |
| A7 | "Ending the week early" on Friday skips Saturday and Sunday and goes straight to the dues payment ("Pay Party Dues and Go Home" appears then too). | The Sunday button is the only dues step you described |
| A8 | The calendar's bottom row shows hours **left** today ("6 Work Hours"); on weekend days "Weekend Hours" with the 4 count. | Text rows either way |
| A9 | Awareness effect timing: threshold effects are checked at each week end. Only the national -5 stacks, as you wrote. The rest apply once per week while the condition holds. | Your list marked only the last as additive |
| A10 | The free card gacha is once per week end while District Awareness is 80 or more. | Frequency |
| A11 | Awareness sources are the ones from the ideation (media buys, grants, bills carried, vote flips, press and town hall stages, events), with numbers to be drafted. | You listed effects but not sources |
| A12 | Existing time-based numbers (cooldowns, durations, special-level delay, news ticker, patron backing units, Draft a Bill cooldown) were written when an average stage was 1 unit. Stages are now about 3 hours on average. I will convert them (multiply by 3) and tell you the new values. | Otherwise cooldowns become three times too short |
| A13 | A "discovered" bill level (from an event) appears in the level list as buyable with its XP price; levels flagged "Needs Discovery" stay hidden until revealed. | Defines the unlock |

## Build steps

| Step | Build | Schema change | Size |
|---|---|---|---|
| 1 | **Hours and calendar**: stage hours, weekday and weekend hour budgets, the calendar square, date from 1 Oct 2018, hour spillover, unit conversion (A12) | Levels: Weekend OK. Stages: hours values only | about 250 lines |
| 2 | **Week flow**: Friday "End the week early", the Sunday "Pay Party Dues and Go Home" button, the week-end popup on the Office screen, weekend level filter | none | about 180 lines |
| 3 | **Dues**: formula, weekly reward tally, payment, overdue balance and its penalties, the loss of party backings | Balance levers | about 250 lines |
| 4 | **Awareness meters**: two meters, gaffe penalties at stage end, display, decay if you want it | Two Sanban rows | about 150 lines |
| 5 | **Awareness Effects tab** and the effects engine; sources | New tab | about 250 lines |
| 6 | **Events**: tabs, screen, level reveal, weekday and weekend flags | Two new tabs | about 250 lines |
| 7 | **Content and balance**: first dozen events, media buys, an economy trial | Content | workbook |

## Risks

| Risk | Note |
|---|---|
| Weekend content gap | Only three existing levels fit. Without new content the weekend is mostly events |
| Dues weight | At 16.3 hours a level, a work week earns roughly 470,000円 (before the recent payout raises), so dues are about 240,000円, around half of income. Please tune after a trial |
| Clock reversal | The earlier "never show the clock" rule is replaced by your calendar |
| Tests | Clock, special-level and cooldown tests will be updated for the new units |
| Saves | New fields have defaults, so current saves still load |
