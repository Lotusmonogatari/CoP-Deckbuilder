extends GutTest
## The level briefing's data (P12, 2026-11-19): LevelBriefing.build() must give, for every level, what the
## briefing showed before the redesign (tests/fixtures/level_briefing_golden.json, recorded from the old code
## on all 114 levels), keep hidden rooms hidden, label the rooms, and do the week's sums.

const GOLDEN_PATH := "res://tests/fixtures/level_briefing_golden.json"

var _golden: Dictionary = {}


func before_all() -> void:
	_golden = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN_PATH))


## Plain JSON numbers (whole numbers read back as decimals), so a value from the file and one from the game compare.
func _norm(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))


func _context(left: int = 28, pool: int = 40, phase: String = "work") -> Dictionary:
	return {"hours_left": left, "pool": pool, "phase": phase, "purpose": {}}


func _view(level: Dictionary, tier: String = Difficulty.STANDARD) -> Dictionary:
	return LevelBriefing.build(BattleSetup.expand_level(level), tier, DataDB.balance_base, _context())


# --- equivalence with the briefing as it was -------------------------------------------

func test_the_record_covers_every_level() -> void:
	assert_eq(_golden.size(), DataDB.levels.size())
	for level: Dictionary in DataDB.levels:
		assert_true(_golden.has(str(level["level_id"])), "%s is in the record" % level["level_id"])


func test_every_level_shows_what_it_showed_before() -> void:
	for level: Dictionary in DataDB.levels:
		var lid := str(level["level_id"])
		var was: Dictionary = _golden[lid]
		var expanded := BattleSetup.expand_level(level)
		var view := LevelBriefing.build(expanded, Difficulty.STANDARD, DataDB.balance_base, _context())

		assert_eq(view["hours"], int(was["hours"]), "%s: total hours" % lid)
		assert_eq(int(view["room_count"]) + int(was["hidden_rooms"]), (expanded["stages"] as Array).size(),
			"%s: shown plus hidden rooms is every room" % lid)
		assert_eq(view["lists_rooms"], was["lists_stages"], "%s: lists its rooms" % lid)
		assert_eq(view["anything_set"], was["anything_set"], "%s: has rewards set" % lid)
		assert_eq(_norm(view["totals"]), _norm(was["totals"]), "%s: totals" % lid)

		var rooms: Array = view["rooms"]
		var was_rooms: Array = was["rooms"]
		assert_eq(rooms.size(), was_rooms.size(), "%s: shown rooms" % lid)
		for i in mini(rooms.size(), was_rooms.size()):
			var room: Dictionary = rooms[i]
			var old: Dictionary = was_rooms[i]
			var where := "%s room %d" % [lid, i + 1]
			assert_eq(room["name"], old["name"], where + ": name")
			assert_eq(room["hours"], int(old["hours"]), where + ": hours")
			assert_eq(room["kind"], LevelBriefing.kind_of({"mode": old["mode"]}), where + ": kind")
			assert_eq(room["loss_continues"], old["loss_continues"], where + ": loss carries on")
			assert_eq(room["rewards_unset"], old["rewards_unset"], where + ": unset")
			assert_eq(_norm(room["rewards"]), _norm(old["rewards"]), where + ": rewards")


func test_the_level_bonus_is_what_it_was_on_every_campaign_pressure() -> void:
	for level: Dictionary in DataDB.levels:
		var lid := str(level["level_id"])
		for tier: String in Difficulty.TIERS:
			var view := _view(level, tier)
			assert_eq(_norm(view["bonus"]), _norm((_golden[lid]["bonus"] as Dictionary)[tier]), "%s at %s" % [lid, tier])


# --- hidden rooms ------------------------------------------------------------------------

func test_a_hidden_room_leaves_no_trace_but_its_hours() -> void:
	var tested := 0
	for level: Dictionary in DataDB.levels:
		var lid := str(level["level_id"])
		var was: Dictionary = _golden[lid]
		if int(was["hidden_rooms"]) == 0:
			continue
		tested += 1
		var view := _view(level)
		var shown_hours := 0
		for room: Dictionary in view["rooms"]:
			shown_hours += int(room["hours"])
		assert_eq(int(view["hours"]), shown_hours + int(was["hidden_hours"]), "%s: the total still counts it" % lid)
		for stage: Dictionary in BattleSetup.expand_level(level)["stages"]:
			if not LevelBriefing.is_revealed(stage):
				for room: Dictionary in view["rooms"]:
					assert_ne(room["name"], str(stage.get("name_en", "")), "%s: %s is not listed" % [lid, stage.get("name_en")])
	assert_gt(tested, 10, "the data has levels with a hidden room")


