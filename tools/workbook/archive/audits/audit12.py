exec(open('audit9.py').read().split("print('--- master baseline')")[0])
import json
SQ=P['Stage Questions'][1]
st=json.load(open('/home/user/CoP-Deckbuilder/data/stages.json')); st=st.get('rows',st) if isinstance(st,dict) else st
sd={s['stage_id']:s for s in st}
pmap={'Frontier Party':'PT03','Keizaijiyuutou':'PT05','Country Initiative':'PT06'}
print('ST03/ST08 eligible stage questions per protagonist party vs turns needed')
for sid in ['ST03','ST08']:
    qs=[q for q in SQ if sid in stg(q['Stage ID'])]
    for party,pid in pmap.items():
        ok=[q for q in qs if not q.get('Asked By Party') or q['Asked By Party'] in ('OWN',pid) or pid in str(q['Asked By Party'])]
        print(sid,party,'eligible',len(ok),'of',len(qs),'turns',sd[sid]['turn_limit'])
print('\nSQ on pooled rooms: Asked By Party values')
for sid in ['ST04','ST05','ST19','ST20','ST21']:
    qs=[q for q in SQ if sid in stg(q['Stage ID'])]
    print(sid,len(qs),collections.Counter(q.get('Asked By Party') for q in qs),'| sample:',qs[0]['Question'][:70],'|',qs[0]['Theme'])
# Committees (ST09-18, ST01): master 3 SQ, proposal adds 9 total: wanted turns?
for sid in ['ST01','ST09','ST18']:
    print(sid,'turns',sd[sid]['turn_limit'],'opp',sd[sid]['opponent_count'],'SQ',len([q for q in SQ if sid in stg(q['Stage ID'])]),'+master',len([q for q in m_sq if sid in stg(q['Stage ID'])]))
# new rooms: turns vs SQ count
newst=P['Stages'][1]
print('\nnew rooms: turns vs SQ (per-bout reset rooms ask turn_limit questions per bout? )')
for d in newst:
    n=len([q for q in SQ if d['Stage ID'] in stg(q['Stage ID'])]); print(d['Stage ID'],d['Sequence Mode'],'turns',d['Turn limit'],'opp',d['Opponent Count'],'SQ',n)
