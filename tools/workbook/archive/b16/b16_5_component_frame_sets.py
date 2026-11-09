"""Writing review group 2, item G (2026-11-09, Cameron decision #56).
Rewrites the component (bill-part) Player Cues and Opponent Cues rows of every part
whose slot uses frame set B or C (component_frames_v2.py), with the same rotation
as b11/component_rewrite.py (five of six frames, offset by part number and style).
Set A rows (slots X and Z) are left exactly as they are. Opponent rows also get the
Side of each new line. Only the six main rows per part (one per style, five lines)
are touched; the extra one-line For rows are not. Run from the repo root."""
import sys, json, re
from collections import Counter
sys.path.insert(0, "tools/workbook"); sys.path.insert(0, "tools/workbook/archive/b16")
from wbx import WB
from component_frames_v2 import SUITS, SLOT_SET, PLAYER, OPPONENT

comps = {c['component_id']: c for c in json.load(open('data/bill_components.json'))}
def cap(s): return s[0].upper() + s[1:]

w = WB('design/Game_Workbook.xlsx')
# The people each part serves, exactly as the data's current Divisive line names them.
PATS = [r"owes (.+?)(?:'s members)? an answer\.$", r"are blocking (.+)\.$",
        r"decision against (.+)\. We should", r"or we leave (.+) behind\.$"]
who = {}
for r, v in w.rows('Player Cues').items():
    cid = v.get('L')
    if cid in comps and v.get('B') == 'Divisive':
        got = Counter()
        for col in 'EFGHI':
            for p in PATS:
                m = re.search(p, v.get(col, ''))
                if m and m.group(1) != 'people' and m.group(1).startswith(('the members of', 'constituents')):
                    got[m.group(1)] += 1
        who[cid] = got.most_common(1)[0][0] if got else 'the people it helps'

n = Counter()
for tab, frames in (('Player Cues', PLAYER), ('Opponent Cues', OPPONENT)):
    for r, v in w.rows(tab).items():
        cid = v.get('L')
        if cid not in comps or v.get('B') not in SUITS or not v.get('I'):
            continue
        s = SLOT_SET[comps[cid]['slot']]
        if s == 'A':
            continue
        k = int(cid[2:]); i = SUITS.index(v['B'])
        fill = dict(p=comps[cid]['phrase'], who=who[cid], Who=cap(who[cid]))
        pool = frames[s][v['B']]
        picks = [pool[(k + i + j) % 6] for j in range(5)]
        for j, col in enumerate('EFGHI'):
            f = picks[j]
            text, side = (f if isinstance(f, tuple) else (f, None))
            w.set_cell(tab, r, col, cap(text.format(**fill)), style_from=r)
            if tab == 'Opponent Cues':
                w.set_cell(tab, r, 'MNOPQ'[j], side, style_from=r)
        n[(tab, s)] += 1
w.save()
print(dict(n))
