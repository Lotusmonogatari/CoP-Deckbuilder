import sys, shutil, re
sys.path.insert(0,'/tmp/claude-0/b1')
from wbx import *
from content import *
import openpyxl

MASTER='/home/user/CoP-Deckbuilder/design/CoP_Starter_Card_Stage_Data.xlsx'
OUT='/tmp/claude-0/b1/draft.xlsx'
shutil.copy(MASTER,OUT)
w=WB(OUT)
ox=openpyxl.load_workbook(MASTER,read_only=True,data_only=True)
def orows(n): return [list(r) for r in ox[n].iter_rows(values_only=True)]
NOTE='Draft 2026-10-13'

# ---------------- Stages
S=orows('Stages'); HDR=S[0]; BYID={r[0]:r for r in S[1:] if r[0]}
SUITS=['Earnest','Emotional','Appeal','Data Driven','Divisive','Duplicitous']
AFF={ # ST: Earnest, Emotional, Appeal, Data, Divisive, Duplicitous
'ST24':[1.0,1.5,1.3,0.7,0.5,1.0],
'ST25':[1.3,0.5,1.0,1.5,0.7,1.0],
'ST26':[1.3,1.0,1.5,0.5,1.0,0.7],
'ST27':[1.3,1.0,0.7,1.5,0.5,1.0],
'ST28':[1.0,0.5,1.0,1.5,0.7,1.3],
'ST29':[1.3,1.5,1.0,1.0,0.5,0.7],
'ST30':[1.3,1.0,1.5,0.7,1.0,0.5],
'ST31':[1.5,1.0,1.0,1.3,0.5,0.7],
}
for k,v in AFF.items():
    ups=sum(x>=1.3 for x in v); downs=sum(x<=0.7 for x in v); neut=sum(x==1.0 for x in v)
    assert (ups,downs,neut)==(2,2,2),(k,v)
# idx: 1 name,2 jp,3 romaji,7 bar max,8 threshold,10 turns,11 energy,12 hand,13 gaffe,14 pstart,15 ostart,16..21 seg,
# 24..28 win deltas,29..33 loss deltas,34 bar model,35 energy mode,36 pool,37 seq,38 oppcount,39 qpool,40 rep,41 reveal,42 loss ends,43 transition
NEW={
'ST24':('ST05',{1:'Town Hall on Commuter Fares',2:'運賃を巡る住民集会',3:'Unchin o Meguru Jūmin Shūkai',15:15,16:22,'seg':[0.1,0.1,0.6,0.1,0,0.1],39:'town_hall'}),
'ST25':('ST21',{1:'Policy Study on Rail Timetables',2:'鉄道ダイヤ政策検討会',3:'Tetsudō Daiya Seisaku Kentōkai',14:2,15:12,'seg':[0,0,0.1,0,0.7,0.2]}),
'ST26':('ST04',{1:'Press Conference on Raising Train Fares',2:'運賃改定記者会見',3:'Unchin Kaitei Kisha Kaiken',8:58,39:None,'seg':[0.85,0,0.1,0,0,0.05]}),
'ST27':('ST15',{1:'Hearing on Rail Safety',2:'鉄道安全に関する公聴会',3:'Tetsudō Anzen ni Kansuru Kōchōkai',8:60,11:4,13:6,14:30,15:32,38:3,'seg':[0,0.2,0.4,0,0.3,0.1],25:20000,27:60}),
'ST28':('ST20',{1:'Lobbyist Meeting on Fishing Quotas',2:'漁獲枠に関するロビー活動',3:'Gyokaku-waku ni Kansuru Robī Katsudō',36:12,'seg':[0,0,0,1,0,0]}),
'ST29':('ST05',{1:'Town Hall at the Harbour',2:'漁港の住民集会',3:'Gyokō no Jūmin Shūkai',8:58,'seg':[0.05,0.05,0.7,0.1,0,0.1],39:'town_hall'}),
'ST30':('ST19',{1:'Media Ambush on Seafood Labelling',2:'水産物表示を巡るぶら下がり取材',3:'Suisanbutsu Hyōji o Meguru Burasagari Shuzai'}),
'ST31':('ST13',{1:'Hearing on Fishery Quotas',2:'漁獲枠に関する公聴会',3:'Gyokaku-waku ni Kansuru Kōchōkai',8:55,11:4,13:6,'seg':[0,0.2,0.5,0,0.1,0.2]}),
}
# Affinity first (new columns W..AD)
AFFCOL={st:n2col(23+i) for i,st in enumerate(AFF)}
for st,col in AFFCOL.items():
    w.set_cell('Affinity',1,col,st,style=w.sty('Affinity','V1'))
    for i,v in enumerate(AFF[st]): w.set_cell('Affinity',i+2,col,v,style=w.sty('Affinity',f'V{i+2}'))
    w.set_cell('Affinity',9,col,NEW[st][1][1],style=w.sty('Affinity','V9'))
    w.set_cell('Affinity',10,col,round(sum(AFF[st])/6,4),formula=f'AVERAGE({col}2:{col}7)',style=w.sty('Affinity','V10'))

