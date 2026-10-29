extends GutTest
## The Marketplace's Funds limit follows the Funds-cap purchases (2026-10-29).

var _saved_bonus := 0


func before_each() -> void:
	_saved_bonus = GameState.funds_cap_bonus


func after_each() -> void:
	GameState.funds_cap_bonus = _saved_bonus


func test_the_limit_starts_at_the_starting_cap() -> void:
	GameState.funds_cap_bonus = 0
	var hard_max := int(DataDB.get_sanban("Funds").get("max", 0))
	assert_eq(GameState.funds_limit(), mini(int(DataDB.rules.get("funds_starting_cap", 100000)), hard_max))


func test_buying_a_limit_increase_raises_it_until_the_hard_ceiling() -> void:
	GameState.funds_cap_bonus = 0
	var before := GameState.funds_limit()
	GameState.funds_cap_bonus = 100000
	assert_gt(GameState.funds_limit(), before)
	GameState.funds_cap_bonus = 999999999
	assert_eq(GameState.funds_limit(), int(DataDB.get_sanban("Funds").get("max", 0)), "never past the hard ceiling")
