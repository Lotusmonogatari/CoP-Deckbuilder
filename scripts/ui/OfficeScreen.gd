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
@onready var _resources: Label = %Resources
@onready var _cards_button: Button = %CardsButton
@onready var _deck_button: Button = %DeckButton
@onready var _backing_button: Button = %BackingButton
@onready var _cards_panel: Overlay = %CardsPanel
@onready var _deck_panel: Overlay = %DeckPanel
@onready var _backing_panel: Overlay = %BackingPanel

## The deck being built, while the deck screen is open. Kept here rather
## than read back off the buttons so the caption can count it as it changes.
var _draft_deck: Array[String] = []
@onready var _portrait: Control = %Portrait


func _ready() -> void:
	_start_button.pressed.connect(_show_briefing)
	_briefing_panel.confirmed.connect(_on_start)
	_deck_panel.confirmed.connect(_on_deck_confirmed)
	_organisations_button.pressed.connect(_show_organisations)
	_cards_button.pressed.connect(_show_cards)
	_deck_button.pressed.connect(_show_deck)
	_backing_button.pressed.connect(_show_backing)
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
	_refresh_resources()


## What there is to spend, and what the deck looks like.
##
## Two currencies on one line: XP buys cards, Funds buy the organisations'
## backing. A shop screen the player has to open to find out whether they can
## afford anything is a shop screen they stop opening.
func _refresh_resources() -> void:
	var funds := int(GameState.meta.get("Funds", 0))
	var size := Ledger.deck_size(DataDB.balance)
	_resources.text = "XP %d  ·  Funds %d  ·  Deck %d of %d" % [
		GameState.xp, funds, GameState.deck.size(), size]

	# A deck that is not legal cannot start a level, so say so here rather
	# than letting the player find out at the briefing.
	var refusal := Ledger.deck_refusal(GameState.deck, GameState.owned_cards, DataDB.balance)
	if not refusal.is_empty():
		_resources.text += "  —  %s" % refusal


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


# ---------------------------------------------------------------------------
# Spending what a run has earned
# ---------------------------------------------------------------------------
# Three screens, one shape: a list of things, each with its price and either
# a button to buy it or the reason you cannot. Every one of those answers
# comes from the Ledger, so a screen can never offer what the rules would
# refuse, and the refusal the player reads is the rules' own words.

## New cards, bought with XP.
##
## Cards are listed by tier with the cheapest first, and the ones already
## yours are shown too: a shop that hides what you own makes it hard to
## remember why you cannot buy something.
func _show_cards() -> void:
	var rows: Array[Control] = []
	rows.append(_wrapped_label("Cards you unlock join your collection. What "
		+ "you actually take into a debate is chosen on the deck screen."))
	rows.append(_wrapped_label("XP %d" % GameState.xp, "HeaderLabel"))

	for tier: String in ["Tier 1", "Tier 2"]:
		var in_tier := DataDB.get_cards_by_tier(tier)
		if in_tier.is_empty():
			continue
		rows.append(_heading_label(tier))
		for card: Dictionary in in_tier:
			rows.append(_card_row(card))

	var owned_extra := GameState.owned_cards.size() - DataDB.get_cards_by_tier("Starter").size()
	if owned_extra > 0:
		rows.append(_wrapped_label(""))
		rows.append(_wrapped_label("%d card%s unlocked so far."
			% [owned_extra, "" if owned_extra == 1 else "s"], "SmallLabel"))

	_cards_panel.open("New cards", rows)


func _card_row(card: Dictionary) -> Control:
	var card_id := str(card.get("card_id", ""))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)

	box.add_child(_wrapped_label("%s %s  —  %d XP" % [
		card.get("name_en", card_id), card.get("name_jp", ""),
		Ledger.card_cost(card)]))
	box.add_child(_wrapped_label("%s  ·  %s" % [
		card.get("suit", ""), card.get("effect_text", "")], "SmallLabel"))

	var refusal := Ledger.card_refusal(card, GameState.owned_cards, GameState.xp)
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 90)
	button.text = "Unlock" if refusal.is_empty() else refusal
	button.disabled = not refusal.is_empty()
	if refusal.is_empty():
		button.pressed.connect(_on_buy_card.bind(card_id))
	box.add_child(button)
	return box


func _on_buy_card(card_id: String) -> void:
	var refusal := GameState.buy_card(card_id)
	if not refusal.is_empty():
		_report.text = refusal
		return
	_refresh_resources()
	_show_cards()   # rebuilt, so the price and what is left are current


## The deck: which of the cards you own are going in.
##
## A fixed size, so unlocking a card means leaving another out. Without that
## constraint an unlock would be a free upgrade and the screen would have
## nothing to decide.
func _show_deck() -> void:
	_draft_deck = GameState.deck.duplicate()
	_build_deck_screen()


