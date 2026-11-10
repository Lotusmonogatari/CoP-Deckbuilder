# Phase 1: Inventory

Audit date: 2026-11-09. Commit audited: `b610d13` (branch `claude/new-session-klhgm8`, same as `main`). Read-only; nothing outside `audit/` was written.

## Engine and settings (`project.godot`)

| Setting | Value | Evidence |
|---|---|---|
| Godot version | 4.5 (features line); the local and CI binary is 4.5.1-stable | `project.godot:17` `config/features=PackedStringArray("4.5", "GL Compatibility")`; `.github/workflows/verify.yml` `GODOT_VERSION: 4.5.1-stable` |
| Renderer | GL Compatibility on desktop and mobile | `project.godot` `[rendering]` `renderer/rendering_method="gl_compatibility"` and `.mobile` the same |
| Language | GDScript only. No `.cs`, no `.csproj`, no GDExtension | file scan: 448 `.gd`, 0 `.cs`, 0 `.gdextension` |
| Main scene | `res://scenes/menus/IntroScreen.tscn` | `project.godot:16` |
| Viewport | 1080 x 2340, stretch `canvas_items`, aspect `expand`, orientation 1 (portrait) | `project.godot` `[display]` |
| Desktop window override | 440 x 953 | `project.godot` `window/size/window_width_override=440` |
| Back button | `config/quit_on_go_back=false` | `project.godot:18` |
| Theme | one project theme, `res://theme/cop_theme.tres` | `project.godot` `[gui]` |
| Sensors | accelerometer and gravity enabled | `project.godot` `[input_devices]` |
| Texture import | `textures/vram_compression/import_etc2_astc=true` | `project.godot` `[rendering]` |
| Input map | **none defined**: `project.godot` has no `[input]` section, so only Godot's built-in `ui_*` actions exist | `grep "^\[input\]" project.godot` returns nothing |
| Export presets | **none**: `export_presets.cfg` does not exist and is listed in `.gitignore` | `ls export_presets.cfg` fails; `.gitignore` line `export_presets.cfg` |
| Version, icon, boot splash | not set: no `config/version`, no `config/icon`, no `boot_splash/*` keys | `project.godot` `[application]` holds only name, description, main scene, features, quit_on_go_back |

## Autoloads (load order) and what each depends on

```
DataDB        -> (Text x1, GameState x1, Audio x1: late calls only)
EventBus      -> nothing
Text          -> DataDB
GameState     -> DataDB (260 refs), Text (164), SaveManager (5), EventBus (3), Audio (1)
SaveManager   -> GameState (10), Text, Layout
Audio         -> EventBus (8), DataDB (3), GameState (1)
Layout        -> DataDB (5)
```

Counts are `Name.` references inside each autoload script. `GameState.gd` is 4,822 lines and is the hub: it owns the run, the week, the shop, staff, promises, events and bills.

## Scenes (10 game scenes; 77 `.tscn` in the repo)

```
IntroScreen (main)
  └─> OfficeScreen  <────────────────────────────────────────┐
        ├─> LevelIntroScreen ─> [stage scene]                │
        └─> [stage scene] via StageRouting.scene_for()       │
              BattleScreen | VisitorScreen | FloorVoteScreen │
              VisitScreen | TradeScreen                      │
                └─> StageTransitionScreen ─> next stage ─────┘ (or back to Office)
BootCheck (tools and CI only)
```

All scene changes use `get_tree().change_scene_to_file()` (21 call sites; `scripts/ui/StageRouting.gd:58,65` is the shared router).

