#!/usr/bin/env python3
"""
Turns the design workbook into the JSON files the game reads.

    python3 tools/export_data.py

Reads  design/CoP_Starter_Card_Stage_Data.xlsx
Writes data/*.json
Prints a validation report, and exits non-zero if there are errors.

WHY THIS EXISTS
---------------
The workbook is the source of truth for every number, name and rule in the
game. The game itself can't read .xlsx, so this script converts each tab into
a plain JSON file. Nothing in the game hardcodes content; it all comes from
these files.

HOW TO ADD A COLUMN
-------------------
Add it in the workbook, then add one line to the matching SHEETS entry below
saying what the column is called in the spreadsheet, what to call it in JSON,
and what kind of value it holds. That's it.

The validation at the bottom is deliberately the same set of checks that
DataDB.gd runs inside the game, so a problem gets caught here — at your desk,
with a readable message — rather than as a crash on a phone.
"""

import json
import re
import sys
import unicodedata
from pathlib import Path

try:
    import openpyxl
except ImportError:
    sys.exit(
        "This script needs the 'openpyxl' library to read .xlsx files.\n"
        "Install it with:  python3 -m pip install openpyxl"
    )

REPO_ROOT = Path(__file__).resolve().parent.parent
WORKBOOK = REPO_ROOT / "design" / "CoP_Starter_Card_Stage_Data.xlsx"
DATA_DIR = REPO_ROOT / "data"

# Cells that mean "no value here". The workbook uses a few different spellings
# of "not applicable", and the brief says to treat them all as empty and work
# the real value out from the module or committee data at runtime.
#
# "majority" is in this list on purpose: it's how the Stages tab writes the
# win threshold for a committee stage, where the real number depends on how
# many members that particular committee has. The engine works it out as
# floor(size / 2) + 1 at battle setup.
NULL_TOKENS = {"", "-", "—", "–", "varies", "majority", "n/a", "na", "tbd", "none", "?"}


# ---------------------------------------------------------------------------
# Column types
# ---------------------------------------------------------------------------
# Each column in the config below says what kind of value it holds:
#
#   "str"   plain text, kept as written
#   "id"    an identifier such as C01 or ST02 — text, but whitespace-trimmed
#           and required to be non-empty
#   "int"   a whole number
#   "num"   a number that may have decimals
#   "pct"   a share written as a fraction (0.3 means 30%) — kept as a fraction
#   "list"  a comma-separated list of IDs, e.g. "M03, M04" -> ["M03", "M04"]
#   "json"  a cell holding a JSON value, e.g. an intent pattern array
#
# Any type may be empty unless it is the sheet's ID column.


def normalise_header(text):
    """
    Makes header matching forgiving about invisible differences.

    Spreadsheets pick up non-breaking spaces, and the workbook mixes three
    different dash characters (-, –, —, and the maths minus −). None of that
    should stop a column being found, so we flatten it all before comparing.
    """
    if text is None:
        return ""
    text = unicodedata.normalize("NFKC", str(text))
    text = text.replace("−", "-").replace("–", "-").replace("—", "-")
    text = text.replace(" ", " ")
    return re.sub(r"\s+", " ", text).strip().lower()


def slugify(text):
    """'Party support: allied buff (>)' -> 'party_support_allied_buff'."""
    text = unicodedata.normalize("NFKC", str(text)).strip()
    text = re.sub(r"\s*\([^)]*\)\s*$", "", text)     # drop a trailing (note)
    text = re.sub(r"[^0-9A-Za-z]+", "_", text)
    return text.strip("_").lower()


# ---------------------------------------------------------------------------
# What to export, tab by tab
# ---------------------------------------------------------------------------
# "columns" is a list of (spreadsheet header, JSON key, type).
# "id_pattern" filters out the summary rows at the bottom of a tab: only rows
#     whose first column looks like a real ID are kept. Rows that are skipped
#     are listed in the report so a typo'd ID can't disappear silently.
# "drop_rows" does the same job for tabs whose first column isn't an ID.
# "optional" names columns that may not exist yet; they export as null and
#     raise a warning rather than an error.

