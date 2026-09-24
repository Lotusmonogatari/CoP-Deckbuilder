class_name IntentRunner
extends RefCounted
## Decides what the opponent does each turn.
##
## Opponents don't play cards — they follow a fixed list of moves that
## repeats. It's readable for the player (the next move is always shown a turn
## ahead), predictable for balancing, and simple to write down.
##
## A pattern is a list of moves. A move is a verb and either one number or a
## range to roll between:
##
##     [["attack", 4], ["gain", 0, 1], ["block", 3, 5]]
##
## That opponent attacks for exactly 4, then gains nothing or 1, then guards
## somewhere between 3 and 5, then starts again. Ranges are INCLUSIVE at both
## ends and rolled evenly.
##
## THE VERBS
##   attack     lowers the player's support by the number, minus any block
##   gain       raises the opponent's own support
##   block      the opponent gains guard, reducing the player's next attack
##
## THE ZERO RULE
## A move that comes out at zero is NOT TAKEN. The opponent steps to the next
## move in the cycle and does that instead, so nobody ever spends a turn
## guarding nothing. An opponent whose pattern ends in a flat "block 0" simply
## never guards: they only ever attack or gain.
##
## WHEN THE ROLL HAPPENS, and why it matters
## At peek, once, and it is then held. Two reasons, both of them correctness
## rather than speed:
##
##   - The screen repaints several times a turn and calls peek() each time.
##     Rolling inside peek() without holding the result would re-roll the
##     opponent's intent on every repaint.
##   - Skipping a zero CHANGES THE VERB. If the skip happened when the move
##     resolved, the screen could announce "Guarding" and the opponent could
##     attack instead. Doing it at peek time means the verb the player is
##     shown is always the verb that happens.

## Every verb this understands. A pattern using anything else is rejected at
## setup with a readable message rather than doing nothing mid-battle.
const KNOWN_VERBS := ["attack", "gain", "block"]

var _pattern: Array = []
var _position := 0

## Where the numbers come from. Handed in rather than made here, so the whole
## battle runs off one seeded generator and a test can post a fixed answer —
## the same arrangement BarModel uses for what a stubborn vote costs. A runner
## built without one rolls for itself: a missing roller must never quietly
## turn the rule off and leave every range playing as its lowest value.
var _roller: Callable

## The resolved move for the current position, and where in the pattern it
## actually landed after any zeros were stepped over. Empty until peeked.
var _pending: Dictionary = {}
var _pending_index := 0

## The same, one move further on: what C12 Head Count reveals. Held rather
## than re-rolled, or the card would show a move that never happens.
var _ahead: Dictionary = {}
var _ahead_index := 0


## `pattern` is the opponent's intent_pattern.
func _init(pattern: Variant = [], roller: Callable = Callable()) -> void:
	if pattern is Array:
		_pattern = (pattern as Array).duplicate(true)
	_roller = roller


## True when there is a usable pattern. A battle should not start without one.
func is_valid() -> bool:
	return not _pattern.is_empty() and problems().is_empty()


## Everything wrong with this pattern, in plain words. Empty when it's fine.
func problems() -> PackedStringArray:
	var found := PackedStringArray()
	if _pattern.is_empty():
		found.append("the opponent has no intent pattern, so it cannot take a turn")
		return found

	var anything_can_happen := false

	for index in _pattern.size():
		var move: Variant = _pattern[index]
		if not (move is Array) or (move as Array).size() < 2:
			found.append("move %d should be a verb and a number, such as [\"attack\", 6]" % (index + 1))
			continue

		var parts: Array = move
		var verb := str(parts[0])
		if not KNOWN_VERBS.has(verb):
			found.append("move %d uses '%s', which is not one of %s" % [index + 1, verb, KNOWN_VERBS])

		# The largest this move could ever be. A move that can only come out
		# at zero is never taken, which is fine on its own — but a pattern
		# made entirely of them would leave the opponent standing there.
		var biggest := int(parts[1])
		if parts.size() >= 3:
			biggest = maxi(int(parts[1]), int(parts[2]))
		if biggest > 0:
			anything_can_happen = true

	if not anything_can_happen:
		found.append("every move in this pattern is worth nothing, so the opponent would never act")
	return found


## The move that is coming next, without using it up. This is what the UI
## shows the player at the top of the turn.
func peek() -> Dictionary:
	if _pending.is_empty():
		var found := _resolve_from(_position)
		_pending = found["move"]
		_pending_index = int(found["index"])
	return _pending


## The move after next. Only revealed by a card that says it does so
## (C12 Head Count).
func peek_ahead() -> Dictionary:
	# The current move has to be settled first: where it lands is where the
	# one after it starts from, once any zeros have been stepped over.
	peek()
	if _ahead.is_empty():
		var found := _resolve_from(_pending_index + 1)
		_ahead = found["move"]
		_ahead_index = int(found["index"])
	return _ahead


