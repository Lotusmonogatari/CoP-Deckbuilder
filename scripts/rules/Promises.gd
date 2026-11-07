class_name Promises
extends RefCounted
## Promises (Cameron, 2026-10-31, commitments phase 2): a choice whose
## Commitment cell says `Promise Item SHxx within H for BOxx` or
## `Promise Hours N within H for BOxx` is taken now and owed later. The player
## keeps it from the Office's Promises panel (hands the item over, or spends
## the hours) before it falls due; one that falls due unkept is broken.
## Pure and UI-free; GameState holds the list and applies kept/broken effects.

const PROMISE_ITEM := "promise_item"
const PROMISE_HOURS := "promise_hours"
## Funds owed later (2026-11-07): `Promise Funds N within H for BOxx`.
const PROMISE_FUNDS := "promise_funds"


static func is_promise(entry: Variant) -> bool:
	return entry is Dictionary and str(entry.get("kind", "")) in [PROMISE_ITEM, PROMISE_HOURS, PROMISE_FUNDS]


## A promise record from a commitment entry: {id, kind, item_id, hours, due_at,
## for_org, source}. `now` is the game clock; the entry's own `within` wins
## over `default_hours`; its `for` organization wins over `fallback_org`.
static func make(entry: Dictionary, now: int, default_hours: int, fallback_org: String,
		source: String, serial: int) -> Dictionary:
	var within: Variant = entry.get("within")
	var org := str(entry.get("for", "")) if entry.get("for") != null else ""
	return {
		"id": "P%d" % serial,
		"kind": str(entry.get("kind", "")),
		"item_id": str(entry.get("item_id", "")),
		"hours": int(entry.get("amount", 0)) if str(entry.get("kind", "")) == PROMISE_HOURS else 0,
		"funds": int(entry.get("amount", 0)) if str(entry.get("kind", "")) == PROMISE_FUNDS else 0,
		"due_at": now + (int(within) if within != null else default_hours),
		"made_at": now,
		"for_org": org if not org.is_empty() else fallback_org,
		"source": source,
	}


## A choice row's own promise terms (Event Choices, 2026-10-31): { kept,
## broken, kept_text }, holding only what the row fills in.
static func terms_of(row: Dictionary) -> Dictionary:
	var terms := {}
	for pair: Array in [["promise_kept", "kept"], ["promise_broken", "broken"], ["promise_kept_text", "kept_text"]]:
		var value: Variant = row.get(pair[0])
		if value is Array and not (value as Array).is_empty():
			terms[pair[1]] = value
		elif value is String and not (value as String).strip_edges().is_empty():
			terms[pair[1]] = value
	return terms


## True when a promise carries its own `key` ("kept" or "broken") effects.
static func has_own(promise: Dictionary, key: String) -> bool:
	return promise.get(key) is Array and not (promise[key] as Array).is_empty()


## Promise deadlines pause while a level is played (Cameron, 2026-11-04): the
## Office, where promises are kept, cannot be reached mid-level. When the level
## ends, each promise's due time moves on by the hours the level took since the
## level began, or since the promise was made if it was made during the level.
## Changes `promises` in place.
static func resume_after_level(promises: Array, level_started_at: int, now: int) -> void:
	for promise: Variant in promises:
		if not (promise is Dictionary):
			continue
		var made := int((promise as Dictionary).get("made_at", level_started_at))
		var paused := now - maxi(made, level_started_at)
		if paused > 0:
			promise["due_at"] = int(promise.get("due_at", 0)) + paused


## Game hours left before a promise falls due (never below zero).
static func hours_left(promise: Dictionary, now: int) -> int:
	return maxi(0, int(promise.get("due_at", 0)) - now)


## The promises that have fallen due unkept by `now`.
static func overdue(promises: Array, now: int) -> Array:
	return promises.filter(func(p: Variant) -> bool: return p is Dictionary and now > int(p.get("due_at", 0)))


## Why a promise cannot be kept right now: "" (it can), "item" (not held),
## "hours" (too few hours left) or "funds" (too little Funds on hand).
static func keep_refusal(promise: Dictionary, inventory: Dictionary, hours_available: int,
		funds_on_hand: int = 0) -> String:
	if str(promise.get("kind", "")) == PROMISE_FUNDS and int(promise.get("funds", 0)) > funds_on_hand:
		return "funds"
	if str(promise.get("kind", "")) == PROMISE_ITEM and int(inventory.get(str(promise.get("item_id", "")), 0)) <= 0:
		return "item"
	if str(promise.get("kind", "")) == PROMISE_HOURS and int(promise.get("hours", 0)) > hours_available:
		return "hours"
	return ""
