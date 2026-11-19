#!/usr/bin/env python3
"""Reads a problem report sent from the game (2026-11-19).

A tester holds three fingers on the screen (or both volume buttons) for two seconds, circles the
problem and saves a report. The report text is copied to the phone's clipboard, so it arrives as a
pasted message, and the same text is in report.md inside the report's zip. It holds what the game was
doing and a compressed copy of the save between two marker lines.

    python3 tools/read_report.py report.txt                 # shows the report, writes report_out/savegame.json
    python3 tools/read_report.py report.txt --out /tmp/rep  # choose the folder
    python3 tools/read_report.py report.txt --install       # also puts the save where the game reads it
    pbpaste | python3 tools/read_report.py -                # read the report from the clipboard

--install keeps whatever save is there as savegame.json.before_report first, so the tester's run can be
played on this computer without losing the developer's own. Reading only; nothing is sent anywhere.
"""
import argparse
import base64
import gzip
import json
import pathlib
import re
import shutil
import sys

BEGIN = "-----BEGIN SAVE-----"
END = "-----END SAVE-----"
ROOT = pathlib.Path(__file__).resolve().parent.parent


def find_blob(text):
    start = text.find(BEGIN)
    stop = text.find(END)
    if start < 0 or stop < 0 or stop < start:
        return ""
    return re.sub(r"\s+", "", text[start + len(BEGIN):stop])


def decode_save(blob):
    """The save's JSON text from a packed block, or None when it does not decode."""
    try:
        return gzip.decompress(base64.b64decode(blob)).decode("utf-8")
    except (ValueError, OSError, EOFError):
        return None


def project_name():
    for line in (ROOT / "project.godot").read_text(encoding="utf-8").splitlines():
        if line.startswith("config/name="):
            return line.split("=", 1)[1].strip().strip('"')
    return ""


def user_dir():
    """Where Godot keeps user:// for this project on this computer."""
    home = pathlib.Path.home()
    name = project_name()
    if sys.platform == "darwin":
        return home / "Library" / "Application Support" / "Godot" / "app_userdata" / name
    if sys.platform.startswith("win"):
        return pathlib.Path.home() / "AppData" / "Roaming" / "Godot" / "app_userdata" / name
    return home / ".local" / "share" / "godot" / "app_userdata" / name


def main():
    parser = argparse.ArgumentParser(description="Read a problem report and unpack its save.")
    parser.add_argument("report", help="the report text file, or - for standard input")
    parser.add_argument("--out", default="report_out", help="folder for the unpacked save (default report_out)")
    parser.add_argument("--install", action="store_true", help="copy the save into the game's user folder (keeps the old one)")
    args = parser.parse_args()

    text = sys.stdin.read() if args.report == "-" else pathlib.Path(args.report).read_text(encoding="utf-8")
    blob = find_blob(text)
    # Show the report without the long block.
    shown = text if not blob else text[:text.find(BEGIN)] + "(packed save, %d characters)\n" % len(blob)
    print(shown.rstrip())
    if not blob:
        print("\nNo save block in this report.")
        return 0
    save = decode_save(blob)
    if save is None:
        print("\nThe save block did not decode (was it cut when pasted?).", file=sys.stderr)
        return 1
    try:
        parsed = json.loads(save)
    except json.JSONDecodeError as error:
        print("\nThe save decoded but is not JSON: %s" % error, file=sys.stderr)
        return 1
    out = pathlib.Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    target = out / "savegame.json"
    target.write_text(save, encoding="utf-8")
    print("\nSave written to %s (version %s, saved %s)." % (target, parsed.get("version"), parsed.get("saved_at")))
    if args.install:
        folder = user_dir()
        folder.mkdir(parents=True, exist_ok=True)
        live = folder / "savegame.json"
        if live.exists():
            shutil.copy2(live, folder / "savegame.json.before_report")
            print("The save that was there is kept as %s." % (folder / "savegame.json.before_report"))
        shutil.copy2(target, live)
        print("Installed as %s. Start the game and press Continue." % live)
    else:
        print("To play this run here, add --install (or copy it to the game's user folder as savegame.json).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
