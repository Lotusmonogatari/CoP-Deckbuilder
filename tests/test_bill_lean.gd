extends GutTest
## BillLean.gd: the Level Intro screen's bill-lean choice (2026-10-01) —
## comparing the player's pick against their own party's Disposition
## toward the level's bill to decide a Party support delta.


func test_leaning_with_a_supportive_party_rewards_the_player() -> void:
	var position := {"disposition": "Supportive"}
	assert_eq(BillLean.party_support_delta(position, BillLean.SUPPORT, 2), 2)


func test_leaning_against_a_supportive_party_penalizes_the_player() -> void:
	var position := {"disposition": "Supportive"}
	assert_eq(BillLean.party_support_delta(position, BillLean.OPPOSE, 2), -2)


func test_leaning_with_an_opposed_party_rewards_the_player() -> void:
	var position := {"disposition": "Opposed"}
	assert_eq(BillLean.party_support_delta(position, BillLean.OPPOSE, 2), 2)


func test_leaning_against_an_opposed_party_penalizes_the_player() -> void:
	var position := {"disposition": "Opposed"}
	assert_eq(BillLean.party_support_delta(position, BillLean.SUPPORT, 2), -2)


func test_a_neutral_party_never_rewards_or_penalizes_either_lean() -> void:
	var position := {"disposition": "Neutral"}
	assert_eq(BillLean.party_support_delta(position, BillLean.SUPPORT, 2), 0)
	assert_eq(BillLean.party_support_delta(position, BillLean.OPPOSE, 2), 0)


func test_a_missing_position_is_treated_the_same_as_neutral() -> void:
	assert_eq(BillLean.party_support_delta({}, BillLean.SUPPORT, 2), 0)
