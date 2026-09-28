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

@onready var _title: Label = %Title

## "· {party}", coloured with the party's own RGB (PartyDisplay.gd) —
## split out of what used to be one "{name} · {party}" string on _title
## itself so only the party portion can carry the colour. Built in code
## and inserted right after _title, the same reason _notices_label is.
var _title_party: Label
@onready var _subtitle: Label = %Subtitle
@onready var _report: Label = %Report
@onready var _start_button: Button = %StartButton
@onready var _organisations_button: Button = %OrganisationsButton
@onready var _organisations_panel: Overlay = %OrganisationsPanel
@onready var _briefing_panel: Overlay = %BriefingPanel
@onready var _levels_panel: Overlay = %LevelsPanel

## The level the player is looking at, chosen on the levels screen.
var _chosen_level: Dictionary = {}
@onready var _resources: Label = %Resources

## The Office's own dynamic flavor line(s) — data/office_notices.json,
## resolved fresh every _build() against the current staff and meta
## (OfficeNotices.gd). Built in code and inserted right after %Resources,
## the same reason _inventory_panel is: no scene-file edit needed for one
## more label in an existing column.
var _notices_label: Label
@onready var _management_button: Button = %ManagementButton
@onready var _management_panel: Overlay = %ManagementPanel
@onready var _cards_panel: Overlay = %CardsPanel
@onready var _deck_panel: Overlay = %DeckPanel
@onready var _backing_panel: Overlay = %BackingPanel
@onready var _staff_panel: Overlay = %StaffPanel

## The deck being built, while the deck screen is open. Kept here rather
## than read back off the buttons so the caption can count it as it changes.
var _draft_deck: Array[String] = []
@onready var _portrait: Control = %Portrait

## The Office's own picture, data/art.json's "OFFICE" background. Fixed —
## unlike the battle screen's, it never changes stage — so it is set once
## here rather than by whatever opens the screen.
@onready var _background: PlaceholderArt = %Background

## The Marketplace: the inventory grid and the Supplies shop together
## (design/proposals/inventory.md, folded together 2026-09-28). Built in
## code rather than placed in the scene, the same way the battle screen
## builds its card zoom: it is this script's to own.
var _inventory_panel: InventoryPanel

## "Your Record" (2026-09-28): lifetime stats — bills the influence swing
## has flipped, how many times each level has been cleared, and clears per
## tier. Built in code, the same reason _inventory_panel is.
var _record_panel: Overlay

## Cosmetic packages (2026-09-28): purely decorative outfit/background/music
## bundles, bought here and equipped per slot. Built in code, the same
## reason _record_panel is.
var _cosmetics_panel: Overlay

## Rhetoric Training's card offer (SH15-17, SH27-29) — Cameron, 2026-09-25:
## showing the card itself, not just naming it in a sentence, is what makes
## drawing a random one feel like a pull rather than a database write; and
## 2026-09-27, it is shown BEFORE paying, with Learn it / Pass. Built in
## code, the same reason _inventory_panel is.
var _card_reveal_panel: Overlay

## New Game: the warning before a run is thrown away, and the choice of
## protagonist. Built in code, like the inventory.
var _new_game_panel: Overlay

## The warning before firing a hired Staff member — built in code, the same
## way, since firing is permanent and costs a severance (Ledger.
## staff_firing_cost()) — see design/proposals/staff_firing.md.
var _fire_staff_panel: Overlay

## Which role's Fire button opened _fire_staff_panel, so the confirm handler
## (which the panel's `confirmed` signal carries no argument for) knows who.
var _firing_role := ""

## What a crisis trigger firing or resolving looks like, once the player is
## back at the Office to hear about it — same idea as the battle screen's
## own outcome panel, built in code the same way _fire_staff_panel is.
## GameState.pending_trigger_alerts is the news; this is just how it's read.
var _trigger_alert_panel: Overlay

## The scrolling news strip at the bottom of the screen — data/office_ticker.json
## via OfficeTicker.gd, driven every frame from _process(). See
## TickerPresenter.gd.
var _ticker: TickerPresenter
@onready var _ticker_strip: Control = %Ticker
@onready var _ticker_label: Label = %TickerLabel


func _ready() -> void:
	_background.kind = PlaceholderArt.Kind.BACKGROUND
	_background.art_id = "OFFICE"
	_background.show_label = false

	_start_button.pressed.connect(_on_start_pressed)
	_briefing_panel.confirmed.connect(_on_start)
	_deck_panel.confirmed.connect(_on_deck_confirmed)
	_organisations_button.pressed.connect(_show_organisations)
	_management_button.pressed.connect(_show_management)
	_build_inventory()
	_build_record()
	_build_cosmetics()
	_new_game_panel = Overlay.new()
	_new_game_panel.name = "NewGamePanel"
	add_child(_new_game_panel)
	_fire_staff_panel = Overlay.new()
	_fire_staff_panel.name = "FireStaffPanel"
	add_child(_fire_staff_panel)
	_fire_staff_panel.confirmed.connect(_on_fire_staff_confirmed)
	_trigger_alert_panel = Overlay.new()
	_trigger_alert_panel.name = "TriggerAlertPanel"
	add_child(_trigger_alert_panel)
	_card_reveal_panel = Overlay.new()
	_card_reveal_panel.name = "CardRevealPanel"
	# Learn it (or Pass, while passes remain) are the only ways on: a draw
	# must end in a learned card (Cameron, 2026-09-27).
	_card_reveal_panel.dismissable = false
	_card_reveal_panel.show_back = false
	add_child(_card_reveal_panel)
	_card_reveal_panel.confirmed.connect(_on_learn_confirmed)

	_ticker = TickerPresenter.new(_ticker_strip, _ticker_label)

	_notices_label = Label.new()
	_notices_label.name = "NoticesLabel"
	_notices_label.theme_type_variation = &"SmallLabel"
	_notices_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var column := _resources.get_parent()
	column.add_child(_notices_label)
	column.move_child(_notices_label, _resources.get_index() + 1)

	_title_party = Label.new()
	_title_party.name = "TitleParty"
	_title_party.theme_type_variation = &"TitleLabel"
	var heading := _title.get_parent()
	heading.add_child(_title_party)
	heading.move_child(_title_party, _title.get_index() + 1)

	# The Office's own bed. Silent until there is a file named against
	# music_office in sounds.json; this is here so that adding one is the
	# whole job, with nothing to wire up afterwards.
	Audio.play_music("music_office")

	_build()

	# No save to come back to: a new player chooses who they are first.
	if GameState.awaiting_new_game:
		_show_new_game(true)
	else:
		SaveManager.autosave()
		# A Rhetoric Training draw left on screen when the app closed comes
		# straight back, same card, same count — quitting is not a reroll.
		if not GameState.card_draw.is_empty():
			_show_rhetoric_training()
			_show_card_offer()


func _process(delta: float) -> void:
	if _ticker != null:
		_ticker.advance(delta)


