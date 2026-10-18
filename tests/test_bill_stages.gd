extends GutTest
## Every bill level is built from bill-specific stages (2026-10-18), and every
## stage has a background to show.

## A level's stage in a slot (1-10), "" for an empty slot (JSON null).
func _slot(level: Dictionary, slot: int) -> String:
	var value: Variant = level.get("stage_%d" % slot)
	return "" if value == null else str(value)


func _bill_levels() -> Array:
	var out: Array = []
	for level: Dictionary in DataDB.levels:
		for slot in 10:
			if _slot(level, slot + 1).begins_with("BI"):
				out.append(level)
				break
	return out


func test_no_bill_level_uses_a_generic_stage() -> void:
	for level: Dictionary in _bill_levels():
		for slot in 10:
			var stage_id := _slot(level, slot + 1)
			if stage_id.is_empty() or stage_id.begins_with("BI"):
				continue
			assert_gt(int(stage_id.substr(2)), 23,
				"%s slot %d uses the generic %s" % [level["level_id"], slot + 1, stage_id])


func test_every_stage_resolves_to_a_background_picture() -> void:
	for stage: Dictionary in DataDB.stages:
		var stage_id := str(stage["stage_id"])
		assert_ne(ArtLoader.background_path(stage_id), "", "%s has no background to show" % stage_id)


func test_a_topic_stage_borrows_its_family_background() -> void:
	assert_eq(DataDB.stage_background_id("ST33"), "ST10", "a Hearing borrows its committee's picture")
	assert_eq(DataDB.stage_background_id("ST32"), "ST04")
	assert_eq(DataDB.stage_background_id("ST101"), "ST07")
	assert_eq(DataDB.stage_background_id("ST05"), "", "a generic stage uses its own")
	assert_eq(ArtLoader.background_path("ST32"), ArtLoader.background_path("ST04"))


func test_every_combat_stage_in_a_bill_level_seats_people() -> void:
	for level: Dictionary in _bill_levels():
		for slot in 10:
			var stage_id := _slot(level, slot + 1)
			if stage_id.is_empty() or stage_id.begins_with("BI"):
				continue
			var stage := DataDB.get_stage(stage_id)
			if str(stage.get("mode", "")) == "Combat":
				assert_gt(BattleSetup.eligible_opponents(stage_id).size(), 0, "%s seats nobody" % stage_id)


func test_a_bill_specific_copy_plays_like_its_family() -> void:
	for stage: Dictionary in DataDB.stages:
		var stage_id := str(stage["stage_id"])
		var base := DataDB.stage_background_id(stage_id)
		if int(stage_id.substr(2)) < 121 or base.is_empty() or int(base.substr(2)) > 23:
			continue
		var generic := DataDB.get_stage(base)
		assert_eq(stage["mode"], generic["mode"], stage_id)
		assert_eq(stage.get("sequence_mode"), generic.get("sequence_mode"), stage_id)
		assert_eq(stage.get("opponent_count"), generic.get("opponent_count"), stage_id)


func test_every_visitor_pinned_to_a_level_exists_and_is_eligible_for_that_slot() -> void:
	var ids := {}
	for visitor: Dictionary in DataDB.visitors:
		ids[str(visitor["visitor_id"])] = visitor
	for pin: Dictionary in DataDB.level_visitor_overrides:
		var visitor: Dictionary = ids.get(str(pin["visitor_id"]), {})
		assert_false(visitor.is_empty(), "%s exists" % pin["visitor_id"])
		var stage_id := _slot(DataDB.get_level(str(pin["level_id"])), int(pin["slot"]))
		assert_true((visitor.get("stages", []) as Array).has(stage_id),
			"%s is written for %s in %s" % [pin["visitor_id"], stage_id, pin["level_id"]])
