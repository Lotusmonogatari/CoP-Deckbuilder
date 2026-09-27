class_name LevelIntroDriver
extends Node
## Walks the Level Intro screen with real clicks, on both sides of its
## whole point: it shows when a hired staff member has something written
## for the level, and it is SKIPPED ENTIRELY — straight to the first real
## stage — when nobody does (CLAUDE.md §7.8).
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/level_intro_test.tscn
##
## data/level_intros.json has no real rows yet (Cameron hasn't written any),
## so this hires a real staff member and injects one fake row into
## DataDB.level_intros in memory only — never touching the workbook, the
## same technique used to verify this feature end to end before it shipped.
## Two real, freely-unlocked Tier-0 levels (LV01, LV02 — both have an
## unlock_cost_vacant of 0) stand in for "nothing written" and "something
## written" so the same run proves both halves of the feature.
##
## Picks the level directly (office.call("_on_level_chosen", ...)) rather
## than clicking through the Levels list first — loop_driver.gd already
## proves that list and its briefing work; every click here from "Go in"
## onward is real, on the actual OfficeScreen code this feature added.
##
## Added 2026-09-28: before this, no interaction test ever opened
## LevelIntroScreen.tscn at all (design/MECHANIC_COVERAGE.md).

const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"
const SKIP_LEVEL_ID := "LV01"
const SHOW_LEVEL_ID := "LV02"
const ROLE := "Policy Research Assistant"

var _failures: PackedStringArray = []
var _hired_staff_id := ""
var _hired_staff_name := ""


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	# A real candidate for the role, not a fabricated one, the same "only
	# the cue row is fake" bargain the feature's own content prompt asks
	# Cameron to keep.
	for candidate: Dictionary in DataDB.staff:
		if str(candidate.get("role", "")) == ROLE:
			_hired_staff_id = str(candidate["staff_id"])
			_hired_staff_name = str(candidate.get("name", _hired_staff_id))
			break
	if _hired_staff_id.is_empty():
		_failures.append("no real '%s' candidate exists in staff.json" % ROLE)
		_finish()
		return
	GameState.staff_hired[ROLE] = {"staff_id": _hired_staff_id, "tier": 0}

	get_tree().change_scene_to_file(OFFICE_SCENE)
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout

	if not await _check_skips_when_nothing_written():
		_finish()
		return
	if not await _check_shows_when_something_is_written():
		_finish()
		return

	_finish()


func _finish() -> void:
	GameState.staff_hired.erase(ROLE)
	DataDB.level_intros.clear()
	print("")
	if _failures.is_empty():
		print("LEVEL INTRO TEST: PASS")
		get_tree().quit(0)
	else:
		print("LEVEL INTRO TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


## LV01 has no level_intros row for the hired role — "Go in" should land
## straight on LV01's own first real stage (ST05, Town Hall), never on the
## Level Intro screen.
func _check_skips_when_nothing_written() -> bool:
	var office := get_tree().current_scene
	if office == null or office.name != "OfficeScreen":
		_failures.append("the game did not start in the Office")
		return false

	if not await _go_in_on(office, SKIP_LEVEL_ID):
		return false

	var landed := get_tree().current_scene
	if landed == null or landed.name == "LevelIntroScreen":
		_failures.append("%s has nothing written, but Go In still opened the Level Intro screen"
			% SKIP_LEVEL_ID)
		return false
	if landed.name != "BattleScreen":
		_failures.append("%s: expected its real first stage (a battle), landed on %s"
			% [SKIP_LEVEL_ID, landed.name if landed else "(null)"])
		return false
	print("  %s (nothing written): Go In skipped straight to %s" % [SKIP_LEVEL_ID, landed.name])

	GameState.end_level()
	get_tree().change_scene_to_file(OFFICE_SCENE)
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	return true


## LV02 gets one fake cue for the hired role, in memory only. "Go in" must
## open the Level Intro screen with the real hired staffer's portrait and
## name, and "Let's go" must land on LV02's real first stage.
func _check_shows_when_something_is_written() -> bool:
	DataDB.level_intros.append({
		"level_id": SHOW_LEVEL_ID, "role": ROLE, "cue_text": "Every seat counts today.",
	})

	var office := get_tree().current_scene
	if not await _go_in_on(office, SHOW_LEVEL_ID):
		return false

	var screen := get_tree().current_scene
	if screen == null or screen.name != "LevelIntroScreen":
		_failures.append("%s has a written cue, but Go In did not open the Level Intro screen (got %s)"
			% [SHOW_LEVEL_ID, screen.name if screen else "(null)"])
		return false
	print("  %s (cue written): Go In opened the Level Intro screen" % SHOW_LEVEL_ID)

	var portrait: PlaceholderArt = screen.get_node("%Portrait")
	var name_label: Label = screen.get_node("%StaffName")
	if portrait.art_id != _hired_staff_id:
		_failures.append("the portrait shows '%s', not the hired staffer '%s'"
			% [portrait.art_id, _hired_staff_id])
		return false
	if name_label.text != _hired_staff_name:
		_failures.append("the name label reads '%s', not '%s'" % [name_label.text, _hired_staff_name])
		return false
	print("  showing the real hired staffer: %s (%s)" % [_hired_staff_name, _hired_staff_id])

	var banner: Node = screen.get_node("CueBanner")
	await get_tree().create_timer(0.3).timeout
	var shown := str(banner.call("current_line"))
	if shown != "Every seat counts today.":
		_failures.append("the banner shows '%s', not the written cue" % shown)
		return false
	print("  banner shows the written cue")

	if not await _click(screen.get_node("%ContinueButton")):
		return false
	await get_tree().create_timer(0.6).timeout

	var landed := get_tree().current_scene
	if landed == null or landed.name != "BattleScreen":
		_failures.append("'Let's go' did not land on %s's real first stage (got %s)"
			% [SHOW_LEVEL_ID, landed.name if landed else "(null)"])
		return false
	print("  'Let's go' landed on %s's real first stage" % SHOW_LEVEL_ID)

	GameState.end_level()
	return true


## Picks `level_id` directly (loop_driver.gd already proves the Levels
## list + briefing chain), then presses the briefing's own real Confirm
## button — the actual "Go in" click this feature's routing runs on.
func _go_in_on(office: Node, level_id: String) -> bool:
	var level := DataDB.get_level(level_id)
	office.call("_on_level_chosen", level)
	await get_tree().create_timer(0.3).timeout

	var briefing := office.get_node("%BriefingPanel") as Overlay
	if briefing == null or not briefing.visible:
		_failures.append("%s: choosing it did not open the briefing" % level_id)
		return false

	var go_in := briefing.find_child("Confirm", true, false) as Button
	if go_in == null or not go_in.visible:
		_failures.append("%s: the briefing had no way in" % level_id)
		return false

	if not await _click(go_in):
		return false
	await get_tree().create_timer(0.6).timeout
	return true


func _click(control: Control) -> bool:
	await get_tree().process_frame
	var rect := control.get_global_rect()
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		_failures.append("%s has no size, so nothing could click it" % control.name)
		return false

	var where: Vector2 = get_viewport().get_screen_transform() * rect.get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = where
		event.global_position = where
		Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().process_frame
	return true
