class_name ClosedHere
extends RefCounted
## What is not open while the player is at one office (P14b, 2026-11-21, Cameron: "reflective of the office"): the kinds of
## thing that belong only to the OTHER office, read from the data's own Location tags (levels, events, visitors). A kind with
## nothing tagged for the other office is not listed, so the list is true of whichever office the player stands in. Pure.

const LEVELS := "levels"
const EVENTS := "events"
const VISITORS := "visitors"


## The kinds that are closed here, in a fixed order. `here` is the office the player stands in; each list is the data's rows
## (each with a "location" cell).
static func kinds(here: String, levels: Array, events: Array, visitors: Array) -> Array[String]:
	var there := Offices.other(Offices.normalize(here))
	var out: Array[String] = []
	for entry: Array in [[LEVELS, levels], [EVENTS, events], [VISITORS, visitors]]:
		for row: Variant in entry[1] as Array:
			if row is Dictionary and Offices.normalize((row as Dictionary).get("location")) == there:
				out.append(str(entry[0]))
				break
	return out
