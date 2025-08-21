extends Node3D

@onready var camera_3d: Camera3D = $Camera3D
@onready var skier_visual_body: Node3D = $"Skier Visual Body"
@onready var rigid_body: RigidBody3D = $CharacterBody3D

# Movement settings
@export var move_force: float = 50.0
@export var constant_forward_force: float = 20.0
@export var turn_speed: float = 2.0
@export var camera_sensitivity: float = 2.0
@export var camera_distance: float = 10.0
@export var camera_height: float = 5.0

# Raycast for surface alignment
var raycast: RayCast3D
var camera_yaw: float = 0.0
var camera_pitch: float = -20.0
var visual_body_y_rotation: float = 0.0

func _ready():
	# Create raycast for surface alignment
	raycast = RayCast3D.new()
	raycast.target_position = Vector3(0, -10, 0)
	raycast.collision_mask = 1  # Adjust based on your collision layers
	add_child(raycast)
	
	# Capture mouse for orbit camera
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	# Orbit camera control
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
	update_visual_body()
	update_camera()

func handle_movement(delta):
	# Get input
	var input_vector = Vector2.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_vector.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_vector.y += 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_vector.y -= 1
	
	# Rotate visual body with A/D inputs
	if input_vector.x != 0:
		visual_body_y_rotation += -input_vector.x * turn_speed * delta
	
	# Apply forward force with W input
	if input_vector.y > 0:
		var forward_dir = -skier_visual_body.transform.basis.z.normalized()
		rigid_body.apply_central_force(forward_dir * move_force * input_vector.y)
	
	# Apply backward force with S input
	if input_vector.y < 0:
		var forward_dir = -skier_visual_body.transform.basis.z.normalized()
		rigid_body.apply_central_force(forward_dir * move_force * input_vector.y)
	
	# Constantly apply forward force in the direction the visual body is facing
	var forward_dir = -skier_visual_body.transform.basis.z.normalized()
	rigid_body.apply_central_force(forward_dir * constant_forward_force)

func update_visual_body():
	# Move visual body to rigid body position
	skier_visual_body.global_position = rigid_body.global_position
	
	# Raycast from rigid body position downward
	raycast.global_position = rigid_body.global_position
	raycast.force_raycast_update()
	
	if raycast.is_colliding():
		var surface_normal = raycast.get_collision_normal()
		
		# Create forward direction from Y rotation
		var forward = Vector3.FORWARD.rotated(Vector3.UP, visual_body_y_rotation)
		
		# Project forward onto the surface plane
		forward = (forward - forward.dot(surface_normal) * surface_normal).normalized()
		var right = forward.cross(surface_normal).normalized()
		
		# Create new basis aligned to surface
		skier_visual_body.transform.basis = Basis(right, surface_normal, -forward)
	else:
		# No surface detected, just apply Y rotation
		skier_visual_body.transform.basis = Basis(Vector3.UP, visual_body_y_rotation)

func update_camera():
	# Calculate orbit position
	var orbit_position = rigid_body.global_position
	orbit_position += Vector3.UP * camera_height
	
	# Apply yaw and pitch to get camera offset
	var camera_offset = Vector3.BACK * camera_distance
	camera_offset = camera_offset.rotated(Vector3.UP, camera_yaw)
	camera_offset = camera_offset.rotated(camera_offset.cross(Vector3.UP).normalized(), camera_pitch)
	
	# Position and orient camera
	camera_3d.global_position = orbit_position + camera_offset
	camera_3d.look_at(rigid_body.global_position, Vector3.UP)
