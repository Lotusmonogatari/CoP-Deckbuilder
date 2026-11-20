#!/usr/bin/env python3
"""Two offices, slice 1 (2026-11-20, Cameron): the Location and Travel Trips columns on Levels (tags from the P11 audit's
levels_location.csv with Cameron's decisions: LV12, LV61 and LV62 District, LV10, LV21 and LV28 Capitol; a mixed level
charges a full round trip capped at 2 trips, 1 for LV12, LV61 and LV62), Location on Events (EV47 only for now) and on the
Bill Level Templates, the District Office name on Player, the travel hours in Balance and the two Rules switches.
Run from the repo root. It refuses to run twice. Then: python3 tools/export_data.py"""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB, col2n, n2col

LOCATION = {'LV01': 'District',
 'LV02': 'Either',
 'LV03': 'District',
 'LV04': 'Capitol',
 'LV05': 'Capitol',
 'LV06': 'Capitol',
 'LV07': 'Capitol',
 'LV08': 'Capitol',
 'LV09': 'Capitol',
 'LV10': 'Capitol',
 'LV100': 'District',
 'LV101': 'District',
 'LV102': 'District',
 'LV103': 'District',
 'LV104': 'District',
 'LV105': 'District',
 'LV106': 'Either',
 'LV107': 'District',
 'LV108': 'District',
 'LV109': 'District',
 'LV11': 'District',
 'LV110': 'District',
 'LV111': 'District',
 'LV112': 'District',
 'LV113': 'District',
 'LV114': 'Capitol',
 'LV12': 'District',
 'LV13': 'Capitol',
 'LV14': 'Capitol',
 'LV15': 'Capitol',
 'LV16': 'Capitol',
 'LV17': 'Capitol',
 'LV18': 'Capitol',
 'LV19': 'Capitol',
 'LV20': 'Capitol',
 'LV21': 'Capitol',
 'LV22': 'Capitol',
 'LV23': 'Capitol',
 'LV24': 'Capitol',
 'LV25': 'Capitol',
 'LV26': 'District',
 'LV27': 'Capitol',
 'LV28': 'Capitol',
 'LV29': 'Capitol',
 'LV30': 'Capitol',
 'LV31': 'Capitol',
 'LV32': 'Capitol',
 'LV33': 'Capitol',
 'LV34': 'Capitol',
 'LV35': 'Capitol',
 'LV36': 'Capitol',
 'LV37': 'Capitol',
 'LV38': 'Capitol',
 'LV39': 'Capitol',
 'LV40': 'Capitol',
 'LV41': 'Capitol',
 'LV42': 'Capitol',
 'LV43': 'Capitol',
 'LV44': 'Capitol',
 'LV45': 'Capitol',
 'LV46': 'Capitol',
 'LV47': 'Capitol',
 'LV48': 'Capitol',
 'LV49': 'Capitol',
 'LV50': 'Capitol',
 'LV51': 'Capitol',
 'LV52': 'Capitol',
 'LV53': 'Capitol',
 'LV54': 'Capitol',
 'LV55': 'Capitol',
 'LV56': 'Capitol',
 'LV57': 'Capitol',
 'LV58': 'Capitol',
 'LV59': 'Capitol',
 'LV60': 'Capitol',
 'LV61': 'District',
 'LV62': 'District',
 'LV63': 'Capitol',
 'LV64': 'Capitol',
 'LV65': 'Capitol',
 'LV66': 'Capitol',
 'LV67': 'Capitol',
 'LV68': 'Capitol',
 'LV69': 'Capitol',
 'LV70': 'Capitol',
 'LV71': 'Capitol',
 'LV72': 'Capitol',
 'LV73': 'Capitol',
 'LV74': 'Capitol',
 'LV75': 'Capitol',
 'LV76': 'Capitol',
 'LV77': 'Capitol',
 'LV78': 'Capitol',
 'LV79': 'Capitol',
 'LV80': 'Capitol',
 'LV81': 'Capitol',
 'LV82': 'Capitol',
 'LV83': 'District',
 'LV84': 'Capitol',
 'LV85': 'Either',
 'LV86': 'Either',
 'LV87': 'District',
 'LV88': 'Capitol',
 'LV89': 'District',
 'LV90': 'Either',
 'LV91': 'Capitol',
 'LV92': 'District',
 'LV93': 'District',
 'LV94': 'District',
 'LV95': 'District',
 'LV96': 'District',
 'LV97': 'District',
 'LV98': 'Capitol',
 'LV99': 'Capitol'}

