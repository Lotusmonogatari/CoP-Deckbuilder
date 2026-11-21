class_name EventLeads
extends RefCounted
## The organizations that LEAD an event (2026-11-21, Cameron): up to two, named in the event's own text, usually the one bringing the
## issue forward. An organization that only has a passive plus or minus from a choice is not a lead. The Events tab's Lead
## Organizations column holds them; this reads them, and says which ones the text really names. Pure: no screens, no files.

const MAX := 2


## The lead organization ids of an event row, at most MAX, in the order the tab lists them; a blank cell gives none.
static func of(event: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var raw: Variant = event.get("lead_organizations")
	if raw is Array:
		for id: Variant in raw as Array:
			var text := str(id).strip_edges()
			if not text.is_empty() and not out.has(text) and out.size() < MAX:
				out.append(text)
	return out


## True when `name` appears in the event's own title or flavor text (case does not matter).
static func names_in_text(event: Dictionary, name: String) -> bool:
	if name.strip_edges().is_empty():
		return false
	var own := (str(event.get("title", "")) + " " + str(event.get("flavor", ""))).to_lower()
	return own.contains(name.to_lower())
