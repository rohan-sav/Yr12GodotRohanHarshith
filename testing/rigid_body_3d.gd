extends RigidBody3D
@export var path: Path3D 
@export var speed = 50.0
@export var target_offset = 0.0
@export var lookahead = 3.0


func _ready() -> void:
	pass 



func _process(delta: float) -> void:
	if path == null or path.curve == null:
		return 

target_offset += lookahead * delta
var target_pos: vector3 = path.curve.sample_baked(target_offset)
var direction = (target_pos - global_transform.origin).normalised()

apply_central_force(direction * speed)