SHEETS = {
    "Suits": {
        "out": "suits.json",
        "key": "element",
        "columns": [
            ("Element (canon)", "element", "id"),
            ("Suit (JP)", "suit_jp", "str"),
            ("Romaji", "romaji", "str"),
            ("Gloss", "gloss", "str"),
            ("Play pattern", "play_pattern", "str"),
            ("Cards in pool", "cards_in_pool", "int"),
        ],
    },
    # Every line the game says to the player. Cameron's to reword; the code
    # asks for a Key and never holds a sentence of its own. A key the code
    # asks for and this tab does not have is an ERROR, checked below, so a
    # typo is caught here rather than appearing on screen mid-playtest.
    "Text": {
        "out": "strings.json",
        "key": "key",
        "columns": [
            ("Key", "key", "id"),
            ("Where", "where", "str"),
            ("English", "english", "str"),
            ("Placeholders", "placeholders", "str"),
            ("Notes", "notes", "str"),
        ],
    },
    "Segments": {
        "out": "segments.json",
        "key": "segment_id",
        "id_pattern": r"^SG\d+$",
        "columns": [
            ("Segment ID", "segment_id", "id"),
            ("Segment (EN)", "name_en", "str"),
            ("Segment (JP)", "name_jp", "str"),
            ("Romaji", "romaji", "str"),
            ("Description", "description", "str"),
        ],
    },
    "Stages": {
        "out": "stages.json",
        "key": "stage_id",
        "id_pattern": r"^ST\d+$",
        "columns": [
            ("Stage ID", "stage_id", "id"),
            ("Stage (EN)", "name_en", "str"),
            ("Stage (JP)", "name_jp", "str"),
            ("Romaji", "romaji", "str"),
            ("Mode", "mode", "str"),
            ("Bar unit", "bar_unit", "str"),
            ("Bar max", "bar_max", "int"),
            ("Win threshold", "win_threshold", "int"),
            ("Win %", "win_pct", "num"),
            ("Turn limit", "turn_limit", "int"),
            ("持ち時間 / turn (energy)", "energy_per_turn", "int"),
            ("Hand size", "hand_size", "int"),
            ("失言 gaffe limit", "gaffe_limit", "int"),
            ("Player start", "player_start", "int"),
            ("Opp start", "opp_start", "int"),
            ("% Press", "pct_press", "pct"),
            ("% Loyalists", "pct_loyalists", "pct"),
            ("% Constituents", "pct_constituents", "pct"),
            ("% Donors", "pct_donors", "pct"),
            ("% Bureaucrats", "pct_bureaucrats", "pct"),
            ("Segment check", "segment_check", "num"),
            ("Favored suit", "favored_suit", "str"),
            ("Win ΔJiban", "win_delta_jiban", "int"),
            ("Win ΔKanban", "win_delta_kanban", "int"),
            ("Win ΔKaban", "win_delta_kaban", "int"),
            ("XP reward", "xp_reward", "int"),
            ("Signature rule", "signature_rule", "str"),
            ("Win ΔParty support", "win_delta_party_support", "int"),
        ],
    },
    "Cards": {
        "out": "cards.json",
        "key": "card_id",
        "id_pattern": r"^C\d+$",
        # The card sheet was replaced wholesale on 2026-09-21 with Cameron's
        # 54-card slate. Gone with it: "Upgrade (+)" (the game has no upgrade
        # mechanic, so every card stands on its printed values), and the
        # Power Score / Power per Cost / Balance flag columns, which were
        # the balancing model's working-out rather than card data. They live
        # in design/CoP_Cards.xlsx if the model is ever revisited.
        #
        # "XP to unlock" is optional: the economy is being priced by
        # playtest rather than by the sheet, so a missing column is fine.
        "optional": ["XP to unlock", "Special", "Special value", "Special note"],
        "columns": [
            ("Card ID", "card_id", "id"),
            ("Name (EN)", "name_en", "str"),
            ("Name (JP)", "name_jp", "str"),
            ("Romaji", "romaji", "str"),
            ("Suit (Element)", "suit", "str"),
            ("Suit (JP)", "suit_jp", "str"),
            ("Type", "type", "str"),
            ("Cost (持ち時間)", "cost", "int"),
            ("Self +", "self_plus", "int"),
            ("Opp −", "opp_minus", "int"),
            ("Guard", "guard", "int"),
            ("Draw", "draw", "int"),
            ("Gaffe +/−", "gaffe", "int"),
            ("Target segment", "target_segment", "str"),
            ("Effect text", "effect_text", "str"),
            ("Tier", "tier", "str"),
            ("XP to unlock", "xp_to_unlock", "int"),
            ("Special", "special", "str"),
            ("Special value", "special_value", "num"),
            ("Special note", "special_note", "str"),
        ],
    },
    "Modifiers": {
        "out": "modifiers.json",
        "key": "mod_id",
        "id_pattern": r"^M\d+$",
        "columns": [
            ("Mod ID", "mod_id", "id"),
            ("Category", "category", "str"),
            ("Category (JP)", "category_jp", "str"),
            ("Name (EN)", "name_en", "str"),
            ("Name (JP)", "name_jp", "str"),
            ("Romaji", "romaji", "str"),
            ("Trigger segment", "trigger_segment", "str"),
            ("Trigger min %", "trigger_min_pct", "pct"),
            ("Effect", "effect", "str"),
            ("Magnitude", "magnitude", "num"),
            ("Kaban cost", "kaban_cost", "int"),
            ("Available to", "available_to", "str"),
            ("Source booster", "source_booster", "str"),
        ],
    },
    "Boosters": {
        "out": "boosters.json",
        "key": "booster_id",
        "id_pattern": r"^BO\d+$",
        "columns": [
            ("Booster ID", "booster_id", "id"),
            ("Organization (EN)", "name_en", "str"),
            ("Organization (JP)", "name_jp", "str"),
            ("Romaji", "romaji", "str"),
            ("Tier", "tier", "str"),
            ("Boosts", "boosts", "str"),
            ("Linked modifiers", "linked_modifiers", "list"),
            ("Modifier count", "modifier_count", "int"),
        ],
    },
    "Opponents": {
        "out": "opponents.json",
        "key": "opp_id",
        "id_pattern": r"^OP\d+$",
        "optional": ["Intent pattern"],
        "columns": [
            ("Opp ID", "opp_id", "id"),
            ("Name", "name", "str"),
            ("Party", "party", "str"),
            ("Committee", "committee", "str"),
            ("Positioning", "positioning", "str"),
            ("Element 1", "element_1", "str"),
            ("Element 2", "element_2", "str"),
            ("Primary suit", "primary_suit_jp", "str"),
            ("Secondary suit", "secondary_suit_jp", "str"),
            ("Deck size", "deck_size", "int"),
            ("Primary cards", "primary_cards", "int"),
            ("Secondary cards", "secondary_cards", "int"),
            ("Other cards", "other_cards", "int"),
            ("Loadout mods", "loadout_mods", "list"),
            ("Source", "source", "str"),
            # Not in the workbook yet. Until an "Intent pattern" column
            # lands there, the patterns come from data/intent_patterns.json,
            # a hand-written bridge the exporter never touches.
            #
            # The old "AI style" column is deliberately NOT exported any
            # more: Cameron dropped the prose on 2026-09-21 in favour of
            # rebuilding opponent character from the numbers. It may stay in
            # the workbook; nothing reads it.
            ("Intent pattern", "intent_pattern", "json"),
        ],
    },
    "Yoron": {
        "out": "yoron.json",
        "key": "topic_id",
        "id_pattern": r"^Y\d+$",
        "columns": [
            ("Topic ID", "topic_id", "id"),
            ("Topic (databook dimension)", "name_en", "str"),
            ("Topic (JP)", "name_jp", "str"),
            ("Romaji", "romaji", "str"),
            ("Start value (0–100)", "start_value", "int"),
            ("Note", "note", "str"),
        ],
    },
    "Bills": {
        "out": "bills.json",
        "key": "bill_id",
        "id_pattern": r"^B\d+$",
        "columns": [
            ("Bill ID", "bill_id", "id"),
            ("Title [placeholder]", "title", "str"),
            ("Topic ID", "topic_id", "str"),
            ("Topic", "topic", "str"),
            ("Direction (+1 more / −1 less)", "direction", "int"),
            ("Yoron value", "yoron_value", "int"),
            ("Alignment", "alignment", "int"),
            ("Difficulty mod (opp start +)", "difficulty_mod", "int"),
            ("Note", "note", "str"),
        ],
    },
    "Committee": {
        "out": "committee.json",
        "key": None,  # keyed by module + seq, not a single ID
        "id_pattern": r"^MOD\d+$",
        "columns": [
            ("Module", "module", "id"),
            ("Seq", "seq", "int"),
            ("Member", "member", "str"),
            ("Party", "party", "str"),
            ("Positioning", "positioning", "str"),
            ("Element 1", "element_1", "str"),
            ("Element 2", "element_2", "str"),
            ("Starting stance [proposed]", "starting_stance", "str"),
            ("Primary suit", "primary_suit_jp", "str"),
            ("Source", "source", "str"),
        ],
    },
    "Modules": {
        "out": "modules.json",
        "key": None,  # keyed by module + seq
        "id_pattern": r"^MOD\d+$",
        "columns": [
            ("Module", "module", "id"),
            ("Seq", "seq", "int"),
            ("Stage ID", "stage_id", "str"),
            ("Stage", "stage_name", "str"),
            ("Mode", "mode", "str"),
            ("Opp ID", "opp_id", "str"),
            ("Opponent", "opponent_name", "str"),
            ("Bill ID", "bill_id", "str"),
            ("Opp start support", "opp_start_support", "int"),
            ("Win threshold", "win_threshold", "int"),
            ("XP reward", "xp_reward", "int"),
            ("Note", "note", "str"),
            ("Difficulty", "difficulty", "str"),
            ("Committee size", "committee_size", "int"),
            ("Size in band?", "size_in_band", "str"),
        ],
    },
    "Visitors": {
        "out": "visitors.json",
        "key": "visitor_id",
        "id_pattern": r"^V\d+$",
        "optional_sheet": True,
        "columns": [
            ("Visitor ID", "visitor_id", "id"),
            ("Module", "module", "str"),
            ("Slot cost", "slot_cost", "int"),
            ("Visitor (EN)", "name_en", "str"),
            ("Visitor (JP)", "name_jp", "str"),
            ("Romaji", "romaji", "str"),
            ("Segment", "segment", "str"),
            ("Situation text", "situation_text", "str"),
            ("Choice A", "choice_a_text", "str"),
            ("A ΔJiban", "choice_a_delta_jiban", "int"),
            ("A ΔKaban", "choice_a_delta_kaban", "int"),
            ("A ΔParty support", "choice_a_delta_party_support", "int"),
            ("A Yoron topic", "choice_a_yoron_topic", "str"),
            ("A ΔYoron", "choice_a_delta_yoron", "int"),
            ("Choice B", "choice_b_text", "str"),
            ("B ΔJiban", "choice_b_delta_jiban", "int"),
            ("B ΔKaban", "choice_b_delta_kaban", "int"),
            ("B ΔParty support", "choice_b_delta_party_support", "int"),
            ("B Yoron topic", "choice_b_yoron_topic", "str"),
            ("B ΔYoron", "choice_b_delta_yoron", "int"),
            ("Note", "note", "str"),
        ],
    },
    "Sanban": {
        "out": "sanban.json",
        "key": "variable",
        "drop_rows": set(),
        "columns": [
            ("Variable", "name_en", "str"),
            ("JP", "name_jp", "str"),
            ("Romaji", "romaji", "str"),
            ("Start", "start", "int"),
            ("Min", "min", "int"),
            ("Max", "max", "int"),
            ("Low threshold", "low_threshold", "int"),
            ("Low consequence", "low_consequence", "str"),
            ("High threshold", "high_threshold", "int"),
            ("High consequence", "high_consequence", "str"),
            ("Fed by", "fed_by", "str"),
            ("Critical threshold", "critical_threshold", "int"),
            ("Critical consequence", "critical_consequence", "str"),
        ],
    },
}

