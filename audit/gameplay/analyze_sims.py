"""Summarises the strategy-playtest runs (audit/gameplay/sim/*.jsonl) into the
tables used in 04-balance.md. Read-only: reads JSONL, prints tables."""
import json, collections, statistics as st, sys
def load(f): return [json.loads(l) for l in open(f)]
A = load('audit/gameplay/sim/strategy_runs.jsonl')
B = load('audit/gameplay/sim/strategy_cap.jsonl')
def med(x): return round(st.median(x),1) if x else 0
def show(rows, title):
    print(f"\n## {title}  (n={len(rows)})")
    g = collections.defaultdict(list)
    for r in rows: g[r['strategy']].append(r)
    print("strategy | n | weeks | stages | wins | losses | win% | levels_cleared | xp_total | funds_end | cap | dues_owed | weeks_overdue | con | rep | party")
    for s, rs in sorted(g.items()):
        w=sum(r['wins'] for r in rs); l=sum(r['losses'] for r in rs)
        print(f"{s} | {len(rs)} | {med([r['weeks'] for r in rs])} | {med([r['stages'] for r in rs])} | {med([r['wins'] for r in rs])} | {med([r['losses'] for r in rs])} | {100*w/max(1,w+l):.0f} | {med([r['levels_cleared'] if isinstance(r['levels_cleared'],(int,float)) else len(r['levels_cleared']) for r in rs])} | {med([r['xp_total'] for r in rs])} | {med([r['funds'] for r in rs])} | {med([r['funds_cap'] for r in rs])} | {med([r['dues_owed'] for r in rs])} | {med([r['weeks_overdue'] for r in rs])} | {med([r['con'] for r in rs])} | {med([r['rep'] for r in rs])} | {med([r['party'] for r in rs])}")
show(A,'Batch 1'); show(B,'Batch 2 (cap_dues vs baseline)')
# difficulty by stage type
print("\n## Win rate by stage type (all runs)")
t=collections.defaultdict(lambda:[0,0])
for r in A+B:
    for k,v in r['stage_type_results'].items():
        t[k][0]+=v.get('wins',0); t[k][1]+=v.get('losses',0)
for k,(w,l) in sorted(t.items()): print(f"{k} | wins {w} | losses {l} | win% {100*w/max(1,w+l):.0f}")
# stages with losses
print("\n## Stages with the most losses (all runs)")
sl=collections.defaultdict(lambda:[0,0])
for r in A+B:
    for k,v in r['level_attempts'].items() if isinstance(r['level_attempts'],dict) else []:
        pass

# ---- extra tables -------------------------------------------------------
import json as _j
stages={s['stage_id']:s for s in _j.load(open('data/stages.json'))} if isinstance(_j.load(open('data/stages.json')),list) else {}
print("\n## Hardest stage types (>=15 attempts, win% < 85), with room type")
for k,(w,l) in sorted(t.items(), key=lambda kv: kv[1][0]/max(1,sum(kv[1]))):
    if w+l>=15 and w/(w+l)<0.85:
        s=stages.get(k,{})
        print(f"{k} | {s.get('stage_type') or s.get('type') or s.get('room_type')} | attempts {w+l} | win% {100*w/(w+l):.0f}")
print("\n## Economy timeline, baseline vs cap_dues (median over runs, every 5th week)")
for name,rows in (('baseline',[r for r in A+B if r['strategy']=='baseline']),('cap_dues',[r for r in B if r['strategy']=='cap_dues'])):
    print(name)
    for wk in range(0,31,5):
        pts=[next((p for p in r['series'] if p['week']==wk),None) for r in rows]
        pts=[p for p in pts if p]
        if pts: print(f"  wk{wk}: funds {med([p['funds'] for p in pts])} | earned {med([p['week_earned'] for p in pts])} | dues {med([p['week_dues'] for p in pts])} | owed {med([p['dues_owed'] for p in pts])} | party {med([p['party'] for p in pts])} | xp_total {med([p['xp_total'] for p in pts])}")
print("\n## Levels cleared by tier (median per run)")
for tier in ('0','1','2','3','4','5'):
    v=[r['levels_by_tier'].get(tier,0) for r in A+B]
    print(f"tier {tier}: median {med(v)} max {max(v)}")
print("\n## Run totals: stalls, bugs, promises broken unseen")
print("stalls", sum(r['stalls'] for r in A+B), "| bugs", sum(len(r['bugs']) if isinstance(r['bugs'],list) else r['bugs'] for r in A+B))

print("\n## Pace per strategy (median): XP per week, Funds earned per week, weeks to Party >= 90, weeks to Constituency >= 70")
def first_week(rows,key,thr):
    out=[]
    for r in rows:
        w=next((p['week'] for p in r['series'] if p[key]>=thr),None)
        out.append(w if w is not None else 99)
    return med(out)
g=collections.defaultdict(list)
for r in A+B: g[r['strategy']].append(r)
print("strategy | XP/week | funds earned/week (wk 5-30) | wk to party>=90 | wk to con>=70 | wk to xp_total>=10000 | stage losses per 100 stages")
for s,rs in sorted(g.items()):
    xpw=med([r['xp_total']/max(1,r['weeks']) for r in rs])
    fe=med([st.mean([p['week_earned'] for p in r['series'] if p['week']>=5]) for r in rs])
    lp=med([100*r['losses']/max(1,r['stages']) for r in rs])
    print(f"{s} | {xpw} | {fe} | {first_week(rs,'party',90)} | {first_week(rs,'con',70)} | {first_week(rs,'xp_total',10000)} | {lp}")
print("\n## Per-level yield from the sims (all runs): per hour of play, by tier and by repeat")
rows=[]
for r in A+B:
    seen=collections.Counter()
    for l in r['levels']:
        seen[l['level']]+=1
        rows.append((l['tier'],l['hours'],l['funds'],l['xp'],l['con'],seen[l['level']],l['level'],r['strategy']))
print("tier | levels played | median hours | funds/hour (median) | xp/hour (median)")
for tier in (0,1,2):
    rr=[x for x in rows if x[0]==tier and x[1]>0]
    print(f"{tier} | {len(rr)} | {med([x[1] for x in rr])} | {med([x[2]/x[1] for x in rr])} | {med([x[3]/x[1] for x in rr])}")
rep=[x for x in rows if x[5]>=10 and x[1]>0]
print(f"\nLevel plays that were the 10th or later play of the same level in one run: {len(rep)} of {len(rows)}")
if rep:
    print("funds/hour on 10th+ plays (median):", med([x[2]/x[1] for x in rep]), "| xp/hour:", med([x[3]/x[1] for x in rep]))
top=collections.Counter(x[6] for x in rows).most_common(5); print("Most played level ids (all runs):", top)
print("\n## Share of runs ending with Funds at 0 and dues owed > 1,000,000")
print(sum(1 for r in A+B if r['funds']==0), "of", len(A+B), "| owed>1M:", sum(1 for r in A+B if r['dues_owed']>1_000_000))
