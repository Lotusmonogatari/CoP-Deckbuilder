class_name HandPresenter
extends RefCounted
## The cards in your hand, and the one you have opened.
##
## Owns the hand row and the zoom panel. Takes the battle state in and draws
## it. Makes no rules decisions: whether a card is affordable, and what it
## would do in this room, are both answered by BattleEngine.
##
## THE CARD VIEWS ARE KEPT, NOT REBUILT.
## This used to free every card and construct five new ones on every refresh.
## It worked, but it makes everything that comes next impossible: a card that
## is destroyed and replaced cannot be animated as it is played, cannot be
## highlighted, cannot fly at the opponent, and cannot carry a text cue out
## of itself. Views are now matched to the hand by card ID and reused, so the
## node on screen is the same node from one turn to the next and there is
## something to animate.

## The player tapped a card. The screen decides what that means.
signal card_chosen(card_id: String)

## The player dragged a card up and let go: play it now.
signal card_flung(card_id: String)

var _row: HBoxContainer
var _scroll: ScrollContainer

## card_id -> CardView currently on screen. A card ID can appear twice in a
## hand, so the views are held as a list per ID.
var _views: Dictionary = {}


func _init(row: HBoxContainer) -> void:
	_row = row
	_scroll = row.get_parent() as ScrollContainer
	# A sideways drag scrolls the hand; an upward one lifts a card (CardView).
	if _scroll != null:
		DragScroll.attach(_scroll, false)


## Redraws the hand for this moment.
func show_state(engine: BattleEngine) -> void:
	var state := engine.state

	# Take every view off the row without freeing it, then put back the ones
	# this hand still wants. Anything left over at the end is genuinely gone.
	var spare := _views.duplicate(true)
	for child in _row.get_children():
		_row.remove_child(child)

	_views = {}
	for card_id: String in state.hand:
		var card := DataDB.get_card(card_id)
		if card.is_empty():
			continue

		var view := _take(spare, card_id)
		if view == null:
			view = CardView.new()
			view.chosen.connect(func(id: String) -> void: card_chosen.emit(id))
			view.flung.connect(func(id: String) -> void: card_flung.emit(id))

		# On screen first, then filled in. A CardView builds its labels when
		# it enters the tree, and filling it before that means building them
		# twice over — which is how a hand of nameless cards happened once.
		_row.add_child(view)

		# Written every refresh, on a reused view as well as a new one.
		# Keeping a view is about keeping the NODE alive so that a card can be
		# animated as it is played; it was never about skipping the labels. A
		# view filled in once and never again would quietly go on showing the
		# old numbers as soon as a card can be upgraded, which is M5.
		view.show_card(card)

		if not _views.has(card_id):
			_views[card_id] = []
		(_views[card_id] as Array).append(view)

		# What it will do HERE, not what it says on paper. The room moves the
		# numbers, and in some rooms a number does nothing at all.
		var effect := engine.preview(card)
		view.show_effect_here(effect)

		# The real cost, after any discount a card played earlier this turn
		# left behind. The same number decides the disc and the dimming, so
		# the card can no longer say "2" while being playable on 1 energy.
		var cost := engine.card_cost(card)
		view.show_cost(cost)
		view.set_affordable(cost <= state.energy and not state.is_over())
		view.set_useless_here(bool(effect.get("does_nothing", false)))

	# Whatever this hand did not want.
	for leftover: Array in spare.values():
		for view: CardView in leftover:
			view.queue_free()


## The view showing this card, if it is on screen. What an animation reaches
## for. Null when the card has already left the hand.
func view_for(card_id: String) -> CardView:
	var held: Array = _views.get(card_id, [])
	return held[0] if not held.is_empty() else null


## Scrolls a card into view. The hand is wider than the screen — only about
## three of five cards are visible — so anything that wants to point at a
## card has to be able to bring it into sight first.
func reveal(card_id: String) -> void:
	var view := view_for(card_id)
	if view != null and _scroll != null:
		_scroll.ensure_control_visible(view)


## Takes a reusable view for this card out of the spare pile, or null.
func _take(spare: Dictionary, card_id: String) -> CardView:
	var held: Array = spare.get(card_id, [])
	if held.is_empty():
		return null
	var view: CardView = held.pop_front()
	if held.is_empty():
		spare.erase(card_id)
	return view
