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
## A card was pressed, and let go (whatever the press turned into: a tap, a lift, or a slide off the card).
signal card_pressed(card_id: String)
signal card_released(card_id: String)

## The gap between cards when they all fit side by side (the scene's own 16).
const HAND_GAP := 16
## A hand that would overlap by up to this many pixels more than the chosen share still fits the row without
## scrolling (four cards need about 5 px more than a third).
const FIT_SLACK := 12.0

var _row: HBoxContainer
var _scroll: ScrollContainer

## Where a held card plays: a Callable returning a screen y (the bottom of the battle bar). Given to every card.
var play_line := Callable()

## card_id -> CardView currently on screen. A card ID can appear twice in a
## hand, so the views are held as a list per ID.
var _views: Dictionary = {}


func _init(row: HBoxContainer) -> void:
	_row = row
	_scroll = row.get_parent() as ScrollContainer
	# A sideways drag scrolls the hand; an upward one lifts a card (CardView).
	if _scroll != null:
		DragScroll.attach(_scroll, false)
		# The scroll bar sits above the cards, in gold (2026-11-05).
		HandScrollBar.attach(_scroll)


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
			# A touched card rises over its neighbours so its whole face and name can be read
			# (review of P9, finding 3: the overlapped cards showed only a few letters of their names).
			view.button_down.connect(_raise.bind(view))
			view.button_up.connect(_settle.bind(view))
			view.button_down.connect(func() -> void: card_pressed.emit(view.card_id))
			view.button_up.connect(func() -> void: card_released.emit(view.card_id))
			view.dropped.connect(func(id: String) -> void: card_dropped.emit(id))

		# On screen first, then filled in. A CardView builds its labels when
		# it enters the tree, and filling it before that means building them
		# twice over — which is how a hand of nameless cards happened once.
		if view.get_parent() != _row:
			_row.add_child(view)
		view.play_line = play_line
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
	_fit_overlap()


## How far a touched card rises, in base pixels.
const RAISE := 44.0


func _raise(view: Control) -> void:
	view.z_index = 4
	view.position.y = -RAISE


func _settle(view: Control) -> void:
	# Starting a drag releases the press (CardView._lift), which lands here: a held card keeps its place on
	# top of its neighbours until it is dropped.
	if view is CardView and (view as CardView).is_lifted():
		return
	view.z_index = 2 if bool(view.get("selected")) else 0
	view.position.y = 0.0


## The hand's cards overlap only by their last third (Balance "Hand: Card Overlap Percent", Cameron,
## 2026-11-19), so each card shows its left two thirds: its cost, name, picture and most of its effect.
## Cards keep their size. A hand that fits with no more overlap than that is spread to fit the row (3 or 4
## cards); a bigger hand keeps the one-third overlap and the row scrolls sideways (the gold bar above the
## hand, or a finger drag), the way it did before the P9 change that squeezed every card on screen. The later
## cards lie over the earlier ones.
func _fit_overlap() -> void:
	if _scroll == null:
		return
	if not _scroll.resized.is_connected(_fit_overlap):
		_scroll.resized.connect(_fit_overlap)
	var count := _row.get_child_count()
	var gap := HAND_GAP
	var available := _scroll.size.x
	if count >= 2 and available > 0.0:
		var natural := float(count) * CardView.WIDTH + float(count - 1) * HAND_GAP
		if natural > available:
			var fit_gap := (available - float(count) * CardView.WIDTH) / float(count - 1)
			var chosen_gap := -CardView.WIDTH * float(Levers.whole("hand_card_overlap_percent")) / 100.0
			# Spread to fit when that overlaps no more than the chosen share (a few pixels over is not worth a
			# scroll); otherwise keep the chosen share and scroll.
			gap = int(floor(fit_gap)) if fit_gap >= chosen_gap - FIT_SLACK else int(round(chosen_gap))
	_row.add_theme_constant_override("separation", gap)
	_fan(count)


## Living Office draws the hand as a fan (P9, 2026-11-17): each card tilts a little about its bottom
## centre, the outer cards most. The look only: positions, sizes and every tap are the same. Other
## styles keep the cards upright (and this resets any tilt left by a switch).
func _fan(_count: int) -> void:
	if not _row.sort_children.is_connected(_apply_tilts):
		# A container sets its children's rotation back to zero every time it sorts them, so the tilt
		# is applied again after each sort.
		_row.sort_children.connect(_apply_tilts)
	_apply_tilts()


func _apply_tilts() -> void:
	var count := _row.get_child_count()
	var fanned := UiStyle.current() == UiStyles.LIVING_OFFICE and count >= 2
	if _scroll != null:
		# A tilted or raised card may reach past the scroll box: let it show rather than be clipped. Cards
		# scrolled past the row's edge then run on to the screen's edge, which reads as "more this way".
		_scroll.clip_contents = false
	var step := minf(2.5, 8.0 / float(maxi(count - 1, 1)))
	for index in count:
		var view := _row.get_child(index) as Control
		if view == null:
			continue
		if not fanned:
			view.rotation_degrees = 0.0
			continue
		view.pivot_offset = Vector2(view.size.x * 0.5, view.size.y)
		view.rotation_degrees = (float(index) - float(count - 1) * 0.5) * step


## True while any card is held off the hand (being dragged).
func any_lifted() -> bool:
	for id: String in _views:
		for view: CardView in _views[id]:
			if view.is_lifted():
				return true
	return false


## Marks the one selected card (or none, with "").
func select_only(card_id: String) -> void:
	for id: String in _views:
		for view: CardView in _views[id]:
			view.selected = (id == card_id and not card_id.is_empty())
			# A raised card lies over its overlapping neighbours.
			view.z_index = 2 if view.selected else 0
	# A card selected while part of it is past the edge scrolls into view, so its Read button can be pressed.
	if not card_id.is_empty() and _scroll != null:
		_reveal.call_deferred(card_id)


func _reveal(card_id: String) -> void:
	if _scroll == null or not _views.has(card_id):
		return
	for view: CardView in _views[card_id]:
		if view.selected and view.is_inside_tree():
			_scroll.ensure_control_visible(view)
			return


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
	# While choosing discards every other card can be picked, playable or not
	# (2026-10-23, Cameron's playtest): a discard costs nothing, so a card the
	# player cannot afford this turn is still a fair one to throw away.
	if not played_id.is_empty():
		for id: String in _views:
			for view: CardView in _views[id]:
				view.disabled = false


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
