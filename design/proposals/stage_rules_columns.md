# Proposal: a living rules set for the Stages tab

Eight new columns for the **Stages** tab, each replacing a rule that
currently lives in GDScript rather than in the workbook. None of this
changes how the game plays today — every column's default, below, is
chosen to reproduce the exact current hardcoded behaviour. The engine
already reads all eight; a blank cell means "use the old hardcoded rule for
this stage," so these can be filled in one stage at a time, or not at all,
without anything breaking.

**Status (2026-09-25):** the first seven columns are pasted into the master
workbook with their safe defaults. `Reveal In Briefing` was added the same
way, set to `No` on `ST19` (Media Ambush) only — the fix for the playtest
report that Media Ambush was spoiled by name in the pre-stage briefing.
Every value in the table below is live in the real Stages tab today, not
just a proposal.

## Why each column exists

| Column | Replaces | Where |
|---|---|---|
| `Bar Model` | The hardcoded list of which 11 stage IDs (`ST01`, `ST09`–`ST18`) use the per-member committee model, plus a separate hardcoded guess (`ST04` → single bar, `ST06` → survival bar, else shared pool) | `BattleEngine.COMMITTEE_STAGE_IDS`, `DataDB.COMMITTEE_STAGE_IDS`, `BarModel.for_stage()` |
| `Energy Mode` | The always-per-turn energy refill every canon stage gets today — pooled energy (handed out once for the whole stage) exists in the engine but nothing in the workbook can ask for it | `BattleEngine.setup()`'s `.get("energy_mode", "per_turn")` fallback |
| `Energy Pool` | (new capability — see Energy Mode) | `BattleEngine.setup()`'s pooled-energy amount |
| `Sequence Mode` | The always-`single`-opponent turn structure every canon stage gets today — multi-opponent carry-over (`continuous`, `reset`, `stream`) exists in the engine, built for the old hand-written playtest levels, but nothing in the workbook can reach it | `BattleEngine._sequence_mode`'s `.get("sequence_mode", "single")` fallback |
| `Opponent Count` | The engine always resolving exactly one opponent for a non-committee stage | `BattleSetup.expand_level()` / `_opponent_count()` |
| `Question Pool` | A hardcoded dict mapping 4 stage IDs to which of the 5 question pools they draw from | `BattleSetup.QUESTION_POOL_BY_STAGE` |
| `Reputation Affects Start` | A hardcoded 2-ID list (`ST04`, `ST06`) deciding whether Reputation nudges the opening bar | `BattleSetup._reputation_affects_start()`'s fallback list |
| `Reveal In Briefing` | Nothing before this — every stage always named itself and its opponent in the pre-stage briefing, with no way to keep a stage a surprise | `OfficeScreen._reveal_in_briefing()` |

## How to fill in a cell

- **Bar Model**: `Single`, `Survival`, `Shared_pool`, or `Committee` (exact
  case matters — the engine compares lowercase strings: `single`,
  `survival`, `shared_pool`, `committee`). Blank = the old ID-based guess.
- **Energy Mode**: `per_turn` or `pool`. Blank = `per_turn`.
- **Energy Pool**: a flat number, only meaningful when Energy Mode is
  `pool`. Blank = the stage's own Energy per turn value is used once,
  which is very likely not what you want for a real pooled stage — if you
  set Energy Mode to `pool`, set this too.
- **Sequence Mode**: `single`, `continuous`, `reset`, or `stream` (see
  `CLAUDE.md`'s or `BattleEngine.gd`'s own comment on `_sequence_mode` for
  what each one carries over between opponents — briefly: `continuous`
  carries everything, `stream` carries the record but refills energy,
  `reset` starts each opponent completely fresh). Blank = `single`.
- **Opponent Count**: a range-string, the same convention as Levels' bonus
  win ranges elsewhere in the workbook — `"1"` for exactly one, `"2-4"` to
  roll between 2 and 4 opponents for that stage. Blank = `"1"`. Only
  meaningful for a non-committee stage; a committee's roster is always
  every eligible opponent regardless of this column.
- **Question Pool**: one of `press_conference`, `town_hall`,
  `lobbyist_meeting`, `policy_study`, `media_ambush`, or blank for a stage
  that doesn't ask reporter-style questions at all.
