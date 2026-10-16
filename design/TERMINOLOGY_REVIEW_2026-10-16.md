# Terminology review (2026-10-16)

Scope: every English string a player can read (Text tab, cards, stages, modifiers, shop, staff, segments, tickers, How to Play), checked for one idea carrying several names, or one name carrying several ideas. **Findings only; nothing has been changed.**

## Executive summary

| | |
|---|---|
| Findings | 16 |
| High (a player will misread a mechanic) | 5 |
| Medium (inconsistent, understandable) | 7 |
| Low (spelling and polish) | 4 |
| Biggest single cause | The workbook mixes the designer's own words (Jiban, Kanban, Kaban, Donors) with the words the game screens use (Constituency support, Reputation, Funds). |
| Needs your decision | 6 questions at the end. |

## High severity

| # | The idea | Names in use now | Where the player sees it | Problem | Proposal |
|---|---|---|---|---|---|
| H1 | The money meta-variable | **Funds** (screens), **Yen** (prices, shop), **Funds (Yen)** (backing text), **円** (Office Notices), **Donors** (Office: "From donors and backers"), **Kaban** (design notes) | Office, Marketplace, Boosters, Staff | One resource, six labels. "Donors" also names an audience group (H2), so "From donors" reads as a link to that group. | Funds is the resource; Yen is the currency in prices ("25,000 Yen" is fine). Rewrite `office.funds_buys` to "Earned by winning stages. Buys the organisations' backing and staff." Drop "Funds (Yen)" to "Funds". Office Notices keep 円 only if you want local flavour. |
| H2 | The audience group **Donors** (SG04) | Donors; described as "Backers, business associations, Kōenkai members" | Cards (+3 if Donors ≥ 50%), the Details panel "In the room", Staff bonuses ("sentiment among Donors") | It is the only audience group named for money, not for who they are (Press, Party Members, Constituents, Bureaucrats are all roles). It also overlaps organisations (Kōenkai is BO03, business associations are BO05) and the Funds resource. | Rename to what they are, not what they give: **Backers** (the word the description already uses), or **Supporters** (but see H3). Recommend **Backers**. A one-cell rename in Segments plus the three cards' text and 3 staff bonus lines. |
| H3 | **Supporters / support** | "support" is used for: the bar ("Support", 22 rooms), Constituency support, Party support, "supporters" (card zoom line, "Rally the Faithful"), and "support" as a backing action ("the organisation's support") | Everywhere | The word means five things. "Being enhanced by supporters" in the card zoom does not say which audience group. | Keep "support" for the two meta-variables only. Rename the bar unit (see H4). Change the card zoom lines to "Being enhanced by this audience." |
| H4 | The bar's unit | Seats, Members, Support, Favourability, Appeasement, Consensus, Press tone, Viewer Interest | Win caption ("65 favourability"), the bar, briefings, modifier text | Eight names for one thing, "how many of the room are with you." Appeasement (Town Hall, Lobbyist) and Favourability (Hearing, Committee) read like different mechanics. A modifier says "ST06 TV Debate starts with +10 **Press tone**", but ST06's own bar is **Viewer Interest**. | Decide a short list. Recommend three: **Seats** (votes: floor, committee), **Support** (every shared pool bar), **Tone** (single bars: press, TV, with the room's own word in the caption). Fix M03's text to match the TV Debate's own unit now. |
| H5 | Meta-variable names in modifier text | "+2 **Jiban** after successful completion of a level" (4 backings) next to "+5 **Party support**", while the Office shows **Constituency support** | Boosters panel (the Effect column is shown verbatim) | The one meta-variable with a Japanese-origin name on screen. A player never sees "Jiban" anywhere else. | Replace "Jiban" with "Constituency support" in those four effect cells. (The code reads the Effect Target column, not the sentence.) |

## Medium severity

| # | The idea | Names in use now | Problem | Proposal |
|---|---|---|---|---|
| M1 | Organisations | Organisation (33), Booster (36), Stakeholder (7), "Important Stakeholders", Backing (30), "org" (2) | The screen buttons say Boosters and Important Stakeholders; the sentences say organisation and backing. | Pick: **organisation** in sentences, **Boosters** only as the Boosters panel's name, **Stakeholders** only for the standing screen. Reword the three blurbs so a backing is "what a booster does for you". |
| M2 | How an organisation feels about you | standing (42), sentiment (staff bonuses), mood (parties), favourability (parties and stages), opinion (party model) | Same idea, five words; "favourability" is also a bar unit (H4). | **Standing** for organisations; **opinion** for parties. Change "sentiment among {name}" to "standing with {name}" only when the name is an organisation; for audience groups say "approval among {name}". |
| M3 | Win line | threshold, win mark, "the line", "target" | The TV Debate says "the line", others "threshold"; code says "target segment". | Player text: **win mark** (matches the caption "to win"). Keep "threshold" in notes only. |
| M4 | Room / stage / battle | stage 172, battle 116, room 64, level 141 | "Stage", "room" and "battle" all mean one encounter. "Level" is the whole chapter. | **Level** (the chapter), **stage** (one encounter in it). Say "room" only for the audience in the room. Retire "battle" in headings. |
| M5 | The person across from you | Opponent (135), debater, rival, "that opponent" | Reporters and constituents are not opponents. | Keep Opponent in the engine and Details panel; for Press, Town Hall and Hearings use "questioner" where a line speaks of them. Low priority. |
| M6 | Party Members, Party Faction, Members of Parliament | SG02, BO02, BO17 | Three groups that sound alike. Party Headquarters and Party Faction are also "Party-tier". | Rename SG02 to **Party Rank-and-File**, or keep and rename BO17 to **Parliamentary Colleagues** (matches M45's name). Recommend renaming BO17. |
| M7 | XP | "Earned by winning stages. Buys new cards." | Stale. Cards come from Rhetoric Training, and XP also buys upgrades and staff. | Reword to "Earned by winning stages. Spent on Rhetoric Training and upgrades." |

## Low severity

| # | Item | Proposal |
|---|---|---|
| L1 | Spelling split: Favourability, Organisation, Neighbourhood (BO27), Colour against Favorability, Neighborhood (BO06), "Neighborhood Associations". | Choose one. The game uses American spelling in most Text rows ("Favorability"). Recommend American everywhere. About 40 cells. |
| L2 | "Gaffe" (71) with one "every slip" (`brief.gaffes.multiplied`) and 失言 in item text. | Use Gaffe everywhere. |
| L3 | Vote words: Aye/Nay everywhere, but "Your Record: no votes yet" and "Yes" still appears in a few notes. | Leave notes; no player text uses Yes/No now. |
| L4 | Marketplace / Supplies / Shop / Inventory / Items (the panel's own heading says Supplies, its button says Marketplace). | Already deliberate (2026-09-29). Mention only. |

## Decisions for you

| # | Question | My recommendation |
|---|---|---|
| 1 | Rename the audience group Donors (H2)? | Yes, to **Backers**. |
| 2 | One word for the bar's unit (H4)? | **Support** for shared pools, **Seats** for votes, **Tone** for single bars. |
| 3 | Replace Jiban in four backing texts (H5)? | Yes. |
| 4 | Spelling: American or British (L1)? | American. |
| 5 | Rename BO17 Members of Parliament to Parliamentary Colleagues (M6)? | Yes. |
| 6 | Do these go in one pass, or one group at a time? | One group at a time, H5 and H1 first. |

## Cost note

All changes are workbook cells or Text rows. None needs engine code, but **do not change** the four meta-variable names (Constituency support, Reputation, Funds, Party support): the code looks them up by name. Stage unit renames (H4) also touch the How to Play guide and the briefing. Cards that say "Donors ≥ 50%" read the segment ID, not the word, so a rename of SG04 is safe for rules; only the display text changes.
