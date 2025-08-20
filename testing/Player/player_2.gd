extends CharacterBody3D

# Adjustable parameters for skiing feel
@export var max_speed: float = 20.0  # Top speed
@export var gravity: float = 9.8  # Gravity strength
@export var push_acceleration: float = 12.0  # Increased for better movement on flats
@export var brake_strength: float = 5.0  # Slowdown when braking
@export var turn_speed: float = 2.0  # Reduced for less aggressive turning
@export var turn_blend_rate: float = 5.0  # Rate for blending velocity towards facing (for carving turns)
@export var air_control_rate: float = 5.0  # Rate for air control adjustments
@export var flat_friction: float = 0.995  # Increased for more momentum on flats
@export var slope_friction: float = 1.0  # No loss on slopes for sustained momentum
@export var air_retention: float = 0.995  # Increased for more momentum in air (horizontal)
@export var max_slope_angle: float = deg_to_rad(60)  # Max angle considered "floor"
@export var flat_angle_threshold: float = deg_to_rad(5)  # Angle to consider "flat"

# Internal vars
var facing_direction: Vector3 = Vector3.FORWARD

func _ready():
	set_floor_max_angle(max_slope_angle)

func _physics_process(delta: float):
	# Get player input
	var input_dir = Vector2(
		Input.get_axis("ui_left", "ui_right"),  # Left/right for turning
		Input.get_axis("ui_down", "ui_up")      # Down for brake, up for push/accelerate
	)

	# Handle rotation for turning (always, even in air)
	if input_dir.x != 0:
		rotate_y(-input_dir.x * turn_speed * delta)
	facing_direction = -transform.basis.z.normalized()

	if is_on_floor():
		var floor_normal = get_floor_normal()

		# Slope acceleration from gravity
		var grav_proj = Vector3.DOWN.dot(floor_normal) * floor_normal
		var tangent_grav = (Vector3.DOWN - grav_proj) * gravity
		velocity += tangent_grav * delta

		# Player push acceleration (projected onto the floor plane)
		if input_dir.y > 0:
			var push_dir = facing_direction - facing_direction.dot(floor_normal) * floor_normal
			if push_dir.length_squared() > 0.001:
				push_dir = push_dir.normalized()
				velocity += push_dir * push_acceleration * input_dir.y * delta

		# Braking (reduce velocity)
		if input_dir.y < 0:
			var brake_amount = brake_strength * (-input_dir.y) * delta
			var speed = velocity.length()
			if speed > 0:
				var reduce = min(brake_amount, speed)
				velocity -= velocity.normalized() * reduce

		# Apply friction based on slope
		var slope_angle = acos(floor_normal.dot(Vector3.UP))
		var friction = flat_friction if slope_angle < flat_angle_threshold else slope_friction
		velocity *= friction

		# Carving turns: gradually blend velocity towards facing direction
		var current_speed = velocity.length()
		if current_speed > 0.001:
			var target_vel = facing_direction * current_speed
			velocity = velocity.lerp(target_vel, turn_blend_rate * delta)

		# Cap horizontal speed
		var horiz_speed = Vector3(velocity.x, 0, velocity.z).length()
		if horiz_speed > max_speed:
			var scale = max_speed / horiz_speed
			velocity.x *= scale
			velocity.z *= scale

	else:
		# In air: apply gravity
		velocity += Vector3.DOWN * gravity * delta

		# Limited air control: blend horizontal velocity towards facing
		var horiz_vel = Vector3(velocity.x, 0, velocity.z)
		var horiz_speed = horiz_vel.length()
		if horiz_speed > 0.001:
			var target_dir = facing_direction
			target_dir.y = 0
			if target_dir.length_squared() > 0.001:
				target_dir = target_dir.normalized()
				horiz_vel = horiz_vel.lerp(target_dir * horiz_speed, air_control_rate * delta)
				velocity.x = horiz_vel.x
				velocity.z = horiz_vel.z

		# Air resistance (dampen horizontal momentum slightly)
		velocity.x *= air_retention
		velocity.z *= air_retention

		# Cap horizontal speed in air
		horiz_speed = Vector3(velocity.x, 0, velocity.z).length()
		if horiz_speed > max_speed:
			var scale = max_speed / horiz_speed
			velocity.x *= scale
			velocity.z *= scale

	# Apply movement
	move_and_slide()
