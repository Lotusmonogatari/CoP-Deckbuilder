class_name ActionLog
extends RefCounted
## The game's "black box": the last few things the player did, newest last (2026-11-19, Cameron's
## error-reporting request). A problem report carries it, so a bug arrives with the steps that led
## to it instead of one screenshot.
##
## Pure: it holds entries and formats them, nothing else. The Reporter autoload feeds it screen
## changes, button presses, taps and the errors the engine reports.
##
## An entry is { "at": seconds since the game started, "kind": "screen" | "press" | "tap" | "layout" |
## "error", "text": what happened, "count": how many times in a row }. The same entry twice in a row
## is one line with a count, so a button pressed ten times does not push everything else out.

var capacity := 60
var _entries: Array = []


func _init(max_entries: int = 60) -> void:
	capacity = maxi(max_entries, 1)


func add(at: float, kind: String, text: String) -> void:
	if not _entries.is_empty():
		var last: Dictionary = _entries[_entries.size() - 1]
		if str(last["kind"]) == kind and str(last["text"]) == text:
			last["count"] = int(last.get("count", 1)) + 1
			last["at"] = at
			return
	_entries.append({"at": at, "kind": kind, "text": text, "count": 1})
	while _entries.size() > capacity:
		_entries.pop_front()


func size() -> int:
	return _entries.size()


func clear() -> void:
	_entries.clear()


## A copy, oldest first.
func entries() -> Array:
	return _entries.duplicate(true)


## The newest entry of a kind, or {} when there is none.
func last_of(kind: String) -> Dictionary:
	for index in range(_entries.size() - 1, -1, -1):
		if str((_entries[index] as Dictionary)["kind"]) == kind:
			return (_entries[index] as Dictionary).duplicate()
	return {}


## One readable line per entry, oldest first: "  12 s ago  press   Promises (1)". `now` is the clock
## the entries were stamped against (seconds since the game started).
func lines(now: float) -> PackedStringArray:
	var out := PackedStringArray()
	for entry: Dictionary in _entries:
		var times := int(entry.get("count", 1))
		var suffix := " (x%d)" % times if times > 1 else ""
		out.append("%10s  %-7s %s%s" % [ago(now - float(entry["at"])), str(entry["kind"]), str(entry["text"]), suffix])
	return out


## For saving to disk between runs.
func to_array() -> Array:
	return entries()


## The inverse of to_array(); entries that are not well-formed are dropped.
static func from_array(data: Array, max_entries: int = 60) -> ActionLog:
	var log := ActionLog.new(max_entries)
	for item: Variant in data:
		if item is Dictionary and (item as Dictionary).has("kind") and (item as Dictionary).has("text"):
			var entry := item as Dictionary
			log._entries.append({"at": float(entry.get("at", 0.0)), "kind": str(entry["kind"]),
				"text": str(entry["text"]), "count": maxi(int(entry.get("count", 1)), 1)})
	while log._entries.size() > log.capacity:
		log._entries.pop_front()
	return log


## "now", "12 s ago", "3 min ago".
static func ago(seconds: float) -> String:
	var whole := maxi(int(round(seconds)), 0)
	if whole < 2:
		return "now"
	if whole < 100:
		return "%d s ago" % whole
	return "%d min ago" % int(round(whole / 60.0))
