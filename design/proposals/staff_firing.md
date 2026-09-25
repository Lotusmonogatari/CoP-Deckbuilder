# Proposal: firing (replacing) hired Staff

**Status: built (2026-09-25).** Cameron asked "how do I fire staff?" There
was no way to, on purpose (see §0). Built as scoped below, once Cameron
answered the five open questions — see §2 for the decisions and §3 for
what actually shipped.

## 0. What happens today, for contrast

The Recruitment shop (`OfficeScreen._show_staff()`) shows three roles —
Policy Research Assistant, Media Spokesperson, District Representative.
A vacant role lists its seven candidates with a Hire button; once filled,
that role shows only the hire and an Upgrade button (or "At their highest
tier" once there is nowhere further to go). There is no Fire/Replace
button anywhere, and `Ledger.staff_hire_refusal()` refuses a second hire
into a filled role outright ("Already yours.") — this is `Ledger.gd`'s
own comment: "no upgrades once a role is vacant (there is no 'fire')."

Hiring and each upgrade also pay out a **one-time** reward the moment
that tier is reached — a flat delta to one organisation's standing
(`BOxx`) or one segment's favourability (`SGxx`), per `data/staff.json`'s
`tier_N_reward` columns (e.g. SF01 hires in at "SG03 +1" — Constituents'
favourability). That delta is applied once
(`GameState._apply_staff_reward()`) and then simply becomes part of the
running standing/favourability total — nothing records that *this*
+1 came from *that* hire, the same way nothing records which press
answer produced an earlier +1. This matters for §2.

## 1. A shape for the flow

A **Fire** button on a filled role's row, next to Upgrade, asking a
confirmation first (reusing the `Overlay` confirm pattern IntroScreen and
Office Management already use for "this throws your run away" — see
`design/proposals/intro_screen.md` and `OfficeScreen._confirm_new_game()`).
Confirming clears `staff_hired[role]`, and the role goes back to showing
its seven candidates, including the one just fired (rehireable later at
their normal price and starting tier — see open question 2 on whether
that price should be normal).

## 2. Decisions (Cameron, 2026-09-25)

| # | Question | Answer |
|---|---|---|
| 1 | Does firing cost anything, or refund anything? | **Costs a severance.** 10% of hiring cost by default, but it's a real column in the Staff tab (`Firing Cost from Funds (Yen)` → `firing_cost_yen`) Cameron can price per candidate — not a hardcoded 10% in code. |
| 2 | Does the one-time standing/favourability reward get clawed back? | **No.** Firing never refunds anything already spent or already earned — the reward from hiring/upgrading stands. |
| 3 | Is there a cooldown on re-filling a role? | **No.** A role can be filled with a different candidate immediately after firing. |
| 4 | Can the fired candidate be re-hired at all? | **No, permanently.** They're greyed out with no Hire button wherever they'd otherwise be listed, for the rest of that run. |
| 5 | Does `office.staff_blurb` need a rewrite? | **Yes.** |

## 3. What was built

| File | Change |
|---|---|
| `design/CoP_Starter_Card_Stage_Data.xlsx` (Staff tab) | New column M, `Firing Cost from Funds (Yen)` — every existing row priced at 10% of its hiring cost, Cameron's to retune per candidate. Four new Text-tab rows (`office.fire_staff`, `office.fire_staff_warning`, `office.fire_staff_confirm`, `office.staff_fired`) and a rewritten `office.staff_blurb`. |
| `tools/export_data.py` | Staff column mapping reads `firing_cost_yen` from the new column. |
| `scripts/rules/Ledger.gd` | `staff_firing_cost()` (the workbook column, falling back to 10% of hiring cost for a hand-built candidate that lacks it), `staff_fire_refusal()`/`can_fire_staff()`. `staff_hire_refusal()`/`can_hire_staff()` gained a `fired` parameter — a fired candidate refuses with `office.staff_fired`, checked before every other reason. |
| `scripts/autoload/GameState.gd` | New `staff_fired: Dictionary` (staff_id → true, persisted in `_SAVED_FIELDS`), cleared by `reset_staff()`. New `fire_staff(role)`: pays the severance, empties the role, marks the candidate fired. Nothing about `hire_staff()`/`upgrade_staff()`'s spending or rewards changed. |
| `scripts/ui/OfficeScreen.gd` | A vacant role's candidate list greys out anyone already fired (no Hire button, just their name and "Fired — will not work for you again."). A filled role's row gets a Fire button beside Upgrade, behind a confirm `Overlay` (`_fire_staff_panel`, built in code like `_new_game_panel`) naming the severance cost before it's spent. |
| `tests/test_ledger.gd`, `tests/test_game_state_staff.gd`, `tests/test_save_load.gd` | The refusal rules, the state change (including the no-clawback and no-re-hire guarantees), and the save round-trip — the same coverage hiring/upgrading already had. |

Nothing in `scripts/rules/BattleEngine.gd`/`CardResolver.gd` was touched —
this stayed entirely an Office-side, meta-progression change.

## 4. What does NOT change

- Hiring and upgrading themselves — untouched.
- The one-role-per-hire rule — firing doesn't relax it, it's still exactly
  one hire per role at a time, just no longer a one-way door.
- `data/staff.json`'s reward columns — whatever §2 decides is handled in
  code, not by changing what a tier pays out.
