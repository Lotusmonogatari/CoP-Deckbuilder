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
var _standing_panel: Overlay = null
@onready var _briefing_panel: LevelBriefingPanel = %BriefingPanel
@onready var _levels_panel: Overlay = %LevelsPanel

## The level the player is looking at, chosen on the levels screen.
var _chosen_level: Dictionary = {}
## Two offices (2026-11-20): the trip button under "Choose a level", and the popup that states a trip's cost first.
var _travel_button: TravelStrip
var _travel_page_panel: Overlay
var _travel_panel: Overlay
var _travel_card: TravelCard
## The mode the strip is set to (the rail pass or a paid ticket: both are pulled), and the mode the popup is about.
var _strip_mode: String = Travel.PASS
var _popup_mode: String = Travel.PASS
var _travel_modes_row: HBoxContainer
## A mixed level waiting on an encounter on the train before it begins (the encounter is shown first).
var _start_after_encounter := false
var _encounter_cleared := false
## How a level's built-in trips are priced in the briefing (the member's rail pass until tickets exist).
var _travel_mode: String = Travel.PASS
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
var _characters_panel: Overlay
var _character_detail_panel: Overlay
var _characters: CharacterCodexPanel

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
## Front and back of one card, opened from the deck screen's View button.
var _card_look_panel: Overlay

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
## The Party Dues / Office Funds box beside the calendar (2026-10-28).
var _dues_box: PanelContainer
## Promises owed (2026-10-31): a button above the dues box, shown only while
## something is owed, that opens the Promises panel.
var _promises_button: Button
var _promises_panel: Overlay
## Set when the briefing's Go In button was pressed (see _on_briefing_closed).
var _briefing_went_in := false
## An event choice waiting on its level's briefing (2026-10-31): Go in takes
## the choice and starts the level; Back returns to the event, nothing taken.
## {event_id, letter, arrived}, or {} when the briefing came from the list.
var _event_launch := {}
## The picture chosen for each event as it was shown, reused on its result screen.
var _event_pictures: Dictionary = {}
## The biggest a staff picture is drawn on the profile, and the gap above it.
const STAFF_PORTRAIT_MAX := Vector2(480, 860)
const STAFF_TOP_GAP := 88.0
var _election_panel: Overlay
var _events_button: Button
var _events_panel: Overlay
var _event_panel: Overlay
## The Marketplace tab showing: Items.PERSONAL or Items.OFFICE_INVENTORY.
var _market_tab := Items.PERSONAL
var _gathering_panel: Overlay
var _hosted_panel: HostedEventPanel
var _week_confirm_panel: Overlay
var _week_over_panel: Overlay
## The End of Week Payments breakdown a tap on the Office box opens (P9, 2026-11-17).
var _payments_panel: Overlay
## Looks once a second for a work week that ran out of hours without the choice
## showing (2026-11-02), whichever way the hours were spent.
var _week_watch: Timer
## True while _build() runs, so the watch does not open a pop-up under its feet.
var _building := false
var _new_week_panel: Overlay
var _draft_ids: Array = []
## The draft adds a second member visit (2026-11-05).
var _draft_extra_visit := false
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

## The Staff Assignments screen (Cameron, 2026-11-16), the pop-up that explains
## one task icon, and the report of the day just ended. Built before the staff
## profile so the profile, opened from a card, draws on top of them.
var _assignments_panel: Overlay
var _task_popup_panel: Overlay
var _delegate_panel: Overlay
var _staff_report_panel: Overlay

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
	_apply_ui_style_veils()
	# The picture under everything: BASE_OFFICE.png, else BASE.png (2026-10-31).
	BaseImage.install(self, "OFFICE")
	_background.kind = PlaceholderArt.Kind.BACKGROUND
	_apply_office_look()
	_build_travel()

	_start_button.pressed.connect(_on_start_pressed)
	_briefing_panel.confirmed.connect(_on_start)
	_briefing_panel.closed.connect(_on_briefing_closed)
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
	_assignments_panel = Overlay.new()
	_assignments_panel.name = "AssignmentsPanel"
	add_child(_assignments_panel)
	_task_popup_panel = Overlay.new()
	_task_popup_panel.name = "TaskPopupPanel"
	add_child(_task_popup_panel)
	_staff_report_panel = Overlay.new()
	_staff_report_panel.name = "StaffReportPanel"
	add_child(_staff_report_panel)
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
	_card_look_panel = Overlay.new()
	_card_look_panel.name = "CardLookPanel"
	add_child(_card_look_panel)
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
	# The portrait gives way when the screen is short or the text is big, so the calendar,
	# dues box and buttons never land on the text or off the bottom (panel P3, 2026-11-17).
	_portrait_behind = PortraitBehind.attach(self, _portrait, $Safe)
	var office_column := get_node_or_null("Safe/Scroll/Column") as Control
	var office_scroll := get_node_or_null("Safe/Scroll") as ScrollContainer
	if office_scroll != null:
		DragScroll.attach(office_scroll)
		office_scroll.resized.connect(_fit_portrait.call_deferred)
	if office_column != null:
		office_column.minimum_size_changed.connect(_fit_portrait.call_deferred)
		office_column.resized.connect(_fit_portrait.call_deferred)
		_fit_portrait.call_deferred()

	# No save to come back to: a new player chooses who they are first.
	if GameState.awaiting_new_game:
		_resume_new_game = ""
		_show_new_game(true)
	elif not _resume_new_game.is_empty():
		var first := _resume_new_game == "first"
		_resume_new_game = ""
		_show_new_game.call_deferred(first)
	else:
		SaveManager.autosave()
		# A Rhetoric Training draw left on screen when the app closed comes
		# straight back, same card, same count — quitting is not a reroll.
		if not GameState.card_draw.is_empty():
			_show_rhetoric_training()
			_show_card_offer()


## The portrait keeps its drawn size (PortraitBehind): when the screen is short or the text is
## big the column squeezes the portrait's slot and the text lies over the lower part of the
## picture. The slot never goes below the floor (panel P3, 2026-11-17).
var _portrait_behind: PortraitBehind
const PORTRAIT_SLOT_FLOOR := 200.0
## What the compact calendar and dues boxes save on the bottom stack (170 px down to 100 px).
const COMPACT_SAVES := 70.0
var _compact := false


## The front page fits itself in three steps: the portrait's slot shrinks to its floor (the
## picture stays full size, behind the text); then the calendar and the dues box turn compact
## (the calendar drops its weekday row, both boxes are 100 px tall); then, only if it is still
## too tall, the page scrolls (the Scroll box in the scene). At 1080 x 2340 and Normal text
## nothing changes.
func _fit_portrait() -> void:
	var scroll := get_node_or_null("Safe/Scroll") as ScrollContainer
	var column := get_node_or_null("Safe/Scroll/Column") as Control
	if scroll == null or column == null or _portrait_behind == null:
		return
	var slot := _portrait_behind.slot
	var others := column.get_combined_minimum_size().y - slot.custom_minimum_size.y
	var room := scroll.size.y - others
	if not _compact and room < PORTRAIT_SLOT_FLOOR:
		_set_compact(true)
		others = column.get_combined_minimum_size().y - slot.custom_minimum_size.y
		room = scroll.size.y - others
	elif _compact and room >= PORTRAIT_SLOT_FLOOR + COMPACT_SAVES + 20.0:
		_set_compact(false)
		others = column.get_combined_minimum_size().y - slot.custom_minimum_size.y
		room = scroll.size.y - others
	var want := clampf(room, PORTRAIT_SLOT_FLOOR, _portrait_behind.full_height)
	if absf(want - slot.custom_minimum_size.y) > 1.0:
		slot.custom_minimum_size.y = want
	# The Promises button sits above whatever height the dues box really has at this text size.
	if _dues_box != null and _promises_button != null:
		var dues_height := maxf(_dues_box.custom_minimum_size.y, _dues_box.get_combined_minimum_size().y)
		_pin_promises_above_dues(dues_height)
		var spacer := get_node_or_null("Safe/Scroll/Column/VSpacer") as Control
		if spacer != null:
			spacer.custom_minimum_size.y = dues_height + 16.0 + 90.0 + 8.0


func _set_compact(on: bool) -> void:
	_compact = on
	CalendarSquare.set_compact(_calendar_square, on)
	DuesBox.set_compact(_dues_box, on)
	var spacer := get_node_or_null("Safe/Scroll/Column/VSpacer") as Control
	if spacer != null and _dues_box != null:
		spacer.custom_minimum_size.y = _dues_box.custom_minimum_size.y + 16.0 + 90.0 + 8.0
		_pin_promises_above_dues(_dues_box.custom_minimum_size.y)


## The Promises button's corner spot, just above the dues box. It belongs to the button only while it
## still sits in the spacer. Broadcast and Woodblock move it into a grid tile and Living Office onto a
## pin in the room; there the container places it, and writing its bottom offset here would push the
## tile up over the payments box (the 2026-11-18 playtest: fine on the first view, out of place after
## buying the Funds cap increase, because that return re-fits the page).
func _pin_promises_above_dues(dues_height: float) -> void:
	if _promises_button == null:
		return
	var spacer := get_node_or_null("Safe/Scroll/Column/VSpacer")
	if spacer == null or _promises_button.get_parent() != spacer:
		return
	_promises_button.offset_bottom = -(dues_height + 16.0)


func _process(delta: float) -> void:
	if _ticker != null:
		_ticker.advance(delta)


## Living Office: the menu's five destinations become pins in the room (RoomObjects). The Start
## button becomes the paper docket card. Does nothing in the other styles.
func _install_room_objects() -> void:
	if UiStyle.current() != UiStyles.LIVING_OFFICE:
		# Broadcast and Woodblock arrange the same buttons as tiles (OfficeLayouts).
		OfficeLayouts.install(self, {"start": _start_button, "events": _events_button, "promises": _promises_button,
			"staff": _management_button, "marketplace": find_child("InventoryButton", true, false) as Button,
			"results": _reputation_button, "admin": find_child("AdministrationButton", true, false) as Button})
		_dress_docket()
		return
	RoomObjects.install(self, {
		"events": _events_button, "results": _reputation_button, "promises": _promises_button,
		"staff": _management_button, "marketplace": find_child("InventoryButton", true, false) as Button})
	var paper := UiStyle.colour("paper", Color(1, 0.97, 0.92))
	var ink := UiStyle.colour("ink_on_paper", Color(0.17, 0.11, 0.07))
	var card := StyleBoxFlat.new()
	card.bg_color = paper
	card.set_corner_radius_all(26)
	card.set_content_margin_all(18)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		_start_button.add_theme_stylebox_override(state, card)
	var card_dim := card.duplicate() as StyleBoxFlat
	card_dim.bg_color = Color(paper.r, paper.g, paper.b, 0.6)
	_start_button.add_theme_stylebox_override("disabled", card_dim)
	_start_button.add_theme_color_override("font_disabled_color", Color(ink.r, ink.g, ink.b, 0.75))
	_dress_docket()
	for colour: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_start_button.add_theme_color_override(colour, ink)


## The Start button as a docket card (P9 review): its title, a second line saying how many hours are
## left this week, and a mark (a folder and a chevron in Living Office, a chevron in Broadcast, a red
## seal in Woodblock). The button, its name and its handler are the same in every style.
func _dress_docket() -> void:
	if _start_button.has_node("DocketHours"):
		(_start_button.get_node("DocketHours") as Label).text = Text.say("office.docket_hours", {"count": GameState.work_hours_left()})
		return
	var style := UiStyle.current()
	_start_button.custom_minimum_size.y = 160.0
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var box := _start_button.get_theme_stylebox(state)
		if box is StyleBoxFlat:
			var padded := (box as StyleBoxFlat).duplicate() as StyleBoxFlat
			padded.content_margin_top = 14.0
			padded.content_margin_bottom = 56.0
			padded.content_margin_left = 130.0 if style == UiStyles.LIVING_OFFICE else 40.0
			padded.content_margin_right = 130.0 if style != UiStyles.BROADCAST else 110.0
			_start_button.add_theme_stylebox_override(state, padded)
	var sub := Label.new()
	sub.name = "DocketHours"
	sub.theme_type_variation = &"SmallLabel"
	sub.text = Text.say("office.docket_hours", {"count": GameState.work_hours_left()})
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sub.offset_top = -58.0
	sub.offset_bottom = -12.0
	sub.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	var ink: Color
	match style:
		UiStyles.LIVING_OFFICE: ink = UiStyle.colour("ink_on_paper", Color(0.17, 0.11, 0.07))
		UiStyles.BROADCAST: ink = UiStyle.colour("ground", Color(0.04, 0.07, 0.12))
		_: ink = UiStyle.colour("paper", Color(0.97, 0.94, 0.88))
	sub.add_theme_color_override("font_color", ink)
	_start_button.add_child(sub)
	match style:
		UiStyles.LIVING_OFFICE:
			var icon := StyleMarks.make(StyleMarks.Kind.FOLDER, UiStyle.colour("paper", Color(1, 0.97, 0.92)), Vector2(84, 84),
				UiStyle.colour("ink_on_paper", Color(0.17, 0.11, 0.07)))
			icon.set_anchors_preset(Control.PRESET_CENTER_LEFT)
			icon.offset_left = 24.0
			icon.offset_right = 24.0 + 84.0
			icon.offset_top = -42.0
			icon.offset_bottom = 42.0
			_start_button.add_child(icon)
			_add_chevron(UiStyle.colour("ink_on_paper", Color(0.17, 0.11, 0.07)))
		UiStyles.BROADCAST:
			_add_chevron(UiStyle.colour("ground", Color(0.04, 0.07, 0.12)))
		UiStyles.WOODBLOCK:
			var seal := StyleMarks.make(StyleMarks.Kind.SEAL, UiStyle.colour("paper", Color(0.97, 0.94, 0.88)), Vector2(96, 96),
				UiStyle.colour("vermilion", Color(0.76, 0.23, 0.13)), "行")
			seal.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
			seal.offset_left = -120.0
			seal.offset_right = -24.0
			seal.offset_top = -56.0
			seal.offset_bottom = 40.0
			_start_button.add_child(seal)


func _add_chevron(colour: Color) -> void:
	var chevron := StyleMarks.make(StyleMarks.Kind.CHEVRON, colour, Vector2(70, 70))
	chevron.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	chevron.offset_left = -96.0
	chevron.offset_right = -26.0
	chevron.offset_top = -50.0
	chevron.offset_bottom = 20.0
	_start_button.add_child(chevron)


func _build() -> void:
	_building = true
	# Woodblock: a wave band along the foot of the Office, above the news ticker (P9 review).
	StyleMarks.add_wave_band(self, 64.0, 56.0)
	StyleMarks.add_print_frame(_portrait)
	GameState.staff_day_sync()   # a staff day that has ended is settled before the screen draws
	GameState.staff_ensure_day()  # and today's tasks are delivered, whether or not anyone is hired
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
		PartyLabel.apply(_title_party, DataDB.get_party(party))
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
	_report.text = _report_text()
	_refresh_resources()
	_refresh_calendar()
	_show_trigger_alerts_if_any()
	_show_broken_promises_if_any()
	_show_resume_choice_if_in_level()
	if not _show_followup_if_due() and not _show_dated_event_if_due():
		_show_random_event_if_due()
	_show_week_over_if_due()
	_show_forced_special_if_due()
	_install_room_objects()
	_building = false
	_maybe_show_staff_report.call_deferred()


# ---------------------------------------------------------------------------
# The week (2026-10-23, Cameron): a gold calendar square in the unused lower
# space, a button on Friday to end the work week early, a weekend that is
# optional, and "Pay Party Dues and Go Home" to end the week.

func _build_week_controls() -> void:
	var spacer := get_node_or_null("Safe/Scroll/Column/VSpacer")
	if spacer != null:
		_calendar_square = CalendarSquare.make()
		spacer.add_child(_calendar_square)
		_dues_box = DuesBox.make(_show_week_payments)
		spacer.add_child(_dues_box)
		# The calendar and the dues stack sit in this space: it never shrinks below them.
		spacer.custom_minimum_size.y = DuesBox.SIZE.y + 16.0 + 90.0 + 8.0
		_promises_button = Button.new()
		_promises_button.name = "PromisesButton"
		_promises_button.custom_minimum_size = Vector2(DuesBox.SIZE.x, 90)
		_promises_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		_promises_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
		_promises_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		_promises_button.offset_bottom = -(DuesBox.SIZE.y + 16)
		_promises_button.pressed.connect(_show_promises)
		spacer.add_child(_promises_button)

	_week_button = Button.new()
	_week_button.name = "WeekButton"
	_week_button.custom_minimum_size = Vector2(0, 100)
	_week_button.pressed.connect(_on_week_button_pressed)
	_start_button.get_parent().add_child(_week_button)
	_start_button.get_parent().move_child(_week_button, _start_button.get_index() + 1)

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
	_promises_panel = Overlay.new()
	_promises_panel.name = "PromisesPanel"
	add_child(_promises_panel)

	_event_panel = Overlay.new()
	_event_panel.name = "EventPanel"
	# Once an event is on screen the only way on is a choice.
	_event_panel.dismissable = false
	_event_panel.show_back = false
	add_child(_event_panel)
	# Who goes (Cameron, 2026-11-16) opens from an event choice, so it draws above the event.
	_delegate_panel = Overlay.new()
	_delegate_panel.name = "DelegatePanel"
	add_child(_delegate_panel)

	_week_confirm_panel = Overlay.new()
	_week_confirm_panel.name = "WeekConfirmPanel"
	add_child(_week_confirm_panel)
	_week_confirm_panel.confirmed.connect(_on_end_work_week_confirmed)
	_payments_panel = Overlay.new()
	_payments_panel.name = "PaymentsPanel"
	add_child(_payments_panel)
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
	_week_watch = Timer.new()
	_week_watch.name = "WeekWatch"
	_week_watch.wait_time = 1.0
	_week_watch.autostart = true
	_week_watch.timeout.connect(_check_week_over)
	add_child(_week_watch)


## The square's two rows, and the one week button that fits today: "End the
## Work Week" on a Friday with hours left, "Pay Party Dues and Go Home" in
## the weekend, nothing otherwise (and nothing mid-level).
func _refresh_calendar() -> void:
	_refresh_travel()
	CalendarSquare.refresh(_calendar_square)
	DuesBox.refresh(_dues_box)
	if _promises_button != null:
		_promises_button.visible = not GameState.promises.is_empty()
		_promises_button.text = Text.say("office.promises", {"count": GameState.promises.size()})
	if _week_button == null:
		return
	var mid_level := GameState.is_in_level()
	if GameState.in_weekend():
		_week_button.text = Text.say("office.go_home")
		_week_button.visible = not mid_level
	elif GameState.work_week_is_full():
		# No hours left: the choice (weekend or home) stays one tap away even if
		# its pop-up was missed (2026-11-02).
		_week_button.text = Text.say("office.week_over_button")
		_week_button.visible = not mid_level
	elif GameState.can_end_work_week_early():
		_week_button.text = Text.say("office.end_work_week")
		_week_button.visible = not mid_level
	else:
		_week_button.visible = false
	# The dues themselves are always on show in the Party Dues box beside the
	# calendar; the Friday line that repeated them is gone (2026-10-30).


func _on_week_button_pressed() -> void:
	if GameState.in_weekend():
		_go_home()
		return
	if GameState.work_week_is_full():
		_show_week_over_if_due()
		return
	var rows: Array[Control] = [UiKit.line(Text.say("office.end_work_week_body",
		{"hours": GameState.work_hours_left(), "count": GameState.work_hours_left()}))]
	_week_confirm_panel.open(Text.say("office.end_work_week_title"), rows,
		Text.say("office.end_work_week_yes"))


