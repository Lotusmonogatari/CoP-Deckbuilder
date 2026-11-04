extends GutTest
## Promises (2026-10-31): a choice's "Promise ..." commitment is owed later,
## kept from the Office (item handed over, or hours spent), or broken when it
## falls due unkept. Numbers come from the Balance tab.

const ITEM := {"kind": "promise_item", "item_id": "SH25", "within": 10, "for": "BO06"}
const HOURS := {"kind": "promise_hours", "amount": 2, "within": 10}


func before_each() -> void:
	GameState.start_new_run("PC01")
	GameState.calendar = WeekCalendar.fresh()
	GameState.booster_standing["BO06"] = 50
	GameState.inventory.erase("SH25")


func test_a_promise_is_made_not_paid() -> void:
	var funds := int(GameState.meta["Funds"])
	GameState.pay_commitments([ITEM], "A test", "")
	assert_eq(GameState.promises.size(), 1)
	assert_eq(str(GameState.promises[0]["for_org"]), "BO06")
	assert_eq(int(GameState.promises[0]["due_at"]), GameState.time_units + 10)
	assert_eq(int(GameState.meta["Funds"]), funds, "nothing is paid yet")
	assert_true(GameState.item_is_promised("SH25"))


func test_a_promise_without_an_organization_goes_to_the_choice_s_own() -> void:
	GameState.pay_commitments([HOURS], "A test", "BO12")
	assert_eq(str(GameState.promises[0]["for_org"]), "BO12")


func test_an_item_promise_is_kept_once_the_item_is_held() -> void:
	GameState.pay_commitments([ITEM], "A test", "")
	var id := str(GameState.promises[0]["id"])
	assert_ne(GameState.keep_promise(id), "", "not held yet")
	GameState.add_item("SH25")
	assert_eq(GameState.keep_promise(id), "")
	assert_eq(GameState.promises.size(), 0)
	assert_eq(GameState.item_count("SH25"), 0, "the item was handed over")
	assert_eq(int(GameState.booster_standing["BO06"]), 50 + int(DataDB.balance.get("promise_kept_standing", 1)))


func test_an_hours_promise_spends_the_hours_when_kept() -> void:
	GameState.pay_commitments([HOURS], "A test", "")
	var before := WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config())
	assert_eq(GameState.keep_promise(str(GameState.promises[0]["id"])), "")
	assert_eq(WeekCalendar.hours_left(GameState.calendar, GameState.calendar_config()), before - 2)


func test_a_promise_falling_due_unkept_is_broken() -> void:
	var reputation := int(GameState.meta.get("Reputation", 0))
	GameState.pay_commitments([ITEM], "A test", "")
	GameState.spend_hours(11)
	assert_eq(GameState.promises.size(), 0)
	assert_eq(GameState.promises_broken_unseen.size(), 1)
	assert_eq(int(GameState.booster_standing["BO06"]), 50 + int(DataDB.balance.get("promise_broken_standing", -3)))
	assert_lte(int(GameState.meta.get("Reputation", 0)), reputation)


## Cameron, 2026-11-04: deadlines pause while a level is played, since the
## Office (where promises are kept) cannot be reached mid-level. A promise made
## before an 11-hour level, due in 10, is still owed afterwards, due 10 hours
## after the level ends.
func test_a_level_pauses_a_promise_made_before_it() -> void:
	GameState.pay_commitments([ITEM], "A test", "")
	GameState.begin_level(LevelRunner.new({"level_id": "LV_PR", "stages": [
		{"seq": 1, "stage_id": "ST05", "mode": "Combat", "time_units": 11}]}))
	GameState.finish_stage(LevelRunner.WON, 0, [], false, 0)
	assert_eq(GameState.promises.size(), 1, "not broken during the level")
	GameState.end_level()
	assert_eq(GameState.promises.size(), 1, "not broken when it ends either")
	assert_eq(Promises.hours_left(GameState.promises[0], GameState.time_units), 10)
	GameState.spend_hours(11)
	assert_eq(GameState.promises.size(), 0, "the clock runs again in the Office")
	assert_eq(GameState.promises_broken_unseen.size(), 1)