func _build() -> void:
	var level := DataDB.playtest_level

	# Whose office it is. A placeholder name until the protagonist is cast,
	# but a named desk reads better than an anonymous one.
	var player := DataDB.player
	var name_en := str(player.get("name_en", ""))
	var party := PartyDisplay.party_name(player)

	if name_en.is_empty():
		_title.text = Text.say("office.title")
		_title_party.hide()
	elif party.is_empty():
		_title.text = "%s's Office" % name_en
		_title_party.hide()
	else:
		_title.text = name_en
		_title_party.text = "· %s" % party
		_title_party.add_theme_color_override("font_color", PartyDisplay.color_for(DataDB.get_party(party)))
		_title_party.show()
	_subtitle.text = "陳情"

	if _portrait is PlaceholderArt:
		var art := _portrait as PlaceholderArt
		art.kind = PlaceholderArt.Kind.CHARACTER
		art.art_id = str(player.get("player_id", ""))
		art.expression = "neutral"

	# A save taken between the stages of a level comes back here, and the
	# button goes straight back into that level rather than choosing another.
	_start_button.text = Text.say(
		"office.resume_level" if GameState.is_in_level() else "office.choose_level")
	_report.text = _last_level_report()
	_refresh_resources()
	_show_trigger_alerts_if_any()


## A crisis trigger firing or resolving since the last time the player was
## here (GameState.finish_stage()'s own edge-checks) — one popup, one line
## per event, shown once and then forgotten so it can never appear twice.
func _show_trigger_alerts_if_any() -> void:
	if GameState.pending_trigger_alerts.is_empty():
		return

	var rows: Array[Control] = []
	for alert: Dictionary in GameState.pending_trigger_alerts:
		var key := "office.trigger.%s.%s" % [alert.get("kind", ""), alert.get("edge", "")]
		rows.append(UiKit.line(Text.say(key, {
			"count": int(alert.get("count", 0)),
			"amount": int(alert.get("amount", 0)),
		})))
	GameState.pending_trigger_alerts = []

	_trigger_alert_panel.open(Text.say("office.trigger_alert_title"), rows)


## The one line the front page keeps about money.
##
## Everything you can SPEND now lives behind Office Management: a playtest
## reported not being able to find the XP and Funds stores at all, because
## they sat as a quiet line of text above four buttons that looked alike and
## none of which said which currency it wanted.
##
## What stays out here is the warning. A deck that is not legal cannot start
## a level, and a player must not have to open a panel to discover that.
func _refresh_resources() -> void:
	var refusal := Ledger.deck_refusal(GameState.deck, GameState.owned_cards, DataDB.balance, Text.phrase())
	if refusal.is_empty():
		_resources.text = Text.say("office.in_order")
	else:
		_resources.text = Text.say("office.deck_warning", {"reason": refusal})
	_refresh_notices()


## What the Office looks like right now — data/office_notices.json resolved
## against the current staff and meta (OfficeNotices.gd). Hidden entirely
## when nothing qualifies, rather than an empty line holding its place.
func _refresh_notices() -> void:
	var lines := OfficeNotices.resolve(
		DataDB.office_notices, GameState.staff_hired, GameState.meta, DataDB.staff)
	_notices_label.visible = not lines.is_empty()
	_notices_label.text = "\n".join(lines)


## What happened last time, if anything has happened yet.
##
## GameState holds nothing between runs until milestone 4 builds saving, so
## this currently only survives within one sitting. That is enough for the
## loop to feel closed.
func _last_level_report() -> String:
	var outcome: Variant = GameState.last_level_outcome
	if outcome == null or str(outcome).is_empty():
		return Text.say("office.report.none")

	match str(outcome):
		LevelRunner.WON:
			return Text.say("office.report.won")
		LevelRunner.LOST:
			return Text.say("office.report.lost")
		_:
			return ""


## Everything there is to spend, and everything to spend it on.
##
## One door rather than three side by side, and it leads with the two
## currencies and what each of them buys. Cameron could not find the stores
## at all in the last playtest: knowing you have 30 Funds is no use if
## nothing says that Funds are what backing costs.
func _show_management() -> void:
	var rows: Array[Control] = []
	var funds := int(GameState.meta.get("Funds", 0))
	var size := Ledger.deck_size(DataDB.balance)

	rows.append(UiKit.heading(Text.say("office.xp", {"count": GameState.xp})))
	rows.append(UiKit.line(
		Text.say("office.xp_buys"), "SmallLabel"))
	rows.append(UiKit.heading(Text.say("office.funds", {"count": funds})))
	rows.append(UiKit.line(
		Text.say("office.funds_buys"), "SmallLabel"))

	var refusal := Ledger.deck_refusal(GameState.deck, GameState.owned_cards, DataDB.balance, Text.phrase())
	rows.append(UiKit.heading(Text.say("office.deck_count",
		{"count": GameState.deck.size(), "size": size})))
	rows.append(UiKit.line(
		Text.say("office.deck_ready") if refusal.is_empty() else refusal, "SmallLabel"))

	for row: Array in [
		[Text.say("office.rhetoric_training"), _show_rhetoric_training],
		[Text.say("office.your_deck"), _show_deck],
		[Text.say("office.backing"), _show_backing],
		[Text.say("office.staff"), _show_staff],
		[Text.say("office.new_game"), _confirm_new_game],
	]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 100)
		button.text = str(row[0])
		button.pressed.connect(func() -> void:
			_management_panel.close()
			(row[1] as Callable).call())
		rows.append(button)

	_management_panel.open(Text.say("office.management"), rows)


## The ten organisations, and where the player stands with each.
##
## Grouped by tier rather than listed flat, because the tiers are the real
## distinction: a Constituency group is worth something different from a
## National one, and seeing them mixed together hides that.
func _show_organisations() -> void:
	var rows: Array[Control] = []

	rows.append(UiKit.line(Text.say("office.orgs_blurb")))

	for tier: String in ["Party", "Constituency", "National"]:
		var in_tier := DataDB.boosters.filter(
			func(b: Dictionary) -> bool: return str(b.get("tier", "")) == tier)
		if in_tier.is_empty():
			continue

		rows.append(UiKit.heading(tier))
		for booster: Dictionary in in_tier:
			rows.append(_organisation_row(booster))

	_organisations_panel.open(Text.say("office.organisations"), rows)


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

	var box := UiKit.tight_column()
	box.add_child(UiKit.line(line))

	# 2026-09-22 workbook: boosters.json no longer has a "boosts" summary
	# column — what an organisation does is the modifiers it links, so that
	# list is shown by name instead. A booster with no Linked modifiers at
	# all (BO17/BO18, 2026-09-26) exports as JSON null, not [] — the <null>
	# trap again (BarModel.for_stage()'s own comment).
	var linked_raw: Variant = booster.get("linked_modifiers")
	var linked: Array = linked_raw if linked_raw is Array else []
	var names: Array[String] = []
	for mod_id: String in linked:
		var modifier := DataDB.get_modifier(mod_id)
		if not modifier.is_empty():
			names.append(str(modifier.get("name_en", mod_id)))
	if not names.is_empty():
		box.add_child(UiKit.line(", ".join(names), "SmallLabel"))
	return box


# ---------------------------------------------------------------------------
# Spending what a run has earned
# ---------------------------------------------------------------------------
# Three screens, one shape: a list of things, each with its price and either
# a button to buy it or the reason you cannot. Every one of those answers
# comes from the Ledger, so a screen can never offer what the rules would
# refuse, and the refusal the player reads is the rules' own words.

