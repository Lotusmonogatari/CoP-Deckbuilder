import json,collections
fv=json.load(open('data/floor_votes.json')); le=json.load(open('data/law_effects.json'))
bo=json.load(open('data/boosters.json')); pa=json.load(open('data/parties.json'))
bn={ (b['booster_id'] if isinstance(b,dict) else k):(b['name_en'] if isinstance(b,dict) else b['name_en']) for k,b in (bo.items() if isinstance(bo,dict) else [(x['booster_id'],x) for x in bo])}
pn={ (p['party_id']):p['name_en'] if 'name_en' in p else p.get('name') for p in (pa.values() if isinstance(pa,dict) else pa)}
def grp(lo,hi):
  ids=[f'BI{n:02d}' for n in range(lo,hi+1)]
  fav=collections.Counter();ann=collections.Counter()
  for r in le:
    if r['bill_id'] in ids and r['outcome']=='Passed':
      for e in r['effects'] or []:
        (fav if e['delta']>0 else ann)[e['target']]+=1
  par={p:collections.Counter() for p in pn}
  for i in ids:
    for pos in fv[i]['positions']: par[pos['party_id']][pos['disposition']]+=1
  return fav,ann,par
out=[]
for lab,(lo,hi) in [('ALL 50',(1,50)),('NEW 20 (BI31-50)',(31,50))]:
  fav,ann,par=grp(lo,hi)
  out.append(f'### {lab}: boosters (bills passed that favour / annoy)\n\n| Booster | Favoured by | Annoyed by |\n|---|---|---|')
  for b in sorted(bn,key=lambda b:-(fav[b]+ann[b])): out.append(f'| {bn[b]} ({b}) | {fav[b]} | {ann[b]} |')
  out.append(f'\n### {lab}: parties\n\n| Party | Aligns (Supportive) | Opposes | Neutral |\n|---|---|---|---|')
  for p in pn: out.append(f'| {pn[p]} | {par[p]["Supportive"]} | {par[p]["Opposed"]} | {par[p]["Neutral"]} |')
  out.append('')
open('/tmp/claude-0/b2/report.md','w').write('\n'.join(out)); print('\n'.join(out))
