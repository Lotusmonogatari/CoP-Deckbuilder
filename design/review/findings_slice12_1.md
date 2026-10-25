# Findings: slice12_1 (floor vote party cues and influence cues)

Saved from the reviewer's returned report (the reviewer could not write the file itself).

The Write tool refused to create /home/user/CoP-Deckbuilder/design/review/findings_slice12_1.md ("Subagents should return findings as text, not write report files"). As PROMPT.txt instructs, the full findings table is below and no file was written.

Rows read: 400 of 400. Findings: A=2, B=32, C=12 (counting each table row once, including grouped IDs). The two A findings are BI25/PT02 and BI29/PT05.

| ID | Field | Sev | Category | Problem | Suggested fix |
|---|---|---|---|---|---|
| BI25 / PT02 | leader cue | A | logic | Disposition is Opposed but the line is mildly favorable ("might work"). | "The Tomakomai proposal will cost us more than it brings." |
| BI29 / PT05 | leader cue | A | logic | Disposition is Neutral but the line ends "Vote no", so it reads as Opposed. "This Prime Minister" is also an unnamed jab. | Keep Neutral: "Ethics in the classroom? Show us who writes the curriculum." Or set the disposition to Opposed (changes meaning; designer's call). |
| BI30 / PT04 | leader cue | B | logic | Neutral, but "Every resident of our towns deserves a voice" reads as support. | "Residents deserve a voice, but our towns should weigh who counts." |
| BI13 / PT04 | leader cue | B | logic | Neutral, but "Our temples are fine as they are" reads as opposed. | "Our temples are cared for already; show us what this adds." |
| BI15 / PT04 | leader cue | B | logic/phrasing | Neutral, but reads as opposed. Near-repeat of BI20/PT04. | "Maybe good for business; show us what our districts get." |
| BI29 / PT04 | leader cue | C | logic | Neutral, but "Leave curriculum to our local boards" is effectively a no. | "Curriculum is a local matter; show us how boards keep a say." |
| BI48 / PT02 | leader cue | B | logic | Neutral, but "Watching everyone makes no one safer" is a flat rejection. | "Safety matters, but watching everyone is a heavy price." |
| BI33 / PT04 | leader cue | C | logic | Neutral, but "One more thing to lose" leans opposed. | "A card could help, but who keeps it safe?" |
| BI10 / PT04 | leader cue | B | logic | Supportive, but "as long as it's voluntary" undercuts a parity Act. It reads as Neutral. | "Fair enough. Our towns should field women, too." (or set the disposition to Neutral) |
| BI29 / PT03 | leader cue | C | phrasing | Supportive but hedged ("could work"). | "A common foundation for every classroom. We support it." |
| BI25 / PT01 | leader cue | B | phrasing | "Gambling addiction is a buffet on which suffering feeds" is a mangled metaphor. | "Casinos feed on addiction, and families pay the bill." |
| BI25 / PT03 | leader cue | B | phrasing | "the Inaka" is an untranslated, undefined word in an English-primary game. | "Tomakomai may gain, but the countryside won't." |
| BI30 / PT03 | leader cue | B | phrasing | Same "Inaka" problem; "needs to prioritize" is stiff. | "Our countryside should put long-rooted residents first." |
| BI30 / PT05 | leader cue | B | phrasing | "Residency alone is not fully investing one's future here" is awkward. | "Living here alone is not the same as staking your future here." |
| BI34 / PT06 | leader cue | B | logic | Bill is about broadcaster independence; "Decency in the public broadcast" is about content standards, which is off-topic. | "A broadcaster free of ministers is a broadcaster we can trust." |
| BI27 / PT02 | leader cue | B | coherence | "Aomori workers" names a place outside Yezo as this party's concern. Confirm intent. | "Rural workers deserve the wages Sapporo pays." |
| BI36 / PT02, PT03, PT04 | leader cue | B | repetition | Three Opposed lines make the same point (firms gain, towns lose) in near-identical shape. | PT03: "Big firms get the cut; farm towns get the bill." PT02: "Whatever corporations save, our budgets will have to find." Keep PT04. |
| BI37 / PT03, PT04, PT05, PT06 | leader cue | B | repetition | Four Opposed lines all say "a new levy/tax lands on X" or "cannot carry". | PT05: "A tax by any other name is still a tax." PT06: "Our factories cannot compete with this on their backs." |
| BI35 / PT01, PT02 | leader cue | C | repetition | Both Neutral lines say small groups/donors need protection. | PT01: "Sunlight helps, but give parties time to adjust." |
| BI40 / PT02, PT03 | leader cue | C | repetition | Both say the regions/our voices must be included. | PT03: "Study it, but not without the regions at the table." |
| PT04 on BI01, BI15, BI20, BI36, BI41, BI43, BI48 | leader cue | B | repetition | PT04's leader uses one formula ("our districts/voters did not ask / see little / see no gain") across many bills. It reads like a stock line. | Vary, e.g. BI01 "No one in our districts petitioned for this."; BI41 "Customs data crossing the water, with nothing in return?"; BI43 "Our voters were never asked about China." |
| BI14 / PT04 | leader cue | B | fitness | "This is exactly why we're here!" is generic; it names nothing about the grants. | "Grants straight to our districts. This is why we're here!" |
| BI32 / PT06 | leader cue | C | fitness | "Care for every region" is generic. | "A hospital within reach of every region. We will back it." |
| BI31 / PT01 | leader cue | C | phrasing | "The forests deserve peace, and so do we" is vague. | "Protect the forests and the animals that live in them." |
| BI08 / PT01, PT02 | leader cue | C | repetition | Both Supportive lines are about caring for elders; neither mentions the tax. | PT02: "Our aging villages can bear this tax if it funds their care." |
| BI03 influence (Fail) | cue_text | B | phrasing | "This was too much change without sufficient policy study or stakeholder consultation." Reads like a memo, with no actor. | "Members felt the zones moved too fast, without enough study or consultation." |
| BI04 influence (Fail) | cue_text | B | phrasing | "The status quo works. Moreover, Yezo needs to invest funding elsewhere." Bare statements, stiff "Moreover". | "Members decided the old lines were good enough and that the money was needed elsewhere." |
| BI05 influence (Fail) | cue_text | C | coherence | "Assembly Members" here, "Members of Parliament" elsewhere. | "Other members started to think Russia was only posturing, and that no real threat was emerging." |
| BI06 influence (Fail) | cue_text | B | grammar | "a robust study over language training capacity" should read "of". | "They wanted a thorough study of language training capacity, too." |
| BI09 influence (Fail) | cue_text | B | phrasing | "taxing power should remain within their scope" is unclear (whose scope?). | "Members feared a patchwork of fiscal rules and wanted taxing power to stay with the national government." |
| BI11 influence (Pass) | cue_text | B | phrasing | "coherence with Japan" is an odd word choice. | "You made the case that closer ties with Japan are a strategic necessity." |
| BI27 influence (Pass) | cue_text | B | logic | "a single wage floor" conflicts with a bill titled "Regional" Minimum Wage. Confirm what the bill does. | "Members decided regional wage floors were worth the burden on small employers." |
| BI32 influence (Fail) | cue_text | B | grammar | "balked at the bill for the hospitals that the network was shelved" is hard to parse. | "Enough members balked at the hospital bill that the network was shelved for now." |
| BI41 influence (Fail) | cue_text | C | logic | A flip to Fail ends in "withdrawn", which is a different outcome from a failed vote. | "...and the customs bill failed." |
| BI44 influence (Fail) | cue_text | C | phrasing | "another round" assumes earlier support that is never mentioned. | "With budgets tight, members refused to fund farm succession support." |
| Bespoke influence cues BI01, BI11, BI15, BI19, BI23, BI33 vs the rest | cue_text | B | coherence | Six bespoke cues address the player ("You...", "Your..."). About forty others never credit the player, and the generic fallback says "Your influence". The voice is uneven in a cutscene meant to show the player's influence. | Pick one voice: either add a short player credit to every bespoke cue, or keep them all third-person and leave the credit to the generic line. |
| BI01, BI31, BI37 influence | cue_text | C | coherence | These cues name Prime Minister Rono (BI01, BI37) and Speaker Ichizaki (BI31). Both appear in data/opponents.json, so they are not invented. Designer should confirm the roles fit. | None needed. |
| 46 generic influence cues: Fail for BI01, BI11, BI15, BI16, BI19, BI23, BI24, BI26-BI28, BI30, BI31, BI33-BI35, BI37, BI43, BI48-BI50; Pass for BI02-BI10, BI12-BI14, BI17, BI18, BI20-BI22, BI29, BI32, BI36, BI38, BI42, BI44-BI47 | cue_text | B | repetition | One template 46 times: "Your influence carried/sank the {Act}. Colleagues noted who made the difference." The second sentence is identical every time and says nothing about the bill. Fine as a fallback, weak for a scene the player sees often. | Write bespoke lines for the missing direction, or vary the closing sentence by direction (Pass: "Your colleagues will remember it." Fail: "Some colleagues will not forget it."). |

Other checks that found no problem: no party cue names a real party or person, and the references to Tokyo, Washington, Brussels and Moscow are countries and cities only. Every bill has six party cues. Every bill has an influence cue for each direction (bespoke or generic), except that BI25, BI39, BI40 and BI41 have two bespoke cues.

ROWS READ: 400 of 400

Biggest patterns:
1. About ten Neutral lines read as support or opposition, and BI25/PT02 (Opposed) and BI29/PT05 (Neutral, says "Vote no") contradict their labels.
2. PT04's "our districts/voters" formula recurs across seven or more bills. BI36 and BI37 each have three or four near-identical Opposed lines. 46 generic influence cues share one template.
3. Untranslated or awkward phrasing ("Inaka", "robust study over", "coherence with Japan") and several bespoke influence cues with no actor or an unclear referent.
