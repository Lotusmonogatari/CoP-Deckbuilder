extends GutTest
## Tests for what a thing costs and whether you may have it.
##
## The ledger is the one place that answers "can I buy this", so these are
## the assertions the Office screens are trusting when they enable a button.


const BALANCE := {"starter_deck_size": 12}

## The real wording, so these tests assert the sentences a player reads.
##
## The Ledger is pure rules and cannot reach an autoload, so it is handed the
## table the way it is handed `balance`. Called without one it returns the
## keys instead, which is what a headless fixture sees.
func _words() -> Phrase:
	return Phrase.new(DataDB.strings)
const SETTINGS := {"required_standing": 60}

## 2026-09-22: modifiers no longer name their own booster — a booster names
## the modifiers IT sells, via linked_modifiers (see Ledger.backing_booster).
## BO03 is the one that sells M01 here; the other two sell nothing, standing
## in for the other nine organisations a real BOOSTERS list would carry.
const BOOSTERS := [
	{"booster_id": "BO01", "linked_modifiers": []},
	{"booster_id": "BO03", "linked_modifiers": ["M01"]},
	{"booster_id": "BO08", "linked_modifiers": []},
]

## Every currency at a level that affords any single-currency test price
## below, so a test only has to override the one cost it cares about.
const RICH_META := {"Funds": 999, "Reputation": 999, "Constituency support": 999}


func _card(overrides: Dictionary = {}) -> Dictionary:
	var base := {"card_id": "C99", "tier": "Tier 1", "xp_to_unlock": 60}
	base.merge(overrides, true)
	return base


## 2026-09-22: kaban_cost became three separate costs (funds_cost,
## reputation_cost, jiban_cost); available_to and source_booster are gone
## entirely (see Ledger.gd's own note on why). Defaults to a Funds-only price
## so the existing tests read the same way they always did.
func _modifier(overrides: Dictionary = {}) -> Dictionary:
	var base := {"mod_id": "M01", "funds_cost": 20}
	base.merge(overrides, true)
	return base


# ---------------------------------------------------------------------------
# Cards
# ---------------------------------------------------------------------------

func test_a_card_you_can_afford_is_yours_to_buy() -> void:
	assert_true(Ledger.can_buy_card(_card(), [], 60, _words()))
	assert_eq(Ledger.card_refusal(_card(), [], 60, _words()), "")


func test_a_card_you_cannot_afford_says_how_short_you_are() -> void:
	# The number matters: "60 XP" tells you nothing you did not know, and
	# "17 XP short" tells you whether the next stage will cover it.
	assert_eq(Ledger.card_refusal(_card(), [], 43, _words()), "17 XP short.")
	assert_false(Ledger.can_buy_card(_card(), [], 43, _words()))


func test_a_card_you_already_own_cannot_be_bought_twice() -> void:
	assert_eq(Ledger.card_refusal(_card(), ["C99"], 999, _words()), "Already yours.")


func test_exactly_enough_xp_is_enough() -> void:
	assert_true(Ledger.can_buy_card(_card({"xp_to_unlock": 60}), [], 60, _words()),
		"60 of 60 buys it; a boundary that goes the other way is a bug players notice")


func test_a_starter_card_costs_nothing() -> void:
	assert_eq(Ledger.card_cost(_card({"tier": "Starter", "xp_to_unlock": 0})), 0)
	assert_true(Ledger.can_buy_card(_card({"xp_to_unlock": 0}), [], 0, _words()))


# ---------------------------------------------------------------------------
# Modifiers
# ---------------------------------------------------------------------------

func test_a_backed_modifier_you_can_afford_is_yours() -> void:
	assert_eq(Ledger.modifier_refusal(
		_modifier(), [], {"Funds": 30}, {"BO03": 60}, SETTINGS, BOOSTERS, _words()), "")


func test_standing_is_checked_before_the_price() -> void:
	# Being told the price of something you are not allowed to buy is worse
	# than being told why you cannot buy it.
	var refusal := Ledger.modifier_refusal(
		_modifier(), [], {"Funds": 0}, {"BO03": 10}, SETTINGS, BOOSTERS, _words())
	assert_eq(refusal, "Standing 10 of 60 needed.",
		"the gate, not the empty wallet")


func test_standing_short_of_the_threshold_refuses() -> void:
	assert_false(Ledger.can_buy_modifier(
		_modifier(), [], RICH_META, {"BO03": 59}, SETTINGS, BOOSTERS, _words()))
	assert_true(Ledger.can_buy_modifier(
		_modifier(), [], RICH_META, {"BO03": 60}, SETTINGS, BOOSTERS, _words()),
		"exactly the threshold is enough")


func test_funds_short_says_how_short() -> void:
	assert_eq(Ledger.modifier_refusal(
		_modifier(), [], {"Funds": 12}, {"BO03": 99}, SETTINGS, BOOSTERS, _words()), "8 short.")


func test_a_reputation_cost_is_checked_too() -> void:
	# 2026-09-22: a modifier's price can be Reputation and/or Constituency
	# support as well as Funds, all three checked the same way.
	var m := _modifier({"funds_cost": 0, "reputation_cost": 10})
	assert_eq(Ledger.modifier_refusal(
		m, [], {"Reputation": 4}, {"BO03": 99}, SETTINGS, BOOSTERS, _words()), "6 short.")
	assert_eq(Ledger.modifier_refusal(
		m, [], {"Reputation": 10}, {"BO03": 99}, SETTINGS, BOOSTERS, _words()), "")