## Rhetoric Training (Cameron, 2026-09-27): where new cards come from. One
## row per training session in shop.json — any item naming a "card_tier"
## (SH15-17 for XP, SH27-29 for Yen). "See a card" draws one random card of
## that tier the player doesn't own yet and shows it; nothing is paid until
## the player chooses to learn it (GameState.offer_random_card() /
## learn_offered_card()). Replaced the old "New cards" list, which let any
## card be bought outright for its XP price with no draw at all.
func _show_rhetoric_training() -> void:
	var rows: Array[Control] = []
	rows.append(UiKit.line(Text.say("rhetoric.blurb")))
	rows.append(UiKit.line(Text.say("office.xp", {"count": GameState.xp}), "HeaderLabel"))
	rows.append(UiKit.line(Text.say("office.funds",
		{"count": int(GameState.meta.get("Funds", 0))}), "HeaderLabel"))
	for item: Dictionary in DataDB.shop:
		if item.get("card_tier") != null:
			rows.append(_training_row(item))
	_cards_panel.open(Text.say("office.rhetoric_training"), rows)


func _training_row(item: Dictionary) -> Control:
	var item_id := str(item.get("item_id", ""))
	var box := UiKit.tight_column()
	box.name = "Training_" + item_id
	box.add_child(UiKit.line(Text.say("rhetoric.session",
		{"tier": int(item.get("card_tier", 0)), "price": _price_text(item)})))
	var button := UiKit.action_button(Text.say("rhetoric.see_card"),
		GameState.card_training_refusal(item_id), _on_see_card.bind(item_id))
	button.name = "SeeCard"
	box.add_child(button)
	return box


func _on_see_card(item_id: String) -> void:
	var offer := GameState.offer_random_card(item_id)
	if not offer.get("ok", false):
		_report.text = str(offer.get("message", ""))
		return
	# Only one draw can be in progress at a time (GameState.offer_random_
	# card()'s own doc comment; test_seeing_a_card_again_mid_draw_returns_
	# the_same_card_not_a_reroll() proves it, "even a different session").
	# Tapping a different row's "See a card" while one is already open
	# quietly reopens THAT draw rather than starting a new one — the price
	# shown is always honest, but nothing said why a different row's price
	# just appeared, until now.
	if str(offer.get("item_id", "")) != item_id:
		_report.text = Text.say("rhetoric.draw_in_progress")
	# On top of the training list, which stays open underneath.
	_show_card_offer()


func _on_pass_card() -> void:
	if GameState.pass_offered_card().get("ok", false):
		_show_card_offer()


func _on_learn_confirmed() -> void:
	var result := GameState.learn_offered_card()
	if result.get("ok", false):
		_report.text = str(result.get("message", ""))
		_after_spending("", _show_rhetoric_training)
	else:
		_after_spending(str(result.get("message", "")), _show_rhetoric_training)


## Every purchase ends the same way: the refusal on the front page if it was
## refused, otherwise the numbers redrawn and the shop rebuilt, so the prices
## and what is left are current.
func _after_spending(refusal: String, reopen: Callable) -> void:
	if not refusal.is_empty():
		_report.text = refusal
		return
	_refresh_resources()
	SaveManager.autosave()
	reopen.call()


# ---------------------------------------------------------------------------
# New game, and who you are
# ---------------------------------------------------------------------------

## Starting over throws the run away, so it asks first.
func _confirm_new_game() -> void:
	_new_game_panel.open(Text.say("office.new_game"),
		[UiKit.line(Text.say("office.new_game_warning"))],
		Text.say("office.new_game_confirm"))
	if not _new_game_panel.confirmed.is_connected(_on_new_game_confirmed):
		_new_game_panel.confirmed.connect(_on_new_game_confirmed)


func _on_new_game_confirmed() -> void:
	_new_game_panel.confirmed.disconnect(_on_new_game_confirmed)
	_show_new_game.call_deferred(false)


## The four protagonists (data/player.json), each with a portrait and a
## button. `first_run` is the very first launch: backing out of it still
## leaves the player as the default protagonist, so there is a run to save.
func _show_new_game(first_run: bool) -> void:
	var rows: Array[Control] = [UiKit.line(Text.say("new_game.blurb"))]
	for protagonist: Dictionary in DataDB.protagonists:
		rows.append(_protagonist_row(protagonist))
	_new_game_panel.open(Text.say("new_game.title"), rows)
	if first_run and not _new_game_panel.closed.is_connected(_on_first_run_closed):
		_new_game_panel.closed.connect(_on_first_run_closed)


func _protagonist_row(protagonist: Dictionary) -> Control:
	var player_id := str(protagonist.get("player_id", ""))
	var row := HBoxContainer.new()
	row.name = "Protagonist_" + player_id
	row.add_theme_constant_override("separation", 20)

	var portrait := PlaceholderArt.new()
	portrait.custom_minimum_size = Vector2(200, 260)
	portrait.kind = PlaceholderArt.Kind.CHARACTER
	portrait.art_id = player_id
	row.add_child(portrait)

	var box := UiKit.tight_column()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(box)
	var name_line := UiKit.heading(str(protagonist.get("name_en", player_id)))
	box.add_child(name_line)
	var name_jp := str(protagonist.get("name_jp", ""))
	if not name_jp.is_empty():
		box.add_child(UiKit.line(name_jp, "JapaneseAccent"))
	var party := PartyDisplay.party_name(protagonist)
	var party_label := UiKit.line(
		party if not party.is_empty() else Text.say("new_game.no_party"), "SmallLabel")
	if not party.is_empty():
		party_label.add_theme_color_override("font_color", PartyDisplay.color_for(DataDB.get_party(party)))
	box.add_child(party_label)
	var blurb := str(protagonist.get("blurb", ""))
	if not blurb.is_empty():
		box.add_child(UiKit.line(blurb, "SmallLabel"))
	box.add_child(UiKit.line(Text.say("new_game.starting_stats"), "SmallLabel"))
	for line: String in _starting_stat_lines(protagonist):
		box.add_child(UiKit.line(line, "SmallLabel"))
	for label: Label in box.get_children().filter(func(n: Node) -> bool: return n is Label):
		label.custom_minimum_size.x = UiKit.LINE_WIDTH - 220.0

	var choose := UiKit.action_button(Text.say("new_game.choose",
		{"name": protagonist.get("name_en", player_id)}), "", _on_protagonist_chosen.bind(player_id))
	choose.name = "Choose"
	box.add_child(choose)
	return row


