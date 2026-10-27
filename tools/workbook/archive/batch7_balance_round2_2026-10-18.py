"""Batch 7 (2026-10-18): balance round 2 (design/BALANCE_AUDIT_2026-10-18.md).
Thresholds: Town Hall 50->53, Party Caucus 46->49, Steering Committee 40->43.
Rewards: Town Hall, Caucus and Steering up. Tier 3 cards +2 on their main number.
Run from the repo root."""
import re, sys
sys.path.insert(0, 'tools/workbook')
from wbx import WB

w = WB('design/Game_Workbook.xlsx')
s = w.rows('Stages')
THRESH = {'Town Hall': 53, 'Party Caucus': 49, 'Party Steering Committee': 43}
REWARD = {'Town Hall': (70, 45000), 'Party Caucus': (90, 20000), 'Party Steering Committee': (90, None)}
cache = []
for row in sorted(s):
    if row == 1:
        continue
    fam = re.sub(r'\s+(on|at|for)\s+.*$', '', s[row].get('B', ''))
    if fam in THRESH:
        w.set_cell('Stages', row, 'I', THRESH[fam])
        cache.append((row, THRESH[fam] / float(s[row]['H'])))
        xp, yen = REWARD[fam]
        w.set_cell('Stages', row, 'AB', xp)
        if yen:
            w.set_cell('Stages', row, 'Z', yen)
p = w.sheet['Stages']
x = w.files[p].decode()
for row, v in cache:
    x = re.sub(r'(<c r="J%d"[^>]*>(?:<f[^>]*/>|<f[^>]*>.*?</f>))<v>[^<]*</v>' % row, r'\g<1><v>%s</v>' % repr(v), x, count=1)
w.files[p] = x.encode()

c = w.rows('Cards')
def card(cid): return next(k for k, v in c.items() if v.get('A') == cid)
for cid, col, old, new, pat in [
    ('C04', 'J', 6, 8, 'Gain 6;'), ('C08', 'J', 9, 11, 'Gain 9.'), ('C16', 'K', 6, 8, 'Opponent −6.'),
    ('C29', 'J', 6, 8, 'Gain 6.'), ('C37', 'J', 6, 8, 'Gain 6.'), ('C39', 'J', 7, 9, 'Gain 7.'),
    ('C44', 'K', 6, 8, 'Opponent −6.'), ('C49', 'K', 9, 11, 'Opponent −9.'), ('C53', 'J', 7, 9, 'Gain 7.')]:
    row = card(cid)
    assert int(c[row][col]) == old, (cid, c[row][col])
    w.set_cell('Cards', row, col, new)
    text = c[row]['P']
    assert pat in text, (cid, text)
    w.set_cell('Cards', row, 'P', text.replace(pat, pat.replace(str(old), str(new)), 1))
w.save()
