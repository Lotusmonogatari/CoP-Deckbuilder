# Hosted events with guests: the walking tour and the dinner (2026-10-23), waiting for approval

Your spec, as I read it: the two purchasable items (**SH20 Host a District Walking Tour for a Constituency Booster** and **SH19 Host a Dinner for a National Booster**) become three-decision events. The player chooses which organization to patronize, a roster of guests from existing characters attends, each decision draws visible guest reactions, and the resulting bonuses and penalties **replace** the two items' current flat rewards (+1 and +2 standing).

This is about 450 lines of new code plus four new workbook tabs of content, so it needs your approval before I build. Nothing below is built.

## Executive summary

| Question | Answer |
|---|---|
| Is it one framework or two? | **One.** A hosted event is three screens of choices, each followed by guest reactions. The tour and the dinner differ only in their first screen and data. A future rally or press lunch can reuse it. |
| What changes in the game | SH19 and SH20 keep their prices, hours (4) and the "pick an organization" step, but instead of a flat +2 / +1 they open the event. My earlier EV01 (walking tour) and EV02 (charity dinner) events are retired. |
| Where do guest reactions come from | **Tags.** Every option (a menu dish, a site, a policy topic, a commitment) carries tags, and each organization has likes and dislikes by tag. No per-guest-per-option table to write. |
| Who are the guests | Existing characters whose organization fits. See the roster problem below. |
| Biggest risk | Content volume (about 12 sites and dishes, 10 topics, 10 commitments, a taste list for 32 organizations) and the guest roster for organizations with no characters yet. |

## The flow

| Screen | Walking tour | Dinner | Guest reaction |
|---|---|---|---|
| 0. Setup | Choose the organization to patronize (the existing step) | Same | n/a |
| 1. What to do | Where to go: a shrine, an agricultural site, a manufacturing plant, the shotengai, a neighborhood | Three dishes: an entree, a drink and a side, each from a menu (local produce, foreign wine, Japanese tuna, Hakodate scallops, Aomori apple juice, ...) | Each guest reacts to the choice from their organization's tastes. A farm co-op guest served French wine or Australian beef reacts badly |
| 2. A policy topic | Choose a topic to talk about (topics mirror the organizations: farm prices, tax, tourism, ...) | Same | Guests react by their organizations' stance on the topic |
| 3. A modest commitment | Cut business taxes, invest Yezo finances in a crypto Yen, pull out of alliances, join more trade agreements, ... | Same | Guests react |

## How reactions are scored (draft)

| Piece | Rule |
|---|---|
| Tags | Each option has two or three tags, for example "Australian beef: foreign, meat, luxury". Each organization has a short list of tags it likes (+) and dislikes (-). |
| A guest's reaction | Sum of the guest's organization's scores for the option's tags, clamped to -2 to +2, shown as one of five lines ("nods warmly", "frowns", ...) |
| Result of a screen | The guests' own organizations move by +1 / 0 / -1 per reaction. The patronized organization counts double. |
| Whole event | Also moves District Awareness (tour) or National Awareness (dinner) by the number of positive reactions, and gives a small Reputation or Party support effect from the commitment. The totals appear on the result screen as organization chips. |

All of these are Balance levers, so you can retune them.

## The guest roster problem

Your rule: guests pulled from existing characters appropriate for the organization. In the data, characters by affiliation are uneven:

| Organization group | Characters listed under it |
|---|---|
| BO17 Members of Parliament | 101 |
| BO08 National Media | 8 |
| BO11 Students United, BO18 Constituency Voters | 3 each |
| BO06 Neighborhood Associations | 2 |
| One each | BO03, BO04, BO05, BO07, BO09, BO10, BO12, BO15 |
| **None** | 17 organizations, including BO13 to BO16 and BO19 to BO32 |

Visitors help: the 94 Office Hours visitors each name the organizations they please, so most organizations have two to five visitors tied to them (BO05 has eight, BO21 five). **Proposed roster rule:** up to five guests, taking characters affiliated with the chosen organization first, then visitors who reward it, then characters from its allied organizations (the Standing Links and Party Stakeholders tabs already say who is allied). Anyone with a title but no name shows as the title, as elsewhere.

## New workbook tabs (a schema change; please confirm)

| Tab | Rows | Holds |
|---|---|---|
| Hosted Events | 2 | The two events: which item starts it, hours, awareness meter, screen titles and heading text |
| Event Options | about 45 | Every option on every screen: event, screen, choice text, tags, flavor line |
| Organization Tastes | about 32 x 4 | For each organization, tags it likes and dislikes |
| Reaction Lines | about 25 | The five reaction levels, several wordings each, so a roster does not repeat itself |

## What I would build, in steps

| Step | Build | Size |
|---|---|---|
| 1 | The four tabs, exporter checks, header notes, and draft content (Claude drafts, you rewrite) | workbook |
| 2 | `HostedEvent.gd` (pure): roster pick, tag scoring, screen results, totals | about 200 lines |
| 3 | The three screens inside the Office (reusing the event panel), the guest list with portraits, result with chips | about 200 lines |
| 4 | Wire SH19 and SH20 to open it; retire EV01 and EV02; tests; a real-click test | about 60 lines |

## Questions for you

| # | Question | My default |
|---|---|---|
| 1 | Tags (reactions computed from an organization's likes and dislikes) rather than hand-writing every guest against every option? | Tags |
| 2 | Keep the items' prices (SH19: 20 XP and 20,000円, SH20: 10 XP and 10,000円) and make each take 4 hours? | Yes |
| 3 | Retire my EV01 walking tour and EV02 charity dinner events, since these replace them? | Yes |
| 4 | Are visitors and allied organizations' characters acceptable guests when the organization has none of its own? | Yes |
| 5 | Should the commitment have a lasting effect (for example a small standing change with every organization the commitment touches) or only the result of this event? | Result of this event only |
| 6 | Roster size: up to 5 guests? | 5 |
| 7 | Should a bad dinner (many negative reactions) cost anything beyond lost standing (for example Reputation)? | Small Reputation loss only on a clearly bad event |
