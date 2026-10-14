exec(open('audit1.py').read().split("# ---- 1. header")[0])
import json
slotcols=[f'Stage ID for Part {i}' for i in range(1,11)]
def slots(d): return [str(d[c]) for c in slotcols if d.get(c) not in (None,'N/A')]
expo=collections.Counter(); bills={}
for d in m_levels:
    for i,s in enumerate(slots(d)):
        if s.startswith('BI'): bills[s]=d['Level ID']
        else: expo[s]+=1
st=json.load(open('/home/user/CoP-Deckbuilder/data/stages.json')); st=st.get('rows',st) if isinstance(st,dict) else st
qs=json.load(open('/home/user/CoP-Deckbuilder/data/questions.json'))
pools={k:len(v) for k,v in qs.items() if isinstance(v,list)}
print('pools',pools)
sqc=collections.Counter(s for q in m_sq for s in str(q['Stage ID']).split(';'))
print('\nstage | name | levels using it | turns | pool (size) | stage Qs | q asked | gap')
for s in st:
    if s['mode']!='Combat': continue
    sid=s['stage_id']; pool=s.get('question_pool'); psz=None
    if not pool and sid=='ST05': pool='town_hall'
    ps=pools.get(pool.replace('press_conference','press_conference'),None) if pool else None
    turns=s.get('turn_limit'); asked=turns if (pool or sqc[sid]) else 0
    print(sid,'|',s['name_en'][:26],'|',expo[sid],'| turns',turns,'| pool',pool,ps,'| SQ',sqc[sid],'| asked',asked)
print('\nbill levels: ',len(bills),'bills; levels LV31-60 stages per level:')
print(collections.Counter(len(slots(d)) for d in m_levels if d['Level ID']>='LV31'))
# which committee stage precedes the bill in each bill level, and bill name
bn={b['Bill ID']:b['Bill Name (EN)'] for b in m_bills}
for d in m_levels:
    if d['Level ID']>='LV31': print(d['Level ID'],[x for x in slots(d)],bn.get([x for x in slots(d) if x.startswith('BI')][0]))
