"""Batch 9 (2026-10-18): bill-specific stages for the 30 older bill levels.
Clones each generic stage a bill level uses into a stage about that bill, copies
the base row's numbers, extends every table that names the base stage, adds a
Background ID column (every stage resolves to a default background), and builds
bill-specific Office Hours stages with a visitor and two dilemma questions.
Run from the repo root: python3 tools/workbook/archive/batch9_bill_stages_2026-10-18.py"""
import json, re, shutil, sys, collections
sys.path.insert(0, 'tools/workbook')
from wbx import WB, n2col, col2n
import openpyxl

PATH = 'design/Game_Workbook.xlsx'
tmp = PATH + '.read.xlsx'
shutil.copy(PATH, tmp)
ox = openpyxl.load_workbook(tmp, read_only=True, data_only=True)
def orows(n): return [list(r) for r in ox[n].iter_rows(values_only=True)]

levels = json.load(open('data/levels.json'))
bills = json.load(open('data/floor_votes.json'))
law = json.load(open('data/law_effects.json'))
boosters = {b['booster_id']: b for b in json.load(open('data/boosters.json'))}
S_json = {s['stage_id']: s for s in json.load(open('data/stages.json'))}
opps = json.load(open('data/opponents.json'))
GENERIC = {f'ST{i:02d}' for i in range(1, 24)} - {'ST22', 'ST23'}

# ---------------------------------------------------------------- plan
def topic(name):
    t = re.sub(r'\s+Act$', '', name.strip())
    return t
clones = {}           # (bill, base) -> new stage id
order = []            # (bill, base, level, slot)
n = max(int(s[2:]) for s in S_json) 
bill_levels = []
for l in levels:
    slots = [l.get(f'stage_{i}') for i in range(1, 11)]
    bill = next((x for x in slots if str(x or '').startswith('BI')), None)
    if not bill or int(bill[2:]) > 30:
        continue
    bill_levels.append((l['level_id'], bill, slots))
    for si, x in enumerate(slots, start=1):
        if x in GENERIC and (bill, x) not in clones:
            n += 1
            clones[(bill, x)] = f'ST{n}'
            order.append((bill, x, l['level_id'], si))
print(len(clones), 'clones, ids up to', f'ST{n}')

def clone_name(base_name, bill_name):
    t = topic(bill_name)
    if base_name == 'Office Hours':
        return f'Office Hours: {t}'
    if base_name.startswith('Committee') or base_name.startswith('Special Committee'):
        return f'{base_name}: {t}'
    return f'{base_name} on {t}'

# background defaults for existing topic stages
COMMITTEE_STAGE = {S_json[i]['name_en']: i for i in S_json if i in ('ST09','ST10','ST11','ST12','ST13','ST14','ST15','ST16','ST17')}
FAMILY_BG = {'Town Hall': 'ST05', 'Party Caucus': 'ST03', 'Press Conference': 'ST04', 'Policy Study': 'ST21',
             'TV Debate': 'ST06', 'Lobbyist Meeting': 'ST20', 'Media Ambush': 'ST19', 'Office Hours': 'ST07'}
def family(name):
    if name.startswith('Office Hours'): return 'Office Hours'
    return re.sub(r'\s+(on|at|for)\s+.*$', '', name)
def default_bg(sid):
    s = S_json[sid]
    if int(sid[2:]) <= 23: return None
    f = family(s['name_en'])
    if f == 'Hearing':
        roles = collections.Counter(o['role'] for o in opps if sid in (o['stages'] or []))
        for role, _ in roles.most_common():
            if role in COMMITTEE_STAGE: return COMMITTEE_STAGE[role]
        return None
    return FAMILY_BG.get(f)

w = WB(PATH)

# ---------------------------------------------------------------- Affinity
aff = orows('Affinity')
hdr = aff[0]; last_col = len(hdr)
col_of = {h: i for i, h in enumerate(hdr) if h}
firstcol = last_col + 1
r_style = lambda r: w.sty('Affinity', f'V{r}')
new_aff = {}
for k, (key, sid) in enumerate(clones.items()):
    col = n2col(firstcol + k)
    bill, base = key
    bi = col_of[base]
    name = clone_name(S_json[base]['name_en'], bills[bill]['bill_name'])
    w.set_cell('Affinity', 1, col, sid, style=r_style(1))
    vals = [aff[j][bi] for j in range(1, 7)]
    for j, v in enumerate(vals):
        w.set_cell('Affinity', j + 2, col, v, style=r_style(j + 2))
    w.set_cell('Affinity', 9, col, name, style=r_style(9))
    w.set_cell('Affinity', 10, col, round(sum(vals) / 6, 4), formula=f'AVERAGE({col}2:{col}7)', style=r_style(10))
    new_aff[sid] = vals
LASTAFF = n2col(firstcol + len(clones) - 1)
suits = [aff[j][0] for j in range(1, 7)]

