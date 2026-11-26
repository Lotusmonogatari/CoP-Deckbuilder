class_name CampaignController
extends Node
## The Campaign Office screen and what goes with it (P20 phase B, 2026-11-26, Cameron): three tabs (Actions, Staff, the Van), the letters'
## organization picker, the result card, the Donate card at the District office, the first-visit How to pages and the phase banners.
## VenuesController hands the Campaign Office (venue VN10) to this; the rules are CampaignOffice, CampaignStaff and ElectionCycle, the run's
## side is GameState. Every sentence is a Text row.

const TAB_ACTIONS := "actions"
const TAB_STAFF := "staff"
const TAB_VAN := "van"

var _venues: Node
var _venue_panel: Overlay
var _chips: Callable
var _on_spent: Callable
var _result_panel: Overlay
var _donate_panel: Overlay
var _banner_panel: Overlay
## The skinned phase banner (P22): a full-screen layer; _banner_panel is the plain card used when the skin is off.
var _banner_layer: CampaignBannerLayer
var _howto_panel: Overlay
var _tab := TAB_ACTIONS
## True while the letters' organization list is showing in place of the action cards.
var _picking := false
var _banner_pages: Array = []
var _banner_index := 0
var _banner_key := ""
var _banner_cycle := ""
var _howto_pages: Array = []
var _howto_index := 0


## `venues` is the VenuesController; `chips` its Callable for the top bar; `on_spent` refreshes the Office's resources line after hours go.
func setup(office: Control, venues: Node, venue_panel: Overlay, chips: Callable, on_spent: Callable) -> void:
	name = "CampaignController"
	office.add_child(self)
	_venues = venues
	_venue_panel = venue_panel
	_chips = chips
	_on_spent = on_spent
	_result_panel = _panel(office, "CampaignResultPanel", true)
	_result_panel.closed.connect(_draw)
	_donate_panel = _panel(office, "CampaignDonatePanel", true)
	_banner_panel = _panel(office, "CampaignBannerCardPanel", false)
	_banner_panel.confirmed.connect(_on_banner_next)
	_banner_layer = CampaignBannerLayer.new()
	_banner_layer.name = "CampaignBannerPanel"
	_banner_layer.hide()
	_banner_layer.confirmed.connect(_on_banner_next)
	office.add_child(_banner_layer)
	_howto_panel = _panel(office, "CampaignHowToPanel", false)
	_howto_panel.confirmed.connect(_on_howto_next)


func _panel(office: Control, panel_name: String, dismissable: bool) -> Overlay:
	var panel := Overlay.new()
	panel.name = panel_name
	panel.dismissable = dismissable
	panel.show_back = dismissable
	office.add_child(panel)
	return panel


## True for the venue this controller draws.
static func draws(venue_id: String) -> bool:
	return venue_id == GameState.CAMPAIGN_VENUE


# --- The Campaign Office -----------------------------------------------------------------------------------------------------------

## Shows the Campaign Office. The first visit shows the how-to pages first.
func open(tab: String = TAB_ACTIONS) -> void:
	_tab = tab
	_picking = false
	if not GameState.campaign_howto_seen:
		_show_howto()
		return
	_draw()


## Opens a card in the campaign skin (when one is in force), with the skin's emblem before its label.
func _open_card(panel: Overlay, config: Dictionary, confirm_text: String = "", back_text: String = "") -> void:
	if CampaignLook.begin():
		config["tag_icon"] = CampaignLook.emblem(UiStyle.scope, 16.0)
	panel.open_card(config, confirm_text, back_text)
	CampaignLook.end()


func _draw() -> void:
	CampaignLook.begin()
	var look := CampaignViews.look()
	var venue := GameState.venue_row(GameState.CAMPAIGN_VENUE)
	var rows: Array[Control] = []
	match _tab:
		TAB_STAFF:
			rows = _staff_rows(look)
		TAB_VAN:
			rows = [CampaignViews.van_card(look, _on_buy_van)]
		_:
			rows = _picker_rows(look) if _picking else _action_rows(look)
	# The skinned Campaign Office has a phase bar under the tabs (P22): the first row of every tab.
	var bar := CampaignViews.phase_bar(look)
	if bar != null:
		rows.push_front(bar)
	var frame := OfficeScreenFrame.new()
	frame.setup({
		"title": str(venue.get("name", Text.say("campaign.office.name"))), "subtitle": str(venue.get("name_jp", "")), "chips": _chips.call(),
		"tabs": [{"id": TAB_ACTIONS, "node": "ActionsTab", "text": Text.say("campaign.tab.actions")},
			{"id": TAB_STAFF, "node": "StaffTab", "text": Text.say("campaign.tab.staff")},
			{"id": TAB_VAN, "node": "VanTab", "text": Text.say("campaign.tab.van")}],
		"active_tab": _tab, "rows": rows,
	})
	frame.tab_chosen.connect(_on_tab)
	_venue_panel.open_frame(frame, Text.say("venue.screen_back"))
	CampaignLook.end()


