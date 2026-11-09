# Writing review R1 (Interface): summary, 2026-11-09

Draft by Claude (reviewer R1) for Cameron. The ledger is `design/review/WRITING_REVIEW_R1_2026-11-09.csv`. Nothing in the workbook, `data/` or the scripts has been changed.

**Scope read in full (about 20,000 words):** `strings` (949 Text rows), `how_to_play` (34), `office_notices` (20), `office_ticker` (155), `shop` (35, name and description), `modifiers` (53, name and effect), `cards` (70, name and effect text) and `staff` (21, biography and role flavor). Lines whose context was unclear were checked against the code that calls them (`Text.say` in `scripts/`).

## Counts

The ledger has 119 rows: **102 proposed changes**, plus 17 sweep candidates that turned out to be true in context. Those 17 are recorded as "(no change)" with a reason, so every C1 to C4 sweep hit is accounted for.

| Code | Proposed changes | Sweep candidates cleared |
|---|---|---|
| C1 Once-only claim | 2 | 0 |
| C2 Unanchored reference | 0 | 3 |
| C3 Assumed history | 2 | 5 |
| C4 Wrong speaker or listener | 2 | 0 |
| C5 Machinery in speech | 1 | 0 |
| C6 Off-term | 32 | 2 |
| C7 Not American English | 7 | 0 |
| C8 Grammar and style | 46 | 0 |
| C9 Text does not match the mechanics | 7 | 0 |
| C10 Repetition in a pool | 0 | 0 |
| C11 Tone break | 2 | 0 |
| C12 Broken placeholder | 1 | 7 |
| **Total** | **102** | **17** |

By confidence: 18 high, 29 medium, 55 low. Most of the low ones are serial commas and hyphens.

| File | Rows read | Changes | Defect rate |
|---|---|---|---|
| strings | 949 | 32 | 3.4% |
| how_to_play | 34 entries (68 fields) | 16 | 47% of entries |
| office_ticker | 155 | 16 | 10% |
| shop | 35 | 23 | 66% of items (mostly "booster" and "buff" wording) |
| staff | 21 (42 fields) | 9 | 43% of people |
| office_notices | 20 | 3 | 15% |
| cards | 70 | 2 | 3% |
| modifiers | 53 | 1 (plus one Text row) | 2% |

These rates come from reading every row, not from sampling. Of the 24 sweep candidates for R1, 17 were false alarms: "energy" inside a bill's name, "You voted" shown only for bills you did vote on, and placeholder cells that list an unused value. The other 7 were real defects, though not always the defect the sweep named. For example, the SH04 to SH08 "first stage" hits were not once-only claims, but those items' descriptions are wrong when an item is used during a stage (C9).

No C10 echoes were found. The ticker's law lines reuse a few frames on purpose ("...leaves a gap that someone will try to fill"), but each one names a different bill and appears only once.

## The ten worst findings

| # | Row | Problem | Proposed |
|---|---|---|---|
| 1 | `strings` modifier.reputation_per_stage_win (C9, high) | Every Funds backing (M02, M05, M15, M20, M28, M38, M50) is shown as "Funds +N円 for every stage won", but the code pays once per **level** won (`ModifierEffects.level_win_resource_bonus`). | "Funds +{count}円 after each level you win." |
| 2 | `how_to_play` HT14 (C6, high) | The guide sends the player to "Boosters", but the button now reads "Backers". | "...backing in Backers..." |
| 3 | `how_to_play` HT34 (C6, high) | The guide says "Buy a Booster Dinner", but no item has that name (SH19 is the National Organization Outreach Dinner). | "Buy an Outreach Dinner or a Walking Tour" |
| 4 | `shop` SH01, SH02, SH03, SH19, SH20 (C6, high) | "booster group" and "relationship" appear in Marketplace descriptions. | "organization" and "standing" |
| 5 | `office_ticker` TK63, TK65 (C8, high) | "voted against the the"; "reaching our to". Both also put the outlet in the wrong place. | Fixed |
| 6 | `office_ticker` TK113 (C6, high) | "the list of "No" votes" | "Nay" |
| 7 | `strings` event.heading_followup (C3, medium) | "As you promised" heads every follow-up event, but follow-ups come from "Follow-up later" choices, which the code keeps separate from promises. | "Following up" |
| 8 | `shop` SH04 to SH08 (C9, medium) | "for the first stage of the next level played" is false when the item is used during a stage (it applies at once). | "+1 energy for your next stage, or the rest of this one if used mid-stage." |
| 9 | `strings` floor_vote.whip_discount (C12, medium) | "{orgs} are in your corner" reads "Fisheries Cooperative are..." when only one organization qualifies. | "In your corner: {orgs}. Every extra vote costs {amount} less." |
| 10 | British usage (C7) | "greyed-out" (HT20), "Monday to Friday" (HT30), "ring around" (EV41 decline), "dearer" (HT28, Campaign Pressure Harder blurb), "wellbeing" (TK24). | grayed-out, Monday through Friday, call around, costlier or pricier, well-being |

