class_name LevelBriefingPanel
extends Overlay
## The level briefing's panel (P12, 2026-11-19, Cameron): an Overlay, so every caller and test that treats panels as
## Overlays (the `closed` and `confirmed` signals, Back, the escape key, find_child("Confirm")) keeps working, with its
## own layout: the back row fixed at the top, the bottom bar (Back and Go in) fixed at the foot, and only the middle
## scrolling. The ground is the style's flat colour from the mockups, not the scrolling-screen picture other panels use.
##
## It draws what LevelBriefing hands it (open_brief); the look comes from LevelBriefingStyles and the pieces from
## LevelBriefingView. Opening it again rebuilds everything, so a changed style or text size shows at once.

var _root: VBoxContainer
var _scroll: ScrollContainer


## Built once; the content is rebuilt on every open_brief().
func _build() -> void:
	if _body != null:
		return
	_root = VBoxContainer.new()
	_root.name = "Briefing"
	_root.add_theme_constant_override("separation", 0)
	add_child(_root)
	# The Overlay's own parts are the root and the buttons the bar makes, so its helpers stay valid.
	_body = _root


## Shows the briefing for `view` (LevelBriefing.build()'s dictionary).
func open_brief(view: Dictionary) -> void:
	_build()
	var look := LevelBriefingStyles.look()
	var ground := StyleBoxFlat.new()
	ground.bg_color = look["ground"]
	add_theme_stylebox_override("panel", ground)

	for child in _root.get_children():
		_root.remove_child(child)
		child.queue_free()

	var top := MarginContainer.new()
	top.name = "TopMargin"
	top.add_theme_constant_override("margin_left", 40)
	top.add_theme_constant_override("margin_right", 40)
	top.add_theme_constant_override("margin_top", 24)
	top.add_child(LevelBriefingView.top_bar(view, look, close))
	_root.add_child(top)

	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll"
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	DragScroll.attach(_scroll)
	var padding := MarginContainer.new()
	# A scroll box gives its child the box's width only when the child asks to expand; without it a level with no
	# timeline (one room) shrinks to its narrowest, and every line stacks letter by letter.
	padding.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	padding.add_theme_constant_override("margin_left", 40)
	padding.add_theme_constant_override("margin_right", 40)
	padding.add_theme_constant_override("margin_top", 8)
	padding.add_theme_constant_override("margin_bottom", 16)
	padding.add_child(LevelBriefingView.middle(view, look))
	_scroll.add_child(padding)
	_root.add_child(_scroll)

	var bar := LevelBriefingView.bottom_bar(view, look, close, _on_confirmed)
	_root.add_child(bar)
	_back = bar.find_child("Back", true, false) as Button
	_confirm = bar.find_child("Confirm", true, false) as Button
	show()


## The whole panel counts as its content: there is no dimmed surround to tap, so a tap never "outside" closes it.
func content_rect() -> Rect2:
	return get_global_rect()
