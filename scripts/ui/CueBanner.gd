class_name CueBanner
extends Control
## The spoken line, slammed across the screen.
##
## When a card is played, what the player SAYS (the card's cue, from the
## workbook's Flavor Text tab) sweeps in on a slanted band across the middle
## of the screen, with their name on a tag and what the card did underneath —
## the way Ace Attorney throws an "Objection!" at you. The opponent's turn
## answers the same way from the other side.
##
##     banner.say(CueBanner.PLAYER, "Hiro", "The numbers do not lie.", "+4 seats")
##
## RULES IT KEEPS
##   - Lines queue. One never cuts short the one before it (the same promise
##     MessagePresenter makes, for the same reason: a turn is several things).
##   - It never blocks the game. Everything but the band lets touches through,
##     so the hand stays playable, and tapping the band skips to the next line.
##   - Nothing in it is a sentence of its own. It shows what it is handed.

## Which side a line comes from. The player's sweep in from the left in blue,
## the other side's from the right in red.
enum Side { PLAYER, OPPONENT }
const PLAYER := Side.PLAYER
const OPPONENT := Side.OPPONENT

const PLAYER_COLOUR := Color(0.16, 0.36, 0.78)
const OPPONENT_COLOUR := Color(0.72, 0.14, 0.14)
const BAND_COLOUR := Color(0.05, 0.05, 0.08, 0.94)
const EDGE_COLOUR := Color(0.95, 0.82, 0.38)
const DETAIL_COLOUR := Color(0.98, 0.88, 0.55)

## How long a line stays up: a floor, plus reading time per character, up
## to a ceiling. Scaled by `speed` (tests wind it right down).
const HOLD_MIN := 1.6
const HOLD_PER_CHAR := 0.035
const HOLD_MAX := 4.0
const SLIDE_IN := 0.16

## Where the band sits, as a share of the screen's height from the top:
## across the middle, clear of the hand.
const BAND_CENTRE := 0.42
const SLIDE_OUT := 0.14

## Kept clear of the true screen edges, the same margin the rest of the
## battle screen's own Safe area uses (tools/build_battle_scene.gd's
## SIDE_MARGIN) — Cameron, 2026-09-24: the band used to run edge to edge,
## which on a real phone runs it under the camera cutout and the rounded
## corners everything else is kept clear of.
const SIDE_MARGIN := 40.0

## Multiplies every duration. 1.0 in play.
var speed := 1.0

## How many lines have finished showing. The tests read it.
var lines_shown := 0

var _queue: Array[Dictionary] = []
var _busy := false
## Bumped for every line and by skip(), so a wait that outlives its line
## knows to stop.
var _generation := 0

var _band: PanelContainer
var _band_box: StyleBoxFlat
var _tag: PanelContainer
var _tag_box: StyleBoxFlat
var _speaker: Label
var _line: Label
var _detail: Label
var _flash: ColorRect


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50
	_build()
	_band.hide()


## Says `line` as `speaker`, after anything already queued. `detail` is the
## smaller line underneath — what the move did. An empty line says nothing.
func say(side: int, speaker: String, line: String, detail: String = "") -> void:
	if line.strip_edges().is_empty():
		return
	_queue.append({"side": side, "speaker": speaker, "line": line, "detail": detail})
	if not _busy:
		_show_next()


## Drops everything waiting and takes the band away now.
func clear() -> void:
	_queue.clear()
	_generation += 1
	_busy = false
	if _band != null:
		_band.hide()


func is_showing() -> bool:
	return _band != null and _band.visible


## The text on the band now, or "" — for the tests.
func current_line() -> String:
	return _line.text if is_showing() else ""


## The line on screen goes; the next one comes in.
func skip() -> void:
	if not _busy:
		return
	_generation += 1
	_band.hide()
	lines_shown += 1
	_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		_busy = false
		_band.hide()
		return
	_busy = true
	_generation += 1
	var mine := _generation
	var entry: Dictionary = _queue.pop_front()
	_present(entry)

	var width := get_viewport_rect().size.x
	_fit_band(width)
	var from := -width if entry["side"] == PLAYER else width
	_band.position.x = from
	_band.show()
	var slide := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	slide.tween_property(_band, "position:x", SIDE_MARGIN, SLIDE_IN * speed)
	_impact()

	var text_length := str(entry["line"]).length() + str(entry["detail"]).length()
	await _wait(clampf(HOLD_MIN + HOLD_PER_CHAR * text_length, HOLD_MIN, HOLD_MAX))
	if mine != _generation:
		return

	var out := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	out.tween_property(_band, "position:x", -from, SLIDE_OUT * speed)
	await _wait(SLIDE_OUT)
	if mine != _generation:
		return
	_band.hide()
	lines_shown += 1
	_show_next()


