"""Item 2: every event with its class, a proposed location and the place type its text assumes; plus the choices
that make a promise (events and visitor questions).

Classes (the spec): Scenario = Random or Follow-up; Arranged = Buyable or a hosted event; Decision! = Dated.
Location comes from the words the text uses (textscan.office_cues) with a few hand-set rows (buyables, the Dated
event) whose reason says so. A follow-up takes the location of the choice that schedules it.
"""
import collections
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import *
from textscan import *

BUYABLE = {
    "EV03": ("Either", "medium", "a regional paper's half page: print reaches both offices"),
    "EV04": ("Capitol", "high", "the National Television Spot is Capitol (the spec's own example)"),
    "EV05": ("District", "medium", "the local associations' projects: a District grant"),
    "EV06": ("District", "medium", "a booked hall and a few hundred chairs: a rally at home, at the weekend"),
    "EV31": ("District", "medium", "a local radio spot"),
    "EV32": ("District", "medium", "a local sports team"),
    "EV33": ("Either", "medium", "a podcast can be recorded from either office"),
    "EV34": ("District", "high", "the Constituency Office Open Day is District (the spec's own example)"),
    "EV35": ("District", "medium", "a festival float: a District festival"),
}


def main():
    events = load("events")
    choices = collections.defaultdict(list)
    for c in load("event_choices"):
        choices[c["event_id"]].append(c)
    vqs = load("visitor_questions")
    # Which choice schedules each follow-up.
    origin = {}
    for c in load("event_choices"):
        for e in c.get("commitment") or []:
            if e.get("kind") == "followup":
                origin[e["event_id"]] = ("event_choices", "%s.%s" % (c["event_id"], c["choice"]), c["event_id"], e.get("after"))
    for q in vqs:
        for L in "abcd":
            for e in q.get(f"commitment_{L}") or []:
                if isinstance(e, dict) and e.get("kind") == "followup":
                    origin[e["event_id"]] = ("visitor_questions", "%s.%s" % (q["question_id"], L), q["question_id"], e.get("after"))
    rows = []
    located = {}
    scored = {}
    for e in events:
        eid = e["event_id"]
        text = " ".join([e["title"], e.get("flavor") or ""] + [(c.get("choice_text") or "") + " " + (c.get("result_text") or "") + " " + (c.get("promise_kept_text") or "") for c in choices[eid]])
        cap, dis = office_cues(text)
        office, conf = propose_office(cap, dis)
        reason = "cue words: Capitol %s; District %s" % (cap[:6] or "none", dis[:6] or "none")
        trig = e["trigger"]
        klass = {"Random": "Scenario: Random", "Followup": "Scenario: Follow-up", "Buyable": "Arranged: Buyable", "Dated": "Decision!: Dated"}.get(trig, trig)
        if trig == "Buyable":
            office, conf, why = BUYABLE[eid]
            reason = why + " (hand-set; the words alone: " + reason + ")"
        elif trig == "Dated":
            office, conf = "Capitol", "high"
            reason = "the Prime Minister's Opening Address: a national, scripted session event (the spec: first Decision! event)"
        scored[eid] = (office, conf, reason)
        generic = generic_places(text)
        # Drop weak generic hits (words like 'student', 'shop') unless the type has two hits or the title carries it.
        needs = [k for k, v in sorted(generic.items(), key=lambda kv: -len(kv[1])) if len(v) >= 2 or any(re.search(p, e["title"], re.I) for p in GENERIC[k])][:3]
        real = real_places(text)
        located[eid] = (office, conf)
        rows.append([eid, e["title"], klass, trig, e["available"], e["hours"], ", ".join(e.get("seasons") or []) or "", e.get("image") or "",
                     office, conf, "; ".join(needs), "; ".join("%s (%s)" % (n, t) for n, t, _ in real), "", reason,
                     "; ".join(sorted(generic)[:8]), "; ".join(sorted(uncataloged_places(text))[:6])])
    # Follow-ups: take the origin's location.
    for row in rows:
        eid = row[0]
        if row[3] == "Followup" and eid in origin:
            table, key, src, after = origin[eid]
            src_office = located.get(src, (None,))[0]
            if table == "visitor_questions":
                # A visitor's question is asked in Office Hours; the visitor is a constituent: leaning District unless the text says otherwise.
                src_office = "District" if row[8] != "Capitol" else row[8]
            row[12] = "%s %s (+%sh)" % (table, key, after)
            if src_office and src_office != row[8]:
                row[13] += "; scheduled by %s which is %s: the follow-up waits for that office (spec)" % (key, src_office)
                row[8] = src_office
            else:
                row[13] += "; scheduled by %s (+%sh): fires at its own location (spec)" % (key, after)
    # Hosted events (Marketplace items that open a scene).
    for h in load("hosted_events"):
        text = " ".join(str(h.get(f) or "") for f in ("title", "intro", "prompt_1", "prompt_2", "prompt_3"))
        cap, dis = office_cues(text)
        office, conf = ("District", "high") if "Walking Tour" in h["title"] else ("Either", "medium")
        why = "a walk through part of the district (District)" if office == "District" else "a dinner with guests: an Either scene at a restaurant"
        rows.append([h["hosted_id"], h["title"], "Arranged: hosted (item %s)" % h["item_id"], "Hosted", "", "", "", h.get("image") or "", office, conf,
                     "; ".join(list(generic_places(text))[:3]), "; ".join("%s (%s)" % (n, t) for n, t, _ in real_places(text)), "", why,
                     "; ".join(sorted(generic_places(text))[:8]), ""])
    write_csv("events_location.csv", ["event_id", "title", "class", "trigger", "available", "hours", "seasons", "image", "proposed_location",
                                      "confidence", "needs_place (from the 24 archetypes)", "real_places_named", "scheduled_by (follow-ups)", "reason",
                                      "all_place_types_hit", "uncataloged_place_words"], rows)
    summary = collections.Counter((r[2].split(":")[0], r[8]) for r in rows)
    print(dict(summary))

    # Promises.
    prow = []
    for c in load("event_choices"):
        kinds = [e for e in (c.get("commitment") or []) if str(e.get("kind", "")).startswith("promise")]
        if not kinds and not c.get("promise_kept"):
            continue
        text = " ".join([c.get("choice_text") or "", c.get("promise_kept_text") or ""])
        cap, dis = office_cues(text)
        office, conf = propose_office(cap, dis)
        kept = c.get("promise_kept_text") or ""
        gp = generic_places(kept or text)
        reason = "kept-text cues: Capitol %s; District %s" % (cap[:4] or "none", dis[:4] or "none")
        prow.append(["event_choices", "%s.%s" % (c["event_id"], c["choice"]), ", ".join("%s %s%s" % (e.get("kind"), e.get("amount") or e.get("item_id") or "", " within %sh" % e["within"] if e.get("within") else "") for e in kinds),
                     (kept or c.get("choice_text") or "")[:140], located.get(c["event_id"], ("?",))[0], office, conf, "; ".join(list(gp)[:3]), reason])
    for q in vqs:
        for L in "abcd":
            kinds = [e for e in (q.get(f"commitment_{L}") or []) if isinstance(e, dict) and str(e.get("kind", "")).startswith("promise")]
            if not kinds:
                continue
            kept = q.get(f"promise_kept_text_{L}") or ""
            text = " ".join([q.get(f"choice_{L}") or "", kept])
            cap, dis = office_cues(text)
            office, conf = propose_office(cap, dis)
            # A constituent's question: a promise made to a constituent is District unless the words say Capitol.
            base = "District"
            if office == "Capitol" and conf != "low":
                base_note = "the words point at the Capitol"
            else:
                office, conf, base_note = "District", ("medium" if not (cap and dis) else "low"), "a constituent's request: District by default"
            gp = generic_places(kept or text)
            prow.append(["visitor_questions", "%s.%s" % (q["question_id"], L), ", ".join("%s %s%s" % (e.get("kind"), e.get("amount") or e.get("item_id") or "", " within %sh" % e["within"] if e.get("within") else "") for e in kinds),
                         (kept or q.get(f"choice_{L}") or "")[:140], "(asked in Office Hours)", office, conf, "; ".join(list(gp)[:3]), "%s; cues: Capitol %s; District %s" % (base_note, cap[:3] or "none", dis[:3] or "none")])
    write_csv("event_promises_location.csv", ["source_table", "source_key", "promise (kind amount within)", "kept_text_or_choice", "source_event_location",
                                              "proposed_promise_location", "confidence", "needs_place", "reason"], prow)
    pc = collections.Counter(r[5] for r in prow)
    print("promise rows by location:", dict(pc), "| by source:", dict(collections.Counter(r[0] for r in prow)))


if __name__ == "__main__":
    main()