# Tabs that are documentation, a derived view, or a production tracker.
# They are deliberately not exported; the game never reads them.
NOT_EXPORTED = {
    "README": "documentation",
    "CardStage": "a derived view — the engine recomputes this from cards + affinity",
    "Assets": "art production tracker, not game data",
}


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

class Report:
    """Collects everything worth telling Cameron, then prints it in one block."""

    def __init__(self):
        self.errors = []    # must be fixed — the game will not work
        self.warnings = []  # known gaps — the game works but something is missing
        self.notes = []     # things that happened, for reassurance

    def error(self, where, message):
        self.errors.append(f"{where}: {message}")

    def warn(self, where, message):
        self.warnings.append(f"{where}: {message}")

    def note(self, message):
        self.notes.append(message)

    def print(self):
        print("\n" + "=" * 70)
        print("DATA VALIDATION REPORT")
        print("=" * 70)

        for line in self.notes:
            print(f"  {line}")

        if self.warnings:
            print(f"\n  {len(self.warnings)} warning(s) — the game runs, but these are gaps:")
            for line in self.warnings:
                print(f"    ! {line}")

        if self.errors:
            print(f"\n  {len(self.errors)} ERROR(S) — these must be fixed in the workbook:")
            for line in self.errors:
                print(f"    X {line}")
        else:
            print("\n  No errors. Every cross-reference in the workbook resolves.")

        print("=" * 70 + "\n")


