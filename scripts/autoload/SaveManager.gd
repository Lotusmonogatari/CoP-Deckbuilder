extends Node
## Writes the current run to disk and reads it back.
##
## One save slot, at user://savegame.json. Godot maps user:// to the app's
## own storage on each platform, so on a phone it is private to the game.
##
## WHEN IT SAVES
##   - after every stage, win or loss (GameState.finish_stage())
##   - whenever the Office opens, and after anything bought or changed there
##   - when the phone sends the game to the background, or the window closes,
##     unless a stage is being fought
## A stage in progress is never saved: coming back mid-stage starts that
## stage again, with the items and standing the player had going in.
##
## WHEN IT LOADS
## When the player presses Continue on the title screen (IntroScreen.gd) —
## not eagerly at boot any more (2026-09-26): the title screen is the
## game's first scene, and reading the save back in is a real, checkable
## action the player takes there, not something that has already silently
## happened by the time anything is drawn. has_save() (a plain file check)
## is all _ready() below still does — enough to grey Continue out or not.
##
## THE FILE
## { "version": 1, "saved_at": "...", "run": <GameState.to_save()> }, with
## the run encoded by JSON.from_native so every number comes back the same
## type it went in — plain JSON would turn the whole numbers into decimals.
## A save from a newer build than this one is left alone, not overwritten.

const SAVE_PATH := "user://savegame.json"
const VERSION := 1
## The one manual backup slot (2026-10-15): written only when the player asks,
## never by autosave, so it survives whatever happens to the main save.
const MANUAL_PATH := "user://savegame.manual.json"
## The run as it was just before the last restore, so one mistaken restore can
## be undone (2026-10-15).
const UNDO_PATH := "user://savegame.undo.json"

## False in the test runs and click tests, so they neither read the
## player's real save nor write over it.
var enabled := true


func _ready() -> void:
	enabled = not _is_test_run()
	if not enabled:
		return
	if not has_save():
		GameState.awaiting_new_game = true


## Saves unless a stage is being fought. What every caller should use.
## `announce` flashes "Saved" on screen once the write succeeds (used after a
## finished stage).
func autosave(announce: bool = false) -> void:
	if enabled and not GameState.mid_stage and not GameState.awaiting_new_game:
		if save_game() and announce:
			Layout.flash(Text.say("save.saved"))


## Writes the manual backup slot. True when written.
func backup_now() -> bool:
	return enabled and not GameState.awaiting_new_game and save_game(MANUAL_PATH)


func has_backup() -> bool:
	return has_save(MANUAL_PATH)


## When the backup was made, as the save file recorded it ("" if none).
func backup_time() -> String:
	if not has_backup():
		return ""
	var parsed: Variant = _parse(MANUAL_PATH)
	if parsed is Dictionary:
		return str((parsed as Dictionary).get("saved_at", "")).replace("T", " ")
	return ""


## Loads the backup into the run and makes it the main save. True on success.
## The run being replaced is first written to UNDO_PATH.
func restore_backup() -> bool:
	return _restore_from(MANUAL_PATH)


func has_undo() -> bool:
	return has_save(UNDO_PATH)


## Puts back the run that was replaced by the last restore. The undo copy is
## spent: a second undo would only swap the two runs back.
func restore_undo() -> bool:
	if not _restore_from(UNDO_PATH, false):
		return false
	delete_save(UNDO_PATH)
	return true


func _restore_from(path: String, keep_undo: bool = true) -> bool:
	if read_save(path).is_empty():
		return false
	if keep_undo and not save_game(UNDO_PATH):
		return false   # never replace a run we could not keep a copy of
	if not load_game(path):
		return false
	save_game()
	return true


