# Coliseum of Parliament: new session start-up (2026-11-13)

Point the assistant at this file at the start of a new session. The brief and the working rules are in `CLAUDE.md`; `README.md` is the short snapshot. This guide replaces the 2026-11-06 version.

## 1. Executive summary

| Item | State |
|---|---|
| Game | Godot 4.5, GDScript, portrait mobile card battler. Fictional nation Yezo (101 seats, floor majority 51, no early elections). |
| Repo and branches | `lotusmonogatari/cop-deckbuilder`. Work on the designated session branch; merge to `main` only after `tools/verify.sh` says "All checks passed". Everything to date is merged; the session branch (`claude/new-session-klhgm8`) is level with `main` at `b6c643f`. |
| Workbook | `design/Game_Workbook.xlsx` |
| Content (`data/`) | 289 stage rows, 114 levels, 70 cards, 32 organizations, 131 opponents, 50 floor-vote bills, 167 visitors and 423 visitor questions, 87 events, 35 shop items, 21 staff, 180 bill components, 6 cosmetic packages, 987 Text rows |
| Tests | About 1,860 GUT tests (157 scripts) and 32 real-click interaction tests. `tools/verify.sh` (which also compiles every script) passes in about 2-3 minutes. |
| Missing | All audio files, most character art (opponents, students, visitors, PC02/PC03), 8 goods icons, `OUT_NEIGHBORHOOD`. No real-phone build yet (milestone M6). |

## 2. The document map

| Read | For |
|---|---|
| `design/GAME_DESIGN.md` | What the game is and how its parts connect, as a story |
| `design/GAME_SYSTEMS.md` | **The exact mechanics**: resources, growth and decline, where the player chooses, and every piece of run state |
| `design/INFORMATION_STANDARDS.md` | **How the player must be told things**: what is shown before and after a choice, the terms, who may say what, layout |
| `design/ARCHITECTURE.md` | How the code is organised, the rules-versus-screens split, pitfalls |
| `design/CONTENT_GUIDE.md` | How to write levels, stages, events and the content they depend on |
| `design/EDITING_TEXT.md` | How to reword existing text, tab by tab |
| `design/CHANGELOG.md` | A summary of September and October, then every dated change since 2026-11-01 |
| `design/CLEANUP_CANDIDATES.md` | Things that look removable. Nothing is deleted without Cameron's say-so |

## 3. The person and the working rules

- Cameron is the designer and a legislature expert. He is not a programmer. He is often on a phone: ask decisions as popup questions (AskUserQuestion, at most four per popup), not long Markdown, and publish anything he must read as a short mobile-friendly page when it is more than a few lines. He likes tables, quick-reference layout and an executive summary on medium and long answers.
- Never decide design or canon for him. Draft, label the draft, and let him correct it. Names of characters, parties, committees and places come only from the data. Staff Biography and Role Flavor Text are his to write.
- Ask before adding a dependency, changing a data schema, renaming an ID, or resolving anything marked open. More than about 150 lines of new code: outline first and wait. He says "go" to approve outlines and "merge" to approve merges. **No deletion or removal without his say-so:** candidates go in `design/CLEANUP_CANDIDATES.md`.
- No sentence lives in a script and no design number lives in a script (workbook Text and Balance tabs; `tests/test_balance_keys.gd` enforces the second).
- Rules code (`scripts/rules/`) is pure, with no UI or scene access. Every rules bug fix gets a test.
- Commits: small, plain-English messages, ending with the `Co-Authored-By:` and `Claude-Session:` lines the session reminder gives. Do not open pull requests unless asked.
- Dates are YY.MM.DD everywhere. `WeekCalendar.parse_date()` is the one parser.

## 4. Commands

```
tools/get_godot.sh                         # if .tools/godot is missing
.tools/godot --headless --path . --import  # after adding a class_name script
python3 tools/export_data.py               # must say "No errors" (add --accept-wording when Text rows change)
python3 tools/workbook/check_formulas.py   # Excel-repair check; verify.sh runs it
.tools/godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
tools/verify.sh                            # the whole gate, about 2 minutes; merge only on "All checks passed"
tools/verify.sh --quick                    # data, boot and unit tests only (JOBS=2 limits parallel click tests)
python3 tools/cue_coverage.py              # which opponent bill-line pools would repeat inside 30 turns
python3 tools/outdoor_backgrounds.py       # the outside scenes: drawn?, who uses them, art prompts
xvfb-run -a -s "-screen 0 1080x2340x24" .tools/godot --path . --resolution 1080x2340 <scene>   # screenshots / one click test
```

When a gate's log is checked, look for the real "All checks passed" line; words like "failed" also appear in test names. Do not edit files while a gate runs. The "Parse Error: NavigationServer2DManager" lines in GUT output are harmless noise.

## 5. Things that bite

The code-level ones are in `design/ARCHITECTURE.md` section 8. Workbook and content ones:

