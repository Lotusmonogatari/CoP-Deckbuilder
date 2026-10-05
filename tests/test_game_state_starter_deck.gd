extends GutTest
## A new run's opening deck must only ever contain cards the run itself owns.
##
## Ledger.opening_deck() deliberately fills past the opening tier from the
## suits above it when there aren't enough Starter cards to fill a deck (see
## its own test, "the rest is filled from above") — reset_collection() has to
## grant whatever it picked, or the very first deck of a gated run (the
## workbook's `open_card_collection = false` setting, live today) would start
## illegal: a deck containing cards the collection screen says aren't owned.

var _saved_run: Dictionary = {}


func before_each() -> void:
	_saved_run = GameState.to_save()


func after_each() -> void:
	GameState.load_save(_saved_run)


func test_every_card_in_the_opening_deck_is_owned() -> void:
	GameState.start_new_run("PC02")
	for card_id: String in GameState.deck:
		assert_true(GameState.owned_cards.has(card_id),
			"%s is in the opening deck but not in owned_cards" % card_id)


func test_the_opening_deck_is_a_legal_deck() -> void:
	GameState.start_new_run("PC02")
	var refusal := Ledger.deck_refusal(GameState.deck, GameState.owned_cards, DataDB.balance, Text.phrase())
	assert_eq(refusal, "", "a fresh run's own starting deck should never be refused")


# ---------------------------------------------------------------------------
# The randomized opening deck (2026-10-05): 15 cards, suits balanced to within
# one, tiers following the Balance-tab recipe, never more than one Tier 3.
# These run against the REAL card set and balance, over many seeds.
# ---------------------------------------------------------------------------

func _tier_of(card_id: String) -> String:
	return str(DataDB.get_card(card_id).get("tier", ""))


func test_the_random_opening_deck_follows_the_recipe_over_many_seeds() -> void:
	var seen_tier_3 := 0
	var seen_different := {}
	for seed_value in 300:
		var deck := Ledger.opening_deck(DataDB.cards, DataDB.balance, seed_value)
		assert_eq(deck.size(), 15, "seed %d: a full deck" % seed_value)

		var unique := {}
		var suit_counts := {}
		var tier_counts := {"0": 0, "1": 0, "2": 0, "3": 0}
		for card_id: String in deck:
			unique[card_id] = true
			var suit := str(DataDB.get_card(card_id).get("suit", ""))
			suit_counts[suit] = int(suit_counts.get(suit, 0)) + 1
			tier_counts[_tier_of(card_id)] += 1
		assert_eq(unique.size(), 15, "seed %d: no card twice" % seed_value)

		assert_eq(suit_counts.size(), 6, "seed %d: every suit present" % seed_value)
		for suit: String in suit_counts:
			assert_between(int(suit_counts[suit]), 2, 3, "seed %d: %s count" % [seed_value, suit])

		assert_eq(tier_counts["0"], 4, "seed %d: Tier 0 count" % seed_value)
		assert_eq(tier_counts["1"], 4, "seed %d: Tier 1 count" % seed_value)
		assert_lte(tier_counts["3"], 1, "seed %d: at most one Tier 3" % seed_value)
		assert_eq(tier_counts["2"] + tier_counts["3"], 7, "seed %d: the rest is Tier 2/3" % seed_value)

		seen_tier_3 += tier_counts["3"]
		seen_different[",".join(deck)] = true

	assert_gt(seen_different.size(), 100, "the deck really is random across seeds")
	assert_gt(seen_tier_3, 0, "a Tier 3 card does turn up sometimes (25% chance)")
	assert_lt(seen_tier_3, 300, "and not every time")


func test_the_same_seed_gives_the_same_opening_deck() -> void:
	assert_eq(Ledger.opening_deck(DataDB.cards, DataDB.balance, 42),
		Ledger.opening_deck(DataDB.cards, DataDB.balance, 42))


func test_a_zero_percent_tier_3_chance_never_deals_a_tier_3() -> void:
	var balance := DataDB.balance.duplicate()
	balance["starter_deck_tier_3_chance"] = 0
	for seed_value in 100:
		for card_id: String in Ledger.opening_deck(DataDB.cards, balance, seed_value):
			assert_ne(_tier_of(card_id), "3")


func test_an_impossible_recipe_falls_back_to_the_old_deck() -> void:
	# Eight Tier 0 cards cannot exist (one per suit), so the recipe gives up
	# and the deterministic deck is used instead of a short or broken one.
	var balance := DataDB.balance.duplicate()
	balance["starter_deck_tier_0_cards"] = 8
	assert_eq(Ledger.opening_deck(DataDB.cards, balance, 1).size(), 15)


# ---------------------------------------------------------------------------
# Gaffe cards (cards that ADD to the gaffe meter) are capped at a percentage of
# the opening deck (2026-10-05, Cameron: 50%, so at most 7 of 15).
# ---------------------------------------------------------------------------

func _gaffe_cards_in(deck: Array) -> int:
	var count := 0
	for card_id: String in deck:
		if int(DataDB.get_card(card_id).get("gaffe", 0) if DataDB.get_card(card_id).get("gaffe") != null else 0) > 0:
			count += 1
	return count


func test_no_opening_deck_is_more_than_half_gaffe_cards() -> void:
	for seed_value in 500:
		var deck := Ledger.opening_deck(DataDB.cards, DataDB.balance, seed_value)
		assert_eq(deck.size(), 15, "seed %d: still a full deck" % seed_value)
		assert_lte(_gaffe_cards_in(deck), 7, "seed %d: at most 7 of 15 are gaffe cards" % seed_value)


func test_the_gaffe_cap_really_does_something() -> void:
	# Without it, plenty of rolls exceed 7 (Divisive and Duplicitous are gaffe
	# cards almost without exception), so the cap above is not passing by luck.
	var uncapped := DataDB.balance.duplicate()
	uncapped["starter_deck_max_gaffe_cards"] = 100
	var over := 0
	for seed_value in 500:
		if _gaffe_cards_in(Ledger.opening_deck(DataDB.cards, uncapped, seed_value)) > 7:
			over += 1
	assert_gt(over, 0, "some uncapped rolls exceed 7 gaffe cards")


func test_a_tighter_gaffe_cap_is_obeyed() -> void:
	var tight := DataDB.balance.duplicate()
	tight["starter_deck_max_gaffe_cards"] = 40   # 40% of 15 = 6
	for seed_value in 100:
		var deck := Ledger.opening_deck(DataDB.cards, tight, seed_value)
		assert_eq(deck.size(), 15)
		assert_lte(_gaffe_cards_in(deck), 6)
