class_name TickerPresenter
extends RefCounted
## Drives the Office screen's scrolling news strip.
##
## OfficeTicker.gd (pure) decides which line comes next; this owns the
## actual motion and timing, both independently tunable in rules.json so
## Cameron can retune either without a code change:
##   ticker_speed_px_per_sec       how fast the current line travels
##   ticker_pull_interval_seconds  how long to pause, with nothing showing,
##                                 after one line has fully scrolled off
##                                 before the next one enters
##
## A line always travels the FULL width and disappears only once every
## letter of it has scrolled past the strip's own left edge — it used to
## swap to a freshly-picked line on the interval alone, wherever the
## current one had scrolled to, which cut a line off mid-screen and made
## it pop out of existence with letters still showing (2026-09-28 mobile
## playtest). The interval now measures the gap AFTER a full exit, not a
## forced swap.
##
## Not pure — reads DataDB/GameState directly, the same as every other
## presenter in scripts/ui/ (OpponentPresenter, PlayerPortraitPresenter).

var _strip: Control
var _label: Label
var _ticker := OfficeTicker.new()
var _rng := RandomNumberGenerator.new()

## True while a line is on screen and scrolling; false during the pause
## between one line's full exit and the next one entering.
var _showing := false
var _text_width := 0.0
var _elapsed_since_exit := 0.0


func _init(strip: Control, label: Label) -> void:
	_strip = strip
	_label = label
	# Free-floating and wide enough for any real line; the strip's own
	# clip_contents crops it to what should actually be visible, so the
	# label's own RECT never needs to match its text width — get_minimum_
	# size() still reports the natural single-line width for exit timing.
	_label.clip_text = false
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_rng.randomize()
	_pull_next()   # the first line shows immediately, no starting pause


## Call every frame (OfficeScreen._process()). `delta` is the frame time.
func advance(delta: float) -> void:
	if not _showing:
		_elapsed_since_exit += delta
		var interval := float(DataDB.rules.get("ticker_pull_interval_seconds", 12))
		if _elapsed_since_exit >= interval:
			_pull_next()
		return

	var speed := float(DataDB.rules.get("ticker_speed_px_per_sec", 50))
	_label.position.x -= speed * delta

	# Fully exited once even its leftmost pixel has passed the strip's own
	# left edge (position.x == 0) — not merely off the right side of it.
	if _label.position.x + _text_width < 0.0:
		_showing = false
		_label.visible = false
		_elapsed_since_exit = 0.0


## A freshly-picked line, starting just off the strip's own right edge.
func _pull_next() -> void:
	var line := _ticker.next_line(
		DataDB.office_ticker, GameState.staff_hired, GameState.meta, _rng,
		str(DataDB.player.get("name_en", "")))
	if line.is_empty():
		# Nothing eligible right now — keep waiting rather than show blank.
		_showing = false
		_label.visible = false
		return

	_label.text = line
	_label.visible = true
	_text_width = _label.get_minimum_size().x
	_label.position.x = _strip.size.x
	_showing = true
