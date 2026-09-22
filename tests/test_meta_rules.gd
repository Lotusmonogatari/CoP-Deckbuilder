extends GutTest
## Tests for the rules that apply between battles: bill difficulty, meta
## variable rewards, and the thresholds that switch effects on.
##
## A PASS HERE DOES NOT MEAN THE GAME DOES IT.
##
## Four of the rules covered below have no caller anywhere in the project —
## town_hall_triggered, steering_committee_triggered, funding_frozen and
## party_support_modifiers. These tests prove the arithmetic is right, and
## nothing more. The systems CLAUDE.md §8 describes are not switched on, and
## they wait for the module runner at M4; MetaRules.gd says the same at more
## length. Do not read a green run here as §8 being finished.


const BALANCE := {
	"bill_difficulty_factor": 0.2,
	"yoron_neutral_point": 50.0,
	"party_support_allied_buff": 75,
	"party_support_debuff": 50,
	"party_support_steering_committee": 25,
	"jiban_town_hall_trigger": 15,
	"jiban_funding_freeze": 0,
}

const SANBAN := [
	{"name_en": "Constituency support", "start": 50, "min": 0, "max": 100,
	 "low_threshold": 15, "high_threshold": 80},
	{"name_en": "Reputation", "start": 50, "min": 0, "max": 100,
	 "low_threshold": 20, "high_threshold": 80},
	{"name_en": "Funds", "start": 30, "min": 0, "max": 999},
	{"name_en": "Party support", "start": 50, "min": 0, "max": 100,
	 "low_threshold": 50, "high_threshold": 75},
]


# ---------------------------------------------------------------------------
# How hard a bill is
# ---------------------------------------------------------------------------

func test_a_bill_the_public_is_neutral_on_is_no_harder() -> void:
	# This is where every bill sits today: all eight opinion topics are still
	# at their placeholder 50.
	assert_eq(MetaRules.bill_difficulty(1, 50, 0.2, 50.0), 0)


func test_an_unpopular_bill_puts_the_opponent_ahead() -> void:
	# Asking for MORE of something the public is cold on (20 out of 100).
	# (50 - 20) x 0.2 = 6.
	assert_eq(MetaRules.bill_difficulty(1, 20, 0.2, 50.0), 6)


func test_a_popular_bill_gives_the_player_a_head_start() -> void:
	# (50 - 80) x 0.2 = -6, so the opponent starts six behind.
	assert_eq(MetaRules.bill_difficulty(1, 80, 0.2, 50.0), -6)


func test_a_bill_asking_for_less_reads_the_opinion_backwards() -> void:
	# A bill CUTTING taxes is easy exactly when the public is cold on
	# taxation. Opinion 20 means alignment 80, so (50 - 80) x 0.2 = -6.
	assert_eq(MetaRules.bill_difficulty(-1, 20, 0.2, 50.0), -6)

	# And a tax cut is hard when the public wants more taxation.
	assert_eq(MetaRules.bill_difficulty(-1, 80, 0.2, 50.0), 6)


func test_the_two_directions_are_mirror_images() -> void:
	for value in [0, 25, 50, 75, 100]:
		assert_eq(
			MetaRules.bill_difficulty(1, value, 0.2, 50.0),
			-MetaRules.bill_difficulty(-1, value, 0.2, 50.0),
			"opinion %d should mirror" % value
		)


func test_bill_difficulty_reads_straight_from_the_data_files() -> void:
	var bill := {"bill_id": "B01", "direction": 1, "topic_id": "Y03"}
	var topic := {"topic_id": "Y03", "start_value": 30}
	assert_eq(MetaRules.bill_difficulty_from_data(bill, topic, BALANCE), 4)


# ---------------------------------------------------------------------------
# Meta-variables
# ---------------------------------------------------------------------------

func test_a_meta_variable_stays_inside_its_range() -> void:
	var jiban := SANBAN[0]
	assert_eq(MetaRules.clamp_meta(150, jiban), 100, "capped at the maximum")
	assert_eq(MetaRules.clamp_meta(-10, jiban), 0, "floored at the minimum")
	assert_eq(MetaRules.clamp_meta(60, jiban), 60, "left alone in between")


func test_winning_a_stage_applies_its_rewards() -> void:
	var stage := TestFixtures.stage({
		"win_delta_jiban": 1, "win_delta_reputation": 2,
		"win_delta_yen": 0, "win_delta_party_support": 3,
	})
	var meta := {"Constituency support": 50, "Reputation": 50, "Funds": 30, "Party support": 50}

	var result := MetaRules.apply_win_deltas(meta, stage, SANBAN)
	assert_eq(result["meta"]["Constituency support"], 51)
	assert_eq(result["meta"]["Reputation"], 52)
	assert_eq(result["meta"]["Party support"], 53)
	assert_eq(result["meta"]["Funds"], 30, "a zero reward changes nothing")


