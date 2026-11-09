"""Writing review, group 1: build the change list (2026-11-09, Cameron).

Reads the six reviewer ledgers (design/review/WRITING_REVIEW_R1..R6_2026-11-09.csv)
and Cameron's 62 decisions (design/review/WRITING_REVIEW_DECISIONS_2026-11-09.md,
encoded by hand below), and writes:

  tools/workbook/archive/b15/changes.json
      every cell to change: tab, row, column, old text, new text
  design/review/WRITING_REVIEW_APPLIED_2026-11-09.csv
      the log: what was applied, skipped (with the decision number or reason)
      and could not be matched

Nothing is written to the workbook here; writing_review.py applies changes.json.
Run from the repo root:  python3 tools/workbook/archive/b15/build_change_list.py
Archived copy: it read the workbook and design/reference/bill_facets.json as
they stood before the review (the facet file then gained its serial commas), so
a second run finds a different starting point; changes.json is the record.

How a ledger row becomes a cell edit:
  * Row findings name an ID, a field and the cell's current text; wbindex.Index
    finds the one cell in a row holding that ID whose text equals it.
  * Frame findings from R3 (player lines) list their cells by ID with one
    pattern-level rewrite; they are expanded here with anchored regular
    expressions over the live text of every Player Cues row.
  * Cameron's decisions that settle wording across many lines (#13 singular
    organizations, #59 ticker format, #62 "the" before organizations) are
    applied as passes over the final text.
Several edits to one cell are chained; an edit whose quoted text no longer
matches is re-applied as a small in-place replacement when that is unambiguous,
and otherwise logged as a conflict.
"""
import csv, json, re, sys, collections
sys.path.insert(0, "tools/workbook/archive/b15")
from wbindex import Index, norm
import export_data as ED

LEDGERS = [f"design/review/WRITING_REVIEW_R{i}_2026-11-09.csv" for i in range(1, 7)]
OUT_CHANGES = "tools/workbook/archive/b15/changes.json"
OUT_LOG = "design/review/WRITING_REVIEW_APPLIED_2026-11-09.csv"

I = Index()
LOG = []          # dicts with file,id,field,original,new,status,reason
EDITS = collections.OrderedDict()   # (tab,row,col) -> list of (old, new, logref)


def log(file, id_, field, original, new, status, reason):
    entry = dict(file=file, id=id_, field=field, original=original, new=new,
                 status=status, reason=reason)
    LOG.append(entry)
    return entry


def col_type(tab, col):
    for key, c in I.field_cols.get(tab, {}).items():
        if c == col:
            for h, k, t in ED.SHEETS[tab]["columns"]:
                if k == key:
                    return key, t
    return None, None


def queue(loc, old, new, entry):
    """Queue one edit for a located cell. Only plain-text columns are edited
    (plus the Flavor Text tab's card-name column, an unexported mirror of Cards)."""
    tab, row, col = loc
    key, typ = col_type(tab, col)
    if tab == "Flavor Text" and I.rows[tab][1].get(col) == "Name (EN)":
        typ = "str"
    if typ != "str":
        entry["status"] = "skipped"
        entry["reason"] += f" | not applied: {tab}!{col}{row} is a structured column ({key}: {typ})"
        return
    EDITS.setdefault(loc, []).append((old, new, entry))


# ---------------------------------------------------------------------------
# Organizations and the article rule (decisions #13 and #62)
# ---------------------------------------------------------------------------
ORGS = [b["name_en"] for b in json.load(open("data/boosters.json"))]
NOART = {"Local Kōenkai", "Our Traditional Society", "Students United"}
ORG_ALT = "|".join(re.escape(o) for o in sorted(ORGS, key=len, reverse=True))
ORG_RE = re.compile(rf"(?<![\w’'])({ORG_ALT})(?![\w])")
NO_ARTICLE_AFTER = re.compile(
    r"(?i)(?:\b(?:the|a|an|my|our|your|their|his|her|its|fellow|other|every|all|those|these|many|some)\s+)$")


def the(o, cap):
    if o in NOART:
        return o
    return ("The " if cap else "the ") + o


def at_sentence_start(text, pos):
    pre = text[:pos]
    return pos == 0 or bool(re.search(r"[.!?]\s+$", pre)) or bool(re.search(r"^[\"“‘']$", pre))


