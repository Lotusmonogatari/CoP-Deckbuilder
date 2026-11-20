#!/usr/bin/env python3
"""Two offices, slice 5 (2026-11-20): the place-bound District events ask for place types instead of naming one real town.
Each edit is (event, old text, new text); the old text must occur exactly once among the event's title, flavor and its
choices' texts and results. The event's Needs Place is then set from the tokens it uses. **Claude's draft rewrites for Cameron
to correct.** Events the audit listed but whose text names no place a token could replace are left as they were:
EV01, EV14, EV18, EV23, EV34, EV51, EV85, EV88, EV92, EV93 (see the CHANGELOG). Refuses to run twice.
Then: python3 tools/export_data.py --accept-wording"""
import re
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

EDITS = [
    ("EV02", "a hillside temple in Matsumae", "{place:shrine_temple}"),
    ("EV12", "outside Shin-Hakodate-Hokuto Station", "outside {place:station}"),
    ("EV13", "holding its festival", "holding {place:festival}"),
    ("EV17", "on Mount Hakodate", "at {place:landmark}"),
    ("EV19", "from Hirosaki", "from {office_city}"),
    ("EV20", "on the express", "on {place:travel_route}"),
    ("EV24", "A school invites you", "{place:school} invites you"),
    ("EV26", "the Toyotomi village clinic", "the village clinic at {place:onsen_town}"),
    ("EV27", "Hakodate port", "{place:harbor}"),
    ("EV35", "The festival committee", "The {place:festival} committee"),
    ("EV37", "A teacher writes", "A teacher at {place:school} writes"),
    ("EV39", "at a market stall", "at a stall in {place:market}"),
    ("EV42", "a school in Shari", "{place:school}"),
    ("EV48", "Morning Radio Exercises by the Lake", "Morning Radio Exercises at {place:landmark}"),
    ("EV48", "on the Lake Tōya path", "on the path at {place:landmark}"),
    ("EV49", "Ainu Cultural Showcase Day at the Lake", "Ainu Cultural Showcase Day"),
    ("EV49", "The Ainu Kotan at Lake Akan", "{place:ainu_site}"),
    ("EV50", "the Ainu cultural center at Shiraoi", "{place:ainu_site}"),
    ("EV52", "the biggest lecture hall on campus", "the biggest lecture hall at {place:university}"),
    ("EV53", "the Rausu harbor hall", "the hall at {place:harbor}"),
    ("EV56", "The agricultural cooperative in Memuro", "The agricultural cooperative at {place:farmland}"),
    ("EV57", "on Asahikawa's Heiwa-dori", "at {place:market}"),
    ("EV58", "from Otaru into Sapporo", "on {place:travel_route}"),
    ("EV63", "from Hakodate port", "from {place:harbor}"),
    ("EV66", "in Furano", "in {office_city}"),
    ("EV69", "near Biei", "near {place:farmland}"),
    ("EV82", "The village hall below Cape Sōya", "The village hall near {place:energy_site}"),
    ("EV82", "further from the cape", "further from the village"),
    ("EV86", "A Foreign Buyer Visits the Port", "A Foreign Buyer Visits {place:harbor}"),
    ("EV86", "to the port with a list of questions", "to {place:harbor} with a list of questions"),
    ("EV87", "Shopkeepers on the main street", "Shopkeepers at {place:market}"),
    ("EV90", "A Savings Fair at the Community Hall", "A Savings Fair at {place:community_hall}"),
    ("EV90", "at the community hall", "at {place:community_hall}"),
    ("EV94", "The community hall that hosts the district's festivals needs", "{place:community_hall}, which hosts the district's festivals, needs"),
]

PATTERN = re.compile(r"\{place:([a-z_]+)\}")

if __name__ == "__main__":
    w = WB("design/Game_Workbook.xlsx")
    ev_rows = w.rows("Events")
    ev_head = ev_rows[1]
    ev_by = {t: l for l, t in ev_head.items()}
    ch_rows = w.rows("Event Choices")
    ch_head = ch_rows[1]
    ch_by = {t: l for l, t in ch_head.items()}
    if "Needs Place" in ev_by:
        raise SystemExit("already there: Needs Place")
    # the new column
    from wbx import n2col, col2n
    needs_col = n2col(max(col2n(c) for c in ev_head) + 1)
    w.set_cell("Events", 1, needs_col, "Needs Place", style_from=1)
    # every text cell of an event: (sheet, row number, column letter, current text)
    def cells_of(event_id):
        found = []
        row = w.find_row("Events", event_id)
        for title in ("Title", "Flavor Text"):
            found.append(("Events", row, ev_by[title], str(ev_rows[row].get(ev_by[title], ""))))
        for number, cells in ch_rows.items():
            if cells.get("A") == event_id:
                for title in ("Choice Text", "Result Text", "Promise Kept Text"):
                    letter = ch_by[title]
                    found.append(("Event Choices", number, letter, str(cells.get(letter, ""))))
        return found
    used = {}
    for event_id, old, new in EDITS:
        hits = [c for c in cells_of(event_id) if old in c[3]]
        if len(hits) != 1 or hits[0][3].count(old) != 1:
            raise SystemExit("%s: %r occurs %d times (expected once)" % (event_id, old, len(hits)))
        sheet, number, letter, text = hits[0]
        w.set_cell(sheet, number, letter, text.replace(old, new))
        # keep the in-memory copies current for later edits to the same cell
        (ev_rows if sheet == "Events" else ch_rows)[number][letter] = text.replace(old, new)
        used.setdefault(event_id, set()).update(PATTERN.findall(new))
    for event_id, kinds in used.items():
        if kinds:
            w.set_cell("Events", w.find_row("Events", event_id), needs_col, "; ".join(sorted(kinds)))
    w.save()
    print("rewrote %d places in %d events; %d events now need a place type" % (len(EDITS), len(used), sum(1 for k in used.values() if k)))