func test_a_modifier_with_no_price_is_not_for_sale() -> void:
	assert_false(Ledger.is_for_sale(_modifier({"funds_cost": 0})))
	assert_eq(Ledger.modifier_refusal(_modifier({"funds_cost": 0}),
		[], RICH_META, {"BO03": 99}, SETTINGS, BOOSTERS, _words()), "Not for sale.")


func test_a_modifier_with_any_nonzero_cost_is_for_sale() -> void:
	assert_true(Ledger.is_for_sale(_modifier({"funds_cost": 0, "jiban_cost": 5})),
		"any of the three costs is enough to be for sale")


func test_a_modifier_backed_by_nobody_needs_no_standing() -> void:
	# M09 and M10 name a meta-variable rather than an organisation, so there
	# is nobody to have standing with — no booster's linked_modifiers names
	# them.
	var m := _modifier({"mod_id": "M09"})
	assert_eq(Ledger.backing_booster(m, BOOSTERS), "")
	assert_eq(Ledger.modifier_refusal(m, [], RICH_META, {}, SETTINGS, BOOSTERS, _words()), "")


func test_a_threshold_can_be_set_per_modifier() -> void:
	# So a National organisation can ask more than a local one without
	# every price becoming a special case in code.
	var settings := {"required_standing": 60,
		"required_standing_by_modifier": {"M01": 80}}
	assert_eq(Ledger.standing_needed(_modifier(), settings), 80)
	assert_eq(Ledger.standing_needed(_modifier({"mod_id": "M04"}), settings), 60)


func test_a_modifier_you_own_cannot_be_bought_twice() -> void:
	assert_eq(Ledger.modifier_refusal(
		_modifier(), ["M01"], RICH_META, {"BO03": 99}, SETTINGS, BOOSTERS, _words()),
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
	assert_true(Ledger.deck_is_legal(_deck(12), _owned(20), BALANCE, _words()))


func test_a_short_deck_says_how_many_more() -> void:
	assert_eq(Ledger.deck_refusal(_deck(9), _owned(20), BALANCE, _words()), "3 more to choose.")


func test_an_overfull_deck_says_how_many_too_many() -> void:
	assert_eq(Ledger.deck_refusal(_deck(14), _owned(20), BALANCE, _words()), "2 too many.")


func test_a_deck_cannot_hold_a_card_you_do_not_own() -> void:
	assert_eq(Ledger.deck_refusal(["C00", "NOPE"], ["C00"], BALANCE, _words()), "NOPE is not yours.")


func test_a_deck_cannot_hold_the_same_card_twice() -> void:
	var deck := _deck(12)
	deck[11] = deck[0]
	assert_eq(Ledger.deck_refusal(deck, _owned(20), BALANCE, _words()), "C00 is in twice.")


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


# ---------------------------------------------------------------------------
# Staff — the Recruitment shop
# ---------------------------------------------------------------------------
# Shapes drawn from the real data/staff.json rows named in the brief: SF04
# starts at tier 0 and can reach tier 2 (both upgrade steps exist); SF05
# starts at tier 1 and has nowhere further to go despite highest_tier 1
# (its 0-to-1 cost is null because tier 0 was never on offer for them).

func _candidate(overrides: Dictionary = {}) -> Dictionary:
	var base := {
		"staff_id": "SF04", "role": "Policy Research Assistant",
		"starting_tier": 0, "highest_tier": 2, "hiring_cost_yen": 50000,
		"upgrade_cost_0_to_1_yen": 30000, "upgrade_cost_1_to_2_yen": 50000,
	}
	base.merge(overrides, true)
	return base


func test_a_vacant_role_can_be_hired_if_affordable() -> void:
	assert_eq(Ledger.staff_hire_refusal(_candidate(), {}, 50000, _words()), "")
	assert_true(Ledger.can_hire_staff(_candidate(), {}, 50000, _words()))


func test_hiring_says_how_many_yen_short() -> void:
	assert_eq(Ledger.staff_hire_refusal(_candidate(), {}, 40000, _words()), "10000 short.")


func test_a_filled_role_cannot_be_hired_into_again() -> void:
	var hired := {"staff_id": "SF03", "tier": 0}
	assert_eq(Ledger.staff_hire_refusal(_candidate(), hired, 999999, _words()), "Already yours.")


func test_the_first_upgrade_step_is_the_hiring_tier() -> void:
	assert_eq(Ledger.staff_upgrade_cost(_candidate(), 0), 30000)
	assert_eq(Ledger.staff_upgrade_cost(_candidate(), 1), 50000)


func test_a_candidate_at_their_highest_tier_has_no_further_step() -> void:
	assert_eq(Ledger.staff_upgrade_cost(_candidate(), 2), null)
	assert_eq(Ledger.staff_upgrade_refusal(_candidate(), 2, 999999, _words()),
		"At their highest tier.")


func test_a_candidate_who_starts_above_tier_zero_has_no_0_to_1_step() -> void:
	# SF05's own shape: starting_tier 1, highest_tier 1, and a null
	# upgrade_cost_0_to_1_yen because tier 0 was never sold for them.
	var sf05 := _candidate({
		"staff_id": "SF05", "starting_tier": 1, "highest_tier": 1,
		"upgrade_cost_0_to_1_yen": null, "upgrade_cost_1_to_2_yen": null,
	})
	assert_eq(Ledger.staff_upgrade_cost(sf05, 1), null,
		"already at their only tier — nothing left to buy")


func test_an_upgrade_you_cannot_afford_says_how_short_you_are() -> void:
	assert_eq(Ledger.staff_upgrade_refusal(_candidate(), 0, 10000, _words()), "20000 short.")


func test_an_affordable_upgrade_is_allowed() -> void:
	assert_true(Ledger.can_upgrade_staff(_candidate(), 0, 30000, _words()))
