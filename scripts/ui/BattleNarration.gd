class_name BattleNarration
extends RefCounted
## Every sentence the battle screen says about a move, in one place.
##
## This is presentation, not rules — it decides nothing and changes nothing.
## It exists as its own file for two reasons. The player's move and the
## opponent's move have to use the SAME grammar, or the screen reads as two
## different games; and being pure static functions, the wording can be
## tested without a scene tree, which is how the room-versus-level rule below
## stays honest.
##
## THE ROOM VERSUS THE LEVEL. A stage measures winning in one of two ways and
## the sentence has to match:
##
##   A room of people — the floor debate, the committee, the caucus. There
##   are seats, and winning one means somebody changed their mind. "3 seats
##   won over." Saying "raised by 3" here would hide the fact that the points
##   on a card are a budget and people cost more than a point each.
##
##   A level that rises — the press conference. There is nobody to win over;
##   there is a mood in the room going up and down. "Press tone raised by 3."
##   Saying "3 press tone won over" is what Cameron actually saw on screen,
##   and it is nonsense.


## True where the bar counts people rather than measuring a mood.
static func is_a_room(state: BattleState) -> bool:
	if state.committee != null:
		return true
	if state.bar == null:
		return false
	return state.bar.model == BarModel.Model.SHARED_POOL


## True where the bar should be read as a percentage rather than a headcount.
##
## Cameron's reason: a caucus is 20 people in one party and 10 in another,
## and he does not want to restate the arithmetic every time the party's
## size changes. The bar is already 0-100, so the percentage is the number
## that is already there — this is a label, not a conversion.
static func is_percent(stage: Dictionary) -> bool:
	return bool(stage.get("bar_as_percent", false))


## The noun for one unit of the bar: "seat", "seats", or "%".
static func unit_noun(stage: Dictionary, count: int) -> String:
	if is_percent(stage):
		return "%"
	var unit := str(stage.get("bar_unit", "support")).to_lower()
	if count == 1 and unit.ends_with("s"):
		return unit.substr(0, unit.length() - 1)
	return unit


## "3 seats", "1 seat", "3%" — a quantity with its unit attached.
static func quantity(stage: Dictionary, count: int) -> String:
	if is_percent(stage):
		return "%d%%" % count
	return "%d %s" % [count, unit_noun(stage, count)]


## What the player's card just did.
##
## The card's numbers are a budget, not an outcome: the undecided come across
## for a point each and the opposition cost one, two or three, so a push of
## five points can win five people or three. Saying which, right afterwards,
## is the difference between a rule the player learns and a screen they
## distrust.
static func player_move(result: Dictionary, stage: Dictionary,
		state: BattleState, opponent_name: String) -> String:
	var applied: Dictionary = result.get("applied", {})
	var effect: Dictionary = result.get("effect", {})
	var parts: Array[String] = []

	# A finished debater comes FIRST. Cameron played a card that beat
	# opponent four and was told only "1 point short", which described the
	# leftover while silently skipping the win.
	var bout: Dictionary = result.get("bout_won", {})
	if not bout.is_empty():
		parts.append(_bout_won(bout))

	var wanted := int(effect.get("self_plus", 0))
	var won := int(applied.get("gained", 0))
	if wanted > 0:
		parts.append(_gained(stage, state, applied, wanted, won,
			bout.is_empty(), opponent_name))

	var stopped := int(applied.get("guard_stopped", 0))
	if stopped > 0:
		parts.append("%s guard stopped %d" % [_their(opponent_name), stopped])

	var lost := int(applied.get("opponent_lost", 0))
	if lost > 0:
		parts.append("%s argued away from %s"
			% [quantity(stage, lost), _them(opponent_name)])

	var gaffe := int(applied.get("gaffe", 0))
	if gaffe > 0:
		parts.append("%d gaffe%s against you" % [gaffe, "" if gaffe == 1 else "s"])

	return _sentence(parts)


