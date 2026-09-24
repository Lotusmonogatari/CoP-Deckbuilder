# Proposal: Item inventory, the Supplies shop, and item use

**Status: built (2026-09-25).** Written as a plan for Cameron's nine-point
request, then built after his answers. **Section 0 is the authoritative
description of what exists.** Sections 1–8 are the plan that led to it, and
Section 0 notes where the build differs from them.

## 0. What was built, after Cameron's answers

**Cameron's decisions (2026-09-25):**

| Question | Answer |
|---|---|
| Where can an item be used? | A Yes/No cell per item, for every category of item, so a cosmetic could later be made usable in a stage without code. **Where** and **how long** are separate columns |
| Using an item in a stage | Free, not a card play, **once per turn by default**, with a per-item cell to raise that cap |
| Office Hours shop-item rewards | Go **into the inventory**, like a purchase, for consistency |
| Buy and stack limits | A **Stack Cap** column, shown in the item's pop-up. A **Purchase Limit** column that resets when a level concludes, win or loss. A sold-out item is greyed out with "Out of Stock", and that wording is editable in the Text tab |

**Shop tab columns** (all optional; blank means the default shown):

| Column | Meaning | Blank means |
|---|---|---|
| Grants | What using it does (`target_delta_list`). Accepts booster, modifier, segment and item targets, the stage-effect words `ENERGY` `GUARD` `DRAW` `TURNS` `GAFFE_CAP`, and pools such as `BO01\|BO02 +1` | Nothing: the item is refused with "no effect set yet" rather than being used up |
| Icon | File name in `assets/icons/`, without `.png` | The item ID. A missing file shows a blue square |
| Use In Office | Yes/No: can **Use** be pressed in the Office | No |
| Use In Stage | Yes/No: can **Use** be pressed during a stage | No |
| Duration | `Stage` or `Level`: how long a stage effect lasts | Stage |
| Uses Per Turn | How many times it can be used per turn in a stage | 1 |
| Stack Cap | The most the player may hold | No cap |
| Purchase Limit | The most that can be bought per level | No limit |

**How the timing works:**

| Where it's used | Duration Stage | Duration Level |
|---|---|---|
| Office | Applies to the next stage only | Applies to every stage of the next level |
| During a stage | Applies now, for the rest of this stage | Applies now, and to every later stage of this level |

Booster, segment and modifier effects apply immediately wherever the item is
used.

**Values filled in the real workbook.** These are proposals for Cameron to
change in the Shop tab:

| Items | Grants | Where | Duration | Stack / Purchase limit |
|---|---|---|---|---|
| SH01–SH03 | `BO01\|BO02 +1`, all National-tier boosters `+2`, all Constituency-tier boosters `+2` | Office only | — | Purchase limit 1 per level ("once per Office screen") |
| SH04–SH08 (Coffee, Tea, Paperwork, Wristwatch, Meditation) | `ENERGY` / `GAFFE_CAP` / `DRAW` / `TURNS` / `GUARD` `+1` | Office and stage | Stage | — |
| SH20–SH24 (level buffs) | Same five effects, `+1` | Office and stage | Level | Stack cap and purchase limit both set to the "+N per level" number in each item's own text (2, 3, 5, 5, 3) |
| All others | Blank | No / No | — | — |

**Code:**

| File | Role |
|---|---|
| `scripts/rules/Items.gd` (new) | Pure rules: where an item works, duration, caps and limits, and refusals |
| `RewardTargets.gd` | Adds the stage-effect words and pool support |
| `BattleEngine.gd` | Reads `item_bonuses` at setup. New `use_item()` enforces Uses Per Turn and resets the count each turn. `turn_limit()` includes turns added by items |
| `GameState.gd` | `inventory`, `buy_shop_item()`, `use_item_in_office()`, `use_item_in_stage()`, the queues for the next stage and next level, and the per-level purchase counts |
| `InventoryPanel.gd` (new) | The grid and the item pop-up, shared by the Office and the stage |
| `OfficeScreen.gd` | Inventory button, and the Supplies shop inside Office Management |
| `BattleScreen.gd` | Inventory button beside Details. Passes item bonuses into each stage |
| `ArtLoader.item_icon()` | Loads an item icon, or the blue fallback square |

