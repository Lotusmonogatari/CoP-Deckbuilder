exec(open('audit9.py').read().split("print('--- master baseline')")[0])
SQ=P['Stage Questions'][1]
themes_master={d['Theme']:d for d in m_themes}; themes_prop={d['Theme']:d for d in P['Question Themes'][1]}
allthemes=dict(themes_master); allthemes.update(themes_prop)
print('proposed themes new:',len(themes_prop),'overlap with master:',[t for t in themes_prop if t in themes_master])
boost=[d['Booster ID'] for d in m_boost]
bad=[]
for t,d in themes_prop.items():
    for o in str(d['Organisation']).split(';')+str(d.get('Annoys') or '').split(';'):
        o=o.strip()
        if o and o not in boost: bad.append((t,o))
print('unknown orgs in new themes:',bad)
sc=collections.Counter(); badg=[]; unk=[]; badp=[]; tm=[]; ln=[]; noW=0; policy=[]
newst=set(d['Stage ID'] for d in P['Stages'][1]); allst=set(d['Stage ID'] for d in m_stages)|newst
PARTIES={'PT01','PT02','PT03','PT04','PT05','PT06','OWN'}
perstage=collections.defaultdict(list)
for q in SQ:
    gr=[q[s] for s in SUITS]
    if any(g not in('S','M','W') for g in gr): badg.append(q['Q ID'])
    S=gr.count('S');W=gr.count('W')
    if S<2 or W>2: sc[(S,W)]+=1
    if W==0: noW+=1
    if q['Theme'] not in allthemes: unk.append((q['Q ID'],q['Theme']))
    for s in stg(q['Stage ID']):
        if s not in allst: unk.append((q['Q ID'],'stage '+s))
        perstage[s].append(q)
    ab=q.get('Asked By Party')
    if ab:
        for p in str(ab).replace(',',';').split(';'):
            if p.strip() not in PARTIES: badp.append((q['Q ID'],ab))
    m=TIMERE.search(q['Question'])
    if m: tm.append((q['Q ID'],m.group(0),q['Question']))
    ln.append(words(q['Question']))
print('SQ rows',len(SQ),'bad grades',badg[:5],'S<2 or W>2 :',dict(sc),'no-W:',noW)
print('unknown theme/stage:',unk[:10],len(unk)); print('bad asked-by-party:',badp[:5])
print('time-word questions:',len(tm),tm[:8])
print('question length words: min',min(ln),'avg',round(sum(ln)/len(ln),1),'max',max(ln))
print('per stage counts (min/max):',min(len(v) for v in perstage.values()),max(len(v) for v in perstage.values()), 'stages covered',len(perstage))
# Which existing stages got stage questions?
print('existing stages with new SQ:',sorted(s for s in perstage if s in allst-newst))
dup=[k for k,c in collections.Counter(q['Question'].strip().lower() for q in SQ).items() if c>1]
print('duplicate question texts:',len(dup),dup[:5])
# Also versus master SQ
mdup=set(q['Question'].lower() for q in m_sq); print('overlap with master SQ:',[q['Q ID'] for q in SQ if q['Question'].lower() in mdup][:5])
# Themes used by SQ that are not mapped by master or proposed => pleases nobody (checked above)
# party-limited questions: do the stages seat that party?
h,ed=table('Edits to Existing Rows'); opp={d['Opp ID']:dict(d) for d in m_opp}
for e in ed:
    if e['Tab']=='Opponents': opp[e['Row ID']]['Stage']=e['Proposed']
pname={d['Party ID']:d['Party Name'] for d in m_parties}
unseat=[]
for q in SQ:
    ab=q.get('Asked By Party')
    if not ab: continue
    for s in stg(q['Stage ID']):
        for p in str(ab).split(';'):
            p=p.strip()
            if p=='OWN': continue
            if not any(s in stg(o.get('Stage')) and o['Party']==pname[p] for o in opp.values()): unseat.append((q['Q ID'],s,p))
print('party-limited questions with nobody of that party seated:',len(unseat),unseat[:10])
print('questions with Asked By Party:',sum(1 for q in SQ if q.get('Asked By Party')),' by value',collections.Counter(q.get('Asked By Party') for q in SQ).most_common(8))
# stage questions on existing stages: per-stage counts vs master
mc=collections.Counter(s for q in m_sq for s in stg(q['Stage ID'])); print('master SQ per stage', dict(mc))
print('proposed SQ on existing stages per stage',{s:len(perstage[s]) for s in sorted(perstage) if s in allst-newst})
# question density and S distribution by suit
print('S-count by suit:',{s:sum(1 for q in SQ if q[s]=='S') for s in SUITS},' W-count:',{s:sum(1 for q in SQ if q[s]=='W') for s in SUITS})
