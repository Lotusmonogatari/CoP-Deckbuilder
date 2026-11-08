extends Control
## The Level Intro screen (2026-09-27): a short beat between the Office and
## a level's first stage, where any hired staff with a written line for this
## level speak it over the Office background before the level begins.
##
## OfficeScreen routes here when LevelIntroCues.resolve() comes back
## non-empty, the level has a Level Purpose (2026-11-04), OR it names a Floor Vote bill (StageRouting.
## LEVEL_INTRO_SCENE) — a level with neither goes straight to its first
## stage instead, so this screen never has to show an empty room. The
## `level_id` export exists only for running this scene on its own from the
## editor, the same convention VisitorScreen uses.
##
## Every qualifying staff cue speaks, one after another, on the same
## CueBanner every other spoken line in the game uses, from the player's own
## (blue) side — staff are the player's own team, not an opponent. The
## portrait swaps to match whoever is currently speaking; CueBanner has no
## "line started" signal, so this watches its own `lines_shown` counter
## each frame to notice when the next cue begins.
##
## Bill lean (2026-10-01): once every staff cue has shown, a level that
## names a Floor Vote bill (DataDB.get_floor_vote()) shows the player's own
## internal thought about the level (if one is written) as one more banner
## line, then two buttons — "Lean Support"/"Lean Oppose" — each showing the
## player's own party leader's portrait. The Continue button stays disabled
## until a lean is picked, so the choice always happens; picking one applies
## a Party support delta (BillLean.gd) via the same GameState path a real
## Floor Vote's own favorability uses, then the screen proceeds normally.

@export var level_id: String = "LV31"

@onready var _background: PlaceholderArt = %Background
@onready var _portrait: PlaceholderArt = %Portrait
@onready var _name_label: Label = %StaffName
@onready var _continue_button: Button = %ContinueButton
@onready var _lean_row: Control = %LeanRow
@onready var _support_portrait: PlaceholderArt = %SupportPortrait
@onready var _support_button: Button = %SupportButton
@onready var _oppose_portrait: PlaceholderArt = %OpposePortrait
@onready var _oppose_button: Button = %OpposeButton

var _banner: CueBanner = null
var _cues: Array[Dictionary] = []
var _lines_accounted_for := 0
var _total_lines := 0

var _bill: Dictionary = {}
var _thought_text := ""
var _lean_shown := false
var _lean_resolved := false
## The "Read the bill" page (2026-11-04, Cameron), built on first use.
var _dossier: Overlay = null


func _ready() -> void:
	_background.kind = PlaceholderArt.Kind.BACKGROUND
	_background.art_id = "OFFICE"
	_background.show_label = false

	_portrait.kind = PlaceholderArt.Kind.CHARACTER
	_portrait.expression = "neutral"

	_banner = CueBanner.new()
	_banner.name = "CueBanner"
	add_child(_banner)

	_continue_button.text = Text.say("level_intro.continue")
	_continue_button.pressed.connect(_on_continue)

	_lean_row.visible = false
	_support_portrait.kind = PlaceholderArt.Kind.CHARACTER
	_oppose_portrait.kind = PlaceholderArt.Kind.CHARACTER
	_support_button.text = Text.say("level_intro.lean_support")
	_oppose_button.text = Text.say("level_intro.lean_oppose")
	_support_button.pressed.connect(_on_lean_chosen.bind(BillLean.SUPPORT))
	_oppose_button.pressed.connect(_on_lean_chosen.bind(BillLean.OPPOSE))

	var lid := str(GameState.level_runner.level.get("level_id", "")) \
		if GameState.is_in_level() else level_id
	_cues = LevelIntroCues.resolve(DataDB.level_intros, lid, GameState.staff_hired, DataDB.staff)
	# What the level is for speaks first (2026-11-04, Cameron): from the staff
	# member in the level's Purpose Speaker role, the first hired staff member,
	# or, with no staff, as narration. A level with no Purpose cell skips it.
	var purpose := LevelPurpose.resolve(DataDB.get_level(lid), GameState.staff_hired, DataDB.staff)
	if not purpose.is_empty():
		# With no staff hired the line is shown as narration, with no name and
		# no portrait (Cameron, 2026-11-08): it is written to "you", so the
		# player saying it to themselves read as someone else's line in the
		# player's mouth.
		_cues.push_front({
			"staff_id": str(purpose["staff_id"]),
			"staff_name": str(purpose["staff_name"]),
			"text": str(purpose["text"]),
		})
	_bill = DataDB.get_floor_vote(lid)
	# The player's thought speaks on any level whose intro shows (2026-10-18),
	# not only on a bill level; one of the level's rows is picked at random.
	_thought_text = LevelIntroCues.player_thought(DataDB.level_intro_thoughts, lid)
	_total_lines = _cues.size() + (1 if not _thought_text.is_empty() else 0)

	if _cues.is_empty() and _bill.is_empty():
		_portrait.visible = false
		_name_label.visible = false
		return

	if not _bill.is_empty():
		_continue_button.disabled = true

	if not _cues.is_empty():
		_show_speaker(0)
	elif not _thought_text.is_empty():
		_show_player_speaker()
	else:
		_portrait.visible = false
		_name_label.visible = false

	for cue: Dictionary in _cues:
		_banner.say(CueBanner.PLAYER, str(cue["staff_name"]), str(cue["text"]))
	if not _thought_text.is_empty():
		_banner.say(CueBanner.PLAYER, str(DataDB.player.get("name_en", "")), _thought_text)

	if _total_lines == 0 and not _bill.is_empty():
		_show_lean_choice()


