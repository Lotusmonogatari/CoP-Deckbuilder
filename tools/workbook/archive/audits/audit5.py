exec(open('audit1.py').read().split("# ---- 1. header")[0])
seats={d['Party ID']:d for d in m_parties}
print('parties cols',list(m_parties[0].keys())[:8]); 
seatcol=[k for k in m_parties[0] if 'Seat' in k][0]
seat={d['Party ID']:int(d[seatcol]) for d in m_parties}; print(seat, sum(seat.values()))
H,B=P['Floor Vote Bills']; H2,POS=P['Floor Vote Party Positions']
bypos=collections.defaultdict(list)
for p in POS: bypos[p['Bill ID']].append(p)
vic={d['Bill ID']:d['Outcome Direction'] for d in P['Vote Influence Cues'][1]}
h,notes=table('Bill Notes')
nd={n['Bill']:n for n in notes}
print()
for b in B:
    bid=b['Bill ID']; ps=bypos[bid]
    y=sum(int(p['Votes Yes']) for p in ps); n=sum(int(p['Votes No']) for p in ps); a=sum(int(p['Votes Abstain']) for p in ps)
    badseat=[(p['Party ID'],int(p['Votes Yes'])+int(p['Votes No'])+int(p['Votes Abstain']),seat[p['Party ID']]) for p in ps if int(p['Votes Yes'])+int(p['Votes No'])+int(p['Votes Abstain'])!=seat[p['Party ID']]]
    need=(y+n+a)//2+1
    default='PASS' if y>=need else 'FAIL'
    want='Flipped to Fail' if default=='PASS' else 'Flipped to Pass'
    print(bid,b['Bill Name (EN)'],f'| Y{y} N{n} A{a} = {y+n+a} | need {need} | default {default} | cue={vic.get(bid)} | {"OK" if vic.get(bid)==want else "CUE MISMATCH"} | seatErrors={badseat} | parties={len(ps)}')
    # dispositions vs vote lean
    print('    ',[ (p['Party ID'],p['Disposition'][:3],f"{p['Votes Yes']}-{p['Votes No']}-{p['Votes Abstain']}") for p in ps])
    # swing viability: how many more Yes to flip
    print('     distance to flip: need',need,'yes',y,'gap',need-y if default=='FAIL' else y-need)
    wc=[ (p['Party ID'],len(str(p['Cue Text']).split())) for p in ps]
    print('     cue words>20:',[w for w in wc if w[1]>20], ' name-in-cue?', [p['Party ID'] for p in ps if p['Party Name (reference only)'] and str(p['Party Name (reference only)']).lower() in str(p['Cue Text']).lower()])
print()
print('Bill Notes flip dir vs cue:',[(k,n['Flip cue direction'],vic.get(k)) for k,n in nd.items() if n['Flip cue direction']!=vic.get(k)])
# dispositions in master: how are they related to the vote lean? summarise master
print('\nMASTER disposition vs lean check')
mp=collections.defaultdict(list)
for p in m_pos: mp[p['Bill ID']].append(p)
agree=0;tot=0
for bid,ps in mp.items():
    for p in ps:
        tot+=1
        y,n=int(p['Votes Yes']),int(p['Votes No']); d=p['Disposition']
        if (d=='Supportive' and y>=n) or (d=='Opposed' and n>=y) or d=='Neutral': agree+=1
print('master agree',agree,'/',tot)
agree=0;tot=0;odd=[]
for p in POS:
    tot+=1; y,n=int(p['Votes Yes']),int(p['Votes No']); d=p['Disposition']
    if (d=='Supportive' and y>=n) or (d=='Opposed' and n>=y) or d=='Neutral': agree+=1
    else: odd.append((p['Bill ID'],p['Party ID'],d,y,n))
print('proposed agree',agree,'/',tot,odd)
# favorability deltas vs master range
print('master favorability delta ranges:',collections.Counter((b['Favorability Delta (Supportive)'],b['Favorability Delta (Opposed)'],b['Favorability Delta (Neutral)']) for b in m_bills).most_common(5))
print('proposed:',collections.Counter((b['Favorability Delta (Supportive)'],b['Favorability Delta (Opposed)'],b['Favorability Delta (Neutral)']) for b in B))
# master defaults
print('\nMASTER default outcomes:')
c=collections.Counter()
for bid,ps in mp.items():
    y=sum(int(p['Votes Yes']) for p in ps); c['PASS' if y>=51 else 'FAIL']+=1
print(c)
