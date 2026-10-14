class_name StageStartFailure
extends RefCounted
## What a stage screen shows when the stage cannot start (2026-10-14).
##
## Before this, a battle, visitor or vote screen whose stage could not be
## built only put up a message that faded away and disabled its controls,
## leaving the player on a dead screen with no way out (and Resume loaded
## the same screen again). This puts a full-screen notice over the screen
## with the reason and one button that ends the level and goes back to
## the Office. Standalone runs (not in a level) just quit, like the
## screens' own outcome panels.

const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"


## Builds the notice on top of `screen` and returns it. `reason` is shown
## under the title, already worded by the caller.
static func show_on(screen: Control, reason: String) -> Control:
	var cover := ColorRect.new()
	cover.name = "StageStartFailure"
	cover.color = Color(0.05, 0.04, 0.04, 0.96)
	cover.set_anchors_preset(Control.PRESET_FULL_RECT)
	cover.mouse_filter = Control.MOUSE_FILTER_STOP

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 60)
	cover.add_child(margin)

	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 36)
	margin.add_child(column)

	var title := Label.new()
	title.text = Text.say("stage.cannot_start_title")
	title.theme_type_variation = "HeaderLabel"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var body := Label.new()
	body.text = reason
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(body)

	var leave := Button.new()
	leave.name = "LeaveButton"
	leave.text = Text.say("stage.cannot_start_leave")
	leave.custom_minimum_size = Vector2(0, 110)
	leave.pressed.connect(_leave.bind(screen))
	column.add_child(leave)

	screen.add_child(cover)
	return cover


static func _leave(screen: Control) -> void:
	if not GameState.is_in_level():
		screen.get_tree().quit()
		return
	GameState.end_level()
	screen.get_tree().change_scene_to_file(OFFICE_SCENE)