1. **Never save the workbook with openpyxl** (it corrupts cached values). Edit with `tools/workbook/wbx.py` and run `python3 tools/export_data.py` after every edit. Header cells need `style=''` (or `style_from=1`). Setting cells without `save()` loses the edit. Copy a row with `w.copy_row(...)`, not by reading `rows()` and writing it back. A workbook upload from Cameron can land on `main` while you work: take his file in a merge and re-apply your edits with `wbx`.
2. A blank workbook cell exports as JSON null; guard `str(null)` and `int(null)`.
3. Agent-written text edits need guards: keep place names and proper names, keep digits, enforce word limits.
4. Content-budget tests pin visitor choice values and per-organization tastes; a content edit can trip them.
5. The export saying "No errors" is not the whole check: run `tools/verify.sh`, `python3 tools/content_depth.py` and a bot trial for new rooms.
6. The workbook's structured columns are the truth: when text and a column disagree, change the text. Drafting rules (the discard tiers) only warn.
7. Protagonist rows in the Opponents tab (OP06, OP22, OP35, OP40) are never seated; a test enforces it.
8. Tests must read workbook values, never type them.
9. Staff pictures resolve `SF01_{expression}.png` first and a plain `SF01.png` last; an `OUT_*` background id shows the Town Hall until its own picture exists.
10. The Decline generator under `tools/workbook/archive/` is a one-off; add a new event's Decline by hand (1.5 times the shortfall of the staff choice against choice A).
11. Shop item IDs were renumbered (2026-10-04): quote an item by name in prose, and never assume an old ID.

## 6. What was done most recently (2026-11-06 to 2026-11-13)

Details are the sections at the end of `design/CHANGELOG.md`. In short:

- **Stage results and saves:** a stage's result is saved when shown, so closing the app on a loss still counts it; every button press saves; haptics (with a setting); the Android back button is deliberately inert.
- **Resign:** a two-part screen (normal layout, then the mirrored goodbye and the title), available only while all three standings are far down.
- **Money:** party dues are 50,000 + 10,000 per 15 Party support above 40 + a share of the week's earnings (5% Relaxed); the national awareness dues relief is 50,000; Tier 0 stage pay is capped at 30,000; the Funds-cap petition leaves the Marketplace at the ceiling.
- **Lost Acts:** a failed win/lose stage in a bill level shows party-colour or gaffe cues; a lost Act records an absent vote and the bill returns after 7,488 hours. A bill the player voted on never returns; absent or abstained ones do.
- **Rooms and items:** the lobbyist's organization always applies scrutiny; the TV debate bar shows the opponent again; items that take hours show a greyed Use button when there is no time; Your Record's changes sit behind buttons.
- **Content:** transitions for custom-bill stages; EV83 to EV94 (twelve events favorable to six organizations); visitors 58 to 78 and 144 and 167 (VI167 has no stage, reward, penalty or questions yet, so it never appears); the Japanese font was re-subset for new names.
- **Characters list (new, 2026-11-13):** Administration, Characters. A scrolling list of every opponent and visitor; the button colour is the party colour, the player's party colour for a party body with no named party, or one muted tier colour (nine Balance rows). Unmet people read 誰ですか。 (a deliberate exception to English-first). "Met" is saved in `GameState.met_characters` and recorded when someone actually appears. Rules in `scripts/rules/CharacterCodex.gd`, UI in `scripts/ui/CharacterCodexPanel.gd`.
- **Reviews (read-only reports):** `audit/` (project audit), `audit/gameplay/` (gameplay review), `design/review/ORG_REPRESENTATION_2026-11-13.md` and `ORG_OUTCOMES_2026-11-13.md` (how events and visitors treat each organization).

## 7. Open items

| # | Item | Notes |
|---|---|---|
| 1 | Audio build, step 1 (approved in principle, outline not yet sent) | Five sliders, a Sound page in Administration, interface and stage-change hooks, vibration switch. Brief: `design/proposals/AUDIO_BRIEF_2026-10-26.md` |
| 2 | Real phone build | Milestone M6; Image Pan's tilt direction and the new portrait sizes need a real phone |
| 3 | Art | Opponents, students, visitors, PC02/PC03, 8 goods icons, `OUT_NEIGHBORHOOD`. Character art is Cameron's pipeline; Claude writes prompts on request |
| 4 | Election strength | Built and shown; fires nothing yet. What it should unlock is Cameron's to decide |
| 5 | Unused stored numbers | `segment_favorability` is stored but read by nothing since staff rewards moved to organizations; the Sanban tab's low/high "consequence" notes are text only |
| 6 | Cleanup | `design/CLEANUP_CANDIDATES.md` (old working papers in `design/review/`, `design/proposals/`, `design/bench/`, balance audits) awaits Cameron's approval |
| 7 | Ministers | Five ministers sit in every TV debate; Cameron chose to leave it |
| 8 | MC²T results | `design/review/MC2T_REPORT_2026-11-06.md`: touch targets (93% under 44 pt), no mid-stage save, "Boosters" naming clash; kit ready for a 5-player round on a real phone. Decisions are Cameron's |
| 9 | Gameplay review leftovers | `audit/gameplay/00-summary.md`: Tier 1 and 2 pay less XP per hour than Tier 0 and repeats do not decay; meters hit their ceilings by week 4 to 8; no audio. Cameron decides |
| 10 | Taxpayers' Alliance | Still the most over-represented organization with net negative outcomes (EV83 choice C and the Decline rows); a rebalance was offered, not approved |
| 11 | VI167 | Done 2026-11-13 as a draft: 16 rooms, standing and six questions (VQ424-VQ429). Cameron to rewrite |
| 12 | Characters list | Colours and the nine Balance rows are drafts; opponents faced before 2026-11-13 show as unmet until they reappear; unmet popup not yet seen on a phone |
| 13 | Branches | Four old remote branches (`ccr-1bbd9851-yg8on5`, `claude/happy-ramanujan-e0mrxj`, `claude/optimistic-noether-1j0yqh`, `claude/new-session-s1juv4`) could not be deleted from a session (no permission); Cameron asked for them to be deleted, so he must do it on GitHub |

## 8. A good first message

"Read design/NEW_CHAT_STARTUP.md, check git status and git log -5, and tell me the state in one table before we start."
