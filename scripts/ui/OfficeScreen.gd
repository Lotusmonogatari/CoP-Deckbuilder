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
@onready var _reputation_button: Button = %ReputationButton
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
var _law_panel: Overlay
var _parties_panel: Overlay
var _party_detail_panel: Overlay

## Cosmetic packages (2026-09-28): purely decorative outfit/background/music
## bundles, bought here and equipped per slot. Built in code, the same
## reason _record_panel is.
var _cosmetics_panel: Overlay

## The How to Play guide (HowToPlayPanel.gd), opened from the row of buttons.
var _how_to_play_panel: Overlay

## The two intermediary menus (_build_menus()).
var _reputation_menu: Overlay
var _administration_menu: Overlay

## Rhetoric Training's card offer (SH09-11, the XP-cost card unlock tiers)
## — Cameron, 2026-09-25: showing the card itself, not just naming it in a
## sentence, is what makes drawing a random one feel like a pull rather
## than a database write; and 2026-09-27, it is shown BEFORE paying, with
## Learn it / Pass. Built in code, the same reason _inventory_panel is.
var _card_reveal_panel: Overlay

## The forced choice when the app is reopened with a level still in
## progress — Resume the Level or Abandon the Level (Cameron, 2026-10-04).
## Built in code, the same way _trigger_alert_panel is.
var _resume_choice_panel: Overlay
var _special_forced_panel: Overlay
## A patron bill's Request panel (Accept, Amend, Decline) and the Amend swap
## being previewed ("" when none).
var _request_panel: Overlay
var _draft_panel: Overlay

## The week calendar (2026-10-23): the gold square, the Friday / weekend button,
## and the three panels that carry the week's decisions.
var _calendar_square: PanelContainer
var _week_button: Button
var _dues_label: Label
var _election_panel: Overlay
var _events_button: Button
var _events_panel: Overlay
var _event_panel: Overlay
var _gathering_panel: Overlay
var _hosted_panel: HostedEventPanel
var _week_confirm_panel: Overlay
var _week_over_panel: Overlay
var _new_week_panel: Overlay
var _draft_ids: Array = []
var _draft_org := ""
var _request_replace := ""
var _request_with := ""

## New Game: the warning before a run is thrown away, and the choice of
## protagonist. Built in code, like the inventory.
var _new_game_panel: Overlay
var _backup_action := ""

## The warning before firing a hired Staff member — built in code, the same
## way, since firing is permanent and costs a severance (Ledger.
## staff_firing_cost()) — see design/proposals/staff_firing.md.
var _fire_staff_panel: Overlay

## One candidate's tier-by-tier profile, opened from the Staff list. Built in
## code like _fire_staff_panel (no .tscn edit, §13).
var _staff_profile_panel: Overlay

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
	_reputation_button.pressed.connect(_show_reputation_menu)
	_management_button.pressed.connect(_show_management)
	_build_inventory()
	_build_menus()
	_build_record()
	_build_cosmetics()
	_build_how_to_play()
	_new_game_panel = Overlay.new()
	_new_game_panel.name = "NewGamePanel"
	add_child(_new_game_panel)
	# Built before the fire confirmation so that one draws on top of it.
	_staff_profile_panel = Overlay.new()
	_staff_profile_panel.name = "StaffProfilePanel"
	add_child(_staff_profile_panel)
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
	_resume_choice_panel = Overlay.new()
	_resume_choice_panel.name = "ResumeChoicePanel"
	# Resume or Abandon are the only ways on — a real decision, not chrome
	# to wave away (Cameron, 2026-10-04): tapping outside it, or Back, must
	# never silently pick either one for the player.
	_resume_choice_panel.dismissable = false
	_resume_choice_panel.show_back = false
	add_child(_resume_choice_panel)
	_special_forced_panel = Overlay.new()
	_special_forced_panel.name = "SpecialForcedPanel"
	# The only way on is the button: a level that has come due cannot be waved away.
	_special_forced_panel.dismissable = false
	_special_forced_panel.show_back = false
	add_child(_special_forced_panel)
	_request_panel = Overlay.new()
	_request_panel.name = "RequestPanel"
	add_child(_request_panel)
	_draft_panel = Overlay.new()
	_draft_panel.name = "DraftPanel"
	add_child(_draft_panel)
	_build_week_controls()

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
	# Whose office it is. A placeholder name until the protagonist is cast,
	# but a named desk reads better than an anonymous one.
	var player := DataDB.player
	var name_en := str(player.get("name_en", ""))
	var party := PartyDisplay.party_name(player)

	if name_en.is_empty():
		_title.text = Text.say("office.title")
		_title_party.hide()
	elif party.is_empty():
		_title.text = Text.say("office.title_named", {"name": name_en})
		_title_party.hide()
	else:
		_title.text = name_en
		_title_party.text = "· %s" % party
		_title_party.add_theme_color_override("font_color", PartyDisplay.color_for(DataDB.get_party(party)))
		_title_party.show()
	_subtitle.text = Text.say("office.subtitle_jp")

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
	_refresh_calendar()
	_show_trigger_alerts_if_any()
	_show_resume_choice_if_in_level()
	_show_random_event_if_due()
	_show_week_over_if_due()
	_show_forced_special_if_due()


# ---------------------------------------------------------------------------
# The week (2026-10-23, Cameron): a gold calendar square in the unused lower
# space, a button on Friday to end the work week early, a weekend that is
# optional, and "Pay Party Dues and Go Home" to end the week.

func _build_week_controls() -> void:
	var spacer := get_node_or_null("Safe/Column/VSpacer")
	if spacer != null:
		_calendar_square = CalendarSquare.make()
		spacer.add_child(_calendar_square)

	_dues_label = Label.new()
	_dues_label.name = "DuesLabel"
	_dues_label.theme_type_variation = &"SmallLabel"
	_dues_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_start_button.get_parent().add_child(_dues_label)
	_start_button.get_parent().move_child(_dues_label, _start_button.get_index() + 1)

	_week_button = Button.new()
	_week_button.name = "WeekButton"
	_week_button.custom_minimum_size = Vector2(0, 100)
	_week_button.pressed.connect(_on_week_button_pressed)
	_start_button.get_parent().add_child(_week_button)
	_start_button.get_parent().move_child(_week_button, _dues_label.get_index() + 1)

	_events_button = Button.new()
	_events_button.name = "EventsButton"
	_events_button.custom_minimum_size = Vector2(0, 100)
	_events_button.text = Text.say("event.menu_button")
	_events_button.pressed.connect(_show_events_list)
	_start_button.get_parent().add_child(_events_button)
	_start_button.get_parent().move_child(_events_button, _start_button.get_index() + 1)

	_events_panel = Overlay.new()
	_events_panel.name = "EventsPanel"
	add_child(_events_panel)
	_hosted_panel = HostedEventPanel.new()
	_hosted_panel.name = "HostedEventPanel"
	add_child(_hosted_panel)
	_hosted_panel.closed.connect(_on_hosted_closed)
	_gathering_panel = Overlay.new()
	_gathering_panel.name = "GatheringPanel"
	_gathering_panel.show_back = false
	add_child(_gathering_panel)
	_event_panel = Overlay.new()
	_event_panel.name = "EventPanel"
	# Once an event is on screen the only way on is a choice.
	_event_panel.dismissable = false
	_event_panel.show_back = false
	add_child(_event_panel)

	_week_confirm_panel = Overlay.new()
	_week_confirm_panel.name = "WeekConfirmPanel"
	add_child(_week_confirm_panel)
	_week_confirm_panel.confirmed.connect(_on_end_work_week_confirmed)
	_week_over_panel = Overlay.new()
	_week_over_panel.name = "WeekOverPanel"
	# The work week has no hours left: weekend or home are the only ways on.
	_week_over_panel.dismissable = false
	_week_over_panel.show_back = false
	add_child(_week_over_panel)
	_new_week_panel = Overlay.new()
	_new_week_panel.name = "NewWeekPanel"
	_new_week_panel.dismissable = false
	_new_week_panel.show_back = false
	add_child(_new_week_panel)


## The square's two rows, and the one week button that fits today: "End the
## Work Week" on a Friday with hours left, "Pay Party Dues and Go Home" in
## the weekend, nothing otherwise (and nothing mid-level).
func _refresh_calendar() -> void:
	CalendarSquare.refresh(_calendar_square)
	if _week_button == null:
		return
	var mid_level := GameState.is_in_level()
	if GameState.in_weekend():
		_week_button.text = Text.say("office.go_home")
		_week_button.visible = not mid_level
	elif GameState.can_end_work_week_early():
		_week_button.text = Text.say("office.end_work_week")
		_week_button.visible = not mid_level
	else:
		_week_button.visible = false
	_dues_label.visible = _week_button.visible or (GameState.work_week_is_full() and not mid_level)
	if _dues_label.visible:
		var due := GameState.dues_preview()
		_dues_label.text = Text.say("dues.preview_owed" if int(due["owed"]) > 0 else "dues.preview", {
			"yen_total": int(due["total"]), "yen_owed": int(due["owed"]), "yen_funds": int(due["funds"])})


func _on_week_button_pressed() -> void:
	if GameState.in_weekend():
		_go_home()
		return
	var rows: Array[Control] = [UiKit.line(Text.say("office.end_work_week_body",
		{"hours": GameState.work_hours_left()}))]
	_week_confirm_panel.open(Text.say("office.end_work_week_title"), rows,
		Text.say("office.end_work_week_yes"))


func _on_end_work_week_confirmed() -> void:
	GameState.end_work_week()
	SaveManager.autosave()
	_build()


