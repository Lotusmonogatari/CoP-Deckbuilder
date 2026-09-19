class_name ArtLoader
extends RefCounted
## Finds artwork by ID, and invents a stand-in when the real thing isn't
## drawn yet.
##
## Almost none of the art exists during development, and missing art must
## never stop the game from running. So every request that can't find a PNG
## gets a flat coloured square instead. The colour is worked out from the ID,
## so the same character is the same colour every time you run the game —
## which makes a placeholder easy to recognise at a glance.
##
## Usage:
##     var portrait := ArtLoader.character("OP03", "neutral")
##     var face := ArtLoader.card("C11")
##
## File naming, matching the build brief:
##     assets/characters/OP03_neutral.png, PROTAGONIST_victory.png
##     assets/cards/C11.png
##     assets/backgrounds/ST02.png
##     assets/icons/BO04.png

const CHARACTERS := "res://assets/characters/"
const CARDS := "res://assets/cards/"
const BACKGROUNDS := "res://assets/backgrounds/"
const ICONS := "res://assets/icons/"

## Expressions every opponent portrait comes in. The protagonist also has
## "victory".
const EXPRESSIONS := ["neutral", "attacking", "confident", "flustered", "defeated"]

const PLACEHOLDER_SIZE := 256

## Cached so a placeholder isn't rebuilt every time a card is redrawn.
static var _placeholder_cache: Dictionary = {}


## A character portrait. `character_id` is an opponent ID such as "OP03",
## a committee member's name, or "PROTAGONIST".
static func character(character_id: String, expression: String = "neutral") -> Texture2D:
	return _load(CHARACTERS + "%s_%s.png" % [character_id, expression], character_id)


## A card face, by card ID.
static func card(card_id: String) -> Texture2D:
	return _load(CARDS + card_id + ".png", card_id)


## A stage background, by stage ID.
static func background(stage_id: String) -> Texture2D:
	return _load(BACKGROUNDS + stage_id + ".png", stage_id)


## An icon — a booster organization, a suit, a meta-variable.
static func icon(icon_name: String) -> Texture2D:
	return _load(ICONS + icon_name + ".png", icon_name)


## True when the real artwork exists. The boot check screen uses this to
## count how much art is still outstanding.
static func exists(path: String) -> bool:
	return ResourceLoader.exists(path)


static func _load(path: String, id_for_placeholder: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var texture := load(path) as Texture2D
		if texture != null:
			return texture
	return placeholder(id_for_placeholder)


## A flat coloured square standing in for missing art.
##
## Drawing the ID onto the texture would need a font and a viewport, so the
## label is drawn by PlaceholderArt (the Control) on top of this instead.
## That keeps this function usable anywhere a plain Texture2D is wanted.
static func placeholder(id: String) -> Texture2D:
	if _placeholder_cache.has(id):
		return _placeholder_cache[id]

	var image := Image.create(PLACEHOLDER_SIZE, PLACEHOLDER_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(placeholder_color(id))

	var texture := ImageTexture.create_from_image(image)
	_placeholder_cache[id] = texture
	return texture


## The colour for an ID. Same ID, same colour, every run.
##
## The hue comes from the ID's hash so two different characters are unlikely
## to share a colour, while the saturation and brightness are fixed low and
## mid so placeholders read as obviously unfinished rather than as artwork,
## and white text stays legible on top.
static func placeholder_color(id: String) -> Color:
	var hue := float(abs(id.hash()) % 360) / 360.0
	return Color.from_hsv(hue, 0.35, 0.55)
