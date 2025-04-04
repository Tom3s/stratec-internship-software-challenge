extends Node2D
class_name Rocket

var start_coord: Vector2
var end_coord: Vector2
var accel_time: float
var cruise_vel: float
var start_day: int
var travel_days: int



# # Called when the node enters the scene tree for the first time.
# func _ready() -> void:
# 	var dir := (end_coord - start_coord).normalized()



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !visible:
		return

	var travel_percent := float(GlobalNames.current_day - start_day) / float(travel_days)

	if travel_percent >= 1.0:
		visible = false
		# GlobalNames.in_simulation = false


	global_position = lerp(start_coord, end_coord, travel_percent) * GlobalNames.system_scale

	var dir := (end_coord - start_coord).normalized()
	%Texture.rotation = dir.angle() + PI / 2

	queue_redraw()

func _draw() -> void:

	var thickness := 2.0 / get_viewport().get_camera_2d().zoom.x

	draw_line(
		start_coord * GlobalNames.system_scale - global_position,
		end_coord * GlobalNames.system_scale - global_position,
		Color.DARK_SEA_GREEN,
		thickness
	)
	# draw_circle(-global_position, 
	# 	GlobalNames.system_scale * orbital_radius * GlobalNames.ASTRONOMICAL_UNIT,
	# 	Color.LIGHT_GRAY, false, thickness, true)
	
	# var temp := GlobalNames.system_scale * diameter * 300
	# if planet_name == "Sun":
	# 	temp = GlobalNames.system_scale * diameter * 20

	# draw_circle(Vector2.ZERO,
	# 	temp, #shuold be 0.5
	# 	color, true)