## The work week ran out of hours: the player chooses the weekend or home.
func _show_week_over_if_due() -> void:
	if GameState.is_in_level() or not GameState.work_week_is_full():
		return
	var rows: Array[Control] = [UiKit.line(Text.say("office.week_over_body"))]
	var weekend := Button.new()
	weekend.name = "WorkWeekendButton"
	weekend.custom_minimum_size = Vector2(0, 110)
	weekend.text = Text.say("office.weekend_work")
	weekend.pressed.connect(_on_work_weekend)
	rows.append(weekend)
	var home := Button.new()
	home.name = "GoHomeButton"
	home.custom_minimum_size = Vector2(0, 110)
	home.text = Text.say("office.go_home")
	home.pressed.connect(_go_home)
	rows.append(home)
	_week_over_panel.open(Text.say("office.week_over_title"), rows)


func _on_work_weekend() -> void:
	_week_over_panel.close()
	GameState.end_work_week()
	SaveManager.autosave()
	_build()


## Ends the week: a cue popup on this same screen says a new week begins.
func _go_home() -> void:
	_week_over_panel.close()
	_week_confirm_panel.close()
	var result := GameState.go_home()
	SaveManager.autosave()
	_build()
	var rows: Array[Control] = [UiKit.line(Text.say("office.new_week_body",
		{"date": str(result.get("date", ""))}))]
	rows.append_array(_dues_report_rows(result.get("dues", {})))
	for awareness_line: String in result.get("awareness", []):
		rows.append(UiKit.line(awareness_line, "SmallLabel"))
	_new_week_panel.open(Text.say("office.new_week_title"), rows, Text.say("office.new_week_go"))


# ---------------------------------------------------------------------------
# Events (2026-10-23, Cameron): arranged from the Events list, or arriving on
# their own after a level or a week end. Flavor text, a few fixed choices,
# variable rewards (GameState.apply_event_choice).

func _show_events_list() -> void:
	var rows: Array[Control] = [UiKit.line(Text.say("event.list_hint"), "SmallLabel")]
	var events := GameState.buyable_events()
	if events.is_empty():
		rows.append(UiKit.line(Text.say("event.none")))
	for event: Dictionary in events:
		var cost: Variant = event.get("cost_funds")
		var title_line := Text.say("event.row", {"title": str(event.get("title", "")),
			"hours": EventEngine.hours_of(event), "cost": int(cost)}) if cost != null and int(cost) > 0 \
			else Text.say("event.row_free", {"title": str(event.get("title", "")),
				"hours": EventEngine.hours_of(event)})
		var box := UiKit.tight_column()
		box.add_child(UiKit.line(title_line))
		var button := UiKit.action_button(Text.say("event.arrange"), GameState.event_refusal(event),
			_on_arrange_event.bind(str(event.get("event_id", ""))), 90.0)
		button.name = "Arrange_" + str(event.get("event_id", ""))
		box.add_child(button)
		rows.append(box)
	_events_panel.open(Text.say("event.list_title"), rows)


func _on_arrange_event(event_id: String) -> void:
	if not GameState.start_event(event_id):
		_show_events_list()
		return
	_events_panel.close()
	SaveManager.autosave()
	_build()
	_present_event(event_id, false)


## The evening is over: refresh what it changed.
func _on_hosted_closed() -> void:
	_refresh_resources()
	SaveManager.autosave()
	_build()


## The picture behind a gathering you hosted, with what came of it (2026-10-23):
## DINING or TOUR, or the purchased alternative (CP03, CP04).
func _show_gathering(result: Dictionary) -> void:
	var rows: Array[Control] = [_picture_row(str(result.get("image", "")))]
	rows.append(UiKit.line(str(result.get("message", ""))))
	var done := Button.new()
	done.name = "GatheringContinueButton"
	done.custom_minimum_size = Vector2(0, 100)
	done.text = Text.say("event.continue")
	done.pressed.connect(_gathering_panel.close)
	rows.append(done)
	_gathering_panel.open(Text.say("event.gathering_title"), rows)


## A background picture as a row in a panel; a missing picture shows a
## placeholder labelled with its asset ID.
func _picture_row(art_id: String) -> Control:
	var art := PlaceholderArt.new()
	art.name = "Picture_" + art_id
	art.kind = PlaceholderArt.Kind.BACKGROUND
	art.art_id = art_id
	art.custom_minimum_size = Vector2(0, 420)
	return art


## A random event may arrive now (never while a choice about the week is pending).
func _show_random_event_if_due() -> void:
	if GameState.is_in_level() or GameState.work_week_is_full():
		return
	var event_id := GameState.roll_random_event()
	if not event_id.is_empty():
		_present_event(event_id, true)


## The event screen: its title, flavor text and one button per choice.
func _present_event(event_id: String, arrived: bool) -> void:
	var event := GameState.get_event(event_id)
	if event.is_empty():
		return
	var rows: Array[Control] = []
	if event.get("image") != null and not str(event["image"]).is_empty():
		rows.append(_picture_row(str(event["image"])))
	if arrived:
		rows.append(UiKit.line(Text.say("event.heading_arrives"), "SmallLabel"))
	rows.append(UiKit.line(str(event.get("flavor", ""))))
	for choice: Dictionary in EventEngine.choices_for(DataDB.event_choices, event_id):
		var price: Variant = choice.get("funds_cost")
		var label := str(choice.get("choice_text", ""))
		var refusal := ""
		if price != null and int(price) > 0:
			label = Text.say("event.choice_cost", {"text": label, "cost": int(price)})
			if int(GameState.meta.get("Funds", 0)) < int(price):
				refusal = Text.say("event.refuse_funds")
		var letter := str(choice.get("choice", ""))
		var button := UiKit.action_button(label, refusal, _on_event_choice.bind(event_id, letter), 100.0)
		button.name = "EventChoice_" + letter
		rows.append(button)
	_event_panel.open(str(event.get("title", "")), rows)


func _on_event_choice(event_id: String, letter: String) -> void:
	var result := GameState.apply_event_choice(event_id, letter)
	if not bool(result.get("ok", false)):
		return
	var rows: Array[Control] = []
	var event_image: Variant = GameState.get_event(event_id).get("image")
	if event_image != null and not str(event_image).is_empty():
		rows.append(_picture_row(str(event_image)))
	rows.append(UiKit.line(str(result.get("result_text", ""))))
	for line: String in result.get("lines", []):
		rows.append(UiKit.line(line, "SmallLabel"))
	var chips := OrgChip.merged(result.get("chips", []))
	if not chips.is_empty():
		rows.append(OrgChip.row(chips))
	var revealed := str(result.get("revealed", ""))
	if not revealed.is_empty():
		rows.append(UiKit.line(Text.say("event.level_revealed", {"name": revealed}), "SmallLabel"))
	if int(result.get("hours", 0)) > 0:
		rows.append(UiKit.line(Text.say("event.hours_line", {"hours": int(result["hours"])}), "SmallLabel"))
	var done := Button.new()
	done.name = "EventContinueButton"
	done.custom_minimum_size = Vector2(0, 100)
	done.text = Text.say("event.continue")
	done.pressed.connect(_on_event_done)
	rows.append(done)
	_event_panel.open(str(GameState.get_event(event_id).get("title", "")), rows)


func _on_event_done() -> void:
	_event_panel.close()
	SaveManager.autosave()
	_build()


## What the party took at the week's end, as lines for the new-week popup.
func _dues_report_rows(report: Dictionary) -> Array[Control]:
	var rows: Array[Control] = []
	if report.is_empty():
		return rows
	if int(report.get("total", 0)) <= 0:
		rows.append(UiKit.line(Text.say("dues.none_line"), "SmallLabel"))
		return rows
	rows.append(UiKit.line(Text.say("dues.paid_line", {"yen_paid": int(report.get("paid", 0))}), "SmallLabel"))
	if int(report.get("owed", 0)) > 0:
		rows.append(UiKit.line(Text.say("dues.owed_line", {"yen_owed": int(report["owed"])}), "SmallLabel"))
	if bool(report.get("penalized", false)):
		rows.append(UiKit.line(Text.say("dues.penalty_line"), "SmallLabel"))
		var withdrawn: Array = report.get("withdrawn", [])
		if not withdrawn.is_empty():
			rows.append(UiKit.line(Text.say("dues.cancelled_line",
				{"names": ", ".join(PackedStringArray(withdrawn))}), "SmallLabel"))
	return rows


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
			"name": str(alert.get("name", "")),
		})))
	GameState.pending_trigger_alerts = []

	_trigger_alert_panel.open(Text.say("office.trigger_alert_title"), rows)


## The app was closed and reopened while a level was still in progress —
## the only way the Office is ever reached with GameState.is_in_level()
## still true, since normal play never returns here until a level actually
## concludes (every intermediate stage of a multi-stage level routes
## straight to the next one, never back through here). A forced choice,
## not the old silent auto-resume (Cameron, 2026-10-04): Resume picks up
## exactly where the saved stage left off, the same scene change the Start
## button's own "Resume the level" label already led to; Abandon throws
## the attempt away (GameState.abandon_level()) without recording a win or
## a loss, and the level goes right back to being just another choice in
## the Levels panel. Called after _show_trigger_alerts_if_any() so, on the
## rare run where both apply, this one ends up the frontmost panel — the
## more urgent of the two decisions.
func _show_resume_choice_if_in_level() -> void:
	if not GameState.is_in_level():
		return

	var rows: Array[Control] = []
	rows.append(UiKit.line(Text.say("office.resume_choice_body")))

	var resume_button := Button.new()
	resume_button.custom_minimum_size = Vector2(0, 110)
	resume_button.text = Text.say("office.resume_level")
	resume_button.pressed.connect(_on_resume_level_chosen)
	rows.append(resume_button)

	var abandon_button := Button.new()
	abandon_button.custom_minimum_size = Vector2(0, 110)
	abandon_button.text = Text.say("office.abandon_level")
	abandon_button.pressed.connect(_on_abandon_level_chosen)
	rows.append(abandon_button)

	_resume_choice_panel.open(Text.say("office.resume_choice_title"), rows)


