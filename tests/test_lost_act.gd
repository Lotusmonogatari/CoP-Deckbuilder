extends GutTest
## A lost or abandoned Act (2026-11-12, Cameron): the cue that says why the
## player was taken off it, and the limited "absent" entry in Legislative Work.

var _saved_run: Dictionary = {}


func before_each() -> void:
	_saved_run = GameState.to_save()
	GameState.start_new_run("PC02")


func after_each() -> void:
	GameState.end_level()
	GameState.load_save(_saved_run)
	GameState.mid_stage = false


func _begin_act(level_id: String) -> void:
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level(level_id))))


## Loses stage after stage until one whose loss ends the level does (the first
## stages of an Act are often ones the player can lose and carry on from).
func _lose_until_the_level_ends() -> void:
	for _i in 12:
		if GameState.finish_stage(LevelRunner.LOST):
			return
	fail_test("the level never ended")


# --- which cue --------------------------------------------------------------

func test_a_gaffe_loss_in_an_act_is_the_tongue_tied_cue() -> void:
	assert_eq(BillLossCue.kind(true, true, true, false, true), BillLossCue.TONGUE)


func test_any_other_loss_in_an_act_is_the_party_cue() -> void:
	assert_eq(BillLossCue.kind(true, true, true, false, false), BillLossCue.PARTY)


func test_there_is_no_cue_outside_an_act_after_a_win_after_abandoning_or_when_the_loss_does_not_end_the_level() -> void:
	assert_eq(BillLossCue.kind(false, true, true, false, true), BillLossCue.NONE, "not an Act")
	assert_eq(BillLossCue.kind(true, false, true, false, false), BillLossCue.NONE, "a win")
	assert_eq(BillLossCue.kind(true, true, true, true, false), BillLossCue.NONE, "abandoned")
	assert_eq(BillLossCue.kind(true, true, false, false, false), BillLossCue.NONE, "the level goes on")


# --- the absent entry -------------------------------------------------------

func test_a_lost_act_enters_the_statute_book_as_a_limited_absent_entry() -> void:
	_begin_act("LV31")
	var bill_id := str(GameState.level_bill().get("bill_id", ""))
	assert_false(bill_id.is_empty(), "LV31 is an Act")
	_lose_until_the_level_ends()
	assert_true(StatuteBook.has_bill(GameState.statute_book, bill_id))
	assert_true(StatuteBook.is_absent(GameState.statute_book, bill_id))
	var law: Dictionary = GameState.statute_book[GameState.statute_book.size() - 1]
	assert_eq(str(law["player_vote"]), "Absent")


func test_an_abandoned_act_gets_the_same_entry() -> void:
	_begin_act("LV32")
	var bill_id := str(GameState.level_bill().get("bill_id", ""))
	GameState.level_runner.abandoned = true
	_lose_until_the_level_ends()
	assert_true(StatuteBook.is_absent(GameState.statute_book, bill_id))


func test_a_won_act_is_not_recorded_as_absent() -> void:
	_begin_act("LV33")
	var bill_id := str(GameState.level_bill().get("bill_id", ""))
	GameState.finish_stage(LevelRunner.WON)
	assert_false(StatuteBook.is_absent(GameState.statute_book, bill_id))


func test_a_real_vote_replaces_an_absent_entry_but_not_a_real_one() -> void:
	_begin_act("LV34")
	var source := GameState.level_bill()
	var bill_id := str(source.get("bill_id", ""))
	_lose_until_the_level_ends()
	assert_true(StatuteBook.is_absent(GameState.statute_book, bill_id))
	var bill := BattleSetup.enriched_floor_vote(source)
	var result := {"totals": {"Yes": 60, "No": 30, "Abstain": 11}, "passed": true}
	GameState.record_floor_vote(bill, result, "Yes")
	assert_false(StatuteBook.is_absent(GameState.statute_book, bill_id), "the real vote took its place")
	var count := GameState.statute_book.size()
	GameState.record_floor_vote(bill, result, "No")
	assert_eq(GameState.statute_book.size(), count, "a real entry stays final")


func test_the_record_row_wording_for_an_absent_entry() -> void:
	var office: Node = load("res://scripts/ui/OfficeScreen.gd").new()
	assert_eq(office._law_row_key({"passed": true, "absent": true}), "office.record_law_absent_passed")
	assert_eq(office._law_row_key({"passed": false, "absent": true}), "office.record_law_absent_failed")
	assert_eq(office._law_row_key({"passed": true}), "office.record_law_passed")
	office.free()


func test_the_levels_replay_timer_is_7488_hours() -> void:
	for level: Dictionary in DataDB.levels:
		for slot in range(1, 11):
			var raw: Variant = level.get("stage_%d" % slot)
			if raw != null and str(raw).begins_with("BI"):
				assert_eq(int(level["cooldown"]), 7488, str(level["level_id"]))
				assert_eq(str(level["one_time"]), "No", str(level["level_id"]))
				break


# --- who comes back (Cameron, 2026-11-13) -----------------------------------

func _vote_on_the_act(level_id: String, choice: String) -> Dictionary:
	_begin_act(level_id)
	var level := DataDB.get_level(level_id)
	var source := GameState.level_bill()
	var bill := BattleSetup.enriched_floor_vote(source)
	var result := {"totals": {"Yes": 55, "No": 36, "Abstain": 10}, "passed": true}
	GameState.record_floor_vote(bill, result, choice)
	return level


func test_an_act_the_player_voted_aye_or_nay_on_never_comes_back() -> void:
	for choice in ["Yes", "No"]:
		GameState.statute_book = []
		var level := _vote_on_the_act("LV35", choice)
		assert_true(GameState.act_is_settled(level), choice)


func test_an_act_the_player_abstained_on_comes_back() -> void:
	var level := _vote_on_the_act("LV35", "Abstain")
	assert_false(GameState.act_is_settled(level))
	assert_true(StatuteBook.is_replaceable(GameState.statute_book, str(GameState.level_bill()["bill_id"])))


func test_an_act_the_player_was_absent_for_comes_back() -> void:
	_begin_act("LV36")
	var level := DataDB.get_level("LV36")
	_lose_until_the_level_ends()
	assert_false(GameState.act_is_settled(level))


func test_a_later_real_vote_replaces_an_abstained_entry_but_an_aye_is_final() -> void:
	var level := _vote_on_the_act("LV37", "Abstain")
	var bill_id := str(GameState.level_bill()["bill_id"])
	var bill := BattleSetup.enriched_floor_vote(GameState.level_bill())
	var result := {"totals": {"Yes": 60, "No": 30, "Abstain": 11}, "passed": true}
	GameState.record_floor_vote(bill, result, "Yes")
	assert_true(StatuteBook.player_took_a_side(GameState.statute_book, bill_id), "the Aye replaced the abstention")
	GameState.record_floor_vote(bill, result, "No")
	assert_eq(str(GameState.statute_book[GameState.statute_book.size() - 1]["player_vote"]), "Yes", "and stays")
	assert_true(GameState.act_is_settled(level))
