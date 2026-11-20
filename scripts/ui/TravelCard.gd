class_name TravelCard
extends ColorRect
## The card shown while a trip happens (two offices, slice 2, 2026-11-20): the Office fades out, the card says
## which way, where and how long, the trip is taken behind it, and the other office fades in. Over everything,
## and it takes every touch until it is gone, so nothing is pressed mid-trip.

const FADE := 0.35
const HOLD := 0.7
## Above the popups (Overlay.POPUP_Z is 10) and below the cue banner's own layer.
const CARD_Z := 40

var _words: Label
var _tween: Tween


func _init() -> void:
	name = "TravelCard"
	color = Color(0.05, 0.06, 0.09, 1.0)
	z_index = CARD_Z
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	modulate.a = 0.0
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_words = Label.new()
	_words.name = "Words"
	_words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_words.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_words.theme_type_variation = &"HeaderLabel"
	_words.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_words.add_theme_color_override("font_color", Color(0.96, 0.94, 0.88))
	_words.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_words.offset_left = 80.0
	_words.offset_right = -80.0
	add_child(_words)


## Fades out to the card, calls `on_midpoint` (the trip itself) behind it, then fades back. Tests skip the fades:
## COP_NO_TRAVEL_FADE takes the trip at once.
func play(words: String, on_midpoint: Callable) -> void:
	if OS.has_environment("COP_NO_TRAVEL_FADE"):
		on_midpoint.call()
		return
	_words.text = words
	visible = true
	if _tween != null:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, FADE)
	_tween.tween_interval(HOLD)
	_tween.tween_callback(on_midpoint)
	_tween.tween_property(self, "modulate:a", 0.0, FADE)
	_tween.tween_callback(hide)
