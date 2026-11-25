class_name AdministrationModel
extends RefCounted
## What the Administration screen shows (P13, 2026-11-20), as plain data: four groups of rows (Display, Appearance and
## Music, Save, Help) and the Political Pressure box. Each row has a label, a current value and the action a tap runs.
##
## This reads the same sources the old menu's buttons read (Layout, GameState, SaveManager, Reporter) and says nothing
## the old buttons did not; AdministrationView only draws it. The actions arrive as Callables from the Office, which
## owns the panels they open.

## A row that a tap runs. `node` is the Button's name (the names the old menu used, so a click test finds it still).
static func _row(node: String, label: String, value: String, press: Callable) -> Dictionary:
	return {"node": node, "label": label, "value": value, "press": press}


## The groups and the pressure box. `actions` carries:
##   redraw, open_cosmetics, open_how_to_play, open_characters, open_statistics, load_main, load_second, backup_undo, new_game
##   (Callables), and pressure (a dictionary: title, now, blurb, button).
static func build(actions: Dictionary) -> Dictionary:
	var redraw: Callable = actions["redraw"]
	var display: Array = [
		_row("TextSizeButton", Text.say("admin.label_text_size"), SettingsRows.text_size_word(),
			_flip.bind(Layout.cycle_text_size, redraw)),
		_row("ScrollSpeedButton", Text.say("admin.label_scroll_speed"), str(Layout.scroll_speed_level),
			_flip.bind(Layout.cycle_scroll_speed, redraw)),
		_row("ImageScrollButton", Text.say("admin.label_image_scroll"),
			SettingsRows.on_off_word(Layout.image_scroll_enabled), _flip.bind(Layout.toggle_image_scroll, redraw)),
		_row("ImagePanButton", Text.say("admin.label_image_pan"),
			SettingsRows.on_off_word(Layout.image_pan_enabled), _flip.bind(Layout.toggle_image_pan, redraw)),
	]
	var appearance: Array = [
		_row("CosmeticsButton", Text.say("office.cosmetics_slot_background"),
			_equipped_name(CosmeticPieces.BACKGROUND), actions["open_cosmetics"]),
		_row("CosmeticsMusicButton", Text.say("office.cosmetics_slot_music"),
			_equipped_name(CosmeticPieces.MUSIC), actions["open_cosmetics"]),
		_row("CosmeticsCalendarButton", Text.say("office.cosmetics_slot_calendar"),
			_equipped_name(CosmeticPieces.CALENDAR), actions["open_cosmetics"]),
	]
	# Two save files (2026-11-25, Cameron): the main one is written on every save, the second on every other save. Each row loads
	# one, and shows when it was written; a row appears only once its file exists. Undo shows only while there is something to undo.
	var save: Array = [{"node": "SaveSlotsNote", "label": Text.say("admin.slots_title"), "value": "", "press": Callable(),
		"hints": [Text.say("admin.slots_hint")]}]
	if SaveManager.has_save():
		save.append(_row("SaveMainButton", Text.say("admin.slot_main", {"when": _stamp(SaveManager.save_path)}),
			Text.say("admin.chip_load"), actions["load_main"]))
	if SaveManager.has_second():
		save.append(_row("SaveSecondButton", Text.say("admin.slot_second", {"when": _stamp(SaveManager.second_path())}),
			Text.say("admin.chip_load"), actions["load_second"]))
	if SaveManager.has_undo():
		save.append(_row("BackupUndoButton", Text.say("office.backup_undo"), Text.say("admin.chip_undo"),
			actions["backup_undo"]))
	save.append(_row("NewGameMenuButton", Text.say("office.new_game"), Text.say("office.new_game_confirm"), actions["new_game"]))
	var help: Array = [
		_row("HowToPlayButton", Text.say("office.how_to_play"), Text.say("admin.chip_open"), actions["open_how_to_play"]),
		_row("CharactersButton", Text.say("office.characters"), Text.say("admin.chip_open"), actions["open_characters"]),
		_row("StatisticsButton", Text.say("admin.label_statistics"), Text.say("admin.chip_open"), actions["open_statistics"]),
	]
	# Reporting a problem is a gesture, not a button: its row says how, from the Reporter's own lines.
	var hints := Reporter.hint_lines()
	if not hints.is_empty():
		help.append({"node": "ReportRow", "label": Text.say("report.form_title"), "value": "", "press": Callable(),
			"hints": hints})
	return {
		"groups": [
			{"id": "display", "title": Text.say("admin.group_display"), "rows": display},
			{"id": "appearance", "title": Text.say("office.cosmetics"), "rows": appearance},
			{"id": "save", "title": Text.say("admin.group_save"), "rows": save},
			{"id": "help", "title": Text.say("admin.group_help"), "rows": help},
		],
		"pressure": actions["pressure"],
	}


## When a save file was written, as "YY.MM.DD HH:MM" (the game's date style), or a dash when it cannot be read.
static func _stamp(path: String) -> String:
	var written := str(SaveManager.summary_of(path).get("when", ""))   # "2026-11-25 07:37:12"
	if written.length() < 16:
		return "-"
	return "%s.%s.%s %s" % [written.substr(2, 2), written.substr(5, 2), written.substr(8, 2), written.substr(11, 5)]


## Flips a setting, then redraws the screen (the old menu's buttons did exactly this).
static func _flip(flip: Callable, redraw: Callable) -> void:
	flip.call()
	redraw.call()


## The name of what is equipped in a slot: the package's name, or "Default" when nothing is.
static func _equipped_name(slot: String) -> String:
	var package_id := str(GameState.active_cosmetics.get(slot, ""))
	if package_id.is_empty():
		return Text.say("office.cosmetics_default")
	var name := CosmeticPieces.field(DataDB.get_cosmetic_package(package_id), "name_en")
	return package_id if name.is_empty() else name
