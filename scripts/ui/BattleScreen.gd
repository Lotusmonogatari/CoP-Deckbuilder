extends Control
## The battle screen.
##
## This owns the engine and routes the player's input to it. It makes no
## rules decisions of its own: every question of "can I play this" or "did
## that win" goes to BattleEngine, and this only shows the answer.
##
## WHAT IT KEEPS, AND WHAT IT HANDS OVER
## It keeps the things that are about the screen as a whole — starting a
## battle, the refresh that fans out to everything else, the status row,
## the reference panel, input, and what happens when a stage ends. Four
## presenters own the rest, each with its own file:
##
##   OpponentPresenter  the speaker row, and which face they are wearing
##   HandPresenter      the cards, kept between refreshes so they can move
##   MessagePresenter   the passing sentences, queued so none is cut short
##   OutcomePresenter   the end-of-stage panel
##
## The split is not tidiness for its own sake. Everything still to come —
## a card animating as it is played, a portrait reacting, a sound cued off
## what just happened — lands in one of those four, and would otherwise all
## have landed here.
##
## Layout, top to bottom, following the UI spec:
##   header        stage name with a small Japanese accent, and the turn count
##   opponent row  portrait, name, and what they are about to do, in words
##   support bar   with the threshold marked and a caption
##   status row    energy pips and the gaffe count
##   hand          three to five cards
##   footer        End turn

const OFFICE_SCENE := "res://scenes/office_hours/OfficeScreen.tscn"

## Which battle to open when no level is in progress — running this scene on
## its own from the editor. During a level the stage comes from the level.
@export var level_id: String = "LV06"
@export var stage_id: String = "ST02"

var engine: BattleEngine = null

var _stage: Dictionary = {}
var _selected_card_id: String = ""

## False when the battle could not be set up. Everything that would touch
## the engine checks this first, so a stage that failed to start shows its
## reason instead of crashing on the next click.
var _ready_to_play := false

## The gaffe count and warning state last announced on the noticeboard, so a
## refresh that changed nothing says nothing. Reset when a stage opens.
var _announced_gaffe := 0
var _announced_critical := false

# --- The presenters --------------------------------------------------------
var _speaker: OpponentPresenter = null
var _hand: HandPresenter = null
var _messages: MessagePresenter = null
var _outcome: OutcomePresenter = null

## What is said out loud — the card's spoken line, the opponent's answer —
## slammed across the screen (CueBanner.gd). Quieter notices, such as a card
## being refused, stay in _messages.
var _banner: CueBanner = null

## The opened card, built once and refilled. Created on first use rather
## than in the scene, so the frame stays a thing the script owns.
var _card_back: CardBackView = null

@onready var _stage_name: Label = %StageName
@onready var _stage_name_jp: Label = %StageNameJP
@onready var _turn_label: Label = %TurnLabel
@onready var _room_notice: Label = %RoomNotice
@onready var _support_bar: SupportBar = %SupportBar
@onready var _energy_row: HBoxContainer = %EnergyRow
@onready var _gaffe_label: Label = %GaffeLabel
@onready var _end_turn_button: Button = %EndTurnButton
@onready var _details_button: Button = %DetailsButton
@onready var _details_panel: PanelContainer = %DetailsPanel
@onready var _details_text: Label = %DetailsText
@onready var _card_zoom: PanelContainer = %CardZoom

## The inventory, opened from its button in the header.
var _inventory: InventoryPanel

## The stage's own picture, behind everything. Blank until start_battle()
## names the stage; a background never needs the ID-label a missing
## character portrait gets (PlaceholderArt.show_label).
@onready var _background: PlaceholderArt = %Background

## Your own face, reacting to what you just did (PlayerPortraitPresenter),
## rather than the opponent's own show_state() which reads what they are
## about to do.
var _player_portrait: PlayerPortraitPresenter = null

## Where a press outside an open panel's content began (see _input()).
var _outside_press: Variant = null


