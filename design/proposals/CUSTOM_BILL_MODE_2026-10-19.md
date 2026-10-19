# Custom Bill mode: plan for approval (2026-10-19)

Status: **proposal only, nothing built.** Cameron's four decisions are applied:
a separate mode (existing levels untouched); the player picks from components;
content is pre-written and tagged to a component pool; the bill's name and text
are assembled from per-component phrases.

## 1. How it plays

1. Office, new button **Draft a Bill**. The player picks 2 or 3 **components**
   (for example "lower taxes on food" + "restrict foreign food imports").
2. A live preview shows the assembled bill name, which parties lean which way,
   and which organizations gain or lose, before the player commits.
3. Confirming builds a level from a **level template** and starts it through
   the normal Level Intro (Support / Oppose lean), stages, and Floor Vote.
4. The vote result goes to the statute book under "Your own bills".

## 2. What is reused, what is new

| Piece | Reused as is | New |
|---|---|---|
| Stage families (caucus, hearing, Town Hall, press, vote) | Yes, the generic rooms | A level template listing which families, in order |
| Floor Vote, stance, influence swing, statute book | Yes | A runtime bill record in the same shape as a `floor_votes.json` row |
| Bill-scoped content (questions, cues, transitions) | The mechanism (rows tagged to a key, dealt up to the 50% share) | A **Component ID** tag, so one level draws from several components |
| Party positions | The shapes (Supportive ~79% Yes, and so on) | Computed in code from component tags and Cameron's party values |
| Organization effects (law effects) | The format | Summed from the components' own effect lists |
| Bill name and text | Text-tab pattern | Built from component phrases |

## 3. Data (schema changes: need your approval)

| New tab or column | Purpose |
|---|---|
| **Bill Components** tab, one row per component (CBxx) | Name fields: Short Label, Phrase ("lower taxes on food"), Description sentence. Topic Area. Excludes (components that can't be combined). Value Tags (party-value dimensions, e.g. `ECON+0.8; TRADE-0.6`). Winners / Losers (organization lists, same format as Law Effects). Committee (which hearing family). Size (feeds tier and rewards). |
| **Party Values** tab (or JSON) | Your 34-dimension table (value, priority, salience per party), so the game can compute positions. Today it is only a reference file nothing reads. |
| **Custom Level Template** tab | Ordered stage slots, tier rule, reward rule, stage numbers copied from the existing families. |
| **Component ID** column on Stage Questions, Player Cues, Opponent Cues, Transition Dialogue, Level Intro Thoughts | Tags content to a component. Optional **Stance** works as it does for bills. |
| Balance levers | Components per bill (2 or 3), position threshold (30), reward scale for custom laws, cooldown or cost. |
| Text rows | `custom_bill.name_2`, `custom_bill.name_3` ("A bill to {a} and {b}"), builder screen wording. |

## 4. Rules (pure code, no UI)

- `CustomBill.compose(component_ids)` checks Excludes and the component count,
  and returns the bill record: name, description, positions, law effects,
  vote requirement.
- Party lean = sum over components of (tag × party salience); the existing
  rule applies (|lean| at or above the threshold takes a side, below it is
  Neutral); splits follow the Supportive / Opposed / Neutral shapes.
  Deterministic, no rolls.
- Law effects = components' winner and loser lists merged, clamped, then scaled
  by a "custom law" lever so this mode is not a grinding route.
- Content draw: for a custom level, the bill-scoped share (50%) is split
  evenly across the chosen components. Generic room content still fills the rest.
- The runtime level and bill are registered in `DataDB` for the run and saved
  in `GameState` (components, stance, result), so resume works.

## 5. Content to write (all drafts for you to rewrite)

Per component: 8 questions, 12 Player Cue rows, 18 Opponent Cue rows, 4
Transition rows, 3 Level Intro Thoughts. Written about the component alone
(never "this bill", never the other components), so any mix reads naturally.

| Batch | Components | Approx. rows |
|---|---|---|
| First | 12 (3 topic areas × 4) | ~430 questions/cues/transitions |
| Second | 12 more (6 topic areas × 4 in all) | ~430 more |

Generated with the same batch-script method as the 50 bills, checked by the
existing audits (tone, time words, length) and the three-times rule.

## 6. Build order (each step stops for your review)

| Step | Work | Output |
|---|---|---|
| A | Schema, exporter checks, pure rules, GUT tests, 4 sample components | Rules proven headless |
| B | Component-tagged content lookup, level builder, routing, save/resume | A custom level plays end to end (test driver) |
| C | Builder screen, Office button, preview, real-click test in `verify.sh` | Playable in the app |
| D | First content batch (12 components), bot trials, balance | Shippable draft |
| E | Second batch, unlock rules if wanted | Full pool |

Steps A–C are well over 150 lines of code, so this plan comes first and I wait
for approval before starting.

## 7. Questions for you

| # | Question | My recommendation |
|---|---|---|
| 1 | 2 components, 3, or either? | 2 or 3, chosen by the player (a lever) |
| 2 | Free pick, or one slot per topic area? | Free pick, with an Excludes list for contradictions |
| 3 | Repeatable? Cost or cooldown to draft a bill? | Repeatable, each bill is one-time, costs Reputation and Funds |
| 4 | Do custom laws change standing and party opinion fully, partly, or not at all? | Partly (reward scale lever, first draft 50%) |
| 5 | Which components unlock first? | All open in the first version; unlock by authored bills later |
| 6 | Oppose-stance content: write separate Support and Oppose variants per component? | Yes, as for bills (cues only; questions stay neutral) |
| 7 | Fixed level shape, or does the first component's topic choose the hearing committee? | Topic chooses the committee |
| 8 | A custom bill's name: also a Japanese accent? | No for now, same as existing bills |

## 8. Risks

- **Odd pairings** (a tax cut plus a spending rise): handled by Excludes, and by
  accepting that tension makes good debate; the preview shows the lean.
- **Balance**: stage numbers come from the template, so the same bot trials
  used for the bill levels apply.
- **Volume**: 24 components is a lot of drafting; start with 12.
