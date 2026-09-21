class_name CardBackView
extends Control
## A card opened up: Cameron's back frame, with the full text on its grid.
##
## The back is a sheet of writing paper — 原稿用紙 ruling with a 蓮物語
## watermark — and everything the front had no room for goes on it: the
## printed text in full, the suit, the Japanese name, and what the room is
## doing to the card right now.
##
## Same idea as CardView: the artwork already draws the furniture, so this
## only positions text over the region the grid occupies, as fractions of the
## card. The numbers were measured off the PNG.
##
## ONE LINE PER CELL, and that is the whole trick. The obvious way to do this
## is one RichTextLabel over the grid with the spacing tuned — and it does not
## work, because a line carrying Japanese is taller than a line of Latin, so
## the first 熱弁 pushes everything below it half a rule out and the page
## reads as a mistake. Each line is instead given its own cell and centred in
## it, which costs a little wrapping code and buys exact registration: the
## title can be twice the size of the body and nothing under it moves.

const FRAME_BACK := "res://assets/cards/frame_back_shoji.png"
const ASPECT := 1429.0 / 2000.0

## The ruled grid, measured off the PNG rather than guessed. Its rules run
## across the sheet at y = 202, 345, 488 … 1631 of 2000, evenly 143 apart.
const RULE_TOP := 0.1010      # the first rule across the sheet
const RULE_PITCH := 0.0715    # one rule to the next
const RULES_DEEP := 10        # whole cells between the first rule and the last

## Side to side: the frame's inner border is at x = 71 and 1358 of 1429. The
## text is inset from both so a long romaji name cannot run out over it.
const TEXT_LEFT := 0.070
const TEXT_WIDTH := 0.860

const INK := Color(0.16, 0.13, 0.10)
## For the line that says what the room is doing, which is commentary rather
## than anything printed on the card.
const FAINT_INK := Color(0.42, 0.35, 0.28)

## How much of a cell each kind of line fills. Only the title differs, and
## only because each line owns its own cell.
const TITLE_SCALE := 0.62
const BODY_SCALE := 0.44

var _frame: TextureRect
var _cells: Array[Label] = []

## What to write, before it is wrapped: {text, scale, color}.
var _lines: Array[Dictionary] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_build()
	_relayout()


func _build() -> void:
	if not _cells.is_empty():
		return

	_frame = TextureRect.new()
	_frame.texture = load(FRAME_BACK)
	_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_frame.stretch_mode = TextureRect.STRETCH_SCALE
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)

	for i: int in RULES_DEEP:
		var cell := Label.new()
		CardView.place(cell, Rect2(
			TEXT_LEFT, RULE_TOP + i * RULE_PITCH, TEXT_WIDTH, RULE_PITCH))
		cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cell.add_theme_color_override("font_color", INK)
		# A line that somehow still will not fit is trimmed rather than
		# allowed to run out over the border.
		cell.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		add_child(cell)
		_cells.append(cell)


## Keeps the card's own proportions whatever height it is given.
func _notification(what: int) -> void:
	if what != NOTIFICATION_RESIZED:
		return
	custom_minimum_size.x = size.y * ASPECT
	_relayout()


## Everything the front had no room for.
func show_card(card: Dictionary, here: String, room: String) -> void:
	_build()

	var suit := str(card.get("suit", ""))

	_lines = []
	_write(str(card.get("name_en", "")), TITLE_SCALE, INK)

	var jp := str(card.get("name_jp", ""))
	var romaji := str(card.get("romaji", ""))
	if not jp.is_empty():
		_write("%s  %s" % [jp, romaji], BODY_SCALE, FAINT_INK)

	_write("%s · %s · costs %d" % [
		suit, card.get("type", ""), int(card.get("cost", 0))], BODY_SCALE, INK)
	_write(str(card.get("effect_text", "")), BODY_SCALE, INK)

	# What it will do HERE, where that differs from what it says on paper.
	if not here.is_empty() and here != str(card.get("effect_text", "")):
		_write("In this room: %s" % here, BODY_SCALE, INK)

	if not room.is_empty():
		_write(room, BODY_SCALE, FAINT_INK)

	_relayout()


func _write(text: String, scale: float, color: Color) -> void:
	if text.strip_edges().is_empty():
		return
	_lines.append({"text": text, "scale": scale, "color": color})


## Wraps what there is to say and deals it out, one line to a cell.
func _relayout() -> void:
	if _cells.is_empty() or size.y <= 0.0:
		return

	# Everything is measured off the height, not the width. The width follows
	# the height through ASPECT, and during a resize it can still be a frame
	# behind — which would wrap the text against a stale number.
	var cell_height := size.y * RULE_PITCH
	var writable := size.y * ASPECT * TEXT_WIDTH

	var dealt: Array[Dictionary] = []
	for line: Dictionary in _lines:
		var font_size := maxi(int(cell_height * float(line["scale"])), 8)
		for piece: String in _wrap(str(line["text"]), font_size, writable):
			dealt.append({"text": piece, "size": font_size, "color": line["color"]})

	for i: int in _cells.size():
		var cell := _cells[i]
		if i >= dealt.size():
			cell.text = ""
			continue
		cell.text = str(dealt[i]["text"])
		cell.add_theme_font_size_override("font_size", int(dealt[i]["size"]))
		cell.add_theme_color_override("font_color", dealt[i]["color"])


## Breaks a sentence into pieces that fit the ruled width.
##
## Label's own autowrap would do this, but a wrapped Label is two lines tall
## and a cell is one line, so the wrapping has to happen before the text is
## handed out rather than inside the cell it lands in.
func _wrap(text: String, font_size: int, width: float) -> PackedStringArray:
	var out := PackedStringArray()
	var font: Font = _cells[0].get_theme_font("font")
	if font == null or width <= 0.0:
		out.append(text)
		return out

	var line := ""
	for word: String in text.split(" ", false):
		var trial := word if line.is_empty() else line + " " + word
		var trial_width := font.get_string_size(
			trial, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		if trial_width <= width or line.is_empty():
			line = trial
		else:
			out.append(line)
			line = word
	if not line.is_empty():
		out.append(line)
	return out
