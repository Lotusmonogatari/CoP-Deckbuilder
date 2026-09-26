@tool
class_name PartyVoteBar
extends Control
## The vote outcome for National Assembly Floor Voting (ST23) — one coloured
## segment per party, sized by how many of its votes landed in the bucket
## this bar is showing, the same "proportional blocks, always full" idea
## SupportBar.gd already uses for a floor debate's seats.
##
## Three of these side by side (Yes / No / Abstain) is the whole vote
## outcome: which parties are in each column, and how big their share of it
## is, at a glance.

const HEIGHT := 40.0

var _segments: Array[Dictionary] = []   ## { "color": Color, "votes": int, "label": String }


func _ready() -> void:
	custom_minimum_size.y = HEIGHT


## `segments` = [{ "color": Color, "votes": int, "label": String }, ...],
## one per party that holds any votes in this bucket. A party with zero
## votes here is simply left out — nothing to draw and nothing to hover.
func show_segments(segments: Array[Dictionary]) -> void:
	_segments = segments
	queue_redraw()


func _draw() -> void:
	var width := size.x
	var total := 0
	for segment: Dictionary in _segments:
		total += int(segment.get("votes", 0))
	if width <= 0.0 or total <= 0:
		draw_rect(Rect2(0, 0, width, HEIGHT), Color(0.28, 0.30, 0.36))
		return

	var scale_x := width / float(total)
	var x := 0.0
	for segment: Dictionary in _segments:
		var votes := int(segment.get("votes", 0))
		if votes <= 0:
			continue
		var segment_width := float(votes) * scale_x
		draw_rect(Rect2(x, 0, segment_width, HEIGHT), segment.get("color", Color.GRAY))
		x += segment_width
