#!/usr/bin/env python3
"""Two offices, Cameron's answers to the slice 7 report (2026-11-20). Refuses to run twice. Then: python3 tools/export_data.py
  * Ratings stay. PC01 starts with four Plane Tickets (SH44 x4); PC04 gets nothing.
  * Ticket prices: Paid Train Ticket 10,000円, Private Car Trip 30,000円, Plane Ticket 60,000円.
  * Spellings: PC04's District office is Daikoku (Wakkanai); PC02's is Akeno Shinmachi (Tomakomai; 明野新町).
  * Misawa, Tohoku (Tohoku-machi) and Shichinohe lie inside Aomori Block 3: a few draft names for PC01's catalog."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

w = WB("design/Game_Workbook.xlsx")

# Player: starting items and District office names
rows = w.rows("Player")
header = {title: col for col, title in rows[min(rows)].items()}
by_id = {str(r.get("A")): n for n, r in rows.items()}
if str(rows[by_id["PC01"]].get(header["Starting Items"])).endswith("SH44 x4"):
    sys.exit("already applied; nothing changed")
w.set_cell("Player", by_id["PC01"], header["Starting Items"], str(rows[by_id["PC01"]].get(header["Starting Items"])) + "; SH44 x4")
w.set_cell("Player", by_id["PC02"], header["District Office"], "Akeno Shinmachi")
w.set_cell("Player", by_id["PC04"], header["District Office"], "Daikoku")

# Shop: prices
shop = w.rows("Shop")
sh = {title: col for col, title in shop[min(shop)].items()}
for item, price in (("SH42", 10000), ("SH43", 30000), ("SH44", 60000)):
    row = [n for n, r in shop.items() if str(r.get("A")) == item][0]
    w.set_cell("Shop", row, sh["Purchase Cost from Funds (Yen)"], price)

# Places: Aomori Block 3 now includes Misawa, Tohoku and Shichinohe (draft names; real places, no brands)
NOTE = "Draft, 2026-11-20: Misawa, Tohoku and Shichinohe confirmed inside Aomori Block 3"
places = w.rows("Places")
ph = {title: col for col, title in places[min(places)].items()}
for kind, name in (("station", "Shichinohe-Towada Station"), ("town_hall", "Misawa City Hall"), ("town_hall", "Shichinohe Town Hall"),
                   ("town_hall", "Tohoku Town Office"), ("landmark", "Lake Ogawara"), ("fishing_grounds", "Lake Ogawara's shijimi clam beds")):
    w.append_row("Places", {ph["Protagonist"]: "PC01", ph["Place Type"]: kind, ph["Name (EN)"]: name, ph["Note"]: NOTE})
w.save()
print("applied")
