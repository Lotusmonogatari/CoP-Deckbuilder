# Content prompt — Floor Vote Bills and Party Positions

A reusable prompt for turning Cameron's own party positions and salience
values into the two workbook tabs National Assembly Floor Voting (ST23)
reads: **Floor Vote Bills** and **Floor Vote Party Positions**. Everything it
produces is a draft for Cameron to correct — same status as every other
content prompt in this project (`design/CONTENT_PROMPT.md`).

---

## What you (Cameron) provide

Per bill:
- Which **level** it belongs to (an LVxx that either already has an ST23
  slot, or will get one)
- A short **bill name** and a plain-English **description** (this becomes
  the scroll's own text)
- Per party: a **position** (Support / Oppose / Neutral — or a scale, e.g.
  −2..+2) and a **salience** (how much that party cares — High/Medium/Low,
  or a number)

That's the raw input. Everything below is how it becomes the two tabs'
actual rows.

---

## Quick reference: the two tabs

| Tab | Key | Columns |
|---|---|---|
| **Floor Vote Bills** | Level ID | Bill Name (EN), Bill Description (EN), Favorability Delta (Supportive), Favorability Delta (Opposed), Favorability Delta (Neutral) |
| **Floor Vote Party Positions** | Level ID + Party ID | Votes Yes, Votes No, Votes Abstain, Disposition, Cue Text |

One Bills row per level; six Party Positions rows per bill (Butsutou, Yezo
Heritage Party, Frontier Party, Five Point Independents, Keizaijiyuutou,
Country Initiative — `data/parties.json`'s PT01-06). A level needs an ST23
slot in its own `stage_1..stage_10` AND a Bills row to actually play — either
alone does nothing (the exporter errors on a Vote-mode slot with no bill,
and warns on a bill with nowhere to be voted on).

---

## Seat counts (resolved 2026-09-26)

`data/parties.json` now carries each party's real seat count, from the
Sep-18 session of parliament (Cameron — an earlier May-18 snapshot he sent
first was a prior, superseded session):

| Party | Seats |
|---|---|
| Butsutou | 19 |
| Yezo Heritage Party | 14 |
| Frontier Party | 27 |
| Five Point Independents | 5 |
| Keizaijiyuutou | 25 |
| Country Initiative | 11 |
| **Total** | **101** |

Fixed per party across every bill, not re-rolled per vote — a bill's Votes
Yes + Votes No + Votes Abstain for a given party always add up to that
party's own row above.

---

## Position + salience → the actual numbers

**Disposition** (Floor Vote Party Positions' own column) is direct: Support
→ Supportive, Oppose → Opposed, Neutral/undecided → Neutral.

**Vote split** — salience decides how *unified* the party is, not which way
it leans (position already says that):

| Salience | Unity | Example on a 15-seat party, position = Support |
|---|---|---|
| High | ~90–100% with the party line | 14 Yes, 1 No |
| Medium | ~70–89% | 12 Yes, 3 No |
| Low | ~55–69% | 9 Yes, 6 No |
| Neutral position (any salience) | most/all of that party's seats go to Abstain, not split Yes/No | 13 Abstain, 1 Yes, 1 No |

Round to whole seats; if a split lands exactly on a tie, round the majority
side up (matches `FloorVoteEngine.majority_bucket()`'s own Yes > No >
Abstain tie-break, so the assumed "player's seat" reads consistently).

**Favorability deltas** (Floor Vote Bills' own three columns — one number
per disposition, applied to every party holding it) scale with **how
salient the bill is overall**, not per party: a bill that matters a lot to
somebody should move the needle more than one nobody cares about.

| Overall salience of the bill | Supportive delta | Opposed delta | Neutral delta |
|---|---|---|---|
| High-stakes | +5 | −5 | 0 |
| Ordinary | +3 | −2 | 0 |
| Low-stakes | +1 | −1 | 0 |

("Overall" = the highest single party salience on that bill, or your own
judgment call when they differ — first-draft convention, yours to override
per bill.)

**Cue Text** — unlike Opponent Cues (`design/CONTENT_PROMPT.md`), a Floor
Vote cue is allowed to be specific to *this* bill and *this* moment: it is
that party's leader reacting to a real vote in front of them, not a generic
line reused everywhere. Still:
- Under 12 words (a little more room than Opponent Cues' 9, since it's said
  once, not looped).
- Still the party leader's own voice, not the bill's narrator — "We need
  every vote!" (Supportive), not "This bill passed by a wide margin."
- No mechanic talk (no "votes," "seats," or numbers) — a person speaking,
  not a scoreboard.

---

## The batch block

```
Bill: <Level ID> — <bill name>, <one-line description of what it does>
Overall salience: <High | Ordinary | Low-stakes>

Party positions (position, salience):
  Butsutou (19 seats):                 <Support/Oppose/Neutral, High/Medium/Low>
  Yezo Heritage Party (14 seats):      <...>
  Frontier Party (27 seats):           <...>
  Five Point Independents (5 seats):   <...>
  Keizaijiyuutou (25 seats):           <...>
  Country Initiative (11 seats):       <...>
```

Hand me (or another LLM) this block filled in, and the output is one Floor
Vote Bills row plus six Floor Vote Party Positions rows, ready to paste into
the workbook — run `python3 tools/export_data.py` afterward, same as any
other content change.

---

## Worked example

```
Bill: LV10 — Hometown Markets Protection Act, tariffs on imported goods
  competing with local producers
Overall salience: High-stakes

Party positions:
  Butsutou (19 seats):                 Support, Medium
  Yezo Heritage Party (14 seats):      Oppose, High
  Frontier Party (27 seats):           Support, High
  Five Point Independents (5 seats):   Neutral, Low
  Keizaijiyuutou (25 seats):           Oppose, Medium
  Country Initiative (11 seats):       Support, Low
```

**Floor Vote Bills** (LV10):

| Bill Name | Bill Description | Fav. Δ Supportive | Fav. Δ Opposed | Fav. Δ Neutral |
|---|---|---|---|---|
| Hometown Markets Protection Act | Tariffs on imported goods competing with local producers. | +5 | −5 | 0 |

**Floor Vote Party Positions** (LV10):

| Party | Yes | No | Abstain | Disposition | Cue Text |
|---|---|---|---|---|---|
| Butsutou | 15 | 4 | 0 | Supportive | "Our producers deserve this." |
| Yezo Heritage Party | 1 | 13 | 0 | Opposed | "This punishes every shopper in Yezo." |
| Frontier Party | 25 | 2 | 0 | Supportive | "We need every vote!" |
| Five Point Independents | 1 | 1 | 3 | Neutral | "We're not convinced either way." |
| Keizaijiyuutou | 6 | 19 | 0 | Opposed | "Markets should decide this, not us." |
| Country Initiative | 7 | 4 | 0 | Supportive | "Long overdue for our districts." |
