extends GutTest
## Election strength (2026-10-23): inputs, the potential, and a slow stock.

var _cfg := ElectionStrength.settings({})
var _before := 0.0
var _earned_before := 0


func before_each() -> void:
	_before = GameState.election_strength
	_earned_before = GameState.xp_earned_total


func after_each() -> void:
	GameState.election_strength = _before
	GameState.xp_earned_total = _earned_before


func _zero() -> Dictionary:
	return {"district": 0, "national": 0, "constituency": 0, "org_share": 0.0, "funds": 0,
		"xp_earned": 0, "laws_passed": 0, "party_support": 0, "dues_overdue": false}


func _maxed() -> Dictionary:
	return {"district": 100, "national": 100, "constituency": 100, "org_share": 1.0, "funds": 5000000,
		"xp_earned": 99999, "laws_passed": 99, "party_support": 100, "dues_overdue": false}


func test_the_eight_maximums_add_to_one_hundred() -> void:
	var parts := ElectionStrength.components(_cfg, _maxed())
	assert_eq(parts.size(), 8)
	assert_eq(ElectionStrength.potential(parts), 100.0)


func test_nothing_in_scores_nothing() -> void:
	assert_eq(ElectionStrength.potential(ElectionStrength.components(_cfg, _zero())), 0.0)


func test_each_input_contributes_in_proportion() -> void:
	var inputs := _zero()
	inputs["district"] = 50
	inputs["funds"] = 250000
	var parts := ElectionStrength.components(_cfg, inputs)
	assert_eq(float(parts[0]["points"]), 7.5, "half of 15")
	assert_eq(float(parts[4]["points"]), 5.0, "half the war chest target")


func test_overdue_dues_halve_party_backing() -> void:
	var inputs := _zero()
	inputs["party_support"] = 80
	inputs["dues_overdue"] = true
	var parts := ElectionStrength.components(_cfg, inputs)
	assert_eq(float(parts[7]["points"]), 4.0)


func test_strength_climbs_at_most_the_weekly_gain() -> void:
	assert_eq(ElectionStrength.step(10.0, 90.0, _cfg), 12.5)
	assert_eq(ElectionStrength.step(10.0, 11.0, _cfg), 11.0, "never past the potential")


func test_strength_falls_at_most_the_weekly_fall() -> void:
	assert_eq(ElectionStrength.step(50.0, 10.0, _cfg), 48.5)
	assert_eq(ElectionStrength.step(50.0, 49.5, _cfg), 49.5)


func test_a_full_game_of_weeks_cannot_reach_the_top_early() -> void:
	var stock := 0.0
	for week in 20:
		stock = ElectionStrength.step(stock, 100.0, _cfg)
	assert_eq(stock, 50.0, "twenty weeks at the cap is only 50")


func test_a_week_end_in_the_game_moves_the_stock() -> void:
	GameState.election_strength = 0.0
	GameState._update_election_strength()
	assert_gt(GameState.election_strength, 0.0)
	assert_lte(GameState.election_strength, 2.5)


func test_earned_xp_is_counted_but_spending_it_is_not() -> void:
	var before := GameState.xp_earned_total
	GameState._move_xp(100)
	GameState._move_xp(-40)
	assert_eq(GameState.xp_earned_total, before + 100)
	GameState.xp -= 60


func test_election_strength_is_saved() -> void:
	GameState.election_strength = 12.5
	assert_eq(float(GameState.to_save()["election_strength"]), 12.5)
