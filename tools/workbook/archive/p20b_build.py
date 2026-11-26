#!/usr/bin/env python3
"""P20 phase B (2026-11-26, Cameron): the Text rows, How To Play entries and Rules row for the Campaign Office screens, the Donate button, the week's
end lines and the phase banners. Run once from the repo root, then python3 tools/export_data.py --accept-wording."""
import re
import sys
sys.path.insert(0, "tools/workbook")
from wbx import WB

NOTE = "P20 phase B (2026-11-26); a draft for Cameron to edit."
w = WB("design/Game_Workbook.xlsx")
texts = {
    # refusals
    "campaign.reason.in_level": "A level is in progress.",
    "campaign.reason.pick_org": "Choose an organization first.",
    "campaign.reason.not_district": "Donations are made at your district office.",
    "campaign.reason.no_funds": "Not enough Funds.",
    "campaign.reason.van_max": "The van is fully upgraded.",
    "campaign.reason.hire_blocked": "Campaign staff cannot be hired until the new year.",
    "campaign.reason.not_available": "This person is not available yet.",
    "campaign.reason.already_hired": "Already on your campaign.",
    "campaign.reason.no_capital": "Not enough campaign capital.",
    "campaign.reason.not_hired": "Not on your campaign.",
    "campaign.reason.top_tier": "Already at their highest rank.",
    # the Campaign Office screens
    "campaign.tab.actions": "Actions",
    "campaign.stat.strength": "Campaign strength",
    "campaign.stat.line": "{name}: {value}",
    "campaign.action.hours": "{hours} h",
    "campaign.action.cost_xp": "{xp} XP",
    "campaign.action.cost_fund": "{yen}円 from the campaign fund",
    "campaign.action.button": "{name} · {hours} h",
    "campaign.action.blurb_fundraise": "Telephone supporters and ask for a donation. The effort becomes campaign capital.",
    "campaign.action.blurb_letters": "Write to one organization to win its goodwill. The effort becomes campaign capital.",
    "campaign.action.blurb_mailings": "Mail every local organization and the district. The effort becomes campaign capital.",
    "campaign.action.blurb_van": "Drive the van and speak through the loudspeaker. It costs the campaign fund and a little goodwill.",
    "campaign.preview.fundraise": "Raises {yen}円 for the campaign fund.",
    "campaign.preview.letters": "Standing {delta} with the organization you choose.",
    "campaign.preview.mailings": "Standing {delta} with each local organization; District awareness {district}.",
    "campaign.preview.national": "National awareness {delta}.",
    "campaign.preview.van": "District awareness {district}; standing {penalty} with {orgs}.",
    "campaign.result.title": "Campaign action",
    "campaign.result.fund_gain": "The campaign fund gains {yen}円.",
    "campaign.result.fund_lost": "{yen}円 did not fit and was lost.",
    "campaign.result.standing": "{org}: standing {delta}.",
    "campaign.result.district": "District awareness {delta}.",
    "campaign.result.national": "National awareness {delta}.",
    "campaign.result.capital": "Campaign capital +{count}.",
    "campaign.result.continue": "Back to the Campaign Office",
    "campaign.letters.title": "Who should the letters go to?",
    "campaign.letters.row": "{org} · standing {standing}",
    "campaign.staff.intro": "Campaign staff work only for the campaign and are paid from the campaign fund. They go home after Election Day.",
    "campaign.staff.hire": "Hire",
    "campaign.staff.upgrade": "Upgrade to tier {tier}",
    "campaign.staff.cost": "{capital} campaign capital and {yen}円 from the fund",
    "campaign.staff.wage": "Wage {yen}円 a week",
    "campaign.staff.loyalty": "Loyalty: {word}",
    "campaign.staff.tier": "Tier {tier}",
    "campaign.staff.unavailable": "Not available yet.",
    "campaign.staff.chain": "Found through a Campaign Moment!",
    "campaign.van.intro": "The van carries your voice. Each tier adds to the van speech.",
    "campaign.van.buy": "Buy the van · {yen}円",
    "campaign.van.upgrade": "Upgrade the van to tier {tier} · {yen}円",
    "campaign.van.owned": "Your van: tier {tier}",
    "campaign.van.none": "You have no van yet.",
    "campaign.van.price": "{yen}円 from the campaign fund",
    "campaign.donate.title": "Donate to your campaign",
    "campaign.donate.body": "Move some of your own Funds into the campaign fund. This cannot be undone.",
    "campaign.donate.step": "{yen}円",
    "campaign.donate.done": "{yen}円 moved into the campaign fund.",
    "campaign.donate.choose": "Choose an amount.",
    # the phase bar, the Election tab, the week's end
    "campaign.phase_note.building": "{days} days to Banners of War Rising",
    "campaign.phase_note.mustering": "{days} days to the campaign · ×{sprint}",
    "campaign.phase_note.campaign": "{days} days to Sengoku no Hi",
    "campaign.phase_note.election_day": "Election Day",
    "campaign.office.phase_line": "Now: {phase}",
    "campaign.week.wages": "Campaign staff wages: {yen}円 from the campaign fund.",
    "campaign.week.missed": "{name} was not paid.",
    "campaign.week.rank_lost": "{name} lost a rank.",
    "campaign.week.quit": "{name} left the campaign.",
    "campaign.week.faded": "{count} campaign capital faded.",
    "record.cause_campaign": "Campaign",
    # the phase banners
    "campaign.phase.announcement_jp": "旗揚げ",
    "campaign.phase.mustering_jp": "出陣準備",
    "campaign.phase.campaign_jp": "選挙戦",
    "campaign.banner.announcement.kicker": "The Prime Minister speaks · {date}",
    "campaign.banner.announcement.sub": "The election is called for {election_day}. The party opens its muster today: {weeks} weeks to make your case to the Candidate Selection Committee.",
    "campaign.banner.announcement.cta": "Raise the banners",
    "campaign.banner.mustering.kicker": "{weeks} weeks · {from} to {to}",
    "campaign.banner.mustering.sub": "{actions} campaign actions a week, each worth half again as much. Campaign strength can rise up to {gain} a week.",
    "campaign.banner.mustering.cta": "To the Campaign Office",
    "campaign.banner.campaign.kicker": "{days} days · {from} to {to}",
    "campaign.banner.campaign.sub": "The committee has ruled. From today only your hours limit the campaign.",
    "campaign.banner.campaign.cta": "Into the arena",
    "campaign.banner.election_day.kicker": "{weekday} {date}",
    "campaign.banner.election_day.sub": "Election Day. The polls open at 7:00. There is nothing left to do but wait for the count.",
    "campaign.banner.election_day.cta": "Wait for the count",
    # the first-visit how-to pages
    "campaign.howto.title": "How the campaign works",
    "campaign.howto.page": "{n} of {total}",
    "campaign.howto.next": "Next",
    "campaign.howto.done": "Got it",
}
have = {c.get("A") for c in w.rows("Text").values()}
last = w.last_data_row("Text")
added = 0
for key, english in texts.items():
    if key in have:
        continue
    last += 1
    added += 1
    row = {"A": key, "B": "P20 campaign: " + key.split(".")[0] + "." + key.split(".")[1], "C": english, "E": NOTE}
    slots = sorted(set(re.findall(r"\{([a-z_]+)\}", english)))
    if slots:
        row["D"] = ", ".join(slots)
    w.append_row("Text", row, style_row=last - 1)

