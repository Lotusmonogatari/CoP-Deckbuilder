"""Patron Bills steps 5 and 6 (2026-10-19): component-scoped content.
Usage: python3 tools/workbook/archive/b11/component_content.py XYV   (step 5)
       python3 tools/workbook/archive/b11/component_content.py ZWABCD (step 6)
Per component: 8 questions + 1 Question Themes row, 6 player cue rows (one per
style), 6 opponent cue rows (attack), 2 staff transition lines and 1 player
thought. Idempotent: a component that already has questions is skipped."""
import sys, json, re
sys.path.insert(0, "tools/workbook"); sys.path.insert(0, "tools/workbook/archive/b11")
from wbx import WB
from component_frames import PLAYER, OPPONENT, QUESTIONS, STAFF_LINES, THOUGHTS, SUITS

slots = sys.argv[1]
comps = json.load(open('data/bill_components.json'))
boosters = json.load(open('data/boosters.json')); boosters = boosters if isinstance(boosters, list) else list(boosters.values())
org = {b['booster_id']: b['name_en'] for b in boosters}
w = WB('design/Game_Workbook.xlsx')

def nxt(tab, prefix, col='A'):
    rows = w.rows(tab)
    return max(int(v[col][len(prefix):]) for v in rows.values()
               if str(v.get(col, '')).startswith(prefix) and str(v[col])[len(prefix):].isdigit()) + 1

done = {v.get('M') for v in w.rows('Stage Questions').values()}
sq, pl, oc, td = nxt('Stage Questions', 'S'), nxt('Player Cues', 'PL'), nxt('Opponent Cues', 'OC'), nxt('Transition Dialogue', 'TD')
last = {t: max(w.rows(t)) for t in ('Stage Questions', 'Player Cues', 'Opponent Cues', 'Transition Dialogue', 'Question Themes')}
themes = {v.get('A') for v in w.rows('Question Themes').values()}

def cap(s): return s[0].upper() + s[1:]
n = 0
for c in comps:
    if c['slot'] not in slots or c['component_id'] in done:
        continue
    cid = c['component_id']; p = c['phrase']
    owner = org[c['owner']]
    losers = [x['target'] for x in (c.get('loses') or []) if x['target'] in org]
    rival = org[losers[0]] if losers else 'its critics'
    theme = c['short_label']
    assert theme not in themes, theme
    themes.add(theme)
    owner_s = owner + ("'" if owner.endswith('s') else "'s")
    # {owner_s} is the possessive WITHOUT the apostrophe-s, so frames read "{owner_s} members"
    f = dict(p=p, owner=owner, rival=rival, owner_s=owner_s)
    def fill(s): return cap(s.format(**f)).replace(cap(owner) + "'s", owner + "'s") if False else cap(s.format(**f))
    k = int(cid[2:])
    # Question Themes row
    w.append_row('Question Themes', {'A': theme, 'B': c['owner'], 'D': '; '.join(dict.fromkeys(losers)) or None,
        'C': "Draft 2026-10-19: a patron bill component. Pleases the organization that wants it and sets back who it costs (Claude's draft)."},
        style_row=last['Question Themes'])
    for stem, prof in QUESTIONS:
        text = stem.format(p=p, Owner=owner)
        row = {'A': f'S{sq}', 'C': text, 'D': theme, 'M': cid}
        for col, g in zip('EFGHIJ', prof.split()):
            row[col] = g
        w.append_row('Stage Questions', row, style_row=last['Stage Questions']); sq += 1
    for i, suit in enumerate(SUITS):
        lines = [fill(s) for s in PLAYER[suit]]
        order = [lines[(k + i + j) % 6] for j in range(6)][:5]
        row = {'A': f'PL{pl}', 'B': suit, 'E': order[0], 'F': order[1], 'G': order[2], 'H': order[3], 'I': order[4], 'L': cid}
        w.append_row('Player Cues', row, style_row=last['Player Cues']); pl += 1
        lines = [fill(s) for s in OPPONENT[suit]]
        order = [lines[(k + i + j) % 6] for j in range(6)][:5]
        row = {'A': f'OC{oc}', 'B': suit, 'C': 'attack', 'E': order[0], 'F': order[1], 'G': order[2], 'H': order[3], 'I': order[4], 'L': cid}
        w.append_row('Opponent Cues', row, style_row=last['Opponent Cues']); oc += 1
    for j in range(2):
        who, line, reply = STAFF_LINES[(k + j) % 3]
        w.append_row('Transition Dialogue', {'A': f'TD{td}', 'B': who, 'D': fill(line.format(**f)) if False else cap(line.format(**f)), 'E': reply, 'H': cid},
                     style_row=last['Transition Dialogue']); td += 1
    w.append_row('Transition Dialogue', {'A': f'TD{td}', 'B': 'PLAYER', 'D': cap(THOUGHTS[k % 4].format(**f)), 'H': cid},
                 style_row=last['Transition Dialogue']); td += 1
    n += 1
w.save()
print('components done', n)