## An ordinary level just ended with a special level due (GameState.special_forced):
## one panel, one button, and the special level begins. Called last, so it is
## the frontmost panel when alerts are showing too.
func _show_forced_special_if_due() -> void:
	if GameState.is_in_level():
		return
	var level := GameState.take_forced_special()
	if level.is_empty():
		return
	var rows: Array[Control] = []
	rows.append(UiKit.line(Text.say("office.special_forced_body",
		{"level": str(level.get("description", ""))})))
	var go := Button.new()
	go.name = "SpecialForcedGoButton"
	go.custom_minimum_size = Vector2(0, 110)
	go.text = Text.say("office.special_forced_go")
	go.pressed.connect(_on_forced_special_go.bind(level))
	rows.append(go)
	_special_forced_panel.open(Text.say("office.special_forced_title"), rows)


func _on_forced_special_go(level: Dictionary) -> void:
	_special_forced_panel.close()
	_chosen_level = level
	_on_start()


func _on_resume_level_chosen() -> void:
	_resume_choice_panel.close()
	get_tree().change_scene_to_file(StageRouting.scene_for(GameState.level_runner.current_stage()))


func _on_abandon_level_chosen() -> void:
	GameState.abandon_level()
	_resume_choice_panel.close()
	SaveManager.autosave()
	_build()


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
		DataDB.office_notices, GameState.staff_hired, GameState.meta, DataDB.staff,
		GameState.ticker_facts())
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
		[Text.say("office.staff"), _show_staff],
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

		rows.append(UiKit.heading(_scope_heading(tier)))
		for booster: Dictionary in in_tier:
			rows.append(_organisation_row(booster))

	_organisations_panel.open(Text.say("office.organisations"), rows)


## The heading over each scope of organization. The data value stays "Party"
## (the rules read it); the player sees "Party Bodies" (2026-10-16, Cameron).
func _scope_heading(tier: String) -> String:
	match tier:
		"Party":
			return Text.say("office.scope_party")
		"Constituency":
			return Text.say("office.scope_constituency")
		"National":
			return Text.say("office.scope_national")
	return tier


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
		var because := CauseLines.because(GameState.last_booster_cause.get(booster_id, []))
		if not because.is_empty():
			line += "  " + because

	var box := UiKit.tight_column()
	box.add_child(UiKit.line(line))
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

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
	return _with_booster_icon(booster_id, box)