def add_articles(t):
    """Puts "the" before every organization name that takes one (#62)."""
    out, last = [], 0
    for m in ORG_RE.finditer(t):
        o = m.group(1)
        if o in NOART:
            continue
        pre = t[:m.start()]
        if NO_ARTICLE_AFTER.search(pre):
            continue
        out.append(t[last:m.start()])
        out.append(the(o, at_sentence_start(t, m.start())))
        last = m.end()
    out.append(t[last:])
    return "".join(out)


def strip_koenkai_article(t):
    """#62: Local Kōenkai takes no article."""
    t = re.sub(r"(?<![\w])The Local Kōenkai", "Local Kōenkai", t)
    t = re.sub(r"(?<![\w])the [Ll]ocal Kōenkai", "Local Kōenkai", t)
    return t


POSS = rf"({ORG_ALT})(?:'s|’s|'|’) members"


def possessive_members(t):
    """"Chamber of Commerce's members" -> "the members of the Chamber of Commerce"."""
    def rep(m):
        cap = at_sentence_start(t, m.start())
        return ("The" if cap else "the") + " members of " + the(m.group(1), False)
    return re.sub(rf"(?<![\w]){POSS}", rep, t)


def singular_orgs(t):
    """#13: Students United and Neighborhood Associations take the singular."""
    for o in ("Students United", "Neighborhood Associations"):
        O = re.escape(o)
        t = re.sub(rf"\bDo ((?:the )?{O}) speak for everyone when they ask\b",
                   lambda m: f"Does {m.group(1)} speak for everyone when it asks", t)
        t = re.sub(rf"\bDoes ((?:the )?{O}) speak for everyone when they ask\b",
                   lambda m: f"Does {m.group(1)} speak for everyone when it asks", t)
        t = re.sub(rf"\b({O}) are worried about (.+?)\. Answer them straight\.",
                   r"\1 is worried about \2. Answer it straight.", t)
        t = re.sub(rf"\b({O}) are worried\b", r"\1 is worried", t)
        t = re.sub(rf"\b({O}) are our neighbors\. Let us not ignore them\b",
                   r"\1 is our neighbor. Let us not ignore it", t)
        t = re.sub(rf"\b({O}) fear what\b", r"\1 fears what", t)
        t = re.sub(rf"\b({O}) want us\b", r"\1 wants us", t)
        t = re.sub(rf"\b({O}) have asked\b", r"\1 has asked", t)
    return t


# ---------------------------------------------------------------------------
# Bill facets (serial comma, R3 frames 5, 8, 9)
# ---------------------------------------------------------------------------
FACETS = json.load(open("design/reference/bill_facets.json"))
FACET_LISTS = {}   # old list phrase -> with serial comma
for bid, f in FACETS.items():
    if not isinstance(f, dict):
        continue
    for k, v in f.items():
        if isinstance(v, str) and v.count(",") >= 1 and re.search(r",[^,]+ and [^,]+$", v):
            if re.search(r", and ", v):
                continue
            new = re.sub(r",([^,]+?) and ([^,]+)$", r",\1, and \2", v)
            FACET_LISTS[v] = new


def serial_comma(t):
    for old, new in FACET_LISTS.items():
        for o, n in ((old, new), (old[:1].upper() + old[1:], new[:1].upper() + new[1:])):
            if o in t and n not in t:
                t = t.replace(o, n)
    return t


def lc_first(s):
    return s[:1].lower() + s[1:]


def uc_first(s):
    return s[:1].upper() + s[1:]


# ---------------------------------------------------------------------------
# R3 frame expansion over Player Cues (component and bill lines)
# ---------------------------------------------------------------------------
COMPONENTS = {c["component_id"]: c for c in json.load(open("data/bill_components.json"))}
PLAYER = {r["cue_id"]: r for r in json.load(open("data/player_cues.json"))}


