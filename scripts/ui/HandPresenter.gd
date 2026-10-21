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

## A card lifted off the hand / put back without being played.
signal card_lifted(card_id: String)
signal card_dropped(card_id: String)

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

	# Every view this hand had is a candidate for reuse. The ones it still
	# wants stay ON the row; only new cards are added and gone ones removed,
	# then the row is put in hand order. (2026-10-11, performance pass: this
	# used to take every card off the row and put it back on each redraw,
	# which by itself was about 12 ms of a 15 ms redraw — re-entering the tree
	# is the expensive part, not filling the card in.)
	var spare := _views.duplicate(true)
	var ordered: Array[CardView] = []

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
			view.lifted.connect(func(id: String) -> void: card_lifted.emit(id))
			view.dropped.connect(func(id: String) -> void: card_dropped.emit(id))

		# On screen first, then filled in. A CardView builds its labels when
		# it enters the tree, and filling it before that means building them
		# twice over — which is how a hand of nameless cards happened once.
		if view.get_parent() != _row:
			_row.add_child(view)
		ordered.append(view)

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
		view.set_affordable(cost <= state.energy and not state.is_over()
			and str(effect.get("play_block", "")).is_empty())
		view.set_useless_here(bool(effect.get("does_nothing", false)))

	# Whatever this hand did not want.
	for leftover: Array in spare.values():
		for view: CardView in leftover:
			if view.get_parent() == _row:
				_row.remove_child(view)
			view.queue_free()

	# In hand order, moving only the views that are out of place.
	for index in ordered.size():
		if ordered[index].get_index() != index:
			_row.move_child(ordered[index], index)


## Marks the one selected card (or none, with "").
func select_only(card_id: String) -> void:
	for id: String in _views:
		for view: CardView in _views[id]:
			view.selected = (id == card_id and not card_id.is_empty())


## Marks the cards chosen to be discarded for `played_id`, and dims that card
## while the player chooses. An ID held twice marks only as many copies as were
## chosen. `picks` empty and `played_id` "" clears everything.
func set_picks(played_id: String, picks: Array) -> void:
	var wanted := {}
	for id: Variant in picks:
		wanted[str(id)] = int(wanted.get(str(id), 0)) + 1
	var played_dimmed := false
	for id: String in _views:
		var left := int(wanted.get(id, 0))
		for view: CardView in _views[id]:
			if id == played_id and not played_dimmed:
				played_dimmed = true
				view.picked = false
				view.modulate = Color(1, 1, 1, 0.55)
				continue
			view.picked = left > 0
			if left > 0:
				left -= 1


## The view showing this card, if it is on screen. What an animation reaches
## for. Null when the card has already left the hand.
func view_for(card_id: String) -> CardView:
	var held: Array = _views.get(card_id, [])
	return held[0] if not held.is_empty() else null


## Takes a reusable view for this card out of the spare pile, or null.
func _take(spare: Dictionary, card_id: String) -> CardView:
	var held: Array = spare.get(card_id, [])
	if held.is_empty():
		return null
	var view: CardView = held.pop_front()
	if held.is_empty():
		spare.erase(card_id)
	return view
