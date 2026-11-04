class_name BillDossier
extends RefCounted
## The "Read the bill" page on the stance screen (2026-11-04, Cameron): what a
## bill does, who gains and who pays, the strongest case on each side, the main
## risk, a middle ground, and how each party leans.
##
## Every section comes from the bill's own Floor Vote Bills row (Bill
## Description, Who Gains, Who Pays, Case For, Case Against, Main Risk, Middle
## Ground) and its Party Positions rows. A blank cell leaves its section out,
## so a half-written bill still shows what it has. Pure and UI-free (CLAUDE.md
## §12): the screen turns each section's field name into its own heading.

## The prose sections in reading order: [field name in the bill row].
const PROSE_FIELDS := ["bill_description", "who_gains", "who_pays", "case_for",
	"case_against", "main_risk", "middle_ground"]


## [{ "field": String, "text": String }] for every prose section the bill has.
static func sections(bill: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for field: String in PROSE_FIELDS:
		var raw: Variant = bill.get(field)
		var text := "" if raw == null else str(raw).strip_edges()
		if not text.is_empty():
			out.append({"field": field, "text": text})
	return out


## { "Supportive": [party names], "Opposed": [...], "Neutral": [...] } from the
## bill's Party Positions, in the bill's own row order. `parties` is
## parties.json (for the names); a party missing from it shows its ID.
static func party_leans(bill: Dictionary, parties: Array) -> Dictionary:
	var names := {}
	for party: Dictionary in parties:
		names[str(party.get("party_id", ""))] = str(party.get("party_name", party.get("name", "")))
	var out := {"Supportive": [], "Opposed": [], "Neutral": []}
	for position: Variant in bill.get("positions", []):
		if not (position is Dictionary):
			continue
		var disposition := str((position as Dictionary).get("disposition", ""))
		if not out.has(disposition):
			continue
		var party_id := str((position as Dictionary).get("party_id", ""))
		(out[disposition] as Array).append(str(names.get(party_id, party_id)))
	return out
