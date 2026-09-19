extends Node
## Writes the current run to disk and reads it back.
##
## NOT BUILT YET. This is a placeholder so the project structure matches the
## build brief; it gets filled in at milestone M4.
##
## What will live here:
##   - auto-save to user://savegame.json after every stage and at every
##     XP checkpoint
##   - loading a save on startup and resuming mid-module
##   - a version number in the save file, so an old save from an earlier
##     build can be upgraded rather than crashing
##
## Saves go to user://, which Godot maps to the right per-app folder on each
## platform. On a phone that means the app's own sandboxed storage.

func _ready() -> void:
	# Nothing to do until M4.
	pass
