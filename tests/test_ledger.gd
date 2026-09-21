extends GutTest
## Tests for what a thing costs and whether you may have it.
##
## The ledger is the one place that answers "can I buy this", so these are
## the assertions the Office screens are trusting when they enable a button.


const BALANCE := {"starter_deck_size": 12}
const SETTINGS := {"required_standing": 60}
const BOOSTERS := ["BO01", "BO03", "BO08"]


func _card(overrides: Dictionary = {}) -> Dictionary:
	var base := {"card_id": "C99", "tier": "Tier 1", "xp_to_unlock": 60}
	base.merge(overrides, true)
	return base


func _modifier(overrides: Dictionary = {}) -> Dictionary:
	var base := {
		"mod_id": "M01", "kaban_cost": 20,
		"available_to": "Both", "source_booster": "BO03",
	}
	base.merge(overrides, true)
	return base


# ---------------------------------------------------------------------------
# Cards
# ---------------------------------------------------------------------------

func test_a_card_you_can_afford_is_yours_to_buy() -> void:
	assert_true(Ledger.can_buy_card(_card(), [], 60))
	assert_eq(Ledger.card_refusal(_card(), [], 60), "")


func test_a_card_you_cannot_afford_says_how_short_you_are() -> void:
	# The number matters: "60 XP" tells you nothing you did not know, and
	# "17 XP short" tells you whether the next stage will cover it.
	assert_eq(Ledger.card_refusal(_card(), [], 43), "17 XP short.")
	assert_false(Ledger.can_buy_card(_card(), [], 43))


func test_a_card_you_already_own_cannot_be_bought_twice() -> void:
	assert_eq(Ledger.card_refusal(_card(), ["C99"], 999), "Already yours.")


func test_exactly_enough_xp_is_enough() -> void:
	assert_true(Ledger.can_buy_card(_card({"xp_to_unlock": 60}), [], 60),
		"60 of 60 buys it; a boundary that goes the other way is a bug players notice")


func test_a_starter_card_costs_nothing() -> void:
	assert_eq(Ledger.card_cost(_card({"tier": "Starter", "xp_to_unlock": 0})), 0)
	assert_true(Ledger.can_buy_card(_card({"xp_to_unlock": 0}), [], 0))


# ---------------------------------------------------------------------------
# Modifiers
# ---------------------------------------------------------------------------

func test_a_backed_modifier_you_can_afford_is_yours() -> void:
	assert_eq(Ledger.modifier_refusal(
		_modifier(), [], 30, {"BO03": 60}, SETTINGS, BOOSTERS), "")


func test_standing_is_checked_before_the_price() -> void:
	# Being told the price of something you are not allowed to buy is worse
	# than being told why you cannot buy it.
	var refusal := Ledger.modifier_refusal(
		_modifier(), [], 0, {"BO03": 10}, SETTINGS, BOOSTERS)
	assert_eq(refusal, "Standing 10 of 60 needed.",
		"the gate, not the empty wallet")


func test_standing_short_of_the_threshold_refuses() -> void:
	assert_false(Ledger.can_buy_modifier(
		_modifier(), [], 999, {"BO03": 59}, SETTINGS, BOOSTERS))
	assert_true(Ledger.can_buy_modifier(
		_modifier(), [], 999, {"BO03": 60}, SETTINGS, BOOSTERS),
		"exactly the threshold is enough")


func test_funds_short_says_how_short() -> void:
	assert_eq(Ledger.modifier_refusal(
		_modifier(), [], 12, {"BO03": 99}, SETTINGS, BOOSTERS), "8 short.")


func test_a_modifier_with_no_price_is_not_for_sale() -> void:
	# The opponent-only ones, and the pair switched on by party support.
	assert_false(Ledger.is_for_sale(_modifier({"kaban_cost": null})))
	assert_eq(Ledger.modifier_refusal(_modifier({"kaban_cost": null}),
		[], 999, {"BO03": 99}, SETTINGS, BOOSTERS), "Not for sale.")


