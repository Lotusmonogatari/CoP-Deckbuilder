# Two new Party Bodies: Party Activists and Candidate Selection Committee (plan, 2026-10-18)

Status: **proposal, nothing built.** Names, numbers and pairings are drafts for Cameron to correct.

## Summary

| | Party Activists | Candidate Selection Committee |
|---|---|---|
| ID (next free) | BO31 | BO32 |
| Tier | Party | Party |
| Who | Hardcore extremists of the player's own party | A balanced set of party members who choose candidates |
| Character | Likes **Divisive** rhetoric; hostile to compromise | No favourite suit: rewards a **varied** style |
| Starting standing (draft) | 25 (below the flat 30: activists are hard to please) | 35 |
| Backing (draft) | M47 Activist Ground Game | M48 Selection Committee Endorsement |
| Rival of | Selection Committee (moderate vs. extreme) | Activists |

Like Party Headquarters and Party Faction, both are **Party Bodies that belong to whichever party the player is in**. They are not stakeholders of any bill, so no Law Effects rows are written for them.

## What already works with no code

Adding a Party-tier organization is mostly workbook data. These existing mechanics pick the new rows up automatically: standing and decay, the Outcome panel icons, the Important Stakeholders list (a "Party Bodies" heading by Tier), the listening strip and its taste lines, Party opinion (the `OWN` rows), the Party-tier vote lean, Your Record cause lines, and the Boosters panel.

## Work plan

| # | Step | Where | Size |
|---|---|---|---|
| 1 | Add BO31, BO32 to **Boosters** (names, Japanese, romaji, Tier Party, Starting Standing, Linked modifiers) | workbook | small |
| 2 | Add backings M47, M48 to **Modifiers** (four existing effect types only) | workbook | small |
| 3 | Add `OWN` rows to **Party Standing** (weights below) | workbook | small |
| 4 | **Question Themes**: add the two organizations to existing themes (rules below), and annoy each other on some | workbook, scripted batch | medium |
| 5 | New **questions** so each organization clears the floor of 15 and its taste is right (see Content) | workbook | medium |
| 6 | **Visitor dilemmas**: add the two as Effects targets on about 8 party visitors | workbook | small |
| 7 | **Office Ticker** lines, 2 per organization | workbook | small |
| 8 | **Party-tier vote lean** per organization (decision A below) | code + 1 column | small-medium |
| 9 | **Icons** BO31.png, BO32.png (Assets) | art | 2 images |
| 10 | Tests and docs: hard-coded organization counts, `design/ART_CHECKLIST.md`, CLAUDE.md entry, README tab counts | repo | small |
| 11 | Playtest: bot stage trials, rubric, `tools/verify.sh` | tools | small |

## Content (all drafts)

**Names**

| ID | English | Japanese | Romaji |
|---|---|---|---|
| BO31 | Party Activists | 党活動家 | Tō Katsudōka |
| BO32 | Candidate Selection Committee | 公認候補選考委員会 | Kōnin Kōho Senkō Iinkai |