def r3_component_rules(t):
    """Frames [0]-[4]: organization slots, "{rival} agree", unanchored "them",
    and the two echoing Appeal frames. Returns (new, [frame numbers])."""
    used, orig = [], t
    o = ORG_ALT
    m = re.match(rf"^({o})(?:'s|’s|'|’) members asked me to (.+), and I think they are right\.$", t)
    if m:
        t = f"Members of {the(m.group(1), False)} want us to {m.group(2)}, and I think they are right."
        used.append(2)
    m = re.match(rf"^({o})(?:'s|’s|'|’) members have asked us to (.+), and their voices matter!$", t)
    if m:
        t = f"Members of {the(m.group(1), False)} want us to {m.group(2)}, and their voices matter!"
        used.append(2)
    t2 = possessive_members(t)
    if t2 != t:
        t = t2; used.append(0)
    m = re.match(rf"^I will not pretend ({o}) agrees?, but I believe we should (.+)$", t)
    if m:
        t = f"{the(m.group(1), True)} may disagree, but I believe we should {m.group(2)}"
        used.append(1)
    for a, b in (("Hear them out, then help us ", "Hear the people it helps, then help us "),
                 ("I have seen what it means to them. We must ", "I have seen what it means to families. We must "),
                 (", or we leave them behind.", ", or we leave people behind.")):
        if a in t:
            t = t.replace(a, b); used.append(3)
    m = re.match(r"^Everyone deserves a fair hearing on a plan to (.+)\.$", t)
    if m:
        t = f"We can shape a plan to {m.group(1)} that works for all of us."; used.append(4)
    m = re.match(r"^Let us decide together on a plan to (.+)\.$", t)
    if m:
        t = f"A plan to {m.group(1)} is stronger if we all shape it."; used.append(4)
    t2 = add_articles(t)
    if t2 != t:
        t = t2; used.append(0)
    if len(t.split(" ")) > 25:
        # Component lines stay within 25 words (test_component_content): use
        # "the Chamber of Commerce's members" when "the members of ..." is too long.
        def short(m):
            o = m.group(2)
            poss = o + ("'" if o.endswith("s") else "'s")
            if o in NOART:          # "the members of Students United" -> "Students United's members"
                return f"{poss} members"
            return f"{m.group(1)} {poss} members"   # -> "the Chamber of Commerce's members"
        t = re.sub(rf"\b([Tt]he) members of (?:the )?({ORG_ALT})", short, t)
    return t, sorted(set(used))


def r3_bill_rules(t, bill):
    """Frames [5]-[8] on bill lines, [10] on topic-room lines, [9] serial comma."""
    used = []
    f = FACETS.get(bill, {}) if bill else {}
    if bill and f:
        if t == "I will carry their stories into this vote!" and f.get("gain"):
            t = f"I will carry the stories of {f['gain']} into this vote!"; used.append(5)
        elif t == "I will carry their fears into this vote!" and f.get("hurt"):
            t = f"I will carry the fears of {f['hurt']} into this vote!"; used.append(5)
    m = re.match(r"^Their faces are why I am here! (.+)$", t)
    if m:
        t = f"The families I have met are why I am here! {m.group(1)}"; used.append(5)
    m = re.match(r"^Their worry is why I am here! (.+)$", t)
    if m:
        t = f"The worry I keep hearing is why I am here! {m.group(1)}"; used.append(5)
    m = re.match(r"^My heart is with (.+) today, and so is my vote!$", t)
    if m:
        t = f"My heart is with {m.group(1)}, and so is my vote!"; used.append(6)
    m = re.match(r"^Every family (waiting on|afraid of) (.+) is listening now!$", t)
    if m:
        t = f"Every family {m.group(1)} {m.group(2)} is listening!"; used.append(6)
    if t == "The blockers have had their say. Now vote.":
        t = "The blockers have had their say. Let the vote decide."; used.append(6)
    if t == "The backers have had their say. Now think.":
        t = "The backers have had their say. Let us think it through."; used.append(6)
    m = re.match(r"^I will ask for a full costing before this chamber votes on (.+)\.$", t)
    if m:
        t = f"I will ask for a full costing before anyone votes on {m.group(1)}."; used.append(7)
    m = re.match(r"^I will report the results of (.+) to this chamber\.$", t)
    if m:
        t = f"I will report the results of {m.group(1)} to the public once it is in force."; used.append(7)
    if bill and f.get("what"):
        what = f["what"]
        m = re.match(r"^(.+) is a plain, fair idea, and I will defend it\.$", t)
        if m and m.group(1).lower() == what.lower():
            t = f"I will defend {what}: it is a plain, fair idea."; used.append(8)
        m = re.match(r"^(.+) sounds fair on paper, and I cannot back it\.$", t)
        if m and m.group(1).lower() == what.lower():
            t = f"I cannot back {what}, however fair it sounds on paper."; used.append(8)
    m = re.match(r"^Funny how (.+) suits you so well\.$", t)
    if m:
        t = f"Funny how {m.group(1)} works out so well for you."; used.append(10)
    m = re.match(r"^Voters keep raising (.+)\.$", t)
    if m and not m.group(1).endswith(" with me"):
        t = f"Voters keep raising {m.group(1)} with me."; used.append(10)
    m = re.match(r"^Your side caused this over (.+)\.$", t)
    if m:
        t = f"Your side made this mess on {m.group(1)}."; used.append(10)
    t2 = serial_comma(t)
    if t2 != t:
        t = t2; used.append(9)
    return t, sorted(set(used))


