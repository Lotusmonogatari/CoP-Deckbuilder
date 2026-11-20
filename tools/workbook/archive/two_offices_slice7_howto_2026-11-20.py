#!/usr/bin/env python3
"""Two offices, slice 7 (2026-11-20): four How To Play entries for the offices and travel (HT35 to HT38; each at most three sentences, the guide's rule), in the group
Between Levels after the week-and-calendar entries. **The wording is Claude's draft for Cameron.** Refuses to run twice.
Then: python3 tools/export_data.py"""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

ENTRIES = [
    ("HT35", 167, "Between Levels", "Two offices",
     "You work from two places: the Capitol in Sapporo, where the Assembly sits, and your District office back home. "
     "Every level, event and visitor belongs to one office or the other, or to both, and the level list shows only what can "
     "start where you stand."),
    ("HT36", 168, "Between Levels", "Taking the train",
     "The train strip under the level list takes you to the other office: drag the train along the track and let go, or tap the "
     "strip to confirm. A trip spends hours from the same week as a level, and its cost is on the strip before you go. It is "
     "refused at the weekend and in the middle of a level, and how long it takes depends on your district."),
    ("HT37", 169, "Between Levels", "Tickets and trips inside levels",
     "Some levels have their trips built in: the briefing adds the travel to the level's hours and, if you own more than one way "
     "of going, lets you pick. The rail pass is free; a paid train ticket, a private car or a plane ticket from the Marketplace "
     "costs Funds, and the car and plane can save hours. On the rail pass or a paid ticket, now and then a fellow passenger "
     "starts a conversation that needs an answer; a car or plane never does."),
    ("HT38", 170, "Between Levels", "Promises and staff across the two offices",
     "A promise is kept at the office it names, so look at the Promises button before you leave. Your staff work for you wherever "
     "you stand."),
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
