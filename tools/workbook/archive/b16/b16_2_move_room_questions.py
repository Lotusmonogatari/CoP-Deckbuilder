"""Writing review group 2, items C and E (2026-11-09, Cameron decisions #31, #33).
Room-pool questions that name a specific policy area move from the five generic room
pools to the Stage Questions of the matching generic room only, so they never come up
in a bill's room (which shares the pool). Text, theme, grades, Asked By Party and
Asked By Organization are kept; each gets the next free S-number. T32 and T33 (the
Town Hall cranks) go to ST05 only. Questions that stay are generic (party, faction,
the member's own work) and fit any room. Run from the repo root."""
import sys, re; sys.path.insert(0, "tools/workbook")
from wbx import WB
w = WB("design/Game_Workbook.xlsx")

def ids(prefix, a, b, skip=()):
    return [f"{prefix}{n}" for n in range(a, b + 1) if n not in skip]

MOVES = {
    # tab: (stage, ids to move)
    "Press Questions": ("ST04", ids("Q", 21, 34, skip=(28, 29, 30))),
    "Town Hall Questions": ("ST05", ids("T", 26, 144, skip=(30, 34, 99, 103, 111, 121, 122, 123, 124))),
    "Lobbyist Questions": ("ST20", ids("L", 21, 108, skip=(63, 70, 78, 84, 93, 95))),
    "Study Session Questions": ("ST21", ids("B", 21, 60, skip=(26,))),
    "Media Ambush Questions": ("ST19", ["A21", "A22"]),
}
# Room tabs: A id, B question, C theme, D-I grades, J party, K org.
# Stage Questions: A id, B stage, C question, D theme, E-J grades, K party, N org.
SQ = "Stage Questions"
used = [int(v["A"][1:]) for v in w.rows(SQ).values() if re.fullmatch(r"S\d+", v.get("A", ""))]
nxt = max(used) + 1
style_row = w.last_data_row(SQ)
log = []
for tab, (stage, qids) in MOVES.items():
    rows = w.rows(tab)
    by_id = {v.get("A"): r for r, v in rows.items()}
    for qid in qids:
        r = by_id[qid]
        t = w.typed_row(tab, r)
        new = {"A": f"S{nxt}", "B": stage, "C": t["B"], "D": t["C"],
               "E": t["D"], "F": t["E"], "G": t["F"], "H": t["G"], "I": t["H"], "J": t["I"]}
        if t.get("J"): new["K"] = t["J"]
        if t.get("K"): new["N"] = t["K"]
        w.append_row(SQ, new, style_row=style_row)
        log.append((tab, qid, f"S{nxt}", stage, t["B"]))
        nxt += 1
    # Remove from the pool, bottom first. Press Questions has a COUNTIF summary row
    # (D36:I36 counts the S grades over D2:D35); take its formula out, delete, then
    # put it back over the shorter range with fresh cached counts.
    p = w.sheet[tab]
    x = w.files[p].decode()
    f = re.search(r'<f t="shared" ref="D(\d+):I\1" si="(\d+)">COUNTIF\(D2:D(\d+),"S"\)</f>', x)
    if f:
        x = re.sub(r'<f[^>]*/>|<f[^>]*>.*?</f>', '', x)
        w.files[p] = x.encode()
    for qid in sorted(qids, key=lambda q: by_id[q], reverse=True):
        w.delete_row(tab, by_id[qid])
    if f:
        n = len(qids)
        sumrow, last = int(f.group(1)) - n, int(f.group(3)) - n
        data = [v for k, v in w.rows(tab).items() if 2 <= k <= last]
        for i, col in enumerate("DEFGHI"):
            cnt = sum(1 for v in data if v.get(col) == "S")
            formula = f'COUNTIF({col}2:{col}{last},"S")'
            w.set_cell(tab, sumrow, col, cnt, formula=formula)
w.save()
with open("tools/workbook/archive/b16/b16_2_moved.tsv", "w") as fh:
    fh.write("from tab\told id\tnew id\tstage\tquestion\n")
    for row in log:
        fh.write("\t".join(row) + "\n")
print(len(log), "moved")
