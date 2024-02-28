// based off of https://github.com/JoshuaManton/workbench/blob/da1a221932b932fc9c0cbe3f4e82be9e065b99fe/tween.odin
package main
import "core:math"
import "core:math/linalg"
import rl "raylib"
PI :: math.PI
cos :: math.cos
sin :: math.sin
pow :: math.pow
sqrt :: math.sqrt
Vec2 :: linalg.Vector2f32
Vec3 :: linalg.Vector3f32
Vec4 :: linalg.Vector4f32
Color :: rl.Color

Tweener :: struct {
    addr: rawptr,

    ptr: union {
        ^f32,
        ^Vec2,
        ^Vec3,
        ^Vec4,
        ^Color,
    },

    start: union {
        Vec2,
        f32,
        Vec3,
        Vec4,
        Color,
    },

    target: union {
        Vec2,
        f32,
        Vec3,
        Vec4,
	Color,
    },

    cur_time: f32,
    duration: f32,

    ease_proc: proc(f32) -> f32,

    start_time: f32,

    active: bool,

    callback: proc(rawptr),
    callback_data: rawptr,

    queued_tween: ^Tweener,
}

updating_tweens: bool;

Tween_Params :: struct {
    delay: f32,
    callback: proc(rawptr),
}

//tween_destroy :: proc(ptr: rawptr) {
//    for _, i in tweeners {
//        tweener := tweeners[i];
//        if tweeners[i].addr == ptr {
//            tween_destroy_index(i);
//            break;
//        }
//    }
//}

tween :: proc(ptr: ^$T, target: T, duration: f32, ease: proc(f32) -> f32 = ease_out_quart, delay : f32 = 0) -> ^Tweener {
    assert(!updating_tweens);

    //tween_destroy(ptr);
    new_tweener := tween_make(ptr, target, duration, ease, delay);
    new_tweener.active = true;
    return new_tweener;
}

tween_make :: proc(ptr: ^$T, target: T, duration: f32, ease: proc(f32) -> f32 = ease_out_quart, delay : f32 = 0) -> ^Tweener {
    new_tweener := new_clone(Tweener{ptr, ptr, ptr^, target, 0, duration, ease, f32(rl.GetTime()), false, nil, nil, nil}); // @Alloc
    //append(&tweeners, new_tweener);
    return new_tweener;
}

tween_callback :: proc(a: ^Tweener, userdata: ^$T, callback: proc(^T)) {
    a.callback = auto_cast callback;
    a.callback_data = userdata;
}

tween_queue :: proc(a, b: ^Tweener) {
    b.active = false;
    a.queued_tween = b;
}

update_tweeners :: proc(tweeners: ^[dynamic]^Tweener, dt: f32) {
    tweener_idx := len(tweeners)-1;
    updating_tweens = true;
    defer updating_tweens = false;
    for tweener_idx >= 0 {
        defer tweener_idx -= 1;

        tweener := tweeners[tweener_idx];
        assert(tweener.duration != 0);

        if !tweener.active do continue;
        if f32(rl.GetTime()) < tweener.start_time do continue;

        t := _update_tweener_t(tweener, dt)
        switch kind in tweener.ptr {
            case ^f32:  kind^ = _lerp_kind(f32, tweener, t);
            case ^Vec2: kind^ = _lerp_kind(Vec2, tweener, t);
            case ^Vec3: kind^ = _lerp_kind(Vec3, tweener, t);
            case ^Vec4: kind^ = _lerp_kind(Vec4, tweener, t);
            case ^Color: {
                a := tweener.start.(Color);
                b := tweener.target.(Color);
                result := Color{
                    u8(math.lerp(f32(a[0]), f32(b[0]), t)),
                    u8(math.lerp(f32(a[1]), f32(b[1]), t)),
                    u8(math.lerp(f32(a[2]), f32(b[2]), t)),
                    u8(math.lerp(f32(a[3]), f32(b[3]), t)),
                };
                kind^ = result
            }
        }

        if t == 1 {
            q := tweener.queued_tween
            if q != nil {
                q.active = true
                switch kind in q.ptr {
                    case ^f32:   q.start = kind^;
                    case ^Vec2:  q.start = kind^;
                    case ^Vec3:  q.start = kind^;
                    case ^Vec4:  q.start = kind^;
                    case ^Color: q.start = kind^;
                }
                tweener.queued_tween.start_time = f32(rl.GetTime())
            }

            // destroy
            unordered_remove(tweeners, tweener_idx)
            free(tweener)
        }
    }
}

_update_tweener_t :: proc(tweener: ^Tweener, dt: f32) -> f32 {
    if tweener.cur_time > tweener.duration {
        return 1;
    }

    tweener.cur_time += dt;

    t := tweener.cur_time / tweener.duration;
    return tweener.ease_proc(t);
}


_lerp_kind :: proc($kind: typeid, tweener: ^Tweener, t: f32) -> kind {
    a := tweener.start.(kind);
    b := tweener.target.(kind);
    result := math.lerp(a, b, t);
    return result
}

ease_linear :: proc(_t: f32) -> f32 {
    t := _t;
    return t;
}

ease_in_sine :: proc(_t: f32) -> f32 {
    t := _t;
    t -= 1;
    return 1 + sin(1.5707963 * t);
}

ease_out_sine :: proc(_t: f32) -> f32 {
    t := _t;
    return sin(1.5707963 * t);
}

