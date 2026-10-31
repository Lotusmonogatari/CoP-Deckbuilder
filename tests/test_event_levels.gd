extends GutTest
## Events that start a level (2026-10-31, Cameron): an Event Choices row's
## Starts Level names an Event Only level; the choice's duration adds that
## level's hours; a choice that would not fit the hours left is refused with
## "Insufficient Work Hours". Read from the workbook data, never typed here.

var _event: Dictionary
var _choice: Dictionary


func before_each() -> void:
	GameState.start_new_run("PC01")
	GameState.calendar = WeekCalendar.fresh()
	_event = {}
	_choice = {}
	for choice: Dictionary in DataDB.event_choices:
		if not GameState.event_choice_level(choice).is_empty():
			_choice = choice
			_event = GameState.get_event(str(choice["event_id"]))
			return


func test_the_workbook_has_a_choice_that_starts_a_level() -> void:
	assert_false(_choice.is_empty(), "some Event Choices row has a Starts Level")


func test_every_started_level_is_event_only_and_off_the_list() -> void:
	for choice: Dictionary in DataDB.event_choices:
		var level_id := GameState.event_choice_level(choice)
		if level_id.is_empty():
			continue
		assert_true(GameState.is_event_only(DataDB.get_level(level_id)), level_id)


func test_a_level_choice_takes_the_event_hours_plus_the_level_hours() -> void:
	var level := DataDB.get_level(GameState.event_choice_level(_choice))
	assert_eq(GameState.event_choice_hours(_event, _choice),
		EventEngine.hours_of(_event) + GameState.level_hours(level))


func test_the_duration_runs_from_the_quickest_choice_to_the_longest() -> void:
	var span := GameState.event_hours_range(_event)
	assert_eq(span[0], EventEngine.hours_of(_event), "a choice with no level takes the event's own hours")
	assert_eq(span[1], GameState.event_choice_hours(_event, _choice))
	assert_true(GameState.event_hours_text(_event).contains(str(span[1])))


func test_a_level_choice_that_does_not_fit_is_refused() -> void:
	assert_eq(GameState.event_choice_refusal(_event, _choice), "", "a fresh week has room")
	var cfg := GameState.calendar_config()
	var need := GameState.event_choice_hours(_event, _choice)
	GameState.calendar = {"week": 0, "phase": "work", "hours": WeekCalendar.pool_hours("work", cfg) - need + 1}
	assert_eq(GameState.event_choice_refusal(_event, _choice), Text.say("event.refuse_work_hours"))


func test_a_choice_without_a_level_is_never_refused_for_hours() -> void:
	for choice: Dictionary in EventEngine.choices_for(DataDB.event_choices, str(_event["event_id"])):
		if GameState.event_choice_level(choice).is_empty():
			GameState.calendar = {"week": 0, "phase": "work", "hours": 39}
			assert_eq(GameState.event_choice_refusal(_event, choice), "")


func test_taking_the_choice_reports_its_level() -> void:
	var result := GameState.apply_event_choice(str(_event["event_id"]), str(_choice["choice"]))
	assert_true(result["ok"])
	assert_eq(result["starts_level"], GameState.event_choice_level(_choice))
