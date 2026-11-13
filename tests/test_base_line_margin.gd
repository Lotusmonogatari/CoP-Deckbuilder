extends GutTest
## Every screen that sits on BASE.png keeps its buttons above the brush line at
## the bottom of the picture (Cameron, 2026-11-13). On the 1080 x 2340 screen
## the line starts about 2271 px down; the Safe area's bottom margin must leave
## the lowest button ending by about 2250 (a 90 px margin).

const SCENES := [
	"res://scenes/battle/BattleScreen.tscn",
	"res://scenes/office_hours/OfficeScreen.tscn",
	"res://scenes/office_hours/VisitorScreen.tscn",
	"res://scenes/office_hours/VisitScreen.tscn",
	"res://scenes/office_hours/TradeScreen.tscn",
	"res://scenes/office_hours/FloorVoteScreen.tscn",
]
const MIN_BOTTOM_MARGIN := 90


func test_each_base_screen_keeps_its_bottom_margin() -> void:
	for path: String in SCENES:
		var root := (load(path) as PackedScene).instantiate()
		var safe := root.get_node("Safe") as MarginContainer
		assert_gte(safe.get_theme_constant("margin_bottom"), MIN_BOTTOM_MARGIN,
			"%s leaves room above BASE's bottom line" % path)
		root.free()
