extends SceneTree
## Rebuilds every brand PNG in assets/brand/ from the SVGs in design/brand/source/ (P10, 2026-11-18).
##
## Run it with a display (the feature graphic is drawn with real text):
##     xvfb-run -a .tools/godot --path . -s tools/brand/export_brand.gd
## Then run the unit test (tests/test_brand_assets.gd) or `tools/verify.sh` to check sizes.
##
## The art is rasterized with Godot's own SVG loader and never redrawn or recoloured. Nothing here decides
## anything about the game: it only turns the brand source files into the files the stores and the engine read.

const SRC := "res://design/brand/source/"
const OUT := "res://assets/brand/"

## The brand colours (spec section 2). Used only for the feature graphic's text and frames.
const WASHI := Color("#F1E6CF")
const PAPER := Color("#F8F1E3")
const INDIGO := Color("#1F3561")
const VERMILION := Color("#C23B22")
const SUMI := Color("#1C1A17")
const QUIET := Color("#5A5146")

## Square icon sizes cut from icon_b.svg: the stores, Android's legacy launcher, and every iOS size Godot 4.5.1's
## iOS export reads (icons/iphone_120x120, iphone_180x180, ipad_152x152, ipad_167x167, notification_40x40,
## notification_60x60, notification_76x76, notification_114x114, settings_58x58, settings_87x87, spotlight_80x80,
## spotlight_120x120, app_store_1024x1024 and icon_1024x1024). The 29 and 20 pt sizes are the 58, 87, 40 and 60.
const ICON_SIZES := [1024, 512, 192, 180, 167, 152, 120, 114, 87, 80, 76, 60, 58, 40]


func _initialize() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var made := 0

	for size: int in ICON_SIZES:
		var icon := _svg("icon_b.svg", size)
		if size == 1024 or size == 512:
			icon.convert(Image.FORMAT_RGB8)   # the store icons carry no alpha channel
		else:
			icon.convert(Image.FORMAT_RGBA8)
		_save(icon, "icon_%d.png" % size)
		made += 1

	_save(_svg("icon_b_adaptive_foreground.svg", 432), "adaptive_foreground_432.png")
	_save(_svg("icon_b_adaptive_background.svg", 432), "adaptive_background_432.png")
	_save(_svg("icon_b_monochrome.svg", 432), "adaptive_monochrome_432.png")
	_save(_svg("mark_b.svg", 600), "splash_seal.png")
	# The wave band for the start screen's foot: 1080 x 199, the SVG scaled to that height and cropped
	# from the top-left (spec section 5, row 13).
	var waves := _svg("waves_b.svg", int(ceil(1020.0 * 199.0 / 170.0)))
	_save(waves.get_region(Rect2i(0, 0, mini(1080, waves.get_width()), mini(199, waves.get_height()))), "waves_1080x199.png")
	made += 5

	await _feature_graphic()
	made += 1
	print("BRAND EXPORT: wrote %d files to assets/brand/" % made)
	quit(0)


## One SVG at `size` pixels across (the SVGs are square, or are scaled by their own width).
func _svg(file: String, size: int) -> Image:
	var text := FileAccess.get_file_as_string(SRC + file)
	var native := _svg_width(text)
	var image := Image.new()
	var error := image.load_svg_from_string(text, float(size) / native)
	if error != OK:
		push_error("could not rasterize %s (error %d)" % [file, error])
		quit(1)
	return image


func _svg_width(text: String) -> float:
	var regex := RegEx.create_from_string("<svg[^>]*\\swidth=\"([0-9.]+)\"")
	var found := regex.search(text)
	return float(found.get_string(1)) if found != null else 1024.0


func _save(image: Image, file: String) -> void:
	var error := image.save_png(ProjectSettings.globalize_path(OUT + file))
	if error != OK:
		push_error("could not write %s" % file)
		quit(1)


