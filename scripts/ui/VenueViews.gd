class_name VenueViews
extends RefCounted
## The pieces the Capitol venues screens are drawn from (P16, 2026-11-23): a suit chip, a venue card, the speaker row and tip box of a
## line pop-up, a tip row. They draw what they are given; nothing here reads a rule. The sentences are Text rows.

## The colour of each suit's chip (a drawing choice, not content).
const SUIT_COLORS := {"Earnest": Color("2f5f8f"), "Emotional": Color("b03a2e"), "Appeal": Color("9c5a1a"), "Data Driven": Color("3a7d5a"),
	"Divisive": Color("5b3a8c"), "Duplicitous": Color("5a5a5a")}


## A small coloured plate holding the suit's name.
static func suit_chip(suit: String) -> Control:
	var holder := PanelContainer.new()
	holder.name = "SuitChip_" + suit.replace(" ", "")
	var box := StyleBoxFlat.new()
	box.bg_color = SUIT_COLORS.get(suit, Color("444444"))
	box.content_margin_left = 14.0
	box.content_margin_right = 14.0
	box.content_margin_top = 4.0
	box.content_margin_bottom = 4.0
	holder.add_theme_stylebox_override("panel", box)
	var label := Label.new()
	label.text = suit
	label.add_theme_color_override("font_color", Color.WHITE)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.set_meta(UiKit.ONE_LINE_META, true)   # the popup wrapper must not break a chip's name into letters
	holder.add_child(label)
	holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return holder


## The suit as a phrase that ends "responds to ...": "data-driven rhetoric" (Cameron, 2026-11-23: each suit needs grammatical wording).
## Literal Text keys, one for each suit, so the exporter can check each exists.
static func rhetoric_phrase(suit: String) -> String:
	match suit:
		"Earnest": return Text.say("tips.rhetoric_earnest")
		"Emotional": return Text.say("tips.rhetoric_emotional")
		"Appeal": return Text.say("tips.rhetoric_appeal")
		"Data Driven": return Text.say("tips.rhetoric_data_driven")
		"Divisive": return Text.say("tips.rhetoric_divisive")
		"Duplicitous": return Text.say("tips.rhetoric_duplicitous")
	return suit


## The name a tip is about: the stage's name or the person's.
static func tip_target_name(tip: Dictionary) -> String:
	var target := str(tip.get("target", ""))
	if str(tip.get("kind", "")) == RhetoricTips.STAGE:
		return str(DataDB.get_stage(target).get("name_en", target))
	return str(DataDB.get_opponent(target).get("name", target))


## "Heard in the Cafeteria" / "Overheard in the Gardens".
static func heard_text(tip: Dictionary, short: bool = false) -> String:
	var gardens := str(tip.get("where", "")) == "gardens"
	if short:
		return Text.say("tips.briefing_from_gardens" if gardens else "tips.briefing_from")
	return Text.say("tips.heard_gardens" if gardens else "tips.heard_cafeteria")


## The tip box of a line pop-up: its heading, "{target} responds to" with the suit chip, and what saving it does.
static func tip_box(hint: Dictionary, where: String) -> Control:
	var box := PanelContainer.new()
	box.name = "TipBox"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.20, 0.45, 0.32, 0.10)
	style.border_color = Color("3a7d5a")
	style.set_border_width_all(3)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	box.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	box.add_child(column)
	var heading := UiKit.line(Text.say("venue.tip_heading_gardens" if where == "gardens" else "venue.tip_heading_cafeteria"), "SmallLabel")
	heading.name = "TipHeading"
	heading.custom_minimum_size.x = 0.0
	column.add_child(heading)
	var target := {"kind": hint.get("kind", ""), "target": hint.get("target", "")}
	var rhetoric := rhetoric_phrase(str(hint.get("suit", "")))
	var words := Text.say("venue.tip_responds_stage", {"target": tip_target_name(target), "rhetoric": rhetoric}) \
		if str(hint.get("kind", "")) == RhetoricTips.STAGE \
		else Text.say("venue.tip_responds", {"target": tip_target_name(target), "rhetoric": rhetoric})
	var sentence := UiKit.line(words, "HeaderLabel")
	sentence.name = "TipSentence"
	sentence.custom_minimum_size.x = 0.0
	column.add_child(sentence)
	var saved := UiKit.line(Text.say("venue.tip_saved_opponent", {"name": tip_target_name(target)})
		if str(hint.get("kind", "")) == RhetoricTips.OPPONENT else Text.say("venue.tip_saved"), "SmallLabel")
	saved.custom_minimum_size.x = 0.0
	column.add_child(saved)
	return box


