# Bill-room replies: analysis and the new Reply Kind (2026-11-01)

Cameron's playtest note: *"This Bill's player responses rotated around a limited
quantity of generic text that actually caused confusion when put up against the
breadth of questions posed by opponents."*

## Executive summary

| | Before | After |
|---|---|---|
| What the player said in a bill room | One of the bill's own 15 slogan lines per style and lean, whatever was asked | A reply written for the **kind** of question just asked, in the card's style and the player's lean |
| Does the reply fit the question? | Rarely: a cost question got a values slogan | Yes: a cost question gets a cost answer, an oversight question an oversight answer |
| Bill name in replies | Full title in nearly every line | Full name on about 25% of lines (Balance lever), otherwise "the Act" / "the bill" |
| Bill slogans | Always used | Still used when a question has no Reply Kind (room-pool questions) |
| New content | — | 180 Player Cues rows, 480 lines (10 kinds × 6 styles × Support 3 / Oppose 3 / no lean 2) |
| Draft status | — | All of it is Claude's draft for Cameron to rewrite |

## What the bill rooms actually ask

228 bill-level rooms can ask 589 Stage Questions over 227 themes. Read as
*what the asker wants to hear*, they fall into ten kinds:

| Reply Kind | Questions | Share | Typical question |
|---|---|---|---|
| Principle | 188 | 32% | "Why should this Assembly back the bill at all?" |
| Cost | 93 | 16% | "Who pays for this, and how much?" |
| Party | 66 | 11% | "Will you hold the party line if colleagues break?" |
| Voters | 54 | 9% | "How do you explain this to voters back home?" |
| Impact | 47 | 8% | "What does this do for farm families?" |
| Alternative | 34 | 6% | "Why not a smaller pilot instead?" |
| Oversight | 33 | 6% | "Who checks the agency's work?" |
| Criticism | 31 | 5% | "Critics say it goes too far. Are they wrong?" |
| Risk | 30 | 5% | "What in this bill stops it being abused?" |
| Evidence | 13 | 2% | "How do we know it works?" |

All 2,539 Stage Questions rows now carry a **Reply Kind** (column O), pre-filled
by a word-matching draft. Principle is the catch-all, so a row that reads as
something more specific may be worth re-tagging.

## How each style answers the same question

The six styles keep their voices by answering the same kind of question in
different ways, not by using different words for the same answer.

| Style | Its move | Cost question | Oversight question |
|---|---|---|---|
| Earnest | Answers directly, admits the trade-off | "It costs real money, and I won't pretend otherwise." | "Someone runs it, someone checks it, and both report to this Assembly." |
| Emotional | Answers through the people affected | "Count the cost in people, and this bill pays for itself." | "Families can call, complain and be heard under this bill." |
| Appeal | Finds common ground, invites the asker in | "I am open to adjusting who pays, if it keeps the bill alive." | "A cross-party review panel would make the bill stronger." |
| Data Driven | Answers with a figure, test or measure | "The budget office figures support the Act. I have the table here." | "Reporting every quarter, an independent audit every year." |
| Divisive | Turns the question on the other side | "The other side spends freely on their friends. Now they discover thrift?" | "They ask who checks the work because they want to stop the work." |
| Duplicitous | Sounds like an answer, commits to nothing | "Let us not get lost in the figures when the vision is so clear." | "The bill will be overseen in the proper way by the proper people." |

Each kind × style has three lines for a player who Supports, three for one who
Opposes, and two for a player who took no lean.

## How it works

1. A Stage Questions row's **Reply Kind** goes into `questions.json`.
2. A Player Cues row with a **Reply Kind** (column M), a Suit and a Stance is a
   reply line. It names no bill; `{bill}` / `{Bill}` stand for the name.
3. In a bill room, `CardCues.for_card()` looks first for a reply line matching
   the question's kind, the card's suit and the player's lean (falling back to
   the no-lean lines), then the bill's own lines, then the suit lines, then the
   card's Flavor Text.
4. `{bill}` becomes "the Ainu Heritage and Language Act" on about a quarter of
   lines (Balance: *Player Cues: Full Bill Name Chance*, 25), otherwise "the
   Act" or "the bill" ("the Agreement" for the two agreements). The choice is
   stable per moment, like the line itself.

## Left alone

- The bill's own 15-lines-per-style slogans stay, as the fallback for room-pool
  questions with no Reply Kind.
- Press, town hall and other room-pool tabs have no Reply Kind column yet. Adding
  one is the same change if Cameron wants it.
