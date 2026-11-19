# Hours impact: what travel would take of a 40-hour week

## Method (read this before the numbers)

1. **The play data** is the strategy bot's 144 logged runs in `design/bench/pc_difficulty.jsonl` (4 protagonists x 3 Campaign Pressures x 12 runs; 30 weeks each). Each run lists the levels it played, in order, with the week and the hours of each: 20485 level plays.
2. **Each level's office** comes from `levels_location.csv` (this audit's proposal: Capitol, District or Either; a mixed level takes its overall shape). Levels the bot played that the CSV does not list: none.
3. **The replay.** The player starts a run at the Capitol and each week starts where the last one ended (settled rule). Playing a level at the other office costs one trip first; an Either level costs nothing; a mixed level's travel is built in and costs nothing; forced moves (the Dated Prime Minister's Opening Address, EV47) cost nothing. Two orders: **as played** (the bot's own order, which ignores location, so it is a pessimistic and noisy upper bound) and **batched** (the best a thoughtful player can do: do everything at the current office first, then make at most one trip a week).
4. **Hours.** Train and car hours are the settled ones (PC01 6/5, PC02 1/1, PC03 1/1, PC04 6/9). One trip spends that many hours from the week's pool of 40. A week is the work week (Monday to Friday); the weekend (8 optional hours) is left out, and so is travel at the weekend (an open question).
5. **What it does not model.** The bot would choose different levels if only one office's levels were listed; the real mix per office would shift play. Crisis levels (LV83 and LV84) wait at their own office and are forced on arrival without a trip; promises and events that need an office are not modelled. The logs predate the staff wages and tasks (2026-11-16), so level hours per week are older numbers. Treat every figure as an order of magnitude.

## Where the levels are (share of the hours the bot played)

| Protagonist | Capitol | District | Either | Mean hours per level | Mean levels per week |
|---|---|---|---|---|---|
| Kenshin Sako (Wakkanai) | 75% | 20% | 5% | 7.5 | 4.7 |
| Haru Yashi (Tomakomai) | 74% | 20% | 5% | 7.5 | 4.7 |
| Arata Ran (Sapporo Block 6) | 75% | 20% | 5% | 7.6 | 4.7 |
| Jyurou Nishihara (Aomori Block 3) | 74% | 21% | 5% | 7.3 | 4.8 |

## Travel per protagonist (all 144 runs; mean per week of 40 work hours)

| Protagonist | Mode | Order | Trips per week | Travel hours per week | Share of the 40 hours | Weeks with at least one trip | Worst week (hours) |
|---|---|---|---|---|---|---|---|
| Kenshin Sako (Wakkanai) | train | as played | 1.87 | 11.2 | 28% | 77% | 42 |
| Kenshin Sako (Wakkanai) | train | batched | 0.80 | 4.8 | 12% | 80% | 6 |
| Kenshin Sako (Wakkanai) | car | as played | 1.87 | 9.3 | 23% | 77% | 35 |
| Kenshin Sako (Wakkanai) | car | batched | 0.80 | 4.0 | 10% | 80% | 5 |
| Haru Yashi (Tomakomai) | train | as played | 1.89 | 1.9 | 5% | 77% | 10 |
| Haru Yashi (Tomakomai) | train | batched | 0.81 | 0.8 | 2% | 81% | 1 |
| Haru Yashi (Tomakomai) | car | as played | 1.89 | 1.9 | 5% | 77% | 10 |
| Haru Yashi (Tomakomai) | car | batched | 0.81 | 0.8 | 2% | 81% | 1 |
| Arata Ran (Sapporo Block 6) | train | as played | 1.89 | 1.9 | 5% | 77% | 7 |
| Arata Ran (Sapporo Block 6) | train | batched | 0.80 | 0.8 | 2% | 80% | 1 |
| Arata Ran (Sapporo Block 6) | car | as played | 1.89 | 1.9 | 5% | 77% | 7 |
| Arata Ran (Sapporo Block 6) | car | batched | 0.80 | 0.8 | 2% | 80% | 1 |
| Jyurou Nishihara (Aomori Block 3) | train | as played | 1.92 | 11.5 | 29% | 76% | 42 |
| Jyurou Nishihara (Aomori Block 3) | train | batched | 0.79 | 4.7 | 12% | 79% | 6 |
| Jyurou Nishihara (Aomori Block 3) | car | as played | 1.92 | 17.3 | 43% | 76% | 63 |
| Jyurou Nishihara (Aomori Block 3) | car | batched | 0.79 | 7.1 | 18% | 79% | 9 |

## Standard Campaign Pressure only, train, hours per week

| Protagonist | As played | Batched |
|---|---|---|
| Kenshin Sako (Wakkanai) | 11.0 | 4.7 |
| Haru Yashi (Tomakomai) | 1.9 | 0.8 |
| Arata Ran (Sapporo Block 6) | 1.9 | 0.8 |
| Jyurou Nishihara (Aomori Block 3) | 10.8 | 4.5 |

## Reading

- **Short routes are almost free.** PC02 and PC03 spend a trip hour each way: batched, about 0.8 hours a week (2% of the work week); the bot's order, about 1.9.
- **PC01 and PC04 look harder.** A 6-hour train is 4.8 hours a week batched (12%) and 11.2 as played (28%). In the worst week a player who keeps crossing spends 42 hours travelling.
- **PC04's car is slower, not faster** (9 hours against 6): by car it is 7.1 hours a week batched against 4.7 by train. PC01's car saves an hour a trip.
- **Most weeks have a trip.** Because the logged levels are 75% Capitol by hours for PC01, a player who lives mostly at the Capitol and goes home for District levels crosses in about 80% of weeks (batched).
- **The honest answer on Easy:** the cost is not the average, it is the lumpiness. A 12-hour round trip is 30% of a week at once, and the level hours a player can no longer fit. Whether PC01 stays Easy is Cameron's call; the numbers say a PC01 who uses the District office at all pays an order of magnitude more than PC02 or PC03, and PC04 pays the same by train and more by car.
- **Levers that would soften it** (not recommended here, listed for the design): make Either levels more common for PC01 and PC04; let a District week be a fixed block; raise the hours pool for those two; or count a train ride as Office time (the train encounter turns the hours into play).