func _on_end_work_week_confirmed() -> void:
	GameState.end_work_week()
	SaveManager.autosave()
	_build()


## The watch: a work week with no hours left and nothing showing the choice.
## Hours are spent in many places (a stage, a tour, an event, a promise kept) and
## only some of them rebuild the Office afterwards, so on one Friday the hours hit
## zero and neither the pop-up nor a button appeared until the game was reloaded
## (2026-11-02, Cameron). Waits while any other pop-up is open.
func _check_week_over() -> void:
	if _building or _week_over_panel.visible or GameState.is_in_level() or not GameState.work_week_is_full():
		return
	for child in get_children():
		if child is Overlay and child != _week_over_panel and (child as Overlay).visible:
			return
	_refresh_calendar()
	_show_week_over_if_due()


## The work week ran out of hours: the player chooses the weekend or home.
## The two translucent veils behind the title and the narration take the equipped UI style's
## plate colour (P9, 2026-11-17), so the text on them keeps its contrast in every style.
func _apply_ui_style_veils() -> void:
	var plate := UiStyle.plate_colour()
	var style := UiStyle.current()
	var heading: Control = $Safe/Scroll/Column/HeadingBackdropMargin/HeadingBackdrop
	var narration: Control = $Safe/Scroll/Column/TextBackdropMargin/TextBackdrop
	for node: Control in [heading, narration]:
		var veil := node.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		# A light (Woodblock) plate over a dark picture needs more body than a dark one.
		veil.bg_color = Color(plate.r, plate.g, plate.b, 0.9 if style == UiStyles.WOODBLOCK else 0.6)
		match style:
			UiStyles.BROADCAST:
				# The name is a slanted lower-third with a gold rule; the narration a red "office" strip.
				if node == heading:
					veil.skew = Vector2(SlantBar.SLANT * 0.5, 0.0)
					veil.border_width_bottom = 4
					veil.border_color = UiStyle.colour("gold", Color(0.89, 0.7, 0.25))
					veil.bg_color = Color(plate.r, plate.g, plate.b, 0.92)
				else:
					veil.border_width_left = 12
					veil.border_color = UiStyle.colour("live_red", Color(0.76, 0.23, 0.13))
					veil.bg_color = Color(plate.r, plate.g, plate.b, 0.85)
			UiStyles.LIVING_OFFICE:
				# The narration is a speech bubble from the protagonist (P9 review): paper, dark ink, rounded,
				# with a tail pointing up at the portrait. The name stays a rounded plate.
				if node == narration:
					veil.bg_color = UiStyle.colour("paper", Color(1, 0.97, 0.92))
					veil.set_corner_radius_all(34)
					veil.set_content_margin_all(18)
					veil.shadow_color = Color(0, 0, 0, 0.3)
					veil.shadow_size = 8
					var ink := UiStyle.colour("ink_on_paper", Color(0.17, 0.11, 0.07))
					# Dark ink for every line in the bubble, including lines added after this runs (a theme on the
					# bubble reaches them; per-label overrides did not, and left light ink on paper).
					var ink_theme := Theme.new()
					for type_name: String in ["Label", "SmallLabel", "HeaderLabel", "TitleLabel", "JapaneseAccent"]:
						ink_theme.set_color("font_color", type_name, ink)
						ink_theme.set_stylebox("normal", type_name, StyleBoxEmpty.new())
					narration.theme = ink_theme
					if not narration.has_node("BubbleTail"):
						var tail := StyleMarks.make(StyleMarks.Kind.TAIL, Color.TRANSPARENT, Vector2.ZERO, veil.bg_color)
						tail.name = "BubbleTail"
						tail.set_anchors_preset(Control.PRESET_FULL_RECT)
						narration.add_child(tail)
			UiStyles.WOODBLOCK:
				# The name is a bordered cartouche with a red offset shadow; the narration a ruled print.
				veil.border_color = UiStyle.colour("ink", Color(0.11, 0.1, 0.09))
				veil.set_border_width_all(2)
				if node == heading:
					veil.shadow_color = UiStyle.colour("vermilion", Color(0.76, 0.23, 0.13))
					veil.shadow_offset = Vector2(8, 8)
					veil.shadow_size = 1
				else:
					veil.border_width_bottom = 5
					veil.border_color = UiStyle.colour("vermilion", Color(0.76, 0.23, 0.13))
		node.add_theme_stylebox_override("panel", veil)


func _show_week_over_if_due() -> void:
	if GameState.is_in_level() or not GameState.work_week_is_full():
		return
	var rows: Array[Control] = [UiKit.line(Text.say("office.week_over_body"))]
	rows.append_array(_week_cost_rows())
	var weekend := Button.new()
	weekend.name = "WorkWeekendButton"
	weekend.custom_minimum_size = Vector2(0, 110)
	weekend.text = Text.say("office.weekend_work")
	weekend.pressed.connect(_on_work_weekend)
	var home := Button.new()
	home.name = "GoHomeButton"
	home.custom_minimum_size = Vector2(0, 110)
	home.text = Text.say("office.go_home")
	home.pressed.connect(_go_home)
	# The pop-up card (P14, 2026-11-20): the payments scroll, the two ways on stay at the foot; going home is the filled one.
	var foot: Array[Control] = [weekend, home]
	_week_over_panel.open_card({"tag": Text.say("popup.tag_week_end"), "title": Text.say("office.week_over_title"), "body": rows,
		"buttons": foot, "primary": 1})


## What "Pay Party Dues and Go Home" will cost and pay, before the player chooses (Information
## Standard 1; panel P4, 2026-11-17). Every number comes from GameState.week_end_preview(),
## which uses the functions that settle the week, so the preview is the charge.
func _week_cost_rows() -> Array[Control]:
	var out: Array[Control] = []
	var preview := GameState.week_end_preview()
	var dues: Dictionary = preview["dues"]
	var staff: Dictionary = preview["staff"]
	var funds: Dictionary = preview["funds"]
	out.append(UiKit.heading(Text.say("office.week_cost_heading")))
	# The money lines are the End of Week Payments breakdown (WeekPaymentsView); what follows
	# explains the dues' parts and what unpaid dues cost.
	out.append_array(WeekPaymentsView.rows(preview))
	if int(dues["week_dues"]) > 0:
		out.append(UiKit.line(Text.say("office.week_cost_dues_parts", {"base": Phrase.with_separators(int(dues["base"])),
			"share": Phrase.with_separators(int(dues["share"])), "earned": Phrase.with_separators(int(dues["earned"]))}), "SmallLabel"))
	if int(dues["relief"]) > 0:
		out.append(UiKit.line(Text.say("office.week_cost_relief", {"yen": Phrase.with_separators(int(dues["relief"]))}), "SmallLabel"))
	if int(preview["short"]) > 0:
		var penalties: Dictionary = preview["penalties"]
		var hq := str(DataDB.get_booster(str(DataDB.get_rule("party_dues_hq_organization", ""))).get("name_en", ""))
		var selection := str(DataDB.get_booster(str(DataDB.get_rule("party_dues_selection_organization", ""))).get("name_en", ""))
		out.append(UiKit.line(Text.say("office.week_cost_short", {"yen": Phrase.with_separators(int(preview["short"]))})))
		out.append(UiKit.line(Text.say("office.week_cost_penalty", {"support": int(penalties["party_support"]), "hq": hq,
			"hq_n": int(penalties["hq"]), "selection": selection, "selection_n": int(penalties["selection"])}), "SmallLabel"))
		var withdrawn: Array = preview["withdrawn"]
		if not withdrawn.is_empty():
			out.append(UiKit.line(Text.say("office.week_cost_backings", {"names": ", ".join(PackedStringArray(withdrawn))}), "SmallLabel"))
	if int(staff["wages_missed"]) > 0:
		out.append(UiKit.line(Text.say("staff.week_warning", {"yen": int(staff["wages"])}), "SmallLabel"))
	out.append(UiKit.line(Text.say("office.week_cost_settle"), "SmallLabel"))
	return out


## The breakdown behind the Office's End of Week Payments box.
func _show_week_payments() -> void:
	Haptics.confirm()
	var rows := WeekPaymentsView.rows(GameState.week_end_preview(), false)
	_payments_panel.open(Text.say("office.week_payments_title"), rows)


func _on_work_weekend() -> void:
	_week_over_panel.close()
	GameState.end_work_week()
	SaveManager.autosave()
	_build()


## Ends the week: a cue popup on this same screen says a new week begins.
func _go_home() -> void:
	Haptics.confirm()
	_week_over_panel.close()
	_week_confirm_panel.close()
	var result := GameState.go_home()
	SaveManager.autosave()
	_build()
	var rows: Array[Control] = [UiKit.line(Text.say("office.new_week_body",
		{"date": str(result.get("date", ""))}))]
	rows.append_array(_dues_report_rows(result.get("dues", {})))
	rows.append_array(StaffAssignmentsView.report_rows(GameState.take_staff_report()))
	rows.append_array(StaffLoyaltyView.week_rows(result.get("staff", {})))
	for awareness_line: String in result.get("awareness", []):
		rows.append(UiKit.line(awareness_line, "SmallLabel"))
	_new_week_panel.open(Text.say("office.new_week_title"), rows, Text.say("office.new_week_go"))


# ---------------------------------------------------------------------------
# Events (2026-10-23, Cameron): arranged from the Events list, or arriving on
# their own after a level or a week end. Flavor text, a few fixed choices,
# variable rewards (GameState.apply_event_choice).

func _show_events_list() -> void:
	_show_events("here")


var _events_tab := "here"


## Events on the shared frame (P13, 2026-11-20): chips for where you stand and the hours left, two tabs (Arrange here, Coming
## up), the hint, a red Decision! banner for a dated event coming up (never a buy row), and one card for every event that can
## be arranged at this office, with its location badge and, when it cannot be arranged now, the reason in red and a greyed
## button. Only what can be arranged at the office the player stands at is listed (the two-offices filtering, unchanged).
func _show_events(tab: String) -> void:
	_events_tab = tab if tab == "coming" else "here"
	var look := OfficeFrameStyles.look()
	var rows: Array[Control] = []
	var coming := EventsModel.coming()
	if _events_tab == "coming":
		if coming.is_empty():
			rows.append(_ground_line(Text.say("event.coming_none"), look))
		for event: Dictionary in coming:
			rows.append(EventsView.decision_banner(look, event))
	else:
		rows.append(_ground_line(Text.say("event.list_hint"), look))
		if not coming.is_empty():
			rows.append(EventsView.decision_banner(look, coming[0]))
		var arrangeable := EventsModel.rows()
		if arrangeable.is_empty():
			rows.append(_ground_line(Text.say("event.none"), look))
		for event: Dictionary in arrangeable:
			rows.append(EventsView.event_card(look, event, _on_arrange_event))
	var frame := OfficeScreenFrame.new()
	frame.setup({
		"title": Text.say("event.list_title"),
		"subtitle": Text.say("office.subtitle_jp_events"),
		"chips": EventsModel.chips(),
		"tabs": [{"id": "here", "text": Text.say("event.tab_here")}, {"id": "coming", "text": Text.say("event.tab_coming")}],
		"active_tab": _events_tab,
		"rows": rows,
	})
	frame.tab_chosen.connect(_show_events)
	_events_panel.open_frame(frame, Text.say("ui.back_office"))


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
	var foot: Array[Control] = [done]
	_gathering_panel.open_card({"tag": Text.say("popup.tag_arranged_result"), "title": Text.say("event.gathering_title"),
		"body": rows, "buttons": foot, "primary": 0})


## A background picture as a row in a panel; a missing picture shows a
## placeholder labelled with its asset ID.
func _picture_row(art_id: String) -> Control:
	var art := PlaceholderArt.new()
	art.name = "Picture_" + art_id
	art.kind = PlaceholderArt.Kind.BACKGROUND
	art.art_id = art_id
	art.custom_minimum_size = Vector2(0, Levers.whole("event_picture_height"))
	return art


## A dated event whose day has come opens at once (2026-10-23), the first time
## the Office is open on or after its date. Real-click tests switch it off with
## the same switch as the random events. True when one was shown.
## A follow-up a choice scheduled (2026-10-31) arrives first, once its time has
## come. True when one was shown.
func _show_followup_if_due() -> bool:
	if GameState.is_in_level():
		return false
	var event_id := GameState.take_due_followup()
	if event_id.is_empty():
		return false
	_present_event(event_id, true)
	return true


func _show_dated_event_if_due() -> bool:
	if GameState.is_in_level() or OS.has_environment("COP_NO_RANDOM_EVENTS"):
		return false
	var event_id := GameState.due_dated_event()
	if event_id.is_empty():
		return false
	# A Dated event that belongs to one office opens the week there (two offices, 2026-11-20).
	if GameState.arrive_for_event(GameState.get_event(event_id)):
		_apply_office_look()
		_report.text = "%s\n%s" % [Text.say("travel.forced_move", {"place": TravelText.place_name(GameState.office_location)}), _report_text()]
		_refresh_resources()
		_refresh_calendar()
		_event_moved_you = true
	_present_event(event_id, false)
	return true


## A random event may arrive now (never while a choice about the week is pending).
func _show_random_event_if_due() -> void:
	if GameState.is_in_level() or GameState.work_week_is_full():
		return
	var event_id := GameState.roll_random_event()
	if not event_id.is_empty():
		_present_event(event_id, true)


## True when this Dated event has just taken the player to its office, so its card says so (travel.forced_move, and that the
## trip cost no hours: forced moves are free). Cleared as the card is drawn.
var _event_moved_you := false


## The kind tag of an event's pop-up card: DECISION! for the calendar's own events, SOMETHING COMES UP for the rest.
func _event_tag(event: Dictionary) -> String:
	return Text.say("popup.tag_decision" if str(event.get("trigger", "")) == "Dated" else "popup.tag_scenario")


## Red for a calendar event (the spec's alarm colour), the accent for the rest.
func _event_tag_kind(event: Dictionary) -> String:
	return PopupCardStyles.ALARM if str(event.get("trigger", "")) == "Dated" else PopupCardStyles.ACCENT


## The event screen: its title, flavor text and one button per choice, on the pop-up card (P14, 2026-11-20): the choices are
## the card's foot, so they stay in view while the story scrolls.
func _present_event(event_id: String, arrived: bool, keep_picture: bool = false) -> void:
	var event := GameState.get_event(event_id)
	if event.is_empty():
		return
	var rows: Array[Control] = []
	var choices: Array[Control] = []
	var moved := _event_moved_you
	_event_moved_you = false
	if moved:
		rows.append(UiKit.line(Text.say("travel.forced_move", {"place": TravelText.place_name(GameState.office_location)}), "SmallLabel"))
		rows.append(UiKit.line(Text.say("travel.forced_free"), "SmallLabel"))
	# An Image cell may list several pictures; one is picked each time the event
	# comes up and kept for its result screen (and when Back returns to it from
	# a level's briefing).
	var picture := str(_event_pictures.get(event_id, "")) if keep_picture else EventPicture.pick(event.get("image"),
		"%s %s" % [event.get("title", ""), event.get("flavor", "")], DataDB.art.get("image_terms", {}))
	_event_pictures[event_id] = picture
	if not picture.is_empty():
		rows.append(_picture_row(picture))
	if str(event.get("trigger", "")) == "Dated":
		rows.append(UiKit.line(Text.say("event.heading_dated", {"date": _event_date_label(str(event.get("on_date", "")))}), "SmallLabel"))
		var speaker := GameState.event_speaker(event_id)
		if not speaker.is_empty():
			var face := PlaceholderArt.new()
			face.name = "Speaker_" + str(speaker.get("opp_id", ""))
			face.kind = PlaceholderArt.Kind.CHARACTER
			face.art_id = str(speaker.get("opp_id", ""))
			face.custom_minimum_size = Vector2(0, 420)
			rows.append(face)
			rows.append(UiKit.line(Text.say("event.speaker_line", {
				"name": str(speaker.get("name", "")), "title": OpponentDisplay.title_for(speaker)}), "SmallLabel"))
	elif str(event.get("trigger", "")) == "Followup":
		rows.append(UiKit.line(Text.say("event.heading_followup"), "SmallLabel"))
	elif str(event.get("trigger", "")) == "Train":
		rows.append(UiKit.line(Text.say("event.heading_train"), "SmallLabel"))
	elif arrived:
		rows.append(UiKit.line(Text.say("event.heading_arrives"), "SmallLabel"))
	rows.append(UiKit.line(str(event.get("flavor", ""))))
	# How long it can take, from the quickest choice to the longest (a choice
	# that starts a level adds that level's hours), 2026-10-31.
	var span := GameState.event_hours_range(event)
	if span[1] > 0:
		rows.append(UiKit.line(Text.say("event.duration", {"hours": GameState.event_hours_text(event),
			"count": span[1]}), "SmallLabel"))
	for choice: Dictionary in EventEngine.choices_for(DataDB.event_choices, event_id):
		var price: Variant = choice.get("funds_cost")
		var label := str(choice.get("choice_text", ""))
		var refusal := ""
		if price != null and int(price) > 0:
			label = Text.say("event.choice_cost", {"text": label, "cost": int(price)})
			if int(GameState.meta.get("Funds", 0)) < int(price):
				refusal = Text.say("event.refuse_funds")
		if refusal.is_empty() and StaffDelegation.blocked(str(choice.get("choice_text", "")),
				DataDB.rules.get("staff_delegation_phrases", []), GameState.staff_hired):
			refusal = Text.say("event.refuse_no_staff")
		var delegating := not GameState.event_delegate_role(choice).is_empty()
		if refusal.is_empty() and delegating:
			refusal = GameState.event_delegate_refusal(event, choice)
		if refusal.is_empty():
			refusal = GameState.event_choice_refusal(event, choice)
		# What the choice costs on the spot (hours, Funds, an item), 2026-10-31.
		var commitments := Commitments.of(choice)
		label = GameState.commitment_label(label, commitments)
		if refusal.is_empty():
			refusal = GameState.commitment_refusal(commitments)
		var letter := str(choice.get("choice", ""))
		# A choice that starts a level opens that level's briefing first.
		var pressed := _on_event_level_choice.bind(event_id, letter, arrived) \
			if not GameState.event_choice_level(choice).is_empty() else _on_event_choice.bind(event_id, letter, "")
		# A choice that hands the job to staff asks who goes (Cameron, 2026-11-16).
		if delegating:
			pressed = _on_event_delegate.bind(event_id, letter)
			label = Text.say("event.delegate_label", {"text": label})
		var button := UiKit.action_button(label, refusal, pressed, 100.0)
		button.name = "EventChoice_" + letter
		choices.append(button)
	# A calendar event is not for sale: nothing on a Decision! card is priced or bought, and it says so.
	if str(event.get("trigger", "")) == "Dated":
		rows.append(UiKit.line(Text.say("event.decision_note"), "SmallLabel"))
	_event_panel.open_card({"tag": _event_tag(event), "tag_kind": _event_tag_kind(event), "meta": EventsModel.pop_meta(event),
		"title": str(event.get("title", "")), "body": rows, "buttons": choices})


## A choice that starts a level (2026-10-31): show the level's usual briefing.
## Go in takes the choice and starts the level (_on_start); Back returns to the
## event with nothing taken (_back_to_levels_if_not_started).
func _on_event_level_choice(event_id: String, letter: String, arrived: bool) -> void:
	var level_id := ""
	for choice: Dictionary in EventEngine.choices_for(DataDB.event_choices, event_id):
		if str(choice.get("choice", "")) == letter:
			level_id = GameState.event_choice_level(choice)
	var level := DataDB.get_level(level_id)
	if level.is_empty():
		return
	_event_launch = {"event_id": event_id, "letter": letter, "arrived": arrived}
	_event_panel.close()
	_chosen_level = level
	_show_briefing()


