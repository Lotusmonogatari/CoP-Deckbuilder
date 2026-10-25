# Plan: decisions 6 and 7 of the content review (2026-10-25)

Mechanical fixes (decisions 2, 3, 4, 8) are applied and merged. Two decisions remain; both are big enough to need your OK first.

## Decision 6: re-cast the asker
**Why a plan.** Today the exporter picks an asker by rotation (`askers[len(pool) % len(askers)]`), so a first-person line like "Our union..." lands on whoever is next. The only existing control is `Asked By Party`.

| | Option A (recommended) | Option B |
|---|---|---|
| What | New optional column **Asked By Organization** (BOxx list) on Town Hall, Lobbyist, Press and Study Session Questions. Blank = rotation as now. A named organization restricts the pick to opponents whose Affiliation is that organization, falling back to rotation if nobody matches. | Reword the ~45 mismatched lines so any asker fits ("People I speak with care about..."). No schema change. |
| Schema change | Yes (one column, one exporter rule, one test) | None |
| Size | about 60 lines of code, then set the column on ~45 rows | ~45 edited lines |
| Risk | Low; blank keeps today's behavior | Lowest, but loses the first-person voice |

You chose "re-cast", which is Option A and needs your approval because it adds a column.

## Decision 7: reword duplicates and vary the templates
| Part | Scope | Plan |
|---|---|---|
| Near-duplicate pairs | about 35 pairs (A16/A33, A09/A28, A05/A20, T05/T08, T21/T22, L03/L12, L05/L19, L13/L15, L61/L62, Q21/Q22, sibling-stage duplicates S600/S603/S608 and similar) | Reword one of each pair using the reviewers' suggestions. One batch, listed in a table. |
| Vary template families | 180 themes x 8 frames = 1,440 questions in Stage Questions (rows S1041-S2480) | Replace 3 of the 8 frames per theme with hand-written, topic-specific questions (540 questions), with grades set by the topic rather than the frame. Marked draft for you to rewrite. Delivered in 6 batches of 30 themes, each reviewed by you or spot-checked by me before the next. |
| Not touched | the 439 opponent-cue template rows (OC2152-OC3030) | Out of scope for this decision; separate cue pass if you want it. |

## What I need from you
1. Approve Option A (new column) or choose Option B for decision 6.
2. Approve the template-varying plan (3 of 8 frames per theme, 6 batches) or shrink it (for example 2 frames, or only the 60 themes for bills).
