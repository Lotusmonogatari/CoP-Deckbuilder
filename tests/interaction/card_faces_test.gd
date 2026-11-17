extends Node
## Card faces must read the same light face wherever they are drawn (design review
## 2026-11-17, panel P2). A card front (cost, name, effect text) and a card back (its
## ruled text rows) are drawn in the hand, the battle zoom, the Rhetoric Training offer
## and the Office card View. A panel built on Overlay, and the battle's card zoom, carry
## BaseImage.plate_theme(), whose dark plate for every Label once reached the card's own
## labels: dark ink on a dark plate. This test renders each face in each place, reads the
## pixels of the text area and fails when
##   - its mean luminance is below the plain face's minus 10%, or
##   - the ink against the face has a contrast ratio under 4.5 to 1.
##
##     xvfb-run .tools/godot --path . tests/interaction/card_faces_test.tscn
##
## With CARD_FACE_SHOTS=dir set it also saves a PNG of every context.

const SIZE := Vector2i(1080, 2340)
const MIN_CONTRAST := 4.5
const MIN_LUMINANCE_SHARE := 0.9

var _failures: PackedStringArray = []
var _report: PackedStringArray = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	GameState.start_new_run("PC02")
	GameState.awaiting_new_game = false
	# One card of each suit: the six suits have six differently coloured backs.
	var seen := {}
	var ids: Array[String] = []
	for row: Dictionary in DataDB.cards:
		var suit := str(row.get("suit", ""))
		if not seen.has(suit):
			seen[suit] = true
			ids.append(str(row.get("card_id", "")))
	for card_id: String in ids:
		await _one_card(card_id)
	print("")
	for line: String in _report:
		print("  " + line)
	if _failures.is_empty():
		print("CARD FACES TEST: PASS (%d suits)" % ids.size())
		get_tree().quit(0)
	else:
		print("CARD FACES TEST: FAIL")
		for line: String in _failures:
			print("  X " + line)
		get_tree().quit(1)


func _one_card(card_id: String) -> void:
	var card := DataDB.get_card(card_id)
	var tag := "%s %s: " % [card_id, str(card.get("suit", ""))]
	# The reference: the faces with nothing around them (what the hand shows).
	var plain := await _viewport()
	var host := Control.new()
	plain.add_child(host)
	var front := CardView.new()
	front.show_card(card)
	front.disabled = true
	host.add_child(front)
	var back := CardBackView.new()
	back.custom_minimum_size = Vector2(CardView.HEIGHT * CardBackView.ASPECT, CardView.HEIGHT)
	back.size = back.custom_minimum_size
	back.position = Vector2(CardView.WIDTH + 40.0, 0.0)
	back.show_card(card, "")
	host.add_child(back)
	await _settle()
	var ref_front := _front_stats(plain, front)
	var ref_back := _back_stats(plain, back)
	_save(plain, card_id + "_plain")
	if card_id == "C02": print("  reference front: luminance %.3f, contrast %.1f" % [ref_front["mean"], ref_front["contrast"]])
	if card_id == "C02": print("  reference back:  luminance %.3f, contrast %.1f" % [ref_back["mean"], ref_back["contrast"]])
	if ref_front["mean"] <= 0.0 or ref_back["mean"] <= 0.0:
		_failures.append(tag + "the reference faces could not be measured")
	_check(tag + "plain front", ref_front, ref_front)
	_check(tag + "plain back", ref_back, ref_back)
	plain.queue_free()

	# The Office: the Rhetoric Training offer and the card View.
	for context: String in ["training offer", "card view"]:
		var vp := await _viewport()
		var office: Control = (load("res://scenes/office_hours/OfficeScreen.tscn") as PackedScene).instantiate()
		vp.add_child(office)
		await _settle()
		for child in office.get_children():
			if child is Overlay and (child as Overlay).visible:
				(child as Overlay).close()
		if context == "training offer":
			GameState.card_draw = {"item_id": "SH09", "card_id": card_id, "look": 1, "seen": [card_id]}
			office.call("_show_card_offer")
		else:
			office.call("_show_card_look", card_id)
		await _settle()
		_measure_pair(vp, tag + context, ref_front, ref_back)
		_save(vp, card_id + "_" + context.replace(" ", "_"))
		GameState.card_draw = {}
		vp.queue_free()
		await get_tree().process_frame

	# The battle: the hand and the zoom.
	GameState.start_new_run("PC02")
	GameState.awaiting_new_game = false
	GameState.begin_level(LevelRunner.new(BattleSetup.expand_level(DataDB.get_level("LV04"))))
	var vp2 := await _viewport()
	var battle: Control = (load("res://scenes/battle/BattleScreen.tscn") as PackedScene).instantiate()
	vp2.add_child(battle)
	await _settle(1.0)
	var hand_cards := battle.find_children("*", "Control", true, false).filter(func(n: Node) -> bool: return n is CardView)
	if hand_cards.is_empty():
		_failures.append(tag + "the battle hand has no cards")
	else:
		var hand_front := _front_stats(vp2, hand_cards[0])
		if card_id == "C02": print("  hand front: luminance %.3f, contrast %.1f" % [hand_front["mean"], hand_front["contrast"]])
		_check(tag + "hand front (its own luminance is the reference)", hand_front, hand_front)
	_save(vp2, card_id + "_hand")
	battle.call("_open_card", card_id)
	await _settle()
	var zoom_back: CardBackView = null
	for node in battle.find_children("*", "Control", true, false):
		if node is CardBackView and (node as CardBackView).is_visible_in_tree():
			zoom_back = node
	if zoom_back == null:
		_failures.append(tag + "the zoom has no card back")
	else:
		_check(tag + "zoom back", _back_stats(vp2, zoom_back), ref_back)
	_save(vp2, card_id + "_zoom")
	vp2.queue_free()
	GameState.end_level()