# ---------------------------------------------------------------------------
# Reading cells
# ---------------------------------------------------------------------------

def is_null(value):
    if value is None:
        return True
    return str(value).strip().lower() in NULL_TOKENS


def coerce(value, kind, where, report):
    """Turns one spreadsheet cell into the right kind of JSON value."""
    if is_null(value):
        return None

    text = str(value).strip()

    if kind in ("str", "id"):
        return text

    if kind == "list":
        # "M03, M04" -> ["M03", "M04"]
        return [part.strip() for part in text.split(",") if part.strip()]

    if kind == "json":
        try:
            return json.loads(text)
        except json.JSONDecodeError as exc:
            report.error(where, f"is not valid JSON ({exc.msg}): {text!r}")
            return None

    # Numbers. Excel hands back floats for everything, so an "int" column
    # arrives as 3.0 and needs rounding back to 3.
    try:
        number = float(text)
    except ValueError:
        report.error(where, f"should be a number but reads {text!r}")
        return None

    if kind == "int":
        if abs(number - round(number)) > 1e-9:
            report.warn(where, f"expected a whole number, got {number} — rounded to {round(number)}")
        return int(round(number))

    if kind == "pct" and number > 1.0:
        report.warn(
            where,
            f"is {number}, but shares are stored as fractions (0.3 means 30%). "
            "Divide it by 100 in the workbook.",
        )

    return number


def read_table(sheet, config, sheet_name, report):
    """Reads one ordinary tab into a list of dictionaries."""
    rows = list(sheet.iter_rows(values_only=True))
    if not rows:
        report.error(sheet_name, "the tab is empty")
        return []

    headers = [normalise_header(cell) for cell in rows[0]]
    optional = {normalise_header(name) for name in config.get("optional", [])}

    # Work out which spreadsheet column each JSON key comes from.
    column_index = {}
    for header, key, kind in config["columns"]:
        wanted = normalise_header(header)
        if wanted in headers:
            column_index[key] = (headers.index(wanted), kind)
        elif wanted in optional:
            column_index[key] = (None, kind)   # exports as null
            report.warn(
                sheet_name,
                f"column '{header}' is not in the workbook yet, so every "
                f"'{key}' is empty. See design/proposals/ for the proposed version.",
            )
        else:
            report.error(sheet_name, f"expected a column called '{header}' and could not find it")
            column_index[key] = (None, kind)

    id_pattern = config.get("id_pattern")
    drop_rows = config.get("drop_rows")
    records, skipped = [], []

    for row_number, row in enumerate(rows[1:], start=2):
        if row is None or all(is_null(cell) for cell in row):
            continue

        first = "" if row[0] is None else str(row[0]).strip()

        if drop_rows is not None and first in drop_rows:
            continue
        if id_pattern and not re.match(id_pattern, first):
            # A row with a blank first cell is a summary or spacer row at the
            # bottom of a tab — not worth mentioning. A row with something in
            # it might be a mistyped ID, so that one gets reported.
            if first:
                skipped.append(f"row {row_number} ({first!r})")
            continue

        record = {}
        for header, key, kind in config["columns"]:
            index, kind = column_index[key]
            cell = None if index is None or index >= len(row) else row[index]
            record[key] = coerce(cell, kind, f"{sheet_name} row {row_number}, '{header}'", report)
        records.append(record)

    if skipped:
        # These are almost always the summary rows at the bottom of a tab.
        # Listed rather than dropped in silence, so a mistyped ID is visible.
        report.note(
            f"{sheet_name}: skipped {len(skipped)} non-data row(s): {', '.join(skipped)}"
        )

    return records


def _as_int_pair(first, second):
    """Returns (int, int) if both cells are whole numbers, otherwise None."""
    try:
        if is_null(first) or is_null(second):
            return None
        return int(round(float(str(first).strip()))), int(round(float(str(second).strip())))
    except ValueError:
        return None


def read_balance(sheet, report):
    """
    The Balance tab is a list of levers, not a table, and it has two small
    sub-tables embedded in it. This turns it into one object:

        { "w_self": 1, ..., "xp_tiers": {...}, "committee_size_bands": {...} }
    """
    levers, xp_tiers, size_bands = {}, {}, {}
    section = None

    for row_number, row in enumerate(sheet.iter_rows(values_only=True), start=1):
        if row is None or all(is_null(cell) for cell in row):
            continue

        label = "" if row[0] is None else str(row[0]).strip()
        if not label or label == "Lever":
            continue

        value = row[1] if len(row) > 1 else None

        # Section headers announce the two sub-tables.
        if label.upper() == "XP TIER TABLE":
            section = "xp"
            continue
        if label.upper().startswith("COMMITTEE SIZE BY DIFFICULTY"):
            section = "bands"
            continue

        where = f"Balance row {row_number}, '{label}'"

        if section == "xp" and re.match(r"^(Starter|Tier \d+)$", label):
            xp_tiers[label] = coerce(value, "int", where, report)
            continue

        if section == "bands" and len(row) > 2:
            # A band row is "Easy | 3 | 5" — a label and two whole numbers.
            # The lever that follows the sub-table has a sentence in the third
            # column, so checking both cells are numbers is what tells the two
            # apart. Tested quietly: a non-match just falls through to a lever.
            band = _as_int_pair(row[1], row[2])
            if band is not None:
                size_bands[label] = {"min": band[0], "max": band[1]}
                continue

        # Anything else is an ordinary lever. Leaving the section marker set
        # would swallow later levers, so clear it once we're past a sub-table.
        section = None
        number = coerce(value, "num", where, report)
        # Levers like "Starter deck size" are counts. Writing them as 12
        # rather than 12.0 keeps the JSON readable; the decimals that matter
        # (weights, shares) are untouched.
        if isinstance(number, float) and number.is_integer():
            number = int(number)
        levers[slugify(label)] = number

    levers["xp_tiers"] = xp_tiers
    levers["committee_size_bands"] = size_bands
    return levers