## Constituency support, Reputation, Funds, Party support and XP this
## protagonist actually opens the run with — sanban.json's defaults, with
## any of their own starting_meta/starting_xp overrides (data/player.json)
## layered on. All four protagonists override nothing today, so every row
## reads the same set of numbers; the line exists so the choice stops being
## a guess the moment one of them does.
func _starting_stat_lines(protagonist: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var meta := BattleSetup.starting_meta_for(protagonist)
	for variable: Dictionary in DataDB.sanban:
		var name := str(variable.get("name_en", ""))
		lines.append(Text.say("new_game.stat_line", {"name": name, "value": meta.get(name, 0)}))
	lines.append(Text.say("new_game.stat_line",
		{"name": "XP", "value": BattleSetup.starting_xp_for(protagonist)}))
	return lines


func _on_protagonist_chosen(player_id: String) -> void:
	if _new_game_panel.closed.is_connected(_on_first_run_closed):
		_new_game_panel.closed.disconnect(_on_first_run_closed)
	_new_game_panel.close()
	if not GameState.start_new_run(player_id):
		return
	SaveManager.autosave()
	_build()
	_report.text = Text.say("office.new_game_started",
		{"name": DataDB.player.get("name_en", player_id)})


## Backed out of the first-run choice: play as the default, and save, so the
## next launch does not ask again from nothing.
func _on_first_run_closed() -> void:
	_new_game_panel.closed.disconnect(_on_first_run_closed)
	if GameState.awaiting_new_game:
		GameState.start_new_run(str(DataDB.player.get("player_id", "")))
		SaveManager.autosave()
		_build()


## The Marketplace button beside Office Management, and the one panel it
## opens — the held-items grid and the Supplies shop together (2026-09-28,
## Cameron: Supplies moved out of Office Management into this same screen,
## and the button itself renamed from "Inventory"). Added last so it draws
## over everything else, the same reason every code-built panel here is.
func _build_inventory() -> void:
	_inventory_panel = InventoryPanel.new()
	_inventory_panel.name = "InventoryPanel"
	_inventory_panel.context = Items.OFFICE
	_inventory_panel.on_used = func(_result: Dictionary) -> void:
		_refresh_resources()
		SaveManager.autosave()
	# Using an item from the Marketplace must reopen the WHOLE Marketplace
	# (grid + Supplies), not narrow back to InventoryPanel's own plain grid
	# view — see reopen's own doc comment.
	_inventory_panel.reopen = _show_marketplace
	add_child(_inventory_panel)

	var button := Button.new()
	button.name = "InventoryButton"
	button.text = Text.say("office.marketplace")
	button.custom_minimum_size = _management_button.custom_minimum_size
	button.size_flags_horizontal = _management_button.size_flags_horizontal
	button.pressed.connect(_show_marketplace)
	var parent := _management_button.get_parent()
	parent.add_child(button)
	parent.move_child(button, _management_button.get_index() + 1)


## "Your Record" button, beside Organisations — same code-built pattern as
## Inventory beside Management, no scene-file edit.
func _build_record() -> void:
	_record_panel = Overlay.new()
	_record_panel.name = "RecordPanel"
	add_child(_record_panel)

	var button := Button.new()
	button.name = "RecordButton"
	button.text = Text.say("office.your_record")
	button.custom_minimum_size = _organisations_button.custom_minimum_size
	button.size_flags_horizontal = _organisations_button.size_flags_horizontal
	button.pressed.connect(_show_record)
	var parent := _organisations_button.get_parent()
	parent.add_child(button)
	parent.move_child(button, _organisations_button.get_index() + 1)


## Lifetime stats: which bills the influence swing has flipped, how many
## times each level has been cleared, and clears per tier (derived from the
## level tally at display time rather than kept as a third counter).
func _show_record() -> void:
	var rows: Array[Control] = []

	rows.append(UiKit.heading(Text.say("office.record_sanban_heading")))
	for variable: Dictionary in DataDB.sanban:
		var name := str(variable.get("name_en", ""))
		rows.append(UiKit.line(Text.say("new_game.stat_line",
			{"name": name, "value": GameState.meta.get(name, 0)})))

	rows.append(UiKit.heading(Text.say("office.record_bills_heading")))
	if GameState.bills_flipped_by_influence.is_empty():
		rows.append(UiKit.line(Text.say("office.record_bills_empty")))
	else:
		for bill_id: String in GameState.bills_flipped_by_influence:
			var bill_name := str(DataDB.floor_votes.get(bill_id, {}).get("bill_name", bill_id))
			rows.append(UiKit.line(bill_name))

	rows.append(UiKit.heading(Text.say("office.record_levels_heading")))
	var any_cleared := false
	for level: Dictionary in DataDB.levels:
		var level_id := str(level.get("level_id", ""))
		var count := int(GameState.levels_cleared.get(level_id, 0))
		if count > 0:
			any_cleared = true
			rows.append(UiKit.line(Text.say("office.record_level_line",
				{"level": level.get("description", level_id), "count": count})))
	if not any_cleared:
		rows.append(UiKit.line(Text.say("office.record_levels_empty")))

	rows.append(UiKit.heading(Text.say("office.record_tiers_heading")))
	var tiers: Array = []
	for level: Dictionary in DataDB.levels:
		if not tiers.has(level.get("tier")):
			tiers.append(level.get("tier"))
	tiers.sort()
	for tier: Variant in tiers:
		var total := 0
		for level: Dictionary in DataDB.levels:
			if level.get("tier") == tier:
				total += int(GameState.levels_cleared.get(str(level.get("level_id", "")), 0))
		rows.append(UiKit.line(Text.say("office.record_tier_line", {"tier": int(tier), "count": total})))

	_record_panel.open(Text.say("office.your_record"), rows)


## Cosmetic packages, beside "Your Record" — same code-built pattern, no
## scene-file edit. Inserted after RecordButton so the row reads
## Organisations, Your Record, Cosmetics, left to right.
func _build_cosmetics() -> void:
	_cosmetics_panel = Overlay.new()
	_cosmetics_panel.name = "CosmeticsPanel"
	add_child(_cosmetics_panel)

	var button := Button.new()
	button.name = "CosmeticsButton"
	button.text = Text.say("office.cosmetics")
	button.custom_minimum_size = _organisations_button.custom_minimum_size
	button.size_flags_horizontal = _organisations_button.size_flags_horizontal
	button.pressed.connect(_show_cosmetics)
	var parent := _organisations_button.get_parent()
	var record_button := parent.get_node("RecordButton")
	parent.add_child(button)
	parent.move_child(button, record_button.get_index() + 1)


## Purely decorative — an outfit, an Office background, and music. A
## package (data/cosmetic_packages.json) is the PURCHASE unit; each of its
## three slots (Outfit / Office Background / Music) is equipped
## independently from anything owned, per CosmeticPieces.gd.
func _show_cosmetics() -> void:
	var rows: Array[Control] = []
	rows.append(UiKit.line(Text.say("office.cosmetics_blurb")))

	for package: Dictionary in DataDB.cosmetic_packages:
		if not GameState.owned_cosmetic_packages.has(str(package.get("package_id", ""))):
			rows.append(_cosmetic_package_row(package))

	if not GameState.owned_cosmetic_packages.is_empty():
		rows.append(UiKit.heading(Text.say("office.cosmetics_owned_heading")))
		for slot: String in CosmeticPieces.SLOTS:
			if not _owns_any_piece_for(slot):
				continue
			rows.append(UiKit.line(_cosmetics_slot_label(slot), "SmallLabel"))
			rows.append(_cosmetics_slot_row(slot))

	_cosmetics_panel.open(Text.say("office.cosmetics"), rows)


func _cosmetic_package_row(package: Dictionary) -> Control:
	var package_id := str(package.get("package_id", ""))
	var row := HBoxContainer.new()
	row.name = "Cosmetic_" + package_id
	row.add_theme_constant_override("separation", 16)

	var icon := TextureRect.new()
	icon.texture = ArtLoader.item_icon(CosmeticPieces.field(package, "icon"))
	icon.custom_minimum_size = Vector2(120, 120)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)

	var box := UiKit.tight_column()
	row.add_child(box)

	var name := CosmeticPieces.field(package, "name_en")
	if name.is_empty():
		name = package_id
	var title := UiKit.line(Text.say("shop.item_title", {"name": name, "price": _price_text(package)}))
	title.custom_minimum_size = Vector2(620, 0)
	box.add_child(title)
	var description := UiKit.line(CosmeticPieces.field(package, "description"), "SmallLabel")
	description.custom_minimum_size = Vector2(620, 0)
	box.add_child(description)

	var refusal := CosmeticPieces.buy_refusal(package, GameState.owned_cosmetic_packages,
		GameState.xp, int(GameState.meta.get("Funds", 0)), Text.phrase())
	box.add_child(UiKit.action_button(Text.say("shop.buy"), refusal, _on_buy_cosmetic_package.bind(package_id)))

	return row


