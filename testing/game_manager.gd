extends Node

func _ready():
	print("GameManager starting...")
	await get_tree().process_frame
	
	var flag = get_tree().get_first_node_in_group("flag")
	var player = get_tree().get_first_node_in_group("player")
	
	print("Found flag: ", flag)
	print("Found player: ", player)
	
	if flag:
		flag.give_to_player_at_start()
	else:
		print("ERROR: No flag found!")
	
	if not player:
		print("ERROR: No player found!")
