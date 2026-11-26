#!/usr/bin/env python3
"""P20 phase A (2026-11-26, Cameron): the workbook half of the election and campaign work. Adds the Election Cycles and Campaign Staff tabs, venue
VN10 (Campaign Office) and its four activities (CM01 to CM04, renamed from the prompt's CA01 to CA04, which clash with Area Characters), the new
Decision Scenes and Event Choices columns, the Balance and Rules rows, and the Text rows of design/proposals/P20_CONTENT.md section 4.
Run once from the repo root, then python3 tools/export_data.py --accept-wording."""
import re
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB, add_sheet, n2col, col2n

PATH = "design/Game_Workbook.xlsx"
NOTE = "Cameron 2026-11-25 (P20 election and campaign); a draft for Cameron to edit."

# --- New tabs ---------------------------------------------------------------------------------------------------------------------
add_sheet(PATH, "Election Cycles", ["Cycle ID", "Banners Date", "Campaign Open Date", "Election Day", "Player Runs", "Note"],
          [["EC01", "21.10.11", "21.11.30", "21.12.12", "Y", "The first election the player stands in."],
           ["EC02", "24.10.07", "24.11.26", "24.12.08", "Y", ""],
           ["EC03", "27.10.11", "27.11.30", "27.12.12", "N", "The player steps aside; the run ends on this Election Day."]],
          [10, 14, 20, 14, 12, 50])
roles = {"office": "A volunteer from the party office", "chain": "Found through a Campaign Moment!"}
draft = "DRAFT: placeholder name, biography and role line; Cameron will rename."
staff_rows = [
    ["CS01", "Campaign Organizer", "Hiroto Ban", "", "", 0, 1, "A campaign organizer.", "Runs the campaign's volunteers and its schedule.", "", "", "", "", "", "office", draft],
    ["CS02", "Campaign Organizer", "Dan Bronco", "", "", 0, 2, "A campaign organizer.", "Runs the campaign's volunteers and its schedule.", "", "", "", "", "", "chain", draft],
    ["CS03", "Campaign Fundraiser", "Ren Fusenji", "", "", 0, 1, "A campaign fundraiser.", "Raises the money the campaign runs on.", "", "", "", "", "", "office", draft],
    ["CS04", "Campaign Fundraiser", "Umina Kota", "", "", 0, 2, "A campaign fundraiser.", "Raises the money the campaign runs on.", "", "", "", "", "", "chain", draft],
    ["CS05", "Campaign Van Announcer", "Hitomi Ota", "", "", 0, 1, "A campaign van announcer.", "Speaks for the campaign from the van.", "", "", "", "", "", "office", draft],
    ["CS06", "Campaign Van Announcer", "Yuina Chanami", "", "", 0, 2, "A campaign van announcer.", "Speaks for the campaign from the van.", "", "", "", "", "", "chain", draft],
]
add_sheet(PATH, "Campaign Staff",
          ["Staff ID", "Staff Role", "Name", "Name JP", "Romaji", "Starting Tier for Staff Role", "Highest Upgradable Tier for Staff Role", "Biography",
           "Role Flavor Text", "Gift Likes", "Gift Dislikes", "Gift Like Loyalty", "Gift Neutral Loyalty", "Gift Dislike Loyalty", "Available", "Note"],
          staff_rows, [10, 24, 18, 12, 12, 14, 14, 30, 40, 12, 12, 10, 10, 10, 11, 50])

w = WB(PATH)


def add_header(sheet, names):
    head = w.rows(sheet)[1]
    last = sorted(head, key=lambda c: (len(c), c))[-1]
    style = w.sty(sheet, last + "1")
    at = col2n(last)
    for name in names:
        at += 1
        w.set_cell(sheet, 1, n2col(at), name, style=style)


# --- Venue VN10 and its activities --------------------------------------------------------------------------------------------------
w.append_row("Venues", {"A": "VN10", "B": "Campaign Office", "C": "選挙事務所", "D": "Senkyo Jimusho", "E": "District", "F": 10,
                        "G": "VEN_CAMPAIGN_OFFICE", "H": "AREA_CAMPAIGN_OFFICE",
                        "I": "A folding table, a telephone and a stack of blank banners.", "J": "Any", "K": "scene"})
