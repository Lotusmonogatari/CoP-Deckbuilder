# Content prompt — Level Intro Cues

A reusable prompt for writing the new **Level Intro Cues** tab: a hired
staff member's own line about the level the player is about to play,
shown on the Level Intro screen between the Office and that level's first
stage (2026-09-27). Everything it produces is a **draft for Cameron to
correct** — same status as every other content prompt in this project
(`design/CONTENT_PROMPT.md`).

---

## How it works in the game

A row is `(Level ID, Role, Cue Text)`. It is **entirely optional per
(level, role) pair** — most combinations will have no row at all, and
that role simply stays silent for that level. A level with no rows at
all never shows the Level Intro screen; the player goes straight from
the Office to the first stage, exactly as before this feature existed.

If more than one hired role has a written line for the same level, **all
of them speak, one after another** — there is no "first match wins" here
(unlike Office Notices), since a level briefing genuinely can have more
than one person weigh in.

`Role` must be one of the three roles already in the **Staff** tab
(`Policy Research Assistant`, `Media Spokesperson`, `District
Representative`) — whichever real person the player currently has hired
in that role is who actually speaks; the row itself only names the role,
not a specific person. If nobody is hired in that role, the row is simply
skipped for that playthrough.

---

## Quick reference

| Tab | Key | Columns |
|---|---|---|
| **Level Intro Cues** | Level ID + Role | Cue Text |

---

## Voice

Unlike Opponent Cues (`design/CONTENT_PROMPT.md`), a Level Intro cue is
allowed to be specific to *this* level — it's someone on the player's own
staff reacting to what's coming, not a generic line reused everywhere.
Still:

- Under 12 words.
- That staff member's own voice — a colleague talking to the player, not
  narration and not a menu label. "Committee days run long — pace
  yourself." not "This level contains a Committee stage."
- No mechanic talk (no "stages," "opponents," "win," or numbers) — a
  person giving you a heads-up, not a load screen.
- Don't spoil a stage the level itself is hiding. If a stage's own "Reveal
  In Briefing" column (Stages tab) is "No" — an ambush, by design — don't
  describe or hint at what's coming in that particular room. General
  encouragement ("Rest up, it's a long one") is fine even then.
- The three roles read differently, since they know different things:
  - **Policy Research Assistant** — briefs on substance: what the fight is
    actually about.
  - **Media Spokesperson** — briefs on optics: how it'll play, who's
    watching.
  - **District Representative** — briefs on stakes back home: what the
    constituents want out of this.

---

## The batch block

```
Level: <Level ID> — <one-line reminder of what the level is, for your own
  reference only, never shown in-game>
Roles to write (one or more): <Policy Research Assistant | Media
  Spokesperson | District Representative>
Anything this batch should specifically cover or avoid: <optional>
```

Hand me (or another LLM) this block filled in, and the output is one
Level Intro Cues row per role requested — ready to paste into the
workbook. Run `python3 tools/export_data.py` afterward, same as any other
content change.

---

## Worked example

```
Level: LV31 — Ainu Heritage and Language Act floor vote
Roles to write: Policy Research Assistant, District Representative
```

**Level Intro Cues**:

| Level ID | Role | Cue Text |
|---|---|---|
| LV31 | Policy Research Assistant | "The numbers are close. Every seat you can move matters today." |
| LV31 | District Representative | "Your district's watching this one closer than most." |

---

## Current status (2026-09-27)

The tab exists in the workbook, empty — no rows written yet. This is a
new feature; nothing plays until Cameron authors at least one row for a
level he wants to have this beat.
