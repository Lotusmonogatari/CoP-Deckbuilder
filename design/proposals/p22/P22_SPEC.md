# Campaign skins: Samurai and Gladiator — design spec

Cameron, 2026-11-26. Mockups: the claude.ai design canvas "Election campaign screens: samurai and gladiator" (20 boards). This package holds its source (`mockups/`), standalone renders (`previews/*.html`), screenshots (`previews/shots/*.png`) and the art (`art/*.svg`).

## What they are

Two **campaign skins** for the election screens built in P20. Both are the base **Woodblock** UI with the same layout, cards, 2 px ink borders, square corners and hard offset shadow. Only colours, a few type settings, an emblem and the phase-banner art change.

| Skin | Idea | Emblem | Banner art | Headings | Tier numerals |
| --- | --- | --- | --- | --- | --- |
| **Samurai** | Washi paper; black lacquer, vermilion (shu) and gold leaf | Crest (four diamonds in a ring) | Nobori war banners rising before a red sun | Antaka Brush Display, as written | 0, 1, 2 |
| **Gladiator** | Travertine; bronze and Roman crimson | Laurel | Laurel wreath and a row of arena arches | Shippori Mincho B1, CAPITALS, tracked .12–.14 em | 0, I, II |

## Screens that take the skin

| Screen (P20) | Board | Skin-specific parts |
| --- | --- | --- |
| Campaign Office, Actions tab | `office` | Phase bar; stat grid; action cards with tags |
| Campaign Office, Staff tab | `staff` | Tier pips; lent and locked states |
| Campaign Office, Van tab | `van` | Van art; tier badges (numerals) |
| Campaign Moment! card | `moment` | Card label with emblem |
| Poll card | `poll` | Card label; strength range bar with threshold marks |
| Selection card | `selection` | Card label; three score bars; the outcome stamp |
| Phase banners | `announcement`, `mustering`, `campaign`, `election_day` | Full-screen banner art per phase; big title; kicker; one button |

Everything else in the game keeps the player's look.

## When each skin shows (proposed; Cameron to confirm)

A Rules switch `campaign_skin`:

| Value | Meaning |
| --- | --- |
| `phase` (proposed default) | Samurai in Building, Banners of War Rising, Mustering the War Campaign and Sengoku no Hi; Gladiator during Gladiators of War Unleashed |
| `samurai` / `gladiator` | That skin always |
| `off` | Campaign screens use the player's own look |

The skin replaces the player's look (Woodblock, Living Office or Broadcast) on the screens above only (proposed).

## Tokens (UI Styles tab, new styles `campaign_samurai` and `campaign_gladiator`)

Any token not listed is taken from `woodblock`.

| Group | Token | Samurai | Gladiator | Used for |
| --- | --- | --- | --- | --- |
| colour | ground | #EDE3CF | #E6DCC6 | Screen background |
| colour | paper | #F7F0E1 | #F3ECDD | Cards |
| colour | ink | #16130F | #221A12 | Text, borders |
| colour | ink_quiet | #4E463C | #54473A | Secondary text |
| colour | accent | #A61E1E | #7E1F1A | Chips, tags, selected states (replaces indigo) |
| colour | on_accent | #F7F0E1 | #F3ECDD | Text on accent |
| colour | tab_on | #A61E1E | #8C5A2B | Selected tab |
| colour | button | #16130F | #7E1F1A | Primary button |
| colour | button_ink | #F1D58C | #F3ECDD | Primary button text |
| colour | shadow | #16130F | #8C5A2B | 4 px hard offset shadow on cards |
| colour | bar_fill | #A61E1E | #7E1F1A | Bars |
| colour | bar_track | #DDD0B6 | #D6CBB2 | Bar tracks |
| colour | phase_bar | #16130F | #7E1F1A | Phase bar background |
| colour | phase_bar_ink | #F1D58C | #F3ECDD | Phase bar text |
| colour | phase_rule | #A61E1E | #8C5A2B | 3 px rules above and below the phase bar |
| colour | card_label | #A61E1E | #8C5A2B | CAMPAIGN MOMENT!, CAMPAIGN POLL, SELECTION labels |
| colour | card_label_ink | #F7F0E1 | #F3ECDD | Label text |
| colour | emblem_fill | #F7F0E1 | #F3ECDD | Small emblem fill |
| colour | emblem_ink | #16130F | #F1D9A0 | Small emblem lines |
| colour | stamp | #A61E1E | #7E1F1A | Selection outcome stamp |
| colour | jp | #6B5F50 | #6E6050 | Japanese accent |
| font | display | Antaka Brush Display | Shippori Mincho B1 | Titles, banner titles, big numbers |
| type | title_case | as_written | upper | Titles and headings |
| type | title_tracking_em | 0 | 0.14 | Banner and card titles |
| type | heading_tracking_em | 0 | 0.12 | Section headings |
| type | numerals | arabic | roman | Tier badges and tier text |
| art | emblem | crest | laurel | `art/emblem_<skin>.svg` |
| art | banner | nobori | arena | `art/banner_<phase>_<skin>.svg` |
| art | van | van_samurai | van_gladiator | `art/van_<skin>.svg` |
| art | texture | fibers vertical, step 7, alpha 0.07 | stone horizontal, step 11, alpha 0.06 | Banner background |
| shape | stamp_tilt_deg | −6 | 0 | Selection stamp |

Good and bad colours (#2F6B3A, #A42A17) and the alarm colour stay as Woodblock.

## Parts

- **Phase bar.** Full-width, under the tabs: emblem (20 px in the mockup), the phase's in-game name in the display face, and a short note at the right ("34 days to the campaign · ×1.5"). Shown on the Campaign Office tabs.
- **Card label.** Top-left of the Campaign Moment!, poll and selection cards: emblem (16 px) and the label in capitals, tracked .1 em.
- **Selection stamp.** A 3 px bordered box in the stamp colour, tilted by `stamp_tilt_deg`: "Selected" in the display face and the outcome below. Not Selected uses the same stamp in the same colour.
- **Phase banners.** Full screen: kicker (dates), big title, Japanese accent, one or two sentences, one button; the art fills the lower 520/844 of the screen. Each phase has its own art (sun or wreath size and banner heights change). Titles and sentences are P20's Text rows; the banner Japanese accents are 旗揚げ, 出陣準備, 選挙戦, 戦国の日 (Text rows `campaign.phase.<id>_jp`).
- **Van.** The van art without lettering; the code draws the player's name on the side panel in `on_accent` on `accent`.
- **Tier pips.** One square per tier the person can reach; filled up to their tier in `accent`.

## Scale

Mockups are 390 × 844 CSS px; the game's base is 1080 × 2340. Multiply mockup sizes by 2.77. Art SVGs use the mockup's coordinates (banners 390 × 520; emblems 20 × 20 or 24 × 24; van 230 × 110); import them at the scale that gives sharp textures at 1080 wide.

## Open (for Cameron)

1. Default `campaign_skin`: `phase` (proposed), or one skin all the time?
2. Should players on Living Office or Broadcast see the skins on campaign screens, or keep their look (`off` for them)?
3. Should the phase bar also show on the main Office and District screens from Banners of War Rising to Sengoku no Hi?
