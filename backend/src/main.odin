package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:math/linalg"

// @(static) 
earth_mass: f64 = 0.0;

GRAVITATIONAL_CONSTANT: f64 = cast(f64) 6.67 * cast(f64) linalg.exp10(-11.0);
ASTRONOMICAL_UNIT: f64 = 149597870.7;

Planet :: struct {
	name: string,
	diameter: int,
	relative_mass: f64,

	period: int,
	orbital_radius: f64,
}

Rocket :: struct {
	nr_engines: int,
	acceleration: f64,
}

get_mass :: proc(planet: Planet) -> f64 {
	return earth_mass * planet.relative_mass;
}

get_escape_velocity :: proc(planet: Planet) -> f64 {
	return linalg.sqrt(
		2 * GRAVITATIONAL_CONSTANT * get_mass(planet) /\
		(cast(f64) planet.diameter / 2 * 1000.0)
	)
}

ms_to_kms :: proc(ms: f64) -> f64 {
	return ms * 0.001;
}

get_accel_time :: proc(v1, v2: f64, rocket: Rocket) -> f64 {
	return linalg.abs(v1 - v2) / (cast(f64) rocket.nr_engines * rocket.acceleration)
}

get_time_to_reach_escape_velocity :: proc(planet: Planet, rocket: Rocket, init_velocity: f64 = 0.0) -> f64 {
	return get_accel_time(get_escape_velocity(planet), init_velocity, rocket);
}

get_distance_travelled_with_accel :: proc(v, t, a: f64) -> f64 {
	return v * t + (a * t * t) / 2.0;
}

get_distance_until_escape_velocity :: proc(planet: Planet, rocket: Rocket, init_velocity: f64 = 0.0) -> f64 {
	t := get_time_to_reach_escape_velocity(planet, rocket, init_velocity);
	// return init_velocity * t + ((cast(f64) rocket.nr_engines * rocket.acceleration) * t * t) / 2.0;
	return get_distance_travelled_with_accel(init_velocity, t, (cast(f64) rocket.nr_engines * rocket.acceleration));
}


read_input :: proc(buffer: []byte) -> string {
	n, err := os.read(os.stdin, buffer[:]);
	if err != nil {
		fmt.eprintln("Error reading: ", err);
		os.exit(1);
		// return
	}
	str := string(buffer[:n])
	// fmt.println("Outputted text:", str)
	return str;
}

read_planetary_data :: proc(filepath: string = "./Planetary_Data.txt") -> [dynamic]Planet {
	planets := make([dynamic]Planet);

	data, ok := os.read_entire_file(filepath, context.allocator);
	if !ok {
		// could not read file
		return {};
	}
	defer delete(data, context.allocator);

	it := string(data);
	for line in strings.split_lines_iterator(&it) {
		// process line
		// fmt.println(line);
		planet_data := strings.split(line, " ");

		planet: Planet;

		// check if there are enough fields (earth should be longer)
		if len(planet_data) >= 9 {
			if !strings.has_suffix(planet_data[0], ":") {
				fmt.println("Invalid planet data format; Missing \":\" for name");
				return {};
			}
			planet_name, was_alloc := strings.remove(planet_data[0], ":", -1);
			planet.name = planet_name;

			if planet_data[1] != "diameter" {
				fmt.println("Invalid planet data format; Missing \"diameter\" keyword");
				return {};
			}
			if planet_data[2] != "=" {
				fmt.println("Invalid planet data format; Missing \"=\" after \"diameter\" keyword");
				return {};
			}

			diameter := strconv.atoi(planet_data[3]);

			if planet_data[4] != "km," {
				fmt.println("Invalid planet data format; Wrong unit for diameter");
				return {};
			}

			planet.diameter = diameter;

			if planet_data[5] != "mass" {
				fmt.println("Invalid planet data format; Missing \"mass\" keyword");
				return {};
			}
			if planet_data[6] != "=" {
				fmt.println("Invalid planet data format; Missing \"=\" after \"mass\" keyword");
				return {};
			}

			mass := 1.0;

			if planet.name != "Earth" {
				mass = strconv.atof(planet_data[7]);
			} else {
				// earth_mass = 0.0;
				mantissa := strconv.atof(planet_data[7]);
				if planet_data[8] != "*" {
					fmt.println("Invalid planet data format; Missing \"*\" for earth mass");
					return {};
				}
				if !strings.has_prefix(planet_data[9], "10^") {
					fmt.println("Invalid planet data format; Wrong notation for earth mass");
					return {};
				}
				exponent_str, was_alloc := strings.remove(planet_data[9], "10^", -1);

				exponent := strconv.atof(exponent_str);

				earth_mass = auto_cast (mantissa * linalg.exp10(exponent));
			}

			planet.relative_mass = auto_cast mass;

			append(&planets, planet);

		}

		// fmt.printf("Planet Mass: %.5f \n", get_mass(planet));
	}

	return planets;
}

