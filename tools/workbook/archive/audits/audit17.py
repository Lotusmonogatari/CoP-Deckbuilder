exec(open('audit1.py').read().split("# ---- 1. header")[0])
slotcols=[f'Stage ID for Part {i}' for i in range(1,11)]
def slots(d): return [str(d[c]) for c in slotcols if d.get(c) not in (None,'N/A')]
levels={d['Level ID']:slots(d) for d in m_levels}
h,ed=table('Edits to Existing Rows')
# apply level edits (slot lists)
for e in ed:
    if e['Tab']=='Levels' and e['Column']=='Stage slots': levels[e['Row ID']]=[x.strip() for x in e['Proposed'].split(',')]
    if e['Tab']=='Levels' and e['Column']=='Stage ID for Part 2': levels[e['Row ID']][1]=e['Proposed']
for d in P['Levels'][1]: levels[d['Level ID']]=slots(d)
td_stages=set(d['Stage ID'] for d in P['Transition Dialogue'][1])
c=collections.Counter(); first=collections.Counter(); total=0
for lv,sl in levels.items():
    for i,s in enumerate(sl):
        if s.startswith('BI'): continue
        if i==0: first[s]+=1
        elif s in td_stages: c[s]+=1; total+=1
print('transitions that actually fire (non-first slot with Show Transition) per full playthrough of all levels:',total,'across',len(levels),'levels')
print('most repeated:',c.most_common(8))
print('stages never reached by a transition (only ever first slot or unused):',sorted(td_stages-set(c)))
# new stages: how many levels use them & as first slot
newst=[d['Stage ID'] for d in P['Stages'][1]]
for s in newst:
    uses=[lv for lv,sl in levels.items() if s in sl]
    fp=[lv for lv in uses if levels[lv][0]==s]
    print(s,'used in',uses,'first-slot(no transition):',fp)
