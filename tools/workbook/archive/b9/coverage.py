"""Option A coverage check (2026-10-19): can every patron bill arise, and can the
player amend every variation, whatever order requests are accepted in?

Simulates the rules in ComposedBill.substitute_enacted() and
PatronRequests.amend_options() on a components table and a patron-bill table,
over many random interleavings (each request randomly amended or not, with a
random alternative). Reports the first failure of each kind.
"""
import random

def substitute(ids, comps, enacted):
    out = list(ids); ok = True
    for i, cid in enumerate(out):
        if cid not in enacted: continue
        owner = comps[cid]["owner"]; swap = None
        for slot in comps_slot_order(comps, owner):
            for c, d in sorted(comps.items()):
                if d["owner"] == owner and d["slot"] == slot and c not in enacted and c not in out:
                    swap = c; break
            if swap: break
        if swap: out[i] = swap
        else: ok = False
    return out, ok

def comps_slot_order(comps, owner):
    return ["X", "Y", "Z", "W", "V", "A", "B", "C", "D"]

def amend_options(bill, comps, enacted):
    ids = bill["components"]; out = []
    if bill["kind"] == "Flagship":
        pool = [ids[-1]]; src = comps[ids[-1]]["owner"]
    else:
        pool = list(ids); src = comps[ids[0]]["owner"]
    for rep in pool:
        for c in sorted(comps):
            if comps[c]["owner"] == src and c not in ids and c not in enacted and comps[c]["slot"] in alts(bill, comps, rep):
                out.append((rep, c))
    return out

def alts(bill, comps, rep):
    return {"Favor": {"X", "Y", "V"}, "Flagship": {"A", "B", "C", "D"}}[bill["kind"]] if True else set()

def run(comps, bills, trials=3000, seed=1):
    rnd = random.Random(seed); fails = {}
    byorg = {}
    for b in bills: byorg.setdefault(b["org"], {})[b["kind"]] = b
    for t in range(trials):
        enacted = set(); done = set(); order = []
        pending = list(bills)
        while pending:
            avail = [b for b in pending if b["kind"] == "Favor" or (b["org"], "Favor") in done]
            b = rnd.choice(avail); pending.remove(b)
            ids, ok = substitute(b["components"], comps, enacted)
            if not ok:
                fails.setdefault(("no-substitute", b["id"]), order[:]); break
            live = dict(b, components=ids)
            opts = amend_options(live, comps, enacted)
            need = ids if b["kind"] == "Favor" else [ids[-1]]
            for rep in need:
                if not [o for o in opts if o[0] == rep]:
                    fails.setdefault(("no-amend", b["id"], rep), order[:])
            if opts and rnd.random() < 0.5:
                rep, w = rnd.choice(opts); ids = [w if x == rep else x for x in ids]
            enacted.update(ids); done.add((b["org"], b["kind"])); order.append(b["id"])
    return fails
