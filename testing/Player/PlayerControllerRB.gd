extends CharacterBody3D

# Node references
@onready var camera_3d: Camera3D = $Camera3D
@onready var skier_visual_body: Node3D = $"Skier Visual Body"
@onready var ground_raycast: RayCast3D = $"Skier Visual Body/RayCast3D"

# Movement settings
@export var move_speed: float = 15.0
@export var acceleration: float = 8.0
@export var deceleration: float = 12.0
@export var turn_speed: float = 2.0
@export var gravity: float = 30.0
@export var ground_stick_force: float = 50.0

# Camera settings
@export var camera_sensitivity: float = 2.0
@export var camera_distance: float = 10.0
@export var camera_height: float = 5.0

# Movement state
var current_speed: float = 0.0
var visual_body_rotation: float = 0.0

# Camera state
var camera_yaw: float = 0.0
var camera_pitch: float = -20.0

func _ready():
	# Set up ground raycast if it doesn't exist
	if not ground_raycast:
		ground_raycast = RayCast3D.new()
		ground_raycast.name = "GroundRaycast"
		skier_visual_body.add_child(ground_raycast)
	
	ground_raycast.target_position = Vector3(0, -10, 0)
	ground_raycast.collision_mask = 1
	
	# Capture mouse for free look camera
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	# Free look mouse control for camera
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_yaw -= event.relative.x * camera_sensitivity * 0.01
		camera_pitch += event.relative.y * camera_sensitivity * 0.01
		camera_pitch = clamp(camera_pitch, deg_to_rad(-80), deg_to_rad(80))
	
	# Toggle mouse capture with Escape
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	handle_movement(delta)
	apply_gravity_and_ground_stick(delta)
	update_visual_body_position()
	align_visual_body_to_surface()
	update_camera()
	move_and_slide()

func handle_movement(delta):
	# Get input
	var input_dir = Vector2.ZERO
	var forward_input = 0.0
	
	# A/D for left/right rotation of visual body
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_dir.x -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_dir.x += 1.0
	
	# W/S for forward/backward movement
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		forward_input += 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		forward_input -= 1.0
	
	# Rotate visual body with A/D input
	if input_dir.x != 0:
		visual_body_rotation += -input_dir.x * turn_speed * delta
	
	# Update speed based on W/S input
	if forward_input > 0:
		current_speed = move_toward(current_speed, move_speed, acceleration * delta)
	elif forward_input < 0:
		current_speed = move_toward(current_speed, -move_speed * 0.5, deceleration * delta)
	else:
		current_speed = move_toward(current_speed, 0.0, deceleration * delta)
	
	# Apply movement in the direction the visual body is facing
	var forward_direction = Vector3.FORWARD.rotated(Vector3.UP, visual_body_rotation)
	velocity.x = forward_direction.x * current_speed
	velocity.z = forward_direction.z * current_speed

func apply_gravity_and_ground_stick(delta):
	# Apply gravity when not on floor
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# When on floor, apply downward force to stick to ground and prevent bouncing
		if velocity.y > 0:
			velocity.y = 0
		
		# Extra ground stick force when moving down slopes
		if ground_raycast.is_colliding():
			var ground_distance = ground_raycast.get_collision_point().distance_to(global_position)
			if ground_distance > 0.5:
				velocity.y -= ground_stick_force * delta

func update_visual_body_position():
	# Move skier visual body to match the CharacterBody3D position
	skier_visual_body.global_position = global_position

func align_visual_body_to_surface():
	# Position raycast at visual body location
	ground_raycast.global_position = skier_visual_body.global_position
	ground_raycast.force_raycast_update()
	
	if ground_raycast.is_colliding():
		var surface_normal = ground_raycast.get_collision_normal()
		
		# Create forward direction from visual body rotation
		var forward = Vector3.FORWARD.rotated(Vector3.UP, visual_body_rotation)
		
		# Project forward direction onto the surface plane
		forward = (forward - forward.dot(surface_normal) * surface_normal).normalized()
		var right = forward.cross(surface_normal).normalized()
		
		# Align visual body to surface normal
		skier_visual_body.transform.basis = Basis(right, surface_normal, -forward)
	else:
		# No surface detected, just apply Y rotation
		skier_visual_body.transform.basis = Basis(Vector3.UP, visual_body_rotation)

func update_camera():
	# Calculate orbit camera position based on CharacterBody3D
	var orbit_center = global_position + Vector3.UP * camera_height
	
	# Apply yaw and pitch to camera offset
	var camera_offset = Vector3.BACK * camera_distance
	camera_offset = camera_offset.rotated(Vector3.UP, camera_yaw)
	camera_offset = camera_offset.rotated(camera_offset.cross(Vector3.UP).normalized(), camera_pitch)
	
	# Position and orient camera
	camera_3d.global_position = orbit_center + camera_offset
	camera_3d.look_at(global_position, Vector3.UP)
