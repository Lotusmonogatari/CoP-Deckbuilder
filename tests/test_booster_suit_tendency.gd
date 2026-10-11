extends GutTest
## BoosterSuitTendency: which suits tend to please which organisations,
## read from the questions' own S/M/W grades.


func _q(booster: String, grade: String) -> Dictionary:
	return {"pleases_boosters": [booster],
		"grades": {"Earnest": grade, "Appeal": "W"}}


func _pool(booster: String, grade: String, n: int) -> Array:
	var out: Array = []
	for i in n:
		out.append(_q(booster, grade))
	return out


func test_an_organisation_leans_towards_the_suit_its_questions_grade_strong() -> void:
	var table := BoosterSuitTendency.by_suit({"p": _pool("BO08", "S", 5)}, ["Earnest", "Appeal"])
	assert_eq(table["Earnest"].size(), 1)
	assert_eq(table["Earnest"][0]["booster_id"], "BO08")
	assert_eq(table["Appeal"].size(), 0, "a suit graded weak is not listed")


func test_a_thin_sample_is_not_listed() -> void:
	var table := BoosterSuitTendency.by_suit({"p": _pool("BO08", "S", 4)}, ["Earnest"])
	assert_eq(table["Earnest"].size(), 0)


func test_lines_name_organisations_and_skip_empty_suits() -> void:
	var lines := BoosterSuitTendency.lines({"p": _pool("BO08", "S", 5)}, ["Earnest", "Appeal"],
		{"BO08": "National Media"})
	assert_eq(lines, ["Earnest: National Media"] as Array[String])


func test_the_real_data_gives_every_suit_a_line_or_none_without_crashing() -> void:
	var suits: Array = []
	for row in DataDB.suits:
		suits.append(str(row["element"]))
	var lines := BoosterSuitTendency.lines(DataDB.questions, suits, BattleSetup.booster_names())
	assert_gt(lines.size(), 0)
	for line in lines:
		assert_false(line.contains("BO"), "organisations are named, not shown as IDs: " + line)
