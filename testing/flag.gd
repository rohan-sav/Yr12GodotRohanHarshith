extends Node3D

var current_holder = null
var transfer_cooldown = 0.0  # Prevent rapid transfers

func _ready():
	# Create collision detection
	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	var sphere = SphereShape3D.new()
	sphere.radius = 2.0
	
	collision.shape = sphere
	area.add_child(collision)
	add_child(area)
	
	# Connect collision signal
	area.body_entered.connect(_on_body_entered)

func _process(delta):
	# Reduce cooldown timer
	if transfer_cooldown > 0:
		transfer_cooldown -= delta

func _on_body_entered(body):
	# Don't transfer if we're in cooldown
	if transfer_cooldown > 0:
		return
	
	var potential_new_holder = null
	
	# Check if it's a bot's RigidBody3D
	if body.name == "RigidBody3D" or body.name == "RigidBody3D2":
		potential_new_holder = body
	# Check if it's player's CharacterBody3D
	elif body.get_parent().has_method("handle_movement"):
		potential_new_holder = body.get_parent()
	
	# Transfer flag if we found someone different than current holder
	if potential_new_holder and potential_new_holder != current_holder:
		transfer_to(potential_new_holder)

func transfer_to(new_holder):
	current_holder = new_holder
	transfer_cooldown = 1.0  # 1 second cooldown
	print("Flag transferred to: " + new_holder.name)
	
	# Move flag to follow the new holder
	reparent(new_holder)
	position = Vector3(1, 1, 0)  # Offset position (like in their hand)

func give_to_player_at_start():
	# Find player and give them the flag
	var player = get_tree().get_first_node_in_group("player")
	if player:
		transfer_to(player)
