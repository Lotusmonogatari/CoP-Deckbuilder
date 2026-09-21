extends Node
## Bootstrap for the card screenshot run. See shot_cards_driver.gd.
##
## This node exists only to put the driver somewhere that survives. Godot
## frees the CURRENT SCENE when change_scene_to_file is called, and the driver
## has to keep running after the battle screen opens — so it is parented to
## the tree root instead of living in this scene.
##
## Deferred because a node cannot be added to the tree while the tree is
## still building it.


func _ready() -> void:
	var driver := Node.new()
	driver.name = "ShotDriver"
	driver.set_script(load("res://tools/shot_cards_driver.gd"))
	get_tree().root.add_child.call_deferred(driver)
