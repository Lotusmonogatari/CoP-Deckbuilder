class_name TickerPresenter
extends RefCounted
## Drives the Office screen's scrolling news strip.
##
## OfficeTicker.gd (pure) decides which line comes next; this owns the
## actual motion and timing, both independently tunable in rules.json so
## Cameron can retune either without a code change:
##   ticker_speed_px_per_sec       how fast the current line travels
##   ticker_pull_interval_seconds  how often a freshly-picked line replaces
##                                 whatever is showing, wherever it has
##                                 scrolled to
##
## Not pure — reads DataDB/GameState directly, the same as every other
## presenter in scripts/ui/ (OpponentPresenter, PlayerPortraitPresenter).

var _strip: Control
var _label: Label
var _ticker := OfficeTicker.new()
var _rng := RandomNumberGenerator.new()
var _elapsed_since_pull := 0.0


func _init(strip: Control, label: Label) -> void:
	_strip = strip
	_label = label
	# Free-floating and wide enough for any real line; the strip's own
	# clip_contents crops it to what should actually be visible, so the
	# label never needs to know its own text width.
	_label.clip_text = false
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_rng.randomize()
	_pull_next()


## Call every frame (OfficeScreen._process()). `delta` is the frame time.
func advance(delta: float) -> void:
	if _label.text.is_empty():
		return
	var speed := float(DataDB.rules.get("ticker_speed_px_per_sec", 50))
	_label.position.x -= speed * delta

	_elapsed_since_pull += delta
	var interval := float(DataDB.rules.get("ticker_pull_interval_seconds", 12))
	if _elapsed_since_pull >= interval:
		_pull_next()


## A freshly-picked line, starting just off the strip's own right edge —
## whatever the current line's own position was, on a timer rather than
## waiting for it to finish scrolling off.
func _pull_next() -> void:
	_elapsed_since_pull = 0.0
	var line := _ticker.next_line(
		DataDB.office_ticker, GameState.staff_hired, GameState.meta, _rng)
	_label.visible = not line.is_empty()
	_label.text = line
	if not line.is_empty():
		_label.position.x = _strip.size.x
