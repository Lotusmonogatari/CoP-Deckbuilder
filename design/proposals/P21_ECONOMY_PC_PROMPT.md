# P21: Economy — Political Capital, decay, Blunders!, Rumor! and Scandal!, credibility, PC sinks

**Branches:** five phases, each its own branch from `main`, merged in order:
`feature/p21a-pc-decay-dues`, `feature/p21b-blunders`, `feature/p21c-credibility`, `feature/p21d-rumors-scandals`, `feature/p21e-pc-sinks`.

**Start after P20 has merged** (P21 uses P20's favor list and its election-strength changes).

**Source:** Cameron's doc "Economy: Political Capital, decay, Blunders! and Scandals! — final guidance" (claude.ai, 2026-11-26). Everything needed from it is in this prompt and in `P21_CONTENT.md`.

**Approval.** Every schema, ID and data change listed here was decided or approved by Cameron on 2026-11-25 and 2026-11-26. This prompt is that approval for the listed items and nothing beyond them. If something you need is not listed, stop and ask. Follow CLAUDE.md: numbers are Balance rows, sentences are Text rows asked for by literal keys, pure rules in `scripts/rules/` with tests, UI separate, heavy comments, merge each phase only after `tools/verify.sh` prints "All checks passed".

**Out of scope:** floor-vote PC sinks (whip, delay, amendment); any change to how XP is earned; Election Day results.

**Every new number goes in the Balance rows listed in each phase.** Rows marked *proposed* are Claude's suggestions Cameron has not tuned: build them the same way.

---

## Phase A — Political Capital, decay, dues and the Funds cap (`feature/p21a-pc-decay-dues`)

### A1. The name
- Everywhere the player sees "XP", show **Political Capital** (short form **PC**). Text rows only; the data key, save field, Balance rows and code names stay `xp`. Update every Text row that says XP, and `design/EDITING_TEXT.md` if it names the currency.

### A2. PC decay (`scripts/rules/PcDecay.gd`)
- At week's end, after the week's spending and before the next week begins: `lost = floor((xp - xp_decay_floor) × xp_decay_percent / 100)` when `xp > xp_decay_floor`; `xp -= lost`. Never touches `xp_earned_total`.
- The Office shows, from Wednesday, how much will fade at week's end.
- Balance: `xp_decay_percent` 15, `xp_decay_floor` 300.
- Test: 1,000 → loses 105; 300 → 0; steady state with 620 earned a week and nothing spent ≈ 3,813.

### A3. Meter decay (in the week-end rules, `MetaRules` or a new `MeterDecay.gd`)
- Party support: −`party_support_decay_at_50` (5) a week while it is 50–74; −`party_support_decay_at_75` (8) while 75+. One step, not both. Never below 50 from this rule.
- District and National awareness: lose `awareness_decay_percent` (2) % of the distance above their start (`awareness_start_district` 20, `awareness_start_national` 10), rounded down, at least 1 when above the start.
- Applied at week's end after the week's gains. Constituency support, Reputation and organization decay are unchanged.

### A4. Decay holds
- **Shore up support**: for `decay_hold_xp` (200) PC, stop one meter's decay at this week's end: Party support, District awareness, National awareness, Constituency support or Reputation. Each consecutive week on the same meter adds `decay_hold_step_xp` (50); a week without resets it.
- **Keep in touch**: for `keep_in_touch_xp` (60) PC, stop one organization's decay at this week's end; +`keep_in_touch_step_xp` (20) each consecutive week on the same organization.
- Bought from the Office during the week. A hold never raises a meter.

### A5. The District 80 coupon
- Awareness Effects gains a **Once Per** column; AE02 gets `month`. The coupon pays at most once per calendar month. The exporter validates the column (`week` default, `month`).

### A6. Dues (`PartyDues.gd`)
- Limit = `dues_limit_cap_percent` (90) % of the player's current Funds cap (replaces `dues_max_per_week`; remove that row once nothing reads it).
- Dues paid = clamp(computed dues, `dues_base`, limit). Keep every other dues rule.
- Test: cap 100,000 → limit 90,000 (same as today); cap 1,000,000 → 900,000; computed 40,000 → 50,000.

### A7. Relief and the Funds cap
- **Dues bailout** (Office, only while dues are owed): `dues_bailout_xp` (100) PC for `dues_bailout_yen` (10,000) off dues owed, never below zero owed. Repeatable.
- **Cap Increase Petition** (SH13): price rises by its new **Cost Step XP** (50) each purchase: 100, 150, 200 … Still +100,000 cap, still up to 1,000,000.
- **Call on the party** (Office): with Party support over `cap_call_min_support` (70): pay `cap_call_party_support` (50) Party support and `cap_call_xp` (200) PC together for +`cap_call_yen` (500,000) cap above 1,000,000. Once per run.
- **Call on the financial industry** (Office): with Financial Industry Association (BO24) standing over `cap_call_finance_min_standing` (70): pay `cap_call_finance_standing` (40) BO24 standing and `cap_call_finance_xp` (150) PC for +`cap_call_finance_yen` (500,000) cap. Once per run.
- Sanban Funds maximum becomes 2,000,000. The cap calls require the cap to be at 1,000,000 first (proposed; ask if Cameron's data says otherwise).

### A8. Difficulty (proposed)
- Every PC price in P21 is multiplied by `xp_price_relaxed_percent` (85) on Relaxed and `xp_price_harder_percent` (115) on Harder, rounded to the nearest 5, the same way item prices follow Political Pressure.

---

## Phase B — gaffes and Blunders! (`feature/p21b-blunders`)

Replace `GameState.apply_awareness_gaffes` and its levers `awareness_gaffes_per_district_point` and `awareness_gaffes_per_national_point` with a pure rule `scripts/rules/Blunders.gd`. Keep `_record_lifetime_gaffes` and its 50-gaffe −15 Constituency penalty unchanged (decided: it stays).

- **Leftover gaffes** (after Difficulty's existing awareness gaffe percent) add to a run total.
- Each time the total passes another `awareness_gaffes_per_roll` (30): roll `awareness_gaffe_roll_chance` (0.2); on success −1 (`awareness_gaffe_roll_delta`) District and National.
- Each time the total passes another `blunder_gaffes_per_roll` (25): roll `blunder_chance` (1/3) for a **Blunder!**.
- Each stage lost to gaffes: roll `blunder_chance` for a Blunder!.
- **Blunder!**: `blunder_awareness_delta` (−10) District and National, never taking either below `blunder_floor` (21); a meter at 21 or less loses nothing.
- **Blunder! card**: shows the loss and, if a Media Spokesperson is hired and not lent or delegated, a **Cancel** button for `blunder_cancel_xp_tier_0/1/2` (200/150/100) PC by the highest spokesperson tier. Cancel removes the awareness loss.
- **Accusation roll** after the card: Scandal! with `blunder_scandal_chance` (1/8), checked first; otherwise Rumor! with `blunder_rumor_chance` (1/3). If cancelled, both chances × `blunder_cancelled_chance_factor` (0.5). Phase B only records the result as a pending accusation; phase D turns it into a card.
- All rolls use the run seed (reload gives the same results).
- The Office shows the Blunder! count and progress toward the next 30 and 25.
- Tests: totals crossing several thresholds in one stage roll once per threshold; the floor; cancel cost by tier; halved chances; determinism.

---

## Phase C — segments and credibility (`feature/p21c-credibility`)

- **Segment Map** tab (new → `data/segment_map.json`): Segment ID, Suit, Organizations (semicolons). Rows in `P21_CONTENT.md`. An organization may appear in several segments; every BO ID must exist; every segment needs one suit.
- **Suit plays**: record cards played by suit per week (the last `segment_suit_use_weeks`, 4, weeks).
- **`Segments.gd`** (pure): favorability = round(average standing of the segment's organizations × min(1, suit plays in the window ÷ `segment_suit_use_target` (20)) − debit), clamped 0–100. Stop reading `initial_favorability_pct`.
- **Credibility** = round(average of the five favorabilities).
- **Spending credibility** (phase D uses it): spending N adds N to every segment's debit, so credibility falls by N. Can't spend more than current credibility. Each week's end, every debit shrinks `credibility_debit_recovery_percent` (10) %, rounded down.
- Office: credibility and the five segments, each with its suit and organizations.
- Tests: the map loads; favorability formula; the cap at 1; debits and recovery; credibility can't go negative.

---

## Phase D — Rumor! and Scandal! (`feature/p21d-rumors-scandals`)

### D1. Data
Cameron exports the claude.ai Sheet **Rumor! and Scandal! pool** as .xlsx into `design/proposals/`. Add its tabs to the workbook:

| Tab | Columns kept | Export |
| --- | --- | --- |
| **Accusers** | ID (`AC##`), Accuser (EN), Title, Group (EN), Tracked Org ID, Name (JP), Romaji, Group (JP), Region, Manner, Status | `data/accusers.json`; only `Approved` rows are drawn (others export but are skipped, with an exporter note) |
| **Claims** | ID (`R##`, `S##`, `H##`), Kind (`Rumor!`/`Scandal!`), Fits (organization tastes, or `any`), Target (`Player`, `Colleague`, `Either`), Source (`Blunder!`, `Hand-made`), Status | `data/claims.json`; the Claim (EN) text becomes Text rows `claim.<id>`; rows with Status `To write` are skipped |
| **Outlets** | ID (`PR##`), Reach (`National`/`District`), Lodges | `data/outlets.json`; names become Text rows `outlet.<id>` |

The exporter checks Tracked Org IDs, that every Fits tag exists in Organization Tastes or is `any`, and the slots in claim text (`{player}`, `{accuser}`, `{accuser_title}`, `{group}`, `{accuser_full}`, `{outlet}`, and for colleague claims `{colleague}`).

### D2. Drawing an accusation (`scripts/rules/Accusations.gd`)
1. Organization: the tracked organization with the lowest standing under 15; with none under 15, the lowest standing; ties by seeded draw.
2. Accuser: an Approved Accusers row for that organization (seeded).
3. Claim: Kind matches; Fits overlaps the organization's likes; else an `any` row; no claim used in the last `claim_repeat_weeks` (8, proposed).
4. Outlet: a Scandal! from a National outlet; a Rumor! from any.
5. `{accuser_full}` = "{accuser}, {accuser_title} of the {group}".

### D3. Sources
- Blunder! accusations from phase B (target: the player).
- **Hand-made**: a Claims row with Source `Hand-made` can be fired by an event choice (`Activates`: `accusation:H01`) or a Decision Scene; its Target says who. A `Colleague` target picks a colleague as P20's `colleague` speaker does.
- **Growth**: a player Rumor! still unanswered `rumor_grow_weeks` (2) weeks after it was lodged becomes a Scandal! with the same accuser and organization (a Scandal! claim drawn for them).

### D4. The accusation card (player is the target)
| Option | Cost | Result |
| --- | --- | --- |
| Answer with credibility | `rumor_answer_credibility` 20 / `scandal_answer_credibility` 40 | Cleared |
| Answer with PC (needs a Media Spokesperson, highest tier, not lent or delegated) | `rumor_answer_xp_tier_0/1/2` 100/75/50; `scandal_answer_xp_tier_0/1/2` 250/200/150 | Cleared |
| Pay half (either currency) | Half the cost, rounded up | Half the penalty, rounded toward the player |
| Call in a favor (if any colleague owes one) | The favor is used | Rumor!: cleared. Scandal!: half the penalty (proposed) |
| Let it stand | — | The penalty lands now. A Rumor! stays open in the Office with a countdown and can still be answered (stopping the growth, not refunding the penalty) |

Penalties: Rumor! −`rumor_penalty_reputation` (5) Reputation and −`rumor_penalty_standing` (5) standing with the accuser's organization. Scandal! −`scandal_penalty_constituency` (10) Constituency support, −`scandal_penalty_reputation` (10) Reputation, −`scandal_penalty_standing` (10) standing.

### D5. Colleague accusations
- The card offers **Lend credibility** (20 for a Rumor!, 40 for a Scandal!) or **Stay out of it** (no cost).
- Lending clears it, adds a favor owed by that colleague (P20's favor list), and gives +`colleague_lend_reward_rumor` (2) / `_scandal` (4) Party Members segment favorability (as a negative debit on SG02, proposed).

### D6. Save
Open accusations (kind, target, accuser, claim, outlet, lodged date, grow date, answered), claim history, favors used.

### D7. Tests
Organization choice; accuser and claim fallbacks; no repeats in the window; Scandal! outlets are National; every answer path and its cost by tier; half pays half; favor paths; growth after 2 weeks and not after an answer; colleague lending.

---

## Phase E — PC sinks (`feature/p21e-pc-sinks`)

| Sink | Where | Price (Balance) | Effect | Limit |
| --- | --- | --- | --- | --- |
| **Trim the deck** | Shop item (new ID after the last SH) | `trim_deck_xp` 75, +`trim_deck_step_xp` 25 each purchase (proposed) | Pick one card in the deck; it is removed for the run | Never below the minimum deck size the game already enforces; if there is none, ask |
| **Mentoring** | Staff screen | `mentoring_xp` 100 | Cancels the Loyalty loss from this week's unpaid or late wage for one person (`StaffLoyalty.after_week` skips it) | Once per staff member per week |
| **Pep talk** | Staff screen | `pep_talk_xp` 60 | +`pep_talk_loyalty` (5) Loyalty | Once per staff member per week |
| **Reserved table** | Cafeteria (VN01) | `venue_reserved_table_xp` 40 | Two more lines that day, one of them a tip slot | Once a day |
| **Rush request** | Library reference desk (VN02) | `rush_request_xp` 60 | A reading without its 2 hours | Once a day |
| **Private session** | Speech Coach (VN04) | `private_session_xp` 100, +`private_session_step_xp` 25 each use in a week | One more look in Rhetoric Training | — |
| **Backstage pass** | Sapporo Stage (VN05) | `backstage_pass_xp` 80 | The meet-and-greet offers a fourth, stronger choice | Once per show |
| **Rush a favor** | Super Station (VN06) | `rush_favor_xp` 50 | A member quest stop takes half its hours | Once per quest |
| **Committee seat** | Office | `committee_seat_xp` 500 | +`committee_seat_start_bonus` (5) starting support in every room of that committee (the stage's committee from its data), for the run | Seats held ≤ Policy Research Assistant's highest hired tier + 1; needs one hired |
| **Rare books room** | Library (VN02) | `rare_books_xp` 200 | Opens the Codex histories and adds a room-file category (from P18) | Once |

- A venue sink ships only where its feature is already on `main` (the meet-and-greet, member quests and Codex may not be). List any you skip in the report; do not build the missing feature.
- Every sink states its price and limit on its button, and is disabled with a reason Text row when it can't be bought.
- Tests per sink: price, escalation, limit, and effect.

---

## Checks before each merge

- `tools/verify.sh` prints "All checks passed"; the exporter runs clean.
- If `tools/economy_map.py` is on `main`, add every new flow (PC decay, holds, bailout, cap calls, Blunders!, accusations, sinks) so `--check` passes.
- A scripted run of one game year (Relaxed) after phase E. Note in the change log: weeks to Party support 75; District and National awareness at the year's end; PC earned against spent; Blunders!, Rumors! and Scandals!; credibility at the year's end.
- Change log (CLAUDE.md section 15): one line per phase, "(2026-11-26, Cameron; branch …)".

## Finish

Report per phase: files changed, new tabs and Balance rows, test counts, and every choice this prompt did not settle, as a question for Cameron.