def r3_thought_rules(t):
    used = []
    m = re.match(r"^(My worry is .+?\.) My hope is that .+ come out better off\.$", t)
    if m:
        t = f"{m.group(1)} I need to know who really comes out better off."; used.append(79)
    m = re.match(r"^Who gains: (.+)\. Who pays: (.+)\.$", t)
    if m:
        t = f"{uc_first(m.group(1))} would gain. {uc_first(m.group(2))} would pay. I have to weigh both."; used.append(80)
    return t, used


# ---------------------------------------------------------------------------
# Decisions applied to ledger rows
# ---------------------------------------------------------------------------
NEW_TEXT = {   # ledger rows whose proposal a decision replaces
    ("R1", "C16", "name_en"): ("Release the White Paper", "#16"),
    ("R6", "EV02", "flavor"): ("The Buddhist Temples Association is ringing the great bell at a hillside temple in Matsumae and asks you to take a turn. A neighbor mentions, quietly, that the bell tower roof leaks.", "#25 (drop the phrase; the ledger draft repeated \"the great bell\")"),
    ("R5", "TD2157", "character_line_en"): ("Half the gallery owes me favors. I will not spend them today.", "agreement fix kept; \"press\" left out because generic transition lines may not mention the press (test_stage_transition)"),
    ("R5", "LV25", "purpose"): ("The reform wave is rising, and the cameras are on you. Ride it through the press, four committees, and the floor.", "#46 (four committees) with the ledger's serial comma"),
}


def decide(rv, r):
    """Returns ("skip", reason) or ("apply", new_text, note)."""
    id_, field, code, conf = r["id"], r["field"], r["code"], r["confidence"]
    o, p = r["original"], r["proposed"]
    src = r["source"]
    key = (rv, id_, field)
    if key in NEW_TEXT:
        return ("apply",) + NEW_TEXT[key]
    if rv == "R1":
        if id_ == "TK113":
            return ("skip", "#43: spoken yes/no is fine; the only change was \"No\" to \"Nay\"")
        if id_ == "event.decline.EV58":
            return ("skip", "superseded by R6 EV58/D (same cell, \"a photo of the empty space\")")
    if rv == "R2":
        if code == "C10":
            return ("skip", "#30: varying the critic clause is new writing (group 2)")
        if id_ == "OC2545":
            return ("skip", "#13: Neighborhood Associations takes the singular; the singular pass rewrites this line instead")
        p2 = strip_koenkai_article(p)
        if p2 != p:
            return ("apply", p2, "#62: Local Kōenkai takes no \"the\"")
    if rv == "R3":
        if id_ in ("PL55", "PL1160", "PL1196", "PL1142"):
            return ("skip", "#8: \"the opposition\" and \"the majority\" are allowed")
        if id_ in ("C10", "C28") and r["file"] == "card_cues":
            return ("skip", "#10: \"my district\" is kept")
        if id_ == "PL3520":
            return ("skip", "#53: \"every yen\" is an idiom; keep")
        if id_.startswith("LV24#"):
            return ("skip", "#7: LV24 post-war creation is canon; keep")
        if r["file"] == "card_cues" and re.match(r"^C(0\d|[1-4]\d|5[0-4])$", id_) and conf == "low":
            return ("skip", "Cameron's own card cue (C01-C54), low-confidence suggestion, not a clear typo")
    if rv == "R4":
        if re.match(r"^media_ambush/A(23|24|25|26|28|30)$", id_):
            return ("skip", "#34: keep the accusing tone of the Media Ambush questions")
        if re.match(r"^stage/S5(7[3-9]|8[0-2])$", id_):
            return ("skip", "#32: S573-S582 move to a candidate-selection room (group 2)")
        if id_.startswith("VQ135-VQ156"):
            return ("skip", "#37: per-bill visitor replies are new writing (group 2)")
    if rv == "R5":
        if id_ in ("LV02", "LV05", "LV62"):
            return ("skip", "#42: the draft removes the hint; Cameron wants varied vague hints (new writing, group 2)")
        if "Some wanted a yes." in o:
            return ("skip", "#43: \"yes\" is fine in speech")
        if "THOUGHTS[1]" in src and re.search(POSS, o):
            new = possessive_members(o)
            return ("apply", new, "#62 article rule (recomputed: the ledger wrote \"the local Kōenkai\")")
    if rv == "R6":
        if id_ == "EV16/B":
            return ("skip", "#24: a Dues change in a structured column (group 2)")
        if id_.startswith("EV81/") or id_ == "EV81":
            return ("skip", "#20: follow-ups will fire only when the promise was kept (code, group 2), so \"second session\" stays true")
        if id_ == "BI01":
            return ("skip", "#48: bill-fact fixes (BI01, BI08, BI09) are drafts for Cameron (group 2)")
        if id_.startswith("PB031-PB302") and field != "fail_line":
            return ("skip", "#50: unused patron lines go to CLEANUP_CANDIDATES.md instead")
        if r["file"] == "bill_components":
            return ("skip", "deferred: the short label doubles as the Theme key in Stage Questions and Question Themes, so changing it renames a key (ask Cameron); phrase and description held back to keep the part consistent")
    return ("apply", p, "")