## A small organisation image to the left of whatever describes it.
func _with_booster_icon(booster_id: String, content: Control) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var icon := TextureRect.new()
	icon.texture = ArtLoader.icon(booster_id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(84, 84)
	icon.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(icon)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(content)
	return row


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
	# A coupon's draw came from the Marketplace, so go back there.
	var coupon := DataDB.get_shop_item(str(GameState.card_draw.get("item_id", "")))
	var reopen: Callable = (_show_marketplace if coupon.get("free_card_tier") != null
		else _show_rhetoric_training)
	var result := GameState.learn_offered_card()
	if result.get("ok", false):
		_report.text = str(result.get("message", ""))
		_after_spending("", reopen)
	else:
		_after_spending(str(result.get("message", "")), reopen)


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
		lines.append(Text.say("new_game.stat_line", {"name": name, "value": Phrase.meta_amount(name, int(meta.get(name, 0)))}))
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
	_inventory_panel.on_used = func(result: Dictionary) -> void:
		_refresh_resources()
		SaveManager.autosave()
		# A Training Session Coupon starts a free draw: show the card now.
		if bool(result.get("opens_draw", false)):
			_show_card_offer.call_deferred()
		# A dinner or a walking tour starts its own three-screen event.
		if bool(result.get("ok", false)) and not str(result.get("opens_hosted", "")).is_empty():
			_hosted_panel.begin.call_deferred()
		# Any other item with a picture shows it.
		elif bool(result.get("ok", false)) and not str(result.get("image", "")).is_empty():
			_show_gathering.call_deferred(result)
	# Using an item from the Marketplace must reopen the WHOLE Marketplace
	# (grid + Supplies), not narrow back to InventoryPanel's own plain grid
	# view — see reopen's own doc comment.
	_inventory_panel.reopen = _show_marketplace
	add_child(_inventory_panel)

	var button := Button.new()
	button.name = "InventoryButton"
	# The battle screen's Inventory button is white; this one is the Office's
	# Marketplace and takes the party colour (Layout.is_cancel_button()).
	button.set_meta("party_outline", true)
	button.text = Text.say("office.marketplace")
	button.custom_minimum_size = _management_button.custom_minimum_size
	button.size_flags_horizontal = _management_button.size_flags_horizontal
	button.pressed.connect(_show_marketplace)
	var parent := _management_button.get_parent()
	parent.add_child(button)
	parent.move_child(button, _management_button.get_index() + 1)


## The "Your Record" panel. Its button lives in the Reputation and Results
## menu now (_show_reputation_menu), no longer in the Office's own row.
func _build_record() -> void:
	_record_panel = Overlay.new()
	_record_panel.name = "RecordPanel"
	add_child(_record_panel)
	# Election strength and the two awareness meters (2026-10-23, Cameron).
	_election_panel = Overlay.new()
	_election_panel.name = "ElectionPanel"
	add_child(_election_panel)
	# One law's details, opened from the statute book on top of Your Record.
	_law_panel = Overlay.new()
	_law_panel.name = "LawPanel"
	add_child(_law_panel)
	_parties_panel = Overlay.new()
	_parties_panel.name = "PartiesPanel"
	add_child(_parties_panel)
	# Opened from a party's button; added after the list so it draws above it.
	_party_detail_panel = Overlay.new()
	_party_detail_panel.name = "PartyDetailPanel"
	add_child(_party_detail_panel)


## How each of the six parties sees the player (PartyOpinion.gd): the party's
## mood from votes and rewards blended with how its stakeholder organisations
## feel. Your own party is tagged; every party is in its own official colour.
func _show_parties() -> void:
	var rows: Array[Control] = [UiKit.line(Text.say("party_opinion.blurb"), "SmallLabel")]
	var own := GameState.own_party_id()
	var names := BattleSetup.booster_names()
	for party: Dictionary in DataDB.parties:
		var party_id := str(party.get("party_id", ""))
		var detail := GameState.party_opinion_detail(party_id)
		var box := UiKit.tight_column()
		var title := str(party.get("name", party_id))
		if party_id == own:
			title += " " + Text.say("party_opinion.own_tag")
		var heading := UiKit.heading(title)
		heading.add_theme_color_override("font_color", PartyDisplay.color_for(party))
		box.add_child(heading)
		box.add_child(UiKit.line(Text.say("party_opinion.line", {
			"score": detail["opinion"],
			"band": _band_word(str(detail["band"])),
		})))
		var held := int(detail["stakeholder"])
		box.add_child(UiKit.line(Text.say("party_opinion.detail", {
			"direct": detail["direct"],
			"stakeholder": "—" if held == PartyOpinion.NO_SCORE else str(held),
		}), "SmallLabel"))
		var view := Button.new()
		view.name = "AlliesButton_" + party_id
		view.text = Text.say("party_opinion.view_button")
		view.custom_minimum_size = Vector2(0, 90)
		view.pressed.connect(_show_party_detail.bind(party_id))
		box.add_child(view)
		rows.append(box)
	_parties_panel.open(Text.say("office.parties"), rows)


## The popup behind a party's "See allies and rivals" button: the
## organisations the party counts as friends and as opponents, each with a
## standing bar and a tag for what it is doing to the party's view of you now.
## An ally's bar is the party's own colour; a rival's is white.
func _show_party_detail(party_id: String) -> void:
	var party := {}
	for row: Dictionary in DataDB.parties:
		if str(row.get("party_id", "")) == party_id:
			party = row
	var colour := PartyDisplay.color_for(party)
	var detail := GameState.party_opinion_detail(party_id)
	var groups := PartyAllies.groups(detail["contributions"])
	var names := BattleSetup.booster_names()

	var rows: Array[Control] = [UiKit.line(Text.say("party_opinion.popup_blurb"), "SmallLabel")]
	for group in ["allies", "rivals"]:
		var is_ally: bool = group == "allies"
		var heading := UiKit.heading(Text.say(
			"party_opinion.allies_heading" if is_ally else "party_opinion.rivals_heading"))
		if is_ally:
			heading.add_theme_color_override("font_color", colour)
		rows.append(heading)
		rows.append(UiKit.line(Text.say(
			"party_opinion.allies_blurb" if is_ally else "party_opinion.rivals_blurb"), "SmallLabel"))
		if (groups[group] as Array).is_empty():
			rows.append(UiKit.line(Text.say("party_opinion.none")))
		for entry: Dictionary in groups[group]:
			rows.append(_ally_row(entry, names, colour if group == "allies" else Color.WHITE))
	_party_detail_panel.open(str(party.get("name", party_id)), rows)
	# Panels draw in the order they were added, and the Parties page was just
	# moved to the front by its menu: put the popup above it.
	move_child(_party_detail_panel, get_child_count() - 1)
	_party_detail_panel.get_node("Margin/Scroll/Centre/Column/Heading").add_theme_color_override(
		"font_color", colour)


## One organisation in the popup: its name and standing, the favorability tag,
## and a 0-100 bar filled in `fill`.
func _ally_row(entry: Dictionary, names: Dictionary, fill: Color) -> Control:
	var box := UiKit.tight_column()
	box.add_child(UiKit.line(Text.say("party_opinion.standing_line", {
		"name": str(names.get(str(entry["booster_id"]), entry["booster_id"])),
		"standing": int(entry["standing"]),
	})))
	box.add_child(_colour_bar(int(entry["standing"]), fill))
	var tag_text := Text.say("party_opinion.tag_neutral")
	match str(entry["tag"]):
		PartyAllies.IMPROVING: tag_text = Text.say("party_opinion.tag_improving")
		PartyAllies.REDUCING: tag_text = Text.say("party_opinion.tag_reducing")
	var tag := UiKit.line(tag_text, "SmallLabel")
	box.add_child(tag)
	return box


## A 0-100 bar filled in one colour over a faint track, the look shared by the
## allies popup and the Election Strength page.
func _colour_bar(value: float, fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 22)
	var fill_box := StyleBoxFlat.new()
	fill_box.bg_color = fill
	bar.add_theme_stylebox_override("fill", fill_box)
	var back_box := StyleBoxFlat.new()
	back_box.bg_color = Color(1, 1, 1, 0.12)
	bar.add_theme_stylebox_override("background", back_box)
	return bar


## Election strength and the two awareness meters, each a bar in the colour of
## the player's own party, then what the strength is made of. The input lines
## say "points from ..." so they are never mistaken for the meters themselves.
func _show_election() -> void:
	var colour := PartyDisplay.color_for(DataDB.get_party(str(DataDB.player.get("party", ""))))
	var rows: Array[Control] = []
	rows.append(UiKit.line(Text.say("election.bar_line", {"value": roundi(GameState.election_strength)})))
	rows.append(_colour_bar(GameState.election_strength, colour))
	rows.append(UiKit.line(Text.say("election.potential_line",
		{"value": roundi(GameState.election_potential())}), "SmallLabel"))

	var meter_names := {"district": Text.say("awareness.district"), "national": Text.say("awareness.national")}
	for meter: String in ["district", "national"]:
		var value := int(GameState.awareness.get(meter, 0))
		var meter_line := Text.say("election.meter_line", {"name": meter_names[meter], "value": value})
		var meter_change := int(GameState.last_awareness_change.get(meter, 0))
		if meter_change != 0:
			meter_line += "  (%+d)" % meter_change
		rows.append(UiKit.line(meter_line))
		rows.append(_colour_bar(value, colour))

	rows.append(UiKit.heading(Text.say("election.inputs_heading")))
	var part_names := {
		"district": Text.say("election.c_district"), "national": Text.say("election.c_national"),
		"constituency": Text.say("election.c_constituency"), "organizations": Text.say("election.c_organizations"),
		"war_chest": Text.say("election.c_war_chest"), "experience": Text.say("election.c_experience"),
		"record": Text.say("election.c_record"), "party": Text.say("election.c_party")}
	for part: Dictionary in GameState.election_parts():
		rows.append(UiKit.line(Text.say("election.component_line", {
			"name": part_names[str(part["id"])], "points": "%.1f" % float(part["points"]),
			"max": roundi(float(part["max"]))}), "SmallLabel"))
	_election_panel.open(Text.say("election.title"), rows)


## The word for an opinion band; each is its own Text row so it can be reworded.
func _band_word(band: String) -> String:
	match band:
		"hostile": return Text.say("party_opinion.band_hostile")
		"cold": return Text.say("party_opinion.band_cold")
		"warm": return Text.say("party_opinion.band_warm")
		"allied": return Text.say("party_opinion.band_allied")
	return Text.say("party_opinion.band_neutral")


## Lifetime stats: which bills the influence swing has flipped, clears per
## tier (derived from the level tally at display time rather than kept as a
## third counter), and how many times each level has been cleared.
func _show_record() -> void:
	var rows: Array[Control] = []

	rows.append(UiKit.heading(Text.say("office.record_sanban_heading")))
	for variable: Dictionary in DataDB.sanban:
		var name := str(variable.get("name_en", ""))
		# Party support is shown as the LIVE number the rules read (the blend of
		# votes and stakeholders, GameState.party_support_effective()), not the
		# stored half of it, so this page agrees with the Parties page.
		var is_party := name == "Party support"
		var shown: Variant = (GameState.party_support_effective()
			if is_party else GameState.meta.get(name, 0))
		var line := Text.say("new_game.stat_line", {"name": name, "value": Phrase.meta_amount(name, int(shown))})
		# What moved this level, the same "(+N)" treatment Important
		# Stakeholders already gives a booster's own recent change.
		var change := (GameState.party_support_change_this_level()
			if is_party else int(GameState.last_meta_change.get(name, 0)))
		if change != 0:
			line += "  (%+d)" % change
			var because := CauseLines.because(GameState.last_meta_cause.get(name, []))
			if not because.is_empty():
				line += "  " + because
		rows.append(UiKit.line(line))

	rows.append(UiKit.heading(Text.say("office.record_bills_heading")))
	if GameState.bills_flipped_by_influence.is_empty():
		rows.append(UiKit.line(Text.say("office.record_bills_empty")))
	else:
		for bill_id: String in GameState.bills_flipped_by_influence:
			var bill_name := str(DataDB.floor_votes.get(bill_id, {}).get("bill_name", bill_id))
			rows.append(UiKit.line(bill_name))

	# The statute book (2026-10-12): every bill voted on, passed or failed.
	rows.append(UiKit.heading(Text.say("office.record_statute_heading")))
	if GameState.statute_book.is_empty():
		rows.append(UiKit.line(Text.say("office.record_statute_empty")))
	else:
		rows.append(UiKit.line(Text.say("record.law_tap_hint"), "SmallLabel"))
		for law: Dictionary in GameState.statute_book:
			var law_id := str(law.get("bill_id", ""))
			var button := UiKit.action_button(Text.say(
				"office.record_law_passed" if bool(law.get("passed", false)) else "office.record_law_failed", {
					"name": DataDB.floor_votes.get(law_id, {}).get("bill_name", law_id),
					"yes": law.get("yes", 0), "no": law.get("no", 0), "abstain": law.get("abstain", 0),
					"vote": _vote_word(str(law.get("player_vote", ""))),
				}), "", _show_law.bind(law), 100.0)
			button.name = "Law_" + law_id
			rows.append(button)

	# Bills organizations asked the player to carry (patron step 4).
	var carried: Array[Control] = []
	for patron_id: String in GameState.patron_requests:
		var status := str((GameState.patron_requests[patron_id] as Dictionary).get("status", ""))
		if status != PatronRequests.PASSED and status != PatronRequests.FAILED:
			continue
		var patron_row := PatronLevel.patron_bill(patron_id)
		var org_id := str(patron_row.get("organization", ""))
		var bill_name := str((GameState.patron_composed.get(patron_id, {}) as Dictionary).get("bill", {}).get("bill_name", patron_id))
		var line_key := "pass_line" if status == PatronRequests.PASSED else "fail_line"
		carried.append(UiKit.line(Text.say("record.carried_line", {"name": bill_name,
			"result": Text.say("record.carried_passed" if status == PatronRequests.PASSED else "record.carried_failed")})))
		var story := str(patron_row.get(line_key, ""))
		if not story.is_empty():
			carried.append(UiKit.line(story.replace("{org}", str(DataDB.get_booster(org_id).get("name_en", org_id))).replace("{bill}", bill_name), "SmallLabel"))
	if not carried.is_empty():
		rows.append(UiKit.heading(Text.say("record.carried_heading")))
		rows.append_array(carried)

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

	_record_panel.open(Text.say("office.your_record"), rows)


## One law in the statute book as a pop-up (2026-10-15): PASSED or FAILED,
## what it needed (Majority or Supermajority Vote to Pass), the Aye / Nay /
## Abstain count, how the player voted, whether their influence turned it,
## and what it did when voted and at the end of every later level.
func _show_law(law: Dictionary) -> void:
	var bill_id := str(law.get("bill_id", ""))
	var bill: Dictionary = DataDB.floor_votes.get(bill_id, {})
	var passed := bool(law.get("passed", false))
	var rows: Array[Control] = []

	var marker := UiKit.heading(Text.say(
		"record.law_marker_passed" if passed else "record.law_marker_failed"))
	marker.add_theme_color_override("font_color",
		VoteMeter.PASS_COLOUR if passed else VoteMeter.FAIL_COLOUR)
	rows.append(marker)

	var requirement := str(law.get("requirement", FloorVoteEngine.requirement_of(bill)))
	var totals := {"Yes": int(law.get("yes", 0)), "No": int(law.get("no", 0)),
		"Abstain": int(law.get("abstain", 0))}
	var needed := int(law.get("yes_needed", 0))
	if needed <= 0:   # a law recorded before the requirement was saved
		needed = FloorVoteEngine.yes_needed(totals, requirement,
			int(DataDB.balance.get("supermajority_percent", 67)))
	var house: int = totals["Yes"] + totals["No"] + totals["Abstain"]
	rows.append(UiKit.line(Text.say("floor_vote.req_line", {
		"requirement": VoteWords.requirement_label(requirement),
		"needed": needed, "house": house})))
	rows.append(UiKit.line(Text.say("record.law_tally", {
		"yes": totals["Yes"], "no": totals["No"], "abstain": totals["Abstain"]})))
	rows.append(UiKit.line(Text.say("record.law_voted",
		{"vote": _vote_word(str(law.get("player_vote", "")))})))
	if bool(law.get("flipped_by_influence", false)):
		rows.append(UiKit.line(Text.say("record.law_flipped")))

	var any_effect := false
	for timing: Array in [[StatuteBook.ONCE, "record.law_now"], [StatuteBook.EACH_LEVEL, "record.law_each"]]:
		var lines := _law_effect_lines(bill_id, passed, str(timing[0]))
		var chips := OrgChip.merged(_law_effect_chips(bill_id, passed, str(timing[0])))
		if lines.is_empty() and chips.is_empty():
			continue
		any_effect = true
		rows.append(UiKit.heading(Text.say(str(timing[1]))))
		if not chips.is_empty():
			rows.append(OrgChip.row(chips))
		for line: String in lines:
			rows.append(UiKit.line(line))
	if not any_effect:
		rows.append(UiKit.line(Text.say("record.law_no_effects")))

	_law_panel.open(str(bill.get("bill_name", bill_id)), rows)
	move_child(_law_panel, get_child_count() - 1)   # above Your Record


## The fixed effects a law's Law Effects rows carry for this outcome and
## timing, as "Reputation +2" style lines (organisations, audiences, meta, XP).
## Party Headquarters and Party Faction follow the player's own party, so they
## are not listed here.
func _law_effect_lines(bill_id: String, passed: bool, timing: String) -> Array[String]:
	var lines: Array[String] = []
	for row: Dictionary in StatuteBook.effects_for(DataDB.law_effects, bill_id, passed, timing):
		var deltas := StatuteBook.meta_deltas(row)
		for name: String in deltas:
			lines.append(_effect_line(name, int(deltas[name])))
		var xp := StatuteBook.xp_delta(row)
		if xp != 0:
			lines.append(_effect_line("XP", xp))
	return lines


## The organization and audience-group changes of the same rows, as chip
## entries ({ "id", "delta" }); everything else stays a line above.
func _law_effect_chips(bill_id: String, passed: bool, timing: String) -> Array:
	var chips: Array = []
	for row: Dictionary in StatuteBook.effects_for(DataDB.law_effects, bill_id, passed, timing):
		var entries: Variant = row.get("effects")
		if entries is Array:
			for entry: Dictionary in entries:
				chips.append({"id": str(entry.get("target", "")), "delta": int(entry.get("delta", 0))})
	return chips


func _effect_line(name: String, delta: int) -> String:
	var shown := Phrase.meta_amount(name, delta, true)
	return Text.say("record.effect_line", {"name": name, "delta": shown})


## How the player voted, in Your Record's own words. Spelled out key by key
## so the exporter's "does anything ask for this key" check can see each one.
func _vote_word(vote: String) -> String:
	match vote:
		"Yes":
			return Text.say("office.record_vote_yes")
		"No":
			return Text.say("office.record_vote_no")
		_:
			return Text.say("office.record_vote_abstain")


## The How to Play panel (HowToPlayPanel.gd, shared with the title screen).
## Its button lives in the Administration menu (_show_administration_menu).
func _build_how_to_play() -> void:
	_how_to_play_panel = HowToPlayPanel.attach(self)


## The Appearance and Music panel. Its button lives in the Administration
## menu too.
func _build_cosmetics() -> void:
	_cosmetics_panel = Overlay.new()
	_cosmetics_panel.name = "CosmeticsPanel"
	add_child(_cosmetics_panel)


## Two intermediary menus (2026-10-06, Cameron) so the Office's button row
## stays short: "Reputation and Results" holds Important Stakeholders and
## Your Record; "Administration" holds Appearance and Music and How to Play.
## Each menu is an ordinary Overlay whose rows are buttons that open the
## panel they always opened. The menu stays open underneath, so Back from
## the panel lands on the menu again. Built in code, no scene edit, except
## that ReputationButton is the scene's old OrganisationsButton, renamed.
func _build_menus() -> void:
	_reputation_menu = Overlay.new()
	_reputation_menu.name = "ReputationMenuPanel"
	add_child(_reputation_menu)

	_administration_menu = Overlay.new()
	_administration_menu.name = "AdministrationMenuPanel"
	add_child(_administration_menu)

	var button := Button.new()
	button.name = "AdministrationButton"
	button.text = Text.say("office.administration")
	button.custom_minimum_size = _reputation_button.custom_minimum_size
	button.size_flags_horizontal = _reputation_button.size_flags_horizontal
	button.pressed.connect(_show_administration_menu)
	var parent := _reputation_button.get_parent()
	parent.add_child(button)
	parent.move_child(button, _reputation_button.get_index() + 1)


func _show_reputation_menu() -> void:
	var rows: Array[Control] = [
		_menu_button("OrganisationsButton", "office.organisations", _show_organisations,
			_organisations_panel),
		_menu_button("BackingButton", "office.backing", _show_backing, _backing_panel),
		_menu_button("PartiesButton", "office.parties", _show_parties, _parties_panel),
		_menu_button("ElectionButton", "election.title", _show_election, _election_panel),
		_menu_button("RecordButton", "office.your_record", _show_record, _record_panel),
	]
	_reputation_menu.open(Text.say("office.reputation_and_results"), rows)


func _show_administration_menu() -> void:
	var rows: Array[Control] = [
		_menu_button("CosmeticsButton", "office.cosmetics", _show_cosmetics, _cosmetics_panel),
		_menu_button("HowToPlayButton", "office.how_to_play",
			HowToPlayPanel.open.bind(_how_to_play_panel), _how_to_play_panel),
		_text_size_button(),
	]
	# The save buttons sit directly in the menu's row list, so the gap between
	# them is the same as between every other menu button.
	rows.append_array(_backup_buttons())
	# Starting over lives here, not in Office Management (Cameron,
	# 2026-10-11). The menu closes first so it is not left open under the
	# warning and the New Game screens.
	rows.append(_menu_button("NewGameMenuButton", "office.new_game", func() -> void:
		_administration_menu.close()
		_confirm_new_game(), _new_game_panel))
	_administration_menu.open(Text.say("office.administration"), rows)


## One manual backup slot (2026-10-15): "Back up now" writes it; "Restore"
## (after a warning) replaces the run with it. Shown with when it was made.
func _backup_buttons() -> Array[Control]:
	var box: Array[Control] = []
	var now := UiKit.action_button(Text.say("office.backup_now"), "", _on_backup_now, 100.0)
	now.name = "BackupNowButton"
	now.custom_minimum_size.x = UiKit.LINE_WIDTH
	box.append(now)
	if SaveManager.has_backup():
		var restore := UiKit.action_button(Text.say("office.backup_restore"), "",
			_confirm_backup_action.bind("restore"), 100.0)
		restore.name = "BackupRestoreButton"
		restore.custom_minimum_size.x = UiKit.LINE_WIDTH
		box.append(restore)
		# No floating summary line here: the summary shows in the restore warning.
	if SaveManager.has_undo():
		var undo := UiKit.action_button(Text.say("office.backup_undo"), "",
			_confirm_backup_action.bind("undo"), 100.0)
		undo.name = "BackupUndoButton"
		undo.custom_minimum_size.x = UiKit.LINE_WIDTH
		box.append(undo)
	return box


## "15 Oct 14:32 · Last level cleared: ... · Inventory: 3 items · XP: 340 · Funds: 80,000".
func _summary_label(summary: Dictionary) -> String:
	if summary.is_empty():
		return Text.say("office.backup_none")
	var level_id := str(summary.get("level_id", ""))
	var level := (str(DataDB.get_level(level_id).get("description", level_id))
		if not level_id.is_empty() else Text.say("office.backup_no_level"))
	return Text.say("office.backup_label", {
		"when": str(summary.get("when", "")) if not str(summary.get("when", "")).is_empty()
			else Text.say("office.backup_current_when"),
		"level": level,
		"items": Text.say("office.backup_items", {"count": int(summary.get("items", 0))}),
		"xp": int(summary.get("xp", 0)),
		"funds": Phrase.meta_amount("Funds", int(summary.get("funds", 0)))})


## The run being played right now, summarised the same way.
func _current_summary() -> Dictionary:
	var summary := SaveSummary.of(GameState.to_save())
	summary["when"] = ""
	return summary


func _on_backup_now() -> void:
	if SaveManager.has_backup():
		_confirm_backup_action("overwrite")   # a backup exists: ask before replacing it
		return
	_do_backup()


func _do_backup() -> void:
	var ok := SaveManager.backup_now()
	Layout.flash(Text.say("office.backup_made" if ok else "office.backup_failed"))
	_show_administration_menu()


## "restore", "undo" and "overwrite" each ask first, showing what would be
## lost; the answer comes back through _on_backup_confirmed().
func _confirm_backup_action(kind: String) -> void:
	_backup_action = kind
	var backup := SaveManager.summary_of(SaveManager.MANUAL_PATH)
	match kind:
		"restore":
			_new_game_panel.open(Text.say("office.backup_restore"),
				[UiKit.line(Text.say("office.backup_compare", {
					"backup": _summary_label(backup),
					"current": _summary_label(_current_summary())}))],
				Text.say("office.backup_restore_confirm"))
		"undo":
			_new_game_panel.open(Text.say("office.backup_undo"),
				[UiKit.line(Text.say("office.backup_undo_warning", {
					"saved": _summary_label(SaveManager.summary_of(SaveManager.UNDO_PATH))}))],
				Text.say("office.backup_undo_confirm"))
		_:
			_new_game_panel.open(Text.say("office.backup_now"),
				[UiKit.line(Text.say("office.backup_overwrite", {"backup": _summary_label(backup)}))],
				Text.say("office.backup_overwrite_confirm"))
	if not _new_game_panel.confirmed.is_connected(_on_backup_confirmed):
		_new_game_panel.confirmed.connect(_on_backup_confirmed)


func _on_backup_confirmed() -> void:
	_new_game_panel.confirmed.disconnect(_on_backup_confirmed)
	match _backup_action:
		"restore":
			if SaveManager.restore_backup():
				get_tree().reload_current_scene.call_deferred()
		"undo":
			if SaveManager.restore_undo():
				get_tree().reload_current_scene.call_deferred()
		_:
			_do_backup()


## "Text size: Normal" -- one tap cycles Small, Normal, Large and applies it
## at once; the menu is rebuilt so the screen shows the new size.
func _text_size_button() -> Button:
	var button := UiKit.action_button(_text_size_label(), "", func() -> void:
		Layout.cycle_text_size()
		_show_administration_menu(), 100.0)
	button.name = "TextSizeButton"
	button.custom_minimum_size.x = UiKit.LINE_WIDTH
	return button


func _text_size_label() -> String:
	var word := Text.say("text_size.normal")
	match Layout.text_size_setting:
		TextScale.SMALL: word = Text.say("text_size.small")
		TextScale.LARGE: word = Text.say("text_size.large")
	return Text.say("office.text_size", {"size": word})


## One row of a menu: a button that runs `opener` (which opens `panel`) and
## then brings `panel` to the front. Panels are drawn in the order they were
## added, and the menus were added after some of them, so without this the
## menu would sit on top of the very panel it just opened.
func _menu_button(button_name: String, text_key: String, opener: Callable,
		panel: Overlay) -> Button:
	var button := UiKit.action_button(Text.say(text_key), "", func() -> void:
		opener.call()
		move_child(panel, get_child_count() - 1), 100.0)
	button.name = button_name
	# As wide as the text column of every other panel, so a menu's buttons
	# are not shrunk to their own labels.
	button.custom_minimum_size.x = UiKit.LINE_WIDTH
	return button


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
		CosmeticPieces.DINING: return Text.say("office.cosmetics_slot_dining")
		CosmeticPieces.TOUR: return Text.say("office.cosmetics_slot_tour")
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
	# Same for the protagonist's own picture: an outfit only shows up once the
	# portrait is told to look again (2026-10-05, Cameron: "Workplace Casual"
	# only appeared after starting a level).
	if slot == CosmeticPieces.OUTFIT and _portrait is PlaceholderArt:
		var art := _portrait as PlaceholderArt
		art.art_id = art.art_id
	_show_cosmetics()


## The Marketplace (2026-09-28, Cameron: Supplies moved out of Office
## Management, folded in here, beside what you already own). Reordered
## 2026-09-29, Cameron, after seeing it on screen: the panel now opens on
## "Supplies" (its blurb, then what you currently hold — InventoryPanel.
## inventory_rows(), the same rows show_inventory() would open alone, whose
## own "appear here" wording is about Supplies purchases landing in your
## inventory, not about the Marketplace heading below it), THEN a
## "Marketplace" heading introduces your XP/Funds and the buyable Supplies
## rows — each row the item's icon, name and price, what it does, and Buy,
## or, once its Purchase Limit for this level is reached, a greyed-out
## "Out of Stock". One screen, one panel (_inventory_panel itself), so
## tapping a held item still drills into its own detail view exactly as it
## always has.
func _show_marketplace() -> void:
	var rows: Array[Control] = []
	rows.append(UiKit.line(Text.say("shop.supplies_blurb")))
	rows.append_array(_inventory_panel.inventory_rows())
	rows.append(UiKit.heading(Text.say("office.marketplace")))
	rows.append(UiKit.line(Text.say("office.xp", {"count": GameState.xp}), "HeaderLabel"))
	rows.append(UiKit.line(Text.say("office.funds",
		{"count": int(GameState.meta.get("Funds", 0))}), "HeaderLabel"))
	for item: Dictionary in DataDB.shop:
		# Card sessions live in Rhetoric Training, not here.
		if item.get("card_tier") == null:
			rows.append(_supply_row(item))
	_inventory_panel.open(Text.say("shop.supplies"), rows)


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

	# Both faces are shown at twice the card's battle size (Cameron,
	# 2026-10-19). The front is a fixed-size card, so it is scaled inside a
	# box of the doubled size; the back lays its text out from its own size.
	var scale_up := 2.0
	var front := CardView.new()
	front.show_card(card)
	front.disabled = true   # a preview, not a hand — tapping it does nothing
	front.scale = Vector2(scale_up, scale_up)
	var front_box := Control.new()
	front_box.custom_minimum_size = Vector2(CardView.WIDTH, CardView.HEIGHT) * scale_up
	front_box.add_child(front)
	var front_frame := CenterContainer.new()
	front_frame.add_child(front_box)

	# Sized to match the front's own height, so the pair reads as one card
	# shown both sides rather than a small card under a much bigger one.
	var back := CardBackView.new()
	back.custom_minimum_size = Vector2(CardView.HEIGHT * CardBackView.ASPECT, CardView.HEIGHT) * scale_up
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

	_backing_panel.open(Text.say("office.backing"), rows)


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
		var standing := (Text.say("backing.standing", {
				"name": names.get(booster, booster), "have": have})
			if have >= needed
			else Text.say("backing.standing_needs", {
				"name": names.get(booster, booster), "have": have, "needed": needed}))
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
	if not booster.is_empty():
		return _with_booster_icon(booster, box)
	# A backing tied to an audience group rather than an organisation (Local
	# Support, Shotengai, the press ones, Party Backing) shows that group's
	# own icon (assets/icons/SG01.png ...), a labelled placeholder until drawn.
	var audience := _audience_of(modifier)
	return _with_booster_icon(audience, box) if not audience.is_empty() else box


## The first audience group (SGxx) a modifier is triggered by, or "".
func _audience_of(modifier: Dictionary) -> String:
	var ids: Variant = modifier.get("trigger_segment_ids")
	if ids is Array and not (ids as Array).is_empty():
		return str((ids as Array)[0])
	return ""


## "10 Funds" or, where a modifier charges more than one currency,
## "10 Funds, 5 Reputation". The three currency names are sanban.json's own
## names, the same ones the rest of the screen already shows.
func _cost_line(modifier: Dictionary) -> String:
	var parts: Array[String] = []
	var costs := Ledger.modifier_costs(modifier)
	for name: String in costs.keys():
		var cost: int = costs[name]
		if cost > 0:
			parts.append("%s %s" % [name, Phrase.meta_amount(name, cost)] if name == "Funds"
				else "%s %s" % [Phrase.with_separators(cost), name])
	return ", ".join(parts) if not parts.is_empty() else Text.say("shop.item_free")


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


## One candidate for a vacant role: a button that opens their profile (what
## each tier gives and costs, and the Hire button). Someone fired earlier this
## run shows greyed out with no button at all.
func _staff_candidate_row(candidate: Dictionary) -> Control:
	var staff_id := str(candidate.get("staff_id", ""))
	var fired := bool(GameState.staff_fired.get(staff_id, false))
	var box := UiKit.tight_column()
	var summary := Text.say("office.staff_candidate", {
		"name": candidate.get("name", staff_id),
		"cost": int(candidate.get("hiring_cost_yen", 0)),
	})

	if fired:
		box.add_child(UiKit.line(summary))
		box.add_child(UiKit.line(Text.say("office.staff_fired"), "SmallLabel"))
		box.modulate = Color(1, 1, 1, 0.5)
	else:
		box.add_child(_profile_button(summary, staff_id))
	return box


## The one candidate hired into a role: a button that opens their profile,
## where Upgrade and Fire now live beside the tiers they act on.
func _staff_hired_row(_role: String, hired: Dictionary) -> Control:
	var candidate := DataDB.get_staff(str(hired.get("staff_id", "")))
	var box := UiKit.tight_column()
	box.add_child(_profile_button(Text.say("office.staff_hired", {
		"name": candidate.get("name", hired.get("staff_id", "")),
		"tier": int(hired.get("tier", 0)),
		"highest": int(candidate.get("highest_tier", 0)),
	}), str(hired.get("staff_id", ""))))
	return box


func _profile_button(text: String, staff_id: String) -> Button:
	var button := Button.new()
	button.name = "Profile_" + staff_id
	button.text = text
	button.custom_minimum_size = Vector2(0, 90)
	button.pressed.connect(_show_staff_profile.bind(staff_id))
	return button


## The Staff Profile: who this is, what each tier gives, what each step up
## costs, and the one action that applies (Hire for a candidate, Upgrade and
## Fire for the person already in the role). Nothing here decides anything —
## the tier rows come from StaffProfile, the refusals from Ledger.
func _show_staff_profile(staff_id: String) -> void:
	var candidate := DataDB.get_staff(staff_id)
	if candidate.is_empty():
		return
	var role := str(candidate.get("role", ""))
	var hired: Dictionary = GameState.staff_hired.get(role, {})
	var is_hired := str(hired.get("staff_id", "")) == staff_id
	var current_tier := int(hired.get("tier", 0)) if is_hired else -1
	var rows: Array[Control] = []

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 20)
	var portrait := PlaceholderArt.new()
	portrait.custom_minimum_size = Vector2(200, 260)
	portrait.kind = PlaceholderArt.Kind.CHARACTER
	portrait.art_id = staff_id
	head.add_child(portrait)
	var who := UiKit.tight_column()
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.add_child(UiKit.line(role, "SmallLabel"))
	who.add_child(UiKit.line(Text.say("staff.profile_cost",
		{"cost": int(candidate.get("hiring_cost_yen", 0))})))
	head.add_child(who)
	rows.append(head)

	rows.append(UiKit.heading(Text.say("staff.tiers_heading")))
	for entry: Dictionary in StaffProfile.tiers(candidate, DataDB.boosters, DataDB.segments, Text.phrase()):
		var box := UiKit.tight_column()
		box.name = "Tier_%d" % int(entry["tier"])
		box.add_child(UiKit.line(_tier_label(entry, current_tier), "HeaderLabel"))
		for line: String in entry["lines"]:
			box.add_child(UiKit.line(line))
		rows.append(box)
	if int(candidate.get("highest_tier", 0)) <= int(candidate.get("starting_tier", 0)):
		rows.append(UiKit.line(Text.say("staff.no_upgrades"), "SmallLabel"))

	var funds := int(GameState.meta.get("Funds", 0))
	if is_hired:
		var cost: Variant = Ledger.staff_upgrade_cost(candidate, current_tier)
		if cost == null:
			rows.append(UiKit.action_button("", Text.say("office.staff_at_max"), Callable()))
		else:
			var upgrade := UiKit.action_button(Text.say("office.upgrade", {"cost": int(cost)}),
				Ledger.staff_upgrade_refusal(candidate, current_tier, funds, Text.phrase()),
				_on_profile_upgrade.bind(role))
			upgrade.name = "ProfileUpgradeButton"
			rows.append(upgrade)
		var fire := UiKit.action_button(Text.say("office.fire_staff"),
			Ledger.staff_fire_refusal(candidate, funds, Text.phrase()),
			_confirm_fire_staff.bind(role, candidate))
		fire.name = "ProfileFireButton"
		rows.append(fire)
	else:
		var hire := UiKit.action_button(Text.say("office.hire"),
			Ledger.staff_hire_refusal(candidate, hired,
				bool(GameState.staff_fired.get(staff_id, false)), funds,
				GameState.staff_recruitment_tier, Text.phrase()),
			_on_profile_hire.bind(staff_id))
		hire.name = "ProfileHireButton"
		rows.append(hire)

	_staff_profile_panel.open(str(candidate.get("name", staff_id)), rows)


