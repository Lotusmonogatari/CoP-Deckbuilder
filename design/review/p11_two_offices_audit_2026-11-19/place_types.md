# Place types the content needs, against the spec's 24 archetypes

Method: every player-facing text row (51905 rows from strings, events and choices, level intros and thoughts, stage names, transitions, visitor, visit and trade questions, staff tasks, the ticker, notices, How to Play, the shop, the room question pools and every spoken cue) is matched against the word lists in `audit/two_offices/lexicon.py`. **Strong** = a place noun (harbor, school, shrine); **weak** = a person or activity that implies a place (students, fishermen, harvest); **real names** = a place name found in the text, mapped to the type it would use. A row counts once per type however many times it says the word. These are drafts for Cameron: a word list finds candidates, it does not read context (for example 'plant' may be a factory or a seedling). **The 'all rows' counts include law and cue text** (the Ainu Heritage Act, the Shinkansen act, the Chishima island acts, spoken cues): that is text ABOUT a topic, not a district place the player stands in. The **casework** column (events, event choices, hosted events, visitor questions) is what a place catalog has to serve.

## The 24 archetypes: how much text points at each

| Archetype | Casework rows (events, choices, hosted, visitor questions) | All strong rows | Weak rows | Real names mapped to it (all rows / casework) | Example |
|---|---|---|---|---|---|
| town_hall | 16 | 106 | 60 | 182 / 92 | strings event.decline.EV41: village office |
| school | 107 | 816 | 717 | 0 / 0 | strings event.decline.EV42: school |
| travel_route | 97 | 1106 | 34 | 153 / 0 | events EV12: train |
| farmland | 68 | 872 | 664 | 7 / 7 | events EV69: farm |
| festival | 70 | 547 | 12 | 6 / 4 | events EV13: festival |
| market | 69 | 259 | 629 | 4 / 4 | events EV39: market |
| station | 52 | 436 | 0 | 4 / 4 | events EV12: station |
| hospital | 56 | 484 | 103 | 0 / 0 | events EV26: clinic |
| shrine_temple | 52 | 968 | 7 | 1 / 1 | events EV02: temple |
| harbor | 34 | 501 | 0 | 14 / 14 | strings event.decline.EV27: harbor |
| landmark | 21 | 38 | 106 | 171 / 18 | events EV48: lake |
| factory | 34 | 348 | 0 | 0 / 0 | events EV57: workshop |
| mountain | 13 | 17 | 6 | 6 / 6 | events EV02: hillside |
| university | 18 | 230 | 37 | 0 / 0 | events EV50: college |
| park | 18 | 172 | 15 | 0 / 0 | strings event.decline.EV67: park |
| district_office | 16 | 305 | 0 | 0 / 0 | strings staff.why_tenure: your office |
| fishing_grounds | 9 | 13 | 1249 | 5 / 5 | event_options HE02.1.DE1: scallops |
| ski_area | 10 | 31 | 244 | 4 / 4 | levels LV93: snow festival |
| onsen_town | 5 | 7 | 11 | 8 / 8 | visitor_questions VQ234: onsen |
| ainu_site | 12 | 979 | 0 | 1 / 1 | events EV49: ainu |
| community_hall | 9 | 11 | 40 | 0 / 0 | events EV90: community hall |
| energy_site | 4 | 38 | 198 | 1 / 1 | events EV82: turbine, wind turbine |
| island | 4 | 374 | 0 | 0 / 0 | level_intro_thoughts LV32: island |
| beach | 1 | 1 | 4 | 1 / 1 | visitor_questions VQ380: beach, drying racks |

**Catalog types that little or no casework uses today** (fewer than 5 casework rows by strong words and real names): `island`, `beach`. Several are needed by the new levels anyway (energy site, travel route, community hall, ski area, island). Islands appear only in the Rishiri text VQ380 used to carry, which is generic now.

**Archetypes in the spec but not in the catalog CSV's first column:** none.
**Archetypes in the catalog CSV that are not in this audit's list:** none.

## Place words the text uses that the catalog has no type for

These are nouns for places that district text names or implies but that none of the 24 archetypes covers. Each is a candidate for a new type, or for deciding the text should use an existing one (a library is a community hall, a street is a market, a road is a travel route).

