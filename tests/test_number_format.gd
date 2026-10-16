extends GutTest
## Amounts of four digits or more read with thousands separators; other
## numbers are left alone.

func test_separators_are_added_to_amounts() -> void:
	var p := Phrase.new({"a": "{count} Yen", "b": "{cost} Yen", "c": "{tier} {count}"})
	assert_eq(p.say("a", {"count": 1000000}), "1,000,000 Yen")
	assert_eq(p.say("b", {"cost": 25000}), "25,000 Yen")
	assert_eq(p.say("a", {"count": 999}), "999 Yen")
	assert_eq(p.say("a", {"count": -12500}), "-12,500 Yen")


func test_other_placeholders_are_untouched() -> void:
	var p := Phrase.new({"c": "{tier} {count}"})
	assert_eq(p.say("c", {"tier": 2026, "count": 5}), "2026 5")


# Funds is written with the 円 mark on the number; no other variable is.
func test_funds_amounts_carry_the_yen_mark() -> void:
	assert_eq(Phrase.meta_amount("Funds", 100000), "100,000円")
	assert_eq(Phrase.meta_amount("Funds", 1500, true), "+1,500円")
	assert_eq(Phrase.meta_amount("Funds", -2500, true), "-2,500円")
	assert_eq(Phrase.meta_amount("Funds", 0, true), "0円")


func test_other_meta_amounts_stay_plain_numbers() -> void:
	assert_eq(Phrase.meta_amount("Reputation", 5, true), "+5")
	assert_eq(Phrase.meta_amount("Constituency support", -3, true), "-3")
	assert_eq(Phrase.meta_amount("Party support", 40), "40")
