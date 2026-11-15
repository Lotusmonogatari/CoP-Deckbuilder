extends Node
## Audit follow-up: the invariants and expectations that were "not tested" in
## audit/testing.md (INV-11, INV-17, INV-18, INV-19, the second half of INV-24,
## reload seating, worst-case save size). Headless, read-only.
##
##   .tools/godot --headless --path . audit/tests/followup_probe.tscn
##   AUDIT_OUT=/path/out.json

var _out := {}


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	seed(21)
	DataDB.clear_runtime()
	GameState.start_new_run("PC02")
	_inv17_calendar_gate()
	_inv18_crisis_edges()
	_inv19_acts()
	_inv24_pending_result_and_seating()
	_save_size_worst_case()
	var path := OS.get_environment("AUDIT_OUT")
	if path.is_empty():
		path = "user://audit_followup.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_out, "\t"))
	file.close()
	print("AUDIT FOLLOWUP written to %s" % path)
	get_tree().quit(0)


## INV-17: with H work hours left, a level starts only if it fits; none starts
## when the week is full; the weekend takes only weekend-ready levels that fit.
func _inv17_calendar_gate() -> void:
	var cfg := GameState.calendar_config()
	var wrong := []
	var counts := {}
	for hours_left: int in [40, 20, 10, 4, 0]:
		var refused := 0
		var allowed := 0
		var checked := 0
		for level: Dictionary in DataDB.levels:
			# set hours so exactly `hours_left` remain in the work week
			GameState.calendar = {"week": 0, "phase": "work", "hours": WeekCalendar.pool_hours("work", cfg) - hours_left}
			var refusal := GameState.level_calendar_refusal(level)
			var needed := GameState.level_hours(level)
			var should_refuse := needed > hours_left or hours_left <= 0
			checked += 1
			if refusal.is_empty():
				allowed += 1
			else:
				refused += 1
			if refusal.is_empty() == should_refuse and wrong.size() < 12:
				wrong.append("%s: %d h needed, %d left, refusal='%s'" % [level.get("level_id"), needed, hours_left, refusal])
		counts[str(hours_left)] = {"levels": checked, "startable": allowed, "refused": refused}
	var longest := 0
	for level: Dictionary in DataDB.levels:
		longest = maxi(longest, GameState.level_hours(level))
	_out["INV-17"] = {"by_hours_left": counts, "mismatches": wrong, "longest_level_hours": longest,
		"work_week_hours": WeekCalendar.pool_hours("work", cfg)}
	GameState.calendar = WeekCalendar.fresh()


## INV-18: each crisis fires once when the value crosses in, and again only
## after it has come back out.
func _inv18_crisis_edges() -> void:
	GameState.pending_trigger_alerts.clear()
	var steps := []
	var set_con := func(value: int) -> void:
		GameState.meta["Constituency support"] = value
		GameState.check_crisis_triggers()
	var kinds := func() -> Array:
		var found := []
		for alert: Dictionary in GameState.pending_trigger_alerts:
			found.append("%s:%s" % [alert.get("kind"), alert.get("edge")])
		return found
	GameState.meta["Party support"] = 50   # keep the other triggers out of it
	set_con.call(50); steps.append(["con 50", kinds.call()])
	set_con.call(14); steps.append(["con 14 (cross in)", kinds.call()])
	set_con.call(10); steps.append(["con 10 (still in)", kinds.call()])
	set_con.call(9); steps.append(["con 9 (still in)", kinds.call()])
	set_con.call(40); steps.append(["con 40 (cross out)", kinds.call()])
	set_con.call(12); steps.append(["con 12 (cross in again)", kinds.call()])
	var entered := 0
	var left := 0
	for entry: String in kinds.call():
		if entry == "town_hall:entered":
			entered += 1
		if entry == "town_hall:left":
			left += 1
	_out["INV-18"] = {"steps": steps, "town_hall_entered": entered, "town_hall_left": left,
		"expected": "entered 2, left 1"}
	GameState.pending_trigger_alerts.clear()
	GameState.meta["Constituency support"] = 20
	GameState.check_crisis_triggers()


