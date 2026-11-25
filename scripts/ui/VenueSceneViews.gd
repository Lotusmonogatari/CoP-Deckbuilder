class_name VenueSceneViews
extends RefCounted
## The scene behind an overheard line (2026-11-25, Cameron): when an Area Characters person speaks, the venue's own background fills the top
## of the screen and the speaker stands over it, full height, with the line's card at the foot. A line spoken by anyone else, or by no one,
## keeps the plain card. Draws what it is given; nothing here decides a rule.


## The scene as a full-screen Control to sit behind a pop-up card: the picture, a fade into the style's ground, and the person.
static func build(background_id: String, speaker_id: String) -> Control:
	var look := OfficeFrameStyles.look()
	var root := Control.new()
	root.name = "VenueScene"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var picture := PlaceholderArt.new()
	picture.name = "SceneBackground"
	picture.kind = PlaceholderArt.Kind.BACKGROUND
	picture.art_id = background_id
	picture.fade_all_sides = false
	picture.anchor_right = 1.0
	picture.anchor_bottom = 0.66
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(picture)
	# The picture melts into the ground colour where the card begins.
	var gradient := Gradient.new()
	var ground: Color = look["ground"]
	gradient.colors = PackedColorArray([Color(ground, 0.0), Color(ground, 1.0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0.0, 0.0)
	texture.fill_to = Vector2(0.0, 1.0)
	var fade := TextureRect.new()
	fade.name = "SceneFade"
	fade.texture = texture
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.anchor_right = 1.0
	fade.anchor_top = 0.50
	fade.anchor_bottom = 0.66
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade)
	var person := PlaceholderArt.new()
	person.name = "ScenePerson"
	person.kind = PlaceholderArt.Kind.CHARACTER
	person.art_id = speaker_id
	person.anchor_left = 0.04
	person.anchor_right = 0.96
	person.anchor_top = 0.14
	person.anchor_bottom = 0.76
	person.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(person)
	return root
