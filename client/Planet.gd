extends Node2D
class_name Planet_Object

@export
var planet_name: String = ""
@export
var diameter: int
@export
var relative_mass: float

@export
var period: int
@export
var orbital_radius: float

var color: Color

var planet_colors := {
	"Sun": Color(1.0, 0.9, 0.0),  # Bright yellow
	"Mercury": Color(0.6, 0.6, 0.6),  # Grayish rocky
	"Venus": Color(0.9, 0.7, 0.3),  # Pale yellow/orange due to thick atmosphere
	"Earth": Color(0.0, 0.5, 1.0),  # Blue oceans dominate
	"Mars": Color(0.8, 0.3, 0.1),  # Reddish due to iron oxide
	"Jupiter": Color(0.9, 0.6, 0.3),  # Brown-orange with cloud bands
	"Saturn": Color(0.9, 0.8, 0.5),  # Pale yellow-beige
	"Uranus": Color(0.5, 0.8, 0.9),  # Cyan due to methane in the atmosphere
	"Neptune": Color(0.2, 0.4, 0.8),  # Deep blue due to methane
	"Pluto": Color(0.8, 0.7, 0.6),  # Pale brown/gray with slight orange hue
}



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	color = Color(randf(), randf(), randf())

	if planet_colors.has(planet_name):
		color = planet_colors[planet_name]

	%Label.text = planet_name

	GlobalNames.system_scale_changed.connect(queue_redraw)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# %Label.position = Vector2(orbital_radius * GlobalNames.ASTRONOMICAL_UNIT, 0) * GlobalNames.system_scale

	# global_position = Vector2(orbital_radius * GlobalNames.ASTRONOMICAL_UNIT, 0) * GlobalNames.system_scale
	global_position = get_planet_position()

	queue_redraw()

func _draw() -> void:

	var thickness := 4.0 / get_viewport().get_camera_2d().zoom.x

	draw_circle(-global_position, 
		GlobalNames.system_scale * orbital_radius * GlobalNames.ASTRONOMICAL_UNIT,
		Color.LIGHT_GRAY, false, thickness, true)
	
	var temp := GlobalNames.system_scale * diameter * 300
	if planet_name == "Sun":
		temp = GlobalNames.system_scale * diameter * 20
	
	if GlobalNames.in_simulation:
		temp = GlobalNames.system_scale * diameter * 0.5

	draw_circle(Vector2.ZERO,
		temp, #shuold be 0.5
		color, true)

	
# get_planet_position :: proc(planet: Planet, day: i32) -> v2 {
# 	angle := get_planet_angle_rad(planet, day);
# 	return {linalg.cos(angle), linalg.sin(angle)} * planet.orbital_radius * ASTRONOMICAL_UNIT;
# }
func get_planet_position() -> Vector2:
	var angle := fmod((TAU / period) * GlobalNames.current_day, TAU)

	return Vector2(cos(angle), sin(angle)) * orbital_radius * GlobalNames.ASTRONOMICAL_UNIT * GlobalNames.system_scale
	