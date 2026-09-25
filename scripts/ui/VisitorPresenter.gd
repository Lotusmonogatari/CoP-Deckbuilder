class_name VisitorPresenter
extends RefCounted
## Who is in the room, and how they took your answer.
##
## A near-twin of OpponentPresenter, considerably simpler: a visitor has no
## intent to telegraph and no support bar to read a mood off of, so the face
## is driven directly by the question they just asked rather than worked out
## from battle state. "neutral" while they're waiting on an answer, then
## "gaining" or "damaged" once they have one — reaction_right/reaction_wrong
## are prose (data/visitor_questions.json, e.g. "Nods approvingly."), shown
## as the response line under the portrait, not an expression keyword
## themselves.
##
## THE ART DOES NOT HAVE TO EXIST — same ArtLoader fallback as every other
## portrait in the game.

const NEUTRAL := ArtLoader.NEUTRAL
const GAINING := ArtLoader.GAINING
const DAMAGED := ArtLoader.DAMAGED

var _portrait: Control
var _name_label: Label
var _title_label: Label


func _init(portrait: Control, name_label: Label, title_label: Label) -> void:
	_portrait = portrait
	_name_label = name_label
	_title_label = title_label


## A new visitor, waiting on their question to be answered.
func show_visitor(visitor: Dictionary) -> void:
	var visitor_id := str(visitor.get("visitor_id", ""))
	_portrait.kind = PlaceholderArt.Kind.CHARACTER
	_portrait.art_id = visitor_id
	_portrait.expression = NEUTRAL
	_name_label.text = str(visitor.get("name_en", "Visitor"))
	var title := str(visitor.get("title", ""))
	_title_label.text = title
	_title_label.visible = not title.is_empty()


## How they took the answer just given — GAINING for correct, DAMAGED
## otherwise, the same pairing PlayerPortraitPresenter already uses for a
## card that won or lost the room.
func react(correct: bool) -> void:
	_portrait.expression = GAINING if correct else DAMAGED
