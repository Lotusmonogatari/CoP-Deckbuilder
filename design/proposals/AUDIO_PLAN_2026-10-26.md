# Plan: music, sound effects and volume settings (2026-10-26)

## Executive summary
| | |
|---|---|
| Where we are | The wiring for sound already exists and ships silent: an `Audio` autoload, three buses (Music, Effects, Speech), and `data/sounds.json` naming 20 moments. `assets/audio/` is empty. There are **no volume settings**, **no interface sounds** (button click, confirm, cancel, stage change), and the Speech bus is not yet used for the cue banner. |
| What you asked for | Install music and sound effects, a volume setting, and **separate volume** for: stage change, clicks/confirmation, cancel/back, cues, and music. |
| Proposal | Six buses and a **Sound** page in the Administration menu with seven sliders (Master, Music, Cues, Battle effects, Stage change, Click and confirm, Cancel and back). Interface sounds are attached automatically to every button, so no screen needs editing. Defaults live in the data files, so the numbers stay yours. |
| Size | About 4 steps. Step 1 (volumes, Sound page, interface hooks) is roughly 200 lines of code plus tests, and the game stays silent until files arrive. |
| Needs from you | The six decisions at the end, and the audio files themselves (or a decision on where to source them). |

## 1. What exists today
| Piece | State |
|---|---|
| `Audio.gd` autoload | Listens to EventBus (card played, gaffe, turn, meta up/down, XP, win/loss) and plays whatever `sounds.json` names. Music by name (`music_title`, `music_office`, `music_battle`), looped, one at a time. Cosmetic music packages (CP01, CP02) already substitute their own tracks. |
| `sounds.json` | 20 entries, every `file` blank, so everything is a no-op. A speech table keyed by protagonist and card cue (`PC01` / `C01_1`...) is also blank. |
| Buses | `Music`, `Effects`, `Speech`, all full volume. `Audio.set_volume()` and `set_muted()` exist but nothing calls them. |
| Settings | Only the text size is remembered (`Layout`, one small settings file). |
| Interface sounds | None. Buttons are silent; scene changes are silent. |

## 2. The sounds, grouped the way you mix them
| Group (slider) | What belongs in it | Bus |
|---|---|---|
| **Music** | Title, Office, battle, win and loss stingers, cosmetic packages | Music |
| **Cues** | The spoken-line cue banner: a short sound when a cue slides in, and recorded voice lines later (the existing `speech` table) | Cues (today's Speech bus, renamed) |
| **Battle effects** | Card played, useless card, turn start/end, intent revealed, gaffe, final gaffe, standing up/down, XP gained/spent | Effects |
| **Stage change** | One sound when the game moves from one room to the next (and Office to level) | Stage change |
| **Click and confirm** | Every ordinary button press and every confirming button (Start, Continue, Play, Learn it, Accept) | Click |
| **Cancel and back** | Back, Pass, Decline, Abandon, Close, and any white-outlined cancel button | Cancel |
| Master | Everything | Master |

Why separate buses: each slider then maps to exactly one bus, so there is no special-case code, and a later "duck the music under cues" is one line.

## 3. How the player controls it
- A new **Sound** page next to Text size in the **Administration** menu: seven sliders (0 to 100 in steps of 10), a Mute button for each, and a **Test** tap that plays a sample of that group so the level can be judged.
- Remembered between runs in the same settings file the text size uses.
- Every sentence on the page is a Text-tab row, as everywhere else.
- Defaults (how loud each group starts) live in `data/rules.json`, so you can retune them without code; first draft: Master 80, Music 60, Cues 90, Battle effects 70, Stage change 70, Click and confirm 60, Cancel and back 60.

## 4. How interface sounds get attached without touching every screen
- A small helper listens to the scene tree and gives every button a "pressed" sound the moment it appears. A button is **Cancel** if it uses the white cancel style the game already has; **Confirm** if it is a primary action; otherwise **Click**. The three kinds map to three entries in `sounds.json`.
- **Stage change** is played from the one place all rooms already pass through (`StageRouting.go_to_next_stage()`), so a room change always makes the sound exactly once.
- `sounds.json` gains `ui_click`, `ui_confirm`, `ui_cancel`, `stage_change`, `cue_in` entries and a per-entry `trim` (a small volume offset, so one loud file can be tamed without re-editing it).

## 5. Files and format
| Topic | Recommendation |
|---|---|
| Format | `.ogg` (Vorbis). Effects short (under 2 seconds), music looped with clean loop points. |
| Loudness | Aim all effects at about the same loudness (around -16 LUFS), music about 4 dB quieter than effects, so the sliders start from a sane mix. |
| Where | `assets/audio/` with folders `music/`, `effects/`, `ui/`, `cues/`; the filename goes in `sounds.json`, nothing in scripts. |
| Phones | Sound must not play when the app is in the background; resume cleanly after a call; respect the phone's silent switch where the platform expects it. Testing on a real iOS and Android device is part of the existing M6 milestone. |
| Licensing | Keep a `design/AUDIO_CREDITS.md` listing source and licence for every file. Store releases need it. |

## 6. Steps
| Step | What | Result |
|---|---|---|
| 1 | Four new buses, volume math (slider to decibels, mute), the Sound page, settings saved, interface-sound helper, stage-change hook, defaults in `rules.json`, tests | Everything is wired and testable; still silent |
| 2 | Placeholder tones (generated, plainly labeled) for each group so you can hear the sliders working before real files exist | You can judge the mix on a phone |
| 3 | Real files dropped in against `sounds.json` keys; loudness pass; credits file | The game is audible |
| 4 | Cues and music polish: duck music a little under a cue, crossfade between rooms, pick a track per room family | Finished mix |
| 5 | Phone checks (interruptions, silent switch, Bluetooth delay) | Ready for the M6 export test |

## 7. Tests and checks
- Slider-to-decibel and mute math (pure rules code, no UI).
- Settings round trip: save, restart, same values.
- A button of each kind plays the right entry; a missing file is still silently ignored.
- A click test in `tools/verify.sh` that opens the Sound page and moves a slider.
- Headless runs use Godot's dummy audio driver, so the verify gate still runs on a machine with no sound card.

## 8. Decisions for you
| # | Question | My recommendation |
|---|---|---|
| 1 | Is the **Cues** slider for the banner sound plus recorded voice lines (both on one bus), or two separate sliders? | One bus and one slider for now. Split it only if you record voice. |
| 2 | Keep **Battle effects** (card, gaffe, turn...) as its own slider, or fold it into Click and confirm? | Keep it; it is the loudest group in play. |
| 3 | Seven sliders, or fewer (for example one "Interface" slider for click, confirm, cancel and stage change)? | Seven as you described; hide advanced ones later if it feels crowded. |
| 4 | Default levels above? | Use them as a starting point and retune by ear on a phone. |
| 5 | Where do the sounds come from: commissioned, licensed library, or generated placeholders for now? | Placeholders now (step 2), licensed or commissioned for release. |
| 6 | Phone vibration (haptics) with confirm and cancel taps? | Not now; add after sounds are chosen. |
