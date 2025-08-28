extends Node3D

var current_holder = null

func transfer_to(new_holder):
	if current_holder == new_holder:
		return
	
	# Only allow transfers between player and bots
	var player = get_tree().get_first_node_in_group("player")
	var is_bot = (new_holder.name == "RigidBody3D" or new_holder.name == "RigidBody3D2")
	var is_player = (new_holder == player)
	
	if not (is_player or is_bot):
		print("Invalid transfer target: " + new_holder.name)
		return
	
	current_holder = new_holder
	print("Flag transferred to: " + new_holder.name)
	
	# Move flag to follow the new holder
	reparent(new_holder)
	position = Vector3(1, 1, 0)

func give_to_player_at_start():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		transfer_to(player)
