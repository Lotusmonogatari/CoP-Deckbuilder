extends GutTest
## The Parties popup's ally/rival lists and their favorability tags.


func test_tags_follow_the_effect_not_the_sign_of_the_weight() -> void:
	assert_eq(PartyAllies.tag_for(2.0), PartyAllies.IMPROVING)
	assert_eq(PartyAllies.tag_for(-2.0), PartyAllies.REDUCING)
	assert_eq(PartyAllies.tag_for(0.2), PartyAllies.NEUTRAL)
	assert_eq(PartyAllies.tag_for(-0.2), PartyAllies.NEUTRAL)


func test_positive_weights_are_allies_and_negative_are_rivals() -> void:
	var g := PartyAllies.groups([
		{"booster_id": "BO01", "weight": 1.0, "standing": 30, "effect": -3.0},
		{"booster_id": "BO02", "weight": 3.0, "standing": 80, "effect": 4.0},
		{"booster_id": "BO03", "weight": -2.0, "standing": 30, "effect": 2.0},
		{"booster_id": "BO04", "weight": 0.0, "standing": 50, "effect": 0.0},
	])
	assert_eq(g["allies"].size(), 2)
	assert_eq(g["allies"][0]["booster_id"], "BO02", "biggest weight first")
	assert_eq(g["allies"][1]["tag"], PartyAllies.REDUCING, "a cold ally reduces favorability")
	assert_eq(g["rivals"].size(), 1)
	assert_eq(g["rivals"][0]["tag"], PartyAllies.IMPROVING, "a cold rival improves it")
