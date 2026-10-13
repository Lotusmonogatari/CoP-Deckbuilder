extends GutTest
## The draw leans toward people the player has met least (Cameron,
## 2026-10-13): the same person can return, but unmet people come first.


func _pool(ids: Array) -> Array:
	var pool: Array = []
	for id in ids:
		pool.append({"opp_id": id})
	return pool


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _ids(people: Array) -> Array:
	var ids: Array = []
	for person: Dictionary in people:
		ids.append(str(person["opp_id"]))
	return ids


func test_the_least_met_people_come_first() -> void:
	var faced := {"A": 2, "B": 2, "D": 1}
	for seed_value in 50:
		var got := _ids(PeopleDraw.pick(_pool(["A", "B", "C", "D"]), "opp_id", faced, 2, [], _rng(seed_value)))
		got.sort()
		assert_eq(got, ["C", "D"], "the unmet and the once-met are drawn before the twice-met")


func test_ties_are_shuffled_so_it_is_not_always_the_same_person() -> void:
	var seen := {}
	for seed_value in 100:
		var got := PeopleDraw.pick(_pool(["A", "B", "C", "D"]), "opp_id", {}, 1, [], _rng(seed_value))
		seen[str((got[0] as Dictionary)["opp_id"])] = true
	assert_gt(seen.size(), 1)


func test_nobody_is_seated_twice_and_a_short_pool_is_used_whole() -> void:
	var got := _ids(PeopleDraw.pick(_pool(["A", "B"]), "opp_id", {}, 5, [], _rng(1)))
	got.sort()
	assert_eq(got, ["A", "B"])


func test_an_excluded_person_is_skipped() -> void:
	var got := _ids(PeopleDraw.pick(_pool(["A", "B", "C"]), "opp_id", {}, 3, ["B"], _rng(3)))
	got.sort()
	assert_eq(got, ["A", "C"])


func test_a_stage_draw_avoids_someone_already_met_when_others_are_available() -> void:
	var pool := BattleSetup.eligible_opponents("ST05")
	assert_gt(pool.size(), 3)
	var saved := GameState.faced_people.duplicate()
	GameState.faced_people = {}
	for opponent: Dictionary in pool:
		GameState.faced_people[str(opponent["opp_id"])] = 4
	var fresh := str((pool[0] as Dictionary)["opp_id"])
	GameState.faced_people[fresh] = 0
	for i in 40:
		var drawn := BattleSetup._opponents_for("LVNONE", "ST05", 1, 1)
		assert_eq(str((drawn[0] as Dictionary)["opp_id"]), fresh, "the one unmet person is drawn every time")
	GameState.faced_people = saved


func test_beginning_a_level_counts_everyone_seated() -> void:
	var saved := GameState.faced_people.duplicate()
	GameState.faced_people = {}
	var stage := {"opponents": [{"opp_id": "OPX1"}, {"opp_id": "OPX2"}], "visitors": [{"visitor_id": "VIX1"}]}
	GameState.record_faced(stage)
	GameState.record_faced(stage)
	assert_eq(int(GameState.faced_people["OPX1"]), 2)
	assert_eq(int(GameState.faced_people["VIX1"]), 2)
	GameState.faced_people = saved
