class_name VoteMeter
extends Control
## A one-line picture of the whole house on a Floor Vote result (2026-10-15):
## Aye, Abstain and Nay side by side, sized by seats, with a white mark where
## the Yes votes needed to pass end. The Aye block is green when the bill
## passed and red when it did not, so a shortfall reads as the gap between
## the block's right edge and the mark.

const HEIGHT := 36.0
const PASS_COLOUR := Color(0.25, 0.65, 0.35)
const FAIL_COLOUR := Color(0.78, 0.28, 0.25)
const ABSTAIN_COLOUR := Color(0.55, 0.55, 0.60)
const NAY_COLOUR := Color(0.35, 0.38, 0.48)

var _aye := 0
var _nay := 0
var _abstain := 0
var _needed := 0
var _passed := false


func _ready() -> void:
	custom_minimum_size.y = HEIGHT


func show_totals(aye: int, nay: int, abstain: int, needed: int, passed: bool) -> void:
	_aye = aye
	_nay = nay
	_abstain = abstain
	_needed = needed
	_passed = passed
	queue_redraw()


func _draw() -> void:
	var house := _aye + _nay + _abstain
	if house <= 0 or size.x <= 0.0:
		return
	var per_seat := size.x / float(house)
	var x := 0.0
	for block: Array in [
			[_aye, PASS_COLOUR if _passed else FAIL_COLOUR],
			[_abstain, ABSTAIN_COLOUR],
			[_nay, NAY_COLOUR]]:
		var width: float = float(block[0]) * per_seat
		draw_rect(Rect2(x, 0.0, width, HEIGHT), block[1])
		x += width
	var mark := float(_needed) * per_seat
	draw_rect(Rect2(mark - 2.0, -4.0, 4.0, HEIGHT + 8.0), Color.WHITE)