LASTCOL='AD'
def stage_cols(n): return [n2col(i+1) for i in range(n)]
CL=stage_cols(46)
r0=w.last_data_row('Stages')
for k,(st,(base,ov)) in enumerate(NEW.items()):
    r=r0+1+k
    v=list(BYID[base]); v[0]=st
    for key,val in ov.items():
        if key=='seg':
            for j,x in enumerate(val): v[16+j]=x
        else: v[key]=val
    v[43]='Yes'
    thr,bm=v[8],v[7]
    for i,val in enumerate(v):
        col=CL[i]
        if i==9:
            w.set_cell('Stages',r,col,round(thr/bm,4),formula=f'IF(AND(ISNUMBER(H{r}),ISNUMBER(I{r})),IF(H{r}=0,"",I{r}/H{r}),"varies")',style_from=r-1)
        elif i==22:
            w.set_cell('Stages',r,col,round(sum(v[16:22]),4),formula=f'SUM(Q{r}:V{r})',style_from=r-1)
        elif i==23:
            fav=SUITS[max(range(6),key=lambda j:(AFF[st][j],-j))]
            w.set_cell('Stages',r,col,fav,formula=f'IF(E{r}<>"Combat","—",IFERROR(INDEX(Affinity!$A$2:$A$7,MATCH(MAX(INDEX(Affinity!$B$2:$AD$7,0,MATCH(A{r},Affinity!$B$1:$AD$1,0))),INDEX(Affinity!$B$2:$AD$7,0,MATCH(A{r},Affinity!$B$1:$AD$1,0)),0)),"—"))',style_from=r-1)
        elif val is not None:
            w.set_cell('Stages',r,col,val if not isinstance(val,str) or not val.isdigit() else val,style_from=r-1)
# Show Transition on for existing Combat rooms (column AR)
for sid in ['ST01','ST02','ST03','ST04','ST05','ST06','ST08']+[f'ST{n:02d}' for n in range(9,22)]:
    w.set_cell('Stages',w.find_row('Stages',sid),'AR','Yes')

# ---------------- Levels
L=orows('Levels'); lv14=[r for r in L if r[0]=='LV14'][0]
LC=[n2col(i+1) for i in range(40)]
def level(lid,desc,bo,slots):
    v=list(lv14); v[0]=lid; v[1]=desc
    for j in range(10): v[8+j]=slots[j] if j<len(slots) else 'N/A'
    for j in range(16): v[23+j]='0'
    for b,rng in bo.items(): v[23+int(b[2:])-1]=rng
    return v
LV=[level('LV61','Rail Fares and Timetables',{'BO14':'1-2'},['ST07','ST24','ST25','ST26','ST27']),
    level('LV62','Fishing Quotas and Harbours',{'BO07':'1-2'},['ST07','ST28','ST29','ST30','ST31'])]
for v in LV:
    w.append_row('Levels',{LC[i]:x for i,x in enumerate(v) if x is not None})

# ---------------- Stage Questions / Themes
for i,st,q,th,g in Q:
    d={'A':i,'B':st,'C':q,'D':th}
    for c,ch in zip('EFGHIJ',g): d[c]=ch
    w.append_row('Stage Questions',d)
for th,org,why,ann in THEMES:
    d={'A':th,'B':org,'C':f'{NOTE}: {why}'}
    w.append_row('Question Themes',d)

# ---------------- Cues
STG={'A':'ST24; ST25; ST26; ST27','B':'ST28; ST29; ST30; ST31'}
n=18
for (lv,suit,verb),rows in PC.items():
    for row in rows:
        n+=1; d={'A':f'PL{n:02d}','B':suit,'C':verb,'D':STG[lv]}
        for c,l in zip('EFGHI',row): d[c]=l
        w.append_row('Player Cues',d)
n=36
for (lv,suit,verb),rows in OC.items():
    for row in rows:
        n+=1; d={'A':f'OC{n:02d}','B':suit,'C':verb,'J':STG[lv]}
        for c,l in zip('EFGHI',row): d[c]=l
        w.append_row('Opponent Cues',d)