func _present(entry: Dictionary) -> void:
	var colour := PLAYER_COLOUR if entry["side"] == PLAYER else OPPONENT_COLOUR
	_tag_box.bg_color = colour
	_band_box.border_color = EDGE_COLOUR
	# Slanted the way the speaker is facing: forward for the player, back
	# for the other side.
	_band_box.skew = Vector2(0.18 if entry["side"] == PLAYER else -0.18, 0.0)
	_speaker.text = str(entry["speaker"])
	_tag.visible = not _speaker.text.is_empty()
	_tag.size_flags_horizontal = (Control.SIZE_SHRINK_BEGIN if entry["side"] == PLAYER
		else Control.SIZE_SHRINK_END)
	_line.text = str(entry["line"])
	_detail.text = str(entry["detail"])
	_detail.visible = not _detail.text.is_empty()


## The band is exactly as wide as the screen minus SIDE_MARGIN on each edge,
## and exactly as tall as its text, centred a little above the middle. Sized
## by hand every time: a wrapping label measured before it knows its width
## reports itself as thousands of pixels tall, and the band would fill the
## screen.
func _fit_band(width: float) -> void:
	var band_width := width - SIDE_MARGIN * 2.0
	var text_width := band_width - _band_box.content_margin_left - _band_box.content_margin_right
	for label: Label in [_line, _detail]:
		label.custom_minimum_size.x = text_width
		label.size = Vector2(text_width, 0.0)   # a wrap is measured at its current width
	_fit_height()


## Shrinks or grows the band to what its text needs now. Also called
## whenever that changes, because a label re-wraps a frame later and a
## control never gets smaller on its own.
func _fit_height() -> void:
	var height := _band.get_combined_minimum_size().y
	_band.size = Vector2(get_viewport_rect().size.x - SIDE_MARGIN * 2.0, height)
	_band.position.y = get_viewport_rect().size.y * BAND_CENTRE - height / 2.0


## The flash and the jolt that make a line land rather than appear.
func _impact() -> void:
	_flash.color = Color(1, 1, 1, 0.35)
	var flash := create_tween()
	flash.tween_property(_flash, "color:a", 0.0, 0.25 * speed)

	# The whole layer jolts, not the band, so the band's own place (which
	# _fit_height() may still be settling) is never overwritten.
	var shake := create_tween()
	for offset: float in [14.0, -10.0, 6.0, 0.0]:
		shake.tween_property(self, "position:y", offset, 0.035 * speed)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(maxf(seconds * speed, 0.0)).timeout


func _on_band_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		skip()
		accept_event()


# ---------------------------------------------------------------------------
# Building
# ---------------------------------------------------------------------------

func _build() -> void:
	_flash = ColorRect.new()
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	add_child(_flash)

	_band = PanelContainer.new()
	_band.name = "Band"
	# Placed and sized by _fit_band(), not by anchors.
	_band.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_band.minimum_size_changed.connect(_fit_height)
	_band.mouse_filter = Control.MOUSE_FILTER_STOP
	_band.gui_input.connect(_on_band_input)
	_band_box = StyleBoxFlat.new()
	_band_box.bg_color = BAND_COLOUR
	_band_box.border_width_top = 8
	_band_box.border_width_bottom = 8
	_band_box.content_margin_left = 70
	_band_box.content_margin_right = 70
	_band_box.content_margin_top = 26
	_band_box.content_margin_bottom = 30
	_band_box.shadow_color = Color(0, 0, 0, 0.5)
	_band_box.shadow_size = 18
	_band.add_theme_stylebox_override("panel", _band_box)
	add_child(_band)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_band.add_child(column)

	_tag = PanelContainer.new()
	_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tag_box = StyleBoxFlat.new()
	_tag_box.set_corner_radius_all(8)
	_tag_box.content_margin_left = 24
	_tag_box.content_margin_right = 24
	_tag_box.content_margin_top = 4
	_tag_box.content_margin_bottom = 6
	_tag.add_theme_stylebox_override("panel", _tag_box)
	column.add_child(_tag)

	_speaker = Label.new()
	_speaker.theme_type_variation = "CueSpeaker"
	_speaker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tag.add_child(_speaker)

	_line = Label.new()
	_line.name = "Line"
	_line.theme_type_variation = "CueBanner"
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_line.add_theme_constant_override("outline_size", 10)
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_line)

	_detail = Label.new()
	_detail.theme_type_variation = "HeaderLabel"
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.add_theme_color_override("font_color", DETAIL_COLOUR)
	_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_detail)