func test_an_opponent_only_modifier_is_not_on_the_players_shelf() -> void:
	assert_false(Ledger.is_for_sale(_modifier({"available_to": "Opponent"})))


func test_a_modifier_backed_by_nobody_needs_no_standing() -> void:
	# M09 and M10 name a meta-variable rather than an organisation, so there
	# is nobody to have standing with.
	var m := _modifier({"source_booster": "Party support (meta)"})
	assert_eq(Ledger.backing_booster(m, BOOSTERS), "")
	assert_eq(Ledger.modifier_refusal(m, [], 30, {}, SETTINGS, BOOSTERS), "")


func test_a_threshold_can_be_set_per_modifier() -> void:
	# So a National organisation can ask more than a local one without
	# every price becoming a special case in code.
	var settings := {"required_standing": 60,
		"required_standing_by_modifier": {"M01": 80}}
	assert_eq(Ledger.standing_needed(_modifier(), settings), 80)
	assert_eq(Ledger.standing_needed(_modifier({"mod_id": "M04"}), settings), 60)


func test_a_modifier_you_own_cannot_be_bought_twice() -> void:
	assert_eq(Ledger.modifier_refusal(
		_modifier(), ["M01"], 999, {"BO03": 99}, SETTINGS, BOOSTERS),
		"Already yours.")


# ---------------------------------------------------------------------------
# The deck
# ---------------------------------------------------------------------------

func _owned(count: int) -> Array:
	var owned: Array = []
	for i in count:
		owned.append("C%02d" % i)
	return owned


func _deck(count: int) -> Array:
	return _owned(count)


func test_a_full_deck_of_cards_you_own_is_legal() -> void:
	assert_true(Ledger.deck_is_legal(_deck(12), _owned(20), BALANCE))


func test_a_short_deck_says_how_many_more() -> void:
	assert_eq(Ledger.deck_refusal(_deck(9), _owned(20), BALANCE), "3 more to choose.")


func test_an_overfull_deck_says_how_many_too_many() -> void:
	assert_eq(Ledger.deck_refusal(_deck(14), _owned(20), BALANCE), "2 too many.")


func test_a_deck_cannot_hold_a_card_you_do_not_own() -> void:
	assert_eq(Ledger.deck_refusal(["C00", "NOPE"], ["C00"], BALANCE), "NOPE is not yours.")


func test_a_deck_cannot_hold_the_same_card_twice() -> void:
	var deck := _deck(12)
	deck[11] = deck[0]
	assert_eq(Ledger.deck_refusal(deck, _owned(20), BALANCE), "C00 is in twice.")


func test_the_deck_size_is_a_lever() -> void:
	assert_eq(Ledger.deck_size({"starter_deck_size": 15}), 15)
	assert_eq(Ledger.deck_size({}), 12, "the brief's default when nothing says otherwise")


func test_a_new_run_opens_with_the_starter_cards() -> void:
	var cards: Array = [
		{"card_id": "S1", "tier": "0", "suit": "Earnest"},
		{"card_id": "T1", "tier": "1", "suit": "Earnest"},
		{"card_id": "S2", "tier": "0", "suit": "Appeal"},
	]
	# Opening-tier first; the deck is then filled towards its size from the
	# tiers above, a suit at a time.
	var deck := Ledger.opening_deck(cards, BALANCE)
	assert_eq(deck.slice(0, 2), ["S1", "S2"] as Array[String],
		"the opening tier leads")
	assert_true(deck.has("T1"), "and the rest is filled from above")


func test_an_opening_deck_never_exceeds_the_deck_size() -> void:
	# More Starter cards than a deck holds would otherwise make the opening
	# hand a silent choice nobody made.
	var cards: Array = []
	for i in 20:
		cards.append({"card_id": "S%02d" % i, "tier": "0", "suit": "Earnest"})
	assert_eq(Ledger.opening_deck(cards, BALANCE).size(), 12)