func _build_deck_screen() -> void:
	var size := Ledger.deck_size(DataDB.balance)
	var rows: Array[Control] = []

	var refusal := Ledger.deck_refusal(_draft_deck, GameState.owned_cards, DataDB.balance)
	rows.append(_wrapped_label("%d of %d chosen%s" % [
		_draft_deck.size(), size,
		"" if refusal.is_empty() else "  —  " + refusal], "HeaderLabel"))
	rows.append(_wrapped_label("Tap a card to take it in or leave it out."))

	for card_id: String in GameState.owned_cards:
		var card := DataDB.get_card(card_id)
		if card.is_empty():
			continue
		rows.append(_deck_row(card, card_id))

	# Confirmed rather than saved as you go: a half-built deck should not be
	# able to become the deck you start a level with.
	_deck_panel.open("Your deck", rows,
		"Take these in" if refusal.is_empty() else "")


func _deck_row(card: Dictionary, card_id: String) -> Control:
	var chosen := _draft_deck.has(card_id)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)

	# The name goes on the button and the effect underneath it. Both on the
	# button ran a long card off the side of the screen and gave the panel a
	# horizontal scrollbar.
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 80)
	button.text = "%s  %s" % ["✓" if chosen else "–", card.get("name_en", card_id)]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(_on_toggle_card.bind(card_id))
	box.add_child(button)

	var effect := _wrapped_label(str(card.get("effect_text", "")), "SmallLabel")
	box.add_child(effect)

	# Dimmed as a whole when it is being left out, so the deck reads at a
	# glance rather than by hunting for ticks.
	if not chosen:
		box.modulate = Color(1, 1, 1, 0.5)
	return box


func _on_toggle_card(card_id: String) -> void:
	if _draft_deck.has(card_id):
		_draft_deck.erase(card_id)
	else:
		_draft_deck.append(card_id)
	_build_deck_screen()


func _on_deck_confirmed() -> void:
	var refusal := GameState.set_deck(_draft_deck)
	if not refusal.is_empty():
		_report.text = refusal
	_refresh_resources()


## The organisations' backing, bought with Funds.
##
## An organisation will not sell you its backing until you have given it
## reason to — Cameron's decision, and the first thing standing has ever
## done. Pleasing a group at a press conference is what raises it.
func _show_backing() -> void:
	var rows: Array[Control] = []
	rows.append(_wrapped_label("An organisation backs you once your standing "
		+ "with it is high enough. Answering a reporter in the suit their "
		+ "question invites is what raises it."))
	rows.append(_wrapped_label("Funds %d" % int(GameState.meta.get("Funds", 0)),
		"HeaderLabel"))

	var names := BattleSetup.booster_names()
	var for_sale := DataDB.modifiers.filter(
		func(m: Dictionary) -> bool: return Ledger.is_for_sale(m))

	if for_sale.is_empty():
		rows.append(_wrapped_label("Nothing is for sale."))
	for modifier: Dictionary in for_sale:
		rows.append(_modifier_row(modifier, names))

	_backing_panel.open("Backing", rows)


func _modifier_row(modifier: Dictionary, names: Dictionary) -> Control:
	var mod_id := str(modifier.get("mod_id", ""))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)

	box.add_child(_wrapped_label("%s  —  %d funds" % [
		modifier.get("name_en", mod_id), Ledger.modifier_cost(modifier)]))

	var booster := Ledger.backing_booster(modifier, BattleSetup.booster_ids())
	if not booster.is_empty():
		var have := int(GameState.booster_standing.get(booster, 0))
		var needed := Ledger.standing_needed(modifier, DataDB.booster_standing)
		var standing := ("%s  ·  standing %d" % [names.get(booster, booster), have]
			if have >= needed
			else "%s  ·  standing %d, needs %d" % [names.get(booster, booster), have, needed])
		box.add_child(_wrapped_label(standing, "SmallLabel"))

	# What it does, in a sentence with the real number in it — not the
	# workbook's "+Magnitude player start support".
	box.add_child(_wrapped_label(
		ModifierEffects.describe(modifier, DataDB.modifier_effects), "SmallLabel"))

	# An effect nothing implements yet is said out loud. A shop that sells
	# something inert is the trap this project has walked into twice.
	if ModifierEffects.is_inert_today(modifier, DataDB.modifier_effects):
		box.add_child(_wrapped_label("No effect yet — your record always "
			+ "opens clean, so there is nothing here to take off.", "SmallLabel"))
	elif not ModifierEffects.is_implemented(modifier, DataDB.modifier_effects):
		box.add_child(_wrapped_label("Not active yet — this effect is still "
			+ "to be built.", "SmallLabel"))

	var refusal := Ledger.modifier_refusal(modifier, GameState.owned_modifiers,
		int(GameState.meta.get("Funds", 0)), GameState.booster_standing,
		DataDB.booster_standing, BattleSetup.booster_ids())
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 90)
	button.text = "Take their backing" if refusal.is_empty() else refusal
	button.disabled = not refusal.is_empty()
	if refusal.is_empty():
		button.pressed.connect(_on_buy_modifier.bind(mod_id))
	box.add_child(button)
	return box


func _on_buy_modifier(mod_id: String) -> void:
	var refusal := GameState.buy_modifier(mod_id)
	if not refusal.is_empty():
		_report.text = refusal
		return
	_refresh_resources()
	_show_backing()


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
