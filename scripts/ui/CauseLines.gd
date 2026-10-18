class_name CauseLines
extends RefCounted
## The "because of ..." half of a change line (2026-10-18). Reasons arrive as
## [{cause, amount}], one per reason with its amounts summed. Every word is a
## Text-tab row; this only chooses which to use.
##
##  - One reason: "because of winning Town Hall" (its amount is the whole
##    change, already shown beside the number).
##  - Several: each carries its own share, joined as a sentence:
##    "because of winning Town Hall (+3) and level win bonuses (+2)", or with
##    three or more, "... (+3), level win bonuses (+2), and your answers (-1)".


## "A", "A and B", "A, B, and C".
static func join(parts: Array) -> String:
	match parts.size():
		0:
			return ""
		1:
			return str(parts[0])
		2:
			return Text.say("record.join_two", {"a": parts[0], "b": parts[1]})
	return Text.say("record.join_many", {
		"list": ", ".join(parts.slice(0, parts.size() - 1)),
		"last": parts[parts.size() - 1]})


## The full phrase, or "" when nothing is recorded.
static func because(entries: Array) -> String:
	if entries.is_empty():
		return ""
	var parts: Array[String] = []
	for entry: Dictionary in entries:
		if entries.size() == 1:
			parts.append(str(entry["cause"]))
		else:
			parts.append(Text.say("record.cause_amount", {
				"cause": entry["cause"], "amount": "%+d" % int(entry["amount"])}))
	return Text.say("record.because", {"causes": join(parts)})