## Who goes: every hired person with how well they suit it, how much of their
## day is left, and what it takes (Cameron, 2026-11-16).
func _on_event_delegate(event_id: String, letter: String) -> void:
	var event := GameState.get_event(event_id)
	var choice := {}
	for row: Dictionary in EventEngine.choices_for(DataDB.event_choices, event_id):
		if str(row.get("choice", "")) == letter:
			choice = row
	if event.is_empty() or choice.is_empty():
		return
	var rows: Array[Control] = []
	var candidates := GameState.event_delegates(event, choice)
	var blocks := GameState.event_delegate_blocks(event, choice)
	rows.append(UiKit.line(Text.say("event.delegate_intro_one" if blocks == 1 else "event.delegate_intro",
		{"role": GameState.event_delegate_role(choice), "count": blocks})))
	for candidate: Dictionary in candidates:
		var button := UiKit.action_button(Text.say("event.delegate_pick", {"name": str(candidate["name"]),
			"fit": StaffAssignmentsView.fit_label(str(candidate["fit"])), "left": int(candidate["left"])}),
			str(candidate["refusal"]), _on_delegate_picked.bind(event_id, letter, str(candidate["staff_id"])), 100.0)
		button.name = "Delegate_" + str(candidate["staff_id"])
		rows.append(button)
	_delegate_panel.top_aligned = true
	_delegate_panel.open(Text.say("event.delegate_title"), rows)


func _on_delegate_picked(event_id: String, letter: String, staff_id: String) -> void:
	_delegate_panel.close()
	_on_event_choice(event_id, letter, staff_id)


func _on_event_choice(event_id: String, letter: String, delegate_id: String = "") -> void:
	var result := GameState.apply_event_choice(event_id, letter, delegate_id)
	if not bool(result.get("ok", false)):
		return
	var rows: Array[Control] = []
	var event_picture := str(_event_pictures.get(event_id, ""))
	if not event_picture.is_empty():
		rows.append(_picture_row(event_picture))
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
		rows.append(UiKit.line(Text.say("event.hours_line", {"hours": int(result["hours"]), "count": int(result["hours"])}), "SmallLabel"))
	var done := Button.new()
	done.name = "EventContinueButton"
	done.custom_minimum_size = Vector2(0, 100)
	done.text = Text.say("event.continue")
	done.pressed.connect(_on_event_done)
	var foot: Array[Control] = [done]
	var finished := GameState.get_event(event_id)
	_event_panel.open_card({"tag": _event_tag(finished), "tag_kind": _event_tag_kind(finished), "title": str(finished.get("title", "")),
		"body": rows, "buttons": foot, "primary": 0})


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
## Promises owed (2026-10-31): each with who it is for, what it owes and when
## it falls due, and a Keep button (greyed with the reason when it cannot be
## kept yet: the item is not held, or the hours are not there).
func _show_promises() -> void:
	var rows: Array[Control] = []
	if GameState.promises.is_empty():
		rows.append(UiKit.line(Text.say("promises.none")))
	var look := OfficeFrameStyles.look()
	for promise: Dictionary in GameState.promises:
		# One tile for each promise (P14b, 2026-11-20): what and for whom, the time left (in the fall colour when it is close),
		# the office it can be kept at, and Keep, greyed with its reason when it cannot be kept yet.
		var tile := PanelContainer.new()
		tile.name = "PromiseTile_" + str(promise.get("id", ""))
		tile.add_theme_stylebox_override("panel", LevelBriefingStyles.tile_box(look))
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var inside := VBoxContainer.new()
		inside.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(6.0)))
		tile.add_child(inside)
		var hours_left := Promises.hours_left(promise, GameState.time_units)
		var due := UiKit.line(Text.say("promises.row", {"what": GameState.promise_what(promise),
			"who": GameState.promise_who(promise), "count": hours_left}))
		due.custom_minimum_size.x = 0.0
		inside.add_child(due)
		if hours_left <= Levers.whole("travel_promise_warning_hours"):
			due.add_theme_color_override("font_color", look["down"])
		# Where it can be kept (two offices, 2026-11-20): a badge for a promise tied to one office.
		var promise_office := Offices.normalize(promise.get("location"))
		if promise_office != Offices.EITHER:
			var badge := UiKit.line(Text.say("promises.badge", {"place": TravelText.place_name(promise_office)}), "SmallLabel")
			badge.custom_minimum_size.x = 0.0
			inside.add_child(badge)
		var keep := UiKit.action_button(Text.say("promises.keep"), GameState.promise_keep_refusal(promise),
			_on_keep_promise.bind(str(promise.get("id", ""))), 100.0)
		keep.name = "Keep_" + str(promise.get("id", ""))
		inside.add_child(keep)
		rows.append(tile)
	_promises_panel.open_card({"tag": Text.say("popup.tag_promises"), "title": Text.say("promises.title"), "body": rows})


func _on_keep_promise(promise_id: String) -> void:
	var who := ""
	var kept_text := ""
	for promise: Dictionary in GameState.promises:
		if str(promise.get("id", "")) == promise_id:
			who = GameState.promise_who(promise)
			kept_text = str(promise.get("kept_text", ""))
	if not GameState.keep_promise(promise_id).is_empty():
		return
	SaveManager.autosave()
	_refresh_resources()
	_refresh_calendar()
	# A promise with its own kept line (Event Choices, 2026-10-31) says it in a
	# pop-up; the rest just flash.
	if not kept_text.is_empty():
		var kept_rows: Array[Control] = [UiKit.line(kept_text)]
		_promises_panel.open_card({"tag": Text.say("popup.tag_promises"), "title": Text.say("promises.kept_title"), "body": kept_rows})
		return
	Layout.flash(Text.say("promises.kept", {"who": who}))
	if GameState.promises.is_empty():
		_promises_panel.close()
	else:
		_show_promises()


## Promises that fell due unkept since the Office last opened, said once.
func _show_broken_promises_if_any() -> void:
	if GameState.promises_broken_unseen.is_empty():
		return
	var rows: Array[Control] = []
	for promise: Dictionary in GameState.promises_broken_unseen:
		rows.append(UiKit.line(Text.say("promises.broken_row", {"who": GameState.promise_who(promise),
			"what": GameState.promise_what(promise)})))
	GameState.promises_broken_unseen = []
	_promises_panel.open_card({"tag": Text.say("popup.tag_broken"), "tag_kind": PopupCardStyles.ALARM,
		"title": Text.say("promises.broken_title"), "body": rows})


## Every crisis-trigger alert's Text row, written out so the exporter can check
## each one exists (QC audit 2026-11-03: the key used to be built at runtime).
const TRIGGER_ALERT_KEYS := {
	"backing_lapsed": {"entered": "office.trigger.backing_lapsed.entered"},
	"funding_freeze": {"entered": "office.trigger.funding_freeze.entered", "left": "office.trigger.funding_freeze.left"},
	"gaffe_penalty": {"entered": "office.trigger.gaffe_penalty.entered"},
	"steering_committee": {"entered": "office.trigger.steering_committee.entered", "left": "office.trigger.steering_committee.left"},
	"town_hall": {"entered": "office.trigger.town_hall.entered", "left": "office.trigger.town_hall.left"},
}


func _show_trigger_alerts_if_any() -> void:
	if GameState.pending_trigger_alerts.is_empty():
		return

	var rows: Array[Control] = []
	for alert: Dictionary in GameState.pending_trigger_alerts:
		var key := str((TRIGGER_ALERT_KEYS.get(str(alert.get("kind", "")), {}) as Dictionary).get(str(alert.get("edge", "")), ""))
		if key.is_empty():
			continue
		rows.append(UiKit.line(Text.say(key, {
			"count": int(alert.get("count", 0)),
			"amount": int(alert.get("amount", 0)),
			"name": str(alert.get("name", "")),
		})))
	GameState.pending_trigger_alerts = []

	_trigger_alert_panel.open_card({"tag": Text.say("office.trigger_alert_title"), "tag_kind": PopupCardStyles.ALARM, "body": rows})


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

	var abandon_button := Button.new()
	abandon_button.custom_minimum_size = Vector2(0, 110)
	abandon_button.text = Text.say("office.abandon_level")
	abandon_button.pressed.connect(_on_abandon_level_chosen)
	# Resume is the filled button; Abandon sits beside it at the foot (P14, 2026-11-20).
	var foot: Array[Control] = [resume_button, abandon_button]
	_resume_choice_panel.open_card({"tag": Text.say("popup.tag_resume"), "title": Text.say("office.resume_choice_title"),
		"body": rows, "buttons": foot, "primary": 0})


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
	var foot: Array[Control] = [go]
	_special_forced_panel.open_card({"tag": Text.say("office.special_forced_title"), "body": rows, "buttons": foot, "primary": 0})


func _on_forced_special_go(level: Dictionary) -> void:
	_special_forced_panel.close()
	_chosen_level = level
	_on_start()


func _on_resume_level_chosen() -> void:
	_resume_choice_panel.close()
	SceneChange.to(get_tree(), StageRouting.scene_for(GameState.level_runner.current_stage()))


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
	# The funds box under the calendar shows Funds, which every purchase changes.
	DuesBox.refresh(_dues_box)
	var refusal := Ledger.deck_refusal(GameState.deck, GameState.owned_cards, GameState.deck_balance(), Text.phrase())
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
## The outcome of the last finished level (GameState.last_level_outcome). It is
## not saved: it only says what happened since the app was opened.
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
	_show_management_tab("staff")


## Office Management on the shared frame (P13, 2026-11-20): one screen with three tabs (Staff, Your Deck, Rhetoric
## Training) in place of a menu of four buttons that each closed it and opened a panel. Funds, XP and the deck count are
## chips; Staff Assignments is the fixed button under the Staff tab.
var _management_tab := "staff"


func _on_management_tab(tab: String) -> void:
	if tab == "deck":
		_show_deck()
	else:
		_show_management_tab(tab)


func _show_management_tab(tab: String) -> void:
	# A refresh after a hire, upgrade or firing: the candidates pop-up of an open place is done with.
	_staff_panel.close()
	var look := OfficeFrameStyles.look()
	var rows: Array[Control]
	var footer: Button = null
	match tab:
		"deck":
			rows = _deck_cards(look)
			footer = _deck_confirm_button()
		"rhetoric":
			rows = _rhetoric_cards(look)
		_:
			tab = "staff"
			rows = StaffRosterView.cards(StaffRosterModel.build(), {"profile": _show_staff_profile, "hire": _show_staff_candidates})
			footer = UiKit.action_button(Text.say("office.staff_assignments"), "", _show_staff_assignments, OfficeFrameStyles.touch_height())
			footer.name = "StaffAssignmentsButton"
	_management_tab = tab
	var frame := OfficeScreenFrame.new()
	frame.setup({
		"title": Text.say("office.management"),
		"subtitle": Text.say("office.subtitle_jp_management"),
		"chips": [Text.say("office.funds", {"count": int(GameState.meta.get("Funds", 0))}), Text.say("office.xp", {"count": GameState.xp}),
			Text.say("office.deck_count", {"count": GameState.deck.size(), "size": GameState.deck_size()})],
		"tabs": [
			{"id": "staff", "text": Text.say("office.staff")},
			{"id": "deck", "text": Text.say("office.your_deck")},
			{"id": "rhetoric", "text": Text.say("office.rhetoric_training")},
		],
		"active_tab": tab,
		"rows": rows,
		"footer": footer,
	})
	frame.tab_chosen.connect(_on_management_tab)
	_management_panel.open_frame(frame, Text.say("ui.back_office"))


## The organizations, and where the player stands with each.
##
## Grouped by tier rather than listed flat, because the tiers are the real
## distinction: a Constituency group is worth something different from a
## National one, and seeing them mixed together hides that.
func _show_organisations() -> void:
	_show_reputation("stakeholders")


## The Stakeholders tab (P13, 2026-11-20): the blurb, then one card per scope (Party Bodies, Constituency, National),
## each row an organization with what moved it last level as a change button.
func _stakeholder_cards(look: Dictionary) -> Array[Control]:
	var rows: Array[Control] = [_ground_line(Text.say("office.orgs_blurb"), look)]
	for tier: String in ["Party", "Constituency", "National"]:
		var in_tier := DataDB.boosters.filter(
			func(b: Dictionary) -> bool: return str(b.get("tier", "")) == tier)
		if in_tier.is_empty():
			continue
		var card := OfficeFrameStyles.card(look, _scope_heading(tier))
		card.name = "StakeholderScope_" + tier
		for booster: Dictionary in in_tier:
			card.get_node("Column").add_child(_organisation_row(booster))
		rows.append(card)
	return rows


## A line of explanation on the frame's own ground (not inside a card), in the room's muted ink.
func _ground_line(text: String, look: Dictionary) -> Label:
	var line := UiKit.line(text, "SmallLabel")
	line.custom_minimum_size.x = 0.0
	line.add_theme_color_override("font_color", look["on_ground_muted"])
	return line


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

	# What moved last level is a button reading only the change (2026-11-09,
	# Cameron); pressing it lists the factors behind that number.
	var change := int(GameState.last_booster_change.get(booster_id, 0))
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	var name_line := UiKit.line(line)
	name_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_line)
	if change != 0:
		var button := OfficeFrameStyles.signed_button(OfficeFrameStyles.look(), "StandingChange_" + booster_id,
			"%+d" % change, change)
		button.pressed.connect(Haptics.confirm)
		button.pressed.connect(_show_standing_factors.bind(booster))
		top.add_child(button)
	var box := UiKit.tight_column()
	box.add_child(top)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return _with_booster_icon(booster_id, box)


## The reasons a stakeholder's standing moved last level, one per row.
func _show_standing_factors(booster: Dictionary) -> void:
	var booster_id := str(booster.get("booster_id", ""))
	var now := int(GameState.booster_standing.get(booster_id, 50))
	var change := int(GameState.last_booster_change.get(booster_id, 0))
	_open_factors(str(booster.get("name_en", booster_id)),
		GameState.last_booster_cause.get(booster_id, []), "",
		Text.say("record.factors_standing", {"old": now - change, "new": now}))


## The reasons one of the four meta numbers moved last level, one per row, with
## the same signed amounts the Your Record button shows (commas, 円).
func _show_meta_factors(meta_name: String) -> void:
	_open_factors(meta_name, GameState.last_meta_cause.get(meta_name, []), meta_name)


## The factors panel both buttons share. `meta_name` blank means a plain
## signed number; a meta name formats the amount the way that number is shown.
func _open_factors(title_name: String, causes: Array, meta_name: String, lead: String = "") -> void:
	if _standing_panel == null:
		_standing_panel = Overlay.new()
		_standing_panel.name = "StandingFactorsPanel"
		add_child(_standing_panel)
	var rows: Array[Control] = []
	# An organization's pop-up starts with where its standing went (P13, 2026-11-20).
	if not lead.is_empty():
		rows.append(UiKit.line(lead, "HeaderLabel"))
	if causes.is_empty():
		rows.append(UiKit.line(Text.say("office.stakeholder_no_cause")))
	for entry: Dictionary in causes:
		var amount := int(entry.get("amount", 0))
		var row := UiKit.line(Text.say("office.stakeholder_factor", {
			"cause": str(entry.get("cause", "")),
			"amount": "%+d" % amount if meta_name.is_empty() else Phrase.meta_amount(meta_name, amount, true)}))
		row.name = "StandingFactor"
		rows.append(row)
	_standing_panel.open_card({"tag": Text.say("popup.tag_reasons"), "title": Text.say("office.stakeholder_change_title", {"name": title_name}),
		"body": rows})


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
## (SH09-SH11, paid in XP). "See a card" draws one random card of
## that tier the player doesn't own yet and shows it; nothing is paid until
## the player chooses to learn it (GameState.offer_random_card() /
## learn_offered_card()). Replaced the old "New cards" list, which let any
## card be bought outright for its XP price with no draw at all.
func _show_rhetoric_training() -> void:
	_show_management_tab("rhetoric")


## The Rhetoric Training tab: the blurb, then one card for each training session. (XP and Funds are chips now.)
func _rhetoric_cards(look: Dictionary) -> Array[Control]:
	var rows: Array[Control] = [_ground_line(Text.say("rhetoric.blurb"), look)]
	# A coupon the player holds is named here (P14b, 2026-11-20): it is redeemed from the items, not taken off a price below.
	for coupon: Dictionary in DataDB.shop:
		var held := GameState.item_count(str(coupon.get("item_id", ""))) if coupon.get("free_card_tier") != null else 0
		if held > 0:
			var note := OfficeFrameStyles.card(look)
			note.name = "CouponNote_" + str(coupon.get("item_id", ""))
			note.get_node("Column").add_child(UiKit.line(Text.say("rhetoric.coupon_line",
				{"count": held, "tier": int(coupon.get("free_card_tier", 0))})))
			rows.append(note)
	for item: Dictionary in DataDB.shop:
		if item.get("card_tier") != null:
			var card := OfficeFrameStyles.card(look)
			card.name = "TrainingCard_" + str(item.get("item_id", ""))
			var row := _training_row(item)
			card.get_node("Column").add_child(row)
			var button := row.find_child("SeeCard", true, false) as Button
			if button != null:
				OfficeFrameStyles.dress_card_button(button, look, not button.disabled)
				button.custom_minimum_size.y = OfficeFrameStyles.touch_height()
			rows.append(card)
	return rows


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


## The tier chosen on the New Game screen, used when a protagonist is picked.
static var _pending_pressure := "standard"
## Set while the New Game screen is open across a restyle: the screen is rebuilt in the new style and
## reopened ("" = not resuming, "first" = the first-launch screen, "again" = started from Administration).
static var _resume_new_game := ""


func _pressure_name(tier: String) -> String:
	match tier:
		Difficulty.RELAXED: return Text.say("pressure.relaxed.name")
		Difficulty.HARDER: return Text.say("pressure.harder.name")
	return Text.say("pressure.standard.name")


func _pressure_blurb(tier: String) -> String:
	match tier:
		Difficulty.RELAXED: return Text.say("pressure.relaxed.blurb")
		Difficulty.HARDER: return Text.say("pressure.harder.blurb")
	return Text.say("pressure.standard.blurb")


func _on_pressure_picked(tier: String, first_run: bool) -> void:
	_pending_pressure = tier
	_show_new_game.call_deferred(first_run)


## The display name of a UI style: the free one from the Text tab, the others from their package.
func _style_name(style: String) -> String:
	if style == UiStyles.LIVING_OFFICE:
		return Text.say("shop.style_living_name")
	var package := _style_package(style)
	return str(package.get("name_en", style))


## The cosmetic package that unlocks `style` ({} for the free default or an unknown style).
func _style_package(style: String) -> Dictionary:
	for package: Dictionary in DataDB.cosmetic_packages:
		if UiStyles.style_of(package) == style:
			return package
	return {}


## The style this New Game screen is showing (and the new run will start in): one being tried, else the
## one already equipped.
func _chosen_style() -> String:
	return UiStyle.current()


## A row of square buttons in a strip you swipe sideways: a heading and `entries` ([id, label] pairs), the
## selected one pressed in. Two squares show at once so the third peeks out as the cue to swipe.
func _swipe_strip(strip_name: String, heading: String, entries: Array, selected: String, on_pick: Callable) -> Control:
	var column := VBoxContainer.new()
	column.name = strip_name
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	var title := UiKit.heading(heading)
	# Two strips share one row: each heading wraps inside its half rather than pushing the row wider.
	title.custom_minimum_size = Vector2(0, 0)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.custom_minimum_size.x = (UiKit.LINE_WIDTH - 20.0) * 0.5
	column.add_child(title)
	# Three small squares that fit their half of the row: nothing to scroll or cut off.
	var strip := HBoxContainer.new()
	strip.name = "Squares"
	strip.add_theme_constant_override("separation", NEW_GAME_SQUARE_GAP)
	column.add_child(strip)
	for entry: Array in entries:
		var button := Button.new()
		button.name = "%s_%s" % [strip_name, str(entry[0])]
		button.text = str(entry[1])
		# As wide as their share of the half row (at least NEW_GAME_SQUARE), so they never overflow or wrap mid-word.
		button.custom_minimum_size = Vector2(NEW_GAME_SQUARE, NEW_GAME_SQUARE)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.clip_text = true
		button.add_theme_font_size_override("font_size", NEW_GAME_SQUARE_FONT)
		button.toggle_mode = true
		button.button_pressed = str(entry[0]) == selected
		button.pressed.connect(Haptics.confirm)
		button.pressed.connect(on_pick.bind(str(entry[0])))
		strip.add_child(button)
	return column