read_rocket_data :: proc(filepath: string = "./Rocket_Data.txt") -> Rocket {
	data, ok := os.read_entire_file(filepath, context.allocator);
	if !ok {
		// could not read file
		return {};
	}
	defer delete(data, context.allocator);

	rocket_data, err := strings.split_lines(string(data));

	// fmt.println(rocket_data);
	if !strings.has_prefix(rocket_data[0], "Number of rocket engines: ") {
		fmt.println("Invalid rocket data format; Missing nr rockets");
		return {};
	}

	nr_engines_str, _ := strings.remove_all(rocket_data[0], "Number of rocket engines: ");

	nr_engines := strconv.atoi(nr_engines_str);

	if !strings.has_prefix(rocket_data[1], "Acceleration per engine: ") {
		fmt.println("Invalid rocket data format; Missing acceleration");
		return {};
	}
	if !strings.has_suffix(rocket_data[1], " m/s^2") {
		fmt.println("Invalid rocket data format; Wrong acceleration unit");
		return {};
	}

	temp, _ := strings.remove_all(rocket_data[1], "Acceleration per engine: ")
	acceleration_str, _ := strings.remove_all(temp, " m/s^2");

	acceleration := strconv.atof(acceleration_str);

	return Rocket{
		acceleration = acceleration,
		nr_engines = nr_engines,
	}
}

// SS_Data :: struct {
// 	name: string,
// 	period: int,
// 	radius: f64,
// }

read_solar_system_data :: proc(planets: [dynamic]Planet, filepath: string = "./Solar_System_Data.txt") -> [dynamic]Planet {
	data, ok := os.read_entire_file(filepath, context.allocator);
	if !ok {
		// could not read file
		return {};
	}
	defer delete(data, context.allocator);

	it := string(data);
	for line in strings.split_lines_iterator(&it) {
		planet_data := strings.split(line, " ");

		if !strings.has_suffix(planet_data[0], ":") {
			fmt.println("Invalid solar system data format; Missing \":\" for name");
			return {};
		}
		planet_name, was_alloc := strings.remove(planet_data[0], ":", -1);

		if planet_data[1] != "period" {
			fmt.println("Invalid solar system data format; Missing \"period\" keyword");
			return {};
		}
		if planet_data[2] != "=" {
			fmt.println("Invalid solar system data format; Missing \"=\" after \"period\" keyword");
			return {};
		}

		period := strconv.atoi(planet_data[3]);

		if planet_data[4] != "days," {
			fmt.println("Invalid solar system data format; Wrong unit for period");
			return {};
		}

		if planet_data[5] != "orbital" {
			fmt.println("Invalid solar system data format; Missing \"orbital\" keyword");
			return {};
		}
		if planet_data[6] != "radius" {
			fmt.println("Invalid solar system data format; Missing \"radius\" keyword");
			return {};
		}
		if planet_data[7] != "=" {
			fmt.println("Invalid solar system data format; Missing \"=\" after \"orbital radius\"");
			return {};
		}

		orbital_radius := strconv.atof(planet_data[8]);

		if planet_data[9] != "AU" {
			fmt.println("Invalid solar system data format; Wrong unit for orbital radius");
			return {};
		}

		for &planet in planets {
			if planet.name == planet_name {
				planet.period = period;
				planet.orbital_radius = orbital_radius;
			}
		}

		// fmt.printf("Planet Mass: %.5f \n", get_mass(planet));
	}

	return planets;
}

get_distance_between :: proc(p1, p2: Planet) -> f64 {
	return linalg.abs(p1.orbital_radius - p2.orbital_radius) * ASTRONOMICAL_UNIT;
}

Time :: struct {
	total_seconds: f64,

	seconds: int,
	minutes: int,
	hours: int,
	days: int,
}

make_time :: proc(s: f64) -> Time {
	t := cast(int) s;

	time: Time;
	time.total_seconds = s;

	time.seconds = t % 60;
	t -= time.seconds;
	t /= 60;
	time.minutes = t % 60;

	t -= time.minutes;
	t /= 60;
	time.hours = t % 60;

	t -= time.hours;
	// t /= 24;
	time.days = t / 24;

	return time;
}

// stage 3
// time to reach cruising vel
// distance from surface at cruising vel
// time of cruise
// distance from surface to start decel
// time to decelerate
// total travel time (+ days, h, m, s formatting)

Travel_Data :: struct {
	p1, p2: Planet,
	rocket: Rocket,

	total_distance: f64,
	accel_time: f64,
	dist_from_surface: f64,
	cruise_time: Time,
	dist_to_surface: f64,
	decel_time: f64,
	travel_time: Time,
}

