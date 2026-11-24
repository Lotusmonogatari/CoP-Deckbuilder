class_name Codex
extends RefCounted
## The Library's Codex and reference desk (P18, 2026-11-24, Cameron): the documents the player has found, how they are found and read,
## the Room files the reference desk makes, and how a room's reading is put into words. Pure: no screens, no autoloads, no files (the
## tests prove it).
##
## A document is a Library Documents row {doc_id, category, order, title, title_jp, kicker, body, party, unlock, unlock_value, hint,
## note}. A row whose Note begins "DRAFT" is a placeholder and is hidden from players. `found` is {doc_id: {"day": day found,
## "read": bool}}. A Room file is not a workbook row: `room_files` is {stage_id: {"day", "level_id", "reading": [...], "read": bool}}
## and a file shows only while a tip for its stage is held.

const ROOM_FILES := "room_file"
const PASSED := "passed"
const FAILED := "failed"


static func is_draft(doc: Dictionary) -> bool:
	var note: Variant = doc.get("note")
	return note != null and str(note).strip_edges().to_upper().begins_with("DRAFT")


## The documents players can see: every row that is not a placeholder, in the tab's order.
static func visible(docs: Array) -> Array:
	var out: Array = []
	for doc: Variant in docs:
		if doc is Dictionary and not is_draft(doc as Dictionary):
			out.append(doc)
	return out


## The categories to show, in order: Room files first, then each Library Documents category by the Order of its first row; a
## category with no visible documents is left out. (Room files appear only when `has_room_files`.)
static func categories(docs: Array, has_room_files: bool) -> Array[String]:
	var out: Array[String] = []
	if has_room_files:
		out.append(ROOM_FILES)
	var firsts: Array = []
	var seen := {}
	var position := 0
	for doc: Variant in visible(docs):
		var category := str((doc as Dictionary).get("category", ""))
		if not seen.has(category):
			seen[category] = true
			firsts.append({"category": category, "order": int((doc as Dictionary).get("order", 0)), "position": position})
		position += 1
	firsts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["order"]) < int(b["order"]) or (int(a["order"]) == int(b["order"]) and int(a["position"]) < int(b["position"])))
	for entry: Dictionary in firsts:
		out.append(str(entry["category"]))
	return out


## The visible documents of a category, by Order (ties keep the tab's order).
static func in_category(docs: Array, category: String) -> Array:
	var rows: Array = []
	var position := 0
	for doc: Variant in visible(docs):
		if str((doc as Dictionary).get("category", "")) == category:
			rows.append({"doc": doc, "position": position})
		position += 1
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var oa := int((a["doc"] as Dictionary).get("order", 0))
		var ob := int((b["doc"] as Dictionary).get("order", 0))
		return oa < ob or (oa == ob and int(a["position"]) < int(b["position"])))
	var out: Array = []
	for row: Dictionary in rows:
		out.append(row["doc"])
	return out


# --- finding ----------------------------------------------------------------------------------------------------------------------------

## The IDs found when a run begins: `start` documents, and `own_party` documents of the player's party (a party ID).
static func found_at_start(docs: Array, party_id: String) -> Array[String]:
	var out: Array[String] = []
	for doc: Variant in visible(docs):   # a hidden placeholder is never found
		var row := doc as Dictionary
		var unlock := str(row.get("unlock", ""))
		if unlock == "start" or (unlock == "own_party" and not party_id.is_empty() and str(row.get("party", "")) == party_id):
			out.append(str(row.get("doc_id", "")))
	return out