func _on_buy_cosmetic_package(package_id: String) -> void:
	var refusal := GameState.buy_cosmetic_package(package_id)
	if refusal.is_empty():
		SaveManager.autosave()
		_refresh_resources()
	_show_cosmetics()


## True when at least one owned package has a piece for this slot — a slot
## with nothing owned for it yet stays off the Equip list entirely.
func _owns_any_piece_for(slot: String) -> bool:
	for package_id: String in GameState.owned_cosmetic_packages:
		if CosmeticPieces.has_piece(DataDB.get_cosmetic_package(package_id), slot):
			return true
	return false


func _cosmetics_slot_label(slot: String) -> String:
	match slot:
		CosmeticPieces.OUTFIT: return Text.say("office.cosmetics_slot_outfit")
		CosmeticPieces.BACKGROUND: return Text.say("office.cosmetics_slot_background")
		CosmeticPieces.MUSIC: return Text.say("office.cosmetics_slot_music")
	return slot


## One row of buttons for a slot: Default, then every owned package with a
## piece for it, in the order they were bought. The active one shows its
## own name with "— Equipped" and is disabled rather than losing its name
## to a generic refusal string (UiKit.action_button's usual "greyed-out
## reason" shape would otherwise replace "Neon Ambition" with "Equipped").
func _cosmetics_slot_row(slot: String) -> Control:
	var row := HBoxContainer.new()
	row.name = "CosmeticSlot_" + slot
	row.add_theme_constant_override("separation", 12)

	var active := str(GameState.active_cosmetics.get(slot, ""))
	row.add_child(_cosmetics_equip_button(
		Text.say("office.cosmetics_default"), active.is_empty(), slot, ""))

	for package_id: String in GameState.owned_cosmetic_packages:
		var package := DataDB.get_cosmetic_package(package_id)
		if not CosmeticPieces.has_piece(package, slot):
			continue
		var name := CosmeticPieces.field(package, "name_en")
		if name.is_empty():
			name = package_id
		row.add_child(_cosmetics_equip_button(name, active == package_id, slot, package_id))

	return row


func _cosmetics_equip_button(label: String, is_active: bool, slot: String, package_id: String) -> Button:
	if is_active:
		var active_button := Button.new()
		active_button.custom_minimum_size = Vector2(0, 90)
		active_button.text = "%s — %s" % [label, Text.say("office.cosmetics_active")]
		active_button.disabled = true
		return active_button
	return UiKit.action_button(label, "", _on_equip_cosmetic.bind(slot, package_id))


func _on_equip_cosmetic(slot: String, package_id: String) -> void:
	GameState.equip_cosmetic(slot, package_id)
	SaveManager.autosave()
	# PlaceholderArt only re-reads its art on its OWN property setters, and
	# nothing else here ever re-sets _background's — without this, equipping
	# a new Office Background left the old picture showing behind the
	# Cosmetics panel until the player left and came back (2026-09-28,
	# caught by a throwaway driver, not by eye: the data path was already
	# correct, only the live node never got told to look again).
	if slot == CosmeticPieces.BACKGROUND:
		_background.art_id = _background.art_id
	_show_cosmetics()


## The Marketplace (2026-09-28, Cameron: Supplies moved out of Office
## Management, folded in here, beside what you already own): the held-items
## grid first (InventoryPanel.inventory_rows(), the same rows show_
## inventory() would open alone), then the Supplies shop below it — each
## row the item's icon, name and price, what it does, and Buy, or, once its
## Purchase Limit for this level is reached, a greyed-out "Out of Stock".
## One screen, one panel (_inventory_panel itself), so tapping a held item
## still drills into its own detail view exactly as it always has.
func _show_marketplace() -> void:
	var rows := _inventory_panel.inventory_rows()
	rows.append(UiKit.heading(Text.say("shop.supplies")))
	rows.append(UiKit.line(Text.say("shop.supplies_blurb")))
	rows.append(UiKit.line(Text.say("office.xp", {"count": GameState.xp}), "HeaderLabel"))
	rows.append(UiKit.line(Text.say("office.funds",
		{"count": int(GameState.meta.get("Funds", 0))}), "HeaderLabel"))
	for item: Dictionary in DataDB.shop:
		# Card sessions live in Rhetoric Training, not here.
		if item.get("card_tier") == null:
			rows.append(_supply_row(item))
	_inventory_panel.open(Text.say("office.marketplace"), rows)


func _supply_row(item: Dictionary) -> Control:
	var item_id := str(item.get("item_id", ""))
	var row := HBoxContainer.new()
	row.name = "Supply_" + item_id
	row.add_theme_constant_override("separation", 16)

	var icon := TextureRect.new()
	icon.texture = ArtLoader.item_icon(InventoryPanel.icon_name(item))
	icon.custom_minimum_size = Vector2(120, 120)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)

	var box := UiKit.tight_column()
	row.add_child(box)

	var title := UiKit.line(Text.say("shop.item_title", {
		"name": item.get("name", item_id), "price": _price_text(item)}))
	title.custom_minimum_size = Vector2(620, 0)
	box.add_child(title)
	var line := UiKit.line(str(item.get("description", "")), "SmallLabel")
	line.custom_minimum_size = Vector2(620, 0)
	box.add_child(line)

	var bought := int(GameState.shop_bought_this_level.get(item_id, 0))
	var refusal := Items.buy_refusal(item, GameState.item_count(item_id), bought,
		GameState.xp, int(GameState.meta.get("Funds", 0)), Text.phrase())
	var button := UiKit.action_button(Text.say("shop.buy"), refusal, _on_buy_item.bind(item_id))
	button.name = "Buy"
	box.add_child(button)

	# Out of Stock greys the whole row, not just its button, so a sold-out
	# item reads as unavailable at a glance.
	if Items.is_out_of_stock(item, bought):
		row.modulate = Color(1, 1, 1, 0.45)
	return row


## "40 XP", "10000 Yen", both joined, or "Free".
func _price_text(item: Dictionary) -> String:
	var price := Items.costs(item)
	var parts: Array[String] = []
	if int(price["XP"]) > 0:
		parts.append(Text.say("shop.item_price_xp", {"count": price["XP"]}))
	if int(price["Funds"]) > 0:
		parts.append(Text.say("shop.item_price_yen", {"count": price["Funds"]}))
	return Text.say("shop.item_free") if parts.is_empty() else " + ".join(parts)


## Three kinds of Supplies item (level_tier/unlocks_recruitment_tier/
## funds_cap_increase, SH13-14/SH18/SH19) take effect the
## moment they are bought instead of going into the inventory to be Used
## later like every other item here — Cameron, 2026-09-26: they never had
## anywhere to apply their effect (Use In Office/Stage both blank), and
## their own Description already says as much ("takes effect immediately").
## Checked off the item's own data, never its ID, the same rule as every
## other branch in this screen.
func _on_buy_item(item_id: String) -> void:
	var item := DataDB.get_shop_item(item_id)
	if item.get("level_tier") != null:
		_report_purchase_result(GameState.buy_random_level(item_id))
		return
	if Items.is_yes(item.get("unlocks_recruitment_tier")):
		_report_purchase_result(GameState.buy_staff_recruitment_tier(item_id))
		return
	if item.get("funds_cap_increase") != null:
		_report_purchase_result(GameState.buy_funds_cap(item_id))
		return

	var refusal := GameState.buy_shop_item(item_id)
	if refusal.is_empty():
		_report.text = Text.say("shop.item_bought",
			{"name": DataDB.get_shop_item(item_id).get("name", item_id)})
	_after_spending(refusal, _show_marketplace)


