extends GutTest
## The level briefing's words (P12, 2026-11-19, Cameron): a room pays when it is won and the level bonus when the
## level is won, and the briefing never says "win all" or "the whole level", which an old draft did and which was not
## what the code does (a level can be won after losing a room that does not end it).

## Rows of the old briefing block (LevelBonusView.rows(), no longer on the screen), listed in design/CLEANUP_CANDIDATES.md
## for Cameron to remove. Their old wording ("paid if you win the whole level") is what this redesign corrected.
const RETIRED := ["briefing.level_bonus", "briefing.level_bonus_orgs"]


func _briefing_rows() -> Dictionary:
	var out := {}
	for key: String in DataDB.strings:
		if key.begins_with("briefing.") and not RETIRED.has(key):
			out[key] = str(DataDB.strings[key])
	return out


func test_there_are_briefing_rows() -> void:
	assert_gt(_briefing_rows().size(), 10, "the briefing's wording is in the Text tab")


func test_no_row_says_win_all() -> void:
	for key: String in _briefing_rows():
		var text: String = str(_briefing_rows()[key]).to_lower()
		assert_false(text.contains("win all"), "%s says 'win all': %s" % [key, text])
		assert_false(text.contains("whole level"), "%s says 'whole level': %s" % [key, text])


func test_the_bonus_is_paid_when_you_win_the_level() -> void:
	var say := Text.say("briefing.how_it_pays").to_lower()
	assert_true(say.contains("win the level"), "how it pays: " + say)
