exec(open('audit6.py').read().split("print('PLAYER CUE reach")[0])
OK=['Cue 1','Cue 2','Cue 3','Cue 4','Cue 5']
ocP=P['Opponent Cues'][1]
# bespoke without stage => global leak
leak=[r for r in ocP if r.get('Opponent ID') and not stg(r.get('Stage ID'))]
print('Opponent-scoped proposed rows with NO stage scope (global):',len(leak))
bes=[r for r in ocP if r.get('Opponent ID')]
print('bespoke rows',len(bes),'general stage rows',len([r for r in ocP if not r.get('Opponent ID') and stg(r.get('Stage ID'))]),'general any-stage',len([r for r in ocP if not r.get('Opponent ID') and not stg(r.get('Stage ID'))]))
oppIDs={d['Opp ID']:d for d in m_opp}
bad=[r['Cue ID'] for r in bes if any(o.strip() not in oppIDs for o in str(r['Opponent ID']).split(';'))]
print('bespoke referencing unknown opponent IDs:',bad[:10])
print('Opponent ID cell sample:',[r['Opponent ID'] for r in bes[:3]], 'multi-id rows:',sum(1 for r in bes if ';' in str(r['Opponent ID'])))
# build opponent indices as the game does
gen=collections.defaultdict(list); gens=collections.defaultdict(list); bo=collections.defaultdict(list); bos=collections.defaultdict(list)
for r in m_oc+ocP:
    ls=lines(r,OK)
    if not ls: continue
    verb=(r.get('Verb') or '').strip(); st=stg(r.get('Stage ID')); ids=[x.strip() for x in str(r.get('Opponent ID') or '').split(';') if x.strip()]
    if ids:
        for o in ids:
            if st:
                for s in st: bos[f"{o}|{s}|{verb}"]+=ls
            else: bo[f"{o}|{verb}"]+=ls
    else:
        if st:
            for s in st: gens[f"{s}|{r['Suit']}|{verb}"]+=ls
        else: gen[f"{r['Suit']}|{verb}"]+=ls
newst=[d['Stage ID'] for d in P['Stages'][1]]
# modify opponents with edits
h,ed=table('Edits to Existing Rows')
opp={d['Opp ID']:dict(d) for d in m_opp}
for e in ed:
    if e['Tab']=='Opponents': opp[e['Row ID']]['Stage']=e['Proposed']
print('\nOPPONENT cue reach per new stage: bespoke seated / seated MPs lacking bespoke / general pool per suit-verb min')
for s in newst:
    seated=[o for o in opp.values() if s in stg(o.get('Stage'))]
    withb=[o['Opp ID'] for o in seated if any(bos.get(f"{o['Opp ID']}|{s}|{v}") for v in VERBS)]
    gmin=min(len(set(gens.get(f"{s}|{su}|{v}",[]))) for su in SUITS for v in VERBS)
    gany=min(len(set(gens.get(f"{s}|{su}|{v}",[]) or gen.get(f"{su}|{v}",[]))) for su in SUITS for v in VERBS)
    print(s,'seated',len(seated),'bespoke-for-stage',len(withb),'general stage-pool min',gmin,'effective min',gany)
# lines per bespoke (opp,stage,verb)
sizes=[len(set(v)) for k,v in bos.items()]
print('bespoke (opp,stage,verb) pool sizes: n',len(sizes),'min',min(sizes),'max',max(sizes),'avg',round(sum(sizes)/len(sizes),1))
# does any existing MP get bespoke rows at stages they were seated in master (precedence change)?
chg=[]
for k in bos:
    o,s,v=k.split('|')
    if s in [x for x in str(next(d for d in m_opp if d['Opp ID']==o).get('Stage') or '').split(';')] if o in oppIDs else False: chg.append(k)
print('bespoke keys for stages the MP already attended in master:',len(chg),chg[:5])