def read_lists(sheet, report):
    """
    The Lists tab holds the dropdown options for the rest of the workbook —
    one independent list per column, each a different length. Exported so the
    validator can check spelling against the same options you see in Excel.
    """
    rows = list(sheet.iter_rows(values_only=True))
    if not rows:
        report.error("Lists", "the tab is empty")
        return {}

    headers = [None if cell is None else str(cell).strip() for cell in rows[0]]
    lists = {}
    for index, header in enumerate(headers):
        if not header:
            continue
        values = []
        for row in rows[1:]:
            cell = row[index] if index < len(row) else None
            if not is_null(cell):
                values.append(str(cell).strip())
        lists[slugify(header)] = values
    return lists


# ---------------------------------------------------------------------------
# Cross-reference validation
# ---------------------------------------------------------------------------
# Everything below answers one question: does every ID in the workbook point
# at something that actually exists? A card whose suit is misspelled, a module
# naming an opponent who isn't in the roster — these are the mistakes that are
# invisible in a spreadsheet and fatal in a game.

def ids_from(records, key):
    return {r[key] for r in records if r.get(key)}


def validate(data, report):
    suits = ids_from(data["suits"], "element")
    stage_ids = ids_from(data["stages"], "stage_id")
    segment_names = {r["name_en"] for r in data["segments"] if r.get("name_en")}
    card_ids = ids_from(data["cards"], "card_id")
    mod_ids = ids_from(data["modifiers"], "mod_id")
    booster_ids = ids_from(data["boosters"], "booster_id")
    opp_ids = ids_from(data["opponents"], "opp_id")
    topic_ids = ids_from(data["yoron"], "topic_id")
    bill_ids = ids_from(data["bills"], "bill_id")
    module_ids = {r["module"] for r in data["modules"] if r.get("module")}
    tier_names = set(data["balance"].get("xp_tiers", {}).keys())
    lists = data.get("lists", {})

    # --- duplicate IDs -----------------------------------------------------
    for name, key in [
        ("cards", "card_id"), ("stages", "stage_id"), ("segments", "segment_id"),
        ("modifiers", "mod_id"), ("boosters", "booster_id"), ("opponents", "opp_id"),
        ("yoron", "topic_id"), ("bills", "bill_id"), ("suits", "element"),
    ]:
        seen = set()
        for record in data[name]:
            value = record.get(key)
            if value in seen:
                report.error(name, f"{key} '{value}' appears more than once")
            seen.add(value)

    # --- cards -------------------------------------------------------------
    for card in data["cards"]:
        cid = card["card_id"]
        if card["suit"] not in suits:
            report.error("cards", f"{cid} has suit '{card['suit']}', which is not in the Suits tab")
        if card["target_segment"] and card["target_segment"] != "Any":
            if card["target_segment"] not in segment_names:
                report.error(
                    "cards",
                    f"{cid} targets segment '{card['target_segment']}', "
                    "which is not in the Segments tab",
                )
        if card["tier"] and tier_names and card["tier"] not in tier_names:
            report.error(
                "cards",
                f"{cid} has tier '{card['tier']}', which is not in the Balance XP tier table",
            )
        if card["type"] and lists.get("types") and card["type"] not in lists["types"]:
            report.error("cards", f"{cid} has type '{card['type']}', which is not in the Lists tab")
        if card["cost"] is None:
            report.error("cards", f"{cid} has no cost")

    # --- affinity ----------------------------------------------------------
    for row in data["affinity"]:
        if row["element"] not in suits:
            report.error("affinity", f"'{row['element']}' is not in the Suits tab")
        for stage_id in row["multipliers"]:
            if stage_id not in stage_ids:
                report.error("affinity", f"column '{stage_id}' is not a stage in the Stages tab")

    combat_stages = {r["stage_id"] for r in data["stages"] if r.get("mode") == "Combat"}
    covered = set()
    for row in data["affinity"]:
        covered |= set(row["multipliers"].keys())
    for stage_id in sorted(combat_stages - covered):
        report.error("affinity", f"combat stage {stage_id} has no affinity column")
    for element in sorted(suits):
        if element not in {r["element"] for r in data["affinity"]}:
            report.error("affinity", f"suit '{element}' has no affinity row")

    # --- stages ------------------------------------------------------------
    for stage in data["stages"]:
        sid = stage["stage_id"]
        if stage["favored_suit"] and stage["favored_suit"] not in suits:
            report.error("stages", f"{sid} favours '{stage['favored_suit']}', which is not a suit")

        mix = stage["segment_mix"]
        total = sum(v for v in mix.values() if v is not None)
        if mix and abs(total - 1.0) > 0.001:
            report.error(
                "stages",
                f"{sid} audience shares add up to {total:.0%}, not 100%",
            )

        if stage["mode"] == "Combat":
            for field in ("turn_limit", "energy_per_turn", "hand_size", "gaffe_limit"):
                if stage[field] is None:
                    report.error("stages", f"{sid} is a combat stage but has no {field}")
            for field in ("bar_max", "win_threshold", "player_start", "opp_start"):
                if stage[field] is None:
                    report.warn(
                        "stages",
                        f"{sid} has no {field} — it must be resolved from the module "
                        "or committee data at battle setup",
                    )

    # --- modifiers ---------------------------------------------------------
    for mod in data["modifiers"]:
        mid = mod["mod_id"]
        if mod["trigger_segment"] and mod["trigger_segment"] not in segment_names:
            report.error(
                "modifiers",
                f"{mid} triggers on segment '{mod['trigger_segment']}', "
                "which is not in the Segments tab",
            )
        if mod["source_booster"] and mod["source_booster"] not in booster_ids:
            # Opponent-only debuffs and meta-driven modifiers have no booster.
            if not mod["source_booster"].startswith("Party support"):
                report.error(
                    "modifiers",
                    f"{mid} names source booster '{mod['source_booster']}', "
                    "which is not in the Boosters tab",
                )
        if mod["trigger_min_pct"] is None and mod["trigger_segment"]:
            report.warn(
                "modifiers",
                f"{mid} names a trigger segment but no trigger min % — "
                "treated as always active once its other condition is met",
            )

    # --- boosters ----------------------------------------------------------
    for booster in data["boosters"]:
        for mod_id in booster["linked_modifiers"] or []:
            if mod_id not in mod_ids:
                report.error(
                    "boosters",
                    f"{booster['booster_id']} links modifier '{mod_id}', "
                    "which is not in the Modifiers tab",
                )
        linked = len(booster["linked_modifiers"] or [])
        if booster["modifier_count"] is not None and booster["modifier_count"] != linked:
            report.error(
                "boosters",
                f"{booster['booster_id']} says it has {booster['modifier_count']} "
                f"modifiers but lists {linked}",
            )

    # --- opponents ---------------------------------------------------------
    for opp in data["opponents"]:
        oid = opp["opp_id"]
        for field in ("element_1", "element_2"):
            if opp[field] and opp[field] not in suits:
                report.error("opponents", f"{oid} has {field} '{opp[field]}', which is not a suit")
        for mod_id in opp["loadout_mods"] or []:
            if mod_id not in mod_ids:
                report.error("opponents", f"{oid} loads modifier '{mod_id}', which does not exist")
        if opp["intent_pattern"] is None:
            report.warn(
                "opponents",
                f"{oid} has no intent pattern of their own, so they fall back to the "
                "shared default in rules.json and play generically. Proposed patterns "
                "for every opponent are in design/proposals/.",
            )

    # --- bills -------------------------------------------------------------
    for bill in data["bills"]:
        if bill["topic_id"] not in topic_ids:
            report.error(
                "bills",
                f"{bill['bill_id']} uses topic '{bill['topic_id']}', "
                "which is not in the Yoron tab",
            )
        if bill["direction"] not in (1, -1):
            report.error(
                "bills",
                f"{bill['bill_id']} has direction {bill['direction']}; it must be +1 or -1",
            )

    # --- visitors ----------------------------------------------------------
    for visitor in data.get("visitors", []):
        vid = visitor["visitor_id"]
        for side in ("a", "b"):
            topic = visitor.get(f"choice_{side}_yoron_topic")
            if topic and topic not in topic_ids:
                report.error(
                    "visitors",
                    f"{vid} choice {side.upper()} moves topic '{topic}', "
                    "which is not in the Yoron tab",
                )
        if visitor.get("segment") and visitor["segment"] not in segment_names:
            report.error(
                "visitors",
                f"{vid} names segment '{visitor['segment']}', which is not in the Segments tab",
            )

    # --- modules -----------------------------------------------------------
    seen_sequence = set()
    for row in data["modules"]:
        label = f"{row['module']} step {row['seq']}"
        if (row["module"], row["seq"]) in seen_sequence:
            report.error("modules", f"{label} appears more than once")
        seen_sequence.add((row["module"], row["seq"]))

        if row["stage_id"] not in stage_ids:
            report.error("modules", f"{label} uses stage '{row['stage_id']}', which does not exist")
        if row["opp_id"] and row["opp_id"] not in opp_ids:
            report.error("modules", f"{label} names opponent '{row['opp_id']}', who does not exist")
        if row["bill_id"] and row["bill_id"] not in bill_ids:
            report.error("modules", f"{label} uses bill '{row['bill_id']}', which does not exist")
        if row["mode"] == "Combat" and not row["opp_id"]:
            report.error("modules", f"{label} is a combat stage with no opponent")

        # Committee stages need members, and the size must sit in the band
        # the difficulty promises.
        if row["stage_id"] == "ST01":
            members = [m for m in data["committee"]
                       if m["module"] == row["module"] and m["seq"] == row["seq"]]
            if not members:
                report.error("modules", f"{label} is a committee stage with no members listed")
            elif row["committee_size"] is not None and len(members) != row["committee_size"]:
                report.error(
                    "modules",
                    f"{label} says committee size {row['committee_size']} "
                    f"but the Committee tab lists {len(members)} members",
                )
            band = data["balance"]["committee_size_bands"].get(row["difficulty"])
            if band and row["committee_size"] is not None:
                if not (band["min"] <= row["committee_size"] <= band["max"]):
                    report.error(
                        "modules",
                        f"{label} has {row['committee_size']} members, outside the "
                        f"{row['difficulty']} band of {band['min']}-{band['max']}",
                    )

    # --- committee ---------------------------------------------------------
    stances = set(lists.get("stance", []))
    for member in data["committee"]:
        label = f"{member['module']} step {member['seq']}, {member['member']}"
        if member["module"] not in module_ids:
            report.error("committee", f"{label} belongs to module '{member['module']}', which does not exist")
        if stances and member["starting_stance"] not in stances:
            report.error(
                "committee",
                f"{label} has stance '{member['starting_stance']}', "
                f"which is not one of {sorted(stances)}",
            )
        for field in ("element_1", "element_2"):
            if member[field] and member[field] not in suits:
                report.error("committee", f"{label} has {field} '{member[field]}', which is not a suit")

    # --- sanban ------------------------------------------------------------
    for variable in data["sanban"]:
        label = variable["name_en"]
        if variable["start"] is None or variable["min"] is None or variable["max"] is None:
            report.error("sanban", f"{label} is missing a start, min or max")
        elif not (variable["min"] <= variable["start"] <= variable["max"]):
            report.error(
                "sanban",
                f"{label} starts at {variable['start']}, outside its range of "
                f"{variable['min']}-{variable['max']}",
            )

    # --- design placeholders ----------------------------------------------
    neutral = data["balance"].get("yoron_neutral_point")
    if neutral is not None:
        flat = [t["topic_id"] for t in data["yoron"] if t["start_value"] == neutral]
        if len(flat) == len(data["yoron"]) and data["yoron"]:
            report.warn(
                "yoron",
                f"every topic still starts at the neutral value ({neutral:g}), so every "
                "bill's difficulty works out to 0. Bill difficulty does nothing until "
                "these are set (open decision #3).",
            )

    missing_special = [c["card_id"] for c in data["cards"]
                       if c.get("special") is None and "if " in (c.get("effect_text") or "").lower()]
    if missing_special:
        report.warn(
            "cards",
            f"{len(missing_special)} card(s) describe a conditional effect but have no "
            f"'special' value, so the condition does nothing: {', '.join(missing_special)}",
        )

    # --- rules.json --------------------------------------------------------
    expected_flags = {
        "turn_limit_outcome": ["loss", "highest_support_wins", "tie_retry"],
        "opponent_can_win_by_threshold": [True, False],
        "opponent_engine": ["intent_patterns", "deck_ai"],
        "press_answer_timer": [True, False],
        "discard_hand_end_of_turn": [True, False],
    }
    flags = data.get("rules", {})
    for flag, allowed in expected_flags.items():
        if flag not in flags:
            report.error("rules.json", f"flag '{flag}' is missing")
        elif flags[flag] not in allowed:
            report.error(
                "rules.json",
                f"flag '{flag}' is set to {flags[flag]!r}; allowed values are {allowed}",
            )

    # Every opponent without a pattern of their own falls back to this one, so
    # a mistake here would break every battle in the game at the same time.
    known_verbs = {"attack", "gain", "block", "lean_down"}
    pattern = flags.get("default_intent_pattern")
    if pattern is None:
        report.error("rules.json", "flag 'default_intent_pattern' is missing")
    elif not isinstance(pattern, list) or not pattern:
        report.error("rules.json", "'default_intent_pattern' must be a non-empty list of moves")
    else:
        for index, move in enumerate(pattern, start=1):
            if not isinstance(move, list) or len(move) < 2:
                report.error(
                    "rules.json",
                    f"default_intent_pattern move {index} should be a verb and a "
                    'number, such as ["attack", 6]',
                )
            elif move[0] not in known_verbs:
                report.error(
                    "rules.json",
                    f"default_intent_pattern move {index} uses '{move[0]}', which is "
                    f"not one of {sorted(known_verbs)}",
                )


