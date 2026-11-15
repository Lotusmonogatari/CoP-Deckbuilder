#!/usr/bin/env python3
"""Audit follow-up: feed deliberately malformed rows through the REAL exporter.

Works on a COPY of the workbook and writes to a temporary data folder, so the
project's workbook and data/ are untouched. Each case edits one cell with the
project's own wbx tool, runs export_data.main(), and records whether the
exporter reported an error, only a warning, or nothing.

    python3 audit/tests/exporter_probe.py     -> audit/tests/results/exporter_cases.json
"""
import contextlib, importlib, io, json, shutil, sys, tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools")); sys.path.insert(0, str(ROOT / "tools" / "workbook"))
import export_data
from wbx import WB

SRC = ROOT / "design" / "Game_Workbook.xlsx"


def find_lever(w, label):
    for r, row in w.rows("Balance").items():
        if str(row.get("A", "")).lower().startswith(label.lower()):
            return r
    raise KeyError(label)


def run(edit):
    work = Path(tempfile.mkdtemp(dir=ROOT / "audit" / "tests" / "results"))
    book = work / "wb.xlsx"
    shutil.copy(SRC, book)
    w = WB(str(book))
    edit(w)
    w.save()
    export_data.WORKBOOK = book
    shutil.copytree(ROOT / "data", work / "data")   # the hand-written files the exporter reads but never writes
    export_data.DATA_DIR = work / "data"
    export_data.REPO_ROOT = ROOT
    buf = io.StringIO()
    code = 0
    with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(buf):
        try:
            export_data.main()
        except SystemExit as e:
            code = e.code if isinstance(e.code, int) else 1
        except Exception as e:  # a crash is a finding too
            code = "CRASH %s: %s" % (type(e).__name__, e)
    text = buf.getvalue()
    errors = [l.strip() for l in text.splitlines() if l.strip().startswith("X ")][:6]
    warnings = [l.strip() for l in text.splitlines() if l.strip().startswith("!")][:400]
    clean = "No errors" in text
    shutil.rmtree(work, ignore_errors=True)
    return {"exit": code, "said_no_errors": clean, "errors": errors, "warnings": warnings,
            "tail": [l for l in text.splitlines() if l.strip()][-3:]}


def col(w, sheet, header):
    rows = w.rows(sheet); first = min(rows)
    return [c for c, v in rows[first].items() if str(v).strip() == header][0]


def blank(sheet, key, header):
    def edit(w):
        r = w.find_row(sheet, key); c = col(w, sheet, header)
        w.set_cell(sheet, r, c, "")
    return edit


def setv(sheet, key, header, value):
    def edit(w):
        r = w.find_row(sheet, key); c = col(w, sheet, header)
        w.set_cell(sheet, r, c, value)
    return edit


def lever_removed(name):
    def edit(w):
        r = find_lever(w, name); w.delete_row("Balance", r)
    return edit


CASES = {
    "baseline_no_edit": lambda w: None,
    "combat_turn_limit_blank (ST02)": blank("Stages", "ST02", "Turn limit"),
    "combat_win_threshold_blank (ST02, a non-committee room)": blank("Stages", "ST02", "Win threshold"),
    "combat_player_start_blank (ST02)": blank("Stages", "ST02", "Player start"),
    "combat_energy_blank (ST02)": blank("Stages", "ST02", "持ち時間 / turn (energy)"),
    "card_cost_blank (C23)": blank("Cards", "C23", "Cost (持ち時間)"),
    "card_unknown_suit (C23)": setv("Cards", "C23", "Suit (Element)", "Sarcasm"),
    "level_unknown_stage (LV01 stage 1)": setv("Levels", "LV01", "Stage ID for Part 1", "ST9999"),
    "balance_lever_removed (dues_base)": lever_removed("Dues: Base"),
    "meta_name_renamed (Funds -> Money)": setv("Sanban", "Funds", "Variable", "Money"),
    "text_row_blank_english (office.haptics)": blank("Text", "office.haptics", "English"),
    "shop_icon_names_missing_file (SH25)": setv("Shop", "SH25", "Icon", "NO_SUCH_FILE"),
    "visitor_unknown_stage (VI01)": setv("Visitors", "VI01", "Stage", "ST9999"),
}
result = {}
for name, edit in CASES.items():
    try:
        result[name] = run(edit)
    except Exception as e:
        result[name] = {"harness_error": "%s: %s" % (type(e).__name__, e)}
    r = result[name]
    if "warnings" in r:
        r["new_warnings"] = [x for x in r["warnings"] if x not in set(result.get("baseline_no_edit", {}).get("warnings", []))][:6] if name != "baseline_no_edit" else []
    print(name, "->", r.get("harness_error") or ("exit %s, no_errors=%s, errors=%s, new warnings=%s" % (r["exit"], r["said_no_errors"], r["errors"][:2], r.get("new_warnings", [])[:2])))
out = ROOT / "audit" / "tests" / "results" / "exporter_cases.json"
json.dump(result, open(out, "w"), indent=1)
