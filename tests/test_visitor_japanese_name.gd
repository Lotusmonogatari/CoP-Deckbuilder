extends GutTest
## A visitor's Japanese name sits under the English one and above the title
## (2026-11-13); a visitor with no Japanese name shows no empty line.

func _presenter() -> Array:
	var portrait := PlaceholderArt.new()
	var name_label := Label.new()
	var title_label := Label.new()
	var jp_label := Label.new()
	for node: Node in [portrait, name_label, title_label, jp_label]:
		add_child_autofree(node)
	return [VisitorPresenter.new(portrait, name_label, title_label, jp_label), name_label, jp_label, title_label]


func test_the_japanese_name_is_shown() -> void:
	var made := _presenter()
	var visitor := DataDB.get_visitor("VI167")
	(made[0] as VisitorPresenter).show_visitor(visitor)
	assert_eq((made[2] as Label).text, str(visitor["name_jp"]))
	assert_true((made[2] as Label).visible)
	assert_eq((made[1] as Label).text, "Masashi Mumotsu")


func test_a_missing_japanese_name_hides_the_line() -> void:
	var made := _presenter()
	(made[0] as VisitorPresenter).show_visitor({"visitor_id": "VI_X", "name_en": "Test", "name_jp": null, "title": "Guest"})
	assert_false((made[2] as Label).visible)


func test_the_japanese_label_sits_between_name_and_title_in_the_scene() -> void:
	var scene := load("res://scenes/office_hours/VisitorScreen.tscn") as PackedScene
	var root := scene.instantiate()
	var details := root.get_node("Safe/Column/VisitorRow/Details")
	assert_eq(details.get_child(0).name, &"VisitorName")
	assert_eq(details.get_child(1).name, &"VisitorNameJP")
	assert_eq(details.get_child(2).name, &"VisitorTitle")
	root.free()
