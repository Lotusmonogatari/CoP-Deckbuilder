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

## The inventory and the Supplies shop (design/proposals/inventory.md).
## Built in code rather than placed in the scene, the same way the battle
## screen builds its card zoom: they are this script's to own.
var _inventory_panel: InventoryPanel
var _supplies_panel: Overlay

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


func _build() -> void:
	var level := DataDB.playtest_level

	# Whose office it is. A placeholder name until the protagonist is cast,
	# but a named desk reads better than an anonymous one.
	var player := DataDB.player
	var name_en := str(player.get("name_en", ""))
	var party := str(player.get("party", ""))

	if name_en.is_empty():
		_title.text = Text.say("office.title")
	elif party.is_empty():
		_title.text = "%s's Office" % name_en
	else:
		_title.text = "%s · %s" % [name_en, party]
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
		[Text.say("office.new_cards"), _show_cards],
		[Text.say("office.your_deck"), _show_deck],
		[Text.say("office.backing"), _show_backing],
		[Text.say("office.staff"), _show_staff],
		[Text.say("shop.supplies"), _show_supplies],
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
	# list is shown by name instead.
	var linked: Array = booster.get("linked_modifiers", [])
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

## New cards, bought with XP.
##
## Cards are listed by tier with the cheapest first, and the ones already
## yours are shown too: a shop that hides what you own makes it hard to
## remember why you cannot buy something.
func _show_cards() -> void:
	var rows: Array[Control] = []
	rows.append(UiKit.line(Text.say("office.cards_blurb")))
	rows.append(UiKit.line(Text.say("office.xp", {"count": GameState.xp}), "HeaderLabel"))

	# cards.json's real "tier" values are the string digits "0"/"1"/"2"/"3"
	# since the 2026-09-21 tier rename (Ledger.OPENING_TIER == "0"), not the
	# literal words "Tier 1"/"Tier 2" this used to compare against — that
	# comparison never matched anything, so the shop always listed zero cards.
	# Tiers are read off the real cards rather than hardcoded, so a new tier
	# added to the workbook shows up here without a code change.
	var tiers: Array[String] = []
	for card: Dictionary in DataDB.cards:
		var tier := str(card.get("tier", ""))
		if tier != Ledger.OPENING_TIER and not tiers.has(tier):
			tiers.append(tier)
	tiers.sort()

	for tier: String in tiers:
		var in_tier := DataDB.get_cards_by_tier(tier)
		if in_tier.is_empty():
			continue
		rows.append(UiKit.heading("Tier %s" % tier))
		for card: Dictionary in in_tier:
			rows.append(_card_row(card))

	var owned_extra := GameState.owned_cards.size() - DataDB.get_cards_by_tier(Ledger.OPENING_TIER).size()
	if owned_extra > 0:
		rows.append(UiKit.line(""))
		rows.append(UiKit.line(Text.say("office.cards_unlocked",
			{"count": owned_extra}), "SmallLabel"))

	_cards_panel.open(Text.say("office.new_cards"), rows)


func _card_row(card: Dictionary) -> Control:
	var card_id := str(card.get("card_id", ""))
	var box := UiKit.tight_column()

	box.add_child(UiKit.line(Text.say("office.card_title", {
		"name": card.get("name_en", card_id),
		"name_jp": card.get("name_jp", ""),
		"cost": Ledger.card_cost(card)})))
	box.add_child(UiKit.line(Text.say("office.card_line", {
		"suit": card.get("suit", ""),
		"effect": card.get("effect_text", "")}), "SmallLabel"))

	var refusal := Ledger.card_refusal(card, GameState.owned_cards, GameState.xp, Text.phrase())
	box.add_child(UiKit.action_button(Text.say("office.unlock"), refusal, _on_buy_card.bind(card_id)))
	return box


func _on_buy_card(card_id: String) -> void:
	_after_spending(GameState.buy_card(card_id), _show_cards)


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
	var party := str(protagonist.get("party", ""))
	box.add_child(UiKit.line(party if not party.is_empty() else Text.say("new_game.no_party"), "SmallLabel"))
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


