extends GutTest
## Tests for the named card effects behind SpecialEffects.gd.


func _effect() -> Dictionary:
	return {"self_plus": 4, "opp_minus": 0, "guard": 0, "draw": 0, "gaffe": 0}


func test_an_unrecognized_key_leaves_the_numbers_untouched() -> void:
	var result := SpecialEffects.apply("not_a_real_key", 2, _effect(), {})
	assert_eq(result["self_plus"], 4)
	assert_false(result["flags"].get("special_triggered", false))


func test_a_blank_key_does_nothing() -> void:
	var result := SpecialEffects.apply("", 2, _effect(), {})
	assert_eq(result, {"self_plus": 4, "opp_minus": 0, "guard": 0, "draw": 0, "gaffe": 0, "flags": {}})


# ---------------------------------------------------------------------------
# The bonus_if_target_segment_ge_10 .. _100 family
# ---------------------------------------------------------------------------
# One effect covers every ten-point mark: C04 checks Constituents >= 30%,
# C09/C10 check >= 50%, and any future card can ask for any other mark in the
# same family without a new case in SpecialEffects.gd.

func test_every_ten_point_threshold_is_known() -> void:
	for threshold in [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]:
		assert_true(SpecialEffects.KNOWN_KEYS.has("bonus_if_target_segment_ge_%d" % threshold),
			"ge_%d should be a known key" % threshold)


func test_the_bonus_applies_at_or_above_its_own_threshold() -> void:
	var result := SpecialEffects.apply(
		"bonus_if_target_segment_ge_30", 2, _effect(), {"segment_share": 0.30})
	assert_eq(result["self_plus"], 6, "at exactly 30%, the >= 30 bonus fires")
	assert_true(result["flags"]["special_triggered"])


func test_the_bonus_does_not_apply_below_its_own_threshold() -> void:
	var result := SpecialEffects.apply(
		"bonus_if_target_segment_ge_30", 2, _effect(), {"segment_share": 0.29})
	assert_eq(result["self_plus"], 4, "just under 30%, nothing extra")
	assert_false(result["flags"].get("special_triggered", false))


func test_a_higher_threshold_does_not_fire_on_a_lower_share() -> void:
	# C04's own 30% mark must not accidentally borrow C09's 50% one, or the
	# other way around — each key checks only its own number.
	var result := SpecialEffects.apply(
		"bonus_if_target_segment_ge_50", 2, _effect(), {"segment_share": 0.30})
	assert_eq(result["self_plus"], 4)


func test_the_ge_100_mark_needs_the_whole_audience() -> void:
	var short_of_all := SpecialEffects.apply(
		"bonus_if_target_segment_ge_100", 3, _effect(), {"segment_share": 0.99})
	assert_eq(short_of_all["self_plus"], 4)

	var all_of_it := SpecialEffects.apply(
		"bonus_if_target_segment_ge_100", 3, _effect(), {"segment_share": 1.0})
	assert_eq(all_of_it["self_plus"], 7)


# ---------------------------------------------------------------------------
# A few of the older, still-distinct effects, so the family above is proven
# not to have swallowed them
# ---------------------------------------------------------------------------

func test_doubling_is_still_its_own_effect_not_the_bonus_family() -> void:
	var result := SpecialEffects.apply(
		"double_if_target_segment_ge_50", null, _effect(), {"segment_share": 0.5})
	assert_eq(result["self_plus"], 8, "doubled, not +the missing amount")


func test_bonus_if_behind_is_unaffected_by_the_prefix_check() -> void:
	var result := SpecialEffects.apply("bonus_if_behind", 3, _effect(),
		{"player_support": 10, "opponent_support": 20})
	assert_eq(result["self_plus"], 7)
