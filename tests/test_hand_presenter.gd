extends GutTest
## The hand row, and the card views it keeps between refreshes.
##
## Card views are reused rather than rebuilt so that a card can be animated
## as it is played — a node that is destroyed every refresh cannot be. That
## reuse brings two risks, and both are tested here: a view that is kept must
## still be REWRITTEN every refresh, or it goes stale; and the cost it shows
## must be the cost the battle will actually charge.

const MODULE := "MOD01"
const FLOOR_DEBATE_STEP := 4
const SHUFFLE_SEED := 20260919

var _scroll: ScrollContainer
var _row: HBoxContainer
var _hand: HandPresenter
var _engine: BattleEngine


func before_each() -> void:
	# The real shape: HandPresenter finds its ScrollContainer by asking the
	# row for its parent, so the row cannot stand on its own.
	_scroll = ScrollContainer.new()
	_row = HBoxContainer.new()
	_scroll.add_child(_row)
	add_child_autofree(_scroll)

	var config := BattleSetup.for_module_step(MODULE, FLOOR_DEBATE_STEP)
	config["seed"] = SHUFFLE_SEED
	_engine = BattleEngine.new()
	assert_true(_engine.setup(config), "the battle starts")

	_hand = HandPresenter.new(_row)


func _first_card_id() -> String:
	return str(_engine.state.hand[0])


func test_the_hand_is_dealt_onto_the_row() -> void:
	_hand.show_state(_engine)
	assert_eq(_row.get_child_count(), _engine.state.hand.size(),
		"one card view per card in hand")


# ---------------------------------------------------------------------------
# Keeping the view
# ---------------------------------------------------------------------------

func test_a_card_view_survives_a_refresh() -> void:
	_hand.show_state(_engine)
	var before := _hand.view_for(_first_card_id())
	_hand.show_state(_engine)
	var after := _hand.view_for(_first_card_id())

	assert_eq(before, after,
		"the same node should still be there — a rebuilt card cannot be animated")


func test_a_kept_view_is_still_rewritten_every_refresh() -> void:
	# THE RISK THAT COMES WITH REUSE. A view that is filled in once and then
	# only ever kept would go on showing the old numbers as soon as the same
	# card ID can carry different data — which is what upgrading a card at
	# the XP checkpoint means.
	#
	# Standing in for that here by scribbling over the view directly, then
	# asking for a refresh: whatever it shows afterwards came from the data,
	# not from what was on it before.
	_hand.show_state(_engine)

	var card_id := _first_card_id()
	var view := _hand.view_for(card_id)
	var honest := view.tooltip_text

	view.show_card({"card_id": card_id, "name_en": "STALE", "effect_text": "STALE"})
	assert_string_contains(view.tooltip_text, "STALE", "the scribble took")

	_hand.show_state(_engine)
	assert_eq(view.tooltip_text, honest,
		"a reused view should be rewritten from the card, not left as it was")


# ---------------------------------------------------------------------------
# The cost it shows
# ---------------------------------------------------------------------------

func test_the_disc_shows_what_the_card_costs_now() -> void:
	# C36 makes the next card of the turn cost one less. The disc used to go
	# on showing the workbook's number, so the card read "2", cost 1, and lit
	# up as playable on a single point of energy.
	_engine.state.next_card_discount = 1
	_hand.show_state(_engine)

	var card_id := _first_card_id()
	var card := DataDB.get_card(card_id)
	var printed := int(card.get("cost", 0))
	if printed <= 0:
		return   # a free card has nothing to discount

	var view := _hand.view_for(card_id)
	# Reading the view's own label: this is the number on screen, which is
	# the whole point — asking the engine again would only test the engine.
	assert_eq(view._cost_label.text, str(_engine.card_cost(card)),
		"the disc should show the discounted cost")
	assert_ne(view._cost_label.text, str(printed),
		"and not the cost printed in the workbook")


func test_the_disc_and_the_dimming_agree() -> void:
	# The two used to be worked out from different numbers, which is how a
	# card could say "2" while being playable on one energy.
	_engine.state.next_card_discount = 1
	_engine.state.energy = 1
	_hand.show_state(_engine)

	for card_id: String in _engine.state.hand:
		var view := _hand.view_for(card_id)
		if view == null:
			continue
		var shown := int(view._cost_label.text)
		assert_eq(view.disabled, shown > 1,
			"%s shows %d, so it should be %s at one energy"
				% [card_id, shown, "dimmed" if shown > 1 else "playable"])


# ---------------------------------------------------------------------------
# Letting the view go
# ---------------------------------------------------------------------------

func test_a_card_that_has_left_the_hand_is_gone() -> void:
	_hand.show_state(_engine)
	var card_id := _first_card_id()

	_engine.state.hand.erase(card_id)
	_hand.show_state(_engine)

	assert_null(_hand.view_for(card_id),
		"a card no longer in hand should not still be on the row")
