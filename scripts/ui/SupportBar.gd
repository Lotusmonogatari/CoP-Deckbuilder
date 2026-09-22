@tool
class_name SupportBar
extends Control
## The win-condition bar at the top of a battle.
##
## In a floor debate this is 101 seats, split three ways: yours, your
## opponent's, and the ones still undecided. The three always add up to the
## whole house, so the bar is always full — what changes is who holds what.
##
## A line marks the threshold, because "am I winning" should be answerable at
## a glance without reading a number.

## Redrawn whenever these change, so callers just set them.
@export var maximum: int = 101: set = _set_maximum
@export var player: int = 40: set = _set_player
@export var opponent: int = 40: set = _set_opponent
@export var threshold: int = 51: set = _set_threshold

## "Seats" or "Support" — whatever the stage measures in.
@export var unit: String = "Seats": set = _set_unit

## False in a stage with no threshold to reach, such as the caucus. Both the
## line and the "X to win" caption are hidden, because there is no number to
## reach and showing one would be a lie.
@export var has_threshold: bool = true: set = _set_has_threshold

## False when the bar measures one thing rather than a contest over a fixed
## house — press tone, for instance. There is no opposing share and nothing
## undecided, so neither is drawn or named.
@export var two_sided: bool = true: set = _set_two_sided

## Who holds the other share. The bar used to call them "Them" even when the
## stage data named them, which is exactly what Cameron asked to stop: a
## named character should be named. Falls back to "Them" when there is no
## name, and to a short form when the name is long enough to break the row.
@export var opponent_name: String = "": set = _set_opponent_name

## True where the bar should be read as a percentage rather than a headcount.
## The caucus is already a 0-100 scale, so this is a label rather than any
## kind of conversion: it stops the player counting heads in a body whose
## size changes from one party to the next.
@export var as_percent: bool = false: set = _set_as_percent

## False when beating this threshold finishes the person in front of you
## rather than the stage. On the floor five debaters rise one after another,
## and "55 seats to win" read as though the first one ended it.
@export var threshold_wins_stage: bool = true: set = _set_threshold_wins_stage

## How long a name can be before the readout falls back to "Them". The
## readout is three columns on a phone; a name of sentence length pushes the
## numbers off the row.
const NAME_LIMIT := 18

const HEIGHT := 56.0
const CORNER := 8.0

# Muted, and distinguishable without relying on colour alone: the player's
# share is always leftmost and the threshold line is a hard edge.
const PLAYER_COLOR := Color(0.36, 0.62, 0.85)
const UNDECIDED_COLOR := Color(0.28, 0.30, 0.36)
const OPPONENT_COLOR := Color(0.78, 0.42, 0.40)
const THRESHOLD_COLOR := Color(1, 1, 1, 0.85)

@onready var _caption: Label = $Caption
@onready var _readout: Label = $Readout


func _set_opponent_name(value: String) -> void:
	opponent_name = value
	_refresh()


func _set_as_percent(value: bool) -> void:
	as_percent = value
	_refresh()


func _set_threshold_wins_stage(value: bool) -> void:
	threshold_wins_stage = value
	_refresh()


func _set_maximum(value: int) -> void:
	maximum = maxi(value, 1)
	_refresh()


func _set_player(value: int) -> void:
	player = value
	_refresh()


func _set_opponent(value: int) -> void:
	opponent = value
	_refresh()


func _set_threshold(value: int) -> void:
	threshold = value
	_refresh()


func _set_unit(value: String) -> void:
	unit = value
	_refresh()


func _set_has_threshold(value: bool) -> void:
	has_threshold = value
	_refresh()


func _set_two_sided(value: bool) -> void:
	two_sided = value
	_refresh()


func _ready() -> void:
	custom_minimum_size.y = HEIGHT + 84.0
	_refresh()


## Takes the numbers straight off a running battle.
func show_bar(bar: BarModel, threshold_applies: bool = true,
		who: String = "", percent: bool = false, wins_stage: bool = true) -> void:
	maximum = bar.maximum
	threshold = bar.threshold
	player = bar.player
	opponent = bar.opponent
	has_threshold = threshold_applies
	opponent_name = who
	as_percent = percent
	threshold_wins_stage = wins_stage
	# Only a shared pool has two sides to it. A press tone or a TV debate is
	# one reading, with nobody holding the rest.
	two_sided = bar.model == BarModel.Model.SHARED_POOL
	_refresh()


func _refresh() -> void:
	queue_redraw()
	if _caption == null:
		return

	if has_threshold:
		# "To win" only where winning here wins the stage. On the floor the
		# threshold ends ONE debater and the next rises, so a player told
		# "55 seats to win" reasonably expects the stage to be over.
		var key := "bar.to_win" if threshold_wins_stage else "bar.to_advance"
		_caption.text = Text.say(key, {"amount": _amount(threshold)})
	elif as_percent:
		_caption.text = Text.say("bar.take_the_room")
	else:
		_caption.text = Text.say("bar.raise_as_high", {"unit": unit.to_lower()})

	if not two_sided:
		_readout.text = Text.say("bar.one_sided",
			{"unit": unit, "count": player, "total": maximum})
		return

	var undecided := maxi(maximum - player - opponent, 0)
	_readout.text = Text.say("bar.two_sided", {
		"you": _amount(player),
		"undecided": _amount(undecided),
		"them": _other_side(),
		"theirs": _amount(opponent),
	})


## A number with its unit, where the unit is worth showing. On a percentage
## bar every figure carries its sign, because "43" and "43%" are read as
## different sizes of thing.
func _amount(value: int) -> String:
	if as_percent:
		return "%d%%" % value
	return str(value)


## What to call whoever holds the other share.
func _other_side() -> String:
	var name := opponent_name.strip_edges()
	if name.is_empty():
		return Text.say("bar.them")
	# A name too long for the row falls back to "Them" rather than being
	# shortened. Taking the first word turned "The Caucus Panel" into "The",
	# which is worse than the generic word it was meant to improve on.
	return name if name.length() <= NAME_LIMIT else Text.say("bar.them")


func _draw() -> void:
	var width := size.x
	if width <= 0.0:
		return

	# Below the caption, which sits on the line above it.
	var top := 44.0
	var scale_x := width / float(maximum)

	# Three blocks, left to right: yours, undecided, theirs. Drawing them in
	# that order means the player's share always grows from the same edge.
	var player_width := float(player) * scale_x
	var opponent_width := float(opponent) * scale_x

	draw_rect(Rect2(0, top, width, HEIGHT), UNDECIDED_COLOR)
	draw_rect(Rect2(0, top, player_width, HEIGHT), PLAYER_COLOR)
	if two_sided:
		draw_rect(Rect2(width - opponent_width, top, opponent_width, HEIGHT),
			OPPONENT_COLOR)

	# The threshold. Drawn last so nothing covers it, and not at all when
	# there is nothing to reach.
	if has_threshold:
		var line_x := float(threshold) * scale_x
		draw_line(Vector2(line_x, top - 8.0), Vector2(line_x, top + HEIGHT + 8.0),
			THRESHOLD_COLOR, 3.0)