for aid, kind, name, icon in (("CM01", "campaign_fundraise", "Fundraising calls", "ACT_CAMPAIGN_FUNDRAISE"),
                              ("CM02", "campaign_letters", "Outreach letters", "ACT_CAMPAIGN_LETTERS"),
                              ("CM03", "campaign_mailings", "Mailings to local organizations", "ACT_CAMPAIGN_MAILINGS"),
                              ("CM04", "campaign_van", "Campaign van speech", "ACT_CAMPAIGN_VAN")):
    w.append_row("Venue Activities", {"A": aid, "B": "VN10", "C": kind, "D": name, "E": icon})

# --- New columns on Decision Scenes and Event Choices ------------------------------------------------------------------------------
add_header("Decision Scenes", ["Card", "Weight", "Weight Late", "Repeat", "Cooldown Weeks", "Phase", "Needs"])
add_header("Event Choices", ["Campaign Fund Delta", "Donate Funds", "Lend Campaign Staff Weeks", "Favor Owed", "Needs"])

# --- Balance rows ------------------------------------------------------------------------------------------------------------------
balance = [
    ("election_capital_target", 3000, "Campaign capital that earns the full Capital points of campaign strength (replaces the Experience Target)."),
    ("election_capital_fade_percent", 5, "Percent of campaign capital that fades at each week's end (whole numbers, rounded down)."),
    ("election_war_chest_limit", 100000000, "The campaign fund's ceiling; income above it is lost and the screen says so."),
    ("election_gain_per_week_mustering", 6, "Most campaign strength can rise in a week during Mustering the War Campaign (the usual limit is Election: Gain Per Week)."),
    ("difficulty_relaxed_election_gain_per_week_mustering", 7, "Relaxed tier: the Mustering weekly rise limit."),
    ("difficulty_harder_election_gain_per_week_mustering", 5, "Harder tier: the Mustering weekly rise limit."),
    ("campaign_sprint_multiplier", 1.5, "Rewards (not costs) of campaign actions are multiplied by this during Mustering."),
    ("campaign_actions_per_week", 2, "Campaign actions the player may take a week during the building and mustering phases; no limit during the campaign."),
    ("campaign_action_hours", 4, "Hours one campaign action takes."),
    ("campaign_action_hours_with_organizer", 2, "Hours for letters and mailings with a Campaign Organizer hired and present."),
    ("campaign_fundraise_xp", 100, "Political Capital (XP) one round of Fundraising calls costs; it becomes campaign capital."),
    ("campaign_fundraise_yield", 40000, "Campaign fund raised by one round of Fundraising calls, before the Fundraiser multiplier."),
    ("campaign_letters_xp", 60, "Political Capital one round of Outreach letters costs."),
    ("campaign_letters_standing", 3, "Standing with the one organization the letters go to."),
    ("campaign_mailings_xp", 200, "Political Capital one round of Mailings costs."),
    ("campaign_mailings_standing", 1, "Standing with every organization of tier Constituency."),
    ("campaign_mailings_district", 1, "District awareness the mailings add."),
    ("campaign_van_speech_cost", 20000, "Campaign fund one van speech costs."),
    ("campaign_van_speech_district", 2, "District awareness a van speech adds."),
    ("campaign_van_speech_penalty", 2, "Standing a van speech costs with each organization named in Rules: campaign_van_speech_penalty_orgs."),
    ("campaign_van_tier_0_cost", 500000, "Campaign fund the van costs."),
    ("campaign_van_tier_1_cost", 1500000, "Campaign fund to upgrade the van to tier 1 (van speech penalties halved)."),
    ("campaign_van_tier_2_cost", 3000000, "Campaign fund to upgrade the van to tier 2 (van speech rewards doubled)."),
    ("campaign_staff_hire_capital", 150, "Campaign capital to hire a campaign staff member; each upgrade costs double the step before."),
    ("campaign_staff_hire_yen", 300000, "Campaign fund to hire a campaign staff member; each upgrade costs double the step before."),
    ("campaign_fundraiser_multiplier_tier_0", 2, "Fundraising yield multiplier with a tier 0 Campaign Fundraiser."),
    ("campaign_fundraiser_multiplier_tier_1", 4, "Fundraising yield multiplier with a tier 1 Campaign Fundraiser."),
    ("campaign_fundraiser_multiplier_tier_2", 8, "Fundraising yield multiplier with a tier 2 Campaign Fundraiser."),
    ("campaign_organizer_letters_bonus", 1, "Flat standing a tier 1 or higher Campaign Organizer adds to letters."),
    ("campaign_organizer_mailings_national", 1, "National awareness a tier 2 Campaign Organizer adds to mailings."),
    ("campaign_announcer_voters_bonus", 1, "Flat standing with Constituency Voters (BO18) a tier 1 or higher Van Announcer adds to a van speech."),
    ("campaign_announcer_district_bonus", 1, "District awareness a tier 2 Van Announcer adds to a van speech."),
    ("selection_weight_strength", 50, "Percent of the selection score that comes from campaign strength."),
    ("selection_weight_alignment", 25, "Percent of the selection score that comes from party alignment."),
    ("selection_weight_influence", 25, "Percent of the selection score that comes from standing with the party (Party support and the Selection Committee)."),
    ("selection_threshold_list", 40, "Selection score at which the player is selected for the Proportional List."),
    ("selection_threshold_smd", 60, "Selection score at which the player is selected for their Single-Member District."),
    ("selection_threshold_safety_net", 75, "Selection score at which the player is selected for the district with a list place as a safety net."),
    ("campaign_moments_per_week_building", 1, "Campaign Moments! that may open in a week while the election is still far off."),
    ("campaign_moments_per_week_late", 2, "Campaign Moments! that may open in a week during mustering and the campaign."),
    ("poll_every_weeks_building", 4, "Weeks between polls while the election is still far off."),
    ("poll_every_weeks_late", 2, "Weeks between polls during mustering and the campaign."),
    ("poll_margin_building", 8, "Points either side of the true campaign strength a building-phase poll reports."),
    ("poll_margin_mustering", 5, "Poll margin during mustering."),
    ("poll_margin_campaign", 3, "Poll margin during the campaign."),
    ("poll_margin_final", 2, "Poll margin of the final poll before Election Day."),
]
for key, value, note in balance:
    label = key.replace("_", " ").title().replace("Xp", "XP")
    w.append_row("Balance", {"A": label, "B": value, "C": NOTE + " " + note})
