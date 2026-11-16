class_name WordFit
extends RefCounted
## Keeps a word whole (Cameron, 2026-11-16): wrapped text must never break in the
## middle of a word and leave a single letter hanging on the next line
## ("Representativ" / "e"). Godot's smart wrap does exactly that when one word is
## wider than its box. These are the measuring rules the TextFit autoload uses:
## wrap at word boundaries only, and when the longest word still does not fit,
## shrink the type a step at a time (to a minimum) until it does.


## The width of the longest piece of `text` that cannot be broken: a word, or the
## part of a hyphenated word up to its hyphen.
static func longest_word_width(text: String, font: Font, size: int) -> float:
	var widest := 0.0
	for word: String in text.replace("\n", " ").replace("-", "- ").split(" ", false):
		widest = maxf(widest, font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
	return widest


## The largest font size, from `current` down to `minimum`, at which the longest
## word fits in `available` pixels; -1 when even the minimum does not fit.
static func fit_size(text: String, font: Font, current: int, available: float, minimum: int) -> int:
	var size := current
	while size >= minimum:
		if longest_word_width(text, font, size) <= available:
			return size
		size -= 1
	return -1


## The width a control's text may use: its width less its own padding.
static func available_width(control: Control) -> float:
	var padding := 0.0
	if control is Label:
		padding = (control as Label).get_theme_stylebox("normal").get_minimum_size().x
	elif control is Button:
		padding = (control as Button).get_theme_stylebox("normal").get_minimum_size().x + 8.0
	return control.size.x - padding