## The run stored at `path` (the main save, the backup or the undo copy) as a
## SaveSummary plus its timestamp, or {} when there is none.
func summary_of(path: String) -> Dictionary:
	var run := read_save(path)
	if run.is_empty():
		return {}
	var summary := SaveSummary.of(run)
	var parsed: Variant = _parse(path)
	summary["when"] = str((parsed as Dictionary).get("saved_at", "")).replace("T", " ") \
		if parsed is Dictionary else ""
	return summary


## Why the last read gave nothing: "" (nothing wrong), "unreadable" (the
## file and its backup could not be parsed) or "newer" (a later build wrote
## it). The title screen words this for the player (2026-10-14).
var last_problem := ""


## Writes the run to `path`. True when it was written.
func save_game(path: String = SAVE_PATH) -> bool:
	var payload := {
		"version": VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"run": JSON.from_native(GameState.to_save()),
	}
	# Written beside the real file first and then swapped in, so a phone that
	# dies mid-write leaves the last good save rather than half of a new one.
	var temp_path := path + ".tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: could not write %s (%s)." % [temp_path, FileAccess.get_open_error()])
		return false
	var wrote := file.store_string(JSON.stringify(payload))
	file.close()
	# A full disk can leave a short file; never swap one in over a good save.
	if not wrote or not _parses(temp_path):
		push_warning("SaveManager: %s was not written completely; keeping the last save." % temp_path)
		DirAccess.remove_absolute(temp_path)
		return false
	# The last good save is kept as a backup, so one bad write or a corrupted
	# file is never the end of a run.
	if _parses(path):
		DirAccess.copy_absolute(path, path + ".bak")
	var error := DirAccess.rename_absolute(temp_path, path)
	if error != OK:
		push_warning("SaveManager: could not replace %s (%s)." % [path, error])
		return false
	return true


## Reads `path` into GameState. False, with GameState untouched, when there
## is no save or it cannot be read.
func load_game(path: String = SAVE_PATH) -> bool:
	var saved := read_save(path)
	if saved.is_empty():
		return false
	GameState.load_save(saved)
	return true


## The run stored at `path`, or empty when there is none worth loading. If
## the file itself cannot be read, its backup is tried before giving up.
func read_save(path: String = SAVE_PATH) -> Dictionary:
	last_problem = ""
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = _parse(path)
	if not (parsed is Dictionary) and FileAccess.file_exists(path + ".bak"):
		push_warning("SaveManager: %s could not be read; using its backup." % path)
		parsed = _parse(path + ".bak")
	if not (parsed is Dictionary):
		push_warning("SaveManager: %s is not a save file; starting fresh." % path)
		last_problem = "unreadable"
		return {}
	var version := int((parsed as Dictionary).get("version", 0))
	if version > VERSION:
		# A newer build wrote this. Do not load it, and do not overwrite it.
		push_warning("SaveManager: %s is from a newer version (%d); leaving it alone." % [path, version])
		enabled = false
		last_problem = "newer"
		return {}
	var run: Variant = JSON.to_native((parsed as Dictionary).get("run"))
	if not (run is Dictionary) or (run as Dictionary).is_empty():
		last_problem = "unreadable"
		return {}
	return run


func _parse(path: String) -> Variant:
	var json := JSON.new()
	return json.data if json.parse(FileAccess.get_file_as_string(path)) == OK else null


## True when `path` holds a JSON object with a run in it.
func _parses(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = _parse(path)
	return parsed is Dictionary and (parsed as Dictionary).get("run") is Dictionary


func has_save(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)


func delete_save(path: String = SAVE_PATH) -> void:
	for file_path: String in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(file_path):
			DirAccess.remove_absolute(file_path)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		autosave()


## The unit tests, the click tests and the screenshot tools run the game
## with a scene or script from tests/ or tools/; none must touch the
## player's real save.
static func _is_test_run() -> bool:
	for arg: String in OS.get_cmdline_args():
		var path := arg.trim_prefix("res://")
		if arg.contains("gut_cmdln") or path.begins_with("tests/") or path.begins_with("tools/"):
			return true
	return false