func _process(_delta: float) -> void:
	if _banner == null:
		return
	if _total_lines > 0 and _banner.lines_shown > _lines_accounted_for:
		_lines_accounted_for = _banner.lines_shown
		if _lines_accounted_for < _cues.size():
			_show_speaker(_lines_accounted_for)
		elif _lines_accounted_for == _cues.size() and not _thought_text.is_empty():
			_show_player_speaker()
	if not _bill.is_empty() and not _lean_shown and _lines_accounted_for >= _total_lines:
		_show_lean_choice()


func _show_speaker(index: int) -> void:
	var cue: Dictionary = _cues[index]
	# A narrated line (no speaker) shows nobody.
	var narrated := str(cue["staff_id"]).is_empty()
	_portrait.visible = not narrated
	_name_label.visible = not narrated
	if narrated:
		return
	_portrait.art_id = str(cue["staff_id"])
	_name_label.text = str(cue["staff_name"])


func _show_player_speaker() -> void:
	_portrait.visible = true
	_name_label.visible = true
	_portrait.art_id = str(DataDB.player.get("player_id", ""))
	_name_label.text = str(DataDB.player.get("name_en", ""))


func _show_lean_choice() -> void:
	_lean_shown = true
	# A bill an organization asked the player to carry is carried: the lean is
	# Support and there is nothing to choose (patron step 4).
	if str(_bill.get("bill_id", "")).begins_with("PB") or str(_bill.get("bill_id", "")).begins_with(DraftBill.PREFIX):
		# With no staff to speak and no choice to make, the screen shows the
		# player at the top, centered, above the stance (2026-11-02, Cameron).
		_show_player_speaker()
		(get_node("Safe/Column/TopSpacer") as Control).size_flags_vertical = Control.SIZE_FILL
		_on_lean_chosen(BillLean.SUPPORT)
		_add_read_button()
		return
	_show_bill_card()
	var note := StanceLines.intro_lines(_bill)
	# What a lean is worth, from the Balance tab (2026-11-04, Cameron).
	note.append(Text.say("level_intro.stakes", {
		"win": int(DataDB.balance.get("stance_win_drift", 0)),
		"vote": int(DataDB.balance.get("stance_vote_delta", 0)),
		"switch": int(DataDB.balance.get("stance_flip_abandoned_penalty", 0))}))
	_stance_note().text = "\n".join(note)
	_stance_note().visible = not _stance_note().text.is_empty()
	var own_party := DataDB.get_party(str(DataDB.player.get("party", "")))
	var leader_id := str(own_party.get("leader_opp_id", ""))
	_support_portrait.art_id = leader_id
	_support_portrait.expression = "neutral"
	_oppose_portrait.art_id = leader_id
	_oppose_portrait.expression = "neutral"
	_lean_row.visible = true


func _on_lean_chosen(lean: String) -> void:
	if _lean_resolved:
		return
	_lean_resolved = true

	var own_party_name := str(DataDB.player.get("party", ""))
	var own_party := DataDB.get_party(own_party_name)
	var own_party_id := str(own_party.get("party_id", ""))
	var own_position: Dictionary = {}
	for position: Dictionary in _bill.get("positions", []):
		if str(position.get("party_id", "")) == own_party_id:
			own_position = position
			break

	GameState.set_bill_lean(str(_bill.get("bill_id", "")), lean)

	var magnitude := int(DataDB.balance.get("lean_party_support_delta", 0))
	var delta := BillLean.party_support_delta(own_position, lean, magnitude)
	if delta != 0:
		GameState.apply_floor_vote_favorability({own_party_name: delta},
			Text.say("record.cause_lean", {"bill": str(_bill.get("bill_name", ""))}))

	_lean_row.visible = false
	# The stance chips below replace the card's For it / Against it rows.
	var sides := _lean_row.get_parent().get_node_or_null("BillSides")
	if sides != null:
		sides.free()
	_stance_note().text = StanceLines.stance_line()
	_stance_note().visible = not _stance_note().text.is_empty()
	_show_stance_chips()
	_continue_button.disabled = false


