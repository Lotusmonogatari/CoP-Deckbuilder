extends GutTest
## A visitor row whose Stage cell is blank exports a null "stages". It used to
## crash every visitor lookup ("Invalid cast: could not convert value to
## 'Array'"); now it simply never appears (2026-11-13, found when Cameron's
## new visitor VI167 arrived with no stages).

func test_a_visitor_with_blank_stages_is_never_offered_and_crashes_nothing() -> void:
	var blank := {"visitor_id": "VI_TEST_BLANK", "name_en": "Test Visitor", "stages": null, "reward": null, "penalty": null}
	DataDB.visitors.append(blank)
	var pool := DataDB.get_visitors_for_stage("ST07")
	DataDB.visitors.erase(blank)
	for visitor: Dictionary in pool:
		assert_ne(str(visitor.get("visitor_id", "")), "VI_TEST_BLANK")
	assert_gt(pool.size(), 0, "the ordinary visitors are still found")


func test_the_real_visitor_with_no_stage_is_in_the_data_and_harmless() -> void:
	var visitor := DataDB.get_visitor("VI167")
	assert_false(visitor.is_empty(), "Cameron's new volcanologist is loaded")
	for stage_id: String in ["ST07", "ST101", "ST264"]:
		for found: Dictionary in DataDB.get_visitors_for_stage(stage_id):
			assert_ne(str(found.get("visitor_id", "")), "VI167")
