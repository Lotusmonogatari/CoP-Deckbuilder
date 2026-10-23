extends Control
## National Assembly Floor Voting (ST23): a single Yes/No/Abstain choice.
##
## Deliberately simple, the same family as VisitorScreen — no cards, no
## energy, no turns. A bill's scroll text sits in the middle, six party
## leader portraits show where each party already stands (their own baked-in
## disposition — Supportive/Opposed/Neutral — decides which face they wear
## and which line they say), and three buttons decide the player's own
## party's seat. FloorVoteEngine.gd does the actual reallocation math and
## favorability deltas; this screen only shows what it returns.
##
## Layout, top to bottom:
##   header       "National Assembly Floor Voting 本会議採決"
##   party row    six leader portraits, their own cue underneath each
##   scroll       the bill's own descriptive text
##   choices      Vote Yes / Vote No / Abstain
## then an outcome panel: three PartyVoteBars (Yes/No/Abstain) and the
## result, the same overlay pattern VisitorScreen's own outcome panel uses.

const OFFICE_SCENE := StageRouting.OFFICE_SCENE

## Which level/stage to open when no level is in progress — running this
## scene on its own from the editor.
@export var level_id: String = "LV01"
@export var stage_id: String = "ST23"

var engine: FloorVoteEngine = null

var _stage: Dictionary = {}
var _ready_to_play := false
var _voted := false

@onready var _stage_name: Label = %StageName
@onready var _stage_name_jp: Label = %StageNameJP
@onready var _party_row: Control = %PartyRow
@onready var _bill_text: Label = %BillText
@onready var _vote_yes: Button = %VoteYes
@onready var _vote_no: Button = %VoteNo
@onready var _vote_abstain: Button = %VoteAbstain
@onready var _background: PlaceholderArt = %Background
@onready var _notice: Label = %Notice

@onready var _outcome_panel: PanelContainer = %OutcomePanel
@onready var _outcome_title: Label = %OutcomeTitle
@onready var _outcome_body: Label = %OutcomeBody
## The organization changes of the player's stance at the vote, as chips.
var _stance_chips: Array = []

## Extra votes the player has chosen to whip, and the vote buttons' own words.
var _whips := 0
var _whip_note := ""
var _vote_words := {}
@onready var _bar_yes: PartyVoteBar = %BarYes
@onready var _bar_no: PartyVoteBar = %BarNo
@onready var _bar_abstain: PartyVoteBar = %BarAbstain
@onready var _outcome_close: Button = %OutcomeClose

var _messages: MessagePresenter = null

## The influence-swing cutscene (2026-09-28, §7.7): built exactly like
## LevelIntroScreen's own CueBanner — this screen never used one before.
var _banner: CueBanner = null


func _ready() -> void:
	_background.kind = PlaceholderArt.Kind.BACKGROUND
	_background.show_label = false
	_messages = MessagePresenter.new(_notice, get_tree())

	_banner = CueBanner.new()
	_banner.name = "CueBanner"
	add_child(_banner)

	_vote_yes.pressed.connect(_on_vote.bind("Yes"))
	_vote_no.pressed.connect(_on_vote.bind("No"))
	_vote_abstain.pressed.connect(_on_vote.bind("Abstain"))
	_outcome_close.pressed.connect(_on_outcome_closed)

	var outcome_scroll := _outcome_panel.get_node_or_null("Margin/Scroll") as ScrollContainer
	if outcome_scroll != null:
		DragScroll.attach(outcome_scroll)
	_outcome_panel.hide()
	start_voting()


