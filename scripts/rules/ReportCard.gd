class_name ReportCard
extends RefCounted
## The text of a problem report (2026-11-19): what a tester's phone sends back so the problem can be
## understood and reproduced without a conversation. Pure: it is handed facts and returns text.
##
## The report is for the developer, not a line the game says to the player, so its headings are
## plain English here and not Text rows. What the player reads while making a report is all in the
## Text tab (report.*).
##
## It holds no name, email or device identifier. A copy of the save travels with it as a compressed
## block of text between two marker lines, so one paste carries everything; tools/read_report.py turns
## the block back into a save file that can be dropped into the game's folder.

const KINDS := ["looks", "broken", "wording", "balance", "idea", "crash"]
const BEGIN := "-----BEGIN SAVE-----"
const END := "-----END SAVE-----"
const LINE_WIDTH := 76
## Godot's gzip compression mode. The pure rules may not name the file classes, so the number is written
## here (the unit test checks it still equals the engine's own constant).
const GZIP_MODE := 3


## `card` keys (all optional): kind, note, source ("touch" | "volume" | "crash"), made_at, build,
## platform, model, screen, safe, scene, style, text_size, run (Dictionary label -> value, in order),
## circled (Array of lines), layout (Array of lines), actions (Array of lines), errors (Array of
## lines), previous_session (bool), save_note (why there is no save block, when there is none).
## `save_blob` is pack_blob()'s text, or "".
static func to_text(card: Dictionary, save_blob: String = "") -> String:
	var out := PackedStringArray()
	out.append("# Problem report")
	out.append("")
	out.append("- Kind: %s" % str(card.get("kind", "")))
	out.append("- Opened by: %s" % str(card.get("source", "")))
	out.append("- Made: %s" % str(card.get("made_at", "")))
	var note := str(card.get("note", "")).strip_edges()
	out.append("- Note: %s" % (note if not note.is_empty() else "(none)"))
	if bool(card.get("previous_session", false)):
		out.append("- About the session BEFORE this one: the game did not close cleanly.")
	out.append("")
	out.append("## Where")
	for key: String in ["build", "platform", "model", "screen", "safe", "scene", "style", "text_size"]:
		if card.has(key) and not str(card[key]).is_empty():
			out.append("- %s: %s" % [_label(key), str(card[key])])
	var run: Variant = card.get("run", {})
	if run is Dictionary and not (run as Dictionary).is_empty():
		out.append("")
		out.append("## The run")
		for key: Variant in (run as Dictionary).keys():
			out.append("- %s: %s" % [str(key), str((run as Dictionary)[key])])
	_section(out, "Circled by the tester", card.get("circled", []))
	_section(out, "Layout notes (found by the game)", card.get("layout", []))
	_section(out, "Errors the game noticed", card.get("errors", []))
	var actions := _as_array(card.get("actions", []))
	if not actions.is_empty():
		out.append("")
		out.append("## Last actions (oldest first)")
		out.append("```")
		for line: Variant in actions:
			out.append(str(line))
		out.append("```")
	out.append("")
	out.append("## Save")
	if save_blob.is_empty():
		out.append(str(card.get("save_note", "(no save included)")))
	else:
		out.append("A copy of the run, compressed. Decode with `python3 tools/read_report.py <this file>`.")
		out.append(BEGIN)
		out.append(save_blob)
		out.append(END)
	out.append("")
	return "\n".join(out)


## The save text, gzipped and written as base64 in lines of LINE_WIDTH characters.
static func pack_blob(save_text: String) -> String:
	var bytes := save_text.to_utf8_buffer().compress(GZIP_MODE)
	var encoded := Marshalls.raw_to_base64(bytes)
	var lines := PackedStringArray()
	for start in range(0, encoded.length(), LINE_WIDTH):
		lines.append(encoded.substr(start, LINE_WIDTH))
	return "\n".join(lines)


## The inverse of pack_blob(); "" when the block is not a packed save.
static func unpack_blob(blob: String) -> String:
	var joined := blob.replace("\n", "").replace("\r", "").replace(" ", "")
	if joined.is_empty():
		return ""
	var bytes := Marshalls.base64_to_raw(joined)
	if bytes.is_empty():
		return ""
	var raw := bytes.decompress_dynamic(64 * 1024 * 1024, GZIP_MODE)
	return raw.get_string_from_utf8()


## The packed block found in a whole report's text, or "".
static func find_blob(report_text: String) -> String:
	var start := report_text.find(BEGIN)
	var stop := report_text.find(END)
	if start < 0 or stop < 0 or stop < start:
		return ""
	return report_text.substr(start + BEGIN.length(), stop - start - BEGIN.length()).strip_edges()


static func _section(out: PackedStringArray, heading: String, lines: Variant) -> void:
	var items := _as_array(lines)
	if items.is_empty():
		return
	out.append("")
	out.append("## %s" % heading)
	for line: Variant in items:
		out.append("- %s" % str(line))


## Lines may arrive as a plain Array or a PackedStringArray (ActionLog.lines).
static func _as_array(lines: Variant) -> Array:
	if lines is Array:
		return lines as Array
	if lines is PackedStringArray:
		return Array(lines as PackedStringArray)
	return []


static func _label(key: String) -> String:
	match key:
		"build": return "Build"
		"platform": return "Platform"
		"model": return "Phone model"
		"screen": return "Screen"
		"safe": return "Safe-area insets"
		"scene": return "Screen showing"
		"style": return "Display style"
		"text_size": return "Text size"
	return key