## "Tier 1 · upgrade cost 30000 Yen", "Tier 0 · given when hired", and so on.
func _tier_label(entry: Dictionary, current_tier: int) -> String:
	var tier := int(entry["tier"])
	if tier == current_tier:
		return Text.say("staff.tier_current", {"tier": tier})
	if bool(entry["on_hire"]) and current_tier < 0:
		return Text.say("staff.tier_on_hire", {"tier": tier})
	if not bool(entry["on_hire"]) and tier > current_tier:
		if entry["cost"] == null:
			return Text.say("staff.tier_upgrade_unpriced", {"tier": tier})
		return Text.say("staff.tier_upgrade", {"tier": tier, "cost": int(entry["cost"])})
	return Text.say("staff.tier_label", {"tier": tier})


func _on_profile_hire(staff_id: String) -> void:
	_staff_profile_panel.close()
	_after_spending(GameState.hire_staff(staff_id), _show_staff)


func _on_profile_upgrade(role: String) -> void:
	_staff_profile_panel.close()
	_after_spending(GameState.upgrade_staff(role), _show_staff)


## Firing is permanent and costs a severance, so it asks first — same
## confirm-overlay pattern as _confirm_new_game().
func _confirm_fire_staff(role: String, candidate: Dictionary) -> void:
	_staff_profile_panel.close()
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
	rows.append(UiKit.line(Text.say("office.levels_blurb")))

	# Drafting your own bill (patron step 7).
	var draft_button := UiKit.action_button(Text.say("draft.button"), "", _open_draft.bind(true), 100.0)
	draft_button.name = "DraftBillButton"
	rows.append(draft_button)

	# Organizations asking the player to carry a bill sit first (patron step 4).
	var shown := GameState.patron_requests_shown()
	if not shown.is_empty():
		rows.append(UiKit.heading(Text.say("office.requests_heading")))
		rows.append(UiKit.line(Text.say("office.requests_hint"), "SmallLabel"))
		for patron_id: String in shown:
			rows.append(_request_row(patron_id))

	# Special levels that have come due sit above everything else.
	var due_rows := GameState.due_special_level_rows()
	if not due_rows.is_empty():
		rows.append(UiKit.heading(Text.say("office.special_levels_heading")))
		for special: Dictionary in due_rows:
			rows.append(_level_row(special))

	var by_tier := {}
	for level: Dictionary in DataDB.levels:
		# Special levels are listed above, and only once due.
		if SpecialLevels.is_special(level):
			continue
		# A "One-Time (Yes/No)" level (levels.json's own "one_time" column)
		# that has already been completed — win or loss — is left out of the
		# list entirely, not shown-but-disabled like a locked or cooling-
		# down one: Cameron's own request was that it disappear outright.
		# Independent of "level_gating_enabled" below, which only gates
		# cost/cooldown, not this.
		if Ledger.level_is_hidden(level, GameState.level_last_completed_at):
			continue
		# A level only an event can reveal ("Needs Discovery") stays out of sight until then.
		if not GameState.is_level_discovered(level):
			continue
		var tier := int(level.get("tier", 0))
		if not by_tier.has(tier):
			by_tier[tier] = []
		by_tier[tier].append(level)

	var tiers: Array = by_tier.keys()
	tiers.sort()
	for tier: int in tiers:
		rows.append(UiKit.heading(Text.say("office.tier_heading", {"tier": tier})))
		for level: Dictionary in by_tier[tier]:
			rows.append(_level_row(level))

	_levels_panel.open(Text.say("office.levels_title"), rows)


