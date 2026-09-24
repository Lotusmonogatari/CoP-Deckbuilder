class_name PlayerPortraitPresenter
extends RefCounted
## The player's own face, in the corner inset beside the opponent.
##
## Unlike OpponentPresenter, nothing here is inferred ahead of time from an
## "intent" — the player controls their own turn, so their face reacts to
## what they just did. BattleScreen calls react_to_card() the moment a card
## resolves and react_to_opponent() once the opponent's turn is read; both
## flash an expression for FLINCH_SECONDS and settle back to neutral, the
## same bargain OpponentPresenter.flinch() makes for a hit landing.
##
## THE ART DOES NOT HAVE TO EXIST. See ArtLoader; a placeholder square with
## no label reacts exactly the way a drawn face would.

const NEUTRAL := ArtLoader.NEUTRAL
const ATTACKING := ArtLoader.ATTACKING
const GUARDING := ArtLoader.GUARDING
const GAINING := ArtLoader.GAINING
const DAMAGED := ArtLoader.DAMAGED
const VICTORY := ArtLoader.VICTORY

## How long a reaction shows before settling back to neutral.
const FLINCH_SECONDS := 0.9

var _portrait: Control
var _stage_id := ""


func _init(portrait: Control) -> void:
	_portrait = portrait


## Called when a stage opens (or reopens on the next one): settles on the
## resting neutral face for whoever the protagonist is and this stage.
func show_state(stage_id: String = "") -> void:
	_stage_id = stage_id
	_wear(NEUTRAL)


## The card just resolved. See face_for_card() for which face wins when a
## card does more than one of these at once.
func react_to_card(applied: Dictionary) -> void:
	var face := face_for_card(applied)
	if face != NEUTRAL:
		_flash(face)


## The opponent's turn just resolved.
func react_to_opponent(opponent_result: Dictionary) -> void:
	var face := face_for_opponent_move(opponent_result)
	if face != NEUTRAL:
		_flash(face)


## The stage just ended in a win: settle on VICTORY rather than fading back
## to neutral, the same way OpponentPresenter settles a beaten opponent on
## DEFEATED.
func show_victory() -> void:
	_wear(VICTORY)


## Pure: which face a just-played card earns, from BattleEngine.play_card()'s
## own "applied" dictionary. Read in order of how much it matters: arguing
## the room away from the opponent beats winning it over beats merely
## banking guard — the same "what actually happened here" ordering
## OpponentPresenter._face_for() uses for the room falling out from under
## the opponent.
static func face_for_card(applied: Dictionary) -> String:
	if int(applied.get("opponent_lost", 0)) > 0:
		return ATTACKING
	if int(applied.get("gained", 0)) > 0:
		return GAINING
	if int(applied.get("guard", 0)) > 0:
		return GUARDING
	return NEUTRAL


## Pure: which face the opponent's own resolved move earns the PLAYER. Only
## a hit that actually got through guard counts — an attack fully absorbed
## already has its own line in the narration (GuardLabel says so too), and
## does not need a face on top of it.
static func face_for_opponent_move(opponent_result: Dictionary) -> String:
	if str(opponent_result.get("verb", "none")) == "attack" \
			and int(opponent_result.get("damage", 0)) > 0:
		return DAMAGED
	return NEUTRAL


func _flash(expression: String) -> void:
	_wear(expression)
	if not (_portrait is PlaceholderArt) or not _portrait.is_inside_tree():
		return
	var mine := expression
	await _portrait.get_tree().create_timer(FLINCH_SECONDS).timeout
	# Unless something else (another reaction, a new stage) changed the face
	# meanwhile.
	if is_instance_valid(_portrait) and (_portrait as PlaceholderArt).expression == mine:
		_wear(NEUTRAL)


func _wear(expression: String) -> void:
	if not (_portrait is PlaceholderArt):
		return
	var art := _portrait as PlaceholderArt
	art.kind = PlaceholderArt.Kind.CHARACTER
	art.art_id = str(DataDB.player.get("player_id", ""))
	art.stage_id = _stage_id
	art.expression = expression
