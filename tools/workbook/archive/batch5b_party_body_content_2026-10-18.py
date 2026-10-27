"""Batch 5b (2026-10-18): questions that please Party Activists (BO31) and the
Candidate Selection Committee (BO32). Existing themes gain the two bodies;
new themes and 18 new Stage Questions (asked in every Party Caucus) shape
their tastes: Activists like divisive rhetoric; the Committee has no taste.
Run from the repo root."""
import json, sys
sys.path.insert(0, 'tools/workbook')
from wbx import WB

PATH = 'design/Game_Workbook.xlsx'
stages = json.load(open('data/stages.json'))
caucuses = '; '.join(s['stage_id'] for s in stages if 'Caucus' in s['name_en'])

ACT_THEMES = ['Party stability', 'Isolation', 'Immigration', 'National symbols', 'Deterrence', 'Cronyism',
    'Disconnect', 'Security strategy', 'Emergency Powers', 'Funding Reform', 'Customs and belonging',
    'Generational divide', 'Faction loyalty', 'Discipline', 'Faction discipline', 'Party platform', 'Money',
    'Motive', 'Verdict', 'Stakes', 'Leverage', 'Limits', 'Defense Budget', 'Local customs', 'Succession',
    'Zoning', 'Shrine land', 'Label accuracy']
COM_THEMES = ['Ethics rules', 'Member pay', 'Parliamentary procedure', 'Internal democracy', 'Committee seats',
    'Party platform', 'Faction loyalty']

NEW_THEMES = [
    ('Purity of the cause', 'BO31; BO02'), ('Compromise', 'BO31'), ('Establishment', 'BO31; BO08'),
    ('Street mobilization', 'BO31; BO18'),
    ('Selection process', 'BO32; BO01'), ('Local standing', 'BO32; BO03; BO18'),
    ('Candidate finances', 'BO32; BO24'), ('Candidate vetting', 'BO32; BO08'),
    ('Candidate quality', 'BO32; BO08; BO18'),
]
# (text, theme, grades E,Em,A,D,Dv,Du)
ACT_Q = [
    ("Why does the party keep softening its message to please its critics?", 'Purity of the cause', 'SSWSSW'),
    ("Is compromise with the other side a betrayal of our members?", 'Compromise', 'WSSMSW'),
    ("When will the party stop apologizing and start fighting?", 'Purity of the cause', 'WMSMSM'),
    ("Who is the establishment protecting, and who is it ignoring?", 'Establishment', 'MWWSSS'),
    ("Will you stand with the members on the street, or with the people in suits?", 'Street mobilization', 'SWMSSS'),
    ("Why should members trust leaders who answer to donors?", 'Establishment', 'WMSMSM'),
    ("Can a movement win without a clear enemy?", 'Compromise', 'SMMWSM'),
    ("What do you say to members who think the party has lost its nerve?", 'Purity of the cause', 'WWMSSS'),
]
COM_Q = [
    ("Why should this committee choose you over a safer candidate?", 'Selection process', 'WMWSMS'),
    ("How do you show a local record in a district that does not know you?", 'Local standing', 'WSWMSM'),
    ("Would voters in your district describe you as one of them?", 'Local standing', 'WSWSMM'),
    ("How much of your campaign can you fund without outside help?", 'Candidate finances', 'WMMSWS'),
    ("Which of your past statements would you want this committee not to read?", 'Candidate vetting', 'MWWSMS'),
    ("How will the press treat you once you are the party's candidate?", 'Candidate quality', 'MMWSWS'),
    ("What will you do if the committee picks someone else?", 'Selection process', 'MWWSMS'),
    ("Is the party better served by a loyalist or an independent voice?", 'Selection process', 'MSMWSS'),
    ("How do you win both the party base and the undecided?", 'Candidate quality', 'MSSWMM'),
    ("What has your work done for ordinary voters, beyond speeches?", 'Local standing', 'WSMWMS'),
]

w = WB(PATH)
themes = w.rows('Question Themes')
by_theme = {v.get('A'): k for k, v in themes.items()}
def add_to(theme, bo, note):
    r = by_theme[theme]
    cur = themes[r].get('B') or ''
    parts = [p.strip() for p in cur.split(';') if p.strip()]
    if bo not in parts:
        parts.append(bo)
    w.set_cell('Question Themes', r, 'B', '; '.join(parts))
    why = themes[r].get('C') or ''
    w.set_cell('Question Themes', r, 'C', (why + ' ' + note).strip())
for t in ACT_THEMES:
    add_to(t, 'BO31', 'Draft 2026-10-18: Party Activists like this fight.')
for t in COM_THEMES:
    add_to(t, 'BO32', 'Draft 2026-10-18: the Candidate Selection Committee cares about party process.')
for name, orgs in NEW_THEMES:
    w.append_row('Question Themes', {'A': name, 'B': orgs,
        'C': 'Draft 2026-10-18: written for the Party Activists / Candidate Selection Committee.'})

rows = w.rows('Stage Questions')
n = max(int(v['A'][1:]) for v in rows.values() if (v.get('A') or '').startswith('S') and v['A'][1:].isdigit()) + 1
for text, theme, grades in ACT_Q + COM_Q:
    row = {'A': f'S{n}', 'B': caucuses, 'C': text, 'D': theme}
    for col, g in zip('EFGHIJ', grades):
        row[col] = g
    w.append_row('Stage Questions', row); n += 1
w.save()
print('next', n)
