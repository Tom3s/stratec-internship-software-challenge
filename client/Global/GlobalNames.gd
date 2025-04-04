extends Node
# class_name GlobalNames

var EARTH_MASS: float = 0.0
var GRAVITATIONAL_CONSTANT: float = 0.0
var ASTRONOMICAL_UNIT: float = 0.0

var current_day: float = 365*100
var day_speed: float = 6.0

var in_simulation: bool = false

signal system_scale_changed()

var system_scale: float = 0.0005:
	set(new_val):
		system_scale = new_val
		system_scale_changed.emit()

class Planet:
	var name: String = ""
	var diameter: int
	var relative_mass: float

	var period: int
	var orbital_radius: float

func _process(delta: float) -> void:
	current_day += day_speed * delta

