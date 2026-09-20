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
@onready var _organisations_button: Button = %OrganisationsButton
@onready var _organisations_panel: Overlay = %OrganisationsPanel
@onready var _briefing_panel: Overlay = %BriefingPanel
@onready var _portrait: Control = %Portrait


func _ready() -> void:
	_start_button.pressed.connect(_show_briefing)
	_briefing_panel.confirmed.connect(_on_start)
	_organisations_button.pressed.connect(_show_organisations)
	_build()


func _build() -> void:
	var level := DataDB.playtest_level

	# Whose office it is. A placeholder name until the protagonist is cast,
	# but a named desk reads better than an anonymous one.
	var player := DataDB.player
	var name_en := str(player.get("name_en", ""))
	var party := str(player.get("party", ""))

	if name_en.is_empty():
		_title.text = "The Office"
	elif party.is_empty():
		_title.text = "%s's Office" % name_en
	else:
		_title.text = "%s · %s" % [name_en, party]
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


## The ten organisations, and where the player stands with each.
##
## Grouped by tier rather than listed flat, because the tiers are the real
## distinction: a Constituency group is worth something different from a
## National one, and seeing them mixed together hides that.
func _show_organisations() -> void:
	var rows: Array[Control] = []

	rows.append(_wrapped_label("Answering a reporter in the suit their "
		+ "question invites pleases the organisation behind it, and that "
		+ "standing is carried between levels."))

	for tier: String in ["Party", "Constituency", "National"]:
		var in_tier := DataDB.boosters.filter(
			func(b: Dictionary) -> bool: return str(b.get("tier", "")) == tier)
		if in_tier.is_empty():
			continue

		rows.append(_heading_label(tier))
		for booster: Dictionary in in_tier:
			rows.append(_organisation_row(booster))

	_organisations_panel.open("The organisations", rows)


func _organisation_row(booster: Dictionary) -> Control:
	var booster_id := str(booster.get("booster_id", ""))
	var standing := int(GameState.booster_standing.get(booster_id, 50))

	var line := "%s %s  —  %d" % [
		booster.get("name_en", booster_id),
		booster.get("name_jp", ""),
		standing,
	]

	# What moved last level, so a change is visible rather than inferred.
	var change := int(GameState.last_booster_change.get(booster_id, 0))
	if change != 0:
		line += "  (%+d)" % change

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.add_child(_wrapped_label(line))
	box.add_child(_wrapped_label(str(booster.get("boosts", "")), "SmallLabel"))
	return box


func _heading_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = "HeaderLabel"
	return label


func _wrapped_label(text: String, variation: String = "") -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(760, 0)
	if not variation.is_empty():
		label.theme_type_variation = variation
	return label


## What the level ahead is worth, before committing to it.
##
## Cameron asked for the STATIC values: what a stage pays flat for being won.
## What a press conference or a caucus produces depends on the number it
## closes on, so those are named as variable rather than forecast — a
## predicted figure here would be a guess presented as a promise.
##
## Every reward in the playtest level is currently zero, and this screen says
## so in words. Four zeroes would read as "this level is worthless"; "not set
## yet" is the truth, and it is Cameron's to set.
func _show_briefing() -> void:
	var runner := LevelRunner.new(DataDB.playtest_level)
	if not runner.is_valid():
		_report.text = "This level cannot start:\n• %s" % "\n• ".join(Array(runner.problems()))
		return

	var rows: Array[Control] = []
	var stages: Array = DataDB.playtest_level.get("stages", [])
	var anything_set := false

	for stage: Variant in stages:
		if typeof(stage) != TYPE_DICTIONARY:
			continue
		rows.append(_heading_label(str(stage.get("name_en", "A stage"))))

		var who := _opponents_line(stage)
		if not who.is_empty():
			rows.append(_wrapped_label(who, "SmallLabel"))

		if LevelRunner.rewards_are_unset(stage):
			rows.append(_wrapped_label(
				"What winning this is worth has not been set yet.", "SmallLabel"))
		else:
			anything_set = true
			for name: String in LevelRunner.win_rewards(stage).keys():
				rows.append(_wrapped_label("%s %+d"
					% [name, LevelRunner.win_rewards(stage)[name]]))
			var xp := int(stage.get("xp_reward", 0))
			if xp > 0:
				rows.append(_wrapped_label("%d XP" % xp))
			for line: String in LevelRunner.variable_rewards(stage):
				rows.append(_wrapped_label(line, "SmallLabel"))

	if not anything_set:
		rows.append(_wrapped_label(""))
		rows.append(_wrapped_label("Nothing in this level pays out yet. The "
			+ "slots are in the data waiting for numbers, and the moment "
			+ "they have any, they will land here and on your standing."))

	# Losing is the same everywhere for now, and saying so is worth a line:
	# the player should know what they are risking, which is the afternoon.
	rows.append(_wrapped_label(""))
	rows.append(_wrapped_label("Lose a stage and you earn nothing from it. "
		+ "Nothing else is taken off you.", "SmallLabel"))

	_briefing_panel.open("Before you go in", rows, "Go in")


## "Against Opponent A, Opponent B and Opponent C" — who is waiting.
func _opponents_line(stage: Dictionary) -> String:
	var names: Array[String] = []
	for entry: Variant in stage.get("opponents", []):
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var name := str(entry.get("name", "")).strip_edges()
		if not name.is_empty():
			names.append(name)

	if names.is_empty():
		return "The reporters ask the questions here." if not stage.get(
			"questions", []).is_empty() else ""
	if names.size() == 1:
		return "Against %s" % names[0]
	return "Against %s and %s" % [", ".join(names.slice(0, -1)), names[-1]]


func _on_start() -> void:
	var runner := LevelRunner.new(DataDB.playtest_level)
	if not runner.is_valid():
		_report.text = "This level cannot start:\n• %s" % "\n• ".join(Array(runner.problems()))
		return

	# The runner is handed over rather than rebuilt, so the level keeps its
	# place and its carried buffs as the battle screen moves through it.
	GameState.begin_level(runner)
	get_tree().change_scene_to_file(BATTLE_SCENE)
