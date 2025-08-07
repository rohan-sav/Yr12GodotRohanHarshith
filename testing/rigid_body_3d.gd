extends RigidBody3D

@export var path: Path3D
@export var speed: float = 50.0
@export var target_offset: float = 0.0
@export var lookahead: float = 3.0

func _physics_process(delta: float) -> void:
	if path == null or path.curve == null:
		return

	target_offset += lookahead * delta
	var target_pos: Vector3 = path.curve.sample_baked(target_offset)
	var direction = (target_pos - global_transform.origin).normalized()

	apply_central_force(direction * speed)
