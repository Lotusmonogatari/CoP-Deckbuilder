#!/usr/bin/env python3
"""P18 (2026-11-24, Cameron): the National Assembly Library's Codex and reference desk, written into the workbook with wbx.
Adds the Library Documents tab (three hidden draft rows, one per category: Cameron chose placeholders over an empty tab), the reference
desk's Venue Activities row (Kind research), the codex_first_read_xp Rules row, the scroll style tokens for the three looks, and the
codex.* / desk.* Text rows. Every sentence is Claude's draft for Cameron to reword.
Run once from the repo root: python3 tools/workbook/archive/p18_library_build.py
Then python3 tools/export_data.py (must say "No errors")."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB, add_sheet

PATH = "design/Game_Workbook.xlsx"
NOTE = "P18 (2026-11-24): Claude's draft for Cameron to reword."


def blend(fg, bg, alpha):
    f = [int(fg[i:i + 2], 16) for i in (1, 3, 5)]
    b = [int(bg[i:i + 2], 16) for i in (1, 3, 5)]
    return "#%02X%02X%02X" % tuple(round(f[i] * alpha + b[i] * (1 - alpha)) for i in range(3))


# --- Library Documents: three hidden placeholders (a Note that begins "DRAFT" hides a row from players) ----------------------------
HEAD = ["Doc ID", "Category", "Order", "Title", "Title JP", "Kicker", "Body", "Party", "Unlock", "Unlock Value", "Hint", "Note"]
ROWS = [
    ["LD01", "party_platform", 1, "Party platform (placeholder)", "", "PARTY PLATFORM", "Placeholder text.", "", "start", "", "",
     "DRAFT: placeholder, hidden from players until real text is written (remove the word DRAFT from this note to show it)."],
    ["LD02", "ne3", 1, "ね3 (placeholder)", "", "ね3", "Placeholder text.", "", "start", "", "",
     "DRAFT: placeholder, hidden from players until real text is written."],
    ["LD03", "history", 1, "History (placeholder)", "", "HISTORY", "Placeholder text.", "", "start", "", "",
     "DRAFT: placeholder, hidden from players until real text is written."],
]
add_sheet(PATH, "Library Documents", HEAD, ROWS, [10, 16, 8, 30, 20, 20, 60, 10, 12, 16, 40, 50])

w = WB(PATH)

# --- Venue Activities: the reference desk -------------------------------------------------------------------------------------------
w.append_row("Venue Activities", {"A": "VA18", "B": "VN02", "C": "research", "D": "Ask the Reference Desk", "E": "ACT_DESK",
                                  "G": 2, "J": 1}, style_row=w.last_data_row("Venue Activities"))

# --- Rules --------------------------------------------------------------------------------------------------------------------------
w.append_row("Rules", {"A": "codex_first_read_xp", "B": "5", "C": "a whole number",
                       "D": "XP paid the first time each Library document is read (never for a Room file, and never again for the same document).",
                       "F": "P18 (2026-11-24, Cameron)."}, style_row=w.last_data_row("Rules"))

# --- UI Styles: the scroll tokens, beside the existing ones ------------------------------------------------------------------------
paper = {"woodblock": "#F4E8CC", "living_office": "#FFFBF3", "broadcast": "#0F1A2E"}
COLOURS = {
    "woodblock": {"scroll_paper": "#F4E8CC", "scroll_ink": "#1C1A17", "scroll_muted": "#5A4F42", "scroll_edge": blend("#1C1A17", "#F4E8CC", .35),
                  "scroll_kicker": "#C23B22", "scroll_rule_line": "#1C1A17", "scroll_dots": blend("#1C1A17", "#F4E8CC", .30),
                  "scroll_fibre": "#785A28", "scroll_roller_top": "#4A3424", "scroll_roller_mid": "#1E140D", "scroll_roller_bottom": "#3A2A1E",
                  "scroll_cap": "#C9A14A", "scroll_seal": "#C23B22", "scroll_seal_ink": "#F8F1E3", "scroll_cord": "#C23B22",
                  "scroll_row_shadow": blend("#C23B22", "#F0E5D1", .55)},
    "living_office": {"scroll_paper": "#FFFBF3", "scroll_ink": "#2B1D12", "scroll_muted": "#6B5843", "scroll_edge": blend("#2B1D12", "#FFFBF3", .12),
                      "scroll_kicker": "#9A6413", "scroll_rule_line": "#E2CFAF", "scroll_dots": blend("#2B1D12", "#FFFBF3", .18),
                      "scroll_fibre": "#785028", "scroll_roller_top": "#D19A64", "scroll_roller_mid": "#8A5A33", "scroll_roller_bottom": "#B47E4E",
                      "scroll_cap": "#F0DDBF", "scroll_seal": "#B5562F", "scroll_seal_ink": "#FFF8EC", "scroll_cord": "#B5562F",
                      "scroll_row_shadow": "#140F0A"},
    "broadcast": {"scroll_paper": "#0F1A2E", "scroll_ink": "#F2F4F8", "scroll_muted": "#AEB8CC", "scroll_edge": "#E3B341",
                  "scroll_kicker": "#E3B341", "scroll_rule_line": "#E3B341", "scroll_dots": blend("#E3B341", "#0F1A2E", .35),
                  "scroll_fibre": "#FFFFFF", "scroll_roller_top": "#F5C75A", "scroll_roller_mid": "#DDAA3E", "scroll_roller_bottom": "#C8921F",
                  "scroll_cap": "#0B1322", "scroll_seal": "#E3B341", "scroll_seal_ink": "#0B1322", "scroll_cord": "#E3B341",
                  "scroll_row_shadow": "#0F1A2E"},
}
SCROLL = {
    "woodblock": {"texture": "fibers", "texture_alpha": "0.06", "texture_step": "6", "roller_radius_px": "2", "seal_shape": "square",
                  "seal_tilt": "-4", "seal_text": "国会図書館", "seal_vertical": "yes", "seal_ring": "no", "cord": "yes", "row_shadow": "hard", "rule_px": "2"},
    "living_office": {"texture": "shade", "texture_alpha": "0.08", "texture_step": "6", "roller_radius_px": "10", "seal_shape": "round",
                      "seal_tilt": "-8", "seal_text": "図書館", "seal_vertical": "yes", "seal_ring": "no", "cord": "yes", "row_shadow": "soft", "rule_px": "1"},
    "broadcast": {"texture": "scanlines", "texture_alpha": "0.035", "texture_step": "4", "roller_radius_px": "0", "seal_shape": "round",
                  "seal_tilt": "0", "seal_text": "FILED", "seal_vertical": "no", "seal_ring": "yes", "cord": "no", "row_shadow": "none", "rule_px": "2"},
}
number = 130
for style in ("woodblock", "living_office", "broadcast"):
    for token, value in COLOURS[style].items():
        w.append_row("UI Styles", {"A": "US%03d" % number, "B": style, "C": "colour", "D": token, "E": value, "F": NOTE},
                     style_row=w.last_data_row("UI Styles"))
        number += 1
    for token, value in SCROLL[style].items():
        w.append_row("UI Styles", {"A": "US%03d" % number, "B": style, "C": "scroll", "D": token, "E": value, "F": NOTE},
                     style_row=w.last_data_row("UI Styles"))
        number += 1

# --- Text rows ----------------------------------------------------------------------------------------------------------------------
TEXT = [
    ("codex.tab_desk", "Library: the reference desk tab", "Reference desk", None),
    ("codex.tab_codex", "Library: the Codex tab with nothing unread", "Codex", None),
    ("codex.tab_codex_new", "Library: the Codex tab with unread documents", "Codex · {count} new", "count"),
    ("codex.intro", "Codex: the line under the tabs", "Documents you have found. Tap one to unroll it.", None),
    ("codex.empty", "Codex: nothing found yet", "The shelves are bare for now. Ask the reference desk about a room, and listen around the Capitol.", None),
    ("codex.category_room_file", "Codex: the Room files heading", "Room files", None),
    ("codex.category_party_platform", "Codex: the Party platforms heading", "Party platforms", None),
    ("codex.category_ne3", "Codex: the ね3 heading", "ね3", None),
    ("codex.category_history", "Codex: the Histories heading", "Histories", None),
    ("codex.count_found", "Codex: a category's count", "{found} of {total}", "found, total"),
    ("codex.count_room_files", "Codex: the Room files count", "{count} found", "count"),
    ("codex.new", "Codex: the mark on a document not yet read", "NEW", None),
    ("codex.sealed", "Codex: a document not yet found", "Sealed", None),
    ("codex.not_found", "Codex: the title of a document not yet found", "Not yet found", None),
    ("codex.from_start", "Codex: where a document found at the start came from", "Found at the start", None),
    ("codex.from_party", "Codex: where your own party's document came from", "Your own party", None),
    ("codex.from_line", "Codex: where a document found by listening came from", "Heard at the Capitol", None),
    ("codex.from_law", "Codex: where a document found by a law came from", "Found when the law was decided", None),
    ("codex.from_desk", "Codex: a Room file's line", "From the reference desk · kept {days} more days", "days"),
    ("codex.from_desk_last", "Codex: a Room file's line on its last day", "From the reference desk · last day", None),
    ("codex.added", "A venue line that adds a document to the Codex", "Added to the Codex", None),
    ("codex.roll_up", "Codex reader: close the scroll", "Roll up", None),
    ("codex.previous", "Codex reader: the earlier document", "‹ Previous", None),
    ("codex.next", "Codex reader: the later document", "Next ›", None),
    ("codex.reader_header", "Codex reader: the line above the scroll", "Codex · {category} · {number} of {total}", "category, number, total"),
    ("codex.room_kicker", "Codex reader: a Room file's small heading with the committee's Japanese name", "Room file · {jp}", "jp"),
    ("codex.room_kicker_plain", "Codex reader: a Room file's small heading", "Room file", None),
    ("codex.room_intro", "Codex reader: a Room file's opening line", "What the members of this room respond to, as read at the reference desk.", None),
    ("codex.room_footer", "Codex reader: a Room file's closing note", "Researched at the National Assembly Library, {date}. The file stays in the Codex while its tip lasts: {days} more days.", "date, days"),
    ("codex.room_footer_last", "Codex reader: a Room file's closing note on its last day", "Researched at the National Assembly Library, {date}. The file stays in the Codex while its tip lasts: today is the last day.", "date"),
    ("desk.intro", "Reference desk: the line under the tabs", "Look up one room in a level on offer this week. The reading is certain, and it is saved as a tip.", None),
    ("desk.tag", "Reference desk: the tag on a reading", "Reference desk", None),
    ("desk.spent", "Reference desk: what the reading cost", "{hours} h spent · {limit} a day", "hours, limit"),
    ("desk.pick_heading", "Reference desk: the heading over the list of rooms", "Which room?", None),
    ("desk.pick_row", "Reference desk: one room in the list", "{stage} · {level}", "stage, level"),
    ("desk.pick_none", "Reference desk: no room can be looked up", "No room on offer this week has a known favored style.", None),
    ("desk.room_line", "Reference desk: where the room is, under its name", "In {level} · room {number} of {total} · what the room's members respond to", "level, number, total"),
    ("desk.band_strongest", "Reference desk: a style's reading, the highest", "Strongest", None),
    ("desk.band_strong", "Reference desk: a style's reading", "Strong", None),
    ("desk.band_neutral", "Reference desk: a style's reading", "Neutral", None),
    ("desk.band_weak", "Reference desk: a style's reading", "Weak", None),
    ("desk.band_weakest", "Reference desk: a style's reading, the lowest", "Weakest", None),
    ("desk.tip_heading", "Reference desk: the tip box heading", "Rhetoric tip · Researched at the Library", None),
    ("desk.tip_line", "Reference desk: the tip's sentence", "The audience in the {stage} responds to {phrase}.", "stage, phrase"),
    ("desk.tip_foot", "Reference desk: the tip box's closing note", "Certain. Saved for {days} days. The full reading stays in the Codex under Room files until the tip ends.", "days"),
    ("desk.back", "Reference desk: back to the Library", "Back", None),
    ("desk.done_today", "Reference desk: used for today", "Done for today", None),
    ("tips.source_library", "The Tips you hold list: a tip researched at the Library", "Researched at the Library", None),
]
for key, where, english, placeholders in TEXT:
    cells = {"A": key, "B": where, "C": english, "E": NOTE}
    if placeholders:
        cells["D"] = placeholders
    w.append_row("Text", cells, style_row=w.last_data_row("Text"))
w.save()
print("workbook updated")
