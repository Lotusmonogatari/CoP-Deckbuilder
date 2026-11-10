# Project audit: summary

Coliseum of Parliament, Godot 4.5.1, GL Compatibility, GDScript. Audited 2026-11-09 to 2026-11-10 at commit `b610d13`. Read-only: nothing outside `audit/` was changed.

## One-page overview

**The game logic is in good shape. The path to a store is not started.**

The code is well above average for a project at this stage: 1,803 tests pass, every function is typed, there are no TODOs, no dead scripts, no orphaned signals, and saving is written carefully (temp file, verify, backup, rename). Nothing I found is a crash waiting to happen in normal play.

What stands between this project and a shippable build is everything around the code:

1. **No build exists.** There are no export presets, no icon, no version, no signing, and the game has never run on a phone. Every device-related statement in this audit is therefore unverified.
2. **The art is too heavy.** 240 MB of lossless PNGs, larger than phones display them, held uncompressed in memory. This likely breaks Google Play's size limit and risks out-of-memory closes on cheaper phones.
3. **Store rules have moved.** Google Play now requires target API 36 and 16 KB page support; Apple requires Xcode 26. Godot 4.5.1 may need preset changes or an engine update to pass. I could not confirm this without a build.
4. **Steam Deck is a different product.** The game is portrait and touch-only. On a Deck it would be a narrow column with text near or under Valve's minimum size and no controller support. This needs a decision before any work.
5. **Content gaps are large.** 3 of 131 opponents and 27 of 166 visitors have art; there is no audio at all.
6. **Phone usability is unproven.** Most buttons are under both platforms' recommended touch size (a known, deliberate choice), small text is about 9 to 10 dp, the Android back button probably does nothing, and progress inside a battle is lost if the OS closes the app.

## Count by severity

| Severity | Count |
|---|---|
| Blocker | 5 |
| High | 10 |
| Medium | 19 |
| Low | 22 |
| **Total** | **56** |

Three pairs overlap and are counted once each in their own phase: R-06 and C-12, A-08 and R-02, U-04 and S-08.

## All findings, by severity

Full evidence and fixes are in the phase files. Effort: S under a day, M a few days, L a week or more.

