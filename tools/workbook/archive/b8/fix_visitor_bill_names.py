"""2026-10-18: the bill visitors VI60-VI70 asked about 'the the Ainu Heritage and Language'
(doubled article, 'Act' dropped). Rewrites those question texts with the bill's full name."""
import sys, json, re
sys.path.insert(0, "tools/workbook")
from wbx import WB
ov = json.load(open('data/level_visitor_overrides.json'))
ov = ov if isinstance(ov, list) else ov.get('overrides', ov.get('rows', []))
levels = {l['level_id']: l for l in json.load(open('data/levels.json'))}
bills = json.load(open('data/floor_votes.json')); bills = bills if isinstance(bills, list) else list(bills.values())
name = {b['bill_id']: b['bill_name'] for b in bills}
vis_bill = {}
for o in ov:
    l = levels.get(o['level_id'])
    if not l: continue
    b = next((l.get(f'stage_{i}') for i in range(1, 11) if str(l.get(f'stage_{i}') or '').startswith('BI')), None)
    if b: vis_bill[o['visitor_id']] = name[b]
w = WB('design/Game_Workbook.xlsx')
n = 0
for r, v in w.rows('Visitor Questions').items():
    vid = v.get('B'); t = v.get('C') or ''
    if vid in vis_bill and 'the the ' in t:
        t2 = re.sub(r'the the .*?\?', 'the ' + vis_bill[vid] + '?', t)
        w.set_cell('Visitor Questions', r, 'C', t2, style_from=r); n += 1
w.save(); print('fixed', n)
