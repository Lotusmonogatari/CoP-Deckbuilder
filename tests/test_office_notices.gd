extends GutTest
## OfficeNotices.gd: which data/office_notices.json rows are true right now,
## one at most per slot. Uses fake rows throughout, the same way
## test_opponent_cues.gd proves its own logic against fabricated data
## rather than the real (and changeable) workbook content.

const STAFF_DIRECTORY := [
	{"staff_id": "SF02", "name": "Yui Kobayashi"},
]


func test_a_staff_role_hired_condition_is_met_when_the_role_is_filled() -> void:
	var notices := [
		{"notice_id": "ON01", "slot": "greeting", "condition_type": "staff_role",
			"condition_target": "District Representative", "condition_op": "hired",
			"text_en": "{staff} is greeting visitors."},
	]
	var staff_hired := {"District Representative": {"staff_id": "SF02"}}
	var lines := OfficeNotices.resolve(notices, staff_hired, {}, STAFF_DIRECTORY)
	assert_eq(lines, ["Yui Kobayashi is greeting visitors."])


func test_a_staff_role_not_hired_condition_is_met_when_the_role_is_vacant() -> void:
	var notices := [
		{"notice_id": "ON02", "slot": "greeting", "condition_type": "staff_role",
			"condition_target": "District Representative", "condition_op": "not_hired",
			"text_en": "No one is at the front desk."},
	]
	var lines := OfficeNotices.resolve(notices, {}, {}, STAFF_DIRECTORY)
	assert_eq(lines, ["No one is at the front desk."])


func test_a_meta_threshold_condition_reads_the_current_value() -> void:
	var notices := [
		{"notice_id": "ON03", "slot": "press", "condition_type": "meta",
			"condition_target": "Reputation", "condition_op": "<", "condition_value": 30,
			"text_en": "Yezo News has not covered your work recently."},
	]
	var lines := OfficeNotices.resolve(notices, {}, {"Reputation": 10}, [])
	assert_eq(lines, ["Yezo News has not covered your work recently."])

	lines = OfficeNotices.resolve(notices, {}, {"Reputation": 50}, [])
	assert_eq(lines, [], "the threshold is not crossed at Reputation 50")


func test_only_one_line_shows_per_slot_the_first_that_qualifies() -> void:
	var notices := [
		{"notice_id": "ON03", "slot": "press", "condition_type": "meta",
			"condition_target": "Reputation", "condition_op": "<", "condition_value": 30,
			"text_en": "low reputation line"},
		{"notice_id": "ON04", "slot": "press", "condition_type": "meta",
			"condition_target": "Reputation", "condition_op": ">=", "condition_value": 30,
			"text_en": "high reputation line"},
	]
	# Reputation 50 only satisfies ON04, but both are in the "press" slot —
	# proves the slot rule doesn't accidentally show a line from the FIRST
	# row in the slot regardless of whether its own condition held.
	var lines := OfficeNotices.resolve(notices, {}, {"Reputation": 50}, [])
	assert_eq(lines, ["high reputation line"])


func test_different_slots_can_both_show_at_once() -> void:
	var notices := [
		{"notice_id": "ON01", "slot": "greeting", "condition_type": "staff_role",
			"condition_target": "District Representative", "condition_op": "hired",
			"text_en": "{staff} is greeting visitors."},
		{"notice_id": "ON03", "slot": "press", "condition_type": "meta",
			"condition_target": "Reputation", "condition_op": "<", "condition_value": 30,
			"text_en": "low reputation line"},
	]
	var staff_hired := {"District Representative": {"staff_id": "SF02"}}
	var lines := OfficeNotices.resolve(notices, staff_hired, {"Reputation": 10}, STAFF_DIRECTORY)
	assert_eq(lines.size(), 2)


func test_nothing_qualifying_is_an_empty_list_not_a_blank_line() -> void:
	var notices := [
		{"notice_id": "ON02", "slot": "greeting", "condition_type": "staff_role",
			"condition_target": "District Representative", "condition_op": "not_hired",
			"text_en": "No one is at the front desk."},
	]
	var staff_hired := {"District Representative": {"staff_id": "SF02"}}
	var lines := OfficeNotices.resolve(notices, staff_hired, {}, STAFF_DIRECTORY)
	assert_eq(lines, [])