## One request in the Requests block: the organization's icon and a button.
func _request_row(patron_bill_id: String) -> Control:
	var row := PatronLevel.patron_bill(patron_bill_id)
	var org := str(row.get("organization", ""))
	var composed := PatronLevel.compose(patron_bill_id, GameState.enacted_components)
	var button := UiKit.action_button(Text.say("request.row", {
			"org": str(DataDB.get_booster(org).get("name_en", org)),
			"bill": str((composed["bill"] as Dictionary).get("bill_name", ""))}), "",
			_open_request.bind(patron_bill_id, "", ""), 100.0)
	button.name = "Request_" + patron_bill_id
	return _with_booster_icon(org, button)


## The Request panel: what is asked, what the vote looks like, the rewards,
## and the three answers. `replace`/`with_id` is an Amend swap being previewed.
func _open_request(patron_bill_id: String, replace: String, with_id: String) -> void:
	_request_replace = replace
	_request_with = with_id
	var row := PatronLevel.patron_bill(patron_bill_id)
	var org := str(row.get("organization", ""))
	var org_name := str(DataDB.get_booster(org).get("name_en", org))
	var ally := str(row.get("ally", "")) if row.get("ally") != null else ""
	var composed := PatronLevel.compose(patron_bill_id, GameState.enacted_components, replace, with_id)
	if not bool(composed["ok"]):
		return
	var bill: Dictionary = composed["bill"]
	var rows: Array[Control] = []
	rows.append(UiKit.line(Text.say("request.line", {"org": org_name, "bill": str(bill.get("bill_name", ""))})))
	rows.append(UiKit.line(RequestLines.default_vote_line(bill)))
	rows.append(UiKit.line(Text.say("request.influence_needed"), "SmallLabel"))
	var own := RequestLines.own_party_line(bill, str(DataDB.player.get("party", "")))
	if not own.is_empty():
		rows.append(UiKit.line(own))
	var reward_chips := RequestLines.reward_entries(row, ally, bool(composed["amended"]))
	if not reward_chips.is_empty():
		rows.append(UiKit.line(Text.say("request.reward_heading")))
		rows.append(OrgChip.row(reward_chips, true))
	if bool(composed["amended"]):
		rows.append(UiKit.line(Text.say("request.amended", {"percent": int(DataDB.balance.get("patron_amend_reward_percent", 75))}), "SmallLabel"))

	var accept := UiKit.action_button(Text.say("request.accept"), "", _on_request_accept.bind(patron_bill_id), 110.0)
	accept.name = "RequestAcceptButton"
	rows.append(accept)

	var live := row.duplicate()
	live["components"] = PatronLevel.compose(patron_bill_id, GameState.enacted_components)["component_ids"]
	var options := PatronRequests.amend_options(live, ComposedBill.index(DataDB.bill_components), GameState.enacted_components)
	if not options.is_empty() and replace.is_empty():
		rows.append(UiKit.heading(Text.say("request.amend_title")))
		rows.append(UiKit.line(Text.say("request.amend_note", {"percent": int(DataDB.balance.get("patron_amend_reward_percent", 75))}), "SmallLabel"))
		var by_id := ComposedBill.index(DataDB.bill_components)
		for option: Dictionary in options:
			var swap := UiKit.action_button(Text.say("request.amend_option", {
				"old": str((by_id.get(option["replace"], {}) as Dictionary).get("short_label", option["replace"])),
				"new": str((by_id.get(option["with"], {}) as Dictionary).get("short_label", option["with"]))}), "",
				_open_request.bind(patron_bill_id, str(option["replace"]), str(option["with"])), 90.0)
			swap.name = "RequestAmend_" + str(option["with"])
			rows.append(swap)
	elif not replace.is_empty():
		var undo := UiKit.action_button(Text.say("request.amend_undo"), "", _open_request.bind(patron_bill_id, "", ""), 90.0)
		undo.name = "RequestAmendUndoButton"
		rows.append(undo)

	var decline := UiKit.action_button(Text.say("request.decline", {"count": PatronRequests.decline_cost(
		str(row.get("kind", PatronRequests.FAVOR)), DataDB.balance), "org": org_name}), "",
		_on_request_decline.bind(patron_bill_id), 90.0)
	decline.name = "RequestDeclineButton"
	rows.append(decline)
	_request_panel.open(Text.say("request.title"), rows)