## Shared by every "takes effect on purchase" branch above: { "ok", "message" }.
func _report_purchase_result(result: Dictionary) -> void:
	var message := str(result.get("message", ""))
	if result.get("ok", false):
		_report.text = message
		_after_spending("", _show_marketplace)
	else:
		_after_spending(message, _show_marketplace)


## A Rhetoric Training offer: the card itself, front then back, with Learn
## it (its price) and Pass — Cameron, 2026-09-25: the same two views a tap on
## a card in a battle shows (CardView for the front, CardBackView for the
## full printed text), stacked vertically here rather than a tap swapping
## one for the other, since the pop-up has nothing else competing for the
## screen. 2026-09-27: shown BEFORE paying rather than after — Pass closes
## it and nothing is spent. Both views read straight off the card's own ID,
## so real art and real text show the moment they exist.
func _show_card_offer() -> void:
	var draw := GameState.card_draw
	var card := DataDB.get_card(str(draw.get("card_id", "")))
	if card.is_empty():
		return

	var front := CardView.new()
	front.show_card(card)
	front.disabled = true   # a preview, not a hand — tapping it does nothing
	var front_frame := CenterContainer.new()
	front_frame.add_child(front)

	# Sized to match the front's own height, so the pair reads as one card
	# shown both sides rather than a small card under a much bigger one —
	# CardBackView otherwise has no size of its own (see BattleScreen's own
	# 1250-tall zoom, which has the whole screen to fill; this popup does not).
	var back := CardBackView.new()
	back.custom_minimum_size = Vector2(CardView.HEIGHT * CardBackView.ASPECT, CardView.HEIGHT)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# No battle room to describe an effect "here" or narrate — just the card
	# as printed, the same as looking at it in the deck screen.
	back.show_card(card, "", "")
	var back_frame := CenterContainer.new()
	back_frame.add_child(back)

	# "2/3": which look of the draw this is (rules.json card_training_looks).
	var counter := UiKit.line(Text.say("rhetoric.counter", {
		"number": int(draw.get("look", 1)), "total": GameState.card_training_looks()}), "HeaderLabel")
	counter.name = "LookCounter"
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var rows: Array[Control] = [counter, front_frame, back_frame]
	# Pass only while it is not the draw's last look. It sits above Learn it,
	# which the panel always places last.
	if GameState.can_pass_offered_card():
		var pass_button := Button.new()
		pass_button.name = "Pass"
		pass_button.text = Text.say("rhetoric.pass")
		pass_button.custom_minimum_size = Vector2(0, 110)
		pass_button.pressed.connect(_on_pass_card)
		rows.append(pass_button)
	_card_reveal_panel.open(Text.say("rhetoric.offer_title"), rows,
		Text.say("rhetoric.learn", {"price": _price_text(
			DataDB.get_shop_item(str(draw.get("item_id", ""))))}))


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

	var refusal := Ledger.deck_refusal(_draft_deck, GameState.owned_cards, DataDB.balance, Text.phrase())
	var warning := ("" if refusal.is_empty()
		else Text.say("office.deck_warning_suffix", {"reason": refusal}))
	rows.append(UiKit.line(Text.say("office.deck_chosen",
		{"count": _draft_deck.size(), "size": size, "warning": warning}), "HeaderLabel"))
	rows.append(UiKit.line(Text.say("office.deck_tap")))

	for card_id: String in GameState.owned_cards:
		var card := DataDB.get_card(card_id)
		if card.is_empty():
			continue
		rows.append(_deck_row(card, card_id))

	# Confirmed rather than saved as you go: a half-built deck should not be
	# able to become the deck you start a level with.
	_deck_panel.open(Text.say("office.your_deck"), rows,
		Text.say("office.deck_confirm") if refusal.is_empty() else "")


func _deck_row(card: Dictionary, card_id: String) -> Control:
	var chosen := _draft_deck.has(card_id)

	var box := UiKit.tight_column()

	# The name goes on the button and the effect underneath it. Both on the
	# button ran a long card off the side of the screen and gave the panel a
	# horizontal scrollbar.
	# The cost goes first, because that is what the choice turns on: a deck
	# of twelve threes cannot be played three energy at a time.
	#
	# The PRINTED cost, not what a battle would charge. There is no battle
	# here, so there is no discount to apply and no engine to ask.
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 80)
	button.text = "%s  %d  %s" % [
		"✓" if chosen else "–", int(card.get("cost", 0)), card.get("name_en", card_id)]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(_on_toggle_card.bind(card_id))
	box.add_child(button)

	var effect := UiKit.line(str(card.get("effect_text", "")), "SmallLabel")
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
	SaveManager.autosave()


## The organisations' backing, bought with Funds.
##
## An organisation will not sell you its backing until you have given it
## reason to — Cameron's decision, and the first thing standing has ever
## done. Pleasing a group at a press conference is what raises it.
func _show_backing() -> void:
	var rows: Array[Control] = []
	rows.append(UiKit.line(Text.say("office.backing_blurb")))
	rows.append(UiKit.line(Text.say("office.funds",
		{"count": int(GameState.meta.get("Funds", 0))}), "HeaderLabel"))

	var names := BattleSetup.booster_names()
	var stage_names := BattleSetup.stage_names()
	var for_sale := DataDB.modifiers.filter(
		func(m: Dictionary) -> bool: return Ledger.is_for_sale(m))

	if for_sale.is_empty():
		rows.append(UiKit.line(Text.say("office.nothing_for_sale")))
	for modifier: Dictionary in for_sale:
		rows.append(_modifier_row(modifier, names, stage_names))

	_backing_panel.open("Backing", rows)


func _modifier_row(modifier: Dictionary, names: Dictionary, stage_names: Dictionary) -> Control:
	var mod_id := str(modifier.get("mod_id", ""))
	var box := UiKit.tight_column()

	# The price line names every currency this modifier charges — most cost
	# only Funds, but 2026-09-22 added separate Reputation and Constituency
	# support costs, and a modifier can ask for any mix of the three.
	box.add_child(UiKit.line("%s  —  %s" % [
		modifier.get("name_en", mod_id), _cost_line(modifier)]))

	var booster := Ledger.backing_booster(modifier, DataDB.boosters)
	if not booster.is_empty():
		var have := int(GameState.booster_standing.get(booster, 0))
		var needed := Ledger.standing_needed(modifier, DataDB.booster_standing)
		var standing := ("%s  ·  standing %d" % [names.get(booster, booster), have]
			if have >= needed
			else "%s  ·  standing %d, needs %d" % [names.get(booster, booster), have, needed])
		box.add_child(UiKit.line(standing, "SmallLabel"))

	# What it does, in the workbook's own words (or, for the one case with a
	# Text tab line of its own, that line with the real number in it).
	box.add_child(UiKit.line(
		ModifierEffects.describe(modifier, Text.phrase(), stage_names), "SmallLabel"))

	# An effect nothing implements yet is said out loud. A shop that sells
	# something inert is the trap this project has walked into twice.
	if not ModifierEffects.is_implemented(modifier):
		box.add_child(UiKit.line(Text.say("office.not_active_yet"), "SmallLabel"))

	var refusal := Ledger.modifier_refusal(modifier, GameState.owned_modifiers,
		GameState.meta, GameState.booster_standing,
		DataDB.booster_standing, DataDB.boosters, Text.phrase())
	box.add_child(UiKit.action_button(Text.say("office.take_backing"), refusal,
		_on_buy_modifier.bind(mod_id)))
	return box


