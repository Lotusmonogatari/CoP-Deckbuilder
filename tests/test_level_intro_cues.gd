extends GutTest
## LevelIntroCues.gd: which data/level_intros.json rows apply to a given
## level right now. Uses fake rows throughout, the same way
## test_office_notices.gd proves its own logic against fabricated data
## rather than the real (and changeable) workbook content.

const STAFF_DIRECTORY := [
	{"staff_id": "SF01", "name": "Hana Takahashi", "role": "Policy Research Assistant"},
	{"staff_id": "SF08", "name": "Yui Kobayashi", "role": "Media Spokesperson"},
	{"staff_id": "SF15", "name": "Sheen Donalds", "role": "District Representative"},
]


func test_a_hired_role_with_a_written_line_for_this_level_speaks() -> void:
	var cues := [
		{"level_id": "LV31", "role": "Policy Research Assistant", "cue_text": "Every seat counts today."},
	]
	var staff_hired := {"Policy Research Assistant": {"staff_id": "SF01"}}
	var result := LevelIntroCues.resolve(cues, "LV31", staff_hired, STAFF_DIRECTORY)
	assert_eq(result, [{
		"role": "Policy Research Assistant",
		"staff_id": "SF01",
		"staff_name": "Hana Takahashi",
		"text": "Every seat counts today.",
	}])


func test_a_role_with_no_hire_stays_silent_even_with_a_written_line() -> void:
	var cues := [
		{"level_id": "LV31", "role": "Policy Research Assistant", "cue_text": "Every seat counts today."},
	]
	var result := LevelIntroCues.resolve(cues, "LV31", {}, STAFF_DIRECTORY)
	assert_eq(result, [])


func test_a_hired_role_with_no_written_line_for_this_level_stays_silent() -> void:
	var cues := [
		{"level_id": "LV31", "role": "Policy Research Assistant", "cue_text": "Every seat counts today."},
	]
	var staff_hired := {"Media Spokesperson": {"staff_id": "SF08"}}
	var result := LevelIntroCues.resolve(cues, "LV31", staff_hired, STAFF_DIRECTORY)
	assert_eq(result, [])


func test_a_row_for_a_different_level_never_leaks_in() -> void:
	var cues := [
		{"level_id": "LV32", "role": "Policy Research Assistant", "cue_text": "A different level's line."},
	]
	var staff_hired := {"Policy Research Assistant": {"staff_id": "SF01"}}
	var result := LevelIntroCues.resolve(cues, "LV31", staff_hired, STAFF_DIRECTORY)
	assert_eq(result, [])


func test_multiple_qualifying_roles_all_speak_in_staff_directory_order() -> void:
	var cues := [
		{"level_id": "LV31", "role": "District Representative", "cue_text": "Your district is watching."},
		{"level_id": "LV31", "role": "Policy Research Assistant", "cue_text": "Every seat counts today."},
	]
	var staff_hired := {
		"Policy Research Assistant": {"staff_id": "SF01"},
		"District Representative": {"staff_id": "SF15"},
	}
	var result := LevelIntroCues.resolve(cues, "LV31", staff_hired, STAFF_DIRECTORY)
	assert_eq(result.size(), 2)
	# STAFF_DIRECTORY lists Policy Research Assistant before District
	# Representative, regardless of the order the cue rows themselves came in.
	assert_eq(result[0]["role"], "Policy Research Assistant")
	assert_eq(result[1]["role"], "District Representative")


func test_nothing_qualifying_is_an_empty_list_not_a_blank_entry() -> void:
	var result := LevelIntroCues.resolve([], "LV31", {}, STAFF_DIRECTORY)
	assert_eq(result, [])


# ---------------------------------------------------------------------------
# player_thought() — the player's own internal thought about a level
# (2026-10-01), shown on a bill level after the staff finish speaking.
# ---------------------------------------------------------------------------

func test_a_levels_own_written_thought_is_returned() -> void:
	var thoughts := [{"level_id": "LV31", "thought_text": "This bill matters to my own district."}]
	assert_eq(LevelIntroCues.player_thought(thoughts, "LV31"), "This bill matters to my own district.")


func test_a_different_levels_thought_never_leaks_in() -> void:
	var thoughts := [{"level_id": "LV32", "thought_text": "Not this level's thought."}]
	assert_eq(LevelIntroCues.player_thought(thoughts, "LV31"), "")


func test_no_written_thought_is_an_empty_string() -> void:
	assert_eq(LevelIntroCues.player_thought([], "LV31"), "")