TRIPS = {'LV05': 2,
 'LV10': 2,
 'LV12': 1,
 'LV17': 2,
 'LV21': 2,
 'LV27': 2,
 'LV28': 2,
 'LV31': 2,
 'LV34': 2,
 'LV37': 2,
 'LV43': 2,
 'LV44': 2,
 'LV47': 2,
 'LV61': 1,
 'LV62': 1,
 'LV63': 2,
 'LV64': 2,
 'LV69': 2,
 'LV70': 2,
 'LV71': 2,
 'LV76': 2,
 'LV78': 2,
 'LV79': 2,
 'LV81': 2}

OFFICES = {"PC01": "Noheji", "PC02": "Akenoshinmachi", "PC03": "Teine Ward", "PC04": "Daikoki"}

# Balance levers (name, value, note). PC01 is the Aomori protagonist and PC04 the Wakkanai one (Cameron, 2026-11-20).
BALANCE = [
    ("Travel Hours: Train PC01", 7, "Two offices (2026-11-20): game hours of a one-way trip by train from Noheji to the Capitol. Spent from the week's hours."),
    ("Travel Hours: Train PC02", 1, "One-way trip by train between Akenoshinmachi (Tomakomai) and the Capitol."),
    ("Travel Hours: Train PC03", 1, "One-way trip by train or subway between Teine Ward and the Capitol, both in Sapporo."),
    ("Travel Hours: Train PC04", 6, "One-way trip by train between Daikoki (Wakkanai) and the Capitol."),
    ("Travel Hours: Plane PC01", 2, "A plane ticket is PC01's fast mode (in place of a private car): one-way hours."),
    ("Travel Hours: Car PC02", 1, "A private car is the fast mode: one-way hours."),
    ("Travel Hours: Car PC03", 1, "A private car is the fast mode: one-way hours."),
    ("Travel Hours: Car PC04", 4, "A private car is the fast mode: one-way hours."),
    ("Travel Forced Hours", 0, "Hours a forced move to the Capitol costs (a Dated event that opens the week). 0 keeps it free; a number keeps a cost possible later."),
]

RULES = [
    ("travel_at_weekend", "false", "[true, false]",
     "Can the player travel between the offices during the optional weekend?",
     '{"false": "No. The weekend is played where the work week ended, and the next week starts there.", "true": "Yes, a trip spends weekend hours like any hours."}'),
    ("start_office", "Capitol", '["Capitol", "District"]',
     "Where does a new run begin?",
     '{"Capitol": "At the Capitol, where most levels are. The District office is reached by the first trip.", "District": "At the protagonist\'s own District office."}'),
]

if __name__ == "__main__":
    w = WB("design/Game_Workbook.xlsx")

    def add_header(sheet, title):
        rows = w.rows(sheet)
        header = rows[min(rows)]
        if title in header.values():
            raise SystemExit("already there: %s on %s" % (title, sheet))
        letter = n2col(max(col2n(c) for c in header) + 1)
        w.set_cell(sheet, min(rows), letter, title, style_from=1)
        return letter

    # Levels
    loc_col = add_header("Levels", "Location")
    trip_col = add_header("Levels", "Travel Trips")
    for level_id, office in LOCATION.items():
        row = w.find_row("Levels", level_id)
        w.set_cell("Levels", row, loc_col, office)
        if level_id in TRIPS:
            w.set_cell("Levels", row, trip_col, TRIPS[level_id])
    # Events: only the Dated one is tagged now; the rest wait for the events slice.
    ev_col = add_header("Events", "Location")
    w.set_cell("Events", w.find_row("Events", "EV47"), ev_col, "Capitol")
    # Bill Level Templates
    tpl_col = add_header("Bill Level Templates", "Location")
    for template in ("BT01", "BT02", "BT03", "BT04"):
        w.set_cell("Bill Level Templates", w.find_row("Bill Level Templates", template), tpl_col, "Capitol")
    # Player
    po_col = add_header("Player", "District Office")
    for pid, name in OFFICES.items():
        w.set_cell("Player", w.find_row("Player", pid), po_col, name)
    # Balance
    style_row = w.last_data_row("Balance")
    for name, value, note in BALANCE:
        w.append_row("Balance", {"A": name, "B": value, "C": note}, style_row=style_row)
    # Rules
    style_row = w.last_data_row("Rules")
    for key, value, options, question, means in RULES:
        w.append_row("Rules", {"A": key, "B": value, "C": options, "D": question, "E": means}, style_row=style_row)
    w.save()
    print("tagged %d levels (%d with trips), EV47, 4 templates, 4 District offices, %d Balance rows, %d Rules rows" % (
        len(LOCATION), len(TRIPS), len(BALANCE), len(RULES)))
