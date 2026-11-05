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
	var bar := Rect2(0, 0, width, HEIGHT)
	var parts: Array = []
	for segment: Dictionary in _segments:
		var votes := int(segment.get("votes", 0))
		if votes > 0:
			parts.append([votes, segment.get("color", Color.GRAY)])
	if width <= 0.0:
		return
	# Nobody in this bucket: an empty track. Otherwise one part per party, on
	# the cue band's slant with its thin gold top and bottom (SlantBar).
	if parts.is_empty():
		parts = [[1, Color(0.28, 0.30, 0.36)]]
	SlantBar.draw_parts(self, bar, parts, 3.0)
