"""Writing review group 2, item B (2026-11-09, Cameron decisions #12, #15, #66).
BI26 Civil Service Merit Act: Butsutou stays the proponent and turns Supportive;
party Aye/Nay/Abstain counts rebalanced so the bill's totals (26/73/2) are unchanged.
BI35 Political Donation Transparency Act: the proponent becomes the Yezo Heritage Party.
Butsutou's BI26 party cue (spoken by its leader before the Floor Vote) is rewritten to argue For.
Run from the repo root."""
import sys; sys.path.insert(0, "tools/workbook")
from wbx import WB
w = WB("design/Game_Workbook.xlsx")
T = "Floor Vote Party Positions"
NEW = {"PT01": (16, 2, 1, "Supportive"), "PT02": (1, 12, 1, "Opposed"), "PT03": (5, 22, 0, "Opposed"),
       "PT04": (0, 5, 0, "Opposed"), "PT05": (1, 24, 0, "Opposed"), "PT06": (3, 8, 0, "Opposed")}
rows = w.rows(T)
for r, v in rows.items():
    if v.get("A") == "BI26" and v.get("B") in NEW:
        y, n, a, d = NEW[v["B"]]
        w.set_cell(T, r, "C", y); w.set_cell(T, r, "D", n); w.set_cell(T, r, "E", a); w.set_cell(T, r, "F", d)
        if v["B"] == "PT01":
            # was "These exams exclude a caring heart." (Opposed)
            w.set_cell(T, r, "G", "A post earned fairly serves everyone.")
assert sum(NEW[k][0] for k in NEW) == 26 and sum(NEW[k][1] for k in NEW) == 73 and sum(NEW[k][2] for k in NEW) == 2
B = "Floor Vote Bills"
r = w.find_row(B, "BI35")
assert w.rows(B)[r]["J"] == "PT03"
w.set_cell(B, r, "J", "PT02")
w.save()
