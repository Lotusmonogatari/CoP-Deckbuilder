#!/usr/bin/env python3
"""Two offices, slice 7 (2026-11-20): two How To Play entries for the offices and travel (HT35, HT36), in the group
Between Levels after the week-and-calendar entries. **The wording is Claude's draft for Cameron.** Refuses to run twice.
Then: python3 tools/export_data.py"""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

ENTRIES = [
    ("HT35", 167, "Between Levels", "Two offices",
     "You work from two places: the Capitol in Sapporo, where the Assembly sits, and your District office back home. Every level, "
     "event and visitor belongs to one office or the other, or to both, and the level list shows only what can start where you "
     "stand. The train strip under it takes you across: drag the train along the track and let go, or tap the strip to confirm. "
     "A trip spends hours from the same week as a level, its cost is on the strip before you go, and it is refused at the weekend "
     "or in the middle of a level. How long it takes depends on your district: an hour for some, most of a day for others."),
    ("HT36", 168, "Between Levels", "Tickets, trips inside levels and promises",
     "Some levels have their trips built in. The briefing adds the travel to the level's hours and, if you own more than one way "
     "of going, lets you pick: the rail pass is free; a paid train ticket, a private car or a plane ticket from the Marketplace "
     "costs Funds, and the car and plane can save hours and skip the chance of meeting someone on the train. On the rail pass or "
     "a paid ticket, now and then a fellow passenger starts a conversation that needs an answer. A promise is kept at the office "
     "it names, so look at the Promises button before you leave."),
]


def main():
    w = WB("design/Game_Workbook.xlsx")
    rows = w.rows("How To Play")
    header = {title: col for col, title in rows[min(rows)].items()}
    if any(str(r.get(header["Entry ID"])) in {e[0] for e in ENTRIES} for r in rows.values()):
        sys.exit("already there; nothing changed")
    for entry_id, order, group, heading, body in ENTRIES:
        w.append_row("How To Play", {header["Entry ID"]: entry_id, header["Order"]: order, header["Group"]: group,
                                      header["Heading (EN)"]: heading, header["Body (EN)"]: body})
    w.save()
    print("added", [e[0] for e in ENTRIES])


main()