The Text tab gained 32 rows for the new screens and messages. The same pass
added the five keys whose absence made every export report errors.

**A bug found and fixed along the way.** `Overlay` set only its anchors. That
works for panels placed in a scene file, but a panel built in code stayed
0×0, so its buttons were drawn on screen and ignored every tap. The new
inventory click test found it before any player could.

**Tests:** `test_items.gd`, `test_battle_items.gd` and `test_inventory.gd`,
plus the rewritten Office Hours reward tests. There is also a new real-click
test, `tests/interaction/inventory_test.tscn`, which buys in Supplies, uses an
item in the Office, checks the next stage starts with the bonus, then uses an
item mid-stage. It runs in `tools/verify.sh`. 618 unit tests and all three
click tests pass.

**Still open:** Q8 (per-item use text), and the XP price that rises with each
extra stack in SH20–SH24's own text. That last one is not built: each stack
currently costs the same (confirmed correct by Cameron, 2026-09-26 — SH20–24
cost the same per purchase and stack to their cap).

## 0.1 Follow-up: SH25/26's picker, and the SH01–03 staff bonus (2026-09-26)

Cameron asked for three things, answered here in order, plus a fourth: he
invited a structural change if one would cut code complexity.

**1. SH25/SH26 ("player-selected" group) now have a real picker.** Both
items' Grants are filled in (`SH25` = `TIER:National +2`, `SH26` =
`TIER:Constituency +1`) and marked **Player Choice = Yes**. Pressing Use on
a Player Choice item opens a third `InventoryPanel` view instead of using it
straight away: a grid of every booster in the item's group, each button
showing that booster's current standing. Tapping one applies the item to
that booster only and closes the picker. `DataDB.choice_options()` builds
the grid live from `DataDB.boosters`, so a booster added to a tier later
appears with no edit to SH25/26 themselves — this is what answers "flexible
for if more are added."

**2. SH20–24 confirmed as already correct** — no code change. They already
charged the same price per stack and capped at the number in their own
text; this was a check, not a gap.

