extends Node2D
@export var node:Node

var duplicated=false
func deactivate():
	if node and !duplicated:
		duplicated=true
		var dup = duplicate(1)
		dup.z_index=-5
		get_tree().get_first_node_in_group("Arena").add_child(dup)
		dup.modulate=Color("4d4d4dff")
		node.target=dup
