class_name RunStats
extends RefCounted
## The run's statistics (2026-11-25, Cameron): plain tallies kept for the whole run, saved with it and cleared by New Game.
## This file only counts and ranks. It knows nothing about screens, words or files; what the numbers are called, and the report
## made from them, belong to StatsReport (scripts/ui).
##
## What is counted here (gaffes, which the run already adds up, and the hours of each activity, which the venues already keep,
## are read from there rather than counted twice):
##   suits    {suit: cards played}                  items {item_id: times used}
##   met      {person_id: meetings}                 venues {venue_id: times gone to}
##   promises {"kept", "broken"}                    wins {"threshold", "zero", "other"}: how stages were won

const KIND_THRESHOLD := "threshold"   ## the bar reached its threshold
const KIND_ZERO := "zero"             ## the opponent's support was argued down to nothing
const KIND_OTHER := "other"           ## a stage with neither (a survival, a vote, a visit)
const WIN_KINDS: Array[String] = [KIND_THRESHOLD, KIND_ZERO, KIND_OTHER]
const PROMISE_KEPT := "kept"
const PROMISE_BROKEN := "broken"


## An empty set of tallies.
static func fresh() -> Dictionary:
	return {
		"suits": {}, "items": {}, "met": {}, "met_at": {}, "venues": {},
		"promises": {PROMISE_KEPT: 0, PROMISE_BROKEN: 0},
		"wins": {KIND_THRESHOLD: 0, KIND_ZERO: 0, KIND_OTHER: 0},
	}


## `saved` with anything missing put back (a save from before the tracker has none) and anything that is not a whole number
## dropped, so a damaged save cannot break the screen.
static func normalized(saved: Variant) -> Dictionary:
	var clean := fresh()
	if not (saved is Dictionary):
		return clean
	var source: Dictionary = saved
	for bucket: String in ["suits", "items", "met", "venues"]:
		var counts: Variant = source.get(bucket)
		if counts is Dictionary:
			for key: Variant in (counts as Dictionary):
				if _is_number((counts as Dictionary)[key]):
					(clean[bucket] as Dictionary)[str(key)] = int((counts as Dictionary)[key])
	var met_at: Variant = source.get("met_at")
	if met_at is Dictionary:
		for key: Variant in (met_at as Dictionary):
			(clean["met_at"] as Dictionary)[str(key)] = str((met_at as Dictionary)[key])
	for bucket: String in ["promises", "wins"]:
		var counts: Variant = source.get(bucket)
		if counts is Dictionary:
			for key: Variant in (clean[bucket] as Dictionary).keys():
				if _is_number((counts as Dictionary).get(key)):
					(clean[bucket] as Dictionary)[key] = int((counts as Dictionary)[key])
	return clean


static func _is_number(value: Variant) -> bool:
	return value is int or value is float


## Adds `amount` to one tally in a bucket ("suits", "items", "venues"). A blank key is ignored.
static func bump(stats: Dictionary, bucket: String, key: String, amount: int = 1) -> void:
	if key.is_empty() or not stats.has(bucket):
		return
	var counts: Dictionary = stats[bucket]
	counts[key] = int(counts.get(key, 0)) + amount


## Counts one meeting with a person. `scene` names where it happened (the stage in play), so the same person shown again in the
## same scene (the next bout, a reload) is one meeting, not several. A blank scene always counts. Returns true when counted.
static func note_met(stats: Dictionary, person_id: String, scene: String) -> bool:
	if person_id.is_empty():
		return false
	var met_at: Dictionary = stats["met_at"]
	if not scene.is_empty() and str(met_at.get(person_id, "")) == scene:
		return false
	met_at[person_id] = scene
	bump(stats, "met", person_id)
	return true


## Counts a promise kept (`kept` true) or broken.
static func note_promise(stats: Dictionary, kept: bool) -> void:
	var counts: Dictionary = stats["promises"]
	var key := PROMISE_KEPT if kept else PROMISE_BROKEN
	counts[key] = int(counts.get(key, 0)) + 1


## Counts a stage won the given way (a kind not listed is "other").
static func note_win(stats: Dictionary, kind: String) -> void:
	var counts: Dictionary = stats["wins"]
	var key := kind if kind in WIN_KINDS else KIND_OTHER
	counts[key] = int(counts.get(key, 0)) + 1


## The tallies of a bucket as [key, count] pairs, most first; equal counts keep alphabetical order so the list never shuffles.
static func ranked(counts: Dictionary) -> Array:
	var pairs: Array = []
	for key: Variant in counts:
		if int(counts[key]) > 0:
			pairs.append([str(key), int(counts[key])])
	pairs.sort_custom(func(a: Array, b: Array) -> bool:
		return int(a[1]) > int(b[1]) or (int(a[1]) == int(b[1]) and str(a[0]) < str(b[0])))
	return pairs


## The key (or keys, when tied) at the top of a bucket; empty when nothing was counted.
static func leaders(counts: Dictionary) -> Array[String]:
	var found: Array[String] = []
	var order := ranked(counts)
	for pair: Array in order:
		if int(pair[1]) != int((order[0] as Array)[1]):
			break
		found.append(str(pair[0]))
	return found


## The sum of a bucket.
static func total(counts: Dictionary) -> int:
	var sum := 0
	for key: Variant in counts:
		sum += int(counts[key])
	return sum
