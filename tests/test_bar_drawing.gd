extends GutTest
## Which battles draw their Living Office bar as seats and which as a continuous arc (2026-11-18).


func test_a_percentage_stage_is_read_as_a_share() -> void:
	assert_true(BarModel.stage_is_percent({"bar_value_kind": "Percentage"}))
	assert_false(BarModel.stage_is_percent({"bar_value_kind": "Numerical"}))
	assert_false(BarModel.stage_is_percent({}))


func test_only_a_counted_room_draws_seats() -> void:
	assert_true(BarModel.draws_as_seats(BarModel.Model.SHARED_POOL, false))
	assert_false(BarModel.draws_as_seats(BarModel.Model.SHARED_POOL, true), "a share is an arc")
	assert_false(BarModel.draws_as_seats(BarModel.Model.SURVIVAL, false), "viewer interest is an arc")
	assert_false(BarModel.draws_as_seats(BarModel.Model.SINGLE, false), "a single score is an arc")


## In the data, exactly the five battles measured in people (Floor Debate, four special committees) get seats.
func test_the_seat_battles_are_the_people_battles() -> void:
	var seat_units := {}
	for stage: Dictionary in DataDB.stages:
		if str(stage.get("mode", "")) != "Combat":
			continue
		if BarModel.draws_as_seats(BarModel.for_stage(stage), BarModel.stage_is_percent(stage)):
			seat_units[str(stage.get("bar_unit", ""))] = int(seat_units.get(str(stage.get("bar_unit", "")), 0)) + 1
	assert_eq(seat_units, {"Seats": 1, "Members": 4})
