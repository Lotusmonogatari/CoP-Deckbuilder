"""Applies extra_frames.py to the workbook (run from the repo root)."""
import sys, json
sys.path.insert(0, "tools/workbook"); sys.path.insert(0, "tools/workbook/archive/b12"); sys.path.insert(0, "tools/workbook/archive/b8")
from wbx import WB
from extra_frames import EXTRA, FIX, SPARE
import bill_frames
SUITS = bill_frames.SUITS
facets = json.load(open('design/reference/bill_facets.json')); facets.pop('_README')
bills = json.load(open('data/floor_votes.json')); bills = bills if isinstance(bills, list) else list(bills.values())
name = {b['bill_id']: b['bill_name'] for b in bills}
def short(bid):
    n = name[bid]; return 'the ' + n if len(n.split()) <= 5 else 'this bill'
def fill(frame, bid):
    f = dict(facets[bid]); f['b'] = short(bid)
    s = frame.format(**f)
    return s[0].upper() + s[1:]
w = WB('design/Game_Workbook.xlsx')
rows = w.rows('Player Cues')
# 1. the lines that read the same under both leans
replaced = 0
for r, v in rows.items():
    bid, st = v.get('J'), v.get('K')
    if bid not in name or st not in ('Support', 'Oppose'):
        continue
    for col in 'EFGHI':
        text = v.get(col)
        for old, new in FIX.items():
            if text == fill(old, bid):
                w.set_cell('Player Cues', r, col, fill(new[st], bid), style_from=r)
                replaced += 1
# 2. ten more per bill, style and stance, as two new rows of five
last_style = max(r for r, v in rows.items() if v.get('J') in name)
nid = max(int(v['A'][2:]) for v in rows.values() if (v.get('A') or '').startswith('PL') and v['A'][2:].isdigit()) + 1
added = 0
for bid in sorted(name):
    for suit in SUITS:
        for st in ('Support', 'Oppose'):
            spares = list(SPARE[(suit, st)])
            lines = []
            for fr in EXTRA[(suit, st)]:
                t = fill(fr, bid)
                if len(t.split()) > 20:
                    t = fill(spares.pop(0), bid)
                lines.append(t)
            for chunk in (lines[:5], lines[5:]):
                row = {'A': f'PL{nid}', 'B': suit, 'J': bid, 'K': st}
                for col, t in zip('EFGHI', chunk):
                    row[col] = t
                w.append_row('Player Cues', row, style_row=last_style)
                nid += 1; added += 1
w.save()
print('replaced', replaced, 'rows added', added)
