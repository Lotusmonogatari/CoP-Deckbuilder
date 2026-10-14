import sys, shutil, re, json
sys.path.insert(0,'/tmp/claude-0/b1'); sys.path.insert(0,'/tmp/claude-0/b3'); sys.path.insert(0,'/tmp/claude-0/b2')
from wbx import *
from spec import B, SU
from cues import BANK, TRANS, lint
from bills import BILLS
import openpyxl
REPO='/home/user/CoP-Deckbuilder'
MASTER='/tmp/claude-0/b3/master_pre.xlsx'
OUT='/tmp/claude-0/b3/draft3.xlsx'
shutil.copy(MASTER,OUT); w=WB(OUT)
ox=openpyxl.load_workbook(MASTER,read_only=True,data_only=True)
def orows(n): return [list(r) for r in ox[n].iter_rows(values_only=True)]
NOTE='Draft 2026-10-13'
BTIER={b[0]:b[4] for b in BILLS}
fv=json.load(open(REPO+'/data/floor_votes.json'))
le=json.load(open(REPO+'/data/law_effects.json'))
bname={b['booster_id']:b['name_en'] for b in json.load(open(REPO+'/data/boosters.json'))}

BASE={'TH':'ST05','PS':'ST21','PR':'ST04','LB':'ST20','MA':'ST19','TV':'ST06','CA':'ST03'}
EN={'TH':'Town Hall on {T}','PS':'Policy Study on {T}','PR':'Press Conference on {T}','HR':'Hearing on {T}','LB':'Lobbyist Meeting on {T}','MA':'Media Ambush on {T}','TV':'TV Debate on {T}','CA':'Party Caucus on {T}'}
JP={'TH':'{jp}を巡る住民集会','PS':'{jp}政策検討会','PR':'{jp}記者会見','HR':'{jp}に関する公聴会','LB':'{jp}に関するロビー活動','MA':'{jp}を巡るぶら下がり取材','TV':'{jp}テレビ討論','CA':'{jp}党内会合'}
RO={'TH':'{ro} o Meguru Jūmin Shūkai','PS':'{ro} Seisaku Kentōkai','PR':'{ro} Kisha Kaiken','HR':'{ro} ni Kansuru Kōchōkai','LB':'{ro} ni Kansuru Robī Katsudō','MA':'{ro} o Meguru Burasagari Shuzai','TV':'{ro} Terebi Tōron','CA':'{ro} Tōnai Kaigō'}
TDELTA={5:2,3:0,1:-2}   # win threshold nudge for the bigger / smaller bills (100-point bars only)
PATS=[((0,1),(4,5)),((0,2),(5,3)),((1,2),(4,5)),((0,3),(5,1))]

# ---------- room plan
plan=[]   # dicts: stage, bill, fam, base, k
n=31
for bid,b in B.items():
    rooms=list(b['rooms'])+['CA']
    for k,code in enumerate(rooms):
        n+=1
        fam,base=(code.split(':')[0],code.split(':')[1]) if ':' in code else (code,BASE.get(code))
        plan.append(dict(stage=f'ST{n}',bill=bid,fam=fam,base=base,k=k,last=(k==len(rooms)-1)))
assert n==100,n
byb={}
for p in plan: byb.setdefault(p['bill'],[]).append(p)

# ---------- Affinity + Stages
S=orows('Stages'); BYID={r[0]:r for r in S[1:] if r[0]}
AFF={}
for p in plan:
    R=B[p['bill']]['R']; ups,downs=PATS[p['k']]
    v={s:1.0 for s in SU}
    v[R[ups[0]]]=1.5; v[R[ups[1]]]=1.3; v[R[downs[0]]]=0.5; v[R[downs[1]]]=0.7
    AFF[p['stage']]=[v[s] for s in SU]
    assert sum(x>=1.3 for x in AFF[p['stage']])==2 and sum(x<=0.7 for x in AFF[p['stage']])==2
firstcol=31
for i,p in enumerate(plan):
    st=p['stage']; col=n2col(firstcol+i); b=B[p['bill']]
    name=EN[p['fam']].format(T=b['T'])
    w.set_cell('Affinity',1,col,st,style=w.sty('Affinity','V1'))
    for j,val in enumerate(AFF[st]): w.set_cell('Affinity',j+2,col,val,style=w.sty('Affinity',f'V{j+2}'))
    w.set_cell('Affinity',9,col,name,style=w.sty('Affinity','V9'))
    w.set_cell('Affinity',10,col,round(sum(AFF[st])/6,4),formula=f'AVERAGE({col}2:{col}7)',style=w.sty('Affinity','V10'))