| ID | Severity | Area | What's wrong | Effort | Confidence | File |
|---|---|---|---|---|---|---|
| S-01 | Blocker | Export | No export presets, package ID, version or signing; no build has ever been made | M | High | 06 |
| S-02 | Blocker | Store listing | No app icon or boot splash; builds would carry Godot's defaults | S | High | 06 |
| S-03 | Blocker | Download size | About 240 MB of lossless art is likely over Google Play's 200 MB base limit (unverified, no AAB built) | M | Medium | 06 |
| S-04 | Blocker | Android target | Play requires target API 36 and 16 KB pages; Godot 4.5's template is reported to target 35 (unverified) | M | Medium | 06 |
| S-05 | Blocker | Apple toolchain | Xcode 26 and iOS 26 SDK required; no iOS preset; template compatibility unverified | M | Medium | 06 |
| C-01 | High | Lifecycle | Android back button is probably dead (quit-on-back off, no handler) | S | Medium | 02 |
| C-02 | High | Save | Progress inside a stage is lost if the OS closes the app in the background | M | High | 02 |
| A-01 | High | Memory / size | All 288 textures are Lossless: about 4.6 MB of video memory per card picture, 12.6 MB per frame | M | High | 04 |
| A-02 | High | Size | Art is larger than any phone draws it (2912x1632 background, 1500x2100 card frames) | M | High | 04 |
| U-01 | High | Touch targets | 83% to 98% of buttons per screen are under Apple's 44 pt (known; the 144 px fix was reverted by choice) | M | High | 05 |
| U-02 | High | Legibility | Small text is about 9 to 10 dp on phones and under 9 px on Steam Deck | M | High | 05 |
| S-06 | High | Export contents | Default export would ship `design/`, `tests/`, `tools/`, the test addon and the workbook | S | High | 06 |
| S-07 | High | Device testing | Never run on a phone; layout and performance checked only on desktop | M | High | 06 |
| S-08 | High | Steam Deck | No controller or focus navigation at all | L | High | 06 |
| S-09 | High | Steam Deck | Portrait-only layout draws as a narrow column at 1280x800 | L | High | 06 |
| C-03 | Medium | Save | A failed save is silent to the player | S | High | 02 |
| C-04 | Medium | Startup | Data errors at startup are ignored by the real game (only the dev boot check shows them) | S | High | 02 |
| C-05 | Medium | Lifecycle | Six screens call `quit()` when no level is in progress | S | High | 02 |
| C-06 | Medium | Startup | 11 MB of JSON parsed on the main thread before the first frame (device time unverified) | M | Medium | 02 |
| C-07 | Medium | Maintainability | `GameState.gd` (4,822 lines) and `OfficeScreen.gd` (3,400) hold a quarter of the code | L | High | 02 |
| R-01 | Medium | Scenes | Three conversation scenes are 99% identical copies | M | High | 03 |
| R-05 | Medium | Styling | 110 theme overrides, 18 hand-built style boxes, 69 literal colors in UI code | M | High | 03 |
| R-07 | Medium | Repo layout | Non-game folders inside the project with no `.gdignore`; 8 review CSVs imported as translations | S | High | 03 |
| A-03 | Medium | Missing art | 3 of 131 opponents and 27 of 166 visitors have art | L | High | 04 |
| A-04 | Medium | Audio | No audio files exist | L | High | 04 |
| A-05 | Medium | Licensing | No record of how each art set was made (Midjourney prompts are in the design docs) | S | Medium | 04 |
| U-03 | Medium | Styling | Styling bypasses the single theme; small drifts already visible | M | High | 05 |
| U-04 | Medium | Navigation | No keyboard or controller focus navigation (see S-08) | L | High | 05 |
| U-05 | Medium | Navigation | No menu or way out inside a stage (unverified by play) | M | Medium | 05 |
| S-10 | Medium | Privacy | Nothing is collected, but a privacy policy and both data forms are still required | S | High | 06 |
| S-11 | Medium | Lifecycle | Resume, focus loss and (future) audio pause are not handled | S | High | 06 |
| S-12 | Medium | Play account | A personal Play account needs 12 testers for 14 days before release (account type unverified) | S | Medium | 06 |
| S-13 | Medium | Performance | Memory, startup parse and stacked translucent layers are the low-end risks; not measured | S | Medium | 06 |
| S-14 | Medium | Steam | Generative-AI content must be disclosed in Steam's survey | S | Medium | 06 |
| C-08 | Low | Performance | Every picture polls the tilt sensors every frame | S | High | 02 |
| C-09 | Low | Performance | `Layout` rebuilds the party name every frame | S | High | 02 |
| C-10 | Low | Tooling | GUT 9.6.1 targets a newer Godot; four script errors at every test start | S | High | 02 |
| C-11 | Low | Logging | Data report printed in release builds | S | High | 02 |
| C-12 | Low | Dead code | One script and 23 functions used only by tests | S | Medium | 02 |
| C-13 | Low | Save | Rename-over-existing may fail on Windows (unverified) | S | Low | 02 |
| C-14 | Low | Audio | No volume or mute functions or settings | S | High | 02 |
| R-02 | Low | Assets | `ST08.png` and `ST22.png` are the same file | S | High | 03 |
| R-03 | Low | UI code | Two different gold-line helpers | S | High | 03 |
| R-04 | Low | Constants | Office scene path repeated in three files | S | High | 03 |
| R-06 | Low | Dead code | Same as C-12 | S | Medium | 03 |
| R-08 | Low | Repo size | `.git` is 553 MB from binaries | M | Medium | 03 |
| A-06 | Low | Licensing | Font licences fine but GUST text and attribution missing | S | High | 04 |
| A-07 | Low | Size | 9.6 MB Japanese font used for a few accent characters | S | High | 04 |
| A-08 | Low | Duplicate | Same as R-02 | S | High | 04 |
| A-09 | Low | Naming | Consistent; one variant rule (`_RED_`) undocumented | S | Medium | 04 |
| U-06 | Low | Scene changes | Instant cuts, 21 direct call sites, no fade or loading cue | M | High | 05 |
| U-07 | Low | Testing | Aspect tests have no landscape or Deck size | S | High | 05 |
| Y-01 | Low | Structure | `Layout` autoload does five unrelated jobs | S | High | 05 |
| Y-02 | Low | Localization | Own text table; a second language would need work | L | High | 05 |
| S-15 | Low | Versioning | No game version number anywhere | S | High | 06 |
| S-16 | Low | Age rating | Rating questionnaires still to answer | S | Medium | 06 |