Also worth a look: `staff` SF09 and SF14 have obvious typos (a lowercase "it" starting a sentence; "after the a recent"). The `modifiers` M35 effect says "+10 Support" for a room whose bar is Consensus. `office.backing_blurb` says only answering reporters raises standing.

## Patterns across the interface

- **Serial comma.** 15 rows list three or more items without one. Each is a separate low-confidence row, so you can accept them all in one go.
- **"Booster", "buff", "modifier", "sentiment", "gate".** These internal words still appear in Marketplace and help text. Each has a fixed replacement (organization, backing, standing).
- **Hyphen versus minus and "x" versus "×".** A few rows use a hyphen for minus (`-{count}`) or a letter x where the rest of the game uses − and ×.
- **Developer fallback lines** (reward.nothing_set, battle.default_pattern, shop.*_no_id) talk about data and IDs. The player sees them only when data is missing. I marked them low.

## Questions for Cameron

1. **ON20: Cabinet Legislation Bureau Chief Rika Ashikaga.** This name appears nowhere else in the data. Is she canon? If not, should the notice say "The Cabinet Legislation Bureau Chief personally delivered..."?
2. **Naizen's posts.** TK22 calls Utemaru Naizen "Butsutou Party Leader", and TK23 and TK24 call Naizen "Minister of Ethics and Prosecution". Is that one person holding both posts, as intended?
3. **Card C16 "Table the White Paper."** In American English, "table" means to shelve something, which is the opposite of what the card does. I proposed "Produce the White Paper". Please choose a name, and check that the Japanese name still fits.
4. **The "Boosters" audience segment.** Card C24's effect text reads "every 20% Boosters". That is a segment name from the data, but the panel is now "Backers" and the sentence term is "organization". Should the segment be renamed? That would be a data change, so I have not proposed it.
5. **Duplicate backing names.** M05 and M25 are both "Agricultural Cooperatives"; M06 and M24 are both "Labor Federation". Is that intended, since they are different backings from the same organization?
6. **Staff biographies and canon.** SF09 mentions "single-member district seats", which implies an electoral system for the 101 seats. SF03 says Sheen grew up "after the war", which makes him about 65 or older in 2018. Are both fine?
7. **Ticker attribution format.** Many law lines name the outlet in the sentence and then end "- ☼" with nothing between the dash and the sun. TK148 and TK149 have no ☼ at all. Is that deliberate? If not, one rule (outlet after the dash) should be applied to all of them.
8. **TK09 to TK11** show only when Reputation is exactly 50. Is that intended, or should it be a range? (This is a condition, not wording.)
9. **brief.q.skip_costs.** "Skipping one costs {count}" gives no unit. I proposed "Tone", since the value comes from `decline_tone_cost`. Is it always Tone?
10. **"Room" as a word for a stage.** The interface uses "room" throughout ("In this room", "Each room favors", "Room rules", HT31 "the end of a room"). INFORMATION_STANDARDS lists "room" as a never-say term except for the audience in the room. Should "room" be accepted as the player-facing word for where a stage happens? I did not flag these rows, because changing them would touch dozens of lines and the card faces.
11. **Outside my scope:** the EV22 event flavor says "waits at the end of your surgery", which is British (C7). I am passing it to R6.
12. **modifier.reputation_per_stage_win.** Please confirm that once per level (what the code does, and what the workbook's Effect column says) is the intended rule. If once per stage was intended, the code is wrong, not the text.