func _ready() -> void:
	_background.kind = PlaceholderArt.Kind.BACKGROUND
	_background.show_label = false

	_speaker = OpponentPresenter.new(
		%Portrait, %OpponentName, %IntentLabel, %GuardLabel, %OpponentGuardLabel,
		%UpcomingIntentLabel)
	_player_portrait = PlayerPortraitPresenter.new(%PlayerPortrait)
	_hand = HandPresenter.new(%HandRow)
	_hand.card_chosen.connect(_on_card_chosen)
	_hand.card_flung.connect(_on_card_flung)
	_messages = MessagePresenter.new(%Notice, get_tree())
	_outcome = OutcomePresenter.new(
		%OutcomePanel, %OutcomeTitle, %OutcomeHeadline, %OutcomeReason, %OutcomeClose)

	_end_turn_button.pressed.connect(_on_end_turn)
	_details_button.pressed.connect(_toggle_details)
	%DetailsClose.pressed.connect(func() -> void: _details_panel.hide())
	%ZoomClose.pressed.connect(func() -> void: _card_zoom.hide())
	%ZoomPlay.pressed.connect(_play_selected)
	%OutcomeClose.pressed.connect(_on_outcome_closed)

	_details_panel.hide()
	_card_zoom.hide()
	for panel: Control in [_details_panel, _card_zoom]:
		var scroll := panel.get_node_or_null("Margin/Scroll") as ScrollContainer
		if scroll != null:
			DragScroll.attach(scroll)
	%OutcomePanel.hide()

	_build_inventory()
	_banner = CueBanner.new()
	_banner.name = "CueBanner"
	add_child(_banner)
	start_battle()


## The Inventory button beside Details, and the panel it opens — the same
## InventoryPanel the Office uses, in its stage mode, so an item is used on
## this battle (design/proposals/inventory.md). Using one is free and is not
## a card play; the screen just redraws what it changed.
func _build_inventory() -> void:
	_inventory = InventoryPanel.new()
	_inventory.name = "InventoryPanel"
	_inventory.context = Items.STAGE
	_inventory.on_used = func(_result: Dictionary) -> void: _refresh()
	add_child(_inventory)

	var button := Button.new()
	button.name = "InventoryButton"
	button.text = Text.say("inventory.button")
	button.custom_minimum_size = _details_button.custom_minimum_size
	button.size_flags_vertical = _details_button.size_flags_vertical
	button.pressed.connect(_inventory.show_inventory)
	var parent := _details_button.get_parent()
	parent.add_child(button)
	parent.move_child(button, _details_button.get_index())


## Opens the next battle.
##
## When a level is in progress, that means the level's current stage. When
## it isn't — opening this scene directly from the editor, say — it falls
## back to the module and step set in the inspector, so the scene stays
## runnable on its own.
func start_battle() -> void:
	var config: Dictionary = {}

	if GameState.is_in_level():
		var runner := GameState.level_runner
		# The run's standing, not the starting values: a press conference
		# earlier in the level has already moved reputation, and the stage
		# after it should be fought with the reputation you actually have.
		config = BattleSetup.for_playtest_stage(
			runner.current_stage(), runner.carried_buffs(), GameState.meta)
		# Items used before this stage: a Coffee from the Office for "the
		# next stage", and any level buff still running. Spent by asking.
		if not config.is_empty():
			config["item_bonuses"] = GameState.take_item_bonuses_for_stage()
	else:
		config = BattleSetup.for_level_stage(level_id, stage_id)

	if config.is_empty():
		_messages.say(Text.say("battle.no_stage"))
		return

	_stage = config.get("stage", {})
	var stage_id := str(_stage.get("stage_id", ""))
	_background.art_id = stage_id
	_player_portrait.show_state(stage_id)

	engine = BattleEngine.new()
	_inventory.engine = engine
	if not engine.setup(config):
		# A battle that cannot start says why, in words, rather than
		# presenting an empty screen. Nothing is left playable either: a
		# half-built battle that accepts input crashes instead of failing.
		_ready_to_play = false
		_end_turn_button.disabled = true
		_messages.say(Text.say("battle.cannot_start",
			{"problems": "\n• ".join(Array(engine.setup_problems))}))
		return

	_ready_to_play = true
	# From here until the stage is finished, nothing is saved: coming back
	# to a save means coming back to the start of this stage.
	GameState.mid_stage = GameState.is_in_level()

	# English first, with the Japanese beside it as a small muted accent.
	_stage_name.text = str(_stage.get("name_en", "Battle"))
	_stage_name_jp.text = str(_stage.get("name_jp", ""))
	_support_bar.unit = str(_stage.get("bar_unit", "Support"))

	# A fresh stage announces its own opening gaffe count rather than
	# inheriting whatever the last one finished on.
	_announced_gaffe = 0
	_announced_critical = false
	_room_notice.hide()

	Audio.play_music("music_battle")

	EventBus.turn_started.emit(engine.state.turn)
	# And what the opponent opens with. This used to be left out, so the very
	# first intent of every stage — the one the player reads before playing
	# anything — never reached the noticeboard at all.
	EventBus.intent_revealed.emit(engine.current_intent())
	_refresh()
	# The opening question, the same way the opponent's own opening intent
	# just was — the room's first word, before the player has done anything.
	_announce_question()