## Draft a Bill: the chosen parts, a preview of the bill, the Draft button,
## then the organizations to take parts from (and one organization's parts
## when it is open). `fresh` starts over with nothing chosen.
func _open_draft(fresh: bool = false) -> void:
	if fresh:
		_draft_ids = []
		_draft_org = ""
	var by_id := ComposedBill.index(DataDB.bill_components)
	var rows: Array[Control] = []
	rows.append(UiKit.line(Text.say("draft.intro", {
		"xp": int(DataDB.balance.get("draft_bill_cost_xp", 350)),
		"funds": Phrase.with_separators(int(DataDB.balance.get("draft_bill_cost_funds", 300000)))})))

	rows.append(UiKit.heading(Text.say("draft.parts_heading")))
	if _draft_ids.is_empty():
		rows.append(UiKit.line(Text.say("draft.no_parts"), "SmallLabel"))
	for id: Variant in _draft_ids:
		var part: Dictionary = by_id.get(str(id), {})
		var remove := UiKit.action_button(Text.say("draft.part_selected", {
			"label": str(part.get("short_label", id)), "phrase": str(part.get("phrase", ""))}), "",
			_draft_toggle.bind(str(id)), 90.0)
		remove.name = "DraftRemove_" + str(id)
		rows.append(remove)

	if _draft_ids.size() >= DraftBill.MIN_PARTS:
		var bill := DraftBill.bill_for(_draft_ids)
		rows.append(UiKit.line(RequestLines.default_vote_line(bill)))
		rows.append(UiKit.line(Text.say("request.influence_needed"), "SmallLabel"))
		var own := RequestLines.own_party_line(bill, str(DataDB.player.get("party", "")))
		if not own.is_empty():
			rows.append(UiKit.line(own))
		rows.append(UiKit.line(Text.say("draft.effects_heading"), "SmallLabel"))
		var draft_chips: Array = []
		for effect: Dictionary in (bill.get("effects", []) as Array):
			var org_id := str(effect.get("target", ""))
			if DataDB.get_booster(org_id).is_empty():
				continue
			draft_chips.append({"id": org_id, "delta": int(effect.get("delta", 0))})
		if not draft_chips.is_empty():
			rows.append(OrgChip.row(OrgChip.merged(draft_chips), true))
	var go := UiKit.action_button(Text.say("draft.go"), GameState.draft_refusal(_draft_ids), _on_draft_go, 110.0)
	go.name = "DraftGoButton"
	rows.append(go)

	if _draft_org.is_empty():
		rows.append(UiKit.heading(Text.say("draft.orgs_heading")))
		var owners := {}
		for component: Dictionary in DataDB.bill_components:
			owners[str(component.get("owner", ""))] = true
		var org_ids: Array = owners.keys()
		org_ids.sort_custom(func(a: String, b: String) -> bool:
			return int(GameState.booster_standing.get(a, 0)) > int(GameState.booster_standing.get(b, 0)))
		for org_id: String in org_ids:
			var button := UiKit.action_button(Text.say("draft.org_row", {
				"org": str(DataDB.get_booster(org_id).get("name_en", org_id)),
				"standing": int(GameState.booster_standing.get(org_id, 0))}), "",
				_draft_open_org.bind(org_id), 90.0)
			button.name = "DraftOrg_" + org_id
			rows.append(_with_booster_icon(org_id, button))
	else:
		var back := UiKit.action_button(Text.say("draft.back_to_orgs"), "", _draft_open_org.bind(""), 90.0)
		back.name = "DraftOrgsBack"
		rows.append(back)
		rows.append(UiKit.heading(str(DataDB.get_booster(_draft_org).get("name_en", _draft_org))))
		for component: Dictionary in DataDB.bill_components:
			if str(component.get("owner", "")) != _draft_org:
				continue
			var id := str(component.get("component_id", ""))
			var chosen := _draft_ids.has(id)
			var part_button := UiKit.action_button(Text.say(
				"draft.part_chosen" if chosen else "draft.part_row", {
					"label": str(component.get("short_label", id)), "phrase": str(component.get("phrase", ""))}), "",
				_draft_toggle.bind(id), 90.0)
			part_button.name = "DraftPart_" + id
			rows.append(part_button)
	_draft_panel.open(Text.say("draft.title"), rows)


