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
