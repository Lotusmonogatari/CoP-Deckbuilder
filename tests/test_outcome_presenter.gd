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
