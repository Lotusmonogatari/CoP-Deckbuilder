import csv, math
rows=list(csv.reader(open('/home/user/CoP-Deckbuilder/design/reference/party_values.tsv'),delimiter='\t'))
H=rows[0]; DIMS=H[2:36]
SAL={}
for r in rows[1:]:
    SAL[r[0]]=dict(zip(DIMS,map(int,r[2+68:2+102])))
PID={'PT01':'Butsutou','PT02':'Yezo Heritage Party','PT03':'Frontier Party','PT04':'Five Point Independents','PT05':'Keizaijiyuutou','PT06':'Country Initiative'}
SEATS={'PT01':19,'PT02':14,'PT03':27,'PT04':5,'PT05':25,'PT06':11}
T=30.0   # score needed to take a side at all
def score(tags,pid):
    return sum(w*SAL[PID[pid]][d] for d,w in tags.items())
def split(tags,pid):
    s=score(tags,pid); n=SEATS[pid]
    a=abs(s)
    if a>=T:
        strength=min(1.0,(a-T)/(3*T))
        yes_share=0.66+0.30*strength
        if s>0: y=yes_share; nn=1-y; ab=0.0; disp='Supportive'
        else: y=1-yes_share; nn=yes_share; ab=0.0; disp='Opposed'
        # a little abstention in the weaker cases
        if strength<0.25:
            ab=0.10*(1-strength/0.25); 
            if s>0: y-=ab/2; nn-=ab/2
            else: y-=ab/2; nn-=ab/2
    else:
        t=s/T
        y=0.31+0.22*t; nn=0.31-0.22*t; ab=1-y-nn; disp='Neutral'
    raw=[y*n,nn*n,ab*n]
    ints=[int(math.floor(x)) for x in raw]
    rem=n-sum(ints)
    order=sorted(range(3),key=lambda i:-(raw[i]-ints[i]))
    for i in order[:rem]: ints[i]+=1
    return disp,ints,s
def tally(tags):
    out={}; tot=[0,0,0]
    for pid in PID:
        d,v,s=split(tags,pid); out[pid]=(d,v,round(s)); 
        for i in range(3): tot[i]+=v[i]
    return out,tot