# ---------------------------------------------------------------------------
# Derived fields
# ---------------------------------------------------------------------------
# A couple of places in the workbook name a segment in words ("Press") where
# the engine wants its ID ("SG01"). Resolving that here, once, keeps the
# lookup out of the game code.

# ---------------------------------------------------------------------------
# Does every line the code asks for actually exist?
# ---------------------------------------------------------------------------

TEXT_KEY_CALLS = [
    re.compile(r'Text\.say\(\s*"([^"]+)"'),      # GDScript
    re.compile(r'Text\.has\(\s*"([^"]+)"'),
    re.compile(r"\bT\(\s*'([^']+)'"),           # the browser build's shorthand
    # A key handed to a helper rather than straight to the lookup — the room
    # brief passes its labels to _bullet(), for instance. Recognised by the
    # shape of a key (dotted, lower case) rather than by the call around it,
    # because there is no end of helpers a key might travel through. The
    # worst a false match can do is suppress a "nothing asks for this" note.
    re.compile(r'["\']([a-z][a-z0-9_]*(?:\.[a-z0-9_]+)+)["\']'),
]

# Where a key is built at runtime rather than written out, the code says so
# with this marker and the check skips the line instead of guessing.
TEXT_DYNAMIC = "text-key-built-at-runtime"


