# Actions taken after the audit (2026-11-10)

Cameron approved batches 3, 6, 10 and, from batch 11, the scene-change helper only. Batch 9 was skipped at his choice. Everything below is on the working branch.

| Finding | Action | Result |
|---|---|---|
| A-01, A-02, S-03 | Import settings only (source PNGs untouched): backgrounds, card art, card frames and characters now import as Lossy (quality 0.85 to 0.9) with a size limit (backgrounds 1440, card art 1024, frames 1200, characters 1600 on the long side). Icons stay lossless. | Imported texture data fell from 175 MB to 27 MB. Largest card picture in memory is now about 3.2 MB (was 4.6); frames about 4 MB (was 12.6). Checked by eye in a battle screenshot at 1080x2340; no visible loss. **Not yet checked on a phone or in an actual AAB.** |
| R-02, A-08 | `assets/backgrounds/ST22.png` removed; ST22's Background ID now borrows ST08. | Done. |
| A-07 | Not done: subsetting the Japanese font needs the `fonttools` Python package, which is not installed. I did not add a dependency without asking. | Open. |
| U-05 | Stage info panel (Details) now has three buttons: Abandon Level, Settings, How to Play. Abandon asks first, then the stage is lost with its ordinary penalties and the level ends (`BattleEngine.forfeit()`, `LevelRunner.abandoned`). Settings are shared with the Office (`SettingsRows.gd`). | Done for battle stages. Office Hours, visits, trades and the Floor Vote have no stage info panel, so they have no menu yet. The Android back button (C-01) is still not wired. |
| U-06 | `SceneChange.to()` is now the one way to change screen (21 call sites), with a short fade to black (Balance `Scene Change: Fade Seconds`, 0.12; 0 turns it off). A second call during a fade is ignored. | Done. The fade is off in tests and click drivers so their timing is unchanged; I ran it once by hand (fade layer appears, the Office loads, the layer is removed). |
| C-08 | Withdrawn: the code was already correct. | No change. |
| C-09 | `Layout` works out the party name only when the protagonist changes. | Done. |
| C-10 | Not done: replacing the test addon version is a dependency change. | Open; harmless noise. |
| C-11 | The data report and the "no sound file" line print only in debug builds. | Done. |
| C-12, R-06 | The one script and 23 functions used only by tests are listed in `design/CLEANUP_CANDIDATES.md` for Cameron's review. Nothing deleted. | Listed. |
| R-03 | One gold-line helper (`UiKit.gold_rule(thickness)`); the Office uses it. | Done. |
| R-04 | The Office scene path comes from `StageRouting.OFFICE_SCENE` everywhere. | Done. |
| Y-01 | Not done: moving settings into their own autoload was tied to adding audio settings (batch 9, skipped). | Open. |
