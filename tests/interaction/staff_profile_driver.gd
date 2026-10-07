class_name StaffProfileDriver
extends Node
## Opens a candidate's profile from the Staff list with real clicks, checks it
## shows every tier with its bonuses and upgrade cost, hires from it, then
## reopens the hired person's profile to upgrade and reach Fire.
##
## Run it with:
##     xvfb-run .tools/godot --path . tests/interaction/staff_profile_test.tscn

const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"
## A real candidate with three tiers and two priced upgrades.
const CANDIDATE := "SF04"

var _failures: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	SaveManager.delete_save()
	GameState.start_new_run("PC02")
	GameState.staff_recruitment_tier = 2
	GameState.meta["Funds"] = 400000
	get_tree().change_scene_to_file(OFFICE_SCENE)
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	var office := get_tree().current_scene

	await _click(office.get_node("%ManagementButton"))
	var management := office.get_node("%ManagementPanel") as Overlay
	await _click(_button_with_text(management, Text.say("office.staff")))
	var staff := office.get_node("%StaffPanel") as Overlay
	if not staff.visible:
		_failures.append("the Staff screen did not open")
		return _finish()

	var candidate := DataDB.get_staff(CANDIDATE)
	var opener := staff.find_child("Profile_" + CANDIDATE, true, false) as Button
	if opener == null:
		_failures.append("the Staff list has no profile button for %s" % CANDIDATE)
		return _finish()
	if staff.find_child("ProfileHireButton", true, false) != null:
		_failures.append("the list itself still carries a Hire button")
	print("  the list offers a profile button instead of Hire")

	await _click(opener)
	var profile := office.get_node("StaffProfilePanel") as Overlay
	if not profile.visible:
		_failures.append("tapping the candidate did not open the profile")
		return _finish()
	_check_tiers(profile, candidate, -1)
	print("  the profile shows every tier, its bonuses and its upgrade costs")

	var hire := profile.find_child("ProfileHireButton", true, false) as Button
	if hire == null or hire.disabled:
		_failures.append("the profile's Hire button is missing or disabled with funds to spare")
		return _finish()
	await _click(hire)
	var role := str(candidate.get("role", ""))
	if str(GameState.staff_hired.get(role, {}).get("staff_id", "")) != CANDIDATE:
		_failures.append("Hire on the profile did not hire %s" % CANDIDATE)
		return _finish()
	if profile.visible:
		_failures.append("the profile stayed open after hiring")
	print("  Hire on the profile hired them and closed it")

	# The hired person's own profile: current tier marked, Upgrade and Fire.
	var hired_opener := staff.find_child("Profile_" + CANDIDATE, true, false) as Button
	if hired_opener == null:
		_failures.append("the hired person has no profile button in the list")
		return _finish()
	await _click(hired_opener)
	_check_tiers(profile, candidate, 0)
	var upgrade := profile.find_child("ProfileUpgradeButton", true, false) as Button
	if upgrade == null or upgrade.disabled:
		_failures.append("the hired profile has no usable Upgrade button")
		return _finish()
	await _click(upgrade)
	if int(GameState.staff_hired.get(role, {}).get("tier", -1)) != 1:
		_failures.append("Upgrade on the profile did not reach tier 1")
		return _finish()
	print("  Upgrade on the profile reached the next tier")

	await _click(staff.find_child("Profile_" + CANDIDATE, true, false) as Button)
	var fire := profile.find_child("ProfileFireButton", true, false) as Button
	if fire == null or fire.disabled:
		_failures.append("the hired profile has no usable Fire button")
		return _finish()
	await _click(fire)
	var warning := office.get_node("FireStaffPanel") as Overlay
	if not warning.visible:
		_failures.append("Fire on the profile did not open the severance warning")
	if profile.visible:
		_failures.append("the profile stayed open behind the severance warning")
	print("  Fire on the profile opened the severance warning")
	_finish()


## Every tier the candidate can be at is on the profile, with its bonuses,
## and a tier still to be bought says what it costs.
func _check_tiers(profile: Overlay, candidate: Dictionary, current_tier: int) -> void:
	var everything := _all_text(profile)
	for entry: Dictionary in StaffProfile.tiers(candidate, DataDB.boosters, DataDB.segments, Text.phrase()):
		var box := profile.find_child("Tier_%d" % int(entry["tier"]), true, false)
		if box == null:
			_failures.append("the profile has no row for tier %d" % int(entry["tier"]))
			continue
		var text := _all_text(box)
		for line: String in entry["lines"]:
			if not text.contains(line):
				_failures.append("tier %d is missing its bonus '%s'" % [int(entry["tier"]), line])
		if entry["cost"] != null and int(entry["tier"]) > current_tier \
				and not text.contains(str(int(entry["cost"]))):
			_failures.append("tier %d does not show its upgrade cost" % int(entry["tier"]))
	if current_tier >= 0 and not _all_text(profile.find_child("Tier_%d" % current_tier, true, false)) \
			.contains(Text.say("staff.tier_current", {"tier": current_tier})):
		_failures.append("the current tier is not marked as current")
	if not everything.contains(str(candidate.get("role", ""))):
		_failures.append("the profile does not name the role")


func _all_text(root: Node) -> String:
	var parts := PackedStringArray()
	for label in root.find_children("", "Label", true, false):
		parts.append((label as Label).text)
	return "\n".join(parts)


func _button_with_text(root: Node, text: String) -> Button:
	for button in root.find_children("", "Button", true, false):
		if (button as Button).text == text:
			return button as Button
	return null


func _finish() -> void:
	SaveManager.delete_save()
	print("")
	if _failures.is_empty():
		print("STAFF PROFILE TEST: PASS")
		get_tree().quit(0)
	else:
		print("STAFF PROFILE TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


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
	await get_tree().create_timer(0.2).timeout
