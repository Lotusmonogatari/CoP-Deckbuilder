"""Content 7 (2026-10-18): player thoughts. (1) Level Intro Thoughts: two more
for every level; (2) Transition Dialogue PLAYER thoughts: sets for each room
family (a Stage ID list covers the room and its copies) and two more for each
bill and stance. Run from the repo root."""
import sys, json
sys.path.insert(0, "tools/workbook")
from wbx import WB

LEVEL = {  # non-bill levels: two thoughts each
"LV01": ["Ordinary people ask the questions that matter most.", "Listening costs nothing and teaches everything."],
"LV02": ["Every lobbyist is selling something. I will decide what I buy.", "Access is not agreement, however politely it is asked for."],
"LV03": ["Questions first. Answers can wait until I understand.", "Study is slow, but mistakes in law are slower to fix."],
"LV04": ["A smaller committee is still a real test.", "Party leaders are watching how I handle a quiet room."],
"LV05": ["Every reporter here has a deadline and a headline in mind.", "One careless sentence can undo a week of good work."],
"LV06": ["Helping the party on farm policy helps real farms, too.", "Friends in the party are worth earning slowly."],
"LV07": ["Roads and rails are promises kept in concrete.", "Infrastructure is a bill that arrives long after the ribbon is cut."],
"LV08": ["A junior member earns trust on the floor.", "The floor rewards preparation, not volume."],
"LV09": ["Filling in is how members learn the whole Assembly.", "Committees are where the real work hides."],
"LV10": ["Hometown shops are a town's memory.", "Protecting a market means choosing who it protects."],
"LV11": ["Students ask the questions older voters stopped asking.", "Their impatience is useful, if I answer honestly."],
"LV12": ["Families carry the weight of every budget decision.", "A tour only counts if I listen more than I talk."],
"LV13": ["Craft is what is left when everything else is copied.", "Artisans ask for respect before they ask for money."],
"LV14": ["A bad commute is a tax on every day.", "Fix the commute and a hundred small things improve."],
"LV15": ["Tradition has something to teach, if I ask it politely.", "The traditionalist wing wants to be heard before it is outvoted."],
"LV16": ["Reformers have energy. I should add judgment.", "Fast change needs careful hands."],
"LV17": ["Coalitions are built one honest conversation at a time.", "A new generation does not owe loyalty to old habits."],
"LV18": ["Shop owners and commuters need each other.", "A coalition is found where two complaints overlap."],
"LV19": ["Veterans remember the reasons. Newcomers ask for them.", "Both groups need me to translate."],
"LV20": ["Young people want a way in. Unions want a way to stay.", "Overlooked groups notice who finally calls."],
"LV21": ["A household budget is the best policy lesson.", "Neighbors trust each other before they trust me."],
"LV22": ["Small business owners know exactly what a rule costs.", "Every shuttered shop was once someone's dream."],
"LV23": ["Winter breaks what summer neglected.", "Infrastructure is cheaper to fix than to apologize for."],
"LV24": ["The old order did not ask the people it reshaped.", "To guard a history, I have to understand it."],
"LV25": ["Reform can lift a career or sink it.", "A wave is easier to ride when I know its direction."],
"LV26": ["Coalitions start with listening.", "Everyone at the table wants proof I will not forget them."],
"LV27": ["Villages lose a little each time a young person leaves.", "A rural future needs a reason to stay."],
"LV28": ["A kōenkai is a family with opinions.", "Loyalty deserves better than being taken for granted."],
"LV29": ["Potholes and empty shops share a cause.", "Main Street is where policy shows up on foot."],
"LV30": ["A bargain needs everyone to give something up.", "Somebody has to move first. It may as well be me."],
"LV61": ["Every fare decision lands in a household budget.", "Timetables decide where people can afford to live."],
"LV62": ["Quotas look like numbers. On the harbor they are crews.", "A town on the water lives on what the sea allows."],
}
FAMILIES = {  # PLAYER thoughts for entering a room family
 "ST05": ["Ordinary people ask honest questions. I should answer the same way.", "A town hall rewards patience.", "Neighbors will remember how I listen.", "No speeches. Just answers.", "Everyone in that room has waited to be heard.", "Plain words work best at a town hall."],
 "ST03": ["Colleagues who share my banner still want proof.", "The caucus is friendly, which is exactly why I must be careful.", "Loyalty is earned in rooms like this.", "Party members remember who spoke up.", "A caucus is a family with opinions.", "Say what I think. Then listen."],
 "ST04": ["Every reporter has a headline waiting.", "A press conference is a series of small traps.", "Short answers, no adjectives.", "The camera forgives nothing and forgets nothing.", "Say the true thing the simple way.", "Their questions are my audience's questions."],
 "ST21": ["A study session is for learning, not winning.", "Experts reward questions that show I read the report.", "Evidence first. Opinions after.", "The best answer here is an honest 'I do not know'.", "Numbers need people to explain them.", "If I understand it, I can defend it."],
 "ST06": ["A television debate is mostly about composure.", "The line to hold is steady tone, not clever lines.", "Viewers decide in seconds.", "Breathe, smile if I mean it, and keep going.", "Viewers at home judge the effort as much as the answer.", "Stay above the line."],
 "ST20": ["Every lobbyist has an ask. I can listen without agreeing.", "A meeting is not a promise.", "Interests are not the same as the public interest.", "Whose voice is missing from this room?", "Polite is not the same as persuaded.", "I owe them a hearing, not a yes."],
 "ST02": ["The floor is where preparation meets pressure.", "Every seat in the chamber counts.", "Debate on the floor is for the record.", "Hold the line, and count the votes.", "A good argument here can move a bench.", "The chamber listens for conviction."],
 "ST08": ["The steering committee decides who gets a future.", "Say what the party needs to hear, and still mean it.", "A quiet room can change a career.", "The platform is a promise. I should know it by heart.", "Discipline is easier when I believe the line.", "Careful. They remember everything."],
 "COMMITTEE": ["A committee is where the details live.", "Specifics beat slogans in a hearing room.", "Members here know their briefs. I should know mine.", "Short answers. Cite the source.", "The record from this room will last.", "Patience wins committees."],
}
COMMITTEES = ["ST01", "ST09", "ST10", "ST11", "ST12", "ST13", "ST14", "ST15", "ST16", "ST17", "ST18"]
bills = json.load(open('data/floor_votes.json')); bills = bills if isinstance(bills, list) else list(bills.values())
facets = json.load(open('design/reference/bill_facets.json'))
levels = json.load(open('data/levels.json'))
stages = json.load(open('data/stages.json'))
fam = {}
for s in stages:
    b = s.get('background_id') or s['stage_id']
    fam.setdefault(b, []).append(s['stage_id'])
