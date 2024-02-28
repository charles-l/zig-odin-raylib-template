package main
import "core:runtime"
import rl "raylib"
import c "core:c"
import "core:mem"
import "core:strings"

IS_WASM :: ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32

@export
_fltused: c.int = 0

mainArena: mem.Arena
mainData: [mem.Megabyte * 20]byte
temp_allocator: mem.Scratch_Allocator

camera: rl.Camera3D
pos := rl.Vector3{0, 10, 0}
color := rl.RED
sp: Spring

ctx: runtime.Context

font: rl.Font

@export
init :: proc "c" () {
    using rl
    context = runtime.default_context()
    // needed to setup some runtime type information in odin
    #force_no_inline runtime._startup_runtime()

    when IS_WASM {
        mem.arena_init(&mainArena, mainData[:])
        context.allocator = mem.arena_allocator(&mainArena)

        mem.scratch_allocator_init(&temp_allocator, mem.Megabyte * 2)
        context.temp_allocator = mem.scratch_allocator(&temp_allocator)

        TraceLog(rl.TraceLogLevel.INFO, "Setup hardcoded arena allocators")
    }
    ctx = context

	init_ecs()

    camera.position = Vector3{3, 3, 3};
    camera.target = Vector3{};
    camera.up = Vector3{0, 1, 0};
    camera.fovy = 80;
    camera.projection = .PERSPECTIVE;
    InitWindow(600, 600, "test")
    SetTargetFPS(60);

    t := tween(&pos, rl.Vector3{0, 0, 0}, 3)
    t.ease_proc = ease_out_elastic
    tween(&color, rl.Color{255, 255, 0, 255}, 3)

    sp = make_spring(2, 0.5, 0, 0)

    for i in 0..<10 {
        cube := create_entity()
        transform := add_component(Transform, cube)
        tweens := add_component(Tweens, cube)
        transform.translation.x = f32(i) * 3
        append(&tweens.tweeners, tween(&transform.translation.y, 3, f32(i+1) * 10))
    }

    font = rl.LoadFont("resources/mago3.ttf")
}

@export
cleanup :: proc "c" () {
    context = ctx
    free_ecs()
    rl.CloseWindow()
    #force_no_inline runtime._cleanup_runtime()
}

draw_text :: proc (s: string, pos: rl.Vector2) {
    cstr, err := strings.clone_to_cstring(s, allocator=context.temp_allocator)
    if err != nil {
        panic("can't alloc string")
    }

    rl.DrawTextEx(font, cstr, pos, 26, 1, rl.WHITE)
}

i := 0
@export
update :: proc "c" () {
    using rl
    context = ctx
    defer free_all(context.temp_allocator)
    update_tween(rl.GetFrameTime())
    BeginDrawing()
    defer EndDrawing()

    UpdateCamera(&camera, .ORBITAL)

    ClearBackground(GRAY)
    BeginMode3D(camera)
    {
        view := make_scene_view(Transform)
		for e in iterate_scene_view(&view) {
            DrawCube(get_component(Transform, e)^.translation, 1, 1, 1, color);
		}
        DrawCube(Vector3{update_spring(&sp, rl.GetMousePosition().x, rl.GetFrameTime()), 2, 0}, 1, 1, 1, rl.GREEN)

        DrawGrid(10, 1);
    }
    EndMode3D()

    draw_text("HI!", rl.Vector2{10, 10})
}


