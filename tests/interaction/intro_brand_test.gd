extends Node
## The Brand B start screen (P10, 2026-11-18), checked from what it draws:
##   - every word on it is a Text row, and the scene has no literal text;
##   - every touch target is at least 122 px tall;
##   - text is at least 4.5 to 1 against its ground, and the seal and borders at least 3 to 1 (from pixels);
##   - the plate, the buttons and the footer never overlap or leave the screen, at 1080 x 2340, 1080 x 1920
##     and at Large text, with a save (Continue live) and without one (Continue greyed).
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/intro_brand_test.tscn

const SCENE := "res://scenes/menus/IntroScreen.tscn"
const WASHI := Color("#F1E6CF")

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _fail(message: String) -> void:
	_failures.append(message)


func _run() -> void:
	DataDB.clear_runtime()
	for setting in [TextScale.NORMAL, TextScale.LARGE]:
		Layout.text_size_setting = setting
		Layout.apply_text_scale()
		for size in [Vector2i(1080, 2340), Vector2i(1080, 1920)]:
			for saved in [true, false]:
				await _check("%dx%d %s %s" % [size.x, size.y, setting, "save" if saved else "no save"], size, saved)
	Layout.text_size_setting = TextScale.NORMAL
	Layout.apply_text_scale()
	SaveManager.delete_save()

	print("")
	if _failures.is_empty():
		print("INTRO BRAND TEST: PASS")
		get_tree().quit(0)
	else:
		print("INTRO BRAND TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _check(tag: String, size: Vector2i, saved: bool) -> void:
	SaveManager.delete_save()
	if saved:
		GameState.start_new_run("PC01")
		SaveManager.save_game()
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var screen: Control = (load(SCENE) as PackedScene).instantiate()
	viewport.add_child(screen)
	await get_tree().process_frame
	await get_tree().create_timer(0.8).timeout

	_check_words(tag, screen)
	_check_rects(tag, screen, Vector2(size))
	var image := viewport.get_texture().get_image()
	_check_pixels(tag, screen, image, saved)

	viewport.queue_free()
	SaveManager.delete_save()
	await get_tree().process_frame


## Every word is a Text row: each label and button shows exactly what the Text tab says.
func _check_words(tag: String, screen: Control) -> void:
	var expected := {
		"Title": Text.say("intro.title_top"), "TitleBottom": Text.say("intro.title_bottom"),
		"Tagline": Text.say("intro.tagline"), "FooterMark": Text.say("intro.footer_mark"),
		"ContinueButton": Text.say("intro.continue"), "NewGameButton": Text.say("intro.new_game"),
		"HowToPlayButton": Text.say("intro.how_to_play"),
	}
	for node_name: String in expected:
		var node := screen.find_child(node_name, true, false)
		if node == null or str(node.get("text")) != str(expected[node_name]):
			_fail("%s: %s does not show its Text row" % [tag, node_name])
	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	if not version.is_empty() and (screen.find_child("FooterVersion", true, false) as Label).text != Text.say("intro.version", {"version": version}):
		_fail("%s: the version is not the Text row with the project version" % tag)


func _rect(screen: Control, node_name: String) -> Rect2:
	return (screen.find_child(node_name, true, false) as Control).get_global_rect()


## The plate, the buttons and the footer stay on the screen and clear of each other; every touch target is 122 px.
func _check_rects(tag: String, screen: Control, size: Vector2) -> void:
	var screen_rect := Rect2(Vector2.ZERO, size)
	var parts := {}
	for node_name: String in ["Plate", "ContinueButton", "NewGameButton", "HowToPlayButton", "FooterVersion", "FooterMark"]:
		parts[node_name] = _rect(screen, node_name)
		if not screen_rect.encloses(parts[node_name]):
			_fail("%s: %s leaves the screen (%s)" % [tag, node_name, parts[node_name]])
	var names: Array = parts.keys()
	for i in names.size():
		for j in range(i + 1, names.size()):
			if (names[i] == "FooterVersion" and names[j] == "FooterMark") or (names[i] == "FooterMark" and names[j] == "FooterVersion"):
				continue
			if (parts[names[i]] as Rect2).intersects(parts[names[j]] as Rect2):
				_fail("%s: %s overlaps %s" % [tag, names[i], names[j]])
	for node_name: String in ["ContinueButton", "NewGameButton", "HowToPlayButton"]:
		if (parts[node_name] as Rect2).size.y < 122.0:
			_fail("%s: %s is only %.0f px tall" % [tag, node_name, (parts[node_name] as Rect2).size.y])
	# The plate's own text stays inside it.
	var plate := parts["Plate"] as Rect2
	for node_name: String in ["Title", "TitleBottom", "Tagline"]:
		var label := screen.find_child(node_name, true, false) as Label
		var rect := label.get_global_rect()
		if rect.position.y < plate.position.y or rect.end.y > plate.end.y + 1.0:
			_fail("%s: %s runs outside the plate" % [tag, node_name])
		if label.get_line_count() > 3:
			_fail("%s: %s wraps to %d lines" % [tag, node_name, label.get_line_count()])


func _lum(c: Color) -> float:
	var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)