bill_level = {}
for l in levels:
    for i in range(1, 11):
        v = l.get(f'stage_{i}')
        if v and str(v).startswith('BI'):
            bill_level[v] = l['level_id']

def cap(t): return t[0].upper() + t[1:]
w = WB('design/CoP_Starter_Card_Stage_Data.xlsx')
# 1. Level Intro Thoughts
added_l = 0
for lid, ts in LEVEL.items():
    for t in ts:
        w.append_row('Level Intro Thoughts', {'A': lid, 'B': t}); added_l += 1
for b in bills:
    f = facets[b['bill_id']]; lid = bill_level[b['bill_id']]
    for t in (f"The people who gain are {f['gain']}. The people who pay are {f['cost']}.",
              f"My worry is {f['risk']}. My hope is that {f['gain']} come out better off."):
        w.append_row('Level Intro Thoughts', {'A': lid, 'B': t}); added_l += 1
# 2. Transition Dialogue PLAYER thoughts
rows = w.rows('Transition Dialogue')
nid = max(int(v['A'][2:]) for v in rows.values() if (v.get('A') or '').startswith('TD') and v['A'][2:].isdigit()) + 1
last = max(rows)
added_t = 0
for key, thoughts in FAMILIES.items():
    bases = COMMITTEES if key == "COMMITTEE" else [key]
    ids = sorted({x for base in bases for x in [base] + fam.get(base, [])}, key=lambda x: int(x[2:]))
    for t in thoughts:
        w.append_row('Transition Dialogue', {'A': f'TD{nid}', 'B': 'PLAYER', 'C': '; '.join(ids), 'D': t}, style_row=last)
        nid += 1; added_t += 1
for b in bills:
    f = facets[b['bill_id']]; bid = b['bill_id']
    items = [
        ('Support', f"If I back {f['what']}, I should be ready to answer for {f['risk']}."),
        ('Support', f"{cap(f['gain'])} are counting on this. I should not take that lightly."),
        ('Oppose', f"If I oppose {f['what']}, I owe {f['gain']} a better answer."),
        ('Oppose', f"Someone has to speak for {f['cost']}. It may as well be me."),
    ]
    for stance, t in items:
        w.append_row('Transition Dialogue', {'A': f'TD{nid}', 'B': 'PLAYER', 'D': t, 'F': bid, 'G': stance}, style_row=last)
        nid += 1; added_t += 1
w.save()
print('level thoughts', added_l, 'transition thoughts', added_t)
