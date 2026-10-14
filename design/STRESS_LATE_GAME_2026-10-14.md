# Late-game and extreme-state stress (2026-10-14)

`tools/stress_late_game.gd` (run through `tools/stress.sh` step 6, or alone: `xvfb-run .tools/godot --path . tools/stress_late_game.tscn`; `STRESS_ONLY="C,F"` runs chosen stages) builds four extreme runs and beats on each: **max** (every card, all 29 backing modifiers, every staff member at top tier, full item stacks, every bill in the statute book, every organisation and party at 100, meta at its ceiling, Funds cap raised to its limit), **min** (everything at 0), **crisis** (Town Hall, Steering Committee and funding freeze all active, organisations alternating 12 and 95, meta near zero) and **stacked** (+30 energy, +20 hand, +99 guard, +40 gaffe cap, +40 turns on top of max).

| Stage | What it checks | Result |
|---|---|---|
| A | Save size, save/load round trip, cost of party-opinion maths | Save is 14-20 KB and writes/loads in 2-6 ms; round trip identical in all four; party opinion costs 0.1 ms per call |
| B | A fight in each of the 97 combat rooms, card conservation, guard, gaffe, energy, bar bounds after every move | No violations; every fight ends well inside the turn cap; the whole 97-room sweep takes 70-200 ms of rules time |
| C | All 50 bills voted three ways with the influence gate open | House always 101; pass rule always Yes at least 51; 77 flips in max and stacked, none when the gate is closed |
| D | 400 level ends each (win and loss mixed, all organisations pleased, annoyed and set back at once) | Meta, standings and party standings never leave their ranges; 4 ms per level end |
| E | Office panels, a real battle screen with up to 15 cards in hand | Office opens in 65-115 ms; slowest panel is Marketplace at about 95 ms; battle redraw 28-60 ms median, 94 ms worst (software renderer on a build machine, so a phone is slower) |
| F | Repeated screen loads | See the two leaks below |

## Two real leaks found and fixed

1. **Every Office load leaked about 130 objects and 0.4 MB.** `Overlay` built its Back and Confirm buttons but only put them in the tree when opened, so the Office's 22 panels (most never opened in a visit) each left two floating buttons that nothing freed. Over 100 level returns that was about 40 MB. They are now parented as soon as they are built. Test: `tests/test_overlay_leak.gd`.
2. **Every battle leaked about 40 KB.** The battle's random-roll lambdas reached the generator through `self`, so the engine and its intent runner / bar held each other and were never freed; the cue banner's two `await`s also left a suspended coroutine when a screen was freed mid-line. The lambdas now capture the generator alone, and the banner uses a `Timer` child. Test: `test_a_battle_engine_is_freed_when_nothing_holds_it`. After the fixes: Office 0.0 objects per load, battle 0.1.

## Observations (no change made)

- With every backing owned and every organisation at 100, **every TV Debate room starts at or above its threshold** (start +5 to +15 from backing), so those rooms are won by not collapsing; the bot wins them 100% already.
- With every backing owned the largest start bonus is +20 (press conference), the largest hand bonus +1 and the largest gaffe-limit bonus +1, so stacked backing is mild; **item** stacking is the unbounded part (+30 energy and +20 hand were accepted by the engine with no cap).
- Late-game meta saturates: Constituency support, Reputation and Party support sit at 100 and Funds at its cap, so the numbers stop carrying information (the full-game bot ends with all three at 100).
- At **Large text size** the Marketplace's three-column item grid breaks long words mid-word ("COMMISSI/ON", "PAPERWO/RK") and leaves its right quarter empty; the Boosters list indents rows that have an icon differently from rows that do not; Funds and prices show no thousands separators (1000000, 25000).
- A full hand of 15 cards shows 3 at a time on the horizontal scroll; 38 energy pips wrap into six rows and push the status row down.
