"""Batch 8 (2026-10-18): the trivially easy room families get harder.
Hearing and Committee thresholds x1.3, Policy Study +8, Floor Debate stays at 51 (canon: a floor majority is 51 of 101)
(from the what-if trials in design/BALANCE_AUDIT_2026-10-18.md). Run from the repo root."""
import re, sys
sys.path.insert(0, 'tools/workbook')
from wbx import WB

w = WB('design/Game_Workbook.xlsx')
s = w.rows('Stages')
cache = []
for row in sorted(s):
    if row == 1:
        continue
    fam = re.sub(r'\s+(on|at|for)\s+.*$', '', s[row].get('B', ''))
    if not s[row].get('H') or not s[row].get('I'):
        continue
    old = float(s[row].get('I'))
    bar = float(s[row]['H'])
    if fam in ('Hearing', 'Committee'):
        new = int(round(old * 1.3))
    elif fam == 'Policy Study':
        new = int(old + 8)
    else:
        continue
    new = min(new, int(bar * 0.9))
    w.set_cell('Stages', row, 'I', new)
    cache.append((row, new / bar))
p = w.sheet['Stages']
x = w.files[p].decode()
for row, v in cache:
    x = re.sub(r'(<c r="J%d"[^>]*>(?:<f[^>]*/>|<f[^>]*>.*?</f>))<v>[^<]*</v>' % row, r'\g<1><v>%s</v>' % repr(v), x, count=1)
w.files[p] = x.encode()
w.save()
print(len(cache), 'rooms')
