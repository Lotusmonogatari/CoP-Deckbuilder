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


static func is_promise(entry: Variant) -> bool:
	return entry is Dictionary and str(entry.get("kind", "")) in [PROMISE_ITEM, PROMISE_HOURS]


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
		"hours": int(entry.get("amount", 0)),
		"due_at": now + (int(within) if within != null else default_hours),
		"for_org": org if not org.is_empty() else fallback_org,
		"source": source,
	}


## Game hours left before a promise falls due (never below zero).
static func hours_left(promise: Dictionary, now: int) -> int:
	return maxi(0, int(promise.get("due_at", 0)) - now)


## The promises that have fallen due unkept by `now`.
static func overdue(promises: Array, now: int) -> Array:
	return promises.filter(func(p: Variant) -> bool: return p is Dictionary and now > int(p.get("due_at", 0)))


## Why a promise cannot be kept right now: "" (it can), "item" (not held) or
## "hours" (too few hours left).
static func keep_refusal(promise: Dictionary, inventory: Dictionary, hours_available: int) -> String:
	if str(promise.get("kind", "")) == PROMISE_ITEM and int(inventory.get(str(promise.get("item_id", "")), 0)) <= 0:
		return "item"
	if str(promise.get("kind", "")) == PROMISE_HOURS and int(promise.get("hours", 0)) > hours_available:
		return "hours"
	return ""
