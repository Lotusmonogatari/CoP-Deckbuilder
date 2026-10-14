exec(open('audit9.py').read().split("print('--- master baseline')")[0])
H,S=P['Stages']; ah,ar=P['Affinity']
for d in S:
    sid=d['Stage ID']
    mix=[d.get(k) or 0 for k in ['% Press','% Party Members','% Constituents','% Donors','% Bureaucrats','% Other']]
    tot=round(sum(float(x) for x in mix),3)
    aff={r['Element']:float(r[sid]) for r in ar if r.get('Element') in SUITS}
    top=max(aff,key=aff.get); topn=[k for k,v in aff.items() if v==aff[top]]
    flag=[]
    if tot!=1.0: flag.append(f'segments sum {tot}')
    if d.get('Favored suit') not in topn: flag.append(f"favored suit cell={d.get('Favored suit')} vs top affinity {topn}")
    if abs(float(d['Win %'])-float(d['Win threshold'])/float(d['Bar max']))>0.001: flag.append('Win% mismatch')
    if str(d.get('Segment check'))[:2]!='OK' and d.get('Segment check') not in (1,1.0,True,'OK'): flag.append(f"segcheck={d.get('Segment check')}")
    if flag: print(sid,flag)
print('stage rows checked')
print('Segment check sample:',S[0].get('Segment check'),'| Favored sample:',S[0].get('Favored suit'), '| master sample:',m_stages[0].get('Segment check'),m_stages[0].get('Favored suit'))
# Formula text in proposed cells?
f=[(d['Stage ID'],k) for d in S for k,v in d.items() if isinstance(v,str) and v.startswith('=')]; print('formula cells in proposed stages:',len(f))
# Assets
AH,AR=P['Assets']
print('\nASSETS',len(AR),collections.Counter(a['Category'] for a in AR))
print({k:AR[0][k] for k in AR[0]})
mA=mt('Assets')[1]; mcat=collections.Counter(a['Category'] for a in mA); print('master asset categories',dict(mcat))
miss=[d['Stage ID'] for d in S if not any(a['Asset ID']==d['Stage ID'] for a in AR)]; print('new stages w/o background asset row:',miss)
# existing master backgrounds present for ST01..? 
import os
have=[f for f in os.listdir('/home/user/CoP-Deckbuilder/assets/backgrounds')]; print('existing backgrounds',len(have),sorted(have)[:6])
# draft markers
print('Stages file note:',wb['Stages']['A1'].value[:200])