func test_the_timeline_runs_over_the_shown_rooms_only() -> void:
	for level: Dictionary in DataDB.levels:
		var start := 0
		for room: Dictionary in _view(level)["rooms"]:
			assert_eq(int(room["start"]), start, "%s room %d starts where the last ended" % [level["level_id"], room["n"]])
			start += int(room["hours"])


func test_a_level_with_one_shown_room_lists_none() -> void:
	var found := 0
	for level: Dictionary in DataDB.levels:
		var view := _view(level)
		if int(view["room_count"]) == 1:
			found += 1
			assert_false(view["lists_rooms"], str(level["level_id"]))
	assert_gt(found, 10)


# --- kinds and loss --------------------------------------------------------------------

func test_each_kind_of_room_has_a_label() -> void:
	assert_eq(LevelBriefing.kind_of({"mode": "Combat"}), LevelBriefing.KIND_DEBATE)
	assert_eq(LevelBriefing.kind_of({"mode": "Non-combat"}), LevelBriefing.KIND_CONVERSATION)
	assert_eq(LevelBriefing.kind_of({"mode": "Vote"}), LevelBriefing.KIND_VOTE)
	assert_eq(LevelBriefing.kind_of({"mode": "Visit"}), LevelBriefing.KIND_VISIT)
	assert_eq(LevelBriefing.kind_of({"mode": "Trade"}), LevelBriefing.KIND_TRADE)
	assert_eq(LevelBriefing.kind_of({}), LevelBriefing.KIND_DEBATE, "an unknown mode reads as a debate")


func test_a_bill_level_has_a_vote_room() -> void:
	var votes := 0
	for level: Dictionary in DataDB.levels:
		for room: Dictionary in _view(level)["rooms"]:
			if room["kind"] == LevelBriefing.KIND_VOTE:
				votes += 1
	assert_gt(votes, 40, "50 levels end in a Floor Vote")


func test_only_a_card_battle_that_does_not_end_the_level_carries_on_after_a_loss() -> void:
	assert_true(LevelBriefing.loses_continue({"mode": "Combat", "loss_ends_level": "No"}))
	assert_false(LevelBriefing.loses_continue({"mode": "Combat"}), "by default a loss ends the level")
	assert_false(LevelBriefing.loses_continue({"mode": "Non-combat", "loss_ends_level": "No"}), "a conversation cannot be lost")


func test_a_loss_cost_is_carried_but_not_shown() -> void:
	var carried := 0
	for level: Dictionary in DataDB.levels:
		for room: Dictionary in _view(level)["rooms"]:
			if not (room["loss"] as Dictionary).is_empty():
				carried += 1
	assert_gt(carried, 100, "most rooms carry a loss cost")


# --- the week and the purpose ---------------------------------------------------------

func test_the_week_around_a_level() -> void:
	var week := LevelBriefing.week_of(6, 28, 40, "work")
	assert_eq(week["used"], 12)
	assert_eq(week["left"], 28)
	assert_eq(week["this_level"], 6)
	assert_eq(week["after"], 22)
	assert_false(week["overflow"])


func test_a_level_that_does_not_fit_leaves_nothing_after() -> void:
	var week := LevelBriefing.week_of(6, 4, 40, "work")
	assert_eq(week["after"], 0)
	assert_eq(week["this_level"], 4, "the bar shows only what there is")
	assert_true(week["overflow"])


func test_the_weekend_has_its_own_pool() -> void:
	var week := LevelBriefing.week_of(2, 8, 8, "weekend")
	assert_eq(week["pool"], 8)
	assert_eq(week["used"], 0)
	assert_eq(week["after"], 6)
	assert_eq(week["phase"], "weekend")


func test_the_refusal_and_the_purpose_come_through() -> void:
	var level := BattleSetup.expand_level(DataDB.get_level("LV11"))
	var context := _context()
	context["refusal"] = "Not enough hours left."
	context["purpose"] = {"text": "Meet the students.", "staff_name": "Aiko", "staff_id": "SF01", "role": "x"}
	var view := LevelBriefing.build(level, Difficulty.STANDARD, DataDB.balance_base, context)
	assert_eq(view["refusal"], "Not enough hours left.")
	assert_eq(view["purpose"], {"text": "Meet the students.", "speaker": "Aiko"})
	assert_eq(view["location"], "", "no office badge until the two-offices plan has a Location")


func test_no_purpose_gives_an_empty_purpose_and_none_with_no_staff_is_narration() -> void:
	var level := BattleSetup.expand_level(DataDB.get_level("LV11"))
	assert_eq(LevelBriefing.build(level, Difficulty.STANDARD, DataDB.balance_base, _context())["purpose"], {})
	assert_eq(LevelBriefing.purpose_of({"text": "A line.", "staff_name": ""}), {"text": "A line.", "speaker": ""})
