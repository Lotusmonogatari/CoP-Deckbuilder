class_name Levers
## The workbook's design numbers and suit list, for rules files that cannot
## reach the DataDB autoload directly (CLAUDE.md section 12: rules stay free
## of UI and of scene state). DataDB fills this in the moment it loads
## balance.json and suits.json; a rules file then asks for a lever by the
## name of its Balance-tab row (lowercased, spaces and punctuation as
## underscores). There is deliberately no fallback number here: a lever the
## workbook lacks is a data error, reported once and read as 0, and
## tests/test_balance_keys.gd fails the build before it can ship.

static var balance: Dictionary = {}
static var suit_names: Array[String] = []
## The Staff role whose tier prices level unlocks: the first role in the Staff tab.
static var unlock_role := ""


## A lever as a number (decimals kept, as the Balance tab wrote them).
static func num(key: String) -> float:
	if not balance.has(key):
		push_warning("Balance lever '%s' is missing from the workbook." % key)
		return 0.0
	return float(balance[key])


## A lever as a whole number.
static func whole(key: String) -> int:
	return roundi(num(key))
