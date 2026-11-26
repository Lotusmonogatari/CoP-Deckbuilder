class_name CampaignLook
extends RefCounted
## The campaign skins on screen (P22, 2026-11-26, Cameron): which skin a campaign screen wears now, how a screen is built inside it, the skin's display
## face and the art it draws. The pure choice is CampaignSkin; the tokens are the UI Styles tab's rows. A skin replaces the player's look on the
## campaign screens ONLY: begin() puts UiStyle in the skin's scope, end() takes it out, and the screens call both around every build.

const ART_FOLDER := "res://assets/campaign/"


## The skin id the campaign screens wear in the phase the calendar is in, or "" for the player's own look (Rules campaign_skin).
static func skin() -> String:
	return CampaignSkin.skin_for(str(GameState.election_phase()["phase"]), str(DataDB.get_rule("campaign_skin", "samurai")))


## The player's party colour (alpha 1), or alpha 0 when the player has none: the skin's accent family takes it.
static func party_accent() -> Color:
	return CampaignSkin.party_colour(DataDB.get_party(str(DataDB.player.get("party", ""))), Color(0, 0, 0, 0))


## Puts the campaign skin in scope; returns whether one is in force (false: the player's own look stays).
static func begin(skin_id: String = "") -> bool:
	var wanted := skin_id if not skin_id.is_empty() else skin()
	if wanted.is_empty():
		UiStyle.end_scope()
		return false
	UiStyle.begin_scope(wanted, party_accent())
	return true


static func end() -> void:
	UiStyle.end_scope()


## Runs `build` inside the skin and always takes the skin out again. Returns what `build` returned.
static func scoped(build: Callable) -> Variant:
	begin()
	var result: Variant = build.call()
	end()
	return result


## The skin's display face: Antaka Brush Display (Samurai) or Shippori Mincho B1 with the accented-letter and Japanese fallbacks (Gladiator), with the
## skin's title tracking (em) added.
static func display_font(skin_id: String) -> Font:
	var name := UiStyle.scoped_token("font", "display", "Antaka Brush Display")
	var tracking := UiStyle.scoped_token("type", "title_tracking_em", "0").to_float()
	var base: Font = UiStyleTheme.face(UiStyleTheme.SHIPPORI if name.begins_with("Shippori") else UiStyleTheme.ANTAKA_DISPLAY)
	if tracking > 0.0 and base is FontVariation:
		(base as FontVariation).spacing_glyph = int(round(tracking * 26.0))
	return base


## The skin's SVG as a texture at `scale` (the art is drawn in mockup pixels; the base is 1080 wide), or null when the file is missing.
static func texture(file_name: String, scale: float, recolour: Callable = Callable()) -> Texture2D:
	var path := ART_FOLDER + file_name
	if not FileAccess.file_exists(path):
		return null
	var text := FileAccess.get_file_as_string(path)
	if recolour.is_valid():
		text = str(recolour.call(text))
	var image := Image.new()
	if image.load_svg_from_string(text, scale) != OK:
		return null
	return ImageTexture.create_from_image(image)


## The emblem of the skin in force (crest or laurel) at a mockup size, or null.
static func emblem(skin_id: String, mockup_px: float) -> Texture2D:
	return texture("emblem_%s.svg" % skin_id.trim_prefix("campaign_"), OfficeFrameStyles.len_px(mockup_px) / 20.0)


## A phase banner's art for the skin in force, its nobori in the three party colours (Samurai), at the width of the screen.
static func banner(skin_id: String, phase: String, width: float) -> Texture2D:
	var kind := skin_id.trim_prefix("campaign_")
	var recolour := Callable()
	if kind == "samurai":
		var colours := nobori_colours()
		recolour = func(svg: String) -> String: return CampaignSkin.recolour_nobori(svg, colours)
	return texture("banner_%s_%s.svg" % [phase, kind], width / 390.0, recolour)


## The colours of the three nobori: the player's own party, then Keizaijiyuutou and the Yezo Heritage Party (a spare party instead of a repeat).
static func nobori_colours() -> Array[String]:
	var own := str(DataDB.get_party(str(DataDB.player.get("party", ""))).get("party_id", ""))
	var others: Array = str(DataDB.get_rule("campaign_banner_parties", "")).split(";")
	var ids := CampaignSkin.banner_parties(own, others, str(DataDB.get_rule("campaign_banner_spare_party", "")))
	var out: Array[String] = []
	for id: String in ids:
		var colour := CampaignSkin.party_colour(DataDB.get_party_by_id(id), Color("#A61E1E"))
		out.append("#" + colour.to_html(false))
	return out
