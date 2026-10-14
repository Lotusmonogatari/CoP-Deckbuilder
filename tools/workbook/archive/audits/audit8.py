exec(open('audit6.py').read().split("print('PLAYER CUE reach")[0])
ocP=P['Opponent Cues'][1]
leak=[r for r in ocP if r.get('Opponent ID') and not stg(r.get('Stage ID'))]
oppn={d['Opp ID']:(d['Name'],d['Party'],d['Stage']) for d in m_opp}
for r in leak: print(r['Cue ID'],r['Suit'],r['Verb'],r['Opponent ID'],oppn[r['Opponent ID']][1],'|',r['Cue 1'],'|',r['Cue 2'])
print()
gl=[r for r in ocP if not r.get('Opponent ID') and not stg(r.get('Stage ID'))]
print('general any-stage proposed rows:',len(gl))
for r in gl[:4]: print(r['Cue ID'],r['Suit'],r['Verb'],r['Cue 1'],'|',r['Cue 2'])
