"""Patron Bills plan: draft components and bills, with computed party positions.

Planning tool only (2026-10-19). Reads design/reference/party_values.tsv and
data/boosters.json, applies the same lean model the Batch 2 bills used
(tools/workbook/archive/b2/model.py), and prints the markdown tables that go in
design/proposals/PATRON_BILLS_BUILD_PLAN_2026-10-19.md. Nothing here is game data.
"""
import json, sys
sys.path.insert(0, "/home/user/CoP-Deckbuilder/tools/workbook/archive/b2")
from model import PID, SEATS, split  # noqa: E402

B = {b["booster_id"]: b for b in json.load(open("/home/user/CoP-Deckbuilder/data/boosters.json"))}
SHORT = {"PT01": "BU", "PT02": "YH", "PT03": "FR", "PT04": "FP", "PT05": "KJ", "PT06": "CI"}
CMT = {"ST09": "Ethics", "ST10": "Environment", "ST11": "War", "ST12": "Natl Assembly",
       "ST13": "Agriculture", "ST14": "Foreign Affairs", "ST15": "Construction",
       "ST16": "Finance", "ST17": "Govt Admin", "ST03": "Party Caucus"}

# org: (rival, ally, [X core, Y modest, Z ambitious]); each component is
# (phrase, committee stage, {value dimension: direction})
ORGS = {
 "BO01": ("BO02", "BO32", [
   ("route campaign funding through party headquarters", "ST03", {"Leadership Interest": 1, "Clientelism": -0.3}),
   ("require party approval for members' private bills", "ST03", {"Leadership Interest": 0.8, "Democratic Norms": -0.3}),
   ("create a central campaign data office", "ST03", {"Leadership Interest": 0.7, "Technocratic": 0.5})]),
 "BO02": ("BO01", "BO31", [
   ("award committee chairs by seniority", "ST03", {"Leadership Interest": -0.6, "Clientelism": 0.6}),
   ("protect faction study groups from headquarters control", "ST03", {"Leadership Interest": -0.8}),
   ("allow faction fundraising events with full disclosure", "ST03", {"Clientelism": 0.8, "Democratic Norms": 0.2})]),
 "BO31": ("BO32", "BO02", [
   ("let members vote on the party platform", "ST03", {"Democratic Norms": 0.8, "Leadership Interest": -0.6}),
   ("open the party conference to all members", "ST03", {"Democratic Norms": 0.6}),
   ("let members choose candidates by ballot", "ST03", {"Democratic Norms": 1, "Leadership Interest": -0.8})]),
 "BO32": ("BO31", "BO01", [
   ("set vetting standards for every candidate", "ST03", {"Leadership Interest": 0.6, "Democratic Norms": 0.3}),
   ("require candidates to disclose their finances", "ST03", {"Democratic Norms": 0.6, "Clientelism": -0.5}),
   ("create a candidate review board", "ST03", {"Leadership Interest": 0.8, "Technocratic": 0.4})]),
 "BO03": ("BO23", "BO18", [
   ("raise allowances for district offices", "ST12", {"Federal Spending": 0.6, "Localism": 0.6, "Clientelism": 0.4}),
   ("ease the rules on constituent gatherings", "ST12", {"Localism": 0.6, "Regulation": -0.4}),
   ("create a constituency development fund", "ST16", {"Federal Spending": 0.9, "Clientelism": 0.7, "Localism": 0.5})]),
 "BO04": ("BO23", "BO30", [
   ("give towns unconditional block grants", "ST17", {"Localism": 1, "Federal Spending": 0.6}),
   ("let towns borrow for local projects", "ST17", {"Localism": 0.8, "Federal Spending": 0.3}),
   ("give towns their own tax-setting powers", "ST16", {"Localism": 1, "Taxation": 0.3})]),
 "BO05": ("BO09", "BO24", [
   ("cut the corporate tax rate", "ST16", {"Taxation": -1, "Economic Liberalization": 0.7}),
   ("simplify business licensing", "ST17", {"Regulation": -0.8, "Economic Liberalization": 0.5}),
   ("open special economic zones", "ST16", {"Economic Liberalization": 1, "Globalism": 0.5, "Industrialism": 0.4})]),
 "BO06": ("BO05", "BO03", [
   ("fund repairs to community halls", "ST15", {"Federal Spending": 0.5, "Localism": 0.7}),
   ("support neighborhood watch groups", "ST17", {"Localism": 0.6, "Traditional Values": 0.3}),
   ("give neighborhood associations legal standing in planning", "ST15", {"Localism": 1, "Regulation": 0.4})]),
 "BO07": ("BO26", "BO10", [
   ("fund harbor repairs", "ST15", {"Federal Spending": 0.6, "Rural Focus": 0.7}),
   ("subsidize fuel for fishing boats", "ST13", {"Federal Spending": 0.6, "Agrarianism": 0.5, "Environmentalism": -0.4}),
   ("hold fishing quotas through local cooperatives", "ST13", {"Localism": 0.7, "Economic Liberalization": -0.5, "Rural Focus": 0.5})]),
 "BO08": ("BO01", "BO26", [
   ("strengthen freedom of information requests", "ST17", {"Civil Liberties": 0.8, "Democratic Norms": 0.6}),
   ("protect reporters' confidential sources", "ST09", {"Civil Liberties": 1, "Judicial Independence": 0.3}),
   ("open every committee hearing to the press", "ST12", {"Democratic Norms": 0.9, "Leadership Interest": -0.5})]),
 "BO09": ("BO05", "BO21", [
   ("raise the minimum wage", "ST16", {"Regulation": 0.8, "Economic Liberalization": -0.7}),
   ("enforce overtime pay", "ST17", {"Regulation": 0.7}),
   ("protect collective bargaining rights", "ST17", {"Regulation": 0.6, "Liberal Rights": 0.4, "Economic Liberalization": -0.6})]),
 "BO10": ("BO27", "BO30", [
   ("support the rice price", "ST13", {"Agrarianism": 1, "Federal Spending": 0.5, "Economic Liberalization": -0.4}),
   ("subsidize farm machinery", "ST13", {"Agrarianism": 0.8, "Federal Spending": 0.5}),
   ("restrict foreign food imports", "ST14", {"Globalism": -1, "Agrarianism": 0.8, "Economic Liberalization": -0.5})]),
 "BO11": ("BO15", "BO16", [
   ("cap university tuition", "ST16", {"Federal Spending": 0.7, "Post-Industrialism": 0.5}),
   ("give students discounted transit", "ST15", {"Federal Spending": 0.4}),
   ("build public student housing", "ST15", {"Federal Spending": 0.8, "Post-Industrialism": 0.4})]),
 "BO12": ("BO25", "BO21", [
   ("raise the child allowance", "ST16", {"Federal Spending": 0.8, "Traditional Values": 0.3}),
   ("extend paid parental leave", "ST17", {"Gender Equality": 0.7, "Regulation": 0.5}),
   ("open more public childcare places", "ST17", {"Federal Spending": 0.8, "Gender Equality": 0.5})]),
 "BO13": ("BO16", "BO15", [
   ("certify local crafts with a protected label", "ST17", {"Traditional Values": 0.6, "Localism": 0.5}),
   ("give tax relief for craft apprenticeships", "ST16", {"Taxation": -0.4, "Traditional Values": 0.5}),
   ("promote craft exports abroad", "ST14", {"Globalism": 0.6, "Traditional Values": 0.4})]),
 "BO14": ("BO30", "BO27", [
   ("freeze commuter fares", "ST15", {"Federal Spending": 0.6, "Rural Focus": -0.5}),
   ("run late-night commuter trains", "ST15", {"Federal Spending": 0.5, "Post-Industrialism": 0.4}),
   ("make every station step-free", "ST15", {"Federal Spending": 0.8, "Minority Rights": 0.4})]),
 "BO15": ("BO11", "BO20", [
   ("fund local festivals", "ST17", {"Traditional Values": 0.8, "Federal Spending": 0.3}),
   ("protect historic districts from redevelopment", "ST15", {"Traditional Values": 0.8, "Regulation": 0.5}),
   ("create a national heritage register", "ST17", {"Traditional Values": 1, "Religious Traditionalism": 0.3})]),
 "BO16": ("BO13", "BO05", [
   ("give a tax credit for research and development", "ST16", {"Post-Industrialism": 1, "Taxation": -0.4}),
   ("offer visas to start-up founders", "ST14", {"Immigration": 0.7, "Post-Industrialism": 0.6}),
   ("move government services online", "ST17", {"Technocratic": 0.9, "Post-Industrialism": 0.5})]),
 "BO17": ("BO23", "BO02", [
   ("raise members' staff allowances", "ST12", {"Federal Spending": 0.5, "Democratic Norms": 0.3}),
   ("fund a committee research office", "ST12", {"Technocratic": 0.7, "Democratic Norms": 0.5}),
   ("create an independent parliamentary budget office", "ST12", {"Technocratic": 0.9, "Democratic Norms": 0.6})]),
 "BO18": ("BO17", "BO06", [
   ("hold local referendums on large projects", "ST17", {"Democratic Norms": 0.8, "Localism": 0.6}),
   ("require public consultation before new projects", "ST15", {"Democratic Norms": 0.7, "Regulation": 0.4}),
   ("let citizen petitions trigger committee hearings", "ST12", {"Democratic Norms": 1, "Leadership Interest": -0.4})]),
 "BO19": ("BO23", "BO20", [
   ("fund temple preservation", "ST17", {"Religious Traditionalism": 0.8, "Federal Spending": 0.4}),
   ("keep the tax exemption on temple land", "ST16", {"Religious Traditionalism": 0.7, "Taxation": -0.4}),
   ("designate temples as disaster shelters", "ST15", {"Religious Traditionalism": 0.5, "Federal Spending": 0.5})]),
 "BO20": ("BO05", "BO15", [
   ("support shrine festivals", "ST17", {"Religious Traditionalism": 0.8, "Traditional Values": 0.5}),
   ("protect shrine forests from development", "ST10", {"Environmentalism": 0.7, "Religious Traditionalism": 0.5}),
   ("list shrine grounds on the heritage register", "ST17", {"Traditional Values": 0.8, "Religious Traditionalism": 0.6})]),
 "BO21": ("BO23", "BO12", [
   ("raise care workers' wages", "ST16", {"Federal Spending": 0.8, "Regulation": 0.3}),
   ("fund home care visits", "ST17", {"Federal Spending": 0.7}),
   ("open dementia care centers in every district", "ST17", {"Federal Spending": 0.9, "Localism": 0.3})]),
 "BO22": ("BO11", "BO15", [
   ("raise veterans' pensions", "ST11", {"Militarism": 0.6, "Federal Spending": 0.6}),
   ("expand veterans' medical care", "ST11", {"Militarism": 0.5, "Federal Spending": 0.6}),
   ("give veterans hiring preference in public jobs", "ST11", {"Militarism": 0.8, "Regulation": 0.3})]),
 "BO23": ("BO21", "BO05", [
   ("cap growth in government spending", "ST16", {"Federal Spending": -1}),
   ("publish the full cost of every bill", "ST16", {"Technocratic": 0.6, "Democratic Norms": 0.4}),
   ("add sunset clauses to new spending", "ST16", {"Federal Spending": -0.8, "Technocratic": 0.3})]),
 "BO24": ("BO26", "BO05", [
   ("ease bank lending rules", "ST16", {"Regulation": -0.8, "Economic Liberalization": 0.7}),
   ("create tax-free investment accounts", "ST16", {"Taxation": -0.6, "Economic Liberalization": 0.5}),
   ("build a financial hub zone in Sapporo", "ST16", {"Economic Liberalization": 0.9, "Globalism": 0.7})]),
 "BO25": ("BO09", "BO05", [
   ("cut taxes for small businesses", "ST16", {"Taxation": -0.8}),
   ("cut paperwork for small firms", "ST17", {"Regulation": -0.7}),
   ("make large firms pay suppliers on time", "ST16", {"Regulation": 0.5, "Economic Liberalization": -0.2})]),
 "BO26": ("BO24", "BO08", [
   ("require clear price labels", "ST17", {"Regulation": 0.7}),
   ("give buyers a cooling-off period", "ST17", {"Regulation": 0.6, "Liberal Rights": 0.3}),
   ("cap bank fees", "ST16", {"Regulation": 0.8, "Economic Liberalization": -0.6})]),
 "BO27": ("BO30", "BO14", [
   ("set an affordable housing quota for new buildings", "ST15", {"Regulation": 0.6, "Federal Spending": 0.4, "Rural Focus": -0.5}),
   ("build more city parks", "ST10", {"Environmentalism": 0.6, "Rural Focus": -0.4}),
   ("cap rent rises in the cities", "ST15", {"Regulation": 0.9, "Economic Liberalization": -0.7})]),
 "BO28": ("BO15", "BO29", [
   ("restore Ainu fishing and harvest rights", "ST13", {"Ainu Enhancement": 1, "Minority Rights": 0.6}),
   ("fund Ainu community centers", "ST17", {"Ainu Enhancement": 0.8, "Federal Spending": 0.4}),
   ("require consultation with Ainu communities on land use", "ST15", {"Ainu Enhancement": 1, "Minority Rights": 0.7, "Localism": 0.3})]),
 "BO29": ("BO15", "BO28", [
   ("teach the Ainu language in schools", "ST17", {"Ainu Enhancement": 0.9, "Ethnic Pluralism": 0.5}),
   ("put Ainu names on public signs", "ST17", {"Ainu Enhancement": 0.7, "Ethnic Pluralism": 0.5}),
   ("fund Ainu-language broadcasting", "ST17", {"Ainu Enhancement": 0.9, "Federal Spending": 0.5})]),
 "BO30": ("BO27", "BO10", [
   ("keep rural bus routes running", "ST15", {"Rural Focus": 0.9, "Federal Spending": 0.5}),
   ("pay grants to families moving to rural towns", "ST17", {"Rural Focus": 0.9, "Federal Spending": 0.5}),
   ("bring broadband to every village", "ST15", {"Rural Focus": 0.8, "Post-Industrialism": 0.5, "Federal Spending": 0.6})]),
}

