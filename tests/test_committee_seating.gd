extends GutTest
## Who may sit where (Cameron, 2026-10-13), checked against the real workbook.
## A "Committee on ..." seats its own members; the Special Committee seats MPs
## who are not ministers; the Cabinet committee seats ministers and chairs.


func _title(opponent: Dictionary) -> String:
	var raw: Variant = opponent.get("title")
	return "" if raw == null else str(raw)


func test_a_named_committee_seats_only_its_own_members() -> void:
	for stage: Dictionary in DataDB.stages:
		var name := str(stage.get("name_en", ""))
		if not name.begins_with("Committee on"):
			continue
		for opponent: Dictionary in BattleSetup.eligible_opponents(str(stage["stage_id"])):
			assert_eq(str(opponent.get("role", "")), name, "%s seats %s" % [stage["stage_id"], opponent.get("name")])


func test_the_special_committee_seats_mps_who_are_not_ministers() -> void:
	var pool := BattleSetup.eligible_opponents("ST01")
	assert_gt(pool.size(), 50, "any non-minister MP can sit on it")
	for opponent: Dictionary in pool:
		assert_eq(str(opponent.get("affiliation", "")), "BO17", "an MP")
		assert_false(_title(opponent).contains("Minister"), "%s is a minister" % opponent.get("name"))


func test_the_cabinet_committee_seats_only_ministers_and_chairs() -> void:
	var pool := BattleSetup.eligible_opponents("ST18")
	assert_gt(pool.size(), 1)
	for opponent: Dictionary in pool:
		var title := _title(opponent)
		assert_true(title.contains("Minister") or title.contains("Chair of"), "%s is neither" % opponent.get("name"))
