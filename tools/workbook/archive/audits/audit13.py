exec(open('audit9.py').read().split("print('--- master baseline')")[0])
LW=P['Law Effects'][1]
boost={d['Booster ID']:d for d in m_boost}
print('LAW EFFECTS rows',len(LW))
bad=[];mag=collections.Counter()
for l in LW:
    for part in str(l['Effects']).split(';'):
        part=part.strip()
        m=re.match(r'^(BO\d+|SG\d+)\s*([+-]\d+)$',part)
        if not m: bad.append((l['Law ID'],part)); continue
        if m.group(1).startswith('BO') and m.group(1) not in boost: bad.append((l['Law ID'],'unknown '+m.group(1)))
        mag[(l['Outcome'],int(m.group(2)))]+=1
    print(l['Law ID'],l['Bill ID'],l['Outcome'],l['Timing'],'|',l['Effects'],'|',{k:l[k] for k in('Constituency support','Reputation','Funds','Party support','XP') if l.get(k) is not None},'|',str(l['Note'])[:70])
print('bad:',bad); print('magnitudes:',sorted(mag.items()))
mm=collections.Counter()
for l in m_law:
    for part in str(l['Effects']).split(';'):
        m=re.match(r'^\s*(BO\d+)\s*([+-]\d+)',part)
        if m: mm[(l['Outcome'],int(m.group(2)))]+=1
print('master magnitudes:',sorted(mm.items()))
# bills covered
bills=set(b['Bill ID'] for b in P['Floor Vote Bills'][1]); cov=collections.defaultdict(set)
for l in LW: cov[l['Bill ID']].add(l['Outcome'])
print('bills without both outcomes:',[b for b in bills if cov[b]!={'Passed','Failed'}])
# D8 check on the union
pl=set();an=set()
for l in m_law+LW:
    for part in str(l['Effects']).split(';'):
        m=re.match(r'^\s*(BO\d+)\s*([+-]\d+)',part)
        if m: (pl if int(m.group(2))>0 else an).add(m.group(1))
print('orgs never pleased:',sorted(set(boost)-pl),'never annoyed:',sorted(set(boost)-an))
# organisation usage frequency in new laws
use=collections.Counter()
for l in LW:
    for part in str(l['Effects']).split(';'):
        m=re.match(r'^\s*(BO\d+)',part)
        if m: use[m.group(1)]+=1
print('new law org usage',use.most_common())
# thoughts
print('\nLEVEL INTRO THOUGHTS')
lv={d['Level ID'] for d in P['Levels'][1]}
for t in P['Level Intro Thoughts'][1]:
    print(t['Level ID'], 'level-exists' if t['Level ID'] in lv else 'MISSING LEVEL','|',words(t['Thought Text']),'w |',t['Thought Text'])
mthought=[words(d.get('Thought Text') or d.get('Thought') or '') for d in m_lit]; print('master thought word counts avg',round(sum(mthought)/max(1,len(mthought)),1), list(m_lit[0].items()) if m_lit else '')
