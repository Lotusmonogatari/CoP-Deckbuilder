class_name SafeNum
## Number reading that survives a blank workbook cell. An optional cell that
## was left empty reaches the game as null, and int(null) is an error in
## GDScript (it once froze every Floor Vote level's briefing). Pure.


## `value` as a whole number, or `fallback` when it is null or not a number.
static func to_int(value: Variant, fallback: int = 0) -> int:
	if value == null:
		return fallback
	if value is int or value is float or value is bool:
		return int(value)
	if value is String and (value as String).is_valid_int():
		return int(value)
	return fallback