## "10 Funds" or, where a modifier charges more than one currency,
## "10 Funds, 5 Reputation". The three currency names are sanban.json's own
## names, the same ones the rest of the screen already shows.
func _cost_line(modifier: Dictionary) -> String:
	var parts: Array[String] = []
	var costs := Ledger.modifier_costs(modifier)
	for name: String in costs.keys():
		var cost: int = costs[name]
		if cost > 0:
			parts.append("%d %s" % [cost, name])
	return ", ".join(parts) if not parts.is_empty() else "free"


func _on_buy_modifier(mod_id: String) -> void:
	_after_spending(GameState.buy_modifier(mod_id), _show_backing)


## The Recruitment shop: one hired staff member per role, paid from Funds.
##
## Three roles, always shown in the same order (Ledger.STAFF_ROLES). A vacant
## role lists its seven candidates as hire choices — greyed out, with no Hire
## button, for anyone fired earlier this run (GameState.staff_fired); a
## filled role shows who is there, the upgrade to their next tier where one
## exists, and a Fire button that asks first (it costs a severance and can't
## be undone — see GameState.hire_staff()/upgrade_staff()/fire_staff() and
## design/proposals/staff_firing.md).
func _show_staff() -> void:
	var rows: Array[Control] = []
	rows.append(UiKit.line(Text.say("office.staff_blurb")))
	rows.append(UiKit.line(Text.say("office.funds",
		{"count": int(GameState.meta.get("Funds", 0))}), "HeaderLabel"))

	for role: String in Ledger.STAFF_ROLES:
		rows.append(UiKit.heading(role))
		var hired: Dictionary = GameState.staff_hired.get(role, {})
		if hired.is_empty():
			for candidate: Dictionary in DataDB.get_staff_by_role(role):
				rows.append(_staff_candidate_row(candidate))
		else:
			rows.append(_staff_hired_row(role, hired))

	_staff_panel.open(Text.say("office.staff"), rows)


## One candidate for a vacant role, with a Hire button — or, for someone
## fired earlier this run, their name greyed out with no button at all.
func _staff_candidate_row(candidate: Dictionary) -> Control:
	var staff_id := str(candidate.get("staff_id", ""))
	var fired := bool(GameState.staff_fired.get(staff_id, false))
	var box := UiKit.tight_column()

	box.add_child(UiKit.line(Text.say("office.staff_candidate", {
		"name": candidate.get("name", staff_id),
		"cost": int(candidate.get("hiring_cost_yen", 0)),
	})))

	if fired:
		box.add_child(UiKit.line(Text.say("office.staff_fired"), "SmallLabel"))
		box.modulate = Color(1, 1, 1, 0.5)
	else:
		var funds := int(GameState.meta.get("Funds", 0))
		var refusal := Ledger.staff_hire_refusal(candidate,
			GameState.staff_hired.get(str(candidate.get("role", "")), {}), false, funds,
			GameState.staff_recruitment_tier, Text.phrase())
		box.add_child(UiKit.action_button(Text.say("office.hire"), refusal, _on_hire_staff.bind(staff_id)))
	return box


## The one candidate hired into a role: an Upgrade button where a next tier
## exists, and a Fire button that opens the severance warning.
func _staff_hired_row(role: String, hired: Dictionary) -> Control:
	var candidate := DataDB.get_staff(str(hired.get("staff_id", "")))
	var tier := int(hired.get("tier", 0))
	var box := UiKit.tight_column()

	box.add_child(UiKit.line(Text.say("office.staff_hired", {
		"name": candidate.get("name", hired.get("staff_id", "")),
		"tier": tier,
		"highest": int(candidate.get("highest_tier", 0)),
	})))

	var funds := int(GameState.meta.get("Funds", 0))
	var refusal := Ledger.staff_upgrade_refusal(candidate, tier, funds, Text.phrase())
	var cost: Variant = Ledger.staff_upgrade_cost(candidate, tier)
	if cost == null:
		box.add_child(UiKit.action_button("", Text.say("office.staff_at_max"), Callable()))
	else:
		box.add_child(UiKit.action_button(Text.say("office.upgrade", {"cost": int(cost)}),
			refusal, _on_upgrade_staff.bind(role)))

	var fire_refusal := Ledger.staff_fire_refusal(candidate, funds, Text.phrase())
	box.add_child(UiKit.action_button(Text.say("office.fire_staff"), fire_refusal,
		_confirm_fire_staff.bind(role, candidate)))
	return box


func _on_hire_staff(staff_id: String) -> void:
	_after_spending(GameState.hire_staff(staff_id), _show_staff)


func _on_upgrade_staff(role: String) -> void:
	_after_spending(GameState.upgrade_staff(role), _show_staff)


## Firing is permanent and costs a severance, so it asks first — same
## confirm-overlay pattern as _confirm_new_game().
func _confirm_fire_staff(role: String, candidate: Dictionary) -> void:
	_firing_role = role
	_fire_staff_panel.open(Text.say("office.fire_staff"),
		[UiKit.line(Text.say("office.fire_staff_warning", {
			"name": candidate.get("name", candidate.get("staff_id", "")),
			"cost": Ledger.staff_firing_cost(candidate),
		}))],
		Text.say("office.fire_staff_confirm"))


func _on_fire_staff_confirmed() -> void:
	_after_spending(GameState.fire_staff(_firing_role), _show_staff)


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
## Which level to play. 30 of them now (LV01-30), grouped by tier.
##
## 2026-09-22 workbook: a level row (data/levels.json) is flat — a
## description and stage_1..stage_10, no embedded name_jp/opponents/blurb the
## way the old hand-written draft had. BattleSetup.expand_level() is what
## turns a chosen row into the ordered, opponent-filled stage list the
## briefing and the battle actually need; the list here works off the raw
## rows, which is all choosing one needs.
##
## Unlock cost and cooldown (levels.json's own unlock_cost_vacant/_tier_0/_1/_2
## and cooldown columns) are gated behind rules.json's "level_gating_enabled",
## default false — so every level stays open today, the same way
## rules.json's "open_card_collection" currently leaves every card open.
## Flip it true and a locked or on-cooldown level shows why, with an Unlock
## button where it can be bought (see _level_row(), Ledger.gd's "Levels"
## section, and GameState.levels_unlocked/levels_completed_count).
func _show_levels() -> void:
	var rows: Array[Control] = []
	rows.append(UiKit.line("Each level is a run of stages. Pick one and "
		+ "you will see what it holds before you commit."))

	var by_tier := {}
	for level: Dictionary in DataDB.levels:
		# A "One-Time (Yes/No)" level (levels.json's own "one_time" column)
		# that has already been completed — win or loss — is left out of the
		# list entirely, not shown-but-disabled like a locked or cooling-
		# down one: Cameron's own request was that it disappear outright.
		# Independent of "level_gating_enabled" below, which only gates
		# cost/cooldown, not this.
		if Ledger.level_is_hidden(level, GameState.level_last_completed_at):
			continue
		var tier := int(level.get("tier", 0))
		if not by_tier.has(tier):
			by_tier[tier] = []
		by_tier[tier].append(level)

	var tiers: Array = by_tier.keys()
	tiers.sort()
	for tier: int in tiers:
		rows.append(UiKit.heading("Tier %d" % tier))
		for level: Dictionary in by_tier[tier]:
			rows.append(_level_row(level))

	_levels_panel.open("Levels", rows)


