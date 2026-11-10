# Phase 6: Input and feel

Code-reading only. **I cannot judge "feel" from code.** Where I write about responsiveness I describe what the code does and flag it for a playtest. Nothing was run on a device; every device statement is unverified.

## Executive summary

| Area | What the code does | Flag |
|---|---|---|
| Input model | Touch is handled as emulated mouse (no `emulate_mouse_from_touch` override in `project.godot`, so the Godot default applies). `CardView._gui_input` reads `InputEventMouseButton` and `InputEventMouseMotion` | Unverified on a device |
| Card play | Drag up 30 px to lift (`LIFT_START`), release past 220 px to play (`PLAY_LIFT`), or tap to open the zoom (`CardView.gd:59-60, 501-556`) | Playtest: is 220 px a long throw on a small phone? |
| Buffering, grace windows, hit pause, aim assist, dead zones | None exist, and none fit a turn-based game | n/a |
| Latency | Handlers are synchronous; no frame waits found in card play | Playtest on a low-end phone |
| Haptics | **None.** No `vibrate` call anywhere in `scripts/` | F-02 |
| Sound | **None.** The audio layer is built and silent by design (`Audio.gd:9`, "IT SHIPS SILENT") | F-01 |
| Animation / shake | Cue banner slides, flashes and shakes (`CueBanner.gd:175-279`); a scene fade exists (`SceneChange.gd:38`); no card-play or bar-change tween found in the bar scripts | F-07 |
| Controller / keyboard | No focus navigation (project audit S-08, U-04) | Known |

Findings: 0 Blocker, 1 High, 2 Medium, 4 Low.

## Per-mechanic feedback

What the player gets when each action happens. "Seen" means a visual change I found in code; "none found" means I searched for a tween, sound, flash or haptic call and found none.

| Mechanic | Visual | Sound | Haptic | Notes |
|---|---|---|---|---|
| Play a card | Card lifts while dragged and tints at the play height (`READY_TINT`, `CardView.gd:521-523`) | none (silent) | none | Dropping early puts the card back (`_drop`, L541) |
| Support bar moves | Bars use the cue band's slant and gold edges; a per-change tween was not found | none | none | Unverified; may update instantly |
| Gaffe meter fills | Counter label; turns red when one more gaffe would end the stage (`BattleScreen.gd:582`) | none (hook exists) | none | See F-03 |
| Opponent intent revealed | Banner (`CueBanner`) | none | none | Banner slide in and out |
| Stage won or lost | Result panel (`%OutcomeClose`) | none | none | Loss is only applied on Close (G-01) |
| Buy item / spend XP | `Layout.flash` toast (`SaveManager.gd:57`) | none | none | |
| Save | "Saved" toast on announced saves; **no toast on failure** (C-03) | none | none | |
| Scene change | Fade in `SceneChange.gd:38` | none | none | |

## Touch-specific

| Check | Result | Evidence |
|---|---|---|
| Touch-target size | 83 % to 98 % of buttons per screen under Apple's 44 pt guideline (known, deliberate) | Project audit U-01 |
| Accidental play | Playing needs a 220 px upward drag; a tap opens zoom, not play. Good guard | `CardView.gd:20, 59-60` |
| Accidental double tap | Stage Continue is disabled for 2 s (`stage_continue_delay_seconds` = 2, `StageTransitionScreen.gd:242-250`); a mash test exists for the rest | Balance row; `tests/interaction/mash_driver.gd` (not re-run) |
| Drag vs scroll | The hand scrolls horizontally in a `ScrollContainer`; a vertical lift must beat a horizontal move to start (`up > absf(dx)`, L517). Diagonal drags are the risk | `CardView.gd:517` |
| Multi-touch | Mouse emulation tracks one pointer, so a second finger is ignored (unverified) | Godot default |
| Finger covers the target | Cards are lifted by 30 px before a decision; the lifted card rises above the hand strip (`_lift`, L531-541) | `CardView.gd` |
| Back button | Probably dead on Android (C-01) | Project audit |
| Safe areas / notch | `Layout` handles safe areas; checked only in desktop screenshots | CLAUDE.md |
| Text size | A text-size setting exists; small text is 9 to 10 dp (U-02) | Project audit |

## Findings

Format: ID | Severity | Mechanic | Location | What's wrong | Evidence | Suggested fix | Effort | Confidence

| ID | Severity | Mechanic | Location | What's wrong | Evidence | Suggested fix | Effort | Confidence |
|---|---|---|---|---|---|---|---|---|
| F-01 | High | Audio feedback | `scripts/autoload/Audio.gd:9, 206`; `data/sounds.json` | No sound exists, so no action has audible feedback. For a card battler this is where most of the "weight" of a card play comes from. Known (A-04) and planned (`design/proposals/AUDIO_PLAN_2026-10-26.md`) | "IT SHIPS SILENT. There are no sound files yet." | Add the first set: card lift, card played, gaffe, win, loss | L | High |
| F-02 | Medium | Haptics | `scripts/` | No haptic call anywhere. Mobile players expect a tap on a card play or a gaffe. Optional, but cheap | `grep -rn "vibrate" scripts/` returns nothing | Add `Input.vibrate_handheld(20)` behind a setting for play, gaffe and loss | S | High |
| F-03 | Low | Gaffe warning | `scripts/ui/BattleScreen.gd:577-596` | The gaffe counter turns red only when one more gaffe would end the stage (`engine.gaffe_is_critical()`), a deliberate choice so the warning is not diluted. It is a label colour and weight change only; the sound hook (`EventBus.gaffe_changed`) fires but there is no sound. So the only warning is one small label changing colour one gaffe before a loss that ends the stage | `_refresh_gaffe` code and comments | Playtest: does a first-time player notice the red label in time? Consider a banner or pulse on the critical edge | S | Medium |
| F-04 | Medium | Card drag threshold | `scripts/ui/CardView.gd:59-60` | `LIFT_START` 30 and `PLAY_LIFT` 220 are fixed pixel values in the script, not Balance rows and not scaled to density or screen size. On a 1080 x 2340 base that is about 9 % of screen height, but a phone with a different aspect ratio changes the physical distance | Constants in code (also T-series in `02-tuning.md`; CLAUDE.md says no design numbers in scripts) | Move to Balance rows; consider scaling by the viewport | S | Medium |
| F-05 | Low | Diagonal drags | `CardView.gd:517` | A lift starts only when upward motion beats sideways motion, and the hand scrolls sideways, so a diagonal flick is ambiguous. Not necessarily bad | Code | Playtest with thumbs, not a mouse | S | Low |
| F-06 | Low | Controller parity | project-wide | No controller or keyboard play at all (S-08). `ui_cancel` is handled in two places (`BattleScreen.gd:1284`, `Overlay.gd:205`) | Known | Decide per Steam plan | L | High |
| F-07 | Low | Hit pause / shake | `CueBanner.gd:277-279` | Only the cue banner shakes; nothing else does. Whether the game needs more is a feel question | Code | Playtest | S | Low |

## What only a playtest can answer

| Question | What to watch |
|---|---|
| Is the 220 px throw comfortable one-handed? | Players dropping cards short and re-lifting |
| Does a card play feel heavy enough with no sound or haptic? | Hesitation, "did it work?" taps |
| Does the gaffe loss surprise players? | Reactions at the moment of loss |
| Are button taps missed because targets are small? | Repeated taps on the same button |
| Is the 2-second Continue hold irritating or protective? | Players tapping a disabled button |
| Does a first lift on a diagonal drag scroll the hand by accident? | Hand moving when a lift was intended |
