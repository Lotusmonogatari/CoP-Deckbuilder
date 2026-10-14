exec(open('audit1.py').read().split("# ---- 1. header")[0])
h,ed=table('Edits to Existing Rows')
mlv={d['Level ID']:d for d in m_levels}
slotcols=[c for c in P['Levels'][0] if c and c.startswith('Stage ID for Part')]
print('LEVEL slot cols',slotcols)
def slots(d): return [str(d[c]) for c in slotcols if d.get(c) not in (None,'N/A')]
for e in ed:
    if e['Tab']=='Levels':
        d=mlv[e['Row ID']]
        cur=', '.join(slots(d))
        if e['Column']=='Stage ID for Part 2': cur=str(d['Stage ID for Part 2'])
        ok = cur==str(e['Current'])
        print('LEVEL EDIT',e['Row ID'],'current matches master:',ok, '' if ok else f'master={cur} vs edit={e["Current"]}')
    if e['Tab']=='Stages':
        d={x['Stage ID']:x for x in m_stages}[e['Row ID']]
        col=e['Column']; cur=d.get(col)
        if (cur or '(blank)')!=e['Current'] and not (cur is None and e['Current']=='(blank)'): print('STAGE EDIT mismatch',e['Row ID'],col,cur,e['Current'])
    if e['Tab'] in('Opponent Cues',):
        d={x['Cue ID']:x for x in m_oc}[e['Row ID']]
        if d.get(e['Column'])!=e['Current']: print('OC EDIT mismatch',e['Row ID'],e['Column'],repr(d.get(e['Column'])),'vs',repr(e['Current']))
print()
# ---- new levels
H,L=P['Levels']
ex=mlv['LV31']
print('master LV31 sample:',{k:ex[k] for k in H if k and k in ex and ex[k] is not None})
for d in L:
    print(d['Level ID'],'|',d['Level Description'],'| tier',d.get('Level Tier'),'cool',[v for k,v in d.items() if 'Cooldown' in k],'| slots',slots(d),'| one-time',[v for k,v in d.items() if 'One-Time' in k])
print([c for c in H if c and ('Win' in c or 'Reward' in c)][:8])