## Takes the next move and steps the pattern on, wrapping at the end.
func advance() -> Dictionary:
	var move := peek()
	_position = _next_after(_pending_index)

	# Whatever Head Count already revealed becomes the next move rather than
	# being thrown away and rolled again, or the card would have lied.
	if _ahead.is_empty():
		_pending = {}
	else:
		_pending = _ahead
		_pending_index = _ahead_index
	_ahead = {}

	return move


## How far through the pattern we are. Saved with the game so reloading
## mid-battle doesn't reset the opponent's rhythm.
func position() -> int:
	return _position


func set_position(value: int) -> void:
	_position = 0 if _pattern.is_empty() else posmod(value, _pattern.size())
	# A held roll belongs to the position it was rolled for.
	_pending = {}
	_ahead = {}


## Finds the next move worth making, starting at `index` and stepping past any
## that come out at zero.
##
## Bounded to one lap of the pattern. If every move came out at zero this
## would otherwise spin forever — none of the patterns in the game can do
## that, and the bound is what keeps it safe to add more.
func _resolve_from(index: int) -> Dictionary:
	if _pattern.is_empty():
		return {"move": _waiting(), "index": index}

	for step in _pattern.size():
		var at := posmod(index + step, _pattern.size())
		var move := _roll(_pattern[at])
		if int(move.get("value", 0)) != 0:
			return {"move": move, "index": at}

	return {"move": _waiting(), "index": posmod(index, _pattern.size())}


## Turns one written move into one that has happened.
func _roll(raw: Variant) -> Dictionary:
	if not (raw is Array) or (raw as Array).size() < 2:
		return _waiting()

	var parts: Array = raw
	var verb := str(parts[0])
	var low := int(parts[1])

	if parts.size() < 3:
		return {"verb": verb, "value": low}

	var high := int(parts[2])
	if high < low:
		var swap := low
		low = high
		high = swap

	# min and max ride along so the screen can say what was possible. They are
	# only here on a move that HAS a range: a fixed move keeps the plain shape
	# it has always had.
	return {
		"verb": verb,
		"value": _between(low, high),
		"min": low,
		"max": high,
	}


func _between(low: int, high: int) -> int:
	if high <= low:
		return low
	if _roller.is_valid():
		return int(_roller.call(low, high))
	return randi_range(low, high)


func _next_after(index: int) -> int:
	return posmod(index + 1, maxi(_pattern.size(), 1))


func _waiting() -> Dictionary:
	return {"verb": "none", "value": 0}


## The move written the way the player reads it: "Attacking · −6", or
## "Attacking · −1 to −6" where it could be anything in a range.
##
## THE RANGE SHOWN IS THE RANGE AFTER THE ZERO RULE. A "block 0 to 2" can
## never actually come out at 0 — a zero would have been stepped over and
## something else shown instead — so advertising "0 to 2" would promise an
## outcome that cannot happen.
##
## The wording comes from the workbook's Text tab, handed in the way the rest
## of the rules receive theirs. The signs and the numbers stay here: those are
## arithmetic, not prose.
static func describe(move: Dictionary, words: Phrase = null) -> String:
	var say := words if words != null else Phrase.new()
	var verb := str(move.get("verb", "none"))
	if verb == "none":
		return say.say("intent.waiting")

	var shape := _shape_of(move)

	match verb:
		"attack": return say.say("intent.attacking", {"amount": _signed(shape, "−", say)})
		"gain": return say.say("intent.gaining", {"amount": _signed(shape, "+", say)})
		"block": return say.say("intent.guarding", {"amount": _plain(shape, say)})
		_: return say.say("intent.waiting")


## What this move could come out as: one number, or a low and a high.
static func _shape_of(move: Dictionary) -> Array:
	if not move.has("min") or not move.has("max"):
		return [int(move.get("value", 0))]

	# Never below 1: see describe().
	var low := maxi(int(move["min"]), 1)
	var high := int(move["max"])
	if high <= low:
		return [high if high > 0 else low]
	return [low, high]


static func _signed(shape: Array, sign_text: String, say: Phrase) -> String:
	if shape.size() == 1:
		return "%s%d" % [sign_text, shape[0]]
	return say.say("intent.range", {
		"low": "%s%d" % [sign_text, shape[0]],
		"high": "%s%d" % [sign_text, shape[1]],
	})


static func _plain(shape: Array, say: Phrase) -> String:
	if shape.size() == 1:
		return str(shape[0])
	return say.say("intent.range", {"low": shape[0], "high": shape[1]})
