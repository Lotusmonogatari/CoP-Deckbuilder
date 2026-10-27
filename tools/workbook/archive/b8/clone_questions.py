"""Content 3 (2026-10-18): room-specific questions for the bill-specific stage
copies (ST121-ST259). Two per room (one for a TV Debate), written from each
bill's facets (design/reference/bill_facets.json). Run from the repo root."""
import sys, json
sys.path.insert(0, "tools/workbook")
from wbx import WB

SUITS = ['Earnest', 'Emotional', 'Appeal', 'Data Driven', 'Divisive', 'Duplicitous']
G = {  # grade profiles: two S at least, no more than two W
 'cost':      dict(zip(SUITS, "S M M S W M".split())),
 'need':      dict(zip(SUITS, "S S M M M W".split())),
 'critic':    dict(zip(SUITS, "M M S M S W".split())),
 'backer':    dict(zip(SUITS, "W S M W M S".split())),
 'local':     dict(zip(SUITS, "M S S M M W".split())),
 'procedure': dict(zip(SUITS, "M W M S W S".split())),
 'risk':      dict(zip(SUITS, "S M M S M W".split())),
 'alt':       dict(zip(SUITS, "M M S M W S".split())),
}
# Fix profiles that break "at least 2 S" / "at most 2 W"
G['backer'] = dict(zip(SUITS, "M S M W M S".split()))     # S: Emotional, Duplicitous
G['procedure'] = dict(zip(SUITS, "M W M S W S".split()))  # S: Data Driven, Duplicitous; W: Emotional, Divisive
G['critic'] = dict(zip(SUITS, "M M S M S W".split()))

# family stage -> four (profile, template). {bill} full name with "the", others from facets.
HEARING = [
 ('procedure', "Which agency would run {bill}, and who checks its work?"),
 ('cost', "What is the full price of {what}, and where does the money come from?"),
 ('risk', "What in this bill stops it from leading to {risk}?"),
 ('alt', "Why not {alt} instead of {what}?"),
]
TOWN = [
 ('local', "What does {what} change for {local}?"),
 ('need', "People here ask whether {gain} are the only ones who gain. Are they?"),
 ('critic', "Some here say {critic}. What do you tell them?"),
 ('cost', "Who bears the cost of {what} in this town?"),
]
PRESS = [
 ('critic', "Critics say {critic}. Why should voters trust you on {bill}?"),
 ('risk', "Can you promise voters that this bill will not lead to {risk}?"),
 ('backer', "Supporters say {what} does not go far enough. Do you agree?"),
 ('cost', "How much will {what} cost, and who pays?"),
]
CAUCUS = [
 ('critic', "Members of our own party say {critic}. How do you answer them?"),
 ('procedure', "How will we explain {what} to the voters back home?"),
 ('risk', "What is our plan if {risk} becomes the story?"),
 ('backer', "Will you spend party credit on {bill}?"),
]
STUDY = [
 ('procedure', "What does the best evidence say about {what}?"),
 ('alt', "Would {alt} deliver most of the benefit with less risk?"),
 ('cost', "Who bears the cost: {cost}?"),
 ('risk', "How would we measure whether {risk} is happening?"),
]
LOBBY = [
 ('backer', "My members care about {gain}. What will {bill} do for them?"),
 ('cost', "My members worry about {cost}. What do you say to them?"),
 ('alt', "Would {alt} protect everyone's interests better?"),
 ('risk', "How do you keep {risk} off the table?"),
]
TV = [
 ('need', "In one sentence, why does the country need {what}?"),
 ('cost', "Viewers ask who bears the cost: {cost}. Answer briefly."),
 ('critic', "Critics say {critic}. Answer in twenty seconds."),
 ('risk', "Is {risk} the biggest danger in {bill}?"),
]
AMBUSH = [
 ('cost', "What is the one fact about {bill} that you hoped no one would raise?"),
 ('risk', "Is {risk} the real story behind {bill}?"),
 ('critic', "They say {critic}. Are they right?"),
 ('backer', "Do you really have the votes to pass {what}?"),
]
FAMILY = {'ST03': CAUCUS, 'ST04': PRESS, 'ST05': TOWN, 'ST06': TV, 'ST19': AMBUSH,
          'ST20': LOBBY, 'ST21': STUDY}
for c in ('ST01', 'ST09', 'ST10', 'ST11', 'ST12', 'ST13', 'ST14', 'ST15', 'ST16', 'ST17', 'ST18'):
    FAMILY[c] = HEARING

stages = {s['stage_id']: s for s in json.load(open('data/stages.json'))}
levels = json.load(open('data/levels.json'))
bills = json.load(open('data/floor_votes.json'))
bills = bills if isinstance(bills, list) else list(bills.values())
bill_by_id = {b['bill_id']: b for b in bills}
facets = json.load(open('design/reference/bill_facets.json'))

room_bill = {}
for l in levels:
    slots = [l.get(f'stage_{i}') for i in range(1, 11)]
    bill = next((s for s in slots if s and s.startswith('BI')), None)
    for s in slots:
        if s and s.startswith('ST') and 121 <= int(s[2:]) <= 259:
            room_bill[s] = bill

w = WB('design/Game_Workbook.xlsx')
rows = w.rows('Stage Questions')
nid = max(int(v['A'][1:]) for v in rows.values() if (v.get('A') or '').startswith('S') and v['A'][1:].isdigit()) + 1
last = max(rows)
added = 0
for sid in sorted(room_bill, key=lambda s: int(s[2:])):
    base = stages[sid]['background_id']
    if base not in FAMILY:
        continue  # Office Hours has visitors, not questions
    bill_id = room_bill[sid]
    b = bill_by_id[bill_id]; f = facets[bill_id]
    n = 1 if base == 'ST06' else 2
    bill = 'the ' + b['bill_name']
    stems = FAMILY[base]
    start = (int(bill_id[2:]) + int(sid[2:])) % 4
    for k in range(n):
        prof, tpl = stems[(start + k * 2) % 4]
        text = tpl.format(bill=bill, **f)
        text = text[0].upper() + text[1:]
        row = {'A': f'S{nid}', 'B': sid, 'C': text, 'D': f"{b['bill_name']} debate"}
        for col, suit in zip('EFGHIJ', SUITS):
            row[col] = G[prof][suit]
        w.append_row('Stage Questions', row, style_row=last)
        nid += 1; added += 1
w.save()
print('added', added, 'next', nid)