LASTAFF=n2col(firstcol+len(plan)-1)
CL=[n2col(i+1) for i in range(46)]
r0=w.last_data_row('Stages')
for k,p in enumerate(plan):
    r=r0+1+k; st=p['stage']; b=B[p['bill']]
    v=list(BYID[p['base']]); v[0]=st
    v[1]=EN[p['fam']].format(T=b['T']); v[2]=JP[p['fam']].format(jp=b['jp']); v[3]=RO[p['fam']].format(ro=b['ro'])
    if p['fam'] in('TH','PS','PR','HR','CA') and isinstance(v[8],(int,float)) and v[7]==100:
        v[8]=v[8]+TDELTA[BTIER[p['bill']]]
    elif p['fam'] in('PS',) and isinstance(v[8],(int,float)):
        v[8]=v[8]+(1 if BTIER[p['bill']]==5 else -1 if BTIER[p['bill']]==1 else 0)
    v[43]='Yes'
    if p['fam']=='TH': v[39]='town_hall'
    thr,bm=v[8],v[7]
    for i,val in enumerate(v):
        col=CL[i]
        if i==9: w.set_cell('Stages',r,col,round(thr/bm,4),formula=f'IF(AND(ISNUMBER(H{r}),ISNUMBER(I{r})),IF(H{r}=0,"",I{r}/H{r}),"varies")',style_from=r-1)
        elif i==22: w.set_cell('Stages',r,col,round(sum(v[16:22]),4),formula=f'SUM(Q{r}:V{r})',style_from=r-1)
        elif i==23:
            fav=SU[max(range(6),key=lambda j:(AFF[st][j],-j))]
            w.set_cell('Stages',r,col,fav,formula=f'IF(E{r}<>"Combat","—",IFERROR(INDEX(Affinity!$A$2:$A$7,MATCH(MAX(INDEX(Affinity!$B$2:${LASTAFF}$7,0,MATCH(A{r},Affinity!$B$1:${LASTAFF}$1,0))),INDEX(Affinity!$B$2:${LASTAFF}$7,0,MATCH(A{r},Affinity!$B$1:${LASTAFF}$1,0)),0)),"—"))',style_from=r-1)
        elif val is not None:
            w.set_cell('Stages',r,col,val,style_from=r-1)

# ---------- Levels
L=orows('Levels'); LB_={r[0]:r for r in L if r[0]}
for bid,b in B.items():
    num=int(bid[2:])-31
    lid=f'LV{63+num}'; tier={5:2,3:1,1:0}[BTIER[bid]]
    base=LB_[{0:'LV31',1:'LV36',2:'LV49'}[tier]]
    v=list(base); v[0]=lid; v[1]=fv[bid]['bill_name']
    slots=['ST07']+[p['stage'] for p in byb[bid]]+[bid]
    for j in range(10): v[8+j]=slots[j] if j<len(slots) else 'N/A'
    w.append_row('Levels',{n2col(i+1):x for i,x in enumerate(v) if x is not None})

# ---------- Stage Questions + Question Themes
srows=w.rows('Stage Questions'); nq=max(int(v['A'][1:]) for v in srows.values() if re.fullmatch(r'S\d+',v.get('A','')))
trows=w.rows('Question Themes'); have_themes={v.get('A') for v in trows.values()}
PAT6=[((0,1),(4,5)),((0,2),(3,5)),((1,3),(2,4)),((2,3),(0,5)),((0,3),(1,4)),((1,4),(2,5))]
def grade(R,j):
    s,wk=PAT6[j]; out=''
    for su in SU:
        p=R.index(su); out+='S' if p in s else 'W' if p in wk else 'M'
    return out
