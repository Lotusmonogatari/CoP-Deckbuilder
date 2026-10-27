extends GutTest
## Every Balance or Rules lever the scripts ask for by name must be a row in
## the workbook's export. A misspelt key silently falls back to the number
## typed in the script, so editing the workbook would do nothing (found
## 2026-10-27: the draft-bill costs and the supermajority share).

const SCRIPT_ROOT := "res://scripts"


func _gd_files(path: String) -> Array[String]:
	var found: Array[String] = []
	for file in DirAccess.get_files_at(path):
		if file.ends_with(".gd"):
			found.append(path + "/" + file)
	for dir in DirAccess.get_directories_at(path):
		found.append_array(_gd_files(path + "/" + dir))
	return found


func _missing(pattern: String, known: Dictionary) -> Array[String]:
	var regex := RegEx.create_from_string(pattern)
	var missing: Array[String] = []
	for file in _gd_files(SCRIPT_ROOT):
		var text := FileAccess.get_file_as_string(file)
		for hit in regex.search_all(text):
			var key := hit.get_string(1)
			if not known.has(key):
				missing.append("%s asks for '%s'" % [file, key])
	return missing


func test_every_balance_key_the_scripts_read_is_in_the_workbook() -> void:
	var missing := _missing("DataDB\\.balance\\.get\\(\"([A-Za-z_0-9]+)\"", DataDB.balance)
	assert_eq(missing, [] as Array[String], "balance keys with no workbook row")


func test_every_rules_key_the_scripts_read_is_in_the_workbook() -> void:
	var missing := _missing("DataDB\\.rules\\.get\\(\"([A-Za-z_0-9]+)\"", DataDB.rules)
	assert_eq(missing, [] as Array[String], "rules keys with no row")


func test_every_lever_a_rules_file_asks_levers_for_is_in_the_workbook() -> void:
	var missing := _missing("Levers\\.(?:num|whole)\\(\"([A-Za-z_0-9]+)\"", DataDB.balance)
	assert_eq(missing, [] as Array[String], "Levers keys with no Balance row")