def check_text_keys(data, report):
    """Every key the code asks for must be a row in the Text tab.

    This is the safety net that makes the wording safe to hand over. A key
    that has no row shows up on screen as the key itself, which is the kind
    of thing a playtester finds and nobody else does — so it is an ERROR
    here, in the report Cameron already reads after every export.

    A row nothing asks for is only a warning: it is probably a typo in the
    Key column, but it might equally be a line written ahead of the screen
    that will use it.
    """
    rows = data.get("strings")
    if rows is None:
        return

    in_sheet = {str(row.get("key", "")) for row in rows}
    asked_for = {}

    searched = list(REPO_ROOT.glob("scripts/**/*.gd")) + list(REPO_ROOT.glob("web/src/*.js"))
    for path in searched:
        text = path.read_text(encoding="utf-8")
        for number, line in enumerate(text.splitlines(), 1):
            if TEXT_DYNAMIC in line:
                continue
            # Comments explain the lookup and quote example keys, so reading
            # them would report lines nothing actually asks for. A docstring
            # showing Text.say("narration.gaffe") is documentation, not a use.
            stripped = line.lstrip()
            if stripped.startswith("#") or stripped.startswith("//"):
                continue
            for pattern in TEXT_KEY_CALLS:
                for key in pattern.findall(line):
                    asked_for.setdefault(key, []).append(
                        f"{path.relative_to(REPO_ROOT)}:{number}")

    # A plural is two rows, key.one and key.other, and the code asks for the
    # bare key. Either shape satisfies the other, so fold them together
    # before comparing or every plural reads as both missing and unused.
    def satisfied(key):
        return key in in_sheet or (
            key + ".one" in in_sheet and key + ".other" in in_sheet)

    def wanted(row_key):
        if row_key in asked_for:
            return True
        base, _, suffix = row_key.rpartition(".")
        return suffix in ("one", "other") and base in asked_for

    for key in sorted(k for k in asked_for if not satisfied(k)):
        report.error("Text tab",
                     f"the code asks for '{key}' and the tab has no such Key "
                     f"({asked_for[key][0]})")

    for key in sorted(k for k in in_sheet if not wanted(k)):
        report.note(f"Text tab: nothing asks for '{key}' yet")

    # A placeholder the row uses but does not declare is a warning, because
    # the Placeholders column is what tells Cameron what he may move around.
    for row in rows:
        used = set(re.findall(r"\{(\w+)\}", str(row.get("english", ""))))
        declared = {p.strip() for p in str(row.get("placeholders") or "").split(",") if p.strip()}
        for name in sorted(used - declared):
            report.warn("Text tab",
                        f"'{row.get('key')}' uses {{{name}}} but does not list it "
                        f"in Placeholders")

    if in_sheet:
        report.note(f"Text tab: {len(in_sheet)} lines, {len(asked_for)} asked for by the code")


