class_name TradeDriver
extends Node
## Walks a real lobbyist trade with real clicks (influence building step C,
## 2026-10-19): the offer, choosing a component to give up, three negotiation
## answers moving the leverage meter, spending leverage on a reward, the deal,
## and the Floor Vote that follows carrying the smaller bill. Then a second
## level where the player refuses to meet.

var _failures: PackedStringArray = []
var _bill_id := ""


func _ready() -> void:
	_run.call_deferred()


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	print("")
	if _failures.is_empty():
		print("TRADE TEST: PASS")
		get_tree().quit(0)
	else:
		print("TRADE TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


## A new run, positioned at the lobbyist stage of a patron level that has one.
func _start_trade_level() -> bool:
	DataDB.clear_runtime()
	GameState.start_new_run("PC01")
	_bill_id = ""
	for row: Dictionary in DataDB.patron_bills:
		var built := PatronLevel.register(str(row["patron_bill_id"]), [])
		DataDB.clear_runtime()
		if (built["level"] as Dictionary).has("trade"):
			_bill_id = str(row["patron_bill_id"])
			if row["kind"] == "Flagship":
				GameState.patron_requests[str(row["organization"]).replace("BO", "PB") + "1"] = {}
			break
	if _bill_id.is_empty():
		_fail("no patron bill has a lobbyist trade")
		return false
	GameState.booster_standing[str(PatronLevel.patron_bill(_bill_id)["organization"])] = 80
	GameState.meta["Funds"] = 20000
	if not GameState.start_patron_level(_bill_id):
		_fail("the patron level would not start")
		return false
	while str(GameState.level_runner.current_stage().get("stage_id", "")) != LobbyistTrade.TRADE_STAGE:
		GameState.finish_stage(LevelRunner.WON)
	get_tree().change_scene_to_file(StageRouting.scene_for(GameState.level_runner.current_stage()))
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	return true


func _run() -> void:
	if not await _start_trade_level():
		_finish()
		return
	var screen := get_tree().current_scene
	if screen == null or screen.name != "TradeScreen":
		_fail("the trade stage did not open the trade screen (opened %s)" % (screen.name if screen else "nothing"))
		_finish()
		return
	print("  opened the trade screen for %s" % _bill_id)
	var trade := GameState.current_trade()
	var question: Label = screen.get_node("%QuestionLabel")
	if not str(question.text).contains(str(trade["lobbyist_name"])):
		_fail("the offer does not name the lobbyist: '%s'" % question.text)

	if not await _click(screen.get_node("%ChoiceA")):   # hear them out
		_finish()
		return
	var drops: Array = trade["drops"]
	var shown := 0
	for letter in ["A", "B", "C", "D"]:
		if screen.get_node("%Choice" + letter).visible:
			shown += 1
	if shown != drops.size() + 1:
		_fail("the pick shows %d buttons for %d components (plus Keep all)" % [shown, drops.size()])
	print("  pick: %s" % str(question.text).left(80))
	var components_before: int = (GameState.patron_requests[_bill_id]["components"] as Array).size()
	if not await _click(screen.get_node("%ChoiceA")):   # give up the first component
		_finish()
		return

	var bar: ProgressBar = screen.get_node("%LeverageBar") if screen.has_node("%LeverageBar") else screen.find_child("LeverageBar", true, false)
	if bar == null or not bar.visible:
		_fail("the leverage meter is not showing")
		_finish()
		return
	var banner: Node = screen.get_node("CueBanner")
	var start_leverage := int(bar.value)
	print("  leverage starts at %d" % start_leverage)
	for round_number in range(3):
		if not await _click(screen.get_node("%ChoiceA")):
			_finish()
			return
		banner.clear()
		await get_tree().process_frame
		if not await _click(screen.get_node("%ContinueButton")):
			_finish()
			return
	print("  leverage after three answers: %d" % int(bar.value))

	# The package: choose a reward the leverage can pay for.
	var cheapest: Button = screen.get_node("%ChoiceA")   # the office donation
	if int(bar.value) < LobbyistTrade.reward_cost("donation", DataDB.balance):
		_fail("leverage %d cannot buy even a donation; the test cannot go on" % int(bar.value))
		_finish()
		return
	if not await _click(cheapest):
		_finish()
		return
	if screen.get_node("%ContinueButton").disabled:
		_fail("Make the deal stayed locked with a paid-for reward chosen")
	if not await _click(screen.get_node("%ContinueButton")):
		_finish()
		return
	var outcome_panel: PanelContainer = screen.get_node("%OutcomePanel")
	if not outcome_panel.visible:
		_fail("the deal's summary did not open")
		_finish()
		return
	print("  deal: %s" % str(screen.get_node("%OutcomeBody").text).left(100))
	var components_after: int = (GameState.patron_requests[_bill_id]["components"] as Array).size()
	if components_after != components_before - 1:
		_fail("the bill kept %d components after the deal (was %d)" % [components_after, components_before])
	if int(GameState.meta["Funds"]) <= 20000:
		_fail("the donation did not pay Funds")
	if not await _click(screen.get_node("%OutcomeClose")):
		_finish()
		return
	await get_tree().create_timer(0.5).timeout
	var next := get_tree().current_scene
	if next == null or next.name != "FloorVoteScreen":
		_fail("after the deal the Floor Vote did not open (opened %s)" % (next.name if next else "nothing"))
	else:
		var bill_text: Label = next.get_node("%BillText")
		print("  the vote is on the smaller bill: %s" % str(bill_text.text).left(70))

	# A second level: refuse to meet.
	GameState.abandon_level()
	if not await _start_trade_level():
		_finish()
		return
	screen = get_tree().current_scene
	if not await _click(screen.get_node("%ChoiceB")):   # refuse
		_finish()
		return
	if not screen.get_node("%OutcomePanel").visible:
		_fail("refusing did not show a result")
	else:
		print("  refused: %s" % str(screen.get_node("%OutcomeBody").text).left(100))
	if not bool(GameState.current_trade().get("done", false)):
		_fail("the refusal was not recorded")
	_finish()


func _click(control: Control) -> bool:
	await get_tree().process_frame
	var rect := control.get_global_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_fail("%s has no size, so nothing could click it" % control.name)
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