## Builds the room from the level in progress, or the exported level/stage
## when run on its own — the same two routes VisitorScreen.start_visiting()
## offers.
func start_voting() -> void:
	if GameState.is_in_level():
		_stage = GameState.level_runner.current_stage()
	else:
		var expanded := BattleSetup.expand_level(DataDB.get_level(level_id))
		_stage = {}
		for stage: Dictionary in expanded.get("stages", []):
			if str(stage.get("stage_id", "")) == stage_id:
				_stage = stage
				break

	if _stage.is_empty():
		_ready_to_play = false
		_messages.say(Text.say("battle.no_stage"))
		StageStartFailure.show_on(self, Text.say("battle.no_stage"))
		return

	_stage_name.text = str(_stage.get("name_en", "National Assembly Floor Voting"))
	_stage_name_jp.text = str(_stage.get("name_jp", ""))
	_fit_stage_name.call_deferred()
	_background.art_id = str(_stage.get("stage_id", ""))

	engine = FloorVoteEngine.new()
	if not engine.setup({
		"bill": _stage.get("floor_vote", {}),
		"player_party": str(DataDB.player.get("party", "")),
		"meta": GameState.effective_meta(),
		"booster_standing": GameState.booster_standing,
		"triggers": DataDB.vote_influence_triggers,
		"default_threshold": int(DataDB.balance.get("vote_influence_default_threshold", 85)),
		"resistance_by_party": _resistance_by_party(),
		"default_resistance": int(DataDB.balance.get("vote_swing_resistance_default", 70)),
		"supermajority_percent": int(DataDB.balance.get("supermajority_percent", 67)),
		"assist": GameState.bill_assist,
	}):
		_ready_to_play = false
		_vote_yes.disabled = true
		_vote_no.disabled = true
		_vote_abstain.disabled = true
		var why := Text.say("battle.cannot_start",
			{"problems": "\n• ".join(Array(engine.setup_problems))})
		_messages.say(why)
		StageStartFailure.show_on(self, why)
		return

	_ready_to_play = true
	_voted = false
	GameState.mid_stage = GameState.is_in_level()
	Audio.play_music("music_office")

	_bill_text.text = str(engine.bill().get("bill_description", ""))
	_vote_yes.text = Text.say("floor_vote.vote_yes")
	_vote_no.text = Text.say("floor_vote.vote_no")
	_vote_abstain.text = Text.say("floor_vote.vote_abstain")
	_vote_words = {"Yes": _vote_yes.text, "No": _vote_no.text, "Abstain": _vote_abstain.text}
	_show_parties(engine.positions())
	_show_influence_and_preview()