def add_segment_ids(data, report):
    by_name = {r["name_en"]: r["segment_id"] for r in data["segments"] if r.get("name_en")}

    # Stages: turn the five "% Press"-style columns into one keyed object.
    for stage in data["stages"]:
        mix = {}
        for name, segment_id in by_name.items():
            column = f"pct_{name.lower()}"
            if column in stage:
                if stage[column] is not None:
                    mix[segment_id] = stage.pop(column)
                else:
                    stage.pop(column)
        stage["segment_mix"] = mix

    # Modifiers: keep the readable name, add the ID next to it.
    for mod in data["modifiers"]:
        mod["trigger_segment_id"] = by_name.get(mod["trigger_segment"])

    # Cards: same, with "Any" meaning no particular segment.
    for card in data["cards"]:
        segment = card.get("target_segment")
        card["target_segment_id"] = None if segment in (None, "Any") else by_name.get(segment)


def reshape_affinity(rows):
    """
    Turns the affinity grid into one row per suit with its stage multipliers
    grouped together, which is how the battle engine looks them up.
    """
    reshaped = []
    for row in rows:
        multipliers = {key: value for key, value in row.items()
                       if key != "element" and value is not None}
        reshaped.append({"element": row["element"], "multipliers": multipliers})
    return reshaped


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def write_json(path, payload):
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main():
    report = Report()

    if not WORKBOOK.exists():
        sys.exit(f"Cannot find the workbook at {WORKBOOK}")

    print(f"Reading {WORKBOOK.relative_to(REPO_ROOT)}")
    # data_only=True gives us the values Excel calculated, so formula columns
    # such as Power Score and Difficulty mod come across as numbers.
    workbook = openpyxl.load_workbook(WORKBOOK, data_only=True, read_only=True)

    present = set(workbook.sheetnames)
    # Balance, Affinity and Lists are expected too — they just have their own
    # readers below rather than an entry in SHEETS.
    expected = set(SHEETS) | set(NOT_EXPORTED) | {"Balance", "Affinity", "Lists"}
    for tab in sorted(present - expected):
        report.warn("workbook", f"tab '{tab}' is not recognised and was not exported")
    for tab in sorted(expected - present):
        if SHEETS.get(tab, {}).get("optional_sheet"):
            report.note(f"{tab}: tab not in the workbook yet — see design/proposals/")
        else:
            report.error("workbook", f"tab '{tab}' is missing from the workbook")

    data = {}
    DATA_DIR.mkdir(exist_ok=True)

    # The ordinary table tabs.
    for sheet_name, config in SHEETS.items():
        if sheet_name not in present:
            continue
        records = read_table(workbook[sheet_name], config, sheet_name, report)
        data[config["out"].replace(".json", "")] = records

    # The three tabs that need their own reader.
    data["balance"] = read_balance(workbook["Balance"], report) if "Balance" in present else {}
    data["lists"] = read_lists(workbook["Lists"], report) if "Lists" in present else {}

    affinity_config = {
        "columns": [("Element", "element", "id")],
        "drop_rows": {"Stage name →", "Column average"},
    }
    if "Affinity" in present:
        # The stage columns aren't known ahead of time — they're whatever
        # stages the tab has — so they're read from the header row.
        header = [normalise_header(c) for c in next(workbook["Affinity"].iter_rows(values_only=True))]
        for index, cell in enumerate(header):
            if index == 0 or not cell:
                continue
            affinity_config["columns"].append((cell.upper(), cell.upper(), "num"))
        data["affinity"] = reshape_affinity(
            read_table(workbook["Affinity"], affinity_config, "Affinity", report)
        )
    else:
        data["affinity"] = []

    workbook.close()

    # rules.json is written by hand, not generated. It is read here only so
    # the validator can check its flags.
    rules_path = DATA_DIR / "rules.json"
    if rules_path.exists():
        raw = json.loads(rules_path.read_text(encoding="utf-8"))
        data["rules"] = {k: v["value"] if isinstance(v, dict) and "value" in v else v
                         for k, v in raw.items() if not k.startswith("_")}
    else:
        report.error("rules.json", "is missing — it holds the open-design switches")
        data["rules"] = {}

    add_segment_ids(data, report)
    validate(data, report)
    check_text_keys(data, report)

    written = 0
    for name, payload in sorted(data.items()):
        if name == "rules":
            continue  # hand-written, never overwritten
        write_json(DATA_DIR / f"{name}.json", payload)
        count = len(payload) if isinstance(payload, list) else len(payload.keys())
        print(f"  wrote data/{name}.json  ({count} {'rows' if isinstance(payload, list) else 'entries'})")
        written += 1

    for tab, reason in NOT_EXPORTED.items():
        report.note(f"{tab}: not exported — {reason}")
    report.note(f"{written} JSON files written to data/")

    report.print()
    return 1 if report.errors else 0


if __name__ == "__main__":
    sys.exit(main())
