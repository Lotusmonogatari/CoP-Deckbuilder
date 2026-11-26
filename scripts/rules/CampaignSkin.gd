class_name CampaignSkin
extends RefCounted
## The campaign skins (P22, 2026-11-26, Cameron): Samurai and Gladiator, two looks for the election screens only. Pure and UI-free (CLAUDE.md
## section 12): which skin a phase wears, the tier numerals, the party colours a skin's accent family and the banners' nobori take, and the nobori
## recolouring of an SVG text. The tokens themselves are the UI Styles tab's rows (styles `campaign_samurai` and `campaign_gladiator`); the Rules
## tab's `campaign_skin` chooses.

const SAMURAI := "campaign_samurai"
const GLADIATOR := "campaign_gladiator"
const STYLES: Array[String] = [SAMURAI, GLADIATOR]
## Rules campaign_skin values.
const BY_PHASE := "phase"
const OFF := "off"


## The skin id a campaign screen wears now, or "" for the player's own look. `phase` is an ElectionCycle phase; `rule_value` the Rules switch.
## Samurai is the default for anything unknown.
static func skin_for(phase: String, rule_value: String) -> String:
	match rule_value:
		OFF: return ""
		"gladiator": return GLADIATOR
		BY_PHASE: return GLADIATOR if phase == ElectionCycle.CAMPAIGN else SAMURAI
	return SAMURAI


static func is_skin(style: String) -> bool:
	return STYLES.has(style)


## A tier number as the skin writes it: Roman for 1 to 3 when `numerals` is "roman" (0 stays 0), else plain.
static func numeral(n: int, numerals: String) -> String:
	if numerals != "roman":
		return str(n)
	return roman(n)


static func roman(n: int) -> String:
	var table := {0: "0", 1: "I", 2: "II", 3: "III", 4: "IV", 5: "V"}
	return str(table.get(n, str(n)))


## The colour tokens that take the player's party colour (the party / accent_family row, semicolons).
static func accent_family(index: Dictionary, style: String) -> Array[String]:
	var out: Array[String] = []
	for piece: String in UiStyles.token(index, style, "party", "accent_family").split(";"):
		if not piece.strip_edges().is_empty():
			out.append(piece.strip_edges())
	return out


## A party row's colour (r, g, b as 0 to 255), or `fallback` when the party is unknown.
static func party_colour(party: Dictionary, fallback: Color) -> Color:
	if party.is_empty() or party.get("r") == null:
		return fallback
	return Color8(int(party["r"]), int(party["g"]), int(party["b"]))


## The party IDs of the three nobori, left to right: the player's own party, then the Rules' two (Keizaijiyuutou and the Yezo Heritage Party). When the
## player's own party is one of those two the third nobori takes `spare` (the Frontier Party) instead of repeating a colour.
static func banner_parties(player_party: String, others: Array, spare: String) -> Array[String]:
	var out: Array[String] = [player_party]
	for id: Variant in others:
		out.append(spare if out.has(str(id)) else str(id))
	return out


## The banner SVG with its three nobori cloths coloured `colours` (hex like "#A61E1E", left to right). The sun, the bands and the outlines are not
## touched. A text with fewer than three cloths is returned as it is.
static func recolour_nobori(svg: String, colours: Array[String]) -> String:
	var rx := RegEx.create_from_string("(<rect[^>]*height=\"360\"[^>]*fill=\")(#[0-9A-Fa-f]{6})(\")")
	var found := rx.search_all(svg)
	if found.size() < 3 or colours.size() < 3:
		return svg
	var out := ""
	var at := 0
	for i in 3:
		var m := found[i]
		out += svg.substr(at, m.get_start(2) - at) + colours[i]
		at = m.get_end(2)
	return out + svg.substr(at)
