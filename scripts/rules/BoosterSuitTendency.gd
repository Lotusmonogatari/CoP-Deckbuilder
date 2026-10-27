class_name BoosterSuitTendency
extends RefCounted
## Which suits tend to please which organisations (2026-10-11, Cameron).
##
## Nothing in the data says "National Media likes Earnest". What pleases an
## organisation is a QUESTION'S OWN grade for the suit you answer with, and a
## question is tied to its organisations through its theme. So the tendency is
## read from the questions themselves: for each organisation, over every
## question that pleases it, a Strong grade counts +1, Medium 0, Weak -1, and
## the average is its score for that suit (-1 to +1). Pure arithmetic, no UI;
## the How to Play guide quotes the result, so it follows the workbook.

## All of these are Balance-tab levers ("Tendency: ..."): the minimum average
## for a suit, the minimum questions (a thin sample proves nothing), the most
## organisations per suit (the guide stays concise) and what S/M/W are worth.
static func points(grade: String) -> float:
	match grade:
		"S": return Levers.num("tendency_strong_points")
		"W": return Levers.num("tendency_weak_points")
	return Levers.num("tendency_medium_points")


## {suit: [{booster_id, score}]} best first, for the suits given. `questions`
## is questions.json (pool -> list of question dictionaries).
static func by_suit(questions: Dictionary, suits: Array) -> Dictionary:
	var totals := {}  # booster_id -> {suit: sum}
	var counts := {}  # booster_id -> questions
	for pool in questions.values():
		for question in (pool as Array):
			var grades: Dictionary = question.get("grades", {})
			for booster_id: String in (question.get("pleases_boosters", []) as Array):
				counts[booster_id] = int(counts.get(booster_id, 0)) + 1
				if not totals.has(booster_id):
					totals[booster_id] = {}
				for suit: String in suits:
					var sums: Dictionary = totals[booster_id]
					sums[suit] = float(sums.get(suit, 0.0)) + points(str(grades.get(suit, "M")))

	var out := {}
	for suit: String in suits:
		var rows: Array[Dictionary] = []
		for booster_id: String in counts:
			if int(counts[booster_id]) < Levers.whole("tendency_minimum_questions"):
				continue
			var score := float((totals[booster_id] as Dictionary).get(suit, 0.0)) / float(counts[booster_id])
			if score >= Levers.num("tendency_minimum_score"):
				rows.append({"booster_id": booster_id, "score": score})
		rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])
		out[suit] = rows.slice(0, Levers.whole("tendency_most_organizations_per_suit"))
	return out


## One line per suit: "Earnest: National Media, Ainu Language and Culture Foundation".
## A suit nobody leans towards is left out.
static func lines(questions: Dictionary, suits: Array, names: Dictionary,
		template: String = "{style}: {names}") -> Array[String]:
	var table := by_suit(questions, suits)
	var result: Array[String] = []
	for suit: String in suits:
		var who: Array[String] = []
		for row: Dictionary in (table.get(suit, []) as Array):
			who.append(str(names.get(row["booster_id"], row["booster_id"])))
		if not who.is_empty():
			result.append(template.replace("{style}", suit).replace("{names}", ", ".join(who)))
	return result


## Every suit's average for ONE organisation, over every question that pleases
## it: {suit: score} from -1 to +1. Unlike by_suit() this has no minimum
## sample or cut-off; the battle screen uses it to show which styles a backed
## organisation likes (2026-10-18, Cameron).
static func scores_for(questions: Dictionary, booster_id: String, suits: Array) -> Dictionary:
	var sums := {}
	var count := 0
	for pool in questions.values():
		for question in (pool as Array):
			if not (question.get("pleases_boosters", []) as Array).has(booster_id):
				continue
			count += 1
			var grades: Dictionary = question.get("grades", {})
			for suit: String in suits:
				sums[suit] = float(sums.get(suit, 0.0)) + points(str(grades.get(suit, "M")))
	var out := {}
	if count == 0:
		return out
	for suit: String in suits:
		out[suit] = float(sums.get(suit, 0.0)) / float(count)
	return out


## The suits an organisation likes and dislikes: {likes: [suit], dislikes:
## [suit]}, each at most two, strongest first, only past `edge` (0.25).
## Empty lists when fewer than MIN_QUESTIONS questions please it.
static func taste_of(questions: Dictionary, booster_id: String, suits: Array,
		edge: float = 0.25) -> Dictionary:
	var scores := scores_for(questions, booster_id, suits)
	var likes: Array = []
	var dislikes: Array = []
	if not scores.is_empty():
		var ordered: Array = scores.keys()
		ordered.sort_custom(func(a: String, b: String) -> bool: return scores[a] > scores[b])
		for suit: String in ordered:
			if scores[suit] >= edge and likes.size() < 2:
				likes.append(suit)
		ordered.reverse()
		for suit: String in ordered:
			if scores[suit] <= -edge and dislikes.size() < 2:
				dislikes.append(suit)
	return {"likes": likes, "dislikes": dislikes}
