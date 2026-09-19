class_name IntentRunner
extends RefCounted
## Decides what the opponent does each turn.
##
## For the first playable version, opponents don't play cards — they follow a
## fixed list of moves that repeats. It's readable for the player (the next
## move is always shown a turn ahead), predictable for balancing, and simple
## to write down in the workbook.
##
## A pattern is a list of moves, each a verb and a number:
##
##     [["attack", 6], ["gain", 4], ["block", 5]]
##
## That opponent attacks for 6, then gains 4, then blocks 5, then attacks for
## 6 again, and so on for as long as the stage lasts.
##
## THE VERBS
##   attack     lowers the player's support by the number, minus any block
##   gain       raises the opponent's own support
##   block      the opponent gains guard, reducing the player's next attack
##   lean_down  committee stages only: pushes one member away from For
##
## NOTE: no opponent in the workbook has a pattern yet, so no battle can run
## on real data. Proposed patterns for all nine are in design/proposals/.

## Every verb this understands. A pattern using anything else is rejected at
## setup with a readable message rather than doing nothing mid-battle.
const KNOWN_VERBS := ["attack", "gain", "block", "lean_down"]

var _pattern: Array = []
var _position := 0


## `pattern` is the opponent's intent_pattern from opponents.json.
func _init(pattern: Variant = []) -> void:
	if pattern is Array:
		_pattern = (pattern as Array).duplicate(true)


## True when there is a usable pattern. A battle should not start without one.
func is_valid() -> bool:
	return not _pattern.is_empty() and problems().is_empty()


## Everything wrong with this pattern, in plain words. Empty when it's fine.
func problems() -> PackedStringArray:
	var found := PackedStringArray()
	if _pattern.is_empty():
		found.append("the opponent has no intent pattern, so it cannot take a turn")
		return found

	for index in _pattern.size():
		var move: Variant = _pattern[index]
		if not (move is Array) or (move as Array).size() < 2:
			found.append("move %d should be a verb and a number, such as [\"attack\", 6]" % (index + 1))
			continue
		var verb := str((move as Array)[0])
		if not KNOWN_VERBS.has(verb):
			found.append("move %d uses '%s', which is not one of %s" % [index + 1, verb, KNOWN_VERBS])
	return found


## The move that is coming next, without using it up. This is what the UI
## shows the player at the top of the turn.
func peek() -> Dictionary:
	return _move_at(_position)


## The move after next. Only revealed by a card that says it does so
## (C12 Head Count).
func peek_ahead() -> Dictionary:
	return _move_at(_position + 1)


## Takes the next move and steps the pattern on, wrapping at the end.
func advance() -> Dictionary:
	var move := _move_at(_position)
	_position = (_position + 1) % maxi(_pattern.size(), 1)
	return move


## How far through the pattern we are. Saved with the game so reloading
## mid-battle doesn't reset the opponent's rhythm.
func position() -> int:
	return _position


func set_position(value: int) -> void:
	_position = 0 if _pattern.is_empty() else posmod(value, _pattern.size())


func _move_at(index: int) -> Dictionary:
	if _pattern.is_empty():
		return {"verb": "none", "value": 0}
	var move: Array = _pattern[index % _pattern.size()]
	return {"verb": str(move[0]), "value": int(move[1])}


## The move written the way the player reads it: "Attacking · −6".
static func describe(move: Dictionary) -> String:
	var value := int(move.get("value", 0))
	match str(move.get("verb", "none")):
		"attack": return "Attacking · −%d" % value
		"gain": return "Gaining · +%d" % value
		"block": return "Defending · %d" % value
		"lean_down": return "Pressuring · −%d" % value
		_: return "Waiting"