def locate_special(rv, r):
    """Cells the generic locator cannot find on its own: list of locations."""
    id_, field, o = r["id"], r["field"], r["original"]
    if r["file"] == "cards" and field == "name_en":
        return [(t, rr, c) for (t, rr, c) in I.by_text.get(norm(o), [])
                if id_ in I.rows[t][rr].values()]
    if r["file"] == "event_choices" and id_.endswith("/D") and field == "result_text":
        loc, how = I.locate("event.decline." + id_.split("/")[0], "english", o)
        return [loc] if loc else []
    if id_.startswith("PB031-PB302"):
        col = I.field_cols["Patron Bills"].get(field)
        return [(t, rr, c) for (t, rr, c) in I.by_text.get(norm(o), [])
                if t == "Patron Bills" and c == col]
    return None


def ledger_pass():
    for n, path in enumerate(LEDGERS, 1):
        rv = f"R{n}"
        for idx, r in enumerate(csv.DictReader(open(path, encoding="utf-8"))):
            if r["proposed"].strip() == "(no change)" or r["proposed"] == r["original"]:
                continue
            file = r["file"].replace("data/", "").replace(".json", "")
            tag = f"{rv} row {idx}"
            if rv == "R3" and r["source"].startswith("frame") and r["original"].startswith("["):
                log(file, f"(frame, {len(r['id'].split(';'))} cells)", r["field"], r["original"], r["proposed"],
                    "applied", f"{tag}: frame expanded per cell below (rows marked 'R3 frame')")
                continue
            d = decide(rv, r)
            if d[0] == "skip":
                log(file, r["id"], r["field"], r["original"], r["proposed"], "skipped", f"{tag}: {d[1]}")
                continue
            new, note = d[1], d[2]
            reason = f"{tag} [{r['code']}, {r['confidence']}]" + (f": {note}" if note else "")
            locs = locate_special(rv, r)
            if locs is None:
                loc, how = I.locate(r["id"], r["field"], r["original"])
                locs = [loc] if loc else []
                why = how
            else:
                why = "special lookup found nothing"
            if not locs:
                log(file, r["id"], r["field"], r["original"], new, "unmatched", f"{tag}: {why}")
                continue
            for loc in locs:
                e = log(file, r["id"], r["field"], r["original"], new, "applied", reason)
                queue(loc, r["original"], new, e)


# ---------------------------------------------------------------------------
# Extra wording that the decisions settle but no ledger row carried
# ---------------------------------------------------------------------------
EXTRAS = [
    ("questions", "town_hall/T27", "text", "When will Parliament restore long-term working visas for the service industry?",
     "When will Parliament introduce long-term working visas for the service industry?", "#39: ask about introducing them, not restoring"),
    ("visitor_questions", "VQ229", "response_c", "Then who is left to elect you?",
     "Then who is left in the valley?", "#40: Imabetsu is not in the player's district"),
    ("levels", "LV103", "purpose", "A tour of the whole district. Everyone you pass will compare it with the last candidate's.",
     "A tour of the whole district. Everyone you pass will be sizing you up.", "#45: reword \"the last candidate's\""),
]


