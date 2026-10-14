exec(open('audit1.py').read().split("# ---- 1. header")[0])
import re
SUITS=['Earnest','Emotional','Appeal','Data Driven','Divisive','Duplicitous']
# ===== A. affinity
ah,ar=P['Affinity']
print('AFFINITY cols',ah[:3],len(ah))
newst=[d['Stage ID'] for d in P['Stages'][1]]
bad=[]
for st in newst:
    vals=[float(r[st]) for r in ar if r.get('Element') in SUITS]
    if sorted(vals)!=sorted([1.5,1.3,1.0,1.0,0.7,0.5]) and sorted(vals)!=sorted([1.3,1.3,1.0,1.0,0.7,0.7]) :
        pass
    bad.append((st,sorted(vals)))
cnt=collections.Counter(tuple(b[1]) for b in bad)
print('AFFINITY shapes:',dict(cnt))
print('missing affinity col for stages:',[s for s in newst if s not in ah])
for st in newst[:3]: print(st,[(r['Element'],r[st]) for r in ar if r.get('Element') in SUITS])
# favoured suit
mstages={d['Stage ID']:d for d in m_stages}
# ===== B. seating: eligible opponents per stage after edits
opp={d['Opp ID']:dict(d) for d in m_opp}
h,ed=P_edits=table('Edits to Existing Rows')
for e in ed:
    if e['Tab']=='Opponents':
        o=opp[e['Row ID']]; 
        if str(o['Stage'])!=str(e['Current']): print('EDIT MISMATCH current',e['Row ID'],o['Stage'],'vs',e['Current'])
        o['Stage']=e['Proposed']
    if e['Tab']=='Levels':
        pass
def stages_of(o): return [s.strip() for s in str(o.get('Stage') or '').split(';') if s.strip()]
allst=list(mstages)+newst
need={}
for d in list(m_stages)+P['Stages'][1]:
    need[d['Stage ID']]=(d.get('Opponent Count'),d['Mode'],d.get('Own Party Only'))
print()
print('SEATING (new stages): eligible opps, parties, needed')
playerparties=['Frontier Party','Keizaijiyuutou','Country Initiative']
for st in newst:
    el=[o for o in opp.values() if st in stages_of(o)]
    pc=collections.Counter(str(o['Party']) for o in el)
    cnt=need[st][0]
    print(st, 'need',cnt,'have',len(el), dict(pc))
# existing stages: did edits change seating counts?
print('\nSEATING changes on existing stages:')
for st in mstages:
    before=len([o for o in m_opp if st in stages_of(o)])
    after=len([o for o in opp.values() if st in stages_of(o)])
    if before!=after: print(st,before,'->',after)
