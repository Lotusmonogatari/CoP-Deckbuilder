# Cleanup candidates (noted 2026-10-28, nothing deleted)

Cameron's call: **do not delete or remove any of these now.** This is a list for a future cleanup pass; each item needs a fresh check and his approval before it goes.

## Unused code

| Item | Where | Why it is a candidate |
|---|---|---|
| `StageBrief.how_this_room_works()` | `scripts/ui/StageBrief.gd` | Removed 2026-10-28 (the only public function found with no caller anywhere in scripts, tests or tools). Listed so the pass knows the scan has been done. |

## Tool scripts with few or no references

| Item | References found | Note |
|---|---|---|
| `tools/build_floor_vote_scene.gd` | 0 | Scene builder; check it is not the only way to rebuild FloorVoteScreen before removing. |
| `tools/art_prompt.py`, `tools/content_lint.py` | 1 each | Single mention; may be run by hand. |
| `tools/build_intro_scene.gd`, `build_stage_transition_scene.gd`, `build_theme.gd` | 1 each | Builders; CLAUDE.md section 13 says which are safe to rerun. |
| `tools/bench.sh`, `measure_plays.sh`, `build_level_intro_scene.gd` | 2 each | Likely still used by notes. |

The stress, benchmark and playtest scripts (`stress*.sh/.gd`, `benchmark.gd`, `rubric_playtest.gd`, `playtest_optimal.gd`, `balance_audit.*`) are referenced from the change log and each other, so they are not candidates.

## Text-tab rows nothing asks for (exporter notes: "nothing asks for ... yet")

