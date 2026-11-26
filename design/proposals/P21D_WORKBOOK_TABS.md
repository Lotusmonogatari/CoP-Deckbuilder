# Rumor! and Scandal!: the workbook tabs (P21 phase D)

2026-11-26 · written by Claude · a draft for Cameron

Three tabs are in `design/Game_Workbook.xlsx` now (**Accusers**, **Claims**, **Outlets**), exported to `data/accusers.json`, `claims.json` and `outlets.json`. Nothing in the game draws from them until phase D is built, so they can stay empty or half-filled. The exporter checks every row you add (`tools/test_accusation_exporter.py` has 22 cases).

## Summary

| Tab | One row is | Rows to write | Drawn when |
|---|---|---|---|
| **Accusers** | A person or group who can accuse you (name, title, group, the organization they speak for) | A few per organization | Status is Approved |
| **Claims** | One thing that can be said, in a sentence with slots | 20 to 40 each of Rumors and Scandals to start, plus hand-made ones | Status is Approved |
| **Outlets** | A paper, station or site that prints it | PR01 to PR03 are named; Reach and Lodges are blank for you | Always |

## Accusers (ID `AC##`)

| Column | Meaning | Allowed values |
|---|---|---|
| ID | AC01, AC02 ... | `AC` and a number |
| Accuser (EN) | The name as printed | text |
| Title | Their job | text ("Chair", "Secretary-General") |
| Group (EN) | The body they speak for | text ("Hokkaido Fisheries Cooperative") |
| Tracked Org ID | The organization whose standing this accuser follows: when that organization's standing is the lowest, this accuser is drawn | a `BO##` from Boosters |
| Name (JP), Romaji, Group (JP) | Japanese accents | text |
| Region | Where they are from | text |
| Manner | How they speak (for your writing; the game does not read it) | text |
| Status | Whether the row may be drawn | Draft, Needs JP check, Needs community review, **Approved** |
| Note | Anything | text |

An Approved accuser must have Accuser, Title, Group and Tracked Org ID. Other statuses may be half empty and are skipped.

## Claims (ID `R##`, `S##`, `H##`)

| Column | Meaning | Allowed values |
|---|---|---|
| ID | `R` Rumor!, `S` Scandal!, `H` hand-made (fired by an event choice or a Decision! scene) | the letter must match Kind and Source |
| Kind | What it is | `Rumor!` or `Scandal!` |
| Claim (EN) | The sentence | text with slots (below) |
| Fits | Which organizations it suits: tags from Organization Tastes (anything an organization likes or dislikes), or `any` | semicolons: `humble; risky` |
| Target | Who it is about | Player, Colleague, Either |
| Source | Where it comes from | `Blunder!` (drawn after a Blunder!) or `Hand-made` |
| Status | Whether it may be drawn | Draft, To write, **Approved** |
| Note | Anything | text |

**Slots the game fills:** `{player}`, `{accuser}`, `{accuser_title}`, `{group}`, `{accuser_full}` ("Name, Title of the Group"), `{outlet}`, and `{colleague}` (only when Target is Colleague or Either).

**How a claim is chosen:** the organization with the lowest standing under 15 (else the lowest), then one of its Approved accusers, then a claim of the right Kind whose Fits matches what that organization likes, else an `any` claim; never one used in the last 8 weeks. A Scandal! is lodged by a National outlet; a Rumor! by any.

## Outlets (ID `PR##`)

| Column | Meaning | Allowed values |
|---|---|---|
| ID | PR01 ... (PR01 to PR03 already name the poll sources) | `PR` and a number |
| Outlet (EN) | The name as printed | text |
| Reach | How far it carries | National, District (blank until you decide) |
| Lodges | What it may print | Rumor!, Scandal!, Both (blank until you decide) |
| Note | Anything | text |

## Questions for you

| Question | My suggestion |
|---|---|
| The prompt said the claim text becomes Text rows `claim.<id>`. Should it? | **No: keep the sentence in the Claims tab**, the way an event keeps its flavor in the Events tab. A Text row per claim would need a built-up key, which the Text rules forbid. |
| What does "Lodges" mean? | I read it as which kind an outlet may print (Rumor!, Scandal!, Both). Tell me if it meant something else. |
| PR01 to PR03 Reach | Which of the three are National? A Scandal! needs one. |
| How many accusers per organization? | At least two, so the same name does not come back every time. |