# ---------------- Depth additions (three-times rule)
from content2 import *
nq=69
for theme,q,g in GENERAL_COMMITTEE_Q:
    nq+=1
    d={'A':f'S{nq}','B':'; '.join(COMMITTEES),'C':q,'D':theme}
    for c,ch in zip('EFGHIJ',g): d[c]=ch
    w.append_row('Stage Questions',d)
for theme,q,g in PRESS_EXTRA:
    nq+=1
    d={'A':f'S{nq}','B':'ST26','C':q,'D':theme}
    for c,ch in zip('EFGHIJ',g): d[c]=ch
    w.append_row('Stage Questions',d)
for qid,q,theme,g in AMBUSH_EXTRA:
    d={'A':qid,'B':q,'C':theme}
    for c,ch in zip('DEFGHI',g): d[c]=ch
    w.append_row('Media Ambush Questions',d)
# committee Player Cue rows PL01-PL18 gain the two new hearing rooms
for r in range(2,20):
    cur=w.rows('Player Cues')[r]['D']
    if 'ST27' not in cur: w.set_cell('Player Cues',r,'D',cur+'; ST27; ST31')
n=18+len(PC)*2
cm='; '.join(COMMITTEES)
for suit,verb,lines in COMMITTEE3:
    n+=1; d={'A':f'PL{n:02d}','B':suit,'C':verb,'D':cm}
    for c,l in zip('EFGHI',lines): d[c]=l
    w.append_row('Player Cues',d)
for suit,verb,lines in COMMITTEE4:
    n+=1; d={'A':f'PL{n:02d}','B':suit,'C':verb,'D':cm}
    for c,l in zip('EFGHI',lines): d[c]=l
    w.append_row('Player Cues',d)
for suit,verb,lines in TV:
    n+=1; d={'A':f'PL{n:02d}','B':suit,'C':verb,'D':'ST06'}
    for c,l in zip('EFGHI',lines): d[c]=l
    w.append_row('Player Cues',d)
for fam,stg in ((TOWN,'ST05; ST24; ST29'),(CAUCUS,'ST03')):
    for suit,verb,rows_ in fam:
        for row in rows_:
            n+=1; d={'A':f'PL{n:02d}','B':suit,'C':verb,'D':stg}
            for c,l in zip('EFGHI',row): d[c]=l
            w.append_row('Player Cues',d)

# ---------------- Transitions
for k,c in enumerate(['SF01','SF02','SF08','SF09','SF15','SF16'],1):
    w.append_row('Transition Cast',{'A':f'TC{k:02d}','C':c})
BG=[('', 'OFFICE'),('ST24','ST05'),('ST25','ST21'),('ST26','ST04'),('ST27','ST15'),('ST28','ST20'),('ST29','ST05'),('ST30','ST19'),('ST31','ST13')]
for k,(st,bg) in enumerate(BG,1):
    d={'A':f'TB{k:02d}','C':bg}
    if st: d['B']=st
    w.append_row('Transition Backgrounds',d)
for k,(c,st,l,r) in enumerate(TD,1):
    d={'A':f'TD{k:02d}','B':c,'D':l,'E':r}
    if st: d['C']=st
    w.append_row('Transition Dialogue',d)

# ---------------- Opponents seating
SEAT={'ST24':[f'OP{n}' for n in range(102,110)],'ST29':[f'OP{n}' for n in range(102,110)],
 'ST25':['OP62','OP68','OP19','OP36','OP13','OP77','OP101'],'ST27':['OP19','OP68','OP13','OP36','OP62','OP77','OP101'],
 'ST26':[f'OP{n}' for n in range(110,118)],'ST30':[f'OP{n}' for n in range(110,118)],
 'ST28':['OP121','OP122','OP118','OP120'],'ST31':['OP25','OP70','OP74','OP79','OP84','OP94','OP98','OP06','OP43','OP29','OP46']}
orows_=w.rows('Opponents')
byop={v['A']:k for k,v in orows_.items() if 'A' in v}
cur={op:orows_[byop[op]].get('I','') for op in byop}
add={}
for st,ops in SEAT.items():
    for op in ops: add.setdefault(op,[]).append(st)
for op,sts in add.items():
    base=cur[op]; val='; '.join([base]+sts) if base and base!='N/A' else '; '.join(sts)
    w.set_cell('Opponents',byop[op],'I',val)

# ---------------- Assets (background art rows)
A=orows('Assets'); st05=[r for r in A if r[0]=='ST05'][0]
for st,(base,ov) in NEW.items():
    v=list(st05); v[0]=st; v[2]=ov[1]; v[4]=f'{st}.png'; v[9]='No'; v[10]=f'{NOTE}: new topic room, background not drawn yet.'
    w.append_row('Assets',{n2col(i+1):x for i,x in enumerate(v) if x is not None})

w.save()
print('built',OUT)
