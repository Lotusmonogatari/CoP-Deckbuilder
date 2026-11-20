class_name PartyDisc
extends RefCounted
## What a party's disc on the Floor Vote says when the leader has no portrait yet (P14, 2026-11-20, Cameron): the first
## character of the party's Japanese name, big, with the English initials small beside it, so English stays next to the Japanese.
## Both come from the Parties tab (Japanese Name, Short Name). Pure: no screens, no files.


## The single character the disc shows: the first kanji of the Japanese name (エゾの遺産党 gives 遺, skipping the kana), or its first
## character when it has no kanji, or "" when the party has none yet.
static func kanji(japanese_name: String) -> String:
	var trimmed := japanese_name.strip_edges()
	for i in trimmed.length():
		var code := trimmed.unicode_at(i)
		if code >= 0x4E00 and code <= 0x9FFF:
			return trimmed.substr(i, 1)
	return "" if trimmed.is_empty() else trimmed.substr(0, 1)


## The small English initials under it; the party's own name's first letters when the tab has no Short Name.
static func initials(short_name: String, party_name: String) -> String:
	var short := short_name.strip_edges()
	if not short.is_empty():
		return short
	var out := ""
	for word: String in party_name.split(" ", false):
		out += word.substr(0, 1).to_upper()
	return out


## Dark or white lettering, whichever reads better on the party's colour (the six colours run from pure red to cyan).
static func ink_on(fill: Color) -> Color:
	var dark := Color("#1A1A1A")
	return Color.WHITE if PartyDisplay.contrast(Color.WHITE, fill) >= PartyDisplay.contrast(dark, fill) else dark
