# Place worklist: the rows that need a decision

Follow-up to `place_references.csv` (2026-11-19). **That file has 14,131 rows because it also lists generic words** such as "district" and "committee" in the spoken cues. Only the real place names and the real brands and festivals need a person to decide. This is that part, grouped by text row: one line per table, key and field, with every name found, and a blank decision column. All proposals are drafts for Cameron.

## Executive summary

| | Hits | Text rows |
|---|---|---|
| Real names and real brands | 1174 | 945 |
| In casework tables (events, choices, visitor questions, intros, shop, staff tasks, strings) | 266 | 239 |
| In spoken and background tables (cues, question pools, transitions, ticker) | 908 | 706 |

Start with `place_worklist_casework.csv` (the rows a player reads as events, questions and intros). The other file adds the spoken tables.

## Where the hits are

| Table | Hits |
|---|---|
| player_cues | 420 |
| opponent_cues | 205 |
| visitor_questions (casework) | 158 |
| questions | 126 |
| office_ticker | 106 |
| transition_dialogue | 51 |
| events (casework) | 40 |
| stages (casework) | 21 |
| shop (casework) | 17 |
| levels (casework) | 10 |
| event_choices (casework) | 7 |
| event_options (casework) | 4 |
| level_intro_thoughts (casework) | 4 |
| level_intros (casework) | 3 |
| visitors (casework) | 1 |
| lobbyist_lines (casework) | 1 |

## The real names, by how often they appear

| Name | Hits | Type | Suggested handling |
|---|---|---|---|
| Sapporo | 174 | capital | Keep: Sapporo is the Capitol's city (canon). |
| Hokkaido | 168 | region | Canon decision: keep the real region name or replace it. |
| Tsugaru | 154 | landmark | Canon decision, or a place token when it is a generic lake, strait or mountain. |
| Hokkaido Shinkansen | 153 | travel_route | Canon decision: the Hokkaido Shinkansen is a bill name. |
| China | 148 | foreign | Keep: a foreign country or region. |
| Russia | 40 | foreign | Keep: a foreign country or region. |
| Aomori | 39 | town_hall | A named town: a place token, or keep when the text is about that very town. |
| Japan | 34 | foreign | Keep: a foreign country or region. |
| Hakodate | 24 | town_hall | A named town: a place token, or keep when the text is about that very town. |
| Otaru | 24 | town_hall | A named town: a place token, or keep when the text is about that very town. |
| Tomakomai | 21 | town_hall | A named town: a place token, or keep when the text is about that very town. |
| Hirosaki | 9 | town_hall | A named town: a place token, or keep when the text is about that very town. |
| Asahikawa | 6 | town_hall | A named town: a place token, or keep when the text is about that very town. |
| Kotoni | 6 | town_hall | A named town: a place token, or keep when the text is about that very town. |
| Korea | 6 | foreign | Keep: a foreign country or region. |
| Taiwan | 6 | foreign | Keep: a foreign country or region. |
| Asia | 6 | foreign | Keep: a foreign country or region. |
| Imabetsu | 5 | town_hall | A named town: a place token, or keep when the text is about that very town. |
| Kushiro | 5 | town_hall | A named town: a place token, or keep when the text is about that very town. |
| Tokyo | 5 | capital | Keep: Sapporo is the Capitol's city (canon). |
| Shari | 4 | town_hall | A named town: a place token, or keep when the text is about that very town. |
| Hachinohe | 4 | harbor | Check the line. |
| Yūbari | 4 | town_hall | A named town: a place token, or keep when the text is about that very town. |
| Sōya | 4 | landmark | Canon decision, or a place token when it is a generic lake, strait or mountain. |
| Esashi | 4 | harbor | Check the line. |
| Neputa | 4 | festival | Check the line. |
| Niseko | 4 | ski_area | Check the line. |
| Noboribetsu | 3 | onsen_town | Check the line. |
| Kitami | 3 | town_hall | A named town: a place token, or keep when the text is about that very town. |
| Akan | 3 | landmark | Canon decision, or a place token when it is a generic lake, strait or mountain. |
| Rausu | 3 | fishing_grounds | Check the line. |
| Mongolia | 3 | foreign | Keep: a foreign country or region. |
| Furano | 3 | farmland | Check the line. |
| Daisetsuzan | 3 | mountain | Check the line. |
| Muroran | 3 | harbor | Check the line. |
| Abashiri | 3 | town_hall | A named town: a place token, or keep when the text is about that very town. |
| Toyotomi | 2 | onsen_town | Check the line. |
| Memuro | 2 | farmland | Check the line. |
| Heiwa-dori | 2 | market | Check the line. |
| Ebetsu | 2 | town_hall | A named town: a place token, or keep when the text is about that very town. |
| ... 51 more names | | | see the CSV |

## The real brands and festivals (12 hits)

These are mostly regional culture (Nebuta and Neputa festivals, Tsugaru-nuri lacquerware, the Yoitomake call, haskap berries), not company brands, so `yezo_brand_map.csv` (which replaces companies and venues) covers almost none of them. The one company name is New Chitose Airport (VQ26). Whether regional culture stays real or becomes Yezo's own is a canon decision.

| Where | Words | Note |
|---|---|---|
| event_choices EV65.A | Yoitomake | Yoitomake (a real Aomori folk tune and festival call) |
| event_choices EV65.A | Haskap | Haskap (a real Hokkaido berry) |
| visitor_questions VQ26 | New Chitose | New Chitose Airport |
| visitor_questions VQ222 | Neputa | Nebuta / Neputa (real Aomori festivals) |
| visitor_questions VQ222 | Neputa | Nebuta / Neputa (real Aomori festivals) |
| visitor_questions VQ223 | Neputa | Nebuta / Neputa (real Aomori festivals) |
| visitor_questions VQ416 | Neputa | Nebuta / Neputa (real Aomori festivals) |
| shop SH26 | Tsugaru-nuri | Tsugaru-nuri (a real Aomori lacquerware craft) |
| shop SH31 | Nebuta | Nebuta / Neputa (real Aomori festivals) |
| shop SH31 | Nebuta | Nebuta / Neputa (real Aomori festivals) |
| shop SH33 | Yoitomake | Yoitomake (a real Aomori folk tune and festival call) |
| shop SH33 | Haskap | Haskap (a real Hokkaido berry) |

## Decisions this asks for

1. **Real region and nation names** (Hokkaido, Japan, Tsugaru, the Hokkaido Shinkansen): keep as real or replace with Yezo's. The names appear in bill titles and the ticker.
2. **Named towns** (Hakodate, Otaru, Tomakomai, Aomori, Hirosaki ...): which text is about that town (keep) and which only needs "a town" (a place token later).
3. **Regional culture** (the twelve brand and festival hits): real or Yezo's own.
