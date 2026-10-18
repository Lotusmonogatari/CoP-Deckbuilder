# Balance audit: process and test design

Purpose: find the **lopsided** parts of the game across its mechanics, with numbers, so a design change starts from evidence. It does not say what is *right*, only what is far from even, never used, never lost, always won, or running away.

Run it after any content batch, any change to a balance lever, or before a release:

```
tools/balance_audit.sh            # 15-25 minutes: bot runs and sweeps (four cores)
python3 tools/balance_audit.py    # seconds: static analysis + reads those logs
```

Output: `design/BALANCE_AUDIT.md` (tables and a ranked flag list) and `design/BALANCE_AUDIT.flags.json`. Every threshold that decides "lopsided" is one number in `THRESHOLDS` at the top of `tools/balance_audit.py`.

## The idea: six lenses, each with a question and a measure

| Lens | Question | Measure | Lopsided when |
|---|---|---|---|
| 1. Progression | Does getting stronger change outcomes? | Win rate per room with the **starter kit** (opening deck only, no backing, no items) against the **full kit** (all cards, backing, items) | The full kit barely helps; or a first-time player almost never wins (a wall); or a late player still loses |
| 2. Difficulty | Is the challenge evenly spread, and does the static table agree with play? | Points needed per energy available (each room), validated against measured win rate | A whole family of rooms is trivial or impossible; the static table does not predict play (then trust the sweeps) |
| 3. Rewards and economy | Do rewards follow difficulty, and does anything cap out? | Reward index per room; XP, Funds, Reputation, Constituency, Party opinion at the n-th level-end; items bought | Hard rooms pay less; meta values sit at their ceiling for most of a run; money is spent as fast as it arrives |
| 4. Choice diversity | Do players have real choices? | Card power per energy, dominated cards, play counts, share of plays per rhetorical style, which styles the rooms and questions favor | One card or style is the default; cards are never played; a style is almost never the right answer |
| 5. Organizations and parties | Are all organizations reachable, distinct and fed? | Questions pleasing each; standing at every level-end; share at the ceiling or near zero; bills favoring versus annoying; party positions and proponents | An organization is never pleased, never reachable, always maxed, or only ever helped or hurt |
| 6. Bills and votes | Are outcomes spread? | Default pass rate, party positions, proponent counts | One party dominates proposing or always loses |

## The tests

**Static (data only, `balance_audit.py`).** Cards: value per energy (self plus opponent loss, guard at 1, draw at 1.5, gaffe at minus 1.5), z-score outliers, dominated cards, tier power, style averages. Affinity: favored and resisted rooms per style, best style per room. Questions: grade totals per style, pleasing and setting-back counts per organization, Gini inequality. Organizations: backings and costs, bills favoring or annoying each. Bills: proponents and dispositions. Stages: the difficulty table below. Shop: price list.

**Stage difficulty model.** `need / energy`: the points a player must add per point of energy. A single fight is its gap over its energy budget. A `reset` room (committees) refights from scratch per opponent with full clock and energy, so it is one bout's gap over one bout's energy. A `stream` or `continuous` room shares one clock (and one energy pool in continuous) across its opponents, so the gap is paid once per opponent over one budget. The audit checks this model against measured results and flags itself if it stops predicting.

**Dynamic (bot, `tools/balance_audit.sh`).** Uses `tools/playtest_optimal.gd`, which plays the real rules headless.
1. *Stage sweeps*: every Combat room, 25 fights per process. **Starter kit** (four processes, one per protagonist, so four different random opening decks, 100 fights per room) answers "what does a new player meet?". **Full kit** (two processes) answers "what does a late player meet?".
2. *Full runs*: one per protagonist, 80 level attempts each, with an `ECON` line after every level (XP, Funds, meta values, cards, backings, items, every organization's standing) and a tally of every card played.
3. Each process gets its own `XDG_DATA_HOME`, so saves cannot contaminate each other.

**Flags.** A flag has a severity (High: the game's promise is broken, such as an unwinnable room; Medium: a mechanic is distorted; Low: worth knowing), an area, a message and evidence. Flags in the same room family are grouped into one so 21 caucus rooms read as one finding.

## Reading the result honestly

* The bot is not a person. It plays quickly, never misreads a card, and builds the strongest deck by its own measure. Treat win rates as **relative** (room against room, kit against kit), not as the rate a person will see. A person is expected to do better than the starter-kit bot on rooms that reward reading the table, and worse on rooms that reward speed.
* Card play counts show what a *deck builder* keeps choosing, not what people enjoy.
* The static model and the sweeps cross-check each other: when they agree (they do today, correlation about -0.9), the table can be used to retune a room without simulating.
* Re-run to confirm a fix. A flag that disappears after a change is the test passing.

## Standard "done" for a balanced build

* No room a first-time player can never win, unless the room is optional and flagged as a deliberate wall (Media Ambush).
* Every family has a visible kit gain (starter to full at least 10 points).
* Harder rooms pay at least as much as easier ones.
* No meta value at its ceiling for more than half of a full run; no organization permanently unreachable.
* No card played more than three times the average; no card never played.
* No rhetorical style under 8% or over 28% of plays.
