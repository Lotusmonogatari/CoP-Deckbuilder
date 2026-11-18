# Brand B, "The Assembly Seal": icon and splash files

Built from `design/brand/source/*.svg` by `tools/brand/export_brand.gd` (run with a display:
`xvfb-run -a .tools/godot --path . -s tools/brand/export_brand.gd`). Do not edit these PNGs by hand. The check is
`tests/test_brand_assets.gd`. The seal always tilts -4 degrees and is never redrawn or recoloured. The icon has no text.

| File | Size | Source | Used for |
|---|---|---|---|
| `icon_1024.png` | 1024 x 1024, no alpha | `icon_b.svg` | Godot project icon (`config/icon`), iOS `icons/icon_1024x1024` and `app_store_1024x1024` |
| `icon_512.png` | 512 x 512, no alpha | `icon_b.svg` | Google Play listing icon |
| `icon_192.png` | 192 x 192 | `icon_b.svg` | Android `launcher_icons/main_192x192` |
| `icon_180.png` | 180 x 180 | `icon_b.svg` | iOS `icons/iphone_180x180` |
| `icon_167.png` | 167 x 167 | `icon_b.svg` | iOS `icons/ipad_167x167` |
| `icon_152.png` | 152 x 152 | `icon_b.svg` | iOS `icons/ipad_152x152` |
| `icon_120.png` | 120 x 120 | `icon_b.svg` | iOS `icons/iphone_120x120` and `spotlight_120x120` |
| `icon_114.png` | 114 x 114 | `icon_b.svg` | iOS `icons/notification_114x114` |
| `icon_87.png` | 87 x 87 | `icon_b.svg` | iOS `icons/settings_87x87` |
| `icon_80.png` | 80 x 80 | `icon_b.svg` | iOS `icons/spotlight_80x80` |
| `icon_76.png` | 76 x 76 | `icon_b.svg` | iOS `icons/notification_76x76` |
| `icon_60.png` | 60 x 60 | `icon_b.svg` | iOS `icons/notification_60x60` |
| `icon_58.png` | 58 x 58 | `icon_b.svg` | iOS `icons/settings_58x58` |
| `icon_40.png` | 40 x 40 | `icon_b.svg` | iOS `icons/notification_40x40` |
| `adaptive_foreground_432.png` | 432 x 432, transparent | `icon_b_adaptive_foreground.svg` | Android `launcher_icons/adaptive_foreground_432x432` (the seal, inside the 66% safe circle) |
| `adaptive_background_432.png` | 432 x 432 | `icon_b_adaptive_background.svg` | Android `launcher_icons/adaptive_background_432x432` (bands, washi, waves, no seal) |
| `adaptive_monochrome_432.png` | 432 x 432, transparent | `icon_b_monochrome.svg` | Android 13 themed icons: `launcher_icons/adaptive_monochrome_432x432` |
| `splash_seal.png` | 600 x 600 | `mark_b.svg` | Boot splash image (`boot_splash/image`), on the washi ground colour |
| `feature_graphic_1024x500.png` | 1024 x 500, no alpha | composed in the script from `mark_b.svg`, `waves_b.svg`, the `TITLE` painting and the title text | Google Play feature graphic |

## Godot 4.5.1's export options (read from the engine, not guessed)

- **Android:** `launcher_icons/main_192x192`, `adaptive_foreground_432x432`, `adaptive_background_432x432`,
  `adaptive_monochrome_432x432`.
- **iOS:** `icons/icon_1024x1024` (also `_dark` and `_tinted`, not made: no dark or tinted art exists),
  `app_store_1024x1024`, `iphone_120x120`, `iphone_180x180`, `ipad_152x152`, `ipad_167x167`, `spotlight_80x80`,
  `spotlight_120x120`, `settings_58x58`, `settings_87x87`, `notification_40x40`, `notification_60x60`,
  `notification_76x76`, `notification_114x114`. (`ios_128x128`, `ios_136x136` and `ios_192x192` are options for
  other targets and are not used.)

## Export presets

`tools/brand/export_presets.example.cfg` holds the Android and iOS presets with every icon wired and the Android
short name set to **Coliseum**. Copy it to the project root as `export_presets.cfg` (the repo ignores that name on
purpose). Placeholders to fill in before a real build: the package name and bundle identifier
(`com.example.coliseumofparliament`), signing, and the Apple team. iOS shows the project name
(`application/config/name`, "Coliseum of Parliament") under the icon: Godot 4.5.1 has no separate iOS display-name
option, so a short iOS name would need a localization entry.

## Project settings

`project.godot` sets `config/icon`, `config/version` ("0.1.0", a placeholder number) and the boot splash
(`boot_splash/bg_color` = washi, `image` = `splash_seal.png`, `fullsize` false, `show_image` true).