## The least a square gets: three of them and their gaps (3 x 104 + 2 x 8 = 328) fit even the narrowest half row (370).
const NEW_GAME_SQUARE := 104.0
const NEW_GAME_SQUARE_GAP := 8
const NEW_GAME_SQUARE_FONT := 22


## A theme picked on the New Game screen: try it at once. The look is read as a screen builds, so the
## Office is rebuilt in the new style and this screen reopened where it was.
func _on_theme_picked(style: String, first_run: bool) -> void:
	if style == UiStyle.current():
		_show_new_game.call_deferred(first_run)
		return
	UiStyle.trying = style
	_resume_new_game = "first" if first_run else "again"
	Layout.apply_ui_style()
	get_tree().reload_current_scene.call_deferred()


## The new run starts in the style chosen on the New Game screen. A style that needs buying is free here
## (Cameron, 2026-11-18): the chosen one is added to the run and equipped.
func _adopt_chosen_style() -> void:
	var style: String = UiStyle.trying
	UiStyle.trying = ""
	if style.is_empty():
		style = UiStyle.current()
	var package_id := ""
	if style != UiStyles.LIVING_OFFICE:
		package_id = str(_style_package(style).get("package_id", ""))
		if not package_id.is_empty() and not GameState.owned_cosmetic_packages.has(package_id):
			GameState.owned_cosmetic_packages.append(package_id)
	GameState.equip_cosmetic(CosmeticPieces.UI_STYLE, package_id)
	Layout.apply_ui_style()


## The four protagonists (data/player.json), each with a portrait and a
## button. `first_run` is the very first launch: backing out of it still
## leaves the player as the default protagonist, so there is a run to save.
func _show_new_game(first_run: bool) -> void:
	# The New Game screen's button outlines are the gold of the title screen, not the old run's party colour.
	Layout.set_outline_override(CueBanner.EDGE_COLOUR, true)
	# On the shared frame (P14b, 2026-11-20): the choice strips in a card, then one card for each champion with its Choose button
	# in the accent colour. The choice itself is unchanged: tapping a champion's Choose starts the run.
	var look := OfficeFrameStyles.look()
	var rows: Array[Control] = [_ground_line(Text.say("new_game.blurb"), look)]
	# Campaign Pressure (Difficulty.gd) on the left and the display theme on the right, each a strip of
	# square buttons to swipe through. Difficulty is raised later in Administration; the theme is free here.
	var tiers: Array = []
	for tier: String in Difficulty.TIERS:
		tiers.append([tier, _pressure_name(tier)])
	var styles: Array = []
	for style: String in UiStyles.ALL:
		styles.append([style, _style_name(style)])
	var pair := HBoxContainer.new()
	pair.name = "ChoiceStrips"
	pair.add_theme_constant_override("separation", 20)
	pair.add_child(_swipe_strip("PressureStrip", Text.say("new_game.pressure_heading"), tiers,
		_pending_pressure, _on_pressure_picked.bind(first_run)))
	pair.add_child(_swipe_strip("ThemeStrip", Text.say("new_game.theme_heading"), styles,
		_chosen_style(), _on_theme_picked.bind(first_run)))
	var strips_card := OfficeFrameStyles.card(look)
	strips_card.name = "NewGameStripsCard"
	strips_card.get_node("Column").add_child(pair)
	rows.append(strips_card)
	for protagonist: Dictionary in DataDB.protagonists:
		var champion := OfficeFrameStyles.card(look)
		champion.name = "NewGameCard_" + str(protagonist.get("player_id", ""))
		var champion_row := _protagonist_row(protagonist)
		champion.get_node("Column").add_child(champion_row)
		var choose := champion_row.find_child("Choose", true, false) as Button
		if choose != null:
			ConversationStyles.dress_button(choose, look, true)
		rows.append(champion)
	var frame := OfficeScreenFrame.new()
	frame.setup({"title": Text.say("new_game.title"), "subtitle": "", "chips": [], "rows": rows})
	_new_game_panel.open_frame(frame, Text.say("ui.back"))
	if first_run and not _new_game_panel.closed.is_connected(_on_first_run_closed):
		_new_game_panel.closed.connect(_on_first_run_closed)
	if not first_run and not _new_game_panel.closed.is_connected(_on_new_game_dismissed):
		_new_game_panel.closed.connect(_on_new_game_dismissed)


func _protagonist_row(protagonist: Dictionary) -> Control:
	var player_id := str(protagonist.get("player_id", ""))
	var row := HBoxContainer.new()
	row.name = "Protagonist_" + player_id
	row.add_theme_constant_override("separation", 20)

	var portrait := PlaceholderArt.new()
	# All four stand the same height: cropped to the figure and held to a fixed box, not stretched to the row.
	portrait.custom_minimum_size = Vector2(200, 340)
	portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	portrait.trim_margins = true
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
		PartyLabel.apply(party_label, DataDB.get_party(party))
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
	Layout.set_outline_override(Color(0, 0, 0, 0), false)
	if _new_game_panel.closed.is_connected(_on_first_run_closed):
		_new_game_panel.closed.disconnect(_on_first_run_closed)
	if _new_game_panel.closed.is_connected(_on_new_game_dismissed):
		_new_game_panel.closed.disconnect(_on_new_game_dismissed)
	_new_game_panel.close()
	var pressure := _pending_pressure
	_pending_pressure = Difficulty.STANDARD
	var chosen_style := UiStyle.current()
	if not GameState.start_new_run(player_id, pressure):
		UiStyle.trying = ""
		return
	UiStyle.trying = chosen_style
	_adopt_chosen_style()
	SaveManager.autosave()
	_build()
	_report.text = Text.say("office.new_game_started",
		{"name": DataDB.player.get("name_en", player_id)})


## Backed out of New Game from Administration: the run carries on as it was, in the style it had.
func _on_new_game_dismissed() -> void:
	_new_game_panel.closed.disconnect(_on_new_game_dismissed)
	Layout.set_outline_override(Color(0, 0, 0, 0), false)
	_pending_pressure = Difficulty.STANDARD
	if not UiStyle.trying.is_empty():
		UiStyle.trying = ""
		Layout.apply_ui_style()
		get_tree().reload_current_scene.call_deferred()


## Backed out of the first-run choice: play as the default, and save, so the
## next launch does not ask again from nothing.
func _on_first_run_closed() -> void:
	_new_game_panel.closed.disconnect(_on_first_run_closed)
	Layout.set_outline_override(Color(0, 0, 0, 0), false)
	if GameState.awaiting_new_game:
		var chosen_style := UiStyle.current()
		GameState.start_new_run(str(DataDB.player.get("player_id", "")))
		UiStyle.trying = chosen_style
		_adopt_chosen_style()
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
	_show_reputation("parties")


## The Parties tab (P13, 2026-11-20): the blurb, then one card per party with its opinion of you and the button that
## opens its allies and rivals.
func _party_cards(look: Dictionary) -> Array[Control]:
	var rows: Array[Control] = [_ground_line(Text.say("party_opinion.blurb"), look)]
	var own := GameState.own_party_id()
	for party: Dictionary in DataDB.parties:
		var party_id := str(party.get("party_id", ""))
		var detail := GameState.party_opinion_detail(party_id)
		var card := OfficeFrameStyles.card(look)
		card.name = "PartyCard_" + party_id
		var box := card.get_node("Column") as VBoxContainer
		var title := str(party.get("name", party_id))
		if party_id == own:
			title += " " + Text.say("party_opinion.own_tag")
		var heading := UiKit.heading(title)
		heading.custom_minimum_size.x = 0.0
		PartyLabel.apply(heading, party)
		box.add_child(heading)
		var opinion := UiKit.line(Text.say("party_opinion.line", {
			"score": detail["opinion"],
			"band": _band_word(str(detail["band"])),
		}))
		opinion.custom_minimum_size.x = 0.0
		box.add_child(opinion)
		var held := int(detail["stakeholder"])
		var breakdown := UiKit.line(Text.say("party_opinion.detail", {
			"direct": detail["direct"],
			"stakeholder": "—" if held == PartyOpinion.NO_SCORE else str(held),
		}), "SmallLabel")
		breakdown.custom_minimum_size.x = 0.0
		box.add_child(breakdown)
		var view := Button.new()
		view.name = "AlliesButton_" + party_id
		view.text = Text.say("party_opinion.view_button")
		view.custom_minimum_size = Vector2(0, OfficeFrameStyles.touch_height())
		OfficeFrameStyles.dress_card_button(view, look)
		view.pressed.connect(Haptics.confirm)
		view.pressed.connect(_show_party_detail.bind(party_id))
		box.add_child(view)
		rows.append(card)
	return rows


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
	var look := OfficeFrameStyles.look()
	var rows: Array[Control] = []

	# --- the party card (P14b, 2026-11-20): a band in its colour, its seats and leader, and how it sees you
	var head := OfficeFrameStyles.card(look)
	head.name = "PartyHeadCard"
	var head_column := head.get_node("Column") as VBoxContainer
	var band := ColorRect.new()
	band.name = "PartyBand"
	band.color = colour
	band.custom_minimum_size = Vector2(0, 14)
	head_column.add_child(band)
	var leader_id := str(party.get("leader_opp_id", "")) if party.get("leader_opp_id") != null else ""
	var leader := str(DataDB.get_opponent(leader_id).get("name", "")) if not leader_id.is_empty() else ""
	var seats := int(party.get("seats", 0)) if party.get("seats") != null else 0
	head_column.add_child(UiKit.line(Text.say("party_opinion.seats_line" if not leader.is_empty() else "party_opinion.seats_line_no_leader",
		{"count": seats, "leader": leader}), "HeaderLabel"))
	var opinion := UiKit.line(Text.say("party_opinion.line", {"score": detail["opinion"], "band": _band_word(str(detail["band"]))}))
	head_column.add_child(opinion)
	var held := int(detail["stakeholder"])
	head_column.add_child(UiKit.line(Text.say("party_opinion.detail", {"direct": detail["direct"],
		"stakeholder": "—" if held == PartyOpinion.NO_SCORE else str(held)}), "SmallLabel"))
	rows.append(head)
	rows.append(_ground_line(Text.say("party_opinion.popup_blurb"), look))

	# --- Allies, then Rivals, one card each
	for group in ["allies", "rivals"]:
		var is_ally: bool = group == "allies"
		var card := OfficeFrameStyles.card(look, Text.say(
			"party_opinion.allies_heading" if is_ally else "party_opinion.rivals_heading"))
		card.name = "PartyAllies" if is_ally else "PartyRivals"
		var column := card.get_node("Column") as VBoxContainer
		column.add_child(UiKit.line(Text.say(
			"party_opinion.allies_blurb" if is_ally else "party_opinion.rivals_blurb"), "SmallLabel"))
		if (groups[group] as Array).is_empty():
			column.add_child(UiKit.line(Text.say("party_opinion.none")))
		for entry: Dictionary in groups[group]:
			column.add_child(_ally_row(entry, names, colour if is_ally else look["ink"]))
		rows.append(card)

	var frame := OfficeScreenFrame.new()
	frame.setup({
		"title": str(party.get("name", party_id)),
		"subtitle": str(party.get("japanese_name", "")) if party.get("japanese_name") != null else "",
		"chips": [],
		"rows": rows,
	})
	_party_detail_panel.open_frame(frame, Text.say("ui.back"))
	# Panels draw in the order they were added, and the Parties page was just moved to the front by its menu: put this above it.
	move_child(_party_detail_panel, get_child_count() - 1)


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


## Election strength in the standard gold, then every value that feeds it as a
## bar in the colour of the player's own party: the two awareness meters (0-100)
## and each other input as its share of its own maximum. Names only, no numbers.
func _show_election() -> void:
	_show_reputation("election")


## The Election tab: one card with the strength bar and each value that feeds it.
func _election_cards(look: Dictionary) -> Array[Control]:
	var colour := PartyDisplay.color_for(DataDB.get_party(str(DataDB.player.get("party", ""))))
	var card := OfficeFrameStyles.card(look, Text.say("election.title"))
	card.name = "ElectionCard"
	var rows := card.get_node("Column") as VBoxContainer
	var bar_line := UiKit.line(Text.say("election.bar_line"))
	bar_line.custom_minimum_size.x = 0.0
	rows.add_child(bar_line)
	rows.add_child(_colour_bar(GameState.election_strength, CueBanner.EDGE_COLOUR))

	var names := {
		"district": Text.say("awareness.district"), "national": Text.say("awareness.national"),
		"constituency": Text.say("election.c_constituency"), "organizations": Text.say("election.c_organizations"),
		"war_chest": Text.say("election.c_war_chest"), "experience": Text.say("election.c_experience"),
		"record": Text.say("election.c_record"), "party": Text.say("election.c_party")}
	for part: Dictionary in GameState.election_parts():
		var id := str(part["id"])
		var share := 100.0 * float(part["points"]) / maxf(1.0, float(part["max"]))
		var caption := str(names[id])
		if id == "district" or id == "national":
			share = float(GameState.awareness.get(id, 0))
		var line := UiKit.line(caption)
		line.custom_minimum_size.x = 0.0
		rows.add_child(line)
		rows.add_child(_colour_bar(share, colour))
	return [card]


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
	_show_reputation("overview")


## The Overview tab (P13, 2026-11-20): the Resign box first while it is available, then the four numbers, the biggest
## moves, the parties, the latest law and the levels cleared. Everything the old Your Record page showed is on this
## tab or the Laws tab.
func _overview_cards(look: Dictionary) -> Array[Control]:
	var rows: Array[Control] = []
	# Resign sits at the very top, and only while all three standings are far down (Balance "Resign: ..." rows,
	# ResignRules). Cameron, 2026-11-20: it stays in Reputation and Results, as its own box.
	if ResignRules.available(GameState.meta, DataDB.balance):
		rows.append(ReputationView.resign_card(look, ResignScreen.button(_resign), Text.say("resign.hold_hint")))
	var handlers := {"meta_factors": _show_meta_factors, "standing_factors": _show_standing_factors,
		"open_law": _show_law, "tab": _show_reputation}
	var model := ReputationModel.overview({"vote_word": _vote_word, "pressure_name": _pressure_name(GameState.difficulty)})
	rows.append_array(ReputationView.overview_cards(model, handlers))
	return rows


## The Laws tab: Legislative Work (every bill voted on, each opening its pop-up), then the bills your influence flipped.
func _law_cards(look: Dictionary) -> Array[Control]:
	var rows: Array[Control] = []
	var statute := OfficeFrameStyles.card(look, Text.say("office.record_statute_heading"))
	statute.name = "LawsCard"
	var column := statute.get_node("Column") as VBoxContainer
	if GameState.statute_book.is_empty():
		var empty := UiKit.line(Text.say("office.record_statute_empty"))
		empty.custom_minimum_size.x = 0.0
		column.add_child(empty)
	else:
		var hint := UiKit.line(Text.say("record.law_tap_hint"), "SmallLabel")
		hint.custom_minimum_size.x = 0.0
		column.add_child(hint)
		for law: Dictionary in GameState.statute_book:
			var law_id := str(law.get("bill_id", ""))
			var button := UiKit.action_button(Text.say(_law_row_key(law), {
					"name": DataDB.floor_votes.get(law_id, {}).get("bill_name", law_id),
					"yes": law.get("yes", 0), "no": law.get("no", 0), "abstain": law.get("abstain", 0),
					"vote": _vote_word(str(law.get("player_vote", ""))),
				}), "", _show_law.bind(law), 100.0)
			button.name = "Law_" + law_id
			OfficeFrameStyles.dress_card_button(button, look)
			column.add_child(button)
	rows.append(statute)
	var flipped := OfficeFrameStyles.card(look, Text.say("office.record_bills_heading"))
	flipped.name = "FlippedCard"
	var flipped_column := flipped.get_node("Column") as VBoxContainer
	if GameState.bills_flipped_by_influence.is_empty():
		var none := UiKit.line(Text.say("office.record_bills_empty"))
		none.custom_minimum_size.x = 0.0
		flipped_column.add_child(none)
	else:
		for bill_id: String in GameState.bills_flipped_by_influence:
			var line := UiKit.line(str(DataDB.floor_votes.get(bill_id, {}).get("bill_name", bill_id)))
			line.custom_minimum_size.x = 0.0
			flipped_column.add_child(line)
	rows.append(flipped)
	return rows


## One law in the statute book as a pop-up (2026-10-15): PASSED or FAILED,
## what it needed (Majority or Supermajority Vote to Pass), the Aye / Nay /
## Abstain count, how the player voted, whether their influence turned it,
## and what it did when voted and at the end of every later level.
## The Legislative Work row text key for one law: a bill voted on in the
## player's absence (a lost or abandoned Act) has its own limited wording.
func _law_row_key(law: Dictionary) -> String:
	var passed := bool(law.get("passed", false))
	if bool(law.get("absent", false)):
		return "office.record_law_absent_passed" if passed else "office.record_law_absent_failed"
	return "office.record_law_passed" if passed else "office.record_law_failed"


func _show_law(law: Dictionary) -> void:
	var bill_id := str(law.get("bill_id", ""))
	var bill: Dictionary = DataDB.floor_votes.get(bill_id, {})
	var passed := bool(law.get("passed", false))
	var rows: Array[Control] = []

	# The PASSED or FAILED marker is the pop-up card's kind tag (P14b, 2026-11-20): green or red, and the word says it too.
	var marker_text := Text.say("record.law_marker_passed" if passed else "record.law_marker_failed")
	var marker_kind := PopupCardStyles.GOOD if passed else PopupCardStyles.ALARM

	# A limited entry (2026-11-12, Cameron): passed or failed, and a note that
	# stakeholders saw the player's absence. No tally and no "you voted" line.
	if bool(law.get("absent", false)):
		rows.append(UiKit.line(Text.say("record.law_absent_note")))
		_law_panel.open_card({"tag": marker_text, "tag_kind": marker_kind, "title": str(bill.get("bill_name", bill_id)), "body": rows})
		move_child(_law_panel, get_child_count() - 1)
		return

	# A bill an organization asked the player to carry (patron step 4): who
	# asked, and what that organization says about how it went (2026-11-05,
	# moved here from a "Bills you carried" section of Your Record).
	var patron_row := PatronLevel.patron_bill(bill_id)
	if not patron_row.is_empty() and str(patron_row.get("organization", "")) != "":
		var org_id := str(patron_row.get("organization", ""))
		var org_name := str(DataDB.get_booster(org_id).get("name_en", org_id))
		rows.append(UiKit.line(Text.say("record.law_carried", {"org": org_name})))
		var story := str(patron_row.get("pass_line" if passed else "fail_line", ""))
		if not story.is_empty():
			rows.append(UiKit.line(story.replace("{org}", org_name).replace("{bill}",
				str(bill.get("bill_name", bill_id))), "SmallLabel"))

	var requirement := str(law.get("requirement", FloorVoteEngine.requirement_of(bill)))
	var totals := {"Yes": int(law.get("yes", 0)), "No": int(law.get("no", 0)),
		"Abstain": int(law.get("abstain", 0))}
	var needed := int(law.get("yes_needed", 0))
	if needed <= 0:   # a law recorded before the requirement was saved
		needed = FloorVoteEngine.yes_needed(totals, requirement,
			Levers.whole("supermajority_percent_of_house"))
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
	var vote_chips := StanceLines.chip_entries(law.get("vote_effects", {}))
	if not vote_chips.is_empty():
		any_effect = true
		rows.append(UiKit.heading(Text.say("record.law_your_vote")))
		rows.append(OrgChip.row(OrgChip.merged(vote_chips)))
	for timing: Array in [[StatuteBook.ONCE, "record.law_now_passed" if passed else "record.law_now_failed"],
			[StatuteBook.EACH_LEVEL, "record.law_each"]]:
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

	_law_panel.open_card({"tag": marker_text, "tag_kind": marker_kind, "title": str(bill.get("bill_name", bill_id)), "body": rows})
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
	return StatuteBook.effect_chips(DataDB.law_effects, bill_id, passed, timing)


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
	# The Characters list and the detail panel for one character (Administration).
	_characters_panel = Overlay.new()
	_characters_panel.name = "CharactersPanel"
	add_child(_characters_panel)
	_character_detail_panel = Overlay.new()
	_character_detail_panel.name = "CharacterDetailPanel"
	add_child(_character_detail_panel)
	_characters = CharacterCodexPanel.new(_characters_panel, _character_detail_panel)


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


