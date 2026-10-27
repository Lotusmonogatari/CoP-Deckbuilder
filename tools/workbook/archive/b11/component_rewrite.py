"""Rewrites the cue and transition rows already written by component_content.py
with the current frames (same row order and rotation). Run after editing
component_frames.py. Raw XML, idempotent."""
import sys, json
sys.path.insert(0, "tools/workbook"); sys.path.insert(0, "tools/workbook/archive/b11")
from wbx import WB
from component_frames import PLAYER, OPPONENT, STAFF_LINES, THOUGHTS, SUITS
comps = {c['component_id']: c for c in json.load(open('data/bill_components.json'))}
boosters = json.load(open('data/boosters.json')); boosters = boosters if isinstance(boosters, list) else list(boosters.values())
org = {b['booster_id']: b['name_en'] for b in boosters}
def cap(s): return s[0].upper() + s[1:]
def ctx(c):
    owner = org[c['owner']]
    losers = [x['target'] for x in (c.get('loses') or []) if x['target'] in org]
    return dict(p=c['phrase'], owner=owner, rival=org[losers[0]] if losers else 'its critics',
                owner_s=owner + ("'" if owner.endswith('s') else "'s"))
w = WB('design/Game_Workbook.xlsx')
n = 0
for tab, frames in (('Player Cues', PLAYER), ('Opponent Cues', OPPONENT)):
    for r, v in w.rows(tab).items():
        cid = v.get('L')
        if cid in comps and v.get('B') in SUITS:
            f = ctx(comps[cid]); k = int(cid[2:]); i = SUITS.index(v['B'])
            lines = [cap(s.format(**f)) for s in frames[v['B']]]
            for col, line in zip('EFGHI', [lines[(k + i + j) % 6] for j in range(5)]):
                w.set_cell(tab, r, col, line, style_from=r)
            n += 1
seen = {}
for r, v in sorted(w.rows('Transition Dialogue').items()):
    cid = v.get('H')
    if cid in comps:
        f = ctx(comps[cid]); k = int(cid[2:]); j = seen.get(cid, 0); seen[cid] = j + 1
        if j < 2:
            who, line, reply = STAFF_LINES[(k + j) % 3]
            w.set_cell('Transition Dialogue', r, 'D', cap(line.format(**f)), style_from=r)
        else:
            w.set_cell('Transition Dialogue', r, 'D', cap(THOUGHTS[k % 4].format(**f)), style_from=r)
        n += 1
w.save(); print('rewrote', n)