ALLOW={'TH':6,'HR':6,'PS':5,'LB':4,'MA':5,'PR':3}
newthemes=[]
for bi,(bid,b) in enumerate(B.items()):
    rows=[p for p in byb[bid] if p['fam'] in ALLOW]
    win=[];lose=[]
    for r in le:
        if r['bill_id']==bid and r['outcome']=='Passed' and r['timing']!='Each level':
            for e in r['effects'] or []:
                (win if e['delta']>0 else lose).append((e['delta'],e['target']))
    win=[t for d,t in sorted(win,reverse=True)]; lose=[t for d,t in sorted(lose)]
    pool=['BO23','BO26','BO08']   # fallback sceptics
    t1=win[:3] or pool[:1]
    t2=(lose[:2]+win[3:4]) or ['BO23']
    t3=(win[1:3] or win[:1]); a3=lose[:1]
    for (th,orgs,ann,why) in zip(b['themes'],(t1,t2,t3),('',','.join([]),lose[:1] and lose[:1] or ''),('how it helps','its cost and risk','fairness and rights')):
        pass
    TH=[(b['themes'][0],t1,[]),(b['themes'][1],t2,[]),(b['themes'][2],t3,a3)]
    for th,orgs,ann in TH:
        assert th not in have_themes,th
        have_themes.add(th)
        names=', '.join(bname[o] for o in orgs)
        w.append_row('Question Themes',{'A':th,'B':'; '.join(orgs),'C':f'{NOTE}: {names} follow {th.lower()}.',**({'D':'; '.join(ann)} if ann else {})})
    # which questions each room asks
    perq={j:[] for j in range(6)}
    for p in rows:
        for i in range(ALLOW[p['fam']]): perq[(bi+i)%6].append(p['stage'])
    for j,q in enumerate(b['Q']):
        if not perq[j]: continue
        nq+=1
        d={'A':f'S{nq}','B':'; '.join(perq[j]),'C':q,'D':b['themes'][j//2]}
        for c,ch in zip('EFGHIJ',grade(b['R'],j)): d[c]=ch
        w.append_row('Stage Questions',d)

# ---------- extend existing cue / question lists to the new rooms
fam_new={}
for p in plan: fam_new.setdefault(p['base'],[]).append(p['stage'])
def extend(sheet,col):
    rows=w.rows(sheet)
    for r,v in rows.items():
        cell=v.get(col)
        if r==1 or not cell: continue
        items=[x.strip() for x in cell.split(';') if x.strip()]
        add=[]
        for base,news in fam_new.items():
            if base in items: add+= [x for x in news if x not in items and x not in add]
        if add: w.set_cell(sheet,r,col,'; '.join(items+add))
extend('Player Cues','D'); extend('Stage Questions','B')

# ---------- topic Player Cues (templated)
plrows=w.rows('Player Cues'); npl=max(int(v['A'][2:]) for v in plrows.values() if re.fullmatch(r'PL\d+',v.get('A','')))
for bi,(bid,b) in enumerate(B.items()):
    stg='; '.join(p['stage'] for p in byb[bid]); t=b['t']; T=t[0].upper()+t[1:]
    for (suit,verb),tpl in BANK.items():
        npl+=1; d={'A':f'PL{npl}','B':suit,'C':verb,'D':stg}
        for c,idx in zip('EFGHI',((bi+i)%5 for i in range(5))):
            line=tpl[idx].format(t=t,T=T); assert lint(line),line; d[c]=line
        w.append_row('Player Cues',d)

# ---------- transitions
tdn=max(int(v['A'][2:]) for v in w.rows('Transition Dialogue').values() if re.fullmatch(r'TD\d+',v.get('A','')))
tbn=max(int(v['A'][2:]) for v in w.rows('Transition Backgrounds').values() if re.fullmatch(r'TB\d+',v.get('A','')))
for p in plan:
    t=B[p['bill']]['t']
    tbn+=1; w.append_row('Transition Backgrounds',{'A':f'TB{tbn:02d}','B':p['stage'],'C':p['base']})
    for ch,line,reply in TRANS[p['fam']]:
        tdn+=1; line=line.format(t=t); assert len(line.split())<=18 and len(reply.split())<=8
        w.append_row('Transition Dialogue',{'A':f'TD{tdn:02d}','B':ch,'C':p['stage'],'D':line,'E':reply})

# ---------- seating: a new room seats whoever its base room seats
orows_=w.rows('Opponents'); byop={v['A']:k for k,v in orows_.items() if 'A' in v and k>1}
cur={op:orows_[byop[op]].get('I','') for op in byop}
for op,cell in cur.items():
    items=[x.strip() for x in cell.split(';') if x.strip()] if cell and cell!='N/A' else []
    add=[]
    for base,news in fam_new.items():
        if base in items: add+=[x for x in news if x not in items and x not in add]
    if add: w.set_cell('Opponents',byop[op],'I','; '.join(items+add))

# ---------- Assets (background art rows) and level thoughts
A=orows('Assets'); st05=[r for r in A if r[0]=='ST05'][0]
for p in plan:
    v=list(st05); v[0]=p['stage']; v[2]=EN[p['fam']].format(T=B[p['bill']]['T']); v[4]=p['stage']+'.png'; v[9]='No'; v[10]=f'{NOTE}: new topic room, background not drawn yet.'
    w.append_row('Assets',{n2col(i+1):x for i,x in enumerate(v) if x is not None})
for bid,b in B.items():
    w.append_row('Level Intro Thoughts',{'A':f'LV{63+int(bid[2:])-31}','B':b['thought']})
w.save(); print('built',OUT,len(plan),'rooms')