func _resign() -> void:
	Haptics.confirm()
	GameState.resign_run()
	SceneChange.to(get_tree(), StageRouting.RESIGN_SCENE)


func _show_reputation_menu() -> void:
	_show_reputation("overview")


## Reputation and Results on the Office frame (P13, 2026-11-20): one screen with tabs (Overview, Stakeholders, Backers,
## Parties, Election, Laws) in place of the old menu of five buttons and the five panels they opened. The tab bodies
## are the old panels' own rows, in cards; Overview is the new summary.
func _show_reputation(tab: String) -> void:
	var look := OfficeFrameStyles.look()
	var rows: Array[Control]
	match tab:
		"stakeholders": rows = _stakeholder_cards(look)
		"backers": rows = _backer_cards(look)
		"parties": rows = _party_cards(look)
		"election": rows = _election_cards(look)
		"laws": rows = _law_cards(look)
		_:
			tab = "overview"
			rows = _overview_cards(look)
	var frame := OfficeScreenFrame.new()
	frame.setup({
		"title": Text.say("office.reputation_and_results"),
		"subtitle": Text.say("office.subtitle_jp_reputation"),
		"chips": [Text.say("office.funds", {"count": int(GameState.meta.get("Funds", 0))}),
			Text.say("office.xp", {"count": GameState.xp})],
		"tabs": [
			{"id": "overview", "text": Text.say("record.tab_overview")},
			{"id": "stakeholders", "text": Text.say("record.tab_stakeholders")},
			{"id": "backers", "text": Text.say("office.backing")},
			{"id": "parties", "text": Text.say("office.parties")},
			{"id": "election", "text": Text.say("record.tab_election")},
			{"id": "laws", "text": Text.say("record.tab_laws")},
		],
		"active_tab": tab,
		"rows": rows,
	})
	frame.tab_chosen.connect(_show_reputation)
	_reputation_menu.open_frame(frame, Text.say("ui.back_office"))


## Campaign Pressure can be raised during a run, never lowered.
func _raise_pressure_button() -> Button:
	var next_tier := _next_pressure_tier()
	var at_top := GameState.difficulty == Difficulty.HARDER
	var button := UiKit.action_button(
		Text.say("admin.raise_pressure", {"name": _pressure_name(next_tier)}),
		Text.say("admin.pressure_top", {"name": _pressure_name(GameState.difficulty)}) if at_top else "",
		func() -> void:
			if GameState.raise_difficulty(next_tier):
				SaveManager.autosave()
				_report.text = Text.say("office.pressure_raised", {"name": _pressure_name(next_tier)})
			_administration_menu.close())
	button.name = "RaisePressureButton"
	button.custom_minimum_size.x = UiKit.LINE_WIDTH
	return button


func _show_administration_menu() -> void:
	# The Office-screens frame (P13, 2026-11-20): the same controls, as grouped rows with their current value beside them.
	# The old row list is replaced by AdministrationModel (what to show) and AdministrationView (how it is drawn).
	var at_top := GameState.difficulty == Difficulty.HARDER
	var actions := {
		"redraw": _show_administration_menu,
		"open_cosmetics": _open_over.bind(_show_cosmetics, _cosmetics_panel),
		"open_how_to_play": _open_over.bind(HowToPlayPanel.open.bind(_how_to_play_panel), _how_to_play_panel),
		"open_characters": _open_over.bind(_characters.open, _characters_panel),
		"backup_now": _on_backup_now,
		"backup_restore": _confirm_backup_action.bind("restore"),
		"backup_undo": _confirm_backup_action.bind("undo"),
		# Starting over lives here, not in Office Management (Cameron, 2026-10-11). The menu closes first so it is not
		# left open under the warning and the New Game screens.
		"new_game": func() -> void:
			_administration_menu.close()
			_confirm_new_game(),
		"pressure": {
			"title": Text.say("new_game.pressure_heading"),
			"now": Text.say("admin.pressure_now", {"name": _pressure_name(GameState.difficulty)}),
			"blurb": _pressure_blurb(GameState.difficulty if at_top else _next_pressure_tier()),
			"button": _raise_pressure_button(),
		},
	}
	var frame := OfficeScreenFrame.new()
	frame.setup({
		"title": Text.say("office.administration"),
		"subtitle": Text.say("office.subtitle_jp_administration"),
		# Cameron (2026-11-20): the mockup's "Saved" chip is always shown, as every button press saves.
		"chips": [Text.say("save.saved")],
		"rows": AdministrationView.cards(AdministrationModel.build(actions)),
	})
	_administration_menu.open_frame(frame, Text.say("ui.back_office"))


## Runs `opener` (which opens `panel`) and then brings `panel` to the front. Panels are drawn in the order they were
## added, and the menus were added after some of them, so without this the menu would sit on top of the very panel it
## just opened (what _menu_button does for the other menus).
func _open_over(opener: Callable, panel: Overlay) -> void:
	opener.call()
	move_child(panel, get_child_count() - 1)


## The tier the Raise Political Pressure button would go to.
func _next_pressure_tier() -> String:
	return Difficulty.HARDER if GameState.difficulty == Difficulty.STANDARD else Difficulty.STANDARD


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


## The settings buttons are shared with a stage's own menu (SettingsRows.gd);
## each redraws this menu after it changes something.
func _text_size_button() -> Button:
	return SettingsRows.text_size_button(_show_administration_menu)


func _image_scroll_button() -> Button:
	return SettingsRows.image_scroll_button(_show_administration_menu)


func _image_pan_button() -> Button:
	return SettingsRows.image_pan_button(_show_administration_menu)


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
	# Appearance and Music on the shared frame (P14b, 2026-11-20): one card for each package still to buy, then one card for each
	# slot with its owned options, the equipped one filled.
	var look := OfficeFrameStyles.look()
	var rows: Array[Control] = [_ground_line(Text.say("office.cosmetics_blurb"), look)]

	for package: Dictionary in DataDB.cosmetic_packages:
		# An Office style is unlocked on the Marketplace's Office styles tab only; this panel switches
		# between the ones you own (review of P9, finding 6).
		if CosmeticPieces.has_piece(package, CosmeticPieces.UI_STYLE):
			continue
		if not GameState.owned_cosmetic_packages.has(str(package.get("package_id", ""))):
			var package_card := OfficeFrameStyles.card(look)
			package_card.name = "CosmeticCard_" + str(package.get("package_id", ""))
			var package_row := _cosmetic_package_row(package)
			package_card.get_node("Column").add_child(package_row)
			for button: Node in package_row.find_children("*", "Button", true, false):
				_dress_option_button(button as Button, look)
			rows.append(package_card)

	if not GameState.owned_cosmetic_packages.is_empty():
		for slot: String in CosmeticPieces.SLOTS:
			if not _owns_any_piece_for(slot):
				continue
			var slot_card := OfficeFrameStyles.card(look, _cosmetics_slot_label(slot))
			slot_card.name = "CosmeticSlotCard_" + slot
			var slot_row := _cosmetics_slot_row(slot)
			slot_card.get_node("Column").add_child(slot_row)
			for button: Node in slot_row.get_children():
				_dress_option_button(button as Button, look)
			rows.append(slot_card)

	var frame := OfficeScreenFrame.new()
	frame.setup({
		"title": Text.say("office.cosmetics"),
		"subtitle": "",
		"chips": [Text.say("office.funds", {"count": int(GameState.meta.get("Funds", 0))}), Text.say("office.xp", {"count": GameState.xp})],
		"rows": rows,
	})
	_cosmetics_panel.open_frame(frame, Text.say("ui.back_office"))


## An option button of a card: outlined in the card's ink; the equipped one (disabled, with its name and "Equipped") is filled.
func _dress_option_button(button: Button, look: Dictionary) -> void:
	if button == null:
		return
	if button.disabled and button.text.contains(Text.say("office.cosmetics_active")):
		ConversationStyles.dress_button(button, look, true)
		button.add_theme_stylebox_override("disabled", button.get_theme_stylebox("normal"))
		button.add_theme_color_override("font_disabled_color", look["on_accent"])
		button.custom_minimum_size.y = OfficeFrameStyles.touch_height()
		return
	_dress_profile_button(button, look)


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
		CosmeticPieces.CALENDAR: return Text.say("office.cosmetics_slot_calendar")
		CosmeticPieces.UI_STYLE: return Text.say("office.cosmetics_slot_ui_style")
	return slot


## One row of buttons for a slot: Default, then every owned package with a
## piece for it, in the order they were bought. The active one shows its
## own name with "— Equipped" and is disabled rather than losing its name
## to a generic refusal string (UiKit.action_button's usual "greyed-out
## reason" shape would otherwise replace "Neon Ambition" with "Equipped").
func _cosmetics_slot_row(slot: String) -> Control:
	# A column, not a row: with many owned packages (or long names) a row
	# squeezed every button to a sliver that wrapped one letter per line.
	var row := VBoxContainer.new()
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
	# The calendar square and the Office music read the equipped package only
	# when asked, so they are asked again now (2026-10-27, Cameron: a new
	# calendar only appeared after starting a level).
	if slot == CosmeticPieces.CALENDAR:
		_refresh_calendar()
	if slot == CosmeticPieces.MUSIC:
		Audio.play_music("music_office")
	if slot == CosmeticPieces.UI_STYLE:
		Layout.apply_ui_style()
		get_tree().reload_current_scene.call_deferred()
		return
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
	# The Office frame (P13, 2026-11-20): chips for Funds against the limit and XP, the same three tabs (Cameron,
	# 2026-10-31), a "You have" card, and one card of the same shape for every item on offer. The old row builder is
	# replaced by MarketModel (what to show) and MarketView (how it is drawn); buying is unchanged.
	var look := OfficeFrameStyles.look()
	var rows: Array[Control] = []
	if _market_tab == STYLES_TAB:
		rows.append_array(_style_cards(look))
	else:
		# At the Funds limit (or above it), say what the limit does (panel P4, item 3; Cameron's wording).
		if int(GameState.meta.get("Funds", 0)) >= GameState.funds_limit():
			var note_card := OfficeFrameStyles.card(look)
			var limit_note := UiKit.line(Text.say("shop.funds_limit_note"), "SmallLabel")
			limit_note.name = "MarketLimitNote"
			limit_note.custom_minimum_size.x = 0.0
			note_card.get_node("Column").add_child(limit_note)
			rows.append(note_card)
		rows.append(_ground_line(Text.say("shop.supplies_blurb" if _market_tab == Items.PERSONAL else "shop.office_blurb"), look))
		rows.append(MarketView.held_card(look, _inventory_panel.inventory_rows(_market_tab)))
		for item: Dictionary in MarketModel.items(_market_tab, {"price_text": _price_text}):
			rows.append(MarketView.item_card(look, item, _on_buy_item))
	var frame := OfficeScreenFrame.new()
	frame.setup({
		"title": Text.say("office.marketplace"),
		"subtitle": Text.say("office.subtitle_jp_marketplace"),
		"chips": MarketModel.chips(),
		# The tabs keep their old node names, so a click test (and anything else) finds them as before.
		"tabs": [
			{"id": Items.PERSONAL, "node": "PersonalTab", "text": Text.say("shop.tab_personal")},
			{"id": Items.OFFICE_INVENTORY, "node": "OfficeTab", "text": Text.say("shop.tab_office")},
			{"id": STYLES_TAB, "node": "StylesTab", "text": Text.say("shop.tab_styles")},
		],
		"active_tab": _market_tab,
		"rows": rows,
	})
	frame.tab_chosen.connect(_on_market_tab)
	_inventory_panel.open_frame(frame, Text.say("ui.back_office"))


## The Marketplace's third tab (P9, 2026-11-17): one card per UI style with its state, and a
## button that unlocks (a refusal says why) or switches to it. Uses CosmeticPieces' own rules.
const STYLES_TAB := "Styles"


func _style_cards(look: Dictionary) -> Array[Control]:
	var rows: Array[Control] = []
	rows.append(_ground_line(Text.say("shop.styles_blurb"), look))
	var in_use := UiStyle.current()
	for style: String in UiStyles.ALL:
		var package := UiStyles.package_for(style, DataDB.cosmetic_packages)
		var package_id := str(package.get("package_id", ""))
		var frame_card := OfficeFrameStyles.card(look)
		var card := VBoxContainer.new()
		card.name = "StyleCard_" + style
		card.add_theme_constant_override("separation", 8)
		frame_card.get_node("Column").add_child(card)
		card.add_child(_style_swatch(style))
		var is_living := style == UiStyles.LIVING_OFFICE
		var name := Text.say("shop.style_living_name") if is_living else CosmeticPieces.field(package, "name_en")
		var heading := UiKit.heading(name)
		heading.custom_minimum_size.x = 0.0
		card.add_child(heading)
		var desc := UiKit.line(Text.say("shop.style_living_desc") if is_living
			else CosmeticPieces.field(package, "description"), "SmallLabel")
		desc.custom_minimum_size.x = 0.0
		card.add_child(desc)
		if style == in_use:
			var state := UiKit.line(Text.say("shop.style_in_use") + (" · " + Text.say("shop.style_included") if is_living else ""))
			state.name = "StyleState_" + style
			state.custom_minimum_size.x = 0.0
			card.add_child(state)
		elif is_living or GameState.owned_cosmetic_packages.has(package_id):
			var use := UiKit.action_button(Text.say("shop.style_use"), "", _on_use_style.bind(package_id))
			use.name = "StyleUse_" + style
			OfficeFrameStyles.dress_card_button(use, look)
			use.custom_minimum_size.y = OfficeFrameStyles.touch_height()
			card.add_child(use)
		else:
			var refusal := CosmeticPieces.buy_refusal(package, GameState.owned_cosmetic_packages, GameState.xp,
				int(GameState.meta.get("Funds", 0)), Text.phrase())
			var unlock := UiKit.action_button(Text.say("shop.style_unlock", {"price": _price_text(package)}),
				refusal, _on_buy_style.bind(package_id))
			unlock.name = "StyleUnlock_" + style
			OfficeFrameStyles.dress_card_button(unlock, look, refusal.is_empty())
			unlock.custom_minimum_size.y = OfficeFrameStyles.touch_height()
			card.add_child(unlock)
		rows.append(frame_card)
	var footer := _ground_line(Text.say("shop.style_footer"), look)
	rows.append(footer)
	return rows


## The style's preview: a screenshot of the Office in that style, or, when none is drawn, a strip of
## its own colours (ground, plate, accent, ink).
func _style_swatch(style: String) -> Control:
	var shot := UiStyle.preview(style)
	if shot != null:
		var picture := TextureRect.new()
		picture.name = "StylePreview_" + style
		picture.texture = shot
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.custom_minimum_size = Vector2(0, 560)
		return picture
	var strip := HBoxContainer.new()
	strip.name = "StyleSwatch_" + style
	strip.add_theme_constant_override("separation", 0)
	var idx := UiStyle.idx()
	for colour: Color in [UiStyles.ground_colour(idx, style), UiStyles.plate_colour(idx, style),
			UiStyles.colour(idx, style, "accent", UiStyles.colour(idx, style, "gold", UiStyles.colour(idx, style, "indigo"))),
			UiStyles.plate_ink(idx, style)]:
		var block := ColorRect.new()
		block.color = colour
		block.custom_minimum_size = Vector2(0, 70)
		block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		strip.add_child(block)
	return strip


func _on_buy_style(package_id: String) -> void:
	var refusal := GameState.buy_cosmetic_package(package_id)
	if refusal.is_empty():
		SaveManager.autosave()
		_refresh_resources()
	_show_marketplace()


## Switches style ("" = Living Office). The look is read as a screen builds, so the Office is
## rebuilt from the saved run: nothing in the save changes but the equipped slot.
func _on_use_style(package_id: String) -> void:
	GameState.equip_cosmetic(CosmeticPieces.UI_STYLE, package_id)
	SaveManager.autosave()
	Layout.apply_ui_style()
	get_tree().reload_current_scene.call_deferred()


## A Marketplace tab button: rebuild the page for that tab.
func _on_market_tab(tab: String) -> void:
	_market_tab = tab
	_show_marketplace()


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
	# An item a promise owes says so (2026-10-31).
	if GameState.item_is_promised(item_id):
		title.text = Text.say("shop.promised", {"title": title.text})
	box.add_child(title)
	var line := UiKit.line(str(item.get("description", "")), "SmallLabel")
	line.custom_minimum_size = Vector2(620, 0)
	box.add_child(line)

	var bought := int(GameState.shop_bought_this_level.get(item_id, 0))
	var refusal := Items.buy_refusal(item, GameState.item_count(item_id), bought,
		GameState.xp, int(GameState.meta.get("Funds", 0)), Text.phrase(), GameState.funds_limit(), GameState.funds_cap_item_name())
	if refusal.is_empty() and GameState.is_staff_slot_item(item):
		refusal = GameState.staff_slot_refusal(item)
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
	if GameState.is_staff_slot_item(item):
		parts.append(Text.say("shop.item_price_reputation",
			{"count": Levers.whole("staff_slots_reputation_cost")}))
	var text := Text.say("shop.item_free") if parts.is_empty() else " + ".join(parts)
	if ItemUses.full_uses(item) > 1:
		text += " · " + Text.say("shop.item_uses", {"count": ItemUses.full_uses(item)})
	return text


## Three kinds of Supplies item (level_tier/unlocks_recruitment_tier/
## funds_cap_increase; today SH09-SH11, SH12 and SH13) take effect the
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
	if item.get("deck_size_increase") != null:
		_report_purchase_result(GameState.buy_deck_expansion(item_id))
		return
	if GameState.is_staff_slot_item(item):
		_report_purchase_result(GameState.buy_staff_slots(item_id))
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

	# Both faces are stacked at the largest size that lets the whole pop-up
	# (heading, counter, two cards and two buttons) fit the screen with no
	# scrolling (Cameron, 2026-10-29; it was a fixed 2x and ran off the bottom).
	var faces := _card_faces(card, CARD_OFFER_CHROME)

	# "2/3": which look of the draw this is (rules.json card_training_looks).
	var counter := UiKit.line(Text.say("rhetoric.counter", {
		"number": int(draw.get("look", 1)), "total": GameState.card_training_looks()}), "HeaderLabel")
	counter.name = "LookCounter"
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# A pop-up card (P14b, 2026-11-20): "Your coach suggests" and the counter in the header, the card's two faces in the body,
	# and at the foot Pass (only while it is not the draw's last look) above Learn it, which the card always places last.
	var rows: Array[Control] = [counter]   # "2/3": which look of the draw this is
	rows.append_array(faces)
	var foot: Array[Control] = []
	if GameState.can_pass_offered_card():
		var pass_button := Button.new()
		pass_button.name = "Pass"
		pass_button.text = Text.say("rhetoric.pass")
		pass_button.custom_minimum_size = Vector2(0, 110)
		pass_button.pressed.connect(_on_pass_card)
		foot.append(pass_button)
	_card_reveal_panel.open_card({"tag": Text.say("rhetoric.offer_title"), "body": rows, "buttons": foot},
		Text.say("rhetoric.learn", {"price": _offer_price_text(
			DataDB.get_shop_item(str(draw.get("item_id", ""))))}))