# ---------------------------------------------------------------------------
# Drawing
# ---------------------------------------------------------------------------

func _refresh() -> void:
	if engine == null or not _ready_to_play:
		return

	var state := engine.state

	# The reporters' questions are the opposition in a press conference, so
	# they take the place of the turn count as well as the intent line.
	_turn_label.text = (engine.question_caption() if engine.is_press_conference()
		else engine.turn_caption())

	_speaker.show_state(engine, str(_stage.get("stage_id", "")))

	if state.bar != null:
		# A scored stage has no threshold, so the bar must not draw a line or
		# claim a number is needed to win. Neither has a press conference:
		# it runs until the reporters are finished, whatever the tone.
		var has_threshold := state.win_mode != "score" and not engine.is_press_conference()
		# Reaching the threshold ends the STAGE only when nobody else is
		# waiting to rise. On the floor it ends one debater of five.
		var wins_stage := not engine.has_more_opponents()
		_support_bar.show_bar(state.bar, has_threshold,
			OpponentPresenter.display_name(engine),
			BattleNarration.is_percent(_stage), wins_stage)

	_refresh_energy(state)
	_refresh_gaffe(state)
	_hand.show_state(engine)
	_refresh_details(state)

	_end_turn_button.disabled = state.is_over()

	if state.is_over():
		if state.outcome == "win":
			_player_portrait.show_victory()
		_outcome.show_outcome(engine, _stage)


## A room whose cards are answers to a drawn question (BattleSetup.
## QUESTION_POOL_BY_STAGE — Town Hall today) but whose bar is not Single, so
## the reporter-shaped row a press conference gets never shows it
## (OpponentPresenter.show_state()'s own check). A press conference itself
## is excluded too — that room already says this in the opponent row.
##
## Gates two things, both 2026-09-26: which room gets the CueBanner showing
## the question by default and the opponent's own cue after the player
## acts, rather than narration (see _announce_question()/_on_end_turn());
## and which room gets %RoomNotice at all (_show_room_notice()).
func _stage_asks_questions() -> bool:
	return engine != null and not engine.is_press_conference() \
		and int(_stage.get("questions_count", 0)) > 0


## The drawn question, as the CueBanner's own default content — what is on
## screen until the player's turn gives the banner something else to say
## (_on_end_turn()'s own cue-or-silence). Cameron, 2026-09-26: this used to
## be a separate, always-on label; now it rides the same banner every other
## spoken line in the game does, and the label that used to hold it
## (%RoomNotice) carries what actually HAPPENED instead — see
## _show_room_notice(). Does nothing outside a question-asking room.
func _announce_question() -> void:
	if not _stage_asks_questions():
		return
	var question := engine.current_question()
	if question.is_empty():
		return
	_banner.say(CueBanner.OPPONENT, OpponentPresenter.display_name(engine),
		Text.say("battle.question_prompt", {"question": str(question.get("text", ""))}))


## What just happened, in a question-asking room only: the opponent's own
## narration, a bout finishing, or the player's own pass/decline penalty —
## everything that used to compete with the question/cue for the CueBanner,
## or sit in the separate %Notice queue, moved here instead. Blank text
## hides the label rather than leaving stale words up from a turn ago.
func _show_room_notice(text: String) -> void:
	if not _stage_asks_questions():
		return
	if text.is_empty():
		_room_notice.hide()
		return
	_room_notice.text = text
	_room_notice.show()


