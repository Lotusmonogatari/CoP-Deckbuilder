# Art wiring plan: the District rooms and the trip row icons (2026-11-20, draft for Cameron)

Two small code changes, each well under 150 lines. Nothing is built until you say "Go". The rest of your uploads are already in: all 27 pictures are renamed to `.png`, the three ticket icons are on SH42 to SH44 and the six train interiors are on EV105 to EV110.

## 1. Executive summary

| Item | Proposal | Size |
|---|---|---|
| District rooms | When the player stands at the **District office**, the shared Lobbyist Meeting, Policy Study and Media Ambush rooms show one of the District pictures, picked at random, instead of the Capitol picture. The Capitol is unchanged. | About 25 lines in `ArtLoader`, one hand-written key in `data/art.json`, a test |
| Trip row icons | The travel-mode buttons (rail pass, paid ticket, private car, plane) show a small picture: your four icons. | About 40 lines in two places (the Office row and the level briefing's row), one hand-written key in `data/art.json`, a test |
| Legislature and Library pictures | Not wired: not on the art list. I need you to say where they go. | none yet |

## 2. The District rooms

| Question | Answer |
|---|---|
| Which stages | The shared rooms: ST19 Media Ambush (and the 5 stages that borrow it), ST20 Lobbyist Meeting (13) and ST21 Policy Study Session (13). Their Stages-tab Background ID is the shared picture today. |
| What changes | `ArtLoader.background_path` asks: is the player at the District office, and is this room one of those three? If so it uses the room's District list. The list lives in `data/art.json` (hand-written, with its own README) under a new key `district_backgrounds`, for example `"ST20": ["DISTRICT_LOBBYIST_MEETING", "DISTRICT_LOBBYIST_MEETING_2", "DISTRICT_LOBBYIST_MEETING_3", "DISTRICT_LOBBYIST_MEETING_4"]`. The pick is random and fixed while the room is on screen, the same way a stage with several pictures already behaves (`EventPicture.pick`). |
| Why `art.json` and not the Stages tab | The Stages tab cannot say "only at the District office"; a Background ID cell holds one picture or a list. A new workbook column would be a schema change. The key in `art.json` adds no column and no new rule. |
| What you will see | Play ST20, ST21 or ST19 (or any stage that borrows them) from the District office and one of the four District pictures shows; from the Capitol the usual picture shows. Missing art still falls back to a labelled placeholder. |
| What the pictures look like | They are four variants of a generic small-town street with cameras (the Ambush ones), not tied to one district, so random is the natural pick. |

**Decision for you:** random (my recommendation), or one picture for each protagonist (variant 1 for Kenshin, 2 for Haru, 3 for Arata, 4 for Jyurou)? The art list said "one picture shared by all four protagonists", and you sent four of each; if you meant them as one per protagonist, say so and the list is keyed by protagonist instead.

## 3. Icons on the trip row

| Question | Answer |
|---|---|
| Where | The mode buttons under the trip strip in the Office (`TravelMode_<mode>`) and the "Travel by" row in a mixed level's briefing. They are text only today. |
| What | A small picture at the left of each button: the rail pass takes `POLITICIAN_TRAIN_TICKET` (the member's card), the paid ticket `PAID_TRAIN_TICKET`, the car `PRIVATE_CAR_TRIP`, the plane `PLANE_TICKET`. |
| How | A new hand-written key in `data/art.json`, `travel_mode_icons`, maps each mode to its picture; the button's icon is that picture, scaled to the button's height. A missing file shows no icon, as before, never a blank square. Text, names and hours do not change. |
| Information standards | Unchanged: the button still says the mode, the hours and how many you hold. The picture is decoration beside it. |

## 4. Not wired, and why

| Pictures | Why |
|---|---|
| `DISTRICT_LEGISLATURE_1` to `_3` | Not on the art list. They show a legislative chamber. Tell me which room or screen they are for (for example the District version of the Floor Vote, a committee, or a level's picture) and I will propose how. |
| `DISTRICT_LIBRARY_1` and `_2` | Not on the art list. Same question. |

## 5. Tests I will add

| Test | Checks |
|---|---|
| District rooms | At the Capitol the three shared rooms resolve to their usual pictures; at the District each resolves to one of its District pictures; a stage that borrows a shared room follows it; a room that is not shared is never changed; every picture named in the key exists. |
| Trip row icons | Every mode has an icon entry; every named file exists; a button shows its icon and keeps its text. |

## 6. Order of work after "Go"

One commit for the District rooms, one for the icons, each with a full `verify.sh` pass, then a merge when you say so.
