#!/usr/bin/env python3
"""Audit Phase 2: static scan of where every variable is defined and read.

Read-only. Writes audit/tests/results/static_scan.json and prints a summary.

    python3 audit/tests/static_scan.py

What it finds
  1. Balance levers: value, the scripts that read each (file:line), levers no
     script reads, and code defaults that disagree with the data.
  2. Fields of every data table: which script names them, and fields no script
     names (workbook fields nothing reads).
  3. Numeric constants typed into scripts (candidates for workbook data).
  4. Hand-written JSON files (values held outside the workbook) and readers.
  5. Balance keys a script asks for that the data lacks.

Limits (stated in the report): a key or field built from pieces at run time
("difficulty_%s_gaffe" % tier) is matched through its format string; a field
read through a variable is not seen, so "no reader" means "no literal reader".
"""
import json, re, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"
OUT = ROOT / "audit" / "tests" / "results" / "static_scan.json"
HAND_WRITTEN = ["rules", "booster_standing", "party_standing", "art", "sounds", "staff_names",
                "level_opponent_overrides", "level_visitor_overrides", "playtest_level", "playtest_cards"]

scripts = sorted((ROOT / "scripts").rglob("*.gd"))
source = {p: p.read_text(encoding="utf-8").splitlines() for p in scripts}
rel = lambda p: str(p.relative_to(ROOT))

# Every quoted string in the scripts, with where it appears.
string_at = {}
formats = []   # (regex, file:line) for strings holding %s / %d
for path, lines in source.items():
    for n, line in enumerate(lines, 1):
        code = line.split("##")[0]
        if code.lstrip().startswith("#"):
            continue
        for text in re.findall(r'"([^"\\]*)"', code):
            string_at.setdefault(text, []).append(f"{rel(path)}:{n}")
            # A format string only counts when it keeps a real literal part:
            # a bare "%s" would otherwise "match" every name in the game.
            literal = text.replace("%s", "").replace("%d", "")
            if ("%s" in text or "%d" in text) and len(re.sub(r"[^A-Za-z0-9_]", "", literal)) >= 4 \
                    and re.fullmatch(r"[A-Za-z0-9_%]+", text):
                pattern = re.escape(text).replace("%s", "[A-Za-z0-9_]+").replace("%d", "[0-9]+")
                formats.append((re.compile("^" + pattern + "$"), f"{rel(path)}:{n}"))


def readers(name, skip_loader=False):
    """Where a key or field name is used: literal first, then format strings.
    `skip_loader` leaves out DataDB.gd, whose validation names columns without
    using them in play."""
    found = [w for w in string_at.get(name, []) if not (skip_loader and "autoload/DataDB.gd" in w)]
    if not found:
        # "win_delta_" + key: a quoted prefix ending in "_" that the name starts with.
        for text, places in string_at.items():
            prefix = len(text) >= 5 and text.endswith("_") and name.startswith(text)
            suffix = len(text) >= 5 and text.startswith("_") and name.endswith(text)   # meter + "_delta"
            if prefix or suffix:
                if not (skip_loader and all("autoload/DataDB.gd" in w for w in places)):
                    found.append(places[0] + " (built key)")
                    break
    if not found:
        for regex, where in formats:
            if regex.match(name):
                found.append(where + " (built key)")
    return found


# 1. Balance levers ---------------------------------------------------------
balance = json.load(open(DATA / "balance.json"))
levers = {}
for key, value in balance.items():
    levers[key] = {"value": value, "readers": readers(key)}
unread_levers = sorted(k for k, v in levers.items() if not v["readers"])

default_mismatch = []
missing_keys = []
call = re.compile(r'(?:balance|levers|Levers)[A-Za-z_\.]*\.(?:get|num|whole)\(\s*"([a-z_0-9]+)"\s*(?:,\s*([-0-9\.]+))?\s*\)')
for path, lines in source.items():
    for n, line in enumerate(lines, 1):
        for key, default in call.findall(line):
            if key not in balance:
                missing_keys.append(f"{key} at {rel(path)}:{n}")
            elif default not in ("", None):
                try:
                    if isinstance(balance[key], (int, float)) and abs(float(default) - float(balance[key])) > 1e-9:
                        default_mismatch.append({"key": key, "code_default": float(default),
                                                 "data": balance[key], "at": f"{rel(path)}:{n}"})
                except ValueError:
                    pass

# 2. Table fields ------------------------------------------------------------
tables = {}
for file in sorted(DATA.glob("*.json")):
    name = file.stem
    if name in ("balance", "strings"):
        continue
    content = json.load(open(file))
    rows = content if isinstance(content, list) else None
    if rows is None and isinstance(content, dict):
        # a dict of rows, or a nested object: take dict values that are dicts
        rows = [v for v in content.values() if isinstance(v, dict)]
        top = [k for k in content if not str(k).startswith("_")]
    else:
        top = []
    fields = {}
    for row in rows or []:
        if not isinstance(row, dict):
            continue
        for field, value in row.items():
            info = fields.setdefault(field, {"filled": 0, "min": None, "max": None})
            if value is not None and value != "":
                info["filled"] += 1
                if isinstance(value, (int, float)) and not isinstance(value, bool):
                    info["min"] = value if info["min"] is None else min(info["min"], value)
                    info["max"] = value if info["max"] is None else max(info["max"], value)
    for field, info in fields.items():
        info["readers"] = readers(field, skip_loader=True)[:6]
        info["loader_only"] = (not info["readers"]) and bool(readers(field))
    tables[name] = {"rows": len(rows or []), "fields": fields, "top_keys": top,
                    "hand_written": name in HAND_WRITTEN,
                    "table_readers": readers(name)[:4]}
