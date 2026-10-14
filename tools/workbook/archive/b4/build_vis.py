import sys,json,re
sys.path.insert(0,'/tmp/claude-0/b1');sys.path.insert(0,'/tmp/claude-0/b3');sys.path.insert(0,'/tmp/claude-0/b4')
from wbx import *
from visitors import V
from spec import B
import openpyxl
REPO='/home/user/CoP-Deckbuilder'; P=REPO+'/design/CoP_Starter_Card_Stage_Data.xlsx'
w=WB(P); ox=openpyxl.load_workbook(P,read_only=True,data_only=True)
orows=lambda n:[list(r) for r in ox[n].iter_rows(values_only=True)]
le=json.load(open(REPO+'/data/law_effects.json'))
NOTE='Draft 2026-10-14'
# --- stages ST101-ST120
S=orows('Stages'); st07=[r for r in S if r[0]=='ST07'][0]
aff=orows('Affinity'); 
cols_aff=[r[0] for r in aff]  # not used
first_aff=len(aff[0])+1
LASTAFF=n2col(first_aff+19)
CL=[n2col(i+1) for i in range(46)]
r0=w.last_data_row('Stages')
newst={}
for i,(bid,b) in enumerate(B.items()):
    st=f'ST{101+i}'; newst[bid]=st
    v=list(st07); v[0]=st; v[1]=f'Office Hours: {b["T"]}'; v[2]=f'{b["jp"]}陳情'; v[3]=f'Chinjō: {b["ro"]}'
    r=r0+1+i
    for j,val in enumerate(v):
        col=CL[j]
        if j==9: w.set_cell('Stages',r,col,1,formula=f'IF(AND(ISNUMBER(H{r}),ISNUMBER(I{r})),IF(H{r}=0,"",I{r}/H{r}),"varies")',style_from=r-1)
        elif j==22: w.set_cell('Stages',r,col,round(sum(v[16:22]),4),formula=f'SUM(Q{r}:V{r})',style_from=r-1)
        elif j==23: w.set_cell('Stages',r,col,'—',formula=f'IF(E{r}<>"Combat","—","—")',style_from=r-1)
        elif val is not None: w.set_cell('Stages',r,col,val,style_from=r-1)
    col=n2col(first_aff+i)
    w.set_cell('Affinity',1,col,st,style=w.sty('Affinity','V1'))
    base=[x[ [h for h in aff[0]].index('ST07') ] for x in aff]   # ST07 column values
    for j in range(2,8): w.set_cell('Affinity',j,col,base[j-1],style=w.sty('Affinity',f'V{j}'))
    w.set_cell('Affinity',9,col,v[1],style=w.sty('Affinity','V9'))
    w.set_cell('Affinity',10,col,round(sum(base[1:7])/6,4),formula=f'AVERAGE({col}2:{col}7)',style=w.sty('Affinity','V10'))
# --- general visitors also appear in the new Office Hours
rows=w.rows('Visitors'); newids=list(newst.values())
for r,v in rows.items():
    if r>1 and v.get('F')=='ST07' or (r>1 and 'ST07' in v.get('F','').split('; ')):
        items=[x.strip() for x in v['F'].split(';')]
        w.set_cell('Visitors',r,'F','; '.join(items+newids))
vn=max(int(v['A'][2:]) for v in rows.values() if re.fullmatch(r'VI\d+',v.get('A','')))
qn=max(int(v['A'][2:]) for v in w.rows('Visitor Questions').values() if re.fullmatch(r'VQ\d+',v.get('A','')))
bname={b['booster_id']:b['name_en'] for b in json.load(open(REPO+'/data/boosters.json'))}
pins=[]; arows=orows('Assets'); vtemplate=[r for r in arows if r[0]=='VI39']; stt=[r for r in arows if r[0]=='ST07'][0]
for i,(bid,b) in enumerate(B.items()):
    vn+=1; vid=f'VI{vn}'; name,jp,ro,role,qs=V[bid]
    win=[];lose=[]
    for r in le:
        if r['bill_id']==bid and r['outcome']=='Passed' and r['timing']!='Each level':
            for e in r['effects'] or []: (win if e['delta']>0 else lose).append((e['delta'],e['target']))
    win=[t for d,t in sorted(win,reverse=True)]
    t1=win[0] if win else 'BO18'; t2=win[1] if len(win)>1 else 'BO03'
    w.append_row('Visitors',{'A':vid,'B':name,'C':jp,'D':ro,'E':role,'F':newst[bid],'G':f'{t1} +1-3; {t2} +1','H':f'{t1} -1'})
    pins.append({'level_id':f'LV{63+i}','slot':1,'visitor_id':vid})
    for k,(q,good,b1,b2,b3,rr,rw,kr,kw) in enumerate(qs):
        qn+=1; opts=[b1,b2,b3]; pos=(i+k)%4; opts.insert(pos,good)
        w.append_row('Visitor Questions',{'A':f'VQ{qn}','B':vid,'C':q,'D':opts[0],'E':opts[1],'F':opts[2],'G':opts[3],'H':'ABCD'[pos],'I':rr,'J':rw,'K':kr,'L':kw})
    for t in vtemplate:
        v=list(t); v[0]=vid; v[2]=name; v[4]=v[4].replace('VI39',vid); v[9]='No'
        w.append_row('Assets',{n2col(j+1):x for j,x in enumerate(v) if x is not None})
    v=list(stt); v[0]=newst[bid]; v[2]=f'Office Hours: {b["T"]}'; v[4]=newst[bid]+'.png'; v[9]='No'; v[10]=f'{NOTE}: topic Office Hours, background not drawn yet.'
    w.append_row('Assets',{n2col(j+1):x for j,x in enumerate(v) if x is not None})
# --- levels: slot 1 becomes the bill's own Office Hours
lr=w.rows('Levels'); byl={v['A']:k for k,v in lr.items() if 'A' in v and k>1}
for i,bid in enumerate(B): w.set_cell('Levels',byl[f'LV{63+i}'],'I',newst[bid])
w.save()
p=REPO+'/data/level_visitor_overrides.json'; d=json.load(open(p)); d['overrides']=pins
d['_README'].append('2026-10-14: LV63-LV82 each pin their own bill-specific visitor (VI40-VI59) to slot 1.')
json.dump(d,open(p,'w'),ensure_ascii=False,indent=2)
print('ok',len(pins))