## Energy as pips rather than a number: three small marks are quicker to
## count than "3 / 3" is to read.
func _refresh_energy(state: BattleState) -> void:
	# One pip per point available, which is a turn's worth normally and the
	# whole pool in a caucus. Reading energy_per_turn here would draw three
	# pips for a five-point pool and quietly lie about what is left.
	var wanted := maxi(state.energy_max, 1)

	# Pips are kept rather than rebuilt: they are cheap, but a pip that
	# survives a refresh is a pip that can be animated when it is spent.
	while _energy_row.get_child_count() > wanted:
		_energy_row.get_child(_energy_row.get_child_count() - 1).queue_free()
		_energy_row.remove_child(_energy_row.get_child(_energy_row.get_child_count() - 1))
	while _energy_row.get_child_count() < wanted:
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(26, 26)
		_energy_row.add_child(pip)

	for index in _energy_row.get_child_count():
		var box := StyleBoxFlat.new()
		box.set_corner_radius_all(13)
		box.bg_color = (Color(0.95, 0.85, 0.45) if index < state.energy
			else Color(0.30, 0.30, 0.34))
		(_energy_row.get_child(index) as Panel).add_theme_stylebox_override("panel", box)


## The gaffe counter turns red ONLY when one more gaffe would end the stage.
## Colouring it earlier would cry wolf and make the real warning meaningless.
func _refresh_gaffe(state: BattleState) -> void:
	var critical := engine.gaffe_is_critical()
	_gaffe_label.text = "Gaffes %d / %d" % [state.gaffe, state.gaffe_limit]
	# SmallLabel either way — same size as Guard beside it — so turning
	# critical only changes the colour and weight, never the size.
	_gaffe_label.theme_type_variation = "GaffeWarning" if critical else "SmallLabel"

	# Announced only when it MOVED. This used to fire on every refresh — every
	# card, every turn, every stage opened — so a gaffe sound would have gone
	# off several times a turn, including on turns where nothing happened. The
	# label is redrawn regardless; redrawing a label is cheap and announcing a
	# thing that did not happen is not.
	if state.gaffe == _announced_gaffe and critical == _announced_critical:
		return
	var delta := state.gaffe - _announced_gaffe
	_announced_gaffe = state.gaffe
	_announced_critical = critical
	EventBus.gaffe_changed.emit(state.gaffe, delta, state.gaffe_limit, critical)


## Who is in the room, and what it takes to win one of them over.
##
## Both of these are rules a player would otherwise have to work out by
## losing: that the people already against you cost more to win than the
## people who have not decided, and that the audience is not the same crowd
## from one stage to the next.
func _room_lines(state: BattleState) -> Array[String]:
	var lines: Array[String] = []

	var mix: Dictionary = _stage.get("segment_mix", {})
	if not mix.is_empty():
		var parts: Array[String] = []
		for segment: Dictionary in DataDB.segments:
			var share := float(mix.get(segment.get("segment_id"), 0.0))
			if share > 0.0:
				parts.append("%d%% %s" % [roundi(share * 100.0), segment.get("name_en", "")])
		if not parts.is_empty():
			lines.append("In the room: %s." % ", ".join(parts))

	if state.bar != null and state.bar.model == BarModel.Model.SHARED_POOL:
		lines.append("Winning over somebody undecided takes one point. "
			+ "Somebody already against you takes one, two or three — "
			+ "you find out which as you go, and points you cannot spend "
			+ "are lost.")

	return lines