## The price on Learn it: "Free" for a coupon's draw (it is never charged), else the item's price.
func _offer_price_text(item: Dictionary) -> String:
	if GameState.draw_is_free(item):
		return Text.say("shop.item_free")
	return _price_text(item)


## How much of the screen's height the card pop-ups spend on everything that
## is not a card: margins, heading, counter, buttons and the gaps between them.
const CARD_OFFER_CHROME := 700.0
const CARD_LOOK_CHROME := 470.0
const CARD_SCALE_MAX := 2.0
const CARD_SCALE_MIN := 1.0


## The card's front and back, one above the other, scaled so the pair fits the
## screen's height once `chrome` pixels are set aside for everything else.
## The front is a fixed-size card, so it is scaled inside a box of the scaled
## size; the back lays its text out from its own size. Both read straight off
## the card's own ID, so real art and real text show the moment they exist.
func _card_faces(card: Dictionary, chrome: float) -> Array[Control]:
	var available := get_viewport_rect().size.y - chrome
	var scale_up := clampf(available / (2.0 * CardView.HEIGHT), CARD_SCALE_MIN, CARD_SCALE_MAX)
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
	back.show_card(card, "")
	var back_frame := CenterContainer.new()
	back_frame.add_child(back)
	return [front_frame, back_frame]


## The deck screen's View button: the card's front and back in a pop-up that
## closes with Back, leaving the deck as it was.
func _show_card_look(card_id: String) -> void:
	var card := DataDB.get_card(card_id)
	if card.is_empty():
		return
	var rows: Array[Control] = []
	# The Japanese name sits beside the English one as a muted line (Standard 6).
	var japanese := str(card.get("name_jp", "")) if card.get("name_jp") != null else ""
	if not japanese.is_empty():
		rows.append(UiKit.line(japanese, "SmallLabel"))
	rows.append_array(_card_faces(card, CARD_LOOK_CHROME))
	_card_look_panel.open_card({"title": str(card.get("name_en", card_id)), "body": rows})


## The deck: which of the cards you own are going in.
##
## A fixed size, so unlocking a card means leaving another out. Without that
## constraint an unlock would be a free upgrade and the screen would have
## nothing to decide.
func _show_deck() -> void:
	_draft_deck = GameState.deck.duplicate()
	_show_management_tab("deck")


func _build_deck_screen() -> void:
	_show_management_tab("deck")


## Why the deck being built cannot be taken in, or "".
func _deck_refusal() -> String:
	return Ledger.deck_refusal(_draft_deck, GameState.owned_cards, GameState.deck_balance(), Text.phrase())


## Which cards the Your Deck tab lists: "all" (the collection: every card you own, the ones left out dimmed) or "deck"
## (only the ones going in).
var _deck_view := "all"


## The Your Deck tab (P14b, 2026-11-20): how many are chosen, the hint, the suit counts of the deck being built, a switch
## between In your deck and the Collection, and the cards in two columns (tap to pick or drop, View to look).
func _deck_cards(look: Dictionary) -> Array[Control]:
	var size := GameState.deck_size()
	var refusal := _deck_refusal()
	var warning := ("" if refusal.is_empty()
		else Text.say("office.deck_warning_suffix", {"reason": refusal}))
	var chosen := UiKit.line(Text.say("office.deck_chosen",
		{"count": _draft_deck.size(), "size": size, "warning": warning}), "HeaderLabel")
	chosen.custom_minimum_size.x = 0.0
	chosen.add_theme_color_override("font_color", look["on_ground"])
	var rows: Array[Control] = [chosen, _ground_line(Text.say("office.deck_tap"), look)]
	rows.append(_deck_suit_chips(look))
	rows.append(_deck_view_switch(look))
	var card := OfficeFrameStyles.card(look)
	card.name = "DeckCard"
	var grid := GridContainer.new()
	grid.name = "DeckGrid"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", int(OfficeFrameStyles.len_px(10.0)))
	grid.add_theme_constant_override("v_separation", int(OfficeFrameStyles.len_px(10.0)))
	for card_id: String in GameState.owned_cards:
		var data := DataDB.get_card(card_id)
		if data.is_empty():
			continue
		if _deck_view == "deck" and not _draft_deck.has(card_id):
			continue
		var tile := _deck_row(data, card_id)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(tile)
	card.get_node("Column").add_child(grid)
	rows.append(card)
	return rows


## One chip for each suit in the deck being built, with its count: the balance of the deck at a glance.
func _deck_suit_chips(look: Dictionary) -> Control:
	var counts := {}
	for card_id: String in _draft_deck:
		var suit := str(DataDB.get_card(card_id).get("suit", ""))
		if not suit.is_empty():
			counts[suit] = int(counts.get(suit, 0)) + 1
	var flow := HFlowContainer.new()
	flow.name = "DeckSuits"
	flow.add_theme_constant_override("h_separation", int(OfficeFrameStyles.len_px(8.0)))
	flow.add_theme_constant_override("v_separation", int(OfficeFrameStyles.len_px(8.0)))
	var suits: Array = counts.keys()
	suits.sort()
	for suit: String in suits:
		var chip := OfficeFrameStyles.chip(look, Text.say("deck.suit_chip", {"suit": suit, "count": int(counts[suit])}))
		# A chip stays on one line: the row builder would otherwise let its words wrap letter by letter.
		var words := chip.find_child("ChipText", true, false) as Label
		if words != null:
			words.set_meta(UiKit.ONE_LINE_META, true)
			words.autowrap_mode = TextServer.AUTOWRAP_OFF
		chip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		flow.add_child(chip)
	return flow


## "In your deck" and "Collection": two buttons, the one showing filled. Redraws the tab.
func _deck_view_switch(look: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.name = "DeckViewSwitch"
	row.add_theme_constant_override("separation", int(OfficeFrameStyles.len_px(8.0)))
	for entry: Array in [["deck", "deck.filter_deck"], ["all", "deck.filter_all"]]:
		var button := Button.new()
		button.name = "DeckView_" + str(entry[0])
		button.text = Text.say(str(entry[1]))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = OfficeFrameStyles.touch_height()
		button.pressed.connect(_on_deck_view.bind(str(entry[0])))
		ConversationStyles.dress_button(button, look, _deck_view == str(entry[0]))
		row.add_child(button)
	return row


func _on_deck_view(view: String) -> void:
	_deck_view = view
	_build_deck_screen()


## "Take these in", the fixed button under the Your Deck tab: only while the deck can be taken in. A half-built deck
## never becomes the deck you start a level with (confirmed rather than saved as you go).
func _deck_confirm_button() -> Button:
	if not _deck_refusal().is_empty():
		return null
	var button := UiKit.action_button(Text.say("office.deck_confirm"), "", func() -> void:
		_management_panel.close()
		_on_deck_confirmed(), OfficeFrameStyles.touch_height())
	button.name = "DeckConfirmButton"
	return button


func _deck_row(card: Dictionary, card_id: String) -> Control:
	var chosen := _draft_deck.has(card_id)

	var box := UiKit.tight_column()

	# A tile in the two-column grid: the pick-or-drop button with the cost first (what the choice turns on: a deck of twelve
	# threes cannot be played three energy at a time), the effect under it, and View below. The PRINTED cost, not what a
	# battle would charge: there is no battle here, so no discount to apply.
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 80)
	button.text = "%s  %d  %s" % [
		"✓" if chosen else "–", int(card.get("cost", 0)), card.get("name_en", card_id)]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.pressed.connect(_on_toggle_card.bind(card_id))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(button)

	var effect := UiKit.line(str(card.get("effect_text", "")), "SmallLabel")
	effect.custom_minimum_size.x = 0.0
	box.add_child(effect)

	# View shows both faces of the card.
	var view := Button.new()
	view.name = "ViewCard_" + card_id
	view.text = Text.say("office.deck_view")
	view.custom_minimum_size = Vector2(0, 80)
	view.pressed.connect(_show_card_look.bind(card_id))
	box.add_child(view)
	var look := OfficeFrameStyles.look()
	OfficeFrameStyles.dress_card_button(button, look, true)
	OfficeFrameStyles.dress_card_button(view, look, true)
	button.custom_minimum_size.y = 80.0
	view.custom_minimum_size.y = 80.0

	# Dimmed as a whole when it is being left out, so the deck reads at a glance rather than by hunting for ticks.
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
	_show_reputation("backers")


## The Backers tab (P13, 2026-11-20): the blurb, Funds, then one card per backing on offer.
func _backer_cards(look: Dictionary) -> Array[Control]:
	var rows: Array[Control] = [_ground_line(Text.say("office.backing_blurb"), look)]
	var funds := UiKit.line(Text.say("office.funds", {"count": int(GameState.meta.get("Funds", 0))}), "HeaderLabel")
	funds.custom_minimum_size.x = 0.0
	funds.add_theme_color_override("font_color", look["on_ground"])
	rows.append(funds)

	var names := BattleSetup.booster_names()
	var stage_names := BattleSetup.stage_names()
	var for_sale := DataDB.modifiers.filter(
		func(m: Dictionary) -> bool: return Ledger.is_for_sale(m))

	if for_sale.is_empty():
		rows.append(_ground_line(Text.say("office.nothing_for_sale"), look))
	for modifier: Dictionary in for_sale:
		var card := OfficeFrameStyles.card(look)
		card.name = "BackingCard_" + str(modifier.get("mod_id", ""))
		card.get_node("Column").add_child(_modifier_row(modifier, names, stage_names))
		rows.append(card)
	return rows


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

	var refusal := GameState.backing_refusal(modifier)
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
## Three roles, always shown in the same order (Ledger.staff_roles(DataDB.staff)). A vacant
## role lists its seven candidates as hire choices — greyed out, with no Hire
## button, for anyone fired earlier this run (GameState.staff_fired); a
## filled role shows who is there, the upgrade to their next tier where one
## exists, and a Fire button that asks first (it costs a severance and can't
## be undone — see GameState.hire_staff()/upgrade_staff()/fire_staff() and
## design/proposals/staff_firing.md).
func _show_staff() -> void:
	_show_management_tab("staff")


## The candidates for one open place (P13, 2026-11-20): today's candidate rows for the role, in a pop-up over the Staff tab.
## Hiring, upgrading or firing refreshes the tab behind it and puts this pop-up away.
func _show_staff_candidates(role: String) -> void:
	var rows: Array[Control] = []
	rows.append(UiKit.line(Text.say("office.staff_blurb") if GameState.staff_slots() <= 1
		else Text.say("office.staff_blurb_places", {"places": GameState.staff_slots()})))
	rows.append(UiKit.line(Text.say("office.funds",
		{"count": int(GameState.meta.get("Funds", 0))}), "HeaderLabel"))
	for candidate: Dictionary in DataDB.get_staff_by_role(role):
		# Someone who resigned never comes back (Cameron, 2026-11-16).
		if GameState.hired_member(str(candidate.get("staff_id", ""))).is_empty() \
				and not bool(GameState.staff_quit.get(str(candidate.get("staff_id", "")), false)):
			rows.append(_staff_candidate_row(candidate))
	_staff_panel.open_card({"tag": Text.say("popup.tag_hire"), "title": role, "body": rows})
	move_child(_staff_panel, get_child_count() - 1)


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
func _staff_hired_row(_role: String, hired: Dictionary, tag_primary: bool = false) -> Control:
	var candidate := DataDB.get_staff(str(hired.get("staff_id", "")))
	var box := UiKit.tight_column()
	var text := Text.say("office.staff_hired", {
		"name": candidate.get("name", hired.get("staff_id", "")),
		"tier": int(hired.get("tier", 0)),
		"highest": int(candidate.get("highest_tier", 0)),
	})
	# With more than one place in the role, the primary is marked.
	if tag_primary:
		text += "  ·  " + Text.say("office.staff_primary_tag")
	box.add_child(_profile_button(text, str(hired.get("staff_id", ""))))
	box.add_child(UiKit.line(StaffLoyaltyView.summary(str(hired.get("staff_id", "")))))
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
	var hired: Dictionary = GameState.hired_member(staff_id)
	var is_hired := not hired.is_empty()
	var current_tier := int(hired.get("tier", 0)) if is_hired else -1
	var look := OfficeFrameStyles.look()
	var rows: Array[Control] = []

	# --- the identity card: the full picture of the person at the left; name, role, flavor and the hiring cost at the right;
	# a biography line under both when the Staff tab has one (Cameron, 2026-10-28; on the shared frame since P14b).
	var identity := OfficeFrameStyles.card(look)
	identity.name = "StaffIdentityCard"
	var identity_column := identity.get_node("Column") as VBoxContainer
	var head := HBoxContainer.new()
	head.name = "StaffHead"
	head.add_theme_constant_override("separation", 24)
	var portrait := PlaceholderArt.new()
	portrait.name = "StaffPortrait"
	portrait.custom_minimum_size = _staff_portrait_size(staff_id)
	portrait.kind = PlaceholderArt.Kind.CHARACTER
	portrait.art_id = staff_id
	head.add_child(portrait)
	var who := UiKit.tight_column()
	who.name = "StaffHiring"
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	who.add_child(UiKit.line(role, "HeaderLabel"))
	# Flavor text about the role, from the Staff tab; no row when blank.
	var role_flavor := str(candidate.get("role_flavor", "")).strip_edges() if candidate.get("role_flavor") != null else ""
	if not role_flavor.is_empty():
		var flavor := UiKit.line(role_flavor)
		flavor.name = "StaffRoleFlavor"
		who.add_child(flavor)
	who.add_child(UiKit.line(Text.say("staff.profile_cost",
		{"cost": int(candidate.get("hiring_cost_yen", 0))})))
	# UiKit.line forces a full-column minimum width; in this narrower column that pushed the buttons off the right edge,
	# so let these wrap instead.
	for label: Node in who.get_children():
		(label as Control).custom_minimum_size.x = 0
	head.add_child(who)
	identity_column.add_child(head)
	var biography := str(candidate.get("biography", "")).strip_edges() if candidate.get("biography") != null else ""
	if not biography.is_empty():
		var bio := UiKit.line(biography)
		bio.name = "StaffBiography"
		identity_column.add_child(bio)
	rows.append(identity)

	# --- Loyalty and pay (a hired person only): the bar, why it moved, and the two things to do about it
	if is_hired:
		var loyalty := OfficeFrameStyles.card(look)
		loyalty.name = "StaffLoyaltyCard"
		var loyalty_column := loyalty.get_node("Column") as VBoxContainer
		for row: Control in StaffLoyaltyView.profile_rows(staff_id):
			loyalty_column.add_child(row)
		var raise := UiKit.action_button(Text.say("staff.raise_pay_button",
			{"yen": StaffLoyalty.wage(GameState.staff_invested_in(staff_id), true), "count": Levers.whole("staff_raise_pay_loyalty")}),
			GameState.raise_pay_refusal(staff_id), _on_raise_pay.bind(staff_id))
		raise.name = "RaisePayButton"
		loyalty_column.add_child(_dress_profile_button(raise, look))
		var thank := UiKit.action_button(Text.say("staff.thank_button",
			{"hours": Levers.whole("staff_thank_in_public_hours"), "count": Levers.whole("staff_thank_in_public_loyalty")}),
			GameState.thank_refusal(staff_id), _on_thank_staff.bind(staff_id))
		thank.name = "ThankButton"
		loyalty_column.add_child(_dress_profile_button(thank, look))
		rows.append(loyalty)

	# --- the bonuses by rank
	var tiers := OfficeFrameStyles.card(look, Text.say("staff.tiers_heading"))
	tiers.name = "StaffTiersCard"
	var tiers_column := tiers.get_node("Column") as VBoxContainer
	for entry: Dictionary in StaffProfile.tiers(candidate, DataDB.boosters, DataDB.segments, Text.phrase()):
		var box := UiKit.tight_column()
		box.name = "Tier_%d" % int(entry["tier"])
		box.add_child(UiKit.line(_tier_label(entry, current_tier), "HeaderLabel"))
		for line: String in entry["lines"]:
			box.add_child(UiKit.line(line))
		tiers_column.add_child(box)
	if int(candidate.get("highest_tier", 0)) <= int(candidate.get("starting_tier", 0)):
		tiers_column.add_child(UiKit.line(Text.say("staff.no_upgrades"), "SmallLabel"))
	rows.append(tiers)

	# --- what can be done: Upgrade, Make primary, then Fire last as a red outline button (Hire for a candidate)
	var funds := int(GameState.meta.get("Funds", 0))
	var actions := OfficeFrameStyles.card(look)
	actions.name = "StaffActionsCard"
	var actions_column := actions.get_node("Column") as VBoxContainer
	if is_hired:
		var cost: Variant = Ledger.staff_upgrade_cost(candidate, current_tier)
		if cost == null:
			actions_column.add_child(_dress_profile_button(UiKit.action_button("", Text.say("office.staff_at_max"), Callable()), look))
		else:
			var upgrade := UiKit.action_button(Text.say("office.upgrade", {"cost": int(cost)}),
				Ledger.staff_upgrade_refusal(candidate, current_tier, funds, Text.phrase()),
				_on_profile_upgrade.bind(staff_id))
			upgrade.name = "ProfileUpgradeButton"
			actions_column.add_child(_dress_profile_button(upgrade, look))
		if not bool(hired.get("primary", true)):
			var primary_button := UiKit.action_button(Text.say("office.staff_make_primary"), "",
				_on_profile_make_primary.bind(staff_id))
			primary_button.name = "ProfilePrimaryButton"
			actions_column.add_child(_dress_profile_button(primary_button, look))
		var fire := UiKit.action_button(Text.say("office.fire_staff"),
			Ledger.staff_fire_refusal(candidate, funds, Text.phrase()),
			_confirm_fire_staff.bind(staff_id, candidate))
		fire.name = "ProfileFireButton"
		actions_column.add_child(_dress_profile_button(fire, look, true))
	else:
		var hire := UiKit.action_button(Text.say("office.hire"),
			_hire_refusal(candidate),
			_on_profile_hire.bind(staff_id))
		hire.name = "ProfileHireButton"
		actions_column.add_child(_dress_profile_button(hire, look))
	rows.append(actions)

	var frame := OfficeScreenFrame.new()
	frame.setup({
		"title": str(candidate.get("name", staff_id)),
		"subtitle": "",
		"chips": [Text.say("office.funds", {"count": funds})],
		"rows": rows,
	})
	_staff_profile_panel.open_frame(frame, Text.say("ui.back"))
	# Above the candidates pop-up or the management screen it was opened from.
	move_child(_staff_profile_panel, get_child_count() - 1)


