"""Batch 4 (2026-10-18): bill-scoped content for all 50 bills (draft, templated).

Writes into the master workbook, raw XML: Stage Questions (4 per bill, Bill ID
set, Stage ID blank), Question Themes (1 per bill), Player Cues (12 per bill:
6 suits x Support/Oppose, any verb), Opponent Cues (18 per bill: 6 suits x
attack/gain/block, neutral probing lines), Transition Dialogue (8 per bill:
three staff x two stances plus a PLAYER thought per stance).
Run from the repo root: python3 tools/workbook/archive/batch4_bill_content_2026-10-18.py
"""
import json, sys
sys.path.insert(0, 'tools/workbook')
from wbx import WB

PATH = 'design/Game_Workbook.xlsx'
SUITS = ['Earnest', 'Emotional', 'Appeal', 'Data Driven', 'Divisive', 'Duplicitous']
PARTY_TIER = {'BO01', 'BO02'}

bills = json.load(open('data/floor_votes.json'))
bills = bills if isinstance(bills, list) else list(bills.values())
laws = json.load(open('data/law_effects.json'))

QUESTIONS = [
    ("Who pays for {t}, and why is that fair?", {'Data Driven': 'S', 'Earnest': 'S', 'Appeal': 'M', 'Emotional': 'M', 'Divisive': 'W', 'Duplicitous': 'M'}),
    ("Is {t} solving a real problem, or creating a new one?", {'Emotional': 'S', 'Earnest': 'S', 'Data Driven': 'M', 'Appeal': 'M', 'Duplicitous': 'W', 'Divisive': 'M'}),
    ("Critics say {t} goes too far. What do you tell them?", {'Appeal': 'S', 'Divisive': 'S', 'Emotional': 'M', 'Data Driven': 'M', 'Earnest': 'M', 'Duplicitous': 'W'}),
    ("Backers say {t} does not go far enough. Where do you stand?", {'Duplicitous': 'S', 'Emotional': 'S', 'Divisive': 'M', 'Appeal': 'M', 'Data Driven': 'W', 'Earnest': 'W'}),
]

