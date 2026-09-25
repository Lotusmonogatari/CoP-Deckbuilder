extends Node
## Fuzzes GameState.finish_stage()'s crisis-trigger wiring: hundreds of
## stage completions with randomized outcomes and meta swings, checking
## invariants after every single call rather than a few hand-picked
## scenarios. Prints PASS/FAIL and exits with a matching code, so it can be
## dropped into a CI step directly if it earns a permanent place later.
##
##     godot --headless --path . tools/stress_crisis_triggers.tscn
##
## Not part of tools/verify.sh — this is a debugging pass, not a repeatable
## regression test (no fixed seed, deliberately, so a run that turns up
## something bad can be reported and then reproduced by hand with that
## exact meta value).

const ITERATIONS := 500
const STAGE_IDS := ["ST02", "ST03", "ST04", "ST06"]

var _failures: Array[String] = []
var _iterations_run := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	randomize()

	GameState.meta["Constituency support"] = randi_range(0, 100)
	GameState.meta["Party support"] = randi_range(0, 100)
	GameState.meta["Funds"] = randi_range(0, 500000)
	_begin_level()

	for i in range(ITERATIONS):
		_iterations_run = i + 1

		# Random meta swings BEFORE the check, same as a real level's win/loss
		# deltas would produce — this is what actually crosses thresholds
		# back and forth repeatedly, the exact case hysteresis exists for.
		GameState.meta["Constituency support"] = clampi(
			int(GameState.meta["Constituency support"]) + randi_range(-20, 20), 0, 100)
		GameState.meta["Party support"] = clampi(
			int(GameState.meta["Party support"]) + randi_range(-20, 20), 0, 100)

		var outcome := LevelRunner.WON if randf() < 0.8 else LevelRunner.LOST
		var gaffe_caused := outcome == LevelRunner.LOST and randf() < 0.3
		var gaffes := randi_range(0, 6)

		if GameState.level_runner == null or GameState.level_runner.is_finished():
			_begin_level()

		var jiban_before := int(GameState.meta["Constituency support"])
		var party_before := int(GameState.meta["Party support"])

		GameState.finish_stage(outcome, randi_range(0, 100), [], gaffe_caused, gaffes)

		_check_invariants(i, jiban_before, party_before)

		if not _failures.is_empty():
			break

	_report()


func _begin_level() -> void:
	var stages: Array = []
	for n in range(randi_range(2, 5)):
		stages.append({
			"seq": n + 1,
			"stage_id": STAGE_IDS[randi() % STAGE_IDS.size()],
			"name_en": "Stress %d" % n,
			"opponents": [{"opp_id": "A"}],
			"win_delta_yen": randi_range(-1000, 5000),
		})
	GameState.begin_level(LevelRunner.new({"level_id": "STRESS", "stages": stages}))


func _check_invariants(i: int, jiban_before: int, party_before: int) -> void:
	var runner := GameState.level_runner
	if runner != null:
		# seq is strictly increasing, 1..N, no gaps or duplicates — the one
		# thing insert_stage()'s renumbering has to hold no matter how many
		# times it fires in a row.
		var seqs: Array = []
		for stage: Dictionary in runner.stages:
			seqs.append(int(stage.get("seq", -1)))
		var expected: Array = []
		for n in range(seqs.size()):
			expected.append(n + 1)
		if seqs != expected:
			_fail(i, "seq is not a clean 1..N sequence: %s" % [seqs])

		# Every stage still resolves to real, enrichable data — a broken
		# insertion (e.g. an unresolved stage_id) would otherwise sit quietly
		# in the queue until a player actually reached it.
		for stage: Dictionary in runner.stages:
			var sid := str(stage.get("stage_id", ""))
			if DataDB.get_stage(sid).is_empty():
				_fail(i, "stage queue has an unresolvable stage_id '%s'" % sid)

	# The flags must always agree with the pure condition, since nothing
	# else is allowed to touch meta between the check and this assertion.
	var jiban := int(GameState.meta.get("Constituency support", 0))
	var party := int(GameState.meta.get("Party support", 0))
	var town_hall_condition := MetaRules.town_hall_triggered(jiban, DataDB.balance)
	var steering_condition := MetaRules.steering_committee_triggered(party, DataDB.balance)
	var freeze_condition := MetaRules.funding_frozen(party, DataDB.balance)

	if freeze_condition != GameState.funding_frozen_active:
		_fail(i, "funding_frozen_active (%s) disagrees with the live condition (%s) at party=%d"
			% [GameState.funding_frozen_active, freeze_condition, party])

	# Town Hall/Steering Committee can legitimately lag the condition by one
	# call (the "nowhere to insert" deferral), so this only checks the
	# invariant hysteresis promises: the flag is never true when the
	# condition is false (that would mean a phantom "still in the zone").
	if GameState.town_hall_active and not town_hall_condition:
		_fail(i, "town_hall_active is true but Jiban (%d) is not in the trigger zone" % jiban)
	if GameState.steering_committee_active and not steering_condition:
		_fail(i, "steering_committee_active is true but party support (%d) is not in the trigger zone" % party)

	# Meta stays inside sanban.json's own bounds no matter what combination
	# of win/loss deltas and the gaffe penalty landed this call.
	for name: String in ["Constituency support", "Party support", "Funds", "Reputation"]:
		var value := int(GameState.meta.get(name, 0))
		if value < 0:
			_fail(i, "%s went negative: %d" % [name, value])

	if GameState.lifetime_gaffes < 0:
		_fail(i, "lifetime_gaffes went negative: %d" % GameState.lifetime_gaffes)
	if GameState.stages_lost_to_gaffes < 0:
		_fail(i, "stages_lost_to_gaffes went negative")

	# Silence unused-parameter warnings without weakening the signature —
	# both values are for a future check (e.g. "meta only moves by a
	# plausible amount"), kept explicit rather than dropped.
	var _unused := [jiban_before, party_before]


func _fail(i: int, message: String) -> void:
	_failures.append("iteration %d: %s" % [i, message])


func _report() -> void:
	print("Ran %d/%d iterations." % [_iterations_run, ITERATIONS])
	print("lifetime_gaffes=%d stages_lost_to_gaffes=%d gaffe_penalty_applied=%s" % [
		GameState.lifetime_gaffes, GameState.stages_lost_to_gaffes, GameState.gaffe_penalty_applied])
	print("stage_type_results=%s" % [GameState.stage_type_results])

	if _failures.is_empty():
		print("STRESS TEST: PASS")
		get_tree().quit(0)
	else:
		print("STRESS TEST: FAIL")
		for f: String in _failures:
			print("  X " + f)
		get_tree().quit(1)
