class_name Commitments
extends RefCounted
## What a choice costs on the spot (Cameron, 2026-10-31, commitments phase 1):
## a choice's Commitment cell (Event Choices, Visitor Questions) lists any of
##   Hours N     hours spent now (a visit, a call made in person)
##   Funds N     Funds paid now (commissioning a study, flowers)
##   Item SHxx   an owned item handed over (a box of apples, a coffee)
## exported as [{"kind": "hours"|"funds"|"item", "amount": N, "item_id": "SHxx"}].
## Pure and UI-free; GameState pays, the screens grey out what cannot be paid.

const HOURS := "hours"
const FUNDS := "funds"
const ITEM := "item"


## The commitment list on a row, or [] (a blank cell is JSON null).
static func of(row: Dictionary, key: String = "commitment") -> Array:
	var raw: Variant = row.get(key)
	return raw if raw is Array else []


static func hours(list: Array) -> int:
	var total := 0
	for entry: Variant in list:
		if entry is Dictionary and str(entry.get("kind", "")) == HOURS:
			total += int(entry.get("amount", 0))
	return total


static func funds(list: Array) -> int:
	var total := 0
	for entry: Variant in list:
		if entry is Dictionary and str(entry.get("kind", "")) == FUNDS:
			total += int(entry.get("amount", 0))
	return total


static func items(list: Array) -> Array[String]:
	var found: Array[String] = []
	for entry: Variant in list:
		if entry is Dictionary and str(entry.get("kind", "")) == ITEM:
			found.append(str(entry.get("item_id", "")))
	return found


## Why the list cannot be paid now: "" (it can), HOURS, FUNDS, or the ID of
## the first item the player does not hold.
static func refusal(list: Array, hours_left: int, funds_on_hand: int, inventory: Dictionary) -> String:
	if hours(list) > hours_left:
		return HOURS
	if funds(list) > funds_on_hand:
		return FUNDS
	for item_id: String in items(list):
		if int(inventory.get(item_id, 0)) <= 0:
			return item_id
	return ""