- **Reputation Affects Start**: `Yes` or `No`. Blank = `No`, except for
  `ST04`/`ST06` where blank still means `Yes` (the old hardcoded list).
- **Reveal In Briefing**: `Yes` or `No`. Blank = `Yes` — the stage names
  itself and who's waiting, as every stage has always done. Set `No` on a
  stage meant to ambush the player (today: `ST19`, Media Ambush) and the
  briefing shows a generic "something is coming" line instead, with the
  stage's rewards still shown underneath so the player can still weigh
  what they're risking.

## The full default table

Every value below reproduces exactly what the game does today. Pasting
this table into the workbook with no changes is a safe, inert no-op.

| Stage | Name | Bar Model | Energy Mode | Energy Pool | Sequence Mode | Opponent Count | Question Pool | Reputation Affects Start | Reveal In Briefing |
|---|---|---|---|---|---|---|---|---|---|
| ST01 | Special Committee | Committee | per_turn | | single | 1 | | No | Yes |
| ST02 | Floor Debate | Shared_pool | per_turn | | single | 1 | | No | Yes |
| ST03 | Party Caucus | Shared_pool | per_turn | | single | 1 | | No | Yes |
| ST04 | Press Conference | Single | per_turn | | single | 1 | press_conference | Yes | Yes |
| ST05 | Town Hall | Shared_pool | per_turn | | single | 1 | | No | Yes |
| ST06 | TV Debate | Survival | per_turn | | single | 1 | | Yes | Yes |
| ST07 | Office Hours | Shared_pool | per_turn | | single | 1 | | No | Yes |
| ST08 | Party Steering Committee | Shared_pool | per_turn | | single | 1 | | No | Yes |
| ST09 | Committee on Ethics and Prosecution | Committee | per_turn | | single | 1 | | No | Yes |
| ST10 | Committee on the Environment | Committee | per_turn | | single | 1 | | No | Yes |
| ST11 | Committee on War | Committee | per_turn | | single | 1 | | No | Yes |
| ST12 | Committee on the National Assembly | Committee | per_turn | | single | 1 | | No | Yes |
| ST13 | Committee on Agriculture | Committee | per_turn | | single | 1 | | No | Yes |
| ST14 | Committee on Foreign Affairs | Committee | per_turn | | single | 1 | | No | Yes |
| ST15 | Committee on Construction and Development | Committee | per_turn | | single | 1 | | No | Yes |
| ST16 | Committee on Finance | Committee | per_turn | | single | 1 | | No | Yes |
| ST17 | Committee on Government Administration | Committee | per_turn | | single | 1 | | No | Yes |
| ST18 | Committee of the Cabinet | Committee | per_turn | | single | 1 | | No | Yes |
| ST19 | Media Ambush | Shared_pool | per_turn | | single | 1 | media_ambush | No | No |
| ST20 | Lobbyist Meeting | Shared_pool | per_turn | | single | 1 | lobbyist_meeting | No | Yes |
| ST21 | Policy Study Session | Shared_pool | per_turn | | single | 1 | policy_study | No | Yes |

A note on ST07 (Office Hours): it's the one Non-combat stage, so none of
this ever actually runs for it today — its `Bar Model` row above is what
the fallback code *would* produce if it were ever asked, not a claim that
it currently means anything.

## Where this opens real design room, once you're ready to move past "inert"

None of this needs deciding now, but it's worth knowing what becomes
possible the moment a cell stops matching its default:

- **A floor debate against several debaters in a row**, one energy pool
  and one clock carrying across all of them (`Opponent Count: 2-3`,
  `Sequence Mode: continuous`) — the shape CLAUDE.md §7.3 implies for a
  chamber full of people but the workbook has never had a way to ask for.
- **A caucus that hands out one energy pool for the whole room** instead
  of refilling every turn (`Energy Mode: pool`, `Energy Pool: <n>`) — closer
  to how the hand-written `stage_types.json` already treats
  `party_caucus`/`tv_debate`/`media_ambush`/`lobbyist_meeting` for the
  playtest fixtures, now reachable for real workbook stages too.
- **A new committee stage** (say a 22nd one, added later) working
  correctly from the moment its row exists, by setting `Bar Model:
  Committee` directly, rather than needing a GDScript change to add its ID
  to a hardcoded list first.
