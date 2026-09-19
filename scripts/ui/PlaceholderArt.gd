@tool
class_name PlaceholderArt
extends Control
## Shows a piece of artwork, or an obvious stand-in labelled with its asset ID
## when the artwork hasn't been drawn yet.
##
## Use this anywhere art goes, rather than a bare TextureRect. Then a missing
## PNG shows up as a labelled coloured box instead of an empty hole, and the
## label tells you exactly which file to draw.
##
## Set `kind` and `art_id` in the inspector, or from code:
##
##     var portrait := PlaceholderArt.new()
##     portrait.kind = PlaceholderArt.Kind.CHARACTER
##     portrait.art_id = "OP03"
##     portrait.expression = "neutral"

enum Kind { CHARACTER, CARD, BACKGROUND, ICON }

@export var kind: Kind = Kind.ICON:
	set(value):
		kind = value
		_refresh()

## The asset ID: "OP03", "C11", "ST02", "BO04".
@export var art_id: String = "":
	set(value):
		art_id = value
		_refresh()

## Only used for characters: neutral, attacking, confident, flustered,
## defeated, and victory for the protagonist.
@export var expression: String = "neutral":
	set(value):
		expression = value
		_refresh()

## Whether to write the asset ID across a placeholder. Off for backgrounds,
## where the label would sit behind the whole battle screen.
@export var show_label: bool = true:
	set(value):
		show_label = value
		_refresh()

var _texture_rect: TextureRect
var _label: Label
var _is_placeholder := false


func _ready() -> void:
	_build()
	_refresh()


func _build() -> void:
	if _texture_rect != null:
		return

	_texture_rect = TextureRect.new()
	_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(_texture_rect)

	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# White on the mid-tone placeholder colour, with a dark outline so it
	# stays readable whichever hue the ID hashes to.
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)


func _refresh() -> void:
	if _texture_rect == null:
		return

	if art_id.is_empty():
		_texture_rect.texture = null
		_label.text = ""
		return

	var path := _expected_path()
	_is_placeholder = not ArtLoader.exists(path)

	match kind:
		Kind.CHARACTER: _texture_rect.texture = ArtLoader.character(art_id, expression)
		Kind.CARD: _texture_rect.texture = ArtLoader.card(art_id)
		Kind.BACKGROUND: _texture_rect.texture = ArtLoader.background(art_id)
		Kind.ICON: _texture_rect.texture = ArtLoader.icon(art_id)

	_label.visible = _is_placeholder and show_label
	_label.text = _label_text() if _is_placeholder else ""


## The file this control is looking for. Shown on the placeholder so whoever
## is drawing the art knows exactly what to name it.
func _expected_path() -> String:
	match kind:
		Kind.CHARACTER: return ArtLoader.CHARACTERS + "%s_%s.png" % [art_id, expression]
		Kind.CARD: return ArtLoader.CARDS + art_id + ".png"
		Kind.BACKGROUND: return ArtLoader.BACKGROUNDS + art_id + ".png"
		_: return ArtLoader.ICONS + art_id + ".png"


func _label_text() -> String:
	if kind == Kind.CHARACTER:
		return "%s\n%s" % [art_id, expression]
	return art_id


## True when this is showing a stand-in rather than real artwork.
func is_placeholder() -> bool:
	return _is_placeholder
