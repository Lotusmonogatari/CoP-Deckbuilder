"""Static balance numbers from the real data files (no simulation):
 1. card power per energy, by tier, and what a turn's energy can do
 2. how fast a stage's threshold must be reached (points per turn) vs the
    best a typical hand can deliver
 3. stage rewards vs prices (XP and Funds) and a shop-spend table
 4. XP income per hour of play vs card/XP prices
Reads data/*.json only. Prints markdown tables."""
import json, statistics as st, collections
cards=json.load(open('data/cards.json')); stages=json.load(open('data/stages.json'))
shop=json.load(open('data/shop.json')); bal={r['key'] if 'key' in r else r.get('id'):r for r in json.load(open('data/balance.json'))} if isinstance(json.load(open('data/balance.json')),list) else json.load(open('data/balance.json'))
print("## 1. Card power per energy (self_plus + opp_minus) by tier")
bt=collections.defaultdict(list)
for c in cards:
    if c['cost'] and c['cost']>0:
        bt[c['tier']].append(((c['self_plus'] or 0)+(c['opp_minus'] or 0))/c['cost'])
print("tier | cards | mean pts/energy | min | max")
for t,v in sorted(bt.items()): print(f"{t} | {len(v)} | {st.mean(v):.2f} | {min(v):.2f} | {max(v):.2f}")
allv=[x for v in bt.values() for x in v]
print(f"\nAll cards: median {st.median(allv):.2f} pts per energy")
combat=[s for s in stages if s['mode']=='Combat' and s.get('win_threshold') and s.get('turn_limit') and s.get('energy_per_turn')]
print("\n## 2. Required pace vs available energy (Combat stages with a numeric threshold)")
rows=[]
for s in combat:
    need=(s['win_threshold']-(s['player_start'] or 0))
    cap=s['turn_limit']*s['energy_per_turn']*st.median(allv)
    rows.append((need/cap, s['stage_id'], s['name_en'], need, s['turn_limit'], s['energy_per_turn'], cap))
rows.sort(reverse=True)
print("Ratio = points still needed / (turns x energy x median pts per energy). Above 1 means the median card cannot get there with every energy spent on points.")
print("ratio | stage | name | need | turns | energy | median-card capacity")
for r in rows[:12]: print(f"{r[0]:.2f} | {r[1]} | {r[2]} | {r[3]} | {r[4]} | {r[5]} | {r[6]:.0f}")
rs=[r[0] for r in rows]
print(f"\nCombat stages: {len(rs)}; ratio median {st.median(rs):.2f}; share above 1.0: {100*sum(1 for x in rs if x>1)/len(rs):.0f}%; share above 0.5: {100*sum(1 for x in rs if x>0.5)/len(rs):.0f}%")
print("\n## 3. Stage rewards (Combat)")
for k in ('win_delta_yen','win_delta_xp','loss_delta_yen','loss_delta_xp'):
    v=[s[k] or 0 for s in combat]; print(f"{k}: median {st.median(v)} | max {max(v)} | min {min(v)}")
lossrich=[s for s in combat if (s['loss_delta_xp'] or 0)>0 or (s['loss_delta_yen'] or 0)>0]
print(f"Combat stages that pay XP or Funds on a LOSS: {len(lossrich)} of {len(combat)}")
print("\n## 4. Shop prices (items with a cost)")
print("item | name | XP | Funds")
for it in sorted(shop,key=lambda i:(i['cost_xp'] or 0, i['cost_yen'] or 0)):
    if (it['cost_xp'] or 0) or (it['cost_yen'] or 0): print(f"{it['item_id']} | {it['name']} | {it['cost_xp'] or 0} | {it['cost_yen'] or 0}")
tot_xp=sum(i['cost_xp'] or 0 for i in shop); tot_y=sum(i['cost_yen'] or 0 for i in shop)
print(f"\nSum of every shop price once: {tot_xp} XP and {tot_y} Funds.")
print(f"Card unlock XP total: {sum(c['xp_to_unlock'] or 0 for c in cards)} XP for {len(cards)} cards.")
