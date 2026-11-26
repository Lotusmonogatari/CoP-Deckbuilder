# Campaign art: the file names

2026-11-26 · written by Claude · a draft for Cameron. Folders are under `assets/`. Anything not drawn shows a labelled placeholder, so nothing is blocked. `design/ART_CHECKLIST.md` (from `tools/art_checklist.py`) ticks off what exists.

## Summary

| Group | Files | Drawn |
|---|---|---|
| Campaign staff portraits | 6 (one neutral face each) | none |
| Campaign Office background | 1 (+ up to 4 seasonal) | none |
| Venue and action icons | 5 | none |
| Decision! scene pictures | 2 shared (+ optional one per scene) | none |
| Campaign skins (banners, emblems, vans) | 12 SVGs | all |

## Campaign staff: `characters/campaign/`

New folder, wired to the `CS` prefix. 1024 x 1536, full body, transparent. Only `_neutral` is asked for; a file with no face (`CS01.png`) serves every face.

| File | Person | Role |
|---|---|---|
| `CS01_neutral.png` | Hiroto Ban | Campaign Organizer |
| `CS02_neutral.png` | Dan Bronco | Campaign Organizer (found in a Campaign Moment!) |
| `CS03_neutral.png` | Ren Fusenji | Campaign Fundraiser |
| `CS04_neutral.png` | Umina Kota | Campaign Fundraiser (found in a Campaign Moment!) |
| `CS05_neutral.png` | Hitomi Ota | Campaign Van Announcer |
| `CS06_neutral.png` | Yuina Chanami | Campaign Van Announcer (found in a Campaign Moment!) |

(The names are placeholders; the IDs are what the files carry. Colleagues who speak in the party scenes use the existing opponent portraits `characters/opponents/OP##_neutral.png`.)

## Offices and places: `backgrounds/` (1080 x 2340)

| File | For |
|---|---|
| `AREA_CAMPAIGN_OFFICE.png` | The Campaign Office screen (VN10, the storefront two doors down from the District office). One picture for every protagonist. |
| `AREA_CAMPAIGN_OFFICE_SPRING.png`, `_SUMMER`, `_AUTUMN`, `_WINTER` | Optional: the season it is now. A missing one uses the plain file. |
| `DEC_PLACE_DISTRICT.png` | The shared picture behind a Decision! scene at the District office (every campaign scene except the Capitol ones). |
| `DEC_PLACE_CAPITOL.png` | The same at the Capitol (DS15, DS22, DS25 and the earlier scenes). |

A scene can also name its own pictures in the Decision Scenes tab's Scene Picture column (`DEC_EV120_1` style); none of DS11 to DS25 does.

## Icons: `icons/` (256 x 256)

| File | For |
|---|---|
| `ACT_CAMPAIGN_FUNDRAISE.png` | Fundraising calls |
| `ACT_CAMPAIGN_LETTERS.png` | Outreach letters |
| `ACT_CAMPAIGN_MAILINGS.png` | Mailings to local organizations |
| `ACT_CAMPAIGN_VAN.png` | Campaign van speech |
| `VEN_CAMPAIGN_OFFICE.png` | The Campaign Office on the place map (named in the Venues tab; the map shows the background today, so this is optional) |

## Vans, banners and emblems: `campaign/` (SVG, all drawn)

The skins draw these from the SVG; there is no PNG to make. The van has no lettering: the code writes the player's name on its side panel and colours the strip in the party colour.

| Files | For |
|---|---|
| `van_samurai.svg`, `van_gladiator.svg` | The Van tab |
| `emblem_samurai.svg` (crest), `emblem_gladiator.svg` (laurel) | The phase bar and every campaign card's label |
| `banner_announcement_samurai.svg`, `banner_mustering_samurai.svg`, `banner_campaign_samurai.svg`, `banner_election_day_samurai.svg` | Samurai phase banners (the three standards take the player's party, Keizaijiyuutou and Yezo Heritage colours) |
| `banner_announcement_gladiator.svg`, `banner_mustering_gladiator.svg`, `banner_campaign_gladiator.svg`, `banner_election_day_gladiator.svg` | Gladiator phase banners (arena arches and laurel) |

## Not asked for yet

| Thing | Why |
|---|---|
| Accuser portraits, outlet logos | The accusation card (P21 phase D) has no picture slots; say if you want them. |
| Campaign staff expressions | The scenes use the neutral face only. |