SUPPORT = {
 'Earnest': ["I support {t}, and I will tell you why.", "This bill is the right thing to do.", "I put my name to {t} without hesitation.", "Judge me by where I stand on this bill.", "This bill deserves an honest yes."],
 'Emotional': ["Think of the people {t} will reach.", "Behind this bill are real families.", "I have heard their stories. They need {t}.", "This is about people, not paperwork.", "Look them in the eye and say yes to {t}."],
 'Appeal': ["Most of this room knows {t} is right.", "Ordinary people are asking for this bill.", "The public wants {t}. Listen to them.", "Stand with the many on this bill.", "This is common ground. Let us take it."],
 'Data Driven': ["The figures support {t}.", "Run the numbers on this bill.", "The evidence for {t} is on the table.", "Every study I read points the same way.", "Costs and benefits favor {t}."],
 'Divisive': ["Opponents of {t} owe this room an answer.", "You are either for this bill or in its way.", "Those blocking {t} should say so openly.", "Choose a side on this bill.", "Delay is a decision against {t}."],
 'Duplicitous': ["Of course I support {t}. Who would not?", "Let us say this bill is simple and move on.", "Nobody here can fault {t}, can they?", "I will support {t}, in the right form.", "Call it what you like. This bill passes."],
}
OPPOSE = {
 'Earnest': ["I oppose {t}, and I will tell you why.", "I cannot support this bill in honesty.", "I will not put my name to {t}.", "Judge me by where I stand on this bill.", "This bill deserves an honest no."],
 'Emotional': ["Think of the people {t} would hurt.", "Behind my no are real families.", "I have heard their worries about {t}.", "This is about people, not paperwork.", "Look them in the eye and defend {t}."],
 'Appeal': ["Most people I meet do not want {t}.", "Ordinary people are wary of this bill.", "The public has doubts about {t}. Hear them.", "Stand with the many against this bill.", "This is common sense. Let us use it."],
 'Data Driven': ["The figures do not support {t}.", "Run the numbers on this bill.", "The evidence against {t} is on the table.", "The study I read points the other way.", "Costs outweigh the benefits of {t}."],
 'Divisive': ["Backers of {t} owe this room an answer.", "You are either with the public or with this bill.", "Those pushing {t} should say who gains.", "Choose a side on this bill.", "Rushing {t} is a decision against the country."],
 'Duplicitous': ["Of course I care about the goal. Not this bill.", "Let us say this bill is simple. It is not.", "Nobody here can promise {t} works, can they?", "I would support {t}, in a different form.", "Call it what you like. This bill stalls."],
}
OPP = {
 ('Earnest', 'attack'): ["Say plainly where you stand on {t}.", "Do you believe in this bill, or just argue it?", "I want an honest answer on {t}.", "Your record on this bill matters.", "Be straight with me about {t}."],
 ('Earnest', 'gain'): ["I will tell you what I think of {t}.", "I came here with an open mind on this bill.", "Let me be honest about {t}.", "My position on this bill is no secret.", "I mean what I say on {t}."],
 ('Earnest', 'block'): ["Not a word of {t} gets past honesty.", "I need more than slogans on this bill.", "Try a plainer answer on {t}.", "That does not answer my question.", "Careful. This bill deserves the truth."],
 ('Emotional', 'attack'): ["Think of who {t} touches.", "Do you feel nothing about this bill?", "People are watching how you treat {t}.", "Will you face them over this bill?", "Say it to their faces: {t}."],
 ('Emotional', 'gain'): ["I carry real stories about {t}.", "This bill is personal to many here.", "I hear families talk of {t}.", "My heart is in this bill.", "Some in this room live with {t}."],
 ('Emotional', 'block'): ["Do not hide behind {t}.", "That sounds cold on this bill.", "You are not moving me on {t}.", "People are more than a bill.", "Try a kinder answer on {t}."],
 ('Appeal', 'attack'): ["The public will judge you on {t}.", "Who asked for this bill?", "Voters are watching {t}.", "Are you listening to the street on {t}?", "Ordinary people read this bill differently."],
 ('Appeal', 'gain'): ["Folks tell me plenty about {t}.", "The mood on this bill is clear.", "Most people I meet raise {t}.", "The crowd is with me on this bill.", "Ask around about {t}."],
 ('Appeal', 'block'): ["The public is not buying that on {t}.", "Say it simply, or not at all.", "That will not play on this bill.", "Voters see through that on {t}.", "Try the plain version of {t}."],
 ('Data Driven', 'attack'): ["Show me the figures for {t}.", "Where is the evidence on this bill?", "Your numbers on {t} do not add up.", "Cite your source on this bill.", "What does {t} cost?"],
 ('Data Driven', 'gain'): ["The figures on {t} favor my view.", "I have the analysis on this bill.", "Read the report on {t}.", "The data on this bill speaks for me.", "My numbers on {t} are checked."],
 ('Data Driven', 'block'): ["That statistic on {t} is misleading.", "Your source on this bill is thin.", "Check your math on {t}.", "That chart is selective.", "The data on {t} says otherwise."],
 ('Divisive', 'attack'): ["Whose side are you on over {t}?", "This bill splits the house. Pick one.", "You cannot straddle {t}.", "Name who you are fighting on this bill.", "Dodging {t} is a choice too."],
 ('Divisive', 'gain'): ["My side on {t} is clear.", "I know who stands where on this bill.", "Draw the line on {t}.", "This bill shows who is who.", "We will not blur {t}."],
 ('Divisive', 'block'): ["Do not paint me into a corner on {t}.", "I refuse that framing of this bill.", "You are dividing us on {t}.", "That is a trap on this bill.", "Not that way on {t}."],
 ('Duplicitous', 'attack'): ["Funny how your tune on {t} changes.", "Is that what you tell donors about this bill?", "I wonder what you say in private on {t}.", "Smooth answer on this bill.", "What is the catch in {t}?"],
 ('Duplicitous', 'gain'): ["There is more to {t} than it seems.", "Let us keep this bill between us.", "Nothing on {t} is quite as stated.", "Perhaps this bill helps me too.", "A deal on {t} is possible."],
 ('Duplicitous', 'block'): ["Nice try on {t}.", "You will not pin me on this bill.", "Is that a promise on {t}? Funny.", "I heard nothing on this bill.", "Ask my office about {t}."],
}
# (character, support line, support reply, oppose line, oppose reply)
STAFF = [
 ('SF01', "The research folder on {t} backs your lean. Start with page two.", "Page two it is.",
          "The research on {t} gives you real ground to oppose. Start with page two.", "Page two it is."),
 ('SF08', "You will have to explain why you back {t}. Keep it short.", "Short and plain.",
          "You will have to explain why you oppose {t}. Keep it short.", "Short and plain."),
 ('SF15', "People at home are watching how you handle {t}.", "Then I will handle it with care.",
          "People at home are watching how you handle {t}. Some wanted a yes.", "I owe them a reason."),
]
THOUGHT = ("I chose to back {t}. Now I have to earn it.", "I chose to oppose {t}. Now I have to justify it.")


