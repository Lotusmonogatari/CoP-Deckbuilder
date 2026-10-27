"""Batch 5 (2026-10-18): Party Activists (BO31) and Candidate Selection
Committee (BO32): Boosters rows + Party Lean Multiplier column, Modifiers
M47/M48, Party Standing OWN rows, a Standing Links tab, Balance lever.
Run from the repo root."""
import json, sys
sys.path.insert(0, 'tools/workbook')
from wbx import WB, add_sheet

PATH = 'design/Game_Workbook.xlsx'
stages = json.load(open('data/stages.json'))
rooms = [s['stage_id'] for s in stages if 'Town Hall' in s['name_en'] or 'Caucus' in s['name_en']]

w = WB(PATH)
w.set_cell('Boosters', 1, 'H', 'Party Lean Multiplier', style_from=1) if False else w.set_cell('Boosters', 1, 'H', 'Party Lean Multiplier')
# existing Party Bodies: Faction reacts 1.5x (Cameron); HQ blank = 1.0
r = w.find_row('Boosters', 'BO02'); w.set_cell('Boosters', r, 'H', 1.5)
w.append_row('Boosters', {'A': 'BO31', 'B': 'Party Activists', 'C': '党活動家', 'D': 'Tō Katsudōka',
    'E': 'Party', 'F': 'M47', 'G': 5, 'H': 2.0})
w.append_row('Boosters', {'A': 'BO32', 'B': 'Candidate Selection Committee', 'C': '公認候補選考委員会',
    'D': 'Kōnin Kōho Senkō Iinkai', 'E': 'Party', 'F': 'M48', 'G': 15, 'H': 0.5})

w.append_row('Modifiers', {'A': 'M47', 'B': 'Activist Ground Game', 'C': '活動家の動員', 'D': 'Katsudōka no Dōin',
    'E': 'BO31', 'F': 20, 'G': '+5 starting support at every Town Hall and Party Caucus.',
    'H': 10, 'I': 5, 'J': 0, 'K': 'STAGE_START_BONUS', 'L': '; '.join(rooms), 'M': 5})
w.append_row('Modifiers', {'A': 'M48', 'B': 'Selection Committee Endorsement', 'C': '選考委員会の推薦',
    'D': 'Senkō Iinkai no Suisen', 'E': 'BO32', 'F': 15,
    'G': '+5 Party support each time your influence turns a bill your party backs from failing to passing.',
    'H': 10, 'I': 0, 'J': 0, 'K': 'PARTY_BILL_FLIP_BONUS', 'L': 'PartySupport', 'M': 5})

w.append_row('Party Standing', {'A': 'OWN', 'B': 'BO31', 'C': 2, 'D': 'Your own party activists'})
w.append_row('Party Standing', {'A': 'OWN', 'B': 'BO32', 'C': 3, 'D': 'Your own party candidate selection committee'})

w.append_row('Balance', {'A': 'Standing Links: Yen Per Point', 'B': 10000,
    'C': 'First-draft. How many yen of Funds count as one standing point when Funds drives an organization through the Standing Links tab (Funds is volatile, so this keeps its pull small).'})
w.save()

add_sheet(PATH, 'Standing Links',
    ['Link ID', 'Source', 'Target', 'Weight', 'Note'],
    [['SL01', 'Reputation', 'BO32', 0.25, 'Draft 2026-10-18: reputation weighs heavily with the Candidate Selection Committee.'],
     ['SL02', 'BO01', 'BO32', 0.15, 'Draft: Party Headquarters standing carries over.'],
     ['SL03', 'BO03', 'BO32', 0.15, 'Draft: Local Kōenkai standing carries over.'],
     ['SL04', 'BO08', 'BO32', 0.05, 'Draft: National Media counts a little.'],
     ['SL05', 'Funds', 'BO32', 0.1, 'Draft: Funds counts less because it swings a lot (see Balance: Standing Links: Yen Per Point).'],
     ['SL06', 'BO18', 'BO32', 0.25, 'Draft: Constituency Voters weigh heavily.'],
     ['SL07', 'BO31', 'BO32', -0.3, 'Draft rivalry: what pleases the Activists sets the Committee back.'],
     ['SL08', 'BO32', 'BO31', -0.3, 'Draft rivalry: what pleases the Committee sets the Activists back.'],
     ['SL09', 'BO01', 'BO02', -0.3, 'Draft rivalry: Headquarters against the Faction.'],
     ['SL10', 'BO02', 'BO01', -0.3, 'Draft rivalry: the Faction against Headquarters.']],
    [9, 14, 9, 9, 80])
