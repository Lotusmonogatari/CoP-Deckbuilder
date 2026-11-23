extends GutTest
## Rhetoric tips (P16): targets come from data, the held list caps and refreshes, and tips expire.

const STAGES := {"ST01": {"favored_suit": "Earnest"}, "ST02": {"favored_suit": null}, "ST03": {"favored_suit": "Appeal"}, "ST04": {"favored_suit": "—"}}


func _tip(target: String, day: int, kind: String = "stage_suit") -> Dictionary:
	return {"kind": kind, "target": target, "suit": "Earnest", "where": "cafeteria", "day": day}


func test_a_stage_with_no_favored_suit_is_never_a_target() -> void:
	var found := RhetoricTips.targets(["ST01", "ST02", "ST03", "ST04", "ST99"], STAGES, {}, [])
	var ids: Array = []
	for target: Dictionary in found["stage_suit"]:
		ids.append(target["id"])
	assert_eq(ids, ["ST01", "ST03"], "blank, a dash and an unknown stage are left out")
	assert_eq(found["stage_suit"][0]["suit"], "Earnest")


func test_opponents_come_from_the_rooms_on_offer_and_the_next_scene_by_their_lead_suit() -> void:
	var by_stage := {"ST01": [{"opp_id": "OP01", "suit_1": "Appeal"}, {"opp_id": "OP02", "suit_1": null}], "ST03": [{"opp_id": "OP01", "suit_1": "Appeal"}]}
	var found := RhetoricTips.targets(["ST01", "ST03"], STAGES, by_stage, [{"opp_id": "OP10", "suit_1": "Earnest"}])
	var ids: Array = []
	for target: Dictionary in found["opponent_suit"]:
		ids.append(target["id"])
	assert_eq(ids, ["OP01", "OP10"], "no repeats; a person with no lead suit is left out")


func test_a_tip_is_built_from_the_dealt_hint() -> void:
	var tip := RhetoricTips.make({"kind": "stage_suit", "target": "ST01", "suit": "Earnest"}, "gardens", 5)
	assert_eq(tip, {"kind": "stage_suit", "target": "ST01", "suit": "Earnest", "where": "gardens", "day": 5})


func test_a_new_tip_replaces_the_oldest_when_ten_are_held() -> void:
	var held: Array = []
	for i in 10:
		held = RhetoricTips.add(held, _tip("ST%02d" % i, 100 + i), 10)
	assert_eq(held.size(), 10)
	held = RhetoricTips.add(held, _tip("ST50", 120), 10)
	assert_eq(held.size(), 10, "still ten")
	assert_true(RhetoricTips.about(held, "stage_suit", "ST00").is_empty(), "the oldest (day 100) is gone")
	assert_false(RhetoricTips.about(held, "stage_suit", "ST50").is_empty())
	assert_false(RhetoricTips.about(held, "stage_suit", "ST01").is_empty(), "the others stay")


func test_a_tip_about_a_target_already_held_refreshes_its_days_instead() -> void:
	var held := RhetoricTips.add([], _tip("ST01", 100), 10)
	held = RhetoricTips.add(held, _tip("ST02", 101), 10)
	held = RhetoricTips.add(held, _tip("ST01", 110), 10)
	assert_eq(held.size(), 2, "no second copy")
	assert_eq(int(RhetoricTips.about(held, "stage_suit", "ST01")["day"]), 110)
	# A stage and an opponent that share an ID prefix are different targets.
	held = RhetoricTips.add(held, _tip("OP01", 111, "opponent_suit"), 10)
	assert_eq(held.size(), 3)


func test_add_never_changes_the_list_it_was_given() -> void:
	var held := [_tip("ST01", 100)]
	RhetoricTips.add(held, _tip("ST02", 101), 10)
	assert_eq(held.size(), 1)


func test_a_tip_lasts_fourteen_days_and_is_gone_on_the_fifteenth() -> void:
	var tip := _tip("ST01", 100)
	assert_eq(RhetoricTips.days_left(tip, 100, 14), 14, "the day it was heard")
	assert_eq(RhetoricTips.days_left(tip, 113, 14), 1, "the last day")
	assert_eq(RhetoricTips.days_left(tip, 114, 14), 0, "day 15 it has expired")
	assert_eq(RhetoricTips.unexpired([tip], 113, 14).size(), 1)
	assert_eq(RhetoricTips.unexpired([tip], 114, 14).size(), 0)
