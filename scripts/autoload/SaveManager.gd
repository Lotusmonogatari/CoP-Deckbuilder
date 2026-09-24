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
## Once, at boot. No save means a new player, so GameState is told to show
## the New Game screen.
##
## THE FILE
## { "version": 1, "saved_at": "...", "run": <GameState.to_save()> }, with
## the run encoded by JSON.from_native so every number comes back the same
## type it went in — plain JSON would turn the whole numbers into decimals.
## A save from a newer build than this one is left alone, not overwritten.

const SAVE_PATH := "user://savegame.json"
const VERSION := 1

## False in the test runs and click tests, so they neither read the
## player's real save nor write over it.
var enabled := true


func _ready() -> void:
	enabled = not _is_test_run()
	if not enabled:
		return
	if not load_game():
		GameState.awaiting_new_game = true


## Saves unless a stage is being fought. What every caller should use.
func autosave() -> void:
	if enabled and not GameState.mid_stage and not GameState.awaiting_new_game:
		save_game()


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
	file.store_string(JSON.stringify(payload))
	file.close()
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


## The run stored at `path`, or empty when there is none worth loading.
func read_save(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	var parsed: Variant = json.data if json.parse(FileAccess.get_file_as_string(path)) == OK else null
	if not (parsed is Dictionary):
		push_warning("SaveManager: %s is not a save file; starting fresh." % path)
		return {}
	var version := int((parsed as Dictionary).get("version", 0))
	if version > VERSION:
		# A newer build wrote this. Do not load it, and do not overwrite it.
		push_warning("SaveManager: %s is from a newer version (%d); leaving it alone." % [path, version])
		enabled = false
		return {}
	var run: Variant = JSON.to_native((parsed as Dictionary).get("run"))
	return run if run is Dictionary else {}


func has_save(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)


func delete_save(path: String = SAVE_PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


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
