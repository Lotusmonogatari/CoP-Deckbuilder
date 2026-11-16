extends GutTest
## Audit C-6 (2026-11-16): a design number is read from the workbook through
## Levers, never with a number typed beside it in a script. A fallback such as
## balance.get("key", 50000) kept answering with a stale number the day a lever
## was renamed or removed; 83 of them disagreed with the workbook.

func _files(path: String) -> Array[String]:
	var found: Array[String] = []
	for file in DirAccess.get_files_at(path):
		if file.ends_with(".gd"):
			found.append(path + "/" + file)
	for dir in DirAccess.get_directories_at(path):
		found.append_array(_files(path + "/" + dir))
	return found


func test_no_script_gives_DataDB_balance_a_typed_fallback() -> void:
	var regex := RegEx.create_from_string("DataDB\\.balance\\.get\\([^)]*,")
	var offenders: Array[String] = []
	for path: String in _files("res://scripts"):
		var lines := FileAccess.get_file_as_string(path).split("\n")
		for number in lines.size():
			var code := (lines[number] as String).split("#")[0]
			if regex.search(code) != null:
				offenders.append("%s:%d" % [path, number + 1])
	assert_eq(offenders, [] as Array[String], "use Levers.whole(\"key\") or Levers.num(\"key\")")
