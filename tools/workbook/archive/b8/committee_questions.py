"""Content 4 (2026-10-18): generic questions for every committee (five each),
shared with the committee's bill-specific copies. Run from the repo root."""
import sys, json
sys.path.insert(0, "tools/workbook")
from wbx import WB
SUITS = ['Earnest', 'Emotional', 'Appeal', 'Data Driven', 'Divisive', 'Duplicitous']
G = {
 'cost':      "S M M S W M", 'need': "S S M M M W", 'critic': "M M S M S W",
 'backer':    "M S M W M S", 'local': "M S S M M W", 'procedure': "M W M S W S",
 'risk':      "S M M S M W", 'alt': "M M S M W S",
}
# stage -> [(text, profile, theme, pleases, annoys)]
Q = {
"ST09": [
 ("Should members have to publish every gift they receive?", 'need', "Gift disclosure", "BO08; BO26; BO23", "BO17"),
 ("When a member is under investigation, who decides whether prosecutors may proceed?", 'procedure', "Investigative independence", "BO08; BO26", "BO17"),
 ("Would stronger protection for whistleblowers help this committee or hinder it?", 'alt', "Whistleblower protection", "BO08; BO09; BO26", ""),
 ("Where is the line between a courtesy and a bribe?", 'critic', "Conflicts of interest", "BO08; BO23; BO18", "BO17"),
 ("Who watches the people who watch the members?", 'risk', "Oversight of overseers", "BO08; BO23", ""),
],
"ST10": [
 ("How do we protect a river without closing the mill beside it?", 'alt', "River protection", "BO07; BO28; BO30", "BO05"),
 ("Who pays to clean up damage that was legal when it was done?", 'cost', "Cleanup costs", "BO23; BO07", "BO05"),
 ("Are wind farms worth the view they take from nearby towns?", 'local', "Wind and view", "BO16; BO30", "BO06"),
 ("What would you cut to meet an emissions target?", 'cost', "Emissions targets", "BO16; BO11; BO27", "BO05; BO10"),
 ("How should this committee weigh a rare species against a hundred jobs?", 'critic', "Wildlife and jobs", "BO28; BO30", "BO05; BO09"),
],
"ST11": [
 ("Is the defense budget buying readiness or only hardware?", 'cost', "Defense value", "BO22; BO23", "BO11"),
 ("Who answers for a mission that goes wrong?", 'procedure', "Command accountability", "BO22; BO08", ""),
 ("Should reservists train more often, and who covers their employers' costs?", 'alt', "Reserve training", "BO22; BO15; BO25", ""),
 ("What do you tell the families of those serving about the risks?", 'need', "Service families", "BO22; BO12; BO21", ""),
 ("How much should allies shape our own defense plans?", 'critic', "Allied planning", "BO22; BO05", "BO15"),
],
"ST12": [
 ("Should committees meet in public unless there is a reason to close the doors?", 'need', "Open committees", "BO08; BO18; BO26", "BO17"),
 ("Who should decide which bills reach the floor?", 'procedure', "Agenda control", "BO17; BO08", ""),
 ("Is the Assembly too slow, or is slow the point?", 'critic', "Pace of lawmaking", "BO18; BO05", ""),
 ("Should members have to read a bill before they vote on it?", 'risk', "Reading the bill", "BO18; BO23", "BO17"),
 ("How should the Assembly discipline a member who breaks its rules?", 'procedure', "Discipline of members", "BO08; BO01", "BO02"),
],
"ST13": [
 ("How can a young person afford to start a farm?", 'need', "Starting a farm", "BO10; BO30; BO15", "BO23"),
 ("Should the state set a floor under crop prices?", 'cost', "Crop price floors", "BO10; BO30", "BO23; BO26"),
 ("What happens to a village when its last farm closes?", 'local', "Village survival", "BO30; BO10; BO04", ""),
 ("Who should carry the risk of a bad harvest?", 'risk', "Harvest risk", "BO10; BO24", "BO23"),
 ("Should imported food face the same standards as local produce?", 'critic', "Food standards", "BO10; BO26", "BO05"),
],
"ST14": [
 ("How much say should a small country have when larger neighbors argue?", 'critic', "Small-state diplomacy", "BO22; BO08", ""),
 ("Should trade ever be used to punish another government?", 'risk', "Trade sanctions", "BO09; BO22", "BO05; BO25"),
 ("Who should speak for Yezo when envoys and ministers disagree?", 'procedure', "Speaking for Yezo", "BO17; BO08", ""),
 ("Are our alliances a shield or a leash?", 'alt', "Alliance value", "BO22; BO15", ""),
 ("What do we owe citizens caught in a crisis abroad?", 'need', "Citizens abroad", "BO12; BO21; BO18", ""),
],
"ST15": [
 ("Who should pay when a road project runs over budget?", 'cost', "Project overruns", "BO23; BO18", "BO05"),
 ("How do we build faster without cutting corners on safety?", 'risk', "Building safely", "BO09; BO14", "BO05"),
 ("Should big projects always go to the lowest bidder?", 'procedure', "Bidding rules", "BO23; BO25", "BO05"),
 ("What do you say to families who must move for a new dam or road?", 'need', "Resettlement", "BO12; BO06; BO03", ""),
 ("Is maintenance less glamorous than ribbon-cutting, and does that matter?", 'critic', "Maintenance first", "BO14; BO04", ""),
],
"ST16": [
 ("If you had to cut one budget line, which would it be?", 'cost', "Budget cuts", "BO23; BO24", "BO21; BO11"),
 ("Is public debt a burden or a tool?", 'critic', "Public debt", "BO24; BO23; BO16", ""),
 ("Should tax breaks come with an expiry date?", 'procedure', "Tax break limits", "BO23; BO26", "BO05"),
 ("Who benefits most when the budget is balanced?", 'need', "Balanced budgets", "BO24; BO23", "BO21"),
 ("How much should the treasury keep in reserve for emergencies?", 'risk', "Emergency reserves", "BO04; BO30; BO22", ""),
],
"ST17": [
 ("Why does a simple permit pass through so many offices?", 'procedure', "Permit delays", "BO25; BO05; BO16", ""),
 ("Should civil servants rotate posts or stay where they are?", 'alt', "Civil service rotation", "BO23; BO26", "BO17"),
 ("How do digital services reach people who avoid computers?", 'need', "Digital access", "BO21; BO12; BO04", ""),
 ("Who should audit a ministry that audits everyone else?", 'risk', "Auditing the auditors", "BO23; BO08", ""),
 ("Should local offices get more say over national rules?", 'critic', "Local flexibility", "BO04; BO03; BO30", "BO01"),
],
"ST18": [
 ("Does the Cabinet speak with one voice, or many?", 'critic', "Cabinet unity", "BO01; BO08", "BO02"),
 ("When a minister makes a mistake, who pays?", 'cost', "Ministerial responsibility", "BO08; BO18; BO23", "BO17"),
 ("How much of the Cabinet's work should the public see?", 'need', "Cabinet openness", "BO08; BO26", ""),
 ("Should ministers answer questions in the Assembly more often?", 'alt', "Question time", "BO17; BO08; BO18", ""),
 ("What does the Cabinet owe a region that voted against it?", 'local', "Governing for all", "BO04; BO18; BO30", ""),
],
"ST01": [
 ("What makes a special committee worth the trouble?", 'need', "Special committee purpose", "BO08; BO18", ""),
 ("Who should sit on a body that exists for one purpose?", 'procedure', "Special committee membership", "BO17; BO08", ""),
 ("How do you keep a special inquiry from turning into a show?", 'risk', "Inquiries as theatre", "BO08; BO23; BO18", "BO31"),
 ("Should the findings of a special committee bind anyone?", 'critic', "Binding findings", "BO17; BO23", ""),
 ("What would success look like for this committee?", 'alt', "Measuring success", "BO23; BO16", ""),
],
}
stages = json.load(open('data/stages.json'))
fam = {}
for s in stages:
    b = s.get('background_id') or s['stage_id']
    fam.setdefault(b, []).append(s['stage_id'])
w = WB('design/Game_Workbook.xlsx')
rows = w.rows('Stage Questions'); last = max(rows)
nid = max(int(v['A'][1:]) for v in rows.values() if (v.get('A') or '').startswith('S') and v['A'][1:].isdigit()) + 1
themes = {v.get('A') for v in w.rows('Question Themes').values()}
added = 0
for base, items in Q.items():
    ids = sorted(set([base] + [x for x in fam.get(base, [])]), key=lambda x: int(x[2:]))
    for text, prof, theme, pl, an in items:
        if theme not in themes:
            cells = {'A': theme, 'B': pl, 'C': "Draft 2026-10-18: committee-generic question theme (Claude's draft)."}
            if an: cells['D'] = an
            w.append_row('Question Themes', cells)
            themes.add(theme)
        row = {'A': f'S{nid}', 'B': '; '.join(ids), 'C': text, 'D': theme}
        for col, suit, g in zip('EFGHIJ', SUITS, G[prof].split()):
            row[col] = g
        w.append_row('Stage Questions', row, style_row=last)
        nid += 1; added += 1
w.save()
print('added', added)
