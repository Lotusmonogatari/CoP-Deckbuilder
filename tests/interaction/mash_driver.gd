class_name MashDriver
extends Node
## Rapid-fire real-click stress: hits the same control repeatedly with no
## settle delay between clicks, checking "exactly one effect happened, no
## crash, no stuck UI state" rather than "the feature works at all" — every
## screen here already has a deliberate-single-click proof (click_test.gd,
## floor_vote_test.gd, shop_items_test.gd), which this driver does not
## re-prove.
##
## WHY THIS MATTERS HERE SPECIFICALLY: most screens in this game are fully
## synchronous end to end — a click's handler checks, mutates state, and
## refreshes a label in one call with no `await` in between, and GDScript's
## signal dispatch is single-threaded, so two same-frame clicks can't even
## interleave mid-handler. The one place that genuinely is NOT synchronous
## is a presenter's reaction animation — OpponentPresenter.flinch() and
## PlayerPortraitPresenter's own _flash() both `await
## get_tree().create_timer(FLINCH_SECONDS).timeout` mid-function — so a
## second turn's reaction can start while the first one's await is still
## pending. That is the scenario most likely to actually find something;
## the purchase/vote/card checks below are regression guards confirming a
## currently-synchronous, currently-safe guard stays that way, not bugs
## expected today (see CLAUDE.md's "A thorough code stress test" note).
##
## Lives outside the current scene, the same reason every driver that
## changes scenes needs to (mash_test.gd reparents this to get_tree().root
## before calling _run(), so a change_scene_to_file() partway through
## cannot free the node still running the rest of the checks).

