extends GutTest
## The end-of-stage Outcome panel: what it says a stage was worth.
##
## 2026-09-28, Cameron: a lost stage's own pleased/displeased organisations
## never reached this panel — _body_for() returned early on the loss branch,
## before the code that prints them, which only ever ran on a win. The
## standing change itself was always applied correctly (GameState.
## finish_stage() doesn't care about outcome for that); only the panel that
## explains WHY stayed silent, and only on the bad news. Fixed by moving the
## pleased/displeased lines ahead of the win/loss branch.

var _panel: PanelContainer
var _title: Label
var _headline: Label
var _body: Label
var _button: Button
var _presenter: OutcomePresenter


func before_each() -> void:
	_panel = PanelContainer.new()
	_title = Label.new()
	_headline = Label.new()
	_body = Label.new()
	_button = Button.new()
	_presenter = OutcomePresenter.new(_panel, _title, _headline, _body, _button)
	GameState.begin_level(LevelRunner.new(DataDB.playtest_level))


func after_each() -> void:
	GameState.end_level()
	_panel.free()
	_title.free()
	_headline.free()
	_body.free()
	_button.free()


## A question-asking stage where a weak answer displeases BO01 (a real
## organisation, "Party Headquarters"), then the stage is lost.
func _lost_stage_with_a_displeased_booster() -> Dictionary:
	var stage := TestFixtures.stage({
		"win_mode": "score", "questions_per_turn": 1, "player_start": 50,
		"loss_delta_jiban": -5,
		"questions": [{
			"id": "Q01", "text": "Where do you stand?",
			"grades": {"Earnest": "S", "Emotional": "M", "Appeal": "W",
				"Data Driven": "M", "Divisive": "M", "Duplicitous": "M"},
			"pleases_boosters": ["BO01"],
		}],
	})
	return stage


func test_a_lost_stages_displeased_organisation_reaches_the_panel() -> void:
	var stage := _lost_stage_with_a_displeased_booster()
	var config := TestFixtures.battle_config({"stage": stage})
	config["cards"] = {
		"WEAK": TestFixtures.card({"card_id": "WEAK", "suit": "Appeal", "cost": 1}),
	}
	config["deck"] = ["WEAK"]

	var engine := BattleEngine.new()
	engine.setup(config)
	engine.play_card("WEAK")
	engine.state.outcome = "loss"

	var body := _presenter.call("_body_for", engine, stage) as String

	assert_string_contains(body, "Party Headquarters",
		"a weak answer's own annoyed organisation should reach the panel on a loss, not only a win")


func test_a_lost_stages_pleased_organisation_also_reaches_the_panel() -> void:
	# The mirror check: a Strong answer earlier the same turn, then the room
	# is still lost overall (a caucus that opened strong but closed short).
	var stage := _lost_stage_with_a_displeased_booster()
	var config := TestFixtures.battle_config({"stage": stage})
	config["cards"] = {
		"STRONG": TestFixtures.card({"card_id": "STRONG", "suit": "Earnest", "cost": 1}),
	}
	config["deck"] = ["STRONG"]

	var engine := BattleEngine.new()
	engine.setup(config)
	engine.play_card("STRONG")
	engine.state.outcome = "loss"

	var body := _presenter.call("_body_for", engine, stage) as String

	assert_string_contains(body, "Party Headquarters",
		"a pleased organisation should still reach the panel even when the stage was lost overall")


func test_a_crushed_opponents_organisation_reaches_the_panel() -> void:
	# 2026-09-29, Cameron: an opponent argued down to zero costs their own
	# organisation — shown the same way pleased/displeased already are, so
	# the connection to a real standing hit isn't lost by the time the
	# player reaches the Office.
	var stage := TestFixtures.stage()
	var config := TestFixtures.battle_config({"stage": stage})
	var engine := BattleEngine.new()
	engine.setup(config)
	engine.state.crushed_opponent_boosters = ["BO01"]
	engine.state.outcome = "win"

	var body := _presenter.call("_body_for", engine, stage) as String

	assert_string_contains(body, "Party Headquarters",
		"a crushed opponent's organisation should reach the panel")


func test_the_losses_own_cost_still_shows_alongside_the_organisation_line() -> void:
	var stage := _lost_stage_with_a_displeased_booster()
	var config := TestFixtures.battle_config({"stage": stage})
	config["cards"] = {
		"WEAK": TestFixtures.card({"card_id": "WEAK", "suit": "Appeal", "cost": 1}),
	}
	config["deck"] = ["WEAK"]

	var engine := BattleEngine.new()
	engine.setup(config)
	engine.play_card("WEAK")
	engine.state.outcome = "loss"

	var body := _presenter.call("_body_for", engine, stage) as String

	assert_string_contains(body, "Party Headquarters", "the organisation line is still there")
	assert_string_contains(body, "Constituency support", "and the loss's own cost line is untouched by the fix")


## The icon row's numbers: one net change per organisation, pleased and
## annoyed settling together, a crush on top.
func test_booster_change_nets_pleased_annoyed_and_crushed() -> void:
	var standing := {"per_please": 5, "per_displease": 1,
		"question_swing_cap": 5, "instant_win_penalty": 2}
	var got := BoosterChange.compute(["BO01", "BO02"], ["BO02", "BO03"], ["BO03"], standing)
	assert_eq(got.size(), 3)
	assert_eq(got[0], {"booster_id": "BO01", "net": 5})
	assert_eq(got[1], {"booster_id": "BO02", "net": 4})
	assert_eq(got[2], {"booster_id": "BO03", "net": -3})


## With an icon container the panel shows one tappable icon per organisation,
## and a tap names it with its net change.
func test_icons_show_and_a_tap_names_the_organisation_with_its_net_change() -> void:
	var stage := TestFixtures.stage()
	var engine := BattleEngine.new()
	engine.setup(TestFixtures.battle_config({"stage": stage}))
	engine.state.crushed_opponent_boosters = ["BO01"]
	engine.state.outcome = "win"

	var box := VBoxContainer.new()
	add_child_autofree(box)
	var presenter := OutcomePresenter.new(_panel, _title, _headline, _body, _button, box)
	presenter.call("_build_booster_icons", engine)
	assert_true(box.visible)
	var icon := box.find_child("BoosterIcon_BO01", true, false) as Button
	assert_not_null(icon)
	icon.pressed.emit()
	var popup := box.get_child(box.get_child_count() - 1) as Label
	assert_true(popup.visible)
	assert_string_contains(popup.text, "Party Headquarters")
	assert_string_contains(popup.text, "-2")
	var body := presenter.call("_body_for", engine, stage) as String
	assert_false(body.contains("Argued out"), "names move from the body to the icons")
