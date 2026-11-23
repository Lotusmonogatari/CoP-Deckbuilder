# Capitol venues: rules, style guide and writing guidelines for chatter, hints and tips

2026-11-23 · for Cameron · all lines are Claude's drafts for you to rewrite. This copy shows the game as it stands on `feature/p16-venue-wording`, so it includes the eight wording suggestions that are still waiting in the claude.ai doc (https://claude.ai/artifact/9DUGwYWHrhiNC9GU3BRfDy).

**Revised 2026-11-23 with Cameron's decisions:** weekend visits and the hours a venue needs; hint rows fill tip slots; the tip cap is meant to bind before the 14 days; committees and ministries may appear in gossip; absolutes allowed when they read as color; the six suit phrases; American spelling throughout.

## Summary

Capitol venues give the player free gossip, and now and then a rhetoric tip, for one work hour a visit. The Cafeteria and the Gardens deal the lines; the Speech Coach opens Rhetoric Training. This guide collects the rules as built, the style guide for chatter, and the guidelines for hints and tips.

| Number | Value | Rules row |
| --- | --- | --- |
| Lines dealt per venue per day | 12 | `venue_daily_set` |
| Lines a player can hear per venue per day | 8, then one dry line | `venue_daily_heard` |
| Share of dealt lines that are tips | 1 in 8 | `venue_hint_share` (stored as 8) |
| Tips held at once | 10 | `tips_max_held` |
| Days a tip lasts | 14 | `tips_days` |
| Cost of a visit | 1 hour (Cafeteria, Gardens) | Venue Activities, Hours |
| Walking to a venue | 0 hours | `venue_walk_hours_building`, `venue_walk_hours_area` |

## The rules as built

The player steps out from the Capitol office, hears up to 8 of the day's 12 lines for one hour, then gets a dry line and "Come back tomorrow".

**Where and when**

- **Step out** shows on the Office at the Capitol office only. It is hidden at the District office, and grayed with its reason during a level or when the player has no hours left: work hours on a weekday, weekend hours on a weekend.
- Walking is free: Office to Capitol Building to Capital Area costs 0 hours (two Rules rows, so you can change them).
- Every venue is open every day, weekends included. On a weekend the player can step out and walk while they have weekend hours; walking still costs nothing.
- **An activity that costs hours needs those hours left.** Eat with Colleagues and People Watching (1 hour) are grayed with their reason when the player has no hours remaining, on a weekday or a weekend. On a weekend the hour comes from weekend hours.
- Built now: Cafeteria (VN01), Capitol Gardens (VN03), Speech Coach (VN04). Grayed "Coming soon": National Assembly Library (VN02), Sapporo Stage (VN05), Sapporo Super Station (VN06).

**The daily set**

- Each line-giving venue deals **12 lines** the first time it is asked on a day, from the lines eligible that day, and keeps them. The deal is seeded by the run, the day and the venue, so a reload never reshuffles it.
- A line is eligible when its condition holds and it is inside its On Date, Date From / Date To, Seasons and After Law cells. A blank cell means any time. A line with Once = Y never comes back after it was heard.
- A line written for today (On Date) is always in the set. Weight raises a line's chance.
- About **1 in 8** slots is a rhetoric tip. **The venue's hint rows fill tip slots**: the game draws one eligible hint row from that venue's pool (by its gates and Weight), and the row sets the kind (`stage_suit` or `opponent_suit`) and, if filled, the target. The words come from the `hint.*` Text rows. Hint rows are never dealt as ordinary lines. A tip slot with no eligible hint row, target or phrasing becomes an ordinary line.

**Hearing**

- One visit (Eat with Colleagues, People Watching) costs its **1 hour once**. Inside it, **Keep listening** reveals the next line free, up to **8** a day.
- After the 8th line, Keep listening shows **one dry line** (the `dry` pool) and is then grayed: "Come back tomorrow".
- A new visit that day is refused without taking the hour. A visit with no hours left is refused the same way (see Where and when). The next day deals a fresh set.
- Eating or watching never changes any number: lines are gossip only (the pop-up says so).

## Rhetoric tips

A tip tells the player which argument style a stage or an opponent responds to. It is built from data, never invented: nothing is written in a line that the data does not support.

| Kind | What it says | Where the suit comes from |
| --- | --- | --- |
| Stage tip | The audience responds to [type of rhetoric linked to the suit] rhetoric. | The stage's Favored Suit. A stage with no Favored Suit is never a target. |
| Opponent tip | This person responds to [type of rhetoric linked to the suit] rhetoric. | The opponent's lead suit, `suit_1`. |

