"""B4 (2026-11-19): a draft office tag (Capitol, District or Either) for each of the 167 visitors, for Cameron to correct.
Reads data/visitors.json and data/boosters.json only; writes visitor_office_tags.csv next to this script.
Method: two signals. (1) the title's words; (2) which kind of organization the visitor's reward and penalty
touch (Party and Members of Parliament lean Capitol; Constituency organizations lean District; the other National
organizations lean neither). Agreement is high confidence, one signal is medium, no signal or a conflict is low and
the tag falls to Either. The spec: fellow members and party people visit the Capitol; constituents belong to the District."""
import csv, json, re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3] if (Path(__file__).resolve().parents[3] / "data").exists() else Path.cwd()
OUT = Path(__file__).resolve().parent

CAPITOL = re.compile(r"\b(party|faction|whip|caucus|secretary-general|candidate|campaign|treasurer|pollster|strategist|fundraiser|"
                     r"ministerial|minister|ministry|cabinet|bureaucrat|official|lobbyist|union representative|reporter|"
                     r"journalist|columnist|editor|anchor|pundit|scholar|professor|think tank|analyst|economist|"
                     r"chief of staff|aide|advisor|adviser|clerk of the|committee|assembly|parliament|legislat|lawyer|attorney|"
                     r"prosecutor|judge|diplomat|ambassador|general secretary|chamber|federation|association president|"
                     r"executive|banker|financier|director of)\b", re.I)
DISTRICT = re.compile(r"\b(farmer|fisherman|fisher|grower|brewer|mayor|neighborhood|shop|shopkeeper|parent|father|mother|commuter|"
                      r"constituent|student|priest|village|town|ferry|boat|captain|doctor|nurse|ranger|retired|resident|"
                      r"woodcarver|craft|artisan|potter|weaver|baker|butcher|grocer|innkeeper|owner|welder|supervisor|"
                      r"islander|young|teacher|schoolteacher|volunteer|local|neighbor|elderly|grandmother|grandfather|"
                      r"station master|clerk|engineer|operator|driver|carpenter|builder|rice|dairy|potato|salmon|scallop|"
                      r"kombu|orchard|greenhouse|rancher|herder|miner|dockworker|trader|exporter|importer|customs|clinic|dentist|hospital|"
                      r"pharmac\w*|midwife|cleaner|maker|sculptor|caretaker|festival|guide|instructor|florist|barber|fishmonger|"
                      r"stallholder|vendor|contractor|dietitian|tutor|librarian|principal|pta|cooperative member|club member|producer|"
                      r"stand|manager|worker|husband|wife|couple|family|grandparent)\b", re.I)
EITHER_WORDS = re.compile(r"\b(celebrity|founder|startup|influencer|athlete|artist|author|novelist|musician|actor|comedian|newsreader|regional)\b", re.I)


def tiers(boosters):
    return {b["booster_id"]: b.get("tier") for b in boosters}


def org_signal(visitor, tier_of):
    votes = {"Capitol": 0, "District": 0, "National": 0}
    for key in ("reward", "penalty"):
        for entry in visitor.get(key) or []:
            tier = tier_of.get(str(entry.get("target")))
            if tier == "Party" or entry.get("target") == "BO17":
                votes["Capitol"] += 1
            elif tier == "Constituency":
                votes["District"] += 1
            elif tier == "National":
                votes["National"] += 1
    if votes["Capitol"] > votes["District"]:
        return "Capitol", votes
    if votes["District"] > votes["Capitol"]:
        return "District", votes
    return ("" if not votes["National"] else "National"), votes


def classify(visitor, tier_of):
    title = str(visitor.get("title") or "")
    if re.search(r"\bconstituent\b", title, re.I):
        return "District", "high", "the spec: constituents belong to the District, whatever organization they touch"
    cap, dis, eit = bool(CAPITOL.search(title)), bool(DISTRICT.search(title)), bool(EITHER_WORDS.search(title))
    # a title that names both (Village Clerk, Young Party Activist) is decided by its LAST word group's strongest hit
    if cap and dis:
        words = re.findall(r"[A-Za-z-]+", title.lower())
        last_c = max((i for i, w in enumerate(words) if CAPITOL.search(w)), default=-1)
        last_d = max((i for i, w in enumerate(words) if DISTRICT.search(w)), default=-1)
        title_says = "Capitol" if last_c > last_d else "District"
        title_note = f"title names both kinds; its head word points {title_says}"
        title_sure = False
    elif cap:
        title_says, title_note, title_sure = "Capitol", "title is a party, press, ministry or Assembly role", True
    elif dis:
        title_says, title_note, title_sure = "District", "title is a local trade, place or ordinary resident", True
    elif eit:
        title_says, title_note, title_sure = "Either", "a public figure with no office of their own", True
    else:
        title_says, title_note, title_sure = "", "title says nothing clear", False
    org, votes = org_signal(visitor, tier_of)
    orgs = f"orgs: Capitol-leaning {votes['Capitol']}, District-leaning {votes['District']}, other national {votes['National']}"
    if title_says and org and title_says == org:
        return title_says, "high", f"{title_note}; the organizations they touch agree ({orgs})"
    if title_says == "Either":
        return "Either", "medium", f"{title_note} ({orgs})"
    if title_says and not org:
        return title_says, ("high" if title_sure else "medium"), f"{title_note}; {orgs}"
    if org in ("Capitol", "District") and not title_says:
        return org, "medium", f"title says nothing clear; the organizations they touch lean {org} ({orgs})"
    if title_says and org in ("Capitol", "District") and title_says != org:
        return "Either", "low", f"title points {title_says} but the organizations they touch lean {org}: left Either ({orgs})"
    if title_says and org == "National":
        return title_says, ("medium" if title_sure else "low"), f"{title_note}; they touch national organizations ({orgs})"
    return "Either", "low", f"no clear signal: left Either ({orgs})"


if __name__ == "__main__":
    visitors = json.loads((ROOT / "data" / "visitors.json").read_text(encoding="utf-8"))
    visitors = visitors if isinstance(visitors, list) else visitors.get("visitors")
    boosters = json.loads((ROOT / "data" / "boosters.json").read_text(encoding="utf-8"))
    boosters = boosters if isinstance(boosters, list) else boosters.get("boosters")
    tier_of = tiers(boosters)
    rows = []
    for v in visitors:
        loc, conf, why = classify(v, tier_of)
        rows.append([v["visitor_id"], v.get("name_en"), v.get("title"), loc, conf, why])
    with open(OUT / "visitor_office_tags.csv", "w", newline="", encoding="utf-8") as handle:
        w = csv.writer(handle)
        w.writerow(["visitor_id", "name", "title", "proposed_office", "confidence", "reason"])
        w.writerows(rows)
    import collections
    print(len(rows), collections.Counter(r[3] for r in rows), collections.Counter(r[4] for r in rows))