## What the opponent's move just did.
##
## The engine has always computed this and thrown it away: `end_turn` returns
## the whole result and no screen ever read it, so the opponent guarded,
## attacked and won people over in complete silence.
static func opponent_move(opponent_result: Dictionary, stage: Dictionary,
		state: BattleState, opponent_name: String) -> String:
	if opponent_result.is_empty():
		return ""

	var who := _name_or(opponent_name, "They")
	var parts: Array[String] = []

	match str(opponent_result.get("verb", "none")):
		"attack":
			var absorbed := int(opponent_result.get("absorbed", 0))
			var damage := int(opponent_result.get("damage", 0))
			if absorbed > 0:
				parts.append("your guard absorbed %d" % absorbed)
			if damage > 0:
				parts.append("%s lost to %s" % [quantity(stage, damage), _them(opponent_name)])
			elif absorbed > 0:
				parts.append("nothing got through")
			else:
				parts.append("the attack found nothing to take")

		"gain":
			var gained := int(opponent_result.get("gained", 0))
			if gained <= 0:
				return "%s pressed the case and won nobody over." % who
			var split: Dictionary = opponent_result.get("gain_split", {})
			parts.append("won over %s" % quantity(stage, gained))
			var detail := _split_detail(stage, split, "you")
			if not detail.is_empty():
				parts.append(detail)

		"block":
			var guard := int(opponent_result.get("guard", 0))
			if guard <= 0:
				return "%s could not guard any further." % who
			parts.append("developed %d guard" % guard)

		"lean_down":
			var member: Dictionary = opponent_result.get("member", {})
			var moved: int = abs(int(member.get("moved", 0)))
			if moved <= 0:
				return "%s leaned on the panel and moved nobody." % who
			var member_name := str(member.get("name", "a member"))
			parts.append("leaned on %s, %d against you" % [member_name, moved])

		_:
			return "%s waited." % who

	# Joined directly rather than through _sentence: that capitalises the
	# first letter, and lowercasing it back again would also flatten any
	# name inside the clause ("2 seats lost to ito").
	return "%s: %s." % [who, ", ".join(parts)]


# ---------------------------------------------------------------------------
# The pieces
# ---------------------------------------------------------------------------

static func _gained(stage: Dictionary, state: BattleState, applied: Dictionary,
		wanted: int, won: int, say_shortfall: bool, opponent_name: String) -> String:
	# A level that rises has nobody to win over: it goes up, and by how much.
	if not is_a_room(state):
		var unit := str(stage.get("bar_unit", "support"))
		return "%s raised by %d" % [unit, won] if won > 0 else "%s did not move" % unit

	var line := "%s won over" % quantity(stage, won)

	var split: Dictionary = applied.get("gain_split", {})
	var detail := _split_detail(stage, split, _them(opponent_name))
	if not detail.is_empty():
		line += " — %s" % detail

	# The leftover. Cameron asked for "# nearly persuaded", but he also
	# decided last round that points which cannot pay for the next person
	# are LOST rather than banked — so "nearly" would promise progress that
	# does not exist. This says what actually happened instead.
	#
	# Suppressed when the card finished a debater: the win is the news, and
	# a shortfall line beside it is what confused him in the first place.
	var short := wanted - won
	if say_shortfall and short > 0 and won < wanted:
		line += ", %d point%s short of the next" % [short, "" if short == 1 else "s"]

	return line


## "2 from the undecided, 1 argued across" — who those people actually were.
static func _split_detail(stage: Dictionary, split: Dictionary, from_whom: String) -> String:
	if split.is_empty():
		return ""

	var undecided := int(split.get("from_undecided", 0))
	var other := int(split.get("from_other_side", 0))

	# Both halves only matter when there are two of them. "3 from the
	# undecided" when that is all there was adds a clause and no information.
	if other <= 0:
		return ""
	if undecided <= 0:
		return "all of them off %s" % from_whom
	return "%d from the undecided, %d off %s" % [undecided, other, from_whom]


static func _bout_won(bout: Dictionary) -> String:
	var finished := str(bout.get("finished", ""))
	var remaining := int(bout.get("remaining", 0))
	var who := _name_or(finished, "That opponent")

	if remaining <= 0:
		return "%s is finished" % who

	var next_up := _name_or(str(bout.get("next", "")), "the next")
	return "%s is finished — %s rises" % [who, next_up]


## The possessive for whoever is opposite: their actual name where there is
## one, so the screen stops saying "them" about a named character.
static func _their(opponent_name: String) -> String:
	var name := opponent_name.strip_edges()
	return "their" if name.is_empty() else "%s's" % name


static func _them(opponent_name: String) -> String:
	var name := opponent_name.strip_edges()
	return "them" if name.is_empty() else name


static func _name_or(name: String, fallback: String) -> String:
	var trimmed := name.strip_edges()
	return fallback if trimmed.is_empty() else trimmed


## Joins the clauses and closes the sentence, capitalising only the first
## letter. Godot's String.capitalize() title-cases every word, which turned
## "3 seats won over" into "3 Seats Won Over".
static func _sentence(parts: Array[String]) -> String:
	if parts.is_empty():
		return ""
	var line := ", ".join(parts)
	return line.substr(0, 1).to_upper() + line.substr(1) + "."
