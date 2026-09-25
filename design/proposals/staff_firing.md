# Proposal: firing (replacing) hired Staff

**Status: scoping only — nothing built yet.** Cameron asked "how do I fire
staff?" There currently is no way to, on purpose (see §0). This is the plan
for adding one, plus the decisions only Cameron can make before any code
gets written — CLAUDE.md's working agreement asks for this outline-first
where a task is nontrivial, and firing touches money, standing, and a
design call ("a role holds one hire for the run") that was made
deliberately, not by omission.

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

## 2. Open questions — Cameron's call, not mine

| # | Question | Why it's not mine to default |
|---|---|---|
| 1 | **Does firing cost anything, or refund anything?** A firing that's free and instant makes "hire the wrong one, fire them, hire the right one" essentially costless scouting. A firing that costs Funds (a severance) or refunds a fraction of the hiring cost are both reasonable, opposite designs. | Pure balance/tone call — how forgiving mis-hiring should feel. |
| 2 | **Does the one-time standing/favourability reward get clawed back?** Per §0, that delta isn't tracked as "belonging" to this hire once applied — it's merged into the pool. Clawing it back means adding bookkeeping (remember what each hire granted) that nothing else in the game does today; leaving it alone means firing someone is free standing, permanently, every time. | Changes the data model (`staff_hired` would need to remember its own grants) — a schema question, which CLAUDE.md asks me to raise rather than decide. |
| 3 | **Is there a cooldown, or a limit on how often a role can be re-filled?** Unlimited instant re-hiring turns Recruitment into a slot machine for the right one-time reward; a cooldown (a number of stages, or once per level) curbs that at the cost of complexity. | Balance/pacing call. |
| 4 | **Can the fired candidate be re-hired at all**, or are they gone from that save for good (so a "bad" hire is a real, permanent loss unless undone by firing)? | Design tone — how punishing a wrong hire should be. |
| 5 | Recruitment's own blurb text currently says "Each role can hold one hire at a time" with no mention of firing — if this ships, that Text-tab line (`office.staff_blurb`) needs a rewrite Cameron approves, the same as any other Text tab change. | CLAUDE.md: no sentence lives in a script, and text changes go through the workbook. |

My own recommendation, if useful: **no refund, no clawback, a modest
Funds cost to fire (severance), and free re-hiring afterwards** — it
keeps the one-time reward meaningful (you don't lose it once earned,
matching how nothing else in the game claws back a standing gain
either), while a real cost stops "fire and re-hire" from being a free
do-over. But this is a recommendation, not a default I'd build without
your answer.

## 3. What changes, file by file (once the above is answered)

| File | Change |
|---|---|
| `scripts/rules/Ledger.gd` | New `staff_fire_refusal()`/`can_fire_staff()` (empty-role guard, and whatever cost/cooldown check §2 lands on) |
| `scripts/autoload/GameState.gd` | New `fire_staff(role)`: clears `staff_hired[role]`, applies whatever cost or clawback §2 decides |
| `scripts/ui/OfficeScreen.gd` | `_staff_hired_row()` gets a Fire button beside Upgrade, behind an `Overlay` confirmation |
| `data/strings.json` (workbook) | `office.fire_staff` (button), a confirmation line, and a rewrite of `office.staff_blurb` if question 5 changes it |
| `tests/test_ledger.gd`, a new `tests/test_game_state_staff.gd` or similar | The refusal rules and the state change, the same coverage hiring/upgrading already have |

Nothing in `scripts/rules/BattleEngine.gd`/`CardResolver.gd` is touched —
this is entirely an Office-side, meta-progression change.

## 4. What does NOT change

- Hiring and upgrading themselves — untouched.
- The one-role-per-hire rule — firing doesn't relax it, it's still exactly
  one hire per role at a time, just no longer a one-way door.
- `data/staff.json`'s reward columns — whatever §2 decides is handled in
  code, not by changing what a tier pays out.