func _on_tab(tab_id: String) -> void:
	_tab = tab_id
	_picking = false
	_draw()


func _action_rows(look: Dictionary) -> Array[Control]:
	var rows: Array[Control] = [CampaignViews.status_card(look)]
	for kind: String in CampaignOffice.KINDS:
		rows.append(CampaignViews.action_card(look, kind, GameState.campaign_refusal(kind), _on_action))
	return rows


func _staff_rows(look: Dictionary) -> Array[Control]:
	var rows: Array[Control] = [UiKit.line(Text.say("campaign.staff.intro"), "SmallLabel")]
	for entry: Dictionary in GameState.campaign_staff_rows():
		rows.append(CampaignViews.staff_card(look, entry, _on_hire, _on_upgrade))
	return rows


## Every organization, to choose who the letters go to.
func _picker_rows(look: Dictionary) -> Array[Control]:
	var rows: Array[Control] = [UiKit.heading(Text.say("campaign.letters.title"))]
	for booster: Dictionary in DataDB.boosters:
		var id := str(booster.get("booster_id", ""))
		rows.append(CampaignViews.org_row(look, booster, int(GameState.booster_standing.get(id, 0)), _on_org_picked))
	var back := Button.new()
	back.name = "LettersBack"
	back.custom_minimum_size = Vector2(0, OfficeFrameStyles.touch_height())
	back.text = Text.say("ui.back")
	OfficeFrameStyles.dress_card_button(back, look, true)
	back.pressed.connect(_on_picker_back)
	rows.append(back)
	return rows


func _on_picker_back() -> void:
	_picking = false
	_draw()


func _on_action(kind: String) -> void:
	if kind == CampaignOffice.LETTERS:
		_picking = true
		_draw()
		return
	_do(kind, "")


func _on_org_picked(org_id: String) -> void:
	_picking = false
	_do(CampaignOffice.LETTERS, org_id)


## Takes the action and shows what it did; the result card's close brings the office back.
func _do(kind: String, org_id: String) -> void:
	var done := GameState.campaign_act(kind, org_id)
	if not bool(done["ok"]):
		_draw()
		return
	_after_change()
	var body: Array[Control] = []
	for line: String in done["lines"]:
		body.append(UiKit.line(line, "SmallLabel"))
	body.append(UiKit.line(CampaignViews.cost_line(done["result"]), "SmallLabel"))
	_open_card(_result_panel, {"tag": Text.say("campaign.result.title"), "meta": CampaignViews.action_name(kind), "body": body}, "",
		Text.say("campaign.result.continue"))


func _on_hire(staff_id: String) -> void:
	GameState.campaign_hire(staff_id)
	_after_change()
	_draw()


func _on_upgrade(staff_id: String) -> void:
	GameState.campaign_upgrade(staff_id)
	_after_change()
	_draw()


func _on_buy_van() -> void:
	GameState.campaign_buy_van()
	_after_change()
	_draw()


func _after_change() -> void:
	_on_spent.call()
	SaveManager.autosave()


# --- Donate (the District office) -----------------------------------------------------------------------------------------------------