func _on_continue() -> void:
	if not GameState.is_in_level():
		get_tree().quit()
		return
	get_tree().change_scene_to_file(StageRouting.scene_for(GameState.level_runner.current_stage()))


## Who is with and against the player, as chips under the stance sentence.
func _show_stance_chips() -> void:
	var parent := _lean_row.get_parent()
	var old := parent.get_node_or_null("StanceChips")
	if old != null:
		old.free()
	var rows := StanceLines.stance_chip_rows(true)
	if rows.is_empty():
		return
	var box := VBoxContainer.new()
	box.name = "StanceChips"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	for row: Control in rows:
		box.add_child(row)
	parent.add_child(box)
	parent.move_child(box, _stance_note().get_index() + 1)


## The label above the lean boxes: whose bill it is and where the player's
## party stands, then (once a lean is picked) the stance and who is with and
## against the player. Built on first use.
func _stance_note() -> Label:
	var note := _lean_row.get_parent().get_node_or_null("StanceNote") as Label
	if note == null:
		note = Label.new()
		note.name = "StanceNote"
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.visible = false
		_lean_row.get_parent().add_child(note)
		_lean_row.get_parent().move_child(note, _lean_row.get_index())
	return note


# ---------------------------------------------------------------------------
# The bill card and the dossier (2026-11-04, Cameron)
# ---------------------------------------------------------------------------

## Above the stance note: the bill's name and what it does. Below it: who is
## for and against it, and a "Read the bill" button for the full page.
func _show_bill_card() -> void:
	var column := _lean_row.get_parent()
	var card := VBoxContainer.new()
	card.name = "BillCard"
	var title := UiKit.heading(str(_bill.get("bill_name", "")))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(title)
	var description := str(_bill.get("bill_description") if _bill.get("bill_description") != null else "")
	if not description.is_empty():
		var line := UiKit.line(description)
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(line)
	column.add_child(card)
	column.move_child(card, _stance_note().get_index())

	var sides := BillStance.sides(_bill, DataDB.law_effects, GameState._party_tier_booster_ids())
	var box := VBoxContainer.new()
	box.name = "BillSides"
	for group: Array in [[sides.get("supporters", []), true, Text.say("level_intro.for_it")],
			[sides.get("opponents", []), false, Text.say("level_intro.against_it")]]:
		if (group[0] as Array).is_empty():
			continue
		var heading := UiKit.line(str(group[2]), "SmallLabel")
		heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(heading)
		var chips := OrgChip.side_row(group[0], bool(group[1]))
		chips.alignment = FlowContainer.ALIGNMENT_CENTER
		box.add_child(chips)
	if box.get_child_count() > 0:
		column.add_child(box)
		column.move_child(box, _stance_note().get_index() + 1)
	else:
		box.free()
	_add_read_button()


func _add_read_button() -> void:
	var column := _lean_row.get_parent()
	if column.get_node_or_null("ReadBill") != null or BillDossier.sections(_bill).is_empty():
		return
	var button := Button.new()
	button.name = "ReadBill"
	button.text = Text.say("level_intro.read_bill")
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(_open_dossier)
	column.add_child(button)
	column.move_child(button, _lean_row.get_index())


func _open_dossier() -> void:
	if _dossier == null:
		_dossier = Overlay.new()
		_dossier.name = "BillDossier"
		add_child(_dossier)
	var rows: Array[Control] = []
	for section: Dictionary in BillDossier.sections(_bill):
		rows.append(UiKit.heading(_dossier_heading(str(section["field"]))))
		rows.append(UiKit.line(str(section["text"])))
	var leans := BillDossier.party_leans(_bill, DataDB.parties)
	var lean_lines: Array[String] = []
	for disposition: String in ["Supportive", "Opposed", "Neutral"]:
		var names: Array = leans[disposition]
		if names.is_empty():
			continue
		var joined := ", ".join(PackedStringArray(names))
		match disposition:
			"Supportive": lean_lines.append(Text.say("dossier.supportive", {"parties": joined}))
			"Opposed": lean_lines.append(Text.say("dossier.opposed", {"parties": joined}))
			_: lean_lines.append(Text.say("dossier.neutral", {"parties": joined}))
	if not lean_lines.is_empty():
		rows.append(UiKit.heading(Text.say("dossier.parties")))
		for line: String in lean_lines:
			rows.append(UiKit.line(line))
	_dossier.open(str(_bill.get("bill_name", "")), rows)


## Each section's heading, key by key so the exporter can see every one.
func _dossier_heading(field: String) -> String:
	match field:
		"bill_description": return Text.say("dossier.what")
		"who_gains": return Text.say("dossier.who_gains")
		"who_pays": return Text.say("dossier.who_pays")
		"case_for": return Text.say("dossier.case_for")
		"case_against": return Text.say("dossier.case_against")
		"main_risk": return Text.say("dossier.main_risk")
		_: return Text.say("dossier.middle_ground")
