import sys,shutil,re,math
sys.path.insert(0,'/tmp/claude-0/b1'); sys.path.insert(0,'/tmp/claude-0/b2')
from wbx import WB
from model import SEATS
from ovr import OVR
MASTER='/home/user/CoP-Deckbuilder/design/CoP_Starter_Card_Stage_Data.xlsx'; OUT='/tmp/claude-0/b2/draft3.xlsx'
shutil.copy(MASTER,OUT); w=WB(OUT)
# 1. Balance levers
w.append_row('Balance',{'A':'Law lean: Party-tier Pass Delta','B':3,'C':'Party Headquarters and Party Faction (the Boosters tab\'s tier "Party") move by this when a bill passes, from where the PLAYER\'S OWN party stood on it: up if the party backed it, down if it opposed it. A Neutral party moves nothing. Replaces fixed Law Effects rows for those two organisations.'})
w.append_row('Balance',{'A':'Law lean: Party-tier Fail Delta','B':1,'C':'The same, when the bill fails (a bill the party opposed failing pleases them; one it backed failing annoys them).'})
# 2. Law Effects
EDITS=[('BI06','BO05',0),('BI22','BO05',0),('BI42','BO05',0),('BI41','BO05',0),('BI42','BO16',3),('BI41','BO25',3),
('BI35','BO05',-2),('BI07','BO05',-2),('BI01','BO05',-2),
('BI36','BO23',3),('BI26','BO23',2),('BI09','BO23',2),('BI25','BO23',2),('BI45','BO23',0),('BI13','BO23',0),('BI01','BO23',0),
('BI10','BO11',0),('BI34','BO11',0),('BI40','BO11',0),('BI31','BO11',0),('BI39','BO11',-2),('BI24','BO11',-2),('BI36','BO11',-2),('BI18','BO11',-2),
('BI44','BO15',2),('BI18','BO15',2),('BI39','BO15',2),('BI05','BO15',2),('BI11','BO15',0),('BI40','BO15',0),
('BI24','BO16',0),('BI49','BO16',0),('BI45','BO16',0),('BI21','BO16',-2),('BI27','BO16',-2),('BI47','BO16',-2),('BI18','BO16',-2),
('BI42','BO22',-2),('BI37','BO24',-2),('BI16','BO24',-2),
('BI46','BO12',0),('BI44','BO12',0),('BI17','BO12',-2),('BI37','BO07',-2),('BI37','BO14',-2),('BI08','BO14',-2),
('BI49','BO18',-2),('BI18','BO18',-2),('BI08','BO18',-2),('BI46','BO29',2),('BI42','BO29',-2),
('BI25','BO20',-2),('BI39','BO21',-2),('BI25','BO19',-2),('BI03','BO13',-2),('BI43','BO13',-2),('BI50','BO17',-2)]
rows=w.rows('Law Effects'); idx={}
for r,v in rows.items():
    if r>1 and v.get('A','').startswith('LW'): idx[(v['B'],v['C'],v.get('D','Once'))]=(r,v)
def parse(s): return [(m.group(1),int(m.group(2))) for m in re.finditer(r'(BO\d+)\s*([+-]\d+)',s or '')]
touched=set(b for b,_,_ in EDITS)
for bid in sorted({k[0] for k in idx}):
    r,v=idx[(bid,'Passed','Once')]
    ent=dict(parse(v.get('E','')))
    for b in ('BO01','BO02'): ent.pop(b,None)
    for eb,bo,d in EDITS:
        if eb==bid:
            if d==0: ent.pop(bo,None)
            else: ent[bo]=d
    if not any(d==3 for d in ent.values()):
        pos=[b for b,d in ent.items() if d>0]
        if pos: ent[pos[0]]=3
    order=sorted(ent.items(),key=lambda kv:(-kv[1],kv[0]))
    eff='; '.join(f'{b} {d:+d}' for b,d in order)
    f=lambda d:-1 if d>0 else 1
    feff='; '.join(f'{b} {f(d):+d}' for b,d in order)
    w.set_cell('Law Effects',r,'E',eff)
    note=v.get('K','')
    if 'Rebalanced 2026-10-13' not in note:
        w.set_cell('Law Effects',r,'K',note+' Rebalanced 2026-10-13 (draft): party-tier organisations now follow the player\'s party lean (Balance tab).')
    fr,fv=idx[(bid,'Failed','Once')]
    w.set_cell('Law Effects',fr,'E',feff)
# 3. Party position overrides
CN={'S':'Supportive','O':'Opposed','N':'Neutral'}
def forced(d,pid):
    n=SEATS[pid]; y,nn,ab={'S':(.72,.28,0),'O':(.28,.72,0),'N':(.31,.31,.38)}[d]
    raw=[y*n,nn*n,ab*n];ints=[int(math.floor(x)) for x in raw];rem=n-sum(ints)
    for i in sorted(range(3),key=lambda i:-(raw[i]-ints[i]))[:rem]:ints[i]+=1
    return ints
pr=w.rows('Floor Vote Party Positions')
for r,v in pr.items():
    bid,pid=v.get('A'),v.get('B')
    if bid in OVR and pid in OVR[bid]:
        d,line=OVR[bid][pid]; y,n,a=forced(d,pid)
        assert len(line.split())<=9,line
        for col,val in zip('CDEFG',(y,n,a,CN[d],line)): w.set_cell('Floor Vote Party Positions',r,col,val)
# 4. new influence cues where the default result changed
for bid,direction,text in [('BI39','Flipped to Pass',"Members backed the shipyards after all, and the defense industry bill squeaked through."),
    ('BI40','Flipped to Pass',"Members agreed on a slate of commissioners, and the constitutional review went ahead."),
    ('BI41','Flipped to Fail',"Members balked at sharing border data with Japan, and the customs bill was withdrawn.")]:
    w.append_row('Vote Influence Cues',{'A':bid,'B':direction,'C':text})
w.save(); print('ok')
