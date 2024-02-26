package main
import "core:math"
import rl "raylib"

// Damped spring. Based on https://www.youtube.com/watch?v=KPoeNZZ6H4s

Spring :: struct {
    k1, k2, k3, x, x_prev, y, yd: f32
}

make_spring :: proc(f, z, r, x0: f32) -> Spring {
    s := Spring{
        k1 = z / (math.PI * f),
        k2 = 1 / math.pow(2 * math.PI * f, 2),
        k3 = r * z / (2 * math.PI * f),
        x = x0,
        x_prev = x0,
        y = x0,
        yd = 0,
    }
    return s
}

update_spring :: proc(spring: ^Spring, x: f32, dt: f32) -> f32 {
    if dt == 0 {
        return x
    }
    xd := (x - spring.x_prev) / dt
    spring.x_prev = x
    spring.y += dt * spring.yd
    spring.yd += dt * (x + spring.k3 * xd - spring.y - spring.k1 * spring.yd) / spring.k2
    return spring.y
}
