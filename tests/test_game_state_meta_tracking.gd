extends GutTest
## Lifetime meta-variables (stage_type_results, lifetime_gaffes,
## stages_lost_to_gaffes, the one-time gaffe penalty) and the three crisis
## triggers (Town Hall, Steering Committee, Funding Freeze) GameState.
## finish_stage() checks after every stage — CLAUDE.md §8, wired 2026-09-25.
##
## GameState is the run's memory and an autoload, so these tests put it back
## the way they found it, the same as test_game_state_staff.gd.
##
## Real balance.json thresholds are used rather than a fixture, the same way
## test_game_state_staff.gd tests real data/staff.json rows — these are the
## actual numbers a player meets: Town Hall at Jiban <= 15, Steering
## Committee at party support < 25, Funding Freeze at party support <= 0,
## the gaffe penalty at 50 lifetime gaffes for -15 Jiban.

var _meta_before: Dictionary = {}
var _runner_before: LevelRunner = null
var _mid_stage_before := false


func before_each() -> void:
	_meta_before = GameState.meta.duplicate(true)
	_runner_before = GameState.level_runner
	_mid_stage_before = GameState.mid_stage
	GameState.reset_crisis_triggers()


func after_each() -> void:
	GameState.meta = _meta_before.duplicate(true)
	GameState.level_runner = _runner_before
	GameState.mid_stage = _mid_stage_before
	GameState.reset_crisis_triggers()


## A level with two stages, so there is always somewhere for a triggered
## stage to be inserted ahead of. Real stage_ids (ST02/ST03) so anything
## that reads DataDB for them (none of this file's own checks do, but a
## defensive future caller might) finds something real.
func _begin_two_stage_level(jiban: int, party_support: int) -> void:
	GameState.meta["Constituency support"] = jiban
	GameState.meta["Party support"] = party_support
	var runner := LevelRunner.new({
		"level_id": "TEST",
		"stages": [
			{"seq": 1, "stage_id": "ST02", "name_en": "First", "opponents": [{"opp_id": "A"}]},
			{"seq": 2, "stage_id": "ST03", "name_en": "Second", "opponents": [{"opp_id": "B"}]},
		],
	})
	GameState.begin_level(runner)


# ---------------------------------------------------------------------------
# stage_type_results
# ---------------------------------------------------------------------------

func test_a_win_is_counted_for_its_own_stage_id() -> void:
	_begin_two_stage_level(50, 50)
	GameState.finish_stage(LevelRunner.WON)
	assert_eq(GameState.stage_type_results.get("ST02", {}).get("wins"), 1)
	assert_eq(GameState.stage_type_results.get("ST02", {}).get("losses", 0), 0)


func test_a_loss_is_counted_for_its_own_stage_id_and_ends_there() -> void:
	_begin_two_stage_level(50, 50)
	GameState.finish_stage(LevelRunner.LOST)
	assert_eq(GameState.stage_type_results.get("ST02", {}).get("losses"), 1)
	assert_true(GameState.stage_type_results.get("ST03", {}).is_empty(),
		"the level ended on the first stage, so the second was never played")


func test_the_same_stage_id_played_again_later_adds_to_its_own_bucket() -> void:
	_begin_two_stage_level(50, 50)
	GameState.finish_stage(LevelRunner.WON)   # ST02
	_begin_two_stage_level(50, 50)
	GameState.finish_stage(LevelRunner.WON)   # ST02 again, a different level
	assert_eq(GameState.stage_type_results.get("ST02", {}).get("wins"), 2)


# ---------------------------------------------------------------------------
# Lifetime gaffes
# ---------------------------------------------------------------------------

func test_lifetime_gaffes_sums_across_stages() -> void:
	_begin_two_stage_level(50, 50)
	GameState.finish_stage(LevelRunner.WON, 0, [], false, 2)
	_begin_two_stage_level(50, 50)
	GameState.finish_stage(LevelRunner.WON, 0, [], false, 3)
	assert_eq(GameState.lifetime_gaffes, 5)


func test_a_gaffe_caused_loss_is_counted_separately() -> void:
	_begin_two_stage_level(50, 50)
	GameState.finish_stage(LevelRunner.LOST, 0, [], true, 6)
	assert_eq(GameState.stages_lost_to_gaffes, 1)
	assert_eq(GameState.lifetime_gaffes, 6)


