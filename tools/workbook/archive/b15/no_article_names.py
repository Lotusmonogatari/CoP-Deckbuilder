"""No "the" before Members of Parliament, Neighborhood Associations and Constituency Voters,
with plural verbs for Neighborhood Associations (Cameron, 2026-11-09). Applied once; archived."""
import sys,re; sys.path.insert(0,"tools/workbook")
from wbx import WB
NAMES="Members of Parliament|Neighborhood Associations|Constituency Voters"
def fix(t):
    o=t
    t=re.sub(r"\bDoes the Neighborhood Associations\b","Do Neighborhood Associations",t)
    t=re.sub(r"(^|[.!?]\s+|\"|: )The ("+NAMES+r")\b",lambda m:m.group(1)+m.group(2),t)
    t=re.sub(r"\b[Tt]he ("+NAMES+r")\b",r"\1",t)
    if "Neighborhood Associations" in t and t!=o:
        verbs={"is":"are","has":"have","was":"were","doesn't":"don't","does":"do","wants":"want","knows":"know","needs":"need","says":"say","asks":"ask","fears":"fear","speaks":"speak","expects":"expect","deserves":"deserve","backs":"back","opposes":"oppose","supports":"support","warns":"warn","worries":"worry","hopes":"hope","remembers":"remember","sees":"see","thinks":"think","believes":"believe","cares":"care","stands":"stand","holds":"hold","gets":"get","loses":"lose","gains":"gain","pays":"pay","keeps":"keep","calls":"call","will":"will"}
        t=re.sub(r"\bNeighborhood Associations (\w+'?\w*)\b",lambda m:"Neighborhood Associations "+verbs.get(m.group(1),m.group(1)),t)
        t=re.sub(r"\bwhen it asks\b","when they ask",t)
        t=t.replace("Answer it straight","Answer them straight")
        t=re.sub(r"\bwhen it (\w+)s\b",lambda m:"when they "+m.group(1),t)
    return t
if __name__=="__main__":
    w=WB("design/Game_Workbook.xlsx"); n=0; show="--show" in sys.argv
    for tab in w.sheet:
        try: rows=w.rows(tab)
        except Exception: continue
        for r,v in rows.items():
            if r==1: continue
            for col,t in v.items():
                if isinstance(t,str):
                    nt=fix(t)
                    if nt!=t:
                        n+=1
                        if show and "Neighborhood" in t: print(t,"\n  ->",nt)
                        if not show: w.set_cell(tab,r,col,nt)
    if not show: w.save()
    print("changed",n)
