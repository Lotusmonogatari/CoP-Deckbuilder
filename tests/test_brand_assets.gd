extends GutTest
## The brand assets (P10, 2026-11-18): every file in assets/brand/ exists at its size, the store icons have no
## alpha channel, and the Android adaptive foreground stays inside the 66% safe circle.
## Rebuild them with: xvfb-run -a .tools/godot --path . -s tools/brand/export_brand.gd

const DIR := "res://assets/brand/"

const SQUARES := {
	"icon_1024.png": 1024, "icon_512.png": 512, "icon_192.png": 192, "icon_180.png": 180, "icon_167.png": 167,
	"icon_152.png": 152, "icon_120.png": 120, "icon_114.png": 114, "icon_87.png": 87, "icon_80.png": 80,
	"icon_76.png": 76, "icon_60.png": 60, "icon_58.png": 58, "icon_40.png": 40,
	"adaptive_foreground_432.png": 432, "adaptive_background_432.png": 432, "adaptive_monochrome_432.png": 432,
	"splash_seal.png": 600,
}


func _image(file: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(DIR + file))


func test_every_icon_is_present_at_its_size() -> void:
	for file: String in SQUARES:
		var image := _image(file)
		assert_not_null(image, "%s exists" % file)
		if image == null:
			continue
		assert_eq(image.get_size(), Vector2i(SQUARES[file], SQUARES[file]), "%s is %d square" % [file, SQUARES[file]])


func test_the_feature_graphic_is_1024_by_500() -> void:
	var image := _image("feature_graphic_1024x500.png")
	assert_not_null(image)
	if image != null:
		assert_eq(image.get_size(), Vector2i(1024, 500))


func test_the_store_icons_have_no_alpha_channel() -> void:
	for file: String in ["icon_1024.png", "icon_512.png", "feature_graphic_1024x500.png"]:
		var image := _image(file)
		if image != null:
			assert_false(image.detect_alpha() != Image.ALPHA_NONE, "%s has no alpha channel" % file)


func test_the_adaptive_foreground_stays_inside_the_safe_circle() -> void:
	var image := _image("adaptive_foreground_432.png")
	assert_not_null(image)
	if image == null:
		return
	var centre := Vector2(216, 216)
	var radius := 432.0 * 0.66 * 0.5
	var outside := 0
	for y in range(0, 432, 2):
		for x in range(0, 432, 2):
			if image.get_pixel(x, y).a > 0.5 and Vector2(x, y).distance_to(centre) > radius:
				outside += 1
	assert_eq(outside, 0, "no opaque foreground pixel outside the 66% circle")


func test_the_monochrome_layer_is_white_on_transparent() -> void:
	var image := _image("adaptive_monochrome_432.png")
	assert_not_null(image)
	if image == null:
		return
	assert_eq(image.get_pixel(0, 0).a, 0.0, "the corner is transparent")
	var opaque := 0
	for y in range(0, 432, 6):
		for x in range(0, 432, 6):
			var c := image.get_pixel(x, y)
			if c.a > 0.5:
				opaque += 1
				assert_gt(c.r + c.g + c.b, 2.7, "opaque pixels are white")
	assert_gt(opaque, 100, "there is a seal")