func test_the_original_values_are_left_alone() -> void:
	var meta := {"Reputation": 50}
	MetaRules.apply_win_deltas(meta, TestFixtures.stage({"win_delta_reputation": 2}), SANBAN)
	assert_eq(meta["Reputation"], 50, "the caller's dictionary was not modified")


func test_a_reward_reports_what_actually_landed() -> void:
	# Reputation is already at 99 and the reward is 3, but the maximum is 100.
	# The UI must say "+1", not "+3".
	var meta := {"Reputation": 99}
	var result := MetaRules.apply_win_deltas(meta, TestFixtures.stage({"win_delta_reputation": 3}), SANBAN)

	assert_eq(result["meta"]["Reputation"], 100)
	assert_eq(result["applied"]["Reputation"], 1, "only one point had anywhere to go")


func test_a_penalty_is_applied_the_same_way() -> void:
	# The Steering Committee stage's win row carries negative numbers.
	var stage := TestFixtures.stage({"win_delta_reputation": -3, "win_delta_yen": -20})
	var meta := {"Reputation": 50, "Funds": 30}

	var result := MetaRules.apply_win_deltas(meta, stage, SANBAN)
	assert_eq(result["meta"]["Reputation"], 47)
	assert_eq(result["meta"]["Funds"], 10)


# ---------------------------------------------------------------------------
# Party support thresholds
# ---------------------------------------------------------------------------

func test_a_strong_party_standing_switches_on_party_backing() -> void:
	assert_eq(MetaRules.party_support_modifiers(80, BALANCE), ["M09"])


func test_a_weak_party_standing_switches_on_the_cold_shoulder() -> void:
	assert_eq(MetaRules.party_support_modifiers(40, BALANCE), ["M10"])


func test_neither_applies_in_the_middle() -> void:
	assert_eq(MetaRules.party_support_modifiers(60, BALANCE), [])


func test_the_thresholds_are_exclusive() -> void:
	# The workbook says "> 75" and "< 50", so sitting exactly on either
	# number does nothing.
	assert_eq(MetaRules.party_support_modifiers(75, BALANCE), [], "exactly 75 is not above 75")
	assert_eq(MetaRules.party_support_modifiers(50, BALANCE), [], "exactly 50 is not below 50")


func test_the_steering_committee_is_forced_when_the_party_turns() -> void:
	assert_true(MetaRules.steering_committee_triggered(20, BALANCE))
	assert_false(MetaRules.steering_committee_triggered(25, BALANCE), "exactly 25 is not below 25")


# ---------------------------------------------------------------------------
# Local support thresholds
# ---------------------------------------------------------------------------

func test_a_thin_local_base_calls_for_a_town_hall() -> void:
	assert_true(MetaRules.town_hall_triggered(15, BALANCE), "the trigger is 15 or below")
	assert_true(MetaRules.town_hall_triggered(10, BALANCE))
	assert_false(MetaRules.town_hall_triggered(16, BALANCE))


func test_no_local_base_freezes_the_money() -> void:
	assert_true(MetaRules.funding_frozen(0, BALANCE))
	assert_false(MetaRules.funding_frozen(1, BALANCE))


# ---------------------------------------------------------------------------
# Reputation in press stages
# ---------------------------------------------------------------------------

func test_a_strong_reputation_opens_a_press_stage_in_your_favour() -> void:
	assert_eq(MetaRules.press_start_adjustment(85, SANBAN), 5)
	assert_eq(MetaRules.press_start_adjustment(80, SANBAN), 5, "exactly on the threshold counts")


func test_a_poor_reputation_opens_it_against_you() -> void:
	assert_eq(MetaRules.press_start_adjustment(15, SANBAN), -5)
	assert_eq(MetaRules.press_start_adjustment(20, SANBAN), -5)


func test_an_ordinary_reputation_changes_nothing() -> void:
	assert_eq(MetaRules.press_start_adjustment(50, SANBAN), 0)


# ---------------------------------------------------------------------------
# Which modifiers fire for a stage's audience
# ---------------------------------------------------------------------------

func test_a_modifier_fires_when_its_audience_is_big_enough() -> void:
	# The test stage's audience is 60% loyalists; this modifier wants 30%.
	var modifiers := [{
		"mod_id": "M06", "trigger_segment_id": "SG02",
		"trigger_min_pct": 0.3, "available_to": "Both",
	}]
	var active := MetaRules.active_modifiers(modifiers, TestFixtures.stage())
	assert_eq(active.size(), 1)


func test_a_modifier_stays_quiet_when_its_audience_is_too_small() -> void:
	# Only 10% of this stage's audience are constituents.
	var modifiers := [{
		"mod_id": "M01", "trigger_segment_id": "SG03",
		"trigger_min_pct": 0.3, "available_to": "Both",
	}]
	assert_eq(MetaRules.active_modifiers(modifiers, TestFixtures.stage()).size(), 0)


