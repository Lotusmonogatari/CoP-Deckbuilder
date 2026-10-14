import sys; sys.path.insert(0,'.')
from load import *
import collections
M=openpyxl.load_workbook('/home/user/CoP-Deckbuilder/design/CoP_Starter_Card_Stage_Data.xlsx',read_only=True)
def mt(n):
    rs=[r for r in M[n].iter_rows(values_only=True) if any(c is not None for c in r)]
    h=list(rs[0]); return h,[{k:v for k,v in zip(h,r) if k} for r in rs[1:]]
# ---- masters
_,m_stages=mt('Stages'); _,m_opp=mt('Opponents'); _,m_levels=mt('Levels'); _,m_bills=mt('Floor Vote Bills'); _,m_pos=mt('Floor Vote Party Positions')
_,m_themes=mt('Question Themes'); _,m_staff=mt('Staff'); _,m_vis=mt('Visitors'); _,m_vq=mt('Visitor Questions'); _,m_boost=mt('Boosters'); _,m_parties=mt('Parties')
_,m_pl=mt('Player Cues'); _,m_oc=mt('Opponent Cues'); _,m_sq=mt('Stage Questions'); _,m_law=mt('Law Effects'); _,m_vic=mt('Vote Influence Cues'); _,m_lit=mt('Level Intro Thoughts')
print('master counts: stages',len(m_stages),'opp',len(m_opp),'levels',len(m_levels),'bills',len(m_bills),'themes',len(m_themes),'PL',len(m_pl),'OC',len(m_oc),'SQ',len(m_sq),'LW',len(m_law),'VQ',len(m_vq))
# ---- proposed
P={}
for n in ['Stages','Affinity','Assets','Player Cues','Opponent Cues','Stage Questions','Question Themes','Visitor Questions','Floor Vote Bills','Floor Vote Party Positions','Vote Influence Cues','Law Effects','Level Intro Thoughts','Levels','Transition Cast','Transition Backgrounds','Transition Dialogue']:
    P[n]=table(n)
for n,(h,r) in P.items(): print(n,len(r))
# ---- 1. header compatibility
for n,mn in [('Stages','Stages'),('Player Cues','Player Cues'),('Opponent Cues','Opponent Cues'),('Stage Questions','Stage Questions'),('Question Themes','Question Themes'),('Visitor Questions','Visitor Questions'),('Floor Vote Bills','Floor Vote Bills'),('Floor Vote Party Positions','Floor Vote Party Positions'),('Vote Influence Cues','Vote Influence Cues'),('Law Effects','Law Effects'),('Levels','Levels'),('Level Intro Thoughts','Level Intro Thoughts')]:
    mh,_=mt(mn); ph=P[n][0]
    mh=[x for x in mh if x]; ph=[x for x in ph if x]
    extra=[x for x in ph if x not in mh]; miss=[x for x in mh if x not in ph]
    order_same = [x for x in ph if x in mh]==[x for x in mh if x in ph]
    print(f'HEADER {n}: extra={extra} missing={miss} orderSame={order_same}')
# ---- 2. ID collisions
def ids(rows,key): return [str(r.get(key)) for r in rows]
for n,key,mrows in [('Stages','Stage ID',m_stages),('Player Cues','Cue ID',m_pl),('Opponent Cues','Cue ID',m_oc),('Stage Questions','Q ID',m_sq),('Floor Vote Bills','Bill ID',m_bills),('Law Effects','Law ID',m_law),('Visitor Questions','Question ID',m_vq),('Levels','Level ID',m_levels)]:
    pid=ids(P[n][1],key); mid=set(ids(mrows,key))
    dup=[k for k,c in collections.Counter(pid).items() if c>1]
    coll=[k for k in pid if k in mid]
    print(f'IDS {n}: proposed {len(pid)} range {pid[0]}..{pid[-1]} dup={dup[:5]} collide_master={coll[:5]}({len(coll)})')