| Rows | Why |
|---|---|
| `card.room_enhanced`, `card.room_greatly_enhanced`, `card.room_greatly_suppressed`, `card.room_neutral`, `card.room_suppressed` | Orphaned 2026-10-28 when the card back dropped the room's suit match line. |
| `card.question_strong`, `card.question_weak`, `card.question_medium` | Orphaned the same day (the question's effect line). |
| `election.c_district`, `election.c_national`, `election.component_line`, `election.inputs_heading`, `election.meter_line`, `election.potential_line`, `election.record_heading` | Not checked. Confirm they are not built up dynamically before removing. |
| `office.trigger.*` (backing_lapsed, funding_freeze, gaffe_penalty, steering_committee, town_hall; entered / left) | Not checked; the trigger alerts may build these keys dynamically. |
| `record.cause_gaffe_awareness` | Not checked. |

`tools/workbook/wbx.py` has no delete-row helper today, so removing Text rows would need one first.

## Tests

No test was found that covers a removed feature. The two click tests that `verify.sh` never ran (`intro_test`, `mash_test`) now run and pass, so they are not candidates either.

## Added 2026-10-30 (playtest fixes)
- Text rows no longer asked for: `briefing.against_one`, `briefing.against_many`, `briefing.reporters_ask` (the briefing no longer names opponents) and `dues.preview`, `dues.preview_owed` (the Friday dues line is gone; the Party Dues box shows it).
- Balance lever "Starting Training Session Coupons" (now 0): replaced by the Player tab's Starting Items; no longer read by the code (2026-10-31).
- Text rows no longer asked for after the briefing template (2026-10-30): `briefing.loss_ends_level`, `reward.if_lost` (the briefing no longer lists loss costs, carry-over lines, bill sides or "standing with whichever organizations"). `CarryOverLines.gd` and `StanceLines.briefing_lines()/briefing_sides()` may now be unused by the briefing; check other callers before removing.

## Cleanup pass (2026-10-31, approved by Cameron item by item)

**Removed:** the Text rows `briefing.against_one`, `briefing.against_many`, `briefing.reporters_ask`, `briefing.loss_ends_level`, `reward.if_lost`, `card.room_*` (5), `card.question_*` (3), `dues.preview`, `dues.preview_owed`, `election.c_district`, `election.c_national`, `election.component_line`, `election.inputs_heading`, `election.meter_line`, `election.potential_line`, `election.record_heading` and `record.cause_gaffe_awareness`; `scripts/ui/CarryOverLines.gd` and its test; `StanceLines.briefing_lines()` and `briefing_sides()`; `tools/build_floor_vote_scene.gd`; and the Balance row "Starting Training Session Coupons".

**Kept, in use:** the `office.trigger.*` rows. The Office builds their keys at runtime (`"office.trigger.%s.%s"`), so the exporter's "nothing asks for" note about them is a false alarm. **Kept by choice:** `tools/art_prompt.py` and `tools/content_lint.py`, which are run by hand.

**Removed in a second pass (Cameron, 2026-10-31: "delete if nothing uses them"; nothing did, not even by a built-up key):** the Text rows `briefing.between_all`, `briefing.between_resets`, `briefing.res_energy`, `briefing.res_gaffes`, `briefing.res_guard`, `briefing.res_hand`, `briefing.res_support` and `briefing.res_turns` (CarryOverLines' lines); and `briefing.bill_line`, `briefing.sides_for`, `briefing.sides_against` and `stance.nobody` (the StanceLines briefing helpers' lines).

## Added 2026-11-01
- **Done 2026-11-03 (Cameron: "Go clean up")**: `_question_concerns_lines()`, its helper `_booster_names_for()` and the rows `battle.question_concerns`, `battle.question_stakes`, `battle.question_sets_back` and `battle.nobody_pleased` were removed. Original note: the Details panel no longer shows them (Cameron's playtest). `StanceLines.stance_chip_rows()` may now be unused there too; check other callers.

## From the stage transition review (2026-11-02)

- Done 2026-11-02 (Cameron's instruction): the two Transition Dialogue rows tied to ST30 (TD31, TD32) moved to ST29, the harbor town hall in the same level; Transition Backgrounds TB08 (ST30, the Media Ambush room picture) was deleted, since only Media Ambush rooms use that picture and they show no transition.

## From the card face change (2026-11-02, second playtest round)

- **Done 2026-11-03 (Cameron: "Go clean up")**: these 11 rows were deleted from the Text tab. Original note: Text rows no longer asked for after the card face dropped the audience and bonus commentary and the "Answers this question." line: `card.answers_question`, `card.received_bonus`, `card.bonus_met`, `card.bonus_unmet`, `card.double_met`, `card.double_unmet`, `card.scale_now`, `card.behind_met`, `card.behind_unmet`, `card.gaffe_zero_met`, `card.gaffe_zero_unmet`.
- `SpecialEffects` still records `flags.special_bonus` (how much a conditional bonus added); nothing reads it now.

## Added 2026-11-06 (documentation review): working papers that look historical

Nothing below was deleted. The change log, the guides and the code are now the record of what was built; these files are the working papers behind them. Each needs a fresh check and Cameron's approval before it goes. Everything stays recoverable from git history.

| Group | Files | Why a candidate |
|---|---|---|
| Superseded reports | `design/MECHANIC_COVERAGE.md` (2026-09-28), `REVIEW_2026-10-14.md`, `STRESS_LATE_GAME_2026-10-14.md`, `UI_PLAYER_REVIEW.md`, `TERMINOLOGY_REVIEW_2026-10-16.md`, `JAPANESE_TEXT_REVIEW_2026-10-15.md`, `BILL_BOOSTER_PARTY_REPORT_2026-10-13.md`, `DYNAMIC_SCREEN_PLAN.md`, `THEME_REBALANCE_PROPOSAL.md` | Findings were applied; the decisions live in `INFORMATION_STANDARDS.md` and the change log summary |
| Balance audits | `design/BALANCE_AUDIT*.md` (five files plus the `.flags.json` files), `BALANCE_AUDIT_PROCESS.md`, `design/review/BALANCE_AUDIT_2026-10-31.md`, `design/bench/balance_logs_2026-10.tar.gz` | The 2026-10-18 audit retuned the game; the latest numbers are in the workbook |
| Plans already built | In `design/proposals/`: the patron-bill build plan, calendar and dues plan, custom bill mode, discard cards plan, district activities, guest events, office hours, inventory, intro screen, staff firing, stage rules columns, TV debate threshold, bill stages plan, choices and commitments plan, difficulty option, opponent cue expansion plan, component code plan, party activists plan, code simplification plan and prompt | The features exist; see `GAME_SYSTEMS.md` |
| Ideas not built | `AUDIO_PLAN`, `AUDIO_BRIEF`, `CAMPAIGN_LAYER_IDEATION`, `PARTY_CAPITAL_IDEATION`, `CARD_EFFECTS_IDEATION`, `INFLUENCE_BUILDING_*`, `UI_PROPOSALS`, `CONTENT_AND_STAGE_GAPS` | **Keep**: these are open ideas, the audio plan especially |
| Code review slices | `design/review/findings_slice*.md` (40 files) | The output of one code review; fixes were applied (see the 2026-10-14 sections of the old change log) |
| Content review and audit papers | `design/review/` (the `*_AUDIT_*`, `*_REVIEW_*`, `REWRITTEN_QUESTIONS_2026-10-25.md`, `TITLES_AND_THEMES_2026-10-31.md`, `PROMISE_WORDING`, `OPEN_ITEMS`, `DECISIONS`, `FIXES_APPLIED` files), `design/drafts/`, `design/archive/` | Applied; `OPEN_ITEMS_2026-10-31.md` was closed in the change log |
| Bench data | `design/bench/*.jsonl`, `*.json`, `visit_review_samples_*.md` (about 120 KB), the strategy and difficulty reports | Raw runs behind decisions already recorded |
| Prompts | `design/prompts/COMPONENT_REVISION_PROMPTS_2026-11-03.md` | The component revision is done |
| Possibly an older copy | `design/game_design_artifact.html` | May duplicate `GAME_DESIGN.md`; check before removing |

**Keep for reference:** `CONTENT_GUIDE.md`, `EDITING_TEXT.md`, `GAME_*.md`, `INFORMATION_STANDARDS.md`, `ARCHITECTURE.md`, `NEW_CHAT_STARTUP.md`, `PLAYTEST_CHECKLIST.md`, `PLAYTEST_RUBRIC.md`, the art and icon prompt files, `OUTDOOR_BACKGROUNDS.md`, `design/reference/` and `tools/workbook/README.md`.

## Other findings from the 2026-11-06 review (noted, not changed)

- `segment_favorability` (and its `last_segment_change`, `reset_segment_favorability`, `segments.json`'s Initial Favorability) is still stored and saved, but nothing reads it since staff audience rewards became organization rewards (2026-11-04).
- The Sanban tab's low and high "consequence" cells (for example "LV10 cannot be activated") are text only; no code enforces them.
- `GameState._apply_time_decays()` and the Balance lever `decay_interval` (0 = off) are a switched-off second decay path; decay runs once a week at "Go Home".
- `GameState.buy_random_level()` and the shop `level_tier` column are unused by the current Shop tab (kept and tested).

## Cleanup pass (2026-11-08, Cameron: "Approve all")

**Removed (still in git history):** the Text rows `floor_vote.preview_line`, `preview_passes`, `preview_fails`, `preview_flips`, `projection_unknown` and `whip_cost_short`, and 98 working papers that no script, test or tool reads: design/ (14); design/drafts (3); design/prompts (1); design/proposals (17); design/review (63).

**Kept on purpose:** `design/bench/` (the bots and `bench.sh` read and write it), the 17 papers whose file names scripts or tools still mention (`BALANCE_AUDIT.md`, `BALANCE_AUDIT_2026-10-18.md`, `BALANCE_AUDIT_PROCESS.md`, `DYNAMIC_SCREEN_PLAN.md`, `MECHANIC_COVERAGE.md`, `review/CHOICE_AUDIT.md`, `review/MC2T_TEST_KIT_2026-11-06.md` and nine plans in `design/proposals/`), the MC²T papers (the player-test kit uses them), `design/archive/` (its README is referenced), `game_design_artifact.html` (needs a duplicate check), and the "Ideas not built" group, which the list itself says to keep.

## From the writing review (2026-11-09)

- Patron Bills tab: the `request_line`, `accept_line` and `decline_line` columns (the same sentence on all 54 rows) are read by no script; only `fail_line` is shown. Cameron's decision #50: list them here rather than reword them.

## From the project audit (2026-11-10): code only the tests use

Nothing deleted. Each needs a fresh check and Cameron's say-so. These are referenced by `tests/` or `tools/` but by no game script or scene:

- Script: `scripts/rules/StageCarryOver.gd` (52 lines; `between_opponents`).
- Functions: `HandPresenter.view_for`, `CueBanner.current_line`, `MessagePresenter.is_saying_something`, `ListeningStrip.listener_ids`, `SaveManager.backup_time`, `DataDB.is_loaded`, `RewardTargets.is_modifier` / `is_shop_item` / `is_segment`, `LevelRunner.progress_caption` / `loss_penalties` / `variable_rewards`, `PatronRequests.room_to_open`, `BillName.sentence_start`, `HowToPlay.unresolved_tokens`, `IntentRunner.set_position`, `BarModel.totals_balance`, `Ledger.can_buy_card` / `can_buy_modifier` / `deck_is_legal` / `can_hire_staff` / `can_upgrade_staff` / `can_fire_staff`.

Several are test helpers (they exist so a test can look inside a presenter) and should stay; the `Ledger.can_*` and `LevelRunner` ones look like rules the game stopped calling.

## From the 2026-11 audit: workbook columns no script reads (nothing deleted; Cameron to rule)

`stages.win_pct`, `bar_value_kind`, `segment_check`; `shop.bonus_condition_1` and `_2` (13 items carry text); `sanban.low_consequence` and `high_consequence`; Balance `xp_tiers`; reference-only columns `cards.special_note`, `cards.suit_jp`, `suits.gloss`, `suit_jp`, `card_design_template`, `opponents.gender`, `party_acronym`; empty columns `bill_components.amend_options` and `each_level_effect`. `patron_bills.request_line`, `accept_line` and `decline_line` are now shown (2026-11-16, W-7). Source: `audit/mechanics.md` M-13 to M-19.


## From the 2026-11-17 documents and hard-coding pass (nothing deleted; Cameron to rule)

- Code for Shop effects no item uses any more (the six office-supply items replaced the drafts): `STRONG_FAMILY`, `REWARD_MULT`, `POOL_FAMILY`, `POOL_MAX` in `StaffTasks.gd`, `GameState` and the exporter's allowed list, with the Text rows `assign.item_cap_family`, `assign.item_desc_family`, `assign.item_cap_mult`, `assign.item_desc_mult`, `assign.item_cap_pool`, `assign.item_cap_max` and the `assign.item_desc_pool_*` and `assign.item_desc_max_*` rows. They still work if a row ever uses them (event choices still change the pool through `staff_pool_mods`).
- The Shop columns `Staff Hours` (superseded by Staff Effect HOURS; kept for the coffee and tea rows), `Staff Target` and `Staff Days` (no current item sets them).
- The Balance rows `Staff Tasks: Pool Size` and `Weekend Pool Size` were retired on 2026-11-16 (the ramp replaced them); confirm they are gone.

## From the 2026-11-19 level briefing redesign (P12): the old briefing's rows and code (nothing deleted; Cameron to rule)

The redesigned briefing no longer asks for these Text rows. Where any code still does, it is `LevelBonusView.rows()` (the old Level Bonus block), which only `tests/test_level_bonus.gd` calls; it can go with them.

| Text row | What it said |
|---|---|
| `briefing.level_hours` (and `.one`) | The old "Level hours" line |
| `briefing.stage_hours` (and `.one`) | A stage's hours in the old stage list |
| `briefing.stage_fallback` | The old stage name when a stage had none |
| `briefing.total_rewards` | The old "Total Rewards" heading |
| `briefing.rewards` | The old per-stage rewards line |
| `briefing.bullet` | The "• " in front of an old reward line |
| `briefing.level_bonus` | "Level Bonus (paid if you win the whole level):", the wording this redesign corrected |
| `briefing.level_bonus_orgs` | The old Level Bonus organizations line |
| `briefing.xp_growth_range` | The old XP range line |
| `reward.delta_range`, `reward.chip_range` | The old range wording for a meter line and an organization chip |
| `office.go_in` | The old plain "Go in" button on the briefing |

Also `LevelRunner.loss_penalties()`, which the briefing now only carries in its data (`LevelBriefing`'s rooms, kept so the loss costs can come back) without showing them. The exporter already prints the rows nothing asks for (`level_hours`, `rewards`, `stage_fallback`, `stage_hours`, `total_rewards`, `office.go_in`); the others on this list are asked for only by `LevelBonusView.rows()`. Removing these Text rows means `python3 tools/export_data.py --accept-wording` to refresh the wording snapshot.


## Cleanup pass (2026-11-20, Cameron: "execute the cleanup")

**Removed (still in git history):**

| What | Detail |
|---|---|
| The old Level Bonus block | `scripts/ui/LevelBonusView.gd` (nothing used it since the P12 briefing) and `LevelBonus.chip_numbers()` with its test. |
| The P12 retired Text rows (14) | `briefing.level_hours` (and `.one`), `briefing.stage_hours` (and `.one`), `briefing.stage_fallback`, `briefing.total_rewards`, `briefing.rewards`, `briefing.bullet`, `briefing.level_bonus`, `briefing.level_bonus_orgs`, `briefing.xp_growth_range`, `reward.delta_range`, `reward.chip_range`, `office.go_in` (workbook script: `tools/workbook/archive/cleanup_2026-11-20.py`). |
| Code only its own tests called | `scripts/rules/StageCarryOver.gd` and its test; `SaveManager.backup_time()`; `RewardTargets.is_modifier()`, `is_shop_item()` and `is_segment()`; `PatronRequests.room_to_open()` and its test; `BillName.sentence_start()`. |

**Kept on purpose, with the reason:**

| What | Why |
|---|---|
| `design/game_design_artifact.html` | The check was done: it is not an older copy of `GAME_DESIGN.md` but the HTML the game design page is published from (its commit says so). |
| The 17 papers whose file names code or tools mention (balance audits, `DYNAMIC_SCREEN_PLAN`, `MECHANIC_COVERAGE`, `CHOICE_AUDIT`, `MC2T_TEST_KIT` and nine plans in `design/proposals/`) | Code comments cite them as the source of a rule (for example `inventory.md` from about twenty files); deleting them would leave the comments pointing nowhere. |
| `design/bench/`, `design/archive/`, the "Ideas not built" group, the MC²T papers | As before: bots read and write the bench folder; the others were marked keep. |
| Test helpers: `HandPresenter.view_for`, `CueBanner.current_line`, `MessagePresenter.is_saying_something`, `ListeningStrip.listener_ids`, `DataDB.is_loaded`, `IntentRunner.set_position`, `HowToPlay.unresolved_tokens`, `BarModel.totals_balance`, `Ledger.deck_is_legal` | Click tests, bots or real tests use them to look inside a screen or set up a state. |
| `Ledger.can_buy_card`, `can_buy_modifier`, `can_hire_staff`, `can_upgrade_staff`, `can_fire_staff` | Thin wrappers whose tests are the only coverage of the rules under them; removing them means rewriting those tests. |
| `LevelRunner.progress_caption()` and `variable_rewards()` | Not called by the game, but removing them would orphan Text rows (`caption.stage`, `reward.by_finish`, `reward.head_start`, `reward.standing` is still used); a pass of its own. |
| Shop effect code and columns no item uses (the 2026-11-17 list), the unread workbook columns (the 2026-11 audit list) and `segment_favorability` | They are part of the workbook's schema, and removing a column or an effect a content author could still use is a schema change that needs its own go. |

**New candidates found by this pass (nothing deleted):**

- Text rows the exporter says nothing asks for: `assign.already_theirs`, `assign.family_max`, `assign.give_to`, `assign.item_caption`, `assign.item_caption_one`, `assign.max_line`, `assign.outcome_line`, `assign.refuse_blocks`, `assign.refuse_locked`, `assign.take_back`, `assign.tile_nothing`, `assign.why_line`, `brand.hook`, `intro.title`, `pressure.pick`, `pressure.picked`.
- Working-paper folders from finished, merged panels, about 210 MB in `design/review/` and 16 MB in `design/proposals/img/`: `director_shots_2026-11-17` (78 MB), `p3_text_sweep_2026-11-17` (40 MB), `p2_card_faces_2026-11-17` (32 MB), `p4_information_2026-11-17` (30 MB), `p9_ui_styles_2026-11-17` (16 MB), `p12_level_preview_2026-11-19` (7 MB), `hand_third_overlap`, `card_play_spot`, `p10_brand_b`, `card_overlap`, `report_2026-11-19`, `level_bonus_*`, `resign_hold`, and the mockups under `design/proposals/img/`. They are evidence screenshots for work already merged; they were not on the list, so they were left for Cameron's word.
- The remote branch `review/p11-two-offices-audit` (the audit, deliberately not merged).

## P13 Office screens (2026-11-20): found while building, nothing deleted

| What | Why it looks removable |
|---|---|
| `OfficeScreen._text_size_button()`, `_image_scroll_button()`, `_image_pan_button()`, `_backup_buttons()` | The Administration screen is now drawn by `AdministrationModel` and `AdministrationView`; nothing calls these four any more. (`SettingsRows`, which the stage menu still uses, is unchanged.) |
| The scene's `OrganisationsPanel`, `BackingPanel` and the code-built `RecordPanel`, `ElectionPanel`, `PartiesPanel`, and `OfficeScreen._menu_button()` | Reputation and Results is now one tabbed screen on the frame; these five panels and the helper that built the menu rows are no longer opened by anything (the Parties allies pop-up, the law pop-up and the factors pop-up are still used). |
| Text rows `office.your_record`, `office.organisations` | The tabs use their own names; check the exporter's "nothing asks for it" list after P13. |
| `OfficeScreen._supply_row()` | The Marketplace's cards are drawn by `MarketView` from `MarketModel`; nothing calls the old row builder. |
| `OfficeScreen._staff_hired_row()`, `_menu_button()`, and the scene's `%CardsPanel`, `%DeckPanel` | Office Management is one tabbed screen in `ManagementPanel`; the hired-person row, the menu-row helper and the two panels (the deck and training bodies now live in the management frame) are no longer opened by anything. `_deck_panel.confirmed` is still connected but nothing emits it. |
| Text rows `office.staff_blurb`'s old use, `office.deck_count` as a heading | Still used (the candidates pop-up and the chip); listed only so they are checked after P13. |
| Text row `event.list_title`'s old heading use | Still used as the title; listed so it is checked after P13. The old list built its row title and button in `_show_events_list`; that code is gone (nothing to delete). |

## P14 part one (2026-11-20): found while building, nothing deleted

| What | Why it looks removable |
|---|---|
| Text rows `popup.tag_moved`, `event.delegate_who`, `rhetoric.coupon_line`, `travel.closed_here`, `travel.destination` | Added for P14 screens not built yet (the moved-for-you card, the staff delegation line, the coupon line, the Travel page); keep until P14b decides. |
| The plain `Overlay.open(title, rows)` calls the nine group-1 pop-ups used to make | Those pop-ups are cards now (`open_card`); `open()` still serves every other panel, so nothing is dead yet. |
| `design/review/p14_remaining_screens_2026-11-20/img/` (12 MB) | Working pictures; removable once P14 is merged and signed off. |

## P14b: Floor Vote (2026-11-20)

| What | Why it looks removable |
|---|---|
| Text row `floor_vote.projection_label` ("{choice} - Likely {result}") | The projections now show the choice at the left and `floor_vote.projection_result` ("Likely {result}") at the right in green or red. Nothing asks for the old combined row. |
| `FloorVoteScreen._gold_rule()` and `UiKit.gold_rule()`'s use there | The Floor Vote body is cards now; check other screens before removing `UiKit.gold_rule()`. |

## P14b commit 1 (2026-11-20): found while building, nothing deleted

| What | Why it looks removable |
|---|---|
| `OfficeScreen.STAFF_TOP_GAP` | The staff profile is a frame now; nothing leaves air above the picture. |
| `StaffAssignmentsView.rows()`'s no-staff branch headings and `UiKit.heading` calls for the old section titles | The staff-present branch uses cards with titles; the no-staff branch still uses plain headings. |
| `StaffAssignmentsView.PLAIN_FRAME` and the dark staff card colours | The person card is the style's card now; the chips keep their own tiles. |

## P14b commit 2 (2026-11-20): found while building, nothing deleted

| What | Why it looks removable |
|---|---|
| `OfficeScreen.CARD_OFFER_CHROME` (700) | The card offer is a pop-up card now; the card's own header, foot and body sizing take the room the constant reserved. Still used to scale the faces; retune before removing. |

## P14b commit 3 (2026-11-20): found while building, nothing deleted

| What | Why it looks removable |
|---|---|
| `OfficeScreen._ally_row` colour argument for rivals, `party_opinion.popup_blurb` as a heading line | The party detail draws its own cards; check before removing. |
| `UiKit.heading` calls in the old Draft a Bill rows | Replaced by card titles. |