func test_a_loss_for_another_reason_does_not_count_as_a_gaffe_loss() -> void:
	# The exact bug caught in review: comparing BattleState.outcome_reason's
	# own (already-translated) text against a raw key never matched in a
	# real build. gaffe_caused_loss is a plain bool now — a loss that ISN'T
	# a gaffe loss (the turn limit, say) must pass false.
	_begin_two_stage_level(50, 50)
	GameState.finish_stage(LevelRunner.LOST, 0, [], false, 0)
	assert_eq(GameState.stages_lost_to_gaffes, 0)


func test_the_gaffe_penalty_fires_once_at_the_real_threshold() -> void:
	_begin_two_stage_level(50, 50)
	GameState.finish_stage(LevelRunner.WON, 0, [], false, 49)
	assert_false(GameState.gaffe_penalty_applied, "49 is still short of 50")
	var jiban_before := int(GameState.meta.get("Constituency support"))

	_begin_two_stage_level(int(GameState.meta.get("Constituency support")), 50)
	GameState.finish_stage(LevelRunner.WON, 0, [], false, 1)   # crosses 50

	assert_true(GameState.gaffe_penalty_applied)
	assert_eq(int(GameState.meta.get("Constituency support")), jiban_before - 15)


func test_the_gaffe_penalty_never_fires_twice() -> void:
	_begin_two_stage_level(80, 50)   # high enough that -15 twice still fits
	GameState.finish_stage(LevelRunner.WON, 0, [], false, 60)   # crosses 50
	var jiban_after_first := int(GameState.meta.get("Constituency support"))

	_begin_two_stage_level(jiban_after_first, 50)
	GameState.finish_stage(LevelRunner.WON, 0, [], false, 10)   # still >= 50

	assert_eq(int(GameState.meta.get("Constituency support")), jiban_after_first,
		"the penalty already fired once; it does not fire again")


# ---------------------------------------------------------------------------
# Town Hall / Steering Committee / Funding Freeze — enter, hold, leave
# ---------------------------------------------------------------------------

func test_town_hall_is_inserted_the_moment_jiban_crosses_the_threshold() -> void:
	_begin_two_stage_level(15, 50)   # <= 15
	GameState.finish_stage(LevelRunner.WON)

	assert_true(GameState.town_hall_active)
	var stage_ids: Array = []
	for stage: Dictionary in GameState.level_runner.stages:
		stage_ids.append(stage.get("stage_id"))
	assert_true(stage_ids.has("ST05"), "a Town Hall was inserted: %s" % [stage_ids])


func test_town_hall_does_not_insert_a_second_time_while_still_in_the_zone() -> void:
	_begin_two_stage_level(15, 50)
	GameState.finish_stage(LevelRunner.WON)   # fires, Jiban still <= 15 after
	var count_after_first := 0
	for stage: Dictionary in GameState.level_runner.stages:
		if stage.get("stage_id") == "ST05":
			count_after_first += 1

	GameState.finish_stage(LevelRunner.WON)   # still in the zone

	var count_after_second := 0
	for stage: Dictionary in GameState.level_runner.stages:
		if stage.get("stage_id") == "ST05":
			count_after_second += 1
	assert_eq(count_after_second, count_after_first,
		"losing/finishing the Town Hall while Jiban is still low must not queue another one")


func test_town_hall_reports_leaving_the_zone_once_jiban_recovers() -> void:
	_begin_two_stage_level(15, 50)
	GameState.finish_stage(LevelRunner.WON)
	assert_true(GameState.town_hall_active)

	GameState.meta["Constituency support"] = 50   # recovered
	GameState.finish_stage(LevelRunner.WON)

	assert_false(GameState.town_hall_active)
	var left_alert := false
	for alert: Dictionary in GameState.pending_trigger_alerts:
		if alert.get("kind") == "town_hall" and alert.get("edge") == "left":
			left_alert = true
	assert_true(left_alert)