## The Donate card: the amounts the Rules offer, each greyed with its reason when it cannot be given. `done` is the line for the last gift.
func open_donate(done: String = "") -> void:
	var look := CampaignViews.look()
	var body: Array[Control] = [UiKit.line(Text.say("campaign.donate.body"))]
	if not done.is_empty():
		body.append(UiKit.line(done, "SmallLabel"))
	body.append(UiKit.line(Text.say("campaign.stat.line", {"name": Text.say("campaign.office.fund"), "value": WeekPaymentsView.yen(GameState.campaign_fund)}), "SmallLabel"))
	var buttons: Array[Control] = []
	for amount: int in GameState.campaign_donate_steps():
		var enabled := int(GameState.meta.get("Funds", 0)) >= amount
		var button := Button.new()
		button.name = "Donate_%d" % amount
		button.custom_minimum_size = Vector2(0, OfficeFrameStyles.touch_height())
		button.text = Text.say("campaign.donate.step", {"yen": amount}) if enabled else "%s · %s" % [Text.say("campaign.donate.step", {"yen": amount}), Text.say("campaign.reason.no_funds")]
		button.disabled = not enabled
		OfficeFrameStyles.dress_card_button(button, look, enabled)
		if enabled:
			button.pressed.connect(_on_donate.bind(amount))
		buttons.append(button)
	_open_card(_donate_panel, {"tag": Text.say("campaign.donate.title"), "meta": Text.say("campaign.stat.line",
		{"name": Text.say("campaign.office.fund"), "value": WeekPaymentsView.yen(GameState.campaign_fund)}), "body": body, "buttons": buttons},
		"", Text.say("ui.back"))


func _on_donate(amount: int) -> void:
	var why := GameState.campaign_donate(amount)
	if not why.is_empty():
		open_donate(why)
		return
	_after_change()
	open_donate(Text.say("campaign.donate.done", {"yen": amount}))


# --- The first visit's how-to pages -------------------------------------------------------------------------------------------------

func _show_howto() -> void:
	_howto_pages = []
	var group := Text.say("campaign.howto.group")
	for entry: Variant in DataDB.how_to_play:
		if str((entry as Dictionary).get("group", "")) == group:
			_howto_pages.append(entry)
	_howto_pages.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("order", 0)) < float(b.get("order", 0)))
	if _howto_pages.is_empty():
		GameState.campaign_howto_seen = true
		_draw()
		return
	_howto_index = 0
	_show_howto_page()


func _show_howto_page() -> void:
	var entry: Dictionary = _howto_pages[_howto_index]
	var last := _howto_index >= _howto_pages.size() - 1
	_open_card(_howto_panel, {"tag": Text.say("campaign.howto.title"), "meta": Text.say("campaign.howto.page", {"n": _howto_index + 1, "total": _howto_pages.size()}),
		"title": str(entry.get("heading_en", "")), "body": [UiKit.line(str(entry.get("body_en", "")))]},
		Text.say("campaign.howto.done") if last else Text.say("campaign.howto.next"))


func _on_howto_next() -> void:
	if _howto_index < _howto_pages.size() - 1:
		_howto_index += 1
		_show_howto_page()
		return
	GameState.campaign_howto_seen = true
	SaveManager.autosave()
	_draw()


# --- The phase banners ----------------------------------------------------------------------------------------------------------------

## Shows the phase banner that is due, if there is one and the player is not in a level. True when a banner went up.
func show_banner_if_due() -> bool:
	if GameState.is_in_level() or _banner_panel.visible or _banner_layer.visible:
		return false
	var due := GameState.campaign_banner_due()
	if due.is_empty():
		return false
	_banner_pages = due["pages"]
	_banner_key = str(due["key"])
	_banner_cycle = str(due["cycle_id"])
	_banner_index = 0
	_show_banner_page()
	return true


func _show_banner_page() -> void:
	var phase := str(_banner_pages[_banner_index])
	var page := CampaignViews.banner_config(phase, _banner_cycle)
	var last := _banner_index >= _banner_pages.size() - 1
	var cta := str(page["cta"])
	# The last page of a muster says "To the Campaign Office" only when there is one to go to.
	if last and phase == ElectionCycle.MUSTERING and not GameState.campaign_office_open():
		cta = Text.say("event.continue")
	if CampaignLook.begin():
		var shown: Dictionary = page.duplicate()
		shown["cta"] = cta
		_banner_layer.show_page(shown)
		CampaignLook.end()
	else:
		_banner_panel.open_card(page["config"], cta)


func _on_banner_next() -> void:
	_banner_layer.hide()
	if _banner_index < _banner_pages.size() - 1:
		_banner_index += 1
		_show_banner_page()
		return
	GameState.campaign_banner_shown(_banner_key)
	SaveManager.autosave()