def extras_pass():
    for file, id_, field, o, n, why in EXTRAS:
        loc, how = I.locate(id_, field, o)
        if not loc:
            log(file, id_, field, o, n, "unmatched", f"decision {why}: {how}")
            continue
        queue(loc, o, n, log(file, id_, field, o, n, "applied", f"decision {why} (Claude's draft)"))


# ---------------------------------------------------------------------------
# Chaining edits per cell
# ---------------------------------------------------------------------------
def diff_apply(cur, old, new):
    """Re-apply old->new as an in-place replacement of the changed span."""
    i = 0
    while i < min(len(old), len(new)) and old[i] == new[i]:
        i += 1
    j = 0
    while j < min(len(old), len(new)) - i and old[-1 - j] == new[-1 - j]:
        j += 1
    for ctx in range(0, 25):
        a, b = max(0, i - ctx), len(old) - j + ctx
        seg_old = old[a:b]
        seg_new = new[a:len(new) - j + ctx] if j - ctx >= 0 else None
        if seg_new is None:
            break
        if seg_old and cur.count(seg_old) == 1:
            return cur.replace(seg_old, seg_new)
    return None


FINAL = {}     # loc -> (start, final)


def chain():
    for loc, edits in EDITS.items():
        start = I.text(*loc)
        cur = start
        for old, new, entry in edits:
            if norm(cur) == norm(old):
                cur = new
            elif norm(cur) == norm(new):
                entry["reason"] += " | same edit as an earlier row for this cell"
            elif norm(start) == norm(old):
                got = diff_apply(cur, old, new)
                if got is None:
                    entry["status"] = "skipped"
                    entry["reason"] += " | conflict: another edit already changed this cell"
                else:
                    cur = got
                    entry["reason"] += " | merged with an earlier edit to the same cell"
                    entry["new"] = got
            else:
                entry["status"] = "skipped"
                entry["reason"] += " | conflict: the quoted text does not match the cell"
        FINAL[loc] = [start, cur]


def cur_text(loc):
    return FINAL[loc][1] if loc in FINAL else I.text(*loc)


def set_final(loc, new, file, id_, field, reason):
    old = cur_text(loc)
    if new == old:
        return
    if loc not in FINAL:
        FINAL[loc] = [I.text(*loc), new]
    else:
        FINAL[loc][1] = new
    log(file, id_, field, old, new, "applied", reason)


# ---------------------------------------------------------------------------
# Passes over whole tabs
# ---------------------------------------------------------------------------
def tab_cells(tab, keys):
    fc = I.field_cols[tab]
    idcol = fc.get(ED.SHEETS[tab]["columns"][0][1])
    for r, cells in I.rows[tab].items():
        if r == 1:
            continue
        for k in keys:
            c = fc.get(k)
            if c and cells.get(c):
                yield (tab, r, c), cells.get(idcol, f"row {r}"), k


R3_LISTED = set()


def read_r3_lists():
    for r in csv.DictReader(open(LEDGERS[2], encoding="utf-8")):
        if r["source"].startswith("frame") and r["original"].startswith("["):
            for part in r["id"].split(";"):
                R3_LISTED.add(part.strip())


def player_pass():
    """R3 frames over Player Cues, then the article rule for organization slots."""
    read_r3_lists()
    for loc, cid, k in tab_cells("Player Cues", [f"cue_{i}" for i in range(1, 6)]):
        row = PLAYER.get(cid)
        if not row:
            continue
        t = cur_text(loc)
        used = []
        if row.get("component_ids"):
            t, used = r3_component_rules(t)
        bill = (row.get("bill_ids") or [None])[0] if row.get("bill_ids") else None
        t, u2 = r3_bill_rules(t, bill)
        used += u2
        if t != cur_text(loc):
            listed = f"{cid}.{k}" in R3_LISTED
            set_final(loc, t, "player_cues", cid, k,
                      f"R3 frame {used}" + ("" if listed else " (same frame, cell not in the reviewer's list)"))


def thoughts_pass():
    listed = set()
    for r in csv.DictReader(open(LEDGERS[2], encoding="utf-8")):
        if r["file"] == "level_intro_thoughts" and r["source"].startswith("frame"):
            listed.update(x.split("#")[0] for x in r["id"].split(";"))
    for loc, lid, k in tab_cells("Level Intro Thoughts", ["thought_text"]):
        t, used = r3_thought_rules(cur_text(loc))
        if used:
            set_final(loc, t, "level_intro_thoughts", lid, k, f"R3 frame {used} [low]")


