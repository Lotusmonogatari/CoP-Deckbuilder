class_name IconBacking
extends RefCounted
## Which backing an organization icon sits on (review of P9, 2026-11-17): a dark rounded plate behind a
## light icon and a light plate behind a dark one, so every icon reads at 3 to 1 or better against its
## backing on any room picture (a single backing fails for some icons: measured 1.8 to 1 for the darkest on dark).
## Pure: it reads an Image it is given and decides; no autoload, file or scene.

## The one chip every organization icon sits on (Cameron, 2026-11-18): the same light colour as the Details'
## icon plates, half see-through, so all the chips look alike (the per-icon dark or light backing looked
## inconsistent). The measured 3 to 1 reading per icon no longer applies: the icons are colourful art on a chip.
const CHIP := Color(0.94, 0.93, 0.90, 0.5)
const DARK := Color(0.07, 0.06, 0.05, 0.85)
const LIGHT := Color(0.94, 0.93, 0.90, 0.92)


## Median relative luminance of the icon's opaque pixels in its middle 70% (the icon's body, not its edge).
static func median_luminance(image: Image) -> float:
	if image == null or image.is_empty():
		return 0.0
	if image.is_compressed():
		image.decompress()
	var w := image.get_width()
	var h := image.get_height()
	var values: Array[float] = []
	var step_x := maxi(w / 40, 1)
	var step_y := maxi(h / 40, 1)
	for y in range(int(h * 0.15), int(h * 0.85), step_y):
		for x in range(int(w * 0.15), int(w * 0.85), step_x):
			var c := image.get_pixel(x, y)
			if c.a > 0.5:
				values.append(luminance(c))
	if values.is_empty():
		return 0.0
	values.sort()
	return values[values.size() / 2]


## True when the light backing reads better behind an icon of this median luminance.
static func use_light(median: float) -> bool:
	return contrast_with(median, LIGHT) > contrast_with(median, DARK)


static func backing_for(median: float) -> Color:
	return LIGHT if use_light(median) else DARK


static func contrast_with(median: float, backing: Color) -> float:
	var lb := luminance(backing)
	return (maxf(median, lb) + 0.05) / (minf(median, lb) + 0.05)


static func luminance(c: Color) -> float:
	var channels: Array[float] = []
	for v: float in [c.r, c.g, c.b]:
		channels.append(v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4))
	return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]