## Under the bill: whether the player's influence can sway other parties yet
## (and what is still missing), then what each choice would give (2026-10-15).
## The labels are built in code beside BillText.
func _show_influence_and_preview() -> void:
	var holder := _bill_text.get_parent()
	if holder.name == "InfoColumn":
		holder = holder.get_parent().get_parent()
	var column := holder.find_child("InfoColumn", true, false) as VBoxContainer
	if column == null:
		# The text can run longer than the strip it sits in, so it scrolls.
		var scroll := ScrollContainer.new()
		scroll.name = "InfoScroll"
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		holder.add_child(scroll)
		DragScroll.attach(scroll)
		column = VBoxContainer.new()
		column.name = "InfoColumn"
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 16)
		scroll.add_child(column)
		_bill_text.reparent(column, false)
	for child in column.get_children():
		if child != _bill_text:
			child.queue_free()

	var rule := Label.new()
	rule.name = "VoteRequirement"
	rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var house := 0
	for position: Dictionary in engine.positions():
		house += int(position.get("votes_yes", 0)) + int(position.get("votes_no", 0)) \
			+ int(position.get("votes_abstain", 0))
	rule.text = Text.say("floor_vote.req_line", {
		"requirement": VoteWords.requirement_label(engine.requirement()),
		"needed": engine.yes_needed_now(), "house": house})
	column.add_child(rule)

	var status := engine.influence_status()
	var influence := Label.new()
	influence.name = "InfluenceStatus"
	influence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if bool(status.get("ready", false)):
		influence.text = Text.say("floor_vote.influence_ready")
	else:
		var needs: Array[String] = []
		var gaps: Array = status.get("missing", [])
		for gap: Dictionary in gaps.slice(0, 3):
			needs.append(Text.say("floor_vote.influence_need", {
				"name": _variable_name(str(gap.get("variable", ""))),
				"have": Phrase.with_separators(int(gap.get("value", 0))),
				"needed": Phrase.with_separators(int(gap.get("threshold", 0)))}))
		if gaps.size() > 3:
			needs.append(Text.say("floor_vote.influence_more", {"more": gaps.size() - 3}))
		influence.text = Text.say("floor_vote.influence_not_ready", {"needs": ", ".join(needs)})
	column.add_child(influence)

	# Members won over and lobbyists at work, when a patron bill's stages left any.
	var won := BillAssist.total(GameState.bill_assist, "won_over")
	var against := BillAssist.total(GameState.bill_assist, "worked_against")
	if won > 0:
		var won_label := Label.new()
		won_label.name = "AssistWon"
		won_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		won_label.text = Text.say("floor_vote.assist_won", {"count": won})
		column.add_child(won_label)
	if against > 0:
		var against_label := Label.new()
		against_label.name = "AssistAgainst"
		against_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		against_label.text = Text.say("floor_vote.assist_against", {"count": against})
		column.add_child(against_label)

	_build_whip_row(column)

	var preview := Label.new()
	preview.name = "VotePreview"
	preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var lines: Array[String] = [Text.say("floor_vote.preview_heading")]
	var labels := _vote_words.duplicate()
	engine.set_whips(_whips)
	for choice: String in labels:
		var trial := engine.preview(choice)
		if trial.is_empty():
			continue
		var totals: Dictionary = trial.get("totals", {})
		var result := Text.say("floor_vote.preview_passes" if bool(trial.get("passed", false))
			else "floor_vote.preview_fails")
		if bool(trial.get("flipped_by_influence", false)):
			result += " " + Text.say("floor_vote.preview_flips")
		lines.append(Text.say("floor_vote.preview_line", {
			"choice": labels[choice],
			"yes": totals.get("Yes", 0), "no": totals.get("No", 0),
			"abstain": totals.get("Abstain", 0), "result": result}))
		if _whips > 0:
			lines[-1] += " " + Text.say("floor_vote.preview_whip",
				{"cost": int(_whip_numbers(choice)["unit"]) * _whips})
	preview.text = "\n".join(lines)
	column.add_child(preview)

	if not GameState.stance_lean().is_empty():
		var stance := VBoxContainer.new()
		stance.name = "StancePreview"
		var heading := Label.new()
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		heading.text = Text.say("floor_vote.stance_heading", {
			"lean": StanceLines.lean_name(GameState.stance_lean())})
		stance.add_child(heading)
		for choice: String in ["Yes", "No", "Abstain"]:
			var trial := GameState.preview_stance_vote(choice)
			var chips := StanceLines.chip_entries(trial.get("deltas", {}))
			var party := int(trial.get("party_delta", 0))
			var line := Label.new()
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.text = Text.say("floor_vote.stance_line", {
				"choice": labels[choice],
				"changes": StanceLines.describe_changes({}, party) if (party != 0 or chips.is_empty()) else "",
				"switch": Text.say("floor_vote.stance_switch") if bool(trial.get("flip", false)) else ""})
			stance.add_child(line)
			if not chips.is_empty():
				stance.add_child(OrgChip.row(chips, true, 90.0))
		column.add_child(stance)


## What a whipped vote costs and allows for `choice`: the price of one extra
## vote and how many may be whipped (Balance levers; VoteWhip is the arithmetic).
func _whip_numbers(choice: String) -> Dictionary:
	var unit := VoteWhip.unit_cost(engine.own_disposition(), choice,
		int(DataDB.balance.get("whip_base_cost", 10)),
		int(DataDB.balance.get("whip_against_party_multiplier", 3)))
	unit = VoteWhip.discounted_unit(unit, _discount_orgs().size(),
		int(DataDB.balance.get("whip_discount_amount", 1)),
		int(DataDB.balance.get("whip_discount_floor", 5)))
	var allowed := VoteWhip.max_whips(unit, int(GameState.meta.get("Party support", 0)),
		int(DataDB.balance.get("whip_party_support_floor", 30)), engine.whip_capacity(choice),
		int(DataDB.balance.get("whip_max_per_vote", 3)))
	return {"unit": unit, "allowed": allowed}


