"""Batch 6 (2026-10-18): balance-audit quick wins (design/BALANCE_AUDIT_2026-10-18.md).
Thresholds: Town Hall 60->50, Party Caucus 60->46, Steering Committee 60->40.
Rewards move toward difficulty. Four card fixes. Run from the repo root."""
import re, sys
sys.path.insert(0, 'tools/workbook')
from wbx import WB

w = WB('design/CoP_Starter_Card_Stage_Data.xlsx')
s = w.rows('Stages')
THRESH = {'Town Hall': 50, 'Party Caucus': 46, 'Party Steering Committee': 40}
def r5(v): return int(round(v / 5.0)) * 5
# family -> (xp function, yen function)
REWARD = {
    'Hearing': (lambda v: r5(v * 0.75), None), 'Committee': (lambda v: r5(v * 0.75), None),
    'Policy Study': (lambda v: 55, None), 'Policy Study Session': (lambda v: 55, None),
    'TV Debate': (lambda v: 55, None),
    'Lobbyist Meeting': (lambda v: 75, lambda v: 50000),
    'Press Conference': (lambda v: 60, lambda v: 30000),
    'Floor Debate': (lambda v: 80, lambda v: 30000),
    'Special Committee': (lambda v: 70, lambda v: 20000),
}
cache = []
for row in sorted(s):
    if row == 1:
        continue
    name = s[row].get('B', '')
    fam = re.sub(r'\s+(on|at|for)\s+.*$', '', name)
    if fam in THRESH:
        w.set_cell('Stages', row, 'I', THRESH[fam])
        cache.append((row, THRESH[fam] / float(s[row]['H'])))
    if fam in REWARD:
        xp_f, yen_f = REWARD[fam]
        w.set_cell('Stages', row, 'AB', xp_f(float(s[row]['AB'])))
        if yen_f:
            w.set_cell('Stages', row, 'Z', yen_f(float(s[row]['Z'])))
# Win % is a shared formula: refresh its cached value only
p = w.sheet['Stages']
x = w.files[p].decode()
for row, v in cache:
    x = re.sub(r'(<c r="J%d"[^>]*>(?:<f[^>]*/>|<f[^>]*>.*?</f>))<v>[^<]*</v>' % row, r'\g<1><v>%s</v>' % repr(v), x, count=1)
w.files[p] = x.encode()

c = w.rows('Cards')
def card(cid): return next(k for k, v in c.items() if v.get('A') == cid)
w.set_cell('Cards', card('C05'), 'N', 0); w.set_cell('Cards', card('C05'), 'P', 'Gain 5.')
w.set_cell('Cards', card('C43'), 'L', 1); w.set_cell('Cards', card('C43'), 'P', 'Opponent −2. Guard 1.')
w.set_cell('Cards', card('C20'), 'N', 3); w.set_cell('Cards', card('C20'), 'P', 'Opponent −7. Gaffe +3.')
w.set_cell('Cards', card('C21'), 'I', 1); w.set_cell('Cards', card('C21'), 'P', 'Gain 3. Guard 5 this turn. Gaffe +2.')
w.save()
