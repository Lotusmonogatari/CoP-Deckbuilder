"""Content 2A (2026-10-18): personal Opponent Cue rows for each opponent's
second and third styles. Run from the repo root."""
import sys, json, re
sys.path.insert(0, "tools/workbook"); sys.path.insert(0, "tools/workbook/archive/b7")
from wbx import WB
from oc_styles import STYLE, TOPIC, CARE
opps = json.load(open("data/opponents.json"))
w = WB("design/CoP_Starter_Card_Stage_Data.xlsx")
rows = w.rows("Opponent Cues")
last = max(rows)
nid = max(int(v["A"][2:]) for v in rows.values() if v.get("A", "").startswith("OC")) + 1
VERBS = ["attack", "gain", "block"]
def words(t): return len(re.sub(r"[.,!?]|\.\.\.", " ", t).split())
added = 0
for o in opps:
    num = int(o["opp_id"][2:])
    topic = TOPIC.get(o["role"], "this")
    care = CARE.get(o.get("party"), "ordinary people")
    seen = {o["suit_1"]}
    slot = 0
    for suit in (o["suit_2"], o["suit_3"]):
        slot += 1
        if suit in seen: continue
        seen.add(suit)
        for vi, vb in enumerate(VERBS):
            g, t, p = STYLE[suit][vb]
            start = (num * 7 + slot * 5 + vi * 3) % len(g)
            gen = [g[(start + k * 4) % len(g)] for k in range(3)]
            top = None; par = None
            for k in range(len(t)):
                c = t[(num + slot + k) % len(t)].replace("{topic}", topic)
                c = c[0].upper() + c[1:]
                if words(c) <= 9: top = c; break
            for k in range(len(p)):
                c = p[(num + k) % len(p)].replace("{care}", care)
                c = c[0].upper() + c[1:]
                if words(c) <= 9: par = c; break
            lines = [gen[0], top or gen[1], gen[1], par or gen[2], gen[2]]
            # dedupe within the row
            out = []
            for l in lines:
                if l not in out: out.append(l)
            while len(out) < 5:
                out.append(g[(start + 2 + len(out)) % len(g)])
                if out[-1] in out[:-1]: out.pop(); start += 1
            cells = {"A": f"OC{nid}", "B": suit, "C": vb, "D": o["opp_id"]}
            for i, col in enumerate("EFGHI"): cells[col] = out[i]
            w.append_row("Opponent Cues", cells, style_row=last)
            nid += 1; added += 1
w.save()
print("added", added, "next", nid)
