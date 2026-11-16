extends Node
## Audit C-9: where does DataDB's load time go? Times each data file's read and
## parse on its own, then the whole DataDB.load_all().
func _ready() -> void:
	var rows := []
	var total_parse := 0
	for file in DirAccess.get_files_at("res://data"):
		if not file.ends_with(".json"):
			continue
		var started := Time.get_ticks_usec()
		var text := FileAccess.get_file_as_string("res://data/" + file)
		var read_us := Time.get_ticks_usec() - started
		started = Time.get_ticks_usec()
		var json := JSON.new()
		json.parse(text)
		var parse_us := Time.get_ticks_usec() - started
		total_parse += parse_us
		rows.append([parse_us, read_us, text.length(), file])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	for row in rows.slice(0, 8):
		print("PROFILE parse %6.1f ms  read %5.1f ms  %6d KB  %s" % [row[0] / 1000.0, row[1] / 1000.0, row[2] / 1024, row[3]])
	print("PROFILE all files parsed: %.1f ms" % (total_parse / 1000.0))
	var times := []
	for i in 5:
		var started := Time.get_ticks_usec()
		DataDB.load_all()
		times.append((Time.get_ticks_usec() - started) / 1000.0)
	print("PROFILE DataDB.load_all() x5 (ms): ", times)
	get_tree().quit(0)