## A promise made during a level (Office Hours) counts from the level's end.
func test_a_promise_made_during_a_level_counts_from_its_end() -> void:
	GameState.begin_level(LevelRunner.new({"level_id": "LV_PR", "stages": [
		{"seq": 1, "stage_id": "ST05", "mode": "Combat", "time_units": 6},
		{"seq": 2, "stage_id": "ST05", "mode": "Combat", "time_units": 20}]}))
	GameState.finish_stage(LevelRunner.WON, 0, [], false, 0)
	GameState.pay_commitments([ITEM], "A test", "")
	GameState.finish_stage(LevelRunner.WON, 0, [], false, 0)
	GameState.end_level()
	assert_eq(GameState.promises.size(), 1)
	assert_eq(Promises.hours_left(GameState.promises[0], GameState.time_units), 10)


## An abandoned level resumes the deadlines too, and the pause is saved.
func test_abandoning_resumes_deadlines_and_the_pause_is_saved() -> void:
	GameState.pay_commitments([ITEM], "A test", "")
	GameState.begin_level(LevelRunner.new({"level_id": "LV_PR", "stages": [
		{"seq": 1, "stage_id": "ST05", "mode": "Combat", "time_units": 4},
		{"seq": 2, "stage_id": "ST05", "mode": "Combat", "time_units": 4}]}))
	assert_true(GameState.to_save().has("level_clock_started"))
	GameState.finish_stage(LevelRunner.WON, 0, [], false, 0)
	GameState.abandon_level()
	assert_eq(GameState.level_clock_started, -1)
	assert_eq(Promises.hours_left(GameState.promises[0], GameState.time_units), 10)


func test_promises_are_saved_with_the_run() -> void:
	GameState.pay_commitments([ITEM], "A test", "")
	var saved := GameState.to_save()
	assert_true(saved.has("promises"))
	assert_eq((saved["promises"] as Array).size(), 1)


func test_the_hours_left_never_go_below_zero() -> void:
	assert_eq(Promises.hours_left({"due_at": 5}, 9), 0)
	assert_eq(Promises.hours_left({"due_at": 9}, 5), 4)


## Follow-ups (2026-10-31): a "Followup EVxx after H" commitment schedules the
## event for the first Office visit H game hours later.
func test_a_followup_waits_for_its_time_then_arrives_once() -> void:
	var followup := ""
	for event: Dictionary in DataDB.events:
		if str(event.get("trigger", "")) == "Followup":
			followup = str(event["event_id"])
			break
	assert_ne(followup, "", "the workbook has a Followup event")
	GameState.pay_commitments([{"kind": "followup", "event_id": followup, "after": 5}])
	assert_eq(GameState.take_due_followup(), "", "not yet")
	GameState.spend_hours(5)
	assert_eq(GameState.take_due_followup(), followup)
	assert_eq(GameState.take_due_followup(), "", "only once")


func test_followup_events_never_arrive_at_random_or_for_sale() -> void:
	var ctx := GameState.event_context()
	for event: Dictionary in EventEngine.eligible_random(DataDB.events, ctx):
		assert_ne(str(event.get("trigger", "")), "Followup")
	for event: Dictionary in GameState.buyable_events():
		assert_ne(str(event.get("trigger", "")), "Followup")


func test_a_promise_s_deadline_counts_from_after_the_choice_s_own_hours() -> void:
	# 2026-10-31: hours a choice costs on the spot pass before the promise is dated.
	var start := GameState.time_units
	GameState.pay_commitments([{"kind": "hours", "amount": 2}, ITEM], "A test", "")
	assert_eq(int(GameState.promises[0]["due_at"]), start + 2 + 10)


func test_a_free_backing_extends_a_running_timer_never_shortens_it() -> void:
	# 2026-10-31: a backing granted while already held on a timer keeps the later expiry.
	var mod_id := str(DataDB.modifiers[0]["mod_id"])
	GameState.owned_modifiers = [mod_id]
	GameState.modifier_expires = {mod_id: GameState.time_units + 5}
	GameState._grant_backing_for(mod_id, 20)
	assert_eq(int(GameState.modifier_expires[mod_id]), GameState.time_units + 20)
	GameState._grant_backing_for(mod_id, 3)
	assert_eq(int(GameState.modifier_expires[mod_id]), GameState.time_units + 20)