## The organizations whose goodwill discounts the whip (see VoteWhip).
func _discount_orgs() -> Array[String]:
	return VoteWhip.discount_orgs(DataDB.party_stakeholders, DataDB.vote_influence_triggers,
		GameState.booster_standing, GameState.own_party_id(),
		int(DataDB.balance.get("whip_discount_standing", 65)),
		int(DataDB.booster_standing.get("start", 30)))


## "Whip the vote": fewer / more extra votes from your own party, with the
## price. The vote buttons carry the cost for the choice they make.
func _build_whip_row(column: VBoxContainer) -> void:
	var most := 0
	for choice: String in ["Yes", "No", "Abstain"]:
		most = maxi(most, int(_whip_numbers(choice)["allowed"]))
	_whips = mini(_whips, most)

	var box := VBoxContainer.new()
	box.name = "WhipRow"
	var heading := Label.new()
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.text = Text.say("floor_vote.whip_heading")
	box.add_child(heading)
	var base := int(DataDB.balance.get("whip_base_cost", 10))
	var info := Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.theme_type_variation = &"SmallLabel"
	info.text = Text.say("floor_vote.whip_cost", {
		"base": base, "against": base * int(DataDB.balance.get("whip_against_party_multiplier", 3)),
		"have": int(GameState.meta.get("Party support", 0)),
		"floor": int(DataDB.balance.get("whip_party_support_floor", 30))})
	box.add_child(info)
	var friends := _discount_orgs()
	if not friends.is_empty():
		var names: Array[String] = []
		for booster_id: String in friends:
			names.append(str(DataDB.get_booster(booster_id).get("name_en", booster_id)))
		var perk := Label.new()
		perk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		perk.theme_type_variation = &"SmallLabel"
		perk.text = Text.say("floor_vote.whip_discount", {
			"orgs": ", ".join(names), "amount": int(DataDB.balance.get("whip_discount_amount", 1))})
		box.add_child(perk)
	if most <= 0:
		var none := Label.new()
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		none.text = Text.say("floor_vote.whip_none")
		box.add_child(none)
	else:
		var controls := HBoxContainer.new()
		controls.add_theme_constant_override("separation", 16)
		var less := Button.new()
		less.name = "WhipLess"
		less.text = Text.say("floor_vote.whip_less")
		less.disabled = _whips <= 0
		less.pressed.connect(_on_whip_changed.bind(-1))
		var count := Label.new()
		count.name = "WhipCount"
		count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		count.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count.custom_minimum_size = Vector2(0, 0)
		count.text = Text.say("floor_vote.whip_count", {"count": _whips, "max": most})
		var more := Button.new()
		more.name = "WhipMore"
		more.text = Text.say("floor_vote.whip_more")
		more.disabled = _whips >= most
		more.pressed.connect(_on_whip_changed.bind(1))
		controls.add_child(less)
		controls.add_child(count)
		controls.add_child(more)
		box.add_child(controls)
	column.add_child(box)
	_refresh_vote_buttons()


func _on_whip_changed(step: int) -> void:
	if _voted:
		return
	_whips = maxi(_whips + step, 0)
	_show_influence_and_preview()


## The vote buttons name what whipping costs for their choice, and are greyed
## when the player cannot afford that many whips for it.
func _refresh_vote_buttons() -> void:
	var buttons := {"Yes": _vote_yes, "No": _vote_no, "Abstain": _vote_abstain}
	for choice: String in buttons:
		var button: Button = buttons[choice]
		# Wraps, so a long price line never widens the whole screen.
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var numbers := _whip_numbers(choice)
		if _whips > 0:
			button.text = Text.say("floor_vote.vote_with_whip",
				{"vote": _vote_words[choice], "cost": int(numbers["unit"]) * _whips})
			button.disabled = _voted or _whips > int(numbers["allowed"])
		else:
			button.text = _vote_words[choice]
			button.disabled = _voted


## A trigger variable as the player knows it: a booster's name, or the meta
## variable's own name.
func _variable_name(variable: String) -> String:
	if not variable.begins_with("BO"):
		return variable   # a meta variable such as Reputation names itself
	var booster := DataDB.get_booster(variable)
	return str(booster.get("name_en", variable)) if not booster.is_empty() else variable


