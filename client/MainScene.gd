extends Node2D
class_name MainScene

@onready var request_button: Button = %RequestButton
@onready var sim_speed_slider: HSlider = %SimSpeedSlider
@onready var sim_speed_label: Label = %SimSpeedLabel
@onready var current_day_label: Label = %CurrentDayLabel

@onready var from_planet_button: OptionButton = %FromPlanet
@onready var to_planet_button: OptionButton = %ToPlanet

@onready var get_travel_button: Button = %GetTravelButton
@onready var travel_status_label: Label = %TravelStatusLabel
@onready var start_sim_button: Button = %StartSimButton


@onready var planet_parent: Node2D = %Planets

var planet_scene := preload("res://Planet.tscn")

var nr_engines: int = 0
var acceleration: float = 0.0

var planets: Array[GlobalNames.Planet]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	request_button.pressed.connect(connect_with_handshake)
	get_travel_button.pressed.connect(request_travel)
	start_sim_button.pressed.connect(start_simulation)

	Network.solar_system_data_received.connect(handle_solar_system_data)
	Network.travel_data_received.connect(handle_travel_data)

	var child: Planet_Object = planet_scene.instantiate()

	child.planet_name = "Sun"
	child.diameter = 1.3927 * 1000000
	child.relative_mass = 0
	child.period = 1
	child.orbital_radius = 0

	planet_parent.add_child(child)

	sim_speed_slider.value = GlobalNames.day_speed
	sim_speed_label.text = str(GlobalNames.day_speed)

	sim_speed_slider.value_changed.connect(func(val: float) -> void:
		GlobalNames.day_speed = val
		sim_speed_label.text = str(GlobalNames.day_speed)
	)

	travel_data = Travel_Data.new()



	# print("should print after global scripts")

func connect_with_handshake() -> void:
	var error := Network.connect_to_server()

	if error != OK:
		print("[PlayerSelect.gd] Aborted connection")
		return
	
	Network.send_request_all_packet()

func request_travel() -> void:
	var from_planet := from_planet_button.get_item_text(from_planet_button.selected)
	var to_planet := to_planet_button.get_item_text(to_planet_button.selected)
	
	if from_planet == "" || to_planet == "" || from_planet == to_planet:
		return

	Network.send_request_travel(from_planet, to_planet)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	current_day_label.text = "Current Day: " + str(int(GlobalNames.current_day))

func handle_solar_system_data(new_accel: float, new_nr_rockets: int, new_planets: Array[GlobalNames.Planet]) -> void:
	request_button.visible = false

	planets = new_planets
	acceleration = new_accel
	nr_engines = new_nr_rockets

	for planet in planets:
		var child: Planet_Object = planet_scene.instantiate()

		child.planet_name = planet.name
		child.diameter = planet.diameter
		child.relative_mass = planet.relative_mass
		child.period = planet.period
		child.orbital_radius = planet.orbital_radius

		planet_parent.add_child(child)

		from_planet_button.add_item(planet.name)
		to_planet_button.add_item(planet.name)

class Travel_Data:
	var from: GlobalNames.Planet
	var to: GlobalNames.Planet
	var start_coord: Vector2
	var to_coord: Vector2
	var accel_time: float
	var cruise_vel: float
	var start_day: int
	var travel_days: int

var travel_data: Travel_Data


func handle_travel_data(
	p1: String, p2: String,
	start_coord: Vector2, end_coord: Vector2,
	accel_time: float, cruise_vel: float,
	start_day: int, travel_days: int,
) -> void:
	travel_status_label.text = "Travel between " + p1 + " and " + p2 + " ready!"
	start_sim_button.disabled = false

	for planet in planets:
		if planet.name == p1:
			travel_data.from = planet
		if planet.name == p2:
			travel_data.to = planet
	
	travel_data.start_coord = start_coord
	travel_data.to_coord = end_coord
	travel_data.accel_time = accel_time
	travel_data.cruise_vel = cruise_vel
	travel_data.start_day = start_day
	travel_data.travel_days = travel_days

func start_simulation() -> void:
	var rocket: Rocket = %Rocket

	var dir := (travel_data.to_coord - travel_data.start_coord).normalized()

	rocket.start_coord = travel_data.start_coord + dir * travel_data.from.diameter * 0.5 * GlobalNames.system_scale
	rocket.end_coord = travel_data.to_coord + dir * travel_data.to.diameter * 0.5 * GlobalNames.system_scale
	rocket.start_day = travel_data.start_day
	rocket.travel_days = travel_data.travel_days

	rocket.cruise_vel = travel_data.cruise_vel * GlobalNames.system_scale

	rocket.visible = true
	# GlobalNames.in_simulation = true

	GlobalNames.current_day = travel_data.start_day