unread_fields = {name: sorted(f for f, i in t["fields"].items() if not i["readers"] and i["filled"] > 0)
                 for name, t in tables.items()}
unread_fields = {k: v for k, v in unread_fields.items() if v}
loader_only_fields = {name: sorted(f for f, i in t["fields"].items() if i.get("loader_only") and i["filled"] > 0)
                      for name, t in tables.items()}
loader_only_fields = {k: v for k, v in loader_only_fields.items() if v}

# 3. Numeric constants in scripts -------------------------------------------
consts = []
const_line = re.compile(r'^\s*const\s+([A-Z0-9_]+)\s*(?::\s*\w+)?\s*:?=\s*(-?[0-9][0-9_\.]*)\s*(?:#.*)?$')
for path, lines in source.items():
    for n, line in enumerate(lines, 1):
        m = const_line.match(line)
        if m:
            layer = "rules" if "/rules/" in rel(path) else ("autoload" if "/autoload/" in rel(path) else ("ui" if "/ui/" in rel(path) else "scripts"))
            consts.append({"name": m.group(1), "value": m.group(2), "at": f"{rel(path)}:{n}", "layer": layer})

# 3b. Number literals inside gameplay code (rules, autoloads, top-level builders).
# Not every one is a design number (array indexes, percent maths), so this is a
# candidate list to read, not a verdict. Left out: 0, 1, 2, -1, 100, defaults
# inside balance.get("key", N), comments and strings.
magic = []
plain = {"0", "1", "2", "100", "0.0", "1.0", "2.0", "100.0"}
number = re.compile(r'(?<![A-Za-z_\.0-9"])(\d+\.\d+|\d+)(?![A-Za-z_0-9"])')
for path, lines in source.items():
    r = rel(path)
    if "/ui/" in r:
        continue
    for n, line in enumerate(lines, 1):
        code = line.split("#")[0]
        if not code.strip() or code.lstrip().startswith(("const ", "enum ")):
            continue
        code = re.sub(r'"[^"]*"', '""', code)
        code = re.sub(r'\.(?:get|num|whole)\(\s*""\s*,\s*[-0-9\.]+\s*\)', '', code)
        found = [x for x in number.findall(code) if x not in plain]
        if found:
            magic.append({"at": f"{r}:{n}", "numbers": found, "line": line.strip()[:160]})
magic_by_file = {}
for m in magic:
    f = m["at"].rsplit(":", 1)[0]
    magic_by_file[f] = magic_by_file.get(f, 0) + 1

# 4. Hand-written files -------------------------------------------------------
def leaves(x):
    if isinstance(x, dict):
        return sum(leaves(v) for k, v in x.items() if not str(k).startswith("_"))
    if isinstance(x, list):
        return sum(leaves(v) for v in x)
    return 1
hand = {}
for name in HAND_WRITTEN:
    content = json.load(open(DATA / f"{name}.json"))
    keys = [k for k in content if not str(k).startswith("_")] if isinstance(content, dict) else []
    hand[name] = {"values": leaves(content), "top_keys": keys,
                  "key_readers": {k: readers(k)[:4] for k in keys}}

result = {
    "counts": {"scripts": len(scripts), "balance_levers": len(balance), "tables": len(tables),
               "numeric_consts": len(consts)},
    "levers": levers, "unread_levers": unread_levers, "default_mismatch": default_mismatch,
    "missing_balance_keys": missing_keys, "tables": tables, "unread_fields": unread_fields, "loader_only_fields": loader_only_fields,
    "consts": consts, "hand_written": hand, "magic": magic, "magic_by_file": magic_by_file,
}
OUT.parent.mkdir(parents=True, exist_ok=True)
json.dump(result, open(OUT, "w"), indent=1, ensure_ascii=False)

print(f"scripts {len(scripts)}; balance levers {len(balance)}; tables {len(tables)}")
print(f"levers with no reader: {len(unread_levers)}")
print(f"code defaults that disagree with the data: {len(default_mismatch)}")
print(f"balance keys asked for and missing: {len(missing_keys)}")
print(f"filled table fields with no literal reader: {sum(len(v) for v in unread_fields.values())} in {len(unread_fields)} tables")
print(f"  of those, named only by DataDB's loader: {sum(len(v) for v in loader_only_fields.values())}")
by_layer = {}
for c in consts:
    by_layer[c["layer"]] = by_layer.get(c["layer"], 0) + 1
print(f"numeric constants in scripts: {len(consts)} {by_layer}")
print(f"lines with a number literal in gameplay code (candidates): {len(magic)} in {len(magic_by_file)} files")
print(f"hand-written files: " + ", ".join(f"{k} {v['values']}" for k, v in hand.items()))