# ---------------------------------------------------------------- Stages
S = orows('Stages'); BYID = {r[0]: r for r in S[1:] if r[0]}
CL = [n2col(i + 1) for i in range(len(S[0]))]
BGCOL = n2col(len(S[0]) + 1)
w.set_cell('Stages', 1, BGCOL, 'Background ID')
r0 = w.last_data_row('Stages')
# default background for existing stages
for rr in range(2, r0 + 1):
    pass
srows = w.rows('Stages')
for rr, v in srows.items():
    if rr == 1: continue
    sid = v.get('A')
    if sid in S_json:
        bg = default_bg(sid)
        if bg: w.set_cell('Stages', rr, BGCOL, bg, style_from=rr - 1)
new_stage_rows = {}
for k, ((bill, base), sid) in enumerate(clones.items()):
    r = r0 + 1 + k
    v = list(BYID[base]); v[0] = sid
    v[1] = clone_name(S_json[base]['name_en'], bills[bill]['bill_name'])
    thr, bm = v[8], v[7]
    for i, val in enumerate(v):
        col = CL[i]
        if i == 9:
            w.set_cell('Stages', r, col, round(thr / bm, 4) if isinstance(thr, (int, float)) and isinstance(bm, (int, float)) and bm else None,
                       formula=f'IF(AND(ISNUMBER(H{r}),ISNUMBER(I{r})),IF(H{r}=0,"",I{r}/H{r}),"varies")', style_from=r - 1) if isinstance(thr, (int, float)) else None
        elif i == 22:
            w.set_cell('Stages', r, col, round(sum(x or 0 for x in v[16:22]), 4), formula=f'SUM(Q{r}:V{r})', style_from=r - 1)
        elif i == 23:
            if v[4] == 'Combat':
                vals = new_aff[sid]
                fav = suits[max(range(6), key=lambda j: (vals[j], -j))]
            else:
                fav = '—'
            w.set_cell('Stages', r, col, fav,
                       formula=f'IF(E{r}<>"Combat","—",IFERROR(INDEX(Affinity!$A$2:$A$7,MATCH(MAX(INDEX(Affinity!$B$2:${LASTAFF}$7,0,MATCH(A{r},Affinity!$B$1:${LASTAFF}$1,0))),INDEX(Affinity!$B$2:${LASTAFF}$7,0,MATCH(A{r},Affinity!$B$1:${LASTAFF}$1,0)),0)),"—"))', style_from=r - 1)
        elif val is not None:
            w.set_cell('Stages', r, col, val, style_from=r - 1)
    w.set_cell('Stages', r, BGCOL, base if int(base[2:]) <= 23 else base, style_from=r - 1)
    new_stage_rows[sid] = r

# ---------------------------------------------------------------- extend list/single cells
by_base = collections.defaultdict(list)
for (bill, base), sid in clones.items():
    by_base[base].append(sid)

def extend_list(sheet, col):
    rows = w.rows(sheet)
    for r, v in rows.items():
        cell = v.get(col)
        if r == 1 or not cell: continue
        items = [x.strip() for x in cell.split(';') if x.strip()]
        add = []
        for base, news in by_base.items():
            if base in items:
                add += [x for x in news if x not in items and x not in add]
        if add: w.set_cell(sheet, r, col, '; '.join(items + add))
for sheet, col in (('Opponents', 'I'), ('Stage Questions', 'B'), ('Player Cues', 'D'), ('Opponent Cues', 'J'),
                   ('Visitors', 'F'), ('Modifiers', 'L')):
    extend_list(sheet, col)

def duplicate_rows(sheet, stage_col, id_col, prefix, width):
    rows = w.rows(sheet)
    top = max(int(v['A'][len(prefix):]) for v in rows.values() if re.fullmatch(prefix + r'\d+', v.get('A', '')))
    adds = []
    for r, v in sorted(rows.items()):
        if r == 1: continue
        base = v.get(stage_col)
        if base in by_base:
            for sid in by_base[base]:
                adds.append((v, sid))
    for v, sid in adds:
        top += 1
        d = dict(v); d['A'] = f'{prefix}{top:0{width}d}' if sheet != 'Transition Dialogue' else f'{prefix}{top}'
        d[stage_col] = sid
        w.append_row(sheet, d)
duplicate_rows('Transition Cast', 'B', 'A', 'TC', 2)
duplicate_rows('Transition Backgrounds', 'B', 'A', 'TB', 2)
duplicate_rows('Transition Dialogue', 'C', 'A', 'TD', 1)

# ---------------------------------------------------------------- Levels
lrows = w.rows('Levels'); lbyid = {v['A']: r for r, v in lrows.items() if r > 1 and 'A' in v}
for level_id, bill, slots in bill_levels:
    r = lbyid[level_id]
    for si, x in enumerate(slots, start=1):
        if (bill, x) in clones:
            w.set_cell('Levels', r, n2col(8 + si), clones[(bill, x)])

