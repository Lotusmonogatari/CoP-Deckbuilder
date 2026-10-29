extends Node
## Loads every script under scripts/, tools/ and tests/ so a parse error anywhere
## (a removed constant, a renamed function) fails the build instead of waiting
## for the day someone runs that file (2026-10-29). Run by tools/verify.sh:
##     godot --headless --path . tools/compile_check.tscn
## It runs as a scene (not -s) so the autoloads exist, as they do in the game.
## Exits 1 and lists each file that did not load.

const FOLDERS := ["res://scripts", "res://tools", "res://tests"]
## This file itself, and the playtest fixtures GUT loads on its own, are fine
## to skip; everything else must load.


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var failed: PackedStringArray = []
	var checked := 0
	for folder: String in FOLDERS:
		for path: String in _scripts_under(folder):
			if path == "res://tools/compile_check.gd":
				continue
			checked += 1
			# A script with a bad member name loads but cannot be instantiated.
			var script := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
			if script == null or not script.can_instantiate():
				failed.append(path)
	print("compile check: %d scripts, %d failed" % [checked, failed.size()])
	for path in failed:
		print("  DID NOT LOAD: " + path)
	get_tree().quit(1 if failed.size() > 0 else 0)


func _scripts_under(folder: String) -> PackedStringArray:
	var found: PackedStringArray = []
	var dir := DirAccess.open(folder)
	if dir == null:
		return found
	for sub in dir.get_directories():
		found.append_array(_scripts_under(folder.path_join(sub)))
	for file in dir.get_files():
		if file.ends_with(".gd"):
			found.append(folder.path_join(file))
	return found
