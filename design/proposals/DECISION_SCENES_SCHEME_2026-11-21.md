# A scheme for the Decision! scenes: forced and optional (draft for Cameron, 2026-11-21)

A proposal only. Nothing is built, and no data or schema changes until you say "Go". The workbook and asset conventions below follow the ones the game already uses (an ID is the file name; several pictures in one cell separated by `;`; a term such as WINTER picks a picture by the text's mood).

## 1. Executive summary

| Question | Answer |
|---|---|
| Where are we | The game has **one** Decision! scene, EV47 (the Prime Minister's Opening Address, Capitol, 18.10.08). It has no picture, and its speaker comes from a title lookup ("Prime Minister"). |
| What is a Decision! scene | An event the **calendar** schedules (Trigger = Dated), shown on a card tagged DECISION!, as opposed to the random, follow-up and buyable events. |
| The two kinds | **Forced:** opens by itself on its day and takes you to its office, free. **Optional:** an invitation that waits on the Events list for a window of days; you may attend or let it lapse, and it never moves you. Only Forced exists in the code today. |
| Recommendation | A new workbook tab, **Decision Scenes** (one row per scene, linked to its Events row), and a `DEC_` naming scheme for pictures in the existing background folder, with a fallback chain so a scene is never blank. |
| What I need from you | The decisions in section 6. |

## 2. Forced and optional

| | Forced | Optional |
|---|---|---|
| Opens | By itself, the first time the Office is open on or after its date | When you open it from the Events screen ("coming up" while its window is open) |
| Moves you | Yes, to its office, with the MOVED FOR YOU card; the trip costs no hours | No: you must already be at its office |
| Can you decline | The choices always include declining (EV47 has "Skip it and work through committee papers") | You may also simply not open it |
| If you do nothing | It opens anyway | It lapses at the end of its window |
| Card tag | DECISION! (red) | DECISION! with a window line, or its own tag (question 1) |
| Today | EV47 | Not built |

## 3. Workbook scheme: a Decision Scenes tab

The Events tab keeps what every event has: title, flavor, hours, choices, lead organizations. The new tab holds only what a scheduled scene adds, so the other 102 events gain no blank columns, and it doubles as the art worklist.

| Column | Meaning | Example (EV47 as DS01) |
|---|---|---|
| Scene ID | `DS01`, `DS02`, ... | DS01 |
| Event ID | The Events row with the text and choices | EV47 |
| Kind | Forced or Optional | Forced |
| Opens | The day it first appears (YY.MM.DD). It replaces the Events tab's On Date for scenes | 18.10.08 |
| Closes | Optional only: the last day it can be opened. Blank for Forced | (blank) |
| Office | Capitol or District: where it happens and where Forced takes you. Replaces the Events Location for scenes | Capitol |
| Speaker | One opponent, staff or visitor ID, not a title lookup | the Prime Minister's opponent ID |
| Second Speaker | Optional: a second person on the card | (blank) |
| Speaker Face | neutral, attacking or gaining: the mood the portrait shows | neutral |
| Scene Picture | One or more picture IDs (section 4), separated by `;` | DEC_EV47_1 |
| Notes | Anything for you or me | |

Rules the exporter would check: Event ID exists and has Trigger = Dated; Kind is Forced or Optional; Optional needs Closes on or after Opens; Office is Capitol or District; Speaker IDs exist; a Scene Picture ID that has no file is a warning, not an error (the fallback below covers it).

To avoid two places for one fact, a scene's date and office would live in this tab only; the matching Events cells (On Date, Location) would be filled from it by the exporter, so every existing screen keeps working.

## 4. Asset scheme

All pictures are PNGs in `assets/backgrounds/`, named exactly like their ID.

| Kind of picture | ID pattern | Example | Notes |
|---|---|---|---|
| A scene's own picture | `DEC_<EventID>_<n>` | `DEC_EV47_1.png` | 1 to 3 per scene; list them all in Scene Picture and one is chosen each time |
| A seasonal alternate | `DEC_<EventID>_<TERM>_<n>` | `DEC_EV47_WINTER_1.png` | Chosen when the text invokes the term (the existing WINTER, NIGHT, RAIN, ... rules) |
| A shared place picture | `DEC_PLACE_<OFFICE>_<name>` | `DEC_PLACE_CAPITOL_CHAMBER.png` | The default for any scene with no picture of its own |
| People on the card | none new | `OP10_neutral.png` | The speaker's existing portrait, by ID and face |

**Fallback chain** (so a scene is never a blank card): the scene's own picture, then the event's own Image cell, then a `DEC_PLACE_<OFFICE>_*` picture, then the Town Hall default the game already uses for outdoor scenes.

**Size:** the same as the other event pictures (those vary today; I would fix one size with you before drawing the first).

**Art tracking:** `tools/art_checklist.py` would gain a Decision scenes section: one row per scene, with a tick for its picture(s) and its speaker's portrait, so you can see at a glance what each scene still needs.

## 5. Where EV47 lands (the pilot)

| Field | Value |
|---|---|
| Scene | DS01, Forced, Capitol, opens 18.10.08 |
| Speaker | The Prime Minister's opponent row (today found by the title "Prime Minister") |
| Picture | `DEC_EV47_1.png` (to be drawn; until then the Capitol chamber default) |
| Nothing else changes | Its text, its three choices and its 2-hour cost stay in the Events and Event Choices tabs |

## 6. Questions for you

| # | Question | My recommendation |
|---|---|---|
| 1 | Should an Optional scene wear the same red DECISION! tag, or its own (for example INVITATION)? | Its own tag, so the two kinds read differently |
| 2 | How long is an Optional window, and can one come back next week? | A window in days set per scene; once lapsed, it does not return |
| 3 | A new tab, or three or four optional columns on the Events tab? | The new tab (it is also the art worklist) |
| 4 | One speaker, or up to two? | Up to two; most scenes will need one |
| 5 | How many pictures per scene? | One required, up to two alternates |
| 6 | Which existing events, if any, should become Decision! scenes besides EV47? | None until you choose; the current Random events stay random |
| 7 | Should I build Forced scenes on the new tab first and Optional later? | Yes: Forced is the one that exists, and Optional needs a new "window" rule in the code |
