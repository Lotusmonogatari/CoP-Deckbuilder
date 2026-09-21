class_name OpponentPresenter
extends RefCounted
## Who is opposite, what they are about to do, and how they are taking it.
##
## Owns the speaker row: the portrait, the name, the intent line and both
## guard readouts. Takes the battle state in and draws it. Makes no rules
## decisions — every number here has already been decided by BattleEngine.
##
## WHY IT IS ITS OWN FILE
## Because this is where a face reacts. An opponent about to attack should
## look like it, and one who has just lost half the room should look like
## that too. Deciding which face to wear is a job with its own rules, and it
## does not belong tangled in a screen that is also dealing cards.
##
## THE ART DOES NOT HAVE TO EXIST. ArtLoader falls back to a labelled
## placeholder for any portrait that has not been drawn, and the placeholder
## is coloured from the ID, so an expression that has no PNG still visibly
## changes. That means the wiring can be finished and tested now and simply
## becomes a face when Cameron draws one.

## Faces, as the brief names them. A portrait file is
## {ID}_{expression}.png, so these are the words that reach the filename.
const NEUTRAL := "neutral"
const ATTACKING := "attacking"
const CONFIDENT := "confident"
const FLUSTERED := "flustered"
const DEFEATED := "defeated"

## How far an opponent's support has to fall, as a share of where they
## started, before they look rattled rather than composed.
const FLUSTERED_BELOW := 0.75

var _portrait: Control
var _name_label: Label
var _intent_label: Label
var _guard_label: Label
var _opponent_guard_label: Label

## Where the opponent stood when this bout began, so "losing badly" can mean
## something. Reset whenever the opponent changes.
##
## `_watched_anyone` rather than comparing `_watching` against "": an opponent
## whose ID happened to be blank would match the starting value, the opening
## support would never be recorded, and they could never look rattled. Every
## opponent in the data has an ID today, so this cannot happen — but it would
## fail silently if one ever lost it.
var _opened_on := 0
var _watching := ""
var _watched_anyone := false


func _init(portrait: Control, name_label: Label, intent_label: Label,
		guard_label: Label, opponent_guard_label: Label) -> void:
	_portrait = portrait
	_name_label = name_label
	_intent_label = intent_label
	_guard_label = guard_label
	_opponent_guard_label = opponent_guard_label

	# A reporter's question is a sentence rather than "Attacking · −6", so
	# the line it sits on has to be able to wrap.
	if _intent_label != null:
		_intent_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


## Draws the whole row for this moment of the battle.
func show_state(engine: BattleEngine) -> void:
	var state := engine.state

	if engine.is_press_conference():
		_intent_label.text = str(
			engine.current_question().get("text", "That was the last question."))
		_show_journalist(engine.current_question())
	else:
		_intent_label.text = IntentRunner.describe(engine.current_intent())
		_show_opponent(engine)

	_show_guards(state)


## The name of whoever is opposite, for a sentence to use.
##
## Empty in a press conference: the journalist asking is named in the speaker
## row, but nobody there is an opponent whose support can be taken.
static func display_name(engine: BattleEngine) -> String:
	if engine.is_press_conference():
		return ""
	return str(engine.current_opponent().get("name", ""))


func _show_opponent(engine: BattleEngine) -> void:
	var opponent := engine.current_opponent()

	_portrait.show()
	_name_label.show()

	# Written out every refresh rather than only when the opponent changes.
	# It used to skip the first one — the screen's idea of who was opposite
	# was set from the same config the engine got, so they matched before the
	# name had ever been written and the player was left looking at the word
	# "Opponent". Redrawing a label is not worth guarding against.
	var caption := engine.opponent_caption()
	var who := str(opponent.get("name", "Visitor A"))
	# "Opponent B  ·  2 of 3", so the player knows how far through a
	# committee they are without counting.
	_name_label.text = who if caption.is_empty() else "%s  ·  %s" % [who, caption]

	_wear(str(opponent.get("opp_id", "")), _face_for(engine))


## Puts the reporter who asked this question in the opponent's place.
##
## They are not an opponent — they never take a turn — but they are who is
## speaking, and a question with a name on it is easier to answer than one
## that arrives from an empty chair.
func _show_journalist(question: Dictionary) -> void:
	if question.is_empty():
		# Between the last answer and the outcome panel there is nobody left
		# to show.
		_portrait.hide()
		_name_label.hide()
		return

	var journalist := DataDB.get_journalist(str(question.get("asked_by", "")))
	if journalist.is_empty():
		_portrait.hide()
		_name_label.hide()
		return

	_portrait.show()
	_name_label.show()
	_name_label.text = str(journalist.get("name", "Visitor A"))
	# A reporter asking a question is doing their job, not emoting at you.
	_wear(str(journalist.get("journalist_id", "")), NEUTRAL)


## Which face this opponent is wearing, from what is happening to them.
##
## Read in order of how much it matters: being finished beats being rattled,
## and being rattled beats whatever they intend to do next.
func _face_for(engine: BattleEngine) -> String:
	var state := engine.state
	var opponent := engine.current_opponent()

	# A new opponent: remember where they started, so a fall can be measured.
	var opp_id := str(opponent.get("opp_id", ""))
	if not _watched_anyone or opp_id != _watching:
		_watched_anyone = true
		_watching = opp_id
		_opened_on = state.bar.opponent if state.bar != null else 0

	if state.outcome == "win":
		return DEFEATED

	if state.bar != null and _opened_on > 0:
		var share := float(state.bar.opponent) / float(_opened_on)
		if share <= FLUSTERED_BELOW:
			return FLUSTERED

	# Otherwise, what they are about to do. An intent is known a turn ahead,
	# so this is the face of somebody winding up rather than reacting.
	match str(engine.current_intent().get("verb", "none")):
		"attack", "lean_down": return ATTACKING
		"block": return CONFIDENT
		_: return NEUTRAL


func _wear(art_id: String, expression: String) -> void:
	if not (_portrait is PlaceholderArt):
		return
	var art := _portrait as PlaceholderArt
	art.kind = PlaceholderArt.Kind.CHARACTER
	art.art_id = art_id
	art.expression = expression


func _show_guards(state: BattleState) -> void:
	# How much of the next attack the player has already covered, and how
	# much more would fit. Guard is a bank with a ceiling, and a playtest
	# asked for the ceiling: without it there is no way to know whether
	# another Guard card is worth playing or would be thrown away.
	#
	# Always shown, including at zero. It used to hide itself when empty,
	# which made an empty bank look like no bank at all — and it reads as a
	# pair with "Gaffes 0 / 6" beside it.
	_guard_label.text = "Guard %d / %d" % [state.block, state.guard_cap]
	_guard_label.visible = true

	# And theirs, on the same ceiling.
	_opponent_guard_label.text = "They guard %d / %d" % [
		state.opponent_block, state.guard_cap]
	_opponent_guard_label.visible = state.opponent_block > 0
