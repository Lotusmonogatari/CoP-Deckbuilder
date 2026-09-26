class_name OfficeNotices
extends RefCounted
## Resolves data/office_notices.json against the current save: which lines
## are true right now, one at most per "slot" so the Office never shows two
## lines fighting over the same subject (e.g. two different verdicts on the
## front desk). The first row in workbook order whose condition holds wins
## its slot — there is no priority column (CLAUDE.md's own schema note).
##
## Pure and UI-free (CLAUDE.md §12): everything it needs is passed in, no
## autoload access, so it is tested headless like every other rules file.


## The resolved lines, in the order their slots were first seen.
static func resolve(notices: Array, staff_hired: Dictionary, meta: Dictionary,
		staff_directory: Array) -> Array[String]:
	var chosen_by_slot: Dictionary = {}
	var slot_order: Array[String] = []
	for row: Dictionary in notices:
		var slot := str(row.get("slot", ""))
		if chosen_by_slot.has(slot):
			continue
		if not _condition_met(row, staff_hired, meta):
			continue
		chosen_by_slot[slot] = _fill_staff_token(
			str(row.get("text_en", "")), row, staff_hired, staff_directory)
		slot_order.append(slot)

	var lines: Array[String] = []
	for slot: String in slot_order:
		lines.append(str(chosen_by_slot[slot]))
	return lines


static func _condition_met(row: Dictionary, staff_hired: Dictionary, meta: Dictionary) -> bool:
	match str(row.get("condition_type", "")):
		"staff_role":
			return _staff_condition_met(row, staff_hired)
		"meta":
			return _meta_condition_met(row, meta)
		"always":
			return true
		_:
			return false


static func _staff_condition_met(row: Dictionary, staff_hired: Dictionary) -> bool:
	var role := str(row.get("condition_target", ""))
	var hired: Dictionary = staff_hired.get(role, {})
	match str(row.get("condition_op", "")):
		"hired":
			return not hired.is_empty()
		"not_hired":
			return hired.is_empty()
		_:
			return false


static func _meta_condition_met(row: Dictionary, meta: Dictionary) -> bool:
	var name := str(row.get("condition_target", ""))
	var value: Variant = row.get("condition_value")
	if value == null:
		return false
	var target := float(value)
	var current := float(meta.get(name, 0))
	match str(row.get("condition_op", "")):
		"<": return current < target
		"<=": return current <= target
		">": return current > target
		">=": return current >= target
		"=": return current == target
		_: return false


## "{staff}" in a staff_role row's own text becomes the actual candidate's
## name — the row itself doesn't say who, only which role, so the name has
## to be looked up through staff_hired -> staff_directory the same way the
## Office's own staff screen already does.
static func _fill_staff_token(text: String, row: Dictionary, staff_hired: Dictionary,
		staff_directory: Array) -> String:
	if not text.contains("{staff}"):
		return text
	var role := str(row.get("condition_target", ""))
	var hired: Dictionary = staff_hired.get(role, {})
	var staff_id := str(hired.get("staff_id", ""))
	var name := staff_id
	for candidate: Dictionary in staff_directory:
		if str(candidate.get("staff_id", "")) == staff_id:
			name = str(candidate.get("name", staff_id))
			break
	return text.replace("{staff}", name)