## A button of the staff profile, outlined in the card's ink and touch-sized; `danger` draws it in the fall colour (Fire).
func _dress_profile_button(button: Button, look: Dictionary, danger: bool = false) -> Button:
	OfficeFrameStyles.dress_card_button(button, look, not button.disabled)
	button.custom_minimum_size.y = OfficeFrameStyles.touch_height()
	if danger and not button.disabled:
		var down: Color = look["down"]
		for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(state, down)
		for state: String in ["normal", "hover", "pressed", "focus"]:
			var box := (button.get_theme_stylebox(state) as StyleBoxFlat).duplicate() as StyleBoxFlat
			box.border_color = down
			button.add_theme_stylebox_override(state, box)
	return button


## The picture's box: the drawing fitted into STAFF_PORTRAIT_MAX with no
## empty margin, so every drawing's top sits at the same height (Cameron,
## 2026-10-28). A missing picture gets the full box.
func _staff_portrait_size(staff_id: String) -> Vector2:
	var path := ArtLoader.character_path(staff_id)
	var texture := load(path) as Texture2D if not path.is_empty() else null
	if texture == null or texture.get_height() <= 0:
		return STAFF_PORTRAIT_MAX
	var aspect := float(texture.get_width()) / float(texture.get_height())
	var width := minf(STAFF_PORTRAIT_MAX.x, STAFF_PORTRAIT_MAX.y * aspect)
	return Vector2(width, width / aspect)


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


# ---------------------------------------------------------------------------
# Staff Assignments (Cameron, 2026-11-16): the day's tasks, given to staff.

func _assignment_handlers() -> Dictionary:
	return {"popup": _on_task_tapped, "dropped": _on_task_given, "profile": _show_staff_profile,
		"confirm": _on_confirm_day, "assign": _on_task_given_from_popup, "unassign": _on_task_taken_back,
		"item_dropped": _on_item_given, "assign_item": _on_item_given_from_popup, "unassign_item": _on_item_taken_back}


func _show_staff_assignments() -> void:
	GameState.staff_ensure_day()
	var handlers := _assignment_handlers()
	var frame := OfficeScreenFrame.new()
	var confirm := StaffAssignmentsView.confirm_button(handlers) if not GameState.staff_members().is_empty() \
		and not GameState.staff_day_pool.is_empty() else null
	frame.setup({
		"title": Text.say("assign.title"),
		"subtitle": "",
		"chips": EventsModel.chips(),
		"rows": StaffAssignmentsView.rows(handlers, false),
		"footer": confirm,
	})
	_assignments_panel.open_frame(frame, Text.say("ui.back_office"))


func _on_task_tapped(uid: String) -> void:
	_task_popup_panel.top_aligned = true
	var rows := StaffAssignmentsView.item_popup_rows(uid.trim_prefix(TaskChip.ITEM_PREFIX), _assignment_handlers()) \
		if uid.begins_with(TaskChip.ITEM_PREFIX) else StaffAssignmentsView.popup_rows(uid, _assignment_handlers())
	_task_popup_panel.open("", rows, "", Text.say("assign.close"))


func _on_item_given(item_id: String, staff_id: String) -> void:
	GameState.staff_use_notes = []
	GameState.staff_assign_item(item_id, staff_id)
	SaveManager.autosave()
	_show_staff_assignments()
	# An Office item that acts at once answers in words, once.
	if not GameState.staff_use_notes.is_empty():
		var rows: Array[Control] = []
		for note: Variant in GameState.staff_use_notes:
			rows.append(UiKit.line(str(note)))
		GameState.staff_use_notes = []
		_staff_report_panel.top_aligned = true
		_staff_report_panel.open(Text.say("assign.gift_title"), rows)


func _on_item_given_from_popup(item_id: String, staff_id: String) -> void:
	_task_popup_panel.close()
	_on_item_given(item_id, staff_id)


func _on_item_taken_back(staff_id: String) -> void:
	_task_popup_panel.close()
	GameState.staff_unassign_item(staff_id)
	SaveManager.autosave()
	_show_staff_assignments()


func _on_task_given(uid: String, staff_id: String) -> void:
	GameState.staff_assign(uid, staff_id)
	SaveManager.autosave()
	_show_staff_assignments()


func _on_task_given_from_popup(uid: String, staff_id: String) -> void:
	_task_popup_panel.close()
	_on_task_given(uid, staff_id)


func _on_task_taken_back(uid: String) -> void:
	_task_popup_panel.close()
	GameState.staff_unassign(uid)
	SaveManager.autosave()
	_show_staff_assignments()


func _on_confirm_day() -> void:
	GameState.staff_confirm_day()
	SaveManager.autosave()
	_show_staff_assignments()
	# Gifts handed over are answered once, in words (Cameron, 2026-11-16).
	if not GameState.staff_gift_notes.is_empty():
		var rows: Array[Control] = []
		for note: Variant in GameState.staff_gift_notes:
			rows.append(UiKit.line(str(note)))
		GameState.staff_gift_notes = []
		_staff_report_panel.top_aligned = true
		_staff_report_panel.open(Text.say("assign.gift_title"), rows)


## The day just ended, once, when the Office is free to show it.
func _maybe_show_staff_report() -> void:
	GameState.staff_day_sync()
	if GameState.staff_report_pending.is_empty():
		return
	for child in get_children():
		if child is Overlay and (child as Overlay).visible:
			return
	_staff_report_panel.top_aligned = true
	_staff_report_panel.open(Text.say("assign.report_title"), StaffAssignmentsView.report_rows(GameState.take_staff_report()))
	SaveManager.autosave()


func _on_raise_pay(staff_id: String) -> void:
	_after_spending(GameState.raise_pay(staff_id), _show_staff_profile.bind(staff_id))


func _on_thank_staff(staff_id: String) -> void:
	_after_spending(GameState.thank_in_public(staff_id), _show_staff_profile.bind(staff_id))


func _on_profile_hire(staff_id: String) -> void:
	_staff_profile_panel.close()
	_after_spending(GameState.hire_staff(staff_id), _show_staff)


## Why this candidate cannot be hired now, in words, or "": the place and the
## price both count (the slot rule lives in GameState.hire_staff()).
func _hire_refusal(candidate: Dictionary) -> String:
	var staff_id := str(candidate.get("staff_id", ""))
	var members := GameState.staff_in_role(str(candidate.get("role", "")))
	if members.size() >= GameState.staff_slots():
		return Text.say("office.staff_slots_full") if GameState.staff_slots() > 1 else Text.say("shop.already_yours")
	return Ledger.staff_hire_refusal(candidate, {}, bool(GameState.staff_fired.get(staff_id, false)),
		int(GameState.meta.get("Funds", 0)), GameState.staff_recruitment_tier, Text.phrase())


func _on_profile_upgrade(staff_id: String) -> void:
	_staff_profile_panel.close()
	_after_spending(GameState.upgrade_staff_member(staff_id), _show_staff)


func _on_profile_make_primary(staff_id: String) -> void:
	_staff_profile_panel.close()
	_after_spending(GameState.make_primary(staff_id), _show_staff)


## Firing is permanent and costs a severance, so it asks first — same
## confirm-overlay pattern as _confirm_new_game().
func _confirm_fire_staff(staff_id: String, candidate: Dictionary) -> void:
	_staff_profile_panel.close()
	_firing_role = staff_id
	var fire_rows: Array[Control] = [UiKit.line(Text.say("office.fire_staff_warning", {
		"name": candidate.get("name", candidate.get("staff_id", "")),
		"cost": Ledger.staff_firing_cost(candidate),
	}))]
	var allies := StaffLoyalty.allies(candidate, int(GameState.hired_member(staff_id).get("tier", 0)))
	var ally_names: Array[String] = []
	for organization: String in allies.keys():
		ally_names.append(str(DataDB.get_booster(organization).get("name_en", organization)))
	if not ally_names.is_empty():
		fire_rows.append(UiKit.line(Text.say("staff.fire_ally_note", {"names": ", ".join(PackedStringArray(ally_names))})))
	_fire_staff_panel.open(Text.say("office.fire_staff"), fire_rows, Text.say("office.fire_staff_confirm"))


func _on_fire_staff_confirmed() -> void:
	_after_spending(GameState.fire_staff_member(_firing_role), _show_staff)


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
# ---------------------------------------------------------------------------
# Two offices (2026-11-20, Cameron): where the player stands and the trip between.

## The picture behind the Office: the Capitol's, or this protagonist's District office (a labelled placeholder
## until it is drawn). Called when the screen opens and after every trip.
func _apply_office_look() -> void:
	if GameState.office_location == Offices.DISTRICT:
		_background.art_id = "DISTRICT_OFFICE_%s" % GameState.protagonist_id
		_background.show_label = true
	else:
		_background.art_id = "OFFICE"
		_background.show_label = false
	RoomObjects.refresh(self)


## The Office's own line about where you are, above the report of the last level.
func _report_text() -> String:
	var last := _last_level_report()
	var here := TravelText.here_line()
	return here if last.is_empty() else "%s\n%s" % [here, last]


func _build_travel() -> void:
	_travel_page_panel = Overlay.new()
	_travel_page_panel.name = "TravelPagePanel"
	add_child(_travel_page_panel)
	_travel_panel = Overlay.new()
	_travel_panel.name = "TravelPanel"
	add_child(_travel_panel)
	_travel_panel.confirmed.connect(_on_travel_confirmed)
	# The card that covers the Office while a trip happens: above every popup.
	_travel_card = TravelCard.new()
	add_child(_travel_card)
	# The strip: drag the train to go; a tap opens the confirm.
	_travel_button = TravelStrip.new()
	_travel_button.name = "TravelButton"
	_travel_button.tapped.connect(_show_travel)
	_travel_button.committed.connect(_start_trip)
	var column := _start_button.get_parent()
	column.add_child(_travel_button)
	column.move_child(_travel_button, _start_button.get_index() + 1)
	# The ways to travel the player holds a ticket for (shown only when there is a choice).
	_travel_modes_row = HBoxContainer.new()
	_travel_modes_row.name = "TravelModes"
	_travel_modes_row.add_theme_constant_override("separation", 10)
	column.add_child(_travel_modes_row)
	column.move_child(_travel_modes_row, _travel_button.get_index() + 1)
	_briefing_panel.travel_mode_chosen.connect(_on_briefing_travel_mode)


## The trip button: where it goes, how long and by what, before it is pressed; greyed with the reason when it cannot.
func _refresh_travel() -> void:
	if _travel_button == null:
		return
	var destination := Offices.other(GameState.office_location)
	var refusal := GameState.travel_refusal(_travel_mode_for_strip())
	_travel_button.text = refusal if not refusal.is_empty() else Text.say("travel.button", {
		"place": TravelText.place_name(destination), "count": GameState.trip_hours(_travel_mode_for_strip()),
		"mode": TravelText.mode_name(_travel_mode_for_strip())})
	_refresh_travel_modes()
	_travel_button.disabled = not refusal.is_empty()
	_travel_button.direction = 1 if GameState.office_location == Offices.CAPITOL else -1


func _travel_mode_for_strip() -> String:
	return _strip_mode if GameState.travel_modes().has(_strip_mode) and _strip_mode != Travel.CAR and _strip_mode != Travel.PLANE else Travel.PASS


## One button for each way to travel the player holds a ticket for: the rail pass and a paid ticket set the mode the
## strip is pulled with; a car or a plane ticket opens its own confirm (instant to do, same fade).
func _refresh_travel_modes() -> void:
	if _travel_modes_row == null:
		return
	for child in _travel_modes_row.get_children():
		_travel_modes_row.remove_child(child)
		child.queue_free()
	var modes := GameState.travel_modes()
	_travel_modes_row.visible = modes.size() > 1
	if modes.size() < 2:
		return
	for mode: String in modes:
		var button := Button.new()
		button.name = "TravelMode_" + mode
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Three buttons share the width, so each one wraps its words rather than push the screen wider.
		button.custom_minimum_size = Vector2(0, 110)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.clip_text = false
		var held := GameState.travel_tickets(mode)
		button.text = Text.say("travel.mode_button", {"mode": TravelText.mode_name(mode), "count": GameState.trip_hours(mode)}) \
			if mode == Travel.PASS else Text.say("travel.mode_button_owned", {"mode": TravelText.mode_name(mode),
				"count": GameState.trip_hours(mode), "owned": held})
		button.disabled = mode == _travel_mode_for_strip() and mode != Travel.CAR and mode != Travel.PLANE
		TravelText.dress_mode_icon(button, mode, 90.0)
		button.pressed.connect(_on_travel_mode.bind(mode))
		_travel_modes_row.add_child(button)


func _on_travel_mode(mode: String) -> void:
	if mode == Travel.CAR or mode == Travel.PLANE:
		_show_travel(mode)
		return
	_strip_mode = mode
	_refresh_travel()


## Picking another way to pay in a mixed level's briefing: the same briefing again, with the hours for that way.
func _on_briefing_travel_mode(mode: String) -> void:
	_travel_mode = mode
	_show_briefing()


## The popup that says what the trip costs before the player takes it (Information Standard 1).
func _show_travel(mode: String = "") -> void:
	_popup_mode = mode if not mode.is_empty() else _travel_mode_for_strip()
	var destination := Offices.other(GameState.office_location)
	var hours := GameState.trip_hours(_popup_mode)
	var rows: Array[Control] = []
	var cost := Text.say("travel.cost_free") if _popup_mode == Travel.PASS else Text.say("travel.cost_ticket", {"mode": TravelText.mode_name(_popup_mode).to_lower()})
	rows.append(UiKit.line(Text.say("travel.confirm_line", {
		"place": TravelText.place_name(destination), "count": hours,
		"mode": TravelText.mode_name(_popup_mode).to_lower(), "cost": cost})))
	var refusal := GameState.travel_refusal(_popup_mode)
	if not refusal.is_empty():
		rows.append(UiKit.line(refusal))
	rows.append(UiKit.line(Text.say("travel.after_line", {"count": maxi(0, GameState.work_hours_left() - hours)})))
	# A promise due soon that can only be kept where the player stands is named before they leave.
	for promise: Dictionary in GameState.promises:
		if Offices.normalize(promise.get("location")) == GameState.office_location \
				and Promises.hours_left(promise, GameState.time_units) <= Levers.whole("travel_promise_warning_hours"):
			rows.append(UiKit.line(Text.say("travel.promise_warning", {"what": GameState.promise_what(promise),
				"place": TravelText.place_name(GameState.office_location), "count": Promises.hours_left(promise, GameState.time_units)})))
	# A crisis level waiting at the other office is named, so the trip is not a surprise.
	for trigger: String in GameState.due_special_levels():
		var waiting := SpecialLevels.level_for(trigger, DataDB.levels)
		if not waiting.is_empty() and Offices.normalize(waiting.get("location")) == destination:
			rows.append(UiKit.line(Text.say("travel.level_waiting", {
				"place": TravelText.place_name(destination), "level": str(waiting.get("description", ""))})))
	# A bottom sheet over the room (P14b, 2026-11-20): the trip's cost and what is left, with the way to the Travel page
	# above Take the trip, and Stay here as the way out.
	var all_trips := Button.new()
	all_trips.name = "AllTripsButton"
	all_trips.text = Text.say("travel.all_trips")
	all_trips.custom_minimum_size = Vector2(0, 110)
	all_trips.pressed.connect(_show_travel_page)
	var foot: Array[Control] = [all_trips]
	_travel_panel.open_card({"title": Text.say("travel.confirm_title"), "body": rows, "buttons": foot, "bottom": true},
		Text.say("travel.confirm_go"), Text.say("travel.confirm_stay"), refusal.is_empty())
	move_child(_travel_panel, get_child_count() - 1)   # above the Travel page when it opened this


## The Travel page (P14b, 2026-11-20, Cameron: the full page): where you are and how many hours are left, then the
## other office with what waits there and one button for each way you can go (the rail pass, a paid ticket, a car, a plane).
## Pressing one opens the confirm sheet, which says the cost before anything is spent.
func _show_travel_page() -> void:
	var look := OfficeFrameStyles.look()
	var destination := Offices.other(GameState.office_location)
	var rows: Array[Control] = []

	var here := OfficeFrameStyles.card(look, Text.say("travel.where_title"))
	here.name = "TravelHereCard"
	here.get_node("Column").add_child(UiKit.line(TravelText.here_line()))
	here.get_node("Column").add_child(UiKit.line(Text.say("office.docket_hours", {"count": GameState.work_hours_left()}), "SmallLabel"))
	rows.append(here)

	var there := OfficeFrameStyles.card(look, Text.say("travel.destination", {"place": TravelText.place_name(destination)}))
	there.name = "TravelDestinationCard"
	var column := there.get_node("Column") as VBoxContainer
	# A crisis level waiting at the other office is named, so the trip is not a surprise.
	for trigger: String in GameState.due_special_levels():
		var waiting := SpecialLevels.level_for(trigger, DataDB.levels)
		if not waiting.is_empty() and Offices.normalize(waiting.get("location")) == destination:
			column.add_child(UiKit.line(Text.say("travel.level_waiting", {
				"place": TravelText.place_name(destination), "level": str(waiting.get("description", ""))})))
	# A promise due soon that can only be kept where the player stands is named before they leave.
	for promise: Dictionary in GameState.promises:
		if Offices.normalize(promise.get("location")) == GameState.office_location \
				and Promises.hours_left(promise, GameState.time_units) <= Levers.whole("travel_promise_warning_hours"):
			var warning := UiKit.line(Text.say("travel.promise_warning", {"what": GameState.promise_what(promise),
				"place": TravelText.place_name(GameState.office_location), "count": Promises.hours_left(promise, GameState.time_units)}))
			warning.add_theme_color_override("font_color", look["down"])
			column.add_child(warning)
	for mode: String in GameState.travel_modes():
		var refusal := GameState.travel_refusal(mode)
		var held := GameState.travel_tickets(mode)
		var button := UiKit.action_button(Text.say("travel.mode_button", {"mode": TravelText.mode_name(mode), "count": GameState.trip_hours(mode)})
			if mode == Travel.PASS else Text.say("travel.mode_button_owned", {"mode": TravelText.mode_name(mode),
				"count": GameState.trip_hours(mode), "owned": held}), refusal, _show_travel.bind(mode), OfficeFrameStyles.touch_height())
		button.name = "TravelPageMode_" + mode
		TravelText.dress_mode_icon(button, mode, 90.0)
		column.add_child(_dress_profile_button(button, look))
	rows.append(there)

	var frame := OfficeScreenFrame.new()
	frame.setup({
		"title": Text.say("travel.page_title"),
		"subtitle": "",
		"chips": EventsModel.chips(),
		"rows": rows,
	})
	_travel_page_panel.open_frame(frame, Text.say("ui.back_office"))


func _on_travel_confirmed() -> void:
	_start_trip(_popup_mode)


## The trip, from the strip's drag or the popup's confirm: the card covers the Office, the trip is taken behind
## it, and the other office is there when the card fades.
func _start_trip(mode: String = "") -> void:
	var by := mode if not mode.is_empty() else _travel_mode_for_strip()
	if not GameState.travel_refusal(by).is_empty():
		return
	var words := Text.say("travel.card_line", {"mode": TravelText.mode_name(by),
		"place": TravelText.place_name(Offices.other(GameState.office_location)),
		"count": GameState.trip_hours(by)})
	_travel_card.play(words, _arrive.bind(by))


func _arrive(by: String) -> void:
	if not GameState.travel(by):
		return
	_apply_office_look()
	_report.text = _report_text()
	_refresh_resources()
	_refresh_calendar()
	# A crisis level that was waiting here is forced in on arrival.
	_show_forced_special_if_due()
	_install_room_objects()
	# An encounter on the train: shown first when the trip brought one (a short dilemma, like an event).
	var encounter := GameState.take_travel_encounter()
	if not encounter.is_empty():
		_present_event(encounter, true)


