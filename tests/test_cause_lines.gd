extends GutTest
## The wording of "because of ..." and how reasons are recorded per
## organization (2026-10-18).

func test_join_reads_as_a_sentence() -> void:
	assert_eq(CauseLines.join([]), "")
	assert_eq(CauseLines.join(["a"]), "a")
	assert_eq(CauseLines.join(["a", "b"]), "a and b")
	assert_eq(CauseLines.join(["a", "b", "c"]), "a, b, and c")


func test_one_reason_has_no_amount_and_several_each_carry_theirs() -> void:
	assert_eq(CauseLines.because([{"cause": "winning Town Hall", "amount": 3}]),
		"because of winning Town Hall")
	assert_eq(CauseLines.because([{"cause": "winning Town Hall", "amount": 3},
		{"cause": "your answers", "amount": -1}]),
		"because of winning Town Hall (+3) and your answers (-1)")
	assert_eq(CauseLines.because([{"cause": "a", "amount": 1}, {"cause": "b", "amount": 2},
		{"cause": "c", "amount": -3}]), "because of a (+1), b (+2), and c (-3)")
	assert_eq(CauseLines.because([]), "")


func test_an_organization_change_is_filed_under_its_cause_and_sums() -> void:
	GameState.start_new_run("PC01")
	GameState.booster_standing["BO03"] = 50
	GameState.last_booster_change = {}
	GameState.last_booster_cause = {}
	GameState._cause = "one"
	GameState._apply_booster_delta("BO03", 2)
	GameState._apply_booster_delta("BO03", 1)
	GameState._cause = "two"
	GameState._apply_booster_delta("BO03", -1)
	GameState._cause = ""
	assert_eq(GameState.last_booster_cause["BO03"], [
		{"cause": "one", "amount": 3}, {"cause": "two", "amount": -1}])
	assert_eq(int(GameState.last_booster_change["BO03"]), 2)


func test_a_change_with_no_named_cause_still_says_something() -> void:
	GameState.start_new_run("PC01")
	GameState.last_booster_cause = {}
	GameState._apply_booster_delta("BO03", 1)
	assert_eq(GameState.last_booster_cause["BO03"][0]["cause"], Text.say("record.cause_other"))


func test_a_stance_vote_files_its_reason_for_each_organization() -> void:
	GameState.start_new_run("PC04")
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV31"))))
	GameState.set_bill_lean("BI01", "Oppose")
	GameState.last_booster_cause = {}
	GameState.apply_stance_vote("Yes")
	var entry: Dictionary = GameState.last_booster_cause["BO28"][0]
	assert_string_contains(entry["cause"], "switching your stance")
	assert_string_contains(entry["cause"], "Ainu Heritage")
	GameState.abandon_level()
