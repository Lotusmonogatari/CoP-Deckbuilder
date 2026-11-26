# Campaign skins: the 20 states and what I kept different

2026-11-26 · written by Claude · a draft for Cameron

Screenshots from `tools/office_screen_shots.tscn` (`venue:campaign`, `venue:campaignstaff`, `venue:campaignvan`, `popup:moment`, `popup:poll`, `popup:selection`, `venue:banner_<phase>`), the player Kenshin Sako (Frontier Party, green). `COP_SKIN=samurai|gladiator` picks the skin and `COP_PC=PC02` and so on the protagonist. The reference shots are in the P22 package (`previews/shots`).

## Summary

| Question | Answer |
|---|---|
| Are all 20 states drawn? | Yes: ten screens in each skin, `samurai_*.png` and `gladiator_*.png`. |
| Is the accent the party colour? | Yes, as you answered: the accent family (accent, selected tab, bar fill, card label, stamp, phase rule) takes the player's party colour. The phase bar, the buttons on the banners and the card ground stay the skin's own. |
| Do the nobori take three party colours? | Yes: the player's party, Keizaijiyuutou and the Yezo Heritage Party (a spare party instead of a repeat). The sun stays vermilion. Gladiator's arena banners have no nobori. |

## Differences I kept from the mock-ups

| Part | Mock-up | Built | Why |
|---|---|---|---|
| Card label emblem | Inside the label chip | Beside the chip | The pop-up card draws its own tag; the emblem is added before it |
| Action cards | Tags (hours, "Mustering x1.5") as chips; the bottom bar "Back to District / Mailings" | Cost and gain lines as before; the frame's own Back | The actions' words are Text rows P20B already wrote; the bottom bar is a layout change to the frame for every screen |
| Stat tiles | A caption under each bar ("Of 3,000 · fades 5% a week") | Heading, value and bar | The captions are new sentences; they can be added as Text rows |
| Theme overlays | Two saved `.tres` themes | None: the skin is read from the UI Styles rows while a screen is built (`UiStyle.begin_scope`) and the display face is set on the titles | Nothing else in the game reads the project theme for these screens, so no second theme is merged over it |
| Gladiator capitals | Tracked 0.12 to 0.14 em on every heading | Capitals everywhere; tracking only on the display face (titles and headings that use it) | Godot's font variation spaces the whole face |
| Chips, tabs, buttons | Square, in the skin colours | The same Woodblock shapes in the skin colours | The skin is Woodblock with other tokens, as the spec says |