func _refresh_details(state: BattleState) -> void:
	# The room's own rules come first, defaults included. Nine kinds of stage
	# now differ in how they hand out energy, how many questions they ask and
	# what winning means, and this panel used to explain only the two cases
	# that were unusual — so a policy study looked like it had finite energy.
	var lines: Array[String] = StageBrief.how_this_room_works(_stage, state)

	lines.append("")
	lines.append_array([
		"Deck %d · Hand %d · Discard %d" % [
			state.deck.size(), state.hand.size(), state.discard.size()],
		"Stage: %s (%s)" % [_stage.get("name_en", ""), _stage.get("stage_id", "")],
	])

	var player := DataDB.player
	if not str(player.get("name_en", "")).is_empty():
		lines.append("You: %s, %s" % [player.get("name_en", ""), player.get("party", "")])

	# No line at all where there is nobody, rather than "Opponent: ,".
	var opponent := engine.current_opponent()
	if not opponent.is_empty():
		lines.append("Opponent: %s, %s" % [opponent.get("name", ""), opponent.get("party", "")])

	if engine.questions_remaining() > 0 or not engine.pleased_boosters().is_empty():
		lines.append("")
		var question_now := engine.current_question()
		if not question_now.is_empty():
			lines.append("This question invites a %s answer."
				% question_now.get("prefers_suit", "any"))
		var pleased := engine.pleased_boosters()
		if pleased.is_empty():
			lines.append("Nobody pleased yet.")
		else:
			# Organisations by name, not by the ID the data files use: the
			# player has no way of knowing what BO08 is.
			var named: Array[String] = []
			for booster_id: String in pleased:
				named.append(str(DataDB.get_booster(booster_id).get("name_en", booster_id)))
			lines.append("Pleased so far: %s." % ", ".join(named))

	lines.append("")
	lines.append_array(_room_lines(state))

	# How many there are to get through. How they follow one another is a row
	# in the table above, so only the count belongs here.
	if state.opponent_count > 1:
		lines.append("")
		lines.append(Text.say("battle.one_at_a_time", {
			"count": state.opponent_count,
			"number": state.opponent_index + 1,
		}))

	# Asked, not sniffed. This used to test whether the sentence began with
	# "Nothing", so rewording that line would have silently hidden the block.
	if GameState.is_in_level() and GameState.level_runner.anything_carried():
		lines.append("")
		lines.append(GameState.level_runner.describe_carried_buffs(
			BattleSetup.booster_names(), Text.phrase()))

	if engine.used_default_intent_pattern:
		lines.append("")
		lines.append(Text.say("battle.default_pattern"))

	# 2026-09-22 workbook: stages.json no longer carries "signature_rule" at
	# all, so this is always empty now and the block below never shows. Left
	# in rather than deleted — it costs nothing, and degrades to nothing
	# happening rather than an error if the column ever comes back under a
	# different name.
	var rule := str(_stage.get("signature_rule", ""))
	if not rule.is_empty():
		lines.append("")
		lines.append(rule)

	_details_text.text = "\n".join(lines)


# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

## How this room is treating this suit, in words rather than a multiplier.
##
## "×0.80" is precise and means nothing at the table. What a player needs to
## know is whether the room is with them, and roughly how much.
static func describe_room_for(affinity: float) -> String:
	if affinity >= 1.51:
		return "Being greatly enhanced by supporters."
	if affinity > 1.0:
		return "Being enhanced by supporters."
	if affinity < 0.5:
		return "Being greatly suppressed by opponents."
	if affinity < 1.0:
		return "Being suppressed by detractors."
	return "Landing as written here."


## Tapping a card opens the zoom view. Nothing is played until the player
## confirms there, so a mis-tap never costs a turn.
func _on_card_chosen(card_id: String) -> void:
	if not _ready_to_play:
		return
	_selected_card_id = card_id
	var card := DataDB.get_card(card_id)

	if _card_back == null:
		_card_back = CardBackView.new()
		# Big enough to read at arm's length: at 1250 tall the card is about
		# 890 wide, which is most of a 1080 screen. The back exists to be
		# read, so it is worth the room.
		#
		# BOTH numbers, not just the height. Leaving the width at zero meant
		# the card was laid out once at no width at all and only corrected
		# itself on the resize that followed — a frame of stretched artwork
		# every time a card was opened.
		_card_back.custom_minimum_size = Vector2(
			1250.0 * CardBackView.ASPECT, 1250.0)
		_card_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		%ZoomColumn.add_child(_card_back)
		%ZoomColumn.move_child(_card_back, 0)

	_card_back.show_card(card, CardView.describe_effect(engine.preview(card), card),
		describe_room_for(engine.affinity_for(card)))

	%ZoomPlay.disabled = engine.card_cost(card) > engine.state.energy
	_card_zoom.show()


## A card dragged up out of the hand and let go: played straight away, the
## same as opening it and pressing Play.
func _on_card_flung(card_id: String) -> void:
	if not _ready_to_play:
		return
	_selected_card_id = card_id
	_play_selected()