## INV-19: an Aye or Nay is final; an absent or abstained entry may be replaced;
## and INV-11: the rooms that cannot be lost have no way to lose in their engines.
func _inv19_acts() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC02")
	var level := {}
	var bill := {}
	for row: Dictionary in DataDB.levels:
		var b := DataDB.get_floor_vote(str(row.get("level_id", "")))
		if not b.is_empty():
			level = row
			bill = b
			break
	var bill_id := str(bill.get("bill_id", ""))
	var states := []
	var vote := func(choice: String, absent: bool) -> void:
		var enriched := BattleSetup.enriched_floor_vote(bill)
		var engine := FloorVoteEngine.new()
		engine.setup({"bill": enriched, "player_party": str(DataDB.player.get("party", "")),
			"meta": GameState.effective_meta(), "booster_standing": GameState.booster_standing,
			"triggers": DataDB.vote_influence_triggers, "default_threshold": 85, "default_resistance": 85,
			"supermajority_percent": 67, "assist": GameState.bill_assist})
		GameState.record_floor_vote(enriched, engine.choose(choice), choice, absent)
	states.append(["before any vote", GameState.act_is_settled(level), GameState.statute_book.size()])
	vote.call("Abstain", true)
	states.append(["absent", GameState.act_is_settled(level), GameState.statute_book.size()])
	vote.call("Abstain", false)
	states.append(["abstain (replaces the absent entry)", GameState.act_is_settled(level), GameState.statute_book.size()])
	vote.call("Yes", false)
	states.append(["Aye (replaces the abstain)", GameState.act_is_settled(level), GameState.statute_book.size()])
	vote.call("No", false)
	states.append(["Nay after an Aye (must be ignored)", GameState.act_is_settled(level), GameState.statute_book.size()])
	var kept := ""
	for law: Dictionary in GameState.statute_book:
		if str(law.get("bill_id", "")) == bill_id:
			kept = str(law.get("player_vote", ""))
	var replay_hours := 0
	for row: Dictionary in DataDB.levels:
		if DataDB.get_floor_vote(str(row.get("level_id", ""))).is_empty():
			continue
		replay_hours = maxi(replay_hours, int(row.get("cooldown", 0)))
	_out["INV-19"] = {"bill": bill_id, "steps": states, "final_entry_vote": kept,
		"expected_final": "Yes", "largest_bill_level_cooldown": replay_hours,
		"bill_levels": DataDB.levels.filter(func(r: Dictionary) -> bool: return not DataDB.get_floor_vote(str(r.get("level_id", ""))).is_empty()).size()}
	# INV-11: neither the Office Hours nor the Floor Vote engine has any way to
	# report a loss (a source search; see audit/edge_cases.md).
	var lost_words := 0
	for path: String in ["res://scripts/rules/OfficeHoursEngine.gd", "res://scripts/rules/FloorVoteEngine.gd"]:
		var text := FileAccess.get_file_as_string(path)
		lost_words += text.count("LOST") + text.count("\"loss\"")
	var loss_ends := []
	for stage: Dictionary in DataDB.stages:
		if str(stage.get("mode", "")) in ["Non-combat", "Vote"] and str(stage.get("loss_ends_level", "")) not in ["", "null", "No", "no"] and stage.get("loss_ends_level") != null:
			loss_ends.append(str(stage.get("stage_id")))
	_out["INV-11"] = {"loss_words_in_the_two_engines": lost_words, "non_combat_or_vote_stages_that_end_a_level_on_loss": loss_ends}


