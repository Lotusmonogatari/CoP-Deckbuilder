#!/usr/bin/env python3
"""Builds the web playtest page.

    python3 tools/build_web_playtest.py

Reads web/src/ and every data/*.json, and writes one self-contained HTML file
to web/playtest.html. That file is what gets published as an Artifact, so
Cameron can play the level on a phone without installing Godot.

WHY THIS EXISTS
The Godot project is the game. This page is a mirror of it, and the whole
point of building it with a script is that the DATA never has to be copied by
hand: change a number in the workbook, re-export, re-run this, and the page
matches. Only the rules are hand-maintained in both places, and web/src/
tests.js re-runs the engine's assertions in the page so that if the two ever
drift apart it says so.
"""

import json
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = REPO_ROOT / "data"
SRC_DIR = REPO_ROOT / "web" / "src"
OUTPUT = REPO_ROOT / "web" / "playtest.html"

# Only what the playtest level actually reads. Loading the whole workbook
# would work, but a page carrying data nothing uses invites the two to drift
# apart without anybody noticing.
NEEDED = [
    "affinity",
    "booster_standing",
    "boosters",
    "cards",
    "journalists",
    "player",
    "playtest_cards",
    "playtest_level",
    "rules",
    "sanban",
    "segments",
    "stages",
    "suits",
]


def read_json(name: str):
    path = DATA_DIR / f"{name}.json"
    if not path.exists():
        sys.exit(f"Missing {path}. Run: python3 tools/export_data.py")
    return json.loads(path.read_text(encoding="utf-8"))


def strip_docs(value):
    """Drops the "_README" and "_note" keys the hand-written files carry.

    They are there for whoever opens the file, not for the game, and they are
    a noticeable share of the bytes in playtest_level.json.
    """
    if isinstance(value, dict):
        return {k: strip_docs(v) for k, v in value.items() if not k.startswith("_")}
    if isinstance(value, list):
        return [strip_docs(item) for item in value]
    return value


def flatten_rules(raw: dict) -> dict:
    """rules.json keeps each switch beside notes explaining the options.

    The game only needs the chosen value. Same as DataDB._flatten_rules.
    """
    flat = {}
    for key, entry in raw.items():
        if key.startswith("_"):
            continue
        flat[key] = entry["value"] if isinstance(entry, dict) and "value" in entry else entry
    return flat


def build_data() -> dict:
    raw = {name: read_json(name) for name in NEEDED}

    cards = list(raw["cards"])
    # Hand-written playtest cards are appended to the workbook's, exactly as
    # DataDB does it, so everything downstream treats them as ordinary cards.
    cards.extend(raw["playtest_cards"].get("cards", []))

    return strip_docs({
        "affinity": raw["affinity"],
        "booster_standing": raw["booster_standing"],
        "boosters": raw["boosters"],
        "cards": cards,
        "journalists": raw["journalists"].get("journalists", []),
        "player": raw["player"],
        "playtest_level": raw["playtest_level"],
        "rules": flatten_rules(raw["rules"]),
        "sanban": raw["sanban"],
        "segments": raw["segments"],
        # Only what a playtest stage borrows: the audience mix of the canon
        # stage it is modelled on. The rest of a stage row is not used here.
        "stages": [
            {"stage_id": row["stage_id"], "segment_mix": row.get("segment_mix", {})}
            for row in raw["stages"]
        ],
        "suits": raw["suits"],
    })


def read_source(name: str) -> str:
    path = SRC_DIR / name
    if not path.exists():
        sys.exit(f"Missing {path}")
    return path.read_text(encoding="utf-8")


def main() -> int:
    data = build_data()

    # "</script" inside a string would close the surrounding tag early. The
    # JSON stays valid either way because < is the same character.
    data_json = json.dumps(data, ensure_ascii=False, separators=(",", ":"))
    data_json = data_json.replace("</", "<\\/")

    page = read_source("index.html")
    for marker, replacement in [
        ("/*{{DATA}}*/ {}", data_json),
        ("/*{{ENGINE}}*/", read_source("engine.js")),
        ("/*{{TESTS}}*/", read_source("tests.js")),
        ("/*{{UI}}*/", read_source("ui.js")),
    ]:
        if marker not in page:
            sys.exit(f"index.html has no {marker} to fill in")
        page = page.replace(marker, replacement, 1)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(page, encoding="utf-8")

    size_kb = len(page.encode("utf-8")) / 1024
    print(f"  {OUTPUT.relative_to(REPO_ROOT)}  {size_kb:.0f} KB")
    print(f"  {len(data['cards'])} cards, {len(data['playtest_level']['stages'])} stages, "
          f"{len(data['journalists'])} reporters")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
