exec(open('audit9.py').read().split("print('--- master baseline')")[0])
import json
SQ=P['Stage Questions'][1]
def dist(rows,label):
    n=len(rows)
    print(label,n,{s:(sum(1 for q in rows if q[s]=='S'),sum(1 for q in rows if q[s]=='W')) for s in SUITS},'  (S,W)')
    print('   share Strong %:',{s[:4]:round(100*sum(1 for q in rows if q[s]=='S')/n) for s in SUITS},' Weak %:',{s[:4]:round(100*sum(1 for q in rows if q[s]=='W')/n) for s in SUITS})
rooms=[]
for t in ['Press Questions','Town Hall Questions','Lobbyist Questions','Study Session Questions','Media Ambush Questions']:
    _,r=mt(t); rooms+=[x for x in r if all(x.get(s) in ('S','M','W') for s in SUITS)]
dist(rooms,'MASTER room tabs')
dist(m_sq,'MASTER stage questions')
dist(SQ,'PROPOSED stage questions')
# per-question: how many suits Strong; how often is Earnest the unique/dominant best
import statistics
def best(q): 
    rank={'S':2,'M':1,'W':0}
    m=max(rank[q[s]] for s in SUITS); return [s for s in SUITS if rank[q[s]]==m]
for lab,rows in (('master rooms',rooms),('proposed SQ',SQ)):
    c=collections.Counter(); alone=0
    for q in rows:
        b=best(q); c.update(b)
        if len(b)==1: alone+=1
    print(lab,'suit appears among best-graded:',{k[:4]:round(100*v/len(rows)) for k,v in c.items()},'unique-best questions %',round(100*alone/len(rows)))
# stage questions asked vs wanted
st=json.load(open('/home/user/CoP-Deckbuilder/data/stages.json')); st=st.get('rows',st) if isinstance(st,dict) else st
sd={s['stage_id']:s for s in st}
per=collections.Counter(s for q in SQ for s in stg(q['Stage ID']))
print('\nstage | turn_limit | questions_per_turn | qcount | pool? | proposed SQ | wanted')
for sid in ['ST02','ST03','ST04','ST05','ST06','ST08','ST19','ST20','ST21']:
    s=sd[sid]; print(sid,s.get('turn_limit'),s.get('questions_per_turn'),s.get('questions_count'),s.get('question_pool'),per[sid], (s.get('questions_per_turn') or 1)*(s.get('turn_limit') or 0), '| mode',s.get('sequence_mode'),'opp_count',s.get('opponent_count'))