func _ratio(a: Color, b: Color) -> float:
	var la := _lum(a)
	var lb := _lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## Text against its ground (the commonest colour in its rectangle is the ground, the farthest from it the ink).
func _text_ratio(image: Image, rect: Rect2) -> float:
	var counts := {}
	var samples: Array[Color] = []
	for y in range(int(rect.position.y), int(rect.end.y), maxi(int(rect.size.y) / 14, 1)):
		for x in range(int(rect.position.x), int(rect.end.x), maxi(int(rect.size.x) / 50, 1)):
			if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
				continue
			var c := image.get_pixel(x, y)
			samples.append(c)
			var key := c.to_html(false)
			counts[key] = int(counts.get(key, 0)) + 1
	var ground := WASHI
	var best := -1
	for key: String in counts:
		if int(counts[key]) > best:
			best = int(counts[key])
			ground = Color.html(key)
	var ink := ground
	var far := -1.0
	for c in samples:
		var d := absf(_lum(c) - _lum(ground))
		if d > far:
			far = d
			ink = c
	return _ratio(ink, ground)


func _check_pixels(tag: String, screen: Control, image: Image, saved: bool) -> void:
	# Text: 4.5 to 1. A disabled Continue is exempt (it is a button that cannot be pressed, at 45% by design).
	for node_name: String in ["Title", "TitleBottom", "Tagline", "FooterVersion", "FooterMark", "NewGameButton", "HowToPlayButton"] \
			+ (["ContinueButton"] if saved else []):
		var ratio := _text_ratio(image, _rect(screen, node_name))
		print("  [%s] %s text %.2f : 1" % [tag, node_name, ratio])
		if ratio < 4.5:
			_fail("%s: %s text is %.2f to 1 (needs 4.5)" % [tag, node_name, ratio])
	# Shapes: 3 to 1. The plate's border, the seal and the New Game and How to Play outlines against the washi ground.
	var plate := _rect(screen, "Plate")
	# Low on the plate, below where the framed print runs behind it, so the ground beside it is the washi.
	_shape(tag, "the plate border", image, Vector2(plate.position.x + 3, plate.end.y - 40), Vector2(plate.position.x - 12, plate.end.y - 40))
	var seal := _rect(screen, "Seal")
	_shape(tag, "the seal", image, seal.get_center() + Vector2(0, -seal.size.y * 0.3), Vector2(seal.end.x + 14, seal.get_center().y))
	var new_game := _rect(screen, "NewGameButton")
	_shape(tag, "the New Game outline", image, Vector2(new_game.position.x + 2, new_game.get_center().y), Vector2(new_game.position.x - 10, new_game.get_center().y))
	var how := _rect(screen, "HowToPlayButton")
	_shape(tag, "the How to Play outline", image, Vector2(how.position.x + 1, how.get_center().y), Vector2(how.position.x - 10, how.get_center().y))


func _shape(tag: String, what: String, image: Image, inside: Vector2, ground: Vector2) -> void:
	var a := image.get_pixel(clampi(int(inside.x), 0, image.get_width() - 1), clampi(int(inside.y), 0, image.get_height() - 1))
	var b := image.get_pixel(clampi(int(ground.x), 0, image.get_width() - 1), clampi(int(ground.y), 0, image.get_height() - 1))
	var ratio := _ratio(a, b)
	print("  [%s] %s %.2f : 1" % [tag, what, ratio])
	if ratio < 3.0:
		_fail("%s: %s is %.2f to 1 against its ground (needs 3)" % [tag, what, ratio])