# How To Play: the campaign pages (body text from P20_CONTENT.md; the first visit to the Campaign Office shows them)
pages = [
    ("HT39", 190, "The campaign fund", "The Campaign Office runs on its own money: the campaign fund. Fundraising fills it, and you can donate your own Funds at the district office. Every campaign cost comes out of it."),
    ("HT40", 191, "Campaign capital", "Political Capital spent here becomes campaign capital, which counts toward your campaign strength. It fades a little each week, so keep the office busy."),
    ("HT41", 192, "Campaign actions", "Until the campaign opens you can take two campaign actions a week. Once Gladiators of War Unleashed begins, only your hours limit you."),
    ("HT42", 193, "Campaign staff", "Campaign staff work only on the campaign. They leave after Sengoku no Hi, and you can hire them again from January."),
    ("HT43", 194, "Candidate selection", "On the morning the campaign opens, the Candidate Selection Committee reads your campaign strength, how closely you have voted with the party, and your standing with the party. If it does not select you, your career ends on Sengoku no Hi."),
]
for entry_id, order, heading, body in pages:
    w.append_row("How To Play", {"A": entry_id, "B": order, "C": "The Campaign", "D": heading, "F": body})

# Rules: the donation steps (text list)
w.append_row("Rules", {"A": "campaign_donate_steps", "B": "10000;50000;100000;500000", "C": "yen amounts separated by semicolons",
                       "D": "The amounts the Donate to your campaign button offers (Funds moved into the campaign fund, one way).", "F": "P20 phase B (2026-11-26, Cameron)."})
w.save()
print("Text rows added:", added, "; How To Play entries 5; Rules row 1")
