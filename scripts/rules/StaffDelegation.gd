class_name StaffDelegation
extends RefCounted
## Which choices hand a job to a staff member ("Send a staff member"), and
## whether the player can take them (2026-10-28, Cameron). With no staff hired
## the choice is greyed out. Pure rules: no UI, no autoloads.


## True when `choice_text` names one of `phrases` (lowercase, compared
## case-insensitively).
static func is_delegation(choice_text: String, phrases: Array) -> bool:
	var lowered := choice_text.to_lower()
	for phrase: Variant in phrases:
		if not str(phrase).is_empty() and lowered.contains(str(phrase).to_lower()):
			return true
	return false


## True when a choice needs staff and nobody is hired (`staff_hired` is
## GameState's role -> hire dictionary).
static func blocked(choice_text: String, phrases: Array, staff_hired: Dictionary) -> bool:
	return staff_hired.is_empty() and is_delegation(choice_text, phrases)