get_travel_data :: proc(p1, p2: Planet, rocket: Rocket) -> Travel_Data {
	p1 := p1;
	p2 := p2;
	// calc distance between planets
	d := get_distance_between(p1, p2);
	// fmt.printfln("%.3f", d);

	// cruising_velocity := 0.0;
	// accel_decel_time := ;
	// cruising_velocity, accel_time, escape_distance: f64;
	heavier_planet, lighter_planet: ^Planet;
	
	if p1.relative_mass >= p2.relative_mass {
		heavier_planet = &p1;
		lighter_planet = &p2;
	} else {
		heavier_planet = &p2;
		lighter_planet = &p1;
	}

	cruising_velocity := get_escape_velocity(heavier_planet^);
	accel_time := get_time_to_reach_escape_velocity(heavier_planet^, rocket);
	escape_distance := get_distance_until_escape_velocity(heavier_planet^, rocket) * 0.001;

	
	
	s_cruise_vel := get_escape_velocity(lighter_planet^);
	s_accel_time := get_time_to_reach_escape_velocity(lighter_planet^, rocket);
	s_escape_distance := get_distance_until_escape_velocity(lighter_planet^, rocket) * 0.001;
	s_t := get_accel_time(cruising_velocity, s_cruise_vel, rocket);
	s_dist := get_distance_travelled_with_accel(cruising_velocity, s_t, - (cast(f64) rocket.nr_engines * rocket.acceleration));
	
	dist_to_surface := (s_escape_distance + s_dist) * 0.001

	cruise_distance := d - escape_distance - dist_to_surface - cast(f64) p1.diameter * .5 - cast(f64) p2.diameter * .5;
	cruise_time := cruise_distance / ms_to_kms(cruising_velocity);

	travel_time := cruise_time + accel_time + s_accel_time + s_t;

	// time := make_time(travel_time);

	return Travel_Data{
		p1 = p1,
		p2 = p2,
		total_distance = d - cast(f64) p1.diameter * .5 - cast(f64) p2.diameter * .5,
		rocket = rocket,
		accel_time = accel_time,
		dist_from_surface = escape_distance,
		cruise_time = make_time(cruise_time),
		dist_to_surface = dist_to_surface,
		decel_time = s_accel_time + s_t,
		travel_time = make_time(travel_time),
	};
}

print_travel_data :: proc(data: Travel_Data) {
	fmt.println("Information about travel between", data.p1.name, "and", data.p2.name);
	fmt.printfln("Time to reach cruising velocity from %s: %.3fs", data.p1.name, data.accel_time);
	fmt.printfln("Distance from %s's surface at cruising velocity: %.3f km", data.p1.name, data.dist_from_surface);
	fmt.printfln("Cruising time: %i days, %i h, %i m, %i s (%.3f total seconds)",
		data.cruise_time.days,
		data.cruise_time.hours,
		data.cruise_time.minutes,
		data.cruise_time.seconds,
		data.cruise_time.total_seconds,
	);
	fmt.printfln("Distance from %s's surface at cruising velocity: %.3f km", data.p2.name, data.dist_to_surface);
	fmt.printfln("Time to decelerate to 0 km/s: %.3fs", data.decel_time);
	fmt.printfln("Total distance travelled: %.3f km", data.total_distance);
	fmt.printfln("Total travel time time: %i days, %i h, %i m, %i s (%.3f total seconds)",
		data.travel_time.days,
		data.travel_time.hours,
		data.travel_time.minutes,
		data.travel_time.seconds,
		data.travel_time.total_seconds,
	);
}

get_planet_position :: proc(planet: Planet, days: int) -> f64 {
	return linalg.mod((360.0 / cast(f64) planet.period) * cast(f64) days, 360);
}

get_planet_position_rad :: proc(planet: Planet, days: int) -> f64 {
	return linalg.mod((linalg.TAU / cast(f64) planet.period) * cast(f64) days, linalg.TAU);
}


// odin run ./backend/src -out:main.exe
main :: proc() {
	// buf: [256]byte
	// fmt.println("Please enter some text:")
	// str := read_input(buf[:]);
	// fmt.println("Outputted text:", str)

	planets := read_planetary_data();

	rocket := read_rocket_data();

	read_solar_system_data(planets);

	fmt.println(rocket);

	day := 365 * 100;

	for planet in planets {
		// fmt.println(planet);
		// fmt.printfln("%s's escape velocity: %.3f km/s ", planet.name, ms_to_kms(get_escape_velocity(planet)));
		// fmt.printfln("Time to reach escape velocity: %.3f s", get_time_to_reach_escape_velocity(planet, rocket));
		// fmt.printfln("Distance travelled until escape: %.3f km (from surface)\n", get_distance_until_escape_velocity(planet, rocket) * 0.001);
		fmt.printfln("%s's position in degrees afetr %i days: %.3f", 
			planet.name,
			day,
			get_planet_position(planet, day),
		)
	}

	// stage 4
	// step 1 day
	// check for intersection
	// no intersect -> get travel data
	// skip travel data if dist > best
	// better data -> save


	// p1 := planets[2];
	// p2 := planets[3];

	// travel_data := get_travel_data(p1, p2, rocket);

	// print_travel_data(travel_data);



}
