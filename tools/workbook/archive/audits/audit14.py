exec(open('audit9.py').read().split("print('--- master baseline')")[0])
VQ=P['Visitor Questions'][1]
vis={d['Visitor ID']:d for d in m_vis}
print('Visitors tab cols',list(m_vis[0].keys()))
print('master VQ cols',list(m_vq[0].keys()))
c=collections.Counter(q['Correct Choice'] for q in VQ); print('proposed correct-choice distribution',dict(c)); 
cm=collections.Counter(q['Correct Choice'] for q in m_vq); print('master correct-choice distribution',dict(cm))
badv=[q['Question ID'] for q in VQ if q['Visitor ID'] not in vis]; print('unknown visitor IDs',badv)
per=collections.Counter(q['Visitor ID'] for q in VQ); print('proposed per visitor',dict(per))
mper=collections.Counter(q['Visitor ID'] for q in m_vq); print('master per visitor (n visitors, min,max)',len(mper),min(mper.values()),max(mper.values()))
# visitors without any question in master
print('visitors with no question in master+proposed:',[v for v in vis if v not in mper and v not in per])
ln=[len(str(q['Choice '+x])) for q in VQ for x in 'ABCD']; mln=[len(str(q['Choice '+x])) for q in m_vq for x in 'ABCD']
print('choice length avg proposed',round(sum(ln)/len(ln)),'master',round(sum(mln)/len(mln)))
# is the correct choice the longest?
lg=sum(1 for q in VQ if max('ABCD',key=lambda x:len(str(q['Choice '+x])))==q['Correct Choice']); print('correct = longest choice:',lg,'/',len(VQ))
mlg=sum(1 for q in m_vq if max('ABCD',key=lambda x:len(str(q['Choice '+x])))==q['Correct Choice']); print('master correct=longest',mlg,'/',len(m_vq))
for q in VQ[:3]: print(q['Question ID'],q['Visitor ID'],vis[q['Visitor ID']]['Visitor (EN)'],vis[q['Visitor ID']].get('Role'),'|',q['Question text'])
# visitor role vs question topic sample
for q in VQ[:35:6]: print(q['Visitor ID'],vis[q['Visitor ID']].get('Role'),'|',q['Question text'][:90])
blank=[(q['Question ID'],k) for q in VQ for k in q if q[k] in (None,'')]; print('blank cells',blank[:5])
tm=[(q['Question ID'],TIMERE.search(q['Question text']).group(0)) for q in VQ if TIMERE.search(q['Question text'])]; print('time words in visitor Qs',len(tm),tm[:5])
# master VQ has reward/penalty? 
print({k:(m_vq[0][k] if m_vq[0][k] is None else str(m_vq[0][k])[:30]) for k in m_vq[0]})