## Every real party's own "Vote Resistance" (parties.json's own
## vote_resistance), by party_name rather than party_id — the shape
## FloorVoteEngine wants, matching how its own positions are keyed. A party
## that leaves the column blank is simply absent here; the engine falls
## back to the flat default itself.
func _resistance_by_party() -> Dictionary:
	var resistance: Dictionary = {}
	for party: Dictionary in DataDB.parties:
		var value: Variant = party.get("vote_resistance")
		if value != null:
			resistance[str(party.get("name", ""))] = int(value)
	return resistance


## PartyRow's own effective width — 1080's own base resolution (§3) minus
## Safe's 40px margin on each side. A constant rather than PartyRow.size.x:
## _show_parties() runs from _ready(), before this Control's own sort pass
## is guaranteed to have run, so its size could still read as whatever the
## .tscn shipped (0) rather than what the VBoxContainer above it actually
## gives it once laid out.
const _ROW_WIDTH := 1000.0
const _CARD_WIDTH := 150.0
## How far the arc's peak rises above its own two ends (2026-09-30, Cameron:
## a semicircle, not a cramped single row) — a dome, the two end parties
## lowest and the two middle ones highest, the shape a hemicycle's own back
## benches are usually diagrammed in.
const _ARC_HEIGHT := 110.0


## One card per party, positioned along a semicircular arc rather than a
## single row (2026-09-30, Cameron: six full portrait-plus-cue blocks in one
## HBoxContainer row compressed and overlapped on a 1080px-wide screen) —
## left to right in the bill's own position order, the same order Cameron
## asked for (Butsutou, Yezo Heritage Party, Frontier Party, Five Point
## Independents, Keizaijiyuutou, Country Initiative), since that is simply
## the order floor_votes.json's own Floor Vote Party Positions rows are in
## for every real bill. A portrait faced for their disposition, their name
## in their own colour, and their own cue line underneath.
func _show_parties(positions: Array) -> void:
	var cards := _party_row.get_children()
	var last := maxi(cards.size() - 1, 1)
	for index in cards.size():
		var card: Control = cards[index]
		card.visible = index < positions.size()
		# Positioned whether visible or not — cheap, and means a bill with
		# fewer than six real positions (never happens today, but the loop
		# already guards for it) still lays out evenly rather than leaving
		# a gap where a hidden card's own slot would have been.
		# Evenly spaced left to right by x, not by angle: spacing every card
		# an equal angle apart around a true circle bunches the two end
		# cards against their neighbours (cosine is flattest near 0°/180°),
		# which is what overlapped Butsutou/Yezo Heritage Party and
		# Keizaijiyuutou/Country Initiative the first time this was tried —
		# caught on a real screenshot, not guessed at. Evenly spaced x with
		# a sine-curve height keeps the dome look with guaranteed gaps.
		var t := float(index) / float(last)
		var x := t * (_ROW_WIDTH - _CARD_WIDTH)
		var y := _ARC_HEIGHT * (1.0 - sin(PI * t))
		card.position = Vector2(x, y)
		if index >= positions.size():
			continue

		var position: Dictionary = positions[index]
		var portrait: PlaceholderArt = card.get_node("Portrait")
		var swatch: ColorRect = card.get_node("Swatch")
		var name_label: Label = card.get_node("Name")
		var cue_label: Label = card.get_node("Cue")

		var leader_id := str(DataDB.get_party_by_id(str(position.get("party_id", ""))).get("leader_opp_id", ""))
		portrait.kind = PlaceholderArt.Kind.CHARACTER
		portrait.art_id = leader_id if not leader_id.is_empty() else str(position.get("party_id", ""))
		portrait.expression = _expression_for(str(position.get("disposition", "")))

		var color := _party_color(position)
		swatch.color = color
		name_label.text = str(position.get("party_name", ""))
		name_label.add_theme_color_override("font_color", color)
		cue_label.text = str(position.get("cue_text", ""))


func _expression_for(disposition: String) -> String:
	match disposition:
		"Supportive": return ArtLoader.GAINING
		"Opposed": return ArtLoader.ATTACKING
		_: return ArtLoader.NEUTRAL