## The `law` documents a law result finds: those whose Unlock Value is "<bill> passed" or "<bill> failed" and whose bill has that
## result in `statuses` ({bill_id: "passed" or "failed"}).
static func found_by_laws(docs: Array, statuses: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for doc: Variant in docs:
		var row := doc as Dictionary
		if str(row.get("unlock", "")) != "law":
			continue
		var parts := str(row.get("unlock_value", "")).strip_edges().split(" ")
		if parts.size() == 2 and str(statuses.get(parts[0], "")) == parts[1]:
			out.append(str(row.get("doc_id", "")))
	return out


## `found` with the document added (found today, not read); unchanged when it is already found.
static func with_found(found: Dictionary, doc_id: String, day: int) -> Dictionary:
	if doc_id.is_empty() or found.has(doc_id):
		return found
	var next := found.duplicate(true)
	next[doc_id] = {"day": day, "read": false}
	return next


## "sealed" (not found), "new" (found, unread) or "read".
static func state_of(found: Dictionary, doc_id: String) -> String:
	if not found.has(doc_id):
		return "sealed"
	return "read" if bool((found[doc_id] as Dictionary).get("read", false)) else "new"


## Reads a document: {"found": the new dictionary, "first": true only the first time (the one time its XP is paid)}.
static func with_read(found: Dictionary, doc_id: String) -> Dictionary:
	if not found.has(doc_id):
		return {"found": found, "first": false}
	var entry: Dictionary = found[doc_id]
	if bool(entry.get("read", false)):
		return {"found": found, "first": false}
	var next := found.duplicate(true)
	(next[doc_id] as Dictionary)["read"] = true
	return {"found": next, "first": true}


## How many found documents are unread, plus `room_files_unread`.
static func unread_count(docs: Array, found: Dictionary, room_files_unread: int = 0) -> int:
	var count := room_files_unread
	for doc: Variant in visible(docs):
		if state_of(found, str((doc as Dictionary).get("doc_id", ""))) == "new":
			count += 1
	return count


## The document before and after `id` in `ids` ("" at either end), for the reader's Previous and Next.
static func neighbours(ids: Array, id: String) -> Dictionary:
	var at := ids.find(id)
	return {"previous": str(ids[at - 1]) if at > 0 else "", "next": str(ids[at + 1]) if at >= 0 and at < ids.size() - 1 else ""}


# --- the reference desk -----------------------------------------------------------------------------------------------------------

## A style's reading in words: {"id": "strongest" | "strong" | "neutral" | "weak" | "weakest", "meter": 5 to 1} from the affinity
## multiplier (1.4 or more, 1.15 to 1.39, 0.86 to 1.14, 0.6 to 0.85, under 0.6).
static func band_for(multiplier: float) -> Dictionary:
	if multiplier >= 1.4:
		return {"id": "strongest", "meter": 5}
	if multiplier >= 1.15:
		return {"id": "strong", "meter": 4}
	if multiplier >= 0.86:
		return {"id": "neutral", "meter": 3}
	if multiplier >= 0.6:
		return {"id": "weak", "meter": 2}
	return {"id": "weakest", "meter": 1}


## The six styles' reading of a room, best first (ties by style name): [{"suit", "multiplier", "band", "meter"}]. `affinity` is the
## affinity table, [{"element": suit, "multipliers": {stage_id: multiplier}}]. A style with no entry for the room reads as 1.0.
static func reading(stage_id: String, affinity: Array) -> Array:
	var rows: Array = []
	for entry: Variant in affinity:
		var row := entry as Dictionary
		var multipliers: Variant = row.get("multipliers")
		var value := 1.0
		if multipliers is Dictionary and (multipliers as Dictionary).has(stage_id) and (multipliers as Dictionary)[stage_id] != null:
			value = float((multipliers as Dictionary)[stage_id])
		var band := band_for(value)
		rows.append({"suit": str(row.get("element", "")), "multiplier": value, "band": band["id"], "meter": band["meter"]})
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["multiplier"]) > float(b["multiplier"]) or (is_equal_approx(float(a["multiplier"]), float(b["multiplier"])) \
			and str(a["suit"]) < str(b["suit"])))
	return rows


# --- Room files -------------------------------------------------------------------------------------------------------------------

## `store` with a room researched: a fresh reading and date; a file already held keeps its read mark (researching again refreshes it).
static func with_room_file(store: Dictionary, stage_id: String, day: int, level_id: String, reading_rows: Array) -> Dictionary:
	var next := store.duplicate(true)
	var was_read := bool((store.get(stage_id, {}) as Dictionary).get("read", false)) if store.has(stage_id) else false
	next[stage_id] = {"day": day, "level_id": level_id, "reading": reading_rows.duplicate(true), "read": was_read}
	return next


## The Room files to show: those whose stage still has a held stage tip. `held_tips` are RhetoricTips' tips.
static func room_file_ids(store: Dictionary, held_tips: Array) -> Array[String]:
	var held := {}
	for tip: Variant in held_tips:
		if str((tip as Dictionary).get("kind", "")) == "stage_suit":
			held[str((tip as Dictionary).get("target", ""))] = true
	var out: Array[String] = []
	for stage_id: Variant in store.keys():
		if held.has(str(stage_id)):
			out.append(str(stage_id))
	out.sort_custom(func(a: String, b: String) -> bool: return int((store[a] as Dictionary).get("day", 0)) > int((store[b] as Dictionary).get("day", 0)))
	return out


## `store` without the files whose tip is no longer held.
static func pruned(store: Dictionary, held_tips: Array) -> Dictionary:
	var keep := room_file_ids(store, held_tips)
	var next := {}
	for stage_id: String in keep:
		next[stage_id] = store[stage_id]
	return next


## `store` with one file marked read.
static func room_file_read(store: Dictionary, stage_id: String) -> Dictionary:
	if not store.has(stage_id):
		return store
	var next := store.duplicate(true)
	(next[stage_id] as Dictionary)["read"] = true
	return next


## How many of the shown Room files are unread.
static func room_files_unread(store: Dictionary, held_tips: Array) -> int:
	var count := 0
	for stage_id: String in room_file_ids(store, held_tips):
		if not bool((store[stage_id] as Dictionary).get("read", false)):
			count += 1
	return count