## The speaker of a line: a portrait beside the quote and "— Name" with the party's colour, or just the words for narration.
static func speaker_row(text: String, speaker_id: String, narration_lead: String = "") -> Control:
	var column := VBoxContainer.new()
	column.name = "LineBody"
	column.add_theme_constant_override("separation", 10)
	if not narration_lead.is_empty():
		var lead := UiKit.line(narration_lead, "SmallLabel")
		lead.custom_minimum_size.x = 0.0
		column.add_child(lead)
	var quote := UiKit.line(text if speaker_id.is_empty() and narration_lead.is_empty() else "“%s”" % text)
	quote.name = "LineText"
	quote.custom_minimum_size.x = 0.0
	if speaker_id.is_empty():
		column.add_child(quote)
		return column
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	var who := _speaker_facts(speaker_id)
	if not bool(who["colleague"]):
		var portrait := PlaceholderArt.new()
		portrait.name = "SpeakerPortrait"
		portrait.kind = PlaceholderArt.Kind.CHARACTER
		portrait.art_id = speaker_id
		portrait.custom_minimum_size = Vector2(150, 200)
		portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		row.add_child(portrait)
	var words := UiKit.tight_column()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_child(quote)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 10)
	if who["color"] != null:
		var swatch := ColorRect.new()
		swatch.name = "PartySwatch"
		swatch.color = who["color"]
		swatch.custom_minimum_size = Vector2(26, 26)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		name_row.add_child(swatch)
	var name_label := UiKit.line("— " + str(who["name"]), "HeaderLabel")
	name_label.name = "SpeakerName"
	name_label.custom_minimum_size.x = 0.0
	name_row.add_child(name_label)
	words.add_child(name_row)
	if not str(who["detail"]).is_empty():
		var detail := UiKit.line(str(who["detail"]), "SmallLabel")
		detail.custom_minimum_size.x = 0.0
		words.add_child(detail)
	row.add_child(words)
	column.add_child(row)
	return column


## {name, detail, color, colleague} for a speaker ID: an opponent, a staff member, a visitor, or "colleague".
static func _speaker_facts(speaker_id: String) -> Dictionary:
	if speaker_id == "colleague":
		return {"name": Text.say("venue.speaker_colleague"), "detail": "", "color": null, "colleague": true}
	match DecisionScenes.person_kind(speaker_id):
		"opponent":
			var opponent := DataDB.get_opponent(speaker_id)
			var party_name := PartyDisplay.party_name(opponent)
			var party := DataDB.get_party(party_name) if not party_name.is_empty() else {}
			var title := OpponentDisplay.title_for(opponent)
			return {"name": str(opponent.get("name", speaker_id)), "detail": title if party_name.is_empty() else "%s · %s" % [party_name, title],
				"color": PartyDisplay.color_for(party) if not party.is_empty() else null, "colleague": false}
		"staff":
			var staff := DataDB.get_staff(speaker_id)
			return {"name": str(staff.get("name", speaker_id)), "detail": str(staff.get("role", "")), "color": null, "colleague": false}
		"visitor":
			var visitor := DataDB.get_visitor(speaker_id)
			return {"name": str(visitor.get("name_en", speaker_id)), "detail": str(visitor.get("title", "")), "color": null, "colleague": false}
	return {"name": speaker_id, "detail": "", "color": null, "colleague": false}


## One tip in the Tips you hold list: the target, the suit chip, where it was heard and the days left ("Last day" in the fall colour).
static func tip_row(look: Dictionary, tip: Dictionary, days_left: int) -> Control:
	var column := VBoxContainer.new()
	column.name = "TipRow_" + str(tip.get("target", ""))
	column.add_theme_constant_override("separation", 4)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	var name_label := UiKit.line(tip_target_name(tip), "HeaderLabel")
	name_label.custom_minimum_size.x = 0.0
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(name_label)
	top.add_child(suit_chip(str(tip.get("suit", ""))))
	column.add_child(top)
	var bottom := HBoxContainer.new()
	var heard := UiKit.line(heard_text(tip), "SmallLabel")
	heard.custom_minimum_size.x = 0.0
	heard.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(heard)
	var last := days_left <= 1
	var left := UiKit.line(Text.say("tips.last_day") if last else Text.say("tips.days_left", {"count": days_left}), "SmallLabel")
	left.name = "DaysLeft"
	left.custom_minimum_size.x = 0.0
	left.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if last:
		left.add_theme_color_override("font_color", Color("b03a2e"))
	bottom.add_child(left)
	column.add_child(bottom)
	return column


## The tip mark under a room in the level briefing: "Responds to [suit] · heard in the Cafeteria". `who` names an opponent's tip.
static func briefing_mark(tip: Dictionary, show_name: bool) -> Control:
	var row := HFlowContainer.new()
	row.name = "TipMark_" + str(tip.get("target", ""))
	row.add_theme_constant_override("h_separation", 10)
	if show_name:
		var name_label := UiKit.line(tip_target_name(tip), "SmallLabel")
		name_label.custom_minimum_size.x = 0.0
		row.add_child(name_label)
	var lead := UiKit.line(Text.say("tips.briefing_responds"), "SmallLabel")
	lead.custom_minimum_size.x = 0.0
	row.add_child(lead)
	row.add_child(suit_chip(str(tip.get("suit", ""))))
	var from := UiKit.line("· " + heard_text(tip, true), "SmallLabel")
	from.custom_minimum_size.x = 0.0
	row.add_child(from)
	return row
