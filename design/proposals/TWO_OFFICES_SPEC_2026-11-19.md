<!-- Exported from the claude.ai doc "Two offices: Capitol and District" on 2026-11-19 (rev 100). The doc is the living source; this file is the copy Claude Code reads. All level IDs, names, numbers and Yezo brands are proposals for Cameron unless a section says Settled. -->

# Two offices: Capitol and District (design scheme and roadmap)

Nov 18, 2026 · @Cameron

## Summary

**The game splits into two places the player stands in: the Capitol office in Sapporo and a district office that differs for each protagonist.** A train swipe moves the player between them and costs work hours. Every level, event, promise and office notice gains a location: Capitol, District or Either. Each protagonist gets a catalog of named places, so district events name the right harbor, onsen town or school. The work runs in six phases, starting with a read-only audit.

| # | Decision (Cameron, Nov 18) | Where it lands |
| --- | --- | --- |
| 1 | Two offices: Capitol and District | New location state; a new District office screen |
| 2 | Levels are Capitol, District or Either. Either levels start from both offices with no travel | A Location column on Levels |
| 3 | Travel costs work hours (for example, 2 hours by train takes 2 of the week's hours) | Balance rows per protagonist |
| 4 | Travel is a swipe: a long train picture dragged right (Capitol to District) or left (District to Capitol), then a fade out and in | A new travel control and transition |
| 5 | Train travel is free on the member's rail pass. A paid train ticket is also sold, and each use pleases fiscally conservative and transit groups (+2 standing each). A private-car ticket may come later; the plane ticket stays a Marketplace item but is not a travel mode (Nov 19), saving hours and skipping train encounters | New item columns |
| 6 | On the train, constituents and others sometimes ask questions: unlisted, by chance, like a media ambush | A new hidden encounter room and its content |
| 7 | The District Representative's lines move from the Office to the District office | Office notices gain an office column |
| 8 | Each protagonist has a catalog of district places that events call by type | A Places tab and place tokens in text |
| 9 | Promises can be Capitol-only, District-only or Either | A location on each promise |

## Today's build

**Nothing in the game knows where the player is today: one Office serves everything, and district text is generic ("the district", "the district hall").** Checked against `main` at `b317606d` on Nov 18 and rechecked at 6dcf6639 on Nov 19 (counts unchanged). Counts come from the exported data files.

| System | What exists now | What the scheme touches |
| --- | --- | --- |
| Hours | A pooled 40-hour work week plus an optional 8-hour weekend. A level may start only if it ends within the hours left (`GAME_SYSTEMS.md` section 3) | Travel spends from the same pool. The "fits in the week" check needs no travel term, since only levels at the player's office are listed (rule 3) |
| Levels | 114 levels (tiers 0, 1, 2: 33, 46, 35), built from 289 stages | Each needs a location |
| Hidden rooms | 6 Media Ambush stages, hidden from the briefing by `reveal_in_briefing` = No, in fixed slots of their levels | Train encounters reuse the hiding, but roll by chance |
| Events | 87 events: 65 Random, 12 Follow-up, 9 Buyable, 1 Dated; 309 choices | Each needs a location; random draws filter by it |
| Promises | Made by event and visit choices. Kept from the Promises panel; 48-hour default deadline, paused during levels | Each needs a location; travel can make one late |
| Staff | 3 roles, 21 candidates; 64 staff tasks (18 suit the District Representative best) | The District Representative's presence moves to the District office |
| Office notices | 20 rows. ON01 and ON02 are the District Representative's greeting ("No one is at the front desk..."); ON13 to ON16 are constituent visits | Move to the District office |
| Office ticker | 155 lines (100 law-driven, 33 by meters). Many name Sapporo outlets | Stays one mixed national and local feed; a Location column can pin a line to one office |
| Protagonists | 4, each with a district: Sōya – Wakkanai (PC01), Tomakomai City (PC02), Sapporo Proportional Block 6 (PC03), Aomori Proportional Block 3 (PC04) | Each needs a district office, travel hours and a place catalog |
| Place references | No place tokens exist; the only `{places}` token is a staff-slot count | A token system is new work |
| Canon | Sapporo is Yezo's capital (`CONTENT_GUIDE.md`, Nov 9) | The Capitol office is in Sapporo |
| UI styles | Living Office, Broadcast and Woodblock each draw the Office (P9) | The District office needs all three |

## The scheme at a glance

**The player is always in one of two offices; each shows only what belongs there, and the train is the only way between them.**

*[Diagram in the source doc: the Capitol office (committees, hearings, caucus, floor debate, Cabinet, TV debates; Floor Votes and dated events; fellow members; press and party notices) and the District office (town halls, constituents, festivals, local visits, Office Hours, the District Representative, the place catalog) joined by the train (swipe right to the District, left to the Capitol; costs work hours; chance encounter; a car ticket skips it). Either rooms and the shared screens open from both.]*

A trip spends work hours from the week's pool and may bring a train encounter on the way. Anything tagged Either, and the shared screens, opens from both offices at no cost.

## Levels by location

**Every level gets one Location: Capitol, District or Either. A level starts only where it belongs, and an Either level starts from both offices with no travel.** A first, rough sort of the 114 levels by their stage names suggests most are Capitol levels. Nearly one in five mixes Capitol and District rooms and is tagged by its overall shape (rule 5).

| Proposed tag | Levels (rough) | Typical rooms | Example |
| --- | --- | --- | --- |
| Capitol | about 53 | Committees, hearings, party caucus, floor debate, Cabinet, TV debates | Hearing at the Committee on the Environment |
| District | about 24 | Town halls, constituents, festivals, local visits | Talking with Constituents |
| Either | about 18 | Lobbyist meetings, policy study, Office Hours, media ambushes | Meeting Lobbyists |
| Mixed (travel built in) | about 19 | A committee and a town hall in one level | Media Rounds; Family Outreach Tour |

The rough sort matched keywords in stage names (low confidence). The Phase 1 audit replaces it with a level-by-level table for Cameron to confirm.

**Rules (settled by Cameron, Nov 19):**

1. **The level list shows only what this office offers.** Every level available where the player stands appears with its location badge. Levels at the other office are hidden; to play one, the player must be at that office.
2. **A level starts only from its own office.** The player travels first, by swipe. There is no "travel and start" shortcut, so the trip and its chance of a train encounter stay visible.
3. **No travel term in the hours check.** Because of rule 1, the "too long for the hours left" check only ever sees levels at the player's office, so it never counts a trip.
4. **Either levels and Office Hours** appear at both offices and never cost travel. Their rooms describe the place neutrally, or use the place tokens of the office the player is in.
5. **Mixed levels: travel is built in and not shown.** No travel step, no encounter roll, no extra hours. A mixed level is tagged by its overall shape, not its first room: a level built around a bill, a committee or the media is Capitol, even if it opens with a town hall. The player ends the level at the office where they started it.
6. **Dated and forced Capitol events open the week and are forced.** When the event is known in advance, staff remind the player before it (no surprise). At the start of the week the player is moved back to the Capitol, and other choices are greyed out with the reason (Standard 2). The move costs no work hours; a Balance row (forced\_travel\_hours, default 0) keeps a cost possible later. An addendum will cover more forced events as they are added.
7. **Each week starts where the player's weekend ended.**

**Rule 6 in detail: which events are forced (evaluation, Nov 19).** Today's 87 events already fall into three kinds by trigger: 65 Random and 12 Follow-up events arrive by chance; 9 Buyable events (ads, a grant, a rally, the office open day) are paid for; and 1 Dated event, the Prime Minister's Opening Address (EV47, 2 hours, on a fixed date), is scripted. The Walking Tour (SH20) and the Dinner (SH19) are Marketplace items that open a hosted scene.

|  | A. A scripted "Decision!" class | B. Make them buyables, like the Walking Tour and Dinner |
| --- | --- | --- |
| What it means | Dated events become "Decision!" events: scripted, on a fixed date, forced under rule 6 | The Prime Minister's address and later set pieces become Marketplace items the player chooses to attend |
| Fit for the Prime Minister's address | Strong: the session opens whether the member wants it or not | Weak: nobody pays to hear the Prime Minister, and skipping it breaks the calendar |
| Travel | A free forced move (rule 6). For PC01 and PC04 that saves 6 hours whenever a Decision! falls in a District week | No forced travel; bought and played where its location allows |
| Player choice | Low, by design: it is the calendar | High |
| Build cost | Small: the Dated trigger exists; add the label, the staff reminder, the move and the greyed-out choices | Medium: shop rows, hosted scenes and prices, plus a guard so national moments can't be skipped |
| Pacing | Gives the session a spine (opening address, later a budget or a no-confidence vote) | Removes the scripted beats |

**Recommendation: A for scripted moments, B's model for optional ones.** Keep three kinds of event:

1. **Scenario events** (Random, Follow-up): drawn only from the player's office plus Either, and never move the player.
2. **Arranged events** (Buyable events and hosted events): bought and played where the player is. Each gets a location tag, for example the Constituency Office Open Day is District and the National Television Spot is Capitol.
3. **Decision! events** (today's Dated trigger, renamed in the interface): scripted and forced under rule 6. The Prime Minister's Opening Address is the first.

The free-trip loophole stays small while Decision! events are rare (one today), and the Balance row `forced_travel_hours` can close it later.

**A gap rule 6 doesn't cover: forced crisis levels.** Two levels are forced in by a countdown today: the Urgent Matters Town Hall (LV83, when Constituency support falls to 15) is a District level, and the Party Steering Committee check-in (LV84, when Party support falls below 25) is a Capitol level. Proposed: each waits at its own office with a staff warning, and is forced in on arrival there; it doesn't move the player. Treating them as Decision! events would make a free trip of every crisis.

**Settled (Cameron, Nov 18):** TV Debate is a Capitol room, because its opponents are national figures. Press conferences stay as they are for now. A **local press gaggle and a local press conference** come later as District rooms, with local reporters and their own background.

**Backgrounds for Either rooms played in the District.** Today each room type draws one background, and all of them read as Sapporo. An Either room started from the District office needs a District version, or it will look like the Capitol:

| Room type | Stages | Background today | In the District | New art |
| --- | --- | --- | --- | --- |
| Lobbyist Meeting | 13 | ST20 | A local meeting room or restaurant | Yes, 1 shared |
| Policy Study (Session) | 14 | ST21 | A local library or community room | Yes, 1 shared |
| Office Hours | 32 | ST07 | The District office's meeting room | Yes, 1 per District office, or reuse the office itself |
| Media Ambush | 6 | ST19 | A street or station in the district | Maybe: `OUT_STREET_1` to `_3` may serve |
| Local press gaggle, local press conference | (later) | (none) | A local press room or a street outside the office | Yes, when those rooms are written |
| TV Debate | 10 | ST06 | Capitol only | No |
| Town Hall | 18 | ST05 (one uses the harbor) | Already District | No |

The District versions can be shared by all four protagonists; only the District office itself must differ. A small mapping (background plus location gives the background to use) avoids a new column on all 289 stages. The outdoor set already in the repo (harbor, farm, festival, school, shrine, street, lakeside, the Ainu cultural center) can also back the place catalog's types.

## Travel

**A trip costs hours, and no Funds on the member's rail pass, and the distance differs sharply by protagonist: real rail times run from minutes to five hours.** Settled (Cameron, Nov 19): the game hours below, by train and by private car, as Balance rows. Flights are not a travel mode on the strip.

| Protagonist | District office | Real trip to Sapporo | Train (game hours) | Private car (game hours) | Note |
| --- | --- | --- | --- | --- | --- |
| PC01 Kenshin Sako | Sōya – Wakkanai | About 5 hours 10 minutes by limited express, one return a day ([Wikipedia](<https://en.wikipedia.org/wiki/S%C5%8Dya_(train)>)) | 6 | 5 | The car is an hour faster. A round trip by train takes 12 of the 40 hours; whether he stays "Easy" is still open |
| PC02 Haru Yashi | Tomakomai City | About 44 minutes by limited express ([Sapporo Station guide](https://www.sapporostation.com/limited-express-super-hokuto-hakodate-tomakomai-sapporo/)) | 1 | 1 |  |
| PC03 Arata Ran | Sapporo Proportional Block 6 | Within the city | 1 | 1 | Same city; the swipe still runs, as a subway or local train ride |
| PC04 Jyurou Nishihara | Aomori Proportional Block 3 | About 61 minutes by Shinkansen to Shin-Hakodate-Hokuto ([Wikipedia](https://en.wikipedia.org/wiki/Hokkaido_Shinkansen)), then 3 hours 40 minutes or more by express to Sapporo ([nippon.com](https://www.nippon.com/en/features/h10017/)) | 6 | 9 | Crosses the strait by the Seikan Tunnel. The car is slower (the strait crossing); its price is privacy, not speed |

**The swipe** (the Office and District office both show it):

- **Look:** a full-width strip along the bottom of the office, carrying a long horizontal picture of a train. Its label states the cost before the gesture: "To Tomakomai · 1 h by train · free".
- **Gesture:** drag the train right (Capitol to District) or left (District to Capitol). Past about 60% of the width it commits; short of that it springs back. On commit, the office fades out, a brief travel card shows (train, destination, hours), and the other office fades in.
- **Refusals with a reason** (Standard 2): not enough hours left; a level in progress; at the weekend, if travel is allowed then at all (open question).
- **Accessibility:** a swipe alone shuts out players who can't drag. A tap on the strip opens a confirm with the same text and cost; the gesture is the fast path, not the only one.
- **Promises:** before you leave, the strip warns if a promise due soon can only be kept where you are.

**Tickets (later, Marketplace items):**

| Ticket | Hours | Funds | Train encounters | Standing on each use | Offered for |
| --- | --- | --- | --- | --- | --- |
| Member's rail pass (default) | Train hours: 6 / 1 / 1 / 6 (PC01 to PC04) | Free | Can happen | None | All |
| **Paid train ticket** | Same as the pass | Price set by Cameron | Can happen | **+2 each with the Taxpayers' Alliance (BO23), the Chamber of Commerce (BO05) and the Commuter Committee (BO14)** | All |
| Private car | Car hours: 5 / 1 / 1 / 9 (PC01 to PC04) | Price set by Cameron | Skipped | None | All; faster only for PC01, otherwise the price is privacy, not speed |
| Airplane ticket | Not a travel mode on the strip (Nov 19). Stays a Marketplace item; its use is to be defined | Price set by Cameron | Not applicable | None | To be defined |

**Why a paid ticket pleases anyone.** It mirrors a real debate. In Japan, lawmakers get free access to most domestic transport, paid from the chambers' budget, and the cost of those passes is a recurring complaint ([Japan Times](https://japantimes.co.jp/news/2012/05/20/national/private-rail-lines-want-diet-ranks-to-pay-up)). A member who pays their own fare is making a visible point about public money. The ticket's description should say so, and a ticker line or office notice can notice it ("The Taxpayers' Alliance newsletter praises a member who buys their own train tickets").

**How the bonus works (proposed):**

- It is an item effect, applied when the trip commits, through the usual standing rules. Gains shrink as standing rises (× 0.6 from 40, × 0.4 from 60), and it counts as "moved this week", so it stops neglect drift for those three groups.
- It costs nobody else standing. A later version could cost a little with groups that see it as a stunt, if playtests show the ticket is an easy win.
- The ticket is a consumable, one trip each, stackable (default stack cap 5), bought in the Marketplace and chosen on the travel strip like the other modes.

When the player owns a ticket, the strip offers a choice of mode before the swipe, and the train picture changes to a car. Flights are not a strip option.

**Train encounters:**

- **What:** a hidden room, rolled per train trip (a Balance row, for example 25%), never shown in advance, like a media ambush.
- **When:** it happens inside the trip's hours, so it costs no extra time: it turns dead travel time into play.
- **Format (proposed):** a short dilemma like Office Hours, one or two questions with four answers and no right answer. Each rider is a constituent (District awareness), a passenger from elsewhere (National awareness), a student, a farmer or fisher, a tourist, a reporter, a party colleague or a lobbyist. A choice can move standing or awareness, or make a promise (and that promise has a location).
- **Alternative:** a three-turn press-style card room that can't be lost, like the ambush. It is heavier to build and longer on a phone; it suits the long routes only.

## Each district's identity

**A new Places tab gives each protagonist a named place for each type, and text asks for the type, not the name: "{place:onsen\_town}" becomes "Toyotomi Onsen" for Kenshin Sako.** An event that needs a type the district lacks doesn't fire there, so no one gets a harbor story in a landlocked block.

**The Places tab** (one row per protagonist and type):

| Column | Example | Rule |
| --- | --- | --- |
| Protagonist | PC01 |  |
| Place type | onsen\_town | From a fixed list (below) |
| Name (English) | Toyotomi Onsen | Shown to players |
| Name (Japanese) | 豊富温泉 | For the Japanese build and the ticker |
| Short form | the onsen | For a second mention in the same text |
| Background | (art ID, optional) | When an event or level shows the place |

**Place types (a first list for the audit to test against the events):** district office, main station, city or town hall, harbor or port, onsen town, mountain, farmland, fishing grounds, school, university, hospital, shrine or temple, market or shopping street, festival, factory or industrial park, island, landmark, Ainu cultural site, beach, ski area, park, energy site, travel route, community hall.

**Tokens:**

| Token | Gives | Example (PC02) |
| --- | --- | --- |
| `{place:<type>}` | That type's name | Port of Tomakomai |
| `{place_short:<type>}` | Its short form | the port |
| `{district}` | The district's name | Tomakomai City |
| `{office_city}` | The district office's town | Tomakomai |

The text checker fails on any token left unresolved on screen (Standard 3) and on any token whose type a protagonist lacks in text that can reach them. Events gain a **Needs Place** column, so the draw skips them where the type is missing.

**The full catalog: every location archetype, localized for each protagonist (24 archetypes, Nov 19).** Real places in each area, all canon decisions for Cameron, since Yezo is fictional and may rename them:

| Archetype (token type) | PC01 Sōya – Wakkanai | PC02 Tomakomai City | PC03 Sapporo Block 6 | PC04 Aomori Block 3 |
| --- | --- | --- | --- | --- |
| District office (district\_office) | Central Wakkanai (proposed) | Central Tomakomai (proposed) | Open: Teine, western Kita Ward or Ishikari | Open: Mutsu, Towada or Noheji |
| Main station (station) | Wakkanai Station | Tomakomai Station | Teine Station; Zenibako Station | Noheji Station; Shimokita Station (Mutsu) |
| Travel route (travel\_route) | Yezo Rail Sōya Line, the Northern Star limited express | Yezo Rail Muroran Line, the Harbor Light limited express | Yezo Rail Hakodate Line local, or the Sapporo City Subway | The Shinkansen through the Seikan Tunnel, then Yezo Rail's Ōminato Line from Noheji |
| City or town hall (town\_hall) | Wakkanai City Hall; Toyotomi Town Hall | Tomakomai City Hall | Teine Ward Office; Ishikari City Hall | Mutsu City Hall; Rokkasho Village Office; Towada City Hall |
| Harbor or port (harbor) | Port of Wakkanai (ferries to Rishiri and Rebun) | Port of Tomakomai; the West Port fishing harbor | Ishikari Bay New Port; the Ishikari river-mouth fishing port | Noheji; Ōma port; Rokkasho's Pacific ports |
| Onsen town (onsen\_town) | Toyotomi Onsen | Tarumae Onsen, at the Tarumae Foothill Baths; the Seaview Baths on the Pacific shore | Ishikari Onsen, at the Ishikari Fish-House Baths | Yagen Onsen; Shimofuro Onsen |
| Mountain (mountain) | The Sōya Hills | Mount Tarumae | Mount Teine | Mount Osore; Mount Kamafuse |
| Farmland (farmland) | Sarobetsu dairy country | The Yūfutsu Plain | The Teine market gardens | Towada's garlic and nagaimo fields; Rokkasho stock farms |
| Fishing grounds (fishing\_grounds) | Sōya Strait kelp and scallops | Tomakomai's hokki (surf clam) beds | The Ishikari salmon run | Mutsu Bay scallop farms; Ōma's tuna grounds |
| School (school) | Sōya Regional High School | Tomakomai Harbor High School | Teine Hillside High School | Shimokita Regional High School |
| University (university) | Wakkanai Northern College | Tomakomai Pacific University | Teine Institute of Technology | Towada Veterinary College |
| Hospital (hospital) | Wakkanai City Hospital | Tomakomai City Hospital | Teine General Hospital | Mutsu General Hospital |
| Shrine or temple (shrine\_temple) | Hokumon Shrine | Tarumae Shrine | Ishikari Benten Shrine | Osorezan Bodaiji; Tanabu Shrine |
| Market or shopping street (market) | Wakkanai Central Arcade | Tomakomai Port Fish Market | Benten historic street, Ishikari | Towada Farmers' Market |
| Festival (festival) | Wakkanai Minato Antarctic Festival (early August) | Tomakomai Port Festival (early August); Hokki Festival (October) | Ishikari Salmon Festival (late September) | Tanabu Festival, Mutsu (August 18–20) |
| Factory or industrial park (factory) | The Sarobetsu Dairy Co-op creamery | Yezo Paper Company's Tomakomai Paper Works; the Northern Motors transmission plant | Ishikari Bay New Port industrial area | Mutsu-Ogawara industrial area, Rokkasho |
| Energy site (energy\_site) | Sōya Hills Wind Park (57 turbines) | Tomakomai Carbon Storage Center; Yezo Electric Power's planned LNG terminal | Bayside Wind Company's offshore wind farm; Yezo Gas's Ishikari LNG terminal | Rokkasho Fuel Recycling Plant (Yezo Nuclear Fuel Corporation) and wind farms; Ōma nuclear plant (Northern Power Development, under construction) |
| Island (island) | Rishiri and Rebun (if inside the district) | None | None | Benten-jima off Cape Ōma |
| Landmark (landmark) | Cape Sōya | Lake Utonai | Hamanasu no Oka Park and the Ishikari lighthouse | Cape Ōma; Lake Towada and the Oirase Gorge |
| Ainu cultural site (ainu\_site) | Wakkanai Ainu Center | Tomakomai Ainu Center | Kita Ward Ainu Center | Towada Ainu Center |
| Beach (beach) | The Sarobetsu coast, facing Rishiri | The Pacific shore at Nishikioka | The Ishikari and Zenibako beaches | The Mutsu Bay shore at Noheji |
| Ski area (ski\_area) | Wakkanai City Ski Hill | Tarumae Ski Hill | Mount Teine Ski Resort | Mount Kamafuse |
| Park (park) | Wakkanai Park | Midorigaoka Park | Maeda Forest Park | Mutsu Bayside Park |
| Community hall (community\_hall) | Wakkanai Community Hall | Tomakomai Community Hall | Teine Community Hall | Mutsu Community Hall |

**Every company, institution and branded venue now carries an invented Yezo name (Nov 19).** Natural features, towns, stations, public offices, shrines and place-named festivals keep their real names until the place-canon decision. Former gaps (schools, community halls, Ainu centers, some parks, beaches and ski hills) use invented regional names with no real counterpart. "None" stays only for islands, where an invented one would contradict the map; events needing an island skip that protagonist. The fresh-lookup table below keeps the real names as the research record; game text uses the names here.

**Naming rule for Yezo brands**, matching the game's existing names (Sapporo Broadcasting Center, Sapporo Digital Networks, Yezo Political Insider): a place or "Yezo" plus a plain English description. No real company or product name, and nothing that echoes one closely (so "Yezo Electric Power", never "Hokkai Electric").

**Brand map** (proposed; confirm under the brand-names action item):

| Yezo name | What it is | Real counterpart it replaces | PC |
| --- | --- | --- | --- |
| Yezo Rail (Northern Star, Harbor Light expresses) | National railway and its limited expresses | JR Hokkaido (Limited Express Sōya, Hokuto) | All |
| Sōya Hills Wind Park | Onshore wind farm | Sōya Misaki Wind Farm (Eurus Energy) | PC01 |
| Sarobetsu Dairy Co-op creamery | Dairy plant | Local dairy brands (none named) | PC01 |
| Tarumae Foothill Baths | Day-use hot spring | Yunomino-yu | PC02 |
| Seaview Baths | Day-use hot spring | Tomakomai Onsen Honoka | PC02 |
| Tomakomai Pacific University | University | Hokuyo University | PC02 |
| Yezo Paper Company, Tomakomai Paper Works | Paper mill | Oji Paper's Tomakomai mill | PC02 |
| Northern Motors | Car-parts plant | Toyota Motor Hokkaido | PC02 |
| Tomakomai Carbon Storage Center | CO2 storage site | Tomakomai CCS demonstration (Japan CCS) | PC02 |
| Yezo Electric Power | Power utility | Hokkaido Electric Power | PC02, PC03 |
| Ishikari Fish-House Baths | Day-use hot spring | Banya no Yu ("fishermen's lodge bath") | PC03 |
| Teine Institute of Technology | University | Hokkaido University of Science | PC03 |
| Teine General Hospital | Hospital | Teine Keijinkai Hospital | PC03 |
| Mount Teine Ski Resort | Ski resort | Sapporo Teine | PC03 |
| Bayside Wind Company | Offshore wind operator | Ishikari Bay New Port offshore wind farm | PC03 |
| Yezo Gas | Gas utility | Hokkaido Gas | PC03 |
| Towada Veterinary College | University | Kitasato University, Towada campus | PC04 |
| Towada Farmers' Market | Farm market | JA Towada Oirase's market | PC04 |
| Yezo Nuclear Fuel Corporation; Rokkasho Fuel Recycling Plant | Fuel plant and its operator | Japan Nuclear Fuel Limited; Rokkasho Reprocessing Plant | PC04 |
| Northern Power Development | Power company | J-Power (Ōma plant) | PC04 |

**Islands and beaches in today's content (Cameron, Nov 19).** The three Chishima acts (LV35, LV53, LV74) are national legislation, playable by anyone, so they stay Capitol and need no island place. The only district-specific island text was a visitor question (VQ380) about kombu racks on "the Rishiri beach". It is now generic ("My kombu drying racks are on the beach and the storm took half. Can you help?"), on branch `content/vq380-generic-beach`, not merged. Once place tokens exist it becomes "…on {place:beach}…": the Sarobetsu coast, facing Rishiri (PC01); the Pacific shore at Nishikioka (PC02); the Ishikari and Zenibako beaches (PC03); the Mutsu Bay shore at Noheji (PC04).

**Settled (Cameron, Nov 18):** the areas of Sapporo Block 6 and Aomori Block 3 above. The PC04 drafts replace the earlier ones (the Hakkōda Mountains, Asamushi Onsen and the Nebuta festival), which sat in Aomori city, outside the block. The two blocks add three place types the first list lacked: **beach, ski area and park**. Rokkasho is inside (Cameron, Nov 19). Mutsu is inside too, since Mount Osore and Yagen Onsen both lie within Mutsu city. Misawa, Tohoku and Shichinohe still need Cameron's word.

**Fresh lookup (Nov 19): every draft place checked against current sources. Two names changed, one place moved to the right city, and PC03 gained an onsen.** Confidence is high unless marked.

| Place | Finding | Change | Source |
| --- | --- | --- | --- |
| Cape Sōya (PC01) | Japan's northernmost point, in Wakkanai city | None | [Wikipedia](https://en.wikipedia.org/wiki/Wakkanai) |
| Port of Wakkanai (PC01) | Seasonal ferries to Rishiri and Rebun; the Sakhalin ferry ended in 2015 | None | [Wikipedia](https://en.wikipedia.org/wiki/Wakkanai) |
| Toyotomi Onsen (PC01) | Northernmost hot-spring town, on the east side of the Sarobetsu Plain; its oil-bearing water burst out of an oil well in 1926 | None | [Visit Hokkaido](https://www.visit-hokkaido.jp/en/spa/spot/detail_10643.html) |
| Mount Tarumae, Lake Utonai (PC02) | Both in Tomakomai. Tarumae is an active volcano of 1,041 m; Utonai was Japan's first bird sanctuary (1981) and is a Ramsar wetland | None | [Lake Utonai](https://wikipedia.com/wiki/Lake_Utonai), [GLTJP](https://cdn.gltjp.com/en/directory/item/14615/) |
| Port of Tomakomai (PC02) | Not re-checked (a stable fact) | None | — |
| Teine ski area (PC03) | The resort is **Sapporo Teine**, in Teine Ward. "Teine Highland" merged into it in 2005 and is now its Highland zone, where the 1972 Olympic slaloms ran | Renamed | [Wikipedia](https://en.wikipedia.org/wiki/Sapporo_Teine), [resort](https://sapporo-teine.com/snow/lang/en/?p=20) |
| Maeda Forest Park (PC03) | Teine Ward; half forest, with a 600 m canal and poplar avenue | None | [Sapporo travel](https://sapporo.travel/?p=24663) |
| Hamanasu no Oka Park (PC03) | A sand spit where the Ishikari River meets the sea, in Ishikari city | None | [Ishikari (prefecture site)](https://www.kirari-ishikari.pref.hokkaido.lg.jp/en/visit/activity-en/ishikari-cultural-search) |
| Ishikari Bay New Port (PC03) | A major port on the bay; its offshore wind farm (112 MW) was inaugurated in April 2024 | Added the wind farm | [Wikipedia](https://en.wikipedia.org/wiki/Ishikari_Bay), [4C Offshore](https://free-4c-dev.datalake.tgs.com/windfarms/ishikari-bay-new-port-japan-jp16.html) |
| Zenibako (PC03) | Zenibako station (Hakodate Main Line, opened 1880) is in **Otaru city**, not Sapporo. The settled area crosses the city line, which is fine for a proportional block | Noted | [Wikipedia](https://en.wikipedia.org/wiki/Zenibako_Station) |
| Ishikari salmon (PC03) | Ishikari grew rich as a salmon-fishing port (medium: a travel page) | None | [Ishikari hot spring page](https://www.asahi-net.or.jp/~ue3t-cb/index_e/spa_e/isikari_e/isikari_e.htm) |
| **Banya no Yu (PC03, new)** | Town-run natural hot spring at the Ishikari river mouth (Bentenchō), "fossil seawater" salt spring, open-air bath facing the sea. Local tours pair it with Hamanasu no Oka Park | Added as onsen town | [Ishikari (prefecture site)](https://www.kirari-ishikari.pref.hokkaido.lg.jp/en/visit/activity-en/ishikari-cultural-search), [Japan 47 GO](https://www.japan47go.travel/en/detail/43c7a576-d302-4419-8e83-397185ac7d83) |
| Mount Osore (PC04) | Bodaiji temple (founded 862) in Mutsu city; closed November to April, which matters for winter events | Season noted | [japan-guide](https://japan-guide.com/e/e3727.html) |
| Cape Ōma (PC04) | Honshu's northernmost point; pole-and-line tuna town; a 440 kg tuna monument | None | [GLTJP](https://www.gltjp.com/en/directory/item/17350/) |
| Yagen Onsen (PC04) | In Mutsu city (former Ōhata), a remote valley north of Mount Osore | None | [Aomori Tourism](https://aomori-tourism.com/en/feature/detail_305.html) |
| Mutsu Bay scallops (PC04) | Farmed around the bay; seabed stocking is used mostly at Noheji and Kawauchi. Juvenile die-offs hit the 2024 crop | None | [Umai Aomori](https://www.umai-aomori.com/202108/mutsu-bay-scallops/), [Undercurrent](https://undercurrentnews.com/2024/12/24/high-mortality-rates-to-hit-japans-mutsu-bay-scallop-production-recovery) |
| Lake Towada, Oirase (PC04) | The Oirase stream runs 14 km from the lake, in Towada city | None | [ANA](https://ana.co.jp/en/kr/japan-travel-planner/aomori/0000001.html) |
| Noheji (PC04) | Junction where the JR Ōminato Line leaves for Mutsu | None | [Wikivoyage (Mutsu)](https://guides.travel.sygic.com/production/en/Mutsu) |
| **Rokkasho (PC04, new)** | Pacific coast at the base of the Shimokita Peninsula, on Lake Ogawara's north shore. The fuel reprocessing plant, begun in 1993, is targeted for completion in fiscal 2026 (by March 2027) after 27 postponements; wind farms with battery storage stand nearby | Added | [WNN](https://world-nuclear-news.org/articles/further-delay-to-japanese-reprocessing-and-mox-pla), [Jiji (May 2026)](https://english.adnkronos.com/2026/05/09/japan-faces-tough-road-ahead-over-n-fuel-reprocessing-plant/), [Wikipedia](https://www.wikiwand.com/en/articles/Rokkasho,_Aomori) |

A watchdog group reported in August 2026 that a 28th postponement is coming (medium: [CNIC](https://cnic.jp/english/?p=9307)), so level text should say "delayed again" rather than give a count.

Proportional blocks cover more ground than a single-member district, so PC03 and PC04 may hold two names for one type. The tab allows several rows per type, picked at random or by event.

## Levels per protagonist: one District fight, one Capitol policy

**Eight new levels, two per protagonist: a District fight that never leaves home, and a Capitol policy fight that starts from the district's stake. Each is built from stages that already exist, on a real local issue checked on Nov 19.** IDs (LV115 to LV122), numbers and names are proposals for Cameron.

| PC | District level | Capitol level |
| --- | --- | --- |
| PC01 Kenshin Sako | **Keep the Sōya Line Running** (LV115, tier 1, 11 h): the rail company can't keep the line north of Nayoro alone | **The Sakhalin Ferry** (LV116, tier 2, 14 h): reopen the Wakkanai–Korsakov crossing |
| PC02 Haru Yashi | **Carbon Under the Harbor** (LV117, tier 1, 11 h): a bigger CO2 store under the port | **A Casino by Lake Utonai?** (LV118, tier 2, 13 h): the integrated-resort siting fight |
| PC03 Arata Ran | **Wind on Ishikari Bay** (LV119, tier 1, 11 h): a second offshore wind farm | **The Tunnel Under Teine** (LV120, tier 2, 14 h): paying for the delayed Shinkansen |
| PC04 Jyurou Nishihara | **The Rokkasho Question** (LV121, tier 2, 11 h): the fuel plant is late again | **Ōma's Bluefin Quota** (LV122, tier 1, 12 h): sharing out a bigger tuna quota |

District levels use only District and Either rooms; Capitol levels use only Capitol and Either rooms, so each is listed at one office only (rule 1). Hours count rooms only; travel to the level's office is extra. Rewards are standing ranges on a win; bonus ranges follow the tier's defaults.

### PC01 District: Keep the Sōya Line Running

The fight: in November 2016 the rail company named the Sōya Line north of Nayoro among the sections it could not keep up alone; towns must pay a share or see it turned over. This is the very line the player rides to the Capitol. Purpose: "The trains to {office\_city} are on the list again. Ride it, count who's on it, and come back with a deal the towns can pay for."

| # | Room (existing stage) | Where | Hours | What it's about |
| --- | --- | --- | --- | --- |
| 1 | Constituency Walkabout (ST267) | District: {place:station} | 2 | Who still rides, and why |
| 2 | Town Hall on Commuter Fares (ST24) | District: Toyotomi town hall | 2 | Emotional. Students, hospital trips, dairy farmers |
| 3 | Media Ambush (ST19), hidden | District: the platform | 1 | "Will the last train run?" |
| 4 | Policy Study on Rail Timetables (ST25) | Either | 2 | Data Driven. Riders per train, cost per kilometre |
| 5 | Lobbyist Meeting (ST20) | Either: the rail company | 2 | Appeal. A shared-cost deal |
| 6 | Town Hall (ST05) | District: {place:town\_hall} | 2 | Earnest. The deal, put to the city |

Rewards: Commuter Committee (BO14) +3 to +7, Rural Revitalization Council (BO30) +2 to +6, Mayors' Network (BO04) +2 to +5, Constituency Voters (BO18) +2 to +5, Agricultural Cooperatives (BO10) +1 to +3. Unique hook (idea): a win lowers PC01's train-encounter chance for four weeks, because the line is calmer.

### PC01 Capitol: The Sakhalin Ferry

The fight: the regular ferry from Wakkanai to Korsakov on Sakhalin ended in 2015. Reopening it needs a foreign-affairs deal and a subsidy, and the party's security hawks object. Purpose: "From {place:landmark} you can see Sakhalin on a clear day. The ferry is gone. Bring it back, if the Capitol will let you."

| # | Room (existing stage) | Where | Hours | What it's about |
| --- | --- | --- | --- | --- |
| 1 | Lobbyist Meeting (ST20) | Either: a shipping line | 2 | Appeal. They'll sail if someone covers the losses |
| 2 | Policy Study Session (ST21) | Either | 2 | Earnest. Customs, cost per passenger, tourism |
| 3 | Committee on Foreign Affairs (ST14) | Capitol | 4 | Appeal. National members weigh the neighbor |
| 4 | Press Conference (ST04) | Capitol | 2 | "Is this the time?" |
| 5 | Party Caucus (ST03) | Capitol | 4 | Divisive. The party splits |

Rewards: Chamber of Commerce (BO05) +2 to +6, Fisheries Cooperative (BO07) +2 to +5, Small Business Owners' Association (BO25) +2 to +5, Mayors' Network +1 to +4, National Media (BO08) +1 to +3. Unique hook: a Capitol win pays off at home, with a District ticker line and an office notice from {place:harbor}.

### PC02 District: Carbon Under the Harbor

The fight: a national demonstration stored 300,000 tonnes of CO2 under Tomakomai's harbor between 2016 and 2019. A bigger, commercial store is now on the table, and the hokki fishers want to know what sits under their clam beds. Purpose: "They want to bury more carbon under {place\_short:harbor}. The port wants the jobs; the clam boats want guarantees. Find a deal both can sign."

| # | Room (existing stage) | Where | Hours | What it's about |
| --- | --- | --- | --- | --- |
| 1 | Constituency Walkabout (ST267) | District: the port and the paper-mill streets | 2 | Who works the port today |
| 2 | Lobbyist Meeting (ST20) | Either: the storage consortium | 2 | Appeal. Jobs, and a climate story for the city |
| 3 | Town Hall at the Harbor (ST29) | District: {place:harbor} | 2 | Emotional. The hokki fishers |
| 4 | Media Ambush (ST19), hidden | District: outside the refinery gates | 1 | "Is it safe in an earthquake?" |
| 5 | Town Hall on the Carbon Levy (ST53) | District: {place:community\_hall} | 2 | Data Driven. Who pays, who profits |
| 6 | Policy Study Session (ST21) | Either | 2 | Earnest. The test found no quakes caused by injection; what else it found |

Rewards: Innovation Society (BO16) +3 to +6, Labor Federation (BO09) +2 to +5, Chamber of Commerce +2 to +5, Fisheries Cooperative +1 to +4, Consumer Advocacy Network (BO26) +1 to +3. Unique hook: the most Data Driven district level, so it rewards a data deck; playable at the weekend.

### PC02 Capitol: A Casino by Lake Utonai?

The fight: Hokkaido dropped an integrated-resort bid in 2019, partly over the candidate site's closeness to the Lake Utonai bird sanctuary. In 2026 the prefecture is deciding again, with Tomakomai still the front-runner. Purpose: "The resort is back, and {office\_city} wants it. Win the site in the Capitol without losing {place:landmark}."

| # | Room (existing stage) | Where | Hours | What it's about |
| --- | --- | --- | --- | --- |
| 1 | Lobbyist Meeting on Integrated Resort (ST233) | Either | 2 | Appeal. The operators' pitch |
| 2 | Policy Study Session on Integrated Resort (ST235) | Either | 2 | Earnest. Visitors, tax, gambling harm, the wetland |
| 3 | Media Ambush on Integrated Resort (ST234), hidden | Capitol | 1 | "Did you take their money?" |
| 4 | Committee on Construction and Development: Integrated Resort (ST236) | Capitol | 4 | Duplicitous. Site rules and buffers |
| 5 | Party Caucus on Integrated Resort (ST238) | Capitol | 4 | Divisive |

Rewards: Chamber of Commerce +3 to +7, Labor Federation +2 to +5, Small Business Owners' Association +2 to +5, Mayors' Network +1 to +4. Shares rooms with the Integrated Resort Act (LV55); this level is the siting fight before it, and a win could discount LV55 for PC02. A true trade-off would cost standing with the Consumer Advocacy Network and the Buddhist Temples Association (BO19).

### PC03 District: Wind on Ishikari Bay

The fight: the bay's first offshore wind farm (112 MW) opened in 2024; developers want a second off the beaches, against the salmon netters and the beach-goers. Purpose: "The developers want a second wind farm off {place:beach}. The port wants the work and the city wants the power; the salmon netters at the river mouth want their water left alone. Settle it here, before the Capitol settles it for you."

| # | Room (existing stage) | Where | Hours | What it's about |
| --- | --- | --- | --- | --- |
| 1 | Lobbyist Meeting (ST20) | Either: the developer's office at {place:harbor} | 2 | Appeal. Work at the port, power for the grid |
| 2 | Town Hall at the Harbor (ST29) | District: the river-mouth fishing port | 2 | Emotional. The netters fear for the salmon run |
| 3 | Media Ambush (ST19), hidden | District: {place:beach} | 1 | "Where will the turbines stand?" |
| 4 | Town Hall on Grid Resilience and Renewable Energy (ST149) | District: {place:community\_hall} in Teine | 2 | Earnest. Cheap, clean power and a clear view |
| 5 | Policy Study Session (ST21) | Either | 2 | Earnest. Birds, fish and noise |
| 6 | Closing Reception (ST276) | District: {place:onsen\_town} (the Ishikari Fish-House Baths) | 2 | Non-combat. Both sides in one bath; the deal gets made |

Rewards: Fisheries Cooperative +3 to +7, Innovation Society +2 to +5, Chamber of Commerce +1 to +4, Neighborhood Associations (BO06) +1 to +4, Constituency Voters +1 to +3. Unique hook: autumn only (the salmon run), playable at the weekend, and the only level that ends in an onsen.

### PC03 Capitol: The Tunnel Under Teine

The fight: the Shinkansen extension to Sapporo is now due at the end of fiscal 2038, eight years late, and its long Sasson Tunnel runs under Teine Ward's Tomioka and Nishimiyanosawa. The Capitol must decide who pays the higher bill and what the neighborhoods above the tunnel get. Purpose: "The bullet train is eight years late and digging under {district}. Make the Capitol pay its share, and make sure Teine gets more than noise."

| # | Room (existing stage) | Where | Hours | What it's about |
| --- | --- | --- | --- | --- |
| 1 | Lobbyist Meeting on Hokkaido Shinkansen Acceleration (ST138) | Either | 2 | Appeal. The builders want certainty |
| 2 | Policy Study Session (ST21) | Either | 2 | Earnest. The new cost and the new date |
| 3 | Committee on Finance: Hokkaido Shinkansen Acceleration (ST137) | Capitol | 4 | Data Driven. Who pays |
| 4 | Committee on Construction and Development: Hokkaido Shinkansen Acceleration (ST139) | Capitol | 4 | Duplicitous. What the tunnel's neighbors get |
| 5 | Press Conference (ST04) | Capitol | 2 | "Was it worth it?" |

Rewards: Commuter Committee +3 to +6, Chamber of Commerce +2 to +5, Neighborhood Associations +2 to +5, Taxpayers' Alliance (BO23) +1 to +3, Constituency Voters +1 to +3. Shares rooms with the Hokkaido Shinkansen Acceleration Act (LV34). Unique hook: two committees back to back, money first, then the ground.

### PC04 District: The Rokkasho Question

The fight: the fuel reprocessing plant at Rokkasho, begun in 1993, has been postponed 27 times and is now targeted for fiscal 2026. The village wants its grants and jobs; the Pacific fishers want proof about the sea. Purpose: "The fuel plant at {place:energy\_site} has slipped again. The village wants its grants and its jobs; the fishers want proof about the sea. Hear Rokkasho out, then answer for it."

| # | Room (existing stage) | Where | Hours | What it's about |
| --- | --- | --- | --- | --- |
| 1 | Constituency Walkabout (ST267) | District: Rokkasho village | 2 | Shops, the village office, the lake shore: who depends on the plant |
| 2 | Town Hall (ST05) | District: the village hall | 2 | Earnest. Jobs and grant money against "how many more delays?" |
| 3 | Media Ambush (ST19), hidden | District: outside the plant gates | 1 | A local reporter asks about the latest delay |
| 4 | Lobbyist Meeting (ST20) | Either: the operator's people | 2 | Appeal. Back another extension |
| 5 | Policy Study Session (ST21) | Either | 2 | Earnest. The safety review, the money, the waste already stored |
| 6 | Town Hall at the Harbor (ST29) | District: Rokkasho's Pacific fishing ports | 2 | Emotional. The fishers hear what the member will do |

Rewards: Rural Revitalization Council +3 to +7, Mayors' Network +2 to +5, Fisheries Cooperative +2 to +6, Constituency Voters +2 to +5, Innovation Society +1 to +3. Settings: needs discovery (a District event, "A letter from the village office", reveals it), no weekend play. Variant: as a Mixed level (travel built in and not shown, rule 5), swap room 5 for a Committee on the Environment (ST10) in the Capitol. It stays listed at the District office and runs 13 hours.

### PC04 Capitol: Ōma's Bluefin Quota

The fight: bluefin tuna stocks have recovered. Japan's quota for large bluefin rose 50% in 2025, boats are running out of quota early in a bumper 2026, and in August 2026 the Pacific nations agreed a further 25% rise for 2027 and 2028. In Yezo's version, the Capitol must share out its larger slice, and Ōma's pole-and-line boats fear the big set-nets will take it. Purpose: "There's more tuna and more quota. Make sure {place:fishing\_grounds} gets its share, not just the big nets."

| # | Room (existing stage) | Where | Hours | What it's about |
| --- | --- | --- | --- | --- |
| 1 | Lobbyist Meeting on Fishing Quotas (ST28) | Either | 2 | Data Driven. The set-net operators' numbers |
| 2 | Hearing on Fishing Quota Reform (ST57) | Capitol | 4 | Data Driven. How the slice is divided |
| 3 | Committee on Foreign Affairs (ST14) | Capitol | 4 | Appeal. Yezo's place in the international commission |
| 4 | Press Conference (ST04) | Capitol | 2 | "Who gets the fish?" |

Rewards: Fisheries Cooperative +3 to +7, Rural Revitalization Council +1 to +4, Small Business Owners' Association +1 to +3, Constituency Voters +1 to +3. Settings: tuna season only (autumn and winter). Shares rooms with the Fisheries Quota Modernization Act (LV70).

### What the eight need

- **A protagonist lock.** No level column says "only this protagonist" today. Proposed: a Protagonist column on Levels (blank means all). A schema change, so Cameron's call.
- **Three new place types:** energy site, travel route and community hall (now in the catalog and the type list).
- **A way to name one row.** Tokens pick a protagonist's place by type, at random when there are several. Levels that need one place (Rokkasho's ports, the Ishikari Fish-House Baths) need a fixed pick, for example a place ID in the token.
- **Overlap with law levels.** Four Capitol levels share rooms with existing acts (LV34, LV55, LV70; LV61 for rail). Decide whether a win unlocks or discounts the act for that protagonist.
- **Optional, true trade-offs:** negative win deltas (for example −2 with the Consumer Advocacy Network on a casino win). No level uses one today, so the loader needs checking first.
- **Real names** in these levels fall under the brand-names action item.

## Promises, staff and events by location

**The same three tags (Capitol, District, Either) go on promises, events, office notices and the ticker, and the screens show only what belongs where the player stands.**

| Thing | Rule proposed | Edge to decide |
| --- | --- | --- |
| **Promises** | Each promise takes the location of the choice that made it, unless the choice row sets one. A location-locked promise can be kept only at its office; the Promises panel shows a badge and "Keep in the District". Either promises can be kept anywhere | Does travel time count toward the deadline? (It does today: hours are hours.) That makes a far district riskier for promises, which may be the point |
| **Hours promises** | "Spend 2 hours with the fishermen" is District-only by nature | Write it into the promise text, not just the tag |
| **Item promises** | Handing over a regional gift (the Bottle of District Sake) is District-only; a report for a committee is Capitol-only |  |
| **Random events** | Drawn only from the current location plus Either | Each office gets its own share of event slots, so neither goes quiet |
| **Follow-ups** | Fire at their own location. If the player is elsewhere, they wait until arrival, or for a deadline set by the row |  |
| **Buyable and dated events** | Buyable: from the office the item is used in. Dated: forced travel, as with a Floor Vote |  |
| **Visitors** | Fellow members visit the Capitol office; constituents' Office Hours belong to the District |  |
| **District Representative** | Their greeting (ON01, ON02) and the constituent notices (ON13 to ON16) move to the District office. Press and party notices stay in the Capitol | Do staff work from one office? Proposed: no, tasks run as today wherever the player is; the District Representative just appears in the District |
| **Staff tasks** | Unchanged mechanically. Tasks in the Constituents family read better from the District; their text can use place tokens |  |
| **Ticker** | One mixed national and local feed in both offices, by design. A new Location column on the Office Ticker tab (Capitol, District or Either; blank means Either) restricts a line to one office when it only makes sense there. Local lines may use place tokens |  |
| **Marketplace, Administration, Reputation and Results, How to Play** | Reachable from both offices |  |

## Dependencies

**About 35 pieces of work across six kinds. The heaviest are content (tagging 114 levels and 87 events, rewriting place text) and art (four district offices in three UI styles).** Sizes are rough: S under a day, M a few days, L a week or more of Claude Code and review.

| Kind | Item | Depends on | Size |
| --- | --- | --- | --- |
| **Data** | Location column on Levels, Events, Event Choices (promises), Office Notices and Office Ticker (Capitol, District or Either; blank means Either, so untagged ticker lines show everywhere) | Cameron approves new columns | M |
| Data | Places tab (protagonist × type) and the place-type list | Canon decisions on names | M |
| Data | Travel rows in Balance: hours per protagonist and mode, encounter chance, weekend travel rule | Decisions on hours | S |
| Data | Train Encounters tab (rider, question, four answers, effects), like the visitor and Office Hours tables | Format decision | M |
| Data | Ticket items in Shop: travel mode, hours saved, skips encounters, routes offered, and a standing effect on use (the paid train ticket: +2 with BO23, BO05 and BO14) | Prices | S |
| Data | Needs Place column on Events | Places tab | S |
| **Mechanics** | `GameState.location`, saved and migrated (old saves start in the Capitol) |  | S |
| Mechanics | Travel action: spend hours, roll an encounter, fade, arrive | Location state | M |
| Mechanics | Level gating by location: list only the levels at the player's office | Level tags | M |
| Mechanics | Event draw by location; follow-ups wait for the right office | Event tags | M |
| Mechanics | Promise location: keepable only at its office; warnings before travel | Choice tags | M |
| Mechanics | Forced Capitol events at the start of the week: staff reminder when known in advance, move to the Capitol at no hours cost (Balance row forced\_travel\_hours, default 0), other choices greyed out with a reason | Travel action | S |
| Mechanics | Week starts where the weekend ended (settled); save the location across the weekend | Decision | S |
| Mechanics | Place-token resolver in `Text.say` and event text, plus its checker | Places tab | M |
| Mechanics | Encounter room (dilemma format) and ticket use | Encounter tab | M |
| **UI** | District office screen, in Living Office, Broadcast and Woodblock | P9 style framework; art | L |
| UI | Travel strip with the train picture, drag to commit, tap fallback, mode choice | Art | M |
| UI | Fade and travel card |  | S |
| UI | Location badges on levels, promises and events; travel cost in the level list | Tags | S |
| UI | Living Office room objects for the District office (`office_hotspots` per background) | Backgrounds | M |
| **Content** | Location tags for 114 levels and 87 events, confirmed by Cameron | Audit | M |
| Content | Mixed levels (about 19): no action, travel is built in and not shown. Later: local press gaggle and local press conference rooms (questions, local reporters, rewards) | Decision | M |
| Content | Place catalogs for 4 protagonists | Canon | M |
| Content | Rewrite district text with place tokens (events, intros, transitions, visitor questions, ticker) | Catalogs | L |
| Content | District office narration and local ticker lines per protagonist | Catalogs | M |
| Content | Train encounter pool: about 8 rider types × 6 to 8 questions, with place tokens | Format | L |
| Content | Travel lines (strip labels, travel card, refusals, warnings) as Text rows |  | S |
| Content | How to Play page for travel |  | S |
| **Art** | District office background for each protagonist (and an upgraded version, as the Capitol office has) | Canon on each office | L |
| Art | Long horizontal train picture for the strip; plane and car versions for tickets |  | M |
| Art | Train interior background for encounters |  | S |
| Art | Encounter riders: silhouettes first (P7), drawn people later. District versions of the Either rooms' backgrounds: lobbyist meeting, policy study, the Office Hours room and possibly the ambush street (about 3 or 4 images, shared); later, the local press room | P7 | M |
| Art | Place backgrounds for key places (optional at first) | Catalogs | L |
| **Tests** | Save migration; travel hours; swipe commit threshold and tap fallback; level and promise gating; encounter rate over 1,000 trips; ticket skips; no unresolved token on any screen; text sweep and style parity on the District office | Each mechanic | M |
| **Other prompts** | **P5** re-simulation must include travel hours (the hours economy shifts). **P6** run shape: if the run ends in an election, District awareness weighs more. **P7** silhouettes cover unpainted riders. **P8** playtest logging must record trips and encounters. **P9** styles must draw the District office | Those prompts |  |
| **Docs** | `GAME_SYSTEMS.md` (hours, locations, travel), `INFORMATION_STANDARDS.md` (travel cost before choice), `CONTENT_GUIDE.md` (place canon) |  | S |

## Roadmap

**Six phases, each closed by a gate; the audit can start today, and content and build run side by side once the design is signed.** The phases follow the panel's rule: measure before changing.

*[Diagram in the source doc: 0 Decisions; 1 Audit (read-only, can start now); 2 Design build-out; 3 Content and art, side by side with 4 Build in four slices (A location, travel, level gating; B District office in three styles and the swipe; C place rules; D encounters and tickets); 5 Tune and test; 6 Release. Each phase ends at a gate.]*

Build slice A (location state, travel and level gating) needs only the confirmed tags and hours, so it can begin while the art is still being drawn. Slices B to D wait for their content and art. The prompts for Phases 2 to 6 get written after the audit, so its findings shape them.

## Action items for Cameron

- [ ] @Cameron **Edit brand names.** Confirm or change the proposed Yezo brands (the brand map under the catalog). Then give each real place a Yezo name, or mark it kept: Cape Sōya, Port of Wakkanai, Toyotomi Onsen, the Sarobetsu Plain, Port of Tomakomai, Mount Tarumae, Lake Utonai, Mount Teine, Maeda Forest Park, Hamanasu no Oka Park, Ishikari Bay New Port, Zenibako, Mount Osore and Bodaiji, Cape Ōma (and "Ōma tuna"), Yagen Onsen, Mutsu Bay, Lake Towada, the Oirase Gorge, Noheji, Rokkasho, and Lake Ogawara. The audit's place\_references.csv will add any real names already in game text.

## Open questions for Cameron

These gate Phase 2; the audit (Phase 1) can run before any of them is answered.

- [ ] 1\. Settled (Nov 19): train 6 / 1 / 1 / 6 and private car 5 / 1 / 1 / 9 game hours (PC01 to PC04); flights are not a travel mode. Still open: does Kenshin Sako stay "Easy" when a round trip by train takes 12 of the 40 hours?
- [ ] 2\. Settled (Nov 19): each week starts where the weekend ended. Also settled: a forced move to the Capitol costs no work hours (a Balance row, default 0, keeps a cost possible later).
- [ ] 3\. Can the player travel at the weekend, and does a weekend trip use the 8 weekend hours?
- [ ] 4\. Settled (Nov 19): mixed levels keep their rooms, with travel built in and not shown. Also settled: a mixed level is tagged by its overall shape (a bill, committee or media level is Capitol, even if it opens with a town hall); its hidden travel costs nothing; the player ends where they started it.
- [ ] 5\. Train encounters: a short dilemma (recommended), or a three-turn card room that can't be lost? And how often: about one trip in four?
- [ ] 6\. Do promise deadlines keep running during travel (as hours do today)?
- [ ] 7\. Do staff work from one office, or wherever the player is (recommended)?
- [ ] 8\. Canon: renaming real places and brands is now an action item (see Action items for Cameron). (The two blocks' areas are settled; see Each district's identity.) Rokkasho and Mutsu are inside. Are Misawa, Tohoku and Shichinohe inside Aomori Block 3?
- [ ] 9\. Which town hosts each block's district office: PC03 in Teine, western Kita Ward or Ishikari; PC04 in Mutsu, Towada or Noheji? Or several offices across a block?
- [ ] 10\. Tickets: which ship first (the paid train ticket needs the least new art)? Prices in Funds? For the paid train ticket: are BO23, BO05 and BO14 the right groups (the Small Business Owners' Association, BO25, is a candidate)? Does the +2 follow the usual scaling as proposed, or apply flat?
- [ ] 11\. Do the Capitol office's Living Office room objects stay as they are, with a new set for each District office?

## Phase 1 prompt: the audit

**A read-only pass that turns this doc's rough counts into tables Cameron can confirm row by row.** It changes no game code, data or workbook. Paste it into Claude Code at the repo root:

```text
Task P11 (audit): two offices, Capitol and District. READ-ONLY for the game.
Branch: review/p11-two-offices-audit, from main. Read CLAUDE.md first and follow it.
The design is in design/proposals/TWO_OFFICES_SPEC_2026-11-19.md: read it first.

Why: Cameron is splitting the Office into a Capitol office (Sapporo) and a district office per
protagonist, with travel between them costing work hours, a train swipe, chance encounters on
the train, and a catalog of named places per district. Before any build we need to know what in
the game is tied to a place. Do not change any game code, data or workbook. New scripts go
under audit/two_offices/ only.

Settled rules (spec section "Rules"), which every proposal must follow:
- The level list shows only levels at the player's office; a level starts only there.
- Either levels and Office Hours appear at both offices and never cost travel.
- A mixed level is tagged by its overall shape: a level built around a bill, a committee or
  the media is Capitol even if it opens with a town hall. Its travel is built in, costs
  nothing, and the player ends where they started. TV Debate is Capitol. The Chishima acts
  (LV35, LV53, LV74) are national and Capitol.
- Travel hours (train / car): PC01 6/5, PC02 1/1, PC03 1/1, PC04 6/9. Flights are not a mode.
- Forced (Decision!) events open the week, move the player to the Capitol at no hours cost,
  and grey out other choices. Each week starts where the weekend ended.

Write everything to design/review/p11_two_offices_audit_<date>/ (add a .gdignore):

1. levels_location.csv: every level, its stages (id and name), a proposed Location (Capitol,
   District, Either), a Mixed flag, a confidence (high, medium, low) and a one-line reason.
   Use stage modes, audiences, question pools, intros and transitions, not keywords alone.
1b. backgrounds_either.csv: for every room type that could be Either, its stages, its
   background today, whether that background reads as the Capitol, and the District
   background it would need. Note any OUT_* background in assets/backgrounds that could serve.
2. events_location.csv: every event with its class (Scenario = Random or Follow-up; Arranged =
   Buyable or a hosted event; Decision! = Dated), a proposed Location, and Needs Place (the
   place type the text assumes, from the spec's 24 archetypes). Same for event choices that
   make a promise (commitment, promise_kept): proposed promise location, and why.
2b. forced_and_dated.md: every Dated event, every forced level (the Urgent Matters Town Hall,
   the Steering Committee check-in, any other special_trigger), and Floor Vote timing: when
   each fires, whether the player can know it in advance, and which office it belongs to.
3. notices_ticker_location.csv: every Office Notice and Office Ticker line with a proposed
   office. The ticker is a mixed national and local feed by design, so most lines stay
   Either: flag only lines that would read wrong in one office.
4. place_references.csv: every player-facing text row (strings, events, choices, level intros,
   intro thoughts, transitions, visitor and visit questions, staff tasks, ticker, notices, how
   to play) that names or implies a district place or a real company or brand. Columns: table,
   key, the words, kind (place or brand), proposed place type and token, or the Yezo brand
   from the spec's brand map.
5. place_types.md: the place types the content actually needs, with counts, against the
   spec's 24 archetypes. Which types appear that the catalog lacks, and which nothing uses.
6. hours_impact.md: using the settled train and car hours, how much of a 40-hour week travel
   takes per protagonist, given the level mix in levels_location.csv. Use the sim logs or the
   strategy bot (audit/tests, tools/strategy_playtest) to estimate how often a week switches
   office. Forced moves and mixed-level travel cost nothing. State the method and every
   assumption, and say whether PC01 and PC04 look harder.
7. touchpoints.md: every screen, script, save field and test that a location would touch, with
   file and line: the Office, level list and briefing, Promises panel, events, visits, staff,
   ticker, notices, Floor Vote and dated events, crisis levels, week end and weekend, save and
   load (location must survive the weekend), the P9 style layouts (OfficeLayouts, RoomObjects,
   office_hotspots), and the interaction tests.
7b. feasibility.md: does the loader accept a negative win_delta_boXX (no level uses one); how
   the Seasons column is applied; where a Protagonist column on Levels would be read; what a
   place-ID token in Text.say would touch.
8. REPORT.md: a one-paragraph answer per item, the counts, the open questions the data raises,
   and the commit hash.

Rules: no change outside audit/two_offices/ and the report folder (git diff must show that).
All proposals are drafts for Cameron. Push the branch and stop. Do not merge.
```
