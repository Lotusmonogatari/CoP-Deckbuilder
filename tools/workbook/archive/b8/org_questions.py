"""Content 5 (2026-10-18): ten questions each for the ten organizations that
never reached the 60 standing a backing needs in the balance audit: four in
the Town Hall pool, three Lobbyist, three Study Session. Run from the repo root."""
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB
SUITS = ['Earnest', 'Emotional', 'Appeal', 'Data Driven', 'Divisive', 'Duplicitous']
G = {
 'cost': "S M M S W M", 'need': "S S M M M W", 'critic': "M M S M S W",
 'backer': "M S M W M S", 'local': "M S S M M W", 'procedure': "M W M S W S",
 'risk': "S M M S M W", 'alt': "M M S M W S",
}
# org: (natural suit, rival orgs, [(pool, text, profile, theme, also_pleases)])
T, L, B = 'T', 'L', 'B'
ORG = {
"BO10": ("Appeal", "BO26; BO23", [
 (T, "The co-op truck now drives forty minutes to find a buyer. What will you do about markets?", 'need', "Farm markets", ""),
 (T, "Fertilizer costs doubled my grain budget. Can anyone help?", 'cost', "Farm input costs", "BO30"),
 (T, "My children left for the city. Why would anyone stay to farm?", 'local', "Farm future", "BO30; BO15"),
 (T, "Hail took half my harvest. Who covers that?", 'risk', "Harvest losses", ""),
 (L, "Our members need shared storage and drying plants. Will you back them?", 'backer', "Shared farm facilities", "BO30"),
 (L, "Imported rice is cheaper at the store. How do farmers compete?", 'critic', "Import competition", ""),
 (L, "Will you stand with the co-ops when the budget is cut?", 'need', "Co-op support", ""),
 (B, "What does the evidence say about price floors versus direct payments?", 'procedure', "Farm support design", "BO23"),
 (B, "How should water be shared among farms in a dry year?", 'alt', "Farm water rights", "BO07"),
 (B, "Which farm subsidies actually reach small farms?", 'cost', "Subsidy targeting", "BO23"),
]),
"BO11": ("Divisive", "BO15; BO05", [
 (T, "Rents near campus keep rising. Whose side are you on, students or landlords?", 'critic', "Student housing", "BO27"),
 (T, "I will graduate owing more than I can repay. What is your answer?", 'need', "Student debt", "BO12"),
 (T, "Why should young people pay for decisions older voters made?", 'critic', "Generational fairness", ""),
 (T, "My degree is in a field with few local jobs. Where do I go?", 'local', "Graduate jobs", "BO16"),
 (L, "Our union wants a seat on the university board. Will you support it?", 'backer', "Student representation", ""),
 (L, "Will you fund campus mental health services or leave them to charity?", 'cost', "Campus wellbeing", "BO21"),
 (L, "Our members are tired of being asked for votes and ignored. What changes?", 'critic', "Youth participation", "BO18"),
 (B, "How do tuition levels compare with graduate earnings across regions?", 'procedure', "Tuition value", "BO24"),
 (B, "What would a student loan forgiveness program cost per year?", 'cost', "Loan relief", "BO23"),
 (B, "Do internships lead to jobs or only to free labor?", 'alt', "Internship rules", "BO09"),
]),
"BO12": ("Emotional", "BO05; BO25", [
 (T, "I cannot find a daycare place within an hour of home. What will you do?", 'need', "Daycare access", "BO21"),
 (T, "My child's school is closing. How do families cope?", 'local', "School closures", "BO30"),
 (T, "Both of us work and still cannot afford a home. Who is helping families like ours?", 'need', "Family housing", "BO27"),
 (T, "Who looks after my parents while I look after my children?", 'critic', "Caring for two generations", "BO21"),
 (L, "Our network wants flexible hours protected in law. Will you back it?", 'backer', "Family-friendly work", "BO09"),
 (L, "Parents are exhausted. Will you fund after-school programs?", 'cost', "After-school care", ""),
 (L, "Children's safety on the way to school is not a luxury. Will you act?", 'risk', "Safe routes to school", "BO06"),
 (B, "What does the research say about early childhood programs and later outcomes?", 'procedure', "Early childhood evidence", "BO11"),
 (B, "How do school meals affect attendance and health?", 'alt', "School meals", "BO21"),
 (B, "Which family benefits reach the households that need them most?", 'cost', "Benefit targeting", "BO23"),
]),
"BO13": ("Earnest", "BO16; BO05", [
 (T, "My family has made lacquerware for six generations. Who will buy it?", 'local', "Traditional crafts", "BO15"),
 (T, "Young people do not want to apprentice. How do we keep the craft alive?", 'need', "Craft apprenticeships", "BO11"),
 (T, "Tourists buy cheap copies made elsewhere. Can you stop that?", 'critic', "Counterfeit crafts", "BO25"),
 (T, "A good workshop needs patient customers. How do we find them?", 'alt', "Craft markets", "BO25"),
 (L, "Our guild wants a recognized quality mark. Will you support it?", 'backer', "Quality marks", "BO26"),
 (L, "Rents for workshop space have tripled. Will you protect it?", 'cost', "Workshop space", "BO27"),
 (L, "Will you fund master craftspeople to teach, not only to sell?", 'need', "Master teachers", "BO11"),
 (B, "How do craft exports compare with mass-produced goods in value per worker?", 'procedure', "Craft economics", "BO05"),
 (B, "What would a registry of traditional techniques cost and who keeps it?", 'cost', "Technique registry", "BO29"),
 (B, "Do heritage labels raise prices or only paperwork?", 'alt', "Heritage labels", "BO15"),
]),
"BO17": ("Duplicitous", "BO08; BO26", [
 (T, "Members never seem to read the bills they pass. Is that true?", 'critic', "Members and bills", "BO18"),
 (T, "Why should I trust a member who changes their mind?", 'critic', "Changing positions", "BO18"),
 (T, "What does a member actually do all week?", 'need', "A member's week", "BO18"),
 (T, "Members vote the party line. When did you last think for yourself?", 'critic', "Independent judgment", "BO01"),
 (L, "Members need staff to do the job well. Will you fund them?", 'backer', "Member staffing", "BO23"),
 (L, "Committee work gets no credit. Will you rebalance the schedule?", 'need', "Committee credit", ""),
 (L, "Members are under constant attack. Will you defend the institution?", 'risk', "Defending the Assembly", "BO08"),
 (B, "How do members' working hours compare with other legislatures?", 'procedure', "Member workload", "BO23"),
 (B, "What does research say about term length and legislative quality?", 'alt', "Term length", ""),
 (B, "Which procedural reforms would speed lawmaking without silencing members?", 'cost', "Faster procedure", "BO18"),
]),
"BO20": ("Earnest", "BO11; BO27", [
 (T, "Our shrine grove is where the neighborhood gathers. Who will protect it?", 'local', "Shrine groves", "BO06"),
 (T, "The festival needs volunteers and funds. How do we keep it going?", 'need', "Community festivals", "BO06; BO13"),
 (T, "Young people drift away from local customs. Is that a loss?", 'critic', "Community customs", "BO15"),
 (T, "Visitors fill the lanes at festival time. Who pays for the cleanup?", 'cost', "Festival crowds", "BO25"),
 (L, "Our association maintains old trees and stone paths. Will you help with the upkeep?", 'backer', "Grove upkeep", "BO30"),
 (L, "Volunteers hold this community together. Will you recognize them?", 'need', "Volunteer groups", "BO06"),
 (L, "Will you protect festival routes from new building?", 'risk', "Festival routes", "BO27"),
 (B, "How much do local festivals contribute to town economies?", 'procedure', "Festival economics", "BO25"),
 (B, "What do community volunteer groups save the public budget?", 'cost', "Volunteer value", "BO23"),
 (B, "How should heritage groves be managed against development pressure?", 'alt', "Grove management", "BO28"),
]),
"BO21": ("Emotional", "BO23; BO24", [
 (T, "My mother needs help bathing and there is no one to send. What do I do?", 'need', "Home care shortage", "BO12"),
 (T, "The care home has a long waiting list. How long must we wait?", 'local', "Care home waiting lists", "BO12"),
 (T, "Care workers are paid less than shop clerks. Is that right?", 'critic', "Care worker pay", "BO09"),
 (T, "I am old and alone. Who will look in on me?", 'need', "Isolated elders", "BO04"),
 (L, "Our staff are leaving the field. Will you raise care pay?", 'cost', "Care staffing", "BO09"),
 (L, "Families give up work to care for relatives. Will you support them?", 'backer', "Family caregivers", "BO12"),
 (L, "Will you protect care funding from budget cuts?", 'risk', "Care funding", ""),
 (B, "What are the projected care needs for the next ten years?", 'procedure', "Care demand", "BO23"),
 (B, "Do home visits cost less than hospital stays?", 'alt', "Home visit value", "BO23"),
 (B, "How could technology help carers without replacing them?", 'cost', "Care technology", "BO16"),
]),
"BO27": ("Data Driven", "BO30; BO10", [
 (T, "Buses in our district run half empty and then packed. What is the plan?", 'local', "City bus service", "BO14"),
 (T, "Apartments are small and rents high. What are you doing about housing?", 'need', "City housing", "BO11"),
 (T, "Noise from late-night bars is wearing us down. Who decides the rules?", 'procedure', "Neighborhood noise", "BO06"),
 (T, "Why do city taxes fund country roads?", 'critic', "City taxes", "BO23"),
 (L, "Our alliance wants zoning rules updated for mixed use. Will you back it?", 'backer', "Mixed-use zoning", "BO25"),
 (L, "Parks and playgrounds are being squeezed out. Will you protect them?", 'risk', "Urban green space", "BO12"),
 (L, "Will you fund bike lanes where the accident data points?", 'cost', "Bike safety", "BO14"),
 (B, "How does density relate to per-person infrastructure cost?", 'procedure', "Density costs", "BO23"),
 (B, "What does the evidence say about rent controls and supply?", 'alt', "Rent policy", "BO25"),
 (B, "Which transit investments move the most commuters per yen?", 'cost', "Transit value", "BO14"),
]),
"BO29": ("Earnest", "BO15; BO05", [
 (T, "My grandmother is the last fluent speaker in our village. How do we record her?", 'need', "Last speakers", "BO28"),
 (T, "School lessons in our language end at age twelve. Why?", 'local', "Language in schools", "BO28; BO11"),
 (T, "Place names should carry their original names. Do you agree?", 'critic', "Place names", "BO28"),
 (T, "We want our stories taught as part of the region's history. Can you help?", 'need', "Teaching local history", "BO28; BO11"),
 (L, "Our foundation wants a language archive. Will you fund it?", 'cost', "Language archives", "BO28"),
 (L, "Will you support teacher training for Ainu language instruction?", 'backer', "Language teachers", "BO28; BO11"),
 (L, "Will you support broadcasts in Ainu on public media?", 'alt', "Language broadcasts", "BO08; BO28"),
 (B, "How many speakers does each Ainu dialect have, and what is the trend?", 'procedure', "Dialect data", "BO28"),
 (B, "What have language revival programs achieved elsewhere?", 'alt', "Revival lessons", "BO28"),
 (B, "How much does a community language school cost per pupil?", 'cost', "Language school costs", "BO23"),
]),
"BO30": ("Appeal", "BO27; BO24", [
 (T, "The last bus to our village now leaves at noon. How do we get to town?", 'need', "Rural transport", "BO14; BO04"),
 (T, "Our clinic closed and the nearest doctor is an hour away. What will you do?", 'local', "Rural clinics", "BO21"),
 (T, "Young people leave and the village empties. How do we keep it alive?", 'need', "Village survival", "BO10"),
 (T, "Broadband stops at the edge of town. Is that fair?", 'critic', "Rural broadband", "BO16"),
 (L, "Our council wants relocation grants for people who move to rural areas. Will you support them?", 'backer', "Relocation grants", "BO10"),
 (L, "Will you protect rural schools from closure?", 'risk', "Rural schools", "BO12"),
 (L, "Will you fund a rural revitalization office with real staff?", 'cost', "Revitalization offices", "BO04"),
 (B, "What does the evidence say about incentives that bring workers to rural areas?", 'procedure', "Rural incentives", "BO24"),
 (B, "How do rural service costs compare with urban per resident?", 'cost', "Rural service costs", "BO23"),
 (B, "Which revitalization programs have kept their population?", 'alt', "What works rurally", "BO04"),
]),
}
# the theme names with BOxx in 'also' were typos of org ids only; keep ids.
w = WB('design/Game_Workbook.xlsx')
sheets = {T: ('Town Hall Questions', 'T'), L: ('Lobbyist Questions', 'L'), B: ('Study Session Questions', 'B')}
next_id = {}
for pool, (sheet, pre) in sheets.items():
    rows = w.rows(sheet)
    next_id[pool] = max(int(v['A'][1:]) for v in rows.values() if (v.get('A') or '').startswith(pre) and v['A'][1:].isdigit()) + 1
themes = {v.get('A') for v in w.rows('Question Themes').values()}
added = 0
for org, (nat, rivals, items) in ORG.items():
    for pool, text, prof, theme, also in items:
        sheet, pre = sheets[pool]
        g = dict(zip(SUITS, G[prof].split()))
        g[nat] = 'S'
        if list(g.values()).count('W') > 2:
            for s in SUITS:
                if g[s] == 'W': g[s] = 'M'; break
        row = {'A': f'{pre}{next_id[pool]}', 'B': text, 'C': theme}
        for col, s in zip('DEFGHI', SUITS):
            row[col] = g[s]
        w.append_row(sheet, row)
        next_id[pool] += 1; added += 1
        if theme not in themes:
            plist = [org] + [x for x in also.split('; ') if x.startswith('BO')]
            cells = {'A': theme, 'B': '; '.join(plist),
                     'C': "Draft 2026-10-18: written to give %s more ways to be pleased (Claude's draft)." % org,
                     'D': rivals}
            w.append_row('Question Themes', cells)
            themes.add(theme)
w.save()
print('added', added)
