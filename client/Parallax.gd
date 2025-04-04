extends TextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	scale = (Vector2.ONE / cam.zoom)
	scale.x = pow(scale.x, 0.99)
	scale.y = pow(scale.y, 0.99)

	var target_pos := (cam.position * 0.99)
	target_pos.x = fmod(target_pos.x, 5000)
	target_pos.y = fmod(target_pos.y, 5000)

	position = cam.position - target_pos - Vector2.ONE * 2500 * scale