ease_in_out_sine :: proc(_t: f32) -> f32 {
    t := _t;
    return 0.5 * (1 + sin(3.1415926 * (t - 0.5)));
}

ease_in_quad :: proc(_t: f32) -> f32 {
    t := _t;
    return t * t;
}

ease_out_quad ::  proc(_t: f32) -> f32 {
    t := _t;
    return t * (2 - t);
}

ease_in_out_quad :: proc(_t: f32) -> f32 {
    t := _t;
    if t < 0.5 {
        return 2 * t * t;
    }
    else {
        return t * (4 - 2 * t) - 1;
    }
}

ease_in_cubic :: proc(_t: f32) -> f32 {
    t := _t;
    return t * t * t;
}

ease_out_cubic :: proc(_t: f32) -> f32 {
    t := _t;
    t -= 1;
    return 1 + t * t * t;
}

ease_in_out_cubic :: proc(_t: f32) -> f32 {
    t := _t;
    if t < 0.5 {
        return 4 * t * t * t;
    }
    else {
        t -= 1;
        return 1 + t * (2 * t) * (2 * t);
    }
}

ease_in_quart :: proc(_t: f32) -> f32 {
    t := _t;
    t *= t;
    return t * t;
}

ease_out_quart :: proc(_t: f32) -> f32 {
    t := _t;
    t -= 1;
    t = t * t;
    return 1 - t * t;
}

ease_in_out_quart :: proc(_t: f32) -> f32 {
    t := _t;
    if t < 0.5 {
        t *= t;
        return 8 * t * t;
    }
    else {
        t -= 1;
        t = t * t;
        return 1 - 8 * t * t;
    }
}

ease_in_quint :: proc(_t: f32) -> f32 {
    t := _t;
    t2 := t * t;
    return t * t2 * t2;
}

ease_out_quint :: proc(_t: f32) -> f32 {
    t := _t;
    t -= 1;
    t2 := t * t;
    return 1 + t * t2 * t2;
}

ease_in_out_quint :: proc(_t: f32) -> f32 {
    t := _t;
    if t < 0.5 {
        t2 := t * t;
        return 16 * t * t2 * t2;
    }
    else {
        t -= 1;
        t2 := t * t;
        return 1 + 16 * t * t2 * t2;
    }
}

ease_in_expo :: proc(_t: f32) -> f32 {
    t := _t;
    return (pow(2, 8 * t) - 1) / 255;
}

ease_out_expo :: proc(_t: f32) -> f32 {
    t := _t;
    return 1 - pow(2, -8 * t);
}

ease_in_out_expo :: proc(_t: f32) -> f32 {
    t := _t;
    if t < 0.5 {
        return (pow(2, 16 * t) - 1) / 510;
    }
    else {
        return 1 - 0.5 * pow(2, -16 * (t - 0.5));
    }
}

ease_in_circ :: proc(_t: f32) -> f32 {
    t := _t;
    return 1 - sqrt(1 - t);
}

ease_out_circ :: proc(_t: f32) -> f32 {
    t := _t;
    return sqrt(t);
}

ease_in_out_circ :: proc(_t: f32) -> f32 {
    t := _t;
    if t < 0.5 {
        return (1 - sqrt(1 - 2 * t)) * 0.5;
    }
    else {
        return (1 + sqrt(2 * t - 1)) * 0.5;
    }
}

ease_in_back :: proc(_t: f32) -> f32 {
    t := _t;
    return t * t * (2.70158 * t - 1.70158);
}

ease_out_back :: proc(_t: f32) -> f32 {
    t := _t;
    t -= 1;
    return 1 + t * t * (2.70158 * t + 1.70158);
}

ease_in_out_back :: proc(_t: f32) -> f32 {
    t := _t;
    if t < 0.5 {
        return t * t * (7 * t - 2.5) * 2;
    }
    else {
        t -= 1;
        return 1 + t * t * 2 * (7 * t + 2.5);
    }
}

ease_in_elastic :: proc(_t: f32) -> f32 {
    t := _t;
    t2 := t * t;
    return t2 * t2 * sin(t * PI * 4.5);
}

ease_out_elastic :: proc(_t: f32) -> f32 {
    t := _t;
    t2 := (t - 1) * (t - 1);
    return 1 - t2 * t2 * cos(t * PI * 4.5);
}

ease_in_out_elastic :: proc(_t: f32) -> f32 {
    t := _t;
    if t < 0.45 {
        t2 := t * t;
        return 8 * t2 * t2 * sin(t * PI * 9);
    }
    else if t < 0.55 {
        return 0.5 + 0.75 * sin(t * PI * 4);
    }
    else {
        t2 := (t - 1) * (t - 1);
        return 1 - 8 * t2 * t2 * sin(t * PI * 9);
    }
}

ease_in_bounce :: proc(_t: f32) -> f32 {
    t := _t;
    return pow(2, 6 * (t - 1)) * abs(sin(t * PI * 3.5));
}

ease_out_bounce :: proc(_t: f32) -> f32 {
    t := _t;
    return 1 - pow(2, -6 * t) * abs(cos(t * PI * 3.5));
}

ease_in_out_bounce :: proc(_t: f32) -> f32 {
    t := _t;
    if t < 0.5 {
        return 8 * pow(2, 8 * (t - 1)) * abs(sin(t * PI * 7));
    }
    else {
        return 1 - 8 * pow(2, -8 * t) * abs(sin(t * PI * 7));
    }
}