func test_town_hall_fires_again_after_leaving_and_re_entering() -> void:
	# Four of this level's own stages, not two: every fire below splices in
	# an extra stage, and re-entering needs somewhere left to insert into —
	# the level must not have just run out on the very call being tested.
	GameState.meta["Constituency support"] = 15
	GameState.meta["Party support"] = 50
	var runner := LevelRunner.new({
		"level_id": "TEST",
		"stages": [
			{"seq": 1, "stage_id": "ST02", "name_en": "A", "opponents": [{"opp_id": "A"}]},
			{"seq": 2, "stage_id": "ST03", "name_en": "B", "opponents": [{"opp_id": "B"}]},
			{"seq": 3, "stage_id": "ST04", "name_en": "C", "opponents": [{"opp_id": "C"}]},
			{"seq": 4, "stage_id": "ST06", "name_en": "D", "opponents": [{"opp_id": "D"}]},
		],
	})
	GameState.begin_level(runner)

	GameState.finish_stage(LevelRunner.WON)   # entered
	GameState.meta["Constituency support"] = 50
	GameState.finish_stage(LevelRunner.WON)   # left
	assert_false(GameState.town_hall_active)

	GameState.meta["Constituency support"] = 10   # back in the zone
	GameState.finish_stage(LevelRunner.WON)

	assert_true(GameState.town_hall_active)


func test_steering_committee_inserts_st22_not_st08() -> void:
	_begin_two_stage_level(50, 24)   # < 25
	GameState.finish_stage(LevelRunner.WON)

	assert_true(GameState.steering_committee_active)
	var stage_ids: Array = []
	for stage: Dictionary in GameState.level_runner.stages:
		stage_ids.append(stage.get("stage_id"))
	assert_true(stage_ids.has("ST22"), "the new check-in room: %s" % [stage_ids])
	assert_false(stage_ids.has("ST08"),
		"ST08 is the hand-placed canon committee — never auto-inserted")


func test_a_crisis_trigger_does_not_insert_into_a_level_that_just_ended() -> void:
	# A single-stage level: finishing it ends the level on this exact call,
	# so there is nowhere to put a forced-in stage. The trigger must not
	# crash, and must not claim to have fired (no alert, flag stays false)
	# — it gets the next opportunity instead, whenever that is.
	GameState.meta["Constituency support"] = 5
	GameState.meta["Party support"] = 50
	var runner := LevelRunner.new({
		"level_id": "TEST_ONE_STAGE",
		"stages": [{"seq": 1, "stage_id": "ST02", "name_en": "Only", "opponents": [{"opp_id": "A"}]}],
	})
	GameState.begin_level(runner)

	GameState.finish_stage(LevelRunner.WON)

	assert_false(GameState.town_hall_active)
	assert_true(GameState.pending_trigger_alerts.is_empty())


# ---------------------------------------------------------------------------
# Funding Freeze — no insertion, both edges always fire, income is zeroed
# ---------------------------------------------------------------------------

func test_funding_freeze_fires_the_entered_edge_at_zero_party_support() -> void:
	_begin_two_stage_level(50, 0)
	GameState.finish_stage(LevelRunner.WON)
	assert_true(GameState.funding_frozen_active)


func test_funding_freeze_zeroes_this_stages_funds_income() -> void:
	GameState.meta["Constituency support"] = 50
	GameState.meta["Party support"] = 0
	GameState.meta["Funds"] = 0
	var runner := LevelRunner.new({
		"level_id": "TEST",
		"stages": [{"seq": 1, "stage_id": "ST02", "name_en": "First",
			"opponents": [{"opp_id": "A"}], "win_delta_yen": 5000}],
	})
	GameState.begin_level(runner)

	GameState.finish_stage(LevelRunner.WON)

	assert_eq(int(GameState.meta.get("Funds")), 0, "frozen — the 5000 win reward never lands")


func test_funding_freeze_fires_even_though_the_level_just_ended() -> void:
	# Unlike Town Hall/Steering Committee, there is nothing to insert, so
	# there is no "nowhere to put it" case — the freeze itself is a live
	# fact about the current number, not an event with a queue slot.
	GameState.meta["Constituency support"] = 50
	GameState.meta["Party support"] = 0
	var runner := LevelRunner.new({
		"level_id": "TEST_ONE_STAGE",
		"stages": [{"seq": 1, "stage_id": "ST02", "name_en": "Only", "opponents": [{"opp_id": "A"}]}],
	})
	GameState.begin_level(runner)

	GameState.finish_stage(LevelRunner.WON)

	assert_true(GameState.funding_frozen_active)


func test_funding_freeze_reports_leaving_once_party_support_recovers() -> void:
	_begin_two_stage_level(50, 0)
	GameState.finish_stage(LevelRunner.WON)
	assert_true(GameState.funding_frozen_active)

	GameState.meta["Party support"] = 50
	GameState.finish_stage(LevelRunner.WON)

	assert_false(GameState.funding_frozen_active)