func test_an_opponent_only_modifier_does_not_fire_for_the_player() -> void:
	var modifiers := [{
		"mod_id": "M07", "trigger_segment_id": "SG01",
		"trigger_min_pct": 0.1, "available_to": "Opponent",
	}]
	assert_eq(MetaRules.active_modifiers(modifiers, TestFixtures.stage(), "Player").size(), 0)
	assert_eq(MetaRules.active_modifiers(modifiers, TestFixtures.stage(), "Opponent").size(), 1)


func test_a_modifier_with_no_audience_condition_is_left_to_the_caller() -> void:
	# M09 and M10 are driven by party support, not by who is in the room.
	var modifiers := [{
		"mod_id": "M09", "trigger_segment_id": "SG02",
		"trigger_min_pct": null, "available_to": "Both",
	}]
	assert_eq(MetaRules.active_modifiers(modifiers, TestFixtures.stage()).size(), 0)


# ---------------------------------------------------------------------------
# What a stage's closing score does to the player's standing
# ---------------------------------------------------------------------------

func _scored_stage(overrides: Dictionary = {}) -> Dictionary:
	var effects := {"baseline": 50, "meta": {"Reputation": 5}}
	effects.merge(overrides, true)
	return {"name_en": "Press Conference", "tone_effects": effects}


func test_a_good_score_raises_the_variable_it_names() -> void:
	var result := MetaRules.apply_score_effects(
		{"Reputation": 50}, _scored_stage(), 70, SANBAN)

	assert_eq(int(result["meta"]["Reputation"]), 54, "twenty above, at five each")
	assert_eq(int(result["applied"]["Reputation"]), 4)


func test_a_bad_score_lowers_it() -> void:
	var result := MetaRules.apply_score_effects(
		{"Reputation": 50}, _scored_stage(), 30, SANBAN)

	assert_eq(int(result["meta"]["Reputation"]), 46)
	assert_eq(int(result["applied"]["Reputation"]), -4)


func test_falling_just_short_of_the_baseline_costs_nothing() -> void:
	var result := MetaRules.apply_score_effects(
		{"Reputation": 50}, _scored_stage(), 47, SANBAN)

	assert_eq(int(result["meta"]["Reputation"]), 50)
	assert_true(result["applied"].is_empty(), "and nothing is reported as having moved")


func test_a_stage_that_says_nothing_changes_nothing() -> void:
	var result := MetaRules.apply_score_effects(
		{"Reputation": 50}, {"name_en": "Committee"}, 90, SANBAN)

	assert_eq(int(result["meta"]["Reputation"]), 50)
	assert_true(result["applied"].is_empty())


func test_the_variables_ceiling_is_respected_and_reported_honestly() -> void:
	# The same rule apply_win_deltas follows: promise only what was delivered.
	var result := MetaRules.apply_score_effects(
		{"Reputation": 98}, _scored_stage(), 100, SANBAN)

	assert_eq(int(result["meta"]["Reputation"]), 100, "clamped to the maximum")
	assert_eq(int(result["applied"]["Reputation"]), 2,
		"two points, not the ten the score was worth")


func test_the_original_standing_is_left_alone() -> void:
	var before := {"Reputation": 50}
	MetaRules.apply_score_effects(before, _scored_stage(), 90, SANBAN)
	assert_eq(int(before["Reputation"]), 50, "a copy came back; this did not change")


# ---------------------------------------------------------------------------
# Winning a stage actually pays out
# ---------------------------------------------------------------------------
# apply_win_deltas was written at milestone 1 and had no production caller
# until now, so every stage in the game was won for nothing.

func test_a_win_and_a_score_both_move_the_same_variable() -> void:
	# A stage can pay flat for being won AND again for the number it closed
	# on. The player is owed the total, not whichever landed last.
	var stage := {
		"win_delta_reputation": 3,
		"tone_effects": {"baseline": 50, "meta": {"Reputation": 5}},
	}
	var meta := {"Reputation": 50}

	var after_win := MetaRules.apply_win_deltas(meta, stage, DataDB.sanban)
	var after_score := MetaRules.apply_score_effects(
		after_win["meta"], stage, 60, DataDB.sanban)

	assert_eq(int(after_win["applied"]["Reputation"]), 3, "flat, for winning")
	assert_eq(int(after_score["applied"]["Reputation"]), 2, "ten points above 50, at 1 per 5")
	assert_eq(int(after_score["meta"]["Reputation"]), 55, "and both landed")


func test_a_stage_with_zero_deltas_moves_nothing() -> void:
	# The state every playtest stage is in until Cameron fills the slots.
	var meta := {"Reputation": 50, "Funds": 50}
	var result := MetaRules.apply_win_deltas(meta, {
		"win_delta_jiban": 0, "win_delta_reputation": 0,
		"win_delta_yen": 0, "win_delta_party_support": 0,
	}, DataDB.sanban)

	assert_eq(result["applied"], {}, "nothing set, nothing claimed")
	assert_eq(result["meta"], meta)
