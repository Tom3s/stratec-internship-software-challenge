package main

import "core:math"
import "core:math/linalg"

v2 :: [2]f64;
v3 :: [3]f64;
v4 :: [4]f64;
v2i :: [2]int;
v3i :: [3]int;
v4i :: [4]int;

remap :: proc(x, froma, toa, fromb, tob: f64) -> f64 {
	return linalg.lerp(
		fromb, tob, \
		linalg.unlerp(froma, toa, x), \
	);
}

// easing functions
ease_in_out_cubic :: proc(x: f64) -> f64 {
	if x < 0.5 {
		return 4 * x * x * x;
	} else {
		return 1 - linalg.pow(-2 * x + 2, 3) / 2;
	}
}

ease_out_cubic :: proc(x: f64) -> f64 {
	return 1 - linalg.pow(1 - x, 3);
}

normalize_int :: proc(v: v2i) -> v2i {
	v := v;
	// can't divide by zero smh
	if v.x != 0 {
		v.x = v.x / abs(v.x);
	}
	if v.y != 0 {
		v.y = v.y / abs(v.y);
	}

	return v;
}


length :: proc(v: v2i) -> f64 {
	return linalg.sqrt(cast(f64) (v.x * v.x) + cast(f64) (v.y * v.y));
}

distance :: proc(v1, v2: v2i) -> f64 {
	return length(v1 - v2);
}

// accuracy verified with desmos xd
// https://www.desmos.com/calculator/nsygzwbcix
// 
// for i in 0..<100 {
// 	p1: v2 = {0, 0};
// 	p2: v2 = {cast(f64) i, 100};
// 	c: v2 = {0, 50};
// 	r: f64 = 25;
// 	fmt.println(p1, p2, c, r, line_intersects_circle(p1, p2, c, r));
// }
// 
// ..
// [0, 0] [56, 100] [0, 50] 25 true
// [0, 0] [57, 100] [0, 50] 25 true
// [0, 0] [58, 100] [0, 50] 25 false
// [0, 0] [59, 100] [0, 50] 25 false
// ..
line_intersects_circle :: proc(p1, p2, c: v2, r: f64) -> bool {
	d := p2 - p1;
	f := p1 - c;

	A := d.x * d.x + d.y * d.y;
	B := 2 * (f.x * d.x + f.y * d.y);
	C := f.x * f.x + f.y * f.y - r * r;

	D := B * B - 4 * A * C;

	if D < 0 do return false;

	t1 := (-B - linalg.sqrt(D)) / (2 * A);
    t2 := (-B + linalg.sqrt(D)) / (2 * A);

	return (0 <= t1 && t1 <= 1) || (0 <= t2 && t2 <= 1);
}
