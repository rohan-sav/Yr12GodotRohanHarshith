extends PathFollow3D
@export var speed := 5



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass 




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	progress += speed * delta 
	print("progress: ", progress)