OPP = {r["cue_id"]: r for r in json.load(open("data/opponent_cues.json"))}


def opponent_pass():
    """#62 article rule on organization slots in bill-part lines; #13 singular."""
    for loc, cid, k in tab_cells("Opponent Cues", [f"cue_{i}" for i in range(1, 6)]):
        row = OPP.get(cid)
        t0 = cur_text(loc)
        t = strip_koenkai_article(t0)
        if row and row.get("component_ids"):
            t = add_articles(t)
        t = singular_orgs(t)
        if t != t0:
            set_final(loc, t, "opponent_cues", cid, k, "#62 \"the\" before organizations / #13 singular organizations")


TEXT_TABS = {
    "Transition Dialogue": ["character_line_en", "player_reply_en"],
    "Visitor Questions": None, "Events": None, "Event Choices": None, "Event Options": None,
    "Levels": ["purpose"], "Level Intro Cues": None, "Level Intro Thoughts": None,
    "Floor Vote Bills": None, "Floor Vote Party Positions": None, "Vote Influence Cues": None,
    "Stage Questions": ["text"], "Press Questions": None, "Town Hall Questions": None,
    "Lobbyist Questions": None, "Study Session Questions": None, "Media Ambush Questions": None,
    "Visit Questions": None, "Visit Answers": None, "Trade Questions": None, "Lobbyist Lines": None,
    "Law Effects": None, "Reaction Lines": None, "Text": None, "Office Notices": None,
    "Opponent Cues": [f"cue_{i}" for i in range(1, 6)], "Player Cues": [f"cue_{i}" for i in range(1, 6)],
}
SKIP_KEYS = re.compile(r"(^|_)(id|ids|key|name|name_en|name_jp|romaji|theme|title_jp|condition)", re.I)


def text_keys(tab):
    keys = TEXT_TABS[tab]
    if keys:
        return keys
    out = []
    for h, k, t in ED.SHEETS[tab]["columns"]:
        if t == "str" and not SKIP_KEYS.search(k) and not k.endswith("_jp"):
            out.append(k)
    return out


def global_pass():
    """Serial comma in the 21 bill-facet lists (R3 frame 9, R2, R4, R5) and
    Local Kōenkai without "the" (#62), over every text column."""
    facet_cells = {norm(v) for v in FACET_LISTS}
    for tab in TEXT_TABS:
        if tab not in I.rows:
            continue
        for loc, rid, k in tab_cells(tab, text_keys(tab)):
            t0 = cur_text(loc)
            if norm(t0) in facet_cells:
                continue
            t = strip_koenkai_article(serial_comma(t0))
            if t != t0:
                set_final(loc, t, tab, rid, k, "serial comma in a bill-facet list (R3 frame 9) / #62 Local Kōenkai")


def ticker_pass():
    """#59: every ticker line ends with the dash and the sun."""
    for loc, tid, k in tab_cells("Office Ticker", ["text_en"]):
        t0 = cur_text(loc)
        t = re.sub(r"\s+☼$", " ☼", t0.rstrip())
        if t.endswith("☼"):
            body = t[:-1].rstrip()
            if not re.search(r" - [^-]*$", body) and not body.endswith(" -"):
                t = body + " - ☼"
        else:
            t = t + " ☼" if re.search(r" - [^-]+$", t) else t + " - ☼"
        t = re.sub(r"  +", " ", t)
        if t != t0:
            set_final(loc, t, "office_ticker", tid, k, "#59: every ticker line ends with the dash and the ☼")


# ---------------------------------------------------------------------------
def main():
    ledger_pass()
    extras_pass()
    chain()
    player_pass()
    thoughts_pass()
    opponent_pass()
    global_pass()
    ticker_pass()
    changes = []
    for (tab, row, col), (start, final) in FINAL.items():
        if final != start:
            changes.append(dict(tab=tab, row=row, col=col, old=start, new=final))
    json.dump(changes, open(OUT_CHANGES, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    with open(OUT_LOG, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["file", "id", "field", "original", "new", "status", "reason"])
        w.writeheader()
        for e in LOG:
            w.writerow(e)
    c = collections.Counter((e["reason"].split(" ")[0] if e["reason"][:1] == "R" else "decision/pass", e["status"]) for e in LOG)
    for k in sorted(c):
        print(k, c[k])
    print(len(changes), "cells change")


if __name__ == "__main__":
    main()
