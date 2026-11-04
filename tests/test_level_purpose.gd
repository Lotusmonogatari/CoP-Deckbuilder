extends GutTest
## LevelPurpose (2026-11-04, Cameron): what a level is for, and who says it.

const STAFF := [
	{"staff_id": "SF01", "role": "District Representative", "name": "Ana"},
	{"staff_id": "SF04", "role": "Policy Research Assistant", "name": "Ben"},
	{"staff_id": "SF11", "role": "Media Spokesperson", "name": "Cho"},
]


func test_the_named_role_speaks_when_hired() -> void:
	var level := {"purpose": "A vote is coming.", "purpose_speaker": "Policy Research Assistant"}
	var hired := {"District Representative": {"staff_id": "SF01"}, "Policy Research Assistant": {"staff_id": "SF04"}}
	var got := LevelPurpose.resolve(level, hired, STAFF)
	assert_eq(got["staff_id"], "SF04")
	assert_eq(got["staff_name"], "Ben")
	assert_eq(got["text"], "A vote is coming.")


func test_the_first_hired_staff_member_stands_in_when_the_role_is_empty() -> void:
	var level := {"purpose": "x", "purpose_speaker": "Media Spokesperson"}
	var got := LevelPurpose.resolve(level, {"Policy Research Assistant": {"staff_id": "SF04"}}, STAFF)
	assert_eq(got["staff_id"], "SF04", "staff.json order, first hired")


func test_with_no_staff_the_player_says_it() -> void:
	var got := LevelPurpose.resolve({"purpose": "x", "purpose_speaker": "Media Spokesperson"}, {}, STAFF)
	assert_eq(got["staff_id"], "")
	assert_eq(got["text"], "x")


func test_a_level_without_a_purpose_has_nothing_to_say() -> void:
	assert_eq(LevelPurpose.resolve({"purpose": null}, {}, STAFF), {})
	assert_eq(LevelPurpose.text_for({}), "")


func test_every_workbook_level_has_a_purpose() -> void:
	for level: Dictionary in DataDB.levels:
		assert_false(LevelPurpose.text_for(level).is_empty(), "%s has no Level Purpose" % level.get("level_id"))
