import sys,shutil
sys.path.insert(0,'/tmp/claude-0/b1'); sys.path.insert(0,'/tmp/claude-0/b2')
from wbx import WB
from model import *; from bills import BILLS; from bills2 import L,FLIP,LAW
MASTER='/home/user/CoP-Deckbuilder/design/Game_Workbook.xlsx'
OUT='/tmp/claude-0/b2/draft2.xlsx'
shutil.copy(MASTER,OUT); w=WB(OUT)
DELTA={1:(1,-1),3:(3,-2),5:(5,-5)}
CODE={'Supportive':'S','Opposed':'O','Neutral':'N'}
pids=list(PID)
n=int(max(v['A'] for v in w.rows('Law Effects').values() if v.get('A','').startswith('LW'))[2:])
for bid,name,desc,tags,tier in BILLS:
    sup,opp=DELTA[tier]
    w.append_row('Floor Vote Bills',{'A':bid,'B':name,'C':desc,'D':sup,'E':opp,'F':0})
    out,tot=tally(tags)
    for i,pid in enumerate(pids):
        disp,v,s=out[pid]
        code,line=L[bid][i]
        assert CODE[disp]==code,(bid,pid,disp,code,s)
        assert sum(v)==SEATS[pid]
        assert len(line.split())<=9,(bid,line)
        w.append_row('Floor Vote Party Positions',{'A':bid,'B':pid,'C':v[0],'D':v[1],'E':v[2],'F':disp,'G':line,'H':PID[pid]})
    default_pass=tot[0]>=51
    direction,cue=FLIP[bid]
    assert (direction=='Flipped to Fail')==default_pass,(bid,tot,direction)
    w.append_row('Vote Influence Cues',{'A':bid,'B':direction,'C':cue})
    win,lose,why=LAW[bid]
    eff='; '.join([f'{win[0]} +3']+[f'{b} +2' for b in win[1:]]+[f'{b} -2' for b in lose])
    n+=1; w.append_row('Law Effects',{'A':f'LW{n}','B':bid,'C':'Passed','D':'Once','E':eff,'K':f'Draft 2026-10-13: {why}.'})
    eff='; '.join([f'{b} -1' for b in win]+[f'{b} +1' for b in lose])
    n+=1; w.append_row('Law Effects',{'A':f'LW{n}','B':bid,'C':'Failed','D':'Once','E':eff,'K':'Draft 2026-10-13: supporters disappointed, opponents relieved.'})
w.save(); print('built',OUT)