| Candidate type | Casework rows | All rows | Example words | Where first seen | Suggestion |
|---|---|---|---|---|---|
| `housing` | 125 | 1272 | house | strings floor_vote.req_line | Houses, apartments and villages: the casework (an empty house, a fence). Generic: leave as `{district}`. |
| `street_or_neighborhood` | 96 | 1607 | corner | strings floor_vote.whip_discount | Many district events happen 'on the street' or 'in the neighborhood'. A candidate `street` type, which is also what the OUT_STREET backgrounds show. |
| `road_or_bridge` | 69 | 190 | road | events EV12 | Streetlight and pothole events: a District street. Candidate `street` type, or `market` (shopping street) for lanes. |
| `forest_or_wildlife` | 33 | 364 | bear | events EV42 | Bears and crows and wilderness text. Candidate `forest`; or fold into `mountain` and `park`. |
| `bank_or_credit_union` | 30 | 178 | bank | events EV60 | Money text, mostly loans. A generic word, not a named place: leave as is. |
| `restaurant_or_inn` | 27 | 45 | dining | strings office.cosmetics_slot_dining | Dinners, breakfasts, a restaurant. The DINING background exists. A candidate `restaurant`. |
| `care_facility` | 24 | 349 | elderly | event_choices EV66.C | Care homes and nurseries. Fold into `hospital` or add `care_home`. |
| `newsroom_or_studio` | 21 | 60 | newspaper | events EV03 | Radio and newspaper places. Capitol-side outlets are Yezo brands (Sapporo Broadcasting Center); a local radio station is a District place: candidate `radio_station`. |
| `police_or_fire` | 13 | 158 | police | event_choices EV68.A | Public-safety places. Fold into `town_hall` (a public office) unless events need them. |
| `library` | 12 | 16 | library | event_choices EV05.C | Spec: Policy Study in a local library or community room: fold into `community_hall` or add `library`. |
| `airport` | 10 | 33 | airline | strings event.decline.EV64 | Probably a new type, `airport`: the Chitose and flight lines; PC03 and PC04 would have different airports. Or fold into `travel_route`. |
| `sports_venue` | 9 | 11 | arena | strings characters.opponents_heading | Sumo, sports teams, arenas. A candidate `venue`, or fold into `community_hall`. |
| `river_or_flood_works` | 5 | 15 | ditch | strings event.decline.EV72 | Floods, ditches, dikes. Fold into `landmark` (river) or `farmland`. |

## Real place names in the text, by how many rows name them

