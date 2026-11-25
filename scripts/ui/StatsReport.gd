class_name StatsReport
extends RefCounted
## The run's statistics as something to read (2026-11-25, Cameron): the sections the Your Statistics screen draws and the text file
## the Export report button writes, both from one list so they never disagree. RunStats.gd does the counting; this puts names and
## words to it. Every word is a Text row (stats.*).
##
## A section is {"id", "title", "rows": Array of [label, value], "note": ""}. A section with nothing counted has no rows.

## The file's name is written in two parts (the exporter's Text-key check reads a quoted "word.word" as a key).
const FILE_STEM := "CoP-statistics"
const FILE_EXTENSION := "." + "txt"


## All sections, in the order the screen shows them. `gaffes_made` and `gaffes_lost` come from the run's own totals and
## `activity_totals` is {activity_id: times done}.
static func sections(stats: Dictionary, gaffes_made: int, gaffes_lost: int, activity_totals: Dictionary) -> Array:
	var made: Array = []
	made.append(_suits(stats))
	made.append(_counted("items", Text.say("stats.items_heading"), stats["items"] as Dictionary, _item_name))
	made.append(_counted("people", Text.say("stats.people_heading"), stats["met"] as Dictionary, _person_name))
	made.append(_promises(stats))
	made.append(_section("gaffes", Text.say("stats.gaffes_heading"), [
		[Text.say("stats.gaffes_made"), _n(gaffes_made)], [Text.say("stats.gaffes_lost"), _n(gaffes_lost)]]))
	made.append(_wins(stats))
	made.append(_counted("venues", Text.say("stats.venues_heading"), stats["venues"] as Dictionary, _venue_name))
	made.append(_counted("activities", Text.say("stats.activities_heading"), activity_totals, _activity_name))
	return made


static func _section(id: String, title: String, rows: Array, note: String = "") -> Dictionary:
	return {"id": id, "title": title, "rows": rows, "note": note}


## One row for each counted key, most first (RunStats.ranked); nothing counted leaves the section without rows.
static func _counted(id: String, title: String, counts: Dictionary, name_of: Callable) -> Dictionary:
	var rows: Array = []
	for pair: Array in RunStats.ranked(counts):
		rows.append([str(name_of.call(str(pair[0]))), _n(int(pair[1]))])
	return _section(id, title, rows)


## The suits, with the one played most (or the ones tied) said on top.
static func _suits(stats: Dictionary) -> Dictionary:
	var section := _counted("suits", Text.say("stats.suits_heading"), stats["suits"] as Dictionary, func(suit: String) -> String: return suit)
	var leaders := RunStats.leaders(stats["suits"] as Dictionary)
	if not leaders.is_empty():
		section["note"] = "%s: %s" % [Text.say("stats.suits_most"), ", ".join(leaders)]
	return section


static func _promises(stats: Dictionary) -> Dictionary:
	var counts: Dictionary = stats["promises"]
	return _section("promises", Text.say("stats.promises_heading"), [
		[Text.say("stats.promises_kept"), _n(int(counts[RunStats.PROMISE_KEPT]))],
		[Text.say("stats.promises_broken"), _n(int(counts[RunStats.PROMISE_BROKEN]))]])


static func _wins(stats: Dictionary) -> Dictionary:
	var counts: Dictionary = stats["wins"]
	return _section("wins", Text.say("stats.wins_heading"), [
		[Text.say("stats.win_threshold"), _n(int(counts[RunStats.KIND_THRESHOLD]))],
		[Text.say("stats.win_zero"), _n(int(counts[RunStats.KIND_ZERO]))],
		[Text.say("stats.win_other"), _n(int(counts[RunStats.KIND_OTHER]))]])


static func _n(count: int) -> String:
	return Phrase.with_separators(count)


static func _item_name(item_id: String) -> String:
	return str(DataDB.get_shop_item(item_id).get("name", item_id))


static func _person_name(person_id: String) -> String:
	var opponent := DataDB.get_opponent(person_id)
	if not opponent.is_empty():
		return str(opponent.get("name", person_id))
	var visitor := DataDB.get_visitor(person_id)
	return str(visitor.get("name_en", person_id)) if not visitor.is_empty() else person_id


static func _venue_name(venue_id: String) -> String:
	return str(GameState.venue_row(venue_id).get("name", venue_id))


static func _activity_name(activity_id: String) -> String:
	return str(GameState.venue_activity(activity_id).get("name", activity_id))


## The report as plain text: a title, who played, then each section as a heading and its rows.
static func text(all_sections: Array) -> String:
	var lines: Array[String] = [Text.say("stats.report_title"),
		Text.say("stats.report_player", {"name": str(DataDB.player.get("name_en", ""))}), ""]
	for section: Dictionary in all_sections:
		lines.append(str(section["title"]))
		if not str(section["note"]).is_empty():
			lines.append("  %s" % str(section["note"]))
		var rows: Array = section["rows"]
		if rows.is_empty():
			lines.append("  %s" % Text.say("stats.nothing"))
		for row: Array in rows:
			lines.append("  %s: %s" % [str(row[0]), str(row[1])])
		lines.append("")
	return "\n".join(lines)


## Writes `report` to the game's own folder and, where the phone allows, to its Downloads folder; puts it on the clipboard.
## Returns {"ok", "file": name, "where": "downloads" | "app" | ""}.
static func export(report: String, run_seed: int) -> Dictionary:
	DisplayServer.clipboard_set(report)
	var file_name := "%s-%d%s" % [FILE_STEM, run_seed, FILE_EXTENSION]
	var result := {"ok": false, "file": file_name, "where": ""}
	var path := "user://".path_join(file_name)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return result
	file.store_string(report)
	file.close()
	result["ok"] = true
	result["where"] = "app"
	var downloads := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if not downloads.is_empty() and DirAccess.dir_exists_absolute(downloads):
		if DirAccess.copy_absolute(path, downloads.path_join(file_name)) == OK:
			result["where"] = "downloads"
	return result