**Which targets are eligible.** Only stages and people in levels **on offer at the Capitol this week** (the same filters as the Levels list), plus the next unanswered Decision! scene's speakers and stage. A hint about something the player cannot reach is never dealt.

**The words.** The game picks a random Text row for the kind and suit: `hint.stage_suit.<suit>_<n>` with `{stage}`, or `hint.opponent_suit.<suit>_<n>` with `{name}`. Suits are written in lower case: earnest, emotional, appeal, data_driven, divisive, duplicitous. The sentence ends in a natural phrase for the suit, never the bare suit name and never "rhetoric of [suit]" (Text rows `tips.rhetoric_<suit>`):

| Suit key | `tips.rhetoric_<suit>` | Reads as |
| --- | --- | --- |
| earnest | earnest rhetoric | "…responds to earnest rhetoric" |
| emotional | emotive rhetoric | "…responds to emotive rhetoric" |
| appeal | appealing rhetoric | "…responds to appealing rhetoric" |
| data_driven | logical rhetoric and data | "…responds to logical rhetoric and data" |
| divisive | divisive rhetoric | "…responds to divisive rhetoric" |
| duplicitous | double-speak | "…responds to double-speak" |

**Holding tips**

| Rule | Detail |
| --- | --- |
| Most held | 10. A new tip replaces the oldest. |
| Same target again | Hearing a tip about a target already held refreshes its 14 days instead of adding a copy. A stage and a person never count as the same target. |
| Lifetime | 14 days on the game calendar. 14 days left on the day it was heard; "Last day" on the 14th; gone on the 15th. |
| Saved with the run | Old saves load with no tips. |
| Which limit binds | By design, the 10-tip cap usually ends a tip before its 14 days. A player who visits both venues on most days hears about one tip per venue a day, so the oldest is replaced after roughly a week. The 14 days matter for a player who visits rarely. |

## Where tips show

A tip appears in five places, from the moment it is heard to the briefing of the level it concerns.

| Place | What the player sees |
| --- | --- |
| The tip box | In the line pop-up when heard: "RHETORIC TIP · HEARD IN THE CAFETERIA" (or "OVERHEARD IN THE GARDENS"), then the sentence with the suit's phrase: "The audience in the {stage} responds to logical rhetoric and data" for a stage, "{name} responds to appealing rhetoric" for a person, and what saving it does. |
| Tips button | On the Levels list, under the hours line, with a count of the tips held. |
| Tips you hold | A pop-up: each tip's target, suit chip, where it was heard and days left ("Last day" in red), with the rule line (14 days, 10 tips) at the top. |
| Level badge | A level with a tipped room says "1 tip" (or "N tips") on its row. |
| Briefing mark | Under a tipped room: "Responds to logical rhetoric and data · heard in the Cafeteria". |

**Opponent tips are marked where the person can appear, not where they certainly will.** The briefing and the fight draw their opponents separately, so a tip about a person shows under every room they can be seated in, worded as a condition ("If {name} is seated here, they respond to logical rhetoric and data"). A stage tip is certain and says so plainly.

**"You overhear…" is not added automatically** (Cameron, 2026-11-23). It is not a lead on every line or on every tip. A writer who wants it puts it in the line's own words.

## Style guide for venue chatter

Chatter is dry, observational and short: one or two sentences the player can read at a glance and smile at.

**Form**

- 8 to 25 words, one or two sentences. No exclamation marks, no emoji. American spelling, dates YY.MM.DD.
- The Cafeteria is gossip and ministry life (topics: gossip, law, time, party). The Gardens is people watching (topic: watch): what the speaker sees from the fountain.
- An attributed line is the quoted sentence; the screen adds "— Name", the party color and the title. Narration has no speaker: leave Speaker blank. `colleague` is an unnamed member.

**Voice.** The speaker's lead suit sets the tone and their party's position sets the subject.

| Lead suit | Tone | Example register |
| --- | --- | --- |
| Earnest | Plain and direct | A straight remark with no spin. |
| Emotional | Personal | A feeling or a person, not a figure. |
| Appeal | Rallying | "We" language, belonging, a favor. |
| Data Driven | A figure | A number, a count, a chart. |
| Divisive | Needling | A jab at the other side. |
| Duplicitous | A wink | Says one thing and implies another. |

A governing-party speaker talks about the coalition and the ministries. An opposition speaker talks about its cracks.

**What a line may name**

