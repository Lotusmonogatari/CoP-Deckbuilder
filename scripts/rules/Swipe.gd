class_name Swipe
extends RefCounted
## The drag that takes a trip (two offices, slice 2, 2026-11-20): how far the train has been pulled, and whether
## letting go commits it. Pure; the strip (TravelStrip) feeds it pixels.

const NO_TRAIN := 0.0


## How far along the track the train is, 0 to 1, from the drag's pixels. `direction` is +1 when the train is
## pulled to the right (Capitol to District) and -1 to the left; a drag the wrong way is no progress at all.
static func progress(drag_x: float, track_length: float, direction: int) -> float:
	if track_length <= 0.0:
		return NO_TRAIN
	return clampf(drag_x * float(direction) / track_length, 0.0, 1.0)


## True when letting go at `progress` commits the trip: past the Balance row's share of the track (about 60%).
static func commits(progress_value: float, commit_fraction: float) -> bool:
	return progress_value >= commit_fraction


## A press that barely moved is a tap (it opens the same confirm as the drag), not a drag.
static func is_tap(drag_pixels: float, slop: float) -> bool:
	return absf(drag_pixels) <= slop