func _draft_open_org(org_id: String) -> void:
	_draft_org = org_id
	_open_draft()


## Takes a part in or out of the draft (three at most).
func _draft_toggle(component_id: String) -> void:
	if _draft_ids.has(component_id):
		_draft_ids.erase(component_id)
	elif _draft_ids.size() < DraftBill.MAX_PARTS:
		_draft_ids.append(component_id)
	_open_draft()


func _on_draft_go() -> void:
	if not GameState.start_draft(_draft_ids):
		_report.text = Text.say("draft.cannot_start")
		_draft_panel.close()
		return
	_draft_panel.close()
	_levels_panel.close()
	get_tree().change_scene_to_file(StageRouting.LEVEL_INTRO_SCENE)


func _on_request_accept(patron_bill_id: String) -> void:
	if not GameState.start_patron_level(patron_bill_id, _request_replace, _request_with):
		_request_panel.close()
		_report.text = Text.say("request.cannot_start")
		return
	_request_panel.close()
	_levels_panel.close()
	get_tree().change_scene_to_file(StageRouting.LEVEL_INTRO_SCENE)


func _on_request_decline(patron_bill_id: String) -> void:
	GameState.decline_patron_bill(patron_bill_id)
	_request_panel.close()
	_show_levels()
	_refresh_resources()


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

	# The calendar comes first: a weekend takes only weekend levels that fit,
	# and a finished work week takes none.
	var calendar_refusal := GameState.level_calendar_refusal(level)
	if not calendar_refusal.is_empty():
		button.text = calendar_refusal
		button.disabled = true
		box.add_child(button)
		return box

	# A locked or cooling-down level is SHOWN, not hidden — the same choice
	# the card and Staff shops make: a player should see what is coming, not
	# have it quietly vanish. Nothing below runs while rules.json's
	# "level_gating_enabled" is off, which is today's default, so a plain
	# "Look it over" is what every existing playtest still sees.
	if DataDB.get_rule("level_gating_enabled", false):
		var level_id := str(level.get("level_id", ""))
		var cooldown := Ledger.level_cooldown_remaining(
			level, GameState.time_units, GameState.level_cleared_units)

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
		_report.text = Text.say("office.level_cannot_start", {"problems": "\n• ".join(Array(runner.problems()))})
		return

	var rows: Array[Control] = []
	var stages: Array = expanded.get("stages", [])
	var anything_set := false

	# A level about a bill says whose bill it is and who is for and against it.
	for bill_line: String in StanceLines.briefing_lines(DataDB.get_floor_vote(str(_chosen_level.get("level_id", "")))):
		rows.append(UiKit.line(bill_line, "SmallLabel"))
	rows.append_array(StanceLines.briefing_sides(DataDB.get_floor_vote(str(_chosen_level.get("level_id", "")))))

	for stage: Dictionary in stages:
		if not _reveal_in_briefing(stage):
			# A stage marked "No" (Media Ambush, an ambush by name) is left
			# out of the briefing entirely — 2026-09-28, Cameron: no heading,
			# no rewards, no "if you lose" line, nothing that gives away it
			# is even there. An earlier pass still showed its win/loss
			# numbers so the player could weigh the risk; this replaces that
			# with a real, total surprise instead.
			continue

		rows.append(UiKit.heading(str(stage.get("name_en", Text.say("briefing.stage_fallback")))))
		var who := _opponents_line(stage)
		if not who.is_empty():
			rows.append(UiKit.line(who, "SmallLabel"))
		if str(stage.get("mode", "")) == "Combat":
			rows.append(UiKit.line(Text.say("briefing.loss_ends_level"
				if LevelRunner.loss_ends_level(stage) else "briefing.loss_continues"), "SmallLabel"))
		for between: String in CarryOverLines.for_stage(stage):
			rows.append(UiKit.line(between, "SmallLabel"))

		if LevelRunner.rewards_are_unset(stage):
			rows.append(UiKit.line(Text.say("reward.stage_not_set"), "SmallLabel"))
		else:
			anything_set = true
			for name: String in LevelRunner.win_rewards(stage).keys():
				rows.append(UiKit.line(Text.say("reward.delta", {
					"name": name,
					"amount": Phrase.meta_amount(name, int(LevelRunner.win_rewards(stage)[name]), true),
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

	var briefing_title := str(_chosen_level.get("description", "")).strip_edges()
	_briefing_panel.open(
		briefing_title if not briefing_title.is_empty() else Text.say("office.briefing_fallback_title"),
		rows, Text.say("office.go_in"))


## "If you lose: Party support -2, Reputation -1, 1 XP" — or "" for a stage
## whose loss columns are all blank.
func _loss_line(stage: Dictionary) -> String:
	var parts: Array[String] = []
	var penalties := LevelRunner.loss_penalties(stage)
	for name: String in penalties.keys():
		parts.append(Text.say("reward.delta", {"name": name, "amount": Phrase.meta_amount(name, int(penalties[name]), true)}))
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
		return Text.say("briefing.reporters_ask") if not stage.get(
			"questions", []).is_empty() else ""
	if names.size() == 1:
		return Text.say("briefing.against_one", {"name": names[0]})
	return Text.say("briefing.against_many", {
		"names": ", ".join(names.slice(0, -1)), "last": names[-1]})


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
		_report.text = Text.say("office.level_cannot_start", {"problems": "\n• ".join(Array(runner.problems()))})
		return

	# The runner is handed over rather than rebuilt, so the level keeps its
	# place and its carried buffs as the battle screen moves through it.
	GameState.begin_level(runner)

	# A hired staff member with a written line for this level gets one beat
	# to say it before the level begins (2026-09-27) — skipped entirely when
	# nobody has anything to say, so a level with no intro content plays
	# exactly as it always has. A level that names a Floor Vote bill always
	# gets this beat too (2026-10-01), even with nothing staff has to say,
	# since that's also where the bill-lean choice lives.
	var level_id := str(runner.level.get("level_id", ""))
	var cues := LevelIntroCues.resolve(DataDB.level_intros, level_id,
		GameState.staff_hired, DataDB.staff)
	var has_bill := not DataDB.get_floor_vote(level_id).is_empty()
	if cues.is_empty() and not has_bill:
		get_tree().change_scene_to_file(StageRouting.scene_for(runner.current_stage()))
	else:
		get_tree().change_scene_to_file(StageRouting.LEVEL_INTRO_SCENE)