## Google Play's feature graphic, 1024 x 500 (spec section 7): the title plate, the seal and the hook line on the
## left, the TITLE painting framed on the right, waves along the foot. Drawn with real text in a SubViewport.
func _feature_graphic() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1024, 500)
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)

	var ground := ColorRect.new()
	ground.color = WASHI
	ground.size = Vector2(1024, 500)
	viewport.add_child(ground)

	# Right 52%: the TITLE painting in a 4 px indigo frame on paper.
	var frame := Panel.new()
	frame.position = Vector2(512, 28)
	frame.size = Vector2(484, 420)
	var frame_box := StyleBoxFlat.new()
	frame_box.bg_color = PAPER
	frame_box.border_color = INDIGO
	frame_box.set_border_width_all(4)
	frame.add_theme_stylebox_override("panel", frame_box)
	viewport.add_child(frame)
	var painting := TextureRect.new()
	painting.texture = load("res://assets/backgrounds/TITLE.png")   # the start screen's own painting
	painting.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	painting.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	painting.position = Vector2(524, 40)
	painting.size = Vector2(460, 396)
	viewport.add_child(painting)

	# Left 48%: the plate (Coliseum / of Parliament) with the vermilion double border, then the hook line.
	var plate := Panel.new()
	plate.position = Vector2(40, 96)
	plate.size = Vector2(420, 190)
	var shadow := StyleBoxFlat.new()
	shadow.bg_color = PAPER
	shadow.border_color = VERMILION
	shadow.set_border_width_all(4)
	shadow.shadow_color = Color(SUMI.r, SUMI.g, SUMI.b, 0.14)
	shadow.shadow_offset = Vector2(7, 7)
	shadow.shadow_size = 1
	plate.add_theme_stylebox_override("panel", shadow)
	viewport.add_child(plate)
	var inner := Panel.new()
	inner.position = Vector2(52, 108)
	inner.size = Vector2(396, 166)
	var inner_box := StyleBoxFlat.new()
	inner_box.bg_color = Color(0, 0, 0, 0)
	inner_box.border_color = VERMILION
	inner_box.set_border_width_all(1)
	inner.add_theme_stylebox_override("panel", inner_box)
	viewport.add_child(inner)

	var bold: Font = load("res://assets/fonts/ShipporiMinchoB1-Bold.woff2")
	var regular: Font = load("res://assets/fonts/ShipporiMinchoB1-Regular.woff2")
	_label(viewport, _say("intro.title_top"), bold, 70, SUMI, Vector2(40, 112), Vector2(420, 84))
	_label(viewport, _say("intro.title_bottom"), bold, 36, INDIGO, Vector2(40, 196), Vector2(420, 48))
	_label(viewport, _say("brand.hook"), regular, 26, QUIET, Vector2(30, 318), Vector2(440, 40))

	# The seal overlaps the plate's top-right corner.
	var seal := TextureRect.new()
	seal.texture = ImageTexture.create_from_image(_svg("mark_b.svg", 120))
	seal.position = Vector2(386, 38)
	seal.size = Vector2(96, 96)
	seal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	viewport.add_child(seal)

	# 40 px of waves along the foot.
	var waves := _svg("waves_b.svg", 1024)
	var strip := waves.get_region(Rect2i(0, 0, waves.get_width(), mini(40, waves.get_height())))
	var waves_rect := TextureRect.new()
	waves_rect.texture = ImageTexture.create_from_image(strip)
	waves_rect.position = Vector2(0, 460)
	viewport.add_child(waves_rect)

	await process_frame
	await process_frame
	await process_frame
	var image := viewport.get_texture().get_image()
	image.convert(Image.FORMAT_RGB8)
	_save(image, "feature_graphic_1024x500.png")
	viewport.queue_free()


## A line from the Text tab (data/strings.json), read straight from the file: autoloads are not running in a
## tool script.
func _say(key: String) -> String:
	var rows: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/strings.json"))
	if rows is Array:
		for row: Variant in rows:
			if row is Dictionary and str((row as Dictionary).get("key", "")) == key:
				return str((row as Dictionary).get("english", ""))
	push_error("no Text row %s" % key)
	return key


func _label(parent: Node, text: String, font: Font, size: int, colour: Color, at: Vector2, extent: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = extent
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", colour)
	label.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	parent.add_child(label)
