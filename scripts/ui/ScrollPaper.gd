class_name ScrollPaper
extends PanelContainer
## The paper of a scroll (P18): the style's paper colour with its texture (fine vertical fibres, shading toward the rolled ends, or
## faint scan lines) and a thin edge on each side. Whatever is put inside it is the writing. Draws from ScrollStyle's tokens.

## True for a document not yet found: the paper is faded.
var dim := false
## True when the scroll is a list row (its edge is a line all round), false for the tall reader paper.
var framed := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# The paper is drawn here, not by a StyleBox; an empty one keeps the container from painting its own.
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())


func _draw() -> void:
	var paper := ScrollStyle.colour("paper")
	if dim:
		paper = paper.lerp(UiStyle.ground_colour(), 0.35)
	draw_rect(Rect2(Vector2.ZERO, size), paper)
	var alpha := ScrollStyle.number("texture_alpha", 0.05)
	var step := maxf(ScrollStyle.len_px(ScrollStyle.number("texture_step", 6.0)) * 0.4, 3.0)
	var fibre := ScrollStyle.colour("fibre")
	fibre.a = alpha
	match ScrollStyle.text("texture", "fibers"):
		"fibers":
			var x := step * 0.5
			while x < size.x:
				draw_line(Vector2(x, 0.0), Vector2(x, size.y), fibre, 1.0)
				x += step
		"scanlines":
			var y := step * 0.5
			while y < size.y:
				draw_line(Vector2(0.0, y), Vector2(size.x, y), fibre, 1.0)
				y += step
		"shade":
			# A soft dark band toward each rolled end, painted in a few steps.
			var depth := minf(size.y * 0.5, ScrollStyle.len_px(26.0))
			var shade := ScrollStyle.colour("fibre")
			for band in range(8):
				var share := float(band) / 8.0
				shade.a = alpha * (1.0 - share) * 1.4
				var h := depth / 8.0
				draw_rect(Rect2(0.0, band * h, size.x, h), shade)
				draw_rect(Rect2(0.0, size.y - (band + 1) * h, size.x, h), shade)
	var edge := ScrollStyle.colour("edge")
	var width := maxf(1.0, ScrollStyle.len_px(1.0))
	if framed:
		draw_rect(Rect2(Vector2.ZERO, size), edge, false, width)
	else:
		draw_line(Vector2(0.0, 0.0), Vector2(0.0, size.y), edge, width)
		draw_line(Vector2(size.x, 0.0), Vector2(size.x, size.y), edge, width)
