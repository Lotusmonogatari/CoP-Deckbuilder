exec(open('audit9.py').read().split("print('--- master baseline')")[0])
allst=set(d['Stage ID'] for d in m_stages)|set(d['Stage ID'] for d in P['Stages'][1])
bills=set(b['Bill ID'] for b in m_bills)|set(b['Bill ID'] for b in P['Floor Vote Bills'][1])
bad=[]
for n in ('Player Cues','Opponent Cues'):
    for r in P[n][1]:
        for s in stg(r.get('Stage ID')):
            if s not in allst: bad.append((n,r['Cue ID'],s))
        if r.get('Suit') not in SUITS: bad.append((n,r['Cue ID'],'suit '+str(r.get('Suit'))))
        if r.get('Verb') not in (None,'attack','gain','block'): bad.append((n,r['Cue ID'],'verb '+str(r.get('Verb'))))
print('bad cue refs',bad[:8],len(bad))
# stage ids of existing combat stages that stage-scoped cues touch (are base rooms overridden?)
base=[d['Stage ID'] for d in m_stages if d['Mode']=='Combat']
pl_base=collections.Counter(s for r in P['Player Cues'][1] for s in stg(r.get('Stage ID')) if s in base)
oc_base=collections.Counter(s for r in P['Opponent Cues'][1] for s in stg(r.get('Stage ID')) if s in base)
print('proposed Player Cue rows touching existing rooms:',dict(pl_base))
print('proposed Opponent Cue rows (stage-scoped) touching existing rooms:',dict(oc_base))
# unknown stage / opponent in Edits
h,ed=table('Edits to Existing Rows')
for e in ed:
    if e['Tab']=='Opponents':
        for s in stg(e['Proposed']):
            if s not in allst: print('edit unknown stage',e['Row ID'],s)
# level slots referencing unknown
for d in P['Levels'][1]:
    for c in [k for k in d if k and k.startswith('Stage ID for Part')]:
        v=d[c]
        if v not in (None,'N/A') and v not in allst and v not in bills: print('level bad slot',d['Level ID'],v)
# level numbering gap check & bill->level mapping
bl={}
for d in P['Levels'][1]:
    for c in [k for k in d if k and k.startswith('Stage ID for Part')]:
        if str(d[c]).startswith('BI'): bl[d[c]]=d['Level ID']
print('bill->level',bl, '| bills without level:',[b for b in [x['Bill ID'] for x in P['Floor Vote Bills'][1]] if b not in bl])
# existing-room flavor loss: PL rows in base rooms
pl_rows_base=[r for r in P['Player Cues'][1] if any(s in base for s in stg(r.get('Stage ID')))]
print('player rows in existing rooms',len(pl_rows_base), 'of', len(P['Player Cues'][1]))
print('rooms that still reach card Flavor Text (any suit/verb cell with no stage/universal PL):')