func _play_selected() -> void:
	_card_zoom.hide()
	if not _ready_to_play or _selected_card_id.is_empty():
		return

	var card_id := _selected_card_id

	# Asked BEFORE the card is played, while it is still in hand. The engine
	# works out whether a card does anything in this room in preview() and
	# nowhere else, so playing first and asking after would be too late.
	# The hand already uses the same call to dim a card that is useless here.
	var useless := bool(engine.preview(DataDB.get_card(card_id))
		.get("does_nothing", false))

	var result := engine.play_card(card_id)
	if not result.get("ok", false):
		_messages.say(str(result.get("reason", Text.say("battle.card_refused"))))
		return

	_selected_card_id = ""
	# Announced before the redraw, so anything listening can reach the card
	# view that played it while it is still on screen.
	#
	# The engine's own result says what the card did; whether it was worth
	# anything in this room is added here, because that is a question the
	# screen asks and the rules do not answer in play_card().
	result["does_nothing"] = useless
	EventBus.card_played.emit(card_id, result)
	_refresh()
	var applied: Dictionary = result.get("applied", {})
	if int(applied.get("opponent_lost", 0)) > 0:
		_speaker.flinch()
	_player_portrait.react_to_card(applied)

	# What the player actually says, in big type across the screen, with
	# what it did to the room underneath. The line is Cameron's, from the
	# workbook; a card with none written yet puts what it did on the band
	# instead, so every card still lands with a line.
	var cue := CardCues.for_card(
		card_id, str(_stage.get("stage_id", "")), engine.state.turn)
	var did := BattleNarration.player_move(
		result, _stage, engine.state, OpponentPresenter.display_name(engine))
	var me := str(DataDB.player.get("name_en", ""))
	if not str(cue["text"]).is_empty():
		_banner.say(CueBanner.PLAYER, me, str(cue["text"]), did)
		# And the recording of it, when there is one. Silent until then: no
		# filename appears in any script, the same as every other sound.
		Audio.say(CardCues.speaker(), str(cue["line_id"]))
	else:
		_banner.say(CueBanner.PLAYER, me, did)


func _on_end_turn() -> void:
	if not _ready_to_play:
		return
	var result := engine.end_turn()
	if not result.get("ok", false):
		return

	EventBus.turn_ended.emit(engine.state.turn)

	# Read the opponent's move BEFORE refreshing, because a finished bout
	# swaps in the next opponent and the sentence is about the one who just
	# acted. The name — and, for OpponentCues below, the whole opponent row —
	# comes from the same snapshot for the same reason.
	var speaker := OpponentPresenter.display_name(engine)
	var acting_opponent := engine.current_opponent()
	_refresh()

	var asks_questions := _stage_asks_questions()

	# The pass penalty has always worked; nothing ever said so, which is why
	# a playtest read it as having stopped after the first time. It never
	# compounds — every quiet turn costs the same one energy.
	#
	# This is the PLAYER's own consequence, not anything the opponent said —
	# it used to ride along inside their banner under their name tag, which
	# read as if Emi were telling you off for your own silence. It belongs
	# with the quiet notices (a refused card, "no stage to play") instead —
	# %RoomNotice in a question-asking room, the ordinary %Notice queue
	# everywhere else.
	var lines: Array[String] = []
	if bool(result.get("passed", false)) and not engine.state.is_over():
		var passed_text := (Text.say("battle.declined") if engine.is_press_conference()
			else Text.say("battle.passed"))
		if asks_questions:
			lines.append(passed_text)
		else:
			_messages.say(passed_text)

	# What the opponent did. The engine has always returned this and no
	# screen has ever read it, so the whole of their turn happened in
	# silence: guard built, seats taken, a panel member leaned on.
	var opponent_result: Dictionary = result.get("opponent", {})
	var said := BattleNarration.opponent_move(
		opponent_result, _stage, engine.state, speaker)
	if not said.is_empty():
		lines.append(said)
	_player_portrait.react_to_opponent(opponent_result)

	# A debater finished by the clock or by their own attack, rather than by
	# a card — the same news, from the other end of the turn.
	var bout: Dictionary = result.get("bout_won", {})
	if not bout.is_empty():
		lines.append(BattleNarration.player_move(
			{"bout_won": bout}, _stage, engine.state, speaker))

	# What they SAY, from the workbook's Opponent Cues tab.
	var move_cue := OpponentCues.for_move(
		acting_opponent, str(opponent_result.get("verb", "")),
		str(_stage.get("stage_id", "")), engine.state.turn)
	var has_cue := not str(move_cue["text"]).is_empty()

	if asks_questions:
		# The CueBanner here is ONLY ever the question or the opponent's own
		# cue (Cameron, 2026-09-26) — never narration, and never restating
		# the name the banner's own tag already carries. Nothing written for
		# this opponent/verb yet leaves the banner showing whatever it last
		# said (the question) rather than falling back to narration.
		if has_cue:
			_banner.say(CueBanner.OPPONENT, speaker, str(move_cue["text"]))
			Audio.say(str(acting_opponent.get("opp_id", "")), str(move_cue["line_id"]))
		_show_room_notice("\n".join(lines))
	else:
		# Unchanged: a line becomes the banner's big type, with what it did
		# demoted underneath it; nothing written yet falls back to narration
		# alone, same as it always has.
		if has_cue:
			_banner.say(CueBanner.OPPONENT, speaker, str(move_cue["text"]), "\n".join(lines))
			Audio.say(str(acting_opponent.get("opp_id", "")), str(move_cue["line_id"]))
		elif not lines.is_empty():
			_banner.say(CueBanner.OPPONENT, speaker, "\n".join(lines))

	if not engine.state.is_over():
		EventBus.turn_started.emit(engine.state.turn)
		EventBus.intent_revealed.emit(engine.current_intent())
		_announce_question()