def topic(name):
    """The name in a short cue line: the full name when it is five words or
    fewer, otherwise "this bill" so a banner line stays short."""
    return 'the ' + name if len(name.split()) <= 5 else 'this bill'


def theme_orgs(bill_id):
    pos, neg = [], []
    for row in laws:
        if row['bill_id'] == bill_id and row['outcome'] == 'Passed' and row['timing'] in (None, 'Once'):
            for e in row['effects'] or []:
                if e['target'] in PARTY_TIER or not e['target'].startswith('BO'):
                    continue
                (pos if e['delta'] > 0 else neg).append((abs(e['delta']), e['target']))
    pos.sort(reverse=True); neg.sort(reverse=True)
    return [b for _, b in pos[:4]], [b for _, b in neg[:2]]


w = WB(PATH)
def next_num(tab, prefix):
    nums = [int(v['A'][len(prefix):]) for v in w.rows(tab).values() if (v.get('A') or '').startswith(prefix)]
    return max(nums) + 1
qn = next_num('Stage Questions', 'S'); pl = next_num('Player Cues', 'PL')
oc = next_num('Opponent Cues', 'OC'); td = next_num('Transition Dialogue', 'TD')

for b in bills:
    bid, name = b['bill_id'], b['bill_name']
    t = topic(name)
    tq = 'the ' + name   # questions have room for the full name
    theme = f"{name} debate"
    pleases, annoys = theme_orgs(bid)
    if not pleases:
        pleases = ['BO18']
    w.append_row('Question Themes', {'A': theme, 'B': '; '.join(pleases),
        'C': "Draft 2026-10-18: the organizations the bill's Law Effects (Passed) favor.",
        **({'D': '; '.join(annoys)} if annoys else {})})
    for text, grades in QUESTIONS:
        row = {'A': f'S{qn}', 'C': text.format(t=tq), 'D': theme, 'L': bid}
        for col, suit in zip('EFGHIJ', SUITS):
            row[col] = grades[suit]
        w.append_row('Stage Questions', row); qn += 1
    for stance, bank in (('Support', SUPPORT), ('Oppose', OPPOSE)):
        for suit in SUITS:
            row = {'A': f'PL{pl}', 'B': suit, 'J': bid, 'K': stance}
            for col, line in zip('EFGHI', bank[suit]):
                row[col] = line.format(t=t)
            w.append_row('Player Cues', row); pl += 1
    for suit in SUITS:
        for verb in ('attack', 'gain', 'block'):
            row = {'A': f'OC{oc}', 'B': suit, 'C': verb, 'K': bid}
            for col, line in zip('EFGHI', OPP[(suit, verb)]):
                row[col] = line.format(t=t)
            w.append_row('Opponent Cues', row); oc += 1
    for char, sl, sr, ol, orr in STAFF:
        for stance, line, reply in (('Support', sl, sr), ('Oppose', ol, orr)):
            w.append_row('Transition Dialogue', {'A': f'TD{td}', 'B': char, 'D': line.format(t=t),
                'E': reply, 'F': bid, 'G': stance}); td += 1
    for stance, line in zip(('Support', 'Oppose'), THOUGHT):
        w.append_row('Transition Dialogue', {'A': f'TD{td}', 'B': 'PLAYER', 'D': line.format(t=t),
            'F': bid, 'G': stance}); td += 1
w.save()
print('done', qn, pl, oc, td)
