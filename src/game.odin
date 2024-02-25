package main
import "core:runtime"
import rl "raylib"
import c "core:c"
import "core:mem"

IS_WASM :: ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32

@export
_fltused: c.int = 0

tempData: [mem.Megabyte * 4]byte
mainData: [mem.Megabyte * 16]byte

camera: rl.Camera3D
pos := rl.Vector3{0, 10, 0}
color := rl.RED

@export
init :: proc "c" () {
    using rl
    context = runtime.default_context()
    // needed to setup some runtime type information in odin
    #force_no_inline runtime._startup_runtime()

    // TODO: figure out how to add hook to call runtime._cleanup_runtime()

    when IS_WASM {
        mainArena: mem.Arena
        mem.arena_init(&mainArena, mainData[:])

        tempArena: mem.Arena
        mem.arena_init(&tempArena, tempData[:])

        context.allocator = mem.arena_allocator(&mainArena)
        context.temp_allocator = mem.arena_allocator(&tempArena)
        TraceLog(rl.TraceLogLevel.INFO, "Setup hardcoded arena allocators")
    }


    camera.position = Vector3{3, 3, 3};
    camera.target = Vector3{};
    camera.up = Vector3{0, 1, 0};
    camera.fovy = 80;
    camera.projection = .PERSPECTIVE;
    InitWindow(600, 600, "test")
    SetTargetFPS(60);
}

@export
update :: proc "c" () {
    using rl
    BeginDrawing();
    defer EndDrawing();

    UpdateCamera(&camera, .ORBITAL);

    ClearBackground(GRAY);
    BeginMode3D(camera);
    {
        DrawCube(pos, 1, 1, 1, color);
        DrawGrid(10, 1);
    }
    EndMode3D();
}