def name(o): return B[o]["name_en"]

def merge(tags_list):
    out = {}
    for t in tags_list:
        for k, v in t.items():
            out[k] = out.get(k, 0) + v
    return out

def tally(tags):
    tot = [0, 0, 0]; disp = {}
    for pid in PID:
        d, v, s = split(tags, pid)
        disp[pid] = d[0]  # S / O / N
        for i in range(3): tot[i] += v[i]
    return disp, tot

def bill_name(phrases):
    if len(phrases) == 2: return "A bill to %s and %s" % tuple(phrases)
    return "A bill to %s, %s and %s" % tuple(phrases)

comp_ids = {}
n = 0
rows_c, rows_b = [], []
for o, (rival, ally, comps) in ORGS.items():
    for i, c in enumerate(comps):
        n += 1; cid = "CB%02d" % n; comp_ids[(o, i)] = cid
        rows_c.append((cid, o, "XYZ"[i], c[0], CMT[c[1]], ", ".join("%s %+.1f" % kv for kv in c[2].items())))
pb = 0
for o, (rival, ally, comps) in ORGS.items():
    party_tier = B[o]["tier"] == "Party"
    for kind, idx, thr in (("Favor", [(o, 0), (o, 1)], 50), ("Flagship", [(o, 0), (o, 2), (ally, 0)], 70)):
        pb += 1
        phrases = [ORGS[k][2][i][0] for k, i in idx]
        tags = merge([ORGS[k][2][i][2] for k, i in idx])
        cids = " + ".join(comp_ids[k] for k in idx)
        gains = [name(o)] + ([name(ally)] if kind == "Flagship" else [])
        if party_tier:
            outcome = "Party Caucus decides"; lean = "own party only"
        else:
            disp, tot = tally(tags)
            outcome = "%d-%d-%d %s" % (tot[0], tot[1], tot[2], "passes" if tot[0] >= 51 else "fails")
            lean = " ".join("%s:%s" % (SHORT[p], disp[p]) for p in PID)
        rows_b.append(("PB%02d" % pb, name(o), thr, kind, bill_name(phrases), cids, ", ".join(gains), name(rival), CMT[ORGS[o][2][0][1]], lean, outcome))

print("### Component library (%d)\n" % len(rows_c))
print("| ID | Owner | Slot | Phrase | Hearing | Value tags (draft) |\n|---|---|---|---|---|---|")
for r in rows_c: print("| %s | %s | %s | %s | %s | %s |" % (r[0], r[1], r[2], r[3], r[4], r[5]))
print("\n### Patron bills (%d)\n" % len(rows_b))
print("| ID | Organization | At | Kind | Bill (assembled name) | Components | Gains | Loses | Hearing | Party lean | Default vote (Aye-Nay-Abstain) |\n|---|---|---|---|---|---|---|---|---|---|---|")
for r in rows_b: print("| %s | %s | %d | %s | %s | %s | %s | %s | %s | %s | %s |" % r)
p = sum(1 for r in rows_b if r[10].endswith("passes")); f = sum(1 for r in rows_b if r[10].endswith("fails"))
print("\nDefault result without influence: %d pass, %d fail, %d decided in caucus." % (p, f, len(rows_b) - p - f))
