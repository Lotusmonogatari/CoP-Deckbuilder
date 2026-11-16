extends GutTest
## scripts/rules/ must not reach the autoloads or the file system (CLAUDE.md
## section 5, "tests prove it"). Added 2026-11-16 after the audit found
## PatronVisit.gd calling DataDB and Text.

const FORBIDDEN := ["DataDB.", "GameState.", "SaveManager.", "EventBus.", "Audio.", "Layout.", "Text.say", "Text.phrase",
	"FileAccess.", "DirAccess.", "get_tree(", "extends Node", "extends Control"]


func _files(path: String) -> Array[String]:
	var found: Array[String] = []
	for file in DirAccess.get_files_at(path):
		if file.ends_with(".gd"):
			found.append(path + "/" + file)
	return found


func test_no_rules_file_reaches_an_autoload_or_a_file() -> void:
	var offenders: Array[String] = []
	for path: String in _files("res://scripts/rules"):
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for number in lines.size():
			var code := (lines[number] as String).split("#")[0]
			if code.strip_edges().is_empty():
				continue
			for word: String in FORBIDDEN:
				if code.contains(word):
					offenders.append("%s:%d uses %s" % [path, number + 1, word])
	assert_eq(offenders, [] as Array[String], "rules files reaching outside the rules layer")