- No bill, stage or company in plain gossip. A bill or stage appears only in a law line (After Law) or a hint.
- Committees and ministries are allowed in plain gossip, with their canon names. Committees are "Committee on X" and ministries "Ministry of X", with the canon names ("Committee on the Environment", never "the Environment committee"). A test fails the build otherwise.
- Protagonists (OP06, OP22, OP35, OP40) never speak. Characters never mention game machinery: levels, stages, turns, energy, numbers.
- A line about a moment fills its gate: On Date for one day, Date From / Date To for a stretch, Seasons for the time of year, After Law (`BIxx passed` or `BIxx failed`) for an aftermath. A line that is only true then must not float free.

**The dry pool** is 20 lines that say nothing new ("Nothing here you haven't heard already."). They carry no gates and no names, and they must read well once, after eight real lines.

**"You overhear…"** is optional wording inside a line, never an automatic lead.

**Status.** Every line is a draft; the Note (tone) column records the speaker's party, role and lead suit.

## Guidelines for hints and tips

A hint is a tilt, never a promise: it says what a room or a person leans toward, in the voice of someone who has watched them.

1. **Keep the token.** A stage hint holds `{stage}`, an opponent hint holds `{name}`. The exporter refuses a hint row that loses it.
2. **Never name the suit.** The phrasing carries the feeling ("they want sincerity, not theater"), not the word "Earnest". The sentence around it names the style with its suit phrase.
3. **Never promise an outcome.** Say what they like, what they respect, what they ignore. Avoid wording that predicts a result: "will", "always wins", "guaranteed", numbers or odds. An absolute that reads as color about a person or a room is fine: "{name} always has a second reason", "They don't hear anything without a chart". The test: does it describe a habit (allowed) or promise a win (not allowed)?
4. **Write at least three phrasings per suit per kind**, so a player who hears several tips does not hear the same sentence twice. Today: 3 or 4 each, 20 stage and 20 opponent.
5. **Stay in the world.** No game words (suit, stage, card, bar, energy). The stage's own name is the only machinery the sentence may carry, through `{stage}`.
6. **Make the suit's meaning audible.**

| Suit | What it answers to | Suit phrase | A current phrasing |
| --- | --- | --- | --- |
| Earnest | Accountability, a plain commitment | earnest rhetoric | "In the {stage}, they want sincerity, not theater." |
| Emotional | People and harm | emotive rhetoric | "{name} melts for a good story. Bring a story." |
| Appeal | Unity, belonging, favors | appealing rhetoric | "In the {stage}, they like to be told they matter. Tell them." |
| Data Driven | Cost, evidence, yes or no | logical rhetoric and data | "The {stage}? Bring charts. They don't hear anything without a chart." |
| Divisive | Loyalty, sides, in-group and out-group | divisive rhetoric | "In the {stage}, they like a fight. Pick a side, and pick it loudly." |
| Duplicitous | Deflection, the smart dodge | double-speak | "{name} always has a second reason. Find it." |

**Suit wording (Cameron, 2026-11-23).** Each tip's sentence ends in its suit phrase, never the bare suit name (Text rows `tips.rhetoric_<suit>`): appealing rhetoric, divisive rhetoric, earnest rhetoric, emotive rhetoric, logical rhetoric and data, double-speak. "Appealing rhetoric" stays: it reads naturally. Never use "rhetoric of [suit]"; it sounds unnatural.

**Phrasing review (2026-11-23).** Eleven phrasings were reworded: no past events ("last session", "once changed a vote"), no invented facts about named people ("half the committee are former accountants"), and the people in the room, not the stage, do the liking and deciding, so a stage called a TV debate or a press conference still reads right.

**Hint rows.** Each venue's hint rows (Topic `hint`, Hint Kind filled, Text blank) are what fill its tip slots. Add a hint row to give a venue more tips of a kind, raise its Weight to favor that kind, or gate it by date, season or law like any line. A venue with no eligible hint row deals no tips that day.

**Targets.** Leave Hint Target blank so the game picks an eligible stage or person each time. Name a target only when a line is about one specific place, and then it must be a stage with a Favored Suit or a real opponent.

**Who says it.** A hint row has no speaker of its own. The Cafeteria shows it as a colleague's remark; the Gardens as something overheard. Wording that needs an "overhear" frame writes it into the phrasing itself.

**Fairness.** The suit comes from data (Favored Suit, lead suit), so a tip is true to the game by construction. Do not write a Hint Target whose data does not match what the phrasing implies.

## Workbook reference

Three tabs hold the content, seven Rules rows hold the numbers, and Text rows hold every sentence the screens say.

