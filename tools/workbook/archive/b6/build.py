import sys, json, re, random
sys.path.insert(0,'/tmp/claude-0/b1'); sys.path.insert(0,'/tmp/claude-0/b6')
import wbx
from content import *; from content2 import *
P='design/Game_Workbook.xlsx'
w=wbx.WB(P)
st=json.load(open('data/stages.json')); st=st if isinstance(st,list) else list(st.values())
S={s['stage_id']:s for s in st}
opp=json.load(open('data/opponents.json')); opp=opp if isinstance(opp,list) else list(opp.values())
fv=json.load(open('data/floor_votes.json')); fv=list(fv.values()) if isinstance(fv,dict) else fv
random.seed(20261014)

def kind(name):
    for pre,k in [("Press Conference","press"),("Town Hall","town"),("TV Debate","tv"),("Party Caucus","caucus"),("Policy Study","policy"),
                  ("Lobbyist","lobby"),("Hearing","committee"),("Floor Debate","floor"),("Party Steering","steering"),("Media Ambush","ambush")]:
        if name.startswith(pre): return k
    return "committee"
def topic(name): return name.split(" on ",1)[1] if " on " in name else None
show=[k for k,s in S.items() if str(s.get('show_transition')).lower()=='yes']

# ---- Stage Questions
qn=[222]
def add_q(stage_ids,text,theme,prof):
    qn[0]+=1
    g=PROFILE[prof].split()
    row={'A':f'S{qn[0]}','B':'; '.join(stage_ids),'C':text,'D':theme}
    for col,val in zip('EFGHIJ',g): row[col]=val
    w.append_row('Stage Questions',row)
caucus_rooms=[k for k,s in S.items() if kind(s['name_en'])=='caucus' and ' on ' in s['name_en']]
tv_rooms=[k for k,s in S.items() if kind(s['name_en'])=='tv' and ' on ' in s['name_en']]
for t,th,p in FLOOR: add_q(['ST02'],t,th,p)
for t,th,p in CAUCUS: add_q(['ST03']+caucus_rooms,t,th,p)
for t,th,p in TV: add_q(['ST06']+tv_rooms,t,th,p)
for t,th,p in STEER: add_q(['ST08'],t,th,p)
# topic themes from sibling rooms' existing stage questions
sib={}
for r in w.rows('Stage Questions').values():
    if r.get('A') and r['A']!='Q ID' and r.get('B') and r.get('D'):
        sib.setdefault(r['B'].split(';')[0].strip(),[]).append(r['D'])
def topic_theme(tp):
    for k,s in S.items():
        if topic(s['name_en'])==tp and k in sib and kind(s['name_en']) not in('caucus','tv'): return sib[k][0]
    return "Position"
for k in caucus_rooms:
    tp=topic(S[k]['name_en']); th=topic_theme(tp)
    for (t,p) in TOPIC_CAUCUS: add_q([k],t.format(t=tp),th,p)
for k in tv_rooms:
    tp=topic(S[k]['name_en']); th=topic_theme(tp)
    for (t,p) in TOPIC_TV: add_q([k],t.format(t=tp),th,p)
print('questions added',qn[0]-222)

# ---- Transition dialogue
D=w.rows('Transition Dialogue'); td=max(int(r['A'][2:]) for r in D.values() if r['A'].startswith('TD'))
def add_td(cid,stage,line,reply):
    global td; td+=1
    row={'A':f'TD{td:03d}' if td<1000 else f'TD{td}','B':cid,'D':line}
    if stage: row['C']=stage
    if reply: row['E']=reply
    w.append_row('Transition Dialogue',row)
for cid,rows_ in TRANS.items():
    for l,r in rows_: add_td(cid,None,l,r)
for t in THOUGHTS: add_td('PLAYER',None,t,None)
# topic-room extra staff lines
for k in show:
    tp=topic(S[k]['name_en'])
    if not tp: continue
    kd=kind(S[k]['name_en']); kd='caucus' if kd=='caucus' else kd
    for cid,l,r in TOPIC_TRANS.get(kd,[]): add_td(cid,k,l.format(t=tp),r)
# opponent-scoped cast + dialogue
C=w.rows('Transition Cast'); tc=max(int(r['A'][2:]) for r in C.values() if r['A'].startswith('TC'))
cnt=0
for k in show:
    kd=kind(S[k]['name_en'])
    if kd in('caucus','steering','ambush') or kd not in OPP_LINES: continue
    seated=[o['opp_id'] for o in opp if k in (o.get('stages') or [])]
    random.shuffle(seated)
    n=2 if ' on ' not in S[k]['name_en'] else 1
    for oid in seated[:n]:
        tc+=1; w.append_row('Transition Cast',{'A':f'TC{tc:02d}','B':k,'C':oid})
        l,r=random.choice(OPP_LINES[kd]); add_td(oid,k,l,r); cnt+=1
print('opponent transition cast',cnt)

# ---- Level Intro Thoughts
th={'LV61':"Fares and timetables decide whether people can live where they work.",
    'LV62':"A harbour that cannot pay its crews is a harbour that dies."}
for k,v in th.items(): w.append_row('Level Intro Thoughts',{'A':k,'B':v})

# ---- Vote Influence Cues: add missing direction
V=w.rows('Vote Influence Cues'); have={(r['A'],r['B']) for r in V.values() if r.get('A') and r['A']!='Bill ID'}
for b in fv:
    nm=b['bill_name']
    for d,txt in [('Flipped to Pass',f"Your influence carried the {nm}. Colleagues noted who made the difference."),
                  ('Flipped to Fail',f"Your influence sank the {nm}. Colleagues noted who made the difference.")]:
        if (b['bill_id'],d) not in have: w.append_row('Vote Influence Cues',{'A':b['bill_id'],'B':d,'C':txt})

# ---- Office Ticker: law lines
T=w.rows('Office Ticker'); tk=max(int(r['A'][2:]) for r in T.values() if r['A'].startswith('TK'))
PASS=["Parliament has enacted the {n}. Commentators are weighing what comes next. ☼",
      "The {n} is now law in Yezo, and its critics are regrouping. ☼",
      "Yezo News reports that the {n} is law, with {player} on the record. ☼",
      "Offices across Yezo are reading the fine print of the new {n}. ☼"]
FAIL=["The {n} failed on the floor. Its backers say they will regroup. ☼",
      "Yezo News reports the {n} has been voted down. ☼",
      "After the failed {n}, {player} is asked what comes next. ☼",
      "The defeat of the {n} leaves a gap that someone will try to fill. ☼"]
for i,b in enumerate(fv):
    for op,bank in(('passed',PASS),('failed',FAIL)):
        tk+=1
        w.append_row('Office Ticker',{'A':f'TK{tk}','B':'law','C':b['bill_id'],'D':op,'F':bank[i%4].format(n=b['bill_name'],player='{player}')})

# ---- Opponent cues: fill Cue 4/5
OC=w.rows('Opponent Cues'); filled=0
for rn,r in OC.items():
    if rn==1 or not r.get('D'): continue
    bank=EXTRA_OPP.get((r.get('B'),r.get('C')))
    if not bank: continue
    n=int(re.sub(r'\D','',r['A']))
    for col,key in (('H','H'),('I','I')):
        if not r.get(col):
            line=bank[(n+(0 if col=='H' else 1))%4]
            w.set_cell('Opponent Cues',rn,col,line); filled+=1
print('opp cue cells',filled)
w.save()
