extends GutTest
## Spending in the Office, and what it announces.
##
## GameState is the run's memory and an autoload, so these tests put it back
## the way they found it. Everything here is about the two currencies behaving
## the same way as each other and staying inside the bounds sanban.json sets —
## the XP and Yen shops are built on exactly this.

var _meta_before: Dictionary = {}
var _xp_before := 0
var _owned_before: Array[String] = []
var _standing_before: Dictionary = {}
var _seen: Array[Dictionary] = []


func before_each() -> void:
	_meta_before = GameState.meta.duplicate(true)
	_xp_before = GameState.xp
	_owned_before = GameState.owned_modifiers.duplicate()
	_standing_before = GameState.booster_standing.duplicate(true)
	_seen = []
	EventBus.meta_changed.connect(_note)


func after_each() -> void:
	EventBus.meta_changed.disconnect(_note)
	GameState.meta = _meta_before.duplicate(true)
	GameState.xp = _xp_before
	GameState.owned_modifiers = _owned_before.duplicate()
	GameState.booster_standing = _standing_before.duplicate(true)


func _note(name: String, value: int, delta: int) -> void:
	_seen.append({"name": name, "value": value, "delta": delta})


func _funds_row() -> Dictionary:
	for row: Dictionary in DataDB.sanban:
		if row.get("name_en") == "Funds":
			return row
	return {}


# ---------------------------------------------------------------------------
# Staying inside the range
# ---------------------------------------------------------------------------

func test_funds_cannot_be_pushed_past_the_ceiling() -> void:
	var ceiling := int(_funds_row().get("max", 999))
	GameState.meta["Funds"] = ceiling - 5
	GameState._move_meta("Funds", 1000)

	assert_eq(int(GameState.meta["Funds"]), ceiling,
		"the maximum in sanban.json is the maximum")


func test_funds_cannot_be_pushed_below_the_floor() -> void:
	var floor_value := int(_funds_row().get("min", 0))
	GameState.meta["Funds"] = floor_value + 5
	GameState._move_meta("Funds", -1000)

	assert_eq(int(GameState.meta["Funds"]), floor_value,
		"the minimum in sanban.json is the minimum")


func test_what_is_announced_is_what_actually_moved() -> void:
	# A ceiling that swallows most of a payment should not be reported as a
	# full one. The Office is about to show this number to the player.
	var ceiling := int(_funds_row().get("max", 999))
	GameState.meta["Funds"] = ceiling - 3
	_seen = []
	GameState._move_meta("Funds", 50)

	assert_eq(_seen.size(), 1, "one move, one announcement")
	assert_eq(_seen[0]["delta"], 3, "only three of the fifty fitted")
	assert_eq(_seen[0]["value"], ceiling)


func test_a_move_that_changes_nothing_announces_nothing() -> void:
	var ceiling := int(_funds_row().get("max", 999))
	GameState.meta["Funds"] = ceiling
	_seen = []
	GameState._move_meta("Funds", 10)

	assert_eq(_seen.size(), 0, "already at the ceiling: nothing moved, nothing to say")


# ---------------------------------------------------------------------------
# The two doors behave alike
# ---------------------------------------------------------------------------

func test_buying_backing_announces_the_spend() -> void:
	# Buying a card has always announced its XP; buying backing used to write
	# the number straight in and say nothing, so the two shops would have
	# behaved differently.
	GameState.meta["Funds"] = 999
	_earn_everyones_backing()

	var modifier := _an_affordable_modifier()
	assert_false(modifier.is_empty(),
		"with the money and the standing, something should be for sale")

	_seen = []
	var refusal := GameState.buy_modifier(str(modifier.get("mod_id", "")))

	assert_eq(refusal, "", "it should have gone through: %s" % refusal)
	assert_eq(_seen.size(), 1, "spending Funds should say so")
	assert_lt(_seen[0]["delta"], 0, "and say that it went down")


## Puts standing with every organisation at the level the shop asks for.
##
## A fresh run starts at 50 against a requirement of 60, so nothing is on
## sale until the player has pleased somebody — which is Cameron's design,
## not an accident, and means this test has to earn its way in.
func _earn_everyones_backing() -> void:
	var needed := int(DataDB.booster_standing.get("required_standing", 60))
	for booster_id: String in GameState.booster_standing.keys():
		GameState.booster_standing[booster_id] = needed


## The first modifier the Ledger would actually sell, or nothing.
func _an_affordable_modifier() -> Dictionary:
	for modifier: Dictionary in DataDB.modifiers:
		if not Ledger.is_for_sale(modifier):
			continue
		if GameState.owned_modifiers.has(str(modifier.get("mod_id", ""))):
			continue
		var refusal := Ledger.modifier_refusal(modifier, GameState.owned_modifiers,
			int(GameState.meta.get("Funds", 0)), GameState.booster_standing,
			DataDB.booster_standing, BattleSetup.booster_ids())
		if refusal.is_empty():
			return modifier
	return {}
