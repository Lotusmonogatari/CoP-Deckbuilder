class_name IntroLayout
extends RefCounted
## Where everything on the start screen goes (P10, Brand B, spec section 5): pure arithmetic from the screen size,
## the safe-area insets and how tall the title plate came out. Positions are base pixels on a 1080-wide screen;
## only the framed print flexes (it fills the room between the bands and the plate), so a short screen or a larger
## text size shrinks the picture and nothing else. No autoload, node or file.

const BAND_HEIGHT := 166.0          # the three bands: 83 + 50 + 33
const PRINT_GAP := 78.0             # from the bands to the framed print
const PRINT_MARGIN := 100.0
const PRINT_MIN_HEIGHT := 520.0
const PLATE_MARGIN := 150.0
const PLATE_OVERLAP := 100.0        # how far the print runs down behind the plate
const PLATE_GAP := 110.0            # from the plate to the first button
const SEAL_SIZE := 172.0
const BUTTON_MARGIN := 89.0
const BUTTON_GAP := 33.0
const CONTINUE_HEIGHT := 161.0
const NEW_GAME_HEIGHT := 150.0
const HOW_TO_PLAY_HEIGHT := 138.0
const FOOTER_FROM_BOTTOM := 330.0   # the footer's top edge above the bottom of the screen
const FOOTER_HEIGHT := 56.0
const WAVES_HEIGHT := 199.0


## Every rectangle. `size` is the screen, `insets` {left, top, right, bottom}, `plate_height` the title plate's
## own height (its text decides it).
static func rects(size: Vector2, insets: Dictionary, plate_height: float) -> Dictionary:
	var left := float(insets.get("left", 0.0))
	var right := float(insets.get("right", 0.0))
	var button_x := maxf(BUTTON_MARGIN, left)
	var button_w := size.x - button_x - maxf(BUTTON_MARGIN, right)

	var footer_top := size.y - FOOTER_FROM_BOTTOM
	var how_top := footer_top - HOW_TO_PLAY_HEIGHT
	var new_top := how_top - BUTTON_GAP - NEW_GAME_HEIGHT
	var continue_top := new_top - BUTTON_GAP - CONTINUE_HEIGHT

	var plate_x := maxf(PLATE_MARGIN, left)
	var plate_w := size.x - plate_x - maxf(PLATE_MARGIN, right)
	var plate_top := continue_top - PLATE_GAP - plate_height

	var print_top := BAND_HEIGHT + PRINT_GAP
	var print_height := maxf(plate_top + PLATE_OVERLAP - print_top, PRINT_MIN_HEIGHT)
	var print_x := maxf(PRINT_MARGIN, left)

	return {
		"bands": Rect2(0, 0, size.x, BAND_HEIGHT),
		"print": Rect2(print_x, print_top, size.x - print_x - maxf(PRINT_MARGIN, right), print_height),
		"plate": Rect2(plate_x, plate_top, plate_w, plate_height),
		"seal": Rect2(plate_x + plate_w - 111.0, plate_top - 72.0, SEAL_SIZE, SEAL_SIZE),
		"continue": Rect2(button_x, continue_top, button_w, CONTINUE_HEIGHT),
		"new_game": Rect2(button_x, new_top, button_w, NEW_GAME_HEIGHT),
		"how_to_play": Rect2(button_x, how_top, button_w, HOW_TO_PLAY_HEIGHT),
		"footer": Rect2(button_x, footer_top + 8.0, button_w, FOOTER_HEIGHT),
		"waves": Rect2(0, size.y - WAVES_HEIGHT, size.x, WAVES_HEIGHT),
	}


## The part of a picture of `texture_size` that fills a frame of `frame_size` (cover), centred across and with the
## focus `focus_y` of the way down (0.42 for the title painting), as a region in the picture's own pixels.
static func cover_region(texture_size: Vector2, frame_size: Vector2, focus_y: float) -> Rect2:
	if texture_size.x <= 0.0 or texture_size.y <= 0.0 or frame_size.x <= 0.0 or frame_size.y <= 0.0:
		return Rect2(Vector2.ZERO, texture_size)
	var scale := maxf(frame_size.x / texture_size.x, frame_size.y / texture_size.y)
	var region := frame_size / scale
	return Rect2((texture_size.x - region.x) * 0.5, (texture_size.y - region.y) * clampf(focus_y, 0.0, 1.0), region.x, region.y)
