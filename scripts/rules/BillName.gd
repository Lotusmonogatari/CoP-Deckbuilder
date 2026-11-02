class_name BillName
extends RefCounted
## A bill's name worked into a sentence (2026-11-02, Cameron).
##
## A named bill reads after "the": "the Hokkaido Shinkansen Acceleration Act". A
## bill a player drafts is named by its words, "A bill to cap the monthly cost of
## a commuter pass", which after "the" gave "The case for the A bill to cap ...".
## So a name that starts with its own article drops it and says "this bill to
## cap ..." instead; a name that starts with "The" is not given a second one.
##
## Pure and UI-free (CLAUDE.md section 12).


## The name as it reads in the middle of a sentence ("the ... Act", "this bill to ...").
static func phrase(bill_name: String) -> String:
	var name := bill_name.strip_edges()
	if name.is_empty():
		return ""
	var lower := name.to_lower()
	if lower.begins_with("a ") or lower.begins_with("an "):
		return "this " + name.substr(name.find(" ") + 1)
	if lower.begins_with("the "):
		return "the " + name.substr(4)
	return "the " + name


## The same, ready to start a sentence ("This bill to ...", "The ... Act").
static func sentence_start(bill_name: String) -> String:
	var text := phrase(bill_name)
	return text.substr(0, 1).to_upper() + text.substr(1)


## The short way to refer back to a bill: "the Act" or "the Agreement" for a bill
## named so, "the bill" for anything else. `variety` picks between "the Act" and
## "the bill" for an Act, so a run of lines does not all say the same one.
static func short(bill_name: String, variety: int = 0) -> String:
	var words := bill_name.strip_edges().split(" ")
	var last := words[words.size() - 1] if not words.is_empty() else ""
	if (last == "Act" or last == "Agreement") and variety % 2 == 0:
		return "the " + last
	return "the bill"