## Suggested fix order

Small batches, each approvable on its own. Nothing here has been done.

| Batch | What | Findings | Why now |
|---|---|---|---|
| 1. First Android build | Export presets (Gradle, AAB, target SDK 36), version number, placeholder icon and splash, exclude filters, `.gdignore` files | S-01, S-02, S-04, S-06, S-15, R-07 | Everything else is guesswork until a build runs on a phone. Mostly configuration, about a day. |
| 2. Decide Steam | Choose: landscape layout plus controller, windowed portrait without Deck Verified, or drop Steam from launch | S-08, S-09, U-04, U-07 | A design decision that changes weeks of work. No code until decided. |
| 3. Texture diet | Resize art to display size; lossy or VRAM compression for backgrounds and card art; subset the Japanese font; remove the duplicate | A-01, A-02, A-07, R-02, S-03 | Fixes the size blocker and the main memory risk. Test visual quality on one screen first. |
| 4. Phone test round | Run the build on a low-end Android phone and a notched iPhone; measure startup, memory, frame time; check touch and text sizes | S-07, C-06, S-13, U-01, U-02 | Turns the "unverified" items into facts and decides U-01 and U-02. |
| 5. Lifecycle safety | Back button, mid-stage checkpoint on pause, failed-save notice, no `quit()` fallbacks, data-error screen | C-01, C-02, C-03, C-04, C-05, S-11 | The fixes that prevent lost progress and dead ends on phones. Each is small and testable. |
| 6. Stage menu | A small menu in stages (Settings, How to Play, Leave), wired to the back button | U-05 | Gives the back button somewhere to go. |
| 7. iOS build | Mac with Xcode 26, iOS preset, first TestFlight build | S-05 | Find Apple toolchain problems early. |
| 8. Store paperwork | Privacy policy, data forms, age ratings, credits and AI disclosure, Play closed test if the account is personal | S-10, S-12, S-14, S-16, A-05, A-06 | Mostly writing; the closed test is 14 days of calendar time, so start early. |
| 9. Content | Character art (or a deliberate silhouette style), audio with volume settings | A-03, A-04, C-14 | The largest effort; scope decision first. |
| 10. Tidy-ups | Small performance and cleanliness items | C-08, C-09, C-10, C-11, C-12, R-03, R-04, Y-01 | Low risk, any time. |
| 11. Structure | Shared conversation scene, theme variations, split `GameState` by area, scene-change helper | R-01, R-05, U-03, U-06, C-07 | Maintainability; do alongside feature work, not before launch. |

## What I could not check

- **Anything on a device.** No build exists, so download size, memory, frame rate, startup time, the back button, safe areas on a real notch, and store upload checks (target API, 16 KB, Xcode 26) are all unverified.
- **Godot 4.5.1's exact Android target SDK and iOS/Xcode 26 compatibility.** I found forum reports, not an official statement.
- **gdlint and gdformat.** Not installed; not run.
- **The real-click tests.** Not re-run for the audit (they passed in the last full check on this commit).
- **Art provenance.** I cannot tell from the files which images are AI-generated.
- **Account status.** Play account type, Apple Developer membership, Steamworks access.
- **Windows.** The save-rename behavior (C-13) and any Windows export.
- **Steam Deck rendering.** Computed from the scale factor, not rendered.
- **A full line-by-line read of all 33,954 lines.** I used tests, scans and targeted reading of the save, lifecycle, input, loading and scene-change code; logic bugs inside the rules that the 1,803 tests do not cover could remain.
