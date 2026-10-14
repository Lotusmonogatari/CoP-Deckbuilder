exec(open('audit6.py').read().split("print('PLAYER CUE reach")[0])
import re
TIME=['now','today','again','already','still','before','always','never','yet','eventually','finally','once','soon','tomorrow','yesterday','last time','anymore','ever','longer','recently','lately','used to','when will','until']
TIMERE=re.compile(r'\b('+'|'.join(re.escape(t) for t in TIME)+r')\b',re.I)
def words(s): return len(str(s).split())
def check_cues(name,rows,keys,maxw=9):
    over=[];tm=[];empty=[];dupl=collections.Counter()
    for r in rows:
        n=0
        for k in keys:
            v=r.get(k)
            if v in (None,''): continue
            n+=1
            if words(v)>maxw: over.append((r.get('Cue ID'),k,words(v),str(v)))
            m=TIMERE.search(str(v))
            if m: tm.append((r.get('Cue ID'),k,m.group(0),str(v)))
            dupl[str(v).strip().lower()]+=1
        if n<5: empty.append((r.get('Cue ID'),n))
    d=[k for k,c in dupl.items() if c>1]
    print(f'{name}: rows {len(rows)} | >{maxw} words: {len(over)} | time words: {len(tm)} | rows<5 cues: {len(empty)} | duplicate lines: {len(d)}')
    return over,tm,empty,d
print('--- master baseline')
check_cues('master PL',m_pl,PLK); check_cues('master OC',m_oc,['Cue 1','Cue 2','Cue 3','Cue 4','Cue 5'])
print('--- proposed')
o1=check_cues('PL',P['Player Cues'][1],PLK)
o2=check_cues('OC',P['Opponent Cues'][1],['Cue 1','Cue 2','Cue 3','Cue 4','Cue 5'])
for tag,o in (('PL',o1),('OC',o2)):
    print(tag,'over-length sample:',o[0][:6])
    print(tag,'time-word sample:',o[1][:12])
    print(tag,'duplicate sample:',o[3][:6])
