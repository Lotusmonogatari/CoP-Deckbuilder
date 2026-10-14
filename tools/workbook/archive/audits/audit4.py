exec(open('audit1.py').read().split("# ---- 1. header")[0])
print('master level tiers:',collections.Counter((d['Level ID'][:3],d['Level Tier']) for d in m_levels if d['Level ID']>='LV31').most_common(3), collections.Counter(d['Level Tier'] for d in m_levels))
print('master LV01-30 tier/cool sample:',[(d['Level ID'],d['Level Tier'],d.get('Cooldown Period  (# of other levels to play before this level is available to play again)')) for d in m_levels[:6]])
# type check numeric cells in Levels and Stages
H,L=P['Levels']
for d in L:
    t=[(k[:25],type(v).__name__) for k,v in d.items() if isinstance(v,str) and v.replace('.','',1).isdigit()]
    if t: print('LEVEL numeric-as-text',d['Level ID'],t[:4])
H,S=P['Stages']
tt=collections.Counter()
for d in S:
    for k,v in d.items():
        if isinstance(v,str) and v.replace('.','',1).replace('-','',1).isdigit(): tt[k]+=1
print('STAGES numeric-as-text cols:',dict(tt))
# compare Stages numbers to master types
ms=m_stages[0]; print({k:type(v).__name__ for k,v in ms.items() if k in('Win threshold','Turn limit','Opponent Count','Energy Pool','Bar max')})
print({k:S[0][k] for k in ('Win threshold','Turn limit','Opponent Count','Energy Pool','Bar max','Hand size','失言 gaffe limit','Player start','Opp start')})
# stage economy comparison
def stats(rows,key):
    return {k:sorted(set(r.get(key) for r in rows)) for k in [key]}
cols=['Bar max','Win threshold','Turn limit','持ち時間 / turn (energy)','Hand size','失言 gaffe limit','Player start','Opp start','Win ΔJiban','Win ΔYen','Win ΔReputation','Win ΔXP','Win ΔParty support','Loss ΔJiban','Loss ΔYen','Loss ΔReputation','Loss ΔXP','Loss ΔParty support']
print('\nSTAGE economy: master combat(min..max) vs proposed')
mc=[d for d in m_stages if d['Mode']=='Combat']
for c in cols:
    mv=[float(d[c]) for d in mc if d.get(c) is not None]
    pv=[float(d[c]) for d in S if d.get(c) is not None]
    print(f'{c[:28]:30} master {min(mv) if mv else "-"}..{max(mv) if mv else "-"}   proposed {min(pv) if pv else "-"}..{max(pv) if pv else "-"}  ({len(pv)} of {len(S)} set)')
