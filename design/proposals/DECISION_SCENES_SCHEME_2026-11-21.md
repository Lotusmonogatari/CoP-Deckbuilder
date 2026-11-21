# A scheme for the Decision! scenes (version 3, draft for Cameron, 2026-11-21)

**Version 3 records the last five decisions (section 7). The design is settled and waiting for a "Go".** Version 2 folded in your answers: **one DECISION! tag with a Mandatory or Optional note; scenes fire once, on the date or in the window the workbook names; up to five follow-up Decision! moments; rewards and penalties; scenes that start other parts of the game (a unique vote screen, stages, events); and one new tab.** A proposal only. Nothing is built, and no data or schema changes until you say "Go".

## 1. Executive summary

| Question | Answer |
|---|---|
| Where are we | One Decision! scene exists, EV47 (the Prime Minister's Opening Address, Capitol, 18.10.08). It has no picture and its speaker comes from a title lookup. |
| What a scene is | An event the **calendar** schedules, shown on the red DECISION! card. The note under the tag says **Mandatory** or **Optional**. |
| Mandatory | Opens by itself on its date and takes you to its office, free. You cannot miss it. |
| Optional | Opens only from the Events screen, while its window is open, and never moves you. If the window closes unopened it lapses, which can carry a penalty. |
| Fires once | Every scene happens at most once per run. The game remembers which have fired. |
| Chains | A scene can lead to **up to five follow-up Decision! moments**, each a scene of its own, timed and chosen by what you decided. |
| Effects | Rewards and penalties reuse the event choice columns that already exist. Scenes can also **start other things**: a level, a stage, an event, a unique vote screen. |
| Workbook | **One new tab, Decision Scenes**, one row per scene or follow-up. Text, choices and effects stay in the Events and Event Choices tabs. |
| What it takes | Four phases (section 6). Phase 1 alone is small. |

## 2. Mandatory and Optional

| | Mandatory | Optional |
|---|---|---|
| Opens | By itself on its date, the first time the Office is open on or after it | When you open it from the Events screen, any day inside its window |
| Moves you | Yes, to its office, with the MOVED FOR YOU card; the trip costs no hours | No: you must already be at its office |
| Can you decline | A choice may decline (EV47 has "Skip it and work through committee papers") and carries its own effects | The same, or you simply do not open it |
| If you do nothing | It opens anyway | It lapses when its window ends, and the **lapse penalty** applies (section 3) |
| Card | DECISION! tag, then the note **Mandatory** | DECISION! tag, then the note **Optional**, with the days left in its window |
| Today | EV47 | Not built |

## 3. The workbook: one Decision Scenes tab

One row per scene. A follow-up is also a row: it names the scene it **follows**.

| Column | Meaning | Example |
|---|---|---|
| Scene ID | DS01, DS02, ... | DS01 |
| Event ID | The Events row holding the title, flavor and choices (and so the rewards and penalties) | EV47 |
| Kind | Mandatory or Optional | Mandatory |
| Opens | First day it can appear (YY.MM.DD). For a follow-up, left blank: its day comes from Delay | 18.10.08 |
| Closes | Optional only: the last day to open it | (blank) |
| Office | Capitol or District: where it happens, and where Mandatory takes you | Capitol |
| Speaker, Second Speaker | Opponent, staff or visitor IDs, not a title lookup | the Prime Minister's ID |
| Speaker Face | neutral, attacking or gaining | neutral |
| Scene Picture | One or more picture IDs (section 4) | DEC_EV47_1 |
| Follows | The scene this one follows (blank for a first scene) | (blank) |
| Delay | Follow-ups only: days after the scene before it resolved | 3 |
| Follow If | Follow-ups only: the choice letters of the earlier scene that lead here (blank = any) | A |
| Activates | Things this scene starts, as `kind:ID` entries separated by `;` (section 5) | `vote:BI51; event:EV106` |
| Notes | For you or me | |

**Rewards and penalties** need no new columns. They stay where they live today:

| Effect | Where | How |
|---|---|---|
| What a choice gives or costs | **Event Choices**, the existing columns (Funds, XP, Constituency support, Reputation, Party support, awareness, organization standing, items) | The same rows the scene's event already has |
| The penalty for letting an Optional scene lapse | **Event Choices**, one reserved choice with the letter `L` for the event; it is never shown as a button and is applied when the window closes | Reuses every effect column |
| What a follow-up carries | Its own event's choices | Each follow-up is a scene with its own Events row |

**Fires once.** The first time a scene opens it is marked done, and it never opens again, whether you answered it, skipped it or let it lapse.

**Exporter checks:** Event ID exists and is Dated; Kind is Mandatory or Optional; Optional has Closes on or after Opens; Office is valid; Speaker IDs exist; Follows points at a real scene and never loops; **a chain has at most the first scene plus five follow-ups**; every `Activates` kind and ID exists; a Scene Picture ID with no file is only a warning.

## 4. The assets

PNGs in `assets/backgrounds/`, named exactly like their ID.

| Kind of picture | ID pattern | Example | Notes |
|---|---|---|---|
| A scene's own picture | `DEC_<EventID>_<n>` | `DEC_EV47_1.png` | 1 to 3 per scene; one is chosen each time |
| A seasonal alternate | `DEC_<EventID>_<TERM>_<n>` | `DEC_EV47_WINTER_1.png` | Chosen when the text invokes the term (the existing WINTER, NIGHT, RAIN rules) |
| A shared place picture | `DEC_PLACE_<OFFICE>_<name>` | `DEC_PLACE_CAPITOL_CHAMBER.png` | The default for any scene with no picture of its own |
| People on the card | none new | `OP10_neutral.png` | The speaker's existing portrait |

**Fallback chain**, so a scene is never a blank card: the scene's own picture, then the event's own Image cell, then a `DEC_PLACE_<OFFICE>_*` picture, then the Town Hall default.

**Art tracking:** `tools/art_checklist.py` gains a Decision scenes section: one row per scene with a tick for its picture(s) and its speaker's portrait.

## 5. Scenes that start other parts of the game

The `Activates` column names what the scene starts. Most of these already exist as mechanisms; the table says which.

| Kind | What it starts | In the game today |
|---|---|---|
| `level:LVxx` | A level, usually an Event Only level | Exists: an event choice can start one |
| `stage:STxx` | A single room or stage | Exists inside a level; a stand-alone start would be new |
| `event:EVxx` | Queues an event for a later day | Exists for follow-ups |
| `vote:BIxx` | **A unique vote screen**: a Floor Vote on that bill, with the scene's own framing | A normal Floor Vote exists; a scene-specific one is new (question 3) |
| `unlock:LVxx` | Makes a level available | Exists (a choice's Unlocks Level) |

An activation can also hang on one choice instead of the whole scene, using the Event Choices columns that exist today.

## 6. Order of work after "Go"

| Phase | What | Size |
|---|---|---|
| 1 | The tab and exporter checks; Mandatory scenes; the Mandatory or Optional note on the card; fires once; **EV47 becomes DS01** | Small |
| 2 | Follow-ups: Follows, Delay, Follow If, the five-follow-up limit | Medium |
| 3 | Activations: level, event, unlock, and then the unique vote screen | Medium to large |
| 4 | Optional scenes: windows on the Events screen, the lapse rule and its reserved choice | Medium |
| Alongside | The `DEC_` pictures and the art checklist section | Small |

## 7. Decisions (Cameron, 2026-11-21)

| # | Question | Decision |
|---|---|---|
| 1 | Does a Mandatory scene have a lapse? | **No.** A penalty for skipping lives on the declining choice. Only Optional scenes lapse. |
| 2 | Can a follow-up branch? | **Yes.** Different choices can lead to different follow-ups, with at most five follow-ups in total for one first scene. |
| 3 | What is the unique vote screen? | **A Floor Vote on a specific, named bill or motion**, reached from the scene, for example a floor debate about CPTPP that goes into a vote on CPTPP. It uses the normal Floor Vote screen. The `vote:` entry names the bill or motion row in the Floor Votes tab; a motion is a row there like any bill, which you write. |
| 4 | Does a follow-up's delay count days from when the earlier scene was answered? | **Yes**, for Mandatory and Optional follow-ups alike. |
| 5 | Does a follow-up's card say "Follow-up n of 5"? | **No.** A follow-up wears the same DECISION! tag and its Mandatory or Optional note, like any scene. |

## 8. What changes in the design

| Part | Result |
|---|---|
| The Kind column | Mandatory or Optional; a lapse penalty (the reserved choice `L`) exists only for Optional |
| Follows, Delay, Follow If | Branching works: two scenes may follow the same one, each with its own Follow If choice letters; the exporter counts every follow-up under one first scene and errors above five |
| Activates `vote:` | Names a bill or motion in the Floor Votes tab. A debate-then-vote scene is a `level` or `stage` activation followed by that vote |
| The card | The tag and the note only; no chain counter |

## 9. Order of work after "Go"

| Phase | What |
|---|---|
| 1 | The tab and checks; Mandatory scenes; the note on the card; fires once; EV47 becomes DS01 |
| 2 | Follow-ups, with branching and the five-follow-up limit |
| 3 | Activations: level, event, unlock, then the named vote |
| 4 | Optional scenes: windows on the Events screen and the lapse rule |
| Alongside | The `DEC_` pictures and the art checklist section |
