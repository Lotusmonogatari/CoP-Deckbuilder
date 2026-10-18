"""Content 1 (2026-10-18): replaces the templated bill-scoped player and
opponent cue lines with facet-written ones, and adds three hand-written
questions per bill. Run from the repo root."""
import sys, json, re
sys.path.insert(0, "tools/workbook"); sys.path.insert(0, "tools/workbook/archive/b8")
from wbx import WB
from bill_frames import PLAYER, OPPONENT, SUITS
from bill_questions import Q
SUITS_Q = ['Earnest', 'Emotional', 'Appeal', 'Data Driven', 'Divisive', 'Duplicitous']
G = {'cost': "S M M S W M", 'need': "S S M M M W", 'critic': "M M S M S W",
     'backer': "M S M W M S", 'local': "M S S M M W", 'procedure': "M W M S W S",
     'risk': "S M M S M W", 'alt': "M M S M W S"}
facets = json.load(open('design/reference/bill_facets.json')); facets.pop('_README')
bills = json.load(open('data/floor_votes.json')); bills = bills if isinstance(bills, list) else list(bills.values())
name = {b['bill_id']: b['bill_name'] for b in bills}
def short(bid):
    n = name[bid]
    return 'the ' + n if len(n.split()) <= 5 else 'this bill'
def fill(frame, bid):
    f = dict(facets[bid]); f['b'] = short(bid)
    s = frame.format(**f)
    return s[0].upper() + s[1:]
def five(frames, bid, k):
    """Five frames, rotating the start by bill and style so neighbouring bills
    differ; a frame that fills out past 20 words is passed over if possible."""
    start = (int(bid[2:]) + k) % len(frames)
    order = [frames[(start + i) % len(frames)] for i in range(len(frames))]
    short_ones = [f for f in order if len(fill(f, bid).split()) <= 20]
    chosen = short_ones[:5]
    for f in order:
        if len(chosen) >= 5:
            break
        if f not in chosen:
            chosen.append(f)
    return chosen
w = WB('design/CoP_Starter_Card_Stage_Data.xlsx')
n_p = n_o = 0
for r, v in w.rows('Player Cues').items():
    bid = v.get('J'); st = v.get('K')
    if bid in name and st in ('Support', 'Oppose') and v.get('B') in SUITS:
        k = SUITS.index(v['B'])
        for col, fr in zip('EFGHI', five(PLAYER[(v['B'], st)], bid, k)):
            w.set_cell('Player Cues', r, col, fill(fr, bid), style_from=r)
        n_p += 1
for r, v in w.rows('Opponent Cues').items():
    bid = v.get('K')
    if bid in name and not v.get('D') and v.get('B') in SUITS and v.get('C') in ('attack', 'gain', 'block'):
        k = SUITS.index(v['B']) + ('attack', 'gain', 'block').index(v['C'])
        for col, fr in zip('EFGHI', five(OPPONENT[(v['B'], v['C'])], bid, k)):
            w.set_cell('Opponent Cues', r, col, fill(fr, bid), style_from=r)
        n_o += 1
rows = w.rows('Stage Questions'); last = max(rows)
nid = max(int(v['A'][1:]) for v in rows.values() if (v.get('A') or '').startswith('S') and v['A'][1:].isdigit()) + 1
n_q = 0
for bid, items in Q.items():
    for text, prof in items:
        row = {'A': f'S{nid}', 'C': text, 'D': f"{name[bid]} debate", 'L': bid}
        for col, g in zip('EFGHIJ', G[prof].split()):
            row[col] = g
        w.append_row('Stage Questions', row, style_row=last)
        nid += 1; n_q += 1
w.save()
print('player rows', n_p, 'opponent rows', n_o, 'questions', n_q)