func _party_color(position: Dictionary) -> Color:
	var rgb: Array = position.get("party_color", [128, 128, 128])
	return Color(int(rgb[0]) / 255.0, int(rgb[1]) / 255.0, int(rgb[2]) / 255.0)


func _on_vote(choice: String) -> void:
	if not _ready_to_play or _voted or engine == null:
		return
	var numbers := _whip_numbers(choice)
	if _whips > int(numbers["allowed"]):
		return   # the button is greyed for this; belt and braces
	_voted = true
	_vote_yes.disabled = true
	_vote_no.disabled = true
	_vote_abstain.disabled = true

	engine.set_whips(_whips)
	var result := engine.choose(choice)
	var bill_name := str(engine.bill().get("bill_name", ""))
	var whipped := int(result.get("whips_applied", 0))
	var whip_cost := whipped * int(numbers["unit"])
	if whipped > 0:
		GameState.spend_party_support(whip_cost, Text.say("record.cause_whip", {"bill": bill_name}))
		_whip_note = Text.say("floor_vote.whip_result", {"count": whipped, "cost": whip_cost})
	GameState.apply_floor_vote_favorability(result.get("favorability_deltas", {}),
		Text.say("record.cause_vote", {"bill": bill_name}))
	# Into the statute book, applying the bill's own "once" Law Effects.
	GameState.record_floor_vote(engine.bill(), result, choice)
	var stance_result := GameState.apply_stance_vote(choice)
	var stance_note := ""
	if not stance_result.is_empty():
		_stance_chips = StanceLines.chip_entries(stance_result.get("deltas", {}))
		if int(stance_result.get("party_delta", 0)) != 0 or _stance_chips.is_empty():
			stance_note = Text.say("floor_vote.stance_result", {"changes": StanceLines.describe_changes(
				{}, int(stance_result.get("party_delta", 0)))})

	if bool(result.get("outcome_flipped_by_influence", false)):
		var bill_id := str(engine.bill().get("bill_id", ""))
		var direction := (VoteInfluenceCues.FLIPPED_TO_PASS if bool(result.get("passed", false))
			else VoteInfluenceCues.FLIPPED_TO_FAIL)
		var line := VoteInfluenceCues.resolve(DataDB.vote_influence_cues, bill_id, direction)
		_banner.say(CueBanner.PLAYER, "", line)
		var bonus := FloorVoteEngine.influence_bonus(engine.bill())
		GameState.apply_floor_vote_influence_bonus(bonus["reputation"], bonus["party_support"],
			Text.say("record.cause_influence", {"bill": bill_name}))
		GameState.record_bill_flip(bill_id)
		GameState.apply_flip_backing(engine.bill(), result)

	_show_outcome(result, stance_note)


## The organization chips under the outcome text, rebuilt each time.
func _show_outcome_chips(entries: Array) -> void:
	var old := _outcome_body.get_parent().get_node_or_null("OutcomeChips")
	if old != null:
		old.free()
	if entries.is_empty():
		return
	var chips := OrgChip.row(OrgChip.merged(entries))
	chips.name = "OutcomeChips"
	_outcome_body.get_parent().add_child(chips)
	_outcome_body.get_parent().move_child(chips, _outcome_body.get_index() + 1)


func _show_outcome(result: Dictionary, stance_note: String = "") -> void:
	# The influence note and the choice preview are moot once the vote is cast,
	# and would show through the result panel.
	var info := find_child("InfoScroll", true, false) as Control
	if info != null:
		info.hide()
	var totals: Dictionary = result.get("totals", {})
	var passed := bool(result.get("passed", false))

	_outcome_title.text = Text.say("floor_vote.title")
	_outcome_body.text = Text.say("floor_vote.passed" if passed else "floor_vote.failed", {
		"yes": totals.get("Yes", 0), "no": totals.get("No", 0), "abstain": totals.get("Abstain", 0),
	})
	if not stance_note.is_empty():
		_outcome_body.text += "\n" + stance_note
	if not _whip_note.is_empty():
		_outcome_body.text += "\n" + _whip_note
	for line: String in RequestLines.outcome_lines(GameState.last_patron_outcome):
		_outcome_body.text += "\n" + line

	_show_outcome_chips(RequestLines.outcome_entries(GameState.last_patron_outcome) + _stance_chips)
	_show_result_summary(result, totals, passed)
	_bar_yes.show_segments(_segments_for(result.get("positions", []), "votes_yes"))
	_bar_no.show_segments(_segments_for(result.get("positions", []), "votes_no"))
	_bar_abstain.show_segments(_segments_for(result.get("positions", []), "votes_abstain"))

	_outcome_close.text = (Text.say("outcome.close") if not GameState.is_in_level()
		else (Text.say("outcome.back_to_office") if OutcomePresenter.is_last_stage_of_level()
			else Text.say("outcome.next_stage")))

	_outcome_panel.show()


