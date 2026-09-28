extends GutTest
## VoteInfluenceCues.resolve(): the optional cutscene line for a Floor Vote
## the influence swing flipped. Fabricated data, same discipline as
## test_office_notices.gd/test_level_intro_cues.gd.

func _cues() -> Array:
	return [
		{"bill_id": "BI01", "outcome_direction": "Flipped to Pass", "cue_text": "Every seat, in the end."},
		{"bill_id": "BI01", "outcome_direction": "Flipped to Fail", "cue_text": "Not this time."},
	]


func test_a_written_row_is_returned() -> void:
	assert_eq(VoteInfluenceCues.resolve(_cues(), "BI01", "Flipped to Pass"), "Every seat, in the end.")


func test_the_other_direction_for_the_same_bill_returns_its_own_line() -> void:
	assert_eq(VoteInfluenceCues.resolve(_cues(), "BI01", "Flipped to Fail"), "Not this time.")


func test_a_bill_with_nothing_written_returns_blank() -> void:
	assert_eq(VoteInfluenceCues.resolve(_cues(), "BI02", "Flipped to Pass"), "")


func test_no_rows_at_all_returns_blank() -> void:
	assert_eq(VoteInfluenceCues.resolve([], "BI01", "Flipped to Pass"), "")