func _toggle_details() -> void:
	_details_panel.visible = not _details_panel.visible


# ---------------------------------------------------------------------------
# Getting out of an overlay
# ---------------------------------------------------------------------------
# Three ways out of every overlay, because being stuck on a screen with no
# exit is the worst thing a UI can do: its own button, the escape key, and
# tapping the dimmed area around it.
#
# The end-of-battle panel is deliberately excluded from the last two. It is
# not something to dismiss by accident — the stage is genuinely over, and the
# only way on is its own button.

## Overlays a player is allowed to back out of, front-most first.
func _dismissable_overlays() -> Array[Control]:
	return [_card_zoom, _details_panel]


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _dismiss_top_overlay():
			get_viewport().set_input_as_handled()
		return

	# A tap anywhere outside the panel's content closes it — on the finger
	# lifting, and only if it did not move, so a drag scrolls instead. Checked
	# against the content's own rectangle rather than the panel's, since the
	# panel covers the whole screen.
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var where: Vector2 = (event as InputEventMouseButton).position
		for overlay: Control in _dismissable_overlays():
			if not overlay.visible:
				continue
			var content := _overlay_content(overlay)
			if content == null:
				return
			if (event as InputEventMouseButton).pressed:
				_outside_press = where if not content.get_global_rect().has_point(where) else null
			elif Overlay.is_tap_outside(_outside_press, where, content.get_global_rect()):
				_outside_press = null
				overlay.hide()
				get_viewport().set_input_as_handled()
			return   # only ever the front-most one


## The two panels name their content column differently, so ask for either
## rather than assuming one shape.
func _overlay_content(overlay: Control) -> Control:
	if overlay.has_node("Margin/Scroll/Centre/Column"):
		return overlay.get_node("Margin/Scroll/Centre/Column") as Control
	return overlay.get_node_or_null("Margin/Scroll/Centre/ZoomColumn") as Control


## Closes the front-most overlay. True when there was one to close.
func _dismiss_top_overlay() -> bool:
	for overlay: Control in _dismissable_overlays():
		if overlay.visible:
			overlay.hide()
			return true
	return false


# ---------------------------------------------------------------------------
# Leaving
# ---------------------------------------------------------------------------

func _on_outcome_closed() -> void:
	_messages.clear()
	_banner.clear()

	if not GameState.is_in_level():
		get_tree().quit()
		return

	if not _ready_to_play:
		GameState.end_level()
		get_tree().change_scene_to_file(OFFICE_SCENE)
		return

	var state := engine.state
	# A caucus has no threshold: how high the support got is the score, and
	# that is what later stages draw on. The gaffe-loss flag and gaffe count
	# feed GameState's own lifetime tracking (stages lost to the gaffe meter
	# specifically, and the running gaffe total) — they change nothing about
	# what the stage is worth. Checked directly off the numbers, not
	# state.outcome_reason's own (already-translated) text — comparing
	# translated text against a key never matches in a real build.
	var gaffe_caused_loss := state.outcome == "loss" and state.gaffe >= state.gaffe_limit
	var level_over := GameState.finish_stage(
		state.outcome, state.player_score(), engine.pleased_boosters(),
		gaffe_caused_loss, state.gaffe)

	if level_over:
		GameState.end_level()
		get_tree().change_scene_to_file(OFFICE_SCENE)
	else:
		# Same scene, next stage — unless it's an Office Hours stage, which
		# plays on VisitorScreen instead. Reloading (rather than a plain
		# change_scene back to this same path) keeps the setup in one place
		# for the common case, where the next stage is another battle.
		var next_scene := StageRouting.scene_for(GameState.level_runner.current_stage())
		if next_scene == StageRouting.BATTLE_SCENE:
			get_tree().reload_current_scene()
		else:
			get_tree().change_scene_to_file(next_scene)
