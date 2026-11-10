extends GutTest
## The shrunk Japanese fallback font (tools/subset_font.py, audit A-07) must keep
## every character the full font had that the game's data uses. If this fails
## after new content, run `python3 tools/subset_font.py` again.

const SHIPPED := "res://assets/fonts/NotoSansJP[wght].ttf"
const FULL := "res://tools/fonts/NotoSansJP[wght].full.ttf"


func _load(path: String) -> FontFile:
	var font := FontFile.new()
	font.load_dynamic_font(path)
	return font


func test_nothing_the_data_uses_was_lost_in_the_shrink() -> void:
	var shipped := _load(SHIPPED)
	var full := _load(FULL)
	var seen := {}
	var dir := DirAccess.open("res://data")
	for file_name in dir.get_files():
		if not file_name.ends_with(".json"):
			continue
		var text := FileAccess.get_file_as_string("res://data/" + file_name)
		for index in text.length():
			seen[text.unicode_at(index)] = true
	var lost: PackedStringArray = []
	for code: int in seen:
		if code > 0x20 and full.has_char(code) and not shipped.has_char(code):
			lost.append(char(code))
	assert_eq(lost.size(), 0, "missing from the shrunk font: %s" % "".join(lost))
	assert_true(full.has_char(0x5186), "the full font loaded")
	assert_true(shipped.has_char(0x5186), "円 is kept")
	assert_true(shipped.has_char(0x014D), "ō is kept")
