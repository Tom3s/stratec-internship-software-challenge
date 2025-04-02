package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"
import "core:math/linalg"

// @(static) 
earth_mass: f64 = 0.0;

GRAVITATIONAL_CONSTANT: f64 = cast(f64) 6.67 * cast(f64) linalg.exp10(-11.0);

Planet :: struct {
	name: string,
	diameter: int,
	relative_mass: f64,
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

get_time_to_reach_escape_velocity :: proc(planet: Planet, rocket: Rocket) -> f64 {
	return get_escape_velocity(planet) / (cast(f64) rocket.nr_engines * rocket.acceleration);
}

get_distance_until_escape_velocity :: proc(planet: Planet, rocket: Rocket, init_velocity: f64 = 0.0) -> f64 {
	t := get_time_to_reach_escape_velocity(planet, rocket);
	return init_velocity * t + ((cast(f64) rocket.nr_engines * rocket.acceleration) * t * t) / 2.0;
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

// odin run ./backend/src -out:main.exe
main :: proc() {
	// buf: [256]byte
	// fmt.println("Please enter some text:")
	// str := read_input(buf[:]);
	// fmt.println("Outputted text:", str)

	planets := read_planetary_data();

	rocket := read_rocket_data();

	fmt.println(rocket);

	for planet in planets {
		// fmt.println(planet);
		fmt.printfln("%s's escape velocity: %.3f km/s ", planet.name, ms_to_kms(get_escape_velocity(planet)));
		fmt.printfln("Time to reach escape velocity: %.3f s", get_time_to_reach_escape_velocity(planet, rocket));
		fmt.printfln("Distance travelled until escape: %.3f km (from surface)\n", get_distance_until_escape_velocity(planet, rocket) * 0.001);
	}
}
