# Phase 4: Assets

Finding format:
ID | Severity | Area | Location | What's wrong | Evidence | Suggested fix | Effort | Confidence

## What is there

| Type | Files | Disk | Dimensions | Import |
|---|---|---|---|---|
| Card art and frames (`assets/cards`) | 83 | 91 MB | 66 at 1232x928; 10 frames and backs at 1500x2100; 4 at 1024x1024 | Lossless, no mipmaps |
| Backgrounds (`assets/backgrounds`) | 52 | 86 MB | 25 at 1024x1024; 14 at 1232x928; 9 at 1344x896; one at 2912x1632 | Lossless, no mipmaps |
| Characters (`assets/characters`) | 92 | 54 MB | about 816x1456 portrait cut-outs; tallest 640x1904 | Lossless, no mipmaps |
| Icons (`assets/icons`) | 61 | 0.9 MB | all 256x256 | Lossless, no mipmaps |
| Fonts | 3 | 9.4 MB | Noto Sans JP variable font is 9.6 MB | default |
| Audio | 0 | none | none | none |
| Video / how-to images | 0 | none | none | none |

Every PNG has a `.import` file; none is missing. All 288 use `compress/mode=0` (Lossless).

## Findings

| ID | Severity | Area | Location | What's wrong | Evidence | Suggested fix | Effort | Confidence |
|---|---|---|---|---|---|---|---|---|
| A-01 | High | Size / memory | every `assets/**/*.png.import` | All textures import as Lossless. The art alone is 240 MB on disk, and it sits in video memory uncompressed: about 4.6 MB per card picture (1232x928), 12.6 MB per card frame (1500x2100), 19 MB for `ST23.png`. Loaded all at once it would be about 1,065 MB. A battle shows a background, several portraits, a hand of cards and frames together. This drives both download size (S-03) and the risk of the OS killing the app on phones with 2 to 3 GB of memory. | `compress/mode=0` in all 288 files; sizes computed from PNG headers (width x height x 4 bytes). `project.godot` already has `import_etc2_astc=true`, but no texture uses VRAM compression. **Memory use on a device is unverified.** | For backgrounds and card art, switch the import to "VRAM Compressed" (ASTC/ETC2 on mobile, a quarter or less of the memory) or "Lossy" WebP (much smaller download, same memory). Keep text-bearing frames and icons lossless. Test for visible banding on one screen before applying to all. | M | High |
| A-02 | High | Size | `assets/backgrounds/ST23.png` (2912x1632, 4.8 MB); `assets/cards/front_*.png`, `back_*.png` (1500x2100) | Some pictures are far larger than any phone shows them. The base screen is 1080 wide; a card in the hand is a few hundred pixels wide, yet card art is 1232x928 and frames 1500x2100. | PNG headers; viewport 1080x2340 (`project.godot`). | Resize sources to the largest size actually drawn (roughly: backgrounds 1080 to 1440 on the long side, card art about 800 wide, frames about 750x1050), or set `process/size_limit` in the import settings. | M | High |
| A-03 | Medium | Missing art | `assets/characters/opponents`, `assets/characters/visitors` | Most characters have no drawing and show the labelled placeholder: 3 of 131 opponents and 27 of 166 visitors have art. Staff (21 of 21), cards (70 of 70) and organization icons (32 of 32) are complete. This is known (`CLAUDE.md` section 11) but it is the largest gap between this build and a store screenshot. | ID match of `data/opponents.json`, `data/visitors.json` against file names. | Decide the launch art scope: draw them, or ship a deliberate silhouette style instead of the developer placeholder (which prints the file name it wants). | L | High |
| A-04 | Medium | Audio | `assets/audio/` | There is no audio at all: no music, effects or speech files. The buses, the `Audio` autoload and `data/sounds.json` are ready. | Folder holds only `README.md`. | Produce the sounds per `design/proposals/AUDIO_PLAN_2026-10-26.md`; use Ogg Vorbis for music (streamed) and short WAV or Ogg for effects; add volume settings (C-14). | L | High |
| A-05 | Medium | Licensing | `assets/cards/art/`, `assets/backgrounds/`, `assets/characters/`; `design/CARD_ART_PROMPTS.md:1`; `design/ART_PROMPT_TEMPLATE.md:18` | The project's own documents describe making art with Midjourney, and the repo holds no record of which shipped images are AI-generated, hand-drawn or licensed. Steam requires AI-generated content to be declared, and all three stores require that you hold the rights to everything shipped. **Unverified:** I cannot tell from the files which images are AI-made. | "# Card art prompts for Midjourney (2026-10-21)"; "replace with your Midjourney/ComiPo! house style line". | Keep a short `assets/CREDITS.md` listing each art set, how it was made, and the licence or subscription it was made under. Answer Steam's AI disclosure from it (see Phase 6). | S | Medium |
| A-06 | Low | Licensing | `assets/fonts/` | The font licences are fine but incompletely documented. `OFL.txt` covers Noto Sans JP (Adobe "Source"). Antaka Brush Display says in its own metadata that it derives from Noto Serif CJK under the OFL; Antaka Brush Text derives from TeX Gyre Adventor under the GUST Font License. Neither the GUST licence text nor a note on who made the Antaka derivatives is in the repo. | Font name tables read from the TTF files: "Derived from TeX Gyre Adventor ... GUST Font License"; "Derived from Noto Serif CJK JP Black ... SIL OFL 1.1". | Add the GUST licence text and one line of attribution for each font to the credits. Both licences allow commercial use and embedding. | S | High |
| A-07 | Low | Size | `assets/fonts/NotoSansJP[wght].ttf` (9.6 MB) | The Japanese fallback font is the full variable font, used only for small accents (names in kanji, ō, 円, arrows). | File size; `CLAUDE.md` section 3 describes its use as fallback only. | Subset it to the characters the data actually uses (a script can collect them from `data/*.json`), typically under 1 MB. Re-run after content changes. | S | High |
| A-08 | Low | Duplicate | `assets/backgrounds/ST08.png`, `ST22.png` | Same file twice. | See R-02. | See R-02. | S | High |
| A-09 | Low | Naming | `assets/` | Naming is consistent where it matters (IDs in upper case: `C01`, `OP91_neutral`, `ST23`, `BO15`, `OUT_FESTIVAL_1`), with lower-case names for non-ID art (`back_sumo`, `walking_tour`). One oddity: protagonist variants use `PC01_RED_neutral` (a party color in the middle of the name). No broken references found. | 253 upper-case-start and 35 lower-case-start file names; expression suffixes neutral, attacking, damaged, gaining, guarding, victory. | No action needed. Document the `_RED_` variant rule in the art checklist if it is not already. | S | Medium |

## Checked and clean

- **Broken references:** none. Scenes reference no missing files; art is loaded by ID with a fallback, so a missing file never errors.
- **Import inconsistencies:** none; all 288 textures share the same settings (which is itself finding A-01).
- **Mipmaps:** off everywhere, which is right for 2D UI drawn near native size.
- **Addon licence:** `addons/gut/LICENSE.md` (MIT) is present; GUT is a test tool and should not ship (S-06).
