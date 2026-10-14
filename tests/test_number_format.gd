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
