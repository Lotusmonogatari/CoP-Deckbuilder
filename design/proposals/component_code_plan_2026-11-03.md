# Component system code plan (2026-11-03)

This is Phase 4 of `design/prompts/COMPONENT_REVISION_PROMPTS_2026-11-03.md`. It is a plan only: nothing here is built until Cameron approves it. Items marked (D) need his decision first.

## Executive summary

| # | Change | Decision? | New lines (approx.) | Schema change |
|---|---|---|---|---|
| 4.1 | Show influence readiness on the Request and Draft panels | No | 70 | None; reuses existing Text rows |
| 4.2 | A Funds cap hint in the draft refusal | **Dropped** | 0 | Cameron answered "No change" on 2026-11-02 |
| 4.3 | Refund part of a draft's cost when it lapses at the hearing | (D) | 35 | 1 Balance row, 1 Text row |
| 4.4 | Show the hearing committee before the player commits | (D) | 40 | 1 or 2 Text rows |
| 4.5 | `carryable()`: real check or a "best case" label | (D) | 15 to 50 | 0 or 1 Text row |
| 4.6 | Member visit: a committee member about half the time | (D) | 20 | 1 Balance row |
| 4.7 | Weight the visited party by its seats outside Yes | No | 15 | None |
| 4.8 | Prefer the lobbyist who has spoken least among equally hurt organizations | No | 20 | None |
| 4.9 | Honest bot counters for drafts and visit wins | No | 40 | None (tools only) |
| 4.10 | A standing floor before drafting | (D) | 0 to 35 | 0 or 1 Balance row, 1 Text row |

Each item is built in its own commit with its tests, then `tools/verify.sh` runs. Afterwards `bill_audit.gd` and `bill_draft_probe.gd` are re-run and their output goes into the report.

## Items

### 4.1 Influence readiness on the panels

- **Now:** both panels say only "It will not pass unless you can sway other members." The Floor Vote screen alone lists what is missing.
- **Change:** move the Floor Vote screen's "Still needed: BO02 62 of 75, ..." builder (`FloorVoteScreen.gd` lines 210 to 235) into a new pure helper, `RequestLines.readiness_line(bill, triggers, meta, standing, threshold)`. The helper uses `VoteInfluence.status()` for the parties holding seats outside Yes. The Floor Vote screen, the Request panel (`OfficeScreen.gd` around line 2880) and the Draft panel (around line 2949) all call it.
- **Text:** reuses `floor_vote.influence_ready`, `floor_vote.influence_not_ready`, `floor_vote.influence_need` and `floor_vote.influence_more`. No new rows.
- **Tests:**
  - `test_request_lines.gd: test_readiness_line_lists_missing_rows`: with standing below the gate, the line names each missing row with "have of needed".
  - `test_readiness_line_ready_when_gate_passes`: passes the gate and gets the ready line.
  - `test_readiness_only_counts_parties_outside_yes`: a party-scoped row for a party already all Yes is not listed.
  - Click tests `requests_test` and `draft_test` assert the line appears on each panel.

### 4.3 (D) Refund on a lapsed draft

- **Change:** in `GameState._conclude_patron_level`, a drafted bill (prefix PD) that never reached its vote returns `draft_lapse_refund_percent` of the Funds cost. It still counts toward the cooldown. The result panel says so.
- **Balance:** `draft_lapse_refund_percent` (the value is the decision). XP is never refunded.
- **Text:** `draft.refund` ("Half your drafting money comes back: {funds}.").
- **Tests:** `test_draft_bill.gd: test_lapsed_draft_refunds_share` and `test_passed_or_failed_vote_never_refunds`.

### 4.4 (D) Hearing committee preview

- **Change:** the Draft panel shows "Hearing: Committee on Finance" as soon as a first part is picked, since the first part decides the committee. One option also adds the player's own record there, from `GameState.stage_type_results` ("You have won 2 of 5 here").
- **Text:** `draft.hearing` and optionally `draft.hearing_record`.
- **Tests:** `test_draft_bill.gd: test_hearing_preview_follows_first_part`; `draft_test` checks the line.

### 4.5 (D) `carryable()`

- **Now:** a draft is refused as "not winnable" only if it could not pass even with every gate open. It does not look at the player's real standing.
- **Options:**
  - (a) Keep the check and say plainly that it is a best case. 4.1 then shows what is really missing.
  - (b) Refuse drafts the player could not carry today. This would block almost every draft for most players.
  - (c) Leave it as it is.
- **Tests (a):** a click test asserts the best-case wording. **(b):** `test_patron_level.gd: test_carryable_uses_real_standing`.

### 4.6 (D) Committee-match compromise

- **Change:** `MpVisit.pick_member` rolls `visit_committee_member_percent`. On a hit it uses the party's members on the hearing committee, provided at least 3 sit there; otherwise it uses the whole party.
- **Balance:** `visit_committee_member_percent`.
- **Tests:** `test_mp_visit.gd: test_committee_share_follows_lever`: across 400 seeded draws, the committee share at 50 lands between 40 and 60, at 100 is all committee members, and at 0 is near the party's base rate.

### 4.7 Party weighting

- **Change:** `MpVisit.pick_party` draws a party weighted by its seats outside Yes, instead of every open party equally.
- **Tests:** `test_pick_party_weights_by_open_seats`: a party with 20 open seats is drawn about 4 times as often as one with 5.

### 4.8 Lobbyist spread

- **Change:** in `LobbyistTrade.pick_lobbyist`, among organizations hurt equally, order them by how often their lobbyists appear in `faced_people` (fewest first), with ties still shuffled.
- **Tests:** `test_lobbyist_trade.gd: test_tied_orgs_prefer_least_faced`.

### 4.9 Bot counters

- **Change:** `strategy_playtest.gd` and `playtest_optimal.gd` count draft attempts, drafts made, drafts lapsed at the hearing, drafts voted, drafts passed, visits held and visits won. These appear in the output JSON and in `strategy_report.py`.
- **Tests:** tools only. A short smoke run is checked by eye and quoted in the report.

### 4.10 (D) Standing floor for drafts

- **Options:**
  - (a) No floor (now).
  - (b) At least one owner of the chosen parts at `draft_min_owner_standing` or more.
  - (c) Every owner at that standing or more.
- **Text:** `draft.standing` ("No organization behind these parts trusts you enough yet.").
- **Tests:** `test_draft_bill.gd: test_standing_floor_refuses_below_and_allows_at`.