## Aye / Nay / Abstain tiles, a whole-house meter with the pass mark, and one
## line saying what the bill needed and by how much it cleared or missed it.
## Built in code beside OutcomeBody and rebuilt on every call (2026-10-15).
func _show_result_summary(result: Dictionary, totals: Dictionary, passed: bool) -> void:
	var column := _outcome_body.get_parent()
	for old in column.get_children():
		if str(old.name).begins_with("Summary"):
			column.remove_child(old)
			old.queue_free()

	var needed := int(result.get("yes_needed", 0))
	var yes := int(totals.get("Yes", 0))
	var house := yes + int(totals.get("No", 0)) + int(totals.get("Abstain", 0))

	var meter := VoteMeter.new()
	meter.name = "SummaryMeter"
	meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meter.show_totals(yes, int(totals.get("No", 0)), int(totals.get("Abstain", 0)), needed)

	var requirement_text := VoteWords.requirement_label(str(result.get("requirement", FloorVoteEngine.MAJORITY)))
	var reason := Label.new()
	reason.name = "SummaryReason"
	reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reason.text = Text.say("floor_vote.req_line", {
		"requirement": requirement_text, "needed": needed, "house": house}) + " " + (
		Text.say("floor_vote.result_cleared", {"n": yes - needed}) if passed
		else Text.say("floor_vote.result_short", {"n": needed - yes}))

	# The per-party bars are named in the same Aye / Nay words.
	for pair: Array in [["BarYesLabel", "floor_vote.bar_aye"], ["BarNoLabel", "floor_vote.bar_nay"],
			["BarAbstainLabel", "floor_vote.bar_abstain"]]:
		var label := find_child(str(pair[0]), true, false) as Label
		if label != null:
			label.text = Text.say(str(pair[1]))
	var index := _outcome_body.get_index() + 1
	for node: Node in [meter, reason]:
		column.add_child(node)
		column.move_child(node, index)
		index += 1


func _segments_for(positions: Array, vote_field: String) -> Array[Dictionary]:
	var segments: Array[Dictionary] = []
	for position: Dictionary in positions:
		segments.append({
			"color": _party_color(position),
			"votes": int(position.get(vote_field, 0)),
			"label": str(position.get("party_name", "")),
		})
	return segments


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

	# A Floor Vote cannot be lost — it is a decision, not a contest — worth
	# whatever the stage's own win_delta_* fields say, same as Office Hours.
	var level_over := GameState.finish_stage(LevelRunner.WON)

	if level_over:
		GameState.end_level()
		get_tree().change_scene_to_file(OFFICE_SCENE)
	else:
		StageRouting.go_to_next_stage(get_tree(), StageRouting.FLOOR_VOTE_SCENE)


## A stage name that fits stays on one line beside its Japanese accent; one
## too long for the header (large text, a narrow phone) wraps instead of
## pushing the accent off the screen. Same rule as VisitorScreen's.
func _fit_stage_name() -> void:
	var header := _stage_name.get_parent().get_parent() as Control
	var font := _stage_name.get_theme_font("font")
	var font_size := _stage_name.get_theme_font_size("font_size")
	var needed := font.get_string_size(_stage_name.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var room := header.size.x - _stage_name_jp.get_combined_minimum_size().x - 48.0
	var wrap := needed > room
	_stage_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	_stage_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL if wrap else Control.SIZE_FILL
