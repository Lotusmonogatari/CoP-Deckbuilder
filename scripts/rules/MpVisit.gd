class_name MpVisit
extends RefCounted
## The member visit (influence building, 2026-10-19, Cameron). In a patron
## Flagship the player may receive a member of parliament from a party that
## still has seats outside the player's side. A short exchange of questions
## (answered in rhetorical styles) sets a rapport score, the rapport changes
## the starting support of a one-on-one fight, and winning the fight wins the
## member over: one seat for the player's pick, for that vote only (BillAssist).
##
## Every member in the Opponents tab is one seat (a party's members add up to
## its seats), so a member won over is literally one seat.
##
## Pure and UI-free (CLAUDE.md section 12): the caller supplies the people,
## the question pool and the random generator.

const VISIT_STAGE := "ST260"
const FIGHT_STAGE := "ST261"
const STYLES := ["Earnest", "Emotional", "Appeal", "Data Driven", "Divisive", "Duplicitous"]
const STRONG := "S"
const MEDIUM := "M"
const WEAK := "W"


## The first party in `visit_parties` (priority order) that has at least one
## seat outside `pick`, i.e. is not already entirely on the player's side.
## "" when every listed party is maxed out (no visit is offered).
static func pick_party(visit_parties: Array, positions: Array, pick: String = "Yes") -> String:
	for party_id: Variant in visit_parties:
		for position: Dictionary in positions:
			if str(position.get("party_id", "")) != str(party_id):
				continue
			var outside := 0
			for bucket: String in FloorVoteEngine.BUCKETS:
				if bucket != pick:
					outside += int(position.get("votes_%s" % bucket.to_lower(), 0))
			if outside > 0:
				return str(party_id)
	return ""


## Members of `party_name`: opponents with that party (MPs sit on committees).
static func members_of(opponents: Array, party_name: String) -> Array:
	return opponents.filter(func(opponent: Dictionary) -> bool:
		return str(opponent.get("party", "")).strip_edges() == party_name)


## One member to visit: from the party's members on the bill's hearing
## committee when there are any (`committee_name` is the committee's name, the
## same text an MP's Role holds), otherwise any member; leaning toward people
## the player has met the fewest times (PeopleDraw).
static func pick_member(opponents: Array, party_name: String, committee_name: String,
		faced: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var pool := members_of(opponents, party_name)
	var on_committee: Array = pool.filter(func(opponent: Dictionary) -> bool:
		return str(opponent.get("role", "")).strip_edges() == committee_name)
	if not on_committee.is_empty():
		pool = on_committee
	var drawn := PeopleDraw.pick(pool, "opp_id", faced, 1, [], rng)
	return drawn[0] if not drawn.is_empty() else {}


## How a style lands with this member: Strong for either of their first two
## styles, Medium for their third, Weak for any other.
static func grade(member: Dictionary, style: String) -> String:
	if style == str(member.get("suit_1", "")) or style == str(member.get("suit_2", "")):
		return STRONG
	if style == str(member.get("suit_3", "")):
		return MEDIUM
	return WEAK


## Rapport points for a grade (levers: strong, medium, weak).
static func points(grade_letter: String, strong: int, medium: int, weak: int) -> int:
	match grade_letter:
		STRONG: return strong
		MEDIUM: return medium
		_: return weak


## Four distinct styles for one question, at least one of them a style the
## member favors, so every question has a good answer. Order is shuffled.
static func choose_styles(member: Dictionary, rng: RandomNumberGenerator) -> Array:
	var favored: Array = []
	for key: String in ["suit_1", "suit_2"]:
		var style := str(member.get(key, ""))
		if STYLES.has(style) and not favored.has(style):
			favored.append(style)
	var pool: Array = STYLES.duplicate()
	_shuffle(pool, rng)
	var chosen: Array = []
	if not favored.is_empty():
		chosen.append(favored[rng.randi_range(0, favored.size() - 1)])
	for style: Variant in pool:
		if chosen.size() >= 4:
			break
		if not chosen.has(style):
			chosen.append(style)
	_shuffle(chosen, rng)
	return chosen


## `count` questions: [{"text", "choices": [{"letter", "style", "text", "grade"}]}].
## `stems` are Visit Questions rows (text_en with {component}); `answers` are
## Visit Answers rows (style, line_en). A stem is not repeated in one visit.
static func build_questions(member: Dictionary, stems: Array, answers: Array, count: int,
		component_phrase: String, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	var pool := stems.duplicate()
	_shuffle(pool, rng)
	for index in range(mini(count, pool.size())):
		var styles := choose_styles(member, rng)
		var choices: Array = []
		for slot in range(styles.size()):
			var style: String = styles[slot]
			var lines: Array = answers.filter(func(row: Dictionary) -> bool:
				return str(row.get("style", "")) == style)
			var line := ""
			if not lines.is_empty():
				line = str((lines[rng.randi_range(0, lines.size() - 1)] as Dictionary).get("line_en", ""))
			choices.append({
				"letter": "ABCD"[slot], "style": style,
				"text": line.replace("{component}", component_phrase),
				"grade": grade(member, style),
			})
		out.append({
			"text": str((pool[index] as Dictionary).get("text_en", "")).replace("{component}", component_phrase),
			"choices": choices,
		})
	return out


## The member's styles in order of preference, without repeats (some members
## list the same style twice).
static func favored_styles(member: Dictionary) -> Array:
	var out: Array = []
	for key: String in ["suit_1", "suit_2", "suit_3"]:
		var style := str(member.get(key, ""))
		if STYLES.has(style) and not out.has(style):
			out.append(style)
	return out


## Whether a hired Policy Research Assistant is senior enough to brief the
## player (staff rank = the tier stored for the hire).
static func briefing_available(staff_hired: Dictionary, min_rank: int) -> bool:
	var hired: Variant = staff_hired.get("Policy Research Assistant")
	return hired is Dictionary and int((hired as Dictionary).get("tier", 0)) >= min_rank


## Starting support the player gets in the fight (negative for bad rapport).
static func start_bonus(rapport: int, per_point: int) -> int:
	return rapport * per_point


static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for index in range(items.size() - 1, 0, -1):
		var swap := rng.randi_range(0, index)
		var held: Variant = items[index]
		items[index] = items[swap]
		items[swap] = held
