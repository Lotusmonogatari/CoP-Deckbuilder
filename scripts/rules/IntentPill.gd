class_name IntentPill
extends RefCounted
## The colour of the opponent's intent pill (2026-11-17, Cameron): the opponent's party colour when the
## opponent has a party that is not the player's own; otherwise the default red. The default red must
## never be mistaken for the Keizaijiyuutou party's red (255, 0, 0), so a test holds it well apart from
## every party colour. Pure: no autoload, file or scene.


## The pill's fill. `party_colour` is the opponent's party colour (ignored when there is no party).
static func colour(opponent_party: String, player_party: String, party_colour: Color, default_red: Color) -> Color:
	var party := opponent_party.strip_edges()
	if party.is_empty() or party == player_party.strip_edges():
		return default_red
	return party_colour


## Light or dark ink, whichever reads better on `fill` (WCAG contrast).
static func ink_for(fill: Color) -> Color:
	var light := Color(1, 0.97, 0.92)
	var dark := Color(0.08, 0.06, 0.05)
	return light if contrast(fill, light) >= contrast(fill, dark) else dark


static func luminance(c: Color) -> float:
	var channels: Array[float] = []
	for v: float in [c.r, c.g, c.b]:
		channels.append(v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4))
	return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]


static func contrast(a: Color, b: Color) -> float:
	var la := luminance(a)
	var lb := luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


## How far apart two colours are, as a straight RGB distance in 0..255 units.
static func distance(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length() * 255.0
