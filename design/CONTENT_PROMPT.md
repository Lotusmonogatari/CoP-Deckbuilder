# Content prompt — questions, cues, and replies

A reusable prompt for drafting the game's spoken lines and questions: Town
Hall (and its four sibling) Questions, Opponent Cues, Visitor Questions, and
Card Flavor cues. Everything it produces is a **draft for Cameron to correct**,
the same status as the Theme → organisation mapping — never a canon decision
made on his behalf. Paste the output into the matching workbook tab, run
`python3 tools/export_data.py`, and reword anything that doesn't sound right.

---

## Quick reference: what each content type needs

| Content type | Tab | Unit of work | Format rule | Canon risk |
|---|---|---|---|---|
| Opponent Cues | **Opponent Cues** | 5 lines per suit × verb (attack/gain/block) | Tone Guide table below; ≤9 words; universal setting | None — generic, no named opponent |
| Town Hall / Press / Lobbyist / Study Session / Media Ambush Questions | the five **…Questions** tabs | 1 question + Theme + S/M/W × 6 suits | Plain question, no venue tell; Theme must be an existing booster or blank | Low — no named target, but Theme choice affects who it pleases |
| Visitor Questions | **Visitor Questions** | 1 question + 4 choices + 1 correct + right/wrong reply + reaction | Distinct choices per question (VQ01/VQ02 currently repeat placeholder choices — needs real content) | None — visitors are placeholders (VI..) |
| Card Flavor cues | **Flavor Text** | Up to 5 spoken lines per card | Same 5 writing rules as Opponent Cues, but may reference the card's own effect | None — first person, no target |

---

## The master prompt

Copy this whole block, fill in the `< >` brackets for the batch you're
running, and hand it to an LLM (or to me in a new turn). Everything after
"Batch" changes per run; everything above it is the constant brief.

```
You are drafting flavor writing for Coliseum of Parliament, a turn-based
card battler about parliamentary rhetoric. Every line is DIALOGUE SPOKEN
IN THE MOMENT — never narration, never a stage direction, never addressed
to "the player" as a game concept.

VOICE BY SUIT (six suits; every line belongs to exactly one):

| Suit | Register | Voice | Signature moves | Example |
|---|---|---|---|---|
| Earnest | Plain, accountable, steady | First person singular. Short declaratives. | Owning results and mistakes; no adjectives doing the work | "Judge me by my record." |
| Emotional | Raw, exclamatory, heartfelt | Exclamation marks, personal stakes. | Faces, families, fighting; the crowd as participant | "I will not be shouted down!" |
| Appeal | Warm, inclusive, collegial | We / us / together; second person as ally. | Unity, loyalty, favors owed, the room already agreed | "One good turn deserves another." |
| Data Driven | Cool, precise, evidentiary | Questions and numbers. No exclamations. | Dates, figures, documents, yes-or-no demands | "Which is it? You can't have both." |
| Divisive | Cutting, accusatory, separating | Us versus them; pointed second person. | Labels, sides, binary choices, loyalty doubts | "Pick a side. The voters are watching." |
| Duplicitous | Slippery, noncommittal, winking | Passive voice, hedges, trailing ellipses. | Deferral, deflection, implied deals, fake memory loss | "We will consider that positively." |

FIVE HARD RULES (a line breaking any of these is rejected, not softened):

1. Under 10 words. Nine words maximum, count them.
2. Universal setting. Must sit naturally at a town hall, a press
   conference, AND a parliamentary floor debate. No venue- or
   audience-specific address ("evening news", "the floor", "Minister").
3. No time references. No days, months, years, durations, or words like
   now, today, again, already, still, before, always, never.
4. No invented history. No claim that a specific prior event happened —
   a vote, a statement, a favor, a meeting, a failure. Present-tense or
   general truths only.
5. Not a reply. Must not depend on what anyone just did — it may be heard
   with no action having happened at all.

Never invent named characters, parties, committees, or specific policies.
If a slot needs a name, use the neutral placeholder already assigned to it
(an opp_id, a VI.. id) and write around the rest generically.

--- Batch ---
Content type: <Opponent Cues | Town Hall Questions | ...>
Rows to fill (IDs + suit/verb, or IDs + theme, as applies): <list>
Existing rows in this same tab, for tone-matching (paste 2-3): <examples>
How many lines/rows per slot: <5 cues | 1 question + grades | ...>
Anything this batch should specifically cover or avoid: <optional>
```

---

## Variant notes

**Opponent Cues.** One row per (suit × verb) — 18 total, `attack`/`gain`/
`block`. `verb` is the mechanic it's tied to (an opponent about to hit you,
about to gain support, or about to guard), not free text — see CLAUDE.md's
data contract. Output 5 numbered lines per row, one becomes `cue_1`..`cue_5`.

**The five Question tabs.** One question + a Theme word + an S/M/W grade
per suit (which suit's *answer* pleases, is neutral, or costs tone — not
which suit the question itself sounds like). Theme must resolve to an
existing booster ID via the Question Themes tab, or the export logs a
warning that answering it well pleases nobody. Twenty questions currently
exist per tab; a fresh batch is for either replacing weak ones or growing
the pool (adding rows doesn't by itself change how many a room asks — see
`design/EDITING_TEXT.md` §4).

**Visitor Questions.** Each row needs FOUR genuinely distinct choices (not
copies from another row), a `correct_choice`, and short in-character
`response_right`/`response_wrong` + `reaction_right`/`reaction_wrong` lines.
These may break the "universal setting" and "not a reply" rules on purpose —
a visitor's reply is explicitly reacting to your choice.

**Card Flavor cues.** Same five rules, but a cue may reference what its own
card does (a Guard card's cue can allude to defending) since it is always
tied to that one card being played, not to a generic moment.

---

## Current known gaps (2026-09-26)

| Tab | Gap |
|---|---|
| Opponent Cues | OC04–OC18 (15 of 18 rows — every suit but Earnest) have no lines yet |
| Visitor Questions | VQ01 and VQ02 share identical choice/response text — needs its own content |
| Town Hall Questions | None — 20 written and complete; the *room* just doesn't ask them yet (a code gap, not a writing one) |
