#!/usr/bin/env python3
"""Shrinks the Japanese fallback font to the characters the game can show (audit A-07, 2026-11-10).

The full Noto Sans JP variable font is 9.6 MB; the game uses it only as a fallback
for names in kanji, 円, macrons and arrows. This keeps:
  - every character that appears in data/*.json or in a script's string literals,
  - ASCII, Latin-1, general punctuation, arrows, math signs, symbols,
  - all hiragana and katakana, full-width forms,
  - the JIS level-1 kanji (2,965 common characters) as headroom, so a new name or
    word written later does not turn into an empty box.
A test (tests/test_font_coverage.gd) fails the build if anything in the data is missing,
so after adding content run this again if that test says so.

The full font lives at tools/fonts/NotoSansJP[wght].full.ttf (not shipped).

    PYTHONPATH=<where fonttools is installed> python3 tools/subset_font.py
Needs the fonttools package (pip install fonttools); it is not a game dependency.
"""
import glob
import json
import re
import sys
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parent.parent
FULL = ROOT / "tools/fonts/NotoSansJP[wght].full.ttf"
OUT = ROOT / "assets/fonts/NotoSansJP[wght].ttf"


def used_characters() -> set:
    chars = set()
    for f in glob.glob(str(ROOT / "data/*.json")):
        chars.update(Path(f).read_text(encoding="utf-8"))
    for f in glob.glob(str(ROOT / "scripts/**/*.gd"), recursive=True):
        for lit in re.findall(r'"((?:[^"\\\n]|\\.)*)"', Path(f).read_text(encoding="utf-8")):
            chars.update(lit)
    return chars


def jis_level_1() -> set:
    out = set()
    for lead in range(0x88, 0x9F):           # JIS X 0208 level 1 kanji rows in Shift_JIS
        for trail in range(0x40, 0xFD):
            if trail == 0x7F:
                continue
            try:
                ch = bytes([lead, trail]).decode("shift_jis")
            except UnicodeDecodeError:
                continue
            if len(ch) == 1:
                out.add(ch)
    return out


def ranges() -> set:
    out = set()
    for a, b in [(0x20, 0x7E), (0xA0, 0x17F), (0x2000, 0x206F), (0x2190, 0x21FF), (0x2200, 0x22FF),
                 (0x2500, 0x25FF), (0x2600, 0x26FF), (0x3000, 0x303F), (0x3040, 0x30FF),
                 (0x31F0, 0x31FF), (0xFF00, 0xFFEF)]:
        out.update(chr(c) for c in range(a, b + 1))
    return out


def main() -> None:
    wanted = {c for c in (used_characters() | jis_level_1() | ranges()) if ord(c) > 0x1F}
    font = TTFont(str(FULL))
    cmap = font.getBestCmap()
    keep = sorted(ord(c) for c in wanted if ord(c) in cmap)
    missing_from_full = sorted(c for c in used_characters() if ord(c) > 0x1F and ord(c) not in cmap)
    options = subset.Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.notdef_outline = True
    options.glyph_names = False
    options.hinting = False
    sub = subset.Subsetter(options)
    sub.populate(unicodes=keep)
    sub.subset(font)
    font.save(str(OUT))
    print("kept %d characters; wrote %s (%.2f MB)" % (len(keep), OUT.relative_to(ROOT), OUT.stat().st_size / 1e6))
    if missing_from_full:
        print("not in the full font either (will show Godot's fallback):", "".join(missing_from_full)[:80])


if __name__ == "__main__":
    sys.exit(main())
