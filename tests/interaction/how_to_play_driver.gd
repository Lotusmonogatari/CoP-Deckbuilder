class_name HowToPlayDriver
extends Node
## Opens the How to Play guide with real clicks from BOTH places it lives —
## the title screen and the Office — and checks the same guide appears in
## each: the seeded entries under their group headings, every live {token}
## filled in, and a screenshot or video the workbook names but nobody has
## drawn yet showing a labelled placeholder rather than nothing.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/how_to_play_test.tscn

const INTRO_SCENE := "res://scenes/menus/IntroScreen.tscn"
const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"

## A row the real workbook does not have: names a screenshot and a video that
## do not exist, so the placeholder path is exercised on purpose.
const MEDIA_ROW := {
	"entry_id": "HT_TEST", "order": 99999.0, "group": "Test group",
	"heading_en": "Test entry", "heading_jp": "試験", "body_en": "Test body {majority}.",
	"screenshot": "no_such_screenshot", "caption": "A caption.", "video": "no_such_video",
}

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveManager.delete_save()
	DataDB.how_to_play.append(MEDIA_ROW)

	await _from_the_title_screen()
	await _from_the_office()

	DataDB.how_to_play = DataDB.how_to_play.filter(
		func(row: Dictionary) -> bool: return str(row.get("entry_id", "")) != "HT_TEST")
	SaveManager.delete_save()

	print("")
	if _failures.is_empty():
		print("HOW TO PLAY TEST: PASS")
		get_tree().quit(0)
	else:
		print("HOW TO PLAY TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _from_the_title_screen() -> void:
	get_tree().change_scene_to_file(INTRO_SCENE)
	await get_tree().process_frame
	await get_tree().create_timer(0.4).timeout

	var intro := get_tree().current_scene
	var button := intro.find_child("HowToPlayButton", true, false) as Button
	if button == null:
		_failures.append("the title screen has no How to Play button")
		return
	if button.text != Text.say("intro.how_to_play"):
		_failures.append("the title screen's button reads '%s'" % button.text)
	print("  the title screen has a How to Play button")

	await _click(button)
	await get_tree().create_timer(0.3).timeout
	var panel := intro.get_node("HowToPlayPanel") as Overlay
	if panel == null or not panel.visible:
		_failures.append("the title screen's button did not open the guide")
		return
	print("  the title screen's button opened the guide")

	_check_guide(panel, "title screen")

	await _click_back(panel)
	await get_tree().create_timer(0.2).timeout
	if panel.visible:
		_failures.append("Back did not close the guide on the title screen")
		return
	if get_tree().current_scene.name != "IntroScreen":
		_failures.append("closing the guide left the title screen")
		return
	print("  Back closed the guide and stayed on the title screen")


func _from_the_office() -> void:
	GameState.start_new_run("PC02")
	get_tree().change_scene_to_file(OFFICE_SCENE)
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout

	var office := get_tree().current_scene
	# How to Play now lives in the Administration menu (2026-10-06).
	await _click(office.find_child("AdministrationButton", true, false) as Control)
	await get_tree().create_timer(0.3).timeout
	var button := office.find_child("HowToPlayButton", true, false) as Button
	if button == null:
		_failures.append("the Office has no How to Play button")
		return
	if button.text != Text.say("office.how_to_play"):
		_failures.append("the Office's button reads '%s'" % button.text)
	print("  the Office has a How to Play button")

	await _click(button)
	await get_tree().create_timer(0.3).timeout
	var panel := office.get_node("HowToPlayPanel") as Overlay
	if panel == null or not panel.visible:
		_failures.append("the Office's button did not open the guide")
		return
	print("  the Office's button opened the guide")

	_check_guide(panel, "Office")

	await _click_back(panel)
	await get_tree().create_timer(0.2).timeout
	if panel.visible:
		_failures.append("Back did not close the guide in the Office")
		return
	print("  Back closed the guide in the Office")


## What the guide must show wherever it was opened from.
func _check_guide(panel: Overlay, where: String) -> void:
	var texts := PackedStringArray()
	for label in panel.find_children("", "Label", true, false):
		texts.append((label as Label).text)
	var everything := "\n".join(texts)

	# The real seeded guide, by its group headings.
	for group: Dictionary in HowToPlay.grouped(DataDB.how_to_play):
		var name := str(group["group"])
		if not name.is_empty() and not everything.contains(name):
			_failures.append("the %s guide is missing the group '%s'" % [where, name])
	if not everything.contains("Winning a debate"):
		_failures.append("the %s guide has no 'Winning a debate' entry" % where)
	if not everything.contains("Losing a debate"):
		_failures.append("the %s guide has no 'Losing a debate' entry" % where)

	# Live tokens are filled: the real Floor Debate majority is quoted.
	var tokens := HowToPlay.live_tokens(DataDB.stages, DataDB.rules)
	if not everything.contains("needs %s of %s seats" % [tokens["majority"], tokens["seats"]]):
		_failures.append("the %s guide did not fill in the Floor Debate's seat numbers" % where)
	for label_text in texts:
		for name in HowToPlay.TOKEN_NAMES:
			if label_text.contains("{%s}" % name):
				_failures.append("the %s guide shows an unfilled {%s}" % [where, name])

	# The row naming media that does not exist: labelled placeholders.
	if not everything.contains("howto/no_such_screenshot.png"):
		_failures.append("the %s guide shows no placeholder for a missing screenshot" % where)
	if not everything.contains("howto/no_such_video.ogv"):
		_failures.append("the %s guide shows no placeholder for a missing video" % where)
	if not everything.contains("A caption."):
		_failures.append("the %s guide dropped an entry's caption" % where)
	print("  the %s guide shows the groups, filled numbers and placeholders" % where)


## The guide is longer than the screen, so Back is below the fold: scroll it
## into view the way a player would, then click it.
func _click_back(panel: Overlay) -> void:
	var back := panel.find_child("Back", true, false) as Control
	var scroll := panel.find_child("Scroll", true, false) as ScrollContainer
	if back != null and scroll != null:
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
		await get_tree().process_frame
		await get_tree().process_frame
	await _click(back)
	await get_tree().create_timer(0.2).timeout


func _click(control: Control) -> void:
	if control == null:
		_failures.append("a button this test needed does not exist")
		return
	await get_tree().process_frame
	var where: Vector2 = get_viewport().get_screen_transform() * control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = where
		event.global_position = where
		Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().create_timer(0.15).timeout