func test_a_promise_with_its_own_kept_effects_pays_them_instead_of_the_default() -> void:
	# Event Choices' Promise Kept / Broken (2026-10-31, EV65).
	GameState.booster_standing["BO28"] = 50
	GameState.booster_standing["BO15"] = 50
	var national := int(GameState.awareness.get("national", 0))
	var terms := {"kept": [{"target": "BO28", "delta": 1}, {"target": "BO15", "delta": 2}, {"target": "National", "delta": 1}],
		"broken": [{"target": "BO28", "delta": -5}], "kept_text": "Delivered."}
	GameState.pay_commitments([{"kind": "promise_item", "item_id": "SH25", "within": 10, "for": "BO15"}], "A test", "", terms)
	assert_eq(str(GameState.promises[0]["kept_text"]), "Delivered.")
	GameState.add_item("SH25")
	assert_eq(GameState.keep_promise(str(GameState.promises[0]["id"])), "")
	assert_eq(int(GameState.booster_standing["BO28"]), 51)
	assert_eq(int(GameState.booster_standing["BO15"]), 52, "its own +2, not the default as well")
	assert_eq(int(GameState.awareness.get("national", 0)), national + 1)


func test_a_promise_with_its_own_broken_effects_charges_only_those() -> void:
	GameState.booster_standing["BO28"] = 50
	var reputation := int(GameState.meta.get("Reputation", 0))
	GameState.pay_commitments([{"kind": "promise_item", "item_id": "SH25", "within": 10, "for": "BO06"}], "A test", "",
		{"broken": [{"target": "BO28", "delta": -5}, {"target": "Reputation", "delta": -1}]})
	GameState.spend_hours(11)
	assert_eq(int(GameState.booster_standing["BO28"]), 45)
	assert_eq(int(GameState.booster_standing["BO06"]), 50, "the default standing loss does not also apply")
	assert_eq(int(GameState.meta.get("Reputation", 0)), maxi(0, reputation - 1))
	assert_eq(GameState.promises_broken_unseen.size(), 1)


func test_ev65_s_promises_carry_their_own_terms() -> void:
	for row: Dictionary in DataDB.event_choices:
		if str(row.get("event_id")) == "EV65" and str(row.get("choice")) in ["A", "B"]:
			assert_true(Promises.has_own(Promises.terms_of(row), "kept"), "EV65 %s has its own kept effects" % row["choice"])
			assert_true(Promises.has_own(Promises.terms_of(row), "broken"))


func test_every_promise_in_the_workbook_says_what_keeping_it_looks_like() -> void:
	# Cameron, 2026-10-31: every promise has a Promise Kept Text.
	var missing: Array[String] = []
	for row: Dictionary in DataDB.event_choices:
		if _promises_something(row.get("commitment")) and str(row.get("promise_kept_text", "")).strip_edges() in ["", "<null>"]:
			missing.append("%s %s" % [row["event_id"], row["choice"]])
	for row: Dictionary in DataDB.visitor_questions:
		for c in ["a", "b", "c", "d"]:
			var text: Variant = row.get("promise_kept_text_" + c)
			if _promises_something(row.get("commitment_" + c)) and (text == null or str(text).is_empty()):
				missing.append("%s %s" % [row["question_id"], c])
	for row: Dictionary in DataDB.event_options:
		var text: Variant = row.get("promise_kept_text")
		if _promises_something(row.get("commitment")) and (text == null or str(text).is_empty()):
			missing.append(str(row["option_id"]))
	assert_eq(missing, [] as Array[String], "promises with no kept text")


func test_a_visitor_or_hosted_promise_keeps_its_kept_text() -> void:
	GameState.pay_commitments([HOURS], "A visitor", "BO12", {"kept_text": "You followed through."})
	assert_eq(str(GameState.promises[0]["kept_text"]), "You followed through.")


func _promises_something(list: Variant) -> bool:
	if not (list is Array):
		return false
	for entry: Variant in list:
		if Promises.is_promise(entry):
			return true
	return false
