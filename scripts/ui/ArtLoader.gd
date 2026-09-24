class_name ArtLoader
extends RefCounted
## Finds artwork by ID, and invents a stand-in when the real thing isn't
## drawn yet.
##
## WHERE ART LIVES is data, not code: data/art.json names a folder for each
## kind of picture, the expressions a character comes in, and what a missing
## expression falls back to. See that file's README for the whole scheme.
##
##     ArtLoader.character("OP03", "attacking")
##         -> assets/characters/opponents/OP03_attacking.png, or failing that
##            OP03_neutral.png, or failing that a coloured placeholder
##     ArtLoader.card("C11")          -> assets/cards/art/C11.png
##     ArtLoader.background("ST02")   -> assets/backgrounds/ST02.png
##     ArtLoader.icon("BO04")         -> assets/icons/BO04.png
##
## Missing art must never stop the game. Every request that finds nothing
## gets a flat coloured square, coloured from the ID so the same character is
## the same colour every run, and PlaceholderArt writes on it the file it is
## waiting for.

## The five faces every character should have (data/art.json can change
## them). Kept as constants so screens name them without typing strings.
const NEUTRAL := "neutral"
const ATTACKING := "attacking"
const GUARDING := "guarding"
const GAINING := "gaining"
const DAMAGED := "damaged"
const DEFEATED := "defeated"
const VICTORY := "victory"

## Used only when data/art.json does not say (it always should).
const _DEFAULT_FOLDERS := {
	"protagonist": "res://assets/characters/protagonists/",
	"opponent": "res://assets/characters/opponents/",
	"staff": "res://assets/characters/staff/",
	"visitor": "res://assets/characters/visitors/",
	"journalist": "res://assets/characters/journalists/",
	"card": "res://assets/cards/art/",
	"background": "res://assets/backgrounds/",
	"icon": "res://assets/icons/",
}

const PLACEHOLDER_SIZE := 256

## Cached so a placeholder isn't rebuilt every time a card is redrawn.
static var _placeholder_cache: Dictionary = {}


# ---------------------------------------------------------------------------
# Textures
# ---------------------------------------------------------------------------

## A character portrait, by ID and expression: any protagonist, opponent,
## staff member, visitor or reporter.
static func character(character_id: String, expression: String = NEUTRAL) -> Texture2D:
	return _load(character_path(character_id, expression), character_id)


## A card's picture, by card ID.
static func card(card_id: String) -> Texture2D:
	return _load(card_path(card_id), card_id)


## A stage background, by stage ID (or OFFICE).
static func background(stage_id: String) -> Texture2D:
	return _load(_first_existing([folder("background") + stage_id + ".png"]), stage_id)


## An icon — an organisation, a suit, a meta-variable.
static func icon(icon_name: String) -> Texture2D:
	return _load(_first_existing([folder("icon") + icon_name + ".png"]), icon_name)


## A shop item's icon (the Shop tab's Icon column). A missing file shows a
## plain blue square — Cameron, 2026-09-25 — rather than the ID-coloured
## placeholder other art gets, so every item without art yet looks the same
## and obviously unfinished.
static func item_icon(icon_name: String) -> Texture2D:
	var path := _first_existing([folder("icon") + icon_name + ".png"]) if not icon_name.is_empty() else ""
	if not path.is_empty():
		var texture := load(path) as Texture2D
		if texture != null:
			return texture
	return _blue_square()


# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

## The file a character's face is read from: the expression asked for, then
## each fallback, then neutral — in the character's own folder first and the
## old shared folder last. Empty when none of them is drawn.
static func character_path(character_id: String, expression: String = NEUTRAL) -> String:
	var candidates: Array[String] = []
	var folders: Array[String] = [character_folder(character_id)]
	var legacy := str(_art().get("legacy_folders", {}).get("character", ""))
	if not legacy.is_empty():
		folders.append(legacy)
	for face: String in expression_chain(expression):
		for where: String in folders:
			candidates.append(where + "%s_%s.png" % [character_id, face])
	return _first_existing(candidates)


static func card_path(card_id: String) -> String:
	var candidates: Array[String] = [folder("card") + card_id + ".png"]
	var legacy := str(_art().get("legacy_folders", {}).get("card", ""))
	if not legacy.is_empty():
		candidates.append(legacy + card_id + ".png")
	return _first_existing(candidates)


## Where a drawing of this character SHOULD go — what a placeholder tells
## the artist to name the file.
static func expected_character_path(character_id: String, expression: String) -> String:
	return character_folder(character_id) + "%s_%s.png" % [character_id, expression]


## The folder for a character, from the two letters its ID starts with
## (art.json's character_prefixes). An ID with no known prefix — a committee
## member's name — goes with the opponents.
static func character_folder(character_id: String) -> String:
	var prefixes: Dictionary = _art().get("character_prefixes", {})
	for prefix: String in prefixes.keys():
		if character_id.begins_with(prefix):
			return folder(str(prefixes[prefix]))
	return folder("opponent")


## A folder by kind: protagonist, opponent, staff, visitor, journalist,
## card, background, icon.
static func folder(kind: String) -> String:
	var folders: Dictionary = _art().get("folders", {})
	return str(folders.get(kind, _DEFAULT_FOLDERS.get(kind, "res://assets/")))


## The faces to try, in order: the one asked for, its fallbacks, neutral.
static func expression_chain(expression: String) -> Array[String]:
	var fallbacks: Dictionary = _art().get("expression_fallbacks", {})
	var chain: Array[String] = []
	var face := expression
	while not face.is_empty() and not chain.has(face):
		chain.append(face)
		face = str(fallbacks.get(face, ""))
	if not chain.has(NEUTRAL):
		chain.append(NEUTRAL)
	return chain


## True when the real artwork exists. The boot check screen uses this to
## count how much art is still outstanding.
static func exists(path: String) -> bool:
	return not path.is_empty() and ResourceLoader.exists(path)


static func _first_existing(paths: Array[String]) -> String:
	for path: String in paths:
		if ResourceLoader.exists(path):
			return path
	return ""


static func _art() -> Dictionary:
	return DataDB.art


# ---------------------------------------------------------------------------
# Placeholders
# ---------------------------------------------------------------------------

static func _load(path: String, id_for_placeholder: String) -> Texture2D:
	if not path.is_empty():
		var texture := load(path) as Texture2D
		if texture != null:
			return texture
	return placeholder(id_for_placeholder)


const ITEM_ICON_FALLBACK := Color(0.2, 0.42, 0.85)
static var _blue_icon: Texture2D = null


static func _blue_square() -> Texture2D:
	if _blue_icon == null:
		var image := Image.create(PLACEHOLDER_SIZE, PLACEHOLDER_SIZE, false, Image.FORMAT_RGBA8)
		image.fill(ITEM_ICON_FALLBACK)
		_blue_icon = ImageTexture.create_from_image(image)
	return _blue_icon


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
