#!/usr/bin/env python3
"""Sapporo Stage (2026-11-25, Cameron): events and performances by date range, a performer schedule for VEN04 and VEN05, Sit and Listen and
Watch the Performance. Adds the Stage Events tab (one hidden DRAFT placeholder row), the Days and Months presence columns on Area Characters, the
Or XP column on Venue Activities, turns VA05 into Sit and Listen (Kind listen, 1 hour, 3 a day, the Gardens' icon), adds VA20 Watch the Performance
(Kind perform, 2 hours, once a day, one of +1 Our Traditional Society and +1 Urban Neighborhood Alliance, or +50 XP, drawn), Cameron's two basic
lines and the Text rows. Run once from the repo root, then python3 tools/export_data.py --accept-wording."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB, add_sheet, n2col, col2n

NOTE = "Cameron 2026-11-25 (Sapporo Stage)."
DRAFT = "DRAFT: placeholder, hidden from players until its Note stops beginning with DRAFT (add real events as rows)."
add_sheet("design/Game_Workbook.xlsx", "Stage Events", ["Event ID", "Name", "Name JP", "Kind", "Date From", "Date To", "Performer", "Blurb", "Note"],
          [["SE01", "Placeholder event", "", "event", "18.10.01", "18.10.01", "VEN04", "An event on the Sapporo Stage (placeholder).", DRAFT]],
          [10, 28, 20, 12, 12, 12, 12, 50, 60])
w = WB("design/Game_Workbook.xlsx")

# Area Characters: when a person is about (blank = always)
ac = w.rows("Area Characters")
head = ac[1]
last = sorted(head, key=lambda c: (len(c), c))[-1]
c_days, c_months = n2col(col2n(last) + 1), n2col(col2n(last) + 2)
w.set_cell("Area Characters", 1, c_days, "Days", style=w.sty("Area Characters", last + "1"))
w.set_cell("Area Characters", 1, c_months, "Months", style=w.sty("Area Characters", last + "1"))
for rn, cells in ac.items():
    if cells.get("A") == "VEN04":
        w.set_cell("Area Characters", rn, c_days, "Wed; Sun")
        w.set_cell("Area Characters", rn, c_months, "10-12; 4-7")
    if cells.get("A") == "VEN05":
        w.set_cell("Area Characters", rn, c_days, "Fri; Sat")
        w.set_cell("Area Characters", rn, c_months, "8-12; 1-3")

# Venue Activities: Or XP, VA05 becomes Sit and Listen, VA20 Watch the Performance
va = w.rows("Venue Activities")
vhead = va[1]
vlast = sorted(vhead, key=lambda c: (len(c), c))[-1]
c_orxp = n2col(col2n(vlast) + 1)
w.set_cell("Venue Activities", 1, c_orxp, "Or XP", style=w.sty("Venue Activities", vlast + "1"))
col = {n: l for l, n in vhead.items()}
for rn, cells in va.items():
    if cells.get("A") == "VA05":
        w.set_cell("Venue Activities", rn, "C", "listen")
        w.set_cell("Venue Activities", rn, "D", "Sit and Listen")
        w.set_cell("Venue Activities", rn, "E", "ACT_WATCH")
        w.set_cell("Venue Activities", rn, col["Hours"], 1)
        w.set_cell("Venue Activities", rn, col["Per Day"], 3)
vals = {"A": "VA20", "B": "VN05", "C": "perform", "D": "Watch the Performance", "E": "ACT_SHOW", col["Hours"]: 2, col["Per Day"]: 1,
        col["Rewards"]: "BO15 +1; BO27 +1", c_orxp: 50}
w.append_row("Venue Activities", vals, style_row=w.last_data_row("Venue Activities"))

# Cameron's two basic lines, for whichever of VEN04 and VEN05 is on stage
vl = w.rows("Venue Lines")
last_id = max(int(r["A"][2:]) for r in vl.values() if str(r.get("A", "")).startswith("VL"))
for i, text in enumerate(["The crisp notes complement the crisp Sapporo air.", "Even the birds are swaying along to the melody."], 1):
    w.append_row("Venue Lines", {"A": "VL%03d" % (last_id + i), "B": "overheard", "C": "gossip", "D": "VEN04|VEN05", "E": text, "O": 1, "P": "N",
                                 "U": "Cameron's basic line for the performers (2026-11-25).", "V": "VN05"}, style_row=w.last_data_row("Venue Lines"))

# Text rows
T = "2026-11-25 (Sapporo Stage): Claude's draft for Cameron to reword."
rows = [
    ("stage.event_today", "Sapporo Stage: an event is on", "On today: {name}", "name"),
    ("stage.performer_today", "Sapporo Stage: who is on stage", "On stage today: {name}", "name"),
    ("stage.quiet", "Sapporo Stage: nothing is on", "Nothing is on today. You may sit and listen.", None),
    ("stage.no_performer", "Watch the Performance: nobody is performing", "Nobody is performing today.", None),
    ("stage.gives_one_of", "Watch the Performance: what it may give", "Gives one of: {list}", "list"),
    ("stage.or_xp", "Watch the Performance: the XP option", "XP {delta}", "delta"),
    ("stage.back", "Sit and Listen and Watch the Performance: go back to the Stage", "Back to the Stage", None),
    ("stage.tag_listen", "The Stage: the tag of a heard line", "Sapporo Stage · Listening", None),
    ("stage.tag_perform", "The Stage: the tag of a performance", "Sapporo Stage · Performance", None),
    ("stage.watched", "The Stage: what a performance gave", "You watched {name} perform.", "name"),
    ("stage.nobody_said", "The Stage: nobody had anything to say", "It is quiet. Nobody says anything worth hearing.", None),
]
last = w.last_data_row("Text")
for key, where, eng, ph in rows:
    last += 1
    d = {"A": key, "B": where, "C": eng, "E": T}
    if ph:
        d["D"] = ph
    w.append_row("Text", d, style_row=last - 1)
w.save()
print("Stage Events tab; Days/Months columns", c_days, c_months, "; Or XP column", c_orxp)