func _level_row(level: Dictionary) -> Control:
	var box := UiKit.tight_column()

	# Neither the level ID nor a stage count is shown — Cameron, 2026-09-26:
	# the count in particular read as wrong for almost every level (it named
	# 10 no matter how many stages a level actually had) because levels.json
	# writes an unused stage_N slot as an explicit JSON null rather than
	# leaving the key out, and str(null) is the literal text "<null>", never
	# empty — the count was silently always 10. Simplest fix and the one
	# asked for: just the name, which is what a player actually reads.
	box.add_child(UiKit.line(str(level.get("description", ""))))

	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 90)

	# A locked or cooling-down level is SHOWN, not hidden — the same choice
	# the card and Staff shops make: a player should see what is coming, not
	# have it quietly vanish. Nothing below runs while rules.json's
	# "level_gating_enabled" is off, which is today's default, so a plain
	# "Look it over" is what every existing playtest still sees.
	if DataDB.get_rule("level_gating_enabled", false):
		var level_id := str(level.get("level_id", ""))
		var cooldown := Ledger.level_cooldown_remaining(
			level, GameState.levels_completed_count, GameState.level_last_completed_at)

		if cooldown > 0:
			button.text = Text.say("office.level_cooldown", {"count": cooldown})
			button.disabled = true
		elif not Ledger.is_level_unlocked(level, GameState.levels_unlocked, GameState.staff_hired):
			var cost := Ledger.level_unlock_cost(level, GameState.staff_hired)
			var refusal := Ledger.level_unlock_refusal(
				level, GameState.levels_unlocked, GameState.staff_hired, GameState.xp, Text.phrase())
			if refusal.is_empty():
				button.text = Text.say("office.level_unlock_cost", {"cost": cost})
				button.pressed.connect(_on_unlock_level.bind(level_id))
			else:
				button.text = refusal
				button.disabled = true
			box.add_child(button)
			return box

	button.text = Text.say("office.look_it_over")
	button.pressed.connect(_on_level_chosen.bind(level))
	box.add_child(button)
	return box


## Spends XP to unlock a level, then rebuilds the panel so the price and what
## is left are current — the same shape as every other purchase here.
func _on_unlock_level(level_id: String) -> void:
	_after_spending(GameState.unlock_level(level_id), _show_levels)


func _on_level_chosen(level: Dictionary) -> void:
	_chosen_level = level
	_levels_panel.close()
	_show_briefing()


func _show_briefing() -> void:
	if _chosen_level.is_empty():
		_show_levels()
		return

	var expanded := BattleSetup.expand_level(_chosen_level)
	var runner := LevelRunner.new(expanded)
	if not runner.is_valid():
		_report.text = "This level cannot start:\n• %s" % "\n• ".join(Array(runner.problems()))
		return

	var rows: Array[Control] = []
	var stages: Array = expanded.get("stages", [])
	var anything_set := false

	for stage: Dictionary in stages:
		if not _reveal_in_briefing(stage):
			# A stage marked "No" (Media Ambush, an ambush by name) is left
			# out of the briefing entirely — 2026-09-28, Cameron: no heading,
			# no rewards, no "if you lose" line, nothing that gives away it
			# is even there. An earlier pass still showed its win/loss
			# numbers so the player could weigh the risk; this replaces that
			# with a real, total surprise instead.
			continue

		rows.append(UiKit.heading(str(stage.get("name_en", "A stage"))))
		var who := _opponents_line(stage)
		if not who.is_empty():
			rows.append(UiKit.line(who, "SmallLabel"))

		if LevelRunner.rewards_are_unset(stage):
			rows.append(UiKit.line(
				"What winning this is worth has not been set yet.", "SmallLabel"))
		else:
			anything_set = true
			for name: String in LevelRunner.win_rewards(stage).keys():
				rows.append(UiKit.line(Text.say("reward.delta", {
					"name": name,
					"amount": "%+d" % int(LevelRunner.win_rewards(stage)[name]),
				})))
			var xp := MetaRules.stage_delta(stage, "win_delta_xp")
			if xp > 0:
				rows.append(UiKit.line(Text.say("outcome.xp", {"count": xp})))
			for line: String in LevelRunner.variable_rewards(stage, Text.phrase()):
				rows.append(UiKit.line(line, "SmallLabel"))

		# What losing it costs, from the stage's own loss_delta_* columns, so
		# the player knows what they are risking before they go in.
		var if_lost := _loss_line(stage)
		if not if_lost.is_empty():
			rows.append(UiKit.line(if_lost, "SmallLabel"))

	if not anything_set:
		rows.append(UiKit.line(""))
		rows.append(UiKit.line(Text.say("reward.nothing_set")))

	_briefing_panel.open(str(_chosen_level.get("level_id", "Before you go in")),
		rows, "Go in")


## "If you lose: Party support -2, Reputation -1, 1 XP" — or "" for a stage
## whose loss columns are all blank.
func _loss_line(stage: Dictionary) -> String:
	var parts: Array[String] = []
	var penalties := LevelRunner.loss_penalties(stage)
	for name: String in penalties.keys():
		parts.append(Text.say("reward.delta", {"name": name, "amount": "%+d" % int(penalties[name])}))
	var xp := MetaRules.stage_delta(stage, "loss_delta_xp")
	if xp > 0:
		parts.append(Text.say("outcome.xp", {"count": xp}))
	if parts.is_empty():
		return ""
	return Text.say("reward.if_lost", {"changes": ", ".join(parts)})


## True unless the Stages tab's "Reveal In Briefing" column is explicitly
## "No" for this stage. Blank (null, the shape every stage has today except
## the one that has been set) keeps the old behaviour: every stage says what
## it is before the player goes in.
func _reveal_in_briefing(stage: Dictionary) -> bool:
	var value: Variant = stage.get("reveal_in_briefing")
	if value == null:
		return true
	return str(value).strip_edges().to_lower() != "no"


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


## Start: choose a level — or, when a saved run stopped between the stages
## of one, go straight back into it.
func _on_start_pressed() -> void:
	if GameState.is_in_level():
		get_tree().change_scene_to_file(StageRouting.scene_for(GameState.level_runner.current_stage()))
		return
	_show_levels()


func _on_start() -> void:
	var expanded := BattleSetup.expand_level(_chosen_level)
	var runner := LevelRunner.new(expanded)
	if not runner.is_valid():
		_report.text = "This level cannot start:\n• %s" % "\n• ".join(Array(runner.problems()))
		return

	# The runner is handed over rather than rebuilt, so the level keeps its
	# place and its carried buffs as the battle screen moves through it.
	GameState.begin_level(runner)

	# A hired staff member with a written line for this level gets one beat
	# to say it before the level begins (2026-09-27) — skipped entirely when
	# nobody has anything to say, so a level with no intro content plays
	# exactly as it always has.
	var cues := LevelIntroCues.resolve(DataDB.level_intros, runner.level.get("level_id", ""),
		GameState.staff_hired, DataDB.staff)
	if cues.is_empty():
		get_tree().change_scene_to_file(StageRouting.scene_for(runner.current_stage()))
	else:
		get_tree().change_scene_to_file(StageRouting.LEVEL_INTRO_SCENE)
