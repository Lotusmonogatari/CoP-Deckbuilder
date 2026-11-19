class_name ReportFiles
extends RefCounted
## Writes a problem report to disk (2026-11-19). One folder per report holding the text, the picture
## of the screen, the marked picture and a copy of the save, and one zip of the same, so a tester
## can pick up a single file. Where the phone allows it, the zip is also copied to the Downloads
## folder, where a person can reach it (the game's own folder is private to the app).
##
## Nothing here knows what a report means; it is handed text, pictures and a name.
## Old reports are removed beyond a limit (only folders and zips this class made).

## File names are written in two parts: the exporter's Text-key check reads any quoted "word.word" as a
## key the code asks for.
const REPORT_TEXT := "report" + ".md"
const SAVE_FILE := "save" + ".json"
const SCREEN_FILE := "screen" + ".png"
const MARKED_FILE := "marked" + ".png"


## `parts`: { "text": String, "screenshot": Image or null, "marked": Image or null, "save_text": String }.
## Returns { "ok": bool, "folder": absolute path, "zip": user:// path, "shared": where the Downloads copy
## went (absolute) or "" }.
static func write(base_dir: String, id: String, parts: Dictionary, keep: int, share: bool = true) -> Dictionary:
	var result := {"ok": false, "folder": "", "zip": "", "shared": ""}
	var folder := base_dir.path_join(id)
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		return result
	result["folder"] = ProjectSettings.globalize_path(folder)
	var names: Array[String] = []
	if _write_text(folder.path_join(REPORT_TEXT), str(parts.get("text", ""))):
		names.append(REPORT_TEXT)
	var save_text := str(parts.get("save_text", ""))
	if not save_text.is_empty() and _write_text(folder.path_join(SAVE_FILE), save_text):
		names.append(SAVE_FILE)
	for pair: Array in [["screenshot", SCREEN_FILE], ["marked", MARKED_FILE]]:
		var image: Variant = parts.get(pair[0])
		if image is Image and not (image as Image).is_empty():
			if (image as Image).save_png(folder.path_join(str(pair[1]))) == OK:
				names.append(str(pair[1]))
	if names.is_empty():
		return result
	var zip_path := base_dir.path_join("%s.zip" % id)
	if _zip(zip_path, folder, names):
		result["zip"] = zip_path
		if share:
			result["shared"] = _share_copy(zip_path, id)
	result["ok"] = true
	prune(base_dir, keep)
	return result


## Removes the oldest reports so that at most `keep` remain.
static func prune(base_dir: String, keep: int) -> void:
	var ids: Array[String] = []
	for name: String in DirAccess.get_directories_at(base_dir):
		ids.append(name)
	ids.sort()
	while ids.size() > maxi(keep, 1):
		var old: String = ids.pop_front()
		var folder := base_dir.path_join(old)
		for file: String in DirAccess.get_files_at(folder):
			DirAccess.remove_absolute(folder.path_join(file))
		DirAccess.remove_absolute(folder)
		DirAccess.remove_absolute(base_dir.path_join("%s.zip" % old))


static func _write_text(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	return true


static func _zip(zip_path: String, folder: String, names: Array[String]) -> bool:
	var packer := ZIPPacker.new()
	if packer.open(zip_path) != OK:
		return false
	for name in names:
		var bytes := FileAccess.get_file_as_bytes(folder.path_join(name))
		packer.start_file(name)
		packer.write_file(bytes)
		packer.close_file()
	packer.close()
	return true


## Copies the zip to the phone's Downloads folder when there is one and it can be written.
static func _share_copy(zip_path: String, id: String) -> String:
	var downloads := OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS)
	if downloads.is_empty() or not DirAccess.dir_exists_absolute(downloads):
		return ""
	var target := downloads.path_join("CoP-report-%s.zip" % id)
	if DirAccess.copy_absolute(zip_path, target) != OK:
		return ""
	return target
