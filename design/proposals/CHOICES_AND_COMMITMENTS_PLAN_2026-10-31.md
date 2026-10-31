# Player choices: an honesty audit, and commitments that cost something (plan, 2026-10-31)

Draft plan for Cameron. Nothing here is built.

## Executive summary

| Part | What | Size |
|---|---|---|
| A. Choice audit and rewrite | Every set of player choices (visitor dilemmas, event choices, hosted-event options, member-visit and lobbyist-trade answers) checked for length, detail and promises, then rewritten so each choice is a fair, honest position in a similar length | Content work in batches; a small report tool |
| B. Commitments | A choice that promises something now costs something: hours, Funds, an item, or a promise with a deadline that is checked later | A new mechanism (more than 150 lines): outline approved first |
| C. Character art | What generating the remaining character pictures would take | Prompts and processing yes; image generation is outside Claude |

## A. Choice audit and rewrite

**What the data shows today:** 455 choice sets. In 320 of them one choice is at least twice as long as another, and in 141 at least three times (for example VQ70: 8, 1, 3 and 2 words). 175 of 1,791 choices make an explicit promise ("I'll call the ward office myself today"), usually only the choice the writer favored, while the others read as dismissive one-liners ("Malls are the future.").

**Style rules (to confirm):**

| Rule | Target |
|---|---|
| Length band | Every choice 4-12 words; the longest no more than about 1.75 times the shortest |
| Honest from the player's point of view | Each choice is something a sincere legislator could say: a real position with its own reason, not a strawman or a joke |
| Same register | First person, plain speech, no stage directions |
| Detail parity | If one choice names a concrete step, the others name theirs ("I'll ask the ministry for a study" against "I'll back the shopkeepers' plan") |
| Promise honesty | A choice that promises an action is tagged with a commitment class (part B), so it costs what it promises |

**Steps:**
1. `tools/choice_audit.py` (new, read-only): per set, word counts, the longest-to-shortest ratio, promise phrases and a guessed commitment class; writes `design/review/CHOICE_AUDIT_*.md` sorted worst first.
2. Cameron confirms the rules (or edits them).
3. Rewrite in batches through `wbx` (visitor dilemmas first: about 400 questions; then events, hosted options, visit and trade answers). Effects and grades are left alone, so the Office Hours budget tests still hold; responses and reactions are adjusted only when a choice's meaning changes.
4. Re-run the audit after each batch; `--accept-wording` where Text-tab rows change.

## B. Commitments that cost something

**Commitment classes, written in a new column on each choice row** (Event Choices, Visitor Questions, Event Options):

| Class | Cell example | What happens |
|---|---|---|
| Stance | blank | Nothing beyond the choice's effects (most choices) |
| Time now | `Hours 2` | Spends the hours when chosen (greyed out with "Insufficient Work Hours" when they do not fit) |
| Money now | `Funds 30000` | Pays from Funds (greyed out with "Not enough Funds") - e.g. commissioning a study |
| Item now | `Item SH04` | Uses an owned item (greyed out with "Needs: ...") |
| Promise | `Promise SH40 48` or `Promise Hours 2 72` | Taken now, owed later: an item bought and handed over, or hours spent (a meeting with the mayor), within the given game hours; kept = a small bonus, broken = a penalty with the organization and Reputation |
| Follow-up | `Followup EV70` | Schedules a short follow-up event (the meeting itself) that arrives before a deadline |

**Pieces:**
- A promise tracker in the run (`GameState.promises`: what, for whom, due when, penalty), saved with the run, checked whenever the clock moves.
- An Office "Promises" box beside the dues box listing what is owed and by when; Your Record gets "kept / broke a promise to ..." causes.
- **Market goods** in the Marketplace: plain, cheap items bought to keep promises (flowers, a gift box, local sweets, a festival donation envelope, school supplies, a wreath), alongside the existing coffee and tea. When a promise names one, the Marketplace marks it.
- Balance levers: default promise deadline, kept bonus, broken penalty, and the goods' prices.
- Tests: the tracker rules (pure), a click test for promise, buy and keep, and one for a broken deadline.

**Order:** tracker and the Time/Money/Item classes first (they use machinery that exists), then Promise and Follow-up, then the goods and the content pass (tagging choices from the part A audit).

## C. Character art

**What remains** (neutral expression first): about 122 opponents (125 less the 3 drawn; the four protagonist rows need none), the 6 placeholder students, 166 visitors and two protagonists (PC02, PC03): about **296 pictures**. The full five-expression set would be about 1,500.

**What Claude can and cannot do:**
- Claude cannot generate images; neither can a chat Claude. The pictures have to come from Cameron's pipeline (Midjourney, ComiPo!, manual edits).
- Claude can do everything around it: write one prompt per character from the workbook (name, gender, role, party colour, organization, house style block from `design/ART_PROMPT_TEMPLATE.md`), in batches; check every delivered file (size, full body, transparent background, naming); cut out backgrounds (the `rembg` step used for PC01_RED); file them; update the Assets tab and the art checklist.

**Is it reasonable?** Yes for the prompts and processing (one session for all 296 prompts). Generating the images is the real cost: realistic in batches of 20-30. Keeping one face across five expressions needs a character reference (Midjourney's character reference, or ComiPo!, which poses a built character directly), so building each character once and posing it is the efficient route.