## The Inventory button beside Office Management, and the two panels it and
## the Supplies shop open. Added last so they draw over everything else.
func _build_inventory() -> void:
	_inventory_panel = InventoryPanel.new()
	_inventory_panel.name = "InventoryPanel"
	_inventory_panel.context = Items.OFFICE
	_inventory_panel.on_used = func(_result: Dictionary) -> void:
		_refresh_resources()
		SaveManager.autosave()
	add_child(_inventory_panel)

	_supplies_panel = Overlay.new()
	_supplies_panel.name = "SuppliesPanel"
	add_child(_supplies_panel)

	var button := Button.new()
	button.name = "InventoryButton"
	button.text = Text.say("inventory.button")
	button.custom_minimum_size = _management_button.custom_minimum_size
	button.size_flags_horizontal = _management_button.size_flags_horizontal
	button.pressed.connect(_inventory_panel.show_inventory)
	var parent := _management_button.get_parent()
	parent.add_child(button)
	parent.move_child(button, _management_button.get_index() + 1)


## Supplies: the Shop tab's items, bought into the inventory. Each row is the
## item's icon, name and price, what it does, and Buy — or, once its Purchase
## Limit for this level is reached, a greyed-out "Out of Stock".
func _show_supplies() -> void:
	var rows: Array[Control] = []
	rows.append(UiKit.line(Text.say("shop.supplies_blurb")))
	rows.append(UiKit.line(Text.say("office.xp", {"count": GameState.xp}), "HeaderLabel"))
	rows.append(UiKit.line(Text.say("office.funds",
		{"count": int(GameState.meta.get("Funds", 0))}), "HeaderLabel"))
	for item: Dictionary in DataDB.shop:
		rows.append(_supply_row(item))
	_supplies_panel.open(Text.say("shop.supplies"), rows)


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


func _on_buy_item(item_id: String) -> void:
	var item := DataDB.get_shop_item(item_id)
	# "Purchase Random Tier N Card" (card_tier set) takes effect on
	# purchase — a random unowned card of that tier, no inventory step —
	# rather than being held and Used like every other Supplies item.
	if item.get("card_tier") != null:
		var result := GameState.buy_random_card(item_id)
		var message := str(result.get("message", ""))
		if result.get("ok", false):
			_report.text = message
			_after_spending("", _show_supplies)
		else:
			_after_spending(message, _show_supplies)
		return

	var refusal := GameState.buy_shop_item(item_id)
	if refusal.is_empty():
		_report.text = Text.say("shop.item_bought",
			{"name": DataDB.get_shop_item(item_id).get("name", item_id)})
	_after_spending(refusal, _show_supplies)


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
			GameState.staff_hired.get(str(candidate.get("role", "")), {}), false, funds, Text.phrase())
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
## is left are current — the same shape as _on_buy_card().
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
		if _reveal_in_briefing(stage):
			rows.append(UiKit.heading(str(stage.get("name_en", "A stage"))))
			var who := _opponents_line(stage)
			if not who.is_empty():
				rows.append(UiKit.line(who, "SmallLabel"))
		else:
			# A stage marked "No" (Media Ambush, an ambush by name) does not
			# get to say what it is or who is waiting — that is the surprise.
			# Its rewards still show below, same as any other stage, so the
			# player can weigh what they are risking without being told what
			# is coming for it.
			rows.append(UiKit.heading(Text.say("office.briefing.surprise_stage")))

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
			var xp := int(stage.get("win_delta_xp", 0))
			if xp > 0:
				rows.append(UiKit.line(Text.say("outcome.xp", {"count": xp})))
			for line: String in LevelRunner.variable_rewards(stage, Text.phrase()):
				rows.append(UiKit.line(line, "SmallLabel"))

	if not anything_set:
		rows.append(UiKit.line(""))
		rows.append(UiKit.line(Text.say("reward.nothing_set")))

	# Losing is the same everywhere for now, and saying so is worth a line:
	# the player should know what they are risking, which is the afternoon.
	rows.append(UiKit.line(""))
	rows.append(UiKit.line("Lose a stage and you earn nothing from it. "
		+ "Nothing else is taken off you.", "SmallLabel"))

	_briefing_panel.open(str(_chosen_level.get("level_id", "Before you go in")),
		rows, "Go in")


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
	get_tree().change_scene_to_file(StageRouting.scene_for(runner.current_stage()))