**Backings** (trigger: that organization's standing, Trigger min % 25; need standing 60 to buy, like every backing)

| ID | Name | Effect (existing type) | Cost |
|---|---|---|---|
| M47 | Activist Ground Game | +10 starting support at ST03 Party Caucus (stage-start bonus) | 10 Reputation, 5 Constituency support |
| M48 | Selection Committee Endorsement | +3 Party support after each level won (`RESOURCE_BONUS_ON_WIN`, target PartySupport, like M09) | 10 Reputation |

**Party Standing rows** (`OWN`): BO31 weight **2** (a loud minority: it moves the party's view of you, not decides it); BO32 weight **3**. The existing HQ 5, Faction 4 and Members of Parliament 2 stay.

**Questions and tastes.** The taste line on the battle screen is read from the grades of the questions that please an organization (a strong grade for a suit is +1), so the character is built by choosing and writing questions.

* **Activists, favour Divisive.** 199 questions already grade Divisive as strong and about 17 each pleasing HQ or Faction do so. Rule: add BO31 to the pleased list of every Question Theme where Divisive is strong in at least half its questions, up to about 30 themes (identity, security, anti-establishment, "us against them"), then write about 8 new questions where Divisive and Emotional are strong and Data Driven and Duplicitous are weak. Target average for Divisive at least +0.5 (today's Student/Traditional Society precedent), so the taste line reads "Likes Divisive".
* **Selection Committee, balanced.** Add BO32 to themes about party process: ethics rules, member pay, parliamentary procedure, internal democracy, ballot integrity, faction discipline, committee seats, leadership ballots. Write about 10 new questions whose strong grades are spread over different suits (never the same two), so no suit averages 0.25 or more and the screen shows **no** taste line, which reads as "balanced".
* **Rivalry.** On Activists' themes, list BO32 under **Annoys** for about 10 of them and the reverse for about 5, so a strong divisive answer cheers the Activists and sets the Committee back: the moderate-versus-extreme tension, using the existing Annoys column.
* **How To Play:** nothing to edit: the suit table (HT21) recomputes. The Divisive line may fill (the four-per-suit cap), so one existing organization could drop off it.

**Visitor dilemmas.** About eight party visitors (VI16-VI39) gain choices that please one body and set the other back (a firebrand's demand versus a procedural answer). Stay inside the dilemma budget in `design/VISITOR_DILEMMA_GUIDE.md`.

**Ticker (examples):** "Party activists are already planning the next rally." (no time words: "Party activists are planning a rally.") and "The Candidate Selection Committee is reviewing its shortlist." Gate them on the standing falling below 30, or `always`.

## Decision needed: vote lean

Today every Party-tier organization moves the **same** amount when a bill passes or fails against your party's position (`law_lean_party_tier_*`, scaled by salience). Two bodies with the same reaction would be one body twice.

| Option | What it does | Cost |
|---|---|---|
| A. Leave it | All Party Bodies react the same | none; the new bodies feel alike |
| B. **Per-body multiplier (recommended)** | New optional Boosters column **Party Lean Multiplier**: Activists 2.0 (they react hardest to a bill your party backed or opposed), Committee 0.5 (steady). Blank = 1.0, so HQ and Faction do not change | a schema change (needs your OK), about 20 lines and a test |
| C. Activists mirror salience only | Scaled only by how strongly your party cares about the bill | a bigger rules change |

## Assets

| File | What | Brief |
|---|---|---|
| `assets/icons/BO31.png` | Party Activists | 256x256 RGBA, house style (flat two-tone, cream trim, one sparkle, no text). Suggested picture: a raised fist holding a flag or a megaphone, in a hot orange-red. See `design/ICON_GENERATION_BRIEF.md` and `design/reference/org_icon_style_sheet.png` |
| `assets/icons/BO32.png` | Candidate Selection Committee | A round table with several seats, or a ballot box with a check mark, in teal |

Check with `python3 tools/merge_icons.py <folder>`, then `.tools/godot --headless --import`. Until drawn they show a labelled placeholder. No portraits, backgrounds or card art are needed.

## Tests and docs to touch

* Any test that counts organizations (30 today), and `test_every_organisation_has_a_backing` (covers BO17-BO30 by name; extend to BO31-BO32).
* `tests/test_booster_suit_tendency.gd`: add a check that BO31 reads as Divisive-liking and BO32 as no taste.
* `design/ART_CHECKLIST.md` (re-run `python3 tools/art_checklist.py`), README tab counts, CLAUDE.md dated entry, `design/WORKBOOK_EXPANSION_GUIDE.md` organization count.
* Rubric line D8 already skips Party-tier organizations; no change.

## Risks

* Activists enlarge the Divisive pool: HQ and Faction already please on Divisive, so check how often one answer pleases three Party Bodies at once and trim if it makes Party Bodies too easy to please.
* Starting standing 25 plus the diminishing-returns bands can make the Activists' backing (needs 60) a very long climb: intended, but confirm.
* Party opinion: two more `OWN` rows shift your own party's blended opinion; the five other parties are unchanged.

## Open questions for Cameron

1. Vote lean: A, B or C?
2. Are the two names and the Japanese right, and is "Activists" always the player's own party's activists (assumed: yes, like HQ and Faction)?
3. Should the Activists' rivalry with the Committee (Annoys) be built, or keep them independent?
4. Starting standings (25 / 35) and the two backings: fine as drafts?
