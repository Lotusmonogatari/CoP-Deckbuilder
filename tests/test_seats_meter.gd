extends GutTest
## Living Office seats (P9): the split always fills the semicircle, in order, and is true to the numbers.

func test_the_split_always_adds_up_to_the_seats() -> void:
	for player in [0, 1, 12, 30, 50, 100]:
		for opponent in [0, 7, 45, 100 - player]:
			var split := SeatsMeter.seat_split(100, player, opponent, 20)
			assert_eq(int(split["player"]) + int(split["undecided"]) + int(split["opponent"]), 20, "%d/%d" % [player, opponent])


func test_five_people_per_seat_in_a_hundred_person_room() -> void:
	var split := SeatsMeter.seat_split(100, 30, 45, 20)
	assert_eq(int(split["player"]), 6)
	assert_eq(int(split["opponent"]), 9)
	assert_eq(int(split["undecided"]), 5)


func test_a_101_seat_house_rounds_to_the_nearest_seat() -> void:
	var split := SeatsMeter.seat_split(101, 51, 0, 20)
	assert_eq(int(split["player"]), 10)


func test_rows_split_twelve_outer_and_eight_inner() -> void:
	var order := SeatsMeter.seat_positions(20, 60)
	assert_eq(order.size(), 20)
	var outer := 0
	for seat: Dictionary in order:
		if int(seat["ring"]) == 0:
			outer += 1
	assert_eq(outer, 12)


func test_seats_are_ordered_from_the_left() -> void:
	var order := SeatsMeter.seat_positions(20, 60)
	for i in range(1, order.size()):
		assert_gte(float((order[i - 1] as Dictionary)["angle"]), float((order[i] as Dictionary)["angle"]))
