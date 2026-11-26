# P22: Campaign skins — Samurai and Gladiator for the election screens

**Branch:** `feature/p22-campaign-skins` from `main`, after P20 phase D has merged (the screens this styles must exist).

**Source:** `SPEC.md` in this package (the design spec, tokens and rules), `previews/shots/*.png` (what each screen should look like), `previews/*.html` (standalone renders you can open), `mockups/` (the canvas source; `tokens.js` holds every value) and `art/*.svg`.

**Approval.** Cameron approved building the two skins on 2026-11-26. The new UI Styles rows, the `campaign_skin` Rules row and the `assets/campaign/` art are approved. Anything else that touches schema, IDs or canon: stop and ask. Follow CLAUDE.md: tokens and numbers in the workbook, sentences in Text rows, pure rules separate from UI, heavy comments, merge only after `tools/verify.sh` prints "All checks passed".

**Before you start, ask Cameron the three open questions at the end of `SPEC.md`.** If he isn't there to answer, build with the proposed defaults (`phase`; skins replace every look on campaign screens; phase bar on the Campaign Office only) and list the questions in your report.

---

## 1. Workbook and data

- **UI Styles tab:** add every token in SPEC.md's table as rows for styles `campaign_samurai` and `campaign_gladiator` (Group, Token, Value, Notes). New groups `type`, `art`, `shape` are allowed for these two styles. The exporter checks that each campaign style has every token in the table and that colours are `#RRGGBB`.
- **Rules tab:** `campaign_skin` = `phase` (values `phase`, `samurai`, `gladiator`, `off`).
- **Text rows:** `campaign.phase.announcement_jp` 旗揚げ, `campaign.phase.mustering_jp` 出陣準備, `campaign.phase.campaign_jp` 選挙戦 (`campaign.phase.election_day_jp` exists from P20); the phase bar notes (`campaign.phase_note.mustering` "{days} days to the campaign · ×1.5", `campaign.phase_note.campaign` "{days} days to Sengoku no Hi", `campaign.phase_note.building` "{days} days to Banners of War Rising"); the banner kickers and button labels as shown in the previews (add each as a Text row; keep the wording).
- **Art:** copy `art/*.svg` to `assets/campaign/` (`banner_<phase>_<skin>.svg`, `emblem_<skin>.svg`, `van_<skin>.svg`). Import as textures at a scale that is sharp at 1080 wide (banners about 1080 × 1440). Add them to `data/art.json` (hand-written; keep its README's format) and to `tools/art_checklist.py` if it lists art by folder.

## 2. Rules

- `scripts/rules/CampaignSkin.gd` (pure): `skin_for(phase, rule_value, player_look) -> "campaign_samurai" | "campaign_gladiator" | ""` (empty = the player's look). `phase` value: samurai for `building`, `announcement`, `mustering`, `election_day`; gladiator for `campaign`.
- `roman(n)`: 0 → "0", 1 → "I", 2 → "II", 3 → "III". Used where `numerals` is `roman`.
- Tests: every phase and rule value; `off`; numerals.

## 3. Theme

- `UiStyleTheme` / `tools/build_theme.gd`: build two more overlays from the campaign styles' tokens, saved as `theme/cop_theme_campaign_samurai.tres` and `theme/cop_theme_campaign_gladiator.tres`. Same items as the other overlays (fonts, ink colours, button boxes), so merging one over another leaves nothing behind. Gladiator's display face is Shippori Mincho B1 with the existing accent fallback (Antaka Brush Text for ō, Ō, ū, Ū, ā, ī) and Noto Sans JP behind it.
- Capitals and tracking: titles and headings on skinned screens take `title_case` and the tracking tokens (Godot: upper-case the displayed string and set the font's spacing; the Text row stays as written).

## 4. Screens (match `previews/shots`)

Apply the overlay for `skin_for(...)` to these screens only, and draw the skin parts from SPEC.md's "Parts":

| Screen | Shot |
| --- | --- |
| Campaign Office, Actions / Staff / Van tabs | `Campaign_office_*`, `Campaign_staff_*`, `Campaign_van_*` |
| Campaign Moment! card | `Campaign_moment_*` |
| Poll card | `Campaign_poll_*` |
| Selection card | `Campaign_selection_*` |
| The four phase banners | `Campaign_announcement_*`, `Campaign_mustering_*`, `Campaign_campaign_*`, `Campaign_election_day_*` |

- **Phase bar** on the three Campaign Office tabs (and on the Office and District screens from Banners of War Rising to Sengoku no Hi only if Cameron says so).
- **Card label** with the emblem on the Campaign Moment!, poll and selection cards.
- **Selection stamp**, tilted by `stamp_tilt_deg`.
- **Phase banners:** background `ground` with the texture token, the phase's banner art across the lower 520/844 of the screen, kicker, title, Japanese accent, sentence, one button, as in the shots.
- **Van tab:** the van art with the player's name drawn on its side panel by code.
- **Tier pips and badges** use `numerals`.
- Card shadow: a 4 px hard offset in `shadow` (no blur), as Woodblock already does with its own colour.
- Leave every other screen on the player's look.

## 5. Checks

- `tools/verify.sh` passes; the exporter checks the new rows; tests for `CampaignSkin`.
- Take a screenshot of each of the 20 states (10 screens × 2 skins) with the project's screenshot tool if it has one (else in the editor), put them in `design/proposals/img/campaign_skins/`, and compare each with `previews/shots`. List any difference you chose to keep.
- Change log: "Campaign skins, Samurai and Gladiator (2026-11-26, Cameron; branch feature/p22-campaign-skins)".

## Finish

Report: files changed, the new tokens and Rules row, the screenshots, Cameron's answers to the three questions (or that you used the defaults), and anything else you had to decide.
