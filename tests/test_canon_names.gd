extends GutTest
## Government bodies are named the way the canon names them (2026-11-02,
## Cameron): the eight ministries follow the committees and ministers
## ("Ministry of Finance", "Minister of the Environment"), and every committee
## is a real one ("Committee on Construction and Development"). A made-up
## "trade ministry" or "transport committee" in a question, cue or event fails
## here. A bare "the ministry" is fine: it names nobody.

## Ministries, in the words that follow "Ministry of" / "Minister of".
const MINISTRIES := ["Agriculture", "Construction and Development", "Ethics and Prosecution",
	"Finance", "Foreign Affairs", "Government Administration", "War", "the Environment"]
## Committees, in the words that follow "Committee on".
const COMMITTEES := ["Agriculture", "Construction and Development", "Ethics and Prosecution",
	"Finance", "Foreign Affairs", "Government Administration", "War", "the Environment",
	"the National Assembly"]
## A topic written as an adjective in front of "ministry" / "committee" is an
## invented body; the canon form is "Ministry of X" / "Committee on X".
const TOPICS := "finance|trade|defen[sc]e|health|education|transport|interior|justice|economy|fisher(?:y|ies)|welfare|labou?r|treasury|energy|industry|tourism|culture|customs|agriculture|foreign|war|environment|budget|ethics"


func _strings() -> Array:
	var found: Array = []
	for path: String in DirAccess.get_files_at("res://data"):
		if not path.ends_with(".json"):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/" + path))
		_walk(parsed, path, found)
	return found


func _walk(node: Variant, path: String, found: Array) -> void:
	if node is Dictionary:
		for value: Variant in (node as Dictionary).values():
			_walk(value, path, found)
	elif node is Array:
		for value: Variant in node:
			_walk(value, path, found)
	elif node is String:
		found.append([path, node])


func _starts_with_one_of(text: String, canon: Array) -> bool:
	for name: String in canon:
		if text.begins_with(name):
			return true
	return false


func test_a_named_ministry_or_minister_is_a_canon_one() -> void:
	var named := RegEx.create_from_string("\\b(?:Ministry|Minister) of ((?:the )?[A-Z][A-Za-z]*(?: (?:and|of|the) [A-Z][A-Za-z]*| [A-Z][A-Za-z]*)*)")
	for pair: Array in _strings():
		for hit in named.search_all(str(pair[1])):
			var topic := hit.get_string(1)
			assert_true(_starts_with_one_of(topic, MINISTRIES),
				"%s names '%s', which is not a canon ministry: %s" % [pair[0], topic, str(pair[1]).left(100)])


func test_no_ministry_is_named_by_topic_alone() -> void:
	var invented := RegEx.create_from_string("(?i)\\b(" + TOPICS + ")\\s+ministry\\b")
	for pair: Array in _strings():
		var hit := invented.search(str(pair[1]))
		assert_null(hit, "%s writes '%s'; use 'Ministry of ...': %s" % [
			pair[0], hit.get_string() if hit else "", str(pair[1]).left(100)])


func test_a_named_committee_is_a_canon_one() -> void:
	var named := RegEx.create_from_string("\\bCommittee on ((?:the )?[A-Z][A-Za-z]*(?: (?:and|of|the) [A-Z][A-Za-z]*| [A-Z][A-Za-z]*)*)")
	for pair: Array in _strings():
		for hit in named.search_all(str(pair[1])):
			var topic := hit.get_string(1)
			assert_true(_starts_with_one_of(topic, COMMITTEES),
				"%s names 'Committee on %s', which is not a canon committee: %s" % [pair[0], topic, str(pair[1]).left(100)])


func test_no_committee_is_named_by_topic_alone() -> void:
	var invented := RegEx.create_from_string("(?i)\\b(" + TOPICS + ")\\s+committee\\b")
	for pair: Array in _strings():
		var hit := invented.search(str(pair[1]))
		assert_null(hit, "%s writes '%s'; use 'Committee on ...': %s" % [
			pair[0], hit.get_string() if hit else "", str(pair[1]).left(100)])


func test_the_canon_lists_match_the_ministers_in_the_workbook() -> void:
	# The eight ministers' titles are the source for the eight ministries.
	var from_data: Array[String] = []
	for opponent: Dictionary in DataDB.opponents:
		for title: String in str(opponent.get("title", "") if opponent.get("title") != null else "").split(";"):
			var cleaned := title.strip_edges()
			if cleaned.begins_with("Minister of "):
				from_data.append(cleaned.trim_prefix("Minister of "))
	from_data.sort()
	var expected: Array[String] = []
	expected.assign(MINISTRIES)
	expected.sort()
	assert_eq(from_data, expected, "the ministers in Opponents are the ministries this test allows")
