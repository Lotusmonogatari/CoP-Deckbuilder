exec(open('audit9.py').read().split("print('--- master baseline')")[0])
TC=P['Transition Cast'][1];TB=P['Transition Backgrounds'][1];TD=P['Transition Dialogue'][1]
print('cast speakers',collections.Counter(c['Character ID'] for c in TC))
print('cast stage coverage',len(set(c['Stage ID'] for c in TC)),'dialogue stage coverage',len(set(d['Stage ID'] for d in TD)),'bg',len(set(b['Stage ID'] for b in TB)))
print('cast!=dialogue char mismatch:',[(c['Stage ID'],c['Character ID']) for c in TC if not any(d['Stage ID']==c['Stage ID'] and d['Character ID']==c['Character ID'] for d in TD)])
print('bg id != stage id:',[(b['Stage ID'],b['Background ID']) for b in TB if b['Stage ID']!=b['Background ID']])
staff={d['Staff ID'] if 'Staff ID' in d else list(d.values())[0]:d for d in m_staff}
print('staff cols',list(m_staff[0].keys())[:8])
for sid in ('SF01','SF08','SF15'): print(sid,{k:v for k,v in list(staff[sid].items())[:8]})
combat=[d['Stage ID'] for d in m_stages if d['Mode']=='Combat']+[d['Stage ID'] for d in P['Stages'][1]]
print('combat stages without a transition:',[s for s in combat if s not in set(d['Stage ID'] for d in TD)])
lw=[words(d['Character Line (EN)']) for d in TD]; pw=[words(d['Player Reply (EN)']) for d in TD]
print('char line words min/avg/max',min(lw),round(sum(lw)/len(lw),1),max(lw),'| reply',min(pw),round(sum(pw)/len(pw),1),max(pw))
dig=[(d['Stage ID'],d['Character Line (EN)']) for d in TD if re.search(r'\d',d['Character Line (EN)'])]; print('lines with digits',len(dig),dig[:4])
tw=[(d['Stage ID'],TIMERE.search(d['Character Line (EN)']).group(0)) for d in TD if TIMERE.search(d['Character Line (EN)'])]; print('time words in transitions (informational)',len(tw),tw[:8])
import os
for sid in ('SF01','SF08','SF15'):
    print(sid,'art:',[f for f in os.listdir('/home/user/CoP-Deckbuilder/assets/characters/staff')[:0]] )
print('staff art dir:',os.path.exists('/home/user/CoP-Deckbuilder/assets/characters/staff'), os.listdir('/home/user/CoP-Deckbuilder/assets/characters/staff')[:5] if os.path.exists('/home/user/CoP-Deckbuilder/assets/characters/staff') else '')
print()
for d in TD[:2]+TD[8:10]+TD[22:24]+TD[34:36]: print(d['Stage ID'],d['Character ID'],'|',d['Character Line (EN)'],'|| reply:',d['Player Reply (EN)'])
h,dy=table('Dynamics (reference)')
print(h)
for r in dy[:2]+dy[22:24]: print(r)