| Scene | Nodes | Script | Top-level children |
|---|---|---|---|
| `scenes/menus/IntroScreen.tscn` | 9 | `IntroScreen.gd` | Background, Scrim, Safe |
| `scenes/menus/BootCheck.tscn` | 7 | `BootCheck.gd` | Background, Safe |
| `scenes/office_hours/OfficeScreen.tscn` | 32 | `OfficeScreen.gd` (3,400 lines) | Background, BackgroundScrim, BackgroundPanel, Safe, Ticker, 8 Overlay panels |
| `scenes/office_hours/LevelIntroScreen.tscn` | 17 | `LevelIntroScreen.gd` | Background, BackgroundScrim, Safe |
| `scenes/office_hours/StageTransitionScreen.tscn` | 11 | `StageTransitionScreen.gd` | Background, BackgroundScrim, Safe |
| `scenes/battle/BattleScreen.tscn` | 62 | `BattleScreen.gd` (1,300 lines) | Background, BackgroundScrim, BackgroundPanel, Safe, DetailsPanel, CardZoom, OutcomePanel, Notice |
| `scenes/office_hours/VisitorScreen.tscn` | 34 | `VisitorScreen.gd` | Background, BackgroundScrim, BackgroundPanel, Safe, OutcomePanel, Notice |
| `scenes/office_hours/VisitScreen.tscn` | 34 | `VisitScreen.gd` | same shape as VisitorScreen |
| `scenes/office_hours/TradeScreen.tscn` | 34 | `TradeScreen.gd` | same shape as VisitorScreen |
| `scenes/office_hours/FloorVoteScreen.tscn` | 67 | `FloorVoteScreen.gd` | Background, BackgroundScrim, BackgroundPanel, Safe, OutcomePanel, Notice |

No scene instances another scene (0 `instance=ExtResource` in the 10 game scenes); shared pieces are built in code.

The other 67 `.tscn` files are test and tool runners: 32 under `tests/` (mostly `tests/interaction/`), 12 under `tools/`, the rest inside `addons/gut/`.

## Scripts

| Folder | `.gd` files | Lines |
|---|---|---|
| `scripts/autoload/` | 7 | 7,544 |
| `scripts/rules/` (pure rules) | 77 | 11,223 |
| `scripts/ui/` | 50 | 13,887 |
| `scripts/` (top level) | 3 | 1,300 |
| **Game code total** | **137** | **33,954** |
| `tests/` | 208 | not counted |

Largest: `GameState.gd` 4,822; `OfficeScreen.gd` 3,400; `DataDB.gd` 1,871; `BattleEngine.gd` 1,715; `BattleScreen.gd` 1,300; `BattleSetup.gd` 850; `FloorVoteScreen.gd` 825.

## Resources, data and addons

| Item | Detail |
|---|---|
| `.tres` | 4 in the repo: `theme/cop_theme.tres`, `audio/default_bus_layout.tres` (Music, Effects, Speech buses), 2 inside `addons/gut` |
| Shaders | 1: `assets/shaders/soft_edge.gdshader` |
| Data | `data/`: 63 files, 11 MB of JSON (largest are the cue tables), loaded by `DataDB` at start |
| Addons | 1: `addons/gut` (GUT 9.6.1, test framework, MIT `LICENSE.md` present), 257 files, 3.2 MB |
| SDKs | none: no ads, analytics, billing, crash reporting or networking addon |
| CI | `.github/workflows/verify.yml` runs `tools/verify.sh` on every push |

## Assets by type

| Folder | Files | Size on disk | Notes |
|---|---|---|---|
| `assets/cards` | 83 PNG | 91 MB | 66 at 1232x928, 10 at 1500x2100, 4 at 1024x1024 |
| `assets/backgrounds` | 52 PNG | 86 MB | 25 at 1024x1024, 14 at 1232x928, 9 at 1344x896; largest `ST23.png` 2912x1632 (4.8 MB) |
| `assets/characters` | 92 PNG | 54 MB | portrait cut-outs, mostly about 816x1456 |
| `assets/icons` | 61 PNG | 0.9 MB | all 256x256 |
| `assets/fonts` | 3 TTF | 9.4 MB | `NotoSansJP[wght].ttf` is 9.6 MB of that |
| `assets/audio` | 0 audio files | 8 KB | a README only |
| `assets/howto` | 0 images | 8 KB | a README only |
| **Total** | **288 PNG, 3 TTF** | **240 MB** | every PNG imports with `compress/mode=0` (Lossless), mipmaps off |

Repo size: `.git` 553 MB; `design/` 26 MB (workbook and working papers); `tools/` 3.9 MB.

## Input

- No custom actions. Code reads raw events: `InputEventScreenTouch`, `InputEventMouseButton`, `InputEventKey` for Escape, and the accelerometer (checked in Phase 2 and 6).
- No `InputEventJoypad*` handling anywhere in `scripts/` (verified by grep in Phase 6).

## Export presets

None exist. There is no Android, iOS, Linux/Steam or Windows preset, no keystore reference, no package name, no icons and no version code. This is recorded as a finding in Phase 6.
