extends RigidBody3D

@export var speed: float = 50.0
@export var target_offset: float = 0.0
@export var lookahead: float = 3.0
@export var checkpoint_system: Node3D
@export var visual_body_height_offset: float = 0.5  # Height above ground

@onready var skier_visual_body: Node3D = $"Bot Visual Body"
@onready var ground_raycast: RayCast3D = $"Bot Visual Body/RayCast3D"

var checkpoints: Array = []
var current_checkpoint_index: int = 0
var current_checkpoint: Node3D
var visual_body_rotation: float = 0.0

func _ready():
	if checkpoint_system:
		checkpoints = checkpoint_system.get_children()
		if checkpoints.size() > 0:
			current_checkpoint = checkpoints[current_checkpoint_index]
			connect_to_checkpoint(current_checkpoint)

func _physics_process(delta: float) -> void:
	if current_checkpoint:
		move_towards_checkpoint(delta)
		update_visual_body_position()
		align_visual_body_to_surface()

func move_towards_checkpoint(delta: float):
	# Calculate direction to checkpoint
	var target_position = current_checkpoint.global_position
	target_position.y += target_offset  # Apply vertical offset if needed
	
	var direction = (target_position - global_position).normalized()
	
	# Apply lookahead - predict where we'll be and adjust direction
	var predicted_position = global_position + linear_velocity * lookahead
	var lookahead_direction = (target_position - predicted_position).normalized()
	
	# Blend current direction with lookahead direction
	direction = direction.lerp(lookahead_direction, 0.5)
	
	# Apply force towards checkpoint
	var force = direction * speed
	apply_central_force(force)

func connect_to_checkpoint(checkpoint: Node3D):
	# Connect to checkpoint's area_entered signal if it has one
	if checkpoint.has_signal("body_entered"):
		if not checkpoint.body_entered.is_connected(_on_checkpoint_entered):
			checkpoint.body_entered.connect(_on_checkpoint_entered)

func _on_checkpoint_entered(body: Node3D):
	# Check if the body that entered is this AI player
	if body == self:
		advance_to_next_checkpoint()

func advance_to_next_checkpoint():
	# Disconnect from current checkpoint
	if current_checkpoint and current_checkpoint.has_signal("body_entered"):
		if current_checkpoint.body_entered.is_connected(_on_checkpoint_entered):
			current_checkpoint.body_entered.disconnect(_on_checkpoint_entered)
	
	# Move to next checkpoint
	current_checkpoint_index += 1
	
	# Loop back to first checkpoint if we've reached the end
	if current_checkpoint_index >= checkpoints.size():
		current_checkpoint_index = 0
	
	# Set new current checkpoint
	current_checkpoint = checkpoints[current_checkpoint_index]
	connect_to_checkpoint(current_checkpoint)
	
	print("AI Player advanced to checkpoint: ", current_checkpoint_index)

# Optional: Manual checkpoint advancement for testing
func set_target_checkpoint(index: int):
	if index >= 0 and index < checkpoints.size():
		# Disconnect from current checkpoint
		if current_checkpoint and current_checkpoint.has_signal("body_entered"):
			if current_checkpoint.body_entered.is_connected(_on_checkpoint_entered):
				current_checkpoint.body_entered.disconnect(_on_checkpoint_entered)
		
		current_checkpoint_index = index
		current_checkpoint = checkpoints[current_checkpoint_index]
		connect_to_checkpoint(current_checkpoint)

# Get distance to current checkpoint
func get_distance_to_checkpoint() -> float:
	if current_checkpoint:
		return global_position.distance_to(current_checkpoint.global_position)
	return 0.0

# Check if we're close to checkpoint (backup method if signals fail)
func _on_area_3d_body_entered(body: Node3D):
	if body == self:
		advance_to_next_checkpoint()

func update_visual_body_position():
	# Only copy X and Z coordinates from RigidBody3D, maintain independent Y
	var visual_pos = skier_visual_body.global_position
	visual_pos.x = global_position.x
	visual_pos.z = global_position.z
	# Keep the visual body's current Y position - it will be updated by ground detection
	skier_visual_body.global_position = visual_pos

func align_visual_body_to_surface():
	# Cast ray from above the visual body position to find ground
	var raycast_start = Vector3(skier_visual_body.global_position.x, 
								skier_visual_body.global_position.y + 10.0, 
								skier_visual_body.global_position.z)
	var raycast_end = Vector3(skier_visual_body.global_position.x, 
							  skier_visual_body.global_position.y - 10.0, 
							  skier_visual_body.global_position.z)
	
	ground_raycast.global_position = raycast_start
	ground_raycast.target_position = Vector3(0, -20.0, 0)  # Cast downward
	ground_raycast.force_raycast_update()
	
	if ground_raycast.is_colliding():
		var hit_point = ground_raycast.get_collision_point()
		var surface_normal = ground_raycast.get_collision_normal()
		
		# Position visual body at ground level plus offset
		var visual_pos = skier_visual_body.global_position
		visual_pos.y = hit_point.y + visual_body_height_offset
		skier_visual_body.global_position = visual_pos
		
		# Calculate forward direction based on RigidBody3D movement direction
		var movement_direction = Vector3.ZERO
		if linear_velocity.length() > 0.1:
			movement_direction = linear_velocity.normalized()
		else:
			# Fallback to transform forward when not moving
			movement_direction = -global_transform.basis.z
		
		# Project movement direction onto the surface plane
		var forward = (movement_direction - movement_direction.dot(surface_normal) * surface_normal).normalized()
		var right = forward.cross(surface_normal).normalized()
		
		# Create basis that aligns with surface normal but faces movement direction
		skier_visual_body.transform.basis = Basis(right, surface_normal, -forward)
	else:
		# No ground found, keep visual body upright and facing movement direction
		var movement_direction = Vector3.ZERO
		if linear_velocity.length() > 0.1:
			movement_direction = linear_velocity.normalized()
		else:
			movement_direction = -global_transform.basis.z
		
		var y_rotation = atan2(movement_direction.x, movement_direction.z)
		skier_visual_body.transform.basis = Basis(Vector3.UP, y_rotation)
