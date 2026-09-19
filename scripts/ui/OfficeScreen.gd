extends Control
## The Office: the hub you return to between levels.
##
## Deliberately almost empty for now. The only thing it does is start the
## level. Visitors, correspondence, and everything else the Office will
## eventually hold come later; right now its job is to be the place the loop
## begins and ends, so the shape of a run is playable end to end.
##
## It also reports how the last level went, because going back to a hub that
## does not acknowledge what just happened feels like a bug.

const BATTLE_SCENE := "res://scenes/battle/BattleScreen.tscn"

@onready var _title: Label = %Title
@onready var _subtitle: Label = %Subtitle
@onready var _report: Label = %Report
@onready var _start_button: Button = %StartButton
@onready var _portrait: Control = %Portrait


func _ready() -> void:
	_start_button.pressed.connect(_on_start)
	_build()


func _build() -> void:
	var level := DataDB.playtest_level

	_title.text = "The Office"
	_subtitle.text = "陳情"

	if _portrait is PlaceholderArt:
		var art := _portrait as PlaceholderArt
		art.kind = PlaceholderArt.Kind.CHARACTER
		art.art_id = "PROTAGONIST"
		art.expression = "neutral"

	_start_button.text = "Start %s" % level.get("name_en", "the level")
	_report.text = _last_level_report()


## What happened last time, if anything has happened yet.
##
## GameState holds nothing between runs until milestone 4 builds saving, so
## this currently only survives within one sitting. That is enough for the
## loop to feel closed.
func _last_level_report() -> String:
	var outcome: Variant = GameState.last_level_outcome
	if outcome == null or str(outcome).is_empty():
		return "Nothing on today. The House sits shortly."

	match str(outcome):
		LevelRunner.WON:
			return "The bill carried. Word has got round."
		LevelRunner.LOST:
			return "The bill failed. There will be questions."
		_:
			return ""


func _on_start() -> void:
	var runner := LevelRunner.new(DataDB.playtest_level)
	if not runner.is_valid():
		_report.text = "This level cannot start:\n• %s" % "\n• ".join(Array(runner.problems()))
		return

	# The runner is handed over rather than rebuilt, so the level keeps its
	# place and its carried buffs as the battle screen moves through it.
	GameState.begin_level(runner)
	get_tree().change_scene_to_file(BATTLE_SCENE)