| Name | Rows | Mapped type | Note |
|---|---|---|---|
| Sapporo | 174 | capital | Yezo's capital (CONTENT_GUIDE, Nov 9): the Capitol office's city; keep |
| Hokkaido | 168 | region | the real region name (Yezo is the nation): bills and the ticker use it; canon decision |
| Tsugaru | 154 | landmark | the Tsugaru region and strait (Aomori) |
| Hokkaido Shinkansen | 153 | travel_route | the real Shinkansen line (bill name) |
| China | 148 | foreign | a foreign country |
| Russia | 40 | foreign | a foreign country (a standing rival in the cues) |
| Aomori | 39 | town_hall | PC04's prefecture (the spec) |
| Japan | 34 | foreign | the real nation (Yezo is the game's nation); canon decision |
| Hakodate | 24 | town_hall | a Hokkaido city |
| Otaru | 24 | town_hall | a Hokkaido city |
| Tomakomai | 21 | town_hall | PC02's district town (the spec) |
| Hirosaki | 9 | town_hall | an Aomori city |
| Asahikawa | 6 | town_hall | a Hokkaido city |
| Kotoni | 6 | town_hall | a Sapporo ward area named in VQ01 and an event |
| Korea | 6 | foreign | a foreign country |
| Taiwan | 6 | foreign | a foreign territory |
| Asia | 6 | foreign | a continent |
| Imabetsu | 5 | town_hall | an Aomori town |
| Kushiro | 5 | town_hall | a Hokkaido city |
| Tokyo | 5 | capital | a national or foreign capital: national, not a district place |
| Shari | 4 | town_hall | a Hokkaido town |
| Hachinohe | 4 | harbor | an Aomori port city |
| Yūbari | 4 | town_hall | a Hokkaido town |
| Sōya | 4 | landmark | Cape Sōya / the Sōya region (PC01) |
| Esashi | 4 | harbor | a Hokkaido fishing town |
| Neputa | 4 | festival | an Aomori festival (Neputa/Nebuta) |
| Niseko | 4 | ski_area | a Hokkaido ski town |
| Noboribetsu | 3 | onsen_town | a Hokkaido onsen town |
| Kitami | 3 | town_hall | a Hokkaido city |
| Akan | 3 | landmark | Lake Akan, a Hokkaido landmark |
| Rausu | 3 | fishing_grounds | a Hokkaido fishing town |
| Mongolia | 3 | foreign | a foreign country |
| Furano | 3 | farmland | a Hokkaido farm and lavender town |
| Daisetsuzan | 3 | mountain | a Hokkaido mountain range |
| Muroran | 3 | harbor | a Hokkaido port city |
| Abashiri | 3 | town_hall | a Hokkaido city |
| Toyotomi | 2 | onsen_town | Toyotomi Onsen (PC01, the spec) |
| Memuro | 2 | farmland | a Hokkaido farm town |
| Heiwa-dori | 2 | market | a shopping street |
| Ebetsu | 2 | town_hall | a Hokkaido city |
| Iwamizawa | 2 | town_hall | a Hokkaido city |
| Europe | 2 | foreign | a continent |
| Honshu | 2 | region | the real main island: canon decision |
| Nishimeya | 2 | town_hall | an Aomori village |
| Ashoro | 2 | town_hall | a Hokkaido town |
| Ishikari | 2 | town_hall | Ishikari city (PC03) |
| Takayama | 2 | town_hall | a town |
| Itayanagi | 2 | town_hall | an Aomori town |
| Shikotsu | 2 | landmark | Lake Shikotsu, a Hokkaido landmark |
| Teshikaga | 2 | landmark | a Hokkaido town on Lake Kussharo and Mashu |
| Tanukikōji | 2 | market | a Sapporo shopping arcade |
| Monbetsu | 2 | harbor | a Hokkaido port town |
| Takikawa | 2 | town_hall | a Hokkaido city |
| Wakkanai | 2 | town_hall | PC01's district town (the spec) |
| Nebuta | 2 | festival | an Aomori festival |
| Matsumae | 1 | shrine_temple | a Hokkaido castle town (the temple-bell event) |
| Shin-Hakodate-Hokuto | 1 | station | Shin-Hakodate-Hokuto Station (the Shinkansen terminus) |
| Sukayu | 1 | onsen_town | Sukayu Onsen (Aomori) |
| Hakkōda | 1 | mountain | the Hakkōda Mountains (Aomori) |
| Tōya | 1 | landmark | Lake Tōya |
| Biei | 1 | farmland | a Hokkaido farm town |
| Ōnuma | 1 | landmark | Ōnuma quasi-national park |
| Chitose | 1 | station | Chitose, the Sapporo-area airport town (airport: not in the catalog) |
| Ōma | 1 | fishing_grounds | Cape Ōma, the tuna town (PC04, the spec) |
| Shakotan | 1 | beach | a Hokkaido coast peninsula |
| Biratori | 1 | ainu_site | a Hokkaido town known for Ainu culture |
| Shiretoko | 1 | landmark | a Hokkaido peninsula |
| Betsukai | 1 | farmland | a Hokkaido dairy town |
| Shimokawa | 1 | town_hall | a Hokkaido town |
| Mutsu | 1 | town_hall | Mutsu (PC04, the spec) |
| Kamishihoro | 1 | town_hall | a Hokkaido town |
| Goshogawara | 1 | town_hall | an Aomori city |
| Nishiokoppe | 1 | town_hall | a Hokkaido village |
| Sōunkyō | 1 | onsen_town | a Hokkaido onsen gorge |
| Jōzankei | 1 | onsen_town | a Sapporo onsen district |
| Susukino | 1 | landmark | Sapporo's entertainment district: Capitol-side, keep |
| Washō | 1 | landmark | a place name (Washō) |
| Shin-Aomori | 1 | station | Shin-Aomori Station |
| Tanesashi | 1 | landmark | an Aomori coast landmark |
| Rumoi | 1 | harbor | a Hokkaido port |
| Horonobe | 1 | energy_site | a Hokkaido town |
| Kiyosato | 1 | town_hall | a town |
| Nakashibetsu | 1 | town_hall | a Hokkaido town |
| Sarufutsu | 1 | fishing_grounds | a Hokkaido fishing village |
| Kuroishi | 1 | town_hall | an Aomori city |
| Pippu | 1 | town_hall | a Hokkaido town |
| Nanae | 1 | town_hall | a Hokkaido town |
| Shintoku | 1 | town_hall | a Hokkaido town |
| Gonō | 1 | station | a Gonō rail line stop (Aomori) |
| Usu | 1 | mountain | Mount Usu, a volcano |
| Tarumae | 1 | mountain | Mount Tarumae (PC02, the spec) |

## Names from the catalog that are already in game text

| Catalog name | Rows |
|---|---|
| Cape Sōya | 4 |
| Ishikari | 2 |
| Mount Tarumae | 1 |
| scallops | 3 |
| wind farms | 1 |

## Real brands from the spec's brand map that appear in game text

None. The text already uses invented outlet brands (Sapporo Digital Networks, Sapporo Broadcasting Center, Yezo Political Insider, Yezo News Nightly, Yezo Artisans Guild). The real names it does carry are places and cultural references (see place_references.csv, kind brand), not companies from the brand map.
