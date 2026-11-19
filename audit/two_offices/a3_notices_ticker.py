"""Item 3: every Office Notice and Office Ticker line with a proposed office.

Notices are few (20) and read by hand. The ticker (155 lines) is a mixed national and local feed by design (spec),
so a line stays Either unless it would read wrong at one office; `lean` records which office its words point at,
and `flag` is Yes only for lines that put a PHYSICAL presence in one office.
"""
import collections
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from common import *
from textscan import *

NOTICE = {
    "ON01": ("District", "high", "the District Representative greeting visitors: the spec moves ON01 and ON02 to the District office"),
    "ON02": ("District", "high", "no one at the front desk: the District office's front desk (spec)"),
    "ON03": ("Capitol", "medium", "reviewing committee minutes and reports: Assembly paperwork. Staff tasks run wherever the player is (spec), so this is a presence line"),
    "ON04": ("Capitol", "medium", "no one reviewing policy reports: same as ON03"),
    "ON05": ("Capitol", "medium", "answering reporters' questions: the press works from the Capitol; could be Either"),
    "ON06": ("Capitol", "medium", "press calls unanswered: same as ON05"),
    "ON07": ("Either", "high", "few visitors seek out the office: either office has visitors"),
    "ON08": ("Either", "high", "a waitlist for visitors: either office"),
    "ON09": ("Capitol", "medium", "a student journalist visits the office: journalists work from the Capitol (spec: press notices stay in the Capitol)"),
    "ON10": ("Capitol", "medium", "veteran journalists visit for a profile: press stays in the Capitol (spec)"),
    "ON11": ("Capitol", "high", "party colleagues visiting: fellow members visit the Capitol office (spec)"),
    "ON12": ("Capitol", "high", "party members who want lunch: a Capitol line"),
    "ON13": ("District", "high", "a constituent removed by security: the spec moves ON13 to ON16 (constituent visits) to the District office"),
    "ON14": ("District", "high", "a constituent and graffiti on the office door: District (spec)"),
    "ON15": ("District", "high", "an elderly constituent leaves a gift basket: District (spec)"),
    "ON16": ("District", "high", "a family from your district takes a picture: District (spec)"),
    "ON17": ("Either", "medium", "a donor demands a refund: donors could write to either office"),
    "ON18": ("Either", "medium", "a benefactor delivers a check: either office (leans District: campaign money)"),
    "ON19": ("Capitol", "high", "a committee intern: committees sit at the Capitol"),
    "ON20": ("Capitol", "high", "Cabinet Legislation Bureau Chief delivers bill analysis: Capitol"),
}

PHYSICAL = re.compile(r"\bin that office\b|\bat the front desk\b|\boutside the party office\b|\byour office door\b|\bwaiting room\b|\bvisited the office\b", re.I)


def main():
    rows = []
    for n in load("office_notices"):
        office, conf, why = NOTICE[n["notice_id"]]
        cond = "%s %s %s %s" % (n["condition_type"], n["condition_target"], n["condition_op"], n["condition_value"] if n["condition_value"] is not None else "")
        rows.append(["notice", n["notice_id"], cond.strip(), n["text_en"], office, conf, "Yes" if office != "Either" else "No", why])
    lean = collections.Counter()
    for t in load("office_ticker"):
        text = t["text_en"]
        cap, dis = office_cues(text)
        office = "Either"
        leaning = "none"
        if len(cap) >= len(dis) + 2:
            leaning = "Capitol"
        elif len(dis) >= len(cap) + 2:
            leaning = "District"
        flag = "No"
        why = "a news line: one mixed feed in both offices (spec)"
        if PHYSICAL.search(text) or t["condition_type"] == "staff_role":
            flag = "Yes"
            why = "puts a person or event INSIDE the player's office (%s): reads as 'this office' wherever it shows" % (PHYSICAL.search(text).group(0) if PHYSICAL.search(text) else "a staff-role line: the staff member is in one office")
        if t.get("from_date") or t.get("yearly"):
            why += "; dated line (from %s): tied to a dated event" % t.get("from_date")
        names_local = re.findall(r"Otaru Radio|Aomori’s|Aomori's|Hirosaki|Otaru|Hakodate", text)
        if names_local:
            why += "; names a local outlet or town (%s): a local feed line" % ", ".join(sorted(set(names_local)))
            if leaning == "none":
                leaning = "District (outlet)"
        lean[leaning] += 1
        cond = "%s %s %s %s" % (t["condition_type"], t["condition_target"], t["condition_op"], t["condition_value"] if t["condition_value"] is not None else "")
        rows.append(["ticker", t["ticker_id"], cond.strip(), text, office, "high" if flag == "No" else "medium", flag, "%s | words lean: %s" % (why, leaning)])
    write_csv("notices_ticker_location.csv", ["source", "id", "condition", "text", "proposed_office", "confidence", "flag_reads_wrong_in_one_office", "reason"], rows)
    flags = collections.Counter((r[0], r[6]) for r in rows)
    print(dict(flags), "| ticker lean:", dict(lean))
    print("notice offices:", dict(collections.Counter(r[4] for r in rows if r[0] == "notice")))


if __name__ == "__main__":
    main()