# ---------------------------------------------------------------- Office Hours: visitors + dilemma questions
def sides(bill):
    pos, neg = [], []
    for row in law:
        if row['bill_id'] == bill and row['outcome'] == 'Passed' and row['timing'] in (None, 'Once'):
            for e in row['effects'] or []:
                t = e['target']
                if not t.startswith('BO') or boosters[t]['tier'] == 'Party': continue
                (pos if e['delta'] > 0 else neg).append((abs(e['delta']), t))
    pos.sort(reverse=True); neg.sort(reverse=True)
    return [b for _, b in pos], [b for _, b in neg]

vrows = w.rows('Visitors'); vtop = max(int(v['A'][2:]) for v in vrows.values() if re.fullmatch(r'VI\d+', v.get('A', '')))
qrows = w.rows('Visitor Questions'); qtop = max(int(v['A'][2:]) for v in qrows.values() if re.fullmatch(r'VQ\d+', v.get('A', '')))
overrides = []
Q = [
 ("Will you stand behind the {t}?",
  [("Yes. It helps people like me.", [(0, 3), (1, 1), (2, -2)], "Good. {W} will remember that.", "Nods slowly."),
   ("No. It goes too far.", [(2, 3), (0, -3)], "Then you are with {L}. Understood.", "Folds arms."),
   ("I want to hear both sides first.", [(0, 1), (2, -1)], "Fair enough. Do not take too long.", "Shrugs."),
   ("That is a question for the party.", [(0, -2), (2, -1)], "So you will not say. Noted.", "Looks away.")]),
 ("Who should pay for the {t}?",
  [("Whoever gains from it.", [(2, 3), (0, -1)], "Fair. {L} will not love it.", "Raises an eyebrow."),
   ("The whole country, through taxes.", [(0, 3), (1, 1), (2, -2)], "Taxes it is. {W} is relieved.", "Smiles thinly."),
   ("Nobody. It should cost nothing.", [(1, 1), (2, -1)], "Nothing costs nothing. But thank you.", "Laughs quietly."),
   ("I will find out and tell you.", [(0, -1), (1, -1)], "Please do. I will ask again.", "Sighs.")])]
FALL = [b for b in boosters if boosters[b]['tier'] != 'Party']
def fmt(eff, W1, W2, L1):
    ids = [W1, W2 or W1, L1]
    out = []
    for idx, d in eff:
        out.append(f'{ids[idx]} {d:+d}')
    # merge duplicate targets
    merged = collections.OrderedDict()
    for part in out:
        t, d = part.split(); merged[t] = merged.get(t, 0) + int(d)
    return '; '.join(f'{t} {d:+d}' for t, d in merged.items() if d)
for (bill, base), sid in clones.items():
    if base != 'ST07': continue
    win, lose = sides(bill)
    W1 = win[0] if win else FALL[0]
    W2 = win[1] if len(win) > 1 else None
    L1 = lose[0] if lose else next(b for b in FALL if b != W1)
    org = boosters[W1]
    vtop += 1; vid = f'VI{vtop}'
    short = org['name_en']
    reward = f'{W1} +1-3' + (f'; {W2} +1' if W2 else '')
    penalty = f'{W1} -3; {L1} -2'
    w.append_row('Visitors', {'A': vid, 'B': f'{short} Representative', 'C': f"{org['name_jp']}の代表", 'D': f"{org['romaji']} no Daihyō",
                              'E': f'{short} Representative', 'F': sid, 'G': reward, 'H': penalty})
    t = 'the ' + topic(bills[bill]['bill_name'])
    for text, choices in Q:
        qtop += 1
        d = {'A': f'VQ{qtop}', 'B': vid, 'C': text.format(t=t), 'H': 'A'}
        for letter, (ch, eff, resp, react) in zip('DEFG', choices):
            d[letter] = ch
        for col, (ch, eff, resp, react) in zip('MNOP', choices):
            d[col] = fmt(eff, W1, W2, L1)
        for col, (ch, eff, resp, react) in zip('QRST', choices):
            d[col] = resp.format(W=boosters[W1]['name_en'], L=boosters[L1]['name_en'])
        for col, (ch, eff, resp, react) in zip('UVWX', choices):
            d[col] = react
        d['I'] = choices[0][2].format(W=boosters[W1]['name_en'], L=boosters[L1]['name_en'])
        d['J'] = 'Then we do not agree.'
        d['K'] = choices[0][3]; d['L'] = 'Frowns.'
        w.append_row('Visitor Questions', d)
    lvl = next(l for l, b, slots in bill_levels if b == bill)
    slot = next(si for si, x in enumerate(next(s for l, b, s in bill_levels if b == bill), start=1) if x == 'ST07')
    overrides.append({'level_id': lvl, 'slot': slot, 'visitor_id': vid})
w.save()

# hand-maintained pins
ovp = 'data/level_visitor_overrides.json'
ov = json.load(open(ovp)); ov['overrides'] += overrides
ov['_README'].append('2026-10-18: LV31-LV60 pin their own bill-specific Office Hours visitor to the Office Hours slot where they have one.')
json.dump(ov, open(ovp, 'w'), indent=2, ensure_ascii=False)
print('done:', len(clones), 'stages;', len(overrides), 'visitors pinned')
