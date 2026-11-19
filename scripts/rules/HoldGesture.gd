class_name HoldGesture
extends RefCounted
## "Hold N things down together for S seconds" (2026-11-19): the two ways to open the problem
## report, three fingers on the screen and both volume buttons. One object per gesture, so the
## same maths serves both. Pure: it is told what went down and up and how much time passed.
##
## It counts the things currently down (finger numbers, key codes). While at least `needed` are
## down, time adds up; letting go of any of them below that count starts over. It fires once per
## continuous hold, and fires again only after the hold has been let go and made again.

var needed := 3
var seconds := 2.0
## What is down right now (ids are whatever the caller likes: finger indexes, key codes).
var down: Dictionary = {}
var held := 0.0
var _fired := false


func _init(how_many: int = 3, how_long: float = 2.0) -> void:
	needed = maxi(how_many, 1)
	seconds = maxf(how_long, 0.1)


func press(id: Variant) -> void:
	down[id] = true


func release(id: Variant) -> void:
	down.erase(id)
	if down.size() < needed:
		held = 0.0
		_fired = false


## Lets go of everything (the window lost focus, a touch was cancelled).
func reset() -> void:
	down.clear()
	held = 0.0
	_fired = false


func is_holding() -> bool:
	return down.size() >= needed and not _fired


## 0 to 1: how far along the hold is.
func progress() -> float:
	if down.size() < needed:
		return 0.0
	return 1.0 if _fired else clampf(held / seconds, 0.0, 1.0)


## Adds `delta` seconds to a hold in progress. True exactly once, on the frame the hold reaches its time.
func tick(delta: float) -> bool:
	if down.size() < needed or _fired:
		return false
	held += delta
	if held >= seconds:
		_fired = true
		return true
	return false
