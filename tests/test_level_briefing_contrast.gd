extends GutTest
## The level briefing's palette (P12, 2026-11-19): every text colour reads on the fill it is drawn on at 4.5:1 or better,
## and every icon, rail and bar reads on its ground at 3:1 or better, in all three UI styles. The colours are the
## brief_* tokens of the UI Styles tab, read the way LevelBriefingStyles reads them.

const TEXT_MIN := 4.5
const GRAPHIC_MIN := 3.0
const NAMES := ["ground", "on_ground", "on_ground_muted", "card", "ink", "muted", "tile", "accent", "on_accent", "hot"]


func _palette(style: String) -> Dictionary:
	var out := {}
	for name: String in NAMES:
		out[name] = UiStyle.colour("brief_" + name, Color.MAGENTA, style)
		assert_ne(out[name], Color.MAGENTA, "%s has a brief_%s colour" % [style, name])
	return out


## Text colour on the fill it sits on, as [text, fill, where] triples for one style.
func _text_pairs(p: Dictionary, style: String) -> Array:
	var pairs: Array = [
		["on_ground", "ground", "the title, the Levels link, the Back button"],
		["on_ground_muted", "ground", "the meta line and the week's words, the hour marks"],
		["ink", "card", "headings and names on a card"],
		["muted", "card", "small print on a card"],
		["ink", "tile", "a tile's number and name, a reward chip"],
		["muted", "tile", "a tile's bonus line"],
		["on_accent", "accent", "Go in, a room's number, the finish marker"],
	]
	# The hours badge: Woodblock sets card-coloured ink on the vermilion seal; the others sit on accent or the ground.
	if style == UiStyles.WOODBLOCK:
		pairs.append(["card", "hot", "the hours seal"])
	return pairs


func test_text_reads_on_its_fill_in_every_style() -> void:
	for style: String in [UiStyles.WOODBLOCK, UiStyles.LIVING_OFFICE, UiStyles.BROADCAST]:
		var p := _palette(style)
		for pair: Array in _text_pairs(p, style):
			var ratio := IntentPill.contrast(p[pair[0]], p[pair[1]])
			assert_gte(ratio, TEXT_MIN, "%s: %s on %s (%s) is %.2f:1" % [style, pair[0], pair[1], pair[2], ratio])


func test_a_greyed_out_go_in_still_reads() -> void:
	# LevelBriefingStyles.primary_box: on_ground_muted at 35% over the ground, with on_ground ink.
	for style: String in [UiStyles.WOODBLOCK, UiStyles.LIVING_OFFICE, UiStyles.BROADCAST]:
		var p := _palette(style)
		var muted: Color = p["on_ground_muted"]
		var fill: Color = (p["ground"] as Color).lerp(Color(muted.r, muted.g, muted.b), 0.35)
		var ratio := IntentPill.contrast(p["on_ground"], fill)
		assert_gte(ratio, TEXT_MIN, "%s: the greyed Go in is %.2f:1" % [style, ratio])


func test_icons_bars_and_rails_read_on_their_ground() -> void:
	for style: String in [UiStyles.WOODBLOCK, UiStyles.LIVING_OFFICE, UiStyles.BROADCAST]:
		var p := _palette(style)
		var graphics: Array = [
			["on_ground", "ground", "the back chevron"],
			["hot", "ground", "this level's stretch of the week bar and the timeline rail"],
			["on_ground_muted", "ground", "the spent hours on the week bar"],
			["accent", "ground", "a style's gold or indigo edge"],
		]
		# Woodblock's indigo accent is a fill under light ink, not an edge on the ground: its edges are the ink colour.
		if style == UiStyles.WOODBLOCK:
			graphics.erase(["accent", "ground", "a style's gold or indigo edge"])
			graphics.append(["ink", "ground", "a card's edge"])
		for pair: Array in graphics:
			var ratio := IntentPill.contrast(p[pair[0]], p[pair[1]])
			assert_gte(ratio, GRAPHIC_MIN, "%s: %s on %s (%s) is %.2f:1" % [style, pair[0], pair[1], pair[2], ratio])
