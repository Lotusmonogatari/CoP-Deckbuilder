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


func _ready() -> void:
	custom_minimum_size.y = HEIGHT + 60.0
	_refresh()


## Takes the numbers straight off a running battle.
func show_bar(bar: BarModel, threshold_applies: bool = true) -> void:
	maximum = bar.maximum
	threshold = bar.threshold
	player = bar.player
	opponent = bar.opponent
	has_threshold = threshold_applies
	_refresh()


func _refresh() -> void:
	queue_redraw()
	if _caption == null:
		return

	if has_threshold:
		_caption.text = "%d %s to win" % [threshold, unit.to_lower()]
	else:
		_caption.text = "Raise %s as high as you can" % unit.to_lower()

	var undecided := maxi(maximum - player - opponent, 0)
	if undecided > 0:
		_readout.text = "You %d · Undecided %d · Them %d" % [player, undecided, opponent]
	else:
		_readout.text = "You %d · Them %d" % [player, opponent]


func _draw() -> void:
	var width := size.x
	if width <= 0.0:
		return

	var top := 30.0
	var scale_x := width / float(maximum)

	# Three blocks, left to right: yours, undecided, theirs. Drawing them in
	# that order means the player's share always grows from the same edge.
	var player_width := float(player) * scale_x
	var opponent_width := float(opponent) * scale_x

	draw_rect(Rect2(0, top, width, HEIGHT), UNDECIDED_COLOR)
	draw_rect(Rect2(0, top, player_width, HEIGHT), PLAYER_COLOR)
	draw_rect(Rect2(width - opponent_width, top, opponent_width, HEIGHT), OPPONENT_COLOR)

	# The threshold. Drawn last so nothing covers it, and not at all when
	# there is nothing to reach.
	if has_threshold:
		var line_x := float(threshold) * scale_x
		draw_line(Vector2(line_x, top - 8.0), Vector2(line_x, top + HEIGHT + 8.0),
			THRESHOLD_COLOR, 3.0)
