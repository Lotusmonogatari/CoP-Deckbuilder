extends GutTest
## Wrapped text never breaks inside a word (Cameron, 2026-11-16): WordFit measures,
## the TextFit autoload shrinks the type until the longest word fits.

func _font() -> Font:
	return ThemeDB.fallback_font


func test_the_longest_word_is_measured_not_the_whole_line() -> void:
	var font := _font()
	var whole := font.get_string_size("Policy Research Assistant", HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
	var word := WordFit.longest_word_width("Policy Research Assistant", font, 30)
	assert_lt(word, whole)
	var widest := 0.0
	for each in ["Policy", "Research", "Assistant"]:
		widest = maxf(widest, font.get_string_size(each, HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x)
	assert_eq(word, widest, "the widest of the three words")


func test_a_hyphenated_word_may_break_at_its_hyphen() -> void:
	var font := _font()
	var joined := font.get_string_size("Wind-Dried", HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x
	assert_lt(WordFit.longest_word_width("Wind-Dried", font, 30), joined)


func test_the_largest_size_that_fits_is_chosen() -> void:
	var font := _font()
	var available := font.get_string_size("Representative", HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var size := WordFit.fit_size("Representative", font, 40, available, 20)
	assert_gte(size, 24)
	assert_lte(WordFit.longest_word_width("Representative", font, size), available)
	assert_gt(WordFit.longest_word_width("Representative", font, size + 1), available, "one larger would not fit")


func test_nothing_fits_returns_minus_one() -> void:
	assert_eq(WordFit.fit_size("Representative", _font(), 40, 10.0, 20), -1)


func test_a_label_with_a_word_too_wide_shrinks_instead_of_splitting() -> void:
	var holder := Control.new()
	holder.size = Vector2(400, 200)
	add_child_autofree(holder)
	var label := Label.new()
	label.text = "Representative"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 60)
	label.size = Vector2(300, 100)
	label.custom_minimum_size = Vector2(300, 0)
	holder.add_child(label)
	await wait_frames(8)
	var font := label.get_theme_font("font")
	var size := label.get_theme_font_size("font_size")
	assert_lt(size, 60, "the type shrank")
	assert_lte(WordFit.longest_word_width("Representative", font, size), label.size.x, "the whole word fits on one line")
	assert_eq(label.autowrap_mode, TextServer.AUTOWRAP_WORD, "wrapping is by whole words")


func test_a_label_that_already_fits_is_left_alone() -> void:
	var holder := Control.new()
	holder.size = Vector2(600, 200)
	add_child_autofree(holder)
	var label := Label.new()
	label.text = "Press the button"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(500, 0)
	label.size = Vector2(500, 60)
	holder.add_child(label)
	var before := label.get_theme_font_size("font_size")
	await wait_frames(8)
	assert_eq(label.get_theme_font_size("font_size"), before)
	assert_eq(label.autowrap_mode, TextServer.AUTOWRAP_WORD)


func test_a_label_that_does_not_wrap_is_not_touched() -> void:
	var label := Label.new()
	label.text = "Representative"
	add_child_autofree(label)
	await wait_frames(8)
	assert_eq(label.autowrap_mode, TextServer.AUTOWRAP_OFF)
