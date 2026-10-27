"""Patron Bills: the full component library for all 27 organizations, with the
alternatives Option A needs (2026-10-19). Rewrites the Bill Components and
Patron Bills tabs wholesale (raw XML via wbx.replace_sheet_data).

Per organization: X, Y (Favor) + V (Favor spare for Amend) + Z, W (Flagship's
own two) + offers A-D (components other organizations' Flagships may use as
their ally component; an ally needs one per Flagship that names it, plus one).

Run once from the repo root:  python3 tools/workbook/archive/b9/step2b_library.py
"""
import sys, io, contextlib, collections
sys.path.insert(0, "tools/workbook"); sys.path.insert(0, "tools/workbook/archive/b9")
from wbx import replace_sheet_data
with contextlib.redirect_stdout(io.StringIO()):
    import patron_plan as P

PATH = "design/Game_Workbook.xlsx"
# org: (W, V, [offers])   each = (phrase, committee stage, tags)
EXTRA = {
 "BO03": (("fund district office staff training", "ST17", {"Localism": 0.5, "Technocratic": 0.3}),
          ("let district offices hold open town days", "ST17", {"Localism": 0.6}),
          [("fund district offices that help citizens file paperwork", "ST17", {"Localism": 0.6, "Technocratic": 0.3}),
           ("publish a directory of district services", "ST17", {"Localism": 0.5, "Democratic Norms": 0.3})]),
 "BO04": (("let towns merge services across borders", "ST17", {"Localism": 0.7, "Technocratic": 0.3}),
          ("fund town planning staff", "ST17", {"Localism": 0.5, "Federal Spending": 0.3}), []),
 "BO05": (("speed up customs clearance at Hokkaido ports", "ST14", {"Globalism": 0.6, "Regulation": -0.5, "Economic Liberalization": 0.5}),
          ("end paper filing for company registration", "ST17", {"Regulation": -0.6, "Technocratic": 0.4}),
          [("open a single window for business permits", "ST17", {"Regulation": -0.6, "Technocratic": 0.5}),
           ("let businesses take on apprentices without extra forms", "ST17", {"Regulation": -0.5, "Economic Liberalization": 0.3}),
           ("give new firms a tax holiday in their first year", "ST16", {"Taxation": -0.6, "Economic Liberalization": 0.4}),
           ("guarantee payment within sixty days on public contracts", "ST16", {"Regulation": 0.3, "Economic Liberalization": 0.3})]),
 "BO06": (("give neighborhood associations a seat on planning boards", "ST15", {"Localism": 0.8, "Democratic Norms": 0.4}),
          ("fund street lighting in residential blocks", "ST15", {"Localism": 0.4, "Federal Spending": 0.4}),
          [("fund neighborhood cleanup days", "ST10", {"Localism": 0.5, "Environmentalism": 0.3}),
           ("let neighborhood associations run small local grants", "ST17", {"Localism": 0.7})]),
 "BO07": (("set up a fisheries disaster relief fund", "ST13", {"Federal Spending": 0.6, "Rural Focus": 0.6}),
          ("fund new cold storage at fishing ports", "ST13", {"Federal Spending": 0.5, "Rural Focus": 0.5}),
          [("protect coastal fishing grounds from industrial dumping", "ST10", {"Environmentalism": 0.7, "Rural Focus": 0.4}),
           ("support direct sales of catch to local markets", "ST13", {"Localism": 0.5, "Rural Focus": 0.5})]),
 "BO08": (("require government data to be published in open formats", "ST17", {"Technocratic": 0.6, "Democratic Norms": 0.6}),
          ("protect journalists from lawsuits meant to silence them", "ST09", {"Civil Liberties": 0.8, "Judicial Independence": 0.3}),
          [("guarantee press access to public meetings", "ST12", {"Democratic Norms": 0.7, "Civil Liberties": 0.4}),
           ("fund local news outlets in small towns", "ST17", {"Federal Spending": 0.4, "Localism": 0.4, "Civil Liberties": 0.3}),
           ("require disclosure of who pays for political advertising", "ST09", {"Democratic Norms": 0.8, "Regulation": 0.3})]),
 "BO09": (("guarantee a living wage on public contracts", "ST16", {"Regulation": 0.6, "Federal Spending": 0.4, "Economic Liberalization": -0.5}),
          ("ban unpaid trial work", "ST17", {"Regulation": 0.6}), []),
 "BO10": (("pay farmers to keep paddies in use", "ST13", {"Agrarianism": 0.8, "Federal Spending": 0.5}),
          ("fund grain storage for farm cooperatives", "ST13", {"Agrarianism": 0.6, "Federal Spending": 0.4}),
          [("start a farm-to-school lunch program", "ST13", {"Agrarianism": 0.6, "Localism": 0.4}),
           ("insure farmers against bad harvests", "ST13", {"Agrarianism": 0.7, "Federal Spending": 0.4}),
           ("support farmers' direct sales at city markets", "ST13", {"Agrarianism": 0.5, "Rural Focus": 0.4})]),
 "BO11": (("forgive student loans for graduates who work in rural towns", "ST16", {"Federal Spending": 0.6, "Rural Focus": 0.4, "Post-Industrialism": 0.3}),
          ("fund scholarships for first-generation students", "ST16", {"Federal Spending": 0.5, "Liberal Rights": 0.2}), []),
 "BO12": (("make school lunches free", "ST16", {"Federal Spending": 0.7}),
          ("give families a tax deduction for each child", "ST16", {"Taxation": -0.4, "Traditional Values": 0.3}),
          [("fund after-school care in every district", "ST17", {"Federal Spending": 0.5, "Localism": 0.3}),
           ("let parents work shorter hours while children are young", "ST17", {"Regulation": 0.5, "Gender Equality": 0.4})]),
 "BO13": (("fund craft workshops in vacant shopfronts", "ST17", {"Traditional Values": 0.5, "Localism": 0.5, "Federal Spending": 0.3}),
          ("waive fees at craft fairs for small makers", "ST17", {"Traditional Values": 0.4, "Regulation": -0.3}),
          [("register master craftspeople as cultural assets", "ST17", {"Traditional Values": 0.7}),
           ("fund a national craft museum", "ST17", {"Traditional Values": 0.6, "Federal Spending": 0.4})]),
 "BO14": (("build park-and-ride lots at commuter stations", "ST15", {"Federal Spending": 0.5, "Rural Focus": 0.3}),
          ("cap the monthly cost of a commuter pass", "ST15", {"Federal Spending": 0.4, "Regulation": 0.3}),
          [("publish real-time delay data for every line", "ST17", {"Technocratic": 0.6, "Democratic Norms": 0.3}),
           ("refund fares for long delays", "ST15", {"Regulation": 0.5})]),
 "BO15": (("teach local traditions in schools", "ST17", {"Traditional Values": 0.8, "Localism": 0.4}),
          ("fund the repair of old wooden buildings", "ST15", {"Traditional Values": 0.6, "Federal Spending": 0.4}),
          [("support traditional crafts in school clubs", "ST17", {"Traditional Values": 0.6}),
           ("protect old town names on maps and signs", "ST17", {"Traditional Values": 0.7, "Localism": 0.4}),
           ("give grants to preserve traditional farmhouses", "ST15", {"Traditional Values": 0.6, "Rural Focus": 0.4, "Federal Spending": 0.3}),
           ("restore old rail stations as community landmarks", "ST15", {"Traditional Values": 0.5, "Federal Spending": 0.4})]),
 "BO16": (("open public data to start-ups", "ST17", {"Technocratic": 0.6, "Post-Industrialism": 0.6}),
          ("fund university spin-off labs", "ST16", {"Post-Industrialism": 0.7, "Federal Spending": 0.4}),
          [("let start-ups test products in regulatory sandboxes", "ST17", {"Regulation": -0.5, "Post-Industrialism": 0.7}),
           ("fund coworking hubs in regional cities", "ST16", {"Post-Industrialism": 0.6, "Rural Focus": 0.3, "Federal Spending": 0.3})]),
 "BO18": (("publish every project's full costs for public comment", "ST17", {"Democratic Norms": 0.7, "Technocratic": 0.4}),
          ("hold public question time with local officials", "ST17", {"Democratic Norms": 0.6, "Localism": 0.4}),
          [("let residents vote on local budget priorities", "ST17", {"Democratic Norms": 0.8, "Localism": 0.6}),
           ("require open hearings before closing local services", "ST12", {"Democratic Norms": 0.6, "Localism": 0.5})]),
 "BO19": (("fund repairs to temple halls damaged by weather", "ST15", {"Religious Traditionalism": 0.6, "Federal Spending": 0.5}),
          ("let temples run public meditation and care programs", "ST17", {"Religious Traditionalism": 0.6, "Liberal Rights": 0.2}), []),
 "BO20": (("waive permit fees for shrine festival stalls", "ST17", {"Religious Traditionalism": 0.6, "Regulation": -0.4}),
          ("fund shrine-led community cleanups", "ST10", {"Religious Traditionalism": 0.4, "Localism": 0.4}),
          [("protect sacred groves in national planning", "ST10", {"Religious Traditionalism": 0.7, "Environmentalism": 0.6}),
           ("record festival music and dance as living heritage", "ST17", {"Traditional Values": 0.7, "Religious Traditionalism": 0.5}),
           ("let festival organizers close streets without extra fees", "ST17", {"Localism": 0.5, "Regulation": -0.4, "Traditional Values": 0.3})]),
 "BO21": (("train and certify more care workers", "ST17", {"Federal Spending": 0.6, "Technocratic": 0.3}),
          ("cap the cost of nursing home beds for families", "ST16", {"Federal Spending": 0.6, "Regulation": 0.4}),
          [("fund respite care for family caregivers", "ST17", {"Federal Spending": 0.6, "Gender Equality": 0.3}),
           ("send local care teams to visit isolated elders", "ST17", {"Federal Spending": 0.5, "Localism": 0.4}),
           ("fund care worker housing near facilities", "ST15", {"Federal Spending": 0.6, "Localism": 0.3})]),
 "BO22": (("fund mental health care for veterans", "ST11", {"Militarism": 0.5, "Federal Spending": 0.5}),
          ("maintain war memorials and cemeteries", "ST11", {"Militarism": 0.4, "Traditional Values": 0.5}), []),
 "BO23": (("require an audit of every large grant", "ST16", {"Technocratic": 0.7, "Federal Spending": -0.5}),
          ("post government spending online by project", "ST16", {"Technocratic": 0.6, "Democratic Norms": 0.4}), []),
 "BO24": (("let foreign banks open branches in Hokkaido", "ST14", {"Globalism": 0.7, "Economic Liberalization": 0.6, "Regulation": -0.4}),
          ("simplify the registration of investment funds", "ST16", {"Regulation": -0.6, "Economic Liberalization": 0.4}),
          [("speed approval of new financial products", "ST16", {"Regulation": -0.5, "Economic Liberalization": 0.5}),
           ("fund financial literacy classes in schools", "ST17", {"Technocratic": 0.4, "Federal Spending": 0.3})]),
 "BO25": (("give small firms cheap loans for equipment", "ST16", {"Federal Spending": 0.4, "Economic Liberalization": 0.3}),
          ("waive licensing fees for micro-enterprises", "ST17", {"Regulation": -0.5, "Taxation": -0.3}), []),
 "BO26": (("let consumers sue together over defective goods", "ST09", {"Regulation": 0.6, "Liberal Rights": 0.5}),
          ("require plain-language contracts", "ST17", {"Regulation": 0.5, "Technocratic": 0.3}),
          [("publish product safety recalls in one public list", "ST17", {"Regulation": 0.5, "Technocratic": 0.5}),
           ("set up a free consumer complaint line", "ST17", {"Regulation": 0.4, "Federal Spending": 0.3})]),
 "BO27": (("allow denser housing near stations", "ST15", {"Regulation": -0.4, "Post-Industrialism": 0.6, "Rural Focus": -0.4}),
          ("fund bike lanes in city centers", "ST15", {"Environmentalism": 0.5, "Post-Industrialism": 0.4}),
          [("fund street trees and shade in city centers", "ST10", {"Environmentalism": 0.6, "Post-Industrialism": 0.3}),
           ("open vacant city lots to community gardens", "ST15", {"Localism": 0.5, "Environmentalism": 0.3})]),
 "BO28": (("return ceremonial sites to Ainu stewardship", "ST15", {"Ainu Enhancement": 1, "Minority Rights": 0.6, "Traditional Values": 0.3}),
          ("fund Ainu elders' knowledge programs", "ST17", {"Ainu Enhancement": 0.7, "Federal Spending": 0.3}), []),
 "BO29": (("fund museum exhibits and archives on Ainu culture", "ST17", {"Ainu Enhancement": 0.8, "Federal Spending": 0.4}),
          ("support Ainu language classes for adults", "ST17", {"Ainu Enhancement": 0.7, "Federal Spending": 0.3}), []),
 "BO30": (("fund clinics in rural towns", "ST17", {"Rural Focus": 0.9, "Federal Spending": 0.6}),
          ("give tax breaks to firms opening in rural towns", "ST16", {"Rural Focus": 0.7, "Taxation": -0.4}),
          [("support small-town shops with rent grants", "ST16", {"Rural Focus": 0.7, "Federal Spending": 0.4}),
           ("fund rural school buses", "ST15", {"Rural Focus": 0.7, "Federal Spending": 0.4}),
           ("support remote work hubs in villages", "ST17", {"Rural Focus": 0.6, "Post-Industrialism": 0.5})]),
}
SLOT_DIGIT = {"X": 1, "Y": 2, "Z": 3, "W": 4, "V": 5, "A": 6, "B": 7, "C": 8, "D": 9}

