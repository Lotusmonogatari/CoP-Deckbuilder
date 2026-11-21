class_name PartyDiscView
extends RefCounted
## The party's colour disc (P14, 2026-11-20, Cameron): the first kanji of its Japanese name, big, with its English initials small
## under it, in the party's colour. It stands in for the leader's portrait only where no portrait is in the assets yet (the Floor
## Vote's party strip and the level intro's lean buttons share it); where the picture exists the picture is used.


## True when this leader has a picture in the assets, so the portrait is used and no disc is drawn.
static func has_portrait(leader_id: String) -> bool:
	return not leader_id.is_empty() and not ArtLoader.character_path(leader_id).is_empty()


## A disc `size` pixels across for this party row (parties.json).
static func build(party: Dictionary, size: float) -> Control:
	var colour := PartyDisplay.color_for(party)
	var ink := PartyDisc.ink_on(colour)
	var disc := Control.new()
	disc.name = "Disc"
	disc.custom_minimum_size = Vector2(size, size)
	# A circle stays a circle: a container may not stretch it into an oval.
	disc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	disc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fill := Panel.new()
	fill.name = "Fill"
	fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box := StyleBoxFlat.new()
	box.bg_color = colour
	box.set_corner_radius_all(int(size / 2.0))
	fill.add_theme_stylebox_override("panel", box)
	disc.add_child(fill)
	var kanji := Label.new()
	kanji.name = "Kanji"
	kanji.text = PartyDisc.kanji(str(party.get("japanese_name", "")))
	kanji.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kanji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kanji.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kanji.add_theme_font_size_override("font_size", int(size * 0.48))
	kanji.add_theme_color_override("font_color", ink)
	kanji.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	disc.add_child(kanji)
	var initials := Label.new()
	initials.name = "Initials"
	initials.text = PartyDisc.initials(str(party.get("short_name", "")), str(party.get("name", "")))
	initials.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	initials.offset_top = -size * 0.27
	initials.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	initials.theme_type_variation = "SmallLabel"
	initials.add_theme_color_override("font_color", ink)
	initials.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	disc.add_child(initials)
	return disc
