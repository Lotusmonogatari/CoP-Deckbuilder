# Future action item: Party-support-locked events for the player's own party

Recorded 2026-11-16 at Cameron's request (audit W-2 decision). **Not built.** For a later session.

## The idea

Some events and levels should open only when the player's Party support is high enough, and should belong to the player character's own party (Frontier Party for PC01 and PC02, Keizaijiyuutou for PC03, Country Initiative for PC04). Today Party support is a number the game reads in many places (dues, crisis triggers, the free Party Backing above 75) but it never unlocks content, and the audit found it sits at 90 to 100 for most of a run, so a locked event would be reachable almost always until the economy is re-tuned.

## Where it hooks in (existing systems, no new mechanic needed)

| Existing system | Hook |
|---|---|
| Events tab | An event's availability conditions (it already supports minimum District and National awareness: `EventEngine.eligible_random`) could take a minimum Party support and an own-party filter |
| Levels tab | A level's "Needs Discovery" and "event-only" flags show the pattern; a `Min Party Support` column would work the same way |
| Hosted events | A party dinner or caucus retreat as a hosted event only the own party can host |
| Protagonist data | `data/player.json` already knows each protagonist's party |

## New workbook fields it would need

`Min Party Support` (number, blank = none) and `Own Party Only` (Yes/blank) on the Events and Levels tabs. A schema change: needs Cameron's approval first.

## Order of work

1. Re-tune Party support so it does not sit at its ceiling (audit W-3), otherwise the lock never bites.
2. Add the two columns and the exporter checks.
3. Write the first events as workbook rows (content, drafted for Cameron).
