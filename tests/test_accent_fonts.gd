extends GutTest
## Accented Latin letters (2026-11-21, a tester's report: the Ō in "Ōminato" was in a different font from its sentence). The body
## faces Shippori Mincho B1 and Zen Kaku Gothic New have no macron letters, so Antaka Brush Text (which has them) is their first
## fallback; Barlow Condensed takes its Latin-extended piece. Every accented Latin letter the game's text uses must be in a face
## that is in the chain, so none falls through to a mismatched font.


func _accented_letters() -> Array[String]:
	var found := {}
	var sources: Array = [DataDB.strings.values(), DataDB.events, DataDB.event_choices, DataDB.boosters, DataDB.opponents, DataDB.visitors]
	for source: Variant in sources:
		var rows: Array = source as Array
		for row: Variant in rows:
			var text := str(row) if not row is String else str(row)
			for i in text.length():
				var code := text.unicode_at(i)
				# Latin-1 Supplement letters and Latin Extended-A, B (not punctuation or Japanese).
				if (code >= 0xC0 and code <= 0x24F) and code != 0xD7 and code != 0xF7:
					found[text.substr(i, 1)] = true
	var out: Array[String] = []
	for letter: String in found.keys():
		out.append(letter)
	out.sort()
	return out


func test_the_body_faces_put_the_accent_font_first_behind_them() -> void:
	for pair: Array in [[UiStyleTheme.SHIPPORI, UiStyleTheme.ANTAKA_TEXT], [UiStyleTheme.ZEN, UiStyleTheme.ANTAKA_TEXT],
			[UiStyleTheme.BARLOW, UiStyleTheme.BARLOW_EXT]]:
		var face := UiStyleTheme.face(str(pair[0])) as FontVariation
		assert_eq(face.fallbacks.size(), 2, "the accent face, then Noto")
		assert_eq((face.fallbacks[0] as Font).resource_path, str(pair[1]), "the accent fallback for " + str(pair[0]))
		assert_true((face.fallbacks[1] as FontVariation).base_font.resource_path.contains("NotoSansJP"), "Noto stays last")


func test_every_accented_letter_the_text_uses_is_in_the_accent_face_of_each_body_font() -> void:
	var letters := _accented_letters()
	assert_gt(letters.size(), 0, "the data has accented letters")
	for pair: Array in [[UiStyleTheme.SHIPPORI, UiStyleTheme.ANTAKA_TEXT], [UiStyleTheme.ZEN, UiStyleTheme.ANTAKA_TEXT]]:
		var body := load(str(pair[0])) as Font
		var accent := load(str(pair[1])) as Font
		for letter: String in letters:
			assert_true(body.has_char(letter.unicode_at(0)) or accent.has_char(letter.unicode_at(0)),
				"%s is in %s or its accent face" % [letter, str(pair[0]).get_file()])
	var barlow := load(UiStyleTheme.BARLOW) as Font
	var barlow_ext := load(UiStyleTheme.BARLOW_EXT) as Font
	for letter: String in letters:
		assert_true(barlow.has_char(letter.unicode_at(0)) or barlow_ext.has_char(letter.unicode_at(0)), letter + " is in Barlow or its extended piece")
