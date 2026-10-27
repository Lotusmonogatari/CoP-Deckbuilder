# Audio commissioning brief: Coliseum of Parliament (2026-10-26)

For the composer / sound designer. Game: a portrait mobile card battler about rhetoric in a parliament (Yezo, a fictional Japan-like nation). Tone: dry, witty, civic, not militaristic. Think a newsroom theme crossed with light jazz and taiko accents.

## Summary
| Item | Spec |
|---|---|
| Delivery format | .ogg (Vorbis, quality 6, 44.1 kHz, stereo). Mono is fine for short effects. |
| Loudness | Effects about -16 LUFS integrated, true peak -1 dBTP. Music about -20 LUFS (4 dB under effects). Stingers -18 LUFS. |
| Music loops | Seamless loop points, no tail fade; 60 to 120 seconds each. |
| Effects length | Under 1.5 s (interface sounds under 0.4 s). |
| File names | Exactly the keys below, e.g. `card_played.ogg`. |
| Budget | Whole set under 25 MB. |
| Credits | A `AUDIO_CREDITS.md` listing author and licence per file. We need full rights for iOS/Android release. |

## Music (looped unless noted)
| Key | Moment |
|---|---|
| music_title | Title / New Game screen |
| music_office | The Office, between levels |
| music_battle | Any stage (one general track; variants welcome) |
| battle_won | Stinger, 3 to 5 s, not looped |
| battle_lost | Stinger, 3 to 5 s, not looped |
| music_office_pop / music_battle_pop | Alternate set for the "Neon Ambition" package (synth-pop) |
| music_office_shamisen / music_battle_shamisen | Alternate set for the "Quiet Chamber" package (gentle shamisen) |

## Battle effects
| Key | Moment |
|---|---|
| card_played | A card leaves the hand (heard most; must not tire) |
| card_useless | A card the room ignores (soft, deflated) |
| turn_started | Player's turn opens |
| turn_ended | End turn pressed |
| intent_revealed | Opponent's next move shown |
| gaffe | Gaffe meter rises (cringe, not harsh) |
| gaffe_final | One more gaffe ends the stage (tension) |
| meta_up / meta_down | A standing rose / fell |
| xp_gained / xp_spent | XP earned / spent |

## Interface (new)
| Key | Moment |
|---|---|
| ui_click | Ordinary button |
| ui_confirm | Confirming button (Start, Continue, Play) |
| ui_cancel | Back, Close, Decline |
| stage_change | Moving from one room to the next |
| cue_in | A spoken-line banner slides in |

## Rules of thumb
- Players hear card_played and ui_click hundreds of times: keep them quiet, short and slightly varied (2 to 3 variants each as `_a`, `_b`, `_c` is welcome).
- Nothing should startle on headphones. No clipping.
- No voice, no lyrics, no sampled national anthems or real political jingles.
- Players can mute any group, so music must also work with effects only.

## How it is used
We drop each file in `assets/audio/` and write its name against the key in `data/sounds.json`. No code changes. Volume sliders: Master, Music, Cues, Effects, Interface; starting volume is 50%.
