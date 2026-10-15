# UI and clarity proposals (2026-10-15)

Nothing here is built. Each item is for Cameron to choose from. Screenshots: `img/vote_end_2026-10-15.png`, `img/record_2026-10-15.png` (real 1080x2340 captures of LV31's vote and Your Record).

## 6. Floor Vote result: showing Aye, Nay and Abstain

**What the screenshot shows.** One line ("It fails — 46 for, 47 against, 8 abstaining.") and three bars labelled Yes / No / Abstain, coloured by party. No numbers on the bars, no key to the colours, and nothing says 51 is needed.

| Option | What the player sees | Cost |
|---|---|---|
| A. Three number tiles | Above the bars: **AYE 46 · NAY 47 · ABSTAIN 8**, large, the Aye tile tinted green if it reached 51 and red if not, with "51 needed" under it. | Text rows plus one HBox. Small. |
| B. Threshold line on the Yes bar | The Yes bar gets a thin white vertical mark at 51 of 101 and a "51" label, so the shortfall is visible as a gap. Numbers printed at each bar's right end. | Small. Needs the bar control to draw one line. |
| C. Per-party table | Six rows, each party's name in its own colour, then Yes / No / Abstain numbers. Opens from a "Who voted how" button so the panel stays short. | Medium. |
| D. Reason line | One sentence: "Needed 51 Yes; got 46. Abstentions count against a bill." | Tiny. |

**Recommendation:** A + B + D together (everything above the fold), C as a button. It answers "why did it fail" at a glance and teaches the 51-of-101 rule.

## 7. Your Record: the statute book

**What the screenshot shows.** Plain text lines: "Ainu Heritage and Language Act: failed, 46 to 47 with 8 abstaining. You voted Yes." Sections run together; there is no colour or marker for passed vs failed, no mention of what the law did, and no mention of the 51 needed.

| Change | Example |
|---|---|
| Passed / Failed marker | Law name, then a coloured word: **PASSED** (green) / **FAILED** (red). |
| Show what you voted | "You voted Yes" on its own muted line. |
| Show the lasting effect | "Each level: +2,000 Funds" under any law with an Each-level row. |
| Show the immediate effect | "Party support −1, Reputation +2" from the law's Once row. |
| Influence flag | "Your influence turned this result." when the swing flipped it. |
| Shortfall | "Needed 51 Yes, had 46." |
| Order and grouping | Newest first, passed laws above failed ones, with a count in each heading. |

**Recommendation:** all of the above except grouping (newest first is enough at 50 bills).

## 9. Crisis alerts and Office notices: examples and changes

Today the popup says what happened ("Constituency support fell to 12 — a Town Hall has been added to your schedule.") but not what it means or how to clear it.

| Trigger | Today | Proposed (alert popup, second line) | Proposed Office Notice (stays on screen while true) |
|---|---|---|---|
| Town Hall (Constituency support 15 or lower) | "…a Town Hall has been added to your schedule." | "Win it, or raise Constituency support above 15, to clear it." | "A Town Hall is pending. Constituents want to be heard." |
| Steering Committee (Party support under 25) | "…the Steering Committee wants to see you." | "Their check-in is your next stage. Answer well to restore Party support." | "The Steering Committee is waiting for you." |
| Funding freeze (Party support at 0) | "…Funding is frozen until it recovers." | "No Funds income from stage wins until Party support is above 0. Losses still cost Funds." | "Funding is frozen. Party support is 0." |
| Party Backing (Party support over 75) | no message | "Party Backing is active for free while Party support stays above 75." | "The party is backing you." |
| Gaffe penalty (50 lifetime gaffes) | "…took a 15 hit." | "This happens once per run." | none (one-time) |

All wording would be Text-tab rows; no code beyond reading a second key per alert. The Office Notices use the existing Office Notices tab and its `meta` condition (for example `Party support < 25`), so they need no code at all.

## 2. Crisis stages: plan to optimise their use, resolution and coding

The four crisis rules (Town Hall, Steering Committee, funding freeze, Party Backing; plus the one-time gaffe penalty) were built in 2026-09-25 and have not been revisited since. Findings:

1. **Resolution is invisible.** A Town Hall inserted by low Constituency support is lost like any stage and can re-trigger only after recovery. The player is never told the exit condition (see item 9).
2. **Party support is now a blend** (votes plus organisation standing). The thresholds read the blend, but Your Record and the alerts quote the blend inconsistently with the stored number. One number everywhere would help.
3. **The inserted stages are generic.** The Steering Committee check-in is ST22 with one placeholder visitor. It could draw its own questions and be Own Party Only, as ST08 is.
4. **Crisis stages are not in the depth audit.** `tools/content_depth.py` does not check that ST22 or the inserted Town Hall have 3x content.
5. **Coding.** The three edge checks (`_check_town_hall`, steering committee, funding freeze) repeat the same enter/leave/insert pattern. A single table of crisis rules (variable, comparison, threshold, action, alert key) in the Balance or a new Crisis Rules tab would let Cameron add or retune crises without code, and give one place to test.

**Proposed order:** (a) alert wording and Office Notices (item 9, no code); (b) one number for Party support in every message; (c) crisis table; (d) richer ST22 content and depth-audit coverage. Each step is separable.

## 12. Backup slot: design

Today: **Back up now** and **Restore the backup**, with the backup's timestamp.

Proposed:

| Piece | Design |
|---|---|
| Label | "Backup: 15 Oct, 14:32 — Level 12 cleared, Funds 80,000, XP 340". Built from the save file itself (`levels_cleared` count, Funds, XP). |
| Restore warning | Shows the backup's summary beside the current run's summary, so the player sees what they would lose. |
| Overwrite warning | If a backup exists, **Back up now** asks "Replace the backup from 15 Oct?". |
| Automatic safety copy | Before a restore, the current run is written to the `.bak` of the main save, so a mistaken restore is itself undoable once. |
| Out of scope | Several slots, cloud save. |

**Recommendation:** label, both warnings and the safety copy. All small; four Text rows.
