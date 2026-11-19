# Draft office tags for the 167 visitors (for Cameron to correct)

Draft, 2026-11-19. **Nothing in the workbook or the game uses this yet.** The two-offices rules say fellow members and party people visit the Capitol and constituents belong to the District, and that Office Hours is an Either level, so the Office Hours draw will need each visitor to carry an office. There is no Location column (that comes with the two-offices build), so this is a review sheet: `visitor_office_tags.csv` has one row per visitor with a proposed office, a confidence and the reason.

## Summary

| Office | Visitors | High confidence | Medium | Low |
|---|---|---|---|---|
| District | 128 | 93 | 35 | 0 |
| Capitol | 23 | 21 | 2 | 0 |
| Either | 16 | 0 | 4 | 12 |

## Method

`make_tags.py` reads `data/visitors.json` and `data/boosters.json` and writes the CSV; run it from anywhere with `python3 -I design/proposals/visitor_office_tags_2026-11-19/make_tags.py`. Two signals:

1. **The title's words.** A party, faction, press, ministry or Assembly role points Capitol. A local trade, a place or an ordinary resident points District. A public figure with no office of their own points Either. A title with both kinds takes its last word group.
2. **Which kind of organization the visitor's reward and penalty touch.** Party organizations and Members of Parliament lean Capitol; Constituency organizations lean District; the other National organizations lean neither.

Both signals agreeing is high confidence. One signal is medium. A conflict or no signal is low and the visitor is left Either. One override from the spec: "Constituent" is always District.

## What to look at

**The 23 Capitol visitors** (party, faction, press and Assembly people). The weakest are VI23 (Company Boss) and VI65 (Parliamentary Liaison), both medium.

**The 16 Either visitors**, mostly the low-confidence ones where the title and the organizations disagree, and the lobbyists (a lobbyist meeting is an Either room):

| Visitor | Name | Title | Proposed | Confidence |
|---|---|---|---|---|
| VI04 | Ryo Kawabata | Union Representative | Either | low |
| VI11 | Lele Aoyama | Startup Founder | Either | medium |
| VI16 | Yuki Kirishima | Celebrity | Either | medium |
| VI20 | Akemi Ito | University Professor | Either | low |
| VI22 | Brad Chunchun | Celebrity | Either | medium |
| VI43 | Eri Shiratori | Regional Newsreader | Either | medium |
| VI44 | Katsu Mizuhara | Campaign Treasurer | Either | low |
| VI59 | Jun Ogasawara | Party Branch Secretary | Either | low |
| VI61 | Atanemat Masanori | Turnip Cooperative Advisor | Either | low |
| VI67 | Riichi Fukuda | Kita Corporate Group Lobbyist | Either | low |
| VI68 | Ushio Hamano | Tsugaru Strait Fisheries Lobbyist | Either | low |
| VI69 | Tsutomu Chikaraishi | Cross Strait Labor Union Lobbyist | Either | low |
| VI71 | Minoru Minoda | Ringo and Rice United Lobbyist | Either | low |
| VI74 | Takumi Ezono | Yezo Artisans Guild Publicist | Either | low |
| VI81 | Takashi Hamada | Yezo Festivals Committee Member | Either | low |
| VI104 | Misao Ogawa | Snow Festival Treasurer | Either | low |

**Medium-confidence District visitors** (35) are mostly people whose title says little ("Pharmacist", "Librarian") but whose organizations are local. They are the ones most likely to need a correction; the CSV's `reason` column says why each was tagged.

## Open questions

1. **Is Office Hours at the Capitol only members and party people, and at the District only constituents?** Or should some visitors (the lobbyists, the celebrities) appear at both? The draft leaves 16 Either.
2. **Visitors tied to a bill** appear first in that bill's Office Hours, which is a Capitol level, so a District visitor tied to a bill would be drawn at the Capitol. Does the bill's visitor keep their own office, or follow the bill?
3. **Who is Capitol, who is District among the organization spokespeople** (VI60 to VI80, such as "Sirur Council Envoy" or "Veterans' Association Representative")? Their organizations lean District, but they speak for national bodies.
