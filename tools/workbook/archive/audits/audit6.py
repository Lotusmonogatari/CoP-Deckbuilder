exec(open('audit1.py').read().split("# ---- 1. header")[0])
SUITS=['Earnest','Emotional','Appeal','Data Driven','Divisive','Duplicitous']
VERBS=['attack','gain','block']
def stg(v): return [s.strip() for s in str(v or '').split(';') if s.strip()]
def lines(r,keys): return [str(r[k]).strip() for k in keys if r.get(k) not in (None,'')]
PLK=['Cue 1','Cue 2','Cue 3','Cue 4','Cue 5']
# ---- player cue index (replicates DataDB._index_player_cues)
def build_pl(rows):
    idx=collections.defaultdict(list)
    for r in rows:
        ls=lines(r,PLK)
        if not ls: continue
        verb=(r.get('Verb') or '').strip(); st=stg(r.get('Stage ID'))
        for k in ([f"{s}|{r['Suit']}|{verb}" for s in st] if st else [f"{r['Suit']}|{verb}"]): idx[k]+=ls
    return idx
def pl_lookup(idx,suit,verb,stage):
    keys=[f"{stage}|{suit}|{verb}",f"{stage}|{suit}|",f"{suit}|{verb}",f"{suit}|"]
    for k in keys:
        if idx.get(k): return k,idx[k]
    return None,[]
allpl=m_pl+P['Player Cues'][1]
idx=build_pl(allpl)
newst=[d['Stage ID'] for d in P['Stages'][1]]
combat=[d['Stage ID'] for d in m_stages if d['Mode']=='Combat']+newst
print('PLAYER CUE reach (per stage: min/avg distinct lines over 18 suit x verb cells; tier used)')
res={}
for s in combat:
    cells=[]; tiers=collections.Counter()
    for su in SUITS:
        for v in VERBS:
            k,l=pl_lookup(idx,su,v,s); cells.append(len(set(l))); 
            tiers['stage+verb' if k and k.startswith(s+'|') and k.endswith('|'+v) else 'stage-anyverb' if k and k.startswith(s+'|') else 'universal' if k else 'none']+=1
    res[s]=(min(cells),sum(cells)/18,tiers)
for s,(mn,av,t) in res.items(): print(s,'min',mn,'avg',round(av,1),dict(t))