## Why a level cannot be started now: not at its office first, then the calendar.
func _level_refusal(level: Dictionary) -> String:
	var elsewhere := GameState.level_office_refusal(level)
	if not elsewhere.is_empty():
		return elsewhere
	var tickets := GameState.level_travel_refusal(level, _travel_mode)
	if not tickets.is_empty():
		return tickets
	return GameState.level_calendar_refusal(level, _travel_mode)


func _show_levels() -> void:
	var rows: Array[Control] = []
	rows.append(UiKit.line(Text.say("office.levels_blurb")))
	# The hours left, at the top of the list (all styles; P9 review).
	rows.append(UiKit.line(Text.say("office.docket_hours", {"count": GameState.work_hours_left()}), "HeaderLabel"))

	# Drafting your own bill (patron step 7).
	var draft_button := UiKit.action_button(Text.say("draft.button"), "", _open_draft.bind(true), 100.0)
	draft_button.name = "DraftBillButton"
	LevelFolder.style_draft_button(draft_button)
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
		# An Act whose bill the player voted Aye or Nay on never comes back
		# (2026-11-13); one they were absent for or abstained on returns once its
		# 7,488-hour replay timer is over, like any cooling-down level.
		if GameState.act_is_settled(level):
			continue
		# A level still cooling down is taken off the list until its cooldown
		# is over (Cameron, 2026-11-06; it used to show as a disabled row).
		if DataDB.get_rule("level_gating_enabled", false) and Ledger.level_cooldown_remaining(
				level, GameState.time_units, GameState.level_cleared_units) > 0:
			continue
		# A level only an event can reveal ("Needs Discovery") stays out of sight until then.
		if not GameState.is_level_discovered(level):
			continue
		# A seasonal level (its Seasons cell) only shows in its season (2026-10-30).
		if not GameState.in_season(level):
			continue
		# An Event Only level is started from an event choice, never the list.
		if GameState.is_event_only(level):
			continue
		# A level starts only at its own office (Either levels from both; two offices, 2026-11-20), and a protagonist's
		# own levels (slice 6) are listed only for them.
		if not GameState.level_at_this_office(level) or not GameState.level_is_for_player(level):
			continue
		var tier := int(level.get("tier", 0))
		if not by_tier.has(tier):
			by_tier[tier] = []
		by_tier[tier].append(level)

	var tiers: Array = by_tier.keys()
	tiers.sort()
	for tier: int in tiers:
		rows.append(LevelFolder.style_tier_heading(UiKit.heading(Text.say("office.tier_heading", {"tier": tier}))))
		# Within a tier the non-combat levels come first, then the battles
		# (2026-11-09, Cameron; the gold line between them was dropped).
		var stages_by_id := {}
		for stage: Dictionary in DataDB.stages:
			stages_by_id[str(stage.get("stage_id", ""))] = stage
		var calm: Array = []
		var battles: Array = []
		for level: Dictionary in by_tier[tier]:
			(calm if Ledger.level_is_non_combat(level, stages_by_id) else battles).append(level)
		for level: Dictionary in calm:
			rows.append(_level_row(level))
		for level: Dictionary in battles:
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
	var asked := RequestLines.patron_line(row, "request_line", org_name, str(bill.get("bill_name", "")))
	if asked.is_empty():
		asked = Text.say("request.line", {"org": org_name, "bill": str(bill.get("bill_name", ""))})
	# The organization's icon beside what it asks (P14b, 2026-11-20).
	rows.append(_with_booster_icon(org, UiKit.line(asked)))
	rows.append(UiKit.line(RequestLines.default_vote_line(bill)))
	rows.append(UiKit.line(Text.say("request.influence_needed"), "SmallLabel"))
	rows.append(_readiness_line(bill))
	var own := RequestLines.own_party_line(bill, str(DataDB.player.get("party", "")))
	if not own.is_empty():
		rows.append(UiKit.line(own))
	var reward_chips := RequestLines.reward_entries(row, ally, bool(composed["amended"]))
	if not reward_chips.is_empty():
		rows.append(UiKit.line(Text.say("request.reward_heading")))
		rows.append(OrgChip.row(reward_chips, true))
	if bool(composed["amended"]):
		rows.append(UiKit.line(Text.say("request.amended", {"percent": Levers.whole("patron_amend_reward_percent")}), "SmallLabel"))

	var accept := UiKit.action_button(Text.say("request.accept"), "", _on_request_accept.bind(patron_bill_id), 110.0)
	accept.name = "RequestAcceptButton"

	var live := row.duplicate()
	live["components"] = PatronLevel.compose(patron_bill_id, GameState.enacted_components)["component_ids"]
	var options := PatronRequests.amend_options(live, ComposedBill.index(DataDB.bill_components), GameState.enacted_components)
	if not options.is_empty() and replace.is_empty():
		rows.append(UiKit.heading(Text.say("request.amend_title")))
		rows.append(UiKit.line(Text.say("request.amend_note", {"percent": Levers.whole("patron_amend_reward_percent")}), "SmallLabel"))
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
	# A pop-up card: Carry it is the filled button, Decline (with its cost) the last, and the amend options scroll in the body.
	var foot: Array[Control] = [accept, decline]
	_request_panel.open_card({"tag": Text.say("request.title"), "title": str(bill.get("bill_name", "")), "body": rows,
		"buttons": foot, "primary": 0})


## What the player's influence still lacks for this bill's vote, today
## (component plan 4.1, 2026-11-03): the same line the Floor Vote screen shows.
func _readiness_line(bill: Dictionary) -> Control:
	var line := UiKit.line(RequestLines.readiness_line(bill, DataDB.vote_influence_triggers,
		GameState.effective_meta(), GameState.booster_standing,
		Levers.whole("vote_influence_default_threshold")), "SmallLabel")
	line.name = "InfluenceReadiness"
	return line


## Draft a Bill: the chosen parts, a preview of the bill, the Draft button,
## then the organizations to take parts from (and one organization's parts
## when it is open). `fresh` starts over with nothing chosen.
func _open_draft(fresh: bool = false) -> void:
	if fresh:
		_draft_ids = []
		_draft_org = ""
		_draft_extra_visit = false
	var by_id := ComposedBill.index(DataDB.bill_components)
	var look := OfficeFrameStyles.look()
	var rows: Array[Control] = []
	rows.append(_ground_line(Text.say("draft.intro", {
		"xp": Levers.whole("draft_bill_xp_cost"),
		"funds": Phrase.with_separators(Levers.whole("draft_bill_funds_cost"))}), look))

	# --- your bill: the parts chosen, each removable, and the committee the first one decides (P14b, 2026-11-20: cards on the frame)
	var mine_card := OfficeFrameStyles.card(look, Text.say("draft.parts_heading"))
	mine_card.name = "DraftBillCard"
	var mine := mine_card.get_node("Column") as VBoxContainer
	if _draft_ids.is_empty():
		mine.add_child(UiKit.line(Text.say("draft.no_parts"), "SmallLabel"))
	for id: Variant in _draft_ids:
		var part: Dictionary = by_id.get(str(id), {})
		var remove := UiKit.action_button(Text.say("draft.part_selected", {
			"label": str(part.get("short_label", id)), "phrase": str(part.get("phrase", ""))}), "",
			_draft_toggle.bind(str(id)), 90.0)
		remove.name = "DraftRemove_" + str(id)
		mine.add_child(_dress_profile_button(remove, look))
	if not _draft_ids.is_empty():
		# The first part decides the hearing committee (component plan 4.4, 2026-11-03).
		var first: Dictionary = by_id.get(str(_draft_ids[0]), {})
		var committee := str(DataDB.get_stage(str(first.get("hearing_stage", ""))).get("name_en", ""))
		if not committee.is_empty():
			var hearing := UiKit.line(Text.say("draft.hearing", {"committee": committee}), "SmallLabel")
			hearing.name = "DraftHearing"
			mine.add_child(hearing)
	rows.append(mine_card)

	# --- if it passes: the vote, what influence it needs, what it does, and the extra visit
	if _draft_ids.size() >= DraftBill.MIN_PARTS:
		var preview_card := OfficeFrameStyles.card(look, Text.say("draft.effects_heading"))
		preview_card.name = "DraftPreviewCard"
		var preview := preview_card.get_node("Column") as VBoxContainer
		var bill := DraftBill.bill_for(_draft_ids)
		preview.add_child(UiKit.line(RequestLines.default_vote_line(bill)))
		preview.add_child(UiKit.line(Text.say("request.influence_needed"), "SmallLabel"))
		preview.add_child(_readiness_line(bill))
		var own := RequestLines.own_party_line(bill, str(DataDB.player.get("party", "")))
		if not own.is_empty():
			preview.add_child(UiKit.line(own))
		var draft_chips: Array = []
		for effect: Dictionary in (bill.get("effects", []) as Array):
			var org_id := str(effect.get("target", ""))
			if DataDB.get_booster(org_id).is_empty():
				continue
			draft_chips.append({"id": org_id, "delta": int(effect.get("delta", 0))})
		if not draft_chips.is_empty():
			preview.add_child(OrgChip.row(OrgChip.merged(draft_chips), true))
		# An extra member visit, just before the vote: a second Member Visit and Win Over a Member pair (2026-11-05). Costs hours
		# and XP; refused, with a reason, when no member is left to win over.
		var extra_hours := TimeClock.units_for_stage(DataDB.get_stage(MpVisit.VISIT_STAGE)) \
			+ TimeClock.units_for_stage(DataDB.get_stage(MpVisit.FIGHT_STAGE))
		var extra_args := {"count": extra_hours, "xp": DraftBill.extra_visit_xp_cost()}
		var extra_refusal := DraftBill.extra_visit_refusal(_draft_ids)
		if not extra_refusal.is_empty():
			_draft_extra_visit = false   # parts changed to a bill with no one left to win over
		var extra := UiKit.action_button(
			Text.say("draft.extra_visit_on" if _draft_extra_visit else "draft.extra_visit_off", extra_args),
			extra_refusal, _draft_toggle_extra_visit, 90.0)
		extra.name = "DraftExtraVisit"
		preview.add_child(_dress_profile_button(extra, look))
		rows.append(preview_card)
	# Draft it: the button the frame fixes at the foot while the cards scroll (greyed with its reason).
	var go := UiKit.action_button(Text.say("draft.go"), GameState.draft_refusal(_draft_ids, _draft_extra_visit), _on_draft_go, OfficeFrameStyles.touch_height())
	go.name = "DraftGoButton"

	# --- add a part from: the organizations with their standing, or one organization's parts
	var parts_card := OfficeFrameStyles.card(look, Text.say("draft.orgs_heading") if _draft_org.is_empty()
		else str(DataDB.get_booster(_draft_org).get("name_en", _draft_org)))
	parts_card.name = "DraftPartsCard"
	var parts := parts_card.get_node("Column") as VBoxContainer
	if _draft_org.is_empty():
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
			parts.add_child(_with_booster_icon(org_id, _dress_profile_button(button, look)))
	else:
		var back := UiKit.action_button(Text.say("draft.back_to_orgs"), "", _draft_open_org.bind(""), 90.0)
		back.name = "DraftOrgsBack"
		parts.add_child(_dress_profile_button(back, look))
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
			parts.add_child(_dress_profile_button(part_button, look))
	rows.append(parts_card)

	var frame := OfficeScreenFrame.new()
	frame.setup({
		"title": Text.say("draft.title"),
		"subtitle": "",
		"chips": [Text.say("office.funds", {"count": int(GameState.meta.get("Funds", 0))}), Text.say("office.xp", {"count": GameState.xp})],
		"rows": rows,
		"footer": go,
	})
	_draft_panel.open_frame(frame, Text.say("ui.back"))


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


func _draft_toggle_extra_visit() -> void:
	_draft_extra_visit = not _draft_extra_visit
	_open_draft()


func _on_draft_go() -> void:
	if not GameState.start_draft(_draft_ids, _draft_extra_visit):
		_report.text = GameState.last_level_start_refusal if not GameState.last_level_start_refusal.is_empty() \
			else Text.say("draft.cannot_start")
		_draft_panel.close()
		return
	_draft_panel.close()
	_levels_panel.close()
	SceneChange.to(get_tree(), StageRouting.LEVEL_INTRO_SCENE)


func _on_request_accept(patron_bill_id: String) -> void:
	if not GameState.start_patron_level(patron_bill_id, _request_replace, _request_with):
		_request_panel.close()
		_report.text = GameState.last_level_start_refusal if not GameState.last_level_start_refusal.is_empty() \
			else Text.say("request.cannot_start")
		return
	_request_panel.close()
	_levels_panel.close()
	# The sponsor's own accepting line (W-7), as a brief notice over the next screen.
	var accepted := _patron_answer_line(patron_bill_id, "accept_line")
	if not accepted.is_empty():
		Layout.flash(accepted)
	SceneChange.to(get_tree(), StageRouting.LEVEL_INTRO_SCENE)


## A sponsor's accept or decline line with its organization and bill named.
func _patron_answer_line(patron_bill_id: String, field: String) -> String:
	var row := PatronLevel.patron_bill(patron_bill_id)
	var org := str(row.get("organization", ""))
	var composed := PatronLevel.compose(patron_bill_id, GameState.enacted_components)
	var bill_name := str((composed.get("bill", {}) as Dictionary).get("bill_name", ""))
	return RequestLines.patron_line(row, field, str(DataDB.get_booster(org).get("name_en", org)), bill_name)


func _on_request_decline(patron_bill_id: String) -> void:
	var declined_line := _patron_answer_line(patron_bill_id, "decline_line")
	GameState.decline_patron_bill(patron_bill_id)
	_request_panel.close()
	_show_levels()
	_refresh_resources()
	if not declined_line.is_empty():
		_report.text = declined_line


## One level in the list: its name, its hours, and its button; Living Office draws it as a folder
## (P9, 2026-11-17). The rules and the refusal text are the same in every style.
func _level_row(level: Dictionary) -> Control:
	return LevelFolder.wrap_for_style(_level_row_plain(level), level)


func _level_row_plain(level: Dictionary) -> Control:
	var box := UiKit.tight_column()
	box.name = "Level_" + str(level.get("level_id", ""))

	# Neither the level ID nor a stage count is shown — Cameron, 2026-09-26:
	# the count in particular read as wrong for almost every level (it named
	# 10 no matter how many stages a level actually had) because levels.json
	# writes an unused stage_N slot as an explicit JSON null rather than
	# leaving the key out, and str(null) is the literal text "<null>", never
	# empty — the count was silently always 10. Simplest fix and the one
	# asked for: just the name, which is what a player actually reads.
	box.add_child(UiKit.line(str(level.get("description", ""))))
	# How long it takes, so the list answers "can I fit it" before the button does (all styles).
	box.add_child(UiKit.line(Text.say("office.level_hours_line", {"count": GameState.level_total_hours(level)}), "SmallLabel"))
	# Where it starts, and that a mixed level's trips are in its hours (two offices, 2026-11-20).
	var place_line := TravelText.level_badge(level.get("location"))
	var trip_hours := GameState.level_trip_hours(level)
	if trip_hours > 0:
		place_line = "%s · %s" % [place_line, Text.say("office.level_travel_line", {"count": trip_hours})]
	box.add_child(UiKit.line(place_line, "SmallLabel"))

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
	_travel_mode = Travel.PASS
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

	# What the level says before the player goes in (P12, 2026-11-19, Cameron). LevelBriefing gathers the numbers
	# from the same rules the briefing always read (a room marked "Reveal In Briefing: No" stays out, its hours
	# still counted), with the week's hours around the level and the reason the level cannot start; the panel draws
	# them in the active style. The reading stays here, the drawing is LevelBriefingPanel's.
	var cfg := GameState.calendar_config()
	var phase := str(GameState.calendar["phase"])
	var context := {
		"hours_left": WeekCalendar.hours_left(GameState.calendar, cfg),
		"pool": WeekCalendar.pool_hours(phase, cfg),
		"phase": phase,
		"purpose": LevelPurpose.resolve(_chosen_level, GameState.staff_hired, DataDB.staff),
		"refusal": _level_refusal(_chosen_level),
		"location": TravelText.level_badge(_chosen_level.get("location")) if Offices.normalize(_chosen_level.get("location")) != Offices.EITHER else "",
		"travel_hours": GameState.level_trip_hours(_chosen_level, _travel_mode),
		"travel_trips": Travel.level_trips(_chosen_level),
		"travel_mode": _travel_mode,
		"travel_options": GameState.level_travel_options(_chosen_level),
	}
	_briefing_panel.open_brief(LevelBriefing.build(expanded, GameState.difficulty, DataDB.balance_base, context))


## Start: choose a level — or, when a saved run stopped between the stages
## of one, go straight back into it.
func _on_start_pressed() -> void:
	if GameState.is_in_level():
		SceneChange.to(get_tree(), StageRouting.scene_for(GameState.level_runner.current_stage()))
		return
	_show_levels()


## Back from a level's briefing returns to the list of levels, not the bare
## Office (2026-10-28, Cameron). Going in also closes the panel, and closed
## fires before confirmed, so the check waits a frame and reads the flag
## _on_start() sets.
func _on_briefing_closed() -> void:
	_briefing_went_in = false
	_back_to_levels_if_not_started.call_deferred()


func _back_to_levels_if_not_started() -> void:
	if _briefing_went_in:
		return
	if not _event_launch.is_empty():
		# Back from an event level's briefing: the event again, as it was.
		var launch := _event_launch
		_event_launch = {}
		_present_event(str(launch["event_id"]), bool(launch["arrived"]), true)
		return
	_show_levels()


## The encounter before a mixed level is dealt with: now the level begins.
func _after_encounter_closed() -> void:
	if not _start_after_encounter:
		return
	_start_after_encounter = false
	_encounter_cleared = true
	_on_start()


func _on_start() -> void:
	_briefing_went_in = true
	var elsewhere := GameState.level_office_refusal(_chosen_level)
	if not elsewhere.is_empty():
		_event_launch = {}
		_report.text = elsewhere
		return
	var expanded := BattleSetup.expand_level(_chosen_level)
	var runner := LevelRunner.new(expanded)
	if not runner.is_valid():
		_event_launch = {}
		_report.text = Text.say("office.level_cannot_start", {"problems": "\n• ".join(Array(runner.problems()))})
		return

	# A mixed level's trips may bring an encounter on the train (one roll, by the rail pass or a paid ticket): it is
	# shown first, and the level begins when the player has dealt with it (two offices, slice 4, 2026-11-20).
	if Travel.level_trips(_chosen_level) > 0 and not _encounter_cleared:
		var encounter := GameState.roll_travel_encounter(_travel_mode)
		if not encounter.is_empty():
			_start_after_encounter = true
			_event_panel.closed.connect(_after_encounter_closed, CONNECT_ONE_SHOT)
			_present_event(encounter, true)
			return
	_encounter_cleared = false

	# Started from an event choice: the choice is taken now (its rewards and
	# the event's own hours), then its level begins (2026-10-31).
	if not _event_launch.is_empty():
		GameState.apply_event_choice(str(_event_launch["event_id"]), str(_event_launch["letter"]))
		_event_launch = {}

	# A mixed level's trips between the offices come off the week as it begins (two offices, 2026-11-20).
	GameState.pay_level_travel(_chosen_level, _travel_mode)

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
	# Every level with a Level Purpose opens on it (2026-11-04, Cameron).
	var has_purpose := not LevelPurpose.text_for(DataDB.get_level(level_id)).is_empty()
	if cues.is_empty() and not has_bill and not has_purpose:
		SceneChange.to(get_tree(), StageRouting.scene_for(runner.current_stage()))
	else:
		SceneChange.to(get_tree(), StageRouting.LEVEL_INTRO_SCENE)


## An event's typed date (YY.MM.DD in the workbook) as the calendar square shows it.
func _event_date_label(typed: String) -> String:
	var number := WeekCalendar.parse_date(typed)
	return typed if number < 0 else WeekCalendar.date_label(number)