# The war chest now reads the campaign fund; its target is raised to match (was Funds, 500,000).
row = w.find_row("Balance", "Election: War Chest Target")
w.set_cell("Balance", row, "B", 25000000)
w.set_cell("Balance", row, "C", "P20 (2026-11-25, Cameron). Campaign fund that earns the full War Chest points (was 500,000 of Funds). The fund can hold up to Election War Chest Limit.")
row = w.find_row("Balance", "Election: Max Experience")
w.set_cell("Balance", row, "C", "Draft 2026-10-23, P20 2026-11-25. Points when campaign capital reaches the Capital Target. (The row keeps its old name; renaming a Balance key needs Cameron's say-so.)")
# The old Experience Target is read by nothing now.
w.delete_row("Balance", w.find_row("Balance", "Election: Experience Target"))

# --- Rules rows (text values) ------------------------------------------------------------------------------------------------------
w.append_row("Rules", {"A": "campaign_van_speech_penalty_orgs", "B": "BO18;BO25", "C": "organization IDs separated by semicolons",
                       "D": "Which organizations a van speech costs standing with (Constituency Voters and the Small Business Owners' Association).", "F": "P20 (2026-11-25, Cameron)."})
w.append_row("Rules", {"A": "campaign_office_open_date", "B": "18.11.01", "C": "a date, YY.MM.DD",
                       "D": "The day the Campaign Office opens (DS11 opens it). Used by tests and the how-to-play, not by the rules.", "F": "P20 (2026-11-25, Cameron)."})

# --- Text rows (P20_CONTENT.md section 4) --------------------------------------------------------------------------------------------
content = open("design/proposals/P20_CONTENT.md", encoding="utf-8").read().split("## 4. Text rows")[1]
texts = []
for line in content.splitlines():
    m = re.match(r"^\| `([a-z0-9_.]+)` \| (.*) \|$", line)
    if m:
        texts.append((m.group(1), m.group(2).strip()))
last = w.last_data_row("Text")
for key, english in texts:
    last += 1
    slots = sorted(set(re.findall(r"\{([a-z_]+)\}", english)))
    row = {"A": key, "B": "P20 campaign: " + key.split(".")[0], "C": english, "E": NOTE}
    if slots:
        row["D"] = ", ".join(slots)
    w.append_row("Text", row, style_row=last - 1)
w.save()
print("Election Cycles 3, Campaign Staff 6, VN10, CM01-04,", len(balance), "Balance rows,", len(texts), "Text rows")