def tags(t): return "; ".join("%s %s" % (k, ("%+g" % v)) for k, v in t.items())
def cid(o, slot): return "CB%02d%d" % (int(o[2:]), SLOT_DIGIT[slot])

comps = {}   # id -> row
order = []
for o, (rival, ally, cs) in P.ORGS.items():
    W, V, offers = EXTRA[o]
    items = [("X", cs[0]), ("Y", cs[1]), ("V", V), ("Z", cs[2]), ("W", W)]
    items += [("ABCD"[i], off) for i, off in enumerate(offers)]
    for slot, (phrase, cmt, t) in items:
        gain = 3 if slot == "X" else 2
        comps[cid(o, slot)] = [cid(o, slot), o, slot, phrase[0].upper() + phrase[1:], phrase, "Would %s." % phrase,
                               cmt, tags(t), "%s +%d" % (o, gain), "%s -2" % rival, None, None, None]
        order.append(cid(o, slot))
need = collections.Counter(a for o, (r, a, c) in P.ORGS.items())
assert all(len(EXTRA[a][2]) == n + 1 for a, n in need.items()), "offer counts"
assert all(not EXTRA[o][2] for o in P.ORGS if o not in need), "unused offers"

pb = []
used = collections.Counter()
for o, (rival, ally, cs) in P.ORGS.items():
    for ki, kind in enumerate(("Favor", "Flagship"), start=1):
        if kind == "Favor":
            ids = [cid(o, "X"), cid(o, "Y")]
        else:
            ids = [cid(o, "Z"), cid(o, "W"), cid(ally, "ABCD"[used[ally]])]
            used[ally] += 1
        pb.append(["PB%02d%d" % (int(o[2:]), ki), o, kind, None, "; ".join(ids), ally if kind == "Flagship" else None,
                   "BT01" if kind == "Favor" else "BT02",
                   "{org} asks you to carry a bill: {bill}. Will you?", "You take it on. {org} is counting on you.",
                   "You tell {org} you cannot carry it. They do not hide their disappointment.",
                   "The bill passes, and {org} will not forget who carried it.",
                   "The bill falls short, and {org} knows you tried.",
                   "Draft 2026-10-19: lines use {org} and {bill}; Cameron to rewrite."])

replace_sheet_data(PATH, "Bill Components", ["Component ID", "Owner", "Slot", "Short Label", "Phrase", "Description",
        "Hearing Committee", "Value Tags", "Gains", "Loses", "Excludes", "Each Level Effect", "Amend Options"],
        [comps[i] for i in order])
replace_sheet_data(PATH, "Patron Bills", ["Patron Bill ID", "Organization", "Kind", "Threshold", "Components", "Ally", "Template ID",
        "Request Line", "Accept Line", "Decline Line", "Pass Line", "Fail Line", "Note"], pb)
print(len(order), "components,", len(pb), "patron bills")