func _viewport() -> SubViewport:
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	return vp


func _settle(seconds: float = 0.7) -> void:
	await get_tree().process_frame
	await get_tree().create_timer(seconds).timeout


func _save(vp: SubViewport, name: String) -> void:
	var dir := OS.get_environment("CARD_FACE_SHOTS")
	if dir.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(dir)
	vp.get_texture().get_image().save_png("%s/%s.png" % [dir, name])


## The front and the back found in a context, measured and judged against the plain ones.
func _measure_pair(vp: SubViewport, context: String, ref_front: Dictionary, ref_back: Dictionary) -> void:
	var front: CardView = null
	var back: CardBackView = null
	for node in vp.find_children("*", "Control", true, false):
		if not (node as Control).is_visible_in_tree():
			continue
		if node is CardView:
			front = node
		elif node is CardBackView:
			back = node
	if front == null or back == null:
		_failures.append("%s: front or back not found" % context)
		return
	_check(context + " front", _front_stats(vp, front), ref_front)
	_check(context + " back", _back_stats(vp, back), ref_back)


func _check(label: String, stats: Dictionary, reference: Dictionary) -> void:
	_report.append("%-22s luminance %.3f (plain %.3f)  contrast %.1f : 1" % [label, stats["mean"], reference["mean"], stats["contrast"]])
	if float(stats["mean"]) < float(reference["mean"]) * MIN_LUMINANCE_SHARE:
		_failures.append("%s is dark: luminance %.3f, the plain face has %.3f (minus 10%% is %.3f)" % [
			label, stats["mean"], reference["mean"], float(reference["mean"]) * MIN_LUMINANCE_SHARE])
	if float(stats["contrast"]) < MIN_CONTRAST:
		_failures.append("%s text contrast %.1f : 1 is under %.1f : 1" % [label, stats["contrast"], MIN_CONTRAST])


func _front_stats(vp: SubViewport, front: Control) -> Dictionary:
	var label: Label = front.get("_effect_label")
	return _stats(vp.get_texture().get_image(), label.get_global_transform() * Rect2(Vector2.ZERO, label.size))


func _back_stats(vp: SubViewport, back: Control) -> Dictionary:
	var rect := Rect2()
	var first := true
	for cell: Label in back.get("_cells"):
		if cell.text.is_empty():
			continue
		var r: Rect2 = cell.get_global_transform() * Rect2(Vector2.ZERO, cell.size)
		rect = r if first else rect.merge(r)
		first = false
	return _stats(vp.get_texture().get_image(), rect)


## Mean luminance of a region, and the contrast of its ink (the darkest few percent of
## pixels) against its ground (the median pixel), as WCAG relative luminance.
func _stats(image: Image, rect: Rect2) -> Dictionary:
	var area := Rect2i(rect.position.floor(), rect.size.ceil()).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	if area.size.x <= 0 or area.size.y <= 0:
		return {"mean": 0.0, "contrast": 0.0}
	var values: Array[float] = []
	var total := 0.0
	for y in range(area.position.y, area.end.y, 2):
		for x in range(area.position.x, area.end.x, 2):
			var c := image.get_pixel(x, y)
			var l := 0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b)
			values.append(l)
			total += l
	values.sort()
	if values.is_empty():
		return {"mean": 0.0, "contrast": 0.0}
	var ground := values[values.size() / 2]
	var ink := values[0]
	return {"mean": total / values.size(), "contrast": (ground + 0.05) / (ink + 0.05)}


func _lin(v: float) -> float:
	return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)
