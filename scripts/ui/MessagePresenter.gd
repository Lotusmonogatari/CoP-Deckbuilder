class_name MessagePresenter
extends RefCounted
## What the screen says to you in passing, one thing at a time.
##
## A card lands, the opponent answers, a bout is won: three things worth a
## sentence can happen inside one turn, and a single label can only hold one
## of them. This queues them so each is shown for long enough to read and
## none is cut short by the next.
##
## THE BUG THIS EXISTS FOR
## It used to be one function that set the label, awaited two and a half
## seconds, and then hid it. Play a card and end the turn — which is every
## turn — and the card's timer fired while the opponent's sentence was still
## on screen and blanked it. The player saw half of what happened.
##
## Two rules keep that from coming back:
##   - A message never cuts short the one before it. It waits its turn.
##   - A timer only hides the message it was started for. A stale timer
##     finds its message already replaced and does nothing.
##
## It is a RefCounted rather than a Node because it owns no nodes of its own
## — it drives a Label the screen already has, and borrows the scene tree for
## its timers.

## How long one message stays up, by default. Long enough to read a sentence,
## short enough not to sit over the hand.
const DWELL_SECONDS := 2.5

## The dwell this presenter is actually using. Separate from the constant so
## it can be changed: the tests wind it down so the suite does not spend ten
## seconds watching a label, and a reading-speed setting would turn it up.
var dwell_seconds := DWELL_SECONDS

## Where to draw, and whose tree to take timers from.
var _label: Label
var _tree: SceneTree

## Sentences still waiting to be read.
var _queue: PackedStringArray = []

## Counts up every time a message is shown. A timer captures the number it
## was started for and gives up if it has moved on since — which is what
## stops a stale timer hiding a live message.
var _shown := 0

## True while a message is up and its timer is still running.
var _busy := false


func _init(label: Label, tree: SceneTree) -> void:
	_label = label
	_tree = tree
	if _label != null:
		_label.hide()


## Says something, after whatever is already being said.
func say(message: String) -> void:
	if _label == null or message.strip_edges().is_empty():
		return
	_queue.append(message)
	if not _busy:
		_show_next()


## Drops anything waiting and clears the screen.
##
## Used when a battle ends or a new one starts: a sentence about the last
## stage has no business appearing over the first turn of the next.
func clear() -> void:
	_queue = PackedStringArray()
	_busy = false
	_shown += 1        # anything still counting down is now stale
	if _label != null:
		_label.hide()


## True when there is something on screen. The tests read this.
func is_saying_something() -> bool:
	return _label != null and _label.visible


func _show_next() -> void:
	if _queue.is_empty():
		_busy = false
		if _label != null:
			_label.hide()
		return

	_busy = true
	_shown += 1
	var mine := _shown

	_label.text = _queue[0]
	_queue.remove_at(0)
	_label.show()

	if _tree == null:
		return
	await _tree.create_timer(dwell_seconds).timeout

	# Somebody else has spoken since this timer started, so this one has
	# nothing left to hide. Without this check the older timer blanks the
	# newer message, which is exactly what used to happen every turn.
	if mine != _shown:
		return
	_show_next()