| Tab | Rows now | Columns |
| --- | --- | --- |
| Venues (IDs VN) | 6 | Venue ID, Name, Name JP, Romaji, Zone (Capitol Building or Capital Area), Order, Icon, Background, Blurb, Open Days (Any), Unlock (not used yet) |
| Venue Activities (VA) | 6 | Activity ID, Venue ID, Kind (chat, read, watch, train, show, travel), Name, Icon, Pool, Hours, Funds, XP, Per Day, Per Week, Condition Type / Target / Op / Value |
| Venue Lines (VL) | 90 | Line ID, Pool (cafeteria, gardens, dry), Topic, Speaker, Text, Condition Type / Target / Op / Value, On Date, Date From, Date To, Seasons, After Law, Weight, Once, Hint Kind, Hint Target, Unlocks Doc, Effects, Note (tone) |

What is in the lines now: Cafeteria 45 (20 gossip, 11 law, 7 time, 2 party, 5 hint rows), Gardens 25 (20 watching, 5 hint rows), dry 20. The hint rows fill tip slots only; they are never dealt as ordinary lines. Unlocks Doc, Effects and Unlock are imported but nothing reads them yet.

**Rules rows** (all whole numbers): `venue_walk_hours_building` 0, `venue_walk_hours_area` 0, `venue_daily_set` 12, `venue_daily_heard` 8, `venue_hint_share` 8 (one in N), `tips_max_held` 10, `tips_days` 14.

**Text keys**

| Prefix | Holds |
| --- | --- |
| `hint.stage_suit.<suit>_<n>` | Stage tips, with `{stage}` |
| `hint.opponent_suit.<suit>_<n>` | Opponent tips, with `{name}` |
| `tips.rhetoric_<suit>` | The suit phrase that ends "responds to ...": earnest rhetoric, emotive rhetoric, appealing rhetoric, logical rhetoric and data, divisive rhetoric, double-speak |
| `venue.*` | The place map, venue screens, line pop-up, refusals |
| `tips.*` | The Tips button and pop-up, level badges, briefing marks |

Edit the workbook with `tools/workbook/wbx.py` and run `python3 tools/export_data.py`; it must say "No errors". `--accept-wording` refreshes the wording snapshot after an intended Text change.

## What is checked, and a checklist

The exporter refuses a bad row before the game runs, and the tests guard the rules and the wording.

**The exporter checks**

- IDs are unique and shaped VN, VA, VL. A Venue ID and a Pool exist; an activity's Pool has lines.
- Kind is one of chat, read, watch, train, show, travel. Zone is Capitol Building or Capital Area.
- Speaker is an opponent, staff, visitor or Capital Area ID, `colleague`, or blank, and never a protagonist.
- Dates are real YY.MM.DD and Date From is not after Date To. Seasons are names from the Rules tab. After Law is `BIxx passed` or `BIxx failed` with a real bill.
- A hint row has Hint Kind `stage_suit` or `opponent_suit`; a Hint Target is a stage with a Favored Suit or an opponent. Every `hint.*` Text row keeps its token.

**The tests check**

- The seeded set is the same after a save and a reload, and differs by day and by run.
- 8 lines, then the dry line, then "Come back tomorrow"; no hours for Keep listening.
- No hours left (work hours on a weekday, weekend hours on a weekend) grays Step out and the 1-hour activities, and takes no hour.
- Hints land about 1 in 8 over many days, are filled only from the venue's hint rows, never on a stage without a Favored Suit, never on a level that is not on offer.
- 10 tips held, oldest replaced, same target refreshed, expiry on the 15th day.
- A line outside its dates, season or law never appears. No protagonist speaks. Committee and ministry names are canon. Suit chips read at 4.5 to 1 contrast. Each suit has its own phrase, and none reads "rhetoric of [suit]".

**Before adding a line**

- [ ] One or two sentences, 8 to 25 words, no exclamation mark
- [ ] Speaker is real, not a protagonist; or blank, or `colleague`
- [ ] The speaker's suit and party shape the tone and subject
- [ ] No bill, stage or company in plain gossip; a bill or stage only in a law line or hint
- [ ] Committees and ministries allowed, with canon names
- [ ] American spelling (color, favor, theater, gray)
- [ ] Date, season or After Law filled if the line is about a moment
- [ ] Note (tone) written; marked as a draft for Cameron
- [ ] For a hint phrasing: token kept, suit not named, no promised outcome (an absolute is fine as color), no invented past event or fact, three or more per suit
- [ ] `python3 tools/export_data.py` says "No errors"
