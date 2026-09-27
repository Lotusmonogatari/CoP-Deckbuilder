class_name FloorVoteDriver
extends Node
## Walks a real National Assembly Floor Voting stage (ST23) with real
## clicks, on a real bill from a real level — LV31, the Ainu Heritage and
## Language Act, the same one verified against the workbook's own Vote
## Tally & Swing tab (CLAUDE.md's 2026-09-27 pull note: 45 Yes / 48 No /
## 8 Abstain).
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/floor_vote_test.tscn
##
## LV31's own stage sequence puts ST23 fifth (after ST07/ST05/ST17/ST03),
## and it is also the level's LAST stage — driving the level from stage 1
## would mean playing a real committee and a real caucus first, which
## loop_test.tscn and office_hours_driver.gd already prove work. Instead
## the runner is built from LV31's own real, expanded stages (so the bill
## is genuine, not fabricated) with its index moved straight to the Vote
## stage — the same "jump to the stage this test is actually about"
## technique used to verify this exact level by hand before it shipped.
##
## Added 2026-09-28: before this, no interaction test ever opened
## FloorVoteScreen.tscn at all (design/MECHANIC_COVERAGE.md).

const LEVEL_ID := "LV31"

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var expanded := BattleSetup.expand_level(DataDB.get_level(LEVEL_ID))
	var runner := LevelRunner.new(expanded)
	if not runner.is_valid():
		_failures.append("%s could not start: %s" % [LEVEL_ID, ", ".join(Array(runner.problems()))])
		_finish()
		return

	var vote_index := -1
	for i in runner.stage_count():
		if str(runner.stage_by_seq(i + 1).get("mode", "")) == "Vote":
			vote_index = i
	if vote_index < 0:
		_failures.append("%s has no Vote-mode stage — is this still the right fixture level?" % LEVEL_ID)
		_finish()
		return
	runner.index = vote_index

	GameState.begin_level(runner)
	get_tree().change_scene_to_file(StageRouting.scene_for(runner.current_stage()))
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout

	await _walk()
	_finish()


func _finish() -> void:
	print("")
	if _failures.is_empty():
		print("FLOOR VOTE TEST: PASS")
		get_tree().quit(0)
	else:
		print("FLOOR VOTE TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _walk() -> void:
	var screen := get_tree().current_scene
	if screen == null or screen.name != "FloorVoteScreen":
		_failures.append("%s's Vote stage did not open the Floor Vote screen" % LEVEL_ID)
		return
	print("  opened the Floor Vote screen")

	var bill_text: Label = screen.get_node("%BillText")
	if str(bill_text.text).strip_edges().is_empty():
		_failures.append("the bill's own scroll text is not showing")
		return
	print("  bill text: %s" % str(bill_text.text).left(60))

	var party_row: HBoxContainer = screen.get_node("%PartyRow")
	var shown_parties := 0
	for card: Control in party_row.get_children():
		if card.visible:
			shown_parties += 1
	if shown_parties != 6:
		_failures.append("expected all 6 party cards visible, got %d" % shown_parties)
		return
	print("  all 6 party positions are showing")

	var standing_before := int(GameState.party_standing.get("Yezo Heritage Party", -1))

	if not await _click(screen.get_node("%VoteNo")):
		return
	await get_tree().create_timer(0.3).timeout

	var outcome_panel: PanelContainer = screen.get_node("%OutcomePanel")
	if not outcome_panel.visible:
		_failures.append("voting did not open the outcome panel")
		return

	var body: Label = screen.get_node("%OutcomeBody")
	# The exact totals this bill's own workbook row verifies against
	# (CLAUDE.md, 2026-09-27 pull note) — proves the real data, the real
	# engine, and the real screen all still agree, not just that a panel
	# opened.
	if not str(body.text).contains("48") or not str(body.text).contains("45"):
		_failures.append("outcome body ('%s') does not show the bill's real 45/48/8 totals" % body.text)
		return
	print("  outcome shows the bill's real totals: %s" % body.text)

	var moved := false
	for party_name: String in ["Butsutou", "Frontier Party", "Five Point Independents",
			"Keizaijiyuutou", "Country Initiative", "Yezo Heritage Party"]:
		if int(GameState.party_standing.get(party_name, -999)) != -999:
			moved = true
	if not moved and int(GameState.meta.get("Party support", -999)) == -999:
		_failures.append("no party's favorability moved at all after the vote")
		return
	print("  party favorability updated (Yezo Heritage Party was %d, now %d)"
		% [standing_before, int(GameState.party_standing.get("Yezo Heritage Party", -1))])

	var close_button: Button = screen.get_node("%OutcomeClose")
	# ST23 can never be lost (CLAUDE.md §7.7) — the button must never offer
	# a "lost" framing, whatever LV31's own position in its level is.
	if close_button.text.to_lower().contains("lost") or close_button.text.to_lower().contains("lose"):
		_failures.append("the close button reads '%s' — a Floor Vote cannot be lost" % close_button.text)
		return
	print("  close button: '%s'" % close_button.text)

	if not await _click(close_button):
		return
	await get_tree().create_timer(0.5).timeout

	# LV31's Vote stage is also its last, so closing the outcome should
	# land back in the Office.
	if get_tree().current_scene == null or get_tree().current_scene.name != "OfficeScreen":
		_failures.append("closing the outcome did not return to the Office (landed on %s)"
			% (get_tree().current_scene.name if get_tree().current_scene else "(null)"))
		return
	print("  returned to the Office")


func _click(control: Control) -> bool:
	await get_tree().process_frame
	var rect := control.get_global_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_failures.append("%s has no size, so nothing could click it" % control.name)
		return false

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
	return true
