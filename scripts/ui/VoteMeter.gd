class_name VoteMeter
extends Control
## The whole house on a Floor Vote result (2026-10-15): Aye, Abstain and Nay
## blocks side by side, sized by seats (Aye green, Abstain white, Nay red --
## always, whatever the outcome), with each block's count printed over its
## own block and a mark where the Aye votes needed end.

const BAR_HEIGHT := 36.0
const LABEL_HEIGHT := 150.0
const HEIGHT := LABEL_HEIGHT + BAR_HEIGHT
const PASS_COLOUR := Color(0.25, 0.65, 0.35)
const FAIL_COLOUR := Color(0.78, 0.28, 0.25)
const AYE_COLOUR := Color(0.25, 0.65, 0.35)
const ABSTAIN_COLOUR := Color(1.0, 1.0, 1.0)
const NAY_COLOUR := Color(0.85, 0.25, 0.22)
const NUMBER_SIZE := 72
const CAPTION_SIZE := 28
const MIN_GAP := 150.0   ## keeps neighbouring counts from overlapping

var _aye := 0
var _nay := 0
var _abstain := 0
var _needed := 0


func _ready() -> void:
	custom_minimum_size.y = HEIGHT


func show_totals(aye: int, nay: int, abstain: int, needed: int) -> void:
	_aye = aye
	_nay = nay
	_abstain = abstain
	_needed = needed
	queue_redraw()


func _draw() -> void:
	var house := _aye + _nay + _abstain
	if house <= 0 or size.x <= 0.0:
		return
	var per_seat := size.x / float(house)
	var bar_top := LABEL_HEIGHT
	var x := 0.0
	var centres: Array[float] = []
	var blocks := [
		[_aye, AYE_COLOUR, Text.say("floor_vote.tile_aye")],
		[_abstain, ABSTAIN_COLOUR, Text.say("floor_vote.tile_abstain")],
		[_nay, NAY_COLOUR, Text.say("floor_vote.tile_nay")],
	]
	for block: Array in blocks:
		var width: float = float(block[0]) * per_seat
		draw_rect(Rect2(x, bar_top, width, BAR_HEIGHT), block[1])
		centres.append(x + width / 2.0)
		x += width
	# Counts sit over their own block, nudged apart only if they would collide.
	for i in range(1, centres.size()):
		centres[i] = maxf(centres[i], centres[i - 1] + MIN_GAP)
	for i in range(centres.size() - 2, -1, -1):
		centres[i] = minf(centres[i], centres[i + 1] - MIN_GAP)
	var font := get_theme_default_font()
	for i in blocks.size():
		var left: float = clampf(centres[i] - MIN_GAP / 2.0, 0.0, size.x - MIN_GAP)
		var colour: Color = blocks[i][1]
		draw_string(font, Vector2(left, 80.0), str(blocks[i][0]),
			HORIZONTAL_ALIGNMENT_CENTER, MIN_GAP, NUMBER_SIZE, colour)
		draw_string(font, Vector2(left, 125.0), str(blocks[i][2]),
			HORIZONTAL_ALIGNMENT_CENTER, MIN_GAP, CAPTION_SIZE, Color(0.85, 0.85, 0.9))
	var mark := float(_needed) * per_seat
	draw_rect(Rect2(mark - 4.0, bar_top - 8.0, 8.0, BAR_HEIGHT + 16.0), Color(0.1, 0.1, 0.12))
	draw_rect(Rect2(mark - 2.0, bar_top - 6.0, 4.0, BAR_HEIGHT + 12.0), Color(1.0, 0.85, 0.2))