**3. SH01–03 now work without staff, and layer a bonus when the named staff
is hired.** Three new **Bonus 1/2/3 Role / Min Tier / Amount** column
triples on the Shop tab hold what Bonus Condition 1–3's prose already said
in words: hiring the row's named Staff role, at or above the row's tier,
adds the row's amount on top of the item's own Grants, read fresh every time
the item is used (not a one-time payout — unlike the tier rewards a Staff
hire itself already pays out). Amounts are **additive layers**, not
restated totals, so a total the text states at Tier 2 becomes (Tier 2's row
amount) added on top of (Tier 1's row amount, usually 0):

| Item | Base (no staff) | Role | Tier 1 adds | Tier 2 adds |
|---|---|---|---|---|
| SH01 Commission Policy Research | `TIER:Party +1` | Policy Research Assistant | +0 | +1 |
| SH02 Commission Press Engagement | `TIER:National +2` | Media Spokesperson | +0 | +2 |
| SH03 Commission District Engagement | `TIER:Constituency +2` | District Representative | +0 | +2 |

**The structural revision (answering "reduce code complexity"): `TIER:X`
pools.** SH01–03's old draft Grants (§2.4) were fixed ID lists —
`BO01|BO02 +1`, then every National ID spelled out, then every Constituency
ID spelled out. Two problems: a booster added later falls out of sync
silently, and SH25/26 needed the same "which boosters count as this tier"
answer a second time for their own picker. Both are now one mechanism: a
`Grants` cell can read `TIER:Party`, `TIER:National` or `TIER:Constituency`
instead of a target ID, and `DataDB.boosters_for_tier()` resolves it live
from each booster's own Tier cell — a `booster_tier` target kind alongside
the existing booster/modifier/segment/shop_item/stage_effect kinds
(`RewardTargets.BOOSTER_TIER`). SH01–03 keep their random pick from the
tier (unchanged behaviour); SH25/26 use the same tier list to build a
picker instead of rolling one. One new column value replaces two
hand-maintained ID lists.

**Code:** `RewardTargets.gd` (`BOOSTER_TIER`, `TIER:` prefix, `is_pool_shaped()`
covering both an explicit pool and a tier), `Items.gd` (`is_player_choice()`,
`choice_pool_spec()`, `staff_bonus_rows()`), `DataDB.gd`
(`boosters_for_tier()`, `choice_options()`, BOOSTER_TIER resolution and
validation), `GameState.gd` (`_choose_target()` — renamed from
`_pick_from_pool()` to cover a player's chosen target as well as a random
pool pick; `_staff_bonus_total()`; `use_item_in_office()`/
`use_item_in_stage()` take an optional `chosen_target` and return
`{"ok": false, "needs_choice": true}` when a Player Choice item is used with
none given), `InventoryPanel.gd` (the picker view, `_choice_button()`).

**Workbook:** Shop tab gained **Player Choice** (Yes/No) and three **Bonus N
Role / Min Tier / Amount** column triples. Text tab gained
`item.choose_heading`. SH01–03 and SH25–26's Grants cells were filled in as
above.

**Tests:** 16 new — `test_reward_targets.gd`, `test_items.gd` and
`test_inventory.gd` each gained coverage for `TIER:` resolution, Player
Choice, and the staff-bonus layering, and `tests/interaction/inventory_test.tscn`
now also clicks through buying, using, and picking a booster from SH25's
picker. 634 unit tests and all three click tests pass.

## Executive summary

| # | Requested | The plan in one line |
|---|---|---|
| 1 | An item inventory | `GameState.inventory`: item ID → quantity. It replaces the `owned_shop_items` list added for Office Hours, which could not hold a quantity |
| 2 | Inventory button on the Office and in a stage | One shared `InventoryPanel` (built on the existing `Overlay`), opened by a new button in each screen. In a stage the button sits beside the existing Details button |
| 3 | Shop → inventory → use | A new **Supplies** section in the Office sells SHxx items for XP/Funds through the Ledger. Buying adds 1 to the inventory, and using an item removes 1 and applies it. Office Hours grants go through the same path |
| 4 | Item icon → pop-up | Tapping an icon opens a second `Overlay` showing the icon, name, quantity, effect text and timing line, with **Use** and **Close** |
| 5 | Icon-name cell | New Shop column **Icon** → `assets/icons/{Icon}.png` |
| 6 | Blue fallback square | `ArtLoader.item_icon()` shows a fixed blue square labelled with the item name when the PNG is missing |
| 7 | Next-stage / current-stage cell | New Shop column **Use Timing**. `Stage` queues the item for the next stage when used in the Office, or applies it to the current stage when used in a stage |
| 8 | Editable use text | New rows in the workbook's **Text** tab (list in §6), following the rule that no sentence lives in a script |
| 9 | Random booster from a pool | New clause syntax in any `target_delta_list` cell: `BO01\|BO02 +1` picks one target from the list when the item is applied |

## 1. What the 29 real shop items actually are

Reading every Description shows that the Shop tab holds five different kinds
of item. Only two of them fit an inventory naturally. **This is the biggest
decision in the plan (§8, Q1).**

| Kind | Items | What they do | Fits the inventory? |
|---|---|---|---|
| **Stage consumables** | SH04 Coffee, SH05 Tea, SH06 Paperwork Automation, SH07 Wristwatch, SH08 Meditation | +1 energy / gaffe cap / draw / turn / guard for one stage | **Yes.** This is exactly item 7's case |
| **Level buffs** | SH20–SH24 | The same five effects for a whole level, stackable with caps | **Yes**, with a `Level` timing |
| **Booster actions** | SH01–SH03 (random from a tier), SH25–SH26 (player picks the group) | An immediate booster standing change | Either. A pool makes SH01–SH03 work (item 9). SH25–SH26 say "player-selected", which is not a random pick (Q5) |
| **Cosmetics** | SH09–SH12 | Nothing yet ("placeholder; will be replaced by art") | No gameplay effect. They could sit in the bag doing nothing, or stay out of the shop |
| **Unlocks / progression** | SH13–SH19, SH27–SH29 | Unlock a level, a random card, a staff tier, the funds cap | These overlap the existing level-unlock and card shops. Recommendation: leave them out of this pass |

## 2. Workbook changes (Shop tab and Text tab)

### 2.1 New Shop columns

The Shop tab already has **Grants**. That column exists, but every row is blank.

| Column | JSON key | Kind | Values |
|---|---|---|---|
| **Icon** | `icon` | str | Icon file name, without `.png`. Blank → the item ID is tried, then the blue square is shown |
| **Use Timing** | `use_timing` | str | `Now`: applies at once, anywhere (booster actions). `Stage`: from the Office it applies to the next stage; in a stage it applies to the current one. `Level`: from the Office it applies to the whole next level; in a stage see Q3. Blank = `Now` |
| **Grants** *(exists)* | `grants` | target_delta_list | Gains two new clause forms, described in §2.2 and §2.3 |

### 2.2 Stage-effect tokens, a closed list like Modifiers' Effect Type

A consumable's effect needs a target that is not a BOxx, Mxx or SGxx. The
proposal adds five fixed words that the Grants cell already parses as targets:

| Token | Used in the Office (Stage/Level timing) | Used in a stage (current stage) |
|---|---|---|
| `ENERGY +N` | +N energy per turn for the next stage/level | +N energy right now |
| `GUARD +N` | Start the next stage with +N guard | +N guard now, capped by `guard_cap` |
| `DRAW +N` | +N hand size for the next stage/level (the existing `hand_size_bonus` route) | Draw N cards now |
| `TURNS +N` | +N to the stage's turn limit | +N to the current stage's turn limit |
| `GAFFE_CAP +N` | +N gaffe limit (the existing `gaffe_limit_bonus` route) | +N gaffe limit now |

`RewardTargets.kind_of()` gains a fifth kind, `stage_effect`, for these
words. An unknown word is an export error, the same as a bad BOxx.

### 2.3 Random booster pool (item 9)

`BO01|BO02 +1` means: pick one of these targets when the item is applied,
then apply +1 to it. The exporter turns it into
`{"target_pool": ["BO01", "BO02"], "delta": 1}`. The pick happens at apply
time, unseeded, the same way range deltas already roll. It works in every
`target_delta_list` cell, including Visitor Reward and Penalty. Every ID in
a pool must be a real target of a known kind. Ranges combine with pools:
`BO03|BO04|BO06 +1-2`.

### 2.4 Proposed first fill for the real items

These are suggestions for Cameron to correct in the workbook. They are not
decisions.

| Item | Use Timing | Grants |
|---|---|---|
| SH01 Commission Policy Research | Now | `BO01\|BO02 +1` (both Party-tier boosters) |
| SH02 Commission Press Engagement | Now | `BO05\|BO08\|BO09\|BO10\|BO13\|BO15\|BO16 +2` (all National-tier) |
| SH03 Commission District Engagement | Now | `BO03\|BO04\|BO06\|BO07\|BO11\|BO12\|BO14 +2` (all Constituency-tier) |
| SH04 Coffee | Stage | `ENERGY +1` |
| SH05 Tea | Stage | `GAFFE_CAP +1` |
| SH06 Paperwork Automation | Stage | `DRAW +1` |
| SH07 Wristwatch | Stage | `TURNS +1` |
| SH08 Meditation Session | Stage | `GUARD +1` |
| SH20–SH24 Level buffs | Level | `DRAW +1` / `ENERGY +1` / `GUARD +1` / `GAFFE_CAP +1` / `TURNS +1` |

The +1/+2 amounts for SH01–SH03 are taken from their Bonus Condition text
(the staff-tier bonus). The base amount with no staff is not stated
anywhere (Q6).

### 2.5 Text tab rows (item 8)

These are new Keys, so every sentence stays editable in the workbook:

| Key | Draft English | Placeholders |
|---|---|---|
| `inventory.button` | Inventory | — |
| `inventory.title` | Inventory | — |
| `inventory.empty` | Nothing here yet. Supplies you buy or are given will appear here. | — |
| `item.quantity` | You have {count} | count |
| `item.use` | Use | — |
| `item.close` | Close | — |
| `item.timing.now` | Takes effect immediately. | — |
| `item.timing.stage_next` | Takes effect at the start of your next stage. | — |
| `item.timing.stage_now` | Takes effect now, in this stage. | — |
| `item.timing.level_next` | Lasts for the whole of your next level. | — |
| `item.used` | {item} used. | item |
| `item.queued` | {item} is ready for your next stage. | item |
| `item.refused.none_left` | You have none left. | — |
| `item.refused.not_here` | This can't be used here. | — |
| `shop.supplies_title` | Supplies | — |
| `shop.item_bought` | {item} added to your inventory. | item |

The same workbook pass should also add the five Text keys the code already
asks for but the Text tab lacks: `office.briefing.surprise_stage`,
`office.level_cooldown`, `office.level_unlock_cost`, `office.look_it_over`
and `shop.level_no_id`. Today every export reports them as errors, and they
survive only because `data/strings.json` is hand-restored after each export.

## 3. Rules layer (pure, headless, tested first)

| File | Change |
|---|---|
| `RewardTargets.gd` | Add a `STAGE_EFFECT` kind for the five tokens. A pool entry is resolved outside this file |
| `Ledger.gd` | `shop_item_price()`, and `shop_item_refusal()` for affordability and a missing ID. Same shape as `modifier_refusal()` |
| `BattleEngine.gd` | `setup()` reads `item_bonuses` (`energy`, `guard`, `draw`, `turns`, `gaffe_cap`) additively, next to the existing `hand_size_bonus`/`gaffe_limit_bonus`. New `apply_item_effect(token, amount) -> Dictionary` for use mid-stage: it refuses if the battle is over and returns what changed so the screen can narrate it. **Open: whether using an item counts as a play, costs energy or has a per-turn limit (Q2)** |
| `LevelRunner.gd` | No change. Level-timing buffs flow through the same config builder as carried buffs |

## 4. GameState

| Addition | Behaviour |
|---|---|
| `inventory: Dictionary` | `{ "SH04": 2, ... }`. Replaces `owned_shop_items` and is reset in the same place |
| `buy_shop_item(id) -> String` | Ledger refusal first, then spend XP and/or Funds (both columns can be non-zero), then add 1 to the inventory. A `Now` item may apply immediately instead (Q1) |
| `use_item(id, context) -> Dictionary` | `context` is `"office"` or `"stage"`. Takes 1 from the inventory. `Now` → Grants applies through the existing `_apply_reward_entries()`, with a pool pick. `Stage`/`Level` in the Office → queued. In a stage the screen passes the stage-effect tokens to `BattleEngine.apply_item_effect()` |
| `pending_item_effects` | Tokens queued from the Office. `Stage` entries are used by the next `for_playtest_stage()` and cleared. `Level` entries last until `end_level()` |
| Office Hours change | A visitor's SHxx reward now adds 1 to the inventory **instead of** applying Grants immediately. This reverses what shipped in `9328a59`, and is what "use from the inventory" implies (Q7) |

`BattleSetup.for_playtest_stage()` merges pending item effects into the
config it already builds. The data needs no new route.

## 5. UI

| Piece | Built from | Notes |
|---|---|---|
| `ArtLoader.item_icon(name)` | Existing `icon()`/`_load()` | Missing file → a fixed blue square. `PlaceholderArt` draws the item's name on it, so the icon stays readable |
| `InventoryPanel.gd` | `Overlay` | Grid of icon buttons with a quantity badge each. Items at 0 are hidden. The empty state uses `inventory.empty`. The same script is used in both screens |
| Item pop-up | `Overlay.open(heading, rows, confirm_text)` | Heading = item name. Rows = icon, `item.quantity`, the Description (display only, never parsed) and the timing line. Confirm = `item.use`, disabled with the refusal line when the item can't be used |
| Office: **Supplies** section + **Inventory** button | Same pattern as the existing card/backing/staff shop panels | Each row shows icon, name, price and a Buy button |
| Stage: **Inventory** button | Beside `%DetailsButton` in the header | Using an item refreshes the screen and posts a message through `MessagePresenter` |

## 6. Testing rubric

| Tier | Check |
|---|---|
| Data | Every Icon, Use Timing and Grants token is valid. Every pool ID exists. An unknown token or timing is an export **error** |
| Rules | Pool picks only from the pool, over many rolls. Pool plus range rolls in bounds. Each of the five tokens applies correctly mid-stage and at setup. `apply_item_effect` refuses after the battle ends. `GUARD` respects `guard_cap`. Ledger refuses when XP or Funds is short |
| GameState | Buying spends both currencies and adds 1. Using takes 1 and refuses at 0. A `Stage` item used in the Office affects exactly the next stage and then clears. A `Level` item lasts the whole next level. An Office Hours SHxx reward adds 1 to the inventory |
| Click test | Extend `loop_driver.gd`: Office → Supplies → buy Coffee → Inventory → tap icon → Use → start a level → the first stage shows +1 energy. In the stage: Inventory → use an item → the effect is visible |
| Manual (Cameron) | The pop-up text reads well, the blue fallback is legible, and the pacing feels right |

## 7. Build order (each step green before the next)

1. Workbook and exporter: Icon and Use Timing columns, pool syntax, stage-effect tokens, Text rows (plus the five missing keys) and the proposed §2.4 fill, all as XML surgery with the usual byte-identical check. Then DataDB validation.
2. Rules: `RewardTargets`, `Ledger` and `BattleEngine` hooks, with GUT tests.
3. GameState: inventory, buy, use, the pending queue and the Office Hours change, with tests.
4. UI: icon fallback, `InventoryPanel`, pop-up, the Supplies section and both Inventory buttons.
5. Click test extension, then Cameron's manual pass.

## 8. Decisions only Cameron can make

| # | Question | Default if unanswered |
|---|---|---|
| Q1 | Which item kinds go **into the bag**, and which apply on purchase? | Stage consumables and level buffs go in the bag. Booster actions apply on purchase (`Now`). Cosmetics and unlocks stay out of the Supplies shop for now |
| Q2 | Using an item **in a stage**: is it free, does it cost energy, does it count as playing a card (which avoids the pass penalty), and is there a limit per turn? | Free, not a card play, no limit |
| Q3 | A **Level** buff used mid-stage: does it apply to the rest of this level? | Yes: the rest of the current level, starting now |
| Q4 | **Buy and stack limits** (SH20–SH24 "stackable up to +N", SH01–SH03 "once per Office screen"): add a Max Held / Buy Limit column now? | Not in this pass. There are no limits, and it is listed as a follow-up |
| Q5 | SH25–SH26 say "player-selected" group. Should that be a pool the player chooses from? | Out of scope. It would need a pick-a-group pop-up |
| Q6 | SH01–SH03 staff-tier bonuses: what is the base amount with no staff hired? | Use the §2.4 amounts until told otherwise |
| Q7 | Confirm that an Office Hours SHxx reward goes **into the bag** rather than applying immediately (this reverses `9328a59`) | Into the bag |
| Q8 | Besides the generic Text rows, add an optional per-item **Use Text** column? | Generic rows only |
