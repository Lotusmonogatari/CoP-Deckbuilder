extends Node
## Keeps wrapped text from splitting a word across two lines (Cameron,
## 2026-11-16). Every label and button that wraps its text is looked at a few
## frames after it appears, once its box has its real width: it is set to wrap
## at word boundaries only, and if its longest word is wider than the box, its
## type is shrunk a size at a time (never below Balance `Text Fit: Minimum Font
## Size`) until the word fits. As a last resort, when even the smallest size does
## not fit, the old smart wrap is allowed so nothing is cut off.
## Cards draw their own text and are left alone. The measuring is WordFit.

## Frames to wait so containers have given the node its real width.
const SETTLE_FRAMES := 3
## A hidden node (a panel not yet opened) is looked at again after this many frames.
const RETRY_FRAMES := 20
const MAX_TRIES := 15

var _pending := {}   # instance id -> { "frame": int, "tries": int }


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is Label or node is Button:
		_pending[node.get_instance_id()] = {"frame": Engine.get_process_frames(), "tries": 0}


func _process(_delta: float) -> void:
	if _pending.is_empty():
		return
	var now := Engine.get_process_frames()
	for id: int in _pending.keys():
		var entry: Dictionary = _pending[id]
		if now - int(entry["frame"]) < SETTLE_FRAMES:
			continue
		var node := instance_from_id(id) as Control
		if node == null or not is_instance_valid(node):
			_pending.erase(id)
			continue
		if _check(node):
			_pending.erase(id)
		elif int(entry["tries"]) >= MAX_TRIES:
			_pending.erase(id)
		else:
			entry["tries"] = int(entry["tries"]) + 1
			entry["frame"] = now + RETRY_FRAMES - SETTLE_FRAMES


## Looks at one node. True when it is finished (fitted, or nothing to do);
## false when it should be looked at again (not on screen yet).
func _check(node: Control) -> bool:
	var wraps := (node as Label).autowrap_mode if node is Label else (node as Button).autowrap_mode
	if wraps == TextServer.AUTOWRAP_OFF:
		return true
	if _inside_card(node):
		return true
	if not node.is_visible_in_tree() or node.size.x <= 1.0:
		return false
	var text := (node as Label).text if node is Label else (node as Button).text
	# Wrap at word boundaries only.
	if wraps == TextServer.AUTOWRAP_WORD_SMART:
		_set_wrap(node, TextServer.AUTOWRAP_WORD)
	var font := node.get_theme_font("font")
	var size := node.get_theme_font_size("font_size")
	var available := WordFit.available_width(node)
	if text.is_empty() or font == null or available <= 0.0:
		return true
	if WordFit.longest_word_width(text, font, size) <= available:
		return true
	var fitted := WordFit.fit_size(text, font, size, available, Levers.whole("text_fit_minimum_font_size"))
	if fitted > 0:
		node.add_theme_font_size_override("font_size", fitted)
	else:
		# Nothing small enough: better a split word than a cut-off one.
		node.add_theme_font_size_override("font_size", Levers.whole("text_fit_minimum_font_size"))
		_set_wrap(node, TextServer.AUTOWRAP_WORD_SMART)
	return true


static func _set_wrap(node: Control, mode: int) -> void:
	if node is Label:
		(node as Label).autowrap_mode = mode as TextServer.AutowrapMode
	else:
		(node as Button).autowrap_mode = mode as TextServer.AutowrapMode


static func _inside_card(node: Node) -> bool:
	var parent := node.get_parent()
	while parent != null:
		if parent is CardView or parent is CardBackView:
			return true
		parent = parent.get_parent()
	return false