## INV-24 (second half) and reload seating: a result recorded before the result
## panel is dismissed must survive save then load, and a level's seated
## opponents must be the same after a reload.
func _inv24_pending_result_and_seating() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC02")
	var level_id := ""
	for row: Dictionary in DataDB.levels:
		var runner := LevelRunner.new(BattleSetup.expand_level(row))
		if runner.is_valid() and str(runner.current_stage().get("mode", "")) == "Combat" \
				and (runner.current_stage().get("opponents", []) as Array).size() >= 2:
			level_id = str(row.get("level_id", ""))
			break
	var runner := LevelRunner.new(BattleSetup.expand_level(DataDB.get_level(level_id)))
	GameState.begin_level(runner)
	var before: Array = []
	for opponent: Variant in GameState.level_runner.current_stage().get("opponents", []):
		before.append(str((opponent as Dictionary).get("opp_id", "")))
	GameState.record_pending_stage_result({"outcome": "loss", "score": 12, "boosters": [], "gaffe_caused_loss": true, "leftover_gaffes": 3})
	var key_before := GameState.stage_checkpoint_key()
	var path := "user://audit_followup_save.json"
	SaveManager.save_game(path)
	GameState.xp += 999   # disturb, then load
	GameState.level_runner = null
	GameState.pending_stage_result = {}
	var loaded := SaveManager.load_game(path)
	var after: Array = []
	if GameState.level_runner != null:
		for opponent: Variant in GameState.level_runner.current_stage().get("opponents", []):
			after.append(str((opponent as Dictionary).get("opp_id", "")))
	var result := GameState.pending_result_for_current_stage()
	_out["INV-24b"] = {"level": level_id, "loaded": loaded, "key_before": key_before, "key_after": GameState.stage_checkpoint_key(),
		"pending_result_after_load": result.get("outcome", "(none)"), "score": result.get("score", -1),
		"opponents_before": before, "opponents_after": after, "same_opponents": before == after}
	# A kill and relaunch: the same file read into a fresh state.
	SaveManager.delete_save(path)
	GameState.abandon_level()


## A worst case, not a measurement of a real run: every list filled to its
## largest plausible size, to see whether a save can approach the 1 MB proposal.
func _save_size_worst_case() -> void:
	DataDB.clear_runtime()
	GameState.start_new_run("PC02")
	for card: Dictionary in DataDB.cards:
		if not GameState.owned_cards.has(str(card.get("card_id", ""))):
			GameState.owned_cards.append(str(card.get("card_id", "")))
	for key: String in DataDB.floor_votes.keys():
		GameState.statute_book.append({"bill_id": key, "passed": true, "player_vote": "Yes", "yes": 60, "no": 30, "abstain": 11,
			"absent": false, "flipped": false, "effects": [], "date": "28.12.31", "name": "x".repeat(40)})
	for person: Dictionary in DataDB.opponents:
		GameState.met_characters[str(person.get("opp_id"))] = true
		GameState.faced_people[str(person.get("opp_id"))] = 50
	for visitor: Dictionary in DataDB.visitors:
		GameState.met_characters[str(visitor.get("visitor_id"))] = true
	for i in 200:
		GameState.promises.append({"id": "P%d" % i, "kind": "hours", "amount": 2, "for_org": "BO01", "due": 99999})
	for stage: Dictionary in DataDB.stages:
		GameState.stage_type_results[str(stage.get("stage_id"))] = {"wins": 99, "losses": 99}
	for level: Dictionary in DataDB.levels:
		GameState.levels_cleared[str(level.get("level_id"))] = 99
		GameState.level_cleared_units[str(level.get("level_id"))] = 999999
		GameState.level_last_completed_at[str(level.get("level_id"))] = 999
	var path := "user://audit_followup_big.json"
	var started := Time.get_ticks_usec()
	SaveManager.save_game(path)
	var elapsed := Time.get_ticks_usec() - started
	var size := FileAccess.get_file_as_bytes(path).size()
	_out["save_size_worst_case"] = {"bytes": size, "kilobytes": snappedf(size / 1024.0, 0.1), "write_ms": snappedf(elapsed / 1000.0, 0.01),
		"statute_entries": GameState.statute_book.size(), "met": GameState.met_characters.size(), "promises": GameState.promises.size()}
	SaveManager.delete_save(path)
