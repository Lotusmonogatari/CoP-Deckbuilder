class_name PanMath
extends RefCounted
## The arithmetic behind a picture the player can drag (Image Scroll) or that
## drifts as the phone tilts (Image Pan) -- Cameron, 2026-10-30. Pure: no
## nodes and no input, so the tests can prove it; PlaceholderArt does the drawing.
##
## An OFFSET is how far the visible window has moved from the centred
## position, in pixels: positive x shows more of the right of the picture,
## positive y more of the bottom.


## How much a picture must be scaled to fill `box` completely (nothing bare,
## the overflow cropped), the same "cover" fit every background uses.
static func cover_scale(box: Vector2, picture: Vector2) -> float:
	if picture.x <= 0.0 or picture.y <= 0.0:
		return 1.0
	return maxf(box.x / picture.x, box.y / picture.y)


## How much of the scaled picture lies outside the box, across and down.
## Zero on an axis means there is nothing to move along it.
static func spare(box: Vector2, picture: Vector2) -> Vector2:
	var scale := cover_scale(box, picture)
	return Vector2(maxf(picture.x * scale - box.x, 0.0), maxf(picture.y * scale - box.y, 0.0))


## An offset kept within reach, so no edge of the box is ever left bare.
static func clamp_offset(offset: Vector2, room: Vector2) -> Vector2:
	var half := room / 2.0
	return Vector2(clampf(offset.x, -half.x, half.x), clampf(offset.y, -half.y, half.y))


## The offset a tilt asks for. `tilt` is in g (1.0 = the full pull of gravity),
## measured from how the phone was held when the picture appeared; `strength`
## is how many times over a tilt is magnified (2.5: a tilt of 0.4 g reaches the
## edge). A negative strength turns the direction round.
static func tilt_offset(tilt: Vector2, strength: float, room: Vector2) -> Vector2:
	var reach := Vector2(clampf(tilt.x * strength, -1.0, 1.0), clampf(tilt.y * strength, -1.0, 1.0))
	return reach * room / 2.0


## Moves `current` part of the way to `target`: `speed` is how quickly it
## catches up, per second, the same at any frame rate.
static func follow(current: Vector2, target: Vector2, speed: float, delta: float) -> Vector2:
	return current.lerp(target, 1.0 - exp(-maxf(speed, 0.0) * maxf(delta, 0.0)))


## Where the scaled picture's top-left corner goes for a given offset.
static func picture_position(box: Vector2, scaled: Vector2, offset: Vector2) -> Vector2:
	return (box - scaled) / 2.0 - offset