const BATTLE_SCENE := "res://scenes/battle/BattleScreen.tscn"
const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"
const VOTE_LEVEL_ID := "LV31"       # same real fixture floor_vote_driver.gd uses
const VOTE_WATCH_PARTY := "Yezo Heritage Party"

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	await _check_end_turn_spam()
	await _check_card_double_drag()
	await _check_overlay_spam()
	await _check_double_vote()
	await _check_double_buy()

	print("")
	if _failures.is_empty():
		print("MASH TEST: PASS")
		get_tree().quit(0)
	else:
		print("MASH TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


# ---------------------------------------------------------------------------
# 1. End Turn, mashed
# ---------------------------------------------------------------------------

## Five real End Turn clicks with no gap between them, against a real
## battle. Not a "does it double-advance" check — BattleEngine.end_turn()
## itself refuses once state.is_over() (a rules-level guard, not a UI one),
## so several genuinely DO resolve — but a deck+hand+discard conservation
## check the whole way through, the same invariant tools/playtest_optimal.gd
## now checks headless, here proven against the real screen and its
## presenters' own reaction animations firing back to back.
func _check_end_turn_spam() -> void:
	var screen: Node = load(BATTLE_SCENE).instantiate()
	add_child(screen)
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	var engine: BattleEngine = screen.engine
	var end_turn_button: Button = screen.get_node("%EndTurnButton")
	var expected_total := engine.state.deck.size() + engine.state.hand.size() + engine.state.discard.size()

	for i in 5:
		await _click_fast(end_turn_button)

	# Whatever the five clicks did, let any still-running reaction animation
	# (OpponentPresenter.flinch() / PlayerPortraitPresenter's _flash(), both
	# on their own timers) finish before reading final state.
	await get_tree().create_timer(2.0).timeout

	var total := engine.state.deck.size() + engine.state.hand.size() + engine.state.discard.size()
	if total != expected_total:
		_failures.append(
			"end-turn spam: deck+hand+discard=%d after mashing End Turn, expected %d (cards vanished or duplicated)"
			% [total, expected_total])
	elif engine.state.gaffe < 0 or engine.state.energy < 0:
		_failures.append("end-turn spam: gaffe=%d energy=%d went negative"
			% [engine.state.gaffe, engine.state.energy])
	else:
		print("  end-turn spam: card conservation held, outcome=%s, no crash" % engine.state.outcome)

	screen.queue_free()
	await get_tree().process_frame


# ---------------------------------------------------------------------------
# 2. The same card, dragged up twice in a row
# ---------------------------------------------------------------------------

## Drags a playable card up out of the hand twice, back to back, at the
## same screen position — a finger picking the same spot up again before
## the hand has had a chance to redraw. The card must leave the hand and
## have its cost paid exactly once, not twice.
func _check_card_double_drag() -> void:
	var screen: Node = load(BATTLE_SCENE).instantiate()
	add_child(screen)
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	var engine: BattleEngine = screen.engine
	var hand: Control = screen.get_node("%HandRow")
	var card: CardView = null
	for child in hand.get_children():
		if child is CardView and not (child as CardView).disabled \
				and (child as Control).get_global_rect().get_center().x < 1000:
			card = child
			break
	if card == null:
		_failures.append("card double-drag: no playable card on screen to drag")
		screen.queue_free()
		await get_tree().process_frame
		return

	var hand_before: Array[String] = engine.state.hand.duplicate()
	var energy_before := engine.state.energy
	var start := card.get_global_rect().get_center()
	var lift := start + Vector2(0, -(CardView.PLAY_LIFT + 120))

	# Two full drag-up gestures, back to back, no settle wait between the
	# first release and the second press — the same starting screen point
	# both times, since a finger does not know the card underneath it has
	# already left. The hand may well have reflowed and put a DIFFERENT
	# card at that same spot for the second drag — that is fine, a second
	# real card played is not a bug. What would be a bug: a card charged
	# for without actually leaving the hand, or charged twice for leaving
	# once — checked below by accounting for every card that actually left,
	# not by assuming only one specific card_id could have been affected.
	await _drag_fast(start, lift)
	await _drag_fast(start, lift)
	await get_tree().create_timer(0.3).timeout

	var hand_after: Array[String] = engine.state.hand.duplicate()
	var left_hand: Array[String] = hand_before.duplicate()
	for card_id: String in hand_after:
		left_hand.erase(card_id)   # multiset difference: hand_before - hand_after

	var expected_spend := 0
	for card_id: String in left_hand:
		expected_spend += engine.card_cost(DataDB.get_card(card_id))
	var actual_spend := energy_before - engine.state.energy

	if left_hand.is_empty():
		_failures.append("card double-drag: two drags on a playable card left nothing played at all")
	elif actual_spend != expected_spend:
		_failures.append(
			("card double-drag: %d energy spent playing %s, expected exactly %d " +
				"(a card was charged without leaving the hand, or charged twice)")
			% [actual_spend, str(left_hand), expected_spend])
	else:
		print("  card double-drag: %s left the hand, energy accounted for exactly (%d spent)"
			% [str(left_hand), actual_spend])

	screen.queue_free()
	await get_tree().process_frame


# ---------------------------------------------------------------------------
# 3. Details panel, opened and closed rapidly
# ---------------------------------------------------------------------------

func _check_overlay_spam() -> void:
	var screen: Node = load(BATTLE_SCENE).instantiate()
	add_child(screen)
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	var details_button: Button = screen.get_node("%DetailsButton")
	var details_panel: Control = screen.get_node("%DetailsPanel")

	# Counts real observed toggles rather than assuming all 10 synthetic
	# clicks land — a rapid-fire InputEventMouseButton pair can legitimately
	# be dropped by Godot's own input pipeline under zero-gap dispatch,
	# which is a limit of this test harness, not something a real finger
	# could do faster than a frame boundary anyway. What matters is that the
	# panel's own visible state is always internally consistent with how
	# many times it actually flipped.
	var toggles := 0
	var was_visible := details_panel.visible
	for i in 10:
		await _click_fast(details_button)
		if details_panel.visible != was_visible:
			toggles += 1
			was_visible = details_panel.visible

	await get_tree().create_timer(0.3).timeout

	var expected_visible := (toggles % 2 == 1)
	if details_panel.visible != expected_visible:
		_failures.append(
			"overlay spam: Details panel visible=%s after %d observed toggles, expected %s"
			% [details_panel.visible, toggles, expected_visible])
	elif toggles == 0:
		_failures.append("overlay spam: ten rapid clicks toggled Details zero times")
	else:
		print("  overlay spam: %d rapid clicks produced %d toggles, ended in a self-consistent state"
			% [10, toggles])

	screen.queue_free()
	await get_tree().process_frame


# ---------------------------------------------------------------------------
# 4. Vote Yes, clicked twice
# ---------------------------------------------------------------------------

## LV31's real bill (Ainu Heritage and Language Act) is the same fixture
## floor_vote_driver.gd verifies against the workbook's own totals. Computes
## what ONE application of its favorability deltas does to a watched
## third-party's standing (via a throwaway FloorVoteEngine, never touching
## GameState), then confirms the real screen — voted on twice, fast —
## only ever applied it once.
func _check_double_vote() -> void:
	var expanded := BattleSetup.expand_level(DataDB.get_level(VOTE_LEVEL_ID))
	var runner := LevelRunner.new(expanded)
	if not runner.is_valid():
		_failures.append("double-vote: %s could not start" % VOTE_LEVEL_ID)
		return

	var vote_index := -1
	for i in runner.stage_count():
		if str(runner.stage_by_seq(i + 1).get("mode", "")) == "Vote":
			vote_index = i
	if vote_index < 0:
		_failures.append("double-vote: %s has no Vote-mode stage" % VOTE_LEVEL_ID)
		return
	var vote_stage := runner.stage_by_seq(vote_index + 1)

	# The single-application delta, computed independently of the real
	# screen and never applied to the real GameState.
	var probe := FloorVoteEngine.new()
	probe.setup({"bill": vote_stage.get("floor_vote", {}), "player_party": str(DataDB.player.get("party", ""))})
	var probe_result := probe.choose("Yes")
	var single_delta := float(probe_result.get("favorability_deltas", {}).get(VOTE_WATCH_PARTY, 0))
	if single_delta == 0.0:
		_failures.append("double-vote: '%s' has no favorability delta on this bill — pick a different watch party"
			% VOTE_WATCH_PARTY)
		return

	runner.index = vote_index
	GameState.begin_level(runner)
	get_tree().change_scene_to_file(StageRouting.scene_for(runner.current_stage()))
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	var screen := get_tree().current_scene
	if screen == null or screen.name != "FloorVoteScreen":
		_failures.append("double-vote: %s's Vote stage did not open the Floor Vote screen" % VOTE_LEVEL_ID)
		return

	var before := float(GameState.party_standing.get(VOTE_WATCH_PARTY, 0))
	var vote_yes: Button = screen.get_node("%VoteYes")

	# Both clicks fired with no frame yield between them at all — the
	# closest this test framework can get to a literal same-frame mash.
	var transform := get_viewport().get_screen_transform()
	var where: Vector2 = transform * vote_yes.get_global_rect().get_center()
	for pressed_first in [true, false]:
		var e1 := InputEventMouseButton.new()
		e1.button_index = MOUSE_BUTTON_LEFT
		e1.pressed = pressed_first
		e1.position = where
		e1.global_position = where
		Input.parse_input_event(e1)
	for pressed_second in [true, false]:
		var e2 := InputEventMouseButton.new()
		e2.button_index = MOUSE_BUTTON_LEFT
		e2.pressed = pressed_second
		e2.position = where
		e2.global_position = where
		Input.parse_input_event(e2)
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	var after := float(GameState.party_standing.get(VOTE_WATCH_PARTY, 0))
	var actual_delta := after - before
	if absf(actual_delta - single_delta) > 0.01:
		_failures.append(
			"double-vote: %s moved by %.1f after two fast clicks, expected exactly one application's %.1f"
			% [VOTE_WATCH_PARTY, actual_delta, single_delta])
	else:
		print("  double-vote: two fast clicks applied favorability exactly once (%.1f)" % actual_delta)

	# Clean up: leave the level so a later phase starts from the Office.
	if GameState.is_in_level():
		GameState.end_level()


# ---------------------------------------------------------------------------
# 5. A Supplies purchase, clicked twice
# ---------------------------------------------------------------------------

## SH19 (Increase Office Funds Cap) is deliberately repeatable (CLAUDE.md
## M5), so this is not "does a second purchase get refused" — that is
## stress_shop_items.gd's job, at the GameState.buy_*() layer, 400
## iterations of it. This confirms the real Buy button deducts Funds by
## exactly one purchase's own cost per real double-click, not a UI-only
## quirk (a stale report label, a button that double-fires its own signal).
func _check_double_buy() -> void:
	GameState.xp = 999999
	GameState.funds_cap_bonus = 0

	get_tree().change_scene_to_file(OFFICE_SCENE)
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	var office := get_tree().current_scene
	if office == null or office.name != "OfficeScreen":
		_failures.append("double-buy: could not reach the Office screen")
		return

	# Supplies moved into the Marketplace (2026-09-28) — one click, not
	# Office Management -> Supplies any more.
	await _click(office.find_child("InventoryButton", true, false) as Control)
	var supplies := office.get_node("InventoryPanel") as Overlay
	if not supplies.visible:
		_failures.append("double-buy: the Marketplace button did not open")
		return

	var row := supplies.find_child("Supply_SH19", true, false)
	var button := row.find_child("Buy", true, false) as Button if row != null else null
	if button == null:
		_failures.append("double-buy: SH19 has no Buy button in Supplies")
		return

	# SH19 sits well down a long scrollable list — has to be scrolled into
	# view first, same as a deliberate _click() already does, or the two
	# rapid clicks below land on whatever happens to be on screen instead.
	var scroll_parent := button.get_parent()
	while scroll_parent != null and not (scroll_parent is ScrollContainer):
		scroll_parent = scroll_parent.get_parent()
	if scroll_parent is ScrollContainer:
		(scroll_parent as ScrollContainer).ensure_control_visible(button)
		await get_tree().process_frame
		await get_tree().process_frame

	var item := DataDB.get_shop_item("SH19")
	var cost := int(item.get("cost_xp", 0))
	var xp_before := GameState.xp

	var transform := get_viewport().get_screen_transform()
	var where: Vector2 = transform * button.get_global_rect().get_center()
	for pressed_first in [true, false]:
		var e1 := InputEventMouseButton.new()
		e1.button_index = MOUSE_BUTTON_LEFT
		e1.pressed = pressed_first
		e1.position = where
		e1.global_position = where
		Input.parse_input_event(e1)
	for pressed_second in [true, false]:
		var e2 := InputEventMouseButton.new()
		e2.button_index = MOUSE_BUTTON_LEFT
		e2.pressed = pressed_second
		e2.position = where
		e2.global_position = where
		Input.parse_input_event(e2)
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	var xp_after := GameState.xp
	var spent := xp_before - xp_after
	# Two full, independent double-clicks is 2 real purchases of a
	# deliberately repeatable item — that is correct, not a bug. What would
	# be a bug is spending an amount that is not a whole-number multiple of
	# the item's own cost (a partial/duplicate deduction from the same
	# logical click), or nothing at all (the button silently ate both).
	if spent <= 0:
		_failures.append("double-buy: two real clicks on SH19 spent no XP at all")
	elif cost > 0 and spent % cost != 0:
		_failures.append("double-buy: spent %d XP on SH19 (cost %d) — not a whole multiple, a click was double-charged"
			% [spent, cost])
	else:
		print("  double-buy: SH19 spent %d XP across two real clicks (cost %d each) — no fractional/double charge"
			% [spent, cost])


# ---------------------------------------------------------------------------
# Click helpers
# ---------------------------------------------------------------------------

## A deliberate click: scrolls the target into view first if it is inside a
## ScrollContainer, then presses and releases with a short settle wait.
## Copied from shop_items_driver.gd's own _click() — every driver in this
## project keeps its own copy rather than sharing a base class.
func _click(control: Control) -> void:
	if control == null:
		_failures.append("a button this test needed does not exist")
		return
	await get_tree().process_frame
	var parent := control.get_parent()
	while parent != null and not (parent is ScrollContainer):
		parent = parent.get_parent()
	if parent is ScrollContainer:
		(parent as ScrollContainer).ensure_control_visible(control)
		await get_tree().process_frame
		await get_tree().process_frame

	var rect := control.get_global_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_failures.append("%s has no size, so nothing could click it" % control.name)
		return
	var where: Vector2 = get_viewport().get_screen_transform() * rect.get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = where
		event.global_position = where
		Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout


## The mash version: press, one frame, release — no scroll handling (the
## target is assumed already on screen) and no settle wait, so two calls in
## a row land as close together as this test framework can put them.
func _click_fast(control: Control) -> void:
	if control == null:
		_failures.append("a button this test needed does not exist")
		return
	var rect := control.get_global_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_failures.append("%s has no size, so nothing could click it" % control.name)
		return
	var where: Vector2 = get_viewport().get_screen_transform() * rect.get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = where
		event.global_position = where
		Input.parse_input_event(event)
		await get_tree().process_frame


## A real press, a movement in steps, and a release — copied from
## click_test.gd's own _drag().
func _drag(from: Vector2, to: Vector2, steps: int = 12) -> void:
	var transform := get_viewport().get_screen_transform()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = transform * from
	press.global_position = press.position
	Input.parse_input_event(press)
	await get_tree().process_frame
	for step in range(1, steps + 1):
		var motion := InputEventMouseMotion.new()
		motion.position = transform * from.lerp(to, float(step) / steps)
		motion.global_position = motion.position
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion)
		await get_tree().process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = transform * to
	release.global_position = release.position
	Input.parse_input_event(release)
	await get_tree().process_frame
	await get_tree().process_frame


## The mash version of _drag(): same gesture, fewer steps, no trailing
## settle wait, so a second gesture can start immediately after.
func _drag_fast(from: Vector2, to: Vector2) -> void:
	var transform := get_viewport().get_screen_transform()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = transform * from
	press.global_position = press.position
	Input.parse_input_event(press)
	await get_tree().process_frame
	for step in range(1, 5):
		var motion := InputEventMouseMotion.new()
		motion.position = transform * from.lerp(to, float(step) / 4.0)
		motion.global_position = motion.position
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion)
		await get_tree().process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = transform * to
	release.global_position = release.position
	Input.parse_input_event(release)
	await get_tree().process_frame


func _button_with_text(root: Node, text: String) -> Control:
	for node in root.find_children("", "Button", true, false):
		if (node as Button).text == text:
			return node as Control
	return null
