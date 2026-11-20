extends Node
## Screenshots of the Office screens on the shared frame (P13, 2026-11-20), for the review folder
## design/review/p13_office_screens_<date>/. Run under a real display:
##
##   xvfb-run -a -s "-screen 0 1080x2340x24" .tools/godot --path . --resolution 1080x2340 \
##       res://tools/office_screen_shots.tscn -- <screen> <style> <out.png> [text_size] [pressure] [bottom]
##
## screen: administration · style: woodblock | living_office | broadcast · text_size: small | normal | large ·
## pressure: standard | harder (Political Pressure in force) · bottom: scroll the screen to its foot.
## Draws the real screen from a fresh run; changes no saved game.

func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var screen := args[0] if args.size() > 0 else "administration"
	var style := args[1] if args.size() > 1 else UiStyles.LIVING_OFFICE
	var out := args[2] if args.size() > 2 else "/tmp/office_screen.png"
	var size_setting := args[3] if args.size() > 3 else ""
	var pressure := args[4] if args.size() > 4 else ""
	var bottom := args.size() > 5 and args[5] == "bottom"
	GameState.start_new_run("PC01")
	GameState.awaiting_new_game = false
	UiStyle.trying = style
	UiStyle.sync()
	if not size_setting.is_empty():
		Layout.text_size_setting = size_setting
	if pressure == "harder":
		GameState.difficulty = Difficulty.HARDER
	var office := (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate()
	add_child(office)
	await get_tree().process_frame
	await get_tree().create_timer(0.8).timeout
	var menu: Overlay = null
	match screen:
		"administration":
			office._show_administration_menu()
			menu = office.get_node("AdministrationMenuPanel")
		_:
			push_error("unknown screen '%s'" % screen)
			get_tree().quit(1)
			return
	await get_tree().create_timer(0.5).timeout
	if bottom:
		var scroll := menu.find_child("FrameScroll", true, false) as ScrollContainer
		scroll.scroll_vertical = 100000
		await get_tree().create_timer(0.3).timeout
	get_viewport().get_texture().get_image().save_png(out)
	get_tree().quit()